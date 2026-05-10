# Handoff from session 23 → session 24

**For:** the next claude session.
**From:** session 23 (stage2 GC bug, round 5; PROBE22POISON
confirmed real bug; 2026-05-10).
**Recommended pickup:** identify the exact StackRep / info table in
cross-built `GHC.Data.FastString` whose bitmap mis-classifies the
`Sp+12` slot of the `_blk_c7te`-containing frame, then look at the
StgToCmm / LayoutStack code path that produces it.

## TL;DR (mandatory read)

- **Bug is real.**  PROBE22POISON (replace non-evac heap-shapes on
  the running TSO's stack with `0xDEADBEEF` post-scavenge) caused
  stage2 ghc compiling M5.hs under `+RTS -A1m -RTS` to crash
  deterministically (5/5 iterations) at `_blk_c7te + 112` with
  `EXC_BAD_ACCESS at 0xdeadbeef`, in `__memcpy(_, src=0xdeadbeef, 16)`.
  The src came from `MEM[Sp+12]` = slot 6 in PROBE22 coordinates of
  the most recent (gc_no=2) GC.  Pre-poison value `0x0bf5f38a` was a
  tagged heap pointer in a non-evacuated nursery block.
- **Location: `GHC.Data.FastString`.**  `_blk_c7te` lives at
  `0x01fa47b0` in stage2's text, between `_s77C_entry` and
  `_ghc_GHCziDataziFastString_mkFastStringByteString_entry` per `nm`.
  The 16-byte memcpy with dst=fresh-heap+8, src=stack-loaded-pointer
  matches the pattern of a `copyByteArray#` inside a FastString
  constructor.
- **Session 22's audit of Catch.hs stands.**  Catch's PNP frames
  really are dead-slot-correct.  But session 22's broader worry —
  "the bug must be in another module" — is now confirmed and
  localised to FastString.
- v0.12.0 ships unchanged.  Stage2 on pmacg5 was reverted to clean
  RTS at session-23 end.

## Read in order

1. **This file** (the handoff).
2. [`README.md`](README.md) — narrative of session 23.
3. [`findings.md`](findings.md) — measurement detail and slot-
   correlation arithmetic.
4. (Reference) [Session 22
   findings](../2026-05-10-session-22-stage2-bitmap-bug/findings.md)
   — the per-block audit that ruled out Catch.hs.
5. (Reference) [`../../log/session23/ghc-real.crash.log`](../../../log/session23/ghc-real.crash.log)
   — full crash dumps if you need register state.
6. (Reference) [`../../log/session23/blk_c7te.disasm`](../../../log/session23/blk_c7te.disasm)
   — disassembly of the crashing block.

## What to NOT redo

- **Don't re-run PROBE22POISON expecting different attribution.**  The
  experiment is decisive in the direction it ran: 1 slot read = real
  bug, 8 other poisoned slots = PROBE21 false positives.  Re-running
  will reproduce.  Apply only if you change the poison strategy
  (e.g., poison only bitmap-non-pointer slots — see *experiments to
  consider* below).
- **Don't re-audit Catch.hs.**  Session 22 settled it.  The bug isn't
  there.
- **Don't trust nm to give you a clean function-to-block mapping.**
  `_blk_c7te` is one of several blocks compiled into the area
  between `_s77C_entry` and `_ghc_...mkFastStringByteString_entry`,
  but `nm`'s sort order doesn't unambiguously identify which Cmm
  function it belongs to.  Re-cross-compile FastString.hs with
  `-ddump-cmm-final` and grep for `block_c7te` (the Cmm-level form
  of the assembly label `__blk_c7te`).
- **Don't poison and run on a smoke-test program** (e.g., Hello.hs)
  expecting to see this crash.  PROBE22POISON only causes a crash
  if a real missed-root slot exists in the stack at the right time.
  Hello.hs is too short for its stack to contain a FastString
  continuation.  Use M5.hs (or any input that triggers the typechecker
  hard enough to allocate FastStrings — most non-trivial inputs).

## What to try next, in priority order

### Top: identify the offending StackRep in FastString.hs's Cmm

```
cd /Users/cell/claude/ghc-darwin8-ppc
PPC_GHC=$PWD/external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc
SRC=$PWD/external/ghc-modern/ghc-9.2.8/compiler/GHC/Data
mkdir -p log/session24/cross
cd log/session24/cross
$PPC_GHC --make -c -O2 -ddump-cmm -ddump-cmm-final -ddump-stg-final \
    -outputdir . -odir . -hidir . -i$SRC \
    -hide-package ghc -package-id ghc-9.2.8 \
    $SRC/FastString.hs > faststring-O2.dump 2>&1
```

(May need extra `-package-id` flags; FastString depends on the rest of
GHC.  If the standalone compile is too painful, you can also extract
the relevant slice from the stage1 build's `_build/stage1/compiler/build/GHC/Data/FastString.dump-cmm-final`
if it was written; many builds skip those dumps.)

Then:

```
grep -n "block_c7te\|c7te" faststring-O2.dump | head
```

If the block name matches: cross-reference its info table (the
function-entry symbol just before it) and read the `info_tbls`
StackRep.

If the block name doesn't match (because uniques change between
compiles), you can attribute by:
1. Look at the C-- entry name nearest the block in the dump.
2. Count by signature: a block whose body does
   `lwz r4, 0xc(r2)` … `lwz r5, 0x8(r2)` … `bl _memcpy`
   should be unique within FastString and easy to grep for in the
   `Output Cmm` section.

