# Handoff from session 48 → session 49

**For:** the next claude session.
**From:** session 48 (probe48-v3 — 10 hooks across
`tcRnSrcDecls`, `tc_rn_src_decls`, and `tcTopSrcDecls`).
**Recommended pickup:** drill inside `tcTopBinds` in
`compiler/GHC/Tc/Gen/Bind.hs` to find the exact loop /
recursion / fold step where the binder count is short-counted
from 8 to 2-3.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe48 reverted).  Stage1 rebuilt clean,
stage2 redeployed clean, smoke-test PASS, baseline tests
matched session-47 noise floor.  v0.12.0 release unchanged.

## TL;DR

| evt | site                              | clean | len=600 | len=1650 |
|-----|------------------------------------|-------|---------|----------|
| 2   | `after_tcTyClsInstDecls`           | 0     | 0       | 0        |
| **3** | **`after_tcTopBinds_val_binds`** | **8** | **2**   | **3**    |
| 5   | `after_tcTopSrcDecls`              | 8     | 2       | 3        |
| 7   | `after_mkTypeableBinds`            | 9     | 3       | 4        |

**`tcTopBinds val_binds val_sigs` is where `tcg_binds` becomes
truncated.**  Clean: 8.  Failing: 2-3.  All subsequent
typechecker / desugarer / simplifier / codegen steps preserve
that count.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative (v1 → v2 →
   v2.5 → v3).
3. [`findings.md`](findings.md) — F1..F9 analysis.
4. [`log.md`](log.md) — real-time log.
5. [`CONTINUATION.md`](CONTINUATION.md) — mid-session handoff
   that handed v3 to a fresh conversation.
6. (Reference) Session 47
   [`HANDOFF.md`](../2026-05-13-session-47-tc-rnmodule/HANDOFF.md).

## What to try next, in priority order

### Top: drill inside `tcTopBinds`

`tcTopBinds` is in `compiler/GHC/Tc/Gen/Bind.hs`.  It takes:

- `val_binds :: [(RecFlag, LHsBinds GhcRn)]`
- `val_sigs :: [LSig GhcRn]`

…and returns `(TcGblEnv, TcLclEnv)` where `tcg_binds` has been
populated.

Sub-steps to probe (look at the implementation in
`compiler/GHC/Tc/Gen/Bind.hs`):

1. `tcValBinds` / `tcBindGroups` — the recursive loop over
   binding groups.
2. The fold that extends `tcg_binds` in `TcGblEnv`.
3. `tcMonoBinds` / `tcPolyBinds` — typecheck individual
   bindings.

### Second: per-binder log

Add a PROBE line per binder typechecked.  If we see "binder 1,
2, 3, ... 8" in clean and "binder 1, 2, 3" in failing, the
recursion is short-circuiting — possibly because the input
list is being truncated by GC, or because an early return is
firing.  If we see all 8 in both runs but the COUNT drops only
at the end, the in-progress bag is being lopped wholesale.

### Third: pin a `tcg_binds` IORef snapshot

Capture `lengthBag (tcg_binds env)` after every binder
processed.  Detect the precise moment the count goes wrong.

### Fourth: file a GHC bug report

We have very tight localization now.  Submit upstream as
"PPC32-unreg GC corrupts in-progress binders bag during
tcTopBinds; reproducible at small source sizes with
`-A1m -G1`."

## Mechanics

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Apply your probe49 patch to
# compiler/GHC/Tc/Gen/Bind.hs (NOT Module.hs this time).

cd external/ghc-modern/ghc-9.2.8
# Edit compiler/GHC/Tc/Gen/Bind.hs to add hooks.
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

## What NOT to redo

* **Don't hook anything AFTER `tcTopBinds val_binds val_sigs`** —
  count is preserved from there onward through the entire
  pipeline.
* **Don't pursue closure-shape / UniqMap / Var.realUnique /
  SimplEnv / BLACKHOLE-IND** — all subsumed.
* **Don't drill `tcTyClsInstDecls`** — it's 0 in both clean
  and failing for our test module.
* **Don't drill `mkTypeableBinds`** — it adds exactly +1
  regardless of failure mode.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real`
  is the clean v0.12.0+ rebuild (session-end-48 redeploy,
  mtime 2026-05-14 01:51).

## Paste-into-fresh-session prompt

```
Context: session 48 of the GHC darwin8-ppc project narrowed
the [InBind] truncation locus to WITHIN
`tcTopBinds val_binds val_sigs` (in GHC.Tc.Gen.Bind).

Probe48-v3 hooked 10 points across tcRnSrcDecls /
tc_rn_src_decls / tcTopSrcDecls:
- after_rnTopSrcDecls            = 0 (renamer; no binds)
- after_tcTyClsInstDecls         = 0 (no class/inst decls)
- after_tcTopBinds_val_binds     ← TRUNCATION HERE
- after_tcTopBinds_deriv_binds
- after_tcTopSrcDecls
- after_tc_rn_src_decls
- after_mkTypeableBinds          (+1 for $trModule)
- after_zonkTcGblEnv_binds_prime
- tcg_env_prime_final
- binds_mf_after_zonk_main

Clean: 0/0/8/8/8/8/9/9/9/0.
Failing len=600: 0/0/2/2/2/2/3/3/3/0.
Failing len=1650: 0/0/3/3/3/3/4/4/4/0.

The truncation happens WITHIN tcTopBinds val_binds val_sigs.
All other typechecker steps preserve the count.

Pipeline chain across sessions 42-48:
- S42: simplTopBinds = 0-1.
- S43: core2core entry = 1-3.
- S44: deSugar final_prs = 3-6.
- S45: deSugar tcg_binds entry = 3-6.
- S46: hsc_typecheck_exit = 3-5.
- S47: tcRnSrcDecls output = 2-5.
- S48: tcTopBinds val_binds val_sigs output = 2-3 (+1 from mkTypeable → 3-4).

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.

Read in order:
1. docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/HANDOFF.md
2. docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/README.md
3. docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/findings.md
4. docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/log.md
5. (Reference) docs/sessions/2026-05-13-session-47-tc-rnmodule/HANDOFF.md

Top priority: probe49 — drill inside tcTopBinds (in
compiler/GHC/Tc/Gen/Bind.hs).  Hook each major sub-step:
tcValBinds, tcBindGroups, the fold extending tcg_binds, and
tcMonoBinds/tcPolyBinds.  Add per-binder logging to detect
whether the input list is short or the bag is being lopped.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide

When session 49 ends, write the next handoff at:
`docs/sessions/<DATE>-session-49-<slug>/HANDOFF.md`.
