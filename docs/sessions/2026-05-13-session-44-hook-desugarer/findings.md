# Session 44 findings — desugarer's output is ALREADY truncated; simpleOptPgm further drops binders

## TL;DR

Probe44 hooks `HsToCore.deSugar` just before it returns
ModGuts.  Logs three lengths:

1. **`final_prs`** — the desugarer's main output BEFORE
   `simpleOptPgm` runs.
2. **`ds_binds`** — output AFTER `simpleOptPgm`.
3. **`mg_binds`** — the final field value stored in
   `ModGuts.mg_binds` (typically equals `ds_binds`).

### Results

| env-len | final_prs | ds_binds | mg_binds | RC | outcome |
|---------|-----------|----------|----------|----|----|
| clean -A256m | 9     | 9        | 9        | 0  | proper compile |
| 600     | **3**     | **0**    | **0**    | 0  | silent miscompile |
| 1650    | 5         | 3        | 3        | 1  | refineFromInScope panic |
| 850     | 6         | 4        | 4        | 1  | refineFromInScope panic |

Three findings:

1. **`final_prs` is already truncated in failing runs** —
   3-6 binders vs clean's 9.  The desugarer's main output
   is corrupted before `simpleOptPgm` even runs.  So the
   truncation is **WITHIN OR BEFORE the desugarer's main
   computation**.
2. **`simpleOptPgm` further drops binders.**  At len=600,
   3 → 0 (drops all 3).  At len=1650, 5 → 3.  At len=850,
   6 → 4.  This is plausibly legitimate dead-code-elimination
   responding to the already-broken `final_prs`.
3. **`mg_binds == ds_binds`** — they're the same value.
   No corruption between simpleOptPgm and ModGuts
   construction.

## F1. Probe44 design

In `compiler/GHC/HsToCore.hs`, near the bottom of `deSugar`'s
main do-block, add a `let !_probe44 = probe44LogDeSugarReturn
(length final_prs) (length ds_binds) (length (mg_binds mod_guts))`
just before `return (msgs, Just mod_guts)`.

Helper `probe44LogDeSugarReturn :: Int -> Int -> Int -> ()`
defined inline in HsToCore.hs (couldn't import from
`Simplify.Env` due to potential circular dependency).

First build attempt failed: placed `import` lines AFTER
function definitions, which is illegal in Haskell.  Fixed by
moving imports up with the existing import block.

## F2. The truncation is IN THE DESUGARER'S MAIN PRODUCTION

`final_prs` is constructed by:

```haskell
final_prs = addExportFlagsAndRules bcknd export_set keep_alive
                                   rules_for_locals (fromOL all_prs)
```

where `all_prs` came from the `initDs` block:

```haskell
do { ds_ev_binds <- dsEvBinds ev_binds
   ; core_prs <- dsTopLHsBinds binds_cvr
   ; core_prs <- patchMagicDefns core_prs
   ; (spec_prs, spec_rules) <- dsImpSpecs imp_specs
   ; (ds_fords, foreign_prs) <- dsForeigns fords
   ; ds_rules <- mapMaybeM dsRule rules
   ; ...
   ; return ( ds_ev_binds
            , foreign_prs `appOL` core_prs `appOL` spec_prs
            , ...) }
```

