# Session 3 — more test coverage (roadmap F)

**Date:** 2026-04-24.
**Starting state:** v0.3.0 tagged.  Test battery at 25 programs, 21
PASS byte-identical.  Untested areas listed in roadmap F:
threaded RTS, profiling, STM, sockets, signals, Data.Time,
System.Random, long-running GC, dynamic linking, Cabal consumers,
`runghc`, `ghc-pkg` commands.

**Goal:** add 6 more test programs covering high-value areas;
run them through the cross-compile → Tiger pipeline; catalog new
bugs.

**Ending state:** 6 new tests added (one removed as unavailable),
**all 5 remaining PASS byte-identical**.  **No new bugs found.**
Battery now at 30 programs; 26 PASS, 4 diff-expected (known test
design).

## What was added

- `26_threaded_rts.hs` — 4 threads × 250k atomicModifyIORef
- `27_stm.hs` — STM retry + bank transfer invariant
- ~~`28_random.hs`~~ — removed (`random` package not bundled)
- `29_data_time.hs` — Data.Time arithmetic
- `30_long_running.hs` — 10⁶ record allocations w/ Int64 sum = 3.5 × 10¹²
- `31_mvar_stress.hs` — 2 producers × 2 consumers over an MVar channel

All 5 remaining new tests PASS byte-identical to host output.  See
[findings.md](findings.md) for details.

## Lessons

- **Threaded RTS works fine on PPC** — atomicModifyIORef with
  contention held correctly, STM didn't corrupt invariants, long-
  running GC under 10⁶ allocations didn't crash.  Given our earlier
  `_hs_xchg64` patch (64-bit atomic force-link issue) this was
  non-obvious — but the 32-bit `hs_xchg32` / `hs_cmpxchg32` paths
  work perfectly.
- **`Int` in test programs = careful.**  Tests with numeric values
  over 2³¹ should pin to `Int64` to avoid host/target diffs.
- **Not every Haskell library is in a cross-compiler bindist.**
  `System.Random` needs `cabal install random`; our current bindist
  has no cabal.  Future session: tackle the Cabal-on-Tiger story.

## Hand-off

Battery is a clean 26/30 PASS.  Next sessions can pick up:
- **F continued:** Socket / network IO, signals, more GC stress.
- **C (GHCi / TH):** restore PPC Mach-O loader.  Bigger piece of work.
- **B (stage2 native):** gdb on pmacg5.  Biggest piece.
