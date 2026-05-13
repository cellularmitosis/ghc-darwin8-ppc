# Handoff from session 38 → session 39

**For:** the next claude session.
**From:** session 38 (probe38 — silent-on-happy-path instrumentation
of `Simplify/Env.hs`'s InScopeSet mutations).
**Recommended pickup:** track the `realUnique` field of a specific
Var across the compilation pipeline (insertion vs. lookup) to
confirm or rule out the **GC-corrupts-Var.realUnique** hypothesis
that session 38 surfaced.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe38 reverted).  Stage1 rebuilt clean +
stage2 redeployed to pmacg5 + smoke-test PASS.  v0.12.0 release
unchanged.

## TL;DR — the major refinement to session 28's framing

Session 28's framing was "GC corruption of UniqMap-backed data
structures."  Session 38's probe38 (which directly instrumented
`addNewInScopeIds`, the three `setInScope*` variants, and the
`refineFromInScope` panic site) shows that **the UniqMap is NOT
what's corrupted**:

- `addNewInScopeIds`'s post-extension self-validation
  (`PROBE38-ADDLOST`) **never fires.**  Insertion is correct.
- `setInScopeSet`/`setInScopeFromE`/`setInScopeFromF`'s shrink
  detection (`PROBE38-SHRINK`) **never fires.**  Replacement is
  correct.
- The InScopeSet at the panic site contains coherent, well-formed
  Var entries.

**What IS broken: the Vars themselves.**

Fingerprint A (env-lens 825..925, 5 identical panics):

```
PROBE38-PANIC call=1 size=6 v=$dOrd(0x61001418) direct=Nothing elemInScope=False
  elements=[wild(0x30000000) k(0x61000e5c) m(0x61000e5d)
            a(0x610013f6) $dOrd(0x610013f7) countOf(0x720004ce)]
```

The InScopeSet **DOES** contain a Var with `OccName = $dOrd_a1k0`,
at raw Unique `0x610013f7`.  But the expression the simplifier is
walking references a Var with `OccName = $dOrd_a1k0` and raw
Unique `0x61001418` — **a different Var**, despite the same
OccName.  The IntMap-keyed lookup fails because Uniques don't
match.

This pattern repeats at env-lens 1650..1700 with `$dOrd(0x610013dc)`
and a smaller scope, and rotates through different victims
(`$dEq`, `ds_d1lr`, `$dFoldable`) as `-A` changes (see findings F5).

**The refined hypothesis:** GC corrupts the `realUnique :: FastInt#`
field of Var heap closures on PPC32 unreg.  When the simplifier
inserts a Var into an InScopeSet, the IntMap key is the Var's
current `realUnique`.  Later, when the same Var is encountered in
the expression tree, its `realUnique` reads differently (because
GC rewrote it), so the lookup misses.

`-A16m` produces a **clean compile** of Big2.hs at len=850 — strong
confirmation that the bug is GC-frequency-sensitive.

## What we learned

1.  **The InScopeSet is innocent.** No PROBE38-ADDLOST / SHRINK
    in any of the ~58 sweep runs.
2.  **Two Vars with same OccName, different Uniques** is the bug
    fingerprint at the refineFromInScope panic site.
3.  **The victim Var rotates with `-A`** — at `-A1m` it's `$dOrd`,
    at `-A2m` it's `$dEq`, at `-A8m` it's `ds_d1lr` (a let-binding,
    not a dictionary).  Bug isn't dictionary-specific.
4.  **`-A16m` produces a clean compile.** Increase nursery →
    reduce GC → no bug.
5.  **The panic is deterministic** given env-len + flags + filename.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative + arrival/exit state +
   what probe38 captured.
3. [`findings.md`](findings.md) — full F1..F10 analysis:
   the panic-site evidence, self-validation results, nursery-size
   table, and concrete next-session targets §F8.
4. [`log.md`](log.md) — real-time work log.
5. (Reference) Session 37
   [`HANDOFF.md`](../2026-05-13-session-37-indirectee-and-update-path/HANDOFF.md)
   — what session 38 came in to pick up.

## What to try next, in priority order

### Top: track a Var's `realUnique` across the pipeline

