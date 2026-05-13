# Handoff from session 33 → session 34

**For:** the next claude session.
**From:** session 33 (closure-shape probe; CUT SHORT 2026-05-13).
**Recommended pickup:** the v1 finding is huge (bug locus =
specific THUNK_1_0 closure type, not a virtual address).  Either
continue the probe campaign from the dirty stage2 already
deployed on pmacg5, or revert to clean and redo with the
findings as a starting point.

## ⚠ SESSION CUT SHORT — DIRTY STATE

This session was interrupted by the user at ~00:37 local for
project reorganization in a separate Claude session.  Final
revert + clean rebuild was **NOT done**.

- **Source tree DIRTY**:
  `external/ghc-modern/ghc-9.2.8/compiler/GHC/Core/Opt/Simplify/Env.hs`
  has the PROBE33-v2 patch applied.  See
  [`probe33-closure-dump.patch`](probe33-closure-dump.patch).
- **`_build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a`** is
  the PROBE33-v2 build (different binary from v0.12.0).
- **`pmacg5:/opt/ghc-stage2/bin/ghc-real`** is the PROBE33-v2
  stage2 (8-word closure dump applied at `refineFromInScope`).

To revert to clean:

```bash
cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8
git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Cycle time: ~14 minutes.

## TL;DR — the major finding to carry forward

**PROBE33-v1 captured FOUR `refineFromInScope` panics at four
different heap addresses across three different megablocks —
and ALL FOUR have the SAME info pointer at offset 0: `_s71L_info`
(a THUNK_1_0 info table at 0x08c62bac in __DATA,__const).**

This **further refines session 32's finding**.  Session 32
falsified the "single virtual address blind spot".  Session 33
replaces it with "single CLOSURE TYPE blind spot":

- The GC bug is on closures of one specific THUNK_1_0 type.
- Different env-var sizes cause different Vars to end up at
  this closure-type, dropping different Vars per env-size.
- The closure type is identified by info-table address
  0x08c62bac (in *this particular* PROBE33-v1 build — the
  address will shift per build, but the SYMBOL is the same).

Companion data point: w3 (offset +12) is consistently
`_ghczmprim_GHCziTypes_Wzh_con_info` (0x092577e0) — the static
info table for `W#`.  Since THUNK_1_0 is only 2 words, w3 is
past the closure; the adjacent heap closure consistently has a
W# pointer at its offset+4.

**Raw data** for the four captured samples (env-len, tagged
addr, w0..w3) lives in [`logs/probe33-zones.log`](logs/probe33-zones.log) — that is the canonical evidence
for the finding above.  The v2 partial sweep (no REFINE samples
in tested range) is in [`logs/probe33-v2-zones.log`](logs/probe33-v2-zones.log).

## Read in order

1. **This file.**
2. [`README.md`](README.md) — narrative.
3. [`findings.md`](findings.md) — full data + analysis.
4. [`log.md`](log.md) — real-time work log.
5. [`logs/probe33-zones.log`](logs/probe33-zones.log) — v1 sweep
   results (the canonical 4-REFINE-sample table).
6. [`logs/probe33-v2-zones.log`](logs/probe33-v2-zones.log) —
   v2 partial sweep (no REFINEs in tested range).
