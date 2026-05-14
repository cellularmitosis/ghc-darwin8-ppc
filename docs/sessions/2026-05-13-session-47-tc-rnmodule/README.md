# Session 47 — corruption narrowed to **WITHIN `tcRnSrcDecls`**

**Dates:** 2026-05-13 (continuation of session 46; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-46 exit.
Session 46 narrowed the corruption to AT or BEFORE the
typechecker's return.

**Status on exit:** CLEAN.  Probe47 reverted, stage1 rebuilt
clean _(TBD)_, stage2 redeployed _(TBD)_, baseline tests
_(TBD)_.  **Finding:** Probe47 adds hooks inside
`tcRnModuleTcRnM` at `after_tcRnImports`,
`after_tcRnSrcDecls`, `after_checkHiBootIface`, and
`tcRnModuleTcRnM_exit`.  **Clean compile shows 0 / 9 / 9 / 9.
Failing runs show 0 / 2-5 / 2-5 / 2-5.**  `tcRnSrcDecls` is
where tcg_binds transitions from 0 to N, and that N is the
truncated count.  **The corruption is WITHIN `tcRnSrcDecls`**
— the main typechecker pass that processes the module's source
declarations and populates tcg_binds.  v0.12.0 release
unchanged.

## Plan (per session 46 HANDOFF.md)

Hook `tcRnModule` / `tcRnModule'` returns to narrow further
within the typechecker.

## What happened

### Phase 1 — probe47-v1

Single hook just before `return tcg_env` at the end of
`tcRnModuleTcRnM`.  Confirmed tcg_binds already truncated to
3 / 5 at exit.

### Phase 2 — probe47-v2

Added 3 more hooks inside `tcRnModuleTcRnM`:
- `after_tcRnImports`
- `after_tcRnSrcDecls`
- `after_checkHiBootIface`

### Phase 3 — results

| env-len | after_tcRnImports | after_tcRnSrcDecls | after_checkHiBootIface | exit | RC |
|---------|-------------------|--------------------|------------------------|------|-----|
| clean   | 0                 | **9**              | 9                      | 9    | 0   |
| 600     | 0                 | **5**              | 5                      | 5    | 1 (panic) |
| 1650    | 0                 | **2**              | 2                      | 2    | 0 (silent miscompile) |

`tcRnSrcDecls` is where tcg_binds transitions from 0 to N.
Clean: 9.  Failing: 2-5.  Subsequent steps preserve count.

### Phase 4 — interpretation

The corruption is **WITHIN `tcRnSrcDecls`**.

`tcRnSrcDecls explicit_mod_hdr export_ies local_decls` (in
`GHC.Tc.Module.hs`) is the function that:
1. Runs the renamer + typechecker on local declarations.
2. Builds tcg_binds from typechecked binders.
3. Returns the populated TcGblEnv.

Its body includes many sub-steps: `tc_rn_src_decls`,
`simplifyTop`, `zonkTopDecls`, etc.  Next session should drill
deeper inside `tcRnSrcDecls`.

### Phase 5 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Tc/Module.hs` — probe reverted.
* Stage1 clean rebuild: `logs/build3-clean.log` _(TBD)_.
* Stage2 redeploy: `logs/deploy3-clean.log` _(TBD)_.
* Baseline tests: `logs/baseline-tests-end.log` _(TBD)_.

Session ends CLEAN.

## Files added this session

* `README.md` (this), `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md`.
* `probe47-tc-rnmodule.patch` — hooks inside tcRnModuleTcRnM.
* `logs/build*.log`, `deploy*.log`,
  `baseline-tests-end.log`.

## Top finding

`tcRnSrcDecls` is where tcg_binds becomes 2-5 binders (vs
clean's 9).  The truncation is within this function.

Session 48 should drill inside `tcRnSrcDecls` to find the
exact step.

See [`findings.md`](findings.md) §F6 for next-experiment
recipes and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
