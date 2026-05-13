# Handoff from session 37 → session 38

**For:** the next claude session.
**From:** session 37 (probe37 dissolves session 36's framing —
the bug is InScopeSet corruption, not thunk-update on PPC unreg).
**Recommended pickup:** instrument InScopeSet construction in the
simplifier descent.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe37 reverted).  Stage1 rebuilt clean +
stage2 redeployed to pmacg5 + smoke-test PASS.  v0.12.0 release
unchanged.

## TL;DR — the major reframe

**Session 36 was reading normal post-evaluation state and calling
it a bug.**  `rts/Updates.h:48-67`'s `updateWithIndirection` macro
sets `word[0] = stg_BLACKHOLE_info` *by design*; `stg_IND_info`
does not appear in this path.  The BLACKHOLE entry code returns
the tagged indirectee to the caller as a normal forced-WHNF value.

Probe37 extended probe36 to dump `word[1] & ~3` (the indirectee)
and `nm` resolves its `word[0]` to **`_ghc_GHCziTypesziVar_Id_con_info`
exactly**.  v has been correctly evaluated; the result is a real
`Id` constructor closure with sensible `Name`/`Unique`/`Type` fields.

**The actual bug is visible in the panic body itself**:

```
  InScope {wild_00 v_B1 allPositive}        ← only 3 entries
  $dOrd_a1k0                                 ← missing var
```

The InScopeSet legitimately doesn't contain the typeclass dictionary
the simplifier is trying to look up.  This is a downstream symptom
of **GC-corruption-of-UniqMap-data-structures**, exactly the family
of bugs sessions 19-28 documented before the closure-shape probe
trail of sessions 33-36 took the investigation on a 4-session
detour.

## What we learned

1.  **`updateWithIndirection` writes `stg_BLACKHOLE_info`, not
    `stg_IND_info`.**  Reading the macro confirms.
2.  **The indirectee IS the Id closure** — `nm` confirms.
3.  **The InScopeSet has only 3 entries at the panic site.**
4.  **At len=850, `depSortStgBinds` panics with a "Found cyclic SCC"
    on `$trModule3_r1lT` and `$trModule4_r1lU`** whose FVs do not
    form a cycle.  Different victim, same underlying corruption.
5.  **The closure-shape probe trail of sessions 33-36 is fully
    dissolved.**

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative + arrival/exit state +
   what probe37 captured.
3. [`findings.md`](findings.md) — full F1..F8 analysis:
   `updateWithIndirection` macro semantics, indirectee confirmation,
   the InScopeSet finding, depSortStgBinds at len=850, and
   concrete next-session targets §F6.
4. [`log.md`](log.md) — real-time work log including the host vs
   PPC32 Cmm diff at refineFromInScope and the `-O0` vs `-O2` flavour
   difference (which turned out to be a side track — interesting but
   not the bug).
5. (Reference, NOW DISSOLVED) Session 36
   [`HANDOFF.md`](../2026-05-13-session-36-unpackclosure-probe/HANDOFF.md)
   — what session 37 came in to verify.  The recommendations in
   that HANDOFF (BLACKHOLE→IND update path investigation, lazy
   blackholing disable) are NOT useful and should not be pursued.

## What to try next, in priority order

### Top: Instrument InScopeSet construction in the simplifier

Add per-call dump-on-change to `addNewInScopeIds`,
`setInScopeFromE`, `setInScopeFromF`, and `extendInScope` in
`compiler/GHC/Core/Opt/Simplify/Env.hs`.  Emit `size in_scope`
+ a digest (sorted realUnique list) every time the InScopeSet
changes.  Trigger Big2.hs `-A1m -G1` and find which call sees
the truncated set.

Sketch:

```haskell
addNewInScopeIds env@(SimplEnv { seInScope = in_scope }) vs
  = unsafePerformIO $ do
      let in_scope1 = extendInScopeSetList in_scope vs
      hPutStrLn stderr $ "PROBE38-ADD " ++ show (sizeVarSet in_scope)
                       ++ " → " ++ show (sizeVarSet in_scope1)
      ... existing logic ...
```

Probably do this for **every** function in Env.hs that mutates
seInScope.  The goal is to find the call boundary where
$dOrd_a1k0 (or its analog) was *just there* and *now isn't*.

### Second: cross-reference with sessions 19-28's GC trace data

Sessions 28-29 produced per-closure-type histograms and confirmed
the bug is GC-frequency-sensitive and filename-sensitive.  With
the InScopeSet framing in hand, re-read those traces looking for
**UniqFM tree** allocations being lost or scavenged-but-not-
followed.

### Third: instrument the dependency analyzer for the depSortStgBinds case

For the len=850 panic, a similar approach in
`compiler/GHC/Stg/DepAnal.hs:depAnal`: log every FVs-set creation
and every adjacency-list update.  Goal: confirm a corrupted
adjacency list before the SCC algorithm runs.

### Fourth: -A8m / -A16m sanity check

If the bug is GC-frequency-dependent, increasing nursery size
should eliminate it.  Sweep Big2.hs at `-A1m`, `-A2m`, `-A4m`,
`-A8m`, `-A16m` and confirm the panic rate vs nursery size.  This
is a quick experiment that validates the GC-corruption theory.

### Fifth: reproduce on host GHC 9.2.8

