# demos/

Real Haskell programs that compile with the cross-toolchain and run
on Mac OS X 10.4 Tiger.  One demo per release, showcasing what each
release unlocked.

These exist to make the project's progress concrete: it is one thing
to say "the runtime Mach-O loader works"; it is another to ship a
Tiger-running Haskell program that uses it to load and call into a
freshly cross-compiled `.o`.

## What's here (v0.14.2)

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
| [`v0.12.0-llvm8-swap.sh`](v0.12.0-llvm8-swap.sh) | **Cross-toolchain on LLVM-8.**  Same v0.11.0 demo recipe, but the cross-clang that compiled the underlying GHC RTS / libraries / stage2 ghc-bin is now LLVM-8.0.1 (with the sister project's BUG-010 patch — PPC32 Darwin "power" struct alignment field-cap restored).  Prints clang's version banner up front to confirm; user-program output is unchanged from v0.11.0.  Closes [roadmap G](../docs/roadmap.md). | [v0.12.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.12.0) |
| [`v0.13.0-bool-bug-fix.sh`](v0.13.0-bool-bug-fix.sh) | **The 32-session-old "stage2 emits empty `.o`" bug is dead.**  Writes Big2.hs (a 30-LOC `Data.Map.Strict` + `Data.List` program — the reproducer that's been the reference test case since session 27) to Tiger and compiles it 5× with the patched stage2 — pre-fix, every iteration produced a 152-byte empty `.o`; post-fix, every iteration produces a fully-populated 46340-byte `.o`.  Then `--make`s a Big2Main executable, runs it on Tiger, and prints the output of Big2's functions — proving stage2's output is functionally correct, not just non-empty.  Root cause: an 11-line big-endian-only bug in upstream `libraries/array/Data/Array/Base.hs`'s `STUArray Bool` `newArray` ([patch 0016](../patches/0016-array-stuarray-bool-word-aligned-init.patch), [session 52](../docs/sessions/2026-05-15-session-52-stuarray-scope/)).  Closes [roadmap B](../docs/roadmap.md). | [v0.13.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.13.0) |
| [`v0.14.0-ghci-repl.sh`](v0.14.0-ghci-repl.sh) | **GHCi REPL on PPC/Tiger.**  ssh's to pmacg5 and exercises the in-process internal interpreter four ways: (1) `ghc -e` one-shot expressions (`sum [1..100]`, `Data.List.sort`, `product [1..15]`, `putStrLn`); (2) `ghc --interactive` with stdin (`:t reverse`, `:t (+)`, let-bindings, lambdas, `iterate`, `Data.Char.toUpper`, `Data.Map.Strict.fromListWith`); (3) `:load` of a real Haskell module followed by calls to its functions (`greet`, `factorial 20`, `fib`, `sortUnique`); (4) a multi-line `:{ :}` block defining `collatz` and evaluating it.  No new patches — all the load-bearing pieces (runtime Mach-O loader, BCO byte-swap, `__eprintf` stub) have been in place since v0.8.0; the last gating dep was stage2 native ghc compiling without `-A1G`, which v0.13.0 unblocked.  v0.14.0 simply enables `-DHAVE_INTERNAL_INTERPRETER` in `scripts/deploy-stage2.sh`'s manual `ghc/Main.hs` build (the cabal `internal-interpreter` flag's effective contents).  Closes [roadmap C](../docs/roadmap.md). | [v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0) |
| [`v0.14.1-literate-haskell.{lhs,sh}`](v0.14.1-literate-haskell.sh) | **Literate Haskell (`.lhs`) end-to-end on Tiger.**  A bird-track `.lhs` source (factorial / sort / toUpper / collatz) is `scp`'d to pmacg5, compiled by stage2 native ghc (whose `.lhs` pre-processing step invokes the bindist's `unlit` helper), the resulting binary runs, then the same `.lhs` is `:load`ed into the GHCi REPL — exercising both the file-on-disk and REPL paths through `unlit`.  Pre-v0.14.1 every step would have failed with `cannot execute binary file` (exit 126) because Hadrian shipped the host arm64 `unlit` with a `powerpc-apple-darwin8-` prefix.  v0.14.1's amended [patch 0010](../patches/0010-hadrian-cross-iserv.patch) makes hadrian cross-build a real PPC `unlit` (47 KB Mach-O) into the bindist. | [v0.14.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1) |
| [`v0.14.2-static-pointers.{hs,sh}`](v0.14.2-static-pointers.sh) | **StaticPointers + GHCi `-fobject-code` work on PPC/Tiger.**  A module with four `static` pointers of different shapes (Bool, String, `Int -> Int` closure, `[Int] -> Int` closure) is `scp`'d to pmacg5 and exercised three ways: (1) native compile + run prints `True`, the string, `42`, `55` from `deRefStaticPtr` calls; (2) `ghc --interactive -fobject-code` loads the module's `.o` (the path that was broken pre-v0.14.2) and `:m + GHC.StaticPtr` makes `deRefStaticPtr` available in the REPL; (3) `main` is invoked from inside the REPL.  Pre-v0.14.2 step 2 aborted with `unknown symbol \`___dso_handle'` because `rts/Linker.c::lookupDependentSymbol`'s `__dso_handle` special case only matched the ELF spelling; the Mach-O symbol is underscore-prefixed (`___dso_handle`).  Two-line fix in [patch 0017](../patches/0017-rts-dso-handle-mach-o-underscore.patch) matches both spellings.  Step 0 of the demo greps the deployed `ghc-real` for both strings to confirm the fix is in. | [v0.14.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2) |

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
