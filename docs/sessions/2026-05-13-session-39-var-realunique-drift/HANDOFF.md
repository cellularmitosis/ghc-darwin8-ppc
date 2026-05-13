# Handoff from session 39 → session 40

**For:** the next claude session.
**From:** session 39 (probe39 — sentinel Var tracking via IORef +
`varUnique` drift check).
**Recommended pickup:** investigate **where the duplicate Var
with the same OccName but different Unique is constructed** in
the pipeline upstream of the simplifier.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe39 reverted).  Stage1 rebuilt clean +
stage2 redeployed to pmacg5 + smoke-test PASS + baseline tests
30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged).  v0.12.0
release unchanged.

## TL;DR — the chain of dissolved framings continues

| Session | Framing                                              | Verdict          |
|---------|------------------------------------------------------|------------------|
| 33-36   | "v's heap closure shape is corrupt"                  | Dissolved by S37 |
| 28-38   | "UniqMap data structures are corrupted"              | Dissolved by S38 |
| 38      | "GC corrupts the `realUnique :: FastInt#` field of Var" | **Dissolved by S39** |
| 39      | "Two genuinely distinct Var objects exist with same OccName" | open             |

Probe39-v2/v3 took a sentinel `$dOrd_a1k0` Var with raw Unique
`0x610013f7`, pinned it to an IORef (keeping it live across GC),
and at every subsequent `refineFromInScope` call re-read its
`varUnique v` via GHC's Haskell-level accessor.  **The value
stays exactly `0x610013f7` every check.**  GC may move the
closure but does not rewrite its realUnique field.

The remaining hypothesis: **two distinct Var heap closures
exist with the same OccName "$dOrd_a1k0" but different
realUnique values**, neither of which drifts during the
simplifier's operation.  One is in the InScopeSet (at the
binding site); the other appears in the expression tree (at the
use site).

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative.
3. [`findings.md`](findings.md) — F1..F7 analysis with the
   probe39 data and "what's ruled out / still open" table.
4. [`log.md`](log.md) — real-time work log (v1 → v2 → v3
   iterations).
5. (Reference) Session 38
   [`HANDOFF.md`](../2026-05-13-session-38-inscopeset-instrumentation/HANDOFF.md)
   — what session 39 came in to verify (and disprove).
6. (Earlier reference) Session 37 + 28 HANDOFFs.

## What to try next, in priority order

### Top: trace expression-Var construction

The panic body shows `v=$dOrd(0x61001418)` (or `0x610013dc`) —
the Var being looked up at `refineFromInScope`.  Where was THIS
Var constructed?  Hypothesis: somewhere in the typechecker /
desugarer / specializer creates dictionaries, and the PPC32
build produces TWO Vars where the host produces one.

Concrete probe:

1. In `GHC.HsToCore.Match` / `GHC.Tc.Solver.Dict` /
   `GHC.Core.Opt.Specialise`, find every site that emits an Id
   for a typeclass dictionary.
2. Add a probe that records every constructed dictionary Id's
   `(Name, Unique, callstack)`.
3. Run Big2.hs `-A1m -G1` and look for duplicate `(Name)` keys
   in the recorded list.  If two records exist with the same
   Name but different Uniques, that's the divergence.

### Second: track `varName v` stability (not just `varUnique`)

If the SAME Var has its `varName :: Name` pointer rewritten by
GC such that a different Name table entry becomes attached, the
"OccName" pretty-print would change but the realUnique would
stay stable.  Like probe39 but tracking `varName v` over time.

Sketch:

```haskell
data Probe40Slot = Probe40Slot Var Word Word -- Var, initU, initNameAddr
{-# NOINLINE probe40Slot #-}
probe40Slot :: IORef (Maybe Probe40Slot)
...
probe40Check site = do
    Just (Probe40Slot v u0 nameAddr0) <- readIORef probe40Slot
    let u_now = getKey (varUnique v)
    nameAddr_now <- probe40AddressOf (varName v)
    when (u_now /= u0 || nameAddr_now /= nameAddr0) $ ...
```

### Third: dump pre-simplifier Core

Run Big2.hs `-A1m -G1 -ddump-tc -ddump-ds -ddump-simpl-iterations`
on PPC32 stage2 and on the host.  Find the first stage at which
`$dOrd_a1k0` appears with a divergent Unique.  This narrows down
which pipeline step is creating the duplicate.

### Fourth: confirm the bug doesn't reproduce on host

Build Big2.hs on uranium host ghc-9.2.8 with `+RTS -A1m -G1`.  If
it compiles clean (as expected), the bug is platform-specific
and isn't a generic GHC bug in dictionary construction.

### Fifth: `-A16m` remains a known workaround

Session 38 confirmed `-A16m` produces a clean compile of
Big2.hs.  Continue to document this as a user-facing operational
workaround until the root cause is found.