Big2.hs `-A1m -G1` compiled on uranium host ghc-9.2.8 must NOT
panic.  If it does, the bug isn't PPC-unreg-specific.

## Mechanics — picking up where session 37 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree is clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-37 redeploy).

# (a) Re-apply probe37 if you need to re-sweep (with EXISTING data):
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-37-indirectee-and-update-path/probe37-indirectee.patch

# (b) For probe38 (InScopeSet instrumentation), patch addNewInScopeIds
# in Simplify/Env.hs.  See "Top priority" above.

# (c) Build + deploy + sweep:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
bash docs/sessions/2026-05-13-session-37-indirectee-and-update-path/scripts/sweep.sh pmacg5 600 2000 50

# (d) For a focused panic-reproduction with full body:
pad=$(awk 'BEGIN{for(i=1;i<=1648;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
    DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1" \
  | head -30
```

## What NOT to redo

* **Don't pursue any "BLACKHOLE→IND swap" theory.**  That framing
  is fully dissolved.  See F1 of `findings.md`.
* **Don't pursue further closure-shape probes on v.**  v IS the
  evaluated Id; the data was right but the framing was wrong.
* **Don't pursue "PPC unreg's `stg_update_thunk_info` is broken"
  hypothesis.**  The Cmm macro is fine; the update mechanism
  works as designed.
* **Don't pursue the `-O0` vs `-O2` flavour difference** from log.md
  Step 3.  That divergence is real and interesting but is NOT the
  bug — even at -O0, the chained function calls eventually force
  v through `realUnique`'s pattern match and read the correct
  Unique.  The Unique is fine.  The InScopeSet is what's wrong.
* **Don't redo lazy/eager blackholing toggle experiments.**  Doesn't
  apply.

## Hosts (unchanged)

* **uranium** (this Mac): cross-build, source edits.
* **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-37 redeploy).
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked,
    kept from session 30.  Unchanged.
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Time estimate for session 38

* Setup + read handoff: 10-15 min.
* Probe38 (instrument addNewInScopeIds + setInScopeFromE/F): 1-2 h.
* Build + sweep + analyze: 1-2 h.
* If immediately fruitful, dig into the offending boundary: 2-4 h.

Total realistic: 1 medium session (4-6 h) to either find the
boundary where InScopeSet loses entries or confirm it's lost
during GC (not at any boundary).

## Paste-into-fresh-session prompt

```
Context: session 37 of the GHC darwin8-ppc project ran probe37
(probe36 extended to follow word[1] of v's BLACKHOLE closure into
the indirectee).  Outcome was a major REFRAME:

  1. v's word[0] = _stg_BLACKHOLE_info IS the canonical post-
     evaluation state per rts/Updates.h's updateWithIndirection
     macro.  Session 36's "BLACKHOLE→IND swap missing" was a
     misreading.

  2. probe37 + nm confirmed v's indirectee at word[1] & ~3 IS a
     real, fully-formed _ghc_GHCziTypesziVar_Id_con_info closure.
     v has been correctly evaluated.

  3. The panic body reveals the REAL bug: the InScope set at the
     refineFromInScope call site has ONLY 3 entries (wild_00,
     v_B1, allPositive).  $dOrd_a1k0 (the missing typeclass
     dictionary) was supposed to be in scope but legitimately
     isn't.

  4. At len=850 the panic shifts to depSortStgBinds "Found cyclic
     SCC" on $trModule3_r1lT and $trModule4_r1lU whose FVs don't
     actually cycle — another victim of the same underlying
     corruption.

This connects back to sessions 19-28's "GC-corruption-of-UniqMap-
data-structures" framing.  Sessions 33-36's closure-shape probe
trail is fully DISSOLVED — don't pursue further "v's closure looks
wrong" theories.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.

Read in order:
1. docs/sessions/2026-05-13-session-37-indirectee-and-update-path/HANDOFF.md
2. docs/sessions/2026-05-13-session-37-indirectee-and-update-path/README.md
3. docs/sessions/2026-05-13-session-37-indirectee-and-update-path/findings.md
4. docs/sessions/2026-05-13-session-37-indirectee-and-update-path/log.md
5. (reference, DISSOLVED) docs/sessions/2026-05-13-session-36-unpackclosure-probe/HANDOFF.md

Top priority: instrument InScopeSet construction.  Patch
addNewInScopeIds, setInScopeFromE, setInScopeFromF in
compiler/GHC/Core/Opt/Simplify/Env.hs with unsafePerformIO
hPutStrLn dumps showing size + a digest of the elements.  Run
Big2.hs +RTS -A1m -G1 to find where $dOrd_a1k0 falls out of the
set.

Second priority: re-read sessions 28-29's per-closure-type
histograms with the InScopeSet framing in hand — look for UniqFM
tree allocations being scavenged-but-not-followed.

Third priority: -A nursery-size sweep for sanity.

Don't pursue BLACKHOLE→IND theories.  Don't pursue further closure-
shape probes on v.  Don't pursue update-path / stg_update_thunk_info
disassembly.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-37-indirectee-and-update-path/HANDOFF.md`](docs/sessions/2026-05-13-session-37-indirectee-and-update-path/HANDOFF.md).

When session 38 ends, write the next handoff at:
`docs/sessions/<DATE>-session-38-<slug>/HANDOFF.md`.