So `all_prs = foreign_prs ++ core_prs ++ spec_prs` (concatenated
via OrdList's `appOL`).  In Big2.hs, `foreign_prs` and
`spec_prs` are likely small/empty; the main contribution is
`core_prs` from `dsTopLHsBinds binds_cvr`.

`binds_cvr` is the typechecker's `tcg_binds` after
coverage-instrumentation (`addTicksToBinds`).

If `final_prs` is 3-6 in failing runs vs 9 in clean, the
truncation is in:

- (a) `tcg_binds` (typechecker's output).
- (b) `addTicksToBinds` (coverage pass).
- (c) `dsTopLHsBinds` (the main desugaring function).
- (d) `patchMagicDefns`, `dsImpSpecs`, `dsForeigns`, `dsRule`
  (the smaller-output desugaring helpers).
- (e) The `appOL` calls (OrdList concatenation).
- (f) `fromOL` (converting OrdList to list).
- (g) `addExportFlagsAndRules`.
- (h) **GC corrupting any of the heap-allocated lists/OrdLists
  in this chain.**

## F3. The `simpleOptPgm` drop pattern

`simpleOptPgm` is GHC's "simple optimization" pass that runs at
the very end of desugaring.  Its job:

> -- The simpleOptPgm gets rid of type
> -- bindings plus any stupid dead code

In our data:

| env-len | final_prs → ds_binds | drop count |
|---------|---------------------|------------|
| clean   | 9 → 9               | 0          |
| 600     | 3 → 0               | 3          |
| 1650    | 5 → 3               | 2          |
| 850     | 6 → 4               | 2          |

In a clean compile, simpleOptPgm preserves all 9 binders (no
dead code).  In failing runs, it drops 2-3 — plausibly because
with the rest of the program missing from final_prs, the
surviving binders look unreferenced.  This is **legitimate
DCE responding to already-broken input**.

Confirms the session 43 hypothesis that simplifier's 2→0 drop
at len=1650 was also DCE on broken input, not a second bug.

## F4. The silent miscompile at len=600 explained

At len=600: `final_prs=3 → ds_binds=0 → mg_binds=0`.
ghc-real then runs the optimizer pipeline (probe43 confirmed
core2core sees 0 binders), produces zero binders to codegen,
and emits an empty .o file with RC=0.

The simplifier's "did nothing" output goes into codegen as
"nothing to compile" → empty .o file → RC=0 success report.

The user sees an apparently-successful compile and an empty
.o file.  Silent miscompile confirmed at the desugarer level.

## F5. -A1G baseline (not needed)

Already know from session 43 that -A1G produces 9 at every
stage.  No need to re-test.

## F6. Concrete next-session targets

1. **Hook earlier in deSugar.**  Add log lines BETWEEN the
   stages:
   - `length tcg_binds` (typechecker output, before
     addTicksToBinds).
   - `length binds_cvr` (after addTicksToBinds).
   - `length core_prs` (after dsTopLHsBinds).
   - `length all_prs` (after concatOL).
   - `length final_prs` (after addExportFlagsAndRules).
   This tells us EXACTLY which step truncates the list.

2. **If truncation is in tcg_binds, hook even earlier — the
   typechecker's output construction.**

3. **If truncation is in dsTopLHsBinds — inspect its
   implementation.**  Look for any `take`, `filter`, or
   list-processing that might be GC-corrupted.

4. **Pin tcg_binds in IORef.**  Walk its length periodically
   to see if GC shrinks it across compilation.

5. **File a GHC bug report** — at this point we have
   conclusive evidence of GC corruption affecting heap-
   allocated lists on PPC32 unreg.  A minimal repro would
   help upstream maintainers.

## F7. Refined picture

Sessions 28-44 collectively show:

1. The bug is **GC corrupting heap-allocated [LHsBinds GhcTc]
   or [(Id, CoreExpr)] lists** on PPC32 unreg.
2. The corruption happens **during the desugarer**, somewhere
   between the typechecker's output and ModGuts construction.
3. **`final_prs` is already 3-6 in failing runs (vs 9 clean)**
   — the desugarer's main output is already corrupted.
4. **`simpleOptPgm` then DCE's further** because its input
   is already broken.
5. **`core2core` receives the truncated mg_binds** and the
   simplifier processes 0-6 binders instead of 9.
6. Result: refineFromInScope panics OR silent miscompiles
   (empty .o files).

The user-facing workaround `+RTS -A1G -RTS` remains the only
known mitigation until the GC bug is fixed.

## F8. What probe44 directly ruled in

**Confirmed:**

- `final_prs` (desugarer's pre-simpleOptPgm output) is
  truncated in failing runs (3-6 binders vs clean's 9).
- `simpleOptPgm` further drops binders (e.g., 3 → 0 at
  len=600).  Plausibly legitimate DCE on broken input.
- `mg_binds == ds_binds` — no additional corruption between
  simpleOptPgm and ModGuts construction.

**Refined hypothesis:**

- The truncation is in the desugarer's `initDs` block
  (between `dsTopLHsBinds` and `final_prs`'s construction),
  or in the typechecker's output (`tcg_binds`), or via GC
  corrupting one of the heap-allocated lists used in those
  stages.

## F9. Big picture from sessions 28-44

The "X is corrupted" hypotheses from earlier sessions are all
downstream symptoms of:

**GC corrupts heap-allocated cons-list spines on PPC32 unreg
under nursery pressure.**

The cons-list is heap-allocated `CONSTR_2_0` closures.  GC's
evac/scav on PPC32 unreg appears to corrupt the `tail` pointer
in some cases, truncating the list to 0-6 elements where the
clean compile has 9.

The corruption manifests at varying degrees depending on
heap-layout (env-len + RTS flags), producing:
- Panics (when truncated list has 1-3 binders → references
  to missing binders fail at refineFromInScope).
- Silent miscompiles (when truncated list has 0 binders →
  empty .o file produced with RC=0).
- TC-time errors (when other UniqMap-backed structures get
  corrupted — `swap not in scope` family).

Workaround: `+RTS -A1G` consistently produces 9 binders.

Real fix requires upstream GHC RTS work on PPC32 unreg
evac/scav.
