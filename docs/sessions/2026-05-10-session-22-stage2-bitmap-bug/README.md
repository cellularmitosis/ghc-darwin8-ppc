# Session 22 — stage2 GC bug, round 4 (PNP-bitmap hypothesis revisited)

**Dates:** 2026-05-10.
**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on
Tiger uses `+RTS -A1G` workaround.  Session 21 narrowed the bug to
"wrong StackRep emitted by StgToCmm/LayoutStack — the `mkLivenessBits`
encoding is faithful but its input is wrong."  Top recommended
experiment was to identify the Cmm-level value being saved at slot 1
of one of the `[F,T,F]` PNP frames, classify it, and instrument
LayoutStack as needed.

**Status on exit:** **session 21's hypothesis does not survive
scrutiny for Catch.hs.**  Per-frame audit of all 15 `True`-containing
StackReps in cross-built Catch.hs shows the True-marked slots are
**either never accessed or only written, never read** — the bitmap is
**correct**.  Cross-host comparison shows cross emits 8× as many
`True`-containing patterns as host on the same source, but the audited
host frames have the same dead-slot pattern.  Conclusion: the dominant
93/106 BAD pay=1 events PROBE21 traced to 4 PNP/PN info tables in
Catch.hs are likely **PROBE21 false positives** — heap-shaped values
legitimately stranded in dead slots that GC correctly skips.  The
real stage2 GC bug is therefore not in those frames; it must be in
some other module's frames, in a non-RET_SMALL frame type PROBE21
skipped, in the RTS scavenger itself, or in CAF/SRT scanning.
v0.12.0 unchanged.  HANDOFF.md proposes a poison-on-stale-slot RTS
patch as the next experiment — definitive test of "real bug vs
PROBE21 false positive" without further bitmap analysis.

## What we did, in order

### Step 1 — confirm baseline still green

`tests/run-tests.sh`: 30 PASS / 4 expected design-diffs.  Same as
v0.12.0 baseline.

### Step 2 — re-cross-compile is unnecessary

Session 21's
[`docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/logs/catch-cross/catch-O2.dump`](../docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/logs/catch-cross/catch-O2.dump)
already contains the post-LayoutStack `Output Cmm` for Catch.hs.
The 8 `[F,T,F]` and 1 `[F,T]` and 6 other `True`-containing
StackReps live in those `Output Cmm` sections, with concrete
Sp-relative writes inserted by the spilling/layout pass.  All 15
frames are visible without re-building anything.

### Step 3 — audit each True-containing frame for slot reads

Wrote
[`scripts/audit-all-true-frames.py`](scripts/audit-all-true-frames.py).
For each `_blk_NAME()` with `True` in its StackRep, the script
extracts the block body and searches for reads (`= ... [Sp + 4(i+1)]`)
and writes (`[Sp + 4(i+1)] = ...`) at every True-marked slot index `i`.

**Result: 0 reads, 15 writes across all 15 True-containing frames.**

In every case, the slot is overwritten before any downstream code
reads it (or never touched at all and just popped via `Sp += N`).
The bitmap is **correct**: GC can safely skip those slots because
no subsequent code needs the value there.

Detail: [`findings.md` Step 2](findings.md).

### Step 4 — host vs cross comparison on same source

Built `Catch.hs` with the bootstrap host GHC 9.2.8 (arm64) at
`-O2 -ddump-cmm`:

```
~/.local/ghc-9.2.8/bin/ghc --make -c -O2 -ddump-cmm \
    -outputdir . -i$SRC -hide-package exceptions \
    $SRC/Control/Monad/Catch.hs > catch-host-O2.dump
```

Counts:

| pattern   | host | cross | delta |
|-----------|-----:|------:|------:|
| `[F,T,F]` |    2 |     8 |    +6 |
| `[F,T]`   |    0 |     1 |    +1 |
| `[F,F,T]` |    0 |     3 |    +3 |
| `[F,T,T,F]`|   0 |     1 |    +1 |
| `[F,T,F,F]`|   0 |     1 |    +1 |
| `[F,F,T,F]`|   0 |     1 |    +1 |

Cross has 8× the True-bits in stack layouts.  But: I inspected the
host's 2 PNP frames and they have **the same body pattern** as the
cross's audited PNP frames (overwrite slot 1 with a fresh value or
copy-from-other-slot, then `Sp += N` and tail-call).  The host
frames are also dead-slot-correct.

The 8× difference is explained by 32-bit codegen producing different
spill/continuation-frame patterns than 64-bit on identical source.
Not a bug per se, just a layout difference.

### Step 5 — verify the bit-order convention end-to-end

Walked the chain `LayoutStack.stackMapToLiveness → mkBitmap →
mkLivenessBits → on-disk bitmap word → scavenge_small_bitmap` and
confirmed bit 0 = first slot above the info pointer in BOTH the
compiler and the runtime.  No bit-order inversion bug, no
endian-swap bug, no off-by-one.

`[F,T,F]` decodes to bits=0b010, size=3, bitmap word = `(0b010 << 5)
| 3 = 0x43` — exactly the value PROBE21 sees at the top-4 pay=1
BAD info tables (0x9143d50, 0x92462b8, 0x924624c, 0x9189c18).

Detail: [`findings.md` Step 4](findings.md).

## Net effect on the search space

Going into session 22 we believed:

> *"The bug is in `compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness`
> or earlier in `StackMap` construction — a saved-pointer LocalReg
> isn't surviving as `isGcPtrType` in `sm_regs`."*

After session 22:

> *"The bitmap output for the 9 PNP/PN info tables in Catch.hs is
> correct.  The blocks reached via those frames don't read the
> True-marked slots.  PROBE21's BAD events for these tables are
> false positives.  The actual GC bug is somewhere else: another
> module, a non-RET_SMALL frame type PROBE21 skipped, the RTS
> scavenger, or CAF / SRT scanning."*

Session 21 was right that "the bitmap-encoding step is faithful"
(`mkLivenessBits` correctly converts StackRep to bitmap word).  It
was wrong to extrapolate from there to "the StackRep itself must
be wrong" — the StackRep can be a faithful summary of "this slot
is dead in this block" *and* the slot can hold a stale heap-shaped
value, simultaneously, with no correctness problem.

PROBE21's `is_ptr=0` flag detects the *latter*, not a *bug*.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with `+RTS -A1G` wrapper,
  baseline test battery green.
- **Two analysis scripts added** to
  [`scripts/`](scripts/) — `audit-ftf-frames.py` (the targeted
  PNP version) and `audit-all-true-frames.py` (generalised, all
  patterns).  Re-usable on any cross-built Cmm dump.
- **Host dump captured** at
  [`logs/host/catch-host-O2.dump`](logs/host/catch-host-O2.dump)
  for any future host-vs-cross comparison work (gitignored;
  ~22.5k lines).
- **No edits** to `external/ghc-modern/` or to live build state.
  No new probe binaries on pmacg5.
- **HANDOFF.md** for session 23 reframes the bug location and
  proposes a **poison-on-stale-slot RTS patch** as the next
  experiment — overwriting non-evac BAD slot values with
  `0xDEADBEEF` post-scavenge, so that subsequent reads either
  crash recognisably (real bug) or silently succeed (PROBE21
  false positive confirmed).
