# Handoff from session 36 → session 37

**For:** the next claude session.
**From:** session 36 (probe redesigned via `anyToAddr#`; revealed
v is `_stg_BLACKHOLE_info` at the panic site).
**Recommended pickup:** investigate the PPC unreg BLACKHOLE→IND
update path.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe36 reverted).  Stage1 rebuilt clean +
stage2 redeployed to pmacg5 + smoke-test PASS.  v0.12.0 release
unchanged.

## TL;DR — the major finding to carry forward

**At the `refineFromInScope` panic site, v's heap closure is
`_stg_BLACKHOLE_info` (exact match `0x092592a4`) with the indirectee
correctly populated as a tagged pointer to an `Id`-constructor
closure (word[1] tag bits = `0b011` = 3rd ctor of Var).**

The thunk WAS evaluated.  The result IS in the closure (at word[1]).
**Only the info-pointer swap from BLACKHOLE → IND is missing.**

This dissolves sessions 33-35's "v looks like an AArch64.CodeGen
thunk" framing entirely — that was the wrapping-thunk artifact of
the broken probe.  This session's probe36 (using `anyToAddr#`) reads
v's REAL closure, validated by a stand-alone fixture test on both
uranium host-ghc and PPC unreg.

## What we learned

1.  **Probe36 design works** — `anyToAddr#` compiles to a Cmm
    register-to-register move with no wrapping thunk.  Verified by
    `-ddump-stg-final` (`anyToAddr# [x void#]`) and runtime
    distinguishing of THUNK vs WHNF on both host-ghc and PPC unreg.
2.  **`seq v` is a no-op** at the panic site (BEFORE = AFTER in
    every capture).  Either the strictness analyzer DCE'd it
    (compiler thinks v is in WHNF via the `case isLocalId v` match),
    or seq entered BLACKHOLE_entry and forwarded to the indirectee
    without rewriting the header.
3.  **The bug is in the BLACKHOLE→IND swap, not in WHNF forcing.**
    Theory 1 ("isLocalId doesn't force v") is partially-refuted:
    isLocalId DID force v (the indirectee is there).  Theory W
    (probe reads wrapping thunk) is conclusively refuted by the
    stand-alone fixture verifier.
4.  **All missing variables are typeclass dictionaries** (`$dNum_a1ko`,
    `$dOrd_a1k0` in this session; session 35 also saw `$dNum_a1kb`).
    Dictionaries are heap-allocated THUNK_1_0 closures from the
    specializer / desugarer.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session plan + arrival/exit state +
   the 4 captures table.
3. [`findings.md`](findings.md) — full BLACKHOLE→IND analysis,
   the 4 mechanism candidates (a-d), and concrete next-session
   experiments §F5.
4. [`log.md`](log.md) — real-time work log.
5. (Reference, NOW SUPERSEDED) Session 35 [`HANDOFF.md`](../2026-05-13-session-35-stg-dump-and-whnf/HANDOFF.md)
   — what session 36 picked up.

## What to try next, in priority order

### Top: confirm the indirectee is an evaluated `Id` constructor

Extend probe36 to ALSO dump the closure at `word[1] & ~3` (the
untagged indirectee).  Expected: word[0] of the indirectee is
`_ghc_GHCziTypesziVar_Id_con_info` (the Id constructor info-table).
This is a quick, definitive confirmation that v's evaluation
completed correctly — only the BLACKHOLE→IND swap is missing.

Sketch:

```haskell
probe37WhnfDump x = unsafePerformIO $ do
    !addr1 <- probe37AddressOf x
    ws1   <- probe37ReadHeader addr1
    -- NEW: follow word[1] (the indirectee), untagged
    let indirectee = head (drop 1 ws1) .&. complement 3
    indWords <- probe37ReadHeader indirectee
    ...
```

### Second: investigate the BLACKHOLE→IND update path

Read in order:
* `rts/Updates.h` — the `UPD_IND`, `UPD_BH_*` macros.
* `rts/StgUpdates.cmm` (and `rts/Updates.cmm`) — the `stg_update_thunk_info`
  return continuation that does the swap.
* `compiler/GHC/StgToCmm/Bind.hs` `emitBlackHoleCode`,
  `emitUpdateableLetRhs`, and the thunk-entry sequence.
* `rts/sm/Compact.c` `thread()`, `rts/sm/Evac.c` `evacuate_BLACKHOLE`,
  and the lazy-blackholing GC pass.

Specifically suspect: the C code emitted by the PPC unreg backend
for `stg_update_thunk_info`'s return path.  Look at the linked
binary's disassembly of `_stg_update_thunk_info` (find its address
via `nm /opt/ghc-stage2/bin/ghc-real | grep stg_update_thunk_info`,
then `otool -d -V` at that offset).

### Third: experiment — disable lazy blackholing

Find the RTS flag (or compile-time CPP) that disables lazy
blackholing.  Build a stage1 with this disabled, redeploy, sweep.
If the panics disappear, the bug is confirmed in the lazy-BH
interaction with PPC unreg's update path.

### Fourth: experiment — disable eager blackholing in compiled code

`-fno-eager-blackholing` (or whatever GHC 9.2 calls it).  Same
test: rebuild with it off, sweep, see if panics persist.

### Fifth: reproduce on uranium host GHC 9.2.8

