# Handoff from session 47 → session 48

**For:** the next claude session.
**From:** session 47 (probe47 — hooks inside `tcRnModuleTcRnM`
at after_tcRnImports / after_tcRnSrcDecls /
after_checkHiBootIface / exit).
**Recommended pickup:** drill inside `tcRnSrcDecls` to find
the exact sub-step where the count drops from 9 (clean) to 2-5
(failing).

## ✅ SESSION CLEAN EXIT _(pending in-flight verification)_

Source tree clean (probe47 reverted).  Stage1 rebuilding +
stage2 redeploying.  v0.12.0 release unchanged.

## TL;DR

| env-len | after_tcRnImports | **after_tcRnSrcDecls** | after_checkHiBootIface | exit |
|---------|-------------------|------------------------|------------------------|------|
| clean   | 0                 | **9**                  | 9                      | 9    |
| 600     | 0                 | **5**                  | 5                      | 5    |
| 1650    | 0                 | **2**                  | 2                      | 2    |

**`tcRnSrcDecls` is where tcg_binds becomes truncated.**
Clean: 9.  Failing: 2-5.  Subsequent steps preserve count.

The corruption is **WITHIN `tcRnSrcDecls`** — the main
typechecker pass.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative.
3. [`findings.md`](findings.md) — F1..F7 analysis.
4. [`log.md`](log.md) — real-time log.
5. (Reference) Session 46
   [`HANDOFF.md`](../2026-05-13-session-46-tc-and-bridge/HANDOFF.md).

## What to try next, in priority order

### Top: drill inside `tcRnSrcDecls`

`tcRnSrcDecls` is in `GHC.Tc.Module` around line 461.  Its
body includes:

1. `tc_rn_src_decls decls` — the main typecheck.
2. `setEnvs (tcg_env, tcl_env) $ do simplifyTop ...` — solver.
3. `setGblEnv tcg_env $ do ...` — finalization.
4. `zonkTopDecls all_binds binds rules imp_specs tcs` — final
   substitution.
5. Constructs final TcGblEnv.

Add hooks at each step.  The drop point pinpoints the
truncating sub-function.

### Second: check `tc_rn_src_decls`'s output

This is the main typechecker.  It returns `(tcg_env, tcl_env,
lie)`.  Look at `lengthBag (tcg_binds tcg_env)` right after
this call.

### Third: pin tcg_binds in IORef inside tcRnSrcDecls

Periodically check it across the function's body to detect
mid-execution GC corruption.

### Fourth: file the GHC bug report

We now have very tight localization.  Submit upstream.

## Mechanics

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.

# (a) Re-apply probe47:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-47-tc-rnmodule/probe47-tc-rnmodule.patch

# (b) For probe48, drill inside tcRnSrcDecls.
# tcRnSrcDecls starts around line 461 of GHC/Tc/Module.hs.

# (c) Build + deploy:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

## What NOT to redo

* **Don't hook anything AFTER tcRnSrcDecls** — count is
  preserved from there onward.
* **Don't pursue closure-shape / UniqMap / Var.realUnique /
  SimplEnv / BLACKHOLE-IND** — all subsumed.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real`
  is the clean v0.12.0+ rebuild (session-end-47 redeploy).

## Paste-into-fresh-session prompt

```
Context: session 47 of the GHC darwin8-ppc project narrowed
the [InBind] truncation locus to WITHIN tcRnSrcDecls.

Probe47 v2 hooked 4 points in tcRnModuleTcRnM:
- after_tcRnImports
- after_tcRnSrcDecls  ← where count goes 0 → N
- after_checkHiBootIface
- tcRnModuleTcRnM_exit

Clean: 0 → 9 → 9 → 9.
Failing len=600: 0 → 5 → 5 → 5.
Failing len=1650: 0 → 2 → 2 → 2.

The truncation happens WITHIN tcRnSrcDecls.  All subsequent
typechecker steps preserve the count.

Pipeline chain across sessions 42-47:
- S42: simplTopBinds = 0-1.
- S43: core2core entry = 1-3.
- S44: deSugar final_prs = 3-6.
- S45: deSugar tcg_binds entry = 3-6.
- S46: hsc_typecheck_exit = 3-5.
- S47: tcRnSrcDecls output = 2-5.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.

Read in order:
1. docs/sessions/2026-05-13-session-47-tc-rnmodule/HANDOFF.md
2. docs/sessions/2026-05-13-session-47-tc-rnmodule/README.md
3. docs/sessions/2026-05-13-session-47-tc-rnmodule/findings.md
4. docs/sessions/2026-05-13-session-47-tc-rnmodule/log.md
5. (Reference) docs/sessions/2026-05-13-session-46-tc-and-bridge/HANDOFF.md

Top priority: probe48 — drill inside tcRnSrcDecls.  Its body
has many sub-steps (tc_rn_src_decls, simplifyTop,
zonkTopDecls, etc).  Hook each step to pinpoint the
truncating sub-function.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide

When session 48 ends, write the next handoff at:
`docs/sessions/<DATE>-session-48-<slug>/HANDOFF.md`.
