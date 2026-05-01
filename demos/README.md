# demos/

Real Haskell programs that compile with the cross-toolchain and run
on Mac OS X 10.4 Tiger.  One demo per release, showcasing what each
release unlocked.

These exist to make the project's progress concrete: it is one thing
to say "the runtime Mach-O loader works"; it is another to ship a
Tiger-running Haskell program that uses it to load and call into a
freshly cross-compiled `.o`.

## What's here (v0.11.0)

| File | Demonstrates | Added in |
|---|---|---|
| [`v0.1.0-hello.hs`](v0.1.0-hello.hs) | First running Haskell program on Tiger PPC.  putStrLn + RTS startup/teardown via the SSH-bridged final link. | [v0.1.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.1.0) |
| [`v0.2.0-pi.hs`](v0.2.0-pi.hs) | `pi :: Double` prints `3.141592653589793` (was `8.6e97` pre-fix).  Exercises 32-bit `decomposeMultiWord` for `CmmFloat n W64` (patch 0008). | [v0.2.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.2.0) |
| [`v0.3.0-self-locate.hs`](v0.3.0-self-locate.hs) | A bindist sanity demo: uses `getExecutablePath`, `getProgName`, `getArgs`.  Should run straight off a fresh `install.sh`. | [v0.3.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.3.0) |
| [`v0.4.0-cabal-aeson/`](v0.4.0-cabal-aeson/) | Uses `aeson` (a Hackage package, ~20 transitive deps) via cabal cross-compile to round-trip a record through JSON. | [v0.4.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.4.0) |
| [`v0.5.0-runghc-args.hs`](v0.5.0-runghc-args.hs) | Verifies argv + exit code round-trip cleanly through `runghc-tiger` (compile + scp + ssh-run + propagate exit code). | [v0.5.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.5.0) |
| [`v0.6.0-runtime-load.hs`](v0.6.0-runtime-load.hs) | Calls the restored runtime PPC Mach-O loader directly via `initLinker` / `loadObj` / `resolveObjs` / `lookupSymbol`.  Loads a hand-compiled C `.o` and calls a function in it. | [v0.6.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.6.0) |
| [`v0.6.1-haskell-load.hs`](v0.6.1-haskell-load.hs) | Loads a real Haskell `.o` via the loader.  Exercises HI16/LO16/HA16 + scattered SECTDIFF (the reloc surface a C source doesn't reach).  Caught a 9.2.8 `resolveImports` bug along the way. | [v0.6.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.6.1) |
| [`v0.7.0-iserv-banner.sh`](v0.7.0-iserv-banner.sh) | Bash probe: ssh's to Tiger, asks the freshly cross-built `ghc-iserv` to print its usage banner.  Confirms the iserv binary boots end-to-end (RTS + base + libiserv + ghci linked + `dieWithUsage` reachable). | [v0.7.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.0) |
| [`v0.7.1-eprintf-stub.hs`](v0.7.1-eprintf-stub.hs) | Computes `21!` (forces ghc-bignum / libgmp), proving the bignum codepath works statically.  v0.7.1's `__eprintf` stub is what unblocks bignum loading via iserv (where `dlsym` can't see the symbol). | [v0.7.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.1) |
| [`v0.7.2-large-load.hs`](v0.7.2-large-load.hs) | Loads `HSbase-4.16.4.0.o` (~3 MB) through the runtime linker.  Pre-v0.7.2 this tripped `BR24 jump island also out of range`; with the symbol_extras-in-RX-segment fix it's clean. | [v0.7.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.7.2) |
| [`v0.8.0-th-splice.hs`](v0.8.0-th-splice.hs) | **TemplateHaskell splices on Tiger.**  `$(stringE "...")`, `$(litE (integerL ...))`, compile-time arithmetic — all evaluated by `ghc-iserv` running on a real PowerMac G5, then spliced into the output binary.  First-ever TH on PPC/Darwin8 since GHC 8.6 (2018).  Closes [roadmap C](../docs/roadmap.md). | [v0.8.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.8.0) |
| [`v0.8.1-tcp-echo.hs`](v0.8.1-tcp-echo.hs) | **Real TCP socket round-trip on Tiger** via vendored `network-3.2.8.0`.  Localhost echo server + client; "hello tiger" → "echo: hello tiger".  Two `#ifdef` guards in `vendor/network/` work around `IP_RECVTOS` / `IPV6_TCLASS` (10.7+) absences in the 10.4u SDK. | [v0.8.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.8.1) |
| [`v0.9.0-https-get.hs`](v0.9.0-https-get.hs) | **HTTPS to the real internet from Tiger.**  TLS 1.x handshake against example.com:443 via vendored `HsOpenSSL` + `tiger.sh`'s OpenSSL 1.1.1t.  Receives Cloudflare's `HTTP/1.1 200 OK` and the HTML body.  Vendor patch replaces three `runInBoundThread` calls with a fallback that runs in the current thread when the (PPC32-impossible) threaded RTS isn't available. | [v0.9.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.9.0) |
| [`v0.10.0-mandel-prof.hs`](v0.10.0-mandel-prof.hs) | **Cost-centre + heap profiling on Tiger.**  Mandelbrot printer compiled with `-O -prof -fprof-auto` runs natively on Tiger and emits a real `.prof` cost-centre report + `.hp` heap-profile file.  Unblocked by [LLVM-7 r4](https://github.com/cellularmitosis/llvm-darwin8-ppc/releases/tag/v7.1.1-r4) (BUG-003 fix to PPC asm printer) plus two Tiger compatibility shims (`__MAC_OS_X_VERSION_MIN_REQUIRED` macro definition + a `strnlen` shim in `rts/RtsUtils.c`). | [v0.10.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.10.0) |
| [`v0.11.0-stage2-native.sh`](v0.11.0-stage2-native.sh) | **Native ghc on Tiger.**  Stage2 ghc binary running on a real PowerMac G5 compiles a `Hello` and a `Data.Map.Strict` word-count program, prints expected output for both.  No host involvement.  GC bug worked around with the `ghc-stage2-wrapper.sh` script that adds `+RTS -A1G -RTS` (see [session 17 GC-BUG-FOUND](../docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)).  Closes [roadmap B](../docs/roadmap.md). | [v0.11.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.11.0) |

## Building & running

The simplest route is `runghc-tiger`, which cross-compiles, scp's
to `$PPC_HOST`, runs there, propagates exit code, cleans up:

```
$ scripts/runghc-tiger demos/v0.1.0-hello.hs
hello from ppc darwin 8

$ scripts/runghc-tiger demos/v0.2.0-pi.hs
pi      = 3.141592653589793
exp 1   = 2.718281828459045
sqrt 2  = 1.4142135623730951

$ scripts/runghc-tiger demos/v0.5.0-runghc-args.hs alpha beta gamma
runghc-tiger demo: runghc-tiger-NNNNN-v0.5.0-runghc-args
  argc = 3
  argv = ["alpha","beta","gamma"]
$ echo $?
3
```

Some demos take arguments (`v0.5.0-runghc-args.hs`,
`v0.6.0-runtime-load.hs`, `v0.6.1-haskell-load.hs`,
`v0.7.2-large-load.hs`).  Pass them after the script path.

The cabal demo is multi-file and uses `tests/cabal-examples/run-one.sh`
(or follow the recipe in [`docs/cabal-cross.md`](../docs/cabal-cross.md)):

```
$ cd demos/v0.4.0-cabal-aeson && bash ../../tests/cabal-examples/run-one.sh .
```

## Adding a demo per release

The project policy (see [`CLAUDE.md`](../CLAUDE.md#release-workflow)):
**every release ships at least one demo** that showcases what the
release unlocked, named `vX.Y.Z-<slug>.hs` (or `.sh` for bash, or a
subdir for cabal projects).  Adding the demo + a row in this table
+ a "Demo" section in the release notes are part of the release
checklist.

The aim is that someone discovering the project at an arbitrary
release tag can scan this directory, pick a `.hs`, run it via
`runghc-tiger`, and *see* the new capability work.  No shell-history
spelunking required.

## Why these aren't in `tests/`

`tests/` is for regression coverage — programs whose output must
match host-GHC's byte-for-byte across releases.  `demos/` is for
narrative — short focused examples meant to be read first, run
second.  Some demos do duplicate test code (the v0.6.x loader demos
mirror `tests/macho-loader/`); the duplication is intentional, so
the demo file is self-contained reading.
