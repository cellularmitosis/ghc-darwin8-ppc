# Handoff from session 50 → session 51

**For:** the next claude session.
**From:** session 50 (probe50, four iterations — 17 hook
sites total across `compiler/GHC/Rename/Bind.hs`,
`compiler/GHC/Types/Name/Env.hs`,
`compiler/GHC/Data/Graph/Directed.hs`).
**Recommended pickup:** isolate `Data.Graph.scc` (Haskell base
library) in a standalone test, then drill its internals.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe50 reverted from all three files).
Stage1 rebuilt clean, stage2 redeployed clean, smoke-test PASS,
baseline tests matched session-49 noise floor (30 PASS, 4
FAIL_OUTPUT).  v0.12.0 release unchanged.

## TL;DR — `Data.Graph.scc` IS THE BUG

Four probe iterations narrowed the corruption locus
incrementally:

| iter | locus pinned                                       |
|------|----------------------------------------------------|
| v1   | inside `rnValBindsRHS` (mapBagM=8, depAnal_groups=3) |
| v2   | inside `depAnalBinds` (bagToList=8, sccs_len=3)     |
| v3   | inside `depAnal` (graph_nodes=8, scc_result=3)      |
| v4   | inside `stronglyConnCompG` (numbered_nodes=8, **forest_len=3**) |

`forest = scc (gr_int_graph graph)` is where the count drops.
`scc` is `Data.Graph.scc` from Haskell `base` (or
`containers` — TBD).  It receives a Graph with N vertices and
returns a Forest with fewer trees than vertices.

The most dramatic data point: **`scc` returns 0 trees from a
1-vertex graph with no edges.**  That's an outright wrong
output, not just a count discrepancy.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative (v1 → v4).
3. [`findings.md`](findings.md) — F1..F10 analysis.
4. [`log.md`](log.md) — real-time log.
5. (Reference) Session 49
   [`HANDOFF.md`](../2026-05-15-session-49-drill-tcTopBinds/HANDOFF.md).

## What to try next, in priority order

### Top: isolate `scc` in a standalone test

Write a tiny Haskell program:

```haskell
import Data.Graph
import Data.Array

main :: IO ()
main = do
  let g = listArray (0, 7) [[], [], [], [], [], [], [], []]
  print (scc g)
```

Cross-compile, ship to pmacg5, run with `+RTS -A1m -G1 -RTS`.
Expected: `[Node 0 [], Node 1 [], ..., Node 7 []]` (8 trees).
If failing, we have a minimal repro independent of the whole
compiler stack — much faster to iterate on.

### Second: drill `Data.Graph.scc`'s implementation

Find the source in 9.2.8's `base` or `containers`.  `scc` is
typically implemented as `dff' . graph . reverseEdges` or
similar.  Add hooks at each internal step.

### Third: confirm CONSTR_2_0 hypothesis

`Tree Vertex = Node Vertex [Tree Vertex]` is CONSTR_2_0.  The
`[Tree Vertex]` cons cells are also CONSTR_2_0.  Session 42
established that GC on PPC32 unreg corrupts CONSTR_2_0
closures.  Need to confirm with direct probe (e.g., peek at
the Forest's spine post-`scc` to detect when corruption
occurred).

### Fourth: hadrian-bypass test of `scc`

Compile a minimal test of `Data.Graph.scc` using the existing
host ghc (host-side test), and an existing stage2-on-pmacg5
build (target-side test).  If host passes but target fails,
the bug is in the target's RTS / GC.  If both fail, the bug is
in `Data.Graph.scc`'s pure Haskell implementation (less likely).

### Fifth: file a GHC bug report

We have very tight localization.  Submit upstream as
"PPC32-unreg: `Data.Graph.scc` returns wrong output (fewer
trees than vertices) under `+RTS -A1m -G1`."

## Mechanics

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Write your scc-standalone test, e.g.
# /tmp/scc_test.hs on pmacg5.

# Cross-build:
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null
# Iterate as needed.
cd ../../..

# Trigger compile:
ssh -q pmacg5 "cd /tmp && rm -f scc_test.hi scc_test.o; \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c scc_test.hs +RTS -A1m -G1 -RTS"
```

## What NOT to redo

* **Don't hook anywhere in the renamer** (rnValBindsLHS /
  rnValBindsRHS / depAnalBinds) — all confirmed innocent.
* **Don't hook `depAnal` or `graphFromEdgedVertices`** — both
  confirmed innocent.
* **Don't hook `tcTopBinds`** — session 49 already proved
  innocence.
* **Don't drill the typechecker / desugarer / simplifier** —
  sessions 42-49 ruled all of those out.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real`
  is the clean v0.12.0+ rebuild (session-end-50 redeploy).

## Paste-into-fresh-session prompt

```
Context: session 50 of the GHC darwin8-ppc project ran four
probe iterations and tracked the corruption from
`rnValBindsRHS` → `depAnalBinds` → `depAnal` →
`stronglyConnCompG` → **`Data.Graph.scc` (Haskell base)**.

Probe50-v4's smoking-gun data (failing -A1m -G1):
- top-level: numbered_nodes=8, forest_len=3 (scc dropped 5 trees!)
- nested swap binding: numbered_nodes=1, forest_len=0 (scc
  returned [] from a 1-vertex graph!)

The corruption is in `scc` from `Data.Graph` (in the base
library).  `scc` builds a Forest of SCCs using mutable arrays
(ST monad).  Under PPC32 unreg + GC pressure (-A1m -G1), it
returns fewer trees than the input graph has vertices.

This is consistent with session 42's finding that PPC32-unreg
GC corrupts CONSTR_2_0 closures.  `Tree Vertex = Node Vertex
[Tree Vertex]` is CONSTR_2_0; `[Tree Vertex]` cons cells are
also CONSTR_2_0.

Pipeline chain across sessions 42-50:
- S42: simplTopBinds = 0-1.
- S43: core2core entry = 1-3.
- S44: deSugar final_prs = 3-6.
- S45: deSugar tcg_binds entry = 3-6.
- S46: hsc_typecheck_exit = 3-5.
- S47: tcRnSrcDecls output = 2-5.
- S48: tcTopBinds val_binds val_sigs OUTPUT = 2-3.
- S49: tcTopBinds INPUT = 2-3.
- S50: stronglyConnCompG forest_len = 0-3 (clean: 1, 8) —
  `Data.Graph.scc` IS the bug.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline tests 30 PASS, 4
FAIL_OUTPUT.

Read in order:
1. docs/sessions/2026-05-15-session-50-drill-rnValBindsRHS/HANDOFF.md
2. docs/sessions/2026-05-15-session-50-drill-rnValBindsRHS/README.md
3. docs/sessions/2026-05-15-session-50-drill-rnValBindsRHS/findings.md
4. docs/sessions/2026-05-15-session-50-drill-rnValBindsRHS/log.md

Top priority: isolate `Data.Graph.scc` in a standalone Haskell
program (load a known graph, call scc, print result, run on
pmacg5 with -A1m -G1).  If that reproduces the wrong-count
output, we have a minimal repro independent of GHC's compiler
internals.  Then drill `scc`'s implementation (it lives in
base / containers).

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide

When session 51 ends, write the next handoff at:
`docs/sessions/<DATE>-session-51-<slug>/HANDOFF.md`.
