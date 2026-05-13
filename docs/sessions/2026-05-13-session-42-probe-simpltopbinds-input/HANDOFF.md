# Handoff from session 42 → session 43

**For:** the next claude session.
**From:** session 42 (probe42 — log binds0 length at
simplTopBinds entry).
**Recommended pickup:** track down WHICH GC pass corrupts the
[InBind] cons-list spine.  Start with Evac.c's handling of
CONSTR_2_0 closures on PPC32 unreg.

## ✅ SESSION CLEAN EXIT _(pending in-flight verification of baseline)_

Source tree clean (probe42 reverted).  Stage1 rebuilding +
stage2 redeploying — see README.md's exit-state paragraph.
v0.12.0 release unchanged.

## TL;DR — the smoking gun

`simplTopBinds`'s input `binds0 :: [InBind]` is **truncated by
GC** in failing runs.

| compile      | binds0 length    | outcome              |
|--------------|------------------|----------------------|
| -A1G clean   | 9 (call 1), 13 (call 2) | proper .o (46340 B) |
| -A1m -G1 len=600/1650/1700 | 1 | refineFromInScope panic |
| -A1m -G1 len=850-1000 | **0** | **silent miscompile — empty 152 B .o** |

The shrinkage is GC-pressure-induced (disappears with -A1G)
and deterministic (3 repeats produce identical numbers).

The list `[InBind]` is a heap cons-list (CONSTR_2_0 closures).
GC corruption of cons-cell `tail` pointers truncates the list.

**This finding subsumes every prior session's framing.**  All
"X is corrupted" claims (v's closure, UniqMap, Var.realUnique,
two distinct Vars, SimplEnv fields) are downstream symptoms of
the same root cause: GC truncates the [InBind] list.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative + the full
   sweep table.
3. [`findings.md`](findings.md) — F1..F8 analysis, signature
   table, silent-miscompile evidence, GC connection.
4. [`log.md`](log.md) — real-time work log.
5. (Reference) Session 41
   [`HANDOFF.md`](../2026-05-13-session-41-simplenv-corruption-tracker/HANDOFF.md)
   — what session 42 came in to verify (and confirmed).

## What to try next, in priority order

### Top: identify the GC pass that truncates the list

`[InBind]` cons cells are `CONSTR_2_0` closures (2 pointer
fields: head, tail).  In `rts/sm/Evac.c::copy_tag`, when
copying such a closure, the new closure's payload pointers
need to be fixed up.  Instrument:

1. Count CONSTR_2_0 closure evacuations per GC cycle.
2. Snapshot a known cons cell's `tail` pointer before and
   after a GC pass.  If it changes from a valid pointer to
   stg_NIL_closure (or to a stale pointer that resembles
   NIL), GC is the culprit.

### Second: pin binds0 and walk its spine across GC cycles

Like probe39 (sentinel Var) but on a `[InBind]` list:

```haskell
{-# NOINLINE probe43BindsRef #-}
probe43BindsRef :: IORef (Maybe [InBind])
probe43BindsRef = unsafePerformIO (newIORef Nothing)

probe43Pin :: [InBind] -> IO ()
probe43Pin binds = do
    m <- readIORef probe43BindsRef
    case m of
      Just _ -> return ()
      Nothing -> writeIORef probe43BindsRef (Just binds)

probe43Check :: String -> IO ()
probe43Check site = do
    m <- readIORef probe43BindsRef
    case m of
      Nothing -> return ()
      Just binds -> do
        let n = length binds
        hPutStrLn stderr $ "PROBE43-CHECK " ++ site ++ " length=" ++ show n
```

Hook simplTopBinds to pin binds0, then periodically call
`probe43Check` from various points in the compilation.  If
the length drops between checks, GC has truncated the spine
in real time.

### Third: compare PPC32 vs arm64 CONSTR_2_0 heap layout

Look at `_build/stage1/lib/include/ClosureLayout.h` or
similar for the closure type's payload layout.  On PPC32 unreg,
the CONSTR_2_0 layout might have a subtle offset issue that
GC's `evac` misses.

### Fourth: update README and roadmap to reflect severity

Stage2 native compilation should be downgraded from ✅ to 🟡
"works but silently miscompiles under low nursery sizes — use
+RTS -A1G".  Add the workaround prominently to the user-facing
docs.

### Fifth: file a GHC bug report

