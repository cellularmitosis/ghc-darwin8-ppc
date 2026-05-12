# Session 25 findings — PROBE23 (pin-aware poison) doesn't change a thing

## TL;DR

- PROBE23 = PROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the
  poison filter, plus a no-poison `PROBE23PINNED` log of stack slots
  that point into pinned blocks (the b-hypothesis "false-positive
  denominator").
- Result on stage2 ghc compiling M5.hs under `+RTS -A1m -RTS`,
  5 iterations: **5/5 SIGSEGV at `_blk_c7te + 112`**, exit=139,
  byte-identical crash signature and PROBE log to session 23's
  PROBE22POISON run.
- Critically: **`pinned_skip = 0` across every GC of every iteration.**
  No stack slot in any of the 3 GCs of the M5.hs compile contained a
  value that pointed into a `BF_PINNED` block.  The pin-aware filter
  never had to skip anything.
- Decisive against hypothesis (b2) "pinned blocks keep BF_PINNED and
  PROBE22 was wrongly stomping them" — that would have shown
  pinned_skip > 0 and a corresponding crash drop.  Neither happened.
- Hypothesis (a) "BS reaches `mkFastStringByteString` with a non-pinned
  underlying byte array" is the simplest reading of the data: **the
  bug is real, in the BS-allocation pipeline, NOT in PROBE22POISON
  itself, NOT in LayoutStack/mkLivenessBits/stackMapToLiveness, and
  NOT in any stack-frame bitmap.**
- Residual hypothesis (b1) "pinned blocks transiently lose BF_PINNED
  at the moment GC runs PROBE23" remains formally consistent with the
  data but would require explaining a contrived RTS state transition.
  Pursuing (a) first is correct unless (b1) gets specific evidence.

## Decisive matrix

This was the decision matrix from session-24 HANDOFF.md:

| Outcome under PROBE23           | Conclusion |
|---------------------------------|-----------|
| All 5/5 crash gone (exit 0)     | (b2) PROBE22POISON was the bug. |
| Crash still fires (5/5 SIGSEGV) | (a) BS really is non-pinned-backed.  Real bug. |
| Crash fires sometimes (1-4/5)   | Mixed signal. |

We landed in row 2.  The handoff classified that as "(a) BS really is
non-pinned-backed."  This session adds a sub-finding: the
pinned-block skip count is 0, so we can also rule out (b2) on its own
terms (not just by absence of crash relief).

## Per-iteration data

5/5 iterations are byte-identical, including TSO/stack/sp pointers.
Below is iter1 (the others differ in nothing).

```
PROBE23POISON gc_no=0 slot=8  old=0x0bdfff44 bd_gen=0 bd_flags=0x0
PROBE23POISON gc_no=0 slot=42 old=0x0bd15e05 bd_gen=0 bd_flags=0x0
PROBE23 gc_no=0 N=0 major=0 tso=0xbefe570 stk=0xbefeafc sp=0xbefedcc
        end=0xbefeeb0 words=57  heap_ptr=23  pinned_skip=0
        evac_skip=21  poisoned=2

PROBE23POISON gc_no=1 slot=13 old=0x0bdeb079 bd_gen=0 bd_flags=0x0
PROBE23POISON gc_no=1 slot=20 old=0x0bdeabd6 bd_gen=0 bd_flags=0x0
PROBE23POISON gc_no=1 slot=46 old=0x0bde9464 bd_gen=0 bd_flags=0x0
PROBE23POISON gc_no=1 slot=65 old=0x0bd5111d bd_gen=0 bd_flags=0x0
PROBE23 gc_no=1 N=0 major=0 tso=0xbefd570 stk=0xbfe1000 sp=0xbfe8e94
        end=0xbfe9000 words=91  heap_ptr=31  pinned_skip=0
        evac_skip=27  poisoned=4

PROBE23POISON gc_no=2 slot=6  old=0x0bf5f38a bd_gen=0 bd_flags=0x0   ★
PROBE23POISON gc_no=2 slot=19 old=0x0bdff04c bd_gen=0 bd_flags=0x0
PROBE23POISON gc_no=2 slot=25 old=0x0bdff0ad bd_gen=0 bd_flags=0x0
PROBE23 gc_no=2 N=1 major=1 tso=0xbf8a19c stk=0xbfe1000 sp=0xbfe8be4
        end=0xbfe9000 words=263 heap_ptr=157 pinned_skip=0
        evac_skip=154 poisoned=3
```

★ = The session-23 smoking-gun slot.  `gc_no=2 slot=6 old=0x0bf5f38a`
is bit-identical to PROBE22POISON's session-23 reading of the same
slot.

Crash trace (matches session 23):

```
Exception:  EXC_BAD_ACCESS (0x0001)
Codes:      KERN_INVALID_ADDRESS (0x0001) at 0xdeadbeef

Thread 0 Crashed:
0   <<00000000>>      0xffff87f0 __memcpy + 80
1   ghc-real          0x01fa4750 _blk_c7te + 112
2   ghc-real          0x07f00b00 StgRun + 32
...

  r4: 0x00000000deadbeef    (memcpy src — the poisoned word)
  r5: 0x0000000000000010    (memcpy len — 16 bytes; matches the
                             FastString copyByteArray# of the BS
                             into the Short-form storage)
```

## Summary table (from `run-poison.sh`)

```
iter1-A1G            exit=0    gc=0   poisoned=0   pinned=0
iter1-A1m-DS         exit=1    gc=0   poisoned=0   pinned=0
iter1-A1m            exit=139  gc=3   poisoned=9   pinned=0
iter2-A1m            exit=139  gc=3   poisoned=9   pinned=0
iter3-A1m            exit=139  gc=3   poisoned=9   pinned=0
iter4-A1m            exit=139  gc=3   poisoned=9   pinned=0
iter5-A1m            exit=139  gc=3   poisoned=9   pinned=0
```

(`-A1G` doesn't trigger any GC during the M5.hs compile so no probe
data; `-A1m -DS` exits with 1 from a sanity-check assertion before
the relevant GC runs, same as session 19 baseline.)

## Why "0 pinned-skip" is informative

PROBE23's pinned-block-on-stack pass logs every stack word `w` for
which `Bdescr(w & ~3)` returns a `bd` with `BF_PINNED` set, and
**does not poison it.**  Across 3 GCs (of which 2 are minor, 1 is
major) and 211 heap-shaped stack words seen, **zero** of them point
into a pinned block.

If hypothesis (b2) had been true — pinned blocks correctly carry
`BF_PINNED` and PROBE22POISON was wrongly stomping them — we'd have
seen pinned_skip > 0 and the crash would have stopped.  Both did
not happen.

Hypothesis (a) — the BS underlying byte array is not pinned —
predicts pinned_skip = 0 trivially: there's no pinned MBA in the
graph for the stack to reference.

There's a residual hypothesis (b1) that PROBE22POISON was wrongly
stomping pinned-memory `Addr#`s and PROBE23 still does the same
because the **pinned blocks transiently present `bd_flags=0`** at the
moment our probe runs (post-scavenge, before `resize_nursery() /
resetNurseries()`).  That would explain both pinned_skip=0 AND the
unchanged crash.  But it requires the GHC RTS to clear `BF_PINNED`
during scavenge in some way, which is not documented behavior and
not visible in `rts/sm/Evac.c` / `rts/sm/Scav.c` on a quick read.
Reasonable reading: this would need its own audit before being
treated as the explanation.

## What this means cumulatively

| Session | Hypothesis                                                 | Outcome |
|---------|------------------------------------------------------------|---------|
| 20      | "stack-frame bitmaps are wrong on PPC32 cross-build"      | PROBE20/21 finds 184 heap-shaped non-evac slots; not-yet-classified |
| 21      | "bitmap encoding step is wrong"                           | Disproved.  `BITMAP_BITS_SHIFT=5` both sides; mkLivenessBits faithful. |
| 22      | "`stackMapToLiveness` or upstream StackMap construction is wrong" | Disproved for Catch.hs.  All 15 True-marked slots are dead. |
| 23      | "the bug is in another module's bitmap; PROBE22POISON will find it" | Found 1 / 9 real read-after-poison events — in FastString. |
| 24      | "that 1 read is into a slot whose StackRep IS wrong"      | Disproved.  The slot is an `Addr#`, correctly typed non-pointer. |
| **25**  | **"PROBE22POISON is itself the bug (pinned-Addr# false positive)"** | **Disproved.  Crash + pinned_skip pattern rules out (b2).** |

All five "the GC bug is somewhere on the stack-frame bitmap" framings
have now been refuted.  After session 25 the strongest hypothesis is:

> The bytestring/FastString boundary in stage2's compilation pipeline
> sometimes feeds a non-pinned-backed `BS` constructor into
> `mkFastStringByteString`.  Inside the inlined
> `Data.ByteString.Short.Internal.toShortIO` body, the BS's `Addr#` is
> spilled to the stack across an `stg_newByteArray#` call (which
> performs a GC), and after GC moves the underlying byte array, the
> `Addr#` on the stack is stale.  When the code resumes and does
> `copyAddrToByteArray#`, the memcpy reads from the stale address.
> Under `-A1m` this is what causes the production "variable not found"
> / SIGSEGV.

Confirming this requires finding the BS allocator that produces the
non-pinned BS.  Session 25 doesn't do that; session 26 should.

## What we didn't try

- Cross-checking the host `ghc` 9.2.8's Cmm for the same
  FastString.hs (handoff suggested it as a side-experiment, "20
  minutes useful background").  Skipping it: the result here is
  decisive enough that the host comparison wouldn't change the
  next-step plan.  Worth picking up if (a) gets stuck.
- Auditing `rts/sm/Evac.c` / `Scav.c` for any code path that clears
  `BF_PINNED`.  This would settle the residual (b1) hypothesis.
  ~30 min, deferred to session 26 as part of the BS-allocator hunt.
- Counting pinned-block stack slots across other inputs (e.g., a
  longer compile that exercises more of the BS allocator surface).
  All-zero pinned_skip on M5.hs is per se interesting but small-N.

## Methodology / files added this session

- [`probe23-poison-stack.patch`](probe23-poison-stack.patch) — the
  RTS patch (PROBE22POISON + BF_PINNED filter + PROBE23PINNED
  no-poison log).
- [`scripts/run-poison.sh`](scripts/run-poison.sh) — adapted from
  session 23.  Counts PROBE23 / PROBE23POISON / PROBE23PINNED lines.
- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — writeup.
- Logs at [`../../../log/session25/`](../../../log/session25/)
  (gitignored).
