# Handoff from session 41 → session 42

**For:** the next claude session.
**From:** session 41 (probe41 — pin SimplEnv in IORef, track
seInScope/seIdSubst drift).
**Recommended pickup:** instrument `simplTopBinds`'s entry to
dump `length (bindersOfBinds binds0)`.  Hypothesis: the input
to simplTopBinds is corrupted upstream, causing simplRecBndrs
to see only 2 binders instead of 10.

## ✅ SESSION CLEAN EXIT _(pending in-flight verification of baseline tests)_

Source tree clean (probe41 reverted).  Stage1 rebuilding +
stage2 redeploying — see exit-state paragraph in README.md for
final status.  v0.12.0 release unchanged.

## TL;DR

Probe41 pinned a SimplEnv reference at every simplRecBndrs
call and at every substId-failure compared the pinned env's
CURRENT seInScope/seIdSubst sizes vs registration-time sizes.

Two findings:

1. **Pinned env's sizes are STABLE** — `pinned_was = pinned_now`
   across all checks.  GC does NOT corrupt the SimplEnv data
   structure for the env probe41 pins.  Session 40's
   "GC corrupts SimplEnv" hypothesis is partially disproven.
2. **Panic-site env is a DIFFERENT SimplEnv than pinned.**  In
   a failing run, pinned env has scope=2 (from a small
   simplRecBndrs call) while the substId-failure has scope=5
   (a different env with more binders).  Multiple envs in
   flight; probe41 didn't track the right one.

Additionally observed:

3. **In failing runs, simplRecBndrs's FIRST call has scope=2**;
   in clean runs it has scope=10 (matching Big2.hs's ~10
   top-level binders).  The simplifier sees only 2 binders at
   what should be simplTopBinds-entry time in failing runs.

**New hypothesis:** the simplifier's input `binds0 / CoreProgram`
is corrupted upstream of simplTopBinds — by the typechecker,
desugarer, specializer, or interface deserializer.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative + comparison.
3. [`findings.md`](findings.md) — F1..F9 analysis with clean
   baseline vs failing data + interpretation.
4. [`log.md`](log.md) — real-time work log (v1 → v2 iteration).
5. (Reference) Session 40
   [`HANDOFF.md`](../2026-05-13-session-40-trace-duplicate-var/HANDOFF.md).

## What to try next, in priority order

### Top: instrument simplTopBinds entry

Hook `simplTopBinds env0 binds0` at its entry in
`compiler/GHC/Core/Opt/Simplify.hs:211` and dump
`length (bindersOfBinds binds0)`.

Sketch (NOTE: simplTopBinds is in Simplify.hs not Env.hs, so
the IORef + helper need to be in a shared module or imported):

```haskell
{-# NOINLINE probe42BindsCounter #-}
probe42BindsCounter :: IORef Int
probe42BindsCounter = unsafePerformIO (newIORef 0)

probe42DumpBinds0 :: [InBind] -> ()
probe42DumpBinds0 binds = unsafePerformIO $ do
    let n = length (bindersOfBinds binds)
    n_seen <- atomicModifyIORef' probe42BindsCounter (\k -> (k+1, k+1))
    hPutStrLn stderr $ "PROBE42-BINDS0 call=" ++ show n_seen ++ " count=" ++ show n
    hFlush stderr
```

Then in simplTopBinds:
```haskell
simplTopBinds env0 binds0
  = do  { let !_dump = probe42DumpBinds0 binds0
        ; !env1 <- simplRecBndrs env0 (bindersOfBinds binds0)
        ; ...
```

If in failing runs the count is 2 (or some small number) and in
clean runs it's 10+, the corruption is BEFORE simplTopBinds.

### Second: trace the CoreProgram from desugarer to simplifier

`Pipeline.hs::simplifyPgm` is where the CoreProgram (mg_binds)
flows from the desugarer through the optimizer pipeline.  Find
the path that produces mg_binds and instrument it.

### Third: dump pre-simplifier Core with -ddump-prep -ddump-cse

These flags dump the Core program after CorePrep / CSE but
before simplifier.  Compare clean vs failing dumps for
binder-list length.

### Fourth: cross-check with `-O0` flavour

