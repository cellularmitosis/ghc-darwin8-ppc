# Session 32 log

Real-time work log.  Continuing from session 31.

## Setup

- 2026-05-12.  Continuing from session 31.
- HANDOFF top priority: use the env-var dodge as a debugging primitive.
  Bisect environ-block-size shifts to find the minimum dodging delta.
- HANDOFF second priority: per-event weak-pointer + stable-pointer
  table probes.

## Step 1 — verify baseline + reproducer

- `tests/run-tests.sh` → green (4 DIFF-expected diffs as documented in
  `tests/RESULTS.md`; rc=0).
- Uploaded canonical Big2.hs to pmacg5:/tmp/Big2.hs.
- Big2 `+RTS -A1m -G1 -RTS` no extra env on clean v0.12.0:
  10/10 FAIL_REFINE (`refineFromInScope`).  Matches session 31 baseline.

## Step 2 — env-var dodge claim doesn't reproduce

Ran 5 iters with `A=A` direct shell-assignment: 1/5 PASS, 4/5 FAIL_SCOPE.
That's NOT 5/5 PASS as session 31 claimed.

Ran 5 iters with `env A=A` (env-wrapper): 0/5 PASS, 5/5 FAIL_REFINE.
Different from shell-assignment, also not what session 31 said.

So session 31's "any env var dodges 5/5" was 1-trial per variant.
Many variants happen to PASS once but FAIL on subsequent iters.

Decision: standardize on `env`-wrapper, run 5 iters/cell, take iters 2-5
as the stable signal (iter 1 is anomalous).

## Step 3 — env-var length sweep, 2..300 step 4

Built [`scripts/env-trial.sh`](scripts/env-trial.sh) and
[`scripts/full-sweep.sh`](scripts/full-sweep.sh).  Ran the sweep.

(Initial bug in env-trial.sh: empty $ENV_PREFIX broke shell var-
assignment parsing.  Fixed by wrapping with `env $ENV_PREFIX DYLD_... cmd`.
Subsequent issue: 5/5 "FAIL_OTHER rc=0" at len=500 turned out to be a
GCC warning emitted to stderr that doesn't fail compilation; fixed the
classifier to use rc=0 → PASS.)

(NEW failure surface discovered at len=350-450: `StgToCmm.Env:
variable not found $trModule4_r1kB`.  Extended classifier with
FAIL_STGCMM.)

Major result: PASS/FAIL is NON-MONOTONIC in env-var length:
- 2-16 bytes: REFINE
- 17-22: SCOPE
- 23-166: PASS (wide 143-byte PASS zone)
- 178-298: REFINE again

## Step 4 — sweep 300..3000, characterize dropped Var

Used [`scripts/extract-fail-detail.sh`](scripts/extract-fail-detail.sh).

Found that the missing Var changes by env-size zone:
- len 2-6: `$dNum_a1jO`
- len 200-320: `$dNum_a1k2`
- len 350-450: `$trModule4_r1kB`
- len 700: `$dOrd_a1kc`

Different Vars at different env-sizes — strongly suggesting heap
layout determines which Var lands at a "blind spot".

Additional zones:
- 300-320: REFINE / `$dNum_a1k2`
- 350-450: STGCMM / `$trModule4_r1kB`
- 500-600: PASS
- 650-700: REFINE / `$dOrd_a1kc`
- 750-800: SCOPE
- 850-900: REFINE / `$dOrd_a1ks`
- 950-1000: STGCMM
- 1050-1700: SCOPE (with one REFINE at 1700)
- 1800-2000: SCOPE
- 2100: A NEW FAILURE: `depSortStgBinds: Found cyclic SCC`!
- 2200-2400: SCOPE
- 2500-3000: PASS

So we have FIVE surfaces of the same root-cause bug.

## Step 5 — PROBE32: heap-address probe

Modified `compiler/GHC/Core/Opt/Simplify/Env.hs:706` to dump the
heap address of `v` at the panic.  Reuses `aToWordzh` trick from
`GHC.Exts.Heap.Closures`'s Box Show instance:

```haskell
foreign import prim "aToWordzh" probe32_aToWord# :: Any -> Word#
probe32AddrHex :: a -> String
probe32AddrHex x =
    let !w = W# (probe32_aToWord# (unsafeCoerce x :: Any))
    in "0x" ++ Numeric.showHex w ""
```

Initial build error: need `{-# LANGUAGE GHCForeignImportPrim #-}` and
`{-# LANGUAGE UnliftedFFITypes #-}` pragmas.  Added both.

Rebuilt stage1 ghc library: 5m34s wall.
Rebuilt + deployed stage2: 8m21s wall.
Total: ~14 min.

## Step 6 — probe sweep, captured addresses

Smoke test with the probe-enabled stage2:
- len=700: 5/5 iters all show `refineFromInScope 0xe003348` — fully deterministic.

Sweep 100..2500 step 50 (and selected points):

| env-len    | result                          |
|------------|---------------------------------|
| 100        | SCOPE                           |
| 150-200    | PASS                            |
| 250-300    | SCOPE                           |
| 350-450    | PASS (zones shifted vs pre-probe due to probe code) |
| 500        | OTHER (DEPSORT)                 |
| 550-600    | PASS                            |
| 650-700    | REFINE @ 0xe003348              |
| 750-800    | SCOPE                           |
| 850-900    | REFINE @ 0xcce80d0              |
| 950-1000   | STGCMM                          |
| 1050-1600  | SCOPE                           |
| 1700       | REFINE @ 0xbe30ddc              |
| 1800-2000  | SCOPE                           |
| 2100       | OTHER (DEPSORT)                 |
| 2200-2400  | SCOPE                           |
| 2500       | PASS                            |

THREE distinct addresses captured:
- 0xe003348 (env-len 650-700)
- 0xcce80d0 (env-len 850-900)
- 0xbe30ddc (env-len 1700)

In three different megablocks (0xe000000, 0xcc00000, 0xbe00000).
No shared alignment, page-offset, or megablock-offset.

**Single-fixed-blind-spot-virtual-address hypothesis: FALSIFIED.**

## Step 7 — clean revert + redeploy

```
cd external/ghc-modern/ghc-9.2.8
git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

(Running in background; ~14 min.  Will verify post-completion that
baseline matches v0.12.0 — Big2 -A1m -G1 no-env FAIL_REFINE 5/5.)

## Findings — analysis

1. **Bug is layout-sensitive at byte granularity** but not in a
   simple linear way.  Multiple narrow REFINE zones at different
   trigger addresses.
2. **The bug condition is satisfied by multiple, unrelated
   virtual addresses** in different megablocks.
3. **For a fixed configuration, the bug is fully deterministic.**
4. **Same-length env vars yield different outcomes** depending
   on byte content — environ-block size isn't the only factor.
5. **At least FIVE pipeline stages can catch the bug**:
   refineFromInScope (simp), TC-time "not in scope", StgToCmm.Env
   "variable not found", depSortStgBinds "cyclic SCC", and PASS.

## Next steps (session 33)

Top: dump closure header + payload at trigger addresses.  Look
for closure-shape commonality across 0xe003348, 0xcce80d0,
0xbe30ddc.

See HANDOFF.md for full plan.
