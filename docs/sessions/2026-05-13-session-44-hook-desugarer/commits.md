# Session 44 commits

- d6b03a1 Session 44: probe44
  hooks `HsToCore.deSugar` just before its return to log three
  list lengths — `final_prs` (desugarer's main output, before
  simpleOptPgm), `ds_binds` (after simpleOptPgm), and
  `mg_binds` (the field stored in ModGuts).

  **Findings:**
  - Clean -A256m: final_prs=9, ds_binds=9, mg_binds=9 →
    proper compile.
  - Failing -A1m -G1 len=600: final_prs=3, ds_binds=0,
    mg_binds=0 → RC=0 silent miscompile.
  - Failing len=850: final_prs=6, ds_binds=4, mg_binds=4 →
    panic.
  - Failing len=1650: final_prs=5, ds_binds=3, mg_binds=3 →
    panic.

  Two truncation events: (1) the desugarer's main computation
  truncates 9 → 3-6 binders; (2) simpleOptPgm further drops
  binders (plausibly legitimate DCE responding to already-
  broken input).

  **Localization:** the bug is WITHIN or BEFORE the
  desugarer's main `initDs` block.  Candidates: typechecker's
  `tcg_binds`, `addTicksToBinds`, `dsTopLHsBinds`,
  `patchMagicDefns`, `dsImpSpecs`, `dsForeigns`, `dsRule`,
  `appOL`/`fromOL` (OrdList ops), or `addExportFlagsAndRules`.
  Most consistent with GC corrupting a heap-allocated list in
  this chain.

  v1 build failed: I placed `import` lines AFTER function
  definitions in `HsToCore.hs`, which is illegal Haskell.
  Fixed by moving the helper definition to after the import
  block.

  v0.12.0 ships unchanged; probe applied for measurement only
  and reverted at session end; stage2 on pmacg5
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (same long-standing
  test-design divergences as sessions 37-43).

  Session 44 HANDOFF.md scopes probe45: hook MORE granularly
  inside `deSugar` to find which specific step
  (addTicksToBinds, dsTopLHsBinds, etc.) truncates the list,
  OR whether the input `tcg_binds` is already broken.
