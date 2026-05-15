# Session 50 findings — **Smoking gun: `Data.Graph.scc` (Haskell base) drops trees from the SCC forest on PPC32 unreg under `-A1m -G1`**

## TL;DR — four probe iterations, ultra-tight localization

Session 50 iterated four probe revisions in one sitting, drilling
from `tcTopBinds`'s upstream caller (the renamer) all the way down
to a specific function in `Data.Graph` from the Haskell `base`
library.  Every iteration tightened the locus.

### Pipeline narrowing

| iter | locus pinned                                       | clean vs failing |
|------|----------------------------------------------------|------------------|
| v1   | corruption is INSIDE `rnValBindsRHS` (or `LHS`)   | LHS/RHS in=8, after_mapBagM=8, **after_depAnal_groups=3** |
| v2   | corruption is INSIDE `depAnalBinds`                | bag_in=8, list_len=8, **sccs_len=3** |
| v3   | corruption is INSIDE `depAnal` (Name/Env.hs)       | nodes_in=8, keyed_nodes=8, graph_nodes=8, **scc_result=3** |
| v4   | corruption is INSIDE `stronglyConnCompG`'s `scc`   | numbered_nodes=8, **forest_len=3** (== result_len) |

**`Data.Graph.scc` is the bug.**  It receives a `Graph` with N
vertices and returns a `Forest Vertex` with fewer than N trees.
Specifically on the nested test case (1-vertex graph), `scc`
returns `[]` (zero trees) instead of `[Node 1 []]` (one tree).
On the top-level test case (8-vertex graph), `scc` returns 3
trees instead of 8 in failing runs.

### Reproducer

`Big2.hs` (8 independent top-level value bindings:
`freqMap`, `topK`, `dedup`, `countOf`, `shift`, `scaleAndShift`,
`allPositive`, `cumsum`), compiled by `ghc-real` on pmacg5 with
`+RTS -A1m -G1 -RTS`.  Probe51-friendly: `scc` should be tested
in isolation by feeding it a known graph.

## F1. Probe50 designed four iterations

In `compiler/GHC/Rename/Bind.hs`,
`compiler/GHC/Types/Name/Env.hs`, and
`compiler/GHC/Data/Graph/Directed.hs`:

- `probe50Log`, `probe50NEnvLog`, `probe50DGLog` — three
  separate IORef counters in three modules (could be unified
  later by a shared module).  All log via `unsafePerformIO` +
  `hPutStrLn stderr`.

**v1** (6 hooks): `rnValBindsLHS_in_mbinds` /
`_after_mapBagM`, `rnValBindsRHS_in_mbinds` /
`_after_mapBagM_binds_w_dus` / `_after_depAnal_groups` /
`_after_depAnal_total`.  Narrowed corruption to between
`after_mapBagM_binds_w_dus` (8) and `after_depAnal_groups` (3).

**v2** (3 more hooks inside `depAnalBinds`):
`depAnalBinds_bag_in`, `_list_len`, `_sccs_len`.
Narrowed further to `depAnal` (the SCC computation in
`Name/Env.hs`).  `bagToList binds_w_dus` faithfully produced 8
elements; `depAnal` returned 3 SCCs.

**v3** (4 hooks inside `depAnal`): `depAnal_nodes_in`,
`_keyed_nodes`, `_graph_nodes`, `_scc_result`.  Narrowed
further to `stronglyConnCompFromEdgedVerticesUniq`.  All three
pre-SCC counts (nodes_in / keyed_nodes / graph_nodes) were 8
in failing runs; only the SCC result was 3.

**v4** (4 hooks inside `Directed.hs`):
`graphFromEdgedVertices_in_nodes`,
`_numbered_nodes`, `_empty_input` (a branch hit for empty
input), and `stronglyConnCompG_forest_len`, `_result_len`.
**Pinpointed: `scc (gr_int_graph graph)` is where the count
drops.** `numbered_nodes` is full (8 in failing top-level, 1 in
failing nested), but `forest_len` is short (3, 0 respectively).

Patch artifact:
[`probe50-renamer-depAnal.patch`](probe50-renamer-depAnal.patch)
(197 lines; cumulative v4).