7. [`probe33-closure-dump.patch`](probe33-closure-dump.patch) —
   the v2 (8-word dump) patch.  Already applied to source tree
   (don't re-apply — `git diff` shows it).
8. (Reference) Session 32 [`HANDOFF.md`](../2026-05-12-session-32-env-var-bisect/HANDOFF.md) — its top priority is what session 33 pursued.

## What to try next, in priority order

### Top: identify which `_s71L_info` symbol is at 0x08c62bac

`_s71L_info` is a compiler-generated name appearing in MULTIPLE
.o files of the GHC compiler:

- `_build/stage1/compiler/build/GHC/Types/Basic.o`
- `_build/stage1/compiler/build/GHC/Driver/CodeOutput.o`
- `_build/stage1/compiler/build/GHC/Rename/Utils.o`
- `_build/stage1/compiler/build/GHC/Tc/Instance/Family.o`
- `_build/stage1/compiler/build/GHC/CmmToAsm/AArch64/CodeGen.o`
- `_build/stage1/compiler/build/GHC/Core/Opt/Simplify/Env.o`

Each module has its OWN local `_s71L_info`.  In the linked
binary, ONE of these wins the address 0x08c62bac.

Approaches:

1. **Disassemble the entry code** at 0x019e2620 (the entry
   field of `_s71L_info`).  The first few PPC instructions
   should reveal the captured environment / what computation
   the thunk performs.

   ```bash
   ssh pmacg5 'otool -t -V /opt/ghc-stage2/bin/ghc-real | \
       awk "/^019e2620/{p=1} p{print; n++; if(n>10) exit}"'
   ```
2. **Linker map**: tweak the link command to emit a map file
   (`ld -map foo.map`) so we can see which .o each address came
   from.  Look up 0x08c62bac.

3. **Exclude-and-rebuild**: rebuild with one candidate .o
   excluded, see if the address shifts.  Slow but mechanical.

4. **Build with `-fdump-cmm`**: the .dump-cmm output names
   each thunk it generates; correlate `s71L` (a Uniq) back to
   source location.

Cost: ~30-60 min for the first approach; longer for #2/#3.

### Second: get PROBE33-v2 data (8-word dump)

The v2 binary is on pmacg5 but the v2 sweep returned no REFINE
samples in the tested env-len range (100..3000).  Either:

a. **Sweep a different env-len range** to find REFINE zones in
   the v2 binary.  Try 50..100 step 1, 3000..5000 step 100, etc.

b. **Add probe33-style dumps to the SCOPE / STGCMM / DEPSORT
   panic sites** so we capture closure data at the surfaces
   that DO fire under v2.  Panic sites approximately:
   - SCOPE: `compiler/GHC/Tc/Utils/Env.hs` or `compiler/GHC/Rename/Env.hs`.
   - STGCMM: `compiler/GHC/StgToCmm/Env.hs:153`.
   - DEPSORT: `compiler/GHC/Stg/DepAnal.hs` (look for `depSortStgBinds`).

Cost: (a) 30 min; (b) 2-3 h.

### Third: probe what's in w1 (the THUNK's captured pointer)

THUNK_1_0 has 1 ptr field at offset +4.  This is the captured
environment.  Reading w1 across the 4 captured samples shows:
- 650: 0x55e3a5d — small value, likely NOT a heap address
- 850, 900: 0xcce00c1 — close to v's address (0xcce0cbc)
- 1700: 0xdb8589a — heap address

Mixed.  In some samples w1 looks like a raw integer (Uniq?);
in others it's a heap pointer.

If we dereference w1 as a pointer in the heap-pointer samples,
we'd see what the THUNK_1_0 captured.  Could give hints about
what this thunk computes.

Cost: ~1-2 h (probe extension, rebuild, deploy, run).

### Fourth: examine the GC walker for THUNK_1_0 misclassification

If the bug is closure-type-specific, the RTS walker has a bug
specific to type 16.  In `rts/sm/Scav.c`, the THUNK_1_0 case
should be a simple "scavenge 1 pointer at +4".  Check whether
there's a special-case path for some condition.

Cost: ~2-4 h.

### Fifth: examine the closure type assignment in CmmToAsm

Closure type is assigned during STG-to-Cmm and Cmm-to-asm.
For PPC unregisterised, the type might be miscoded.

Cost: ~3-4 h.

## Mechanics — picking up where session 33 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# OPTION A: Continue from PROBE33-v2 build (currently deployed)
# Run a sweep to find REFINE zones with current v2 binary:
for n in $(awk 'BEGIN{for(i=20;i<=200;i+=2) print i; for(i=200;i<=3000;i+=20) print i}'); do
    pad=$(awk "BEGIN{for(i=1;i<=$((n-2));i++) printf \"A\"}")
    e="A=${pad}"
    out=$(ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; \
        env $e DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
        /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; \
        echo RC=\$?")
    refineLine=$(echo "$out" | grep "refineFromInScope " | head -1)
    if [ -n "$refineLine" ]; then
        echo "len=$n $refineLine"
    fi
done

# Same Big2.hs as before, already on pmacg5:/tmp/Big2.hs.

# OPTION B: Revert to clean, redo
cd external/ghc-modern/ghc-9.2.8
git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

## What NOT to redo

- **Don't redo the env-var length bisect** — session 32 mapped
  the zones.
- **Don't redo the address probe (PROBE32-v1)** — session 32 +
  33's findings supersede it; closure shape (not address) is
  the right level.
- **Don't redo cross-run address diffing** — session 31 ruled
  out.
- **Don't redo `scavenge_stack` iteration probes** — session 31
  ruled out.
- **Don't hypothesize single-blind-spot-virtual-address** —
  session 32 ruled out.

## Hosts (unchanged)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **PROBE33-v2 build**
    (NOT clean v0.12.0).  Dirty.
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked,
    kept from session 30.  Unchanged.
- **imacg3**: not used this session.
- **indium**: don't use for clang or hadrian builds.

## Time estimate for session 34

- Setup + read handoff + reproduce: 15-30 min.
- (If reverting first) revert + clean rebuild + redeploy: ~14 min.
- Disassemble entry code at 0x019e2620 (top priority #1): 30-60 min.
- Bonus: re-sweep with different env-lens to find v2 REFINE zones: 30-60 min.
- Trace `_s71L_info` to its Haskell-source location: 1-2 h.

Realistic: 1 medium session (~4 h) to pin down what
`_s71L_info` represents and propose a GC-walker fix.

## Paste-into-fresh-session prompt

```
Context: session 33 of the GHC darwin8-ppc project was CUT SHORT
at ~00:37 local on 2026-05-13 by user request for project
reorganization.  Source tree + stage2 are DIRTY.

Session 33's major finding (from PROBE33-v1 sweep):

PROBE33-v1 dumps closure-header + 3 payload words at the
refineFromInScope panic.  FOUR captured REFINE samples at four
different heap addresses across three different megablocks ALL
SHARE THE SAME INFO POINTER 0x08c62bac (`_s71L_info`, a THUNK_1_0
info table) AND THE SAME w3 = 0x092577e0
(`_ghczmprim_GHCziTypes_Wzh_con_info`, the W# constructor's
static info table).

This refines session 32's framing: the bug locus is NOT a
specific virtual address but a SPECIFIC CLOSURE TYPE — the
THUNK_1_0 at `_s71L_info` 0x08c62bac.

`_s71L_info` is a compiler-generated name that appears in
multiple .o files of compiled GHC.  Which specific module
generated the THUNK at 0x08c62bac was not determined this
session.

PROBE33-v2 (8-word dump) deployed but its sweep returned no
REFINE samples in the tested env-len range (100..3000).
v2 binary is currently the deployed stage2 on pmacg5.

Read in order:
1. docs/sessions/2026-05-13-session-33-closure-shape-probe/HANDOFF.md
2. docs/sessions/2026-05-13-session-33-closure-shape-probe/README.md
3. docs/sessions/2026-05-13-session-33-closure-shape-probe/findings.md
4. docs/sessions/2026-05-13-session-33-closure-shape-probe/log.md
5. (reference) docs/sessions/2026-05-12-session-32-env-var-bisect/HANDOFF.md

DIRTY STATE — must decide:
A) Pick up the PROBE33-v2 binary already on pmacg5; find REFINE
   zones in v2 by sweeping different env-lens.
B) Revert + clean rebuild + redeploy (~14 min cycle), then redo
   probe campaign with knowledge that closure-shape matters.

Top priority: identify what `_s71L_info` represents.  Disassemble
the entry code at 0x019e2620 in the deployed stage2 — first few
PPC instructions should reveal the captured environment / what
the thunk computes.  Tools: `otool -t -V`.

Second priority: get PROBE33-v2 data (8-word closure dump) by
sweeping different env-lens, OR add probes to the SCOPE / STGCMM
/ DEPSORT panic sites for cross-surface comparison.

Don't redo: env-var length bisect (session 32 mapped it),
cross-run address diff (session 31 ruled out), scavenge_stack
iteration probes (session 31 ruled out), single-blind-spot-
virtual-address hypothesis (session 32 ruled out).

ALWAYS revert probes + rebuild + redeploy clean stage2 at
session end.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-33-closure-shape-probe/HANDOFF.md`](docs/sessions/2026-05-13-session-33-closure-shape-probe/HANDOFF.md).

When session 34 ends, write the next handoff at:
`docs/sessions/<DATE>-session-34-<slug>/HANDOFF.md`.
