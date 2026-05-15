# Session 51 log

## 2026-05-15 — session start

- Read HANDOFF.md from session 50.  Session 50 pinned the
  corruption locus to `Data.Graph.scc` in
  `libraries/containers/containers/src/Data/Graph.hs:650`.
- Baseline tests run (background): 30 PASS / 4 FAIL_OUTPUT —
  matches session-49/50 noise floor.

## Plan — strip the bug to its essentials

Session 50's HANDOFF prioritized writing a standalone test of
`Data.Graph.scc`.  Session 51 took that to its logical
conclusion across five iterations:

| iter | test           | what it does                          | reproduces? |
|------|----------------|---------------------------------------|-------------|
| 1    | scc_test.hs    | single pass, sizes 1-128, `scc`       | NO (default & -A1m) |
| 2    | scc_test2.hs   | 1000-iter loop + burnGC interleaved   | YES (8-vertex, 19% default, 97% -A1m) |
| 3    | scc_test3.hs   | sweep sizes 1-256                     | YES (6-24, 48 BAD; others OK) |
| 4    | scc_test4.hs   | inlined scc with probes (STUArray)    | YES — chop visits vertex 3 first call |
| 5    | stuarray_test.hs | just newArray + readArray           | YES — 84% bad rate |

The minimal repro is just `newArray (0, 7) False :: ST s (STUArray
s Int Bool)` followed by `readArray`.

## Per-iteration details

### iter 1 — scc_test.hs

Built scc test with sizes 1, 2, 4, 8, 32, 128.  Single-pass and
100-iter loop.  Both default RTS and -A1m -G1.  All passed.

**Did not reproduce.**  The single-pass nature doesn't generate
enough GC pressure.

### iter 2 — scc_test2.hs

Added `burnGC` (allocate-and-throw-away [1..1000] computation)
before and after each scc call.  Ran 1000 iterations per size.

**Reproduced**: 8-vertex, default RTS, 191/1000 bad;
-A1m -G1, 966/1000 bad.  Host uranium: 0 bad — confirms
PPC32-unreg-specific.

[`logs/scc_test2-output.log`](logs/scc_test2-output.log)

### iter 3 — scc_test3.hs

Swept graph size 1 through 256.  500 iterations each.

**Default RTS:** sizes 1-5 OK, 6-24 BAD, 28 OK, 32 OK, 48 BAD,
64+ OK.

**-A1m -G1:** sizes 1-2 OK, 3-24 BAD, 28-32 OK, 48 BAD, 64+ OK.

Bug is size-sensitive but not monotonic.  Heap-layout-dependent.

### iter 4 — scc_test4.hs

Re-implemented `dfs` / `prune` / `chop` / `generate` /
`postOrd` / `transposeG` inline.  Initially used `STArray`
(boxed).  Did NOT reproduce.  Switched to `STUArray` (unboxed
bit array).  **Reproduced.**

Trace shows the first bad iteration (size 8):
- `prune_chop_in_len = 8`
- `prune_chop_out_len = 6`

Then drilled inside `chop` with per-call probes.  Found:
- chop visits vertex 0 → fresh, mark True
- chop visits vertex 1 → fresh, mark True
- chop visits vertex 2 → fresh, mark True
- **chop visits vertex 3 → VISITED** (impossible — array is
  fresh, no write to position 3 yet)
- chop visits 4-7 → fresh
- Result: 7 trees instead of 8

**The STUArray Bool, freshly allocated with `False`, has
spurious True bits.**

### iter 5 — stuarray_test.hs (THE MINIMAL REPRO)

Pared down to just the STUArray test:

```haskell
checkFresh :: Int -> [Bool]
checkFresh n = runST $ do
  arr <- newArray (0, n - 1) False :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]
```

Loop 10000 times with burnGC interleaved.

**Default RTS: 8431/10001 bad.  -A1m -G1: 8655/10001 bad.**
**Host uranium: 0/10001 bad.**

Sample bad outputs (random bit patterns):
- `[False,False,False,False,True,False,False,True]`
- `[True,False,True,False,True,True,True,True]`
- `[False,False,True,True,True,False,True,False]`

[`logs/stuarray-test-default.log`](logs/stuarray-test-default.log),
[`logs/stuarray-test-A1m-G1.log`](logs/stuarray-test-A1m-G1.log).

## Conclusion

**The bug is in GHC's RTS allocation/zeroing of
`MutableByteArray#` on PPC32 unreg.**  Specifically, when
`newArray :: ST s (STUArray s Int Bool)` allocates a small
unboxed bit array, the contents aren't reliably zeroed under
GC pressure.

This is the root cause of every probe finding from sessions
42-50.  Session 42's "empty .o file" symptom traces all the
way back to STUArray's allocation being miscompiled / mis-zeroed.

## Files this session

* `README.md`, `log.md` (this), `findings.md`, `HANDOFF.md`,
  `commits.md`.
* `scc_test.hs` (v1), `scc_test2.hs` (v2 interleaved),
  `scc_test3.hs` (v3 size sweep), `scc_test4.hs` (v4 inlined
  + probes), `stuarray_test.hs` (v5 minimal repro).
* `logs/baseline-tests-start.log`,
  `logs/scc_test2-output.log` (11K lines, includes the bad
  iterations),
  `logs/stuarray-test-default.log`,
  `logs/stuarray-test-A1m-G1.log`.

No GHC source modifications.  Baseline at session-end: 30 PASS
/ 4 FAIL_OUTPUT — matches session-49/50 noise floor.

Session ends CLEAN.
