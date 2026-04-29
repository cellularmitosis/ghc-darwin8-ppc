# Roadmap — GHC 9.2.8 on PPC/Darwin 8

Last reviewed: 2026-04-29 session 13.

## What's done (baseline)

- Stage1 cross-compiler on arm64 macOS → produces running PPC Mach-O binaries.
- 25-program test battery: 21 PASS byte-identical to host, 4 test-design
  diffs, 0 real bugs.
- ~117–124 MB `.tar.xz` cross-bindist packaged; tagged v0.1.0,
  v0.2.0 (pi fix), v0.3.0 (installer), v0.4.0 (cabal cross-compile
  docs), v0.5.0 (runghc-tiger bundled), v0.6.0 (PPC Mach-O runtime
  loader restored), v0.6.1 (Haskell `.o` loader test + resolveImports
  fix), v0.7.0 (PPC ghc-iserv built + SSH-piped TH protocol working),
  v0.7.1 (eprintf stub + DYLD + filesystem mirror docs),
  v0.7.2 (BR24 jump-island fix; all `.o` files including `base` load
  via iserv), **v0.8.0 (TemplateHaskell works end-to-end on Tiger 🎉)**.
- **pi-Double codegen bug fixed** (patch 0008) — `CmmToC.decomposeMultiWord`
  now recurses on 32-bit targets.
- **One-command install** — `./install.sh --prefix --ppc-host` bundled
  in the tarball.  Verifies prereqs, copies tree, writes settings,
  smoke-tests.
- Stage2 ppc-native `ghc` binary: runs `--version`, can't compile yet
  (see *Stage2 native ghc* below).

## Open engineering work

Ordered by the user's stated priority: **A → D → F → C → B → E**
(done ✅ = struck through).

### ~~A. Bug fixes from stress testing~~ ✅ done

*No user-facing bugs currently known.*
- ~~Double literals codegen~~ fixed by patch 0008 (session 1).

### ~~D. Bindist / install experience~~ ✅ done (v0.3.0)

