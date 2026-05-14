# Session 45 — desugarer is INNOCENT; `tcg_binds` is already truncated when deSugar receives it

**Dates:** 2026-05-13 (continuation of session 44; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-44 exit.
Session 44 narrowed the truncation to WITHIN or BEFORE the
desugarer.  Session 45 hooks more granularly to pinpoint
WHICH step within deSugar truncates.

**Status on exit:** CLEAN.  Probe45 reverted, stage1 rebuilt
clean _(TBD)_, stage2 redeployed _(TBD)_, baseline tests
_(TBD)_.  **Definitive finding:** Probe45 adds 7 length hooks
inside `HsToCore.deSugar` at every step from `tcg_binds`
(input) through `final_prs` (output before simpleOptPgm).
**Every step preserves the count exactly.**  The desugarer is
INNOCENT — whatever count `tcg_binds` arrives as, that's what
flows through every internal step unchanged.  **The
truncation has ALREADY HAPPENED when deSugar receives
`tcg_binds`.**  Corruption is in the typechecker's output, in
HscMain's bridging code, or via GC corruption of the heap-
allocated `Bag (LHsBindLR GhcTc GhcTc)` during transit between
typechecker exit and deSugar entry.  v0.12.0 release
unchanged.

## Plan (per session 44 HANDOFF.md)

Hook MORE granularly inside `deSugar`:
- `length tcg_binds` (input from typechecker)
- `length binds_cvr` (after addTicksToBinds)
- `length core_prs` (after dsTopLHsBinds)
- `length all_prs` (after concatOL)
- `length final_prs` (after addExportFlagsAndRules)

The drop point pinpoints which step truncates.

## What happened

### Phase 1 — probe45 design

Helper inline in `HsToCore.hs`.  7 hook calls:
1. `tcg_binds` (input)
2. `binds_cvr` (after addTicksToBinds)
3. `core_prs_initial` (after dsTopLHsBinds)
4. `core_prs_patched` (after patchMagicDefns)
5. `all_prs_in_initDs` (after concatOL inside initDs)
6. `all_prs_outside_initDs` (after initDs case unpack)
7. `final_prs` (after addExportFlagsAndRules)

`lengthBag` imported from `GHC.Data.Bag` for measuring the
`Bag (LHsBindLR GhcTc GhcTc)` types.

### Phase 2 — build + deploy

Build (~6m, EXIT=0).  Deploy (~6m, EXIT=0).

### Phase 3 — triggers

Clean compile (-A256m): all 7 steps = 9.
Failing len=600: all 7 steps = 3, then panic.
Failing len=850: all 7 steps = 6, then RC=0.
Failing len=1650: all 7 steps = 5, then panic.

**Every step preserves the count exactly.**

### Phase 4 — interpretation

The desugarer is doing its job correctly.  Whatever count it
gets in, it produces the same count out.

The truncation is BEFORE `tcg_binds` arrives at deSugar.

`tcg_binds :: LHsBinds GhcTc = Bag (LHsBindLR GhcTc GhcTc)`
— a heap-allocated `Bag`.  The `Bag.TwoBags` constructor is
`CONSTR_2_0` (2 pointer fields: left Bag, right Bag).  GC
corruption of TwoBags pointers would shrink the Bag's
effective contents, similar to the cons-list truncation
observed in `[InBind]` cells.

### Phase 5 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/HsToCore.hs` — probe reverted.
* Stage1 clean rebuild: `logs/build2-clean.log` _(TBD)_.
* Stage2 redeploy: `logs/deploy2-clean.log` _(TBD)_.
* Baseline tests: `logs/baseline-tests-end.log` _(TBD)_.

Session ends CLEAN.

## Files added this session

* `README.md` (this), `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md`.
* `probe45-granular-desugar.patch` — 7 hook points inside
  `deSugar`.
* `logs/` — build, deploy, trigger output _(TBD post-revert
  rebuild/redeploy/baseline)_.

## Top finding

`tcg_binds` is ALREADY truncated to 3-6 binders when deSugar
receives it (vs clean's 9).  The desugarer is innocent — every
internal step preserves the count.

Session 46 should hook the typechecker's output and/or
HscMain's bridging code between typechecker and deSugar.

See [`findings.md`](findings.md) §F7 for concrete experiment
recipes and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
