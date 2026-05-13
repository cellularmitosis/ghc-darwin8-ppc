# Handoff from session 34 → session 35

**For:** the next claude session.
**From:** session 34 (s71L identification; CLEAN exit).
**Recommended pickup:** add a `-ddump-stg-final` build of
`AArch64/CodeGen.hs` to pin which of three textual `ncgPlatform
config` occurrences corresponds to `s71L`, then run a
verification probe to test whether v is actually in WHNF at the
panic site.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe33-v2 patch reverted; `CmmToC.hs` retains
canonical patches/0008 pi-Double fix).  Stage1 + stage2 rebuilt
clean and redeployed to pmacg5.  v0.12.0 release unchanged.

## TL;DR — the major finding to carry forward

**The buggy `_s71L_info` from session 33's REFINE samples is the
info-table for a `ncgPlatform config` thunk emitted by
`GHC.CmmToAsm.AArch64.CodeGen`.**

Static analysis on the deployed PROBE33-v2 stage2 binary + the
corresponding `_build/stage1/.../GHC/CmmToAsm/AArch64/CodeGen.o`
on uranium:

- 5 candidate `_s71L_info` symbols in the linked stage2 (one per
  surviving .o that emits this Uniq).
- Only ONE has type THUNK_1_0 (layout 1 ptr / 0 nptrs / type 0x10)
  — the rest are THUNK (0 or 3 ptrs) or THUNK_2_0.
- Symbol-neighbor analysis + byte-for-byte entry-code match
  confirms the THUNK_1_0 candidate is from
  `GHC/CmmToAsm/AArch64/CodeGen.o`.
- The .o file's NLP relocations resolve to
  `_ghc_GHCziCmmToAsmziConfig_ncgPlatform_closure` + `_stg_ap_p_fast`
  + `_stg_upd_frame_info`.  This is the canonical compiled form
  of `ncgPlatform config`.

`AArch64/CodeGen.hs` has three textual occurrences of
`ncgPlatform config`:

- `:142` — `pdoc (ncgPlatform config) block`
- `:392` — inside `getFloatReg`'s `pprPanic`
- `:406` — inside `getRegister`

Without `-ddump-stg-final` we cannot tell which Uniq `s71L` maps
to.  The next session can resolve this in ~30 min.

**The PUZZLE the finding deepens:**  `nativeCodeGen` in
`compiler/GHC/CmmToAsm.hs:153` dispatches by arch — `ArchPPC` →
`PPC.ncgPPC`, `ArchAArch64` → `AArch64.ncgAArch64`, etc.  For a
PPC compilation, the AArch64 codegen branch is unreachable.  So no
`ncgPlatform config` thunk from AArch64.CodeGen should ever be
heap-allocated at runtime.  Yet session 33's probe sees this
thunk's info pointer at v's heap address across 4 captures.

See [`findings.md`](findings.md) §F4 for the 4 candidate theories
(WHNF/aToWordzh/GC-walker mistype/random collision) and which
each predicts.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session plan + arrival state.
3. [`findings.md`](findings.md) — full data + analysis.
4. [`log.md`](log.md) — real-time work log.
5. (Reference) Session 33 [`HANDOFF.md`](../2026-05-13-session-33-closure-shape-probe/HANDOFF.md) — what session 34 picked up.
6. (Reference) Session 33 [`findings.md`](../2026-05-13-session-33-closure-shape-probe/findings.md) — the THUNK_1_0 closure-shape finding.

## What to try next, in priority order

### Top: pin down which source line `s71L` corresponds to

Rebuild `compiler/GHC/CmmToAsm/AArch64/CodeGen.hs` with
`-ddump-stg-final` (or `-ddump-cmm-from-stg`).  Grep for `s71L` in
the dump file.  This identifies which textual `ncgPlatform config`
occurrence becomes this Uniq.

Practical approach: temporarily add `-ddump-stg-final -ddump-to-file`
to hadrian's compile flags for the compiler package.  Build, find
the `.dump-stg-final` file, grep.  Cycle time: ~6–8 min stage1
rebuild.

### Second: verify v is actually in WHNF at the probe site

Re-introduce a probe (like probe33-v1, the 4-word version that
captured data) but also `seq v` BEFORE reading the heap header.
If header changes from `_s71L_info` to an Id-con-info, the bug is
"isLocalId isn't actually forcing on PPC unreg" (theory 1).
If it stays THUNK_1_0, the bug is heap corruption (theories 3/4).

Cycle: ~14 min rebuild + ~5 min sweep.

### Third: collect more REFINE samples

The 4 captures in session 33's `probe33-zones.log` are all at
env-len {650, 850, 900, 1700}.  Sweep more env-lens with the v1
(4-word) probe to gather more samples.  If the info pointer
keeps coming back as `_s71L_info` (= AArch64.CodeGen
ncgPlatform config), the finding is solid.  If a different info
pointer appears, the closure-type framing has a hole.

Cycle: ~14 min build + 30 min sweep.

### Fourth: investigate the GC walker

If theories 3/4 (heap corruption / aToWordzh) are confirmed,
follow session 33's HANDOFF priority #4:
inspect `rts/sm/Scav.c`'s `THUNK_1_0` case for misclassification.

Cycle: 2–4 h.

## Mechanics — picking up where session 34 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree is clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild from end of session 34.

# Option A — dump-stg-final probe to identify s71L source line:
# (need to add -ddump-stg-final to hadrian; left as exercise)

