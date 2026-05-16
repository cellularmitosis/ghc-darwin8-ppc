# state.md — where are we right now

*Updated: 2026-05-15 session 55 (**GHCi REPL works on PPC/Tiger** — v0.14.0).  No new patches.  All the load-bearing pieces (runtime Mach-O loader, BCO byte-swap, `__eprintf` stub) have been in place since v0.8.0 / session 12f (TemplateHaskell); the last gating dep was stage2 native ghc compiling without `-A1G`, which v0.13.0's `STUArray Bool` fix unblocked.  Build change is one-line-ish: `scripts/deploy-stage2.sh` now compiles `ghc/Main.hs` with `-DHAVE_INTERNAL_INTERPRETER` (the cabal `internal-interpreter` flag's effective contents — also pulls in `-i$GHC_SRC/ghc -package exceptions -package time` for the GHCi.UI/Leak/Util modules and the new deps).  Verified end-to-end on pmacg5: `ghc -e "sum [1..100]"` → `5050`, `ghc -e "Data.List.sort [3,1,4,1,5,9,2,6]"` → `[1,1,2,3,4,5,6,9]`, `ghc --interactive` accepts `:t`, `:load`, multi-line `:{ :}` blocks, imports of `Data.Char` / `Data.Map.Strict`, let-bindings + lambdas, recursion (`factorial 20`, `fib 12`).  Stage2 ghc-real binary grew ~5 MB (193 → 199 MB) for the additional GHCi.UI / GHCi.Leak / haskeline-driven REPL machinery.  Roadmap §C closes ✅ "REPL done".  **STATE CLEAN** — stage2 redeployed to pmacg5, ghci smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged — baseline is cross-compile, doesn't touch stage2).  Demo: [`demos/v0.14.0-ghci-repl.sh`](../demos/v0.14.0-ghci-repl.sh).*

_(Prior summary, session 54:)_ Upstream prior-art discovery — the `STUArray Bool` bug was already fixed upstream in May 2023, commit [`9cc80b5`](https://gitlab.haskell.org/ghc/packages/array/-/commit/9cc80b51cf98c13a140b00effb38329e7210d03c) "Round up unboxed Bool arrays to whole-word sizes" by Matthew Craven, motivated by [ghc#23132](https://gitlab.haskell.org/ghc/ghc/-/issues/23132).  Shipped in `array-0.5.6.0`+.  Upstream's fix modifies `bOOL_SCALE` itself; ours adds `bOOL_WORD_SCALE` and updates call sites — functionally identical.  GHC 9.2.8 ships `array-0.5.4.0` (predates the fix), so patch 0016 is the equivalent backport into our tree.  Session 53's "live upstream issue" framing was wrong: the `MArray (STUArray s) Bool (ST s)` instance code in upstream HEAD IS byte-identical to ours, but `bOOL_SCALE` itself (which the instance calls) was the part that was changed upstream.  Roadmap §H closes ✅ as "already fixed upstream".  Our project still adds the silent-miscompile-on-BE narrative on top of upstream's "spurious -fcheck-prim-bounds alarms" framing.  **STATE CLEAN** — no GHC source changes this session; patch 0016 commentary cross-references the upstream fix; baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.13.0 release unchanged.*

_(Prior summary, session 52:)_ The 32-session-old "stage2 emits empty `.o`" bug is **FIXED**.  An 11-line patch to `libraries/array/Data/Array/Base.hs` repairs `STUArray Bool`'s `newArray`: the buggy code allocated and zeroed `bOOL_SCALE n = ceil(n/8)` bytes via `setByteArray#` but `unsafeRead`/`unsafeWrite` access via `readWordArray#` / `writeWordArray#` (a full machine word).  For sub-word sizes the trailing partial-word bytes were uninitialised by `newByteArray#`; on big-endian, the bit for element 0 lives in memory byte 3 (LSB) but `setByteArray#` writes byte 0 (MSB), so every read of an `STUArray Bool` of size < SIZEOF_HSWORD*8 returned garbage.  `Data.Graph.scc` uses `STUArray Int Bool` for its "visited" set; a corrupt visited set drops vertices, the renamer drops bindings, the stage2 compiler emits empty `.o` files.  Fix: `bOOL_WORD_SCALE` (rounds nbytes up to a whole machine word) used in place of `bOOL_SCALE` in Bool's `newArray` and `unsafeNewArray_`.  Validation: `confirm_test` pre-fix 1998/2000 bad → 0/2000 bad post-fix; Big2.hs `-c` 152-byte empty .o → 46340-byte real .o under both default RTS and `-A1m -G1`; baseline 30 PASS / 4 FAIL_OUTPUT unchanged.  Patch: `patches/0016-array-stuarray-bool-word-aligned-init.patch`.  This was originally framed as an upstream GHC bug with identical code in current GHC HEAD; session 54 discovered the fix was already upstream as of May 2023.  Session-53 cuts release v0.13.0 with the fix.  **STATE CLEAN** — patch applied, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).*

_(Prior summary, session 51:)_ Stage2 GC bug round 33, **CLEAN exit**.  **TRUE MINIMAL REPRO found.**  Session 51 took session 50's `Data.Graph.scc` finding and stripped it across five iterations down to a 3-line standalone test that has nothing to do with the GHC compiler.  **The bug:** `newArray False :: ST s (STUArray s Int Bool)` produces a freshly-allocated MutableByteArray whose contents have spurious True bits under moderate GC pressure on PPC32 unreg.  Default RTS: 8431/10001 iterations (84%) corrupted.  -A1m -G1: 8655/10001 (87%) corrupted.  Host uranium (arm64): 0/10001 — confirms PPC32-unreg-specific.  Five test iterations: (1) `scc_test.hs` — single-pass scc, did NOT reproduce; (2) `scc_test2.hs` — interleaved burnGC, 1000-iter loop, REPRODUCED at 19-97% bad rate; (3) `scc_test3.hs` — size sweep, found sizes 6-24 + 48 BAD, others OK, size-sensitive non-monotonic pattern; (4) `scc_test4.hs` — inlined scc with probes, found `chop` reads vertex 3 as already-visited on first iteration (the STUArray's data is corrupt); (5) `stuarray_test.hs` — stripped everything except `newArray + readArray`, still 84% bad.  Sample bad outputs include `[False,False,False,False,True,False,False,True]` and `[True,False,True,False,True,True,True,True]` — random-looking garbage consistent with uninitialized memory.  The bug is in GHC's RTS byte-array allocation/zeroing on PPC32 unreg, not in any compiler code.  This single bug explains every probe finding from sessions 42-50: session 50's `scc` returns wrong forests because `chop`'s `STUArray Bool` is corrupt; session 49's `tcTopBinds` input is short because `depAnal` produced too few SCCs; session 42's "empty .o" symptom traces all the way back to STUArray corruption.  Pipeline progress chain S42-S51: simplTopBinds=0-1 → core2core=1-3 → deSugar final_prs=3-6 → deSugar tcg_binds=3-6 → hsc_typecheck_exit=3-5 → tcRnSrcDecls=2-5 → tcTopBinds OUTPUT=2-3 → tcTopBinds INPUT=2-3 → `stronglyConnCompG.scc` forest_len=0-3 → **`newArray False :: STUArray Bool` corrupted at allocation time**.  Thirteen sessions of bisection now resolved.  Next session (52) should test other unboxed types (Int8, Word8, Int, Word, Char) to map the scope, test pinned arrays, test without GC pressure (no burnGC), then read RTS source for `stg_newByteArrayzh` on PPC32 unreg.  **STATE CLEAN** — no GHC source modifications this session, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (matches session-49/50 noise floor).  v0.12.0 release unchanged.*

_(Prior summary, session 50:)_ **Locus pinned to `Data.Graph.scc` in the Haskell base library.**  Probe50 ran four iterations (17 hook sites total) across `compiler/GHC/Rename/Bind.hs`, `compiler/GHC/Types/Name/Env.hs`, and `compiler/GHC/Data/Graph/Directed.hs`, drilling the corruption locus successively from the renamer down to a specific function in `Data.Graph`.  **Findings:** v1 (6 hooks in Bind.hs) — `rnValBindsRHS_after_mapBagM=8`, `_after_depAnal_groups=3` → narrows to `depAnalBinds`.  v2 (3 hooks in `depAnalBinds`) — `bagToList`-produced list_len=8, but `sccs_len=3` → narrows to `depAnal`.  v3 (4 hooks in `depAnal` in Name/Env.hs) — graph_nodes=8 but `scc_result=3` → narrows to `stronglyConnCompFromEdgedVerticesUniq`.  v4 (4 hooks in Directed.hs) — `graphFromEdgedVertices_numbered_nodes=8` but **`stronglyConnCompG_forest_len=3`** → pins it to `forest = scc (gr_int_graph graph)`.  **`Data.Graph.scc` from the Haskell base library is the bug.**  Dramatic data point: `scc` returns 0 trees from a 1-vertex graph with no edges (the nested `where swap` binding in Big2.hs).  Consistent with session 42's CONSTR_2_0 GC corruption — `Tree Vertex = Node Vertex [Tree Vertex]` is CONSTR_2_0, and `[Tree Vertex]` cons cells are too.  Pipeline progress chain S42-S50: simplTopBinds=0-1, core2core entry=1-3, deSugar final_prs=3-6, deSugar tcg_binds entry=3-6, hsc_typecheck_exit=3-5, tcRnSrcDecls output=2-5, tcTopBinds OUTPUT=2-3, tcTopBinds INPUT=2-3, **`stronglyConnCompG` forest_len=0-3 (clean: 1, 8) — `Data.Graph.scc` IS the bug**.  Twelve sessions of pipeline-bisection, each ruling out a phase; now narrowed to a single function in the Haskell base library.  Next session (51) should isolate `Data.Graph.scc` in a standalone Haskell program (load a known graph, call scc, print result, run on pmacg5 with -A1m -G1) to confirm a minimal repro independent of GHC's compiler internals; then drill `scc`'s internal DFS / transpose / SCC-derivation steps.  **STATE CLEAN** — probe reverted across all three files, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (matches session-49 noise floor).  v0.12.0 release unchanged.*

