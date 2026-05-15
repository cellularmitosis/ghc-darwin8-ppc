# Session 49 log

## 2026-05-15 — session start

- Read HANDOFF.md, README.md, findings.md from session 48.
- Confirmed source tree clean at `compiler/GHC/Tc/Gen/Bind.hs`
  and `compiler/GHC/Tc/Module.hs`.  Stage2 on pmacg5 is the
  end-of-session-48 clean rebuild.
- Inspected `tcTopBinds` (lines 176-201), `tcValBinds`
  (lines 301-335), `tcBindGroups` (lines 338-358), `tc_group`
  (lines 387-432) in `compiler/GHC/Tc/Gen/Bind.hs`.
  `GHC.Data.Bag` is already imported (line 63), so `lengthBag`
  is available.

## Probe49-v1 design

Hook the major sub-steps inside `tcTopBinds` to identify
whether truncation is at:
- INPUT to `tcTopBinds` (upstream corruption);
- INSIDE `tcValBinds` → `tcBindGroups` recursion (per-group
  short circuit);
- the final `addTypecheckedBinds` step in `tcTopBinds`'s body.

Hooks (13 sites):

| evt | site                                       |
|-----|--------------------------------------------|
| - | `tcTopBinds_entry_groups`                    |
| - | `tcTopBinds_entry_total`                     |
| - | `tcTopBinds_after_tcValBinds`                |
| - | `tcValBinds_entry_total`                     |
| - | `tcValBinds_after_tcBindGroups`              |
| - | `tcValBinds_exit_total`                      |
| - | `tcBindGroups_in_groupsize` (per-iter)       |
| - | `tcBindGroups_in_remaining` (per-iter)       |
| - | `tcBindGroups_out_groupsize` (per-iter)      |
| - | `tcBindGroups_recursion_done` (base case)    |
| - | `tc_group_nonrec_in` / `_out`                |
| - | `tc_group_rec_in` / `_out`                   |

Helper:
- `probe49Log :: String -> Int -> ()` (single `IORef` counter,
  `unsafePerformIO`, hPutStrLn stderr).
- `probe49TotalBinders :: [(RecFlag, LHsBinds p)] -> Int`
  (sums `lengthBag . snd` over the list).

Patch artifact:
[`probe49-tcTopBinds.patch`](probe49-tcTopBinds.patch).

## Build, deploy, triggers

- Build: 7m46s, EXIT=0
  ([`logs/build1-probe49v1.log`](logs/build1-probe49v1.log)).
- Deploy: smoke-test PASS
  ([`logs/deploy1-probe49v1.log`](logs/deploy1-probe49v1.log)).
- Triggers (clean -A256m, len=600 -A1m -G1, len=1650 -A1m -G1):
  [`logs/v1-triggers.log`](logs/v1-triggers.log).

## Top finding

**The input list to `tcTopBinds` is already truncated.**

Clean: `tcTopBinds_entry_groups=8`, `entry_total=8`.
Failing len=600: `entry_groups=2`, `entry_total=2`.
Failing len=1650: `entry_groups=2`, `entry_total=3`.

The recursion through `tcBindGroups` walks each group
correctly and produces a correctly-typechecked output.  The
output `tcg_binds` is 2-3 only because the input was already
that short.

len=1650 specifically produced 1 NonRec (size 1) + 1 Rec
(size 2).  `Big2.hs` has no mutually recursive bindings — the
Rec group of size 2 means `depAnal` saw a phantom cycle, which
points at corrupted `(defs, uses)` fields in the
`(LHsBind, [Name], Uses)` triples.

## Re-localization

`val_binds` arrives at `tcTopBinds` via:

```
tcTopSrcDecls (HsGroup { …
                       , hs_valds  = hs_val_binds@(XValBindsLR (NValBinds val_binds val_sigs)) })
```

The `HsGroup` is built by `rnSrcDecls` (in
`compiler/GHC/Rename/Module.hs:96`) which calls
`rnValBindsRHS` (in `compiler/GHC/Rename/Bind.hs:298`).
The list `val_binds = anal_binds` is the output of
`depAnalBinds binds_w_dus` (line 305 of Rename/Bind.hs).

Session 50 should drill `rnValBindsRHS`:
- Hook 1: `lengthBag mbinds` at entry.
- Hook 2: `lengthBag binds_w_dus` after `mapBagM rnLBind`.
- Hook 3: `length anal_binds` after `depAnalBinds`.

This will pinpoint whether the corruption is in the parser
(mbinds short on entry), the `mapBagM rnLBind` step (Bag
copy/iterate), or `depAnal`.

## Revert + clean rebuild + redeploy

- `git checkout -- compiler/GHC/Tc/Gen/Bind.hs` — probe reverted.
- Stage1 clean rebuild:
  [`logs/build2-clean.log`](logs/build2-clean.log).
- Stage2 redeploy:
  [`logs/deploy2-clean.log`](logs/deploy2-clean.log).
- Baseline tests:
  [`logs/baseline-tests-end.log`](logs/baseline-tests-end.log).

Session ends CLEAN.
