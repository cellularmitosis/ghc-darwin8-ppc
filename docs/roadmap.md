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

❌ **Underlying GC bug not yet fixed** but the search space is
much smaller than session 17 left it.  See:

- [`docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md`](sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)
  — original write-up: panic catalogue per input shape, the `-A`
  threshold table, why LLVM and unreg-C both fail.
- [`docs/sessions/2026-05-09-session-19-stage2-gc-bug/`](sessions/2026-05-09-session-19-stage2-gc-bug/)
  — round 1 of the root-cause search.  Sanity check passes; SMP
  atomics, `large_alloc_lim` overflow, and CAF-list truncation
  all ruled out.  PROBE19 data shows GC trace is deterministic
  while output is non-deterministic, implying corruption is in
  non-heap state.
- [`docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/`](sessions/2026-05-10-session-20-stage2-gc-bug-round2/)
  — round 2.  **Proximate cause found.**  PROBE20 + PROBE21 walk
  the typechecker's stack post-scavenge and find ~184 slots that
  are heap-shaped but not in `BF_EVACUATED` blocks.  The
  bitmap-aware walker confirms 100% of these are at slots the
  enclosing stack-frame bitmap marks as non-pointer.  GC is
  doing its job; the bitmaps are wrong.  Pointer derefs yield
  real info tables (2-tuples, closures from Control.Monad.Catch,
  etc.).  Affects 14+ info tables across 6+ modules
  (Data.Map.Strict.Internal, Control.Monad.Catch,
  GHC.Iface.Binary, GHC.Base, GHC.List, Data.Map.Internal) —
  systematic GHC cross-codegen bug for PPC32, not per-module.
  Session-20 [`HANDOFF.md`](sessions/2026-05-10-session-20-stage2-gc-bug-round2/HANDOFF.md)
  points at finding the offending Cmm/StgToCmm path.
- [`docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/`](sessions/2026-05-10-session-21-stage2-bitmap-bug/)
  — round 3.  Decoded the PPC32 bitmap-word format
  (`BITMAP_BITS_SHIFT=5`).  Confirmed compile-time and runtime
  agree on the shift.  Cross-built Catch.o has 9 `PN`/`PNP` info
  tables; `-ddump-cmm` of the same source has exactly 9 matching
  `[F,T,F]`/`[F,T]` StackReps.  **`mkLivenessBits` is innocent —
  the bitmap encoding faithfully reflects the IR.**  Hypothesised
  the bug must therefore be in `stackMapToLiveness` or earlier
  StackMap construction — but see session 22 below.