_(Prior summary, session 49:)_ **Session 49 OVERTURNS session 48 — corruption is BEFORE `tcTopBinds`, in the renamer.**  Probe49-v1 adds 13 hook sites inside `compiler/GHC/Tc/Gen/Bind.hs`'s `tcTopBinds`, `tcValBinds`, `tcBindGroups`, and `tc_group`.  The crucial new measurement is the INPUT to `tcTopBinds` (the `val_binds :: [(RecFlag, LHsBinds GhcRn)]` argument).  **Findings:** Clean compile (-A256m): `tcTopBinds_entry_groups`=8, `entry_total`=8 (matches `Big2.hs`'s 8 top-level value bindings).  Failing -A1m -G1 len=600: `entry_groups`=2, `entry_total`=2.  Failing len=1650: `entry_groups`=2, `entry_total`=3 — and one group is a fake Recursive of size 2 (`Big2.hs` has no mutually recursive bindings; `depAnal` detected a phantom cycle).  Per-group recursion through `tcBindGroups` / `tc_group` faithfully processes whatever input it gets.  **The list arriving at `tcTopBinds` is ALREADY truncated.**  Session 48's "inside `tcTopBinds`" claim was wrong — `tcTopBinds` is innocent.  The truncation is upstream, in the renamer that builds the `HsGroup`'s `hs_valds` field — most likely in `compiler/GHC/Rename/Bind.hs`'s `rnValBindsRHS` (line 298) → `mapBagM (rnLBind …) mbinds` (line 304) → `depAnalBinds` (line 570).  The fake CyclicSCC in len=1650 hints at structural pointer corruption of the `(LHsBind, [Name], Uses)` triples that `depAnal` consumes.  Pipeline progress chain S42-S49: simplTopBinds=0-1, core2core entry=1-3, deSugar final_prs=3-6, deSugar tcg_binds entry=3-6, hsc_typecheck_exit=3-5, tcRnSrcDecls output=2-5, tcTopBinds val_binds output=2-3, **tcTopBinds INPUT=2-3 (8 clean)** — locus pushed upstream of the typechecker entirely.  Next session (50) should drill `rnValBindsRHS`: hook `lengthBag mbinds` at entry, `lengthBag binds_w_dus` after `mapBagM rnLBind`, `length anal_binds` after `depAnalBinds`.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (matches session-48 noise floor).  v0.12.0 release unchanged.*

_(Prior summary, session 48:)_ Probe48-v3 hooks 10 points across `compiler/GHC/Tc/Module.hs::tcRnSrcDecls` / `tc_rn_src_decls` / `tcTopSrcDecls`: `after_rnTopSrcDecls`, `after_tcTyClsInstDecls`, `after_tcTopBinds_val_binds`, `after_tcTopBinds_deriv_binds`, `after_tcTopSrcDecls`, `after_tc_rn_src_decls`, `after_mkTypeableBinds`, `after_zonkTcGblEnv_binds_prime`, `tcg_env_prime_final`, `binds_mf_after_zonk_main`.  **Corruption narrowed to INSIDE `tcTopBinds val_binds val_sigs`** *(SESSION 49 OVERTURNED THIS — see above; the corruption is actually upstream of `tcTopBinds`, in the renamer)*.  Probe48-v3 hooks all log `lengthBag (tcg_binds tc_env)`.  **Findings:** Clean compile (-A256m): 0/0/**8**/8/8/8/9/9/9/0.  Failing -A1m -G1 len=600: 0/0/**2**/2/2/2/3/3/3/0.  Failing len=1650: 0/0/**3**/3/3/3/4/4/4/0.  Both failing runs are silent miscompiles (RC=0).  `after_rnTopSrcDecls` and `after_tcTyClsInstDecls` are always 0 (renamer + class/instance handling don't populate `tcg_binds` for Big2.hs).  `after_tcTopBinds_val_binds` is where `tcg_binds` transitions from 0 to N — clean produces 8, failing produces 2-3.  All subsequent steps preserve the count (modulo +1 from `mkTypeableBinds`'s synthesized `$trModule`).  See [`docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/`](sessions/2026-05-14-session-48-drill-tcRnSrcDecls/).  Probe48-v3 hooks 10 points across `compiler/GHC/Tc/Module.hs::tcRnSrcDecls` / `tc_rn_src_decls` / `tcTopSrcDecls`: `after_rnTopSrcDecls`, `after_tcTyClsInstDecls`, `after_tcTopBinds_val_binds`, `after_tcTopBinds_deriv_binds`, `after_tcTopSrcDecls`, `after_tc_rn_src_decls`, `after_mkTypeableBinds`, `after_zonkTcGblEnv_binds_prime`, `tcg_env_prime_final`, `binds_mf_after_zonk_main`.  **Findings:** Clean compile (-A256m): 0/0/**8**/8/8/8/9/9/9/0.  Failing -A1m -G1 len=600: 0/0/**2**/2/2/2/3/3/3/0.  Failing len=1650: 0/0/**3**/3/3/3/4/4/4/0.  Both failing runs are silent miscompiles (RC=0).  `after_rnTopSrcDecls` and `after_tcTyClsInstDecls` are always 0 (renamer + class/instance handling don't populate tcg_binds for Big2.hs).  **`after_tcTopBinds_val_binds` is where tcg_binds transitions from 0 to N** — clean produces 8, failing produces 2-3.  All subsequent steps preserve the count (modulo +1 from `mkTypeableBinds`'s synthesized `$trModule`).  The truncation is INSIDE `tcTopBinds val_binds val_sigs` (in `compiler/GHC/Tc/Gen/Bind.hs`) — the function that typechecks top-level value bindings and extends `tcg_binds` in the recursive walk.  Pipeline progress chain S42-S48: simplTopBinds=0-1, core2core entry=1-3, deSugar final_prs=3-6, deSugar tcg_binds entry=3-6, hsc_typecheck_exit=3-5, tcRnSrcDecls output=2-5, **tcTopBinds val_binds output=2-3** (+1 from mkTypeable → 3-4).  Next session should drill inside `tcTopBinds`'s recursive walk (in `GHC.Tc.Gen.Bind`) and add per-binder logging to determine whether the input list is short or the bag is being lopped wholesale.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (same known-flaky as session 47).  v0.12.0 release unchanged.*

_(Prior summary, session 47:)_ Probe47 hooks 4 points inside `compiler/GHC/Tc/Module.hs::tcRnModuleTcRnM`: `after_tcRnImports`, `after_tcRnSrcDecls`, `after_checkHiBootIface`, `tcRnModuleTcRnM_exit`.  **Findings:** Clean compile (-A256m): 0 / 9 / 9 / 9.  Failing -A1m -G1 len=600: 0 / **5** / 5 / 5.  Failing len=1650: 0 / **2** / 2 / 2.  `after_tcRnImports` is always 0.  **`after_tcRnSrcDecls` is where tcg_binds transitions from 0 to N** — clean produces 9, failing produces 2-5.  All subsequent steps preserve the count.  The truncation happens WITHIN `tcRnSrcDecls`.  See [`docs/sessions/2026-05-13-session-47-tc-rnmodule/`](sessions/2026-05-13-session-47-tc-rnmodule/).

