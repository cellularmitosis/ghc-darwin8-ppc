# Session 18 — LLVM-7 r4 → LLVM-8 r5 cross-toolchain swap (two attempts, both rolled back)

**Date:** 2026-05-09.
**Status:** swap **blocked on a new clang-8 codegen bug**.  Rolled back
to LLVM-7 r4.  No release cut.  Bug-report draft for the sister project
at [`llvm8-r5-rts-miscompile-draft.md`](llvm8-r5-rts-miscompile-draft.md).

## What we wanted to do

Swap our cross-clang from LLVM-7 r4 (clang 7.1.1) to LLVM-8 r5
(clang 8.0.1) per the
[`llvm8-toolchain-swap.md`](../../proposals/llvm8-toolchain-swap.md)
proposal.  Sister project froze the LLVM-7 line at v7.1.1-r9 in their
session 032 and is now maintaining v8.0.1-r5 as the primary; LLVM-7
≡ LLVM-8 for PPC per Iain Sandoe.

## Attempt 1 (rsync from indium): blocked on indium env

User pointed at
`/Users/cell/claude/llvm-7-darwin-ppc/releases/8.0.1-r5/clang-8.0.1-ppc-darwin8.tar.gz`
to "proceed with the toolchain swap to llvm 8".  Released tarball is
PPC-native (Tiger self-host); not what our arm64-host cross-build
needs.  Tried to rsync the host-cross binary from
`indium:~/tmp/claude/llvm-7-darwin-ppc/build-llvm8/bin/clang-8`.

Two problems:

1. **Indium's clang-8 binary predates the BUG-003 fix.**  Dated
   Apr 25; the asm-printer fix landed in source on Apr 29.  Built
   stage1 against it and tripped on `lwz r2, 20(0)` — bare `0` for
   ZERO/R0 base register, classic BUG-003.

2. **Indium can't currently rebuild.**  Xcode uninstalled there, and
   `/usr/bin/clang++` from the CommandLineTools install is missing
   `<new>`.  Sed-replacing Xcode paths in `CMakeCache.txt` got
   further but hit `'new' file not found`.

Rolled back, restored clang-7, wiped 591 stale `.o`/`.hi`/`.d` files,
verified cross-build still produces PPC Mach-O.

User then said: "I trimmed some dev-related stuff to free up room
to run local llm's.  can you build on this laptop (uranium) from now
on?"

## Attempt 2 (build on uranium): clang-8 builds, but the resulting GHC RTS crashes

1. Rsync'd `LLVM-8-Branch/` source from indium to uranium (1.5 GB
   including .git history + uncommitted patches in working tree:
   BUG-003, ABI-001, ABI-002, and the Tiger Mach-O load-command
   patches).  Set up `/Users/cell/claude/llvm-7-darwin-ppc/build-llvm8-uranium/`
   with `cmake -G Ninja -DCMAKE_BUILD_TYPE=Release
   -DLLVM_TARGETS_TO_BUILD="PowerPC;X86" -DLLVM_ENABLE_ASSERTIONS=ON`.

2. `ninja clang` finished in **8 minutes** on uranium (much faster
   than indium because uranium has more cores + working Xcode).
   Resulting binary: 112 MB arm64 clang version 8.0.1.

3. Smoke tests passed end-to-end:
   - Standalone C compile via ppc-cc → Mach-O object ppc ✓
   - C with `<stdio.h> <stdarg.h> <stddef.h>` includes → Mach-O ppc ✓
   - **ABI-001 verification:** `va_arg(ap, struct Big)` test
     program compiled, deployed to pmacg5, ran correctly.  The
     ABI-001 fix in the working-tree patches is in the binary.

4. Wiped shake.database; ran hadrian.  Stage1 built clean with
   clang-8 in **16m45s**.  No BUG-003 errors, no failures.
   Compared to LLVM-7's 48m46s rebuild — clang-8 is also notably
   faster.

5. Cross-built ghc/Main.hs against new stage1 to make stage2.
   193 MB Mach-O ppc_7400.  Deployed to pmacg5 as
   `/opt/ghc-stage2/bin/ghc-real`.

6. **Smoke-test failed.**  `ghc-real --version` exits 138 (= SIGBUS on
   PPC Darwin) silently.  No output.

7. Tried a simple Haskell program through the new stage1
   (`main = putStrLn "from clang-8 build"`) — same SIGBUS, exit 138.
   So the bug isn't stage2-specific; **any** Haskell binary built
   through the new toolchain crashes at startup.

