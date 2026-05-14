# Session 48 — corruption narrowed to **INSIDE `tcTopBinds val_binds val_sigs`**

**Dates:** 2026-05-14 (continuation of session 47; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-47 exit.
Session 47 narrowed the corruption to WITHIN `tcRnSrcDecls`
(the main typechecker pass that builds `tcg_binds` from the
local declarations).

**Status on exit:** CLEAN.  Probe48 reverted, stage1 rebuilt
clean, stage2 redeployed, smoke-test PASS, baseline tests run.
**Finding:** Probe48-v3 adds 10 hooks across `tcRnSrcDecls`,
`tc_rn_src_decls`, and (crucially) `tcTopSrcDecls`.  **Clean
compile shows the count is 8 right after `tcTopBinds val_binds
val_sigs` (the value-binding typecheck pass).  Failing runs
show 2-3 at that same point** — every subsequent step inside
the typechecker preserves the count.  **The corruption is
inside `tcTopBinds val_binds val_sigs` itself** — the function
in `GHC.Tc.Gen.Bind` that typechecks the module's top-level
value bindings.  v0.12.0 release unchanged.

## Plan (per session 47 HANDOFF.md)

Hook the major sub-steps inside `tcRnSrcDecls` (which is
defined around line 461 of `compiler/GHC/Tc/Module.hs`).
Major sub-steps: `tc_rn_src_decls`, `mkTypeableBinds`,
`zonkTcGblEnv`, etc.  Narrow further by drilling into
`tcTopSrcDecls` if needed.

## What happened

### Phase 1 — probe48-v1

Single hook at the end of `tcRnSrcDecls`
(`after_tc_rn_src_decls`).  Build (~7m, EXIT=0), deploy.
Confirmed the count is already 2-3 at the end of
`tcRnSrcDecls`'s top-level work in failing runs.

### Phase 2 — probe48-v2

Added 3 more hooks inside `tcRnSrcDecls`:
- `after_mkTypeableBinds` — after Typeable bindings are added.
- `after_zonkTcGblEnv_binds_prime` — after zonking the env.
- `tcg_env_prime_final` — at the final TcGblEnv construction.

Result (count at each hook):

| env-len | `tc_rn_src_decls` | `mkTypeable` | `zonk binds'` | `tcg_env'_final` |
|---------|--------------------|---------------|----------------|-------------------|
| clean   | 8                  | 9             | 9              | 9                 |
| 600     | 2                  | 3             | 3              | 3                 |
| 1650    | 2                  | 3             | 3              | 3                 |

`tc_rn_src_decls` itself produces 2-8 binders; `mkTypeableBinds`
adds exactly 1 (the module's `$trModule`).  All downstream
steps preserve count.

### Phase 3 — probe48-v2.5 (add rn/tc split hooks)

Added 2 more hooks inside `tc_rn_src_decls`:
- `after_rnTopSrcDecls` — after the renamer.
- `after_tcTopSrcDecls` — after the typechecker.

Result:

| env-len | `rnTopSrcDecls` | **`tcTopSrcDecls`** | `tc_rn_src_decls` |
|---------|-------------------|----------------------|---------------------|
| clean   | 0                 | **8**                | 8                   |
| 600     | 0                 | **2**                | 2                   |
| 1650    | 0                 | **2**                | 2                   |

`rnTopSrcDecls` (the renamer) returns 0 binders — it doesn't
populate `tcg_binds`.  **`tcTopSrcDecls` (the typechecker) is
where the count becomes 2/8** — and stays there for the rest
of the pipeline.

### Phase 4 — probe48-v3 (drill `tcTopSrcDecls`'s sub-steps)

Added 3 more hooks INSIDE `tcTopSrcDecls`:
- `after_tcTyClsInstDecls` — after type/class/instance decls.
- `after_tcTopBinds_val_binds` — after value-binding typecheck.
- `after_tcTopBinds_deriv_binds` — after derived-binding typecheck.

Result (all 10 hooks in evt order):

| evt | site                                | clean | len=600 | len=1650 |
|-----|--------------------------------------|-------|---------|----------|
| 1   | `after_rnTopSrcDecls`                | 0     | 0       | 0        |
| 2   | `after_tcTyClsInstDecls`             | 0     | 0       | 0        |
| 3   | **`after_tcTopBinds_val_binds`**     | **8** | **2**   | **3**    |
| 4   | `after_tcTopBinds_deriv_binds`       | 8     | 2       | 3        |
| 5   | `after_tcTopSrcDecls`                | 8     | 2       | 3        |
| 6   | `after_tc_rn_src_decls`              | 8     | 2       | 3        |
| 7   | `after_mkTypeableBinds`              | 9     | 3       | 4        |
| 8   | `after_zonkTcGblEnv_binds_prime`     | 9     | 3       | 4        |
| 9   | `tcg_env_prime_final`                | 9     | 3       | 4        |
| 10  | `binds_mf_after_zonk_main`           | 0     | 0       | 0        |

All three len=600/1650 runs `RC=0` (silent miscompile).

**Localization (decision-tree match):**
- `after_tcTyClsInstDecls` is 0 in both clean and failing
  (it handles type/class/instance decls, not value bindings,
  so this is expected).
- **`after_tcTopBinds_val_binds` is 8 in clean but 2/3 in
  failing.**  The initial count was 0 (from
  `tcTyClsInstDecls`).  `tcTopBinds val_binds val_sigs` is the
  step that ADDS the binders — and in failing runs it adds
  fewer than 8.
- `after_tcTopBinds_deriv_binds` preserves the count (no
  derived bindings in `Big2.hs`).
- All subsequent steps preserve the count.

### Phase 5 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Tc/Module.hs` — probe reverted.
* Stage1 clean rebuild: `logs/build4-clean.log`.
* Stage2 redeploy: `logs/deploy4-clean.log` (smoke-test PASS).
* Baseline tests: `logs/baseline-tests-end.log`.

Session ends CLEAN.

## Files added this session

* `README.md` (this), `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md`, `CONTINUATION.md` (mid-session handoff).
* `probe48-tcRnSrcDecls.patch` — final v3 patch (cumulative;
  10 hook sites across `tcRnSrcDecls` / `tc_rn_src_decls` /
  `tcTopSrcDecls`).
* `logs/build1-probe48.log` (v1), `build2-probe48v2.log` (v2),
  `build3-probe48v3.log` (v2.5+v3), `build4-clean.log`
  (revert).
* `logs/deploy1-probe48.log`, `deploy2-probe48v2.log`,
  `deploy3-probe48v3.log` (interrupted),
  `deploy3-probe48v3-redo.log` (re-run that actually shipped
  v3), `deploy4-clean.log`.
* `logs/v3-triggers.log` — the 10-event trigger run.
* `logs/baseline-tests-end.log`.

## Top finding

**`tcTopBinds val_binds val_sigs`** (in `GHC.Tc.Gen.Bind`) is
where `tcg_binds` becomes 2-3 binders in failing runs vs 8 in
clean runs.  Before this call, the count is 0 (from
`tcTyClsInstDecls`).  After this call, the count is the
truncated value, and every subsequent typechecker / desugarer /
simplifier / codegen step preserves whatever count
`tcTopBinds` produced.

Session 49 should drill inside `tcTopBinds` to find the exact
loop / fold / recursion step where the binder count is
short-counted.

See [`findings.md`](findings.md) §F8 for next-experiment
recipes and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
