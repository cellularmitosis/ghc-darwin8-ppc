# Stage2 — non-determinism finding (2026-04-30)

**Headline:** Stage2 native ghc on Tiger silently drops user
top-level bindings.  The drop happens during/before the renamer.
The visible behaviour is **non-deterministic across flag
combinations** on the same binary, suggesting a memory-corruption /
thunk-eval bug rather than a "passes drop bindings" miscompile.

The earlier session-14 hypothesis (stage1 miscompiles `simpleOptPgm`)
turns out to be wrong — that pointed at the wrong layer.  -O0
libraries did not fix anything.

## Reproducer (`M5.hs`)

```haskell
module M5 where
five = (5::Int)
six = (6::Int)
```

Same binary on uranium and Tiger
(MD5 e4c13ce4f668742be7e7e7c98dc93afc).

| flags                              | renamer dump        | typechecker dump     | .o symbols           |
|------------------------------------|---------------------|----------------------|----------------------|
| `-c`                               | (n/a)               | (n/a)                | empty                |
| `-c -ddump-rn`                     | both bindings       | (n/a)                | empty                |
| `-c -ddump-rn -ddump-tc`           | only `six`          | only `six`           | only `six`           |
| `-c -ddump-tc`                     | (n/a)               | only `five`          | only `five`          |
| `-c -O0 -ddump-rn`                 | only `six`          | (n/a)                | only `six`           |
| `-c -fforce-recomp -ddump-rn`      | (none in dump)      | (n/a)                | varies               |

**The rendered renamer output changes when you add `-ddump-tc`.**
Same binary, same input, same shell.  This is the smoking gun for
memory corruption.

For comparison, **stage1 cross-built `.o` of the same `M5.hs`** has
both bindings: renamer dump shows both, typechecker dump shows both,
the `.o` has both `M5_five_closure` and `M5_six_closure`.

## Other inputs and the panics they trigger

- 1 binding without sig (`x = 1::Int`):
  ```
  ghc: panic! GHC.StgToCmm.Env: variable not found
    $trModule4_r75
    local binds for: $trModule1_r6W $trModule2_r73
  ```
- 1 binding with sig (`x :: Int; x = 1`): silently produces empty
  152-byte `.o` (no panic, but no `_x_closure` either).
- 2 bindings without sigs (M5):
  ```
  ghc: panic! refineFromInScope
    InScope {wild_00 six}
    six_a6E
  ```
- 2 bindings with sigs (Sig1):
  ```
  ghc: panic! depSortStgBinds Found cyclic SCC:
    [($trModule2 = TrNameS! [$trModule1], {$trModule1}),
     ($trModule1 = "main"#, {})]
  ```
- 3 bindings: similar StgToCmm `variable not found` panic.

The common thread: late-stage compilation passes look up things
**by Unique** in maps, and the lookups fail because the same
"display name" is mapped to different Uniques in different places.

## What this rules out

- **Simplifier / `simpleOptPgm`.**  Loss happens before the desugarer.
  -O0 libraries didn't help.
- **HPC `addTicksToBinds`.**  Runs in the desugarer; loss visible
  in the renamer dump (which runs first).  `-fno-hpc` doesn't fix
  larger inputs.
- **Determinism**: same input + same binary + different `-d…` flag
  combinations give different observable bindings.  This is not a
  pass-level miscompile.
- **Bag traversal in user code**: a 30-line program that builds
  `TwoBags (UnitBag a) (UnitBag b)`, traverses with `mapBagM`, and
  prints, runs perfectly when stage1-cross-built and run on Tiger.
- **`fetchAddWordAddr#` / atomic counter** in user code: works fine.
- **`unsafeDupableInterleaveIO`-driven recursive UniqSupply pattern**
  in user code: works fine, returns 20 sequential uniques.

## What this points at

Every primitive used by `mkSplitUniqSupply` works correctly when
exercised from user code.  The bug only manifests inside ghc-the-
binary.  That isolates one of:

1. **LLVM-7 PPC backend miscompile** of ghc-specific code shapes
   (large, tight monadic loops; `forM`/`mapM` over data structures
   crossing module boundaries; `unsafePerformIO`-backed shared
   state in `FastString`/`UniqSupply`).
2. **Specific code patterns in ghc** (e.g. `TcM`'s deep
   `ReaderT`-stack `>>=`) that trip a subtle codegen bug.
3. **Cross-compile artifact**: stage1's output for stage2 differs
   from stage1's output for ordinary user code (e.g. SCC profiling
   tags interfering with optimisation when compiled with `-O`).

(1) is the leading hypothesis.  Test in progress: rebuild stage1
**without `-fllvm`** (using the unreg-C path through gcc14).  If
the resulting stage2 ghc compiles M5.hs correctly, the bug is in
LLVM-7's PPC backend.

## Empirical artefact

Run output stored as task `bte42irr3.output`:

```
=== run 1 ===
==================== Typechecker ====================
M5.$trModule
  = GHC.Types.Module
      (GHC.Types.TrNameS "main"#) (GHC.Types.TrNameS "M5"#)
five = (5 :: Int)
=== run 2 ===
…same… (5 runs, all show only `five`)
```

## Next experimental steps

1. **No-LLVM rebuild** (in flight): stage1 with `hsLibrary = -O`
   only and `hsGhc = -O0` only — drop `-fllvm` from both.  Compare
   stage2 behaviour.
2. **C-output inspection**: `-keep-tmp-files` on the stage1
   cross-build of one ghc internal module, look at the `.hc`/`.s`
   for codegen anomalies.  Easier with C-only path than with LLVM.
3. **gdb on Tiger** inside `addl`/`add_bind`/`mapBagM`, watch the
   bag structure as bindings get appended/traversed.

The "fast win" is (1) — if the rebuilt stage2 works, we have a
crisp bug report for the LLVM-7 sister project.
