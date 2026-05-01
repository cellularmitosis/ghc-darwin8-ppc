# Roadmap — GHC 9.2.8 on PPC/Darwin 8

Last reviewed: 2026-04-29 session 16.

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

✅ **Profiling** (session 16, v0.10.0): `-prof -fprof-auto` produces
`.prof` cost-centre reports and `.hp` heap-profile files on Tiger.
Unblocked by the sister project's [LLVM-7 r4](https://github.com/cellularmitosis/llvm-darwin8-ppc/releases/tag/v7.1.1-r4)
(BUG-003 fix to the PPC asm printer's r0/ZERO operand) plus two
Tiger compat shims: `__MAC_OS_X_VERSION_MIN_REQUIRED` in our
cross-cc, and `tiger_strnlen` in `rts/RtsUtils.c` (patch 0015).

✅ **`network` 3.x** (session 13, v0.8.1): vendored at `vendor/network/`
with two `#ifdef` guards on `IP_RECVTOS` / `IPV6_TCLASS` (added in
macOS 10.7).  Real localhost TCP echo round-trip verified on Tiger.
The `SOCK_CLOEXEC` concern from session 7 was stale — already gated by
upstream's `HAVE_ACCEPT4` autoconf check.

✅ **TLS / HTTPS** (session 15, v0.9.0): `HsOpenSSL-0.11.7.10` vendored
at `vendor/HsOpenSSL/` with a 1-line `runInBoundThread` fallback
patch.  Builds against `tiger.sh`'s `openssl-1.1.1t`.  Real
`HTTP/1.1 200 OK` from Cloudflare via TLS 1.x verified on Tiger.
See `docs/sessions/2026-04-29-session-15-tls/`.

Remaining untested / future sessions:
- Dynamic linking (`-dynamic` disabled by QuickCross; 24-bit scattered reloc limit)
- HTTP client higher-level libraries (`http-client`, `req`, `wreq`).
  Should layer on top of working HsOpenSSL.  Future session.
- Threaded RTS / SMP — gcc14 on Tiger lacks `__atomic_*_8`
  intrinsics, so the threaded RTS won't link.  Workaround in
  `vendor/HsOpenSSL/` covers the TLS-handshake case; programs that
  really need OS-thread parallelism need either a `__atomic_*_8`
  shim, libatomic, or SMP rebuild.  Not blocking.

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

🟡 **GHCi REPL** — stage2 works as of v0.11.0, so an in-process
REPL is now reachable.  Not yet wired up; future session.  TH
end-to-end via `-fexternal-interpreter` already works (v0.8.0).

### B. Stage2 native `ghc` — 🟡 working with workaround (v0.11.0)

**The dragon was a GC bug.**  After ruling out (session 17):
- Optimiser passes (session 14's `simpleOptPgm` hypothesis).
- LLVM-7 PPC backend (rebuilt without `-fllvm`, same bug).
- User-level Bag/UniqSupply/atomic primitives (probes all PASS).

`+RTS -A1G -RTS` makes stage2 work: the giant allocation area
keeps small compiles inside one block, no GC fires, no bug.

✅ **v0.11.0** ships:
- `scripts/ghc-stage2-wrapper.sh` — one-line wrapper that adds
  `+RTS -A1G -RTS` so users don't have to think about it.
- `scripts/deploy-stage2.sh` — cross-build + deploy + smoke-test
  in one command.
- Demo: [`demos/v0.11.0-stage2-native.sh`](../demos/v0.11.0-stage2-native.sh)
  compiles `Hello.hs` and a `Data.Map.Strict` word-count program
  on Tiger and runs both end-to-end.

❌ **Underlying GC bug not yet fixed.**  See
[`docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md`](sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)
for the catalogue (which panic each input shape triggers, why
LLVM and unreg-C both fail, the threshold table for `-A` sizes).
Fixing the actual GC bug is multi-session work — likely a missing
PPC memory-fence in 9.2.8's RTS that 8.6.5 had.

**Older context, kept for the record:**
[session 14](sessions/2026-04-29-session-14-stage2-investigation/),
[experiments/006-stage2-native-ghc.md](experiments/006-stage2-native-ghc.md),
[proposals/stage2-native.md](proposals/stage2-native.md).

### ~~E. Upstream contribution~~ on hold (user request)

Paused until we're further down the road.

## Sister project touch-points

- **llvm-7-darwin-ppc** (private) — source of our cross clang + SDK
  + the underlying LLVM-7 PPC backend.  Our patch 0008 to
  `compiler/GHC/CmmToC.hs` is pure-Haskell and doesn't affect LLVM;
  no change to that project needed.
- **rogerppc** (private) — unrelated to this project.
