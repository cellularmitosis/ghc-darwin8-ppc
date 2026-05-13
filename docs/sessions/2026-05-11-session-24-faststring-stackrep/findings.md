# Session 24 findings — _blk_c7te's StackRep is correct; PROBE22POISON's hit is an Addr#, not a misclassified pointer

## TL;DR

- `_blk_c7te`'s info-table has `rep: StackRep [False, True, True]`.
  Convention (from
  `compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` line 1037
  and session 22's audit): `False` = GC pointer, `True` =
  non-pointer.
- Reading session 23's "crash reads `MEM[Sp + 12]`" coordinate
  against this StackRep: slot 2 is `True` ⇒ non-pointer.  **GC
  correctly does not trace it.**
- That slot holds `_s77l`, which is the **`Addr#` field** of an
  unboxed `Data.ByteString.Internal.Type.BS` constructor (`BS
  !(ForeignPtr Word8) !Int` ⇒ unboxed to 3 fields: ptr
  `ForeignPtrContents`, raw `Addr#`, raw `Int`).
- An `Addr#` is only safe across GC if the underlying ByteArray# is
  pinned (per the invariants documented at
  `libraries/base/GHC/ForeignPtr.hs:145`).  Session 23's PROBE22POISON
  reported `bd_flags=0x0` for the stomped block, which means: not
  `BF_PINNED` and not `BF_EVACUATED`.
- So one of two things is true:
  1. **Invariant violation upstream** — some BS constructor reaches
     `mkFastStringByteString` with a non-pinned underlying byte
     array.  The Addr# is stale post-GC; this is a real bug, but
     **NOT** in LayoutStack / mkLivenessBits / stackMapToLiveness.
  2. **PROBE22POISON false positive on pinned-memory Addr#** — pinned
     blocks may end up with `bd_flags=0` at the time PROBE22POISON
     runs (post-scavenge but before `resetNurseries`); in which case
     PROBE22POISON wrongly stomped a stable Addr#, and there is no
     real read-after-poison.  Production crashes under `-A1m` would
     then need a different explanation.

Decisive next test: `BF_PINNED`-aware PROBE23 (see [`HANDOFF.md`](HANDOFF.md)).

## Cumulative reading of sessions 20–24

Sessions 20–23 progressively narrowed "the bug is a stack-frame
bitmap mis-classification."  Session 24 demolishes the last bit of
that narrative:

| Session | Hypothesis                                                | Outcome |
|---------|-----------------------------------------------------------|---------|
| 20      | "stack-frame bitmaps are wrong on PPC32 cross-build"     | PROBE20/21 finds 184 heap-shaped non-evac slots; not-yet-classified |
| 21      | "bitmap encoding step is wrong"                          | Disproved.  `BITMAP_BITS_SHIFT=5` both sides; mkLivenessBits faithful. |
| 22      | "`stackMapToLiveness` or upstream StackMap construction is wrong, for Catch.hs at least" | Disproved.  All 15 True-marked slots in Catch.hs are dead. |
| 23      | "the bug is in another module's bitmap; PROBE22POISON will find it" | Found 1 / 9 real read-after-poison events — in FastString. |
| **24**  | **"that 1 read is into a slot whose StackRep IS wrong"** | **Disproved.  The slot is an `Addr#`, correctly typed non-pointer.  The bitmap is right.** |

So PROBE21's signal-to-noise on missed-root events is **0/106** real
bitmap bugs.  PROBE22POISON's was 0–1/9 (one real read-after-poison,
but maybe a different cause than a misclassified slot).

If session 25's pin-aware PROBE23 finds 0 real bitmap bugs across
the run, then **none of sessions 19–24 ever observed a bitmap
misclassification.**  The actual mechanism behind the production
"variable not found" panic and SIGSEGV under `-A1m` must be
something else entirely — not on the running TSO's stack, or not
detectable by these probes:
- CAF / SRT corruption (closure lists outside per-thread state).
- Info-table contents (read-only, but a bad pointer in an info
  table's payload list would mislead the scavenger globally).
- Static-closure layout mismatch.
- Generation 1 / older-generation scavenge ordering.
- Pinned-block sub-allocator state on PPC32.

## What we know about the slot at Sp + 12

From session-23 PROBE22POISON line (iter2–5, gc_no=2):

```
PROBE22POISON gc_no=2 slot=6 old=0x0bf5f38a bd_gen=0 bd_flags=0x0
```

From this session's Cmm reading, the slot semantics are:

| Field                              | Value                                                                 |
|------------------------------------|-----------------------------------------------------------------------|
| Source in BS constructor           | field 2 (= `Addr#` part of `ForeignPtr`)                              |
| Cmm type at the spill site         | `I32` (raw word)                                                      |
| Cmm load `I32[_s77k::P32 + 7]`     | "extract second unboxed field of the BS at R1"                        |
| StackRep bit                       | `True` (non-pointer)                                                  |
| GC behaviour                       | skip (do not trace)                                                   |
| Library invariant for safety       | underlying MutableByteArray# must be pinned (`libraries/base/GHC/ForeignPtr.hs:145`) |
| PROBE22 observation                | `bd_flags=0x0` → no `BF_PINNED`, no `BF_EVACUATED`, no `BF_LARGE`     |

### Three possible explanations for `bd_flags=0`

(a) **The underlying ByteArray# really was non-pinned** (invariant
    violation by some BS producer).  Then the Addr# is stale, and
    the crash without PROBE22POISON would be reading old-block
    garbage — exactly the "variable not found" / SIGSEGV symptom
    session 17 saw under `-A1m`.

