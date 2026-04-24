# Session 4 findings

## 1. POSIX signals fully working

`installHandler sigUSR1 (Catch h) Nothing` + `signalProcess sigUSR1
pid` + `threadDelay` + check counter.  Handler ran exactly 3 times
across 3 raises.  Tests `signalProcess`, POSIX `sigaction` handler
registration, signal-safe IORef bumps.

## 2. Weak pointers + GC finalizers working

`mkWeakIORef` + drop strong ref + `performGC` + `deRefWeak` →
`Nothing` and finalizer printed "finalizer ran".  This exercises:

- Weak pointer table in the runtime
- Finalizer queue dispatch after GC
- Major GC invocation via `performGC`

All work on 32-bit BE.

## 3. STM's retry+orElse + threadDelay interop works

Test 35 combines `atomically` + `retry` (implicit via `readTVar` in
an if branch), with a producer that uses `threadDelay` between
writes.  Consumer blocks via retry until the list has ≥3 items.
No deadlocks, no corruption.

## 4. Battery coverage approaching "wide enough"

34 tests now cover all of:
- Numeric (Int/Word/Float/Double/Integer bignum)
- Text (String/ByteString/Text)
- Collections (List/Map/Array)
- Class system (ADTs, deriving, typeclasses, Typeable)
- IO (file, env, args, exceptions, signals, show/read)
- Concurrency (IORef, MVar, forkIO, threaded RTS, STM)
- Memory (weak refs, performGC, long-running GC)
- FFI (ccall)
- Laziness

Remaining gaps (Network.Socket, profiling, Cabal, runghc) are either
substantial work or not ecosystem-critical for the MVP.  Diminishing
returns from here.

## Zero real bugs across 4 test-adding sessions

Out of 34 programs exercising a wide cross-section of Haskell's
stdlib surface, after the patch-0008 pi-Double fix, **no Haskell-level
bugs remain**.  Remaining 4 diffs are all "`Int` is 32-bit on PPC32"
and "`getpid`/`getProgName` differ between host and target" — test
design artifacts, not compiler issues.

That's a strong signal that the cross-compile path is solid for
real Haskell code.  Time to move up the stack (GHCi, stage2 native)
or out to ecosystem tooling (cabal, runghc).
