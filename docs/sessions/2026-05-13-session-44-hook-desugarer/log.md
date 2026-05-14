# Session 44 — real-time log

## Pickup

Session 43 narrowed the truncation locus to BEFORE `core2core`
entry.  Session 44 hooks the desugarer's output to determine
whether the truncation is IN the desugarer or in HscMain
bridge code.

## Step 1 — find deSugar's return point

`compiler/GHC/HsToCore.hs::deSugar` constructs `mod_guts` near
the end of its main do-block and returns
`(msgs, Just mod_guts)`.  `mg_binds = ds_binds` where
`ds_binds` comes from `simpleOptPgm`'s output.  `simpleOptPgm`
receives `final_pgm = combineEvBinds ds_ev_binds final_prs`
and `final_prs` is the desugarer's main output.

## Step 2 — design probe44

Log three lengths just before `return (msgs, Just mod_guts)`:

- `final_prs` (desugarer output, pre-simpleOptPgm)
- `ds_binds` (post-simpleOptPgm)
- `mg_binds` (final field in ModGuts)

Helper defined inline in HsToCore.hs (Simplify.Env couldn't
be imported without circular dependency).

## Step 3 — build attempts

v1 build failed: put `import` lines AFTER function definitions
(illegal in Haskell — all imports must precede definitions).
Fixed by moving the helper definition to after the import
block (around line 94-120).

v1.1 build (~6m): EXIT=0.

## Step 4 — deploy + trigger

Deploy: EXIT=0, smoke-test PASS.

### Clean compile (-A256m)

```
PROBE44-DESUGAR-RETURN evt=1 final_prs=9 ds_binds=9 mg_binds=9
RC=0
```

All three lengths are 9.  simpleOptPgm preserves all binders.

### Failing -A1m -G1 len=600

```
PROBE44-DESUGAR-RETURN evt=1 final_prs=3 ds_binds=0 mg_binds=0
RC=0
```

**final_prs=3** — already truncated from 9 to 3 in the
desugarer.
**ds_binds=0** — simpleOptPgm dropped all 3 to 0 (DCE).
**mg_binds=0** — ModGuts stored 0 binders → silent miscompile.

### Failing -A1m -G1 len=850

```
PROBE44-DESUGAR-RETURN evt=1 final_prs=6 ds_binds=4 mg_binds=4
ghc-real: panic! refineFromInScope
RC=1
```

final_prs=6, simpleOptPgm dropped 2 to 4, then panic.

### Failing -A1m -G1 len=1650

```
PROBE44-DESUGAR-RETURN evt=1 final_prs=5 ds_binds=3 mg_binds=3
ghc-real: panic! refineFromInScope
RC=1
```

final_prs=5, simpleOptPgm dropped 2 to 3, then panic.

## Step 5 — interpretation

**Key finding: `final_prs` is already truncated in failing
runs.**  The corruption happens WITHIN OR BEFORE the
desugarer's main `initDs` block.

Pipeline within `deSugar`:
1. `addTicksToBinds binds → binds_cvr` (coverage instrumentation).
2. `dsTopLHsBinds binds_cvr → core_prs` (main desugaring).
3. `patchMagicDefns`, `dsImpSpecs`, `dsForeigns`, `dsRule`
   (smaller-output desugarings).
4. `core_prs ++ spec_prs ++ foreign_prs → all_prs` (concat).
5. `addExportFlagsAndRules ... (fromOL all_prs) → final_prs`.

If `final_prs` is 3-6 (vs clean's 9), the truncation happened
somewhere in steps 1-5.  Most likely candidates:

- (a) `tcg_binds` (typechecker output) was already truncated
  going INTO deSugar.
- (b) `addTicksToBinds` truncated `binds → binds_cvr`.
- (c) `dsTopLHsBinds` truncated its output.
- (d) `appOL` or `fromOL` (OrdList operations) corrupted.
- (e) GC corrupted any of the heap-allocated lists in transit.

`simpleOptPgm` then DCE's the broken input further.

## Step 6 — silent miscompile mechanism

At len=600: final_prs=3 → ds_binds=0 → mg_binds=0.
ModGuts contains 0 binders.  core2core processes 0 binders
(probe43 confirmed).  Codegen produces empty .o.  ghc-real
exits RC=0.

The user sees an apparently-successful compile and an empty
.o file.  Silent miscompile traced to its source: the
desugarer's output was already truncated, and `simpleOptPgm`
+ codegen happily processed the (empty) result.

## Step 7 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/HsToCore.hs` — probe reverted.
* Stage1 clean rebuild: `logs/build2-clean.log`.
* (next) Stage2 redeploy + smoke-test.
* (next) Baseline tests.

Session ends CLEAN with the desugarer-localization captured.
