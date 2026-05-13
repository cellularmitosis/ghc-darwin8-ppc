# Handoff from session 22 → session 23

**For:** the next claude session.
**From:** session 22 (stage2 GC bug, round 4; 2026-05-10).
**Recommended pickup:** build the **poison-on-stale-slot RTS
patch** — it decisively distinguishes "real GC bug" from
"PROBE21 false positive" without further bitmap analysis.

## TL;DR (mandatory read)

- v0.12.0 still ships unchanged.  Stage2 still uses `-A1G`
  workaround.
- **Session 21's hypothesis ("bitmap is wrong") does NOT
  survive scrutiny for Catch.hs's PNP/PN frames.**  Per-block
  audit of all 15 `True`-containing StackReps in cross-built
  Catch.hs shows the True-marked slots are **never read** by
  the body — only written/overwritten or passed-through-then-
  popped.  The bitmap is **the right answer**.
- Cross-host comparison: cross has 8× more True-bit StackReps
  on Catch than host, but the audited host frames have the
  same dead-slot pattern.  Difference is 32-bit codegen layout,
  not misclassification.
- Therefore the dominant 93/106 BAD pay=1 events PROBE21
  attributed to 4 PNP/PN info tables in Catch.hs are most
  likely **PROBE21 false positives** — heap-shaped values
  legitimately stranded in dead slots.
- **The actual stage2 GC crash is real** (session 19
  reproduced it deterministically with `-DS`); it just isn't
  in the frames PROBE21 has been pointing at.  Need a
  different probe to find it.

## Read in order

1. **This file** (the handoff).
2. [`README.md`](README.md) — narrative of session 22.
3. [`findings.md`](findings.md) — measurement detail and
   bit-order verification.
4. (Reference) [Session 21
   findings](../2026-05-10-session-21-stage2-bitmap-bug/findings.md)
   — the hypothesis we just disproved.
5. (Reference) [Session 20
   findings](../2026-05-10-session-20-stage2-gc-bug-round2/findings.md)
   — original PROBE20/21 patches and BAD-event data.

## What to NOT redo

- **Don't re-audit Catch.hs PNP frames.**  All 15 are
  audited in
  [`findings.md`](findings.md) — every True-slot is dead
  from its block's perspective.  Re-running the audit will
  produce the same answer.
- **Don't instrument `stackMapToLiveness` in LayoutStack.**
  Session 21's HANDOFF recommended this, but the per-block
  audit already establishes that the bitmap is the right
  answer for those frames.  A debug print in
  `stackMapToLiveness` would only confirm what we already
  know empirically.  Defer until/unless you find a frame
  whose body really does read a True-marked slot.
- **Don't re-decode bitmap word semantics.**  Bit 0 = first
  slot above the info pointer, in BOTH compiler and runtime.
  End-to-end verified.  `[F,T,F]` → bits=0b010, size=3,
  word=0x43.
- **Don't trust PROBE21's `is_ptr=0` as evidence of a
  missed root.**  PROBE21 detects "value is heap-shaped AND
  enclosing block is not BF_EVACUATED."  This is necessary
  but not sufficient for "this slot is a missed GC root."
  A truly-dead slot satisfies the heuristic without being a
  bug.

## What to try next, in priority order

### Top: poison-on-stale-slot RTS patch — decisive

**Goal:** distinguish "real missed root" from "stranded
dead-slot heap-shape."

**Approach:** in `rts/sm/GC.c::GarbageCollect`, after all
scavenging is done but before `resetNurseries()` (same
location PROBE21 already runs), walk the running TSO's stack
and **overwrite** each non-evac heap-shaped slot value with
a sentinel like `0xDEADBEEF`.

```c
/* PROBE22POISON: replace BAD slot values with sentinel.
 * If anyone reads this slot later, the value will be
 * 0xDEADBEEF — easy to spot in a crash backtrace. */
for (StgPtr p = probe_sp; p < probe_sp_tso_stack_end; p++) {
    StgWord w = *p;
    if (HEAP_ALLOCED((void*)w)) {
        bdescr *bd = Bdescr((P_)(w & ~(StgWord)3));
        if (bd && !(bd->flags & BF_EVACUATED)) {
            *p = (StgWord)0xDEADBEEF;
        }
    }
}
```

