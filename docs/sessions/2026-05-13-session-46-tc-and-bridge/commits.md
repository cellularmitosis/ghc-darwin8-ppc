# Session 46 commits

- _TBD: backfill SHA after `git commit`._  Session 46: probe46
  hooks 3 points in `compiler/GHC/Driver/Main.hs` —
  `hsc_typecheck_exit` (just before `hsc_typecheck` returns),
  `hscDesugar_entry` (in the wrapper), and
  `hscDesugarPrime_entry` (in the actual desugarer driver).
  All log `lengthBag (tcg_binds tc_env)`.

  **Findings:**
  - Clean -A256m: hsc_typecheck_exit=9, hscDesugar'_entry=9.
  - Failing -A1m -G1 len=600: 3, 3.
  - Failing len=1650: 5, 5.
  - `hscDesugar_entry` never fires — Big2.hs uses
    `hscDesugar'` directly, probably via
    `hscIncrementalCompile`.

  **The typechecker's output already has 3-5 binders in
  failing runs.**  The bridge between typechecker exit and
  desugarer call preserves the count exactly.

  The corruption is AT or BEFORE the typechecker's
  `return (tc_result, rn_info)`.  Inside `hsc_typecheck` for a
  normal `.hs` file, the suspect is `tcRnModule'` (the
  renamer + typechecker driver).

  Pipeline progress chain across sessions 42-46:
  - S42: simplTopBinds = 0-1 binders.
  - S43: core2core entry = 1-3.
  - S44: deSugar final_prs = 3-6.
  - S45: deSugar tcg_binds (entry) = 3-6.
  - **S46: hsc_typecheck_exit tcg_binds = 3-5.**

  Refined hypothesis: GC on PPC32 unreg corrupts the
  heap-allocated `Bag (LHsBindLR GhcTc GhcTc)` during
  typechecking.  `Bag.TwoBags (Bag a) (Bag a)` is a CONSTR_2_0
  closure (2 pointer fields), structurally identical to `[a]`
  cons cells.  Same GC bug affects both.

  v0.12.0 ships unchanged; probe applied for measurement only
  and reverted at session end; stage2 on pmacg5
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (same long-standing
  test-design divergences as sessions 37-45).

  Session 46 HANDOFF.md scopes probe47: hook `tcRnModule` and
  `tcRnModule'` return points in `GHC/Tc/Module.hs` to narrow
  the corruption locus within the typechecker itself.
