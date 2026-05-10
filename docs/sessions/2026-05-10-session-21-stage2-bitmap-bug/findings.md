# Session 21 findings — bitmap-emission narrowing, round 1

## TL;DR

Session 20's "wrong stack-frame bitmaps" finding stands.  This
session went one level deeper:

1. **Decoded the actual bitmap word format on PPC32.**
   PPC32 uses `BITMAP_BITS_SHIFT=5`, `BITMAP_SIZE_MASK=0x1F` (per
   `includes/rts/Constants.h` under `SIZEOF_VOID_P==4`).  The
   bitmap encoding is `MK_SMALL_BITMAP(size,bits) = (bits<<5)|size`.
   Bit i==1 → slot i is **non-pointer**; bit i==0 → slot i **is**
   pointer (matches `scavenge_small_bitmap`).
2. **Confirmed compile-time agrees with runtime on the shift.**
   Stage1 cross-compiler's `pc_BITMAP_BITS_SHIFT = 5` (per
   `_build/stage1/lib/DerivedConstants.h` → v122 of HS_CONSTANTS).
   RTS Constants.h compiled with `SIZEOF_VOID_P=4` → shift=5.
   **No shift mismatch — the bitmap word emitted by the compiler
   means exactly what the RTS thinks it means.**
3. **Identified the dominant BAD pattern.**  Re-running
   PROBE21 logs through `scripts/correlate-probe21-bads.py`:
   the top 4 info tables alone account for **93/106** of the BAD
   pay=1 events.  All four have **bitmap layout 0x42 or 0x43** —
   i.e. `RET_SMALL` frames of size 2 or 3 with the *middle* slot
   marked non-pointer.  Pattern: `PN` (size 2) and `PNP` (size 3).
4. **The bitmap word emitted in the .o matches the StackRep that
   GHC's Cmm IR specifies.**  Cross-built `Catch.o` has 9
   `[P,N]/[P,N,P]` info tables (sizes 2/3, bits=0b10/0b010).
   Re-cross-compiling `Catch.hs` with `-ddump-cmm` yields
   exactly **9 corresponding `StackRep [F,T,F]/[F,T]` declarations**
   in the IR (recall `True` ⇔ non-pointer per
   `compiler/GHC/StgToCmm/Types.hs`).  **The bitmap-encoding step
   is faithful — the bug is upstream of `mkLivenessBits`.**
5. **Therefore the bug lives in the StgToCmm liveness analysis or
   the LayoutStack stack-map construction.**  GHC decides "this
   slot is dead/non-pointer" but at runtime the slot holds a real
   live heap pointer (PROBE21 derefs hit
   `ghczmprim_GHCziTuple_Z2T_con_info`,
   `Control.Monad.Catch.uninterruptibleMask1`-internal closures,
   etc.).

## What we measured this session

### Step 0 — confirm baseline still green

`tests/run-tests.sh`: 30 PASS / 4 expected design-diffs (Int
size, getProgName, getpid, numeric boundaries).  Same as v0.12.0
baseline.  No regression.

### Step 1 — decode the on-disk bitmap word at `_c8m6_info`

`Internal.o` for `Data.Map.Strict.Internal`, section `__const`
in `__DATA` segment (addr 0x14a50, file off 85292).  Symbol
`_c8m6_info` at addr 0x16998 → file offset 0x16C74.  Raw 16
bytes:

```
00016c74: 0001 1880 0000 3e89 001e 0001 0001 7088
          ^entry    ^layout   ^type^srt
```

PPC32 unreg-C, no TABLES_NEXT_TO_CODE, no PROFILING:

| field  | offset | bytes (BE) | value      | meaning |
|--------|-------:|------------|------------|---------|
| entry  | +0     | 00 01 18 80 | 0x00011880 | entry-code addr |
| layout | +4     | 00 00 3e 89 | 0x00003E89 | bitmap word |
| type   | +8     | 00 1e       | 30         | RET_SMALL |
| srt    | +10    | 00 01       | 1          | has-SRT flag |

Decoding `0x3E89` with PPC32's `(SHIFT=5, MASK=0x1F)`:

- size = 0x3E89 & 0x1F = 9
- bits = 0x3E89 >> 5 = 0x1F4 = 0b1_1111_0100
- pattern (bit i==1 → non-pointer): `[P, P, N, P, N, N, N, N, N]`

