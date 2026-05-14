# Session 45 commits

- 2982e0f Session 45: probe45
  adds 7 granular length hooks inside `HsToCore.deSugar`:
  `tcg_binds`, `binds_cvr`, `core_prs_initial`,
  `core_prs_patched`, `all_prs_in_initDs`,
  `all_prs_outside_initDs`, `final_prs`.

  **Findings (across env-lens):**

  | step                       | clean | 600 | 850 | 1650 |
  |----------------------------|-------|-----|-----|------|
  | tcg_binds                  | 9     | 3   | 6   | 5    |
  | binds_cvr → final_prs       | 9     | 3   | 6   | 5    |

  **EVERY step preserves the count exactly.**  The desugarer
  is INNOCENT — whatever count it gets in, it produces the
  same count out.  The truncation has ALREADY HAPPENED by
  the time `tcg_binds` arrives at deSugar.

  Corruption is BEFORE deSugar — in:
  - The typechecker's output construction.
  - HscMain's bridging code between typechecker and deSugar.
  - GC corruption of the heap-allocated
    `Bag (LHsBindLR GhcTc GhcTc)` during transit.

  `Bag.TwoBags (Bag a) (Bag a)` is a CONSTR_2_0 closure
  (2 pointer fields: left, right).  Structurally identical
  to `[a]` cons cells.  Same GC bug that corrupts cons-list
  spines would also corrupt TwoBags.

  Pipeline progress chain:
  - S42: simplTopBinds sees 0-1 binders.
  - S43: core2core entry sees 1-3.
  - S44: deSugar's final_prs is 3-6.
  - **S45: deSugar's tcg_binds (input) is 3-6.  Desugarer
    innocent.**

  v0.12.0 ships unchanged; probe applied for measurement only
  and reverted at session end; stage2 on pmacg5
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (same long-standing
  test-design divergences as sessions 37-44).

  Session 45 HANDOFF.md scopes probe46: hook the typechecker's
  output (GHC/Tc/Module.hs) and HscMain's bridge
  (GHC/Driver/Main.hs::hscDesugar) to localize the truncation
  to typechecker, bridge, or GC-in-transit.
