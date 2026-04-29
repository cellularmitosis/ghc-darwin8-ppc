# ghc-darwin8-ppc

![](docs/media/haskell-tiger.png)

GHC (the Glasgow Haskell Compiler) 9.2.8, resurrected for **PowerPC
Mac OS X 10.4 Tiger**.

PPC/Darwin support was removed from GHC in December 2018 (commit
[`374e44704b`](https://gitlab.haskell.org/ghc/ghc/-/commit/374e44704b),
first absent in 8.8.1).  This project brings it back on 9.2.8, with a
cross-build toolchain that runs on arm64 macOS and produces Mach-O PPC
binaries that execute on real Tiger hardware.

## Status

**Working cross-compile pipeline** as of 2026-04-25:

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

Latest release:
[**v0.8.0**](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.8.0)
— **TemplateHaskell works end-to-end on Tiger** 🎉.  First-ever TH on
PPC/Darwin8 since GHC 8.6 (2018).

## Implementation status

A live accounting of which parts of GHC the cross-build implements,
approximates, or explicitly stubs.  Updated as each release lands.

### Compiler & cross-build

| Feature | Status | Notes |
|---|---|---|
| Cross-compile (`powerpc-apple-darwin8-ghc`) | ✅ Working | 134 MB arm64 binary that emits PPC Mach-O.  Built via `hadrian --flavour=quick-cross`.  ~16 minutes from scratch on M-series Mac. |
| Final link (Tiger crt1 / dyld) | ✅ Working | `ppc-ld-tiger.sh` ssh's to `$PPC_HOST` for the link step (Tigerbrew gcc14 + ld there).  Wrapped transparently by the cross-cc. |
| Bindist tarball | ✅ Working | `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz` (~123 MB) on every GitHub release.  Includes `install.sh`, `cross-scripts/`, `lib/bin/ghc-iserv` (since v0.7.0). |
| `install.sh --prefix --ppc-host` | ✅ Working | One-command install (since [v0.3.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.3.0)).  Detects cctools/clang/SDK from canonical locations, writes `lib/settings`, recaches ghc-pkg, smoke-tests. |
| Stage2 native ghc | 🟡 Partial | 128 MB ppc-native `ghc` binary that runs `--version`, panics on compile in `StgToCmm.Env` (Typeable lookup).  Bypass with `-dno-typeable-binds` lets non-main modules compile.  See [`docs/experiments/006-stage2-native-ghc.md`](docs/experiments/006-stage2-native-ghc.md). |

### Language & libraries (verified on Tiger)

Verified byte-identical to host-GHC output across the
[25-program test battery](tests/RESULTS.md) (30/34 PASS, 4 expected
differences from 32-bit Int / process-pid / program-name).

| Surface | Status | Notes |
|---|---|---|
| Int / Word (8/16/32/64) | ✅ Working | 32-bit native sizes; Int64/Word64 via libgmp / RTS helpers. |
| Float / Double | ✅ Working | IEEE 754 single + double.  `pi :: Double` was broken in v0.1.0 (literal truncation in 32-bit codegen); fixed in [v0.2.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.2.0) by [patch 0008](patches/0008-cmmtoc-split-w64-double-on-32bit.patch). |
| Integer (libgmp) | ✅ Working | Cross-linked against `/opt/gmp-6.2.1/lib/libgmp.dylib` on Tiger; F(100) = 354224848179261915075. |
| Char / String / Data.List | ✅ Working | `sort`, `nub`, `zip`, folds, ranges all match host-GHC byte-for-byte. |
| ADTs + `deriving (Show, Eq, Ord, Enum, Bounded)` | ✅ Working | |
| Type classes, multiple instances | ✅ Working | |
| `Show` / `Read` round-trip | ✅ Working | |
| `Maybe` / `Either` / `Data.Map` / `Data.ByteString` / `Data.Text` / `Data.Array` | ✅ Working | All boot libs cross-built; same package set as a host GHC 9.2.8. |
| Lazy evaluation (infinite lists, `take`, `repeat`, `cycle`, `iterate`) | ✅ Working | |
| `IORef`, `MVar`, `forkIO` | ✅ Working | Non-threaded RTS by default; threaded RTS also built (`thr` way present in libHSrts variants). |
| File IO (`readFile`, `writeFile`, `hGetLine`, `hClose`) | ✅ Working | |
| Exceptions (`try`, `catch`, `evaluate`) | ✅ Working | |
| `Data.Bits` (`.&.`, `.\|.`, `xor`, `shiftL/R`, `popCount`) | ✅ Working | |
| `Data.Typeable` (`typeOf`, `typeRep`) | ✅ Working | |
| FFI (`ccall`, `CString`, `CInt`, `CSize`) | ✅ Working | |
| Threaded RTS, STM, `Data.Time` | ✅ Working | Verified in [test battery sessions 3+4](docs/sessions/). |
| MVar stress, POSIX signals, weak refs + performGC | ✅ Working | Same. |
| STM `retry` + `orElse` | ✅ Working | Same. |
| Long-running GC | ✅ Working | Same. |

### Cabal / Hackage cross-build

| Surface | Status | Notes |
|---|---|---|
| `cabal build --with-compiler=<cross-ghc>` | ✅ Working | [v0.4.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.4.0).  Cabal solver sees our cross-GHC, resolves Hackage deps, builds each with the cross-compiler.  Recipe in [`docs/cabal-cross.md`](docs/cabal-cross.md). |
| `random` (+ vendored splitmix) | ✅ Working | splitmix vendored at `vendor/splitmix/` — replaces `Security/SecRandom.h` (Tiger-absent) with `/dev/urandom`.  15-line patch. |
| `async` | ✅ Working | + transitive `hashable`, `unordered-containers`, `primitive`. |
| `vector` | ✅ Working | + `vector-stream`, `primitive`. |
| `aeson` (Generics, not TH) | ✅ Working | + ~20 transitive deps incl. `scientific`, `text-iso8601`. |
| `optparse-applicative` | ✅ Working | + `prettyprinter`, `ansi-terminal`. |
| `megaparsec` | ✅ Working | + `parser-combinators`, `case-insensitive`. |
| `network` | 🟡 Pinned `< 3.0` | Newer versions reference `SOCK_CLOEXEC` (added in 10.7) in `Cbits.hsc`.  3.x would need vendoring with `#ifdef` guards. |
| 8 ready-to-go example projects | ✅ Working | [`tests/cabal-examples/`](tests/cabal-examples/) with `run-one.sh` that builds + scp + ssh-runs. |

### Runtime linker (loadObj / resolveObjs / lookupSymbol)

| Capability | Status | Notes |
|---|---|---|
| Load a hand-compiled C `.o` | ✅ Working | [v0.6.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.6.0).  `relocateSection` for PPC restored from GHC 8.6.5 reference, adapted to 9.2.8's per-section restructured API.  See [patch 0009](patches/0009-restore-ppc-runtime-macho-loader.patch). |
| Load a real Haskell `.o` | ✅ Working | [v0.6.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.6.1).  Caught a pre-existing 9.2.8 `resolveImports` bug (used old monolithic-image addressing instead of per-section mmap). |
| Load a multi-MB Haskell `.o` (`base.o`, ~3 MB) | ✅ Working | [v0.7.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.2).  BR24 jump-island fix: `oc->symbol_extras` now placed inside the RX segment's mmap, guaranteed within ±32 MB of every text section. |
| `PPC_RELOC_VANILLA` (scattered + non-scattered) | ✅ Working | C + Haskell smoke tests. |
| `PPC_RELOC_BR24` + jump-island | ✅ Working | C smoke test exercises the extern-call path through `_puts`. |
| `PPC_RELOC_HI16/LO16/HA16` (scattered + non-scattered) | ✅ Working | Haskell smoke test (261 in `__text` of `Greeter.o`). |
| `PPC_RELOC_SECTDIFF` family | ✅ Working | Haskell smoke test (44 scattered LOCAL_SECTDIFF in `__eh_frame`, 12 in `__DATA,__const`). |

### TemplateHaskell / external interpreter

| Capability | Status | Notes |
|---|---|---|
| Cross-build PPC `ghc-iserv` | ✅ Working | [v0.7.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.0).  29.7 MB PPC binary bundled in the bindist `lib/bin/`.  See [patch 0010](patches/0010-hadrian-cross-iserv.patch). |
| `pgmi-shim.sh` (SSH bridge for `-pgmi=`) | ✅ Working | 30-line bash wrapper at [`scripts/pgmi-shim.sh`](scripts/pgmi-shim.sh).  Bridges ghc's local-iserv pipe fds to remote `ghc-iserv` on Tiger via SSH stdio.  Sets `DYLD_LIBRARY_PATH` for libgmp. |
| Spawn iserv on Tiger via SSH | ✅ Working | Verified iserv prints its usage banner; binary protocol round-trips. |
| `loadObj` of all bindist `.o`s through iserv | ✅ Working | [v0.7.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.2).  ghc-prim, integer-gmp, ghc-bignum, **base** all load successfully. |
| `__eprintf` symbol resolution | ✅ Working | [v0.7.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.1).  Tiger's libSystem has the symbol but doesn't export it, so `dlsym` fails.  RTS now ships its own stub via [patch 0011](patches/0011-rts-eprintf-stub.patch). |
| TH splice end-to-end (host ghc → SSH → iserv → result) | ✅ Working | [v0.8.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.8.0).  `$(stringE …)`, `$(litE …)`, compile-time arithmetic — all evaluated by `ghc-iserv` on Tiger, then spliced into the output binary by host GHC.  Two bugs caught during 12f: (a) cross-built `binary` library mis-encoded Generic-derived sum tags as Word64 instead of Word8 ([patch 0013](patches/0013-binary-generic-direct-numeric-guards.patch)); (b) BCO array contents need byte-swap on host/target endian mismatch ([patch 0014](patches/0014-ghci-bco-byteswap-on-endian-mismatch.patch)). |
| GHCi REPL | ❌ Missing | Needs stage2 native ghc working (currently panics on Typeable lookup) — see roadmap B.  Use `-fexternal-interpreter` instead (full TH support). |

### Tooling

| Tool | Status | Notes |
|---|---|---|
| `runghc-tiger` (compile + scp + ssh-run) | ✅ Working | [v0.5.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.5.0).  Bundled in bindist; `install.sh` patches the `PPC_HOST` default. |
| `ghc-pkg list/describe/field/latest/check` | ✅ Working | Verified [in session 10](docs/sessions/2026-04-24-session-10-runghc-and-ghc-pkg/).  Package conf db is target-arch-agnostic. |
| `cabal --with-compiler=<cross-ghc>` | ✅ Working | See "Cabal / Hackage" above. |
| Profiling (`-prof`, `hp2ps`) | 🟡 Deferred | clang-7's PPC integrated assembler rejects `lwz r2, 16(0)` displacement-form syntax that clang's own backend emits for `-prof -O2` builds.  Documented in [session 9 findings](docs/sessions/2026-04-24-session-9-profiling/findings.md). |
| Dynamic linking (`-dynamic`) | ❌ Missing | Disabled by `quick-cross` flavour: `GHC.Hs.Instances` as `dyn_o` blows past PPC Mach-O's 24-bit scattered-reloc / 16 MB section limit. |
| TLS / HTTPS | ❌ Missing | Needs Tiger-compatible openssl in the package set.  Not yet attempted. |

## Demos

[`demos/`](demos/) — one runnable Haskell program per release,
showcasing what each one unlocked.  See [`demos/README.md`](demos/README.md)
for the full table.  Quick build via:

```
$ scripts/runghc-tiger demos/v0.1.0-hello.hs
hello from ppc darwin 8
```

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

Most users should grab the prebuilt
[**bindist tarball**](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/latest)
and run `./install.sh --prefix=$PREFIX --ppc-host=<your-tiger-ssh-alias>`
instead.

## Layout

- [`docs/`](docs/) — plan, state, roadmap, ghc version discussion,
  cross-toolchain strategy, dated session logs.
- [`docs/sessions/`](docs/sessions/) — per-session narratives
  (README + findings + commits).  See
  [`docs/sessions/README.md`](docs/sessions/README.md).
- [`patches/`](patches/) — 12 patches to GHC 9.2.8 source
  re-enabling PPC/Darwin bits.
- [`scripts/`](scripts/) — `cross-env.sh`, `ppc-cc` wrapper,
  `ppc-ld-tiger` SSH shim, `runghc-tiger`, `pgmi-shim.sh`,
  `tiger-config.site` (autoconf overrides), install-name shims,
  `install.sh` (bindist installer).
- [`tests/`](tests/) — 25-program regression battery + 8 cabal
  examples + macho-loader test driver + th-iserv test.
- [`demos/`](demos/) — one runnable Haskell program per release.
- [`vendor/`](vendor/) — Tiger-friendly forks (currently just
  `splitmix` with `/dev/urandom` instead of `SecRandomCopyBytes`).

## Releases

| Tag | Date | Headline |
|---|---|---|
| [v0.1.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.1.0) | 2026-04-24 | First working cross-compile to Tiger PPC. |
| [v0.2.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.2.0) | 2026-04-24 | `pi` is 3.14 again 🥧 (Double-literal codegen fix, patch 0008). |
| [v0.3.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.3.0) | 2026-04-24 | One-command `install.sh`. |
| [v0.4.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.4.0) | 2026-04-24 | Cabal cross-compile works 🎊 (30+ Hackage packages). |
| [v0.5.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.5.0) | 2026-04-25 | `runghc-tiger` 🐅 bundled. |
| [v0.6.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.6.0) | 2026-04-25 | PPC Mach-O runtime loader 🔌 restored (patch 0009). |
| [v0.6.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.6.1) | 2026-04-25 | Haskell `.o` loads at runtime 🐧 (`resolveImports` fix). |
| [v0.7.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.0) | 2026-04-25 | PPC `ghc-iserv` 🛰 + `pgmi-shim.sh` (patch 0010). |
| [v0.7.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.1) | 2026-04-25 | TH gets closer 🎯 (`__eprintf` stub + DYLD, patch 0011). |
| [v0.7.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.2) | 2026-04-25 | `base.o` loads via iserv ⛓️ (BR24 jump-island fix, patch 0012). |
| [v0.8.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.8.0) | 2026-04-29 | **TemplateHaskell works on Tiger** 🪄 (patches 0013 + 0014). |

## Licence

GHC is BSD-3-Clause.  Changes and additions here are BSD-3-Clause to
match.

## Credits

Built across many [Claude Code](https://claude.com/claude-code) sessions.
