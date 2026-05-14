# Handoff from session 43 → session 44

**For:** the next claude session.
**From:** session 43 (probe43 — pipeline mg_binds length tracer
at core2core entry, runCorePasses entry, and each Core pass).
**Recommended pickup:** hook the desugarer's output to find
whether the truncation happens IN the desugarer or in HscMain
between deSugar and core2core.

## ✅ SESSION CLEAN EXIT _(pending in-flight verification)_

Source tree clean (probe43 reverted).  Stage1 rebuilding +
stage2 redeploying — see README.md exit-state paragraph.
v0.12.0 release unchanged.

## TL;DR

Probe43-v2 hooks `core2core` entry AND `runCorePasses` entry
AND each `do_pass`.

| env-len | core2core | runCorePasses | Simplifier | RC |
|---------|-----------|---------------|------------|----|
| clean -A256m | 9 | 9 | 9 → 13 | 0 |
| 600     | 1         | 1             | (panic)    | 1  |
| 850     | 2         | 2             | 2 → 5      | 1  |
| 1650    | 2         | 2             | 2 → 0 *** DROPPED *** | 0 (silent miscompile) |

**`mg_binds` is already truncated at `core2core` entry.**  The
corruption happens BEFORE `core2core`.

Combined with session 42's smoking gun (simplTopBinds receives
0/1 binders), the locus is now narrowed to the path **between
the desugarer's output and `core2core`'s call** — including
GC-in-transit during that interval.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative + comparison
   table.
3. [`findings.md`](findings.md) — F1..F9 analysis with v1/v2
   data + the "corruption before core2core" localization.
4. [`log.md`](log.md) — real-time work log.
5. (Reference) Session 42
   [`HANDOFF.md`](../2026-05-13-session-42-probe-simpltopbinds-input/HANDOFF.md).

## What to try next, in priority order

### Top: hook the desugarer's output (`HsToCore.deSugar`)

The desugarer is at `compiler/GHC/HsToCore.hs`, function
`deSugar`.  Find its return point and dump
`length (mg_binds guts)` before returning ModGuts.

If the desugarer's output already shows 1-3 binders → the
corruption is in the desugarer OR earlier (typechecker).

If the desugarer's output shows 9 binders → the corruption
happens between deSugar's return and core2core's entry —
likely GC-in-transit during HscMain bridging code.

### Second: pin mg_binds at deSugar's return and check at core2core

Like probe39 (sentinel Var) but on `mg_binds`.  Stash the list
reference in an IORef immediately after deSugar produces it.
At core2core entry, read the IORef and compute `length`.  If
the pinned list shrinks between pin and check, GC corrupted
the heap-allocated cons cells.

### Third: dump ModGuts heap addresses

`anyToAddr#` on `mg_binds guts` to get the heap address of the
list head.  Compare addresses across passes — if the address
changes, the closure was relocated by GC.  Hard to do because
ModGuts is plumbed through monad stacks.

### Fourth: investigate GHC's CONSTR_2_0 closure GC handling

The `[InBind]` cons cells are CONSTR_2_0 (2 pointer fields:
head, tail).  In `rts/sm/Evac.c::copy_tag`, find the path that
copies CONSTR_2_0.  Verify that on PPC32 unreg with `-DNOSMP`
and `Tables next to code = NO`, the head/tail pointers are
correctly forwarded.  Compare with arm64 host's path for
byte-equivalent traversal.

### Fifth: file a GHC bug report

This is a serious correctness bug in GHC's RTS on PPC32 unreg.
Even with our fork's fix, the upstream report would help anyone
reviving PPC unreg in the future.

## Mechanics — picking up where session 43 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-43 redeploy).

# (a) Re-apply probe43 if you need to re-verify:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-43-trace-pipeline-binds/probe43-pipeline-trace.patch

# (b) For probe44 (desugarer-output hook), find:
grep -n "^deSugar\b" compiler/GHC/HsToCore.hs

# Add a hook like probe43's CORE2CORE one, just before deSugar
# returns ModGuts.

# (c) Build + deploy + test:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# (d) Compare clean vs failing:
pad=$(awk 'BEGIN{for(i=1;i<=598;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
    DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1" \
  | grep -E "PROBE4[34]|panic"
```

## What NOT to redo

* **Don't pursue closure-shape probes on v** — S37 dissolved.
* **Don't pursue UniqMap-corruption theories** — S38 ruled out.
* **Don't pursue Var.realUnique drift** — S39 disproved.
* **Don't pursue SimplEnv pointer-field corruption** — S41
  partially disproved.
* **Don't pursue BLACKHOLE→IND theories** — S36 framing wrong.
* **Don't hook anything AFTER core2core entry** to find the
  corruption — the corruption is BEFORE that point.
* **Don't believe `-A16m` clean compile** — that was S38's
  artifact.  Real clean threshold is `-A256m` (or `-A1G`).

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-43 redeploy).
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Time estimate for session 44

* Setup + read handoff: 10-15 min.
* Probe44 design + apply (desugarer hook): 1-2 h.
* Build + deploy + sweep + analyze: 1-2 h.
* If signal points at GC-in-transit: 2-4 h to design a Var pin
  + RTS-side probe.

Total realistic: 1 medium session (4-6 h).

## Paste-into-fresh-session prompt

```
Context: session 43 of the GHC darwin8-ppc project ran probe43
— a pipeline-level mg_binds length tracer hooked at core2core
entry, runCorePasses entry, and every Core pipeline pass.

Outcome: mg_binds is **already truncated at core2core entry**.
At core2core entry in failing runs: 1-3 binders.  At
runCorePasses entry: same count (no drop in between).  Clean
compile: 9 binders.

Two specific findings:
1. The truncation happens BEFORE core2core entry.  Suspect:
   desugarer output, HscMain bridge code, or GC-in-transit
   between phases.
2. At env-len 1650, the simplifier received 2 binders and
   produced 0 (`*** DROPPED`), with RC=0 — SILENT MISCOMPILE.
   This is the SECOND silent-miscompile env-len observed
   (session 42 found 850-1000).

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline 30 PASS / 4 FAIL_OUTPUT
unchanged.

Read in order:
1. docs/sessions/2026-05-13-session-43-trace-pipeline-binds/HANDOFF.md
2. docs/sessions/2026-05-13-session-43-trace-pipeline-binds/README.md
3. docs/sessions/2026-05-13-session-43-trace-pipeline-binds/findings.md
4. docs/sessions/2026-05-13-session-43-trace-pipeline-binds/log.md
5. (Reference) docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/HANDOFF.md

Top priority: probe44 — hook the desugarer's output
(`compiler/GHC/HsToCore.hs::deSugar`) to dump
`length (mg_binds guts)` just before deSugar returns ModGuts.
If failing runs show count=9 there but 1-3 at core2core, the
corruption is in HscMain between phases (likely GC).  If
failing runs show count=1-3 at deSugar output too, the
corruption is in the desugarer or earlier.

Don't pursue: closure-shape / UniqMap / Var.realUnique /
SimplEnv field corruption / BLACKHOLE-IND.  All ruled out.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-43-trace-pipeline-binds/HANDOFF.md`](docs/sessions/2026-05-13-session-43-trace-pipeline-binds/HANDOFF.md).

When session 44 ends, write the next handoff at:
`docs/sessions/<DATE>-session-44-<slug>/HANDOFF.md`.
