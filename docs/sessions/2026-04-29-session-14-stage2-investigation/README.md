# Session 14 — Stage2 native ghc investigation

**Date:** 2026-04-29.  Started after v0.8.1 shipped.
**Goal:** unblock roadmap B — stage2 native `ghc` running on Tiger
that can compile fresh Haskell source.
**Outcome:** **fault narrowed to a specific code pattern**, but not
yet fixed.  Documented here for the next session to pick up.

## Where exp 006 left it

128 MB ppc-native `ghc` runs `--version` on Tiger.  Compile attempts
panic in `StgToCmm.Env`:

```
ghc: panic! (the 'impossible' happened)
  GHC.StgToCmm.Env: variable not found
  $trModule3_rwD
```

Workaround: `-dno-typeable-binds` was claimed to make non-main
modules compile.  Hypothesis: typechecker / IORef state.

## Where session 14 leaves it

Reproduced freshly against current stage1 (which has 14 patches now,
many landed since exp 006).  Two new findings:

### 1. Stage2 silently emits 152-byte empty `.o` files

`-c` on a non-main module:

```
$ stage2 ghc -O0 -c M3.hs   # M3 = "addOne x = x + 1"
$ ls -la M3.o
-rw-r--r--   1 macuser  wheel  152 ...
$ /usr/bin/nm M3.o
/usr/bin/nm: no name list      ← no symbols at all
```

For comparison, stage1 cross-compiles the same module to a 1944-byte
`.o` with proper symbols (`_M3_addOne_closure`, `_M3_addOne_entry`,
`_M3_addOne_info`, `_M3_zdtrModule_closure`, etc.).

Stage2's "compile success" is misleading — it produces a Mach-O file
containing only the header and an empty `__TEXT,__text` section.

### 2. The simple optimizer is dropping all top-level terms

`-v` shows the smoking gun:

```
*** Desugar [M3]:
Result size of Desugar (before optimization)
  = {terms: 6, types: 1, coercions: 0, joins: 0/0}
Result size of Desugar (after optimization)
  = {terms: 0, types: 0, coercions: 0, joins: 0/0}    ← all 6 terms gone
*** Simplifier [M3]:
Result size of Simplifier
  = {terms: 0, types: 0, coercions: 0, joins: 0/0}
*** CoreTidy [M3]:
…
*** CodeGen [M3]: …                ← runs on empty program → empty .o
```

The "after optimization" pass is `simpleOptPgm` in
`compiler/GHC/Core/SimpleOpt.hs:160`, which is structured as:

```haskell
(final_env, binds') = foldl' do_one (emptyEnv opts, []) occ_anald_binds

do_one (env, binds') bind
  = case simple_opt_bind env bind TopLevel of
      (env', Nothing)    -> (env', binds')
      (env', Just bind') -> (env', bind':binds')
```

A `foldl'` accumulating `(env, [bind])`.  On stage2 native, this
fold's accumulator is collapsing — the final `binds'` list is `[]`.

Verified by adding `-ddump-rn -ddump-tc -ddump-ds`:

| Module             | Parser sees | Renamer sees | Typechecker sees | Desugar (final) | Tidy Core |
|--------------------|-------------|--------------|------------------|-----------------|-----------|
| `M4: five = (5::Int)` (sig+def) | full | sig + def | only `$trModule` | ditto | ditto |
| `M5: five = ...; six = ...` (no sigs) | full | both defs | both defs + `$trModule` | only `six` | only `six` |
| `M3: addOne x = x+1` (sig+def) | full | partial | only `$trModule` | only `$trModule3_rwD` | only `$trModule` |

The typechecker is fine; the bug is in the desugarer or simple
optimizer.  All 6 terms enter; 0 exit.

### 3. Same root cause likely produces the original panic

When using `--make` mode + a main module, GHC tries harder to keep
references alive (because `:Main.main` synthesis points at
`Main.main`).  The simple optimizer then keeps SOME terms but loses
their dependencies, leaving `$trModule3_rwD` referenced but undefined
in StgToCmm's env.  Hence the panic.

So both symptoms (silent empty `.o` and the StgToCmm panic) trace back
to the same bug: **PPC32 stage1's compiled `simpleOptPgm` mis-handles
its `foldl' do_one` accumulator.**

## Hypotheses for the root cause

1. **Tuple-return ABI bug on PPC32.**  `do_one` returns
   `(SimpleOptEnv, [OutBind])`.  If stage1's PPC32 codegen mis-emits
   the second tuple slot, the list collapses to `[]` (or single
   element).
2. **Strictness analysis miscompile.**  `foldl'` requires strict
   accumulator evaluation.  If our stage1 build emitted weakened
   strictness for tuple components, the list may be discarded
   instead of forced.
3. **Subtle Bag/Map/Set fold issue.**  Less likely (basic `Data.Map`
   round-trips work on Tiger via cross-compile, see
   `/tmp/maptest.hs` in the session log) but possible if the GHC-
   library version of these structures has a different code path.

## What we ruled out

- **Data.Map / IORef / cons:** a simple cross-compiled program that
  builds a `Map` via `foldr` + `M.insert` and via repeated
  `modifyIORef` works correctly on Tiger.
- **`-dno-typeable-binds` doesn't help:** in exp 006's notes this was
  claimed as a "bypass" that compiles non-main modules.  It does
  produce a 152-byte `.o` but that `.o` is empty in both cases.
  The bypass was illusory.

## Next session checklist

1. **Reproduce in isolation.**  Cross-compile a small Haskell
   program from uranium that does `foldl' (\(e, bs) b -> (e+1,
   b:bs)) (0, []) [1..5]` and run it on Tiger.  If the result is
   `(5, [5,4,3,2,1])`, the simple case works — narrows to GHC-library
   complexity.  If the result is `(_, [5])` or `(_, [])`, we have a
   minimal repro.

2. **Try `-O0` on the GHC compiler library build.**  Rebuild stage1
   with `-O0` for `compiler/GHC/Core/SimpleOpt.hs` (and
   neighbours).  If stage2-built-from-O0-stage1 works, we know it's
   an optimizer pass.  Bisect by re-enabling individual optimizations.

3. **gdb on Tiger.**  Set a breakpoint inside `simpleOptPgm`
   (would need to symbolize the binary, may be tricky).  Inspect
   `binds'` after each fold step.

4. **Compare `.o` size of `compiler/GHC/Core/SimpleOpt.o` between
   our build and a known-good upstream PPC build (8.6.5 or earlier).**
   Significant size delta might point at codegen anomaly.

## Tests added this session

- `tests/stage2-native/` — `NoMain.hs`, `Hello.hs`, `run.sh`.
  Drives the stage2 ghc through compile + link + run cycle on
  pmacg5.  Will be the regression suite for stage2 once it works.

## What ships in v0.8.2

This session contributed no user-facing fix.  But:

- LLVM-7 bug report for the profiling clang asm issue.
- Vendored `network-3.x` (v0.8.1, separate release).
- Detailed write-up of stage2 investigation (this doc).

The stage2 work itself is **deferred** — it's a multi-session
project requiring deep PPC32 codegen / runtime debug.  The
cross-compile path remains the recommended way to build Haskell
for Tiger.