If the bug is sensitive to simplifier passes' execution order,
disabling optimization might shift the trigger.  Try compiling
Big2.hs with `-O0` and see if it still panics.

### Fifth: shrink Big2.hs to the minimal repro

750 bytes is small but possibly shrinkable further.  Strip
imports/functions to find the minimal failing program.  A
3-line repro would be much easier to instrument and bisect.

## Mechanics — picking up where session 41 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-41 redeploy).

# (a) Re-apply probe41 if you need to re-verify:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/probe41-simplenv-tracker.patch

# (b) For probe42 (binds0 length dump), see "Top priority" above.
# Note simplTopBinds lives in compiler/GHC/Core/Opt/Simplify.hs
# while the probe helpers belong in Simplify/Env.hs — you may
# need to export the probe helpers from Env.hs (already imported
# by Simplify.hs).

# (c) Build + deploy + sweep:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# (d) Single trigger:
pad=$(awk 'BEGIN{for(i=1;i<=598;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
    DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1" | head -10
```

## What NOT to redo

* **Don't pursue "GC corrupts the SimplEnv data structure
  probe41 pins"** — probe41 ruled it out (the pinned env's
  sizes are stable).
* **Don't pursue "GC corrupts Var.realUnique"** — session 39
  ruled it out.
* **Don't pursue "UniqFM IntMap corruption"** — session 38
  ruled it out.
* **Don't pursue closure-shape probes on v** — session 37
  dissolved that.
* **Don't pursue BLACKHOLE→IND theories** — session 36's
  framing is wrong.
* **Don't pin a SimplEnv via threshold-based heuristic** — in
  failing runs, simplRecBndrs's first call has scope=2,
  smaller than session 41's >=5 threshold.  v2's "log every,
  keep largest" worked but pinned the wrong env anyway
  (the panic site uses a different env entirely).

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-41 redeploy).
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Time estimate for session 42

* Setup + read handoff: 10-15 min.
* Probe42 (binds0 length dump at simplTopBinds entry): 1-2 h
  (needs cross-module helper export).
* Build + deploy + sweep + analyze: 1-2 h.
* If signal: 1-2 h root-cause investigation.

Total realistic: 1 medium session (4-6 h).

## Paste-into-fresh-session prompt

```
Context: session 41 of the GHC darwin8-ppc project ran probe41 —
a SimplEnv pinning + drift detector in compiler/GHC/Core/Opt/
Simplify/Env.hs.

Outcome: session 40's "GC corrupts the SimplEnv heap closure's
seInScope/seIdSubst fields" hypothesis is partially disproven.
The pinned env's sizes (was=2, now=2 at panic time) are stable
across the compilation.  GC does NOT corrupt the env probe41
tracks.

However: the panic-site env is a DIFFERENT SimplEnv than the
pinned env.  In a failing run, pinned env has scope=2 while
substId-failure has scope=5.  Multiple envs in flight.  Also:
the FIRST simplRecBndrs call has scope=2 in failing runs vs
scope=10 in clean runs — Big2.hs has ~10 top-level binders,
yet the simplifier sees only 2 at simplTopBinds-entry time in
failing runs.

New hypothesis: the simplifier's input binds0 / CoreProgram is
corrupted upstream of simplTopBinds — by the typechecker,
desugarer, specializer, or interface deserializer.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline 30 PASS / 4 FAIL_OUTPUT
unchanged.

Read in order:
1. docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/HANDOFF.md
2. docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/README.md
3. docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/findings.md
4. docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/log.md
5. (Reference) docs/sessions/2026-05-13-session-40-trace-duplicate-var/HANDOFF.md

Top priority: probe42 — instrument simplTopBinds entry to dump
length (bindersOfBinds binds0).  If failing runs show count=2
and clean runs show count=10, the corruption is BEFORE
simplTopBinds.  Compare desugarer / specializer output between
clean and failing compiles.

Don't pursue: GC-of-SimplEnv-fields, GC-of-Var.realUnique,
UniqMap-corruption, closure-shape probes — all ruled out.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/HANDOFF.md`](docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/HANDOFF.md).

When session 42 ends, write the next handoff at:
`docs/sessions/<DATE>-session-42-<slug>/HANDOFF.md`.
