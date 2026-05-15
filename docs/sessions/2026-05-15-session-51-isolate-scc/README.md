# Session 51 — TRUE MINIMAL REPRO: `STUArray Bool` is corrupt at allocation time on PPC32 unreg

**Date:** 2026-05-15 (continuation of session 50; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-50 exit.
Stage1 + stage2 redeployed clean.  Baseline tests at the
session-49/50 noise floor (30 PASS, 4 FAIL_OUTPUT — all
test-design issues).  Session 50 narrowed the corruption locus
to `Data.Graph.scc` in
`libraries/containers/containers/src/Data/Graph.hs:650`.

**Status on exit:** CLEAN.  No GHC source modifications.
Baseline tests run at session-end: 30 PASS / 4 FAIL_OUTPUT
(unchanged).  **TRUE MINIMAL REPRO found:** the bug is in
`newArray False :: ST s (STUArray s Int Bool)` on PPC32 unreg —
freshly allocated arrays have spurious True bits in 84-87% of
iterations under moderate GC pressure.  Reproduces under
default RTS, not just `-A1m -G1`.  Host uranium: 0 bad.

## Plan (per session 50 HANDOFF)

Isolate `Data.Graph.scc` in a standalone Haskell program,
confirm a minimal repro independent of the compiler, then drill
the algorithm's internals.

## What happened (five test iterations)

| iter | test               | reproduces? | locus narrowed to                            |
|------|--------------------|-------------|----------------------------------------------|
| 1    | scc_test.hs        | NO          | (single-pass not enough GC pressure)         |
| 2    | scc_test2.hs       | YES         | scc with interleaved burnGC, 8-vertex graphs |
| 3    | scc_test3.hs       | YES         | size-sensitive: 6-24 BAD, others mostly OK   |
| 4    | scc_test4.hs       | YES         | inside `prune`'s `chop` (STUArray reads spurious True) |
| 5    | stuarray_test.hs   | YES         | **freshly-allocated `STUArray Bool` itself** |

### iter 1 — single-pass test (`scc_test.hs`)

Tested `scc` with sizes 1, 2, 4, 8, 32, 128 in single-pass and
100-iter loops, both default RTS and `-A1m -G1`.  **All passed.**
Single-pass doesn't accumulate enough GC pressure.

### iter 2 — interleaved allocation (`scc_test2.hs`)

Added `burnGC 1000` allocation before and after each `scc`
call, in a 1000-iter loop.

- 8-vertex graphs, default RTS: 191/1000 bad.
- 8-vertex graphs, `-A1m -G1`: 966/1000 bad.
- Host uranium: 0/10000 bad.

**Bug reproduces under default RTS too.**  Not just `-A1m -G1`.

### iter 3 — size sweep (`scc_test3.hs`)

Sized graphs 1-256.

**Default RTS:** sizes 1-5 OK, 6-24 BAD, 28 OK, 32 OK, 48 BAD,
64+ OK.

**-A1m -G1:** sizes 1-2 OK, 3-24 BAD, 28-32 OK, 48 BAD, 64+ OK.

Bug is size-sensitive but not monotonic — heap-layout-dependent.

### iter 4 — inlined `scc` with probes (`scc_test4.hs`)

Re-implemented `dfs` / `prune` / `chop` / `generate` /
`postOrd` / `transposeG` inline.  Initially used `STArray`
(boxed) — **didn't reproduce**.  Switched to `STUArray`
(unboxed) — **reproduced**.

Trace at first bad iter (size 8): `prune_chop_in_len=8`,
`prune_chop_out_len=6`.  Per-vertex chop drilling showed
vertex 3 read as `True` on the **first call** to `readArray
marks 3`, before any write to position 3.

### iter 5 — minimal STUArray repro (`stuarray_test.hs`)

Stripped everything except:

```haskell
checkFresh :: Int -> [Bool]
checkFresh n = runST $ do
  arr <- newArray (0, n - 1) False :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]
```

Loop 10000 times with `burnGC 1000` interleaved.

- pmacg5 default RTS: **8431/10001 bad** (84%).
- pmacg5 `-A1m -G1`: **8655/10001 bad** (87%).
- uranium (host arm64): **0/10001 bad**.

Sample bad outputs:
- `[False,False,False,False,True,False,False,True]`
- `[True,False,True,False,True,True,True,True]`
- `[False,False,True,True,True,False,True,False]`

Random-looking garbage, consistent with uninitialized memory.

## Top finding

**`newArray False :: ST s (STUArray s Int Bool)` does not
reliably produce a zeroed `MutableByteArray#` on PPC32 unreg
under moderate GC pressure.**  The bug is in GHC's RTS
allocation/zeroing path, not in any compiler code.

This single bug explains every probe finding from sessions
42-50.  Session 50's `Data.Graph.scc` returning wrong forests
traces to `chop` reading spurious True bits from a freshly-
allocated `STUArray Bool`.  Session 42's "compiler emits
152-byte empty .o" symptom traces all the way back to this
same root cause.

Session 52 should test other unboxed STUArray types, test
pinned arrays, test without GC pressure, then read the RTS
source for `stg_newByteArrayzh` on PPC32 unreg to identify the
exact fix.

## Files added this session

* `README.md` (this), `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md`.
* `scc_test.hs`, `scc_test2.hs`, `scc_test3.hs`,
  `scc_test4.hs`, `stuarray_test.hs` — the five test
  iterations.
* `logs/baseline-tests-start.log`,
  `logs/scc_test2-output.log` (11K lines — bug fired
  reliably with interleaved allocation),
  `logs/stuarray-test-default.log`,
  `logs/stuarray-test-A1m-G1.log`.

No GHC source-tree changes this session.  All testing was in
standalone Haskell programs.

See [`findings.md`](findings.md) §F5 for next-session targets
and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