Pick one Var (say, `$dOrd_a1k0` at insertion in `addNewInScopeIds`).
Stash a "fingerprint" of it: `Ptr (FastInt#)` to the realUnique
field via `anyToAddr#`, plus the initial value.  At later points
(e.g. before each `refineFromInScope` call), re-read the same
address and report any deviation.  If the value at the address
changes between insertion and lookup, that's **direct evidence of
GC-corruption-of-Var.realUnique**.

Sketch (in `Env.hs`):

```haskell
{-# NOINLINE probe39Tracker #-}
probe39Tracker :: IORef (Maybe (Var, Addr#, Int))  -- (var, &realUnique, expected)
probe39Tracker = unsafePerformIO (newIORef Nothing)

trackVar :: Var -> IO ()
trackVar v
  | getOccString v == "$dOrd_a1k0" = do
      addr <- probe37AddressOf v   -- via anyToAddr#
      let u0 = getKey (varUnique v)
      writeIORef probe39Tracker (Just (v, addr, u0))
      hPutStrLn stderr $ "PROBE39-TRACK init @" ++ probe38Hex addr ++
                         " realUnique=" ++ probe38Hex u0
  | otherwise = return ()

checkTracked :: String -> IO ()
checkTracked site = do
    m <- readIORef probe39Tracker
    case m of
      Nothing -> return ()
      Just (v, addr, u0) -> do
        let u1 = getKey (varUnique v)
        when (u1 /= u0) $ do
          hPutStrLn stderr $ "PROBE39-DRIFT @" ++ site ++
            " realUnique was=" ++ probe38Hex u0 ++ " now=" ++ probe38Hex u1
```

Call `trackVar` at every `addNewInScopeIds` entry that contains an
`$dOrd_a1k0`-flavoured var; call `checkTracked "refineFromInScope"`
at the start of each `refineFromInScope`.  If `PROBE39-DRIFT` fires,
the hypothesis is confirmed and we have the addr to disassemble.

### Second: PPC32 unreg Cmm dump of Var operations

Examine how Var's `realUnique :: FastInt` field is laid out in the
PPC32 unreg ABI.  Look at:

- `compiler/GHC/Types/Var.hs` — Var data constructor.
- `_build/stage1/compiler/build/GHC/Types/Var.dump-cmm-from-stg` —
  the Cmm IR for Var's projections.
- Specifically: is `varUnique` reading `realUnique` from the
  expected closure-payload offset?  On PPC32, with `-DNOSMP` /
  `Tables next to code = NO`, the closure layout differs from
  arm64/x86_64.

### Third: test the same bug on uranium host GHC 9.2.8

Big2.hs `-A1m -G1 +RTS -ddump-stg ...` on uranium host ghc-9.2.8
must NOT panic.  If it does, the bug isn't PPC-unreg-specific.

### Fourth: workaround documentation

Document `+RTS -A16m -RTS` as a known PPC32-unreg pitfall in the
user-facing README's notes.  This is an immediate operational
workaround.

### Fifth: rts/Heap/Evac.c traversal of Int# closures

If the realUnique field is being corrupted by evac/scav, the
culprit is somewhere in PPC32's small-payload evacuation path.
Compare arm64 evac for the same closure type — should be
byte-identical traversal.  Look for any 32-bit vs 64-bit field
size assumption in evac that PPC32 hits wrong.

## Mechanics — picking up where session 38 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-38 redeploy).

# (a) Re-apply probe38 if you need to re-sweep:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/probe38-inscopeset.patch

# (b) For probe39 (realUnique drift tracker), add the trackVar /
# checkTracked helpers to Simplify/Env.hs and call them in
# addNewInScopeIds + refineFromInScope.  See "Top priority" above.

# (c) Build + deploy + sweep:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
bash docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/scripts/sweep.sh pmacg5 600 2000 25

