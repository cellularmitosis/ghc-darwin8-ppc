# Session 37 — probe37 dissolves session 36's framing; real bug is InScopeSet corruption (back to sessions 19-28's GC theory)

**Dates:** 2026-05-13 (continuation of session 36; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-36 exit.
`pmacg5:/opt/ghc-stage2/bin/ghc-real` is the clean v0.12.0+ rebuild
(no probes).  v0.12.0 release unchanged.

**Status on exit:** CLEAN.  Probe37 reverted, stage1 rebuilt clean,
stage2 redeployed to pmacg5 + smoke-test PASS.  **Major reframe:**
session 36's "BLACKHOLE→IND swap missing" theory was a misreading
of `rts/Updates.h` — BLACKHOLE+tagged-indirectee IS the canonical
post-evaluation state.  Probe37 confirmed the indirectee is a
real, fully-formed `_ghc_GHCziTypesziVar_Id_con_info` closure.
The actual bug — visible in the panic's `InScope {wild_00 v_B1
allPositive}` body — is that the InScopeSet legitimately doesn't
contain `$dOrd_a1k0`.  This connects back to sessions 19-28's
"GC corruption of UniqMap-backed data structures" framing, and
**dissolves sessions 33-36's closure-shape probe trail as a wild
goose chase.**

## Plan

Session 36 captured v's REAL closure header at `refineFromInScope`'s
panic site using `anyToAddr#` (no wrapping-thunk artefact) and
discovered that **v's `word[0]` is exactly `_stg_BLACKHOLE_info`
with `word[1]` being a tagged pointer to (presumably) the evaluated
`Id` constructor closure.**

The thunk WAS evaluated; the result IS at `word[1]`; only the
BLACKHOLE→IND info-pointer swap is missing.  Session 36 finished
CLEAN.

Session 37 picks up from there.

### Top priority

**Confirm the indirectee is an evaluated `Id` constructor closure**
by extending probe36 to also dump 4 words at `word[1] & ~3` (the
untagged indirectee pointer).  Expected: `word[0]` of the indirectee
is `_ghc_GHCziTypesziVar_Id_con_info` (or the closely-related Id
constructor info-table address).  This is the cleanest definitive
proof that v's evaluation completed correctly — only the BLACKHOLE→IND
swap is missing.

### Second priority

**Investigate the BLACKHOLE→IND update path on PPC unreg.** Read
the relevant RTS code:
- `rts/Updates.h` — `UPD_IND`, `UPD_BH_*` macros, the wakeup logic.
- `rts/Updates.cmm` — `stg_update_thunk_info` Cmm code.
- `rts/StgMiscClosures.cmm` — `stg_BLACKHOLE_info`'s entry code and
  forwarding logic.
- `compiler/GHC/StgToCmm/Bind.hs` — `emitBlackHoleCode`,
  `emitUpdateableLetRhs`, and the thunk-entry / update-frame sequence.

Specifically: disassemble `_stg_update_thunk_info` in the deployed
PPC stage2 binary and look for a missing info-pointer store (or a
mis-ordered store that races against a GC pass).

### Third priority (if time)

Experiment with **disabling lazy blackholing** (RTS flag or compile-
time CPP) to see if the panics disappear; this would localize the
bug to the lazy-BH ↔ PPC-unreg update-path interaction.

### Fourth priority (if time)

Compare against **uranium host GHC 9.2.8** with the same Big2.hs
trigger — should NOT panic.

## What happened

### Phase 1 — read rts/Updates.h

`updateWithIndirection` macro (`rts/Updates.h:48-67`) revealed
that after a thunk evaluates, the canonical state is:

```
word[0] = stg_BLACKHOLE_info        (NOT stg_IND_info!)
word[1] = tagged-pointer-to-result  (indirectee)
```

And `stg_BLACKHOLE_entry` (`rts/StgMiscClosures.cmm:487-492`)
checks `if (GETTAG(indirectee) != 0) return (p);` — i.e., returns
the tagged result to the caller as a normal forced-WHNF value.

**Session 36's "BLACKHOLE→IND swap missing" framing was based on
the assumption that `stg_BLACKHOLE_info` was an incomplete-update
artefact.  It isn't.  It's the normal post-evaluation state.**

### Phase 2 — probe37 captures the indirectee

`probe37-indirectee.patch` adds a 4-word dump at `word[1] & ~3`
on top of probe36's BEFORE/AFTER lines.

Build + deploy + sweep results: 2 captures (at len=1650/1700).
The indirectee at `0xd9bda68` has `word[0] = 0x90662c4`.  `nm`
resolves this exact address to
**`_ghc_GHCziTypesziVar_Id_con_info`** — confirming v's evaluation
produced a real `Id` constructor closure.

### Phase 3 — the panic body reveals the real bug

The full panic message at len=1650:

```
ghc-real: panic! (the 'impossible' happened)
  refineFromInScope PROBE37-INDIRECTEE-AFTER @0xd9bda68 [...]
  InScope {wild_00 v_B1 allPositive}      ← only 3 entries!
  $dOrd_a1k0                                ← missing var
```

**The `InScope` set legitimately contains only 3 entries.**  The
missing `$dOrd_a1k0` (typeclass dictionary for `Ord`, used by
Big2.hs's `topK`) was supposed to be there but isn't.  This is
a downstream symptom of GC corruption in the UniqFM-backed
InScopeSet — exactly the family of bugs sessions 19-28 documented.

### Phase 4 — at len=850 the panic shape shifts

`depSortStgBinds` panics with "Found cyclic SCC" on
`$trModule3_r1lT` and `$trModule4_r1lU`, two top-level module-
tracking metadata bindings whose FVs (per the pprPanic output)
do NOT form a cycle.  Same underlying corruption, different
victim data structure — consistent with session 28's "one bug,
multiple victim data structures" finding.

### Phase 5 — revert + clean rebuild + redeploy

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` —
  probe reverted.
* Stage1 clean rebuild: `logs/build2-clean.log`.
* Stage2 redeploy: `logs/deploy2-clean.log`.
* Smoke-test PASS.
* Baseline tests (post-revert): see `logs/baseline-tests-end.log`.

Session ended CLEAN.

## Files added this session

* `README.md` (this), [`log.md`](log.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`commits.md`](commits.md).
* `probe37-indirectee.patch` — probe36 + word[1] follow.
* `scripts/sweep.sh` — sweep helper (PROBE37-prefixed greps).
* `scripts/identify-symbols.sh` — post-sweep symbol identification.
* `logs/build1-probe37.log` — probe37 build.
* `logs/deploy1-probe37.log` — probe37 deploy.
* `logs/sweep1-broad.log` — probe37 sweep across env-len 600..2000.
* `logs/panic-trigger-len1650.log` — full panic body at len=1650.
* `logs/build2-clean.log` — clean rebuild.
* `logs/deploy2-clean.log` — clean redeploy.
* `logs/baseline-tests-end.log` — post-revert baseline.

## Top finding to carry into session 38

**The InScopeSet at the panic site is missing entries (legitimately
only 3 entries in a context that should have many).**  The bug is
upstream of `refineFromInScope` — likely a GC-of-UniqMap corruption
of `seInScope` or `seIdSubst` during simplifier descent.  See
[`findings.md`](findings.md) §F6 for concrete next-session targets
and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.

Session 36's closure-shape probe family was based on a misreading
of `rts/Updates.h`; the indirectee data was correct but the
"BLACKHOLE→IND swap missing" diagnosis was wrong.  **Future
sessions should not pursue further closure-shape probes on v.**
The right next step is to instrument InScopeSet construction.
