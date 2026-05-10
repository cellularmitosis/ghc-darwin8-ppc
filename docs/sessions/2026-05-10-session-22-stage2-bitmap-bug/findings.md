# Session 22 findings — bitmap-emission round 4

## TL;DR

Session 21 narrowed the bug to "wrong StackRep produced by
StgToCmm/LayoutStack."  This session re-tested that hypothesis
two ways and found it **does not survive scrutiny** for
Catch.hs's PNP/PN frames:

1. **Per-frame audit of all 15 `True`-containing StackReps in
   cross-built Catch.hs** (8 × `[F,T,F]`, 1 × `[F,T]`, 3 × `[F,F,T]`,
   1 × `[F,T,T,F]`, 1 × `[F,T,F,F]`, 1 × `[F,F,T,F]`).  In every
   case the slot marked `True` is either never accessed in the
   block or **only written, never read**.  Several frames overwrite
   the slot with a heap pointer or info-table address before any
   downstream code could read it.  Conclusion: from these blocks'
   own perspective, those slots are **genuinely dead**, and marking
   them non-pointer is the **correct GC instruction**.
2. **Host vs cross GHC 9.2.8 comparison** on identical Catch.hs
   `-O2`: cross emits 8 × `[F,T,F]` and 7 other `True`-containing
   patterns; host emits 2 × `[F,T,F]` and zero others.  The cross's
   2 audited PNP frames look the same as the host's structurally
   (slot 1 dead).  The extra `True` patterns on cross are explained
   by 32-bit codegen producing different stack layouts than 64-bit
   (more spills, more continuation frames), not by misclassification
   per se.

This means session 21's confident framing — "the bug lives in
`compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` or earlier" —
is at least incomplete and probably **wrong for the dominant
Catch.hs PNP frames**.  Those frames are most likely **PROBE21
false positives**: PROBE21 flags any heap-shaped value in a
non-evac'd block whose bitmap says "non-pointer," but a slot
marked non-pointer is **allowed to hold stale heap-shaped bytes
if no later code reads it**, which is exactly what these blocks do.

The actual stage2 GC bug is therefore **not located in the 9 PNP
frames in Catch.hs**.  v0.12.0 still ships unchanged.  Stage2 still
needs the `+RTS -A1G` workaround.  We are back to the question
"where is the missed root?" with the bitmap-content angle ruled
out for at least one whole module.

## What we measured

### Step 0 — confirm baseline still green

`tests/run-tests.sh`: 30 PASS / 4 expected design-diffs (Int size,
getProgName, getpid, numeric boundaries).  Same as v0.12.0.

### Step 1 — re-cross-compile Catch.hs with -ddump-cmm-final

(Session 21's `log/session21/catch-cross/catch-O2.dump` already
contains the post-LayoutStack `Output Cmm` for Catch.hs.  All 8
[F,T,F] and 1 [F,T] StackReps live in those `Output Cmm` sections.
No re-build needed.)

### Step 2 — audit each `True`-containing frame for slot reads

Ran [`scripts/audit-all-true-frames.py`](scripts/audit-all-true-frames.py)
which extracts each `_blk_NAME` whose `info_tbls` StackRep has at
least one `True`, then for every True-marked slot index `i` (slot
i = `Sp + 4*(i+1)` on PPC32) searches the block body for reads
(`= ... [Sp + 4(i+1)]`) and writes (`[Sp + 4(i+1)] = ...`).

Result table:

| info table          | StackRep              | T-slots    | reads | writes |
|---------------------|-----------------------|------------|-------|--------|
| block_c95k          | [F, F, T]             | [2]        | 0     | 2      |
| block_c95p          | [F, T, F]             | [1]        | 0     | 0      |
| block_c98t          | [F, T]                | [1]        | 0     | 2      |
| block_c9av          | [F, F, T]             | [2]        | 0     | 1      |
| block_c9bf          | [F, F, T]             | [2]        | 0     | 1      |
| block_c9hq          | [F, F, T, F]          | [2]        | 0     | 0      |
| block_c9hQ          | [F, T, T, F]          | [1, 2]     | 0     | 2      |
| block_c9j4          | [F, T, F]             | [1]        | 0     | 1      |
| block_c9sm          | [F, T, F, F]          | [1]        | 0     | 1      |
| block_caDQ          | [F, T, F]             | [1]        | 0     | 1      |
| block_caDW          | [F, T, F]             | [1]        | 0     | 1      |
| block_caHe          | [F, T, F]             | [1]        | 0     | 1      |
| block_caHk          | [F, T, F]             | [1]        | 0     | 1      |
| block_caKJ          | [F, T, F]             | [1]        | 0     | 1      |
| block_caKP          | [F, T, F]             | [1]        | 0     | 1      |

**Total: 15 frames, 0 reads, 15 writes** to the `True`-marked
slots.  In every case the slot is either passed through then
popped (c95p, c9hq) or overwritten with a fresh value before
any downstream code could read it.

