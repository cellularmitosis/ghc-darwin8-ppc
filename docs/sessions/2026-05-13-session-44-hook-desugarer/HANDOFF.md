# Handoff from session 44 → session 45

**For:** the next claude session.
**From:** session 44 (probe44 — hook `HsToCore.deSugar`
return).
**Recommended pickup:** hook MORE granularly inside `deSugar`
to find which specific step truncates the list.

## ✅ SESSION CLEAN EXIT _(pending in-flight verification)_

Source tree clean (probe44 reverted).  Stage1 rebuilding +
stage2 redeploying.  v0.12.0 release unchanged.

## TL;DR

Probe44 logs three lengths at `deSugar`'s return:
- `final_prs` (desugarer's main output before simpleOptPgm).
- `ds_binds` (post-simpleOptPgm).
- `mg_binds` (in ModGuts).

| env-len | final_prs | ds_binds | mg_binds | outcome |
|---------|-----------|----------|----------|---------|
| clean   | 9         | 9        | 9        | proper |
| 600     | **3**     | **0**    | **0**    | silent miscompile |
| 850     | 6         | 4        | 4        | panic |
| 1650    | 5         | 3        | 3        | panic |

**`final_prs` is already truncated in failing runs.**  The
corruption is WITHIN or BEFORE the desugarer's main
computation.

`simpleOptPgm` further drops binders (legitimate DCE on broken
input).

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative + the data table.
3. [`findings.md`](findings.md) — F1..F9 analysis with
   detailed interpretation of where in deSugar the truncation
   could happen.
4. [`log.md`](log.md) — real-time work log.
5. (Reference) Session 43
   [`HANDOFF.md`](../2026-05-13-session-43-trace-pipeline-binds/HANDOFF.md).

## What to try next, in priority order

### Top: granular probes inside deSugar

Hook each step within `deSugar`'s do-block:

```haskell
-- AT deSugar entry:
let !_p45_tcgbinds = probe45LogStep "tcg_binds" (length binds)

-- AFTER addTicksToBinds:
; let !_p45_cvr = probe45LogStep "binds_cvr" (length binds_cvr)

-- INSIDE initDs, AFTER dsTopLHsBinds:
do { ; core_prs <- dsTopLHsBinds binds_cvr
   ; let !_p45_core = probe45LogStep "core_prs" (length core_prs)
   ; ... }

-- AFTER concatOL into all_prs:
... `appOL` core_prs `appOL` spec_prs `appOL` ...
   then check `length (fromOL all_prs)`.

-- AT final_prs:
; let !_p45_final = probe45LogStep "final_prs" (length final_prs)
```

The drop point pinpoints which function corrupts the list.

### Second: hook tcg_binds GET point too

`tcg_binds` is the typechecker's output, passed into `deSugar`.
If `length tcg_binds` is already 3-6 in failing runs (vs 9 in
clean), the corruption is in the typechecker.  If `length
tcg_binds` is 9 but later steps drop it, the corruption is in
the desugarer.

### Third: investigate addTicksToBinds and dsTopLHsBinds

These are the main candidates for list-processing within
deSugar.  If the truncation localizes to one of them, audit
its implementation for any list operations that GC could
corrupt.

### Fourth: pin tcg_binds in IORef + check at intervals

Like probe39 for [LHsBinds].  Pin at deSugar entry, check
length at simpleOptPgm time.  If length drops between pin and
check, GC corrupted the heap-allocated list spine in transit.

## Mechanics — picking up where session 44 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-44 redeploy).

# (a) Re-apply probe44:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-44-hook-desugarer/probe44-desugar-hook.patch

# (b) For probe45 (granular per-step), extend HsToCore.hs.
# Helper goes inline (same pattern as probe44; can't import
# Simplify.Env from HsToCore).

# (c) Build + deploy + run:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# (d) Single trigger:
pad=$(awk 'BEGIN{for(i=1;i<=598;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
    DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1" | head -15
```

## What NOT to redo

* **Don't pursue closure-shape / UniqMap / Var.realUnique /
  SimplEnv / BLACKHOLE-IND theories** — all subsumed by the
  GC list-truncation finding.
* **Don't hook anything in `simplTopBinds` / `core2core` /
  `runCorePasses`** — by then the list is already broken.
  Earlier hooks are needed.
* **Don't put imports AFTER function definitions** — that's
  illegal Haskell (parse error).  All imports first.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-44 redeploy).
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Paste-into-fresh-session prompt

```
Context: session 44 of the GHC darwin8-ppc project ran probe44 —
a length tracer at HsToCore.deSugar's return, logging final_prs
(desugarer output), ds_binds (post-simpleOptPgm), and mg_binds.

Findings:
- Clean -A256m: final_prs=9, ds_binds=9, mg_binds=9.
- Failing -A1m -G1 len=600: final_prs=3, ds_binds=0, mg_binds=0,
  RC=0 (silent miscompile).
- Failing len=850: final_prs=6, ds_binds=4, mg_binds=4, panic.
- Failing len=1650: final_prs=5, ds_binds=3, mg_binds=3, panic.

**final_prs is already truncated in failing runs**.  The
corruption is WITHIN or BEFORE the desugarer's main
computation.  simpleOptPgm then drops binders further
(legitimate DCE on broken input).

The chain so far:
- Session 42: simplTopBinds receives 0-1 binders (vs 9 clean).
- Session 43: core2core receives 1-3 binders.
- Session 44: deSugar's final_prs is 3-6 binders.

Truncation candidates (within deSugar):
- addTicksToBinds (coverage)
- dsTopLHsBinds (main desugaring)
- patchMagicDefns / dsImpSpecs / dsForeigns / dsRule
- appOL / fromOL (OrdList ops)
- addExportFlagsAndRules
- OR the input tcg_binds (from typechecker)
- OR GC corrupting any heap list in this chain.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline 30 PASS / 4 FAIL_OUTPUT
unchanged.

Read in order:
1. docs/sessions/2026-05-13-session-44-hook-desugarer/HANDOFF.md
2. docs/sessions/2026-05-13-session-44-hook-desugarer/README.md
3. docs/sessions/2026-05-13-session-44-hook-desugarer/findings.md
4. docs/sessions/2026-05-13-session-44-hook-desugarer/log.md
5. (Reference) docs/sessions/2026-05-13-session-43-trace-pipeline-binds/HANDOFF.md

Top priority: probe45 — hook MORE granularly inside `deSugar`:
- length tcg_binds (input from typechecker, before addTicksToBinds)
- length binds_cvr (after addTicksToBinds)
- length core_prs (after dsTopLHsBinds)
- length all_prs (after concatOL)
- length final_prs (after addExportFlagsAndRules)

The drop point pinpoints which step truncates the list.

Helper goes inline in HsToCore.hs (Simplify.Env can't be
imported from there).  Put imports BEFORE function definitions
(probe44 v1 failed because I put them after).

Don't pursue: closure-shape / UniqMap / Var.realUnique /
SimplEnv field corruption / BLACKHOLE-IND.  All subsumed.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-44-hook-desugarer/HANDOFF.md`](docs/sessions/2026-05-13-session-44-hook-desugarer/HANDOFF.md).

When session 45 ends, write the next handoff at:
`docs/sessions/<DATE>-session-45-<slug>/HANDOFF.md`.
