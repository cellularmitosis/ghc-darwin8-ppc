# state.md — where are we right now

*Updated: 2026-05-13 session 33 (stage2 GC bug round 15, **CUT SHORT** for project reorg).  Major finding: **PROBE33-v1 (heap-closure-header dump at refineFromInScope panic) captures FOUR REFINE samples at four different heap addresses across three different megablocks — ALL FOUR share the same info pointer `_s71L_info` (a THUNK_1_0 info table at 0x08c62bac in __DATA,__const) AND the same w3 = `_ghczmprim_GHCziTypes_Wzh_con_info` (0x092577e0).**  This refines session 32's framing: the bug locus is **NOT a specific virtual address** (session 32's finding) **but a specific CLOSURE TYPE** — the one THUNK_1_0 at info table 0x08c62bac.  Different env-var sizes cause different Vars to be allocated at closures of this type, dropping different Vars per env-size.  PROBE33-v2 (8-word closure dump) deployed but its sweep returned no REFINE samples in the tested env-len range (100..3000); next session must either re-sweep different env-lens to find v2 REFINE zones or add probes to the SCOPE/STGCMM/DEPSORT panic sites.  `_s71L_info` is a compiler-generated symbol appearing in multiple .o files; which module's `_s71L_info` won the link-time address 0x08c62bac was NOT determined this session.  **STATE DIRTY** — probe33-v2 patch applied to `compiler/GHC/Core/Opt/Simplify/Env.hs`, stage2 on pmacg5 is the probe33-v2 build (NOT clean v0.12.0).  Session 34 must revert + rebuild + redeploy clean stage2 OR pick up the dirty probe.  v0.12.0 release tag unchanged.  Next session: identify what `_s71L_info` represents (disassemble entry code at 0x019e2620; correlate against link map or per-module .o files).*

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

### 2. PPC-native `ghc` binary (WORKS, with `+RTS -A1G` workaround) — v0.11.0

~210 MB Mach-O `ppc_7400` executable.  `ghc --version` prints the banner.
`ghc Hello.hs -o hello` produces a working PPC binary on Tiger.
`ghc -c Words.hs` (with `Data.Map.Strict` import) compiles correctly.