# (d) For a focused panic-reproduction with full body:
bash docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/scripts/trigger-one.sh pmacg5 850
```

## What NOT to redo

* **Don't pursue "UniqFM IntMap is corrupted" theories** — probe38's
  ADDLOST / SHRINK self-validation definitively rules that out.
  See findings F3 and F9.
* **Don't add more InScopeSet instrumentation** without first
  considering whether you can directly observe Var.realUnique
  drift instead.  That's the more localized hypothesis.
* **Don't pursue BLACKHOLE→IND theories** (session 36's framing
  was dissolved by session 37).
* **Don't pursue further closure-shape probes on v itself** —
  session 37's data was right but the framing was wrong.
* **Don't redo lazy/eager blackholing experiments.**
* **Don't pursue session 36's "update-path / stg_update_thunk_info
  disassembly"** — the macro is fine.

## Hosts (unchanged)

* **uranium** (this Mac): cross-build, source edits.
* **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-38 redeploy).
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked,
    kept from session 30.  Unchanged.
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Time estimate for session 39

* Setup + read handoff: 10-15 min.
* Probe39 (realUnique drift tracker): 1-2 h to design + implement.
* Build + sweep + analyze: 1-2 h.
* If `PROBE39-DRIFT` fires immediately: 1-2 h follow-on
  investigation of which GC phase rewrites the field.

Total realistic: 1 medium session (4-6 h) to either confirm
Var.realUnique drift directly or rule it out and pivot.

## Paste-into-fresh-session prompt

```
Context: session 38 of the GHC darwin8-ppc project ran probe38
(silent-on-happy-path instrumentation of Simplify/Env.hs's
InScopeSet mutations: panic-site full dump at refineFromInScope,
self-validation at addNewInScopeIds, shrink detection at all three
setInScope* variants).

Outcome: a major REFINEMENT to session 28's framing.

  1. PROBE38-ADDLOST never fires across the full env-len sweep —
     insertion is correct.
  2. PROBE38-SHRINK never fires — replacement is correct.
  3. The InScopeSet at the panic site contains coherent Var
     entries.
  4. The panic body's "missing var" is a Var with the SAME OccName
     as an in-scope Var but a DIFFERENT raw Unique.  E.g., at
     env-lens 825..925, in-scope has $dOrd(0x610013f7) but the
     expression's $dOrd has raw Unique 0x61001418.  Delta=33.
  5. The victim rotates with -A nursery size: -A1m → $dOrd,
     -A2m → $dEq, -A8m → ds_d1lr (a let-binding, not a dict),
     -A32m → $dFoldable.  Not dictionary-specific.
  6. -A16m produces a CLEAN compile of Big2.hs at len=850 — strong
     confirmation the bug is GC-frequency-sensitive.

This refines session 28's framing from "UniqMap data structures
are corrupted" to **the Var heap closures' realUnique fields are
corrupted by GC on PPC32 unreg**.  The various UniqMap-backed
victim structures (InScopeSet, depSortStgBinds adjacency list, TC
GlobalRdrEnv) are all innocent; they correctly store and key by
Unique.  But the Vars they store don't have stable Uniques across
GC.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.

Read in order:
1. docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/HANDOFF.md
2. docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/README.md
3. docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/findings.md
4. docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/log.md
5. (reference) docs/sessions/2026-05-13-session-37-indirectee-and-update-path/HANDOFF.md

Top priority: design a probe that tracks a SPECIFIC Var's
realUnique field across the compilation pipeline.  Stash the Var's
heap address (via anyToAddr#) and initial realUnique at insertion
into the InScopeSet (addNewInScopeIds).  At every refineFromInScope
call, re-read the address and check if realUnique changed.  If
PROBE39-DRIFT fires, GC-corrupts-realUnique is directly confirmed.
See HANDOFF.md "Top priority" for the sketch.

Second priority: dump PPC32 unreg Cmm for Var's realUnique
projection (compiler/GHC/Types/Var.hs's varUnique).  Verify the
closure-payload offset is correct.

Third priority: confirm the bug doesn't reproduce on uranium host
ghc-9.2.8.

Don't pursue InScopeSet-corruption theories — probe38 ruled them
out.  Don't pursue BLACKHOLE→IND theories — session 37 dissolved
that.  Don't pursue further closure-shape probes on v — session 37
data was right, framing wrong.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/HANDOFF.md`](docs/sessions/2026-05-13-session-38-inscopeset-instrumentation/HANDOFF.md).

When session 39 ends, write the next handoff at:
`docs/sessions/<DATE>-session-39-<slug>/HANDOFF.md`.