_(Prior summary, session 46:)_ Probe46 narrowed the truncation to AT or BEFORE the typechecker's return.  See `docs/sessions/2026-05-13-session-46-tc-and-bridge/`.  **Corruption locus narrowed to within the typechecker (or GC during typechecking).**  Probe46 hooks 3 points in `compiler/GHC/Driver/Main.hs`: `hsc_typecheck_exit` (just before `hsc_typecheck` returns `(tc_result, rn_info)`), `hscDesugar_entry`, `hscDesugarPrime_entry`.  All log `lengthBag (tcg_binds tc_env)`.  **Findings:** Clean compile (-A256m): hsc_typecheck_exit=9, hscDesugar'_entry=9.  Failing -A1m -G1 len=600: 3, 3.  Failing len=1650: 5, 5.  `hscDesugar_entry` never fires — Big2.hs uses `hscDesugar'` directly (probably via `hscIncrementalCompile`).  **The typechecker's output already has 3-5 binders in failing runs.**  The Driver.Main bridge between typechecker exit and desugarer call preserves the count exactly.  **The corruption is AT or BEFORE the typechecker's `return (tc_result, rn_info)`** — specifically within `tcRnModule'` (the renamer + typechecker driver), or via GC corrupting the heap-allocated `Bag (LHsBindLR GhcTc GhcTc)` during typechecking.  Pipeline progress chain S42-S46: simplTopBinds=0-1, core2core entry=1-3, deSugar final_prs=3-6, deSugar tcg_binds entry=3-6, hsc_typecheck_exit=3-5.  Hypothesis: GC on PPC32 unreg corrupts CONSTR_2_0 closures (`Bag.TwoBags` and `[a]` cons cells both have this layout: 2 pointer fields).  **New observation:** baseline test battery now flakes — different test fails compile each run (26_threaded_rts then 01_int_arith).  Sessions 37-45's baseline had stable 30 PASS / 4 FAIL_OUTPUT; now FAIL_COMPILE appears intermittently.  This is a downstream symptom of the same GC bug.  Next session should hook `tcRnModule` / `tcRnModule'` in `GHC/Tc/Module.hs` to narrow further within the typechecker.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests flaky (29-30 PASS / 1 FAIL_COMPILE / 3-4 FAIL_OUTPUT depending on run).  v0.12.0 release unchanged.*

_(Prior summary, session 45:)_ Probe45 ruled the desugarer innocent.  See `docs/sessions/2026-05-13-session-45-granular-desugar/`.  **Desugarer ruled INNOCENT.**  Probe45 adds 7 granular length hooks inside `HsToCore.deSugar`: tcg_binds (input), binds_cvr (after addTicksToBinds), core_prs_initial (after dsTopLHsBinds), core_prs_patched (after patchMagicDefns), all_prs_in_initDs, all_prs_outside_initDs, final_prs (after addExportFlagsAndRules).  **Findings:** Clean compile (-A256m): all 7 steps = 9.  Failing -A1m -G1 len=600: all 7 steps = 3.  Failing len=850: all 7 steps = 6.  Failing len=1650: all 7 steps = 5.  **EVERY step preserves the count exactly.**  The desugarer is INNOCENT — whatever count it gets in, it produces the same count out.  **The truncation has ALREADY HAPPENED when `tcg_binds` arrives at deSugar.**  Corruption is in: (a) the typechecker's output construction, (b) HscMain's bridging code (`hscDesugar`) between typechecker and deSugar, or (c) GC corruption of the heap-allocated `Bag (LHsBindLR GhcTc GhcTc)` during transit.  `Bag.TwoBags (Bag a) (Bag a)` is a CONSTR_2_0 closure (2 pointer fields) — structurally identical to `[a]` cons cells.  The same GC bug that corrupts cons-list spines would also corrupt TwoBags.  Next session should hook the typechecker's TcGblEnv construction and HscMain's hscDesugar bridge.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.12.0 release unchanged.*

_(Prior summary, session 44:)_ Probe44 narrowed the truncation to the desugarer level.  See `docs/sessions/2026-05-13-session-44-hook-desugarer/`.  **Corruption locus narrowed further: it's WITHIN or BEFORE the desugarer.**  Probe44 hooks `HsToCore.deSugar`'s return point and logs three list lengths: `final_prs` (desugarer's main output before `simpleOptPgm`), `ds_binds` (after `simpleOptPgm`), and `mg_binds` (the field stored in `ModGuts`).  **Findings:** Clean compile (-A256m): final_prs=9, ds_binds=9, mg_binds=9.  Failing -A1m -G1 len=600: **final_prs=3**, ds_binds=0, mg_binds=0 → silent miscompile (RC=0, empty .o).  Failing len=850: final_prs=6, ds_binds=4, mg_binds=4 → panic.  Failing len=1650: final_prs=5, ds_binds=3, mg_binds=3 → panic.  **`final_prs` is already truncated in failing runs.**  The corruption is WITHIN or BEFORE the desugarer's main `initDs` block (or in the typechecker's `tcg_binds` going in).  `simpleOptPgm` then further drops binders (plausibly legitimate DCE responding to already-broken input).  Truncation candidates within `deSugar`: `addTicksToBinds`, `dsTopLHsBinds`, `patchMagicDefns`, `dsImpSpecs`, `dsForeigns`, `dsRule`, OrdList ops (`appOL`/`fromOL`), or `addExportFlagsAndRules` — OR the input `tcg_binds` from the typechecker.  Most consistent with GC corrupting a heap-allocated `[LHsBinds]` or `OrdList (Id, CoreExpr)` cons-list spine.  Next session should hook MORE granularly inside `deSugar` (length at each stage) to pinpoint the exact truncation step.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.12.0 release unchanged.*

_(Prior summary, session 43:)_ Probe43 traced mg_binds through the Core pipeline, confirming the truncation happens BEFORE core2core entry.  See `docs/sessions/2026-05-13-session-43-trace-pipeline-binds/`.  **Corruption locus narrowed.**  Probe43 hooks `Pipeline.hs::core2core` entry, `runCorePasses` entry, and each Core pipeline pass (before/after lengths).  **Findings:** (1) Clean compile (`-A256m`): CORE2CORE=9, INITIAL=9, Simplifier 9→13.  (2) Failing `-A1m -G1` len=600: CORE2CORE=1, INITIAL=1, panic.  (3) Failing len=850: CORE2CORE=2, INITIAL=2, Simplifier 2→5, panic.  (4) Failing len=1650: CORE2CORE=2, INITIAL=2, **Simplifier 2→0 `*** DROPPED`, RC=0 (silent miscompile)**.  **Key localization:** CORE2CORE count equals INITIAL count in every run (no drop between core2core entry and runCorePasses entry).  **The `[InBind]` truncation happens BEFORE `core2core`'s entry** — in the desugarer's output, in HscMain's bridge code between desugarer and core2core, or via GC corrupting the heap-allocated `[InBind]` list while ModGuts sits in memory between phases.  **Silent miscompile band extends:** len=1650 is now a second silent-miscompile env-len (after session 42's 850-1000).  The simplifier's 2→0 drop at len=1650 is plausibly legitimate DCE responding to an already-broken input (most top-level binders missing → surviving 2 look unreferenced → eliminated as dead).  Next session should hook the desugarer's output (`HsToCore.deSugar`) to localize whether the truncation is IN the desugarer or in HscMain bridge code.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.12.0 release unchanged.*

_(Prior summary, session 42:)_ Probe42 instruments simplTopBinds entry and confirmed mg_binds is truncated to 0-1 binders in failing runs (vs 9 in clean), causing both refineFromInScope panics and silent miscompiles (152-byte empty .o files).  See `docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/`.  **Root cause located.**  Probe42 instruments `simplTopBinds`'s entry in `Simplify.hs` to log `(length binds0, length (bindersOfBinds binds0))`.  **Findings:** (1) Clean compile (`-A256m` or `-A1G`, no padding): first simplTopBinds call sees 9 binders (matching Big2.hs's ~10 top-level functions + dictionaries); call 2 sees 13.  (2) Failing `-A1m -G1` at len=600/1650/1700: simplTopBinds sees **1 binder** → refineFromInScope panic.  (3) Failing `-A1m -G1` at len=850/900/950/1000: simplTopBinds sees **0 binders** → ghc-real exits RC=0 producing a **152-byte empty .o file** (SILENT MISCOMPILE — no function definitions emitted, confirmed via `nm /tmp/Big2.o` returning empty output; clean .o is 46340 B with all 8 functions).  (4) `-A1G` (huge nursery → minimal GC) **always** sees 9 binders.  (5) Three repeats at len=600 produce identical numbers — deterministic given heap layout.  **Root cause:** **GC corrupts the `[InBind]` cons-list spine** flowing into `simplTopBinds`, truncating it to 0-1 elements.  The list is heap-allocated CONSTR_2_0 closures (cons cells with 2 pointer fields: head, tail); GC's evac/scav handling on PPC32 unreg appears to corrupt them under GC pressure.  **This finding subsumes every prior session's framing** — v's-closure-shape (S33-36), UniqMap-corruption (S28-38), Var.realUnique-drift (S38), two-distinct-Vars (S39), SimplEnv-field-corruption (S40-41) — all are downstream symptoms of the same root cause: GC truncates the [InBind] list, leaving the simplifier with 0-1 binders instead of 9.  **Severity update:** the bug is worse than previously thought — not just panics but also silent miscompiles producing empty .o files.  User-facing workaround: `+RTS -A1G -RTS` (or `-A256m` for moderate compiles).  Next session should track down WHICH GC pass corrupts CONSTR_2_0 closures — likely candidate is `rts/sm/Evac.c::copy_tag` on PPC32 unreg.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.12.0 release unchanged.*

_(Prior summary, session 41:)_ Probe41 partially disproved "GC corrupts SimplEnv heap closure" — pinned env's sizes stable but panic-site env was a different env entirely.  See `docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/`.  Probe41 (pin a SimplEnv reference in an IORef at every `simplRecBndrs` call, track its `seInScope`/`seIdSubst` sizes at every `substId`-failure) **partially disproves session 40's "GC corrupts SimplEnv heap closure" hypothesis**.  Two iterations: v1 (threshold size≥5 didn't fire in failing runs because the first simplRecBndrs call has scope=2); v2 (logs every call, pins LARGEST).  **Findings:** (1) Pinned env's sizes are STABLE — `pinned_was = pinned_now` at panic time.  GC does NOT corrupt the env probe41 tracks.  (2) The panic-site env is a DIFFERENT SimplEnv than the pinned one — pinned has scope=2 while the substId-failure has scope=5.  Multiple envs in flight.  (3) In a CLEAN compile (`-A256m`), the FIRST simplRecBndrs call has scope=10 (matching Big2.hs's ~10 top-level binders); in a FAILING compile (`-A1m -G1` len=600), the first call has scope=2.  **New hypothesis:** the simplifier's input `binds0 / CoreProgram` is corrupted UPSTREAM of `simplTopBinds` — by the typechecker, desugarer, specializer, or interface deserializer.  Next session should instrument `simplTopBinds`'s entry to dump `length (bindersOfBinds binds0)` and confirm.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.12.0 release unchanged.*

_(Prior summary, session 40:)_ Probe40 (extension of probe38) revealed seIdSubst is EMPTY at every refineFromInScope panic.  See `docs/sessions/2026-05-13-session-40-trace-duplicate-var/`.

_(Prior summary, session 39:)_ Probe39 disproved "GC corrupts Var.realUnique."  See `docs/sessions/2026-05-13-session-39-var-realunique-drift/`.

_(Prior summary, session 38:)_ Probe38 refuted "UniqFM IntMap data structure corruption" — PROBE38-ADDLOST never fires, PROBE38-SHRINK never fires.  Probe40 (extends probe38's panic-site dump to also report `seIdSubst`'s size and keys at every `substId env v` call where v's in-scope lookup fails — the path that fires `refineFromInScope`) reveals: **`seIdSubst` is EMPTY at every refineFromInScope panic**.  The env at the panic site has only `init_in_scope = {wild_00}` plus the binders for the current function being descended into (no top-level binders, no substitutions).  This is the shape of a freshly-created SimplEnv (`mkSimplEnv mode` output) plus a tiny descent — but `mkSimplEnv` is called only once per simplifier iteration per `Pipeline.hs:734`, and its output flows into `simplTopBinds` which populates `seInScope` with all top-level binders via `simplRecBndrs`.  The panic-site env doesn't match that expected post-simplRecBndrs shape.  **New hypothesis:** GC corrupts the SimplEnv heap closure's `seInScope :: !InScopeSet` and `seIdSubst :: SimplIdSubst` fields, resetting them to fresh-env defaults somewhere during the simplifier's descent.  Consistent with sessions 28-29's heap-layout-sensitive triggering and with probe38's PROBE38-SHRINK never firing (PROBE38-SHRINK only catches Haskell-level set replacements via `setInScope*` functions; a GC pointer rewrite of the SimplEnv data structure bypasses those).  **Side discovery 1:** session 38's claim of `-A16m` clean compile was an artifact of `head -8` truncating the panic body; the real clean-compile threshold for Big2.hs + dump flags on PPC stage2 is `-A256m` (or `-A1G`).  **Side discovery 2:** With `-dsuppress-uniques`, PPC stage2's `-A256m` Core dump and uranium host's `-A1m -G1` Core dump are byte-identical — the pipeline producing the simplifier's input is correct on PPC; the bug is dynamic (env corruption at descent time).  Next session should pin a SimplEnv reference in an IORef and periodically check its seInScope/seIdSubst sizes to directly observe the corruption.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.12.0 release unchanged.*

_(Prior summary, session 39:)_ Probe39 (sentinel-Var IORef tracker) disproved session 38's "GC corrupts Var.realUnique" hypothesis — when the sentinel registered, `varUnique v` returned the same Unique at registration AND at every subsequent refineFromInScope check.  See `docs/sessions/2026-05-13-session-39-var-realunique-drift/`.

_(Prior summary, session 38:)_ Probe38 (silent-on-happy-path InScopeSet instrumentation) refuted the "UniqFM corruption" framing — PROBE38-ADDLOST never fires, PROBE38-SHRINK never fires.  **Session 38's "GC corrupts the `realUnique :: FastInt#` field of Var heap closures" hypothesis is DISPROVEN.**  Probe39 (a sentinel-Var IORef tracker in `Simplify/Env.hs` that registers the first `$d*`-named Var seen in `subst_id_bndr`, stashes it in an IORef to keep it live across GC, and at every `refineFromInScope` re-reads its `varUnique v` via GHC's Haskell-level accessor) directly tests the hypothesis.  Three iterations: v1 (hardcoded filter, registered nothing — wrong target names), v2 (broadened filter to any `$d`-prefixed OccName, also hooked subst_id_bndr; at len=850 registered `$dOrd_a1k0(0x610013f7)` and showed `u_via_haskell = 0x610013f7` stable across 4 refineFromInScope checks — the raw word[2] peek differed because anyToAddr# returns a wrapping-thunk address, not the Id closure proper, resurfacing the session-37 lesson), v3 (dropped misleading raw-peek check, emits PROBE39-DRIFT only on Haskell-level drift).  **Result:** when the sentinel registers, `varUnique v` returns the same Unique at registration AND at every subsequent refineFromInScope check.  GC may relocate the Var closure but does NOT rewrite the realUnique field's value.  In failing runs (env-lens 650-725 and 1650-1700 with probe39-v3) the sentinel never registers because the panic precedes any `$d*` Var binding through `subst_id_bndr` — narrows down WHEN/WHERE the duplicate Var appears.  **Refined framing:** the bug is **two distinct Var heap closures existing with the same `OccName` "$dOrd_a1k0" but different Uniques** — neither drifts; they're genuinely two separate objects.  The duplicate is created upstream of the simplifier — likely in the typechecker, desugarer, specializer, or interface deserializer.  Next session should trace where the duplicate is constructed via probes at dictionary-emitting sites in HsToCore/Tc/Solver/Specialise/Iface.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.12.0 release unchanged.*

  **Major refinement to session 28's framing.**  Probe38 (silent-on-happy-path instrumentation of `Simplify/Env.hs`: panic-site full dump at `refineFromInScope`, post-insertion self-validation at `addNewInScopeIds`, shrink detection at all three `setInScope*` variants) was applied, built, deployed, and swept across env-lens 600..2000.  **Findings:** (1) `PROBE38-ADDLOST` never fires — `addNewInScopeIds`'s post-extension check (every var still `elemInScopeSet` of the new set) always passes.  (2) `PROBE38-SHRINK` never fires — none of `setInScopeSet`/`setInScopeFromE`/`setInScopeFromF` ever replaces the in-scope set with a smaller one.  (3) The InScopeSet at the panic site contains **coherent** Var entries.  (4) But the panic's missing var has the **same OccName** as an in-scope var with a **different raw Unique** — e.g. at env-lens 825..925, in-scope has `$dOrd(0x610013f7)` while the expression's `$dOrd` has raw Unique `0x61001418` (delta=33).  (5) The victim Var rotates with `-A` nursery size: -A1m → `$dOrd`, -A2m → `$dEq`, -A8m → `ds_d1lr` (a normal let-binding, not a dict), -A32m → `$dFoldable`.  Not dictionary-specific.  (6) **`-A16m` produces a clean compile of Big2.hs at len=850** — confirms GC-frequency-sensitive triggering.  **Refined framing:** the InScopeSet is innocent.  **The bug is GC corrupting the `realUnique :: FastInt#` field of Var heap closures on PPC32 unreg.**  When the simplifier inserts Var v into an InScopeSet, the IntMap key is `varUnique v` at insertion time.  Later, when the simplifier looks up the same v in the expression tree, `varUnique v` returns a different value (because GC rewrote v's realUnique field), so the Unique-keyed lookup misses.  The various UniqMap-backed "victim" structures (InScopeSet, depSortStgBinds adjacency list, TC GlobalRdrEnv) are all innocent — they correctly store and key by Unique.  Next session should design a probe that directly tracks a specific Var's realUnique across the pipeline via `anyToAddr#` + IORef.  **STATE CLEAN** — probe reverted, stage1 rebuilt, stage2 redeployed to pmacg5 + smoke-test PASS.  v0.12.0 release unchanged.*

## Headline

**GHC 9.2.8 builds and runs Haskell programs on PowerPC Mac OS X 10.4 Tiger.**
First time since commit 374e44704b removed PPC/Darwin support in Dec 2018.

Three programs verified on real Tiger hardware (pmacg5):
- `hello.hs`  — `putStrLn` → "hello from ppc darwin 8"
- `fib.hs`    — lazy infinite list + libgmp Integer → F(100) = 354224848179261915075
- `stdin.hs`  — getContents + Data.List.{sort,nub} → sorted unique words

Plus a 34-program test battery (see [`tests/RESULTS.md`](../tests/RESULTS.md))
— 30 PASS byte-identical to host output, 4 test-design diffs (Int
size differences between 32-bit PPC and 64-bit arm64, process-pid /
program-name differences).  **No real bugs.**

Plus **30+ Hackage packages** cross-compiled via `cabal-install` and
running on Tiger (random, splitmix, async, vector, aeson, optparse-applicative,
megaparsec, and their transitive deps — see
[`docs/cabal-cross.md`](cabal-cross.md)).

Each test binary is 8–12 MB statically-linked Mach-O PPC executable.

## Two flavors of "working"

### 1. Cross-compile toolchain (RECOMMENDED — fully working)

Runs on arm64 macOS (uranium), produces PPC binaries, final link shipped
via SSH to pmacg5.

- `external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc`
  (134 MB arm64 binary — the cross-compiler)
- 33 libraries registered in `_build/stage1/lib/package.conf.d/` as ppc
- Bindist tarball at
  `external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`
  (117 MB — includes `install.sh` at the root and `cross-scripts/runghc-tiger`).
  Released on GitHub as
  [v0.5.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.5.0).
  Install flow: `tar xJf <tarball> && cd ghc-9.2.8-powerpc-apple-darwin8 && ./install.sh --prefix=$PREFIX --ppc-host=<ssh-alias>`.
  After install, `$PREFIX/bin/runghc-tiger foo.hs [args]` compiles +
  scp's + ssh-runs the result on the configured Tiger box.

**Usage:**
```
source scripts/cross-env.sh
_build/stage1/bin/powerpc-apple-darwin8-ghc hello.hs -o hello-ppc
scp hello-ppc pmacg5:/tmp/ && ssh pmacg5 /tmp/hello-ppc
```

### 2. PPC-native `ghc` binary (FULLY WORKING) — v0.13.0

~210 MB Mach-O `ppc_7400` executable.  `ghc --version` prints the banner.
`ghc Hello.hs -o hello` produces a working PPC binary on Tiger.
`ghc -c Big2.hs` (using `Data.Map.Strict`, `Data.List`, top-level
recursion) compiles correctly under the default RTS — no `-A1G`
workaround needed.

The 32-session-old "stage2 emits 152-byte empty `.o` files" bug
was a single big-endian library bug in `STUArray Bool`'s `newArray`,
fixed in v0.13.0 by [patch 0016](../patches/0016-array-stuarray-bool-word-aligned-init.patch).
Was previously mistaken for a PPC-Darwin RTS GC bug; the actual
GC paths are fine.  See
[`docs/sessions/2026-05-15-session-52-stuarray-scope/`](sessions/2026-05-15-session-52-stuarray-scope/)
for the bisection and fix.  The wrapper (`scripts/ghc-stage2-wrapper.sh`)
still ships but no longer needs to add `-A1G`.  See
[`docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md`](sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)
for the original investigation (panic catalogue, threshold table,
why removing `-fllvm` and switching to unreg-C didn't fix it on its
own), and
[`docs/sessions/2026-05-09-session-19-stage2-gc-bug/`](sessions/2026-05-09-session-19-stage2-gc-bug/)
for round 1 of the root-cause investigation (sanity check passes,
SMP/atomic and CAF-list-truncation hypotheses ruled out) and
[`docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/`](sessions/2026-05-10-session-20-stage2-gc-bug-round2/)
for round 2 — proximate cause identified: ~184 stack-frame slots
have bitmaps that mark them as non-pointer but actually contain
real heap pointers, so GC skips them and they go stale.
Systematic across 6+ modules; root mechanism (why the bitmaps are
wrong on PPC32 cross-build) is the next session's question.
And [`docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/`](sessions/2026-05-10-session-21-stage2-bitmap-bug/)
for round 3 — bug narrowed by another layer: the bitmap-encoding
step (`mkLivenessBits`) is correct, the .o faithfully encodes
the StackRep that the Cmm IR specifies.  Pre-existing host/target
`BITMAP_BITS_SHIFT` mismatch theory disproved (both = 5 on PPC32).
Session 21 hypothesised the bug must therefore be in
`stackMapToLiveness` or earlier StackMap construction.
And [`docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/`](sessions/2026-05-10-session-22-stage2-bitmap-bug/)
for round 4 — that session-21 hypothesis does **not** survive
per-block audit.  All 15 `True`-containing StackReps in
cross-built Catch.hs have True-marked slots that are **never
read by the body** (only written/overwritten or
passed-through-then-popped).  The bitmap is the right answer.
Cross-host comparison: cross emits 8× more True-bit StackReps
than host on the same source, but the audited host frames have
the same dead-slot pattern — the difference is 32-bit codegen
layout, not misclassification.  Conclusion: the dominant 93/106
BAD pay=1 events PROBE21 attributed to 4 PNP/PN info tables in
Catch.hs are PROBE21 **false positives** (heap-shaped values
legitimately stranded in dead slots that GC correctly skips).
The actual GC crash is real but somewhere else: another
module's frames, a non-RET_SMALL frame type PROBE21 skipped,
the RTS scavenger itself, or CAF/SRT scanning.
And [`docs/sessions/2026-05-11-session-24-faststring-stackrep/`](sessions/2026-05-11-session-24-faststring-stackrep/)
for round 6 — **session 23's attribution was wrong**.  Cross-built
FastString.hs's `_blk_c7te` info-table's StackRep is `[False, True,
True]`, which is the **correct** bitmap for what the Cmm IR
specifies: slot Sp+12 holds the `Addr#` field of an unboxed
`Data.ByteString.Internal.Type.BS` constructor (the
`byteArrayContents#` of the underlying `ForeignPtrContents`), typed
`I32` (non-pointer) in Cmm.  LayoutStack faithfully encodes this;
`mkLivenessBits` faithfully encodes that.  The actual stale-Addr#
read-after-poison is upstream of LayoutStack — either an invariant
violation by some caller of `mkFastStringByteString` (the BS is
backed by a non-pinned `MutableByteArray#`, so the `Addr#` is stale
across the `stg_newByteArray#` GC point) or PROBE22POISON itself
false-positiveing on pinned-memory `Addr#`s in blocks whose
`bd_flags` happen to be `0x0` at the moment PROBE22 runs.
And [`docs/sessions/2026-05-11-session-25-pin-aware-poison/`](sessions/2026-05-11-session-25-pin-aware-poison/)
for round 7 — **PROBE23 (pin-aware poison) settled it.**  PROBE23 =
PROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the poison filter,
plus a no-poison `PROBE23PINNED` log of stack slots pointing into
`BF_PINNED` blocks.  Result on M5.hs `+RTS -A1m`: 5/5 SIGSEGV
byte-identical to session 23's PROBE22 (same crash slot
`gc_no=2 slot=6 old=0x0bf5f38a` at `_blk_c7te + 112`), AND
`pinned_skip = 0` across every GC of every iteration.  No stack
slot held a value pointing into a pinned block during M5.hs's
compile.  Rules out the strong form of the b-hypothesis "PROBE22
was wrongly stomping pinned-memory Addr#s" — there were no pinned-
backed addresses on the stack to stomp.  Confirms hypothesis (a):
the BS reaching `mkFastStringByteString` really is non-pinned-backed.
Sessions 19–25 collectively rule out all of: bitmap codegen,
`mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, the StackRep
itself.  The actual bug is upstream of all of them, in the
bytestring/FastString allocation boundary.  Next session: instrument
`mkFastStringByteString` to print whether each incoming BS's
`ForeignPtrContents` is `PlainPtr` (unpinned) vs one of the pinned
variants, find the violator, fix the BS producer.  Session
[`HANDOFF.md`](sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md)
scopes it.
And [`docs/sessions/2026-05-10-session-23-stage2-poison-probe/`](sessions/2026-05-10-session-23-stage2-poison-probe/)
for round 5 — **PROBE22POISON found a real read-after-poison.**  PROBE22POISON
(replace every non-evac heap-shape on the running TSO's stack with
`0xDEADBEEF` post-scavenge) caused stage2 ghc compiling M5.hs under
`+RTS -A1m -RTS` to crash deterministically (5/5 iterations) at
`_blk_c7te + 112` with `EXC_BAD_ACCESS at 0xdeadbeef` in
`__memcpy(_, src=0xdeadbeef, 16)`.  The src came from `MEM[Sp+12]`
= slot 6 in PROBE22 coordinates of the most recent (gc_no=2) GC.
Pre-poison value `0x0bf5f38a` was a tagged heap pointer in a
non-evacuated nursery block.  `_blk_c7te` lives between
`_s77C_entry` and
`_ghc_GHCziDataziFastString_mkFastStringByteString_entry` per `nm`
on stage2's text section — i.e. in some local closure /
continuation Cmm block within `GHC.Data.FastString`.  Of the 9
slots PROBE22POISON stomped per run, only 1 caused a read-after-
poison crash; the other 8 were benign (PROBE21 false positives,
exactly as session 22 said).  Session 22's "Catch frames are
correct" stands; the bug is in a *different* module's bitmap.
Next session: re-cross-compile `compiler/GHC/Data/FastString.hs`
with `-ddump-cmm-final`, find the StackRep of the offending
info table (block ~`c7te` or its sibling), and trace back to
StgToCmm/LayoutStack to see why the slot got marked non-pointer.

Deploy with `scripts/deploy-stage2.sh <ssh-host>`.

## Infrastructure

### Tools on uranium (arm64 macOS), under `~/.local/`:

- Host GHC 9.2.8: `~/.local/ghc-9.2.8/bin/ghc`
- Host GHC wrapper (auto-mkdir): `~/.local/ghc-boot-wrap/bin/ghc`
- Cross clang 7.1.1: `~/.local/ghc-ppc-xtools/clang`
- Clang resource-dir: `~/.local/lib/clang/7.1.1/`
- 10.4u SDK: `~/.local/ghc-ppc-xtools/MacOSX10.4u.sdk/`
- cctools-port ld64-253.9-ppc: `~/.local/cctools-ppc/install/bin/powerpc-apple-darwin8-*`
- happy 1.20.1.1, alex 3.2.7.4: `~/.local/bin/`
- PPC gmp.h (32-bit limbs, from pmacg5): `~/.local/ghc-ppc-xtools/include-ppc/gmp.h`
- Cross-CC wrapper: `~/.local/ghc-ppc-xtools/bin-wrap/ppc-cc` (tracked at `scripts/ppc-cc.sh`)
- Tiger-link SSH shim: `~/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-tiger` (tracked at `scripts/ppc-ld-tiger.sh`)
- Fake linker (for autoconf): `~/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-fake`
- ld shim (routes `-r` merge-objects via SSH): installed as `~/.local/cctools-ppc/install/bin/powerpc-apple-darwin8-ld` (tracked at `scripts/ppc-ld-shim.sh`)
- install_name_tool shim (routes PPC Mach-O rewrites via SSH): `~/.local/bin/install_name_tool`
- Cross-env: `source scripts/cross-env.sh` sets PATH + CONFIG_SITE + CROSS_CC etc.

### On pmacg5 (PowerPC Tiger 10.4.11), under `/opt/`:

- gcc 14.2 (Tigerbrew / port): `/opt/gcc14/bin/gcc`, `/opt/gcc14/bin/ld`
- gmp 6.2.1: `/opt/gmp-6.2.1/lib/libgmp.dylib`, includes at `/opt/gmp-6.2.1/include/gmp.h`

### Patches in `patches/` (applied to `external/ghc-modern/ghc-9.2.8/`)

1. `0001-libffi-gate-go-closure-on-ppc-darwin.patch` — libffi 3.3-rc2 had `ffi_go_closure` used unconditionally in `ffi_darwin.c`; gate behind `FFI_GO_CLOSURES`.
2. `0002-restore-32bit-machotypes-for-ppc.patch` — add 32-bit ppc/i386 case to `MachOTypes.h`.
3. `0003-restore-loadarchive-ppc-darwin.patch` — restore PPC case in `LoadArchive.c`.
4. `0004-macho-c-ppc-symbol-extras-and-reloc-include.patch` — `ocAllocateExtras_MachO` for PPC plus `<mach-o/ppc/reloc.h>`.
5. `0005-posixsource-h-no-posix-c-source-on-darwin.patch` — skip `_POSIX_C_SOURCE` define on Darwin (Tiger compat).
6. `0006-quickcross-static-only.patch` — `hadrian QuickCross` flavour: `libraryWays = [vanilla]` (static only).
7. `0007-rts-gate-hs_xchg64-on-64bit.patch` — gate `-Wl,-u,_hs_xchg64` behind 64-bit word size.
8. `0008-cmmtoc-split-w64-double-on-32bit.patch` — recurse `decomposeMultiWord` in `CmmToC.hs` for `CmmFloat n W64` on 32-bit targets, so closures holding Doubles get a full 12-byte layout (con-info + hi32 + lo32) instead of 8 bytes (con-info + truncated 32-bit).  Fixes `pi :: Double` and any Double in a static closure.
9. `0009-restore-ppc-runtime-macho-loader.patch` — restore `relocateSection` for PPC in `rts/linker/MachO.c` (deleted in commit 374e44704b, the GHC 8.8.1 release).  Adds `relocateSectionPPC()` + `relocateAddressPPC()` adapted from 8.6.5 to 9.2.8's per-section restructured API; fixes `ocVerifyImage_MachO` to accept 32-bit `MH_MAGIC` for PPC/i386.  Also fixes a pre-existing 9.2.8 bug in `resolveImports` that wrote through `oc->image + sect->offset` (old monolithic-image addressing) instead of `oc->sections[i].start` (per-section mmap), tripping `checkProddableBlock` on real Haskell `.o` loads.  Verified end-to-end with `tests/macho-loader/run.sh` (C source) and `tests/macho-loader/run-haskell.sh` (Haskell source, exercises HI16/LO16/HA16 + scattered SECTDIFF).
10. `0010-hadrian-cross-iserv.patch` — enable `iserv` + `libiserv` packages for cross-builds (default they're gated behind `not cross`), and special-case the hadrian program-rule so iserv builds from source for the target rather than copying from a (non-existent) stage0 host iserv.  The resulting PPC `ghc-iserv` (29.7 MB) is shipped in the bindist; users plumb it via `pgmi-shim.sh` for `-fexternal-interpreter` over SSH.
11. `0011-rts-eprintf-stub.patch` — register a `__eprintf` symbol in `RTS_PPC_DARWIN_SYMBOLS` so the runtime loader can resolve `___eprintf` references emitted by old-gcc-style `assert()` macros in ghc-bignum / gmp.  The stub function definition lives in `rts/linker/MachO.c` (folded into patch 0009).  Tiger's libSystem has the symbol but doesn't export it, so `dlsym` can't find it — providing our own stub bypasses that.
12. `0012-rts-ppc-contiguous-mmap-and-symbol-extras-near-text.patch` — enable `SHORT_REL_BRANCH` and `USE_CONTIGUOUS_MMAP` for PPC darwin so the loader knows it has the same ±32 MB BR24 limit as ARM32.  The actual fix for symbol_extras placement (so jump islands stay within BR24 range of all text sections) lives in patch 0009: `ocBuildSegments_MachO` reserves space at the end of the RX segment and `oc->symbol_extras` is overridden to point there.  Unblocks loading large `.o` files like `base.o` via iserv.
13. `0013-binary-generic-direct-numeric-guards.patch` — rewrite `Data.Binary.Generic`'s `gput`/`gget` for sum types to use direct numeric comparisons (`size <= 0x100`) instead of the original CPP-macro-expanded `(size - 1) <= fromIntegral (maxBound :: Word8)` chain.  The cross-built ppc-darwin8 GHC mis-compiled the original pattern, always selecting the Word64 branch even when size <= 256 — leading to host emitting 1-byte tags but target reading 8-byte tags for the same Generic-derived sum.  Affected the iserv binary protocol's encoding of `ResolvedBCOPtr` (5 constructors).
14. `0014-ghci-bco-byteswap-on-endian-mismatch.patch` — replace the "mixed endianness not supported" error in `GHCi.CreateBCO` with a recursive byte-swap of the BCO's `instrs` (Word16), `bitmap` (Word64), `lits` (Word64), and any nested `ResolvedBCOPtrBCO` BCOs.  Required because `getArray`/`putArray` write/read raw bytes in host endian — host (arm64 LE) and target (PPC32 BE) disagree.  Together with patch 0013 lands TH end-to-end (v0.8.0).
15. `0015-rts-rtsutils-tiger-strnlen-shim.patch` — inline `tiger_strnlen` in `rts/RtsUtils.c` for `__MAC_OS_X_VERSION_MIN_REQUIRED < 1070`.  Tiger's libSystem predates POSIX 2008's `strnlen` (added in macOS 10.7).  Without the shim, `-prof` programs fail to link with `_strnlen` undefined from `RtsUtils.p_o`.  Lands profiling support (v0.10.0).

Additional in-tree edits NOT tracked as patches (regenerated by autoreconf):
- `mk/config.h`: `#undef HAVE_PTHREAD_SET_NAME_NP`, `HAVE_PTHREAD_SETNAME_NP{,_DARWIN}`, `HAVE_EVENTFD`
- `rts/rts.cabal`, `rts/rts.cabal.in`, `rts/package.conf.in`: gate `_hs_xchg64` / `_hs_cmpxchg64` by 64-bit
- `rts/package.conf.in`: strip `mingwex` from `extra-libraries`
- `rts/linker/MachO.c`: PPC stub in `ocResolve_MachO` (print error for runtime-loader attempts)
- `hadrian/cfg/system.config`: `gmp-include-dir = /Users/cell/.local/ghc-ppc-xtools/include-ppc`

