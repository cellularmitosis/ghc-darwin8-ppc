# Cross-build test battery results — 2026-04-24

**Summary: 30 of 34 tests PASS with byte-identical output to host.**
Session 4 added 4 more tests (POSIX signals, Data.Map heavy use,
weak refs + performGC, STM retry+orElse).  All PASS.  The 4 non-
matching tests are all test-design issues (Int width, getpid,
progname), not bugs.  **No real bugs known as of this run.**

## History

- **Session 0 (first run before fix):** 20 PASS, 1 real bug (`pi :: Double`).
- **Session 1 (after pi fix):** 21 PASS, 0 real bugs, `02_double_literal`
  byte-identical after patch 0008.
- **Session 3:** 26 PASS out of 30.  New tests 26–27, 29–31
  all PASS.  Threaded RTS, STM, long-running GC (10⁶ allocations),
  Data.Time, MVar-contention producer/consumer all work.
- **Session 4 (this run):** 30 PASS out of 34.  New tests 32–35 all
  PASS.  POSIX signals (installHandler + raise + catch), Data.Map
  heavy use, weak refs + performGC, STM retry + orElse all work.

## Full test coverage

| # | Test | Status | Notes |
|---|------|--------|-------|
| 01 | Int arith | DIFF-expected | Int is 32-bit on PPC, 64-bit on arm64 |
| 02 | Double literal | PASS | Fixed by patch 0008 (CmmToC W64 Float decompose) |
| 03 | Double runtime (sqrt/sin/exp/log) | PASS | |
| 04 | Float literals | PASS | |
| 05 | Word8/16/32/64, Int8/16/32/64 sizes | PASS | |
| 06 | Integer bignum (libgmp) | PASS | F(100), 2^200 etc. |
| 07 | Char / String | PASS | |
| 08 | List ops (sort, zip, folds, `[1..10]`) | PASS | |
| 09 | Maybe / Either | PASS | |
| 10 | ADT deriving (Show/Eq/Ord/Enum/Bounded) | PASS | BST traversal too |
| 11 | Type classes + instances | PASS | |
| 12 | Show / Read round-trip | PASS | |
| 13 | File IO (writeFile/readFile/openFile/hGetLine/hClose) | PASS | |
| 14 | getArgs/getProgName/lookupEnv | DIFF-expected | progname differs (test design) |
| 15 | Exceptions (try/evaluate/catch) | PASS | |
| 16 | IORef + MVar | PASS | |
| 17 | Data.Bits (.&., .|., xor, shift, popCount) | PASS | |
| 18 | ByteString (strict + lazy) | PASS | |
| 19 | Data.Text | PASS | |
| 20 | Laziness (take, repeat, cycle, iterate) | PASS | |
| 21 | Data.Typeable (typeOf, typeRep) | PASS | Works via cross-ghc (unlike native stage2) |
| 22 | Data.Array (listArray, 2D, accumArray) | PASS | |
| 23 | forkIO + MVar synchronisation | PASS | Non-threaded RTS |
| 24 | FFI (getpid, strlen, abs via `ccall`) | DIFF-expected | pid differs (test design) |
| 25 | Numeric boundaries (max/minBound, Int overflow, 1/0, 0/0, NaN) | DIFF-expected | Int is 32-bit |
| 26 | Threaded RTS (-threaded + atomicModifyIORef + 4 threads × 250k increments) | PASS | counter exactly 1000000 |
| 27 | STM (atomically / retry / 2 threads transferring) | PASS | invariant preserved |
| 29 | Data.Time (epoch, fromGregorian, addDays, diffDays, TimeOfDay) | PASS | |
| 30 | Long-running allocation (10⁶ records, Int64 sum 3.5 trillion) | PASS | GC under pressure |
| 31 | MVar stress (2 producers × 2 consumers, 200 items) | PASS | non-threaded RTS |
| 32 | POSIX signals (installHandler + raise SIGUSR1 × 3) | PASS | signalProcess + Catch handler |
| 33 | Data.Map heavy (fromList, map, filter, keys/elems) | PASS | |
| 34 | Weak references + performGC | PASS | finalizer ran correctly |
| 35 | STM retry + orElse (producer/consumer with timeout) | PASS | |

## Fixed bugs

### BUG-1 [FIXED]: `pi :: Double` returns garbage on PPC