The same `Big2.hs` compiled with host ghc-9.2.8 must NOT panic.  If
it does, the bug isn't PPC-unreg-specific.  Diff the simplifier's
trace between host and PPC for a minimal reproducer.

## Mechanics — picking up where session 36 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree is clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild (session-end-36 redeploy).

# (a) Re-apply probe36 if you need to re-sweep:
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-13-session-36-unpackclosure-probe/probe36-anyToAddr.patch

# (b) Then build + deploy:
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# (c) Re-sweep:
bash docs/sessions/2026-05-13-session-36-unpackclosure-probe/scripts/sweep.sh pmacg5 600 2000 50

# (d) For probe37 (with indirectee follow), modify
# docs/.../probe36-anyToAddr.patch's probe36ReadHeader / probe36WhnfDump
# to also dereference word[1] & ~3.
```

## What NOT to redo

* **Don't redo the probe-design exercise** — `anyToAddr#` is the
  right primop.  Documented in `findings.md` F1.
* **Don't redo the stand-alone fixture verifier** — already
  confirmed clean.  See `probe36_verify.hs` + `logs/verify-*.log`.
* **Don't trust theory W** (probe reads wrapping thunk) — fully
  resolved.  probe36 reads v's real closure.
* **Don't trust the AArch64.CodeGen identification from session 34**
  — that was a structural coincidence in session 33's binary
  layout, dissolved in session 35.
* **Don't redo the env-var bisect / address probe / cross-run
  address diff** — sessions 31-33 ruled those out.

## Hosts (unchanged)

* **uranium** (this Mac): cross-build, source edits.
* **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-36 rebuild).
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked,
    kept from session 30.  Unchanged.
* **imacg3**: not used.
* **indium**: don't use for clang/hadrian builds.

## Time estimate for session 37

* Setup + read handoff: 10-15 min.
* Probe37 (add word[1] follow) + build + sweep: ~1 hour.
* Investigate UPD_IND / stg_update_thunk_info path: 2-4 hours.
* If lazy-blackholing-disable experiment narrows it: another 1-2 h.

Total realistic: 1 medium session (4-6 h) to either fix the bug or
nail down the exact failing macro / code path.

## Paste-into-fresh-session prompt

```
Context: session 36 of the GHC darwin8-ppc project redesigned the
refineFromInScope panic probe using GHC.Exts.anyToAddr# (a polymorphic
primop that compiles to a Cmm register-to-register move with no
wrapping thunk -- unlike session 35's aToWordzh + unsafeCoerce which
wrapped v in an intermediate thunk).  The probe was verified clean on
both uranium host-ghc and PPC unreg cross-stage1 via a stand-alone
fixture program that distinguishes WHNF, thunk, and seq-forced cases.

Sweep on pmacg5 with the same Big2.hs trigger captured 4 panics in 2
env-len zones (850/900 missing $dNum_a1ko, 1650/1700 missing $dOrd_a1k0).
ALL FOUR captures show:

  * BEFORE == AFTER (`seq v` is a no-op)
  * word[0] is exactly 0x092592a4 = _stg_BLACKHOLE_info
  * word[1] has tag bits 0b011 (= 3rd ctor of Var = `Id`), so it is
    a tagged pointer to an evaluated Id constructor closure.

The thunk WAS evaluated -- the indirectee at word[1] is correctly
populated.  The bug is that v's info-pointer was NEVER swapped from
_stg_BLACKHOLE_info to _stg_IND_info after evaluation completed.

This is the PPC unreg bug, isolated to the BLACKHOLE→IND update path
(`stg_update_thunk_info` in rts/Updates.cmm, `UPD_IND` macro in
rts/Updates.h, and/or the lazy-blackholing GC pass in rts/sm/).

Session 36 ended CLEAN: probe reverted, stage1 rebuilt, stage2
redeployed to pmacg5 + smoke-test PASS.

Read in order:
1. docs/sessions/2026-05-13-session-36-unpackclosure-probe/HANDOFF.md
2. docs/sessions/2026-05-13-session-36-unpackclosure-probe/README.md
3. docs/sessions/2026-05-13-session-36-unpackclosure-probe/findings.md
4. docs/sessions/2026-05-13-session-36-unpackclosure-probe/log.md
5. (reference, NOW SUPERSEDED) docs/sessions/2026-05-13-session-35-stg-dump-and-whnf/HANDOFF.md

Top priority: extend probe36 to follow word[1] (untagged) and confirm
the indirectee's info-pointer is _ghc_GHCziTypesziVar_Id_con_info.

Second priority: investigate stg_update_thunk_info / UPD_IND in
rts/Updates.cmm + rts/Updates.h, plus the PPC unreg backend's
emission of the thunk-update sequence.

Third priority: experiment -- disable lazy blackholing (RTS flag or
compile-time switch) and re-run the trigger.  If panics disappear,
the bug is in the lazy-BH ↔ PPC update-path interaction.

Fourth priority: reproduce on uranium host GHC 9.2.8 to confirm the
bug is PPC-unreg-specific.

Don't redo probe design.  Don't trust session 33/34 thunk
identifications.  Don't redo session 31/32 framings.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-36-unpackclosure-probe/HANDOFF.md`](docs/sessions/2026-05-13-session-36-unpackclosure-probe/HANDOFF.md).

When session 37 ends, write the next handoff at:
`docs/sessions/<DATE>-session-37-<slug>/HANDOFF.md`.
