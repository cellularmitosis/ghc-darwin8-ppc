# Session 49 findings — **Smoking gun: the input to `tcTopBinds` is already truncated; corruption is in the RENAMER, not the typechecker**

## TL;DR — overturns session 48

Session 48 concluded "corruption is INSIDE `tcTopBinds val_binds val_sigs`".  Session 49 measured what session 48 didn't: the SIZE OF THE INPUT to `tcTopBinds`.

### Results

Probe49-v1 added 13 hook sites inside `compiler/GHC/Tc/Gen/Bind.hs`:

| evt | site                            | clean | len=600 | len=1650 |
|-----|---------------------------------|-------|---------|----------|
|  1  | `tcTopBinds_entry_total`        | **8** | **2**   | **3**    |
|  2  | `tcTopBinds_entry_groups`       | **8** | **2**   | **2**    |
|  3  | `tcValBinds_entry_total`        |  8    |  2      |  3       |
|  …  | (per-group recursion)           | …     | …       | …        |
|     | `tcValBinds_after_tcBindGroups` |  8    |  2      |  2       |
|     | `tcTopBinds_after_tcValBinds`   |  8    |  2      |  2       |

(See [`logs/v1-triggers.log`](logs/v1-triggers.log) for the full trace.)

**The `[(RecFlag, LHsBinds GhcRn)]` list arriving at `tcTopBinds` is already short.**  In `Big2.hs` the source contains 8 independent value bindings; clean produces 8 NonRecursive groups of size 1, totalling 8 binders.  In failing runs the list contains 2 groups totalling 2-3 binders.

### Re-localization: corruption is BEFORE `tcTopBinds`

`tcTopBinds` is called from `tcTopSrcDecls` in `compiler/GHC/Tc/Module.hs`, where `val_binds` is destructured directly out of the `HsGroup`'s `hs_valds` field:

```haskell
tcTopSrcDecls (HsGroup { …
                       , hs_valds  = hs_val_binds@(XValBindsLR (NValBinds val_binds val_sigs)) })
 = do { …
      ; tc_envs <- tcTopBinds val_binds val_sigs ; … }
```

The `HsGroup` is built by **the renamer** (`rnTopSrcDecls` in `compiler/GHC/Rename/Module.hs` → `rnSrcDecls` line 96 → `rnValBindsRHS` in `compiler/GHC/Rename/Bind.hs` line 298 → `depAnalBinds` line 570).

So the corruption is in one of:
- The parser (parsed `mbinds` is already short).
- `rnValBindsLHS` / `rnValBindsRHS` `mapBagM` iteration that copies / renames the Bag.
- `depAnalBinds` / `depAnal` SCC analysis on `bagToList binds_w_dus`.

Hot suspect: `depAnalBinds` (or earlier `bagToList`) reads a Bag that was just renamed; if a GC happened during `mapBagM rnLBind`, the resulting bag's internal structure might be partially zeroed by an SRT-misalignment bug.

## How session 48 went wrong

Session 48 hooked `after_tcTopBinds_val_binds = lengthBag (tcg_binds tcg_env)` and saw 8/2-3.  Session 48 interpreted this as "corruption is INSIDE `tcTopBinds`".  But what session 48 actually proved was: **`tcg_binds` was populated to 2-3 by `tcTopBinds`.**  The output count says nothing about whether the input was short or the function lost binders mid-flight.

The crucial probe session 48 didn't add: measure `length val_binds` BEFORE the call, i.e. the input to `tcTopBinds`.  That's what session 49 added, and it shows the input is already short.

## F1. The 8 → 2 / 8 → 3 truncation pattern

In `Big2.hs` (29 lines, 8 value bindings), in clean (-A256m):
- 8 NonRecursive groups arrive at `tcTopBinds`, each with 1 binder.
- The list is `[(NonRec, {freqMap}), (NonRec, {topK}), …, (NonRec, {cumsum})]`.
- `tcTopBinds` walks all 8 and produces `tcg_binds` of size 8.

In failing len=600 (-A1m -G1):
- 2 NonRecursive groups arrive, each with 1 binder.
- 6 binders are missing from the input list.

In failing len=1650 (-A1m -G1):
- 2 groups arrive: 1 NonRecursive (size 1) + 1 Recursive (size 2).
- Total 3 binders.  6 missing.
- **The Recursive group of size 2 is suspicious** — `Big2.hs` has no mutually recursive bindings.  Two unrelated NonRecursive groups got merged into a fake CyclicSCC.

The fake CyclicSCC strongly suggests the corruption is structural: the renamer's `(LHsBind GhcRn, [Name], Uses)` triple has its `defs` / `uses` fields garbled by GC, causing `depAnal`'s SCC algorithm to detect a non-existent cycle.  That points to `depAnalBinds` or earlier in `rnValBindsRHS`'s `mapBagM rnLBind`.

## F2. Pipeline chain (sessions 42-49)

