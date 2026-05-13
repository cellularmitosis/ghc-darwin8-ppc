# Session 32 — stage2 GC bug, round 14 (env-var bisect + heap-address probe; single-blind-spot hypothesis falsified)

**Dates:** 2026-05-12 (continuing the stage2 GC bug hunt from session 31).

**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on
Tiger uses `+RTS -A1G` workaround.  Session 31 produced three big
findings: (a) cross-run address-stream diff is unworkable
(D.hs / E.hs `-Dg` traces diverge at GC 1), (b) "any 3+ byte env
var dodges" the bug (per their 1-trial test), (c) PROBE31 exonerates
`scavenge_stack` walker iteration.  Session-31 HANDOFF top priority:
use the env-var dodge as a debugging primitive to bisect the
heap-shift trigger.

**Status on exit:**

- **Session 31's "any env var dodges" claim is wrong.**  The bug's
  PASS/FAIL pattern is **non-monotonic** in env-var length.
  Multiple distinct zones of PASS / FAIL alternate as env-var size
  grows from 0 to 3000 bytes.  Sample (iters 2-5, env-wrapper +
  `A=A...A` of varying value length): 0-16 REFINE → 17-22 SCOPE →
  23-166 PASS → 178-320 REFINE → 350-450 STGCMM → 500-600 PASS →
  650-700 REFINE → 750-800 SCOPE → 850-900 REFINE → 950-1000
  STGCMM → 1050-1600 SCOPE → 1700 REFINE → 1800-2000 SCOPE →
  2100 DEPSORT → 2200-2400 SCOPE → 2500-3000 PASS.
- **A FIFTH surface error discovered: `depSortStgBinds: Found
  cyclic SCC`** (STG dependency sorter).  Joins the four already
  known surfaces (REFINE, SCOPE, STGCMM, PASS).  All five
  surfaces are the same root-cause "GHC dropped a Var" bug —
  caught at different pipeline stages depending on which Var
  got dropped.
- **Probe added to `refineFromInScope` panic site** to dump the
  dropped Var's heap address.  THREE distinct addresses captured
  across three REFINE zones: 0xe003348 (env-len 650-700),
  0xcce80d0 (env-len 850-900), 0xbe30ddc (env-len 1700).
- **The "single fixed blind-spot virtual address" hypothesis is
  FALSIFIED.**  Sessions 19/30/31 framed the bug as "ONE specific
  virtual address X is a blind spot for the GC walker."  The
  probe data shows MULTIPLE unrelated addresses, in different
  megablocks, each deterministically triggering the same kind
  of panic.  The bug condition must be something other than
  "specific address X."
- **For a fixed env-var configuration, the dropped Var's address
  is fully deterministic (5/5 iters identical).**
- **Same-length env vars with different bytes give different
  results** — e.g. `A=AAAAAAAAAAAAAAAAA` (17 bytes) FAILs SCOPE,
  but `PROBE31_VERBOSE=0` (17 bytes) PASSes.  So it isn't just
  total environ size — actual byte content matters.
- v0.12.0 unchanged.  Source tree clean at session end (PROBE32
  reverted).  Stage2 on pmacg5 rebuilt + redeployed clean.

HANDOFF for session 33: see [`HANDOFF.md`](HANDOFF.md).  Pivot:
with single-blind-spot-address falsified, the next probes should
investigate **closure-shape-based** conditions (does the trigger
closure share a specific header / payload pattern across
addresses?) and **GC-event-sequence** conditions (does the
trigger Var get allocated during a specific GC phase?).

## What we did, in order

### Step 1 — verified baseline + reproducer + env-var dodge claim

`tests/run-tests.sh` green.  Big2 `-A1m -G1` no env: 10/10 FAIL_REFINE
on clean v0.12.0.

Tried `A=A` env-wrapped on 5 iters: 0/10 PASS — contradicts session 31.
Tried `A=A` direct shell-assignment: 1/10 PASS + 9/10 FAIL_SCOPE.
Session 31's "5/5 pass" must have been a single per-variant trial
that happened to PASS once.  The bug is more present than session 31
reported.

### Step 2 — fine env-var length sweep, 2..300 bytes step 4

