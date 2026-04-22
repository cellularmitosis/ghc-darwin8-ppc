# Test corpus

A small set of Haskell programs that exercise different layers of
the compiler/RTS. Each one should compile and run on the GHC we
build for `powerpc-apple-darwin8`. Designed to be runnable under
**any** GHC ≥ 7.0 (ie no language extensions specific to modern
GHC, no `base` symbols added after 4.3.x), so that the same corpus
validates Path A (legacy 7.0/7.6) and Path B (modern 9.x).

Each program prints "OK <name>" on success. A wrapper
`run-all.sh` runs them all and reports pass/fail counts.

## Programs and what they exercise

| Program | What's exercised |
|---|---|
| `01-hello.hs` | Most-basic codegen, top-level IO, `putStrLn`, exit 0 |
| `02-arith.hs` | Integer + Double arithmetic, `IO` monad, `print` |
| `03-int64.hs` | 64-bit integer ops on a 32-bit target — needs the lowering rules in `PPC/CodeGen.hs` |
| `04-string.hs` | String list concat, `length`, `reverse` — RTS allocator |
| `05-iorefs.hs` | `IORef`, `modifyIORef`, mutation — RTS heap, write barriers |
| `06-data-map.hs` | `Data.Map.Strict` insert + lookup — `containers` library |
| `07-bytestring.hs` | `Data.ByteString.Char8` pack/unpack/length — `bytestring` library |
| `08-exceptions.hs` | `try`/`catch`/`throwIO` with `IOError` — RTS exception machinery |
| `09-ffi-puts.hs` | `foreign import ccall puts` — FFI call into libSystem |
| `10-args-env.hs` | `getArgs`, `lookupEnv` — System.Environment |
| `11-readfile.hs` | `readFile`, simple text I/O — System.IO |
| `12-forkio.hs` | `forkIO`, `MVar`, simple synchronization — RTS threading |

12 programs, ~150 lines total. Should self-validate the major
codegen + RTS subsystems we'll restore.

## Running locally (smoke-test on host platform first)

If you have `ghc` on the build host (any modern GHC), all of these
should compile and run there before we ship them to Tiger:

```bash
cd testprogs
./run-all.sh
```

Doesn't validate PPC/Darwin behaviour — just confirms the corpus
itself is correct Haskell.

## Running on Tiger

Once a `ghc` is installed on Tiger:

```bash
~/bin/tiger-rsync.sh testprogs/ pmacg5:/Users/macuser/tmp/ghc/testprogs/
ssh pmacg5 'cd /Users/macuser/tmp/ghc/testprogs && PATH=/usr/local/bin:$PATH ./run-all.sh'
```
