# Session 17 — stage2 investigation: bug shape and no-LLVM experiment

**Date:** 2026-04-29 → 2026-04-30.
**Original goal:** test whether stage1's `-O` optimisation of the ghc
compiler library miscompiles `simpleOptPgm`, leading to stage2
emitting empty `.o` files (session 14's narrowed bug).

**Outcome so far:**
- The `-O0` hypothesis was wrong; -O0 libraries produce the same
  empty `.o` files for trivial test modules.
- A much sharper picture of the bug emerged.  See
  [`stage2-non-determinism-finding.md`](stage2-non-determinism-finding.md).
- **New experiment in flight:** rebuild stage1 with `-fllvm` removed
  (use the unreg-C codegen path through gcc14 instead of LLVM-7), to
  test whether the bug lives in the LLVM-7 PPC backend.

## What we did, in order

### Day 1 (2026-04-29)

1. `hsLibrary` flipped from `-O -fllvm` → `-O0 -fllvm` in
   `hadrian/src/Settings/Flavours/QuickCross.hs`.
2. Wiped `_build/hadrian/.shake.database`; rebuilt stage1 from
   clean (~54 minutes).
3. Cross-built stage2 against the new `-O0` libraries.
4. Deployed and ran on pmacg5 (Tiger):
   - Test modules still produced 152-byte empty `.o` files.  No
     improvement.
5. Reverted hsLibrary to `-O -fllvm`.

### Day 2 (2026-04-30)

1. Re-tested stage2 on Tiger with various `-d…` flag combinations.
   Discovered the **non-determinism**: the same binary produces
   different observable bindings depending on which `-ddump-…`
   flags are present.  Same MD5 binary on uranium and Tiger
   (`e4c13ce4f668742be7e7e7c98dc93afc`).
2. Probed the layers:
   - `-ddump-parsed`: always shows both `five` and `six`
     (parser is fine).
   - `-ddump-rn`: sometimes both, sometimes one, sometimes none —
     depending on what other dump flags are enabled.
   - `-ddump-tc`: typically only one binding visible.
   - The `.o` output also varies.
3. Wrote three probe programs that exercise the same primitives
   the renamer/UniqSupply use, cross-built them with stage1, and
   ran on Tiger:
   - `BagTest.hs` — `mapBagM` over `TwoBags`: WORKS.
   - `AtomTest.hs` — `fetchAddWordAddr#` direct atomic counter:
     WORKS.
   - `USup.hs` — full `mkSplitUniqSupply` pattern with
     `unsafeDupableInterleaveIO` + `noDuplicate#` + recursive
     splitting: WORKS, returns 20 sequential uniques.
4. Conclusion: the primitives behave correctly when stage1 emits
   user code; the bug only manifests inside ghc-the-binary.
5. Started the no-LLVM experiment.  Edited
   `hadrian/src/Settings/Flavours/QuickCross.hs`:
   ```diff
   -    , hsLibrary  = notStage0 ? mconcat [ arg "-O", arg "-fllvm" ]
   -    , hsCompiler = stage0 ? arg "-O2"
   -    , hsGhc      = mconcat
   -                   [ stage0 ? arg "-O"
   -                   , stage1 ? mconcat [ arg "-O0", arg "-fllvm" ] ] }
   +    , hsLibrary  = notStage0 ? arg "-O"
   +    , hsCompiler = stage0 ? arg "-O2"
   +    , hsGhc      = mconcat
   +                   [ stage0 ? arg "-O"
   +                   , stage1 ? arg "-O0" ] }
   ```
6. Wiped `_build/hadrian/.shake.database`; started the rebuild
   (in flight at the time of writing).

## Why the no-LLVM experiment

If the rebuilt stage2 compiles M5.hs correctly, the bug is in
the LLVM-7 PPC backend's handling of ghc's specific code shapes
(probably the heavy `IO`-monad continuation chains in
`TcM`/`RnM`).  That's an LLVM-7 sister-project issue.

If the rebuilt stage2 still drops bindings, the bug is in
something common to both LLVM and C codegen — most likely a
specific Haskell-level pattern in ghc that compiles wrong on PPC
unreg in either backend.  We then need to keep narrowing.

## What's documented

- [`stage2-non-determinism-finding.md`](stage2-non-determinism-finding.md):
  reproducer table, per-input panic catalogue, what's been ruled
  out, and remaining hypothesis tree.

## Files touched

- `hadrian/src/Settings/Flavours/QuickCross.hs` (active: no-llvm).
- Test programs at `/tmp/{BagTest,AtomTest,USup,M5,Sig1,Two,Three,One,NoSig,BigMod,Hello}.hs`
  and Tiger mirror under `pmacg5:/tmp/`.
- Build script `/tmp/build-stage2.sh` (cross-compile + deploy).
- Build log `/tmp/hadrian-noLLVM.log` (in-progress).
