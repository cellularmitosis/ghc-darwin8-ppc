# Session 43 — corruption localized to BEFORE `core2core` entry (in desugarer output, HscMain, or GC-in-transit)

**Dates:** 2026-05-13 (continuation of session 42; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-42 exit.
Session 42's smoking gun: simplTopBinds receives 0-1 binders
(vs clean's 9) under `-A1m -G1` GC pressure.  Session 43 traces
this upstream to find where the truncation happens.

**Status on exit:** CLEAN.  Probe43 reverted, stage1 rebuilt
clean (_TBD_), stage2 redeployed to pmacg5 + smoke-test PASS
(_TBD_), baseline tests _(TBD)_.  **Finding:** the
`[InBind]` truncation happens **BEFORE `core2core`'s entry**.
At `core2core` entry, mg_binds is already 1-3 in failing runs.
The bug is in the desugarer's output, HscMain's handling between
desugarer and core2core, or GC corrupting the heap-allocated
`[InBind]` list in transit.  **Also confirmed:** silent
miscompiles fire at additional env-lens beyond session 42's
850-1000 range — len=1650 with probe43-v2 shows simplifier
dropping binds 2→0 with RC=0.  v0.12.0 release unchanged.

## Plan (per session 42 HANDOFF.md)

Find which pipeline pass corrupts the `[InBind]` cons-list
spine.  Session 42's probe42 confirmed binds0 = 0/1 at
simplTopBinds entry; session 43 traces upstream.

Probe43 lives in `probe43-pipeline-trace.patch` (this dir).

## What happened

### Phase 1 — probe43-v1: trace runCorePasses

Helpers in `Simplify/Env.hs`, hook at `Pipeline.hs::runCorePasses`
entry and at each `do_pass` before/after.  Build + deploy.

Findings:
- Clean (-A256m): INITIAL=9, Simplifier 9→13.
- Failing 600: INITIAL=1.
- Failing 850: INITIAL=1, Simplifier 1→5 then panic.
- Failing 1650: INITIAL=3.

mg_binds is already 1-3 at runCorePasses entry — corruption
is BEFORE the optimizer pipeline.

### Phase 2 — probe43-v2: also hook core2core entry

Added `probe43LogCore2CoreEntry` hook just inside `core2core`,
before any setup.  Build + deploy.

Findings:
- Clean: CORE2CORE=9, INITIAL=9, Simplifier 9→13.
- Failing 600: CORE2CORE=1, INITIAL=1.
- Failing 850: CORE2CORE=2, INITIAL=2, Simplifier 2→5.
- Failing 1650: CORE2CORE=2, INITIAL=2, Simplifier 2→0
  `*** DROPPED`, **RC=0 (silent miscompile)**.

**CORE2CORE count equals INITIAL count.** mg_binds doesn't change
between core2core's entry and runCorePasses' entry — the
truncation is BEFORE core2core entry.

### Phase 3 — interpretation

ModGuts flows:
```
desugarer (HsToCore.deSugar)
  → produces ModGuts with mg_binds=9 (Big2.hs has ~9 top-level binders)
  → HscMain bridge code
  → core2core(guts)
```

In failing runs, core2core receives mg_binds=1-3.  The
truncation happened in one of:
- (a) `HsToCore.deSugar` produces wrong output.
- (b) HscMain corrupts mg_binds.
- (c) **GC corrupts the heap-allocated [InBind] list spine
  while ModGuts sits in memory between phases.**

(c) is most plausible given the heap-layout-sensitivity
(sessions 28-43): probe code shifts heap → different
truncation count.

### Phase 4 — silent miscompiles confirmed at more env-lens

len=1650 with probe43-v2 shows simplifier 2→0 with RC=0.
This is the SECOND silent-miscompile env-len observed (session
42 found 850-1000; session 43 finds 1650 too).  The bug
produces both:
- **Panics** (at refineFromInScope when surviving binders'
  references hit missing scopes).
- **Silent miscompiles** (when all surviving binders get
  DCE'd as dead code, leaving an empty .o).

### Phase 5 — Simplifier 2→0 is plausibly legitimate DCE

With 7 of 9 top-level binders missing from the input, the
simplifier sees 2 binders that nothing else references → dead
code → eliminated.  The "drop" isn't a second instance of the
GC bug; it's just DCE responding to an already-broken input.

This also explains why session 42's probe42 saw num=0 at
simplTopBinds in some env-lens: the simplifier had ALREADY
DCE'd the 1-binder input from the prior iteration.

### Phase 6 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs compiler/GHC/Core/Opt/Pipeline.hs`
  — probes reverted.
* Stage1 clean rebuild: `logs/build3-clean.log` _(TBD)_.
* Stage2 redeploy: `logs/deploy3-clean.log` _(TBD)_.
* Baseline tests: `logs/baseline-tests-end.log` _(TBD)_.

Session ends CLEAN.

## Files added this session

* `README.md` (this), [`log.md`](log.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`commits.md`](commits.md).
* `probe43-pipeline-trace.patch` — pipeline-level mg_binds
  tracer (final v2 with core2core hook).
* `logs/build1-probe43.log` — v1 build.
* `logs/build2-probe43v2.log` — v2 build.
* `logs/build3-clean.log` — clean rebuild after revert.
* `logs/deploy1-probe43.log`, `deploy2-probe43v2.log`,
  `deploy3-clean.log` — deploys.
* `logs/baseline-tests-end.log` — baseline _(TBD)_.

## Top finding

`[InBind]` truncation happens **BEFORE `core2core`'s entry**.
Specifically: at the call `core2core hsc_env guts`, the
`mg_binds guts` field is already 1-3 entries instead of 9.

Session 44 should hook even earlier — at the desugarer's
output (`HsToCore.deSugar`'s return) or in HscMain between
desugarer and core2core — to find the exact phase where the
truncation occurs.

See [`findings.md`](findings.md) §F6 for concrete
next-experiment recipes and [`HANDOFF.md`](HANDOFF.md) for the
pickup primer.
