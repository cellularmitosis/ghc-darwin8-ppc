# Handoff from session 46 → session 47

**For:** the next claude session.
**From:** session 46 (probe46 — Driver/Main.hs hooks at
`hsc_typecheck_exit`, `hscDesugar_entry`,
`hscDesugarPrime_entry`).
**Recommended pickup:** hook the typechecker's `tcRnModule`
(in `GHC/Tc/Module.hs`) to narrow the corruption locus
within the typechecker itself.

## ✅ SESSION CLEAN EXIT _(pending in-flight verification)_

Source tree clean (probe46 reverted).  Stage1 rebuilding +
stage2 redeploying.  v0.12.0 release unchanged.

## TL;DR

Probe46 logs `lengthBag (tcg_binds tc_env)` at 3 points in
`Driver/Main.hs`:

| env-len | hsc_typecheck_exit | hscDesugar'_entry | outcome |
|---------|---------------------|-------------------|---------|
| clean   | 9                   | 9                 | proper  |
| 600     | **3**               | 3                 | panic   |
| 1650    | **5**               | 5                 | panic   |

`hscDesugar_entry` never fires — Big2.hs uses `hscDesugar'`
directly (probably via `hscIncrementalCompile`).

**The typechecker's output already has 3-5 binders in failing
runs.**  The bridge between typechecker exit and desugarer
preserves the count.

The corruption is within `hsc_typecheck` — specifically
`tcRnModule'` (the renamer + typechecker driver).

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative.
3. [`findings.md`](findings.md) — F1..F8 analysis.
4. [`log.md`](log.md) — real-time log.
5. (Reference) Session 45
   [`HANDOFF.md`](../2026-05-13-session-45-granular-desugar/HANDOFF.md).

## What to try next, in priority order

### Top: hook tcRnModule and tcRnModule' returns

In `compiler/GHC/Tc/Module.hs`, find `tcRnModule` and
`tcRnModule'`'s return points.  Add probes that dump
`lengthBag (tcg_binds tc_env)` just before returning.

If clean=9 and failing=3-5 there, the corruption is in
`tcRnModule`'s body or upstream (renamer).

If clean=9 and failing=9 at `tcRnModule` exit but =3-5 at
`hsc_typecheck_exit`, GC corrupted the Bag between
`tcRnModule` exit and `hsc_typecheck` exit.

### Second: hook tcRnSrcDecls / tcRnGroup

These are the lower-level typechecker entry points that
populate `tcg_binds`.

### Third: pin tcg_binds in IORef at tcRnModule exit

Walk its length at multiple downstream checkpoints to detect
GC-in-transit corruption.

### Fourth: add RTS GC logging

`+RTS -DG -RTS` produces verbose GC logs.  Correlate GC
events with the truncation timing.

### Fifth: file the GHC bug report

We now have conclusive evidence: GC on PPC32 unreg
corrupts `Bag (LHsBindLR GhcTc GhcTc)` between typechecker
construction and downstream consumption.  Workaround:
`+RTS -A1G -RTS`.

## Mechanics — picking up where session 46 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-46 redeploy).

# (a) Re-apply probe46:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-46-tc-and-bridge/probe46-tc-bridge.patch

# (b) For probe47 (tcRnModule hooks), see "Top priority" above.
# Find return points in GHC/Tc/Module.hs.

# (c) Build + deploy + run:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# (d) Single trigger:
pad=$(awk 'BEGIN{for(i=1;i<=598;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
    DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1" | head -10
```

## What NOT to redo

* **Don't hook anything after `hsc_typecheck` returns** — the
  corruption is upstream of that.
* **Don't pursue closure-shape / UniqMap / Var.realUnique /
  SimplEnv / BLACKHOLE-IND** — all subsumed by the GC
  CONSTR_2_0 corruption hypothesis.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-46 redeploy).
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Paste-into-fresh-session prompt

```
Context: session 46 of the GHC darwin8-ppc project ran probe46
— hooks at hsc_typecheck_exit, hscDesugar_entry,
hscDesugarPrime_entry in Driver/Main.hs.

Findings:
- Clean -A256m: hsc_typecheck_exit=9, hscDesugar'_entry=9.
- Failing -A1m -G1 len=600: 3, 3.
- Failing len=1650: 5, 5.
- hscDesugar_entry never fires (Big2.hs uses hscDesugar'
  directly).

The typechecker's output already has 3-5 binders in failing
runs.  The bridge code preserves the count.  The corruption
is AT or BEFORE hsc_typecheck's return — specifically within
tcRnModule' (the renamer + typechecker driver).

Pipeline progress chain across sessions 42-46:
- 42: simplTopBinds = 0-1 binders.
- 43: core2core entry = 1-3.
- 44: deSugar final_prs = 3-6.
- 45: deSugar tcg_binds (entry) = 3-6.
- 46: hsc_typecheck_exit tcg_binds = 3-5.

Hypothesis: GC on PPC32 unreg corrupts the heap-allocated
Bag (LHsBindLR GhcTc GhcTc) during typechecking.  Bag.TwoBags
is a CONSTR_2_0 closure (2 ptr fields) — same as [a] cons
cells.  Same GC bug affects both.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline 30 PASS / 4 FAIL_OUTPUT
unchanged.

Read in order:
1. docs/sessions/2026-05-13-session-46-tc-and-bridge/HANDOFF.md
2. docs/sessions/2026-05-13-session-46-tc-and-bridge/README.md
3. docs/sessions/2026-05-13-session-46-tc-and-bridge/findings.md
4. docs/sessions/2026-05-13-session-46-tc-and-bridge/log.md
5. (Reference) docs/sessions/2026-05-13-session-45-granular-desugar/HANDOFF.md

Top priority: probe47 — hook tcRnModule and tcRnModule'
return points in GHC/Tc/Module.hs.  Determine whether the
truncation is in tcRnModule's body or via GC between
tcRnModule exit and hsc_typecheck exit.

Don't pursue: closure-shape / UniqMap / Var.realUnique /
SimplEnv field corruption / BLACKHOLE-IND.  All subsumed by
GC CONSTR_2_0 corruption.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-46-tc-and-bridge/HANDOFF.md`](docs/sessions/2026-05-13-session-46-tc-and-bridge/HANDOFF.md).

When session 47 ends, write the next handoff at:
`docs/sessions/<DATE>-session-47-<slug>/HANDOFF.md`.