The shipping wrapper (`scripts/ghc-stage2-wrapper.sh`) prepends
`+RTS -A1G -RTS` to every invocation, sidestepping the unfixed
PPC-Darwin RTS GC bug that corrupts the typechecker's `Bag`-based
binding store after the first major collection.  See
[`docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md`](sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)
for the original investigation (panic catalogue, threshold table,
why removing `-fllvm` and switching to unreg-C didn't fix it on its
own), and
[`docs/sessions/2026-05-09-session-19-stage2-gc-bug/`](sessions/2026-05-09-session-19-stage2-gc-bug/)
for round 1 of the root-cause investigation (sanity check passes,
SMP/atomic and CAF-list-truncation hypotheses ruled out) and
[`docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/`](sessions/2026-05-10-session-20-stage2-gc-bug-round2/)
for round 2 — proximate cause identified: ~184 stack-frame slots
have bitmaps that mark them as non-pointer but actually contain
real heap pointers, so GC skips them and they go stale.
Systematic across 6+ modules; root mechanism (why the bitmaps are
wrong on PPC32 cross-build) is the next session's question.
And [`docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/`](sessions/2026-05-10-session-21-stage2-bitmap-bug/)
for round 3 — bug narrowed by another layer: the bitmap-encoding
step (`mkLivenessBits`) is correct, the .o faithfully encodes
the StackRep that the Cmm IR specifies.  Pre-existing host/target
`BITMAP_BITS_SHIFT` mismatch theory disproved (both = 5 on PPC32).
Session 21 hypothesised the bug must therefore be in
`stackMapToLiveness` or earlier StackMap construction.
And [`docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/`](sessions/2026-05-10-session-22-stage2-bitmap-bug/)
for round 4 — that session-21 hypothesis does **not** survive
per-block audit.  All 15 `True`-containing StackReps in
cross-built Catch.hs have True-marked slots that are **never
read by the body** (only written/overwritten or
passed-through-then-popped).  The bitmap is the right answer.
Cross-host comparison: cross emits 8× more True-bit StackReps
than host on the same source, but the audited host frames have
the same dead-slot pattern — the difference is 32-bit codegen
layout, not misclassification.  Conclusion: the dominant 93/106
BAD pay=1 events PROBE21 attributed to 4 PNP/PN info tables in
Catch.hs are PROBE21 **false positives** (heap-shaped values
legitimately stranded in dead slots that GC correctly skips).
The actual GC crash is real but somewhere else: another
module's frames, a non-RET_SMALL frame type PROBE21 skipped,
the RTS scavenger itself, or CAF/SRT scanning.
And [`docs/sessions/2026-05-11-session-24-faststring-stackrep/`](sessions/2026-05-11-session-24-faststring-stackrep/)
for round 6 — **session 23's attribution was wrong**.  Cross-built
FastString.hs's `_blk_c7te` info-table's StackRep is `[False, True,
True]`, which is the **correct** bitmap for what the Cmm IR
specifies: slot Sp+12 holds the `Addr#` field of an unboxed
`Data.ByteString.Internal.Type.BS` constructor (the
`byteArrayContents#` of the underlying `ForeignPtrContents`), typed
`I32` (non-pointer) in Cmm.  LayoutStack faithfully encodes this;
`mkLivenessBits` faithfully encodes that.  The actual stale-Addr#
read-after-poison is upstream of LayoutStack — either an invariant
violation by some caller of `mkFastStringByteString` (the BS is
backed by a non-pinned `MutableByteArray#`, so the `Addr#` is stale
across the `stg_newByteArray#` GC point) or PROBE22POISON itself
false-positiveing on pinned-memory `Addr#`s in blocks whose
`bd_flags` happen to be `0x0` at the moment PROBE22 runs.
And [`docs/sessions/2026-05-11-session-25-pin-aware-poison/`](sessions/2026-05-11-session-25-pin-aware-poison/)
for round 7 — **PROBE23 (pin-aware poison) settled it.**  PROBE23 =
PROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the poison filter,
plus a no-poison `PROBE23PINNED` log of stack slots pointing into
`BF_PINNED` blocks.  Result on M5.hs `+RTS -A1m`: 5/5 SIGSEGV
byte-identical to session 23's PROBE22 (same crash slot
`gc_no=2 slot=6 old=0x0bf5f38a` at `_blk_c7te + 112`), AND
`pinned_skip = 0` across every GC of every iteration.  No stack
slot held a value pointing into a pinned block during M5.hs's
compile.  Rules out the strong form of the b-hypothesis "PROBE22
was wrongly stomping pinned-memory Addr#s" — there were no pinned-
backed addresses on the stack to stomp.  Confirms hypothesis (a):
the BS reaching `mkFastStringByteString` really is non-pinned-backed.
Sessions 19–25 collectively rule out all of: bitmap codegen,
`mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, the StackRep
itself.  The actual bug is upstream of all of them, in the
bytestring/FastString allocation boundary.  Next session: instrument
`mkFastStringByteString` to print whether each incoming BS's
`ForeignPtrContents` is `PlainPtr` (unpinned) vs one of the pinned
variants, find the violator, fix the BS producer.  Session
[`HANDOFF.md`](sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md)
scopes it.
And [`docs/sessions/2026-05-10-session-23-stage2-poison-probe/`](sessions/2026-05-10-session-23-stage2-poison-probe/)
for round 5 — **PROBE22POISON found a real read-after-poison.**  PROBE22POISON
(replace every non-evac heap-shape on the running TSO's stack with
`0xDEADBEEF` post-scavenge) caused stage2 ghc compiling M5.hs under
`+RTS -A1m -RTS` to crash deterministically (5/5 iterations) at
`_blk_c7te + 112` with `EXC_BAD_ACCESS at 0xdeadbeef` in
`__memcpy(_, src=0xdeadbeef, 16)`.  The src came from `MEM[Sp+12]`
= slot 6 in PROBE22 coordinates of the most recent (gc_no=2) GC.
Pre-poison value `0x0bf5f38a` was a tagged heap pointer in a
non-evacuated nursery block.  `_blk_c7te` lives between
`_s77C_entry` and
`_ghc_GHCziDataziFastString_mkFastStringByteString_entry` per `nm`
on stage2's text section — i.e. in some local closure /
continuation Cmm block within `GHC.Data.FastString`.  Of the 9
slots PROBE22POISON stomped per run, only 1 caused a read-after-
poison crash; the other 8 were benign (PROBE21 false positives,
exactly as session 22 said).  Session 22's "Catch frames are
correct" stands; the bug is in a *different* module's bitmap.
Next session: re-cross-compile `compiler/GHC/Data/FastString.hs`
with `-ddump-cmm-final`, find the StackRep of the offending
info table (block ~`c7te` or its sibling), and trace back to
StgToCmm/LayoutStack to see why the slot got marked non-pointer.

Deploy with `scripts/deploy-stage2.sh <ssh-host>`.

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
15. `0015-rts-rtsutils-tiger-strnlen-shim.patch` — inline `tiger_strnlen` in `rts/RtsUtils.c` for `__MAC_OS_X_VERSION_MIN_REQUIRED < 1070`.  Tiger's libSystem predates POSIX 2008's `strnlen` (added in macOS 10.7).  Without the shim, `-prof` programs fail to link with `_strnlen` undefined from `RtsUtils.p_o`.  Lands profiling support (v0.10.0).

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
3. **No dynamic libraries** — `QuickCross` keeps `dynamicGhcPrograms = pure False`: PPC Mach-O's 24-bit `r_address` limit on scattered relocs (16 MB section limit) is hit by GHC.Hs.Instances as a dyn_o.  Profiling way is now enabled (v0.10.0).
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
- 2026-04-29 session 14: stage2 native ghc investigation (no fix).
  Narrowed bug to a miscompile in stage1's PPC build of
  `compiler/GHC/Core/SimpleOpt.hs`'s `foldl' do_one` accumulator.
  Ruled out the obvious data-structure-miscompile candidates;
  next-session checklist documented.  Cross-compile path remains the
  recommended way to build Haskell for Tiger.
