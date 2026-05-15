# Session 50 commits

(SHA backfilled after commit lands.)

- `e072c93` — Session 50: probe50 in four iterations narrowed the
  truncation locus from `rnValBindsRHS` (renamer) down to
  `Data.Graph.scc` in the Haskell base library.  v1 hooked
  `rnValBindsLHS` / `rnValBindsRHS`; v2 drilled `depAnalBinds`;
  v3 drilled `depAnal`; v4 drilled
  `stronglyConnCompG` / `graphFromEdgedVertices`.  Final
  finding: `scc` receives a Graph with N vertices and returns
  a Forest with fewer trees (in dramatic cases: 0 trees from
  a 1-vertex graph) under PPC32 unreg with `+RTS -A1m -G1`.

No GHC source-tree changes land in this commit (all probes
reverted, source tree clean).  Only session notes + patch
artifact + trigger scripts + logs.
