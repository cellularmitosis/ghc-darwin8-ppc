# Session 21 — stage2 GC bug, round 3 (bitmap-emission narrowing)

**Dates:** 2026-05-10 (continued from session 20 close).
**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on
Tiger uses `+RTS -A1G` workaround.  Session 20 found the proximate
cause: the typechecker's running-thread stack contains ~184 slots
holding real heap pointers whose enclosing stack-frame bitmaps mark
them as non-pointers; GC dutifully skips, pointers go stale, panic.
Affects 14+ info tables across 6+ modules.  WHY the bitmaps are
wrong is the open question.

**Status on exit:** **bug narrowed by one more layer.**  Confirmed
the bitmap-encoding step (`mkLivenessBits`) is correct — the .o
faithfully encodes the StackRep that GHC's Cmm IR specifies.
Therefore the bug lives upstream, in
`compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` or earlier
`StackMap` construction (StgToCmm pass).  The dominant failure
fingerprint is **`PN`/`PNP` frames** (size 2/3 with the middle slot
marked non-pointer) — 93/106 of the BAD pay=1 events trace to just
4 info tables sharing this exact shape.  Pre-existing
`pc_BITMAP_BITS_SHIFT` host/target mismatch theory **disproved**:
both compile-time and runtime agree on shift=5 for PPC32.  v0.12.0
unchanged.

## What we did, in order

### Step 1 — confirm baseline still green

`tests/run-tests.sh`: 30 PASS / 4 expected design-diffs.  No
regression introduced by anything in session 20 (we did revert
all probe code at session-20 close).

### Step 2 — decode the on-disk bitmap word at `_c8m6_info`

`Internal.o` for `Data.Map.Strict.Internal` has `_c8m6_info` at
file offset 0x16C74 (within the `__const(__DATA)` section).  The
StgInfoTable struct (PPC32 unreg-C, no TABLES_NEXT_TO_CODE):

```
entry  = 0x00011880
layout = 0x00003E89    -- bitmap word
type   = 30            -- RET_SMALL
srt    = 1
```

Decoded with PPC32's `BITMAP_BITS_SHIFT=5` and `BITMAP_SIZE_MASK=0x1F`:
size=9, bits=0x1F4, pattern `[P, P, N, P, N, N, N, N, N]`.

Detail: [`findings.md` Step 1](findings.md).

### Step 3 — kill the host/target shift-mismatch hypothesis

Stage1 cross-compiler's `pc_BITMAP_BITS_SHIFT = 5` per
`_build/stage1/lib/DerivedConstants.h`.  RTS Constants.h
preprocessed in target build env: `BITMAP_BITS_SHIFT = 5`.
**Compiler and runtime agree on shift = 5.**  The earlier
"maybe deriveConstants used host word size" hypothesis was
wrong — the value baked into stage1 is target-derived.

Detail: [`findings.md` Step 2](findings.md).

### Step 4 — re-attribute BAD events from session-20 PROBE21 logs

Wrote
[`scripts/correlate-probe21-bads.py`](scripts/correlate-probe21-bads.py)
which walks a PROBE21 log and groups `PROBE21BAD` lines by their
enclosing `PROBE21FRAME` info= and bitmap_raw=.

For pay=1 (the dominant 96/184 BAD-slot position):

| info=      | bitmap | size | bits | count | pattern |
|------------|-------:|-----:|-----:|------:|---------|
| 0x9143d50  | 0x43   |    3 | 0x2  |   39  | `PNP`   |
| 0x92462b8  | 0x42   |    2 | 0x2  |   33  | `PN`    |
| 0x924624c  | 0x43   |    3 | 0x2  |   16  | `PNP`   |
| 0x9189c18  | 0x43   |    3 | 0x2  |    5  | `PNP`   |

Top 4 info tables = 93/106 of pay=1 BADs.  All share the **same
fingerprint**: small frame (size 2 or 3), only slot 1 marked
non-pointer.

### Step 5 — count the suspect pattern in cross-built .o files

[`scripts/decode-info-tables.py`](scripts/decode-info-tables.py)
on `_build/.../Catch.o`: 9 RET_SMALL info tables with layout
0x42 (PN size 2) or 0x43 (PNP size 3).  Same script on
Map.Internal.o: dozens of each.

### Step 6 — re-cross-build Catch.hs with -ddump-cmm and compare

```
PPC_GHC=external/.../powerpc-apple-darwin8-ghc
$PPC_GHC --make -c -O2 -ddump-cmm -ddump-stg-final \
    -i.../exceptions/src \
    -hide-package exceptions \
    .../Catch.hs > catch-O2.dump
```

Cmm IR distinct StackRep patterns:
- size 3: 35× `[F,F,F]`, **8× `[F,T,F]`**, 3× `[F,F,T]`
- size 2: 25× `[F,F]`, **1× `[F,T]`**

Recall `compiler/GHC/StgToCmm/Types.hs:178`:
`type Liveness = [Bool]   -- True <=> non-ptr or dead`.

So `[F,T,F]` ↔ `PNP` and `[F,T]` ↔ `PN`: **8+1 = 9 IR
StackReps** matching the .o's **9 PN/PNP info tables**.  The
bitmap encoding is faithful.

### Step 7 — identify the upstream-of-encoding location

`compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness`:

```haskell
stackMapToLiveness platform StackMap{..} =
   reverse $ Array.elems $
        accumArray (\_ x -> x) True (toWords platform sm_ret_off + 1,
                                     toWords platform (sm_sp - sm_args)) live_words
   where
     live_words =  [ (toWords platform off, False)
                   | (r,off) <- nonDetEltsUFM sm_regs
                   , isGcPtrType (localRegType r) ]
```

Defaults all slots to `True` (non-pointer/dead), then writes
`False` for each `LocalReg` in `sm_regs` whose type is
`isGcPtrType`.  If a register holding a tagged pointer is missing
from `sm_regs`, has wrong `off`, or has type misclassified as
non-Gc, its slot stays `True` → bitmap says non-pointer → bug.

`toWords platform off` uses **target** word size (4 on PPC32) —
not the source of the bug.

## Net effect on the search space

Going into session 21 the question was:

> *"What does cross-codegen do wrong when emitting stack-frame
> bitmaps for PPC32?"*

After session 21:

> *"Why does StgToCmm/LayoutStack populate `sm_regs` (or set
> `localRegType`) such that a saved-pointer slot — specifically
> slot 1 of small frames — gets classified as non-pointer/dead?"*

The bitmap-encoding pipeline (size+bits → StgWord → little-endian
.o bytes) is **proven correct**.  The wrongness is a deliberate
choice somewhere upstream.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 still ships with `+RTS -A1G`
  wrapper, baseline test battery green.
- **Two analysis scripts added** to
  [`scripts/`](scripts/) under this session dir: bitmap decoder
  and PROBE21 correlator.  Both are reusable for future probes.
- **No tree edits** to `external/ghc-modern/` or live build state.
  No new probe binaries on pmacg5.
- **HANDOFF.md** for session 22 points at three concrete next
  experiments to identify which Haskell→Cmm path produces the
  wrong `[F, T, F]` StackRep.