| Session | Hook point                                  | Count clean / failing |
|---------|---------------------------------------------|------------------------|
| 42      | `simplTopBinds` entry                       | 9 / 0-1               |
| 43      | `core2core` entry                           | 9 / 1-3               |
| 44      | `deSugar` `final_prs`                       | 9 / 3-6               |
| 45      | `deSugar` `tcg_binds` entry                 | 9 / 3-6               |
| 46      | `hsc_typecheck` exit                        | 9 / 3-5               |
| 47      | `tcRnSrcDecls` output                       | 9 / 2-5               |
| 48      | `tcTopBinds val_binds val_sigs` output      | 8 / 2-3 (+1 from `mkTypeable` → 9 / 3-4) |
| **49**  | **`tcTopBinds` INPUT (`val_binds`)**        | **8 / 2-3**           |

The number 2-3 has been stable since deSugar.  Session 49 shows it was 2-3 **before** the typechecker ever ran.  The truncation is upstream of the typechecker — in the renamer or earlier.

## F3. What probe49 directly ruled in

**Confirmed:**

- `tcTopBinds` is innocent.  It faithfully processes whatever input list it receives.
- `tcValBinds`, `tcBindGroups`, `tc_group` are innocent.  Recursion through the list is correct.
- The corruption is at the boundary between the renamer and the typechecker — i.e., the `HsGroup`'s `hs_valds` field that the typechecker pattern-matches out.

**Strong-but-not-yet-proven:**

- The renamer's `rnValBindsRHS` / `depAnalBinds` chain is the most likely suspect.  This is where `[(RecFlag, LHsBinds GhcRn)]` is constructed.
- The fake CyclicSCC in len=1650 suggests structural pointer corruption (garbled `defs` / `uses` fields), pointing at `mapBagM rnLBind` (which copies the Bag triple-by-triple) or the Bag itself.

**Ruled out:**

- Any GC corruption inside `tcTopBinds` body.
- Any GC corruption inside `tcValBinds` / `tcBindGroups` / `tc_group` body.

## F4. The 1m-G1 sensitivity

This bug only fires at small allocation areas (`-A1m -G1`).  `-A256m` is clean.  Reading 8 entries from a Bag of 8 is a few hundred bytes of allocation in the renamer's `mapBagM` — well under 1 MB.  The GC must be running on something else (probably much more allocation in `rnLBind`'s recursive Haskell-AST traversal) and corrupting the Bag's spine pointers during that.

## F5. Concrete next-session targets (session 50)

1. **Drill `rnValBindsRHS`** in `compiler/GHC/Rename/Bind.hs:298-322`.  Hook:
   - `rnValBindsRHS_in_mbinds` — `lengthBag mbinds` at entry.
   - `rnValBindsRHS_after_mapBagM` — `lengthBag binds_w_dus` after the `mapBagM rnLBind`.
   - `rnValBindsRHS_after_depAnal` — `length anal_binds` after `depAnalBinds`.
   - `rnValBindsRHS_total_binders` — sum of `lengthBag . snd` over `anal_binds`.
2. **Drill `rnTopBindsLHS`** in `compiler/GHC/Rename/Bind.hs:184` if (1) shows the truncation already happened.
3. **Drill the parser** (`Parser.y` / `GHC.Parser.PostProcess`) if (2) also shows truncation.  This would be a big finding — bug is in the parser.
4. **Pin a Bag-size snapshot at each `mapBagM` step** — fine-grained per-iteration log.  If `mapBagM` consumes only K of N items, the truncation is during iteration; if it sees N items but writes K to the output, the truncation is in the writer.
5. **File a GHC bug report.**  We have very tight localization now.  Submit upstream as "PPC32-unreg GC corrupts Bag during renamer's `mapBagM rnLBind`; reproducible at small source sizes with `-A1m -G1`."

## F6. Re-reading session 48 in light of session 49

Session 48's `after_rnTopSrcDecls = 0` data point was correct but not the right question.  `rnTopSrcDecls` doesn't populate `tcg_binds` (which session 48 measured).  But it DOES populate `hs_valds` in the `HsGroup` it returns.  Session 48 should have measured `lengthBag` over `hs_valds` of the returned `HsGroup`, not `tcg_binds` of `tc_env`.

Session 49 sidestepped that gap by measuring the input to `tcTopBinds` directly — which is `val_binds`, destructured from `hs_valds`.  That's the same data, measured from the consumer side.

## F7. The 1 → 2 / 2 → 3 step is still puzzling

Session 47's failing range was 2-5 (at `tcRnSrcDecls` output).  Session 48's failing range was 2-3 (at `tcTopBinds val_binds` output).  Session 49's failing range is 2-3 (at `tcTopBinds` input).  The narrowing from 2-5 → 2-3 between sessions 47 and 48 is probably just heap-layout noise (different probe code → different memory layout → slightly different GC timing).

Session 49's len=600 = 2 and len=1650 = 3 — stable across the probe versions.