- ~~Installer script that handles tarball + settings rewrite + smoke test~~.
- Follow-ups (later sessions):
  - CI (GitHub Actions can't run ppc; need custom runners or self-hosted).
  - Homebrew formula.
  - Bundle clang/SDK/cctools into one combined installer.

### F. More test coverage — mostly done (sessions 3 + 4 + 6)

✅ Done: threaded RTS, STM, Data.Time, long-running GC, MVar
stress, POSIX signals, Data.Map, weak refs + performGC, STM
retry+orElse (battery 30/34 PASS byte-identical).

✅ **Cabal cross-compile** (session 6, v0.4.0): 30+ Hackage
packages verified — random, splitmix (vendored), async, vector,
aeson, optparse-applicative, megaparsec + transitive deps.
Recipe in [`docs/cabal-cross.md`](cabal-cross.md).

✅ **`runghc-tiger`** (session 10, v0.5.0): a `runghc` analog that
makes sense for cross-compile — compile, scp to `$PPC_HOST`, ssh-run,
return exit code, clean up.  Bundled in the bindist; install.sh
patches the `PPC_HOST` default.

✅ **`ghc-pkg`** (session 10): standard commands all work via
`powerpc-apple-darwin8-ghc-pkg list/describe/field/latest/check`.

⚠️ **Profiling** (session 9, deferred): `-prof` builds hit a clang-7
PPC integrated-assembler bug (`lwz r2, 16(0)` rejected as
displacement-form base register).  Documented in
[`docs/sessions/2026-04-24-session-9-profiling/findings.md`](sessions/2026-04-24-session-9-profiling/findings.md).
Workarounds for a future session.

✅ **`network` 3.x** (session 13, v0.8.1): vendored at `vendor/network/`
with two `#ifdef` guards on `IP_RECVTOS` / `IPV6_TCLASS` (added in
macOS 10.7).  Real localhost TCP echo round-trip verified on Tiger.
The `SOCK_CLOEXEC` concern from session 7 was stale — already gated by
upstream's `HAVE_ACCEPT4` autoconf check.

Remaining untested / future sessions:
- Dynamic linking (`-dynamic` disabled by QuickCross; 24-bit scattered reloc limit)
- TLS / HTTPS — `tiger.sh` provides modern openssl on Tiger, so the
  path is "build hsopenssl / tls against /opt/tiger.sh's openssl".

### ~~C. GHCi / TemplateHaskell~~ ✅ TH done (session 12f, v0.8.0)

✅ **PPC runtime Mach-O loader restored.**  Patch 0009 brings back
`relocateSection()` for PPC, adapted from GHC 8.6.5 to 9.2.8's
per-section restructured API.  `loadObj` + `resolveObjs` +
`lookupSymbol` + calling the loaded code works end-to-end on Tiger.
Test in `tests/macho-loader/`:
- `PPC_RELOC_VANILLA` (scattered + non-scattered) ✅
- `PPC_RELOC_BR24` + jump-island for out-of-range `bl`s ✅
- `PPC_RELOC_HI16/LO16/HA16/LO14` (scattered + non-scattered) ✅ —
  exercised by `tests/macho-loader/run-haskell.sh` (loads a real
  Haskell `.o` whose 261 text relocs are mostly HI16/LO16/HA16
  pairs into `__nl_symbol_ptr`).
- `PPC_RELOC_SECTDIFF` family ✅ — same Haskell `.o` test exercises
  scattered LOCAL_SECTDIFF in `__eh_frame`.

❌ **GHCi REPL** still blocked on stage2 (roadmap B) — no in-process
ghc to compile splice expressions.

⚠️ **TemplateHaskell end-to-end — partial.**  v0.7.0/v0.7.1 ship:
- PPC `ghc-iserv` (29.7 MB), bundled in the bindist `lib/bin/`.
- `pgmi-shim.sh` SSH bridge for `-pgmi=` (with DYLD path).
- Patch 0010: enable iserv + libiserv in cross-builds.
- Patch 0011: `__eprintf` stub for ghc-bignum/gmp loads.

What works (with manual filesystem mirror — see release notes):
- iserv runs on Tiger.
- TH `loadObj` succeeds for small Haskell `.o`s (ghc-prim,
  integer-gmp, bignum).

✅ **Session 12e (v0.7.2):** BR24 jump-island fix.  `symbol_extras`
now placed inside the RX segment's mmap so jump islands always
stay within ±32 MB of all text sections.  All `.o` files load
via iserv, including the multi-MB `base.o`.  Patch 0009 grew
from 461 → 524 lines; patch 0012 enables `SHORT_REL_BRANCH` and
`USE_CONTIGUOUS_MMAP` for PPC.

✅ **Session 12f (v0.8.0):** TH end-to-end on Tiger.  Two bugs:
(a) cross-built `binary` library mis-encoded Generic-derived sum
tags as Word64 instead of Word8 ([patch 0013](../patches/0013-binary-generic-direct-numeric-guards.patch));
(b) BCO array contents need byte-swap on host/target endian
mismatch ([patch 0014](../patches/0014-ghci-bco-byteswap-on-endian-mismatch.patch)).
After both fixes, `$(stringE "...")` and friends evaluate on Tiger
and splice into the output binary.  See [`docs/sessions/2026-04-24-session-12-iserv-ppc/12f-th-end-to-end.md`](sessions/2026-04-24-session-12-iserv-ppc/12f-th-end-to-end.md).
Demo: [`demos/v0.8.0-th-splice.hs`](../demos/v0.8.0-th-splice.hs).

❌ **GHCi REPL** still blocked on stage2 (roadmap B).  TH end-to-end
via `-fexternal-interpreter` works; an in-process REPL would need
a working stage2 native ghc.

### B. Stretch: stage2 native `ghc` bug

Current 128 MB ppc-native `ghc` binary runs `--version` but panics on
compile with `StgToCmm.Env: variable not found $trModule3_rwD`.
Typeable binding generation works in TC but fails in codegen.  Bypass
with `-dno-typeable-binds` lets non-main modules compile.

`:Main.main` synthesis also fails separately — `tcLookupId main_name`
finds empty tcl_env.

Both smell like "runtime state isn't wired up" — `HscEnv`, `DynFlags`
IORefs, maybe something specific to PPC32 atomics (given our earlier
`_hs_xchg64` patch, the atomics ABI is suspect).

Needs gdb on pmacg5 for a ppc-native Haskell runtime trace, or
careful comparison against a known-good stage2 build (chicken-and-egg).

See [`docs/experiments/006-stage2-native-ghc.md`](experiments/006-stage2-native-ghc.md)
and [`docs/proposals/stage2-native.md`](proposals/stage2-native.md).

### ~~E. Upstream contribution~~ on hold (user request)

Paused until we're further down the road.

## Sister project touch-points

- **llvm-7-darwin-ppc** (private) — source of our cross clang + SDK
  + the underlying LLVM-7 PPC backend.  Our patch 0008 to
  `compiler/GHC/CmmToC.hs` is pure-Haskell and doesn't affect LLVM;
  no change to that project needed.
- **rogerppc** (private) — unrelated to this project.
