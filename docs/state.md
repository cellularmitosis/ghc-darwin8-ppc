# state.md — where are we right now

*Updated: 2026-04-29 session 13 (post-v0.8.1, `network` 3.x sockets work).*

## Headline

**GHC 9.2.8 builds and runs Haskell programs on PowerPC Mac OS X 10.4 Tiger.**
First time since commit 374e44704b removed PPC/Darwin support in Dec 2018.

Three programs verified on real Tiger hardware (pmacg5):
- `hello.hs`  — `putStrLn` → "hello from ppc darwin 8"
- `fib.hs`    — lazy infinite list + libgmp Integer → F(100) = 354224848179261915075
- `stdin.hs`  — getContents + Data.List.{sort,nub} → sorted unique words

Plus a 34-program test battery (see [`tests/RESULTS.md`](../tests/RESULTS.md))
— 30 PASS byte-identical to host output, 4 test-design diffs (Int
size differences between 32-bit PPC and 64-bit arm64, process-pid /
program-name differences).  **No real bugs.**

Plus **30+ Hackage packages** cross-compiled via `cabal-install` and
running on Tiger (random, splitmix, async, vector, aeson, optparse-applicative,
megaparsec, and their transitive deps — see
[`docs/cabal-cross.md`](cabal-cross.md)).

Each test binary is 8–12 MB statically-linked Mach-O PPC executable.

## Two flavors of "working"

### 1. Cross-compile toolchain (RECOMMENDED — fully working)

Runs on arm64 macOS (uranium), produces PPC binaries, final link shipped
via SSH to pmacg5.

- `external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc`
  (134 MB arm64 binary — the cross-compiler)
- 33 libraries registered in `_build/stage1/lib/package.conf.d/` as ppc
- Bindist tarball at
  `external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`
  (117 MB — includes `install.sh` at the root and `cross-scripts/runghc-tiger`).
  Released on GitHub as
  [v0.5.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.5.0).
  Install flow: `tar xJf <tarball> && cd ghc-9.2.8-powerpc-apple-darwin8 && ./install.sh --prefix=$PREFIX --ppc-host=<ssh-alias>`.
  After install, `$PREFIX/bin/runghc-tiger foo.hs [args]` compiles +
  scp's + ssh-runs the result on the configured Tiger box.

**Usage:**
```
source scripts/cross-env.sh
_build/stage1/bin/powerpc-apple-darwin8-ghc hello.hs -o hello-ppc
scp hello-ppc pmacg5:/tmp/ && ssh pmacg5 /tmp/hello-ppc
```

### 2. PPC-native `ghc` binary (RUNS BUT CAN'T COMPILE)

128 MB Mach-O `ppc_7400` executable.  `ghc --version` prints the banner.
`ghc -c foo.hs` panics inside `StgToCmm.Env` on a Typeable lookup.
Documented in `docs/experiments/006-stage2-native-ghc.md`, deferred.

## Infrastructure

### Tools on uranium (arm64 macOS), under `~/.local/`:

- Host GHC 9.2.8: `~/.local/ghc-9.2.8/bin/ghc`
- Host GHC wrapper (auto-mkdir): `~/.local/ghc-boot-wrap/bin/ghc`
- Cross clang 7.1.1: `~/.local/ghc-ppc-xtools/clang`
- Clang resource-dir: `~/.local/lib/clang/7.1.1/`
- 10.4u SDK: `~/.local/ghc-ppc-xtools/MacOSX10.4u.sdk/`
- cctools-port ld64-253.9-ppc: `~/.local/cctools-ppc/install/bin/powerpc-apple-darwin8-*`
- happy 1.20.1.1, alex 3.2.7.4: `~/.local/bin/`
- PPC gmp.h (32-bit limbs, from pmacg5): `~/.local/ghc-ppc-xtools/include-ppc/gmp.h`
- Cross-CC wrapper: `~/.local/ghc-ppc-xtools/bin-wrap/ppc-cc` (tracked at `scripts/ppc-cc.sh`)
- Tiger-link SSH shim: `~/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-tiger` (tracked at `scripts/ppc-ld-tiger.sh`)
- Fake linker (for autoconf): `~/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-fake`
- ld shim (routes `-r` merge-objects via SSH): installed as `~/.local/cctools-ppc/install/bin/powerpc-apple-darwin8-ld` (tracked at `scripts/ppc-ld-shim.sh`)
- install_name_tool shim (routes PPC Mach-O rewrites via SSH): `~/.local/bin/install_name_tool`
- Cross-env: `source scripts/cross-env.sh` sets PATH + CONFIG_SITE + CROSS_CC etc.