Session 20's findings.md citation `bits=0x1f4` was correct — I
initially mis-applied the 64-bit shift=6 and got 0xFA, which is
how the same word would decode on a 64-bit RTS.  Important
correction: **session 20's bitmap decoding was right; I was
double-checking the wrong way for ~30 minutes before realizing.**

### Step 2 — confirm `pc_BITMAP_BITS_SHIFT` for the cross-compiler

`compiler/GHC/Cmm/Info.hs:373`:

```haskell
bitmap_word = ... .|. (small_bitmap `shiftL` pc_BITMAP_BITS_SHIFT (platformConstants platform))
```

`pc_BITMAP_BITS_SHIFT` comes from `PlatformConstants` which is
populated from the `HS_CONSTANTS` string in `DerivedConstants.h`.

For our cross-build:

- `_build/stage1/lib/DerivedConstants.h` HS_CONSTANTS field 122
  (the slot for `BITMAP_BITS_SHIFT` per
  `_build/stage1/compiler/build/GHC/Platform/Constants.hs`):
  **5**.
- `_build/stage0/lib/DerivedConstants.h` field 122: also **5**.

So when stage1 ghc compiles target Haskell code, it correctly
emits a small-bitmap word with `(bits << 5) | size`.

For the runtime side: preprocessing
`_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/include/Rts.h`
through `ppc-cc -E`:

```
const int X_SHIFT = 5;
const int X_MASK = 0x1f;
const int X_VOID_P = 4;
```

So the RTS compiles `BITMAP_BITS(x) = x >> 5` and `BITMAP_SIZE(x)
= x & 0x1f`.  **Compiler and runtime agree.**

### Step 3 — re-attribute the BAD pay= events

`scripts/correlate-probe21-bads.py
log/session20/probe20-iter1-vanilla-A1m.log 1` shows:

```
Top info tables for BAD pay=1:
info           bitmap     size bits      count  pat
0x9143d50      0x00000043    3 0x2          39  PNP
0x92462b8      0x00000042    2 0x2          33  PN
0x924624c      0x00000043    3 0x2          16  PNP
0x9189c18      0x00000043    3 0x2           5  PNP
0x9186490      0x00003e49    9 0x1f2         3  PNPPNNNNN
...
```

The first four account for 93/106 BADs at pay=1, all sharing
**bits=0x2** (only bit 1 set, i.e. only slot 1 marked
non-pointer) in size-2 or size-3 frames.

For pay≠1 the dominant pattern shifts but is similar in shape:
small frames with one non-pointer slot at the position pointed to
by the bad pay value.

### Step 4 — count `PN`/`PNP` info tables in cross-built .o files

`scripts/decode-info-tables.py path/to/Module.o --filter-pnp`:

| Module                     | size-2 PN | size-3 PNP |
|----------------------------|----------:|-----------:|
| Data.Map.Strict.Internal   |        12 |          1 |
| Data.Map.Internal          |       45+ |       25+  |
| Control.Monad.Catch        |         1 |          9 |

(For Map.Internal I capped the listing at 8 in the script run —
the full count is several dozen of each.)

### Step 5 — re-cross-build `Control/Monad/Catch.hs` with -ddump-cmm

```
PPC_GHC=external/.../powerpc-apple-darwin8-ghc
$PPC_GHC --make -c -O2 -ddump-cmm -ddump-stg-final \
    -i.../exceptions/src \
    -hide-package exceptions \
    .../Catch.hs > catch-O2.dump
```

(Captured at
[`log/session21/catch-cross/catch-O2.dump`](../../../log/session21/catch-cross/catch-O2.dump)
— ~1.1 MB, gitignored).

Counted distinct StackRep patterns by size in the dump.  Size 2:
`25× [F,F]`, **`1× [F,T]`**.  Size 3: `35× [F,F,F]`, `8× [F,T,F]`,
`3× [F,F,T]`.

Recall `compiler/GHC/StgToCmm/Types.hs:178`:

```haskell
type Liveness = [Bool]   -- One Bool per word; True  <=> non-ptr or dead
```

So `[F,T]` corresponds to `[Pointer, NonPointer]` = `PN`, and
`[F,T,F]` is `PNP`.

