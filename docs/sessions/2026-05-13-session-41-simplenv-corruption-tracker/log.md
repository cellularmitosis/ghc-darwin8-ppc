# Session 41 — real-time log

## Pickup

Session 40 found that at every `refineFromInScope` panic, the
env's `seIdSubst` is EMPTY and `seInScope` has only
init_in_scope's `{wild_00}` plus the binders for the current
function being descended into.  Session 40's interpretation was
GC corrupting the SimplEnv heap closure's seInScope/seIdSubst
pointer fields.  Session 41 picks up to directly test this by
pinning a SimplEnv reference and periodically checking its
sizes.

## Step 1 — design probe41

Hook every `simplRecBndrs` call.  Register the env in an IORef
(initially only when size >=5; v2 broadened to "register every,
update to LARGEST").  At every `substId` failure, emit the
failing env's sizes AND the pinned env's CURRENT sizes.  If
pinned env's size drifts, GC has corrupted it.

## Step 2 — probe41-v1 build + deploy + sweep

First build failed: `>>` / `$` precedence bug.  Fixed: replaced
`hPutStrLn stderr $ unwords [...] >> hFlush stderr` with a do-block.

Sweep results (env-lens 600..2000 step 50):

| len      | pin?           | panic kind                             |
|----------|----------------|----------------------------------------|
| 600-700  | none           | PROBE41-FAIL refineFromInScope         |
| 950-1000 | scope=6,subst=0| StgToCmm: variable not found           |

`pinned=none` at 600-700: no simplRecBndrs with size >= 5 fired.
`PROBE41-PIN scope=6` at 950-1000: a real simplRecBndrs ran but
the panic is different (StgToCmm-time).

## Step 3 — probe41-v2: log every simplRecBndrs call

v2 changes:
- `probe41Pin` now logs EVERY call with size info.
- Pin updates to LARGEST env seen.

Build + deploy.

### v2 single-trigger len=600

```
PROBE41-RECBNDRS call=1 scope=2 subst=0 pin=yes
PROBE41-FAIL v=$dNum(0x610013d0) fail_scope=5 fail_subst=0
             pinned_was=(2,0) pinned_now=(2,0)
refineFromInScope panic, InScope {wild_00 s_aXl n_aXm x_aXn scaleAndShift}
```

- Only ONE simplRecBndrs call before panic, scope=2.
- Pinned env doesn't drift: (2,0) → (2,0).
- Panic-site env has scope=5 — DIFFERENT env from pinned (2).

### v2 clean compile (no padding, -A256m) baseline

```
PROBE41-RECBNDRS call=1 scope=10 subst=0 pin=yes
PROBE41-RECBNDRS call=2 scope=18 subst=0 pin=yes
PROBE41-RECBNDRS call=3 scope=14 subst=0 pin=no
PROBE41-RECBNDRS call=4 scope=18 subst=0 pin=no
RC=0
```

First call has scope=10 — matches Big2.hs's ~10 top-level binders.

### v2 len=950 (StgToCmm panic family)

```
PROBE41-RECBNDRS call=1 scope=2 subst=0 pin=yes
PROBE41-RECBNDRS call=2 scope=6 subst=0 pin=yes
GHC.StgToCmm.Env: variable not found $trModule1_r1ky
```

Two RecBndrs calls; sizes 2 then 6.  Still smaller than clean's
10/18/14/18 sequence.  No PROBE41-FAIL (StgToCmm panic is
post-simplifier).

## Step 4 — interpretation

- Pinned env's sizes are STABLE — `pinned_was == pinned_now`.
  Session 40's "GC corrupts the SimplEnv we track" hypothesis
  is partially disproven (at least for the env probe41 pins).
- BUT the panic-site env is a DIFFERENT env (fail_scope=5,
  pinned scope=2).  We pinned the "wrong" env.
- In FAILING runs, the first simplRecBndrs call has scope=2
  instead of clean's scope=10.  This shift in scope-size
  pattern between clean/failing runs is heap-layout-sensitive
  (`-A1m -G1` vs `-A256m`).

New hypothesis: **the simplifier's INPUT (binds0 / CoreProgram)
may itself be corrupted upstream**, causing simplRecBndrs to
see only 2 binders instead of 10.  This shifts the suspect to
the typechecker/desugarer/specializer pipeline.

## Step 5 — revert + clean rebuild + redeploy + baseline

- `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` —
  probe reverted.  Confirmed empty diff.
- Stage1 clean rebuild starting: `logs/build3-clean.log`.
- (next) Stage2 redeploy + smoke-test.
- (next) Baseline tests.

Session ends CLEAN with the major new lead captured in findings.md.
