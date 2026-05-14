# Session 47 — real-time log

## Pickup

Session 46 narrowed the truncation to AT or BEFORE the
typechecker's `return`.  Session 47 hooks inside the
typechecker proper (`tcRnModule` → `tcRnModuleTcRnM`).

## Step 1 — locate hooks in Tc.Module

`tcRnModule` is the outer driver; calls `tcRnModuleTcRnM`
through `initTc ... withTcPlugins ...`.

`tcRnModuleTcRnM` is the actual typecheck driver with all the
phases: tcRnImports, tcRnSrcDecls, checkHiBootIface,
reportUnusedNames, runTypecheckerPlugin, etc.

## Step 2 — probe47-v1: hook tcRnModuleTcRnM exit only

Single hook just before `return tcg_env` at line 343.  Build
(~6m, EXIT=0), deploy.

Result:
```
clean:    tcRnModuleTcRnM_exit n=9
600:      tcRnModuleTcRnM_exit n=3 → panic
1650:     tcRnModuleTcRnM_exit n=5 → panic
```

Corruption is INSIDE tcRnModuleTcRnM.  Need to narrow further.

## Step 3 — probe47-v2: add 3 more hooks

Added hooks at:
- `after_tcRnImports` (line 305+)
- `after_tcRnSrcDecls` (line 336+)
- `after_checkHiBootIface` (line 344+)

Build (~6m, EXIT=0), deploy.

## Step 4 — v2 triggers

```
=== clean (-A256m) ===
PROBE47-TC evt=1 site=after_tcRnImports n=0
PROBE47-TC evt=2 site=after_tcRnSrcDecls n=9
PROBE47-TC evt=3 site=after_checkHiBootIface n=9
PROBE47-TC evt=4 site=tcRnModuleTcRnM_exit n=9
RC=0

=== failing len=600 ===
PROBE47-TC evt=1 site=after_tcRnImports n=0
PROBE47-TC evt=2 site=after_tcRnSrcDecls n=5
PROBE47-TC evt=3 site=after_checkHiBootIface n=5
PROBE47-TC evt=4 site=tcRnModuleTcRnM_exit n=5
panic, RC=1

=== failing len=1650 ===
PROBE47-TC evt=1 site=after_tcRnImports n=0
PROBE47-TC evt=2 site=after_tcRnSrcDecls n=2
PROBE47-TC evt=3 site=after_checkHiBootIface n=2
PROBE47-TC evt=4 site=tcRnModuleTcRnM_exit n=2
RC=0
```

## Step 5 — interpretation

- `after_tcRnImports` is always 0.  tcRnImports doesn't add to
  tcg_binds.
- `after_tcRnSrcDecls` is where tcg_binds becomes N.  Clean: 9.
  Failing: 2-5.
- Subsequent steps preserve count.

**The corruption is WITHIN `tcRnSrcDecls`.**

Also note: len=1650 with v2 shows RC=0 (silent miscompile)
with only 2 binders.  Heap shift from v2's added code put us
in a new failure mode.

## Step 6 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Tc/Module.hs` — probe reverted.
* Stage1 clean rebuild: `logs/build3-clean.log`.
* (next) Stage2 redeploy + smoke-test.
* (next) Baseline tests.

Session ends CLEAN with corruption narrowed to inside
`tcRnSrcDecls`.