### Second: extend `audit-all-true-frames.py` to FastString

Once the dump exists, run session 22's audit script on it (after a
1-line edit to point at the new path):

```
python3 docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/scripts/audit-all-true-frames.py
```

For Catch the audit was 0 reads / 15 writes (all false positives).
For FastString we expect at least one True-marked slot to be **read**
— specifically the one that becomes `Sp+12` in `_blk_c7te`.  That's
the smoking gun for "StackRep is wrong here."

### Third: instrument `stackMapToLiveness` for the offending function

Once the offending function is identified, add a debug print in
`compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness`:

```haskell
stackMapToLiveness platform StackMap{..} =
  let liveness = [ ... ]
  in pprTrace "stackMapToLiveness"
       (vcat [ text "sm_sp" <+> ppr sm_sp
             , text "sm_args" <+> ppr sm_args
             , text "sm_ret_off" <+> ppr sm_ret_off
             , text "sm_regs (ptr only)" <+>
                 ppr [r | (_, (r,_)) <- nonDetUFMToList sm_regs
                        , isGcPtrType (localRegType r)]
             , text "live_words" <+> ppr [...]
             ]) liveness
```

Filter to "only print for the offending unique" by either grepping
post hoc or guarding the trace by the function's compilation
context.

12-15 min stage1 rebuild after the edit.

### Fourth: bisect — try other inputs

If the FastString analysis stalls, run PROBE22POISON on bigger
inputs:

```
echo 'module B where' > /tmp/B.hs
echo 'main = putStrLn (show (sum [1..1000::Int]))' >> /tmp/B.hs
ssh pmacg5 'DYLD=... /opt/ghc-stage2/bin/ghc-real --make /tmp/B.hs -o /tmp/B +RTS -A1m -RTS' 2>&1 | grep PROBE22
```

A bigger compile may surface more PROBE22-detected reads in
*different* modules — useful for confirming "FastString is one of
several" vs "FastString is THE one."

## Mechanics — how to reproduce session-23 results

### Re-apply PROBE22POISON

```
cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-10-session-23-stage2-poison-probe/probe22-poison-stack.patch
```

(Also fine to copy the C block from
[`probe22-poison-stack.patch`](probe22-poison-stack.patch) into
`rts/sm/GC.c` by hand; insertion point is right before
`resize_nursery();` in `GarbageCollect()`.)

### RTS-only rebuild

```
source ../../../scripts/cross-env.sh > /dev/null 2>&1
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
# ~3 min for incremental RTS rebuild (all 12 ways batched)
```

### Re-link + deploy

