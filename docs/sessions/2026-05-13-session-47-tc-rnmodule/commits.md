# Session 47 commits

- 3a881a0 Session 47: probe47
  hooks 4 points inside `tcRnModuleTcRnM` in
  `compiler/GHC/Tc/Module.hs`: `after_tcRnImports`,
  `after_tcRnSrcDecls`, `after_checkHiBootIface`, and
  `tcRnModuleTcRnM_exit`.  All log `lengthBag (tcg_binds tc_env)`.

  **Findings:**

  | env-len | imports | **srcDecls** | bootIface | exit | outcome |
  |---------|---------|--------------|-----------|------|---------|
  | clean   | 0       | **9**        | 9         | 9    | proper  |
  | 600     | 0       | **5**        | 5         | 5    | panic   |
  | 1650    | 0       | **2**        | 2         | 2    | silent miscompile |

  **`tcRnSrcDecls` is where the truncation happens.**  Before
  it, tcg_binds is 0 (empty).  After it, tcg_binds is 9 (clean)
  or 2-5 (failing).  Subsequent steps preserve the count.

  Pipeline progress chain across sessions 42-47:
  - S42: simplTopBinds entry = 0-1 binders.
  - S43: core2core entry = 1-3.
  - S44: deSugar final_prs = 3-6.
  - S45: deSugar tcg_binds entry = 3-6.
  - S46: hsc_typecheck_exit = 3-5.
  - **S47: tcRnSrcDecls output = 2-5.**

  `tcRnSrcDecls` (line ~461 of `GHC.Tc.Module`) is the main
  typechecker pass.  Its body has many sub-steps:
  `tc_rn_src_decls`, `simplifyTop`, `zonkTopDecls`, etc.  Next
  session should drill inside to pinpoint the specific
  truncating sub-function.

  v0.12.0 ships unchanged; probe applied for measurement only
  and reverted at session end; stage2 on pmacg5
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  (flaky as noted in S46).

  Session 47 HANDOFF.md scopes probe48: drill inside
  `tcRnSrcDecls` to identify which sub-step truncates the
  binders list.
