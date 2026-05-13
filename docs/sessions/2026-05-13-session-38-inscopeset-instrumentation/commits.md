# Session 38 commits

- f3d776e Session 38: probe38
  instruments `compiler/GHC/Core/Opt/Simplify/Env.hs` with three
  silent-on-happy-path diagnostics — (A) `refineFromInScope`
  panic-site full dump of the InScopeSet contents + size +
  per-element name(uniqueKey) + `lookupInScope_Directly`
  cross-check, (B) `addNewInScopeIds` self-validation that all
  inserted vars are post-extension `elemInScopeSet`, (C)
  `setInScopeSet`/`setInScopeFromE`/`setInScopeFromF` shrink-
  detection wrappers.  Built stage1 (11m35s) + deployed stage2 to
  pmacg5 + smoke-test PASS.  Swept Big2.hs `+RTS -A1m -G1` across
  env-lens 600..2000 step 25 (8 refineFromInScope panics) and ran
  determinism + nursery-size sensitivity studies.  **Findings:**
  (1) `PROBE38-ADDLOST` never fires — insertion is correct;
  (2) `PROBE38-SHRINK` never fires — replacement never reduces the
  set's size; (3) the InScopeSet at the panic site contains
  coherent Var entries with the **right OccName** at the binding
  site (`$dOrd(0x610013f7)` at env-lens 825..925) — but the
  expression at the use site has a **different raw Unique** for
  the same OccName (`$dOrd(0x61001418)`, delta=33).  Determinism
  check: 3 consecutive runs at len=850 produce identical Uniques.
  Nursery sweep at len=850 shows the victim Var rotates with `-A`:
  -A1m → `$dOrd`, -A2m → `$dEq`, -A8m → `ds_d1lr` (a let-binding,
  not a dictionary), -A32m → `$dFoldable`; **-A16m produces a
  clean compile**, confirming GC-frequency-sensitive triggering.
  **Major refinement to session 28's framing:** the UniqFM/IntMap
  is not corrupted; **the Var heap closures' `realUnique :: FastInt#`
  fields are corrupted by GC on PPC32 unreg**, which manifests as
  failed Unique-keyed lookups in whichever UniqMap-backed structure
  (InScopeSet, depSortStgBinds adjacency, TC GlobalRdrEnv) first
  queries one of the corrupted Vars.  v0.12.0 ships unchanged;
  probe applied for measurement only and reverted at session end;
  stage2 on pmacg5 rebuilt+redeployed clean + smoke-test PASS.
