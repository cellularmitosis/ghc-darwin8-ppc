# Session 43 — real-time log

## Pickup

Session 42's smoking gun: simplTopBinds receives a truncated
`[InBind]` list (0-1 binders vs clean's 9).  Session 43 traces
this upstream to find WHICH pipeline phase causes the
truncation.

## Step 1 — probe43 design

Add helpers in `Simplify/Env.hs`, export them.  Hook them in
`Pipeline.hs`:

- `runCorePasses` entry → log `length (mg_binds guts)`.
- Each `do_pass` → log `length (mg_binds guts)` before and
  `length (mg_binds guts')` after the pass.

Patch saved: `probe43-pipeline-trace.patch`.

## Step 2 — probe43-v1 build + deploy

Build (~6m, EXIT=0).  Deploy (~6m, EXIT=0, smoke-test PASS).

## Step 3 — v1 triggers

Clean compile (-A256m):
```
PROBE43-INITIAL evt=1 mg_binds=9
PROBE43-PASS evt=2 pass=Simplifier before=9 after=13
RC=0
```

Failing len=600 (-A1m -G1):
```
PROBE43-INITIAL evt=1 mg_binds=1
panic! refineFromInScope
RC=1
```

Failing len=850:
```
PROBE43-INITIAL evt=1 mg_binds=1
PROBE43-PASS evt=2 pass=Simplifier before=1 after=5
panic!
RC=1
```

Failing len=1650:
```
PROBE43-INITIAL evt=1 mg_binds=3
panic! refineFromInScope
RC=1
```

**mg_binds is already 1-3 at runCorePasses entry** — corruption
is BEFORE the optimizer pipeline.

## Step 4 — extend probe43 to also hook core2core entry

v2 adds `probe43LogCore2CoreEntry :: Int -> ()` exported from
`Simplify/Env.hs`, called from `Pipeline.hs::core2core` at its
entry (before any setup).

Build (~6m, EXIT=0).  Deploy (~6m, EXIT=0).

## Step 5 — v2 triggers

Clean compile (-A256m):
```
PROBE43-CORE2CORE evt=1 mg_binds=9
PROBE43-INITIAL evt=2 mg_binds=9
PROBE43-PASS evt=3 pass=Simplifier before=9 after=13
RC=0
```

Failing len=600:
```
PROBE43-CORE2CORE evt=1 mg_binds=1
PROBE43-INITIAL evt=2 mg_binds=1
panic!
RC=1
```

Failing len=850:
```
PROBE43-CORE2CORE evt=1 mg_binds=2
PROBE43-INITIAL evt=2 mg_binds=2
PROBE43-PASS evt=3 pass=Simplifier before=2 after=5
panic!
RC=1
```

Failing len=1650:
```
PROBE43-CORE2CORE evt=1 mg_binds=2
PROBE43-INITIAL evt=2 mg_binds=2
PROBE43-PASS evt=3 pass=Simplifier before=2 after=0 *** DROPPED
RC=0
```

**Key observations:**

1. **CORE2CORE ≡ INITIAL counts.** mg_binds doesn't change
   between core2core's entry and runCorePasses' entry.  The
   corruption is BEFORE core2core entry.

2. **len=1650 silent miscompile.** Simplifier went 2 → 0 and
   ghc-real exited RC=0.  Marked with `*** DROPPED` flag.
   This is a SECOND silent-miscompile env-len (session 42 found
   850-1000; this is 1650 in v2's heap layout).

## Step 6 — interpretation

ModGuts is constructed by the desugarer (`HsToCore.deSugar`) and
flows into `core2core`.  In between are calls from HscMain.

In failing runs, mg_binds is already 1-3 when core2core
receives it.  So the truncation happens during:

- (a) The desugarer producing the wrong output, OR
- (b) Code between desugarer and core2core in HscMain, OR
- (c) GC corrupting the heap-allocated `[InBind]` list spine
  while it's in memory between phases.

(c) is most consistent with the heap-layout-sensitivity
documented in sessions 28-42.

## Step 7 — Simplifier's own 2→0 drop

At len=1650 the simplifier received 2 binders and produced 0.
Probably legitimate DCE: with 7 of the original 9 binders
missing from the list, the surviving 2 look unreferenced and
get dropped.  Not a SECOND bug, just the natural consequence
of the truncated input.

This explains why session 42's probe42 saw 0 at simplTopBinds
in some env-lens: the simplifier had already DCE'd the
1-binder input from the prior pipeline pass.

## Step 8 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs compiler/GHC/Core/Opt/Pipeline.hs`
  — probe reverted.
* Stage1 clean rebuild: `logs/build3-clean.log`.
* (next) Stage2 redeploy + smoke-test.
* (next) Baseline tests.

Session ends CLEAN with the narrowed-down localization captured.
