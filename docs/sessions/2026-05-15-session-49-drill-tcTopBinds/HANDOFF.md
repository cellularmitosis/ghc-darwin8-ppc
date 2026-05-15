# Handoff from session 49 → session 50

**For:** the next claude session.
**From:** session 49 (probe49-v1 — 13 hooks inside
`tcTopBinds`, `tcValBinds`, `tcBindGroups`, `tc_group`).
**Recommended pickup:** drill inside `rnValBindsRHS` in
`compiler/GHC/Rename/Bind.hs` to find where the renamer
truncates the `Bag (LHsBind GhcRn, [Name], Uses)`.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe49 reverted).  Stage1 rebuilt clean,
stage2 redeployed clean, smoke-test PASS, baseline tests
matched session-48 noise floor (30 PASS, 4 FAIL_OUTPUT).
v0.12.0 release unchanged.

## TL;DR — session 49 overturned session 48

| evt | site                      | clean | len=600 | len=1650 |
|-----|---------------------------|-------|---------|----------|
| 1   | **`tcTopBinds_entry_total`**  | **8** | **2** | **3** |
| 2   | **`tcTopBinds_entry_groups`** | **8** | **2** | **2** |
| 56  | `tcTopBinds_after_tcValBinds` | 8     | 2     | 2     |

**The input list `val_binds` arriving at `tcTopBinds` is
already short.**  `tcTopBinds`, `tcValBinds`, `tcBindGroups`,
and `tc_group` faithfully process whatever input they receive.
The corruption is **BEFORE `tcTopBinds`** — in the renamer
that builds the `HsGroup`'s `hs_valds` field.

The len=1650 case showed a fake Recursive group of size 2
where `Big2.hs` has no mutually recursive bindings → strong
hint that `depAnal`'s `(defs, uses)` triples are getting
their fields garbled by GC.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative.
3. [`findings.md`](findings.md) — F1..F7 analysis.
4. [`log.md`](log.md) — real-time log.
5. (Reference) Session 48
   [`HANDOFF.md`](../2026-05-14-session-48-drill-tcRnSrcDecls/HANDOFF.md).
6. (Reference) Session 47
   [`HANDOFF.md`](../2026-05-13-session-47-tc-rnmodule/HANDOFF.md).

## What to try next, in priority order

### Top: drill `rnValBindsRHS` in `compiler/GHC/Rename/Bind.hs`

`rnValBindsRHS` is at line 298.  Its body:

```haskell
rnValBindsRHS ctxt (ValBinds _ mbinds sigs)
  = do { (sigs', sig_fvs) <- renameSigs ctxt sigs
       ; binds_w_dus <- mapBagM (rnLBind (mkScopedTvFn sigs')) mbinds
       ; let !(anal_binds, anal_dus) = depAnalBinds binds_w_dus
       …
       ; return (XValBindsLR (NValBinds anal_binds sigs'), valbind'_dus) }
```

Add hooks:

1. `rnValBindsRHS_in_mbinds`     = `lengthBag mbinds` at entry.
2. `rnValBindsRHS_after_mapBagM` = `lengthBag binds_w_dus` after `mapBagM`.
3. `rnValBindsRHS_after_depAnal_groups` = `length anal_binds`.
4. `rnValBindsRHS_after_depAnal_total`  = total binders in anal_binds.

If (1) is 8 in clean and 2-3 in failing → bug is in the
parser, not the renamer.  Drill upstream into `Parser.y`.

If (1) is 8 in both but (2) is 8 / 2-3 → bug is in
`mapBagM rnLBind` (i.e., in renamer iteration, possibly the
Bag implementation itself).

If (2) is 8 in both but (3) / (4) is 8 / 2-3 → bug is in
`depAnalBinds` / `depAnal`'s SCC computation.

### Second: per-binding log inside `mapBagM rnLBind`

If (2) is where the count drops, add a hook inside
`rnLBind`'s body (or wrap the function passed to `mapBagM`).
Log `lengthBag mbinds_remaining` each call.  If we see all 8
calls but the OUTPUT Bag is short, the writer is dropping
entries.  If we see only K calls, the iterator is
short-circuiting.

### Third: hook `depAnal`'s output

`depAnalBinds` calls `depAnal` (from `GHC.Data.Graph.Directed`)
on `bagToList binds_w_dus`.  Hook:
- `length (bagToList binds_w_dus)` before depAnal.
- `length sccs` after depAnal.