8. gdb backtrace on Tiger:

   ```
   Program received signal EXC_BAD_ACCESS, Could not access memory.
   Reason: KERN_PROTECTION_FAILURE at address: 0x0000000c
   0x0049fde4 in updateNurseriesStats ()
   #0  0x0049fde4 in updateNurseriesStats ()
   #1  0x0048af54 in stat_startGC ()
   #2  0x00494ef4 in GarbageCollect ()
   #3  0x00489594 in scheduleDoGC ()
   #4  0x00488eb0 in scheduleWaitThread ()
   #5  0x00483208 in rts_evalLazyIO ()
   #6  0x0048593c in hs_main ()
   #7  0x0000a6b8 in main ()
   ```

   Crash is in `updateNurseriesStats` at
   [`rts/sm/Storage.c:1584`](../../../external/ghc-modern/ghc-9.2.8/rts/sm/Storage.c)
   during the very first garbage collection.  Address `0x0000000c`
   — NULL+12, a struct-field offset.  This code worked correctly
   under clang-7 r4 in v0.10.0/v0.11.0.

9. The miscompiled function:

   ```c
   void
   updateNurseriesStats (void)
   {
       uint32_t i;
       bdescr *bd;

       for (i = 0; i < getNumCapabilities(); i++) {
           bd = capabilities[i]->r.rCurrentNursery;
           if (bd) finishedNurseryBlock(capabilities[i], bd);
           bd = capabilities[i]->r.rCurrentAlloc;
           if (bd) finishedNurseryBlock(capabilities[i], bd);
       }
   }
   ```

   Something about how clang-8 codegens the `capabilities[i]->r.rCurrentNursery`
   load is wrong.

## Rolled back (again)

- Restored clang-7 (`mv clang-7.llvm7.bak → clang-7`,
  `ln -s clang-7 ~/.local/ghc-ppc-xtools/clang`).
- Wiped 6,200+ stale clang-8 `.o`/`.hi`/`.d`/`.a` files from
  `_build/stage1/`.
- Stage1 lib/ was wiped along with everything else, so a full
  hadrian rebuild with LLVM-7 is needed to restore baseline.
  Currently in flight (~50 min).
- Reverted cross-env.sh comment changes.

## What ended up in the working tree

Still on disk for the next attempt:

- `/Users/cell/claude/llvm-7-darwin-ppc/LLVM-8-Branch/` — full source
  with patches in working tree.  Gitignored at the LLVM project's
  `.gitignore` in attempt-2 prep (`/LLVM-8-Branch/` + `/build-*/`
  added).
- `/Users/cell/claude/llvm-7-darwin-ppc/build-llvm8-uranium/` —
  fresh ninja-build dir; rebuilds incrementally via `ninja clang`.
- `~/.local/ghc-ppc-xtools/clang-8` — 112 MB arm64 binary with
  all patches.  Don't symlink as `clang` until the RTS miscompile
  is fixed.
- `~/.local/lib/clang/8.0.1/include/` — 118 r5 freestanding headers.
- `/tmp/clang8-rts-crash-bt.txt` — gdb backtrace evidence.

## What needs to happen for the swap to land

Sister project needs to investigate the
`updateNurseriesStats` miscompile.  Bug-report draft:
[`llvm8-r5-rts-miscompile-draft.md`](llvm8-r5-rts-miscompile-draft.md).

Hypothesis: a clang-8 PPC codegen issue around the
`capabilities[i]->r.field` access pattern (array of pointers into
`Capability` struct's `r :: StgRegTable`).  Either an aliasing /
optimisation bug, or an issue with how clang-8 lays out / emits
loads from large structs.  Doesn't reproduce in the simple
struct-vararg test (so isn't the same as ABI-001), and doesn't
hit BUG-003 (no bare `0(0)` syntax errors at assembly time).

When the sister project lands the fix in r6 / r7 / etc., we redo
this session's procedure — should take 30 minutes start-to-finish
since all the source / build / install paths are now wired up.

## Side discovery from session 18 attempt 2

`-fllvm` is silently a no-op for unregisterised ABI targets.  Hadrian
logs `Target platform uses unregisterised ABI, so compiling via C`
for every Haskell file.  All v0.10.0 / v0.11.0 release narrative
that framed builds as "LLVM vs no-LLVM" was misframed; both modes
use the same clang to compile the C output of `compiler/GHC/CmmToC.hs`.
Updated proposal G + roadmap entry.

## Cross-references

- Proposal (still open): [`docs/proposals/llvm8-toolchain-swap.md`](../../proposals/llvm8-toolchain-swap.md)
- Bug-report draft: [`llvm8-r5-rts-miscompile-draft.md`](llvm8-r5-rts-miscompile-draft.md)
- Sister-project rationale: [`llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/rationale-llvm7-freeze.md`](../../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/rationale-llvm7-freeze.md)
- r5 release notes (BUG-009 / freestanding-headers fix):
  [`llvm-7-darwin-ppc/releases/8.0.1-r5/NOTES.md`](../../../../llvm-7-darwin-ppc/releases/8.0.1-r5/NOTES.md)
