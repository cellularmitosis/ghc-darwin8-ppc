# Session 44 — desugarer's output (`final_prs`) is already truncated in failing runs; corruption is WITHIN or BEFORE the desugarer

**Dates:** 2026-05-13 (continuation of session 43; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-43 exit.
Session 43 narrowed the [InBind] truncation locus to BEFORE
core2core entry.  Session 44 hooks the desugarer's output to
narrow further.

**Status on exit:** CLEAN.  Probe44 reverted, stage1 rebuilt
clean _(TBD)_, stage2 redeployed _(TBD)_, baseline tests _(TBD)_.
**Major finding:** Probe44 hooks `HsToCore.deSugar`'s return
point and logs three lengths: `final_prs` (desugarer's main
output before simpleOptPgm), `ds_binds` (post-simpleOptPgm),
and `mg_binds` (the field in ModGuts).  **`final_prs` is
already 3-6 in failing runs vs 9 in clean compiles.**  The
corruption is WITHIN or BEFORE the desugarer's main
computation (between the typechecker's `tcg_binds` and the
construction of `final_prs`).  `simpleOptPgm` then drops
binders further (legitimate DCE on broken input).  At len=600,
`final_prs=3 → ds_binds=0 → silent miscompile`.  v0.12.0
release unchanged.

## Plan (per session 43 HANDOFF.md)

Hook the desugarer's output to localize whether the truncation
is IN the desugarer or in HscMain between desugarer and
core2core.

## What happened

### Phase 1 — design probe44

Helper added inline in `HsToCore.hs`.  Hook just before
`return (msgs, Just mod_guts)` to log three lengths:

```haskell
let !_probe44 = probe44LogDeSugarReturn
                  (length final_prs) (length ds_binds)
                  (length (mg_binds mod_guts))
```

Patch saved as `probe44-desugar-hook.patch`.

### Phase 2 — build attempts

v1 build failed: placed `import` lines AFTER function
definitions.  Fixed by moving helpers into the post-import
section.

v1.1 build (~6m): EXIT=0.

### Phase 3 — deploy + trigger

Deploy: EXIT=0, smoke-test PASS.

| env-len | final_prs | ds_binds | mg_binds | RC | outcome |
|---------|-----------|----------|----------|----|---------|
| clean -A256m | 9   | 9        | 9        | 0  | proper compile |
| 600     | 3         | 0        | 0        | 0  | silent miscompile |
| 850     | 6         | 4        | 4        | 1  | refineFromInScope panic |
| 1650    | 5         | 3        | 3        | 1  | refineFromInScope panic |

### Phase 4 — interpretation

**Two distinct truncation events:**

1. **The desugarer's main computation truncates 9 → 3-6
   binders** (`final_prs` is the desugarer's primary output;
   it should equal Big2.hs's ~9 top-level binders).
2. **`simpleOptPgm` further drops binders** (3 → 0 at len=600;
   5 → 3 at len=1650).  Plausibly legitimate DCE: with most
   binders already missing, the surviving ones look
   unreferenced and get eliminated.

`mg_binds == ds_binds` always — no further corruption after
simpleOptPgm.

The truncation locus is now narrowed to **within the
desugarer's `initDs` block** (`dsTopLHsBinds`, `patchMagicDefns`,
`dsImpSpecs`, `dsForeigns`, `dsRule`, `appOL`, `fromOL`, or
`addExportFlagsAndRules`).  OR in the typechecker's output
(`tcg_binds`).  OR GC corruption of any heap-allocated list
in this chain.

### Phase 5 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/HsToCore.hs` — probe reverted.
* Stage1 clean rebuild: `logs/build2-clean.log` _(TBD)_.
* Stage2 redeploy: `logs/deploy2-clean.log` _(TBD)_.
* Baseline tests: `logs/baseline-tests-end.log` _(TBD)_.

Session ends CLEAN.

## Files added this session

* `README.md` (this), `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md`.
* `probe44-desugar-hook.patch` — deSugar return hook.
* `logs/build1-probe44.log` — build (first attempt failed,
  second succeeded after fixing import placement).
* `logs/build2-clean.log`, `deploy*.log`,
  `baseline-tests-end.log` — post-revert cleanup _(TBD)_.

## Top finding to carry into session 45

`final_prs` is already 3-6 in failing runs (vs 9 clean) at
the desugarer's exit.  The truncation is WITHIN the desugarer's
main computation or in the typechecker's output going into it.

Session 45 should hook more granularly inside `deSugar`:

- `length tcg_binds` (input to deSugar from typechecker).
- `length binds_cvr` (after addTicksToBinds).
- `length core_prs` (after dsTopLHsBinds).
- `length all_prs` (after concatOL).

This will pinpoint the EXACT step where the [LHsBinds] or
[(Id, CoreExpr)] list is truncated.

See [`findings.md`](findings.md) §F6 for the experiment
recipe and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