### Config overrides in `scripts/tiger-config.site`

~50 `ac_cv_func_*=no` and `ac_cv_header_*=no` entries telling autoconf that
Tiger lacks clock_gettime, pthread_setname_np, utimensat/openat family,
eventfd, epoll, kevent64, getclock, libRT, _chsize, lutimes, statx, inotify,
copy_file_range, renameat2, lchmod, strerror_r, posix_spawn, dispatch_*,
getcontext/makecontext, pthread_threadid_np, etc.

## Known limitations / future work

1. **Stage2 native ghc** — runs, doesn't compile.  `StgToCmm.Env: variable not found $trModule3_rwD` panic.  See `docs/experiments/006`.
2. **GHCi / TemplateHaskell partial** — the runtime Mach-O loader is alive (v0.6.0, patch 0009; tested on real Haskell `.o` in v0.6.1) and PPC `ghc-iserv` is built and runs on Tiger (v0.7.0, patch 0010).  `pgmi-shim.sh` bridges ghc's local-iserv pipes to the remote target via SSH and the binary protocol works through that.  TH splices, however, need iserv to *find the host's package paths* on the target — and Tiger doesn't have a `/Users/cell/.../HSghc-prim-0.8.0.o` filesystem image.  Two fixes deferred to session 12d: (a) rsync the cross-bindist `lib/` to the same path on Tiger before each TH build, or (b) wire up the proper `iserv-proxy` + `remote-iserv` over TCP (which ships `.o` bytes over the wire to a target temp file).  Plus stage2 native ghc work for in-process GHCi REPL is still roadmap B.  See [docs/sessions/2026-04-24-session-12-iserv-ppc/README.md](sessions/2026-04-24-session-12-iserv-ppc/README.md).
3. **No dynamic libraries** — `QuickCross` keeps `dynamicGhcPrograms = pure False`: PPC Mach-O's 24-bit `r_address` limit on scattered relocs (16 MB section limit) is hit by GHC.Hs.Instances as a dyn_o.  Profiling way is now enabled (v0.10.0).
4. **Not in upstream GHC** — these are all local edits in our vendored tree.  Not yet turned into an MR/PR.
5. **No CI** — nothing keeps this working.  If GHC master moves, this bitrots.

