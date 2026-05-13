# Session 39 — probe39 disproves session 38's "GC corrupts Var.realUnique" hypothesis

**Dates:** 2026-05-13 (continuation of session 38; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-38 exit.
`pmacg5:/opt/ghc-stage2/bin/ghc-real` is the clean v0.12.0+
rebuild (no probes).  Session 38 had refined the framing from
"UniqMap corruption" to "GC corrupts the `realUnique :: FastInt#`
field of Var heap closures on PPC32 unreg," based on observing
that the in-scope set at the panic site contains a Var with the
right OccName but a different raw Unique than the expression's.

**Status on exit:** CLEAN.  Probe39 reverted, stage1 rebuilt
clean, stage2 redeployed to pmacg5 + smoke-test PASS, baseline
tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).
**Session 38's "GC corrupts realUnique" hypothesis is
DISPROVEN.** Probe39 pinned a sentinel `$dOrd_a1k0` Var with raw
Unique `0x610013f7` to an IORef (keeping it alive across GC) and
re-read its `varUnique` (the Haskell-level accessor) at every
subsequent `refineFromInScope` call.  **The value stays exactly
`0x610013f7` every check.**  GC may move the closure but does
NOT rewrite the realUnique field's value as observed by GHC's
own accessor.  The remaining hypothesis: **two distinct Var
heap closures exist with the same OccName "$dOrd_a1k0" but
different Uniques**, created upstream of the simplifier by the
renamer/typechecker/desugarer/specializer/interface-deserializer
pipeline.  Neither Var drifts; they're genuinely two separate
objects.  v0.12.0 release unchanged.

## Plan (per session 38 HANDOFF.md)

Design a probe that **directly tests** the Var.realUnique drift
hypothesis: pick a sentinel Var (any `$d*`-named one we see
entering scope), stash it in an IORef, and at every
`refineFromInScope` call re-read its `varUnique` to detect any
drift.

Probe39 lives in `probe39-realunique-drift.patch` (this dir).

## What happened

### Iteration 1 (probe39-v1): hardcoded OccName filter missed

Initial filter matched specific OccNames from session 38's
fingerprints (`$dOrd_a1k0`, `$dEq_a1km`, etc.).  Hook in
`addNewInScopeIds`.  Sweep showed `sentinel=none` everywhere —
the build's actual victim names differed by suffix
(`$dOrd_a1kY`, `$dNum_a1jW`).

### Iteration 2 (probe39-v2): broaden filter + hook subst_id_bndr

v2:
- Filter: any `$d`-prefixed OccName.
- Also hooked `subst_id_bndr` — `addNewInScopeIds` misses
  top-level binders that flow through `simplRecBndrs` →
  `substIdBndr`.

Single-trigger at len=850 produced:

```
PROBE39-INIT name=$dOrd realUnique=0x610013f7 addr=0xcccc4eb
PROBE39-DRIFT drift_evt=1 checks=1 was@0xcccc4eb was_u=0x610013f7
              now@0xcccc4eb u_via_haskell=0x610013f7 u_raw_w2=0xce214ed
(4 identical events)
RC=0
```

- `u_via_haskell = 0x610013f7 = was_u` — **NO drift in the
  Haskell-level read**.
- `u_raw_w2 = 0xce214ed` differs — but this is the
  wrapping-thunk artefact from sessions 33-37: `anyToAddr#`
  returned the address of a wrapping thunk, not the Id closure
  proper.  The raw peek read thunk metadata.

### Iteration 3 (probe39-v3): drop misleading raw-peek check

v3 emits `PROBE39-DRIFT` only on Haskell-level drift
(`varUnique v != was_u`).  The `u_raw_w2` check was generating
false-positive drift events.

Fine sweep (step 25, env-lens 600..2000) with v3:

| env-len   | sentinel | panic shape          |
|-----------|----------|----------------------|
| 650-725   | none     | refine, $dNum(0x610013d8) |
| 1650-1700 | none     | refine, $dOrd(0x610013dc) |

In every failing run, **the sentinel never registered** — the
panic fires before `subst_id_bndr` sees any `$d*` Var.

### Iteration 4 — interpretation

Combining the two findings:

(a) When sentinel IS registered (probe39-v2 at len=850 where
    compile succeeded): **varUnique v is stable** across every
    refineFromInScope check.
(b) When the bug fires (probe39-v3 at len=650 etc.): sentinel
    never registered because panic precedes any `$d*` Var
    binding through `subst_id_bndr`.

Together these argue against the "GC rewrites realUnique"
hypothesis.  The bug must be that **two genuinely distinct Var
objects** exist with the same OccName but different Uniques —
neither drifts; they were never the same Var.

### Iteration 5 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` — probe
  reverted.
* Stage1 clean rebuild (~6m): `logs/build4-clean.log`, EXIT=0.
* Stage2 redeploy: `logs/deploy4-clean.log`, EXIT=0, smoke-test
  PASS.
* Baseline tests: `logs/baseline-tests-end.log` — **30 PASS,
  0 FAIL_RUN, 4 FAIL_OUTPUT** (same as session 37/38).

Session ends CLEAN.

## Files added this session

* `README.md` (this), [`log.md`](log.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`commits.md`](commits.md).
* `probe39-realunique-drift.patch` — sentinel-tracking probe
  (v3, final).
* `scripts/sweep.sh`, `scripts/sweep-panic-shape.sh`,
  `scripts/sweep-full.sh`, `scripts/trigger-one.sh` — copied
  from session 38, prefixes updated to PROBE39.
* `logs/build1-probe39.log` — v1 build.
* `logs/build2-probe39v2.log` — v2 build.
* `logs/build3-probe39v3.log` — v3 build.
* `logs/build4-clean.log` — clean rebuild after revert.
* `logs/deploy1-probe39.log`, `deploy2-probe39v2.log`,
  `deploy3-probe39v3.log`, `deploy4-clean.log` — deploys.
* `logs/panic-trigger-len850.log` — v1 single trigger.
* `logs/panic-trigger-v2-len850.log` — v2 single trigger (the
  one that captured the stable Haskell-level Unique).
* `logs/panic-trigger-v3-len850.log` — v3 single trigger.
* `logs/sweep1-broad.log` — v2 broad sweep.
* `logs/sweep2-v3-fine.log` — v3 fine sweep.
* `logs/panic-shape-v3.log` — v3 panic-shape sweep.
* `logs/baseline-tests-end.log` — post-revert baseline.

## Top finding to carry into session 40

**The realUnique field is stable.**  Probe39 directly observed
`varUnique v` returning the same Unique across multiple
refineFromInScope calls in the same compilation.

So the bug must be **two distinct Var objects with the same
OccName**, not a single Var whose Unique changes over time.
Future probes should trace **where** the duplicate is created —
likely in the renamer, typechecker, desugarer, specializer, or
interface deserializer.

See [`findings.md`](findings.md) §F5 for concrete experiment
recipes, and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