The dump has **9 of these `slot-1-marked-non-pointer` StackReps**.
The .o has **9 `PN`/`PNP` info tables** (1+8 = 9).  **Match.**
The bitmap encoding is faithful — `mkLivenessBits` is innocent.

### Step 6 — verify scrutinee dereferences

Session 20's PROBE21BAD lines log a `deref_ok=1 info=0x...` for
each BAD slot's dereferenced first word.  On GC #3:

```
PROBE21BAD ... pay=2 val=0x0cbff359 ... deref_ok=1 info=0x092a204c
                                                            ^^^^^^^^
                                                _ghczmprim_GHCziTuple_Z2T_con_info
                                                (a 2-tuple constructor)
```

So the BAD slot holds a pointer to a real heap-allocated 2-tuple
closure.  GHC's StackRep marked this slot non-pointer; it isn't.

## Where the bug actually lives

Putting it all together: **the bug is in
`compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` or earlier
in the `StackMap`-construction pipeline**.  The function:

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

defaults every slot to `True` (non-pointer/dead), then writes
`False` (live pointer) at each `toWords platform off` whose
`LocalReg` is `isGcPtrType`.  If a saved-pointer register is
missing from `sm_regs`, **or** its `off` is wrong, **or** its
type is misclassified as non-Gc, the slot reverts to `True` and
the bitmap marks it non-pointer.

`toWords platform off = off `quot` platformWordSizeInBytes platform`
uses **target** word size (4 on PPC32) — that's correct.  So the
likely culprits, in order:

1. **`sm_regs` is missing entries** for live pointer-typed
   `LocalReg`s that are saved on the stack across a call.
2. The `LocalReg` type for a saved pointer is being constructed
   as `bWord` or similar (non-Gc), losing the GcPtr property.
3. A register that holds a tagged pointer (e.g. R1 with low-bit
   constructor tag) is treated as non-pointer because its
   apparent type at the Cmm level doesn't say `gcWord`.

## What rules in / out so far

✅ Bitmap encoding step (`mkLivenessBits`) is correct.
✅ `pc_BITMAP_BITS_SHIFT` and runtime `BITMAP_BITS_SHIFT` agree
   (both = 5 on PPC32).
✅ The .o matches the Cmm IR's StackRep — no codegen-level
   bit-flip / endian-swap / size-encoding bug.
✅ The bug is reproducible on multiple modules across multiple
   packages — systematic.
✅ The wrong-marked slots really do hold heap pointers (deref
   yields real info-table pointers when from-space hasn't been
   recycled yet).
❌ NOT a host vs target word-size shift mismatch.
❌ NOT specific to large bitmaps (the dominant cases are tiny:
   size 2 and 3).
❌ NOT specific to Int64#/Word64#/Double# slots (the affected
   modules — Catch, Map.Internal — don't use 64-bit primitives in
   any obvious way).

## Methodology / tools added this session

- [`scripts/decode-info-tables.py`](scripts/decode-info-tables.py)
  — for any cross-built Mach-O .o, dump every `_*_info` symbol
  in `__const(__DATA)` decoded as a 12-byte StgInfoTable
  (PPC32 unreg-C, no TNToC, no PROF).  Filters to PN/PNP if
  `--filter-pnp` is passed.
- [`scripts/correlate-probe21-bads.py`](scripts/correlate-probe21-bads.py)
  — re-attributes PROBE21BAD lines to their PROBE21FRAME info=
  by walking the log sequentially, then ranks info-table
  addresses by BAD count (overall or for a specific pay= value).

Both scripts assume the cctools-port `nm`/`otool` are at the
session-20 paths
(`$HOME/.local/cctools-ppc/install/bin/powerpc-apple-darwin8-{nm,otool}`).

## What didn't work

- Hadrian unique-name scheme produces *different* `_cXXXX_info`
  labels each compile (depends on `-O` flags and other inputs).
  Re-cross-building one module to find a SPECIFIC label like
  `_c8m6_info` doesn't work — the same source produces different
  uniques.  We worked around by structural matching (search for
  `[F,T,F]` StackReps) instead.
- `-ddump-cmm-final` would have given the post-LayoutStack Cmm
  with concrete stack offsets.  Not yet used; would help in
  session 22 to see the `Sp - 4 = ...; Sp - 8 = ...` assignments
  for the `[F,T,F]` frames and identify which value is being
  saved at slot 1.
