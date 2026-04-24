# state.md — where are we right now

*Updated: 2026-04-24 session 6 (post-v0.4.0, cabal cross-compile shipped).*

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
  (117 MB — now includes `install.sh` at the root).  Released on
  GitHub as
  [v0.3.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.3.0).
  Install flow: `tar xJf <tarball> && cd ghc-9.2.8-powerpc-apple-darwin8 && ./install.sh --prefix=$PREFIX --ppc-host=<ssh-alias>`.

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
2. **No GHCi / TemplateHaskell** — the runtime Mach-O loader for PPC was discarded in 2018; our stub errors at runtime.  Users can't splice TH on Tiger.  Restoring it requires re-implementing `relocateSection()` for PPC `PPC_RELOC_*` types.
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