(Be careful to do this BEFORE `resetNurseries()` — once
nurseries are recycled, the BF_EVACUATED check is meaningless.)

**Decision rules:**
- If stage2 ghc crashes at `0xDEADBEEF` → that slot was
  being read.  Real bug.  The crash backtrace tells you
  WHERE in the code the read happens.
- If stage2 ghc still crashes at the original "variable
  not found `$trModule2_xxx`" panic → the BAD slots are
  truly dead, the bug is elsewhere (a different scanning
  failure: SRT, CAF, RET_FUN/RET_BCO, or RTS-internal).
- If stage2 ghc starts working → impossible, but if so the
  poison is somehow benign and we have new information.

**Build:** RTS-only change — `Scav.c` / `GC.c` patches
typically rebuild in 2-5 minutes (`./hadrian/build
--flavour=quick-cross -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_thr.a`
or just nuke that dir and rebuild).  No stage1-compiler-
itself rebuild needed.

**Deploy:** the RTS lib is statically linked into stage2
ghc binaries.  Re-link a test program (or rebuild stage2 ghc
itself) to pick up the patched RTS.

**Run:** stage2 ghc compiling M5.hs (the standard repro from
session 19) under `+RTS -A1m`.  If the poison patch fires
and 0xDEADBEEF gets read, the segfault address will be
`0xDEADBEEF` (or a small offset).

### Second: audit Map.Internal frames the same way

`scripts/audit-all-true-frames.py` should run cleanly on
[`docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/logs/cmm-cross/internal-O2.dump`](../docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/logs/cmm-cross/internal-O2.dump)
(~6.9 MB, 45+ PN and 25+ PNP info tables per session 21
counts).

If even ONE Map.Internal frame's body reads its True-marked
slot, that's a real bug candidate — focus there.  If none do
(consistent with Catch.hs), broadens the case that the bug
is RTS-side, not StackRep-side.

```
python3 docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/scripts/audit-all-true-frames.py
```

(The script hard-codes the Catch path; a 5-line edit
parameterises it for any module.)

### Third: PROBE21 extension to attribute RET_FUN / RET_BCO

PROBE21 currently bails out at the first RET_FUN / RET_BCO
frame.  Per session 20, ~31 of 215 PROBE20 BAD slots fall
in those skipped portions.  Implementing `scavenge_arg_block`-
equivalent layout for RET_FUN (and BCO bitmap decoding for
RET_BCO) in PROBE21 would close this gap.

The RTS already has the layout decoders; we just need to
adapt them to PROBE21's "report-only, don't evacuate"
mode.

### Fourth: examine CAF revert / SRT scanning

Session 19 had a `markCAFs-count.patch` probe that wasn't
followed up after PROBE20/21 re-framed the question.
Worth a look:

- Are SRTs being walked correctly during major GC?
- Are CAFs being correctly REVERTED to thunks for re-evaluation
  on subsequent collections?
- Is the SRT bitmap encoding subject to the same scrutiny
  as the stack-frame bitmap?

If a typechecker-CAF gets collected when it shouldn't, the
"variable not found" symptom is exactly what we'd expect.

## Mechanics — how to reproduce session-22 results

### Audit any Cmm dump for True-slot reads/writes

```
cd /Users/cell/claude/ghc-darwin8-ppc
python3 docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/scripts/audit-all-true-frames.py
# Edit the script's hard-coded path to point at any other
# Cmm dump (e.g. docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/logs/cmm-cross/internal-O2.dump).
```

### Re-cross-compile a single module with -ddump-cmm