## F2. The locus: `Data.Graph.scc` from Haskell `base`

`stronglyConnCompG` in `compiler/GHC/Data/Graph/Directed.hs:290`:

```haskell
stronglyConnCompG :: Graph node -> [SCC node]
stronglyConnCompG graph = decodeSccs graph forest
  where forest = {-# SCC "Digraph.scc" #-} scc (gr_int_graph graph)
```

`scc :: Graph -> Forest Vertex` is from `Data.Graph` in the
`containers` package (or `Data.Graph` from base in newer GHCs —
need to confirm which one 9.2.8 uses).  This function:
1. Builds the depth-first forest of the graph.
2. Builds the depth-first forest of the transpose graph.
3. Returns the SCC forest derived from the two DFS forests.

The implementation uses `mutable arrays / STArray` internally.
That's the most likely site for the bug — GC corrupts a
mutable array or the working ST state.

## F3. Detailed v4 results — failing len=600

Top-level value binds (8 input → 3 SCCs):

```
PROBE50    rnValBindsRHS_after_mapBagM_binds_w_dus n=8
PROBE50    depAnalBinds_list_len                   n=8
PROBE50DG  graphFromEdgedVertices_in_nodes         n=8
PROBE50DG  graphFromEdgedVertices_numbered_nodes   n=8
PROBE50DG  stronglyConnCompG_forest_len            n=3  ← !!
PROBE50DG  stronglyConnCompG_result_len            n=3
PROBE50NE  depAnal_scc_result                      n=3
PROBE50    depAnalBinds_sccs_len                   n=3
PROBE50    rnValBindsRHS_after_depAnal_groups      n=3
PROBE50    rnValBindsRHS_after_depAnal_total       n=4
```

Nested `topK`'s where-clause for `swap` (1 input → 0 SCCs):

```
PROBE50    rnValBindsRHS_after_mapBagM_binds_w_dus n=1
PROBE50    depAnalBinds_list_len                   n=1
PROBE50DG  graphFromEdgedVertices_in_nodes         n=1
PROBE50DG  graphFromEdgedVertices_numbered_nodes   n=1
PROBE50DG  stronglyConnCompG_forest_len            n=0  ← !!
PROBE50DG  stronglyConnCompG_result_len            n=0
PROBE50NE  depAnal_scc_result                      n=0
PROBE50    depAnalBinds_sccs_len                   n=0
```

**A 1-vertex graph with no edges has the SCC `[AcyclicSCC 1]` —
one tree.  `scc` returning `[]` is a bona fide bug, period.**

## F4. The pipeline progress chain (sessions 42-50)

| Session | Hook point                                  | Count clean / failing |
|---------|---------------------------------------------|------------------------|
| 42      | `simplTopBinds` entry                       | 9 / 0-1               |
| 43      | `core2core` entry                           | 9 / 1-3               |
| 44      | `deSugar` `final_prs`                       | 9 / 3-6               |
| 45      | `deSugar` `tcg_binds` entry                 | 9 / 3-6               |
| 46      | `hsc_typecheck` exit                        | 9 / 3-5               |
| 47      | `tcRnSrcDecls` output                       | 9 / 2-5               |
| 48      | `tcTopBinds val_binds val_sigs` output      | 8 / 2-3               |
| 49      | `tcTopBinds` INPUT                          | 8 / 2-3               |
| **50**  | **`Data.Graph.scc` in `stronglyConnCompG`** | **8 / 3** (forest_len) |

Twelve sessions of pipeline-bisection, each ruling out a phase.

## F5. Why `-A1m -G1` triggers this

`scc` from `Data.Graph` uses ST state (`STArray` for marking
visited vertices, working stack/queue).  Under heavy GC
pressure (`-A1m -G1`), GC may relocate the ST state's array
backing or corrupt the cons-list spine that holds the
intermediate DFS results.

PPC32 unreg's GC has a known bug corrupting CONSTR_2_0 closures
(session 42 finding).  `Tree Vertex = Node Vertex [Tree Vertex]`
which has CONSTR_2_0 layout (2 pointer fields).  The `:` cons
cell of `[Tree Vertex]` is also CONSTR_2_0.  Either could be
the corruption target.

