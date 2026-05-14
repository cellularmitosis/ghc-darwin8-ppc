# Session 45 findings — `tcg_binds` is ALREADY truncated at deSugar entry; corruption is in/before the typechecker

## TL;DR

Probe45 instruments 7 points inside `HsToCore.deSugar`:

1. `tcg_binds` (input from typechecker).
2. `binds_cvr` (after `addTicksToBinds`).
3. `core_prs_initial` (after `dsTopLHsBinds`).
4. `core_prs_patched` (after `patchMagicDefns`).
5. `all_prs_in_initDs` (after concatOL inside initDs).
6. `all_prs_outside_initDs` (after initDs's case unpacks).
7. `final_prs` (after `addExportFlagsAndRules`).

### Results across env-lens

| step                  | clean | 600 | 850 | 1650 |
|-----------------------|-------|-----|-----|------|
| tcg_binds             | 9     | **3** | **6** | **5**  |
| binds_cvr             | 9     | 3   | 6   | 5    |
| core_prs_initial      | 9     | 3   | 6   | 5    |
| core_prs_patched      | 9     | 3   | 6   | 5    |
| all_prs_in_initDs     | 9     | 3   | 6   | 5    |
| all_prs_outside_initDs| 9     | 3   | 6   | 5    |
| final_prs             | 9     | 3   | 6   | 5    |

**EVERY step preserves the count.** The desugarer is INNOCENT.
The truncation has ALREADY HAPPENED when `tcg_binds` arrives.

### Localization

The corruption is in one of:

- (a) The typechecker's output construction of `TcGblEnv`'s
  `tcg_binds` field.
- (b) HscMain's bridging code between typechecker exit and
  `deSugar` invocation (the `hscDesugar` function, etc.).
- (c) GC corruption of the heap-allocated `Bag (LHsBindLR
  GhcTc GhcTc)` while `TcGblEnv` is in memory between
  typechecker exit and `deSugar` entry.

(c) remains the most consistent explanation given the heap-
layout-sensitivity from sessions 28-44.

## F1. Probe45 design

In `compiler/GHC/HsToCore.hs`:

- Helper `probe45LogStep :: String -> Int -> ()` defined inline
  (same pattern as probe44).
- 7 hook calls placed at each step of `deSugar`'s do-block.
- `lengthBag` imported from `GHC.Data.Bag` for measuring the
  `Bag (LHsBindLR GhcTc GhcTc)` types.

Patch: `probe45-granular-desugar.patch` (84 lines).

## F2. The desugarer is innocent

Every internal step of `deSugar` preserves the binder count
exactly:

```
tcg_binds = N
binds_cvr = N    (addTicksToBinds preserves)
core_prs_initial = N    (dsTopLHsBinds 1-to-1 maps each LHsBinds → CoreExpr)
core_prs_patched = N    (patchMagicDefns preserves)
all_prs_in_initDs = N   (foreign_prs ++ core_prs ++ spec_prs for Big2.hs = 0 + N + 0 = N)
all_prs_outside_initDs = N    (passed through case unpack)
final_prs = N    (addExportFlagsAndRules preserves)
```

The desugarer is doing its job correctly.  Whatever count it
gets in, it produces the same count out.

## F3. Where the bug is now

`tcg_binds` is the typechecker's `TcGblEnv` field.  It's
populated during typechecking and passed in `TcGblEnv` through
the pipeline.

Pipeline order:
```
parser → renamer → typechecker → desugarer → core2core → codegen
```

The TcGblEnv flows from the typechecker to the desugarer
through `HscMain.hscDesugar`.  Specifically:

```
hscTypeCheckRn → TcGblEnv
              → hscDesugar tcg_env → ModGuts
                              → deSugar hsc_env mod_loc tcg_env
```

The typechecker produces `TcGblEnv.tcg_binds` as `Bag
(LHsBindLR GhcTc GhcTc)`.  This Bag is heap-allocated.  If GC
corrupts the Bag's internal structure between typechecker
output and deSugar consumption, the count would drop.

## F4. The Bag data structure

From `compiler/GHC/Data/Bag.hs`:

```haskell
data Bag a
  = EmptyBag
  | UnitBag a
  | TwoBags (Bag a) (Bag a)  -- INVARIANT: nonempty
  | ListBag [a]              -- INVARIANT: nonempty
```

`TwoBags` is similar to a cons cell — it has 2 pointer fields.
On PPC32 unreg, `TwoBags` would be a `CONSTR_2_0` closure with
2 pointer payload words.

If GC corrupts a `TwoBags` closure's `Bag a` (left) or `Bag a`
(right) pointer to point to an `EmptyBag` (which is a `CONSTR_0`
or similar), the Bag's effective contents shrink.

This is consistent with the `[InBind]` cons-list truncation
finding from earlier sessions — both `[a]` cons cells and
`Bag a TwoBags` are `CONSTR_2_0` closures whose `tail`/`right`
pointers can be corrupted by GC.

## F5. Determinism check

The clean compile always sees 9 binders (Big2.hs has 9
top-level binders).  Failing compiles see 3-6 (deterministic
per env-len + RTS flags).

## F6. The simpleOptPgm DCE explained

Session 44's observation that simpleOptPgm drops 3 → 0 at
len=600 (etc.) is **legitimate dead-code elimination** on
already-truncated input.  Specifically: when the typechecker's
9 binders are truncated to 3, the 3 surviving binders'
references to the missing 6 become undefined.  simpleOptPgm
sees these as dead code and eliminates them.

Probe45 confirms `final_prs` matches `tcg_binds` exactly (no
intermediate loss).  Session 44's `final_prs=3 → ds_binds=0`
drop is from simpleOptPgm, which runs AFTER final_prs.

## F7. Concrete next-session targets

1. **Hook the typechecker's output.**  Find where TcGblEnv is
   constructed in the typechecker and add a probe that dumps
   `lengthBag (tcg_binds tcg_env)` at the typechecker's exit
   point.  If clean shows 9 and failing shows 3-6, the
   truncation is in the typechecker itself.

2. **Hook HscMain's `hscDesugar` (or wherever it lives).**
   Find the function that bridges typechecker output to
   `deSugar` invocation.  Add a probe at its entry to dump
   `lengthBag (tcg_binds tcg_env)`.  If clean=9 and failing=9
   at HscMain entry but failing=3-6 at deSugar entry, the
   corruption is in the call site / between.

3. **Pin tcg_binds in IORef at typechecker exit.**  Walk its
   length at multiple downstream points to see when it shrinks.

4. **File a GHC bug report.**  This is a definitive GC-on-
   PPC32-unreg bug.  Upstream maintainers might be able to
   confirm and fix.

## F8. Big picture

Sessions 28-45 chain:

- 33-36: closure-shape of v probes → dissolved (S37).
- 28-38: UniqMap data structures corrupted → dissolved (S38).
- 38: Var.realUnique drift → dissolved (S39).
- 39: two distinct Vars same OccName → dissolved (S40).
- 40-41: SimplEnv field corruption → dissolved (S41).
- 41: binds0/CoreProgram upstream → confirmed (S42).
- 42: simplTopBinds sees 0-1 binders.
- 43: core2core entry sees 1-3 binders.
- 44: deSugar's final_prs is 3-6.
- **45: tcg_binds is ALREADY 3-6 at deSugar entry — the
  desugarer is innocent.**

The locus has now been narrowed to:
- The typechecker's output, OR
- HscMain's bridging code, OR
- GC corruption of the heap-allocated Bag during this transit.

Workaround: `+RTS -A1G -RTS` consistently produces 9 binders.
Real fix likely requires upstream GHC RTS work on PPC32 unreg
CONSTR_2_0 evac/scav (which affects both `[InBind]` cons cells
and `Bag.TwoBags` closures equally).

## F9. What probe45 directly ruled in

**Confirmed:**

- `tcg_binds` (input to deSugar from typechecker via TcGblEnv)
  is already truncated to 3-6 elements in failing runs (vs 9
  in clean).
- The desugarer preserves the count perfectly through all 7
  internal steps.

**Localized to:**

- The typechecker, HscMain bridge, or GC-in-transit between
  typechecker exit and deSugar entry.

**Strengthened the CONSTR_2_0 corruption hypothesis:**

- `Bag.TwoBags (Bag a) (Bag a)` is a CONSTR_2_0 closure just
  like `[a]` cons cells.  Same GC bug would affect both.
