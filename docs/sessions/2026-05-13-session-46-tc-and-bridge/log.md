# Session 46 — real-time log

## Pickup

Session 45 ruled the desugarer INNOCENT.  tcg_binds is already
truncated when deSugar receives it.  Session 46 hooks the
typechecker output and HscMain's bridge.

## Step 1 — locate hooks

`compiler/GHC/Driver/Main.hs`:
- `hsc_typecheck` (line 565+) is the typechecker driver; returns
  `(tc_result, rn_info)`.
- `hscDesugar` (line 658) wraps `hscDesugar'`.
- `hscDesugar'` (line 662) calls `deSugar`.

## Step 2 — design probe46

Inline helper in Driver/Main.hs.  3 hook points logging
`lengthBag (tcg_binds tc_env)`.

Imports added: `tcg_binds` from `GHC.Tc.Types`,
`hPutStrLn`/`stderr`/`hFlush` from System.IO,
`unsafePerformIO` from System.IO.Unsafe.

## Step 3 — build + deploy

Build (~6m, EXIT=0).  Deploy (~6m, EXIT=0).

## Step 4 — triggers

```
=== clean (-A256m) ===
PROBE46-TCGBINDS evt=1 site=hsc_typecheck_exit n=9
PROBE46-TCGBINDS evt=2 site=hscDesugarPrime_entry n=9
RC=0

=== failing len=600 ===
PROBE46-TCGBINDS evt=1 site=hsc_typecheck_exit n=3
PROBE46-TCGBINDS evt=2 site=hscDesugarPrime_entry n=3
panic
RC=1

=== failing len=1650 ===
PROBE46-TCGBINDS evt=1 site=hsc_typecheck_exit n=5
PROBE46-TCGBINDS evt=2 site=hscDesugarPrime_entry n=5
panic
RC=1
```

## Step 5 — observations

1. **`hsc_typecheck_exit` is already truncated.**  Clean=9,
   failing=3-5.
2. **`hscDesugar'_entry` preserves the count.**  Same count
   between exit and entry.
3. **`hscDesugar_entry` never fires.**  Big2.hs's path uses
   `hscDesugar'` directly (probably via
   `hscIncrementalCompile`), not `hscDesugar`.

The corruption is AT or BEFORE `hsc_typecheck`'s return.
Inside `hsc_typecheck` for a normal `.hs` file, the path is:

```
hpm <- hscParse'
tc_result0 <- tcRnModule' mod_summary keep_rn' hpm
let tc_result = tc_result0
rn_info <- extract_renamed_stuff mod_summary tc_result
return (tc_result, rn_info)
```

`tcRnModule'` is the renamer + typechecker driver.  The
corruption is within it or in GC during it.

## Step 6 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Driver/Main.hs` — probe
  reverted.
* Stage1 clean rebuild: `logs/build2-clean.log`.
* (next) Stage2 redeploy + smoke-test.
* (next) Baseline tests.

Session ends CLEAN with corruption localized to within
`tcRnModule'`.
