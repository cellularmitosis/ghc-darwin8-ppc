# Roadmap — GHC 9.2.8 on PPC/Darwin 8

Last reviewed: 2026-05-15 session 49.

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
  — round 7.  PROBE23 = PROBE22POISON + `BF_PINNED` filter + a
  no-poison `PROBE23PINNED` log of stack slots pointing into pinned
  blocks.  Result on M5.hs `+RTS -A1m`: 5/5 SIGSEGV byte-identical
  to session 23 (same `_blk_c7te + 112`, same `r4=0xdeadbeef`, same
  `r5=0x10`), AND `pinned_skip = 0` across every GC.  Session 25
  read this as confirming hypothesis (a) "the BS reaching
  `mkFastStringByteString` is non-pinned-backed."  But session 26
  showed both pieces of that conclusion are flawed (see below).
- [`docs/sessions/2026-05-12-session-26-bs-allocator-hunt/`](sessions/2026-05-12-session-26-bs-allocator-hunt/)
  — round 8.  **Hypothesis (a) is REJECTED.**  PROBE26 (Haskell-side
  patch to `mkFastStringByteString`) classifies the
  `ForeignPtrContents` of every BS that flows in, plus tests the
  underlying `MutableByteArray#`'s pinning via `isMutableByteArrayPinned#`.
  Result on M5.hs `+RTS -A1m`: 150 visible BSes across 3 runs, **all
  `PlainPtr+pinned`, zero UNPINNED.**  Stress-test on M5plus.hs and
  Big.hs: 1/16 panic, 25+/25+ OK — bug rate dramatically reduced
  but not zero.  The instrumentation perturbs `mkFastStringByteString`'s
  Cmm enough to hide the SIGSEGV on M5.hs entirely.  Plus
  clarifications: (i) PROBE23's `pinned_skip = 0` is a phantom of
  the `BF_EVACUATED`-checked-first filter ordering — pinned blocks
  carry `BF_EVACUATED` too, so they're counted as `evac_skip`;
  (ii) the "5/5 SIGSEGV at `_blk_c7te+112`" signature is a
  PROBE22POISON / PROBE23 specific artefact (the probes themselves
  filled stack slots with `0xDEADBEEF`).  Without any probe, the
  bug surfaces as the panics that session 17 first cataloged
  (`depSortStgBinds`, `refineFromInScope`, "variable not found").
  Sessions 19–26 collectively rule out: bitmap codegen,
  `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, StackRep,
  AND the BS-pinning-invariant theory.  We do not currently have a
  confirmed proximate cause.  Session-26
  [`HANDOFF.md`](sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md)
  scopes re-establishing a non-perturbing repro (currently 4/5 panic
  on clean stage2 + M5.hs `-A1m`) and pivoting investigation upstream.
- [`docs/sessions/2026-05-12-session-27-non-perturbing-repro/`](sessions/2026-05-12-session-27-non-perturbing-repro/)
  — round 9.  **Deterministic non-perturbing repro nailed.**
  `M5.hs +RTS -A1m -RTS` on clean stage2 panics **10/10** with the
  STG-time panic family (depSortStgBinds, refineFromInScope, "variable
  not found").  **`+RTS -A1m -G1` (single-generation) fully
  suppresses the M5.hs panic family** (10/10 OK), and likewise on
  M5plus.hs (5/5 OK).  Goldilocks: `-A1G`, `-A4m`, and even `-A512k`
  are too large/small to reproduce M5.hs's failure.  But on a
  larger clean input — Big2.hs, ~30-LOC, uses Data.Map.Strict and
  a `where`-bound local function — `-A1m -G1` fails 10/10 with a
  **new, previously-undocumented signature**: `* GHC internal
  error: 'swap' is not in scope during type checking, but it
  passed the renamer`.  Session-27 framed this as "the bug has at
  least two distinct corruption modes" — **downgraded by session
  28 to one bug, two victim data structures** (see next entry).
  v0.12.0 ships unchanged; source tree clean; no commits to
  external/ghc-modern this session.
- [`docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/)
  — round 10.  Wrote **PROBE28** — a slim RTS-side per-GC printf in
  `rts/sm/GC.c` (file-static counter + pre-GC mut_list snapshot via
  `countOccupied` + post-GC summary line walking
  `gct->scavenged_static_objects` via `STATIC_LINK`).  With the
  probe enabled, **Big2.hs `-A1m -G1` flips from session 27's
  TC-time "swap not in scope" signature (10/10) to the STG-time
  `refineFromInScope` signature 5/5** — the probe's tiny per-GC
  timing delay shifts which downstream IntMap-backed VarEnv catches
  the corruption.  Strong evidence for **one bug, two victim data
  structures**.  PROBE28 also rules out two of session 27's audit
  targets: (i) `scavenge_capability_mut_lists` / mut_list write-
  barrier path (Big2 `-G1` fails 5/5 with zero mut_list activity —
  under `-G1` mut_lists are empty); (ii) `scavenge_static` /
  `scavenge_thunk_srt` / `scavenge_fun_srt` (under `-G1` every GC
  walks the same ~175k-entry static_objects chain in both M5 (PASS)
  and Big2 (FAIL)).  Remaining suspects: `rts/sm/Evac.c`
  (`evacuate`, `copy_tag`, `copy`), `rts/sm/Scav.c::scavenge_block`
  dispatch by closure type, forwarding-pointer / info-table
  machinery on PPC32 (32-bit big-endian).  v0.12.0 ships unchanged;
  probe applied for measurement and reverted at session end; stage2
  on pmacg5 rebuilt+redeployed clean.  Session-28
  [`HANDOFF.md`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)
  scopes a per-closure-type histogram extension to PROBE28, then a
  PPC32-eyes audit of Evac.c / Scav.c.
