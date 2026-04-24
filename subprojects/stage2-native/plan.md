# stage2-native — plan

## Goal

A ppc-native `ghc` binary that runs on Tiger and can compile Haskell
source natively — i.e. "self-hosting Haskell on Tiger" without needing
the uranium cross-build for every compile.

## Current state (deferred)

128 MB Mach-O `ppc_7400` binary, lives at `/tmp/ghc-stage2-ppc` (also
installed on pmacg5 at `/tmp/ghc-tiger-install/bin/ghc`).  `ghc --version`
runs fine and prints the standard banner.

But:
- `ghc -c foo.hs` on a typechecked-only module panics with
  `StgToCmm.Env: variable not found $trModule3_rwD` — Typeable binding
  lookup fails at codegen.  Bypass with `-dno-typeable-binds`.
- `ghc -c Main.hs` (any module with `main`) fails earlier:
  `GHC internal error: 'main' is not in scope during type checking` —
  `tcLookupId` finds an empty `tcl_env` for the main Name.
- `ghc --make Main.hs` gets further but produces a near-empty `.o`
  missing `_Main_main_closure`, so executable link fails on
  `_ZCMain_main_closure`.

Both symptoms look like "runtime state machinery in the `ghc` library
isn't wired up properly" — `HscEnv`, `DynFlags` IORefs, etc.  See
[docs/experiments/006-stage2-native-ghc.md](../../docs/experiments/006-stage2-native-ghc.md)
for full analysis.

## Why it's deferred

Not a user-facing blocker — the stage1 cross-build from uranium
produces fully working ppc binaries (see
[stage1-cross](../stage1-cross/)).  Tiger users can run compiled
Haskell today; they just can't compile Haskell *on* Tiger with our
current build.

Debugging would need either:
- gdb on pmacg5 with a ppc-native Haskell runtime trace, to see where
  `$trModule3_rwD` drops out of the environment.  Expensive to set up.
- A known-good reference stage2 ghc for ppc-darwin8, but that would
  only exist if someone restored the port upstream — chicken and egg.
- Bisecting the PPC-removal patch set in GHC git history to see if any
  of those changes broke the Typeable code path on 32-bit BE before
  the removal landed.

Any of these is a week of dedicated work.

## If we resume

Possible next steps, in order of likelihood to produce insight:

1. **Compare Stage1 and Stage2 `.hi` for a shared module.**  They
   should be identical — stage2 libs are compiled by the stage1 cross
   compiler.  Any divergence points at a codegen bug.

2. **Try a minimal "typechecker-only" test.**  `ghc-bin -M` (dep
   discovery) or `ghc-bin --print-global-package-db` — see if these
   fail with the same empty-env issue or if it's specific to code gen.

3. **Look at what `hs_main` does** in libHSrts when launching a
   Haskell program compiled for a 32-bit BE target.  The miniinterpreter
   setup might have a bug that corrupts `IORef`-like state.

4. **Check `GHC.IORef` (`newIORef` / `readIORef`)** for PPC32 ABI
   issues — maybe atomics on 32-bit BE are mis-emitted.  Given our
   earlier `_hs_xchg64` patch, it wouldn't be out of character.

## Dependencies

Nothing blocks starting this — the stage2 binary exists and is ready
to be poked with gdb on pmacg5.
