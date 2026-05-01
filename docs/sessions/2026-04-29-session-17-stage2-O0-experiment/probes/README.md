# Stage2-bug probe programs

Small Haskell programs that exercise the same primitives ghc's
renamer / `UniqSupply` / `Bag` use.  All four cross-build with
stage1 and run correctly on Tiger — none of them reproduce the
stage2 binding-loss symptom.

This is the negative result.  Together they rule out user-code-
level miscompiles of:

- **`BagTest.hs`** — the `Bag` ADT with `mapBagM` over a `TwoBags`
  with two `UnitBag` children, plus `snocBag` / `unionBags` to
  build up.
- **`AtomTest.hs`** — `fetchAddWordAddr#` as an atomic counter,
  10 sequential increments.
- **`UPIO.hs`** — a CAF backed by `unsafePerformIO + IORef`
  (verifies the basic `unsafePerformIO` pattern; CAF is correctly
  memoised, returning `0` ten times — that's the expected,
  *correct* behaviour for code as written, the test just confirms
  no crashes).
- **`UniqTest.hs`** — IORef-based unique supply, threaded through
  a monadic Bag traversal, returning a list of (name, unique)
  pairs.
- **`USup.hs`** — the actual `mkSplitUniqSupply` pattern from
  `compiler/GHC/Types/Unique/Supply.hs`: an `IO`-action using
  `unsafeDupableInterleaveIO`, `noDuplicate#`, and a foreign atomic
  counter, recursively splitting itself.  `take 20 . uniqsFromSupply`
  returns 20 sequential masked uniques.  This is the most direct
  reproduction of GHC's own pattern that we could write at the user
  level, and it works.

## How to run

```sh
source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh
GHC1=$(realpath ../../../../external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc)
$GHC1 BagTest.hs   -o /tmp/BagTest   -outputdir /tmp/bagtest-build
scp /tmp/BagTest pmacg5:/tmp/
ssh pmacg5 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /tmp/BagTest'
```

(Same recipe for the others — pick the right outputdir.)
