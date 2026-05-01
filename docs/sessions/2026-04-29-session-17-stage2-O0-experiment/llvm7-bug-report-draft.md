# DRAFT — LLVM-7 BUG-004 (or whatever the next number is)

**Status:** draft, do not file yet.  Awaiting confirmation from the
no-LLVM hadrian rebuild that the bug actually disappears in the
unreg-C path.  If it does, this becomes the bug report.

## One-line summary

LLVM-7 PPC backend miscompiles GHC-9.2.8's stage2 native ghc binary
such that user top-level bindings are silently dropped during the
renamer/typechecker pipeline.  The visible symptom is
flag-combination-dependent: the same binary on the same input
produces different observable bindings depending on which
`-ddump-…` flags are enabled.

## How to reproduce

1. Use the `ghc-darwin8-ppc` project's stage1 cross-compiler
   (this repo's `_build/stage1/bin/powerpc-apple-darwin8-ghc`),
   built with `--flavour=quick-cross` and `-fllvm`.
2. Cross-build stage2 ghc-bin (see `/tmp/build-stage2.sh` in
   session 17 for the recipe).
3. Deploy to a Tiger PPC host with the matching libraries.
4. On Tiger:
   ```sh
   cat > M5.hs <<'EOF'
   module M5 where
   five = (5::Int)
   six = (6::Int)
   EOF
   /opt/ghc-stage2/bin/ghc -ddump-rn          -c M5.hs # both bindings
   /opt/ghc-stage2/bin/ghc -ddump-rn -ddump-tc -c M5.hs # only one binding
   /opt/ghc-stage2/bin/ghc                    -c M5.hs # empty .o, no error
   ```

## What we ruled out at the user-code level

Cross-compiled with this same stage1, all of these probes run
**correctly** on the same Tiger host:

- `mapBagM` over a `TwoBags (UnitBag x) (UnitBag y)`.
- `fetchAddWordAddr#` as an atomic counter — 10 sequential
  uniques.
- `mkSplitUniqSupply` pattern (the actual code from
  `compiler/GHC/Types/Unique/Supply.hs`) using
  `unsafeDupableInterleaveIO`, `noDuplicate#`, and recursive
  splitting — 20 sequential masked uniques.

So the LLVM-7 PPC backend can compile these primitives correctly
in isolation.  The bug only shows when the same primitives are
exercised inside a much larger module graph (ghc itself).

## Working hypothesis (for the LLVM-7 sister project to confirm)

A specific Cmm-level pattern in ghc's compiler library — likely a
deep nested `case` chain inside the `IO`-monad continuation
(produced by the typechecker / renamer's `TcM`/`RnM` stack) —
gets miscompiled by LLVM-7's PPC backend.  The miscompile looks
like memory corruption (data structures change shape between
forces).

## What we need from the LLVM-7 project

Either:

- A reduced Cmm or LLVM-IR test case extracted from one of the
  panicking ghc internal modules (e.g. one of `compiler/GHC/Tc/`)
  that miscompiles in isolation.  Tooling: `ghc -keep-tmp-files
  -fllvm-only -dverbose-core2core` on the failing module
  + a diff against the C-codegen output for the same module.
- Or a confirmation that the bug is in LLVM-7's PPC backend and
  not in ghc, with a fix in the LLVM-7 r4+ release.

## Workaround

Until fixed, ghc-darwin8-ppc ships with `-fllvm` removed from
`hsLibrary` and `hsGhc` in
`hadrian/src/Settings/Flavours/QuickCross.hs`.  The unreg-C
codegen path through gcc14 produces a working stage2.

## Cross-references

- ghc-darwin8-ppc session 17 docs:
  `docs/sessions/2026-04-29-session-17-stage2-O0-experiment/`
- Reproducer table & panic catalogue:
  `stage2-non-determinism-finding.md`
- Probe programs (all PASS):
  `probes/`
- Test modules:
  `test-modules/`
