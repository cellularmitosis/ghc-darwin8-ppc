# DRAFT — clang-8 r5 miscompiles GHC RTS `updateNurseriesStats` on PPC32 Darwin

**Status:** draft, ready to file as a bug against the sister
[llvm-darwin8-ppc](https://github.com/cellularmitosis/llvm-darwin8-ppc)
project once the user reviews.
**Audience:** sister project (Jason).
**Severity:** blocks the LLVM-7 → LLVM-8 toolchain swap for
ghc-darwin8-ppc.  No regression for existing LLVM-8 users — this is
new test coverage that just got attempted.

## One-line summary

clang-8 r5 (the binary built fresh on uranium, with all the working-
tree patches: BUG-003 + ABI-001 + ABI-002 + Tiger Mach-O LCs)
produces a GHC RTS where the very first call to
`updateNurseriesStats` SIGBUSes — `EXC_BAD_ACCESS at 0x0000000c`,
i.e. NULL+12.

clang-7 r4 (same patch set ported one version back) compiles the
same `rts/sm/Storage.c` correctly — that's our v0.10.0 / v0.11.0
shipping toolchain.

## Reproducer

Tools needed (all on uranium except the run target):

- `~/.local/ghc-ppc-xtools/clang-8` — built from
  `/Users/cell/claude/llvm-7-darwin-ppc/build-llvm8-uranium/bin/clang-8`
  (LLVM-8-Branch with the working-tree patches).
- A Tiger PPC machine for the run-time test.

Steps:

1. Install clang-8 as our cross-clang:

   ```sh
   ln -sf clang-8 ~/.local/ghc-ppc-xtools/clang
   ```

2. Wipe shake.database in
   `~/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/_build/`
   and rebuild stage1:

   ```sh
   cd ~/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8
   rm -f _build/hadrian/.shake.database
   source ~/claude/ghc-darwin8-ppc/scripts/cross-env.sh
   ./hadrian/build --flavour=quick-cross --docs=none -j8
   ```

   No errors.  Build completes in ~17 minutes.

3. Cross-build a trivial Haskell program through the new stage1:

   ```sh
   echo 'main = putStrLn "x"' > /tmp/hello.hs
   _build/stage1/bin/powerpc-apple-darwin8-ghc \
       /tmp/hello.hs -o /tmp/hello -outputdir /tmp/hello-build
   ```

   `/tmp/hello` is a 17-MB Mach-O ppc executable.  No errors.

4. Deploy and run on a Tiger PPC host:

   ```sh
   scp /tmp/hello tiger:/tmp/hello
   ssh tiger 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /tmp/hello'
   ```

   Expected: `x`
   Observed: silent exit, status 138 (= signal 10 = SIGBUS).

5. gdb on Tiger:

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

## The miscompiled function

[`rts/sm/Storage.c:1584`](https://gitlab.haskell.org/ghc/ghc/-/blob/ghc-9.2.8-release/rts/sm/Storage.c#L1584)
in GHC 9.2.8:

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

`capabilities` is a `Capability **`.  Each `Capability` contains an
embedded `StgRegTable` named `r` whose
`rCurrentNursery`/`rCurrentAlloc` fields live some offset into the
struct.  `0x0000000c = 12` is suspiciously close to a small
struct-field offset.

The crash address `0x0000000c` suggests that **either**:

- `capabilities[i]` is being read as NULL (and then `->r.rCurrentNursery`
  dereferences NULL+offset), or
- `capabilities[i]->r.rCurrentNursery` is loaded from somewhere
  wrong, returning a NULL+12-style address.

Under clang-7 r4 with the same source, this same loop runs correctly
on the same Tiger host and produces working `.prof` reports
(v0.10.0).

## What I tested to triangulate

- `va_arg(ap, struct Big)` test program (the canonical ABI-001
  reproducer): **PASSES** under clang-8 r5 on Tiger.  ABI-001
  patch is in our binary.
- BUG-003 / `lwz r0, 20(0)` integrated-assembler errors during the
  hadrian rebuild: **none**.  BUG-003 fix is in our binary.
- Simple C program with `<stdio.h>`/`<stdarg.h>`/`<stddef.h>`
  through the ppc-cc wrapper: compiles and runs.

So this isn't the same shape as ABI-001/002/BUG-003.  It's a new
PPC32 Darwin codegen issue specific to the
`array_of_ptr_to_struct[i]->embedded_struct.field` access pattern,
or possibly to the `Capability` struct's specific layout in GHC.

## Things that would help confirm

If you (sister project) have a way to:

- `objdump --disassemble` the suspect function from clang-7 r4 vs
  clang-8 r5 and diff, you'd probably see the codegen difference
  immediately.
- A reduced C reproducer would help — I started with the exact
  `Capability`/`StgRegTable` layout from
  [`includes/rts/Capability.h`](https://gitlab.haskell.org/ghc/ghc/-/blob/ghc-9.2.8-release/rts/include/rts/Capability.h)
  but couldn't immediately get the same crash from a synthesized
  micro-test.  May need the full `Capability` layout and the GHC
  scheduler init path.

I can capture the relevant `.s` files from both clang-7 and clang-8
runs of `rts/sm/Storage.c` if that's useful — let me know.

## Workaround (in this project)

Stay on LLVM-7 r4 for the cross-clang.  Roll back the symlink to
`clang-7`.  Already done in our repo as of session 18 v2; v0.12.0
not cut.

## Cross-references

- Session 18 README:
  [`ghc-darwin8-ppc/docs/sessions/2026-05-09-session-18-llvm8-toolchain-swap/README.md`](README.md)
- Build evidence:
  - `/tmp/hadrian-llvm8-uranium.log` — clean stage1 build with clang-8
  - `/tmp/clang8-rts-crash-bt.txt` — gdb backtrace from Tiger run
- The patches that ARE working on clang-8 (in
  `LLVM-8-Branch` working tree):
  - BUG-003: `llvm/lib/Target/PowerPC/InstPrinter/PPCInstPrinter.cpp:420-440`
  - ABI-001 + ABI-002: `clang/lib/CodeGen/TargetInfo.cpp` (243-line diff)
- Existing-working clang-7 r4 (no patches beyond BUG-003):
  [`llvm-7-darwin-ppc/LLVM-7-branch`](../../../../llvm-7-darwin-ppc) on indium

## File / don't file?

Worth filing.  This is the first concrete reproducer where clang-8
miscompiles real-world (non-toy) PPC32 Darwin C code, and the
sister project's stress-shipped harness wouldn't have caught it
(GHC's RTS is a whole different code shape from any of the
existing test surfaces).
