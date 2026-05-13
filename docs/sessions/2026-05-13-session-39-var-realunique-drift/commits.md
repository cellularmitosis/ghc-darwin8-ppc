# Session 39 commits

- e695771 Session 39: probe39
  (a sentinel-Var IORef tracker in
  `compiler/GHC/Core/Opt/Simplify/Env.hs`) directly tests
  session 38's hypothesis that GC corrupts the
  `realUnique :: FastInt#` field of Var heap closures on PPC32
  unreg.  The probe registers the first `$d*`-named Var seen in
  `subst_id_bndr`, stashes it in an IORef (keeping it live
  across GC), and at every subsequent `refineFromInScope` call
  re-reads its `varUnique v` via GHC's Haskell-level accessor
  to detect any drift.  Three iterations: v1 (hardcoded OccName
  filter) registered nothing (wrong target names); v2 (broadened
  filter to any `$d`-prefixed Name, also hooked subst_id_bndr in
  addition to addNewInScopeIds) registered `$dOrd_a1k0` at
  len=850 and showed `u_via_haskell = 0x610013f7` stable across
  4 refineFromInScope checks (the raw word[2] peek differed
  because anyToAddr# returns a wrapping-thunk address, not the
  Id closure — the session-37 lesson resurfaced); v3 dropped the
  misleading raw-peek check and emitted PROBE39-DRIFT only on
  Haskell-level drift.  Fine sweep with v3 (env-lens 600..2000
  step 25) showed: in every FAILING run, `sentinel=none` because
  the panic fires before `subst_id_bndr` is called with any
  `$d*` Var; in the single SUCCEEDING compile that registered
  the sentinel, varUnique was stable.  **Session 38's "GC
  corrupts realUnique" hypothesis is disproven.**  The remaining
  hypothesis: two distinct Var heap closures exist with the same
  OccName "$dOrd_a1k0" but different Uniques, created upstream
  of the simplifier (likely in the typechecker / desugarer /
  specializer / interface deserializer).  v0.12.0 ships unchanged;
  probe applied for measurement and reverted at session end;
  stage2 on pmacg5 rebuilt+redeployed clean + smoke-test PASS +
  baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).
