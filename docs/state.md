# state.md — where are we right now

*Updated: 2026-04-22, end of overnight session.*

## Current phase

**Pivoting out of Path A, into Path B Phase 3.** Path A relied on
installing a prebuilt PPC/Darwin GHC binary on Tiger as a
bootstrap, but all three available prebuilts (6.10.4 maeder, 7.0.1
maeder, 7.0.4 krabby) are Leopard-or-later builds that fault in
libSystem's `_malloc_initialize` when run on Tiger. Details in
[`experiments/001-ghc-704-pkg-on-tiger.md`](experiments/001-ghc-704-pkg-on-tiger.md).

The plan's original Phase 1 (install 7.0.4 .pkg, run hello world)
turned out to be a load-bearing assumption that fails. Revised
approach below.

## What is known to work

- Full repository scaffolding. Plan, notes (codebase tour, file
  mapping 8.6→9.2, bootstrap chain, iconv ABI mismatch,
  fleet recon, 7.0.4 pkg anatomy), testprogs corpus, external
  downloads (6.10.4 + 7.0.4 + 7.6.3 sources, 6.10.4 + 7.0.1 +
  7.0.4 binaries, GHC 8.6.5 and 9.2.8 source trees).
- Fleet confirmed reachable: 8 of 9 Tiger/Leopard hosts up
  (pmacg3 is offline). pmacg5 chosen as primary build host
  (970MP dual-core 2.3, 51 GB free on /, 2 GB RAM, /opt has GMP
  4.3.2 + 6.2.1, libiconv 1.16, libffi 3.4.2, ncurses 6.3,
  gcc 4.9.4 + 10.3.0 + 14, cctools 667.3, ld64-97.17-tigerbrew,
  python 3.11.2 + 2.7.18, autoconf 2.13).
- The krabby 7.0.4 framework extracts, installs, and does loadtime
  library resolution successfully on pmacg5 with
  `DYLD_LIBRARY_PATH=/opt/libiconv-1.16/lib`. `ghc-pkg list` runs
  end-to-end. Only the main `ghc` binary (full RTS init) hits the
  `_malloc_initialize` crash; this is *not* a setup problem.

## What is currently blocking progress

Nothing hard-blocked. The pivot to Path B is straightforward —
it's what Trommler recommended up front, and we have everything
needed: 9.2.8 source tree, 8.6.5 source tree (for comparison), the
removal-commit diff cached offline, the cross-toolchain ideas from
the sibling `llvm-7-darwin-ppc` project (which has working clang
for `powerpc-apple-darwin8` Mach-O output).

Biggest open sub-choices (decide in the next session):

1. ~~**Cross-toolchain source.**~~ **Decided:** reuse the sibling
   `llvm-7-darwin-ppc` project's clang on `indium`. First-contact
   probe confirmed it produces PPC Mach-O for a trivial C program.
   See [`notes/cross-toolchain-strategy.md`](notes/cross-toolchain-strategy.md).
2. **GHC host build tool.** Tentative: `ghcup install ghc 9.2.8` on
   indium. Install in next session; not a decision, just a step.
3. **Initial target: unregisterised or direct?** Trommler recommends
   starting `--enable-unregisterised`. Non-negotiable for phase 3.

## Key open questions

1. Do the prebuilt binaries work on Leopard? Quick experiment
   remaining on mdd / pbookg42 — needed sudo password. Not
   blocking; just nice-to-have for cross-check. **Defer.**
2. Is there a way to recover Path A cheaply? E.g. build 7.0.4 from
   source on Leopard with `--with-macosx-deployment-target=10.4`,
   cross-install to Tiger. Maybe worth a separate experiment
   later if the modern cross-bootstrap runs into insurmountable
   trouble. **Defer.**
3. Does the `llvm-7-darwin-ppc` project's clang emit the exact
   Mach-O dialect GHC's NCG expects? **Find out in Phase 3
   when we try linking cross-compiled Haskell against it.**

## Last-touched state

- Git: `main` branch, 2 commits, clean.
- Latest commit: `da20d84 Phase 0: codebase tour, file mapping,
  bootstrap chain, test corpus.`
- Local clones: `external/ghc-8.6.5/`, `external/ghc-modern/ghc-9.2.8/`.
- Primary build host: `pmacg5` (Tiger). Framework installed
  but non-functional at
  `/Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/`.
  Kept in place; harmless; supports the
  `scripts/install-ghc-704-on-tiger.sh` rollout path if we
  revisit Option A'.

## Immediate next steps (for next session)

Target: a cross-compile of a trivial `hello.hs` to ppc Mach-O.

1. **~~Pick the cross-C-toolchain.~~** Done — see
   [`notes/cross-toolchain-strategy.md`](notes/cross-toolchain-strategy.md).
   Using the sibling LLVM-7 project's clang on indium.
2. **Install a modern GHC on indium.**
   `ghcup install ghc 9.2.8 && ghcup set ghc 9.2.8`.
   Required to drive the cross-compile.
3. **Rsync GHC 9.2.8 source to indium.**
   `~/bin/tiger-rsync.sh` won't work (it's Tiger-specific), just
   use plain rsync or `git clone` on indium directly.
4. **`./configure --target=powerpc-apple-darwin8
      --enable-unregisterised CC=$CLANG CFLAGS="-target
      powerpc-apple-darwin8 -isysroot $SDK"`** in the GHC source
   tree. Expect this to fail at the target-recognition step
   (374e447 deleted `powerpc-darwin` from recognized triples).
   Capture the error, write the first patch
   `patches/0001-restore-configure-ac-target-darwin-powerpc.patch`.
5. **Iterate through configure → build → (fail) cycle with
   forward-ported hunks from 374e44704b**, one file at a time,
   following the priority list in
   [`notes/file-mapping-86-vs-modern.md`](notes/file-mapping-86-vs-modern.md).
6. **Milestone:** unregisterised cross-compiler emits a PPC Mach-O
   `hello.o` that a Tiger host runs after linking.

## Files to read first for anyone picking this up

In order:

1. [`plan.md`](plan.md) — the big picture
2. [`state.md`](state.md) — this file (where we are)
3. [`log/2026-04-22-phase0-and-path-a-pivot.md`](log/2026-04-22-phase0-and-path-a-pivot.md)
4. [`notes/codebase-tour.md`](notes/codebase-tour.md) — what PPC/Darwin code looks like in 8.6.5
5. [`notes/file-mapping-86-vs-modern.md`](notes/file-mapping-86-vs-modern.md) — how it has moved in 9.2
6. [`notes/bootstrap-chain.md`](notes/bootstrap-chain.md) — why we're going straight to Path B
7. [`experiments/001-ghc-704-pkg-on-tiger.md`](experiments/001-ghc-704-pkg-on-tiger.md) — why Path A didn't work