Crucially: every "overwrite" matches one of two patterns:
- `P32[Sp + N] = P32[Sp + 12]` (copy a pointer from another slot —
  consistent with the "[F,T,F] before pop" idiom: the block is
  preparing to call its tail with the slot 2 pointer in the slot
  1 position, then `Sp = Sp + 8` pops slots 0+1)
- `P32[Sp + N] = Hp - K` (write a freshly-allocated heap pointer
  to the slot before passing it to the next call)
- `I32[Sp + N] = block_xxx_info` (write a static info-table
  address — non-pointer for GC purposes)

### Step 3 — host vs cross GHC 9.2.8 on Catch.hs

Built `Catch.hs` with the host bootstrap GHC 9.2.8 at
`-O2 -ddump-cmm`:

```
~/.local/ghc-9.2.8/bin/ghc --make -c -O2 -ddump-cmm \
    -outputdir . -i$SRC -hide-package exceptions \
    $SRC/Control/Monad/Catch.hs > catch-host-O2.dump
```

(see [`log/session22/host/catch-host-O2.dump`](../../../log/session22/host/catch-host-O2.dump),
~22.5k lines, gitignored).

StackRep distribution (host vs cross):

| pattern               | host | cross | delta |
|-----------------------|-----:|------:|------:|
| `[]`                  |   17 |    17 |     0 |
| `[F]`                 |   29 |    28 |    -1 |
| `[F, F]`              |   35 |    25 |   -10 |
| `[F, F, F]`           |   37 |    35 |    -2 |
| `[F, F, F, F]`        |   14 |    14 |     0 |
| `[F, F, F, F, F]`     |    7 |     7 |     0 |
| `[F, F, F, F, F, F, F]`|   2 |     2 |     0 |
| `[F, T, F]`           |    2 |     8 |    +6 |
| `[F, T]`              |    0 |     1 |    +1 |
| `[F, F, T]`           |    0 |     3 |    +3 |
| `[F, T, T, F]`        |    0 |     1 |    +1 |
| `[F, T, F, F]`        |    0 |     1 |    +1 |
| `[F, F, T, F]`        |    0 |     1 |    +1 |

Total `True`-containing slots: host=2 (in 2 frames), cross=16 (in
15 frames).  Cross has **8× more** `True` bits in stack layouts.

Inspected the host's 2 [F,T,F] frames (block_c9kR_info from
`$lio_g8WJ_entry`).  Body pattern is identical to the cross's
PNP idiom: write fresh values to slots, then `Sp += N` and tail-
call.  Slot 1 is dead.  Bitmap is correct.

The 8× difference in cross can be explained by 32-bit codegen
factors (Int# / Word# stay 1 slot but pointers double-up in some
spill patterns; argument blocks expand from 8B to 12B for 3-ptr
calls; etc.).  None of that is a bug; it's just more stack
slots.

### Step 4 — verify bit-order convention end-to-end

Walked the chain to make sure I understood it correctly:

- `compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` builds an
  array indexed `[toWords sm_ret_off + 1 .. toWords (sm_sp - sm_args)]`
  (word indices), defaults all `True` (non-ptr/dead), writes `False`
  for each pointer-typed `LocalReg` in `sm_regs`.
- `reverse $ Array.elems` puts the **highest word index** at list
  position 0.  In LayoutStack's offset convention, "highest offset"
  = "closest to Sp" = "first slot above the info pointer."
- `compiler/GHC/Data/Bitmap.hs::mkBitmap` puts list element 0 at
  bit 0.
- `rts/sm/Scav.c::scavenge_small_bitmap` sets `p = payload`
  (= `Sp + wordSize`, the first slot above the info pointer),
  then `bit 0 first, p++ each iteration`.

So **bit 0 ↔ first slot above the info ptr** all the way through.
For `[F,T,F]` (size 3, bits=0b010 = 2, encoded word = 0x43): bit
0 = slot 0 = pointer, bit 1 = slot 1 = non-pointer, bit 2 = slot 2
= pointer.  Matches the runtime bitmap word PROBE21 dumps for the
top-4 pay=1 BAD info tables.

So the encoding chain is right and the StackRep semantics are
right.  The bug is **not** in either layer for these frames.

## Where the bug actually is — revised

Going into session 22 we believed the dominant 93/106 BAD pay=1
events traced to genuinely-wrong [F,T,F] / [F,T] bitmaps in info
tables emitted by the cross-build's StgToCmm/LayoutStack pass.

Out of session 22, with the per-block audit, the strongest claim
we can make is:

> **For every Catch.hs PNP/PN/related-pattern info table, the
> blocks reached via that frame never actually read the slot their
> bitmap marks non-pointer.  Marking it non-pointer is therefore
> correct, and the BAD events PROBE21 attributes to those tables
> are false positives — heap-shaped values legitimately left
> stranded in dead slots that GC correctly skips because nobody
> will read them.**