(b) **PROBE22POISON's `BF_EVACUATED` check is incomplete.**  Pinned
    blocks may be effectively-evacuated-in-place at this point in
    the GC cycle, but with `BF_EVACUATED` not yet set or already
    cleared.  Then PROBE22POISON wrongly poisoned a stable Addr#,
    and the segfault is PROBE22POISON-only.

(c) **Some other RTS-state-vs-block-flag interaction.**  E.g., the
    block became part of a "pinned object block list" maintained
    elsewhere, with bd_flags reset for that book-keeping.

I don't think we can choose between (a)/(b)/(c) by reading code
alone.  The PROBE23 experiment (see HANDOFF) tells us in one run.

### Why "this is the FastString bug" is consistent with both
explanations

(a) → "the BS that flows into `mkFastStringByteString` is sometimes
backed by `PlainPtr (non-pinned MutableByteArray#)`.  Most callers
go through `mallocByteString` / `mallocPlainForeignPtrBytes` (pinned
via `newPinnedByteArray#`), but some don't, and the rare non-pinned
case crashes when (a) `-A1m` makes GC fire mid-`toShortIO`-inline
and (b) GC happens to move the byte data."

(b) → "every BS is pinned-backed.  Production crashes under `-A1m`
without PROBE22POISON are from a different mechanism (CAF or RTS
scavenger).  Session 23's `_blk_c7te` crash was an artefact of the
probe."

### Why this is consistent with sessions 19–23

Session 19's "GC trace is deterministic; output is non-deterministic"
fits either:

(a) The Addr# stale-read pulls garbage that's non-deterministic
    depending on what was in the freed block.

(b) The corruption is elsewhere (CAF/SRT/info-table state); GC
    trace looks the same but output diverges later.

Session 20's "184 heap-shaped non-evac slots" — those are mostly
PROBE21 false positives (session 22 proved 15 of 15 for Catch.hs).
The 1 in FastString that read-after-poisoned could be either real
(a) or a probe artefact (b).  We won't know until PROBE23.

## Mechanics — how to reproduce session-24 results

### Cross-compile FastString.hs with cmm dumps

```
cd /Users/cell/claude/ghc-darwin8-ppc
bash docs/sessions/2026-05-11-session-24-faststring-stackrep/scripts/dump-faststring-cmm.sh
# ~8 sec.  Output: logs/cross/dump-{cmm,cmm-cps,cmm-sp,cmm-info,stg-final}
```

The script restores the original FastString.o / FastString.hi via an
EXIT trap, so it doesn't disturb the stage2 build artefact.

### Find c7te in the dumps

```
grep -n c7te logs/cross/dump-cmm-info | head
# 3611:          I32[Sp - 12] = block_c7te_info;
# 3627:_blk_c7te() { //  [R1]
# 3628:        { info_tbls: [(c7te,
# 3629:                       label: block_c7te_info
# 3630-                       rep: StackRep [False, True, True]
```

### Cross-reference with the on-target text section

```
$ ssh pmacg5 nm /opt/ghc-stage2/bin/ghc-real | sort | grep -B1 -A1 c7te
01fa46e0 t _s77C_entry                              # sat_s77C from this session's dump
01fa4750 t __blk_c7t9                               # c7t9 from this session's dump
01fa47b0 t __blk_c7te                               # c7te from this session's dump
01fa4880 t __blk_c7tr                               # c7tr from this session's dump
...
```

Uniques are stable across rebuilds.  Nice.

### Read the StackRep convention

`compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` (line 1034)
builds the `Liveness` array as:

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

So the default is `True`, and slots whose register is GC-pointer-typed
get `False`.  Hence `False` ↔ pointer, `True` ↔ non-pointer.

## Methodology / files added this session

- [`scripts/dump-faststring-cmm.sh`](scripts/dump-faststring-cmm.sh)
  — replay hadrian's `_build/stage1/compiler/build/GHC/Data/FastString.o`
  compile with `-ddump-{cmm,cmm-cps,cmm-sp,cmm-info,stg-final}
  -ddump-to-file -dno-suppress-uniques` added; .o/.hi backed up &
  restored.
- [`excerpts/c7t9-c7te.cmm`](excerpts/c7t9-c7te.cmm) — the slice of
  `logs/cross/dump-cmm-info` for `_blk_c7t9` and `_blk_c7te`.
- [`excerpts/mkFastStringByteString.stg`](excerpts/mkFastStringByteString.stg)
  — the STG of `mkFastStringByteString` showing the `case bs of BS
  ipv_s77l ipv1_s77m ipv2_s77n -> ...` pattern.
- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — writeup.