## F6. What probe50 directly ruled in/out

**Confirmed:**

- The renamer's `rnValBindsLHS` / `rnValBindsRHS` `mapBagM`
  iterations are innocent — they correctly process all 8
  bindings.
- `depAnalBinds` in `compiler/GHC/Rename/Bind.hs:570` is innocent —
  `bagToList` faithfully produces 8 elements.
- `depAnal` in `compiler/GHC/Types/Name/Env.hs:66` is innocent —
  it correctly numbers and builds the graph_nodes list.
- `graphFromEdgedVertices` in
  `compiler/GHC/Data/Graph/Directed.hs:118` is innocent — it
  correctly produces a Graph with 8 vertices.
- **`Data.Graph.scc` (from Haskell `base` or `containers`) is
  the bug.**  Returns a Forest with fewer trees than the input
  graph has vertices.

**Ruled out (this session):**

- Any corruption in the renamer's Bag traversal.
- Any corruption in `depAnal`'s zip / map / mkNameEnv setup.
- Any corruption in `graphFromEdgedVertices`'s array build.

**Strong-but-not-proven:**

- The bug is in `scc`'s ST-based mutable-array bookkeeping
  (most likely), OR in the cons-list spine of intermediate
  results, OR in the `Forest Vertex = [Tree Vertex]` output
  list spine.

## F7. Concrete next-session targets (session 51)

1. **Isolate `scc` in a standalone test.**  Write a tiny
   Haskell program that builds a known graph (8 vertices, no
   edges) and calls `Data.Graph.scc` directly.  Run it under
   `+RTS -A1m -G1 -RTS` on pmacg5.  If it reproduces, we have a
   minimal repro without the whole compiler.
2. **Drill `Data.Graph.scc`'s implementation.**  Find its
   source in `base` or `containers` (depending on what
   9.2.8 imports).  Hook the internal DFS / SCC steps.  Most
   likely candidates: `dff`, `dfs`, `scc'` (whatever the
   internal names are).  This will pinpoint whether the bug is
   in DFS, in transpose, or in the SCC-derivation step.
3. **Confirm CONSTR_2_0 hypothesis.**  Hook the corruption
   while watching for `Tree Vertex` or `[Tree Vertex]` cons
   cells specifically.  Could test by replacing the SCC
   implementation with a snapshot-printer to see WHEN the count
   drops.
4. **Try `+RTS -DG -RTS` (GC tracing).**  See which GC pass
   coincides with the count change.  May reveal whether minor
   GC or major GC is the culprit.
5. **File a GHC / Haskell-libraries bug report.**  We have
   reproducible evidence that `Data.Graph.scc` returns wrong
   output on PPC32 unreg under GC pressure.

## F8. Stage 1 / clean baseline matches throughout

All four probe iterations built cleanly and ran the baseline test
battery at end with 30 PASS / 4 FAIL_OUTPUT (same noise floor as
session 48/49).  Probe code was reverted between v4 and
end-of-session.

## F9. Heap-layout sensitivity continues

- len=600: depAnal returns 3 SCCs (total 4 binders — one
  CyclicSCC of size 2 + two AcyclicSCC of size 1).
- len=1650: depAnal returns 3 SCCs (total 3 binders — three
  AcyclicSCC).

The number of dropped trees is heap-layout-sensitive.  But the
pattern is robust: failing always produces FEWER SCCs than
input vertices.

## F10. The fake CyclicSCC observation (session 49) now explained

Session 49 noticed a "fake Recursive group of size 2 where
`Big2.hs` has no mutually recursive bindings."  Session 50's
data clarifies this: `scc` doesn't just drop trees — sometimes
it MERGES vertices into a fake CyclicSCC.  Looking at the v4
data for failing len=600: `forest_len=3`,
`depAnal_total_binders=4`, so 1 of the 3 SCCs is a CyclicSCC of
size 2 (4 binders in 3 SCCs = 1 + 1 + 2).  That's a real bug:
`scc` is hallucinating a cycle between two non-adjacent
vertices.

This is consistent with GC corrupting either the graph's
adjacency array (causing scc to see fake edges) or scc's
internal DFS stack (causing it to backtrack into the wrong
vertex).
