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
[**v0.14.2**](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2)
— **StaticPointers + GHCi `-fobject-code` packaging fix** 🪄.
[Patch 0017](patches/0017-rts-dso-handle-mach-o-underscore.patch)
teaches the runtime Mach-O loader's `__dso_handle` special case
about the platform underscore prefix.  Upstream's
`rts/Linker.c::lookupDependentSymbol` strcmps against the ELF
spelling `"__dso_handle"`, but on Mach-O the symbol arrives as
`"___dso_handle"` (three underscores).  Pre-fix, `:l Foo.hs` in
GHCi `-fobject-code` mode aborted with `unknown symbol
\`___dso_handle'` whenever the module had any `static` pointer —
the SPT init code calls `__cxa_atexit(_, _, __dso_handle)` which
emits an undefined external for the symbol.  Surfaced by [session
60](docs/sessions/2026-05-17-session-60-extra-run-opts-runner/)'s
extended ghci-tnum runner via T9878b.  Two-line patch matches both
spellings; T9878b flips to PASS, session-60 runner reports
**165/166** against the new bindist (only T17549's HFS+ mtime
race remains).  See [session 61](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/)
and [`demos/v0.14.2-static-pointers.sh`](demos/v0.14.2-static-pointers.sh).
Plus all of v0.14.1's literate Haskell, v0.14.0's GHCi REPL,
v0.13.0's `STUArray Bool` fix, v0.12.0's LLVM-8 swap, v0.11.0's
stage2 native ghc, v0.10.0's profiling, v0.9.0's HTTPS, etc.

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
| Stage2 native ghc | ✅ Working | [v0.13.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.13.0).  ~210 MB ppc-native `ghc` binary that compiles Haskell to PPC Mach-O on Tiger.  The `+RTS -A1G -RTS` workaround shipped in v0.11.0 / v0.12.0 is no longer needed: the bug it dodged was a single big-endian library bug in `libraries/array/Data/Array/Base.hs`'s `STUArray Bool` `newArray` ([patch 0016](patches/0016-array-stuarray-bool-word-aligned-init.patch), root-caused in [session 52](docs/sessions/2026-05-15-session-52-stuarray-scope/) after 11 sessions of bisection).  Deploy with `scripts/deploy-stage2.sh`.  The wrapper still ships for backwards compatibility but defaults to no extra RTS flags. |

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
| `network` (3.x) | ✅ Working | [v0.8.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.8.1).  Vendored at `vendor/network/` with two `#ifdef` guards on `IP_RECVTOS` / `IPV6_TCLASS` (added in macOS 10.7).  `SOCK_CLOEXEC` was a *non-issue* — already gated by the package's `HAVE_ACCEPT4` autoconf check, which our `tiger-config.site` correctly disables.  Smoke-test in [`tests/cabal-examples/network-echo-three/`](tests/cabal-examples/network-echo-three/). |
| TLS / HTTPS | ✅ Working | [v0.9.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.9.0).  `HsOpenSSL-0.11.7.10` vendored at `vendor/HsOpenSSL/` with a small `runInBoundThread` fallback patch.  Builds against `tiger.sh`'s `openssl-1.1.1t`.  Verified: real TLS 1.x handshake to example.com:443, fetched `HTTP/1.1 200 OK` from Cloudflare.  See [`tests/cabal-examples/https-get/`](tests/cabal-examples/https-get/) and [`vendor/HsOpenSSL/TIGER-PATCHES.md`](vendor/HsOpenSSL/TIGER-PATCHES.md). |
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
| GHCi REPL | ✅ Working | [v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0).  `ghc -e`, `ghc --interactive`, `:t`, `:load`, `let`/lambdas, `:{ :}` blocks, imports, `Data.Map.Strict` lookups — all running in-process on a real PowerMac G5 under Mac OS X 10.4.  No new patches; the load-bearing pieces (runtime Mach-O loader, BCO byte-swap, `__eprintf` stub) have been in place since v0.8.0; v0.13.0's `STUArray Bool` fix unblocked the last gating dep.  Build change: `scripts/deploy-stage2.sh` compiles `ghc/Main.hs` with `-DHAVE_INTERNAL_INTERPRETER` + `-i$GHC_SRC/ghc -package exceptions -package time` (the cabal `internal-interpreter` flag's effective contents).  **Testsuite verification ([session 56](docs/sessions/2026-05-15-session-56-ghci-testsuite/)):** 51/51 PASS on a curated subset of upstream's `testsuite/tests/ghci/scripts/` — every `normal`/`combined_output` script test that doesn't need extra harness (reqlib, req_th, etc.).  Covers `:type` / `:info` / `:load` / `:reload` / `:browse` / `:instances` / `:m` / `:set prompt` / multi-line `:{ :}` / `:main` / `:def` / TH-splice-from-REPL / static-pointers / `:doc` / record-wildcards / type families. Reusable harness in [`scripts/run-ghci-subset.sh`](docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/run-ghci-subset.sh).  **Extended verification ([session 58](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/)):** 161/163 PASS on the bug-numbered `T<NUM>.script` subset of the same dir (every `normal` / `combined_output` / `extra_files` test that doesn't need special harness).  Covers six TemplateHaskell-from-REPL regressions (T4127, T4127a, T5566, T8831, T10466, T11098), the `:reload` / `:load` / module-dependency family, type families + kind polymorphism, `StaticPtr`, type-applications, GADTs, and a long tail of `T<NNN>` issue-tracker regressions.  The two remaining failures (T8042, T17549) are HFS+ mtime-granularity races in the upstream scripts themselves — not PPC bugs.  Session 58 also surfaced a real **packaging bug** in the v0.14.0 bindist: `lib/bin/powerpc-apple-darwin8-unlit` was a host (arm64) binary, not PPC; Hadrian's cross-build host-copy carve-out in [patch 0010](patches/0010-hadrian-cross-iserv.patch) only excluded `iserv` but should also have excluded `unlit`.  **Fixed in [v0.14.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1)** ([session 59](docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/)) — patch 0010 amended to add `unlit` to the carve-out; cross-build's `buildBinary` path produces a real 47 KB PPC `unlit`; T10989 (literate Haskell `:l dummy.lhs`) now PASSes natively from the bindist, taking the session-58 runner to 161/163 PASS.  **Runner extension ([session 60](docs/sessions/2026-05-17-session-60-extra-run-opts-runner/)):** added `extra_run_opts(...)` support to `run-ghci-tnum.sh` and three new tests (T9878b, T12091, T17500).  T12091 + T17500 PASS clean (164/166).  T9878b surfaced a real PPC/Tiger bug — `rts/Linker.c::lookupDependentSymbol`'s `__dso_handle` special case strcmps against the ELF spelling but the Mach-O loader passes the underscore-prefixed `___dso_handle`, so static-pointer SPT-init's `__cxa_atexit` reference goes unresolved.  **Fixed in [v0.14.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2)** ([session 61](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/)) — [patch 0017](patches/0017-rts-dso-handle-mach-o-underscore.patch) matches both spellings; T9878b flips to PASS, taking the session-60 runner to **165/166** PASS against the new bindist (only T17549's HFS+ mtime race remains).  **Runner extension ([session 62](docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/)):** added `extra_hc_opts(...)` support to `run-ghci-tnum.sh` and six new tests (T2452, T2182ghci2, T9293, T13385, T14342, T16563).  All 6 PASS clean.  `normalise.py` gained a trailing-blank-line trim to absorb a 1-byte discrepancy between upstream's `T16563.stdout` and GHCi's actual output (reproduced on host ghc-9.2.8 too — test-data issue, not PPC).  Session-60+62 runner now reports **171/172** PASS; lone failure is T8042, the HFS+ mtime-race coin-flip that alternates with T17549. |
| GHCi debugger (`:break` / `:step` / `:trace` / `:print` / `:force` / `:list`) | ✅ Working | **Testsuite verification ([session 57](docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/)):** 83/83 PASS on a curated subset of upstream's `testsuite/tests/ghci.debugger/scripts/` — every `normal` / `combined_output` / plain `extra_files` test that doesn't need special harness.  Covers bytecode breakpoint insertion (`:break NAME` / `:break NUM` / `:break MOD.NAME`), single-step execution (`:step` / `:steplocal` / `:stepmodule`), execution history (`:trace` / `:hist` / `:back` / `:forward`), suspended-thunk introspection (`:print` / `:sprint`), thunk forcing (`:force`, `_result` rebinding), source listing (`:list`), dynamic break enable/disable/delete, and 15 bug-numbered `T<NNN>` regression tests including `T13825-debugger` (`expect_broken` for ppc64 — passes here on ppc32).  Reusable harness in [`scripts/run-ghci-debugger.sh`](docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/scripts/run-ghci-debugger.sh). |

