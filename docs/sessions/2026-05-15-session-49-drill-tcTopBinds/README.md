# Session 49 — corruption is **BEFORE `tcTopBinds`** — in the renamer

**Date:** 2026-05-15 (continuation of session 48; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-48 exit.
Stage1 + stage2 redeployed clean.  Baseline tests at the
session-47 noise floor (30 PASS, 4 FAIL_OUTPUT — all
test-design issues).  Session 48 narrowed the truncation locus
to "inside `tcTopBinds val_binds val_sigs`" based on the
output count.

**Status on exit:** CLEAN.  Probe49 reverted, stage1 rebuilt
clean, stage2 redeployed, smoke-test PASS, baseline tests run.
**Finding:** Probe49-v1 added 13 hook sites inside
`compiler/GHC/Tc/Gen/Bind.hs` and measured both the INPUT and
OUTPUT of `tcTopBinds`, plus per-group recursion.  **The input
`val_binds` list arriving at `tcTopBinds` is already truncated
(2-3 binders vs 8 clean).**  Session 48's conclusion is
overturned: `tcTopBinds` is innocent.  The corruption is
**upstream of the typechecker — in the renamer**
(`rnValBindsRHS` / `depAnalBinds` in `compiler/GHC/Rename/Bind.hs`)
or earlier.

## Plan (per session 48 HANDOFF)

Drill INSIDE `tcTopBinds` to find which sub-step (the
recursion / fold / `tcValBinds` / `tcBindGroups`) loses
binders.

## What happened

### Phase 1 — probe49-v1 (13 hooks in `Bind.hs`)

Added the following hook sites:
- `tcTopBinds`: entry (groups + total), after `tcValBinds`.
- `tcValBinds`: entry, after `tcBindGroups`, exit.
- `tcBindGroups`: per-iter in_groupsize / in_remaining /
  out_groupsize; base-case `recursion_done`.
- `tc_group`: per-call NonRecursive in/out, Recursive in/out.

Patch: [`probe49-tcTopBinds.patch`](probe49-tcTopBinds.patch)
(134 lines, single file).

Build: [`logs/build1-probe49v1.log`](logs/build1-probe49v1.log)
(7m46s, EXIT=0).
Deploy: [`logs/deploy1-probe49v1.log`](logs/deploy1-probe49v1.log)
(smoke-test PASS).
Triggers: [`logs/v1-triggers.log`](logs/v1-triggers.log)
(128 lines: clean + len=600 + len=1650).

### Phase 2 — result

| evt | site                       | clean | len=600 | len=1650 |
|-----|----------------------------|-------|---------|----------|
| 1   | `tcTopBinds_entry_total`   | **8** | **2**   | **3**    |
| 2   | `tcTopBinds_entry_groups`  | **8** | **2**   | **2**    |
| …   | per-group recursion        | 8x1   | 2x1     | 1x1+1x2  |
|     | `tcTopBinds_after_tcValBinds` | 8   | 2       | 2        |

**The input list is already short**: `tcTopBinds` is being
called with 2-3 binders, not 8.  `tcTopBinds` then faithfully
typechecks whatever it got.  That's why session 48 saw 2-3 in
`tcg_binds` after `tcTopBinds`.

The len=1650 case is particularly telling: 1 NonRecursive
group (size 1) + 1 Recursive group (size 2).  `Big2.hs` has no
mutually recursive bindings — a Rec group of size 2 means
`depAnal`'s SCC algorithm detected a fake cycle.  That's
structural corruption: the `(LHsBind, [Name], Uses)` triples
fed to `depAnal` have garbled `defs` / `uses` fields, causing
two unrelated binders to be linked as mutually recursive.

### Phase 3 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Tc/Gen/Bind.hs` — probe reverted.
* Stage1 clean rebuild: [`logs/build2-clean.log`](logs/build2-clean.log).
* Stage2 redeploy: [`logs/deploy2-clean.log`](logs/deploy2-clean.log).
* Baseline tests: [`logs/baseline-tests-end.log`](logs/baseline-tests-end.log).

Session ends CLEAN.

## Files added this session

* `README.md` (this), `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md`.
* `probe49-tcTopBinds.patch` — the cumulative v1 patch (13 hooks).
* `scripts/run-triggers.sh` — runs the three triggers and
  captures `PROBE49` lines.
* `logs/baseline-tests-start.log`,
  `logs/build1-probe49v1.log`, `logs/deploy1-probe49v1.log`,
  `logs/v1-triggers.log`,
  `logs/build2-clean.log`, `logs/deploy2-clean.log`,
  `logs/baseline-tests-end.log`.

## Top finding

The truncation is **upstream of the typechecker**.  The
`HsGroup`'s `hs_valds` field — built by the renamer — is
already short when it arrives at `tcTopSrcDecls`.

Session 50 should drill INSIDE `compiler/GHC/Rename/Bind.hs`'s
`rnValBindsRHS` (line 298) → `mapBagM rnLBind` (line 304) →
`depAnalBinds` (line 570).  The most likely culprit is GC
corruption during the `mapBagM rnLBind` iteration that copies
each binding's triple.

See [`findings.md`](findings.md) §F5 for the next-session
hook plan, and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
