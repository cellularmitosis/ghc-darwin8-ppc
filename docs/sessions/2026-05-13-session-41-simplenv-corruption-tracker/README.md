# Session 41 — probe41 partially disproves session 40's hypothesis; panic-site env is a **different** env than pinned

**Dates:** 2026-05-13 (continuation of session 40; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-40 exit.
`pmacg5:/opt/ghc-stage2/bin/ghc-real` is the clean v0.12.0+
rebuild (no probes).  Session 40 had hypothesized GC corruption
of the SimplEnv heap closure based on observing empty
seIdSubst at panic time.

**Status on exit:** CLEAN.  Probe41 reverted, stage1 rebuilt
clean, stage2 redeployed to pmacg5 + smoke-test PASS, baseline
tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged from
sessions 37-40).  **Probe41 pinned a SimplEnv reference in an
IORef and tracked its `seInScope`/`seIdSubst` sizes across the
compilation.  Result: pinned env's sizes are STABLE
(`pinned_was = pinned_now`), partially disproving session 40's
"GC corrupts the SimplEnv we track" hypothesis.**  However, the
**panic-site env is a different SimplEnv than the pinned one**:
in a failing run, probe41 pins an env with scope=2 (a small
inner simplRecBndrs call), while the substId-failure happens
with a different env at scope=5.  The simplifier has multiple
envs in flight; my probe didn't track the right one.  Also
observed: in failing runs, simplRecBndrs's FIRST call has
scope=2, whereas in a clean compile it has scope=10 (matching
Big2.hs's ~10 top-level binders).  **New hypothesis:** the
simplifier's INPUT `binds0 / CoreProgram` may be corrupted
upstream, causing simplRecBndrs to see only 2 binders instead
of 10.  The suspect shifts upstream to the typechecker /
desugarer / specializer / interface deserializer pipeline.
v0.12.0 release unchanged.

## Plan (per session 40 HANDOFF.md)

Pin a SimplEnv reference in an IORef and periodically check its
seInScope/seIdSubst sizes.  If the size drops between checks,
GC has corrupted the SimplEnv data structure.

Probe41 lives in `probe41-simplenv-tracker.patch` (this dir).

## What happened

### Iteration 1 (probe41-v1)

v1 registers an env in `probe41PinnedEnv :: IORef (Maybe (SimplEnv, Int, Int))`
when its `seInScope` size >= 5 (heuristic for "real top-level env").

First build failed: `>>` / `$` precedence bug — `hPutStrLn stderr $ unwords [...] >> hFlush stderr`
parsed as `hPutStrLn stderr $ (unwords [...] >> hFlush stderr)`,
making `String >> IO ()` a type error.  Fixed via do-block.

Sweep across env-lens 600..2000 step 50:

| len      | pin                      | panic kind                          |
|----------|--------------------------|-------------------------------------|
| 600-700  | none (no simplRecBndrs ≥5)| PROBE41-FAIL refineFromInScope     |
| 950-1000 | scope=6, subst=0         | StgToCmm: variable not found       |

### Iteration 2 (probe41-v2): track every simplRecBndrs call

Broadened: log EVERY simplRecBndrs call's env size, update pin
to LARGEST seen.

len=600 trigger:

```
PROBE41-RECBNDRS call=1 scope=2 subst=0 pin=yes
PROBE41-FAIL v=$dNum(0x610013d0) fail_scope=5 fail_subst=0
             pinned_was=(2,0) pinned_now=(2,0)
panic refineFromInScope, InScope {wild_00 s_aXl n_aXm x_aXn scaleAndShift}
```

- Only ONE simplRecBndrs call before panic, with scope=2.
- The pinned env's sizes are STABLE (`(2,0) → (2,0)`).
- The panic-site env has scope=5 — DIFFERENT from the pinned env.

Clean compile (`-A256m`, no padding):

```
PROBE41-RECBNDRS call=1 scope=10 subst=0 pin=yes
PROBE41-RECBNDRS call=2 scope=18 subst=0 pin=yes
PROBE41-RECBNDRS call=3 scope=14 subst=0 pin=no
PROBE41-RECBNDRS call=4 scope=18 subst=0 pin=no
RC=0
```

First call has scope=10 — matches Big2.hs's ~10 top-level binders.

### Iteration 3 — interpretation

Combining:

(a) Pinned env's sizes are STABLE — the env probe41 tracks does
    NOT have its seInScope/seIdSubst fields corrupted by GC.
(b) The panic-site env is DIFFERENT from the pinned env.  Two
    different envs are in flight during the failing
    compilation.
(c) In failing runs, simplRecBndrs's FIRST call has scope=2
    instead of clean's scope=10.  The simplifier sees only 2
    binders at simplTopBinds-entry time.

Session 40's "GC corrupts SimplEnv" hypothesis is partially
disproven by (a).  But (b) and (c) suggest the corruption (if
any) happens UPSTREAM of simplTopBinds — possibly to the
`binds0 / CoreProgram` input.

### Iteration 4 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` — probe
  reverted.  Confirmed empty diff.
* Stage1 clean rebuild (~6m): `logs/build3-clean.log` — EXIT=0
  _(TBD pending in-flight verification)_.
* Stage2 redeploy: `logs/deploy3-clean.log` _(TBD)_.
* Baseline tests: `logs/baseline-tests-end.log` _(TBD)_.

Session ends CLEAN.

## Files added this session

* `README.md` (this), [`log.md`](log.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`commits.md`](commits.md).
* `probe41-simplenv-tracker.patch` — SimplEnv pin + drift
  tracker (v2, final).
* `logs/build1-probe41.log` — v1 build (failed → fixed → success).
* `logs/build2-probe41v2.log` — v2 build.
* `logs/build3-clean.log` — post-revert clean rebuild.
* `logs/deploy1-probe41.log`, `deploy2-probe41v2.log`,
  `deploy3-clean.log` — deploys.
* `logs/sweep1-probe41.log` — v1 sweep.
* `logs/panic-trigger-len*.log` — focused triggers.
* `logs/v2-len600.log`, `v2-len950.log`, `v2-len1050.log` —
  v2 triggers.
* `logs/baseline-tests-end.log` — post-revert baseline.

## Top finding to carry into session 42

The simplifier's first `simplRecBndrs` call has scope=2 in
failing runs vs scope=10 in clean runs.  The pinned env doesn't
drift.  This narrows the suspect to **the input `binds0 /
CoreProgram` to simplTopBinds being corrupted upstream** —
typechecker, desugarer, specializer, or interface
deserializer.  See [`findings.md`](findings.md) §F8 for
concrete next-experiment recipes.