### Tooling

| Tool | Status | Notes |
|---|---|---|
| `runghc-tiger` (compile + scp + ssh-run) | ✅ Working | [v0.5.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.5.0).  Bundled in bindist; `install.sh` patches the `PPC_HOST` default. |
| `ghc-pkg list/describe/field/latest/check` | ✅ Working | Verified [in session 10](docs/sessions/2026-04-24-session-10-runghc-and-ghc-pkg/).  Package conf db is target-arch-agnostic. |
| `cabal --with-compiler=<cross-ghc>` | ✅ Working | See "Cabal / Hackage" above. |
| Profiling (`-prof`, `+RTS -p`, `+RTS -h`) | ✅ Working | [v0.10.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.10.0).  Unblocked by [LLVM-7 r4](https://github.com/cellularmitosis/llvm-darwin8-ppc/releases/tag/v7.1.1-r4) (BUG-003 fix to PPC asm printer's r0/ZERO operand) plus two Tiger compatibility shims (`__MAC_OS_X_VERSION_MIN_REQUIRED=1040` to take the right Tiger branch in `rts/posix/OSThreads.c`; a `tiger_strnlen` inline in `rts/RtsUtils.c` since Tiger's libSystem predates POSIX 2008's `strnlen`).  Smoke-test in [`tests/profiling/`](tests/profiling/). |
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
- [`patches/`](patches/) — 17 patches to GHC 9.2.8 source
  re-enabling PPC/Darwin bits, including [patch 0016](patches/0016-array-stuarray-bool-word-aligned-init.patch)
  for the big-endian `STUArray Bool` bug and [patch 0017](patches/0017-rts-dso-handle-mach-o-underscore.patch)
  for the Mach-O `___dso_handle` strcmp.
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
| [v0.8.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.8.1) | 2026-04-29 | `network` 3.x works 🌐 (vendored `IP_RECVTOS` / `IPV6_TCLASS` ifdef guards). |
| [v0.9.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.9.0) | 2026-04-29 | **HTTPS works on Tiger** 🔐 (vendored `HsOpenSSL` `runInBoundThread` fallback + `tiger.sh` openssl-1.1.1t). |
| [v0.10.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.10.0) | 2026-04-29 | **Profiling works on Tiger** 📊 (LLVM-7 r4 BUG-003 fix + Tiger compat shims for `__MAC_OS_X_VERSION_MIN_REQUIRED` + `strnlen`). |
| [v0.11.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.11.0) | 2026-04-30 | **Stage2 native ghc works on Tiger** 🐯 (GC bug worked around with `+RTS -A1G -RTS`; `scripts/ghc-stage2-wrapper.sh` + `scripts/deploy-stage2.sh`). |
| [v0.12.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.12.0) | 2026-05-09 | **Cross-toolchain swap LLVM-7 → LLVM-8** 🔧 (sister-project's BUG-010 patch restored the PPC32 Darwin "power" alignment field-cap that LLVM-8 dropped; stage1 builds 3× faster). |
| [v0.13.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.13.0) | 2026-05-15 | **`STUArray Bool` big-endian root cause fixed** 🪄 (11-line patch to `libraries/array/Data/Array/Base.hs`; stage2 native ghc compiles real programs without the `-A1G` workaround.  Same root cause as previously-fixed-upstream [ghc#23132](https://gitlab.haskell.org/ghc/ghc/-/issues/23132); patch 0016 backports the equivalent fix into `array-0.5.4.0` — upstream's `bOOL_SCALE` rounding was added in `array-0.5.6.0`).  Closes the 32-session "stage2 produces empty .o" investigation. |
| [v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0) | 2026-05-15 | **GHCi REPL on PPC/Tiger** 🎉 (`ghc -e`, `ghc --interactive`, `:t`, `:load`, multi-line `:{ :}`, imports — all running in-process on a real PowerMac G5).  No new patches; `scripts/deploy-stage2.sh` now compiles `ghc/Main.hs` with `-DHAVE_INTERNAL_INTERPRETER` + `-i$GHC_SRC/ghc -package exceptions -package time` (the cabal `internal-interpreter` flag's effective contents).  Closes [roadmap C](docs/roadmap.md). |
| [v0.14.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1) | 2026-05-17 | **Literate Haskell (`.lhs`) works on Tiger** 📜 — Hadrian patch 0010 amended to add `unlit` alongside `iserv` in the cross-mode helper-binary-copy carve-out.  Pre-fix the v0.14.0 bindist shipped the host arm64 `unlit` with a `powerpc-apple-darwin8-` prefix (latent since v0.7.0 when patch 0010 landed; surfaced by [session 58](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/) via T10989).  Post-fix `unlit` cross-builds as a real 47 KB PPC Mach-O binary through hadrian's normal `buildBinary` path; session-58 runner re-runs at 161/163 PASS.  No other changes. |
| [v0.14.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2) | 2026-05-17 | **StaticPointers + GHCi `-fobject-code` work on Tiger** 🪄 — Two-line [patch 0017](patches/0017-rts-dso-handle-mach-o-underscore.patch) teaches `rts/Linker.c::lookupDependentSymbol`'s `__dso_handle` special case about Mach-O's leading-underscore prefix.  Pre-fix, the strcmp matched only the ELF spelling, so `:l Foo.hs` in GHCi `-fobject-code` mode failed with `unknown symbol \`___dso_handle'` whenever the module had a `static` pointer (SPT-init code references `__dso_handle` via `__cxa_atexit`).  Surfaced by [session 60](docs/sessions/2026-05-17-session-60-extra-run-opts-runner/) via T9878b; fixed in [session 61](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/).  Session-60 runner now reports 165/166 PASS (only T17549's HFS+ mtime race remains).  Upstream-shaped — same fix would help any Mach-O cross-GHC. |

## Licence

GHC is BSD-3-Clause.  Changes and additions here are BSD-3-Clause to
match.

## Credits

Built across many [Claude Code](https://claude.com/claude-code) sessions.