## Build instructions

From scratch on arm64 macOS:

```
cd external/ghc-modern/ghc-9.2.8
source ../../../../scripts/cross-env.sh
./hadrian/build --flavour=quick-cross --docs=none -j8
```

About 16 minutes on M-series Mac, with ~200 SSH link round-trips to pmacg5.

## Session log

- Session 1: project setup, plan.md, fleet recon
- Sessions 2–3: Phase 1 (trying stock GHC 7.0.4 on Tiger — dead end)
- Sessions 4–6: Phase 3 cross-toolchain, configure, libffi fix
- Sessions 7–13: stage1 library chain, CC wrapper, Tiger-link, RTS patches
- Session 14: stage1 hello.hs runs on Tiger 🎉
- Session 15: stage2 ppc-native ghc runs `--version`; compile panic, deferred
- 2026-04-24 sessions 1–10: workflow + bug fixes + bindist installer +
  test battery + cabal cross-compile + runghc-tiger / ghc-pkg verify
  (v0.1.0 through v0.5.0).
- 2026-04-24 session 11: PPC Mach-O runtime loader restored (v0.6.0).
  loadObj + resolveObjs + lookupSymbol work end-to-end on Tiger;
  GHCi/TH still need iserv plumbing layered on top.
- 2026-04-24 session 12a: Haskell `.o` loads end-to-end (v0.6.1).
  Caught a pre-existing 9.2.8 `resolveImports` bug along the way.
  Iserv plumbing scoped in `docs/proposals/iserv-ssh-shim.md`.
