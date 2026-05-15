# Session 49 commits

(SHA backfilled after commit lands.)

- `<TBD>` — Session 49: probe49-v1 (13 hooks in
  `compiler/GHC/Tc/Gen/Bind.hs`) shows the input list arriving at
  `tcTopBinds` is already truncated to 2-3 binders.  Corruption is
  UPSTREAM of the typechecker — in the renamer
  (`rnValBindsRHS` / `depAnalBinds` in
  `compiler/GHC/Rename/Bind.hs`) or earlier.  Overturns session 48.

No GHC source-tree changes land in this commit (probe reverted,
source tree clean).  Only session notes + patch artifact +
trigger script + logs.
