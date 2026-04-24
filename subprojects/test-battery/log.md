# test-battery — log

## 2026-04-24

- Wrote 25 test programs under `tests/programs/`, covering numeric
  types, bignum, Char/String, lists, ADTs, type classes, file IO,
  exceptions, IORef/MVar, Bits, ByteString/Text, Array, forkIO, FFI.
- Wrote `tests/run-tests.sh`: compile on host ghc for expected output,
  compile with cross-ghc, scp to pmacg5, run, diff.
- First run: 20/25 byte-identical.  Diffs in 01 (Int size), 02 (pi),
  14 (progname), 24 (pid), 25 (Int size).
- Only 02 is a real bug — `pi :: Double` returns `8.6e97`.  Filed as
  `bug-pi-double-literal` subproject.
- Wrote [RESULTS.md](../../tests/RESULTS.md) with full table and bug
  writeup.