- 2026-04-24 session 12b/c: PPC `ghc-iserv` cross-builds and runs on
  Tiger; `pgmi-shim.sh` bridges the iserv binary protocol over SSH
  (v0.7.0).
- 2026-04-24 session 12d: filesystem mirror works around path
  mismatch; DYLD_LIBRARY_PATH fixes libgmp lookup; `__eprintf` stub
  unblocks ghc-bignum loading.  Small Haskell `.o`s now load via
  iserv on Tiger (v0.7.1).
- 2026-04-24 session 12e: BR24 jump-island fix.  `symbol_extras`
  now placed inside the RX segment's mmap so jump islands always
  stay within ±32 MB of all text sections.  All `.o`s (including
  `base.o` ~3 MB) now load via iserv (v0.7.2).  Final hop —
  iserv's binary-protocol parse error at byte ~133 — is a separate
  bug, deferred to 12f.
- 2026-04-29 session 12f: **TemplateHaskell works end-to-end on
  Tiger** (v0.8.0).  Two bugs fixed: (a) cross-built `binary`
  library mis-encoded Generic-derived sum tags as Word64 instead
  of Word8 (patch 0013); (b) BCO array contents need byte-swap on
  host/target endian mismatch (patch 0014).  First TH on PPC/Darwin8
  since GHC 8.6 (2018).  Closes roadmap C.
