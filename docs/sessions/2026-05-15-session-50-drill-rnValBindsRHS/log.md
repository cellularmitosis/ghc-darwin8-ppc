# Session 50 log

## 2026-05-15 — session start

- Read HANDOFF.md, README.md, findings.md from session 49.
  Session 49 overturned session 48: the input list arriving at
  `tcTopBinds` is already truncated.  Corruption is in the
  renamer that builds the `HsGroup`'s `hs_valds` field.
- Confirmed source tree clean at
  `compiler/GHC/Rename/Bind.hs` (file unmodified) and
  `compiler/GHC/Tc/Gen/Bind.hs` (probe49 reverted at end of
  session 49).
- Inspected `rnValBindsLHS` (line 282) and `rnValBindsRHS`
  (line 298) in `compiler/GHC/Rename/Bind.hs`.  Also
  `rnSrcDecls` in `Rename/Module.hs:96` which wires them.

## Probe50-v1 (6 hooks in Bind.hs)

Hooks at entry / exit of `rnValBindsLHS`, entry / after mapBagM
/ after depAnalBinds (groups + total) of `rnValBindsRHS`.

Build 7m11s, EXIT=0
([`logs/build1-probe50v1.log`](logs/build1-probe50v1.log)).
Deploy smoke-test PASS
([`logs/deploy1-probe50v1.log`](logs/deploy1-probe50v1.log)).
Triggers:
[`logs/v1-triggers.log`](logs/v1-triggers.log).

**Finding:** `mapBagM rnLBind` correctly yields 8 elements;
`depAnalBinds` returns 3 groups (4 binders total) — narrows to
within `depAnalBinds`.

## Probe50-v2 (3 hooks inside `depAnalBinds`)

Hooks: `depAnalBinds_bag_in`, `_list_len`, `_sccs_len`.

Build 7m28s, EXIT=0
([`logs/build2-probe50v2.log`](logs/build2-probe50v2.log)).
Triggers: [`logs/v2-triggers.log`](logs/v2-triggers.log).

**Finding:** `bagToList` correctly yields 8 elements; `depAnal`
returns 3 SCCs — narrows to within `depAnal`.

## Probe50-v3 (4 hooks inside `depAnal` in Name/Env.hs)

Hooks: `depAnal_nodes_in`, `_keyed_nodes`, `_graph_nodes`,
`_scc_result`.

Build 7m27s, EXIT=0
([`logs/build3-probe50v3.log`](logs/build3-probe50v3.log)).
Triggers: [`logs/v3-triggers.log`](logs/v3-triggers.log).

**Finding:** zip / mk_node / key_map all yield 8 — narrows to
within `stronglyConnCompFromEdgedVerticesUniq`.

## Probe50-v4 (4 hooks inside `Directed.hs`)

Hooks: `graphFromEdgedVertices_in_nodes`, `_numbered_nodes`,
`_empty_input`, `stronglyConnCompG_forest_len`, `_result_len`.

Build 7m56s, EXIT=0
([`logs/build4-probe50v4.log`](logs/build4-probe50v4.log)).
Triggers: [`logs/v4-triggers.log`](logs/v4-triggers.log).

**Finding:** `graphFromEdgedVertices` is correct
(numbered_nodes=8 for top-level, =1 for nested swap).  But
`stronglyConnCompG_forest_len` is 3 (top-level) or 0 (nested
swap).  Since `forest = scc (gr_int_graph graph)`,
**`Data.Graph.scc` is the bug.**

A 1-vertex graph with no edges should yield 1 tree.  `scc`
returns 0.  That's an outright wrong output, not a count
discrepancy.

## Revert + clean rebuild + redeploy

- `git checkout -- compiler/GHC/Rename/Bind.hs
   compiler/GHC/Types/Name/Env.hs
   compiler/GHC/Data/Graph/Directed.hs` — all probes reverted.
- Stage1 clean rebuild:
  [`logs/build5-clean.log`](logs/build5-clean.log).
- Stage2 redeploy:
  [`logs/deploy5-clean.log`](logs/deploy5-clean.log).
- Baseline tests:
  [`logs/baseline-tests-end.log`](logs/baseline-tests-end.log).

Session ends CLEAN.

## The pipeline progression chain (sessions 42-50)

S42 simplTopBinds=0-1 → S43 core2core entry=1-3 → S44 deSugar
final_prs=3-6 → S45 deSugar tcg_binds entry=3-6 → S46
hsc_typecheck_exit=3-5 → S47 tcRnSrcDecls output=2-5 → S48
tcTopBinds OUTPUT=2-3 → S49 tcTopBinds INPUT=2-3 → S50
`Data.Graph.scc` forest_len=0-3 (clean: 1, 8).

**Twelve sessions of pipeline bisection.  Locus now pinned to a
single function in the Haskell base library.**