**Fix:** [`patches/0008-cmmtoc-split-w64-double-on-32bit.patch`](../patches/0008-cmmtoc-split-w64-double-on-32bit.patch).
Recurse in `decomposeMultiWord` for `CmmFloat n W64` on 32-bit targets
so the resulting W64 int gets further split into two W32 ints.  See
[session 1 findings](../docs/sessions/2026-04-24-session-1-workflow-and-pi-probe/findings.md)
for the full analysis.

**Original reproduction (now all correct):**

```haskell
main = do
  putStrLn $ "pi = " ++ show (pi :: Double)        -- was 8.6e97; now 3.141592653589793
  putStrLn $ "1.5 = " ++ show (1.5 :: Double)      -- was 1.5 (always correct)
  putStrLn $ "3.14159265358979 = " ++ show (3.14159265358979 :: Double)  -- always correct
```

**What is `pi`?** Defined in `libraries/base/GHC/Float.hs`:

```haskell
instance Floating Double where
    pi = 3.141592653589793238
```

**Root cause hypothesis:** The literal `3.141592653589793238` has 19
significant digits — one more than Double's precision.  In the
unregisterised codegen path, GHC emits this Double constant as a C `.hc`
source constant.  We saw this warning at build time:

```
warning: implicit conversion from 'StgWord64' (aka 'unsigned long long')
         to 'StgWord' (aka 'unsigned int')
         changes value from 4614256656552045848 to 1413754136
         [-Wconstant-conversion]
```

`4614256656552045848` = `0x400921FB54442D18` = IEEE 754 bit pattern of
Double π.  So GHC is asking clang to convert a 64-bit value into a
32-bit `StgWord`, and clang truncates.  The resulting `pi` closure
holds a wrong bit pattern, shows as `8.6e97`.

**Surprising part:** simpler literals like `1.5`, `2.5`, `3.14`,
`3.14159265358979` come out correctly — their upper 32 bits differ from
their lower 32 bits in ways that let the NCG path (for direct literals)
use a different encoding than the Floating-class instance does.

**Why 14-digit literals work but 19-digit doesn't:** GHC's literal
parser creates a `Rational` then eagerly converts to Double.  For 14
digits, the `Rational → Double` conversion is exact-ish and the StgToCmm
emission uses a routed path that's PPC-safe.  For 19 digits, a
different path triggers the `.hc` emission that hits the truncation bug.

**Fix direction:** either
1. GHC: fix unregisterised codegen to emit 64-bit Double literals as
   two 32-bit StgWord stores (big-endian order) instead of a single
   truncating cast.
2. base: redefine `pi` with ≤17 digits (`3.141592653589793`).  Would be
   an upstream patch but feels wrong — GHC should handle any literal.

## "Diff-expected" explanations

### 01 / 25: `Int` bound values differ

`Int` is 32-bit on PPC32, 64-bit on arm64.  Expected and working as
intended per Haskell Report: `Int` has a platform-dependent size ≥ 30 bits.

### 14: `getProgName` differs

Host binary is `14_env_args-host`; Tiger binary is renamed to
`/tmp/ghc-test-bin` by the harness.  No bug.

### 24: `getpid` differs

Different machines, different PIDs.  FFI round-trip is otherwise
correct.

## What the tests exercise

- RTS: non-threaded (stable), heap alloc, minor/major GC via laziness + large lists
- base: numeric classes, lists, tuples, ADTs, typeclasses, deriving, records, Show/Read, Data.{Char,List,Bits,Typeable,IORef,Array}
- bytestring, text, containers (Map) — all three fully functional
- unix: file IO, fork, env, signals
- FFI: ccall imports, withCString, CInt/CString/CSize marshalling
- Concurrency: MVar + forkIO (non-threaded RTS — forkIO is cooperative)

## What's NOT tested (deferred)

- Threaded RTS (`-threaded` flag + capabilities)
- Profiling (`-prof`)
- GHCi (stage2 blocked)
- TemplateHaskell (stage2 blocked + MachO loader stub)
- Cabal library compilation (Data.Map, Data.Text used as consumers — not yet building a lib)
- `runghc`, `ghc-pkg`
- Long-running programs (>1s CPU)
- Socket/network IO
- Large-memory programs (`-H1G` or similar)
- Dynamic linking (`-dynamic`) — skipped by QuickCross flavour
- STM (`atomically`, `retry`)
- POSIX signals handler