### Fourth: file a GHC bug report

We have very tight localization now.  Submit upstream as
"PPC32-unreg GC corrupts the renamed-bindings Bag during
`rnValBindsRHS`'s `mapBagM rnLBind` iteration; reproducible at
small source sizes with `-A1m -G1`."

## Mechanics

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Apply your probe50 patch to
# compiler/GHC/Rename/Bind.hs (NOT Bind.hs in Tc/Gen this time).

cd external/ghc-modern/ghc-9.2.8
# Edit compiler/GHC/Rename/Bind.hs to add hooks.
# (Don't forget to import Data.IORef, System.IO,
#  System.IO.Unsafe.)

# Build:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Trigger compiles:
```bash
echo "=== clean (-A256m) ==="
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A256m -RTS 2>&1; echo RC=\$?" \
  | grep -E "PROBE|RC="

echo "=== failing len=600 ==="
pad=$(awk 'BEGIN{for(i=1;i<=598;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; echo RC=\$?" \
  | grep -E "PROBE|panic|RC="
```

(The `Big2.hs` test source on pmacg5 has 8 top-level value
bindings: freqMap, topK, dedup, countOf, shift, scaleAndShift,
allPositive, cumsum.)

## What NOT to redo

* **Don't hook inside `tcTopBinds` / `tcValBinds` /
  `tcBindGroups` / `tc_group`** — they are innocent; they
  process the truncated input list correctly.  Session 49
  proved this.
* **Don't drill `tcTyClsInstDecls`** — 0 binders in both
  clean and failing for `Big2.hs`.
* **Don't drill `mkTypeableBinds`** — it adds exactly +1
  regardless of failure mode.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real`
  is the clean v0.12.0+ rebuild (session-end-49 redeploy).

## Paste-into-fresh-session prompt

```
Context: session 49 of the GHC darwin8-ppc project overturned
session 48's localization.  Session 48 thought corruption was
INSIDE `tcTopBinds val_binds val_sigs`.  Session 49 added a
hook that measured the INPUT to `tcTopBinds` and found the
input list is ALREADY short (2-3 entries in failing vs 8 in
clean).

So the truncation is UPSTREAM of `tcTopBinds`, in the renamer
that builds the `HsGroup`'s `hs_valds` field.  Most likely
inside `compiler/GHC/Rename/Bind.hs`'s `rnValBindsRHS`
(line 298), specifically the `mapBagM (rnLBind …) mbinds`
step or the subsequent `depAnalBinds` call.

The len=1650 failing case showed `[(NonRec, 1 binder),
(Rec, 2 binders)]` — a fake Recursive group of size 2 where
`Big2.hs` has no mutually recursive bindings.  This hints at
structural pointer corruption in the `(LHsBind, [Name],
Uses)` triples that `depAnal` consumes.

Pipeline chain across sessions 42-49:
- S42: simplTopBinds = 0-1.
- S43: core2core entry = 1-3.
- S44: deSugar final_prs = 3-6.
- S45: deSugar tcg_binds entry = 3-6.
- S46: hsc_typecheck_exit = 3-5.
- S47: tcRnSrcDecls output = 2-5.
- S48: tcTopBinds val_binds val_sigs OUTPUT = 2-3.
- S49: tcTopBinds INPUT = 2-3 (8 clean) — locus is UPSTREAM of typechecker.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline tests 30 PASS, 4
FAIL_OUTPUT — matches session-48 noise floor.

Read in order:
1. docs/sessions/2026-05-15-session-49-drill-tcTopBinds/HANDOFF.md
2. docs/sessions/2026-05-15-session-49-drill-tcTopBinds/README.md
3. docs/sessions/2026-05-15-session-49-drill-tcTopBinds/findings.md
4. docs/sessions/2026-05-15-session-49-drill-tcTopBinds/log.md
5. (Reference) docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/HANDOFF.md

Top priority: probe50 — drill inside `rnValBindsRHS` in
`compiler/GHC/Rename/Bind.hs:298`.  Hook (1) `lengthBag mbinds`
at entry, (2) `lengthBag binds_w_dus` after `mapBagM rnLBind`,
(3) `length anal_binds` after `depAnalBinds`.  Add per-binding
log inside `mapBagM rnLBind` if (2) is where the count drops.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide

When session 50 ends, write the next handoff at:
`docs/sessions/<DATE>-session-50-<slug>/HANDOFF.md`.
