# Session 43 commits

- _TBD: backfill SHA after `git commit`._  Session 43: probe43
  traces `mg_binds` length through the Core optimization
  pipeline.  Two iterations: v1 hooks `runCorePasses` entry and
  each `do_pass` before/after; v2 adds a hook at `core2core`
  entry itself.

  **Findings:**
  - Clean compile (-A256m): CORE2CORE=9, INITIAL=9, Simplifier
    9→13.
  - Failing -A1m -G1 len=600: CORE2CORE=1, INITIAL=1, panic
    before simplify completes.
  - Failing len=850: CORE2CORE=2, INITIAL=2, Simplifier 2→5
    then panic.
  - Failing len=1650: CORE2CORE=2, INITIAL=2, Simplifier 2→0
    `*** DROPPED`, **RC=0 (silent miscompile)**.

  **Localization:** `mg_binds` is already truncated at
  `core2core` entry in failing runs.  CORE2CORE count equals
  INITIAL count (no drop in between).  The corruption happens
  BEFORE the optimizer pipeline starts — in the desugarer's
  output, HscMain's bridge code, or GC corrupting the
  heap-allocated `[InBind]` list while ModGuts sits in memory
  between phases.

  **Silent miscompile extends:** len=1650 with probe43-v2
  also produces a silent miscompile (RC=0 with simplifier
  dropping binds 2→0).  This is the second env-len band with
  silent miscompiles after session 42's 850-1000.

  Simplifier's 2→0 drop at len=1650 is plausibly legitimate
  dead-code elimination — with most top-level binders missing
  from the input, the surviving 2 look unreferenced and get
  DCE'd.  Not a SECOND bug, just downstream behavior on
  already-broken input.

  v0.12.0 ships unchanged; probes applied for measurement only
  and reverted at session end; stage2 on pmacg5
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (same long-standing
  test-design divergences as sessions 37-42).

  Session 43 HANDOFF.md scopes probe44: hook the desugarer's
  output (`HsToCore.deSugar`) to localize whether the
  truncation is in the desugarer or in HscMain between
  desugarer and core2core.
