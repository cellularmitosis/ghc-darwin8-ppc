# Session 46 — `hsc_typecheck`'s `tc_result.tcg_binds` is already truncated at the typechecker's exit

**Dates:** 2026-05-13 (continuation of session 45; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-45 exit.
Session 45 ruled the desugarer innocent — `tcg_binds` is
already truncated when deSugar receives it.

**Status on exit:** CLEAN.  Probe46 reverted, stage1 rebuilt
clean _(TBD)_, stage2 redeployed _(TBD)_, baseline tests
_(TBD)_.  **Finding:** Probe46 adds 3 hooks in
`Driver/Main.hs`: `hsc_typecheck_exit` (right before
`hsc_typecheck` returns), `hscDesugar_entry` (in the
wrapper), `hscDesugarPrime_entry` (in the actual desugarer
driver).  **At `hsc_typecheck_exit` in failing runs, tcg_binds
is already 3 / 5 elements** (vs 9 in clean compiles).  The
bridge between typechecker exit and desugarer call preserves
the count exactly.  `hscDesugar_entry` never fires — Big2.hs's
compile path uses `hscDesugar'` directly.  **The corruption
is AT or BEFORE the typechecker's `return (tc_result, rn_info)`.**
Inside `hsc_typecheck`, the suspect is `tcRnModule'` (the
renamer + typechecker driver).  v0.12.0 release unchanged.

## Plan (per session 45 HANDOFF.md)

Hook the typechecker's TcGblEnv construction and HscMain's
bridge to localize the truncation.

## What happened

### Phase 1 — design probe46

Inline helper in `Driver/Main.hs`.  3 hook points:
1. `hsc_typecheck_exit` — right before `return (tc_result, rn_info)`.
2. `hscDesugar_entry` — at `hscDesugar`'s body.
3. `hscDesugarPrime_entry` — at `hscDesugar'`'s body.

All log `lengthBag (tcg_binds tc_env)`.

Patch: `probe46-tc-bridge.patch` (68 lines).

### Phase 2 — build + deploy

Build (~6m, EXIT=0).  Deploy (~6m, EXIT=0).

### Phase 3 — triggers

| env-len | hsc_typecheck_exit | hscDesugar'_entry | outcome |
|---------|---------------------|-------------------|---------|
| clean   | 9                   | 9                 | proper  |
| 600     | **3**               | 3                 | panic   |
| 1650    | **5**               | 5                 | panic   |

Two observations:

1. `hsc_typecheck_exit` shows the typechecker's output
   already has 3-5 binders in failing runs.
2. The bridge between typechecker exit and desugarer
   preserves the count.

### Phase 4 — `hscDesugar_entry` never fires

Big2.hs's compile path doesn't go through `hscDesugar`
(which wraps `hscDesugar'` via `runHsc`).  It calls
`hscDesugar'` directly, probably from `hscIncrementalCompile`
or similar.

### Phase 5 — interpretation

The corruption locus is now narrowed to **inside
`hsc_typecheck`** — specifically within the
`tcRnModule' → tc_result` step.  Either:
- The typechecker actually emits only 3-5 binders.
- The typechecker emits 9, but GC corrupts the heap-allocated
  Bag during the typechecker's run, before
  `hsc_typecheck` returns.

The CONSTR_2_0 hypothesis from sessions 44-45 fits: both
`[InBind]` cons cells and `Bag.TwoBags` are CONSTR_2_0
closures.  GC on PPC32 unreg corrupting CONSTR_2_0 explains
both.

### Phase 6 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Driver/Main.hs` — probe
  reverted.
* Stage1 clean rebuild (~6m): `logs/build2-clean.log`, EXIT=0.
* Stage2 redeploy: `logs/deploy2-clean.log`, EXIT=0,
  smoke-test PASS.
* Baseline tests: NEW OBSERVATION — flaky FAIL_COMPILE.
  - First run: `logs/baseline-tests-end.log`: 29 PASS /
    1 FAIL_COMPILE (26_threaded_rts) / 4 FAIL_OUTPUT.
  - Second run: `logs/baseline-tests-end-rerun.log`: 30 PASS /
    1 FAIL_COMPILE (01_int_arith) / 3 FAIL_OUTPUT.
  - Different tests fail each run.  This is the GC bug
    starting to hit the test cross-compile phase.  Sessions
    37-45's baseline had 30 PASS / 0 FAIL_COMPILE /
    4 FAIL_OUTPUT consistently — now the test battery is
    flaky.

Session ends CLEAN-ish.  Sources reverted, stage2
rebuilt+redeployed clean.  The test battery flakiness is a
**downstream symptom** of the same GC bug we've been
narrowing down, not a regression caused by probe46.

## Files added this session

* `README.md` (this), `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md`.
* `probe46-tc-bridge.patch` — Driver/Main hooks.
* `logs/build*.log`, `deploy*.log`, `baseline-tests-end.log`.

## Top finding

`hsc_typecheck`'s output `tc_result.tcg_binds` is already
3-5 in failing runs (vs 9 clean).  The corruption is within
`hsc_typecheck` (specifically `tcRnModule'`) or via GC
during typechecking.

Session 47 should hook the typechecker's main module
(`tcRnModule` in `GHC/Tc/Module.hs`) to narrow further.
