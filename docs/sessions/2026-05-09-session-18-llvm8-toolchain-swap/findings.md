# Session 18 findings

## `-fllvm` is a no-op in our build

Verbose probe: `ghc -fllvm -c probe.hs -v` shows `*** C codegen:`
followed by `*** systool:cc:`.  No `llc`, no `opt`.  GHC silently
overrides `-fllvm` when the target ABI is unregisterised.  Hadrian
also logs `Target platform uses unregisterised ABI, so compiling
via C` for every Haskell file.

Implication: when we eventually do the LLVM-8 swap, the win is
about *which clang compiles the C output of `compiler/GHC/CmmToC.hs`*,
not about the LLVM IR pipeline.  All the libraries / RTS / stage1
compiler library go through that one clang.

Documentation in v0.10.0 / v0.11.0 release notes incorrectly
framed the choice as "LLVM-7 vs no-LLVM"; both modes use the same
clang binary.  The earlier "no-LLVM" rebuild experiment in session
17 also went through clang-7, just with a flag that didn't change
behavior.

## The sister project's "ppc-darwin8" tarballs are PPC-native

`releases/v8.0.1-r5/clang-8.0.1-ppc-darwin8.tar.gz` is a Tiger
self-host clang (87 MB PPC Mach-O).  It's not the artifact our
arm64 cross-build needs.

The host-cross binary lives on `indium` at
`~/tmp/claude/llvm-7-darwin-ppc/build-llvm8/bin/clang-8`, exactly
analogous to where we got the LLVM-7 r4 binary in v0.10.0.

For future swaps: the pattern is **rsync the binary from indium's
build dir**, not the released tarball.  Use the released tarball's
`lib/clang/8.0.1/include/` for the freestanding headers (it's the
audited / BUG-009-fixed shape) but combine it with indium's
arm64 binary.

## Indium's cmake build is broken

`build-llvm8/CMakeCache.txt` references `/Applications/Xcode.app/...`
paths that no longer exist (Xcode uninstalled).  Sed-replacing
those with `/usr/bin/...` makes the build start, but
`/usr/bin/clang++` then fails with `'new' file not found` because
indium's CommandLineTools install is missing the C++ standard
library headers.

To unblock LLVM-8 swaps we need indium-side host maintenance:
either `xcode-select --install` (re-run) or a full Xcode install.
Outside the scope of any one ghc-darwin8-ppc session.

## The BUG-003 fix is uncommitted on indium

In `~/tmp/claude/llvm-7-darwin-ppc/LLVM-8-Branch`, the patch is
visible as `git diff HEAD --
llvm/lib/Target/PowerPC/InstPrinter/PPCInstPrinter.cpp` but
isn't on a branch.  The build dated Apr 25 predates it.

Same story on `LLVM-7-branch`, but there the binary at
`build-phase0/bin/clang-7` is dated Apr 29 — after the patch was
applied — so it picks the fix up.  That's why our v0.10.0
profiling and v0.11.0 stage2 builds worked.

For session 18's purposes: a proper r5 swap needs a `build-llvm8`
binary that's at least Apr 29, ideally on a committed branch
state.

## Recovery procedure works

When the swap failed, we:

- restored the LLVM-7 install (rename clang-7 backup back into place)
- wiped 591 stale `.o`/`.hi`/`.d` files left by the partial clang-8
  hadrian run
- reverted cross-env.sh comments
- verified the cross-build still produces PPC Mach-O

Cost: zero.  The LLVM-7 install is byte-identical to before.

That gives us confidence to retry the swap once indium is healthy:
backup again, swap, fail, roll back, no harm done.

## Things to keep on disk for next time

- `~/.local/ghc-ppc-xtools/clang-8` — pre-fix clang-8 binary
  (don't symlink as `clang`; useful only as a sanity reference
  when checking that a fresh build actually picks up new bytes).
- `~/.local/lib/clang/8.0.1/include/` — 118 freestanding headers
  from the r5 tarball.  Architecture-independent C headers, can
  stay even with LLVM-7 active.

Both are <120 MB combined, fine to leave for next time.

## Attempt 2 finding (uranium build): RTS miscompile

clang-8 r5 (built on uranium with all known patches) miscompiles
GHC's RTS.  Specifically `updateNurseriesStats` in
`rts/sm/Storage.c:1584` crashes at first call with
`EXC_BAD_ACCESS at 0x0000000c`.

Bug shape:

- ABI-001 (struct-vararg) test program passes on Tiger.  So the
  ABI-001 fix is in our binary.
- BUG-003 (asm-printer ZERO/r0 syntax) doesn't trigger during
  stage1 build.  So the BUG-003 fix is in our binary.
- Yet the same C code that compiles correctly under clang-7 r4
  produces a NULL-deref crash under clang-8 r5.

A new miscompile, distinct from the three known ones above.
Probably in `array_of_ptr_to_struct[i]->embedded_struct.field`
codegen for PPC32 Darwin.  Not yet reduced to a non-GHC test case.

Drafted as a bug report for the sister project.

## Build-host lesson

Uranium is a much faster LLVM build host than indium:

| host | clang ninja-build wall | cores |
|---|---|---|
| indium | 30+ min (when working) | dual-core |
| uranium | 8 min | M-series many-core |

For future LLVM swaps, build on uranium directly — fewer moving
parts, faster turnaround.  Source rsynced once is 1.5 GB.

## Recovery cost

Rolling back from a bad clang-8 swap costs us ~50 min of hadrian
rebuild because stage1's `_build/lib/` had to be wiped clean to
remove half-baked clang-8 outputs.  Worth scripting / tracking
better next time:

- Snapshot `_build/stage1/lib/` before swapping.
- Or use a side-by-side `_build/` per toolchain.

Not urgent unless we attempt the swap many more times.