# Option B — re-do probe33-v1 (4-word dump) to gather more REFINE samples:
cd external/ghc-modern/ghc-9.2.8
# Apply session 33's saved v2 patch then change [0..7] → [0..3]
git apply ../../../docs/sessions/2026-05-13-session-33-closure-shape-probe/probe33-closure-dump.patch
# Edit compiler/GHC/Core/Opt/Simplify/Env.hs to change [0 .. 7] to [0 .. 3]
# (v1 had a 4-word dump, v2 had 8-word; v1 binary actually captured REFINE samples)
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# Then run the sweep (Big2.hs already on pmacg5:/tmp/Big2.hs):
for n in $(awk 'BEGIN{for(i=600;i<=2000;i+=50) print i}'); do
    pad=$(awk "BEGIN{for(i=1;i<=$((n-2));i++) printf \"A\"}")
    e="A=${pad}"
    out=$(ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; \
        env $e DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
        /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; \
        echo RC=\$?")
    refineLine=$(echo "$out" | grep "refineFromInScope " | head -1)
    [ -n "$refineLine" ] && echo "len=$n $refineLine"
done
```

## What NOT to redo

- **Don't redo the v2 sweep at env-len 100..3000** — session 33's
  v2 sweep returned no REFINE samples; the v1 (4-word) build
  captures more reliably because the binary size is smaller.
- **Don't redo the candidate identification** — session 34 did
  the byte-for-byte match + relocation decode.  The buggy thunk
  is `GHC.CmmToAsm.AArch64.CodeGen._s71L_info`, period.
- **Don't redo the env-var bisect / address probe** — sessions
  32 + 33 ruled those framings out.
- **Don't redo the cross-run address diff** — session 31 ruled out.

## Hosts (unchanged)

- **uranium** (this Mac): cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-34 rebuild).
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked,
    kept from session 30.  Unchanged.
- **imacg3**: not used.
- **indium**: don't use for clang/hadrian builds.

## Time estimate for session 35

- Setup + read handoff + reproduce: 15-30 min.
- Add `-ddump-stg-final` flag, rebuild, grep s71L: ~30-45 min.
- Probe33-v1 with `seq v` for WHNF verification: ~30 min build +
  30 min sweep + analysis.
- Total realistic: 1 medium session (~3-4 h) to definitively pin
  down the bug locus (closure type vs heap corruption vs WHNF bug).

## Paste-into-fresh-session prompt

```
Context: session 34 of the GHC darwin8-ppc project did a STATIC
ANALYSIS pass on session 33's PROBE33 stage2 binary.  Session 34
ended clean — source tree reverted to baseline, stage2 redeployed
clean to pmacg5.

Session 34's major finding:

The buggy `_s71L_info` from session 33's 4 REFINE captures is the
info-table for a `ncgPlatform config` THUNK_1_0 emitted by
`GHC.CmmToAsm.AArch64.CodeGen`.

Process:
1. nm v2 stage2 → 5 candidate _s71L_info addresses.
2. Read layout at each → only ONE is THUNK_1_0 (layout 1/0,
   type 0x10).  The rest are THUNK (0 or 3 ptrs) or THUNK_2_0.
3. Match candidate's symbol-neighbors + .o-file layout → it's
   GHC/CmmToAsm/AArch64/CodeGen.o.
4. Byte-for-byte disassembly + NLP relocation decode →
   entry calls _stg_ap_p_fast on a captured ptr against
   _ghc_GHCziCmmToAsmziConfig_ncgPlatform_closure.  That's
   `ncgPlatform config`.

The deepening puzzle: nativeCodeGen at
compiler/GHC/CmmToAsm.hs:153 dispatches by arch.  For ArchPPC,
the AArch64 branch is unreachable.  So no AArch64.CodeGen thunks
should be heap-allocated at runtime.  Yet probe33 sees the
ncgPlatform-config thunk's info pointer at v's heap address.

This points to one of:
(a) isLocalId isn't actually forcing v on PPC unreg.
(b) aToWordzh on PPC32 returns the wrong address.
(c) GC walker bug corrupts v's heap memory.
(d) Pointer-bytes coincidence (unlikely, 4 times).

Read in order:
1. docs/sessions/2026-05-13-session-34-s71L-identification/HANDOFF.md
2. docs/sessions/2026-05-13-session-34-s71L-identification/README.md
3. docs/sessions/2026-05-13-session-34-s71L-identification/findings.md
4. docs/sessions/2026-05-13-session-34-s71L-identification/log.md
5. (reference) docs/sessions/2026-05-13-session-33-closure-shape-probe/HANDOFF.md
6. (reference) docs/sessions/2026-05-13-session-33-closure-shape-probe/findings.md

Top priority: rebuild AArch64/CodeGen.hs with -ddump-stg-final and
grep for s71L to identify which of three textual `ncgPlatform
config` occurrences (line 142, 392, or 406) generates this thunk.

Second priority: verify v is actually in WHNF at the panic site
with a new probe (seq v + dump before/after).  Distinguishes the
WHNF-bug theory from the heap-corruption theory.

Third: collect more REFINE samples with the v1 (4-word) probe to
confirm the `_s71L_info` info pointer keeps appearing.

Don't redo: candidate enumeration (session 34 nailed it), env-var
bisect (session 32 mapped it), virtual-address framing (session
32 ruled out), single-blind-spot-address hypothesis (sessions 19/
30/31 superseded).

ALWAYS revert probes + rebuild + redeploy clean stage2 at session
end.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-34-s71L-identification/HANDOFF.md`](docs/sessions/2026-05-13-session-34-s71L-identification/HANDOFF.md).

When session 35 ends, write the next handoff at:
`docs/sessions/<DATE>-session-35-<slug>/HANDOFF.md`.
