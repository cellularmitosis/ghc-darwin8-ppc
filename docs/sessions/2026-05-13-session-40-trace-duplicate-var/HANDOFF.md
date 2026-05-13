# Handoff from session 40 → session 41

**For:** the next claude session.
**From:** session 40 (probe40 — extend probe38's panic dump with
seIdSubst size + keys; also `-A256m` clean-compile Core diff
between PPC stage2 and uranium host).
**Recommended pickup:** test the "GC corrupts the SimplEnv data
structure's seInScope/seIdSubst pointer fields" hypothesis by
periodically reading the seInScope size off a long-held
SimplEnv reference held in an IORef (like probe39 but on the
env itself, not a Var).

## ✅ SESSION CLEAN EXIT

Source tree clean (probe40 reverted).  Stage1 rebuilt clean +
stage2 redeployed to pmacg5 + smoke-test PASS + baseline tests
30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged, _TBD pending
in-flight verification_).  v0.12.0 release unchanged.

## TL;DR

Probe40 extended probe38's panic-site dump to also report
`seIdSubst`'s size and keys.

**The seIdSubst is EMPTY at every refineFromInScope panic.**

The env at the panic site looks freshly created — `init_in_scope`
+ only the binders for the current function being descended
into, no top-levels, no substitutions.

`mkSimplEnv` is called only once per simplifier iteration (per
`Pipeline.hs:734`).  Its output flows into `simplTopBinds`,
which populates seInScope with all top-level binders via
`simplRecBndrs`.  The panic-site env doesn't match this expected
post-simplRecBndrs shape.

**New hypothesis:** GC corrupts the SimplEnv heap closure's
`seInScope :: !InScopeSet` and `seIdSubst :: SimplIdSubst`
fields, resetting them to fresh-env defaults somewhere during
the simplifier's descent.  This is consistent with the heap-
layout-sensitive triggering from sessions 28-29 and with
probe38's PROBE38-SHRINK never firing (PROBE38-SHRINK only
detects Haskell-level set replacements via `setInScope*`
functions; a GC pointer rewrite wouldn't go through these).

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative + Core-diff +
   probe40 captures.
3. [`findings.md`](findings.md) — F1..F8 analysis with the
   "fresh env" interpretation, SimplEnv heap-layout reasoning,
   and candidate next-experiment list.
4. [`log.md`](log.md) — real-time work log.
5. (Reference) Session 39
   [`HANDOFF.md`](../2026-05-13-session-39-var-realunique-drift/HANDOFF.md)
   — disproves "GC corrupts Var.realUnique."

## What to try next, in priority order

### Top: track a SimplEnv heap address + seInScope size over time

Like probe39 but on a `SimplEnv` reference instead of a `Var`.
At `simplTopBinds`'s end (after `simplRecBndrs` populated env1
with top-level binders), stash `env1` in an IORef.  At every
subsequent refineFromInScope call (or at simplExpr entry), read
`sizeVarSet (getInScopeVars (seInScope env1))`.  If the size
drops between checks, GC has corrupted env1's seInScope field.

Sketch:

```haskell
{-# NOINLINE probe41EnvRef #-}
probe41EnvRef :: IORef (Maybe SimplEnv)
probe41EnvRef = unsafePerformIO (newIORef Nothing)

probe41RegisterEnv :: SimplEnv -> IO ()
probe41RegisterEnv env = do
    m <- readIORef probe41EnvRef
    case m of
      Just _  -> return ()  -- Already tracking
      Nothing -> do
        let sz = sizeVarSet (getInScopeVars (seInScope env))
        writeIORef probe41EnvRef (Just env)
        hPutStrLn stderr $ "PROBE41-INIT scope_size=" ++ show sz
        hFlush stderr

probe41CheckEnv :: String -> IO ()
probe41CheckEnv site = do
    m <- readIORef probe41EnvRef
    case m of
      Nothing -> return ()
      Just env -> do
        let sz = sizeVarSet (getInScopeVars (seInScope env))
            subst_sz = sizeUFM (seIdSubst env)
        hPutStrLn stderr $ unwords
          ["PROBE41-CHECK", "site=" ++ site,
           "scope_size=" ++ show sz,
           "subst_size=" ++ show subst_sz]
        hFlush stderr
```

Hook `simplTopBinds` to call `probe41RegisterEnv env1` after
simplRecBndrs.  Hook `refineFromInScope` (or substId's Nothing
branch) to call `probe41CheckEnv "refineFromInScope"`.  If the
"main" env's scope_size drops from N (post-simplRecBndrs) to a
small value at the panic site, that's direct evidence of GC
corruption of the SimplEnv.

### Second: investigate ContEx / mkContEx capture-and-restore path

If the simplifier captures a SimplEnv inside a `SimplSR.ContEx`
(via `mkContEx`) and later reconstructs from it, a corrupted
SimplSR could explain the fresh-looking env.  Audit all
ContEx production and consumption sites.

### Third: try -fno-pre-inlining / -fno-pre-inlining-2

If the bug fires during specific simplifier passes (inliner,
specializer), disabling those passes might shift or eliminate
the panic.

