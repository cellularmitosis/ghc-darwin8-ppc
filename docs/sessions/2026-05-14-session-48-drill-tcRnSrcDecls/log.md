# Session 48 — real-time log

## Pickup

Session 47 narrowed the truncation to WITHIN `tcRnSrcDecls`.
Session 48 drills inside `tcRnSrcDecls` and its sub-functions
(`tc_rn_src_decls`, `mkTypeableBinds`, `zonkTcGblEnv`, ...)
to pinpoint the specific sub-step that produces the truncated
count.

## Step 1 — locate hooks inside `tcRnSrcDecls`

`tcRnSrcDecls` is at line 461 of
`compiler/GHC/Tc/Module.hs`.  Body sequence:

1. `tc_rn_src_decls decls` — the typechecker proper.
2. `setEnvs (tcg_env, tcl_env) $ do { ... simplifyTop ... }` —
   constraint solver.
3. `setGblEnv tcg_env $ mkTypeableBinds` — synthesize Typeable
   binding(s).
4. `zonkTcGblEnv new_ev_binds tcg_env` — zonk final
   substitution.
5. Construct final `tcg_env'` with merged module-finalizers
   binds.

## Step 2 — probe48-v1: hook only `after_tc_rn_src_decls`

Single hook right after `tc_rn_src_decls` returns.  Build
(~7m, EXIT=0), deploy, trigger.  Confirmed `tc_rn_src_decls`
already produces 2 (failing) vs 8 (clean) binders.

## Step 3 — probe48-v2: hook 3 more steps

Added `after_mkTypeableBinds`,
`after_zonkTcGblEnv_binds_prime`, `tcg_env_prime_final`, and
`binds_mf_after_zonk_main`.  Build, deploy, trigger:

```
clean   : tc_rn_src_decls=8 mkType=9 zonk=9 final=9
600     : tc_rn_src_decls=2 mkType=3 zonk=3 final=3
1650    : tc_rn_src_decls=2 mkType=3 zonk=3 final=3
```

`mkTypeableBinds` adds exactly 1.  All other steps preserve
count.

## Step 4 — probe48-v2.5: hook inside `tc_rn_src_decls`

Added `after_rnTopSrcDecls`, `after_tcTopSrcDecls` to split
the renamer vs typechecker phases.  Build, deploy, trigger:

```
clean   : rnTop=0 tcTop=8 tc_rn=8
600     : rnTop=0 tcTop=2 tc_rn=2
1650    : rnTop=0 tcTop=2 tc_rn=2
```

`rnTopSrcDecls` (renamer) produces 0 binders.
**`tcTopSrcDecls` (typechecker) is where binders count becomes 2/8.**

## Step 5 — probe48-v3: hook inside `tcTopSrcDecls`

Added 3 more hooks inside `tcTopSrcDecls`:
- `after_tcTyClsInstDecls`
- `after_tcTopBinds_val_binds`
- `after_tcTopBinds_deriv_binds`

Build (~7m, EXIT=0).  First deploy was interrupted at step
[1/5] of `deploy-stage2.sh` — the deploy log only shows the
cross-compile line and no transfer.  The binary on pmacg5
remained the v2.5 version (mtime 01:14).  Re-ran
`deploy-stage2.sh pmacg5` and it completed all 5 steps;
smoke-test PASS; new binary mtime 01:38; `strings` confirms
`after_tcTyClsInstDecls`, `after_tcTopBinds_val_binds`, and
`after_tcTopBinds_deriv_binds` are now in the binary.

## Step 6 — v3 triggers (after correct redeploy)

```
=== clean (-A256m) ===
evt=1 after_rnTopSrcDecls               n=0
evt=2 after_tcTyClsInstDecls            n=0
evt=3 after_tcTopBinds_val_binds        n=8
evt=4 after_tcTopBinds_deriv_binds      n=8
evt=5 after_tcTopSrcDecls               n=8
evt=6 after_tc_rn_src_decls             n=8
evt=7 after_mkTypeableBinds             n=9
evt=8 after_zonkTcGblEnv_binds_prime    n=9
evt=9 tcg_env_prime_final               n=9
evt=10 binds_mf_after_zonk_main         n=0
RC=0

=== failing len=600 ===
evt=1 after_rnTopSrcDecls               n=0
evt=2 after_tcTyClsInstDecls            n=0
evt=3 after_tcTopBinds_val_binds        n=2
evt=4 after_tcTopBinds_deriv_binds      n=2
evt=5 after_tcTopSrcDecls               n=2
evt=6 after_tc_rn_src_decls             n=2
evt=7 after_mkTypeableBinds             n=3
evt=8 after_zonkTcGblEnv_binds_prime    n=3
evt=9 tcg_env_prime_final               n=3
evt=10 binds_mf_after_zonk_main         n=0
RC=0   ← silent miscompile

=== failing len=1650 ===
evt=1 after_rnTopSrcDecls               n=0
evt=2 after_tcTyClsInstDecls            n=0
evt=3 after_tcTopBinds_val_binds        n=3
evt=4 after_tcTopBinds_deriv_binds      n=3
evt=5 after_tcTopSrcDecls               n=3
evt=6 after_tc_rn_src_decls             n=3
evt=7 after_mkTypeableBinds             n=4
evt=8 after_zonkTcGblEnv_binds_prime    n=4
evt=9 tcg_env_prime_final               n=4
evt=10 binds_mf_after_zonk_main         n=0
RC=0   ← silent miscompile
```

## Step 7 — interpretation

- evt=1 (`rnTopSrcDecls`) = 0 always — renamer doesn't
  populate `tcg_binds`.
- evt=2 (`tcTyClsInstDecls`) = 0 always — no class/instance
  decls in Big2.hs.
- **evt=3 (`tcTopBinds val_binds val_sigs`) = 8 vs 2/3** —
  this is the step that goes 0 → N, and it short-counts in
  failing runs.
- evt=4..10 all preserve the count (modulo +1 from
  `mkTypeableBinds`).

**The truncation is INSIDE `tcTopBinds val_binds val_sigs`**
(defined in `compiler/GHC/Tc/Gen/Bind.hs`).

## Step 8 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Tc/Module.hs` — probe48
  reverted; working tree clean.
* Stage1 clean rebuild: `logs/build4-clean.log` (~6m50s,
  EXIT=0).
* Stage2 redeploy: `logs/deploy4-clean.log` (smoke-test PASS,
  new binary mtime 01:51, `strings` shows no PROBE48
  markers).
* Baseline tests: `logs/baseline-tests-end.log` — 30 PASS,
  4 FAIL_OUTPUT (same known-flaky 32-bit Int / getProgName /
  getpid mismatches as session 47).

## Continuation handoff (mid-session)

Mid-session, the conversation context was nearly full; we
wrote `CONTINUATION.md` to hand off to the next claude
conversation inside the same session.  The next conversation
re-deployed v3 (the first deploy was interrupted), ran the
v3 trigger, did the revert / rebuild / redeploy / baseline,
and wrote these docs.

Session ends CLEAN with corruption narrowed to inside
`tcTopBinds val_binds val_sigs` in `GHC.Tc.Gen.Bind`.
