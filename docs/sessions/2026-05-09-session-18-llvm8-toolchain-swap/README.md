# Session 18 — LLVM-7 r4 → LLVM-8 r5 cross-toolchain swap (rolled back)

**Date:** 2026-05-09.
**Status:** swap **attempted, rolled back**.  Blocked on upstream
clang-8 rebuild that includes the BUG-003 fix.  No release cut.

## What we wanted to do

Swap our cross-clang from LLVM-7 r4 (clang 7.1.1) to LLVM-8 r5
(clang 8.0.1) per the
[`llvm8-toolchain-swap.md`](../../proposals/llvm8-toolchain-swap.md)
proposal.  Sister project froze the LLVM-7 line at v7.1.1-r9 in
their session 032 and is now maintaining v8.0.1-r5 as the primary;
LLVM-7 ≡ LLVM-8 for PPC per Iain Sandoe.

User pointed at
`/Users/cell/claude/llvm-7-darwin-ppc/releases/8.0.1-r5/clang-8.0.1-ppc-darwin8.tar.gz`
and asked us to proceed.

## What we found out, in order

### 1. The released tarball is PPC-native, not host-cross

The r5 tarball ships a Tiger-self-host clang-8 binary (87 MB
PPC Mach-O).  Our cross-build needs an **arm64-host cross-clang**
that targets PPC.  These are two different artifacts; the released
tarball isn't one we can use directly.

The arm64-host cross-clang lives in the sister project's build
tree on `indium`, exactly analogous to how we got the LLVM-7
r4 binary in v0.10.0 / v0.11.0.

### 2. `-fllvm` was a no-op anyway

While probing, ran `ghc -fllvm -c probe.hs -v` and saw:

```
*** CodeGen [Main]:
*** C codegen:                  ← unreg-C path
*** systool:cc:
*** C Compiler:
*** systool:as:
```

GHC's `-fllvm` flag is silently overridden when the target ABI is
unregisterised.  Hadrian even logs `Target platform uses
unregisterised ABI, so compiling via C` for every Haskell file.

So all the v0.10.0 / v0.11.0 release narrative around "LLVM-7 r4
vs no-LLVM" was misframed.  Both modes use the same `clang` binary,
just to compile the C output of `compiler/GHC/CmmToC.hs`.  The
`-fllvm` flag has been a no-op the whole time.

This actually makes the toolchain swap *more* meaningful than the
proposal anticipated: clang is what runs on every `.c` produced
by our cross-build, not just on `.ll` IR.  Better optimiser +
miscompile fixes hit the libraries and stage1 directly.

### 3. Indium's `build-llvm8/bin/clang-8` predates the BUG-003 fix

Pulled the indium binary (`build-llvm8/bin/clang-8`, dated
Apr 25 16:44, 112 MB), wrote a smoke-test C file (
`probe-clang8.c` with `<stdarg.h>`), ran through `ppc-cc`,
got a clean `Mach-O object ppc`.  Resource-dir resolved to
`~/.local/lib/clang/8.0.1/include/` (extracted from r5 tarball,
which fixes BUG-009 / sparse headers).

But: indium's clang-8 binary is dated **Apr 25**.  The BUG-003 fix
landed in the LLVM-8-Branch source tree on Apr 29 (still
uncommitted on indium — it's a working-tree change in
`llvm/lib/Target/PowerPC/InstPrinter/PPCInstPrinter.cpp` that
adds the `r0`/`ZERO` → `"r0"` literal output).  The build is
older than the patch.

When we wired the new clang-8 into the hadrian rebuild and started
cross-compiling the libraries, the integrated assembler tripped
on its own output:

```
ghc_1.s:2389:14: error: unexpected integer value
        lwz r2, 20(0)
                   ^
…
ghc_1.s:2416:14: error: unexpected integer value
        lwz r26, 12(0)
                    ^
ppc-cc' failed in phase `Assembler'.
```

This is exactly BUG-003: clang's PPC asm printer emits `0` for the
ZERO/R0 base register, then clang's own integrated assembler
rejects it.  The r4+ release fixes this; the indium build doesn't
have it.

### 4. Indium can't rebuild right now

Tried `ninja clang` on `~/tmp/claude/llvm-7-darwin-ppc/build-llvm8`:

```
/bin/sh: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++: No such file or directory
```

Xcode is uninstalled but `CMakeCache.txt` still references it
(stale paths for cc / c++ / ar / ld / nm / etc.).  Sed-replaced
the Xcode paths with `/usr/bin/` equivalents and re-ran ninja.
Got further (clang++ found this time), but immediately:

```
fatal error: 'new' file not found
```

`/usr/bin/clang++` from the CommandLineTools install on indium
is missing the C++ standard library headers.  Either CommandLineTools
needs reinstalling, or we need to install Xcode.  Both are
indium-environment fixes outside the scope of this session.

### 5. Rolled back

To preserve a working toolchain, restored the LLVM-7 install:

- `mv clang-7.llvm7.bak → clang-7`
- `mv lib/clang/7.1.1.llvm7.bak → lib/clang/7.1.1`
- `ln -s clang-7 ~/.local/ghc-ppc-xtools/clang`
- Wiped 591 stale `.o`/`.hi`/`.d` files that were created by the
  partial clang-8 build (in `_build/stage1/{rts,libffi,…}/build/`).
- Reverted `cross-env.sh` comment back to LLVM-7 install procedure.

Verified: cross-build of `main = putStrLn "rollback-ok"` produces
a clean `Mach-O executable ppc` again.

## What ended up in the working tree

Still on disk for the next attempt:

- `~/.local/ghc-ppc-xtools/clang-8` — 112 MB arm64 clang-8 binary
  from indium's build-llvm8 (pre-BUG-003-fix; **don't symlink as
  clang until rebuilt with the fix**).
- `~/.local/lib/clang/8.0.1/include/` — 118 freestanding headers
  from the r5 tarball.  Independent of the binary; can stay.
- `clang-7.r3.llvm7.bak` (older LLVM-7 binary) — left as backup.

These are harmless by themselves.  The active `clang` symlink
points at clang-7 again.

## What needs to happen for the swap to land

1. **Indium's CommandLineTools or Xcode install needs fixing** so
   `clang++` can find `<new>` and the rest of libc++.  Probably
   `xcode-select --install` (re-run) or installing full Xcode.
   This is host maintenance, not our project's work.

2. After indium is healthy, rebuild clang-8 with the BUG-003 patch
   committed (or at least applied) on the LLVM-8-Branch tree.

3. Then redo session 18: rsync the new `build-llvm8/bin/clang-8`,
   keep our existing r5 freestanding headers, repoint the symlink,
   wipe shake.database, rebuild stage1, redeploy stage2, cut
   v0.12.0.

4. The proposal at `docs/proposals/llvm8-toolchain-swap.md` stays
   open but with this session's findings appended.

## Cross-references

- Proposal (still open): [`docs/proposals/llvm8-toolchain-swap.md`](../../proposals/llvm8-toolchain-swap.md)
- Sister-project rationale: [`llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/rationale-llvm7-freeze.md`](../../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/rationale-llvm7-freeze.md)
- BUG-003 (the clang asm printer fix that the indium build is
  missing): in
  [`llvm-7-darwin-ppc/LLVM-8-Branch/llvm/lib/Target/PowerPC/InstPrinter/PPCInstPrinter.cpp`](../../../../llvm-7-darwin-ppc/LLVM-8-Branch/llvm/lib/Target/PowerPC/InstPrinter/PPCInstPrinter.cpp)
  on indium — lines 420–434, see `git diff HEAD` there.
- r5 release (PPC-native, not the artifact we need but does ship
  the BUG-009 freestanding-header fix we want):
  [`llvm-7-darwin-ppc/releases/8.0.1-r5/NOTES.md`](../../../../llvm-7-darwin-ppc/releases/8.0.1-r5/NOTES.md)
