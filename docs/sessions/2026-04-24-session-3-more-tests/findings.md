# Session 3 findings

## 1. Threaded RTS works on PPC

Test `26_threaded_rts.hs` spawns 4 threads each doing 250,000
`atomicModifyIORef'` increments of a shared `IORef Int`.  Expected
total 1,000,000; got 1,000,000.

This exercises the RTS's atomics on 32-bit BE PPC.  No bugs.  Given
our prior `_hs_xchg64` patch this could have been suspect — but
`atomicModifyIORef'` on an `Int` only needs word-sized atomic CAS,
and `hs_cmpxchg32` / `hs_xchg32` are defined.

## 2. STM works

Test `27_stm.hs`: two threads each do 50 `atomically (transfer ...)`
calls, some of which `retry`.  Total account balance invariant held
across all runs.  Works.

## 3. Data.Time works

Test `29_data_time.hs` exercises `posixSecondsToUTCTime`,
`fromGregorian`, `addDays`, `diffDays`, `TimeOfDay`.  All correct.

## 4. Long-running GC works

Test `30_long_running.hs`: 10⁶ record allocations, computing an
Int64 sum that ends up at 3.5 × 10¹².  Output matches host exactly.
RTS minor + major GC under pressure, no crashes or corruption.

## 5. Producer/consumer MVar contention (non-threaded) works

Test `31_mvar_stress.hs`: 2 producers × 2 consumers over a shared
MVar channel.  Item sum invariant held.

## 6. `System.Random` isn't in the base install

Removed `28_random.hs` — `random` package ships separately on
Hackage, not bundled with our cross-compiler bindist.  Would need
`cabal install random` on the host (but our build chain doesn't
support Hackage installs yet — that's a future session's work).

## 7. Test 30 Int-platform-dependence

First iteration of test 30 used `Int`.  Host (arm64) gave Int64
result `3500003500000`; PPC (32-bit) gave `-394846240` (Int32
overflow, same value as expected under Int32 so the in-program
"match" check passed).  Fixed by using `Int64` explicitly so host
and PPC produce byte-identical output.

Reminder: `Int`'s width is platform-dependent per the Haskell Report.
Tests with numeric values that might exceed 2³¹ should pin to `Int64`.