[`scripts/full-sweep.sh`](scripts/full-sweep.sh) drives
[`scripts/env-trial.sh`](scripts/env-trial.sh).

Discovered:
- 2-16: REFINE (with iter-1 anomalies)
- 17-22: SCOPE
- 23-166: PASS — wide PASS zone, ~143 bytes
- 178-298: REFINE — second REFINE zone

(Full data in `logs/sweep-2-300-step4.log`.)

### Step 3 — sweep 300..3000, dropped-Var detail

Discovered TWO MORE failure surfaces:
- **STGCMM**: `StgToCmm.Env: variable not found $trModule4_r1kB`
  (codegen).  Fires at 350-450 and 950-1000.
- **DEPSORT**: `depSortStgBinds: Found cyclic SCC` (STG dep sort).
  Fires at 2100.

Used [`scripts/extract-fail-detail.sh`](scripts/extract-fail-detail.sh)
to extract the specific Var name dropped at each env-size:

| env-len | dropped Var          |
|---------|----------------------|
| 2-6     | `$dNum_a1jO`         |
| 200-320 | `$dNum_a1k2`         |
| 350-450 | `$trModule4_r1kB`    |
| 700     | `$dOrd_a1kc`         |

Different env-sizes drop different Vars — strongly suggesting
the bug's "blind spot" is layout-dependent, with different Vars
landing at the triggering location in each zone.

### Step 4 — added heap-address probe to refineFromInScope

Patched [`compiler/GHC/Core/Opt/Simplify/Env.hs:706`] to dump
the heap address of `v` (the missing Var) right before the panic.

The probe reuses the same trick from `GHC.Exts.Heap.Closures`'s
`Box` Show instance:

```haskell
foreign import prim "aToWordzh" probe32_aToWord# :: Any -> Word#
probe32AddrHex :: a -> String
probe32AddrHex x =
    let !w = W# (probe32_aToWord# (unsafeCoerce x :: Any))
    in "0x" ++ Numeric.showHex w ""
```

And modified the panic call site to:

```haskell
Nothing -> pprPanic ("refineFromInScope " ++ probe32AddrHex v)
                    (ppr in_scope $$ ppr v)
```

Patch: [`probe32-refineFromInScope-addr.patch`](probe32-refineFromInScope-addr.patch).

Rebuilt stage1 compiler library (5m34s) + stage2 (8m21s).
Deployed to pmacg5.

### Step 5 — probe sweep, captured heap addresses

Sweep with the probe-enabled stage2:

| env-len | dropped-Var heap address |
|---------|--------------------------|
| 650, 700| 0xe003348                |
| 850, 900| 0xcce80d0                |
| 1700    | 0xbe30ddc                |

5/5 iterations at len=700 all return `refineFromInScope 0xe003348`
— fully deterministic.

Three different addresses in three different megablocks (0xe000000,
0xcc00000, 0xbe00000).  No shared alignment, page-offset, or
megablock-offset.

**The single-blind-spot-address hypothesis is falsified.**

### Step 6 — clean revert + redeploy

`git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs`, rebuild
stage1 ghc library (~5 min), rebuild + deploy stage2 (~8 min).
Verified baseline matches v0.12.0 with no env var.

## Status on exit

- **v0.12.0 unchanged.**  No GHC-tree source edits committed.
- **Stage2 on pmacg5 is the clean rebuild after probe revert.**
  Matches v0.12.0 behavior.
- **Logs at** `logs/`
- **HANDOFF for session 33** pivots to closure-shape probing
  and GC-event-sequence analysis (single-blind-spot falsified).
  See [`HANDOFF.md`](HANDOFF.md).

## Files added this session

- [`README.md`](README.md) (this), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`log.md`](log.md),
  [`commits.md`](commits.md) — writeup.
- [`probe32-refineFromInScope-addr.patch`](probe32-refineFromInScope-addr.patch)
  — heap-address probe at the simplifier panic site.
- [`scripts/env-trial.sh`](scripts/env-trial.sh) — single-env-var
  trial driver with outcome classification.
- [`scripts/full-sweep.sh`](scripts/full-sweep.sh) — length sweep
  driver.
- [`scripts/extract-fail-detail.sh`](scripts/extract-fail-detail.sh)
  — dropped-Var-name extractor.
