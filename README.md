# ghc-darwin8-ppc

GHC (the Glasgow Haskell Compiler) 9.2.8, resurrected for **PowerPC
Mac OS X 10.4 Tiger**.

PPC/Darwin support was removed from GHC in December 2018 (commit
[`374e44704b`](https://gitlab.haskell.org/ghc/ghc/-/commit/374e44704b),
first absent in 8.8.1).  This project brings it back on 9.2.8, with a
cross-build toolchain that runs on arm64 macOS and produces Mach-O PPC
binaries that execute on real Tiger hardware.

## Status

**Working cross-compile pipeline** as of 2026-04-24:

```
$ cat /tmp/hello.hs
main = putStrLn "hello from ppc darwin 8"

$ powerpc-apple-darwin8-ghc /tmp/hello.hs -o hello-ppc
$ scp hello-ppc pmacg5:/tmp/
$ ssh pmacg5 /tmp/hello-ppc
hello from ppc darwin 8
```

The `powerpc-apple-darwin8-ghc` binary is an arm64 Mac executable (the
*cross* compiler).  Its output is a PowerPC Mach-O binary
(`ppc_7400`).  Final linking is bridged via SSH to a Tiger PPC machine
running Tigerbrew's gcc14, because our local cross-ld doesn't speak
Tiger's crt1.

## What works

Verified byte-identical to host-GHC output across 25 test programs
(see [tests/RESULTS.md](tests/RESULTS.md)):

- Int / Word (8/16/32/64-bit sizes), Float, Integer (libgmp bignum)
- Char, String, Data.List (sort, nub, zip, folds, ranges)
- ADTs with `deriving (Show, Eq, Ord, Enum, Bounded)`
- Type classes with multiple instances
- `Show` / `Read` round-trip
- Maybe / Either / Data.Map / Data.ByteString / Data.Text / Data.Array
- Laziness (infinite lists, `take`, `repeat`, `cycle`, `iterate`)
- IORef, MVar, `forkIO` (non-threaded RTS)
- File IO (`writeFile`, `readFile`, `hGetLine`, `hClose`)
- Exceptions (`try`, `evaluate`, `catch`)
- Data.Bits (`.&.`, `.|.`, `xor`, `shiftL`/`R`, `popCount`)
- Data.Typeable (`typeOf`, `typeRep`)
- FFI (`ccall`, `CString`, `CInt`, `CSize`)

## What doesn't (yet)

- **`pi :: Double`** returns garbage (`8.6e97`) due to a 19-digit
  literal truncation in the unregisterised codegen.  Other Double
  literals ≤17 digits are fine.  See
  [subprojects/bug-pi-double-literal](subprojects/bug-pi-double-literal/).
- **Stage2 native ghc binary** runs `--version` but can't compile —
  typechecker's `tcl_env` comes up empty.  Deferred; see
  [docs/proposals/stage2-native.md](docs/proposals/stage2-native.md).
- **GHCi / TemplateHaskell** — the runtime Mach-O loader needs PPC
  relocation code restored.  See
  [docs/proposals/ghci-macho-loader.md](docs/proposals/ghci-macho-loader.md).
- **Profiling, dynamic libraries** — static-only (Quick-cross flavour
  dodges a PPC Mach-O 16 MB section limit for `.dyn_o`).

## Cabal / Hackage packages

**`cabal-install` on your arm64 macOS host compiles Hackage packages
for Tiger**, via our cross-ghc.  Seven top-level packages verified
end-to-end: `random` (via vendored splitmix), `async`, `vector`,
`aeson` (with Generics instead of TH), `optparse-applicative`,
`megaparsec`, `network` (pinned `< 3.0`).  30+ packages in their
transitive graphs.

See [`docs/cabal-cross.md`](docs/cabal-cross.md) for the recipe and
[`tests/cabal-examples/`](tests/cabal-examples/) for 8 runnable
project templates (with a `run-one.sh` that builds + ships + runs
on Tiger in one command).

## Build

Requires arm64 macOS with:

- Host GHC 9.2.8 ([download](https://www.haskell.org/ghc/download_ghc_9_2_8.html))
- `happy-1.20.1.1`, `alex-3.2.7.4` (via `cabal install`)
- clang 7.1.1 + `MacOSX10.4u.sdk` (from the sibling
  [llvm-7-darwin-ppc](https://github.com/cellularmitosis/llvm-7-darwin-ppc) project)
- cctools-port ld64-253.9-ppc branch from
  [tpoechtrager/cctools-port](https://github.com/tpoechtrager/cctools-port)
- Network-reachable PowerPC Tiger/Leopard box for final link
  (`pmacg5` in our setup; add its ssh alias before building)

Then:

```
git clone https://github.com/cellularmitosis/ghc-darwin8-ppc.git
cd ghc-darwin8-ppc
# ... fetch external/ghc-modern/ghc-9.2.8 source, apply patches/ ...
source scripts/cross-env.sh
cd external/ghc-modern/ghc-9.2.8
./hadrian/build --flavour=quick-cross --docs=none -j8
```

Takes about 16 minutes on an M-series Mac.

*(Detailed bootstrap instructions WIP in [subprojects/bindist-installer](subprojects/bindist-installer/).)*

## Layout

- [`docs/`](docs/) — plan, state, roadmap, experiment logs, ghc
  version discussion, cross-toolchain strategy, notes on fleet setup.
- [`patches/`](patches/) — 7 patches to GHC 9.2.8 source
  re-enabling PPC/Darwin bits.
- [`scripts/`](scripts/) — cross-env, `ppc-cc` wrapper, `ppc-ld-tiger`
  SSH shim, `tiger-config.site` (autoconf overrides), install-name
  shims.
- [`subprojects/`](subprojects/) — discrete workstreams, each with a
  plan/log/post-mortem.
- [`tests/`](tests/) — 25-program regression battery + runner.

## Licence

GHC is BSD-3-Clause.  Changes and additions here are BSD-3-Clause to
match.

## Credits

Built in ~15 Claude Code sessions over a week.