## Mechanics — picking up where session 39 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-39 redeploy).

# (a) Re-apply probe39 if you need to re-verify:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-39-var-realunique-drift/probe39-realunique-drift.patch

# (b) For probe40 (varName drift tracker, or upstream dictionary
# emit tracking), see "Top priority" above.

# (c) Build + deploy + sweep:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# (d) For a focused panic-reproduction:
bash docs/sessions/2026-05-13-session-39-var-realunique-drift/scripts/trigger-one.sh pmacg5 1650
```

## What NOT to redo

* **Don't pursue "GC corrupts Var.realUnique"** — probe39 ruled
  it out via direct sentinel-based observation.  See findings F4.
* **Don't pursue "UniqFM IntMap corruption"** — session 38 ruled
  it out via PROBE38-ADDLOST/SHRINK self-validation.
* **Don't pursue closure-shape probes on v** — session 37
  dissolved that.  v IS the evaluated Id.
* **Don't pursue BLACKHOLE→IND theories** — session 36's framing
  is wrong (`rts/Updates.h:48-67` doesn't write IND).
* **Don't redo raw `peek`-at-word[2] for Var fields** —
  `anyToAddr#` returns a wrapping thunk's address, not the Id
  closure's.  Use the Haskell-level accessor (`varUnique v`,
  `varName v`) instead.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-39 redeploy).
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Time estimate for session 40

* Setup + read handoff: 10-15 min.
* Probe40 (varName drift tracker OR upstream dictionary
  tracker): 2-3 h.
* Build + deploy + sweep + analyze: 1-2 h.
* If clear signal: 1-2 h investigation of the pipeline stage
  producing the duplicate.

Total realistic: 1 medium-large session (5-7 h).

## Paste-into-fresh-session prompt

```
Context: session 39 of the GHC darwin8-ppc project ran probe39 —
a sentinel-Var IORef tracking probe in compiler/GHC/Core/Opt/
Simplify/Env.hs that registered the first $d*-named Var seen in
subst_id_bndr and at every refineFromInScope call re-read its
varUnique via Haskell to detect drift.

Outcome: session 38's "GC corrupts Var.realUnique" hypothesis is
DISPROVEN.

  1. When the sentinel registered (in successful compiles at
     len=850 after probe-shifted heap), varUnique v returned
     0x610013f7 at registration and 0x610013f7 at every
     subsequent refineFromInScope check — NO DRIFT.
  2. When the bug fires (at env-lens 650-725 and 1650-1700 with
     probe39-v3), the sentinel never registers because the
     panic precedes any $d* Var entering scope via
     subst_id_bndr.
  3. The session-37 wrapping-thunk lesson resurfaced: anyToAddr#
     returns a thunk wrapper address, not the Id closure proper,
     so raw word[2] peeks read thunk metadata not realUnique.
     Use varUnique v (Haskell-level accessor) instead.

Refined framing: the bug is TWO DISTINCT VAR OBJECTS existing
with the same OccName "$dOrd_a1k0" but different Uniques.
Neither drifts.  The duplicate is created somewhere upstream of
the simplifier — likely in the typechecker, desugarer,
specializer, or interface deserializer.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline 30 PASS / 0 FAIL_RUN /
4 FAIL_OUTPUT.

Read in order:
1. docs/sessions/2026-05-13-session-39-var-realunique-drift/HANDOFF.md
2. docs/sessions/2026-05-13-session-39-var-realunique-drift/README.md
3. docs/sessions/2026-05-13-session-39-var-realunique-drift/findings.md
4. docs/sessions/2026-05-13-session-39-var-realunique-drift/log.md
5. (Reference) docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/HANDOFF.md

Top priority: trace where the duplicate Var is constructed.
Add probes to dictionary-emitting sites in:
- compiler/GHC/HsToCore/* (desugarer)
- compiler/GHC/Tc/Solver/* (typechecker)
- compiler/GHC/Core/Opt/Specialise.hs (specializer)
- compiler/GHC/Iface/Load.hs (interface deserializer)
Look for two emissions with the same Name but different Unique.

Second priority: track varName v stability (like probe39 but on
the Name pointer field, not realUnique).  If the Name pointer
is rewritten by GC, we'd see the same OccName attach to
different Uniques.

Third priority: cross-check with -ddump-tc / -ddump-ds /
-ddump-simpl-iterations dumps on PPC vs host.

Don't pursue GC-of-realUnique theories — probe39 ruled them
out.  Don't pursue raw word[2] reads from anyToAddr#-returned
addresses — those are wrapping thunks.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-39-var-realunique-drift/HANDOFF.md`](docs/sessions/2026-05-13-session-39-var-realunique-drift/HANDOFF.md).

When session 40 ends, write the next handoff at:
`docs/sessions/<DATE>-session-40-<slug>/HANDOFF.md`.