### Fourth: smaller test cases

Big2.hs is ~750 bytes.  Can we shrink it further?  Strip
imports/functions one at a time and find the minimal repro.
A 3-line repro would be much easier to instrument.

### Fifth: GHC issue search

Search GHC's bug tracker for similar reports
(`refineFromInScope` + `panic` + `unregisterised`).  This bug
shape has surely been seen before on other PPC-unreg or
SPARC-unreg builds.

## Mechanics — picking up where session 40 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-40 redeploy).

# (a) Re-apply probe40 if you need to re-sweep:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-40-trace-duplicate-var/probe40-subst-fail.patch

# (b) For probe41 (SimplEnv corruption tracker), see "Top
# priority" above.

# (c) Build + deploy + sweep:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# (d) For a focused panic-reproduction:
pad=$(awk 'BEGIN{for(i=1;i<=848;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
    DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1" \
  | head -20
```

## What NOT to redo

* **Don't pursue "GC corrupts Var.realUnique"** — session 39
  ruled it out.
* **Don't pursue "UniqFM IntMap data structure corruption"** —
  session 38's PROBE38-ADDLOST / SHRINK ruled it out.
* **Don't pursue closure-shape probes on v** — session 37
  dissolved that; v IS the evaluated Id.
* **Don't pursue BLACKHOLE→IND theories** — session 36's
  framing is wrong.
* **Don't believe `-A16m` produces a clean compile** — session
  38's claim was an artifact of `head -8` truncating output.
  `-A256m` is the real clean-compile threshold for Big2.hs +
  dump flags on PPC stage2.
* **Don't raw-peek word[2] from anyToAddr#-returned addresses**
  — those are wrapping thunks (session-37 / session-39 lesson).

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-40 redeploy).
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Time estimate for session 41

* Setup + read handoff: 10-15 min.
* Probe41 (SimplEnv corruption tracker): 1-2 h.
* Build + deploy + sweep + analyze: 1-2 h.
* If signal: 1-2 h root-cause investigation.

Total realistic: 1 medium session (4-6 h).

## Paste-into-fresh-session prompt

```
Context: session 40 of the GHC darwin8-ppc project ran probe40 —
an extension of probe38's panic dump to also report seIdSubst's
size and keys at every substId-Nothing branch (the path that
fires refineFromInScope).

Outcome: **seIdSubst is EMPTY at every refineFromInScope panic.**
The env at the panic site has only init_in_scope + the binders
for the current function being descended into.  No top-level
binders, no substitutions.

`mkSimplEnv` is called only once per simplifier iteration; its
output flows into simplTopBinds which populates seInScope with
all top-level binders.  The panic-site env doesn't match this
expected post-simplRecBndrs shape.

New hypothesis: GC corrupts the SimplEnv heap closure's
seInScope and seIdSubst pointer fields, resetting them to
fresh-env defaults.  This is consistent with sessions 28-29's
heap-layout-sensitive triggering, and with probe38's
PROBE38-SHRINK never firing (it only catches Haskell-level
set replacements; pointer rewrites by GC bypass those).

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline 30 PASS / 4 FAIL_OUTPUT
(unchanged).

Side discovery: `-A16m` does NOT produce a clean compile of
Big2.hs with dump flags on PPC stage2 — session 38's claim was
an artifact of `head -8` truncating the panic body.  The real
clean-compile threshold is `-A256m` (or `-A1G`).

Side discovery: With `-dsuppress-uniques`, PPC stage2's
`-A256m` Core dump and uranium host's `-A1m -G1` Core dump are
BYTE-IDENTICAL except a trailing `RC=0` line.  Structural Core
is correct on PPC; the bug is dynamic (env corruption at
descent time).

Read in order:
1. docs/sessions/2026-05-13-session-40-trace-duplicate-var/HANDOFF.md
2. docs/sessions/2026-05-13-session-40-trace-duplicate-var/README.md
3. docs/sessions/2026-05-13-session-40-trace-duplicate-var/findings.md
4. docs/sessions/2026-05-13-session-40-trace-duplicate-var/log.md
5. (Reference) docs/sessions/2026-05-13-session-39-var-realunique-drift/HANDOFF.md

Top priority: probe41 — pin a SimplEnv reference (e.g., env1
after simplRecBndrs) in an IORef and at every refineFromInScope
check `sizeVarSet (getInScopeVars (seInScope env))`.  If the
size drops between checks, GC has corrupted the SimplEnv data
structure.

Second priority: audit ContEx capture-and-restore paths in
Simplify.hs for env-state restoration that could land us in a
fresh-looking env.

Third priority: shrink Big2.hs to a minimal repro.

Don't pursue Var.realUnique / UniqMap-corruption / closure-shape
/ BLACKHOLE-IND theories — all ruled out.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-40-trace-duplicate-var/HANDOFF.md`](docs/sessions/2026-05-13-session-40-trace-duplicate-var/HANDOFF.md).

When session 41 ends, write the next handoff at:
`docs/sessions/<DATE>-session-41-<slug>/HANDOFF.md`.