- [`docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/`](sessions/2026-05-10-session-22-stage2-bitmap-bug/)
  — round 4.  **Session 21's hypothesis does NOT survive
  per-block audit.**  For every `_blk_NAME` with `True` in its
  StackRep in cross-built Catch.hs (15 frames total), check
  whether the body reads the True-marked slot.  Result: 0 reads,
  15 writes.  The bitmap is the right answer.  Cross-host
  comparison: cross emits 8× more True-bit StackReps than host
  on the same source, but the audited host PNP frames have the
  same dead-slot pattern.  The 8× difference is 32-bit codegen
  layout, not misclassification.  Verified end-to-end that bit
  0 = first slot above the info pointer in both compiler and
  runtime.  Conclusion: the dominant 93/106 BAD pay=1 events
  PROBE21 attributed to 4 PNP/PN info tables in Catch.hs are
  **PROBE21 false positives** — heap-shaped values legitimately
  stranded in dead slots that GC correctly skips.  The actual
  GC crash is real but somewhere else (different module, a
  non-RET_SMALL frame type PROBE21 skipped, the RTS scavenger,
  or CAF/SRT scanning).  Session-22
  [`HANDOFF.md`](sessions/2026-05-10-session-22-stage2-bitmap-bug/HANDOFF.md)
  proposes a poison-on-stale-slot RTS patch (overwrite each
  non-evac heap-shaped slot value with `0xDEADBEEF` post-
  scavenge — decisive test of "real bug vs PROBE21 false
  positive" in one short cycle).
- [`docs/sessions/2026-05-10-session-23-stage2-poison-probe/`](sessions/2026-05-10-session-23-stage2-poison-probe/)
  — round 5.  **PROBE22POISON ran the experiment.**  Stage2 ghc
  compiling M5.hs under `+RTS -A1m` crashed deterministically (5/5
  iterations) at `_blk_c7te + 112` with `EXC_BAD_ACCESS at
  0xdeadbeef`, in `__memcpy(_, src=0xdeadbeef, len=16)`.  The src
  came from `MEM[Sp+12]` of the topmost frame at crash time,
  which corresponds to **slot 6** in PROBE22's coordinates from
  the most recent (gc_no=2) GC — pre-poison value `0x0bf5f38a`
  in a block with `bd_gen=0 bd_flags=0x0`.  `_blk_c7te` lives in
  `GHC.Data.FastString` per `nm` on stage2's text.  Session-23
  attributed the crash to "a Cmm block whose StackRep misclassifies
  a pointer slot as non-pointer" — but session 24 (below) showed
  that attribution is wrong.
- [`docs/sessions/2026-05-11-session-24-faststring-stackrep/`](sessions/2026-05-11-session-24-faststring-stackrep/)
  — round 6.  **Session 23's attribution was wrong.**  Re-cross-
  compiled FastString.hs with `-ddump-cmm-sp -ddump-cmm-info`;
  found `_blk_c7te`'s info table directly (uniques are stable
  across rebuilds).  Its StackRep is `[False, True, True]` — and
  reading the Cmm IR, that is the **correct** answer: slot Sp+12
  is `_s77l`, the `Addr#` field of an unboxed `BS` constructor
  (`BS !(ForeignPtr Word8) !Int` ⇒ 3 unboxed fields: ptr
  `ForeignPtrContents`, raw `Addr#`, raw `Int`).  An `Addr#` is
  typed `I32` in Cmm — non-pointer — and the bitmap faithfully
  reflects that.  `mkLivenessBits`, `stackMapToLiveness`, and
  `LayoutStack` are all correct.  The PROBE22POISON read-after-
  poison crash is therefore **not** a bitmap bug.  Two open
  hypotheses for what it really is:
    (a) Invariant violation upstream — some BS reaching
        `mkFastStringByteString` has a non-pinned `MutableByteArray#`
        backing its `ForeignPtrContents`, so the `Addr#` becomes
        stale when GC moves the byte array.  Real bug, but not in
        LayoutStack.
    (b) PROBE22POISON false positive — pinned blocks may transiently
        present `bd_flags=0x0` (no `BF_PINNED`) at the moment
        PROBE22 runs, causing the probe to wrongly stomp stable
        `Addr#`s.  In that case, the production GC crash under
        `-A1m` has a different mechanism (CAFs, SRTs, info-tables,
        non-stack RTS state).
  Decisive test: PROBE23 = PROBE22POISON + `&& !(bd->flags &
  BF_PINNED)` to the poison filter.  See session 25 below.
- [`docs/sessions/2026-05-11-session-25-pin-aware-poison/`](sessions/2026-05-11-session-25-pin-aware-poison/)
  — round 7.  **PROBE23 settled it.**  PROBE23 = PROBE22POISON +
  `BF_PINNED` filter + a no-poison `PROBE23PINNED` log of stack
  slots pointing into pinned blocks.  Result on M5.hs `+RTS -A1m`:
  5/5 SIGSEGV byte-identical to session 23 (same `_blk_c7te + 112`,
  same `r4=0xdeadbeef`, same `r5=0x10`), AND `pinned_skip = 0`
  across every GC of every iteration — no stack-resident value
  pointed into a pinned block during M5.hs's compile.  Rules out
  hypothesis (b2) "PROBE22 was wrongly stomping pinned-Addr#s" in
  its strong form: there were no pinned-backed addresses on the
  stack at all.  Confirms hypothesis (a): the BS reaching
  `mkFastStringByteString` really is non-pinned-backed.  Sessions
  19–25 collectively rule out: bitmap codegen, `mkLivenessBits`,
  `stackMapToLiveness`, `LayoutStack`, the StackRep itself.  The
  bug is upstream of all of them, in the bytestring/FastString
  allocation boundary.  Next: find the BS allocator that omits
  pinning.  Session-25
  [`HANDOFF.md`](sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md)
  scopes the BS-allocator hunt.

