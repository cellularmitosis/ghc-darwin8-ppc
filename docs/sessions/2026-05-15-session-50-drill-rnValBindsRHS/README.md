# Session 50 — corruption pinned to **`Data.Graph.scc`** (Haskell base library)

**Date:** 2026-05-15 (continuation of session 49; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-49 exit.
Stage1 + stage2 redeployed clean.  Baseline tests at the
session-48 noise floor (30 PASS, 4 FAIL_OUTPUT — all
test-design issues).  Session 49 overturned session 48 and
localized the truncation to **BEFORE `tcTopBinds`** — i.e., in
the renamer that builds the `HsGroup`'s `hs_valds` field.

**Status on exit:** CLEAN.  Probe50 (across four iterations
spanning `compiler/GHC/Rename/Bind.hs`,
`compiler/GHC/Types/Name/Env.hs`, and
`compiler/GHC/Data/Graph/Directed.hs`) reverted, stage1
rebuilt clean, stage2 redeployed, smoke-test PASS, baseline
tests run.  **Finding:** Four iterations of probe-build-deploy
-trigger drilled the corruption locus from the renamer down to
**`Data.Graph.scc` in Haskell base library**.  `scc` receives
a Graph with N vertices and returns a Forest with fewer trees
than vertices — including the dramatic case of returning 0
trees from a 1-vertex graph.  v0.12.0 release unchanged.

## Plan (per session 49 HANDOFF)

Drill into `compiler/GHC/Rename/Bind.hs`'s `rnValBindsRHS`
(line 298) and `rnValBindsLHS` (line 282) to localize the
truncation in the renamer.

## What happened

### Phase 1 — probe50-v1 (6 hooks in Bind.hs)

Hooks: `rnValBindsLHS_in_mbinds` / `_after_mapBagM`,
`rnValBindsRHS_in_mbinds` / `_after_mapBagM_binds_w_dus` /
`_after_depAnal_groups` / `_after_depAnal_total`.

Result (failing top-level len=600):
- LHS in=8, LHS after_mapBagM=8.
- RHS in=8, RHS after_mapBagM=**8**.
- RHS after_depAnal_groups=**3**, after_depAnal_total=**4**.

**The `mapBagM rnLBind` is correct.  `depAnalBinds` drops the
count.**

### Phase 2 — probe50-v2 (3 hooks inside `depAnalBinds`)

Hooks: `depAnalBinds_bag_in`, `_list_len`, `_sccs_len`.

Result (failing top-level len=600):
- bag_in=8, list_len=8.
- sccs_len=**3**.

**`bagToList` correctly produces 8 elements.  `depAnal` is the
culprit.**

### Phase 3 — probe50-v3 (4 hooks inside `depAnal` in Name/Env.hs)

Hooks: `depAnal_nodes_in`, `_keyed_nodes`, `_graph_nodes`,
`_scc_result`.

Result (failing top-level len=600):
- nodes_in=8, keyed_nodes=8, graph_nodes=8.
- scc_result=**2**.

**Numbering and graph_nodes construction are correct.
`stronglyConnCompFromEdgedVerticesUniq` drops nodes during the
SCC computation.**

### Phase 4 — probe50-v4 (4 hooks inside `stronglyConnCompG` and `graphFromEdgedVertices`)

Hooks: `graphFromEdgedVertices_in_nodes` / `_numbered_nodes` /
`_empty_input`, `stronglyConnCompG_forest_len` / `_result_len`.

Result (failing top-level len=600):
- graphFromEdgedVertices_in_nodes=8, numbered_nodes=8.
- stronglyConnCompG_forest_len=**3**, result_len=**3**.

Result (failing nested `swap` len=600):
- graphFromEdgedVertices_in_nodes=1, numbered_nodes=1.
- stronglyConnCompG_forest_len=**0**, result_len=**0**.

**`forest = scc (gr_int_graph graph)` is where the count drops.
`scc` is `Data.Graph.scc` from Haskell base library.**  A
1-vertex graph with no edges should yield `[Node 0 []]` — one
tree.  `scc` returning `[]` is an outright wrong output.

### Phase 5 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Rename/Bind.hs
   compiler/GHC/Types/Name/Env.hs
   compiler/GHC/Data/Graph/Directed.hs` — all probes reverted.
* Stage1 clean rebuild:
  [`logs/build5-clean.log`](logs/build5-clean.log).
* Stage2 redeploy:
  [`logs/deploy5-clean.log`](logs/deploy5-clean.log).
* Baseline tests:
  [`logs/baseline-tests-end.log`](logs/baseline-tests-end.log).

Session ends CLEAN.

## Files added this session

* `README.md` (this), `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md`.
* `probe50-renamer-depAnal.patch` — cumulative v4 patch (197
  lines across three files).
* `scripts/run-triggers.sh` (v1), `run-triggers-v3.sh`,
  `run-triggers-v4.sh`.
* `logs/baseline-tests-start.log`,
  `build1-probe50v1.log`, `deploy1-probe50v1.log`,
  `v1-triggers.log`,
  `build2-probe50v2.log`, `deploy2-probe50v2.log`,
  `v2-triggers.log`,
  `build3-probe50v3.log`, `deploy3-probe50v3.log`,
  `v3-triggers.log`,
  `build4-probe50v4.log`, `deploy4-probe50v4.log`,
  `v4-triggers.log`,
  `build5-clean.log`, `deploy5-clean.log`,
  `baseline-tests-end.log`.

## Top finding

**`Data.Graph.scc`** (in Haskell `base` / `containers`) is the
corruption site.  When called with a Graph of N vertices, it
returns a `Forest Vertex` with fewer trees than vertices,
under PPC32 unreg with `+RTS -A1m -G1 -RTS`.

The bug is consistent with session 42's finding that PPC32-unreg
GC corrupts CONSTR_2_0 closures.  `Tree Vertex = Node Vertex
[Tree Vertex]` is CONSTR_2_0; `[Tree Vertex]` cons cells are
also CONSTR_2_0.

Session 51 should isolate `scc` in a standalone Haskell
program and drill its internal DFS / transpose / SCC-derivation
steps.

See [`findings.md`](findings.md) §F7 for next-experiment
recipes and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
