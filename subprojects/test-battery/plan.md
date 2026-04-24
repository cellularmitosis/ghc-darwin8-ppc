# test-battery — plan

## Goal

Exercise many independent Haskell features through the stage1
cross-ghc → pmacg5 pipeline.  Compare byte-for-byte against host
(arm64) output.  Use this as a regression net and a bug-finding tool.

## Approach

- Each test is a standalone `.hs` file under `tests/programs/`.
- Tests use only `base` + big-three libraries (`bytestring`, `text`,
  `containers`) — things any Haskell user expects.
- `tests/run-tests.sh` compiles each test with both host GHC and the
  cross-ghc, ships the ppc binary to pmacg5, runs it, and diffs the
  outputs.
- Expected outputs live in `tests/expected/`; actual in `tests/actual/`.

## Current coverage (25 tests)

See [tests/RESULTS.md](../../tests/RESULTS.md) for the full table.
Categories: numeric types, Integer bignum, Char/String, Lists,
Maybe/Either, ADTs + deriving, type classes, Show/Read, File IO,
getArgs/env, exceptions, IORef/MVar, Data.Bits, ByteString, Text,
laziness, Typeable, Data.Array, forkIO (non-threaded RTS), FFI
(ccall).

## Gaps (future additions)

- Threaded RTS (`-threaded`)
- Profiling (`-prof`, `-p`)
- STM (`atomically`, `retry`)
- Socket / network IO
- Long-running programs (GC under pressure)
- Dynamic linking (currently disabled by QuickCross flavour)
- Cabal package consumer (build a library from Hackage)
- Signal handling (installHandler)
- Random (System.Random)
- Data.Time

## Runner improvements wanted

- Report FAIL summaries more cleanly (bash `set -u` interacts badly
  with empty arrays — currently crashes on the summary line).
- Parallelize the per-test SSH link (currently serial; could run 4–8
  in parallel).
- Record wall time per test to spot regressions.