(Same as session 21's recipe; works fine.)

```
cd /Users/cell/claude/ghc-darwin8-ppc
PPC_GHC=$PWD/external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc
SRC=$PWD/external/ghc-modern/ghc-9.2.8/libraries/exceptions/src
mkdir -p docs/sessions/2026-05-10-session-23-stage2-poison-probe/logs/cross
cd docs/sessions/2026-05-10-session-23-stage2-poison-probe/logs/cross
$PPC_GHC --make -c -O2 -ddump-cmm -ddump-cmm-final -ddump-stg-final \
    -outputdir . -odir . -hidir . -i$SRC -hide-package exceptions \
    $SRC/Control/Monad/Catch.hs > catch-O2.dump 2>&1
```

### Compile same module with HOST GHC for comparison

```
cd /Users/cell/claude/ghc-darwin8-ppc
mkdir -p docs/sessions/2026-05-10-session-23-stage2-poison-probe/logs/host
cd docs/sessions/2026-05-10-session-23-stage2-poison-probe/logs/host
SRC=$PWD/../../../external/ghc-modern/ghc-9.2.8/libraries/exceptions/src
~/.local/ghc-9.2.8/bin/ghc --make -c -O2 -ddump-cmm \
    -outputdir . -i$SRC -hide-package exceptions \
    $SRC/Control/Monad/Catch.hs > catch-host-O2.dump 2>&1
```

(Note: -ddump-cmm-final is unsupported on the host GHC; use
just -ddump-cmm.  In 9.2.8 both produce the `Output Cmm`
section that contains `StackRep [...]` lines.)

### RTS-only rebuild (when you start the poison experiment)

```
cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null 2>&1
# edit rts/sm/GC.c
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_thr.a
# ~3-5 min for incremental RTS rebuild
# Then re-link any program that needs the patched RTS.
```

## Hosts (unchanged from session 21)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  ssh works without password.  Where the bug fires.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: trimmed dev tools — don't use for clang or
  hadrian builds (no Xcode).

## What's clean / dirty in the source tree

- All `compiler/` and `rts/` files **untouched** by session 22
  (read-only investigation).
- `external/ghc-modern/ghc-9.2.8/_build/stage1/...` — **unchanged**
  cross-built tree.  No probe / instrumentation patches applied.
- `logs/host/catch-host-O2.dump` exists with the host
  build output (~22.5k lines, gitignored).  Clean up with
  `rm -rf logs/` if needed.
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — unchanged
  (production stage2 with `-A1G` wrapper).

## Time estimate for session 23

- Setup + read handoff: 15 min.
- Implement poison-on-stale-slot patch in GC.c: 30 min.
- RTS-only rebuild: 5 min.
- Re-link stage2 ghc with patched RTS, deploy to pmacg5: 10 min.
- Run M5.hs, observe crash address: 5 min.
- Interpret result + write up: 30-60 min.

Realistic: 1 short session to definitively resolve "is the
bug in the bitmap or somewhere else?"  If somewhere else,
plan the next probe.  If in the bitmap, the crash backtrace
gives us the read site and we can trace back to the source.

## Paste-into-fresh-session prompt

```
Context: just finished session 22 (stage2 GC bug round 4).
Session 21's hypothesis ("the bug is in the bitmap output of
StgToCmm/LayoutStack for PNP/PN frames in Catch.hs") does NOT
survive scrutiny.  Per-block audit of all 15 True-containing
StackReps in cross-built Catch.hs shows the True-marked slots
are never read by the body — only written/overwritten or
passed-through-then-popped.  The bitmap is the right answer
for those frames.  Therefore PROBE21's BAD events for the
4 dominant Catch.hs info tables are PROBE21 false positives
(heap-shaped values stranded in genuinely-dead slots that GC
correctly skips).

Cross-host comparison on the same Catch.hs: cross has 8x
more True-bits in StackReps than host, but the audited host
frames have the same dead-slot pattern.  Difference is just
32-bit codegen layout, not misclassification.

The stage2 GC crash is real (session 19 reproduced
deterministically under -DS).  It just isn't in the frames
PROBE21 has been pointing at.

Read in order:
1. docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/HANDOFF.md
2. docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/README.md
3. docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/findings.md

Then the recommended next experiment: build the
poison-on-stale-slot RTS patch.  In rts/sm/GC.c after PROBE21's
walker (before resetNurseries), overwrite each non-evac
heap-shaped stack slot value with 0xDEADBEEF.  Rebuild RTS
(quick-cross flavour, ~5 min), re-link stage2 ghc, deploy to
pmacg5, run M5.hs under -A1m.  If crash address = 0xDEADBEEF,
the slot was being read = real bug.  If crash is the original
"variable not found" panic, slots are truly dead, look
elsewhere (RET_FUN/RET_BCO, RTS scavenger, CAFs/SRTs).

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's -A1G wrapper.

Unsupervised mode is project default.
```