### On pmacg5 (PowerPC Tiger 10.4.11), under `/opt/`:

- gcc 14.2 (Tigerbrew / port): `/opt/gcc14/bin/gcc`, `/opt/gcc14/bin/ld`
- gmp 6.2.1: `/opt/gmp-6.2.1/lib/libgmp.dylib`, includes at `/opt/gmp-6.2.1/include/gmp.h`

### Patches in `patches/` (applied to `external/ghc-modern/ghc-9.2.8/`)

1. `0001-libffi-gate-go-closure-on-ppc-darwin.patch` — libffi 3.3-rc2 had `ffi_go_closure` used unconditionally in `ffi_darwin.c`; gate behind `FFI_GO_CLOSURES`.
2. `0002-restore-32bit-machotypes-for-ppc.patch` — add 32-bit ppc/i386 case to `MachOTypes.h`.
3. `0003-restore-loadarchive-ppc-darwin.patch` — restore PPC case in `LoadArchive.c`.
4. `0004-macho-c-ppc-symbol-extras-and-reloc-include.patch` — `ocAllocateExtras_MachO` for PPC plus `<mach-o/ppc/reloc.h>`.
5. `0005-posixsource-h-no-posix-c-source-on-darwin.patch` — skip `_POSIX_C_SOURCE` define on Darwin (Tiger compat).
6. `0006-quickcross-static-only.patch` — `hadrian QuickCross` flavour: `libraryWays = [vanilla]` (static only).
7. `0007-rts-gate-hs_xchg64-on-64bit.patch` — gate `-Wl,-u,_hs_xchg64` behind 64-bit word size.
8. `0008-cmmtoc-split-w64-double-on-32bit.patch` — recurse `decomposeMultiWord` in `CmmToC.hs` for `CmmFloat n W64` on 32-bit targets, so closures holding Doubles get a full 12-byte layout (con-info + hi32 + lo32) instead of 8 bytes (con-info + truncated 32-bit).  Fixes `pi :: Double` and any Double in a static closure.
9. `0009-restore-ppc-runtime-macho-loader.patch` — restore `relocateSection` for PPC in `rts/linker/MachO.c` (deleted in commit 374e44704b, the GHC 8.8.1 release).  Adds `relocateSectionPPC()` + `relocateAddressPPC()` adapted from 8.6.5 to 9.2.8's per-section restructured API; fixes `ocVerifyImage_MachO` to accept 32-bit `MH_MAGIC` for PPC/i386.  Also fixes a pre-existing 9.2.8 bug in `resolveImports` that wrote through `oc->image + sect->offset` (old monolithic-image addressing) instead of `oc->sections[i].start` (per-section mmap), tripping `checkProddableBlock` on real Haskell `.o` loads.  Verified end-to-end with `tests/macho-loader/run.sh` (C source) and `tests/macho-loader/run-haskell.sh` (Haskell source, exercises HI16/LO16/HA16 + scattered SECTDIFF).
10. `0010-hadrian-cross-iserv.patch` — enable `iserv` + `libiserv` packages for cross-builds (default they're gated behind `not cross`), and special-case the hadrian program-rule so iserv builds from source for the target rather than copying from a (non-existent) stage0 host iserv.  The resulting PPC `ghc-iserv` (29.7 MB) is shipped in the bindist; users plumb it via `pgmi-shim.sh` for `-fexternal-interpreter` over SSH.
11. `0011-rts-eprintf-stub.patch` — register a `__eprintf` symbol in `RTS_PPC_DARWIN_SYMBOLS` so the runtime loader can resolve `___eprintf` references emitted by old-gcc-style `assert()` macros in ghc-bignum / gmp.  The stub function definition lives in `rts/linker/MachO.c` (folded into patch 0009).  Tiger's libSystem has the symbol but doesn't export it, so `dlsym` can't find it — providing our own stub bypasses that.
12. `0012-rts-ppc-contiguous-mmap-and-symbol-extras-near-text.patch` — enable `SHORT_REL_BRANCH` and `USE_CONTIGUOUS_MMAP` for PPC darwin so the loader knows it has the same ±32 MB BR24 limit as ARM32.  The actual fix for symbol_extras placement (so jump islands stay within BR24 range of all text sections) lives in patch 0009: `ocBuildSegments_MachO` reserves space at the end of the RX segment and `oc->symbol_extras` is overridden to point there.  Unblocks loading large `.o` files like `base.o` via iserv.
13. `0013-binary-generic-direct-numeric-guards.patch` — rewrite `Data.Binary.Generic`'s `gput`/`gget` for sum types to use direct numeric comparisons (`size <= 0x100`) instead of the original CPP-macro-expanded `(size - 1) <= fromIntegral (maxBound :: Word8)` chain.  The cross-built ppc-darwin8 GHC mis-compiled the original pattern, always selecting the Word64 branch even when size <= 256 — leading to host emitting 1-byte tags but target reading 8-byte tags for the same Generic-derived sum.  Affected the iserv binary protocol's encoding of `ResolvedBCOPtr` (5 constructors).
14. `0014-ghci-bco-byteswap-on-endian-mismatch.patch` — replace the "mixed endianness not supported" error in `GHCi.CreateBCO` with a recursive byte-swap of the BCO's `instrs` (Word16), `bitmap` (Word64), `lits` (Word64), and any nested `ResolvedBCOPtrBCO` BCOs.  Required because `getArray`/`putArray` write/read raw bytes in host endian — host (arm64 LE) and target (PPC32 BE) disagree.  Together with patch 0013 lands TH end-to-end (v0.8.0).

Additional in-tree edits NOT tracked as patches (regenerated by autoreconf):
- `mk/config.h`: `#undef HAVE_PTHREAD_SET_NAME_NP`, `HAVE_PTHREAD_SETNAME_NP{,_DARWIN}`, `HAVE_EVENTFD`
- `rts/rts.cabal`, `rts/rts.cabal.in`, `rts/package.conf.in`: gate `_hs_xchg64` / `_hs_cmpxchg64` by 64-bit
- `rts/package.conf.in`: strip `mingwex` from `extra-libraries`
- `rts/linker/MachO.c`: PPC stub in `ocResolve_MachO` (print error for runtime-loader attempts)
- `hadrian/cfg/system.config`: `gmp-include-dir = /Users/cell/.local/ghc-ppc-xtools/include-ppc`

### Config overrides in `scripts/tiger-config.site`

~50 `ac_cv_func_*=no` and `ac_cv_header_*=no` entries telling autoconf that
Tiger lacks clock_gettime, pthread_setname_np, utimensat/openat family,
eventfd, epoll, kevent64, getclock, libRT, _chsize, lutimes, statx, inotify,
copy_file_range, renameat2, lchmod, strerror_r, posix_spawn, dispatch_*,
getcontext/makecontext, pthread_threadid_np, etc.

## Known limitations / future work

1. **Stage2 native ghc** — runs, doesn't compile.  `StgToCmm.Env: variable not found $trModule3_rwD` panic.  See `docs/experiments/006`.
2. **GHCi / TemplateHaskell partial** — the runtime Mach-O loader is alive (v0.6.0, patch 0009; tested on real Haskell `.o` in v0.6.1) and PPC `ghc-iserv` is built and runs on Tiger (v0.7.0, patch 0010).  `pgmi-shim.sh` bridges ghc's local-iserv pipes to the remote target via SSH and the binary protocol works through that.  TH splices, however, need iserv to *find the host's package paths* on the target — and Tiger doesn't have a `/Users/cell/.../HSghc-prim-0.8.0.o` filesystem image.  Two fixes deferred to session 12d: (a) rsync the cross-bindist `lib/` to the same path on Tiger before each TH build, or (b) wire up the proper `iserv-proxy` + `remote-iserv` over TCP (which ships `.o` bytes over the wire to a target temp file).  Plus stage2 native ghc work for in-process GHCi REPL is still roadmap B.  See [docs/sessions/2026-04-24-session-12-iserv-ppc/README.md](sessions/2026-04-24-session-12-iserv-ppc/README.md).
3. **No profiling / dynamic libraries** — `QuickCross` sets `libraryWays = [vanilla]` to dodge PPC Mach-O's 24-bit `r_address` limit on scattered relocs (16 MB section limit hit by GHC.Hs.Instances as a dyn_o).  `dynamic` and `profiling` ways untested.
4. **Not in upstream GHC** — these are all local edits in our vendored tree.  Not yet turned into an MR/PR.
5. **No CI** — nothing keeps this working.  If GHC master moves, this bitrots.

## Build instructions

From scratch on arm64 macOS:

```
cd external/ghc-modern/ghc-9.2.8
source ../../../../scripts/cross-env.sh
./hadrian/build --flavour=quick-cross --docs=none -j8
```

About 16 minutes on M-series Mac, with ~200 SSH link round-trips to pmacg5.

## Session log

- Session 1: project setup, plan.md, fleet recon
- Sessions 2–3: Phase 1 (trying stock GHC 7.0.4 on Tiger — dead end)
- Sessions 4–6: Phase 3 cross-toolchain, configure, libffi fix
- Sessions 7–13: stage1 library chain, CC wrapper, Tiger-link, RTS patches
- Session 14: stage1 hello.hs runs on Tiger 🎉
- Session 15: stage2 ppc-native ghc runs `--version`; compile panic, deferred
- 2026-04-24 sessions 1–10: workflow + bug fixes + bindist installer +
  test battery + cabal cross-compile + runghc-tiger / ghc-pkg verify
  (v0.1.0 through v0.5.0).
- 2026-04-24 session 11: PPC Mach-O runtime loader restored (v0.6.0).
  loadObj + resolveObjs + lookupSymbol work end-to-end on Tiger;
  GHCi/TH still need iserv plumbing layered on top.
- 2026-04-24 session 12a: Haskell `.o` loads end-to-end (v0.6.1).
  Caught a pre-existing 9.2.8 `resolveImports` bug along the way.
  Iserv plumbing scoped in `docs/proposals/iserv-ssh-shim.md`.
- 2026-04-24 session 12b/c: PPC `ghc-iserv` cross-builds and runs on
  Tiger; `pgmi-shim.sh` bridges the iserv binary protocol over SSH
  (v0.7.0).
- 2026-04-24 session 12d: filesystem mirror works around path
  mismatch; DYLD_LIBRARY_PATH fixes libgmp lookup; `__eprintf` stub
  unblocks ghc-bignum loading.  Small Haskell `.o`s now load via
  iserv on Tiger (v0.7.1).
- 2026-04-24 session 12e: BR24 jump-island fix.  `symbol_extras`
  now placed inside the RX segment's mmap so jump islands always
  stay within ±32 MB of all text sections.  All `.o`s (including
  `base.o` ~3 MB) now load via iserv (v0.7.2).  Final hop —
  iserv's binary-protocol parse error at byte ~133 — is a separate
  bug, deferred to 12f.
- 2026-04-29 session 12f: **TemplateHaskell works end-to-end on
  Tiger** (v0.8.0).  Two bugs fixed: (a) cross-built `binary`
  library mis-encoded Generic-derived sum tags as Word64 instead
  of Word8 (patch 0013); (b) BCO array contents need byte-swap on
  host/target endian mismatch (patch 0014).  First TH on PPC/Darwin8
  since GHC 8.6 (2018).  Closes roadmap C.
- 2026-04-29 session 13: vendor `network-3.2.8.0` for Tiger (v0.8.1).
  Two `#ifdef` guards on `IP_RECVTOS` / `IPV6_TCLASS` (10.7+
  constants).  Real localhost TCP echo round-trip on Tiger.  The
  `SOCK_CLOEXEC` concern from session 7 was stale — already gated by
  upstream's `HAVE_ACCEPT4` autoconf check.
