# Handoff from session 45 → session 46

**For:** the next claude session.
**From:** session 45 (probe45 — 7 granular length hooks inside
`HsToCore.deSugar`).
**Recommended pickup:** hook the typechecker's output and/or
HscMain's bridging code to find whether `tcg_binds` is already
truncated at typechecker exit OR truncated in transit to
deSugar.

## ✅ SESSION CLEAN EXIT _(pending in-flight verification)_

Source tree clean (probe45 reverted).  Stage1 rebuilding +
stage2 redeploying.  v0.12.0 release unchanged.

## TL;DR

Probe45 logs binder counts at 7 points inside `deSugar`:

| step                      | clean | 600 | 850 | 1650 |
|---------------------------|-------|-----|-----|------|
| tcg_binds                 | 9     | 3   | 6   | 5    |
| binds_cvr                 | 9     | 3   | 6   | 5    |
| core_prs_initial          | 9     | 3   | 6   | 5    |
| core_prs_patched          | 9     | 3   | 6   | 5    |
| all_prs_in_initDs         | 9     | 3   | 6   | 5    |
| all_prs_outside_initDs    | 9     | 3   | 6   | 5    |
| final_prs                 | 9     | 3   | 6   | 5    |

**Every step preserves the count exactly.**  The desugarer
is innocent.  `tcg_binds` is already truncated when deSugar
receives it.

The corruption is in the typechecker, HscMain's bridge code,
or GC corruption of the heap-allocated Bag during transit.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative.
3. [`findings.md`](findings.md) — F1..F9 with the conclusive
   data table.
4. [`log.md`](log.md) — real-time log.
5. (Reference) Session 44
   [`HANDOFF.md`](../2026-05-13-session-44-hook-desugarer/HANDOFF.md).

## What to try next, in priority order

### Top: hook the typechecker's output

`TcGblEnv` is constructed in `compiler/GHC/Tc/Module.hs` or
similar.  Find the function that builds the final `TcGblEnv`
and hook it to dump `lengthBag (tcg_binds tcg_env)` at exit.

If clean=9 and failing=3-6 at typechecker exit, the bug is
in the typechecker itself (or upstream — renamer/parser).

If clean=9 and failing=9 at typechecker exit but =3-6 at
deSugar entry, the bug is in HscMain's bridging code or GC
corruption of the Bag during transit.

### Second: hook hscDesugar / Plugins.hscDesugar

`hscDesugar` (or whatever HscMain function calls `deSugar`)
is the bridge.  Find it and dump the Bag's length at its
entry.

### Third: pin tcg_binds in IORef at typechecker exit

Like sessions 39/41 sentinel-pinning, but on the Bag.  Pin
at typechecker exit, then check length at deSugar entry.  If
length drops between pin and check, GC corrupted the Bag in
transit.

### Fourth: inspect TwoBags closure layout on PPC32 unreg

`Bag a` has `TwoBags (Bag a) (Bag a)` — a CONSTR_2_0 closure.
This is structurally identical to a `[a]` cons cell (also
CONSTR_2_0).  The same GC bug that corrupts cons-list spines
would also corrupt TwoBags.  Inspect the PPC32 unreg
evac/scav handling of CONSTR_2_0.

### Fifth: file a GHC bug report

Conclusive evidence: GC on PPC32 unreg corrupts heap-allocated
CONSTR_2_0 closures.  Upstream maintainers should be able to
confirm and fix.

## Mechanics — picking up where session 45 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-45 redeploy).

# (a) Re-apply probe45 if you need to re-verify:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-45-granular-desugar/probe45-granular-desugar.patch

# (b) For probe46 (typechecker hook), find where TcGblEnv is
# constructed:
grep -rn "TcGblEnv {" compiler/GHC/Tc/Module.hs | head -5
# Add a hook there using the same pattern.

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

* **Don't hook anything INSIDE `deSugar`** — the desugarer is
  innocent.  Every step preserves the count.
* **Don't pursue closure-shape / UniqMap / Var.realUnique /
  SimplEnv / BLACKHOLE-IND theories** — all subsumed by the
  GC list-truncation finding.
* **Don't put imports AFTER function definitions** — illegal
  Haskell.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-45 redeploy).
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Paste-into-fresh-session prompt

```
Context: session 45 of the GHC darwin8-ppc project ran probe45
— 7 granular length hooks inside HsToCore.deSugar, logging
binder counts at tcg_binds, binds_cvr, core_prs_initial,
core_prs_patched, all_prs_in_initDs, all_prs_outside_initDs,
final_prs.

Findings:
- Clean -A256m: all 7 steps = 9.
- Failing -A1m -G1 len=600: all 7 steps = 3.
- Failing len=850: all 7 steps = 6.
- Failing len=1650: all 7 steps = 5.

**EVERY step preserves the count exactly.**  The desugarer is
INNOCENT.  tcg_binds is already truncated when deSugar
receives it.

The corruption is BEFORE deSugar — in one of:
- The typechecker's output construction.
- HscMain's bridging code (e.g., hscDesugar) between
  typechecker and deSugar.
- GC corruption of the heap-allocated Bag (LHsBindLR GhcTc
  GhcTc) during transit.

`Bag.TwoBags (Bag a) (Bag a)` is a CONSTR_2_0 closure — same
shape as `[a]` cons cells.  The same GC bug that corrupts
cons-list spines would also corrupt TwoBags.

Pipeline-wide progress so far:
- Session 42: simplTopBinds sees 0-1 binders.
- Session 43: core2core entry sees 1-3.
- Session 44: deSugar's final_prs is 3-6.
- Session 45: deSugar's tcg_binds (input) is 3-6.  Desugarer
  innocent.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline 30 PASS / 4 FAIL_OUTPUT
unchanged.

Read in order:
1. docs/sessions/2026-05-13-session-45-granular-desugar/HANDOFF.md
2. docs/sessions/2026-05-13-session-45-granular-desugar/README.md
3. docs/sessions/2026-05-13-session-45-granular-desugar/findings.md
4. docs/sessions/2026-05-13-session-45-granular-desugar/log.md
5. (Reference) docs/sessions/2026-05-13-session-44-hook-desugarer/HANDOFF.md

Top priority: probe46 — hook the typechecker's output
(GHC/Tc/Module.hs's TcGblEnv construction) and HscMain's
bridging code (hscDesugar in GHC/Driver/Main.hs).  Determine
whether the truncation is in the typechecker OR in transit
between typechecker and deSugar.

Don't pursue: closure-shape / UniqMap / Var.realUnique /
SimplEnv / BLACKHOLE-IND.  All subsumed.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-45-granular-desugar/HANDOFF.md`](docs/sessions/2026-05-13-session-45-granular-desugar/HANDOFF.md).

When session 46 ends, write the next handoff at:
`docs/sessions/<DATE>-session-46-<slug>/HANDOFF.md`.
