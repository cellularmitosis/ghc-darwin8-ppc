# Session 48 commits

- 58fc94b Session 48: probe48
  hooks 10 points across `tcRnSrcDecls`, `tc_rn_src_decls`,
  and `tcTopSrcDecls` in `compiler/GHC/Tc/Module.hs`.  Three
  iterations (v1 / v2 / v2.5 / v3 cumulative).

  **Findings:**

  | evt | site                              | clean | len=600 | len=1650 |
  |-----|------------------------------------|-------|---------|----------|
  | 1   | `after_rnTopSrcDecls`              | 0     | 0       | 0        |
  | 2   | `after_tcTyClsInstDecls`           | 0     | 0       | 0        |
  | 3   | **`after_tcTopBinds_val_binds`**   | **8** | **2**   | **3**    |
  | 4   | `after_tcTopBinds_deriv_binds`     | 8     | 2       | 3        |
  | 5   | `after_tcTopSrcDecls`              | 8     | 2       | 3        |
  | 6   | `after_tc_rn_src_decls`            | 8     | 2       | 3        |
  | 7   | `after_mkTypeableBinds`            | 9     | 3       | 4        |
  | 8   | `after_zonkTcGblEnv_binds_prime`   | 9     | 3       | 4        |
  | 9   | `tcg_env_prime_final`              | 9     | 3       | 4        |
  | 10  | `binds_mf_after_zonk_main`         | 0     | 0       | 0        |

  Failing runs are `RC=0` silent miscompiles.

  **`tcTopBinds val_binds val_sigs` is where the truncation
  happens.**  Before it (after `tcTyClsInstDecls`), tcg_binds
  is 0.  After it, tcg_binds is 8 (clean) or 2-3 (failing).
  Subsequent steps preserve the count (modulo +1 from
  `mkTypeableBinds`'s synthesized `$trModule`).

  Pipeline progress chain across sessions 42-48:
  - S42: simplTopBinds entry = 0-1 binders.
  - S43: core2core entry = 1-3.
  - S44: deSugar final_prs = 3-6.
  - S45: deSugar tcg_binds entry = 3-6.
  - S46: hsc_typecheck_exit = 3-5.
  - S47: tcRnSrcDecls output = 2-5.
  - **S48: tcTopBinds val_binds val_sigs output = 2-3
    (+1 from mkTypeable → 3-4).**

  `tcTopBinds` is in `compiler/GHC/Tc/Gen/Bind.hs`.  Its body
  is a recursive walk over the value-binding groups,
  typechecking each one and extending `tcg_binds`.  Next
  session should drill inside to identify the specific
  recursion / loop step where the count is short-counted.

  v0.12.0 ships unchanged; probe applied for measurement only
  and reverted at session end; stage2 on pmacg5
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  (30 PASS, 4 known-flaky FAIL_OUTPUT matching session 47).

  Session 48 HANDOFF.md scopes probe49: drill inside
  `tcTopBinds` to identify which recursion / fold step
  truncates the binders bag.