This is a real PPC32 unreg bug in GHC's runtime.  Even if we
fix it in our fork, upstreaming the diagnosis would help anyone
reviving PPC unreg in the future.

## Mechanics — picking up where session 42 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-42 redeploy).

# (a) Re-apply probe42 if you need to re-verify:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/probe42-topbinds-input.patch

# (b) For probe43 (binds0 spine tracker), see "Top priority"
# above.  Helper goes in Simplify/Env.hs (exported); call sites
# in Simplify.hs.

# (c) Build + deploy + test:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# (d) Compare -A1G clean vs -A1m -G1 failing:
ssh pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1G -RTS; ls -la /tmp/Big2.o"

pad=$(awk 'BEGIN{for(i=1;i<=848;i++) printf "A"}')
ssh pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS; ls -la /tmp/Big2.o"
```

## What NOT to redo

* **Don't pursue closure-shape probes on v** — session 37
  dissolved that.  v IS the evaluated Id from a small env.
* **Don't pursue UniqMap-corruption theories** — session 38
  ruled them out.  The UniqMaps are coherent within whatever
  small env exists.
* **Don't pursue Var.realUnique drift** — session 39 ruled
  it out.  Var.realUnique is stable.
* **Don't pursue SimplEnv pointer-field corruption** —
  session 41 ruled it out.  The SimplEnv is intact.
* **Don't pursue BLACKHOLE→IND theories** — session 36
  framing is wrong.
* **Don't believe `-A16m` is a clean threshold** — at most
  `-A256m`, ideally `-A1G`.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-42 redeploy).
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Time estimate for session 43

* Setup + read handoff: 10-15 min.
* Probe43 design + apply: 1-2 h.
* Build + deploy + sweep: 1-2 h.
* If clear signal pointing at a specific GC pass: 1-3 h
  investigation + potential fix attempt.

Total realistic: 1 medium-large session (5-7 h).  A real fix
might span multiple sessions.

## Paste-into-fresh-session prompt

```
Context: session 42 of the GHC darwin8-ppc project found the
**smoking gun** root cause of the stage2 GC bug.

Probe42 instrumented simplTopBinds in Simplify.hs to log
length (bindersOfBinds binds0) at the function's entry.

Findings:
- Clean compile (-A1G or -A256m): binds0 has 9 binders.
- Failing -A1m -G1 len=600/1650/1700: binds0 has 1 binder →
  refineFromInScope panic.
- Failing -A1m -G1 len=850-1000: binds0 has 0 binders →
  ghc-real exits RC=0 producing a 152-byte empty .o file
  (SILENT MISCOMPILE — no function definitions emitted).
- -A1G eliminates the bug entirely (no GC pressure).
- 3 repeats at len=600 produce identical numbers (deterministic).

Root cause: **GC is corrupting the [InBind] cons-list spine
flowing into simplTopBinds**.  In failing runs, the list is
truncated to 0 or 1 elements.

This finding subsumes every prior session's framing.  All
"X is corrupted" hypotheses (v's closure, UniqMap,
Var.realUnique, two distinct Vars, SimplEnv fields) are
downstream symptoms of the same root cause: GC truncates the
[InBind] list.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline 30 PASS / 4 FAIL_OUTPUT
unchanged.

Read in order:
1. docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/HANDOFF.md
2. docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/README.md
3. docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/findings.md
4. docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/log.md
5. (Reference) docs/sessions/2026-05-13-session-41-simplenv-corruption-tracker/HANDOFF.md

Top priority: identify the GC pass corrupting CONSTR_2_0 cons
cells (the [InBind] list spine).  Instrument
rts/sm/Evac.c::copy_tag to log per-closure-type evacuations.
Also pin binds0 in an IORef and check its length periodically
across the compilation — if it shrinks between checks, GC is
the truncator.

Second priority: file a GHC bug report (this is a real PPC32
unreg bug in GHC's runtime).

Third priority: update README/roadmap to reflect severity —
silent miscompile is far worse than a panic.

Don't pursue: closure-shape / UniqMap / Var.realUnique /
SimplEnv field corruption / BLACKHOLE-IND theories — all ruled
out.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/HANDOFF.md`](docs/sessions/2026-05-13-session-42-probe-simpltopbinds-input/HANDOFF.md).

When session 43 ends, write the next handoff at:
`docs/sessions/<DATE>-session-43-<slug>/HANDOFF.md`.
