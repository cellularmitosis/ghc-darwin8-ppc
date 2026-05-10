# Session 20 — stage2 GC bug investigation, round 2

**Dates:** 2026-05-10 (continued from session 19 close).
**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc
on Tiger uses `+RTS -A1G` workaround.  Session 19 ruled out three
big hypotheses (SMP atomics, `large_alloc_lim` overflow, CAF-list
truncation) and fingered "missed root in non-heap state" — top
suspect was PPC32 `StgRegTable` field-offset mismatch / TSO stack
walk on PPC32.

**Status on exit:** **bug found.**  Specifically: stage2 ghc's
running-thread stack contains 184 slots (deterministic) that hold
real heap pointers but whose enclosing stack-frame bitmaps mark
them as non-pointers.  GC dutifully skips, pointers go stale,
typechecker reads garbage, panic.  Affects 14+ distinct info
tables across 6+ modules (Data.Map.Strict.Internal,
Control.Monad.Catch, GHC.Iface.Binary, GHC.Base, etc.).  Root
cause (why bitmaps are wrong) **not yet identified** — that's the
session-21 task.  v0.12.0 / `-A1G` workaround unchanged.

## What we did, in order

### Step 1 — kill the StgRegTable-offset hypothesis

Session-19 HANDOFF's top suspect was a struct-offset mismatch on
`Capability::r` / `StgRegTable::*`.  Disassembled
`updateNurseriesStats` in the current `Storage.o`:

```
lwz r4, 0x340(r3)    ; r.rCurrentNursery — 0x340 = 832 ✓
lwz r4, 0x344(r3)    ; r.rCurrentAlloc   — 0x344 = 836 ✓
```

Both match `OFFSET_Capability_r (12) + OFFSET_StgRegTable_* (820/824)`
from `_build/stage1/lib/DerivedConstants.h`.  The sister project's
LLVM-8 BUG-010 patch (PPC32 Darwin "power" struct alignment field
cap) is in effect.  C and Cmm agree on layout.  **Hypothesis
dead.**

Detail: [`findings.md` Step 0](findings.md).

### Step 2 — PROBE20: post-scavenge stack inspection

Patched `rts/sm/GC.c::GarbageCollect` to walk
`capabilities[0]->run_queue_hd->stackobj` after all scavenging is
done but before `resetNurseries()` recycles from-space.  For every
word in the stack, check `HEAP_ALLOCED` and `BF_EVACUATED`.

**Headline:** every iteration of `+RTS -A1m` shows 215 stack words
that are heap-shaped but NOT in `BF_EVACUATED` blocks.
Bit-for-bit deterministic across iter1/2/3 (4779 heap-shaped /
4564 evac'd / 215 stale across 25 GCs).

### Step 3 — PROBE20.B: dump individual non-evac'd pointers

Added per-slot `PROBE20BAD` lines.  Found:

- All 215 BAD slots are in gen-0 from-space (`bd_gen=0
  bd_flags=0x0`).
- Same slot offsets and same values across iter1/2/3.
- Repeated values: `0x0cb15ed1` appears 24×, `0x0cb51339` 22×,
  etc. — suggests the typechecker holds a small set of CAFs and
  references them from many stack positions.

GC #4 of M5.hs's compile shows a striking 38-BAD pattern: 12
repeated identical-shape frames × 3 BAD slots each.  Two of the
three BAD values are constant across all 12 repetitions — same
shared CAF references at the same stack offsets in each frame.

### Step 4 — PROBE21: bitmap-aware walker

Walked the stack frame-by-frame using `get_ret_itbl`, classifying
each BAD slot as "pointer slot per bitmap" (`is_ptr=1`) or
"non-pointer slot per bitmap" (`is_ptr=0`).

**100% of BAD slots are `is_ptr=0`** (184/184; the missing 31 are
in 5 RET_FUN/RET_BCO frames PROBE21 skipped for layout-decoding
complexity).  GC is doing exactly what the bitmap says.  **The bug
is in the bitmap.**

### Step 5 — PROBE21FRAME + deref to confirm

Added per-frame metadata dumps and pointer derefs.  Confirmed:

- Affected frames are RET_SMALL (type=30) with sizes 2-11 and
  diverse bitmap values.  Bug is systematic, not one-off.
- Derefs of BAD pointer values yield real info-table addresses.
  Examples:
  - `val=0x0cbff359 → info=0x092a204c =`
    `_ghczmprim_GHCziTuple_Z2T_con_info` (a 2-tuple constructor).
  - `val=0x0cb15ed1 → info=0x09141e68` = a closure inside
    `Control.Monad.Catch.uninterruptibleMask1`.
- Same val at later GC after from-space recycled: deref now
  yields random heap data.  Temporal corruption confirmed.

### Step 6 — module attribution

Looked up the 14 unique BAD info-table addresses against the
deployed stage2 binary's symbol table.  The bug spans:

- Data.Map.Strict.Internal (containers)
- Control.Monad.Catch (exceptions)
- GHC.Iface.Binary
- Data.Map.Internal
- GHC.List
- GHC.Base

Multiple modules across multiple packages.  **Systematic** GHC
codegen bug for PPC32 cross-build, not a one-module issue.

## Net effect on the search space

The bug is now narrowed from "something in PPC32 GC missing a
root" to "GHC's host-arm64 → target-PPC32 cross-codegen produces
stack-frame bitmaps that mark certain pointer slots as
non-pointer."

Specifically the bitmap WORD itself (the `info->i.layout.bitmap`
StgWord32 in PPC32 stack-frame info tables) is wrong.

The rest of the GC machinery is correct: scavenge_stack /
checkSmallBitmap / etc. read the bitmap consistently with what
GHC emits.

Why workaround `-A1G` works: it suppresses GC entirely for the
typechecker's lifetime.  The wrong bitmaps are still there but
they never get a chance to bite.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 still ships with `+RTS -A1G`
  wrapper, baseline test battery green (30 PASS / 4 expected
  design-diffs).
- **Probe patch + scripts archived** for session 21 to re-apply.
  Live tree is clean (PROBE20/21 reverted, RTS rebuilt
  unmodified, `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` removed).
- **HANDOFF.md** for session 21 points at the bitmap-generation
  question, with concrete next-step probe ideas (compare host
  vs cross-build Cmm output for one affected function; inspect
  GHC's StgToCmm liveness analysis for 32-bit/64-bit confusion).
- **Roughly 15 dev-loop iterations** completed (probe edit →
  rebuild → deploy → run → analyze).  Each cycle ~15-20 min,
  workable.