```
cd /Users/cell/claude/ghc-darwin8-ppc
bash scripts/deploy-stage2.sh pmacg5
# ~5 min for cross-link + scp + smoke test
```

### Run the experiment

```
bash docs/sessions/2026-05-10-session-23-stage2-poison-probe/scripts/run-poison.sh pmacg5
# Captures 5 × M5.hs runs + 2 controls in ~30s.
```

### Pull the crash log

```
ssh pmacg5 'cat ~/Library/Logs/CrashReporter/ghc-real.crash.log' \
  > log/session24/ghc-real.crash.log
```

### Restore stage2 to clean state

```
cd external/ghc-modern/ghc-9.2.8
git checkout rts/sm/GC.c
source ../../../scripts/cross-env.sh > /dev/null 2>&1
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

## Hosts (unchanged from session 22)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  ssh works without password.  Where the bug fires.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: trimmed dev tools — don't use for clang or
  hadrian builds (no Xcode).

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/rts/sm/GC.c` — **clean** (revert
  applied at session-23 end).
- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSrts-1.0.2*.a`
  — **clean RTS** rebuilt + redeployed (no PROBE22 instrumentation).
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — **clean** (matches
  v0.12.0).
- `log/session23/` exists with the crash log + per-iter PROBE logs +
  block disassembly (gitignored).

## Time estimate for session 24

- Setup + read handoff: 15 min.
- Cross-compile FastString.hs alone with `-ddump-cmm`: 10–30 min
  (depends on how clean the standalone-compile recipe is).
- Audit dump for read-after-poison candidates: 30 min.
- Identify the offending info table + StackRep: 30 min.
- Compare to session 22's Catch audit; characterise the codegen
  difference: 30 min.
- Decide on next probe (LayoutStack instrumentation, or further
  Cmm-level bisection): 30 min.
- Writeup: 30 min.

Realistic: 1 medium session (~3-5 h) to localise the bug to a
specific Cmm-level info table and have a hypothesis for why
LayoutStack got it wrong.  Then probably another session (~3-5 h) to
patch LayoutStack and verify the fix removes the read-after-poison
event.

## Paste-into-fresh-session prompt

```
Context: just finished session 23 (stage2 GC bug round 5; PROBE22POISON).
Bug is REAL.  PROBE22POISON replaces non-evac heap-shapes on the running
TSO's stack with 0xDEADBEEF post-scavenge.  Stage2 ghc compiling M5.hs
under +RTS -A1m -RTS then crashed deterministically (5/5 iterations) at
_blk_c7te + 112 with EXC_BAD_ACCESS at 0xdeadbeef, in
__memcpy(_, src=0xdeadbeef, 16).  Src came from MEM[Sp+12] = slot 6 in
PROBE22 coordinates of gc_no=2 (most recent GC).  Pre-poison value
0x0bf5f38a was a tagged heap pointer.

Location: _blk_c7te lives between _s77C_entry and
_ghc_GHCziDataziFastString_mkFastStringByteString_entry per nm — i.e.
in some local closure / continuation Cmm block in GHC.Data.FastString's
compilation unit.  16-byte memcpy with dst=fresh-heap+8 looks like a
copyByteArray# inside FastString construction.

Session 22's per-block audit of Catch.hs stands — Catch frames are
dead-slot-correct.  The bug is in a DIFFERENT module's bitmap.

Read in order:
1. docs/sessions/2026-05-10-session-23-stage2-poison-probe/HANDOFF.md
2. docs/sessions/2026-05-10-session-23-stage2-poison-probe/README.md
3. docs/sessions/2026-05-10-session-23-stage2-poison-probe/findings.md

Then the recommended next experiment: re-cross-compile FastString.hs
with -ddump-cmm-final, grep for block_c7te (or its sibling), find the
StackRep of the enclosing info table, and check whether the True-marked
slot at index 2 (corresponding to MEM[Sp+12]) is a real pointer that
the bitmap mis-classifies.  Then trace back to
compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness for that frame.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's -A1G wrapper.

Unsupervised mode is project default.
```
