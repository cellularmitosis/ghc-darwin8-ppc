# Session 45 — real-time log

## Pickup

Session 44 narrowed the truncation locus to WITHIN or BEFORE
the desugarer (final_prs is 3-6 in failing runs).  Session 45
hooks more granularly inside deSugar to pinpoint WHICH step
truncates the list.

## Step 1 — probe45 design

7 hooks inside `deSugar`:

1. `tcg_binds` (input from TcGblEnv) — `lengthBag binds`.
2. `binds_cvr` (after addTicksToBinds) — `lengthBag binds_cvr`.
3. `core_prs_initial` (after dsTopLHsBinds) —
   `length (fromOL core_prs)`.
4. `core_prs_patched` (after patchMagicDefns) —
   `length (fromOL core_prs)`.
5. `all_prs_in_initDs` (after concatOL inside initDs).
6. `all_prs_outside_initDs` (after initDs's case unpack).
7. `final_prs` (after addExportFlagsAndRules).

Helper inline in HsToCore.hs.  `lengthBag` imported from
`GHC.Data.Bag`.

## Step 2 — build + deploy

Build (~6m, EXIT=0).  Deploy (~6m, EXIT=0).

## Step 3 — triggers

### Clean compile (-A256m)
```
PROBE45-STEP tcg_binds n=9
PROBE45-STEP binds_cvr n=9
PROBE45-STEP core_prs_initial n=9
PROBE45-STEP core_prs_patched n=9
PROBE45-STEP all_prs_in_initDs n=9
PROBE45-STEP all_prs_outside_initDs n=9
PROBE45-STEP final_prs n=9
RC=0
```

### Failing len=600
```
PROBE45-STEP tcg_binds n=3
... (all = 3)
PROBE45-STEP final_prs n=3
panic
RC=1
```

### Failing len=850
```
PROBE45-STEP tcg_binds n=6
... (all = 6)
PROBE45-STEP final_prs n=6
RC=0
```

### Failing len=1650
```
PROBE45-STEP tcg_binds n=5
... (all = 5)
PROBE45-STEP final_prs n=5
panic
RC=1
```

## Step 4 — analysis

**Every step preserves the count exactly.**  The desugarer is
INNOCENT.  Whatever `tcg_binds` arrives as, that's what
`final_prs` produces.

The truncation has ALREADY happened by the time deSugar is
called.  The corruption is in:
- The typechecker's output construction of TcGblEnv.tcg_binds.
- HscMain's bridging code between typechecker and deSugar.
- GC corruption of the heap-allocated Bag during transit.

## Step 5 — Bag.TwoBags is also CONSTR_2_0

`Bag a` has a `TwoBags (Bag a) (Bag a)` constructor — a
CONSTR_2_0 closure (2 pointer fields).  This is structurally
similar to `[a]` cons cells (`:` is also CONSTR_2_0).

Both `[InBind]` cons cells and `Bag (LHsBindLR GhcTc GhcTc)`
TwoBags closures could be affected by the same GC bug.

## Step 6 — heap-layout sensitivity at probe45

At len=850 with probe45 deployed: RC=0 (clean compile, 6
binders).  Session 44 saw RC=1 panic at len=850.  Heap shift
from added probe code changed the panic-vs-success outcome
even though the binders count is similar (6 here vs 6 in
session 44).

This reinforces the GC-pressure-sensitivity: tiny changes in
heap layout shift the bug between manifestations.

## Step 7 — revert + clean rebuild + redeploy + baseline

- `git checkout -- compiler/GHC/HsToCore.hs` — probe reverted.
- Stage1 clean rebuild: `logs/build2-clean.log`.
- (next) Stage2 redeploy + smoke-test.
- (next) Baseline tests.

Session ends CLEAN with the narrowed-down localization.