- 2026-04-29 session 15: TLS/HTTPS via tiger.sh's openssl-1.1.1t
  (v0.9.0).  Vendored `HsOpenSSL-0.11.7.10` at `vendor/HsOpenSSL/`
  with a 1-line patch wrapping `runInBoundThread` in a fallback that
  runs the action in the current thread when the threaded RTS isn't
  available (PPC32+gcc14 lacks `__atomic_*_8` intrinsics).  Real
  TLS handshake + HTTPS GET to example.com:443 verified on
  PowerMac G5 / Tiger 10.4.11.
- 2026-04-29 session 16: profiling builds work (v0.10.0).
  Sister project shipped LLVM-7 r4 with BUG-003 fix (PPC asm
  printer emits `r0` for ZERO/R0 base register, not bare `0`),
  unblocking the original session-9 build failure.  Plus two
  Tiger compatibility shims: `-D__MAC_OS_X_VERSION_MIN_REQUIRED=1040`
  in our cross-cc wrapper (so RTS version-gates take the
  pre-Snow-Leopard branch), and a 7-line `tiger_strnlen` inline
  in `rts/RtsUtils.c` (Tiger predates POSIX 2008's `strnlen`).
  Real `mandel.prof` cost-centre report + `mandel.hp` heap-profile
  produced on Tiger.
- 2026-04-30 session 17: stage2 native ghc works on Tiger (v0.11.0).
  Long-running investigation finally tracked the binding-loss bug
  to garbage collection: a major GC during a compile corrupts the
  typechecker's `Bag`-based binding store.  Workaround:
  `+RTS -A1G -RTS` keeps small compiles inside one allocation block
  so GC never fires.  Shipped as `scripts/ghc-stage2-wrapper.sh`
  + `scripts/deploy-stage2.sh`.  Demo `demos/v0.11.0-stage2-native.sh`
  compiles `Hello` and a `Data.Map.Strict` word-count program on a
  PowerMac G5 and runs both end-to-end.  Underlying GC bug not yet
  fixed (likely missing PPC memory fences in 9.2.8's RTS).
- 2026-05-09 session 18: cross-toolchain swapped from LLVM-7 r4 to
  LLVM-8 (v0.12.0).  Three attempts.  First two rolled back on
  indium env breakage and a `updateNurseriesStats` SIGBUS in
  every Haskell binary the new toolchain produced.  Sister project's
  session 036 traced the SIGBUS to LLVM-8 dropping the PPC32 Darwin
  "power" struct alignment field-cap; their patch 0013 restored it.
  Repointed our cross-clang at the patched binary, rebuilt stage1
  in 16m52s (~3× faster than LLVM-7's 48m46s), redeployed stage2,
  v0.11.0 demo green.  Side discovery: GHC's `-fllvm` is a no-op
  for unregisterised ABI targets — the swap is about which clang
  compiles GHC's C output, not about LLVM IR.
- 2026-05-12 session 28: stage2 GC bug investigation, round 10.
  Wrote **PROBE28** — a slim RTS-side per-GC printf in `rts/sm/GC.c`
  (file-static counter + pre-GC mut_list snapshot via `countOccupied`
  + post-GC summary line walking `gct->scavenged_static_objects`)
  — to discriminate session 27's "one bug, two victims" vs "two
  bugs" framings.  With the probe enabled, **Big2.hs `-A1m -G1`
  flips from session 27's TC-time "swap not in scope" signature
  (10/10) to the STG-time `refineFromInScope` signature 5/5** —
  the probe's tiny per-GC timing delay shifts which downstream
  IntMap-backed VarEnv catches the corruption.  Strong evidence
  for **one bug, two victim data structures**.  PROBE28 also rules
  out (i) the mut_list / write-barrier audit (Big2 `-G1` fails 5/5
  with zero mut_list activity — under `-G1` mut_lists are empty),
  and (ii) the static_objects scavenge audit (under `-G1` every GC
  walks the same ~175k-entry static chain in both M5 (PASS) and Big2
  (FAIL)).  Remaining suspects: `rts/sm/Evac.c` (evacuate, copy_tag,
  copy) and `rts/sm/Scav.c::scavenge_block` dispatch — these run on
  every GC regardless of `-G` and would fire identically across
  M5/Big2 except that Big2 has more closures of whatever type
  triggers the bug.  v0.12.0 ships unchanged; probe applied for
  measurement, then reverted; clean stage2 redeployed at session end.
  Session
  [`HANDOFF.md`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)
  scopes the closure-type histogram extension + Evac.c / Scav.c
  audit.
- 2026-05-12 session 27: stage2 GC bug investigation, round 9.
  Re-established a **deterministic non-perturbing repro** after
  session 26 showed PROBE26 was hiding the M5.hs SIGSEGV: clean
  stage2 + `M5.hs +RTS -A1m -RTS` panics **10/10** with the
  STG-time panic family (depSortStgBinds, refineFromInScope, etc.).
  Tried a matrix of RTS flag profiles on M5.hs: `-A1G` 10/0,
  `-A1m` 0/10, `-A1m -G1` **10/0** (single-generation fully
  suppresses!), `-A512k` 9/1, `-A4m` 10/0.  `-G1` empties the
  older-gen mut_list scavenge loop in `scavenge_capability_mut_lists`,
  so the bug looked consistent with a missed-mut_list-entry / write-
  barrier bug.  Then on slightly larger inputs the picture broke:
  M5plus.hs `-A1m -G1` 5/0 (still suppressed), but a syntactically
  clean Big2.hs `-A1m -G1` fails **10/10** with a previously-
  undocumented signature — `* GHC internal error: 'swap' is not in
  scope during type checking, but it passed the renamer`.  So the
  bug has at least two distinct corruption modes: STG-time
  (suppressed by `-G1`) and typecheck-time (not suppressed).  Either
  two separate bugs or one bug with two victim data structures.
  v0.12.0 ships unchanged; source tree clean; no commits to
  external/ghc-modern this session.  Session
  [`HANDOFF.md`](sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md)
  scopes a slim RTS-side probe to discriminate one-bug vs two-bug.
- 2026-05-12 session 26: stage2 GC bug investigation, round 8.
  PROBE26 = Haskell-side ForeignPtrContents classifier in
  `mkFastStringByteString`.  Result on M5.hs `+RTS -A1m`: 150
  visible BSes across 3 runs, all **`PlainPtr+pinned`, zero
  UNPINNED**.  Hypothesis (a) from session 25 ("BS reaches
  `mkFastStringByteString` with non-pinned MBA") is **rejected
  by direct observation**.  Additionally, PROBE26 prevents the
  SIGSEGV on M5.hs entirely (0/3 vs. session 23's 5/5) — the
  instrumentation perturbs `mkFastStringByteString`'s Cmm enough
  to hide the bug.  Stress-test on M5plus.hs and Big.hs: bug
  rate dramatically reduced but not zero (1/16 panic on a cold
  M5plus.hs first run).  Sessions 23–25's `_blk_c7te + 112 /
  0xdeadbeef` signature was a PROBE22POISON / PROBE23 probe
  artefact — without any probe, the bug surfaces as the panics
  that session 17 first cataloged.  Sessions 19–26 collectively
  rule out: bitmap codegen, mkLivenessBits, stackMapToLiveness,
  LayoutStack, StackRep, AND the BS-pinning-invariant theory.
  v0.12.0 ships unchanged; stage2 on pmacg5 redeployed clean.
  See [`HANDOFF.md`](sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md).
- 2026-05-11 session 25: stage2 GC bug investigation, round 7.
  PROBE23 (PROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the
  poison filter, plus a no-poison `PROBE23PINNED` log of stack
  slots pointing into pinned blocks) ran against M5.hs under
  `+RTS -A1m`.  Result: 5/5 SIGSEGV byte-identical to session
  23's PROBE22 (same crash slot `gc_no=2 slot=6 old=0x0bf5f38a`
  at `_blk_c7te + 112`, same `r4=0xdeadbeef`, same `r5=0x10`),
  AND `pinned_skip = 0` across every GC of every iteration.
  No stack-resident value pointed into a `BF_PINNED` block during
  M5.hs's compile.  Rules out the false-positive theory in its
  strong form: PROBE22 was NOT wrongly stomping pinned-Addr#s
  (there weren't any).  Confirms hypothesis (a) from session-24
  HANDOFF: the BS reaching `mkFastStringByteString` is backed by
  a non-pinned `MutableByteArray#`, violating the pinning
  invariant at `libraries/base/GHC/ForeignPtr.hs:145`.  Sessions
  19–25 collectively rule out all of: bitmap codegen,
  `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, the
  StackRep itself.  The bug is upstream of all of them, in the
  bytestring/FastString allocation boundary.  v0.12.0 ships
  unchanged; stage2 on pmacg5 reverted to clean RTS at session-25
  end.  Next session: instrument `mkFastStringByteString` (or
  audit the BS producer surface) to find the BS allocator that
  omits pinning.
- 2026-05-10 session 23: stage2 GC bug investigation, round 5.
  Built PROBE22POISON (RTS patch — replace every non-evac heap-
  shape on the running TSO's stack with `0xDEADBEEF` post-
  scavenge) and ran stage2 ghc against M5.hs under `+RTS -A1m`.
  5/5 iterations crashed deterministically at `_blk_c7te + 112`
  with `EXC_BAD_ACCESS at 0xdeadbeef`, in
  `__memcpy(dst, src=0xdeadbeef, len=16)`.  The poisoned slot
  is at `MEM[Sp+12]` of the topmost frame at crash time, which
  corresponds to **slot 6** in PROBE22's coordinates from the
  most recent (gc_no=2) GC — pre-poison value `0x0bf5f38a`,
  a tagged heap pointer.  `_blk_c7te` lives between
  `_s77C_entry` and
  `_ghc_GHCziDataziFastString_mkFastStringByteString_entry` per
  `nm` on stage2 ghc's text section, so the misclassifying
  StackRep is in some local closure / continuation Cmm block
  within `GHC.Data.FastString`.  Of the 9 slots PROBE22POISON
  stomped per run, only 1 caused a read-after-poison crash;
  the other 8 were benign (consistent with session 22's
  per-block audit).  v0.12.0 ships unchanged; stage2 on pmacg5
  reverted to clean RTS at session-23 end.  Next session: dump
  cross-built FastString.hs Cmm, find the StackRep of the
  offending info table, trace back to LayoutStack /
  stackMapToLiveness.
- 2026-05-10 session 22: stage2 GC bug investigation, round 4.
  Re-tested session 21's "bitmap is wrong" hypothesis with a
  per-block audit: for every `_blk_NAME` in cross-built Catch.hs
  whose StackRep contains `True`, check whether the body reads
  the True-marked slot.  Result across all 15 True-containing
  frames: **0 reads, 15 writes** — the bitmap is the right answer.
  Cross-host comparison shows cross emits 8× more True-bit
  StackReps than host on the same source, but the audited host
  PNP frames have the same dead-slot pattern.  Verified the
  bit-order convention end-to-end: bit 0 = first slot above the
  info pointer in both compiler and runtime.  Conclusion:
  PROBE21's BAD events for the 4 dominant Catch.hs PNP/PN info
  tables are **false positives** (heap-shaped values stranded
  in genuinely-dead slots).  The actual GC crash is real but
  somewhere else.  Next session: build poison-on-stale-slot RTS
  patch — overwrite each non-evac heap-shaped slot value with
  `0xDEADBEEF` post-scavenge; if the typechecker crashes at
  `0xDEADBEEF`, the slot was being read = real bug; if it
  crashes at the original "variable not found" panic, slots are
  truly dead = bug is RTS-side or in a non-RET_SMALL frame
  type.  Two reusable audit scripts shipped.
  Stage2 still ships unchanged.
- 2026-05-10 session 21: stage2 GC bug investigation, round 3.
  Decoded the on-disk bitmap word format on PPC32
  (BITMAP_BITS_SHIFT=5, MASK=0x1F).  Confirmed both compile-time
  (`pc_BITMAP_BITS_SHIFT=5` in stage1's PlatformConstants) and
  runtime (`SIZEOF_VOID_P=4` → shift=5 in Constants.h) agree —
  no shift mismatch.  Re-attributed PROBE21BAD events: 93/106
  of pay=1 BADs come from just 4 info tables, all with bitmap
  layout 0x42 (PN size 2) or 0x43 (PNP size 3) — middle slot
  wrongly marked non-pointer.  Cross-rebuilt
  `Control/Monad/Catch.hs` with `-ddump-cmm`: the IR has
  exactly 9 `[F,T,F]`/`[F,T]` StackReps matching the .o's 9
  `PN`/`PNP` info tables.  **The bitmap-encoding step is
  faithful.** Therefore the bug lives in
  `compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` or
  earlier StgToCmm StackMap construction.  Likely cause: a
  saved-pointer slot doesn't make it into `sm_regs`, or its
  `LocalReg` type is misclassified so `isGcPtrType` returns
  False.  Two reusable analysis scripts
  (decode-info-tables.py, correlate-probe21-bads.py) shipped.
  Stage2 still ships unchanged.
- 2026-05-10 session 20: stage2 GC bug investigation, round 2.
  Built PROBE20 + PROBE21 on top of the debug RTS to walk the
  running TSO's stack post-scavenge and classify every word.
  Found 184 stack slots that are heap-shaped but non-evac'd —
  bit-for-bit deterministic across iter1/2/3.  PROBE21's
  bitmap-aware walker shows **100% of those slots have
  `is_ptr=0`** (the frame's bitmap claims they're non-pointer).
  Pointer derefs of the BAD values yield real info-table
  addresses (e.g. `_ghczmprim_GHCziTuple_Z2T_con_info` for a
  2-tuple).  GC is doing its job; the bitmap is wrong.
  Affects 14+ info tables across 6+ modules
  (Data.Map.Strict.Internal, Control.Monad.Catch,
  GHC.Iface.Binary, GHC.Base, GHC.List, Data.Map.Internal) —
  systematic, not per-module.  Why the bitmap is wrong is the
  session-21 question; likeliest culprit is a host-arm64 →
  target-PPC32 mismatch in StgToCmm liveness analysis.  Stage2
  still ships unchanged with the `-A1G` workaround.
- 2026-05-09→10 session 19: stage2 GC bug investigation, round 1.
  Linked stage2 against `libHSrts-1.0.2_debug.a` and ran M5.hs
  compiles under sanity check (`+RTS -DS`), single-generation
  GC (`-G1`), zero-on-free (`-DZ`), and an instrumented
  `markCAFs` that logged per-GC CAF counts.  Three big hypotheses
  ruled out: SMP atomics (non-threaded RTS uses no fences anyway),
  `large_alloc_lim` 32-bit overflow (1 MiB at default; doesn't
  overflow), and CAF-list truncation (count grows monotonically
  across all 25 GCs in every run).  Sanity check fires no
  assertions — heap is internally consistent.  `-G1` doesn't
  bypass the bug, so it's not specifically gen0→gen1 promotion.
  PROBE19's per-GC trace is bit-for-bit deterministic across runs
  while M5.o output is non-deterministic, which means the
  corruption is in non-heap state (saved registers / stack slots
  / `StgRegTable` field interpretation on PPC32).  Stage2 still
  ships unchanged with the `-A1G` wrapper.