- 2026-04-29 session 13: vendor `network-3.2.8.0` for Tiger (v0.8.1).
  Two `#ifdef` guards on `IP_RECVTOS` / `IPV6_TCLASS` (10.7+
  constants).  Real localhost TCP echo round-trip on Tiger.  The
  `SOCK_CLOEXEC` concern from session 7 was stale — already gated by
  upstream's `HAVE_ACCEPT4` autoconf check.
- 2026-04-29 session 14: stage2 native ghc investigation (no fix).
  Narrowed bug to a miscompile in stage1's PPC build of
  `compiler/GHC/Core/SimpleOpt.hs`'s `foldl' do_one` accumulator.
  Ruled out the obvious data-structure-miscompile candidates;
  next-session checklist documented.  Cross-compile path remains the
  recommended way to build Haskell for Tiger.
- 2026-04-29 session 15: TLS/HTTPS via tiger.sh's openssl-1.1.1t
  (v0.9.0).  Vendored `HsOpenSSL-0.11.7.10` at `vendor/HsOpenSSL/`
  with a 1-line patch wrapping `runInBoundThread` in a fallback that
  runs the action in the current thread when the threaded RTS isn't
  available (PPC32+gcc14 lacks `__atomic_*_8` intrinsics).  Real
  TLS handshake + HTTPS GET to example.com:443 verified on
  PowerMac G5 / Tiger 10.4.11.
- 2026-04-29 session 16: profiling builds work (v0.10.0).
  Sister project shipped LLVM-7 r4 with BUG-003 fix (PPC asm
  printer emits `r0` for ZERO/R0 base register, not bare `0`),
  unblocking the original session-9 build failure.  Plus two
  Tiger compatibility shims: `-D__MAC_OS_X_VERSION_MIN_REQUIRED=1040`
  in our cross-cc wrapper (so RTS version-gates take the
  pre-Snow-Leopard branch), and a 7-line `tiger_strnlen` inline
  in `rts/RtsUtils.c` (Tiger predates POSIX 2008's `strnlen`).
  Real `mandel.prof` cost-centre report + `mandel.hp` heap-profile
  produced on Tiger.
- 2026-04-30 session 17: stage2 native ghc works on Tiger (v0.11.0).
  Long-running investigation finally tracked the binding-loss bug
  to garbage collection: a major GC during a compile corrupts the
  typechecker's `Bag`-based binding store.  Workaround:
  `+RTS -A1G -RTS` keeps small compiles inside one allocation block
  so GC never fires.  Shipped as `scripts/ghc-stage2-wrapper.sh`
  + `scripts/deploy-stage2.sh`.  Demo `demos/v0.11.0-stage2-native.sh`
  compiles `Hello` and a `Data.Map.Strict` word-count program on a
  PowerMac G5 and runs both end-to-end.  Underlying GC bug not yet
  fixed (likely missing PPC memory fences in 9.2.8's RTS).
- 2026-05-09 session 18: cross-toolchain swapped from LLVM-7 r4 to
  LLVM-8 (v0.12.0).  Three attempts.  First two rolled back on
  indium env breakage and a `updateNurseriesStats` SIGBUS in
  every Haskell binary the new toolchain produced.  Sister project's
  session 036 traced the SIGBUS to LLVM-8 dropping the PPC32 Darwin
  "power" struct alignment field-cap; their patch 0013 restored it.
  Repointed our cross-clang at the patched binary, rebuilt stage1
  in 16m52s (~3× faster than LLVM-7's 48m46s), redeployed stage2,
  v0.11.0 demo green.  Side discovery: GHC's `-fllvm` is a no-op
  for unregisterised ABI targets — the swap is about which clang
  compiles GHC's C output, not about LLVM IR.
- 2026-05-12 session 28: stage2 GC bug investigation, round 10.
  Wrote **PROBE28** — a slim RTS-side per-GC printf in `rts/sm/GC.c`
  (file-static counter + pre-GC mut_list snapshot via `countOccupied`
  + post-GC summary line walking `gct->scavenged_static_objects`)
  — to discriminate session 27's "one bug, two victims" vs "two
  bugs" framings.  With the probe enabled, **Big2.hs `-A1m -G1`
  flips from session 27's TC-time "swap not in scope" signature
  (10/10) to the STG-time `refineFromInScope` signature 5/5** —
  the probe's tiny per-GC timing delay shifts which downstream
  IntMap-backed VarEnv catches the corruption.  Strong evidence
  for **one bug, two victim data structures**.  PROBE28 also rules
  out (i) the mut_list / write-barrier audit (Big2 `-G1` fails 5/5
  with zero mut_list activity — under `-G1` mut_lists are empty),
  and (ii) the static_objects scavenge audit (under `-G1` every GC
  walks the same ~175k-entry static chain in both M5 (PASS) and Big2
  (FAIL)).  Remaining suspects: `rts/sm/Evac.c` (evacuate, copy_tag,
  copy) and `rts/sm/Scav.c::scavenge_block` dispatch — these run on
  every GC regardless of `-G` and would fire identically across
  M5/Big2 except that Big2 has more closures of whatever type
  triggers the bug.  v0.12.0 ships unchanged; probe applied for
  measurement, then reverted; clean stage2 redeployed at session end.
  Session
  [`HANDOFF.md`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)
  scopes the closure-type histogram extension + Evac.c / Scav.c
  audit.
- 2026-05-12 session 27: stage2 GC bug investigation, round 9.
  Re-established a **deterministic non-perturbing repro** after
  session 26 showed PROBE26 was hiding the M5.hs SIGSEGV: clean
  stage2 + `M5.hs +RTS -A1m -RTS` panics **10/10** with the
  STG-time panic family (depSortStgBinds, refineFromInScope, etc.).
  Tried a matrix of RTS flag profiles on M5.hs: `-A1G` 10/0,
  `-A1m` 0/10, `-A1m -G1` **10/0** (single-generation fully
  suppresses!), `-A512k` 9/1, `-A4m` 10/0.  `-G1` empties the
  older-gen mut_list scavenge loop in `scavenge_capability_mut_lists`,
  so the bug looked consistent with a missed-mut_list-entry / write-
  barrier bug.  Then on slightly larger inputs the picture broke:
  M5plus.hs `-A1m -G1` 5/0 (still suppressed), but a syntactically
  clean Big2.hs `-A1m -G1` fails **10/10** with a previously-
  undocumented signature — `* GHC internal error: 'swap' is not in
  scope during type checking, but it passed the renamer`.  So the
  bug has at least two distinct corruption modes: STG-time
  (suppressed by `-G1`) and typecheck-time (not suppressed).  Either
  two separate bugs or one bug with two victim data structures.
  v0.12.0 ships unchanged; source tree clean; no commits to
  external/ghc-modern this session.  Session
  [`HANDOFF.md`](sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md)
  scopes a slim RTS-side probe to discriminate one-bug vs two-bug.
- 2026-05-12 session 26: stage2 GC bug investigation, round 8.
  PROBE26 = Haskell-side ForeignPtrContents classifier in
  `mkFastStringByteString`.  Result on M5.hs `+RTS -A1m`: 150
  visible BSes across 3 runs, all **`PlainPtr+pinned`, zero
  UNPINNED**.  Hypothesis (a) from session 25 ("BS reaches
  `mkFastStringByteString` with non-pinned MBA") is **rejected
  by direct observation**.  Additionally, PROBE26 prevents the
  SIGSEGV on M5.hs entirely (0/3 vs. session 23's 5/5) — the
  instrumentation perturbs `mkFastStringByteString`'s Cmm enough
  to hide the bug.  Stress-test on M5plus.hs and Big.hs: bug
  rate dramatically reduced but not zero (1/16 panic on a cold
  M5plus.hs first run).  Sessions 23–25's `_blk_c7te + 112 /
  0xdeadbeef` signature was a PROBE22POISON / PROBE23 probe
  artefact — without any probe, the bug surfaces as the panics
  that session 17 first cataloged.  Sessions 19–26 collectively
  rule out: bitmap codegen, mkLivenessBits, stackMapToLiveness,
  LayoutStack, StackRep, AND the BS-pinning-invariant theory.
  v0.12.0 ships unchanged; stage2 on pmacg5 redeployed clean.
  See [`HANDOFF.md`](sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md).
- 2026-05-11 session 25: stage2 GC bug investigation, round 7.
  PROBE23 (PROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the
  poison filter, plus a no-poison `PROBE23PINNED` log of stack
  slots pointing into pinned blocks) ran against M5.hs under
  `+RTS -A1m`.  Result: 5/5 SIGSEGV byte-identical to session
  23's PROBE22 (same crash slot `gc_no=2 slot=6 old=0x0bf5f38a`
  at `_blk_c7te + 112`, same `r4=0xdeadbeef`, same `r5=0x10`),
  AND `pinned_skip = 0` across every GC of every iteration.
  No stack-resident value pointed into a `BF_PINNED` block during
  M5.hs's compile.  Rules out the false-positive theory in its
  strong form: PROBE22 was NOT wrongly stomping pinned-Addr#s
  (there weren't any).  Confirms hypothesis (a) from session-24
  HANDOFF: the BS reaching `mkFastStringByteString` is backed by
  a non-pinned `MutableByteArray#`, violating the pinning
  invariant at `libraries/base/GHC/ForeignPtr.hs:145`.  Sessions
  19–25 collectively rule out all of: bitmap codegen,
  `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, the
  StackRep itself.  The bug is upstream of all of them, in the
  bytestring/FastString allocation boundary.  v0.12.0 ships
  unchanged; stage2 on pmacg5 reverted to clean RTS at session-25
  end.  Next session: instrument `mkFastStringByteString` (or
  audit the BS producer surface) to find the BS allocator that
  omits pinning.
- 2026-05-10 session 23: stage2 GC bug investigation, round 5.
  Built PROBE22POISON (RTS patch — replace every non-evac heap-
  shape on the running TSO's stack with `0xDEADBEEF` post-
  scavenge) and ran stage2 ghc against M5.hs under `+RTS -A1m`.
  5/5 iterations crashed deterministically at `_blk_c7te + 112`
  with `EXC_BAD_ACCESS at 0xdeadbeef`, in
  `__memcpy(dst, src=0xdeadbeef, len=16)`.  The poisoned slot
  is at `MEM[Sp+12]` of the topmost frame at crash time, which
  corresponds to **slot 6** in PROBE22's coordinates from the
  most recent (gc_no=2) GC — pre-poison value `0x0bf5f38a`,
  a tagged heap pointer.  `_blk_c7te` lives between
  `_s77C_entry` and
  `_ghc_GHCziDataziFastString_mkFastStringByteString_entry` per
  `nm` on stage2 ghc's text section, so the misclassifying
  StackRep is in some local closure / continuation Cmm block
  within `GHC.Data.FastString`.  Of the 9 slots PROBE22POISON
  stomped per run, only 1 caused a read-after-poison crash;
  the other 8 were benign (consistent with session 22's
  per-block audit).  v0.12.0 ships unchanged; stage2 on pmacg5
  reverted to clean RTS at session-23 end.  Next session: dump
  cross-built FastString.hs Cmm, find the StackRep of the
  offending info table, trace back to LayoutStack /
  stackMapToLiveness.
- 2026-05-10 session 22: stage2 GC bug investigation, round 4.
  Re-tested session 21's "bitmap is wrong" hypothesis with a
  per-block audit: for every `_blk_NAME` in cross-built Catch.hs
  whose StackRep contains `True`, check whether the body reads
  the True-marked slot.  Result across all 15 True-containing
  frames: **0 reads, 15 writes** — the bitmap is the right answer.
  Cross-host comparison shows cross emits 8× more True-bit
  StackReps than host on the same source, but the audited host
  PNP frames have the same dead-slot pattern.  Verified the
  bit-order convention end-to-end: bit 0 = first slot above the
  info pointer in both compiler and runtime.  Conclusion:
  PROBE21's BAD events for the 4 dominant Catch.hs PNP/PN info
  tables are **false positives** (heap-shaped values stranded
  in genuinely-dead slots).  The actual GC crash is real but
  somewhere else.  Next session: build poison-on-stale-slot RTS
  patch — overwrite each non-evac heap-shaped slot value with
  `0xDEADBEEF` post-scavenge; if the typechecker crashes at
  `0xDEADBEEF`, the slot was being read = real bug; if it
  crashes at the original "variable not found" panic, slots are
  truly dead = bug is RTS-side or in a non-RET_SMALL frame
  type.  Two reusable audit scripts shipped.
  Stage2 still ships unchanged.
- 2026-05-10 session 21: stage2 GC bug investigation, round 3.
  Decoded the on-disk bitmap word format on PPC32
  (BITMAP_BITS_SHIFT=5, MASK=0x1F).  Confirmed both compile-time
  (`pc_BITMAP_BITS_SHIFT=5` in stage1's PlatformConstants) and
  runtime (`SIZEOF_VOID_P=4` → shift=5 in Constants.h) agree —
  no shift mismatch.  Re-attributed PROBE21BAD events: 93/106
  of pay=1 BADs come from just 4 info tables, all with bitmap
  layout 0x42 (PN size 2) or 0x43 (PNP size 3) — middle slot
  wrongly marked non-pointer.  Cross-rebuilt
  `Control/Monad/Catch.hs` with `-ddump-cmm`: the IR has
  exactly 9 `[F,T,F]`/`[F,T]` StackReps matching the .o's 9
  `PN`/`PNP` info tables.  **The bitmap-encoding step is
  faithful.** Therefore the bug lives in
  `compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` or
  earlier StgToCmm StackMap construction.  Likely cause: a
  saved-pointer slot doesn't make it into `sm_regs`, or its
  `LocalReg` type is misclassified so `isGcPtrType` returns
  False.  Two reusable analysis scripts
  (decode-info-tables.py, correlate-probe21-bads.py) shipped.
  Stage2 still ships unchanged.
- 2026-05-10 session 20: stage2 GC bug investigation, round 2.
  Built PROBE20 + PROBE21 on top of the debug RTS to walk the
  running TSO's stack post-scavenge and classify every word.
  Found 184 stack slots that are heap-shaped but non-evac'd —
  bit-for-bit deterministic across iter1/2/3.  PROBE21's
  bitmap-aware walker shows **100% of those slots have
  `is_ptr=0`** (the frame's bitmap claims they're non-pointer).
  Pointer derefs of the BAD values yield real info-table
  addresses (e.g. `_ghczmprim_GHCziTuple_Z2T_con_info` for a
  2-tuple).  GC is doing its job; the bitmap is wrong.
  Affects 14+ info tables across 6+ modules
  (Data.Map.Strict.Internal, Control.Monad.Catch,
  GHC.Iface.Binary, GHC.Base, GHC.List, Data.Map.Internal) —
  systematic, not per-module.  Why the bitmap is wrong is the
  session-21 question; likeliest culprit is a host-arm64 →
  target-PPC32 mismatch in StgToCmm liveness analysis.  Stage2
  still ships unchanged with the `-A1G` workaround.
- 2026-05-09→10 session 19: stage2 GC bug investigation, round 1.
  Linked stage2 against `libHSrts-1.0.2_debug.a` and ran M5.hs
  compiles under sanity check (`+RTS -DS`), single-generation
  GC (`-G1`), zero-on-free (`-DZ`), and an instrumented
  `markCAFs` that logged per-GC CAF counts.  Three big hypotheses
  ruled out: SMP atomics (non-threaded RTS uses no fences anyway),
  `large_alloc_lim` 32-bit overflow (1 MiB at default; doesn't
  overflow), and CAF-list truncation (count grows monotonically
  across all 25 GCs in every run).  Sanity check fires no
  assertions — heap is internally consistent.  `-G1` doesn't
  bypass the bug, so it's not specifically gen0→gen1 promotion.
  PROBE19's per-GC trace is bit-for-bit deterministic across runs
  while M5.o output is non-deterministic, which means the
  corruption is in non-heap state (saved registers / stack slots
  / `StgRegTable` field interpretation on PPC32).  Stage2 still
  ships unchanged with the `-A1G` wrapper.