Earlier "missing PPC memory fences" hypothesis is **dead** under
our build configuration — non-threaded RTS uses no fences.

Fixing the actual GC bug is still likely multi-session work.

**Older context, kept for the record:**
[session 14](sessions/2026-04-29-session-14-stage2-investigation/),
[experiments/006-stage2-native-ghc.md](experiments/006-stage2-native-ghc.md),
[proposals/stage2-native.md](proposals/stage2-native.md).

### ~~E. Upstream contribution~~ on hold (user request)

Paused until we're further down the road.

### ~~G. Cross-toolchain: LLVM-7 r4 → LLVM-8 swap~~ ✅ done (v0.12.0)

Sister project froze the LLVM-7 line at v7.1.1-r9 and consolidated
on LLVM-8 ([rationale](../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/rationale-llvm7-freeze.md)).
Per Iain, LLVM-7 ≡ LLVM-8 for PPC.

**Session 18 (2026-05-09):** three attempts.

- *Attempt 1* (rsync clang-8 from indium): blocked on indium env.
- *Attempt 2* (build clang-8 on uranium with then-known patches):
  builds + rebuilds clean, but every Haskell binary SIGBUSes in
  `updateNurseriesStats` during first GC.  Drafted the bug for the
  sister project; rolled back.
- *Attempt 3* (post-sister-fix): sister project's session 036 traced
  the crash to LLVM-8 dropping the PPC32 Darwin "power" alignment
  field-cap (`__alignof__(StgRegTable)` went 4→8, shifting
  `offsetof(Capability, r)` 12→16, disagreeing with GHC's prebaked
  Cmm offsets).  Their patch 0013 restored the cap.  Repointed
  symlink, rebuilt stage1 (16m52s, ~3× faster than LLVM-7's 48m46s),
  redeployed stage2, demo green.  **Shipped as v0.12.0.**

Side discovery (still relevant): GHC's `-fllvm` is a no-op for
unregisterised ABI targets.  The swap is about which clang
compiles GHC's C output, not about LLVM IR.

See [`docs/sessions/2026-05-09-session-18-llvm8-toolchain-swap/README.md`](sessions/2026-05-09-session-18-llvm8-toolchain-swap/README.md)
and [proposal G](proposals/llvm8-toolchain-swap.md) for the
narrative.

## Sister project touch-points

- **llvm-7-darwin-ppc** (now consolidating on LLVM-8) — source
  of our cross clang + SDK + the underlying PPC backend.  As of
  v0.12.0 we're on **clang 8.0.1 with sister-project patches
  BUG-003 / ABI-001 / ABI-002 / Tiger Mach-O LCs / BUG-010**
  (the BUG-010 fix was their session 036, restoring PPC32 Darwin
  "power" struct alignment).  Our patch 0008 to
  `compiler/GHC/CmmToC.hs` is pure-Haskell and doesn't affect
  LLVM; no change to that project needed.  Cross-clang is built
  on uranium from the source tree at
  `/Users/cell/claude/llvm-7-darwin-ppc/LLVM-8-Branch/` (1.5 GB,
  rsync'd from indium once); incremental ninja rebuilds in
  ~5 sec when their patch tree updates.
- **rogerppc** (private) — unrelated to this project.