- [`docs/sessions/2026-05-12-session-29-closure-type-histogram/`](sessions/2026-05-12-session-29-closure-type-histogram/)
  — round 11.  Extended PROBE28 to **PROBE29** — per-closure-type
  histogram in `rts/sm/Scav.c::scavenge_block` and
  `rts/sm/Evac.c::evacuate`, plus a forwarding-pointer hit count.
  **All 5 Big2 `-A1m -G1` failing GCs produce byte-identical
  histograms** (full determinism confirmed).  Diff M5 GC 13 (PASS)
  vs Big2 GC 17 (FAIL): largest workload-relative anomalies are
  **ARR_WORDS at 1.66× scav**, THUNK_2_0 at 1.42×, BLACKHOLE evac
  at 4.81× — but **no closure type is unique to Big2's failing GC**
  (every type at GC 17 also appears in earlier Big2 GCs and in
  M5's GCs).  Then a Big2.hs bisect produced the headline finding:
  **the bug is filename-sensitive**.  Byte-identical Big2.hs source
  compiled under filename `Big2.hs` panics 5/5 at GC 17; under
  `B0.hs` (or `BB.hs`, `X.hs`, `A.hs`) it PASSES at GC 18.  `md5`
  confirmed identical bytes.  Length sweep: `A.hs` passes, `AA.hs`
  fails; `BB.hs` passes, `BBB.hs` fails.  Different RTS flags
  shift which filenames trigger.  **This rules out a per-closure-
  type scavenge / evacuate bug**: such a bug would fire whenever
  type X is processed.  The trigger is **heap-layout-dependent**.
  Audit direction pivots to: heap-block geometry, allocator state
  (`alloc_in_moving_heap` / `todo_block_full`), block-boundary
  crossings, info-pointer / forwarding-pointer alignment, ROUNDUP /
  sizeofW arithmetic at variable-size closures on PPC32.  v0.12.0
  ships unchanged; probe applied for measurement and reverted at
  session end; stage2 on pmacg5 rebuilt+redeployed clean.  Session-29
  [`HANDOFF.md`](sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md)
  scopes a DEBUG/sanity-check RTS rebuild (`+RTS -DS`) to catch
  corruption inside `GarbageCollect()`, then an allocator + block-
  boundary audit.

- Rounds 12-17 (sessions 30-35): debug-RTS build, env-var bisect,
  closure-shape probes via `aToWordzh (unsafeCoerce v :: Any)`, STG
  dump on AArch64/CodeGen.hs.  Capstone finding at session 35:
  **the whole probe family was reading the wrong memory** —
  `aToWordzh (unsafeCoerce v :: Any)` wraps v in a let-bound thunk
  and reports the wrapping thunk's info pointer, not v's.  Session
  35 dissolved sessions 33-34's "AArch64.CodeGen ncgPlatform-config
  thunk" identification as a structural coincidence in `__DATA,__const`
  layout.  What WAS robustly learned across these rounds: the bug
  fires at 3 discrete env-len zones (~650-700, 850-900, 1650-1700)
  and always misses a TYPECLASS DICTIONARY variable.  See sessions
  [30](sessions/2026-05-12-session-30-debug-rts/),
  [31](sessions/2026-05-12-session-31-cross-run-diff/),
  [32](sessions/2026-05-12-session-32-env-var-bisect/),
  [33](sessions/2026-05-13-session-33-closure-shape-probe/),
  [34](sessions/2026-05-13-session-34-s71L-identification/),
  [35](sessions/2026-05-13-session-35-stg-dump-and-whnf/).
- [`docs/sessions/2026-05-13-session-36-unpackclosure-probe/`](sessions/2026-05-13-session-36-unpackclosure-probe/)
  — round 18.  **Redesigned the probe to use `GHC.Exts.anyToAddr#`**
  — a polymorphic primop that compiles to a Cmm register-to-register
  move (no wrapping thunk) in `compiler/GHC/StgToCmm/Prim.hs`'s
  `AnyToAddrOp`.  Verified clean via `-ddump-stg-final`
  (`anyToAddr# [x void#]` with x passed directly) and a stand-alone
  fixture program that distinguishes THUNK / WHNF / CAF-thunk-then-
  forced cases on both uranium host-ghc and PPC unreg cross-stage1.
  Sweep on pmacg5 produced 4 captures in 2 env-len zones (sessions
  35's 650-700 zone didn't fire — heap layout shifted).  **All 4
  captures show word[0] = exactly `0x092592a4` = `_stg_BLACKHOLE_info`,
  word[1] tag bits `0b011` = pointer to evaluated `Id` ctor closure,
  BEFORE = AFTER (no in-place update from seq).**  The thunk WAS
  evaluated; the indirectee IS populated.  Only the BLACKHOLE→IND
  info-pointer swap is missing.  This dissolves theory W
  (wrapping-thunk artifact, definitively) and refines theory 1
  (isLocalId DID force v — the indirectee exists — but v's closure
  header retained `_stg_BLACKHOLE_info`).  Bug is in PPC unreg's
  `stg_update_thunk_info` / `UPD_IND` path, or its interaction with
  lazy blackholing.  v0.12.0 ships unchanged; probe applied for
  measurement and reverted at session end; stage2 on pmacg5
  rebuilt+redeployed clean.  Session-36
  [`HANDOFF.md`](sessions/2026-05-13-session-36-unpackclosure-probe/HANDOFF.md)
  scopes extending the probe to follow word[1] (confirm Id ctor
  info-table), reading `rts/Updates.cmm` + `rts/Updates.h` for the
  BLACKHOLE→IND swap, and experimenting with disabled lazy
  blackholing.
- [`docs/sessions/2026-05-13-session-37-indirectee-and-update-path/`](sessions/2026-05-13-session-37-indirectee-and-update-path/)
  — round 19.  **MAJOR REFRAME** — probe37 (probe36 extended with
  a follow-through to `word[1] & ~3`) dissolves session 36's
  framing.  Reading `rts/Updates.h:48-67`'s `updateWithIndirection`
  macro reveals the canonical post-evaluation state of an updated
  thunk IS `word[0] = stg_BLACKHOLE_info` + `word[1] = tagged
  result pointer`; `stg_IND_info` does not appear in this path
  (it's reserved for GC old-generation indirection short-circuit).
  `nm` resolves the indirectee's `word[0]` to
  **`_ghc_GHCziTypesziVar_Id_con_info` exactly** — v's evaluation
  produced a fully-formed Id constructor closure with sensible
  Name/Unique/Type fields.  **The actual bug surfaces in the panic
  message body**: `InScope {wild_00 v_B1 allPositive}` — only 3
  entries in a simplifier scope that should have many more,
  missing the `$dOrd_a1k0` typeclass dictionary the simplifier is
  trying to look up.  At len=850 the panic shifts to
  `depSortStgBinds` "Found cyclic SCC" on `$trModule3_r1lT` and
  `$trModule4_r1lU` whose printed FVs (`{}` and `{$trModule3_r1lT}`
  respectively) do NOT form a cycle — different victim, same
  underlying corruption.  This is consistent with session 28's
  "one bug, multiple victim data structures, all UniqMap-backed"
  framing and **dissolves sessions 33-36's closure-shape probe
  trail as a wild goose chase**.  The bug is GC-of-UniqMap-data-
  structures, not thunk-update on PPC unreg.  v0.12.0 ships
  unchanged; probe applied for measurement and reverted at session
  end; stage2 on pmacg5 rebuilt+redeployed clean.  Session-37
  [`HANDOFF.md`](sessions/2026-05-13-session-37-indirectee-and-update-path/HANDOFF.md)
  scopes instrumenting `addNewInScopeIds` / `setInScopeFromE` /
  `setInScopeFromF` in `Simplify/Env.hs` to find where InScopeSet
  entries are lost during simplifier descent.
- [`docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/`](sessions/2026-05-13-session-38-inscopeset-instrumentation/)
  — round 20.  **MAJOR REFINEMENT to session 28's framing.**
  Probe38 was the silent-on-happy-path InScopeSet instrumentation
  scoped by session 37's HANDOFF.  Three diagnostics: panic-site
  full dump at `refineFromInScope`, post-extension self-validation
  at `addNewInScopeIds`, shrink detection at all three
  `setInScope*` variants.  Built clean, deployed, swept across
  env-lens 600..2000 step 25 (8 panics).  **`PROBE38-ADDLOST` and
  `PROBE38-SHRINK` never fire** — insertion is correct, replacement
  never reduces the set's size.  The InScopeSet at the panic site
  contains **coherent** Var entries, but the panic's missing var
  has the **same OccName as an in-scope Var with a different raw
  Unique** — e.g. at env-lens 825..925, in-scope has
  `$dOrd(0x610013f7)` while the expression's `$dOrd` has raw
  Unique `0x61001418` (delta=33).  Three runs at len=850 produce
  identical Uniques (deterministic given heap layout).  Nursery
  sweep `-A1m`..`-A32m` at len=850 shows the victim Var rotates
  with `-A`: $dOrd, $dEq, ds_d1lr (let-binding), $dFoldable, etc.
  — **not dictionary-specific**.  **`-A16m` produces a clean
  compile of Big2.hs at len=850.**  Refined framing: **the bug is
  GC corrupting the `realUnique :: FastInt#` field of Var heap
  closures on PPC32 unreg.**  The various UniqMap-backed "victim"
  structures are all innocent.  v0.12.0 ships unchanged; probe
  applied and reverted; stage2 rebuilt+redeployed clean +
  smoke-test PASS + baseline tests 30 PASS / 4 FAIL_OUTPUT
  unchanged.  Session-38
  [`HANDOFF.md`](sessions/2026-05-13-session-38-inscopeset-instrumentation/HANDOFF.md)
  scopes probe39: tracking a specific Var's realUnique field
  across the pipeline via `anyToAddr#` + IORef drift detector to
  directly confirm or rule out GC-of-Var.realUnique corruption.
- [`docs/sessions/2026-05-13-session-39-var-realunique-drift/`](sessions/2026-05-13-session-39-var-realunique-drift/)
  — round 21.  **Session 38's "GC corrupts Var.realUnique"
  hypothesis is DISPROVEN.**  Probe39 (a sentinel-Var IORef
  tracker in `Simplify/Env.hs` that registers the first
  `$d*`-named Var seen in `subst_id_bndr`, pins it in an IORef
  to keep it live across GC, and at every `refineFromInScope`
  re-reads its `varUnique v`) directly tests the hypothesis
  across three iterations.  v1 (hardcoded OccName filter)
  registered nothing — wrong target names.  v2 (broadened to
  any `$d`-prefixed OccName, also hooked `subst_id_bndr` in
  addition to `addNewInScopeIds`) at len=850 registered
  `$dOrd_a1k0(0x610013f7)` and showed `u_via_haskell` STABLE
  across 4 `refineFromInScope` checks; the raw word[2] peek
  differed because `anyToAddr#` returns a wrapping-thunk
  address (session-37 lesson resurfaced).  v3 dropped the
  misleading raw-peek check.  Fine sweep showed `sentinel=none`
  on every failing run — the panic fires before any `$d*` Var
  enters scope via `subst_id_bndr`.  **Conclusion:** when the
  sentinel registers, `varUnique v` returns the same value at
  registration AND at every subsequent check.  GC may relocate
  the Var closure but does NOT rewrite its realUnique field.
  Refined framing: the bug is **two distinct Var heap closures
  existing with the same `OccName` "$dOrd_a1k0" but different
  Uniques** — neither drifts; they're genuinely two separate
  objects.  Duplicate is created upstream of the simplifier
  (typechecker, desugarer, specializer, or interface
  deserializer).  v0.12.0 ships unchanged; probe applied and
  reverted; stage2 rebuilt+redeployed clean + smoke-test PASS
  + baseline tests 30 PASS / 4 FAIL_OUTPUT unchanged.
  Session-39
  [`HANDOFF.md`](sessions/2026-05-13-session-39-var-realunique-drift/HANDOFF.md)
  scopes probe40: trace where the duplicate Var is
  constructed in the typechecker/desugarer/specializer pipeline.
- [`docs/sessions/2026-05-13-session-40-trace-duplicate-var/`](sessions/2026-05-13-session-40-trace-duplicate-var/)
  — round 22.  **Major new lead:** probe40 (extends probe38's
  panic-site dump to also report `seIdSubst`'s size and keys
  at every `substId env v` call where v's in-scope lookup
  fails) reveals **`seIdSubst` is EMPTY at every
  refineFromInScope panic**.  The env at the panic site has
  only `init_in_scope = {wild_00}` plus the binders for the
  current function being descended into — no top-level
  binders, no substitutions.  This matches the shape of a
  freshly-created SimplEnv (`mkSimplEnv mode` output) plus a
  tiny descent, but `mkSimplEnv` is called only once per
  simplifier iteration and its output flows into
  `simplTopBinds` which populates seInScope with all
  top-level binders via `simplRecBndrs`.  **New hypothesis:**
  GC corrupts the SimplEnv heap closure's seInScope and
  seIdSubst fields, resetting them to fresh-env defaults
  somewhere during descent.  Consistent with heap-layout-
  sensitive triggering (sessions 28-29) and with probe38's
  PROBE38-SHRINK never firing (which only catches Haskell-
  level set replacements; a GC pointer rewrite of the
  SimplEnv data structure bypasses those).  **Side discovery
  1:** session 38's `-A16m` clean-compile claim was an
  artifact of `head -8` truncating output; real clean-compile
  threshold is `-A256m`.  **Side discovery 2:** with
  `-dsuppress-uniques`, PPC stage2 `-A256m` Core dump and
  uranium host `-A1m -G1` Core dump are byte-identical — the
  pipeline producing the simplifier's input is correct on
  PPC; the bug is dynamic.  v0.12.0 ships unchanged; probe
  applied and reverted; stage2 rebuilt+redeployed clean +
  smoke-test PASS + baseline tests 30 PASS / 4 FAIL_OUTPUT
  unchanged.  Session-40
  [`HANDOFF.md`](sessions/2026-05-13-session-40-trace-duplicate-var/HANDOFF.md)
  scopes probe41: pin a SimplEnv reference in an IORef and
  periodically check its seInScope/seIdSubst sizes to
  directly observe the corruption.
- [`docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/`](sessions/2026-05-13-session-41-simplenv-corruption-tracker/)
  — round 23.  Probe41 (pin a SimplEnv reference in an IORef
  at every `simplRecBndrs` call, track its `seInScope` /
  `seIdSubst` sizes at every `substId`-failure) **partially
  disproves session 40's "GC corrupts SimplEnv heap closure"
  hypothesis**.  Two iterations: v1 hardcoded threshold (size
  ≥5) didn't fire in failing runs because first simplRecBndrs
  call has scope=2; v2 logs every call.  **Findings:**
  (1) Pinned env's sizes are STABLE — pinned_was == pinned_now
  at panic time.  GC does NOT corrupt the env probe41 tracks.
  (2) The panic-site env is a DIFFERENT SimplEnv than the
  pinned one — pinned scope=2 vs substId-failure scope=5.
  Multiple envs in flight; probe41 didn't track the right one.
  (3) In a CLEAN compile (-A256m), first simplRecBndrs call has
  scope=10 (matching Big2.hs's ~10 top-level binders); in a
  FAILING compile (-A1m -G1 len=600), first simplRecBndrs has
  scope=2.  **New hypothesis:** the simplifier's input
  `binds0 / CoreProgram` is corrupted UPSTREAM of
  `simplTopBinds` — by the typechecker, desugarer, specializer,
  or interface deserializer.  v0.12.0 ships unchanged; probe
  applied and reverted; stage2 rebuilt+redeployed clean +
  smoke-test PASS + baseline tests 30 PASS / 4 FAIL_OUTPUT
  unchanged.  Session-41
  [`HANDOFF.md`](sessions/2026-05-13-session-41-simplenv-corruption-tracker/HANDOFF.md)
  scopes probe42: instrument `simplTopBinds`'s entry to dump
  `length (bindersOfBinds binds0)` and directly compare
  clean vs failing compile.
- [`docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/`](sessions/2026-05-13-session-42-probe-simpltopbinds-input/)
  — round 24.  **SMOKING GUN — root cause located.**  Probe42
  instruments `simplTopBinds`'s entry in `Simplify.hs` to log
  `(length binds0, length (bindersOfBinds binds0))`.  **Findings:**
  Clean compile (`-A256m`/`-A1G`): binds0 has 9 binders, call 2
  has 13.  Failing `-A1m -G1` at len=600/1650/1700: binds0 has
  **1 binder** → refineFromInScope panic.  Failing `-A1m -G1`
  at len=850-1000: binds0 has **0 binders** → ghc-real exits
  RC=0 producing a **152-byte empty .o file** (SILENT
  MISCOMPILE — no function definitions emitted; clean .o is
  46340 B).  `-A1G` always sees 9 binders.  Deterministic
  given env-len + RTS flags.  **Root cause:** GC corrupts the
  `[InBind]` cons-list spine flowing into `simplTopBinds`,
  truncating it to 0-1 elements.  This finding **subsumes
  every prior session's framing** — v's-closure-shape (S33-36),
  UniqMap-corruption (S28-38), Var.realUnique-drift (S38),
  two-distinct-Vars (S39), SimplEnv-field-corruption (S40-41)
  — all are downstream symptoms of the same root cause.
  **Severity update:** the bug is worse than previously thought
  — not just panics but also silent miscompiles producing
  empty .o files.  User-facing workaround: `+RTS -A1G -RTS`
  (or `-A256m`).  v0.12.0 ships unchanged; probe applied and
  reverted; stage2 rebuilt+redeployed clean + smoke-test PASS
  + baseline tests 30 PASS / 4 FAIL_OUTPUT unchanged.
  Session-42
  [`HANDOFF.md`](sessions/2026-05-13-session-42-probe-simpltopbinds-input/HANDOFF.md)
  scopes probe43: identify WHICH GC pass corrupts
  CONSTR_2_0 closures (the [InBind] cons cells).  Likely
  candidate: `rts/sm/Evac.c::copy_tag` on PPC32 unreg.

- [`docs/sessions/2026-05-13-session-43-trace-pipeline-binds/`](sessions/2026-05-13-session-43-trace-pipeline-binds/)
  — round 25.  **Corruption locus narrowed.**  Probe43 traces
  `mg_binds` length through the Core pipeline: hooks at
  `core2core` entry, `runCorePasses` entry, and each Core
  pass.  **Findings:** Clean compile (-A256m): CORE2CORE=9,
  INITIAL=9, Simplifier 9→13.  Failing len=600: CORE2CORE=1,
  INITIAL=1, panic.  Failing len=850: CORE2CORE=2, INITIAL=2,
  Simplifier 2→5, panic.  Failing len=1650: CORE2CORE=2,
  INITIAL=2, Simplifier 2→0 `*** DROPPED`, **RC=0 (silent
  miscompile)**.  **Key localization:** CORE2CORE count equals
  INITIAL count in every run — no drop between core2core entry
  and runCorePasses.  The `[InBind]` truncation happens
  **BEFORE `core2core`'s entry** — in the desugarer's output,
  in HscMain bridge code between desugarer and core2core, or
  via GC corrupting the heap-allocated `[InBind]` list while
  ModGuts sits in memory between phases.  Silent miscompile
  band extends: len=1650 is now a second silent-miscompile
  env-len (after session 42's 850-1000).  v0.12.0 ships
  unchanged; probe applied and reverted; stage2
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 4 FAIL_OUTPUT unchanged.  Session-43
  [`HANDOFF.md`](sessions/2026-05-13-session-43-trace-pipeline-binds/HANDOFF.md)
  scopes probe44: hook the desugarer's output
  (`HsToCore.deSugar`) to localize whether the truncation is
  IN the desugarer or in HscMain bridge code.
- [`docs/sessions/2026-05-13-session-44-hook-desugarer/`](sessions/2026-05-13-session-44-hook-desugarer/)
  — round 26.  **Corruption narrowed to WITHIN or BEFORE the
  desugarer.**  Probe44 hooks `HsToCore.deSugar` just before
  it returns, logging `final_prs` (desugarer output),
  `ds_binds` (post-simpleOptPgm), and `mg_binds` (in ModGuts).
  **Findings:** Clean: 9/9/9.  Failing len=600: 3/0/0 (silent
  miscompile).  Failing len=850: 6/4/4 (panic).  Failing
  len=1650: 5/3/3 (panic).  **`final_prs` is already truncated
  in failing runs** — the desugarer's main computation
  produces 3-6 binders instead of 9.  `simpleOptPgm` then
  drops binders further (legitimate DCE on broken input).
  Truncation candidates: typechecker's `tcg_binds`,
  `addTicksToBinds`, `dsTopLHsBinds`, `patchMagicDefns`,
  `dsImpSpecs`, `dsForeigns`, `dsRule`, OrdList ops, or
  `addExportFlagsAndRules`.  Most consistent with GC
  corrupting a heap-allocated cons-list spine.  v0.12.0 ships
  unchanged; probe applied and reverted; stage2
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 4 FAIL_OUTPUT unchanged.  Session-44
  [`HANDOFF.md`](sessions/2026-05-13-session-44-hook-desugarer/HANDOFF.md)
  scopes probe45: hook MORE granularly inside `deSugar`
  (length at each stage) to pinpoint the exact truncation step.
- [`docs/sessions/2026-05-13-session-45-granular-desugar/`](sessions/2026-05-13-session-45-granular-desugar/)
  — round 27.  **Desugarer ruled INNOCENT.**  Probe45 adds 7
  granular length hooks inside `HsToCore.deSugar` (tcg_binds,
  binds_cvr, core_prs_initial, core_prs_patched,
  all_prs_in_initDs, all_prs_outside_initDs, final_prs).
  **EVERY step preserves the count exactly** — clean compile
  shows 9/9/9/9/9/9/9; failing runs show 3/3/3/3/3/3/3,
  5/5/5/.../5, or 6/6/6/.../6.  The desugarer does not modify
  the binders list.  **The truncation has ALREADY happened by
  the time `tcg_binds` arrives at deSugar.**  Corruption is
  in: typechecker output, HscMain's `hscDesugar` bridge, or
  GC corrupting the heap-allocated `Bag (LHsBindLR GhcTc
  GhcTc)` during transit.  Note that `Bag.TwoBags` is a
  CONSTR_2_0 closure (2 pointer fields), structurally identical
  to `[a]` cons cells — the same GC bug that corrupts cons-list
  spines would also corrupt TwoBags closures.  v0.12.0 ships
  unchanged; probe applied and reverted; stage2
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 4 FAIL_OUTPUT unchanged.  Session-45
  [`HANDOFF.md`](sessions/2026-05-13-session-45-granular-desugar/HANDOFF.md)
  scopes probe46: hook the typechecker's TcGblEnv construction
  (`GHC.Tc.Module`) and HscMain's `hscDesugar` bridge
  (`GHC.Driver.Main`) to localize the truncation to
  typechecker, bridge code, or GC-in-transit.
- [`docs/sessions/2026-05-13-session-46-tc-and-bridge/`](sessions/2026-05-13-session-46-tc-and-bridge/)
  — round 28.  **Corruption locus narrowed to within the
  typechecker.**  Probe46 hooks `hsc_typecheck_exit`,
  `hscDesugar_entry`, `hscDesugarPrime_entry` in
  `Driver/Main.hs`.  All log `lengthBag (tcg_binds tc_env)`.
  **Findings:** Clean: 9/9 at hsc_typecheck_exit /
  hscDesugar'_entry.  Failing len=600: 3/3.  Failing len=1650:
  5/5.  `hscDesugar_entry` never fires (Big2.hs uses
  `hscDesugar'` directly).  The typechecker's output is
  already truncated at `hsc_typecheck` exit; the bridge
  preserves the count.  Corruption is **AT or BEFORE the
  typechecker's `return`** — within `tcRnModule'`, or via GC
  corrupting the heap Bag during typechecking.  **New
  observation:** baseline test battery now flakes — different
  test fails compile each run (26_threaded_rts, 01_int_arith).
  Sessions 37-45 had stable 30 PASS / 4 FAIL_OUTPUT; now
  FAIL_COMPILE appears intermittently.  Downstream symptom of
  the same GC bug.  v0.12.0 ships unchanged; probe applied
  and reverted; stage2 rebuilt+redeployed clean.  Session-46
  [`HANDOFF.md`](sessions/2026-05-13-session-46-tc-and-bridge/HANDOFF.md)
  scopes probe47: hook `tcRnModule` / `tcRnModule'` return
  points in `GHC/Tc/Module.hs` to narrow further within the
  typechecker.
- [`docs/sessions/2026-05-13-session-47-tc-rnmodule/`](sessions/2026-05-13-session-47-tc-rnmodule/)
  — round 29.  **Corruption narrowed to WITHIN `tcRnSrcDecls`.**
  Probe47 hooks 4 points inside `tcRnModuleTcRnM`:
  `after_tcRnImports`, `after_tcRnSrcDecls`,
  `after_checkHiBootIface`, `tcRnModuleTcRnM_exit`.
  **Findings:** Clean: 0/9/9/9.  Failing len=600: 0/5/5/5.
  Failing len=1650: 0/2/2/2.  `tcRnImports` doesn't populate
  tcg_binds (always 0 after it).  **`tcRnSrcDecls` is where
  tcg_binds becomes truncated** — clean produces 9, failing
  produces 2-5.  Subsequent steps preserve the count.  The
  truncation is WITHIN `tcRnSrcDecls` — the main typechecker
  pass.  Its body has many sub-steps: `tc_rn_src_decls`,
  `simplifyTop`, `zonkTopDecls`, etc.  v0.12.0 ships unchanged;
  probe applied and reverted; stage2 rebuilt+redeployed clean
  + smoke-test PASS + baseline tests 30 PASS / 4 FAIL_OUTPUT
  (clean run, session 46's flakiness wasn't deterministic).
  Session-47
  [`HANDOFF.md`](sessions/2026-05-13-session-47-tc-rnmodule/HANDOFF.md)
  scopes probe48: drill inside `tcRnSrcDecls` to identify the
  specific sub-step that truncates the binders list.
- [`docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/`](sessions/2026-05-14-session-48-drill-tcRnSrcDecls/)
  — round 30.  **Corruption narrowed to INSIDE
  `tcTopBinds val_binds val_sigs`.**  Probe48-v3 hooks 10
  points across `tcRnSrcDecls` / `tc_rn_src_decls` /
  `tcTopSrcDecls` in `compiler/GHC/Tc/Module.hs`.  Iterations
  v1 (single hook after `tc_rn_src_decls`) → v2 (added
  `mkTypeableBinds`, zonk, env'_final, binds_mf) → v2.5 (added
  `rnTopSrcDecls`, `tcTopSrcDecls` split) → v3 (added
  `tcTyClsInstDecls`, `tcTopBinds val_binds`,
  `tcTopBinds deriv_binds` inside `tcTopSrcDecls`).
  **Findings:** Clean: 0/0/**8**/8/8/8/9/9/9/0.  Failing
  len=600: 0/0/**2**/2/2/2/3/3/3/0.  Failing len=1650:
  0/0/**3**/3/3/3/4/4/4/0.  Both failing runs are silent
  miscompiles (RC=0).  `rnTopSrcDecls` and `tcTyClsInstDecls`
  produce 0 binders.  **`tcTopBinds val_binds val_sigs`**
  (defined in `compiler/GHC/Tc/Gen/Bind.hs`) **is where
  tcg_binds becomes truncated** — clean produces 8, failing
  produces 2-3.  Subsequent steps preserve the count (modulo
  +1 from `mkTypeableBinds`'s synthesized `$trModule`).
  v0.12.0 ships unchanged; probe applied and reverted; stage2
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 4 FAIL_OUTPUT (same known-flaky as session 47).
  Session-48
  [`HANDOFF.md`](sessions/2026-05-14-session-48-drill-tcRnSrcDecls/HANDOFF.md)
  scopes probe49: drill inside `tcTopBinds` (in
  `GHC.Tc.Gen.Bind`) — add per-binder logging to determine
  whether the input list is short or the in-progress bag is
  being lopped wholesale.
- [`docs/sessions/2026-05-15-session-49-drill-tcTopBinds/`](sessions/2026-05-15-session-49-drill-tcTopBinds/)
  — round 31.  **Session 49 OVERTURNS session 48 — corruption
  is BEFORE `tcTopBinds`, in the renamer.**  Probe49-v1 adds
  13 hook sites inside `compiler/GHC/Tc/Gen/Bind.hs`'s
  `tcTopBinds`, `tcValBinds`, `tcBindGroups`, and `tc_group`.
  The crucial new measurement is the INPUT to `tcTopBinds` (the
  `val_binds` argument).  **Findings:** Clean (-A256m):
  `tcTopBinds_entry_groups`=8, `entry_total`=8 (matches
  Big2.hs's 8 top-level bindings).  Failing -A1m -G1 len=600:
  `entry_groups`=2, `entry_total`=2.  Failing len=1650:
  `entry_groups`=2, `entry_total`=3 — with one group being a
  fake Recursive of size 2 (Big2.hs has no mutually recursive
  bindings; `depAnal` saw a phantom cycle, hinting at
  structural pointer corruption).  Per-group recursion through
  `tcBindGroups` / `tc_group` is faithful — whatever input
  arrives gets processed correctly.  **The list arriving at
  `tcTopBinds` is ALREADY truncated.**  Session 48's
  "inside `tcTopBinds`" claim was wrong (it measured the OUTPUT
  of `tcTopBinds`, not the input).  The truncation is upstream
  of the typechecker entirely — in the renamer that builds the
  `HsGroup`'s `hs_valds` field — most likely in
  `compiler/GHC/Rename/Bind.hs`'s `rnValBindsRHS` (line 298) →
  `mapBagM (rnLBind …) mbinds` (line 304) → `depAnalBinds`
  (line 570).  v0.12.0 ships unchanged; probe applied and
  reverted; stage2 rebuilt+redeployed clean + smoke-test PASS
  + baseline tests 30 PASS / 4 FAIL_OUTPUT (matches session-48
  noise floor).  Session-49
  [`HANDOFF.md`](sessions/2026-05-15-session-49-drill-tcTopBinds/HANDOFF.md)
  scopes probe50: drill inside `rnValBindsRHS` — hook
  `lengthBag mbinds` at entry, `lengthBag binds_w_dus` after
  `mapBagM rnLBind`, `length anal_binds` after `depAnalBinds`.

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