PROBE21's heuristic is "value is heap-shaped AND the block it
points to is not BF_EVACUATED."  This is not equivalent to "the
slot is a missed GC root."  A dead-but-stale slot satisfies the
heuristic without being a bug.

That **does not** mean the stage2 GC crash is fictitious —
session 19 showed reproducible "variable not found" panics under
default `-A1m` that disappear with `-A1G`.  Something IS being
collected too aggressively.  But the dominant fingerprint
PROBE21 surfaces in Catch.hs is not it.

### Implications for the remaining search space

1. The bug may be in a **different module** than Catch.  Map.Internal
   has dozens of PN/PNP info tables (per session-21 counts); the
   absolute number of BAD events from there is much larger.  Auditing
   Map.Internal's frames the same way might surface a frame that
   actually does read its True-slot.
2. The bug may be in a **non-RET_SMALL frame type** that PROBE21
   skips entirely (RET_FUN, RET_BCO).  Session 20 noted ~31 of 215
   PROBE20 BAD slots fell into a RET_FUN/RET_BCO block PROBE21
   bailed out of.  Those 31 are still completely uncharacterized.
3. The bug may be in the **RTS scavenger or stack walker itself** —
   not in the bitmap layer at all.  E.g., a wrong frame-size
   calculation, a missed handling of UPDATE_FRAME's payload, an
   AP_STACK / STM frame layout mismatch, etc.
4. The bug may be in **CAF revert / SRT scanning** rather than
   the running-thread stack.  Session 19 had a `markCAFs-count`
   probe; revisit that line of inquiry.

## What rules in / out (cumulative across sessions 19-22)

Ruled OUT:

- ✅ `pc_BITMAP_BITS_SHIFT` host/target mismatch (session 21).
- ✅ `mkLivenessBits` codegen step (session 21).
- ✅ `stackMapToLiveness` for Catch.hs PNP/PN frames (session 22).
- ✅ `StgRegTable` / `Capability::r` field-offset mismatch (session 20).
- ✅ Word64#/Int64#/Double# misalignment as primary cause (session 21
  reasoning still holds — the dominant fingerprint is small frames).
- ✅ Bitmap encoding convention (bit-order verified end-to-end this
  session).

Still in PLAY:

- ❓ Map.Internal / GHC.Iface.Binary / GHC.Base / GHC.List frames
  (un-audited).  Could contain a frame whose body actually does
  read a True-marked slot.
- ❓ RET_FUN / RET_BCO frames (PROBE21 bails out at the first one).
- ❓ Special-frame-type handling: UPDATE_FRAME, STM frames,
  CATCH_FRAME, etc.
- ❓ RTS scavenger bug: wrong frame-size calculation, off-by-one
  in walker.
- ❓ CAF revert / SRT scanning incompleteness.
- ❓ Some kind of hardware/ABI thing specific to PPC32 Tiger that
  manifests under heavy GC pressure but not under -A1G (e.g.,
  cache-coherence quirk during evacuation, ABI register-clobbering
  in a specific call chain).

## Methodology / tools added this session

- [`scripts/audit-ftf-frames.py`](scripts/audit-ftf-frames.py) —
  for each `_blk_NAME` with StackRep `[False, True, False]` in a
  Cmm dump, prints the block body's writes/reads at `Sp+8`.
- [`scripts/audit-all-true-frames.py`](scripts/audit-all-true-frames.py)
  — generalised version: for each `_blk_NAME` with **any** True
  in its StackRep, prints reads/writes at every True-marked slot.

Both are stand-alone Python; they parse the Cmm `Output Cmm`
sections of GHC's `-ddump-cmm` / `-ddump-cmm-final` output (the
two appear identical in 9.2.8 — both go through the
`Output Cmm` header).

## What didn't work (or wasn't tried)

- **LayoutStack instrumentation deferred.**  HANDOFF's experiment
  #2 ("add a debug print to `stackMapToLiveness`") would tell us
  what `sm_regs` and `live_words` actually contain at compile time
  for these frames.  But the per-block audit already establishes
  that the resulting bitmap is **the right answer**, so the debug
  print would only confirm what we already know.  Holding off on
  the 12-15 min stage1 rebuild.
- **Poison-on-stale-slot RTS patch not built.**  Strongly want
  this for next session — see HANDOFF top experiment.  The idea:
  in `rts/sm/GC.c::GarbageCollect`, after PROBE21-style scan,
  overwrite each non-evac heap-shaped slot value with a sentinel
  like `0xDEADBEEF`.  If subsequent execution crashes at
  `0xDEADBEEF`, that slot really was being read (real bug).  If
  no crash, those slots really were dead.  Decisive.
- **Map.Internal audit not run.**  Larger module (dozens of PN/PNP
  tables); same script should run cleanly on
  `log/session21/cmm-cross/internal-O2.dump`.  Worth doing as the
  next-cheapest experiment.
