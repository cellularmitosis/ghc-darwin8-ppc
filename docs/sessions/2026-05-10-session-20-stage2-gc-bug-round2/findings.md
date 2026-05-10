# Session 20 findings — things learned that will matter later

## The big result

**The stage2 GC bug is a missed-root caused by wrong stack-frame
bitmaps.**  Specific stack frames in stage2 ghc carry bitmaps that
mark certain payload slots as "non-pointer", but those slots
actually contain real heap pointers.  GC dutifully skips those
slots; the pointers go stale after the from-space they reference is
recycled; subsequent reads through the stale pointer yield garbage.

Symptom: typechecker `Bag` losing entries → "variable not found
$trModule2_ruq" panic.

This is **the proximate cause** for the v0.11.0 stage2 panic that
`-A1G` works around.

## How we found it

### Step 0 — rule out the session-19 HANDOFF top suspect

Session-19 fingered "PPC32 `StgRegTable` field offset mismatch" as
the top suspect.  Disassembling
`_build/stage1/rts/build/c/sm/Storage.o::updateNurseriesStats`
showed:

```
lwz r4, 0x340(r3)    ; r.rCurrentNursery — 0x340 = 832
lwz r4, 0x344(r3)    ; r.rCurrentAlloc   — 0x344 = 836
```

Both match `OFFSET_Capability_r (12) + OFFSET_StgRegTable_rCurrent*
(820/824) = 832/836` from `_build/stage1/lib/DerivedConstants.h`.
Sister project's BUG-010 fix (LLVM-8 patch 0013, restoring PPC32
Darwin "power" struct alignment field-cap) is in effect.  C and Cmm
agree on layout.  **Hypothesis dead.**

### Step 1 — PROBE20 v1: stack-pointer count summary per GC

Added per-GC stats in `rts/sm/GC.c::GarbageCollect`, after
scavenging is fully done but before `resetNurseries()` recycles
from-space:

- Walk `capabilities[0]->run_queue_hd->stackobj` from sp to
  stack_end.
- For each word, check if it's `HEAP_ALLOCED`; if so, look up the
  bdescr and check `BF_EVACUATED`.
- Tally: total words, heap-shaped words, of-those-evacuated, by-gen.

**Result on M5.hs compile (3 iters of `+RTS -A1m -RTS`):**

```
iter1 / iter2 / iter3 (bit-for-bit identical):
  n_gc=25 heap_ptr=4779 evacd=4564 g0=3596
```

215 words on the typechecker's stack are heap-shaped but DON'T point
to BF_EVACUATED blocks.  All three iterations identical, confirming
session-19's "GC trace deterministic" finding.

`+RTS -A1G` control: 1 GC at exit only (after main thread done),
empty stack.  Demonstrates `-A1G` keeps GC away from the active
typechecker, which is why the workaround works.

### Step 2 — PROBE20 v2: dump individual non-evac'd pointers

Added `PROBE20BAD` lines for each non-evac'd HEAP_ALLOCED word, with
slot offset and value.  Across iter1/2/3 vanilla: bit-for-bit
identical 215 BAD lines.  All `bd_gen=0 bd_flags=0x0` (gen-0
from-space, freshly-recycled-but-not-yet-rebuilt).  Some values
repeat: `0x0cb15ed1` 24×, `0x0cb51339` 22×, `0x0cb2ef7c` 19× —
suggesting the typechecker holds a small set of CAFs and their
references are at consistent stack positions.

GC #4 of M5.hs's compile shows a striking 38-BAD pattern: 12
repeated frames × 3 BAD slots each, with two of the three values
constant across the 12 repetitions (`0x0cbfffe8`, `0x0cbfff8c`).
That's a recursive-typechecker stack with consistent CAF
references.

### Step 3 — PROBE21: bitmap-aware stack walker

Walked the stack frame-by-frame using `get_ret_itbl` to identify
each frame's info-table type, size, and bitmap.  For each
HEAP_ALLOCED non-evac'd slot, classify whether the bitmap claims
it's a pointer or a non-pointer slot.

**Result: 184/184 BAD slots have `is_ptr=0`** (bitmap claims
non-pointer, GC dutifully skipped).  Zero have `is_ptr=1`.

So GC is doing its job — it walks the bitmap correctly and
evacuates every slot the bitmap calls a pointer.  **The bug is in
the bitmap itself.**

(184 vs 215: the 31-line gap is RET_FUN/RET_BCO frames PROBE21
skipped because their bitmap layouts are more complex; we walked
through 20 of 25 GCs.)

### Step 4 — frame metadata + deref to confirm "real closure"

Added per-frame `PROBE21FRAME` line dumping `info=0x...`,
`bitmap_raw=0x...`, `size=N`, `bits=0x...`.  Also `deref_ok=1
info=0x...` on each BAD slot, dereferencing the pointer (safely,
within the bdescr's block range) to read the would-be info-table
pointer.

**Critical confirmation**: derefs of BAD pointers consistently
yield values that look like real info-table addresses, not Int#
junk.  Examples:

- `val=0x0cbff359 → info=0x092a204c` = `_ghczmprim_GHCziTuple_Z2T_con_info`
  (a 2-tuple constructor!)
- `val=0x0cb15ed1 → info=0x09141e68` = `_s8VC_info` (local closure
  inside `Control.Monad.Catch.zdwzdcuninterruptibleMask1`)
- `val=0x0cb15ed1 → info=0x0cb15d91` (heap garbage — same address
  read at a LATER GC after from-space was recycled, demonstrating
  the temporal corruption)

The fact that **at GC 0 a slot's deref yields a real info table**,
and **at GC 2 the same address's deref yields random heap data**,
proves the closures were real and the from-space they live in was
later reused for fresh allocations.  Textbook missed-root pattern.

## Affected info tables span multiple modules

The 184 BAD slots come from 14 distinct info-table addresses
spanning these modules:

| Info table     | Module                          | BAD count |
|----------------|---------------------------------|----------:|
| 0x9143d50      | Control.Monad.Catch             | 36        |
| 0x92462b8      | GHC.Base                        | 32        |
| 0x9186474      | Data.Map.Strict.Internal        | 26        |
| 0x8e52acc      | GHC.Iface.Binary                | 24        |
| 0x918a828      | Data.Map.Internal               | 16        |
| 0x924624c      | GHC.Base (different fn)         | 15        |
| 0x9186490      | Data.Map.Strict.Internal        |  9        |
| 0x92719c4      | GHC.List                        |  8        |
| 0x9189c18      | Data.Map.Internal               |  5        |
| (rest)         | various                         | 13        |

Different sizes and bitmap layouts — sizes 2, 3, 5, 6, 8, 9, 11
observed.  The bug is **systematic**, not specific to one Haskell
function.

## The most-frequent BAD payload-slot positions

Of 184 BADs:
- pay=1: 96 (52%)  — second slot of frame
- pay=2: 27
- pay=5: 17
- pay=7: 16
- pay=6: 12
- pay=4: 12
- pay=8: 4

Strongly skewed to `payload[1]` — the slot right after the
return-value position.

## What this rules in / out

✅ Real closures are stored at slots the bitmap calls non-pointer.
✅ The stale pointers point to gen-0 from-space.
✅ Deterministic across iter1/2/3 — same 184 BAD slots per run.
✅ Cross-build PPC32 specifically (host-built ghc on M5.hs is fine).
✅ All affected modules are imported into stage2 ghc.
❌ NOT a Cmm/C struct-offset issue (sister project's BUG-010 is fixed).
❌ NOT a missing PPC memory fence (non-threaded RTS uses no fences anyway).
❌ NOT specific to one function or one constructor.

## What's NOT yet known

- **Why** is the bitmap wrong?  Possibilities (in order of
  decreasing plausibility):
  1. GHC's StgToCmm liveness analysis decides specific slots are
     non-pointer when they really are pointers — but only on
     PPC32 cross-build, somehow.
  2. Cmm-level codegen bug emitting wrong bits in the bitmap word
     (e.g., bit-ordering reversed, bits shifted, overflow into the
     size field).
  3. Word-size confusion when host-arm64 ghc generates info tables
     for target-PPC32 (e.g., 64-bit alignment assumed where 32-bit
     was expected).
  4. SRT field interaction — PPC32 has different `srt` size or
     alignment in `StgInfoTable`.

- The actual function inside Data.Map.Strict.Internal /
  Control.Monad.Catch / etc. that owns each BAD info table.  The
  local label scheme (e.g., `_c8m6_info`) doesn't trivially
  map back to source.

## Why workaround `-A1G` works

With `-A1G`, the typechecker compiles in one block without ever
firing GC mid-compile.  Stale pointers don't accumulate, and by
the time the at-exit GC runs, the typechecker stack is gone.  So
the bug never bites: the wrong bitmaps are still there, but they
never get a chance to corrupt anything because no GC happens
during the typechecker's lifetime.

## Methodology notes

- The dev loop is ~15-20 min per RTS edit (1 min RTS rebuild +
  17 min stage2 cross-build + ppc-side link + scp).  Actually
  workable for printf-bisection iterations.
- `+RTS -DS` (sanity) panics deterministically and triggers
  earlier than vanilla `-A1m`, useful for getting reproducible
  data.
- Iteration determinism varies: most runs are byte-identical
  iter-to-iter, but occasionally we got 4779 → 4859 (iter1 vs
  iter2) — likely ASLR shifting allocation addresses such that a
  different number of false-positive HEAP_ALLOCED hits happen on
  Int# slots in some runs.

## Probes saved for future sessions

[`probe20-21-stack-walk.patch`](probe20-21-stack-walk.patch) — the
final PROBE20+PROBE21 patch (~225 lines added to
`rts/sm/GC.c::GarbageCollect`).  Apply with:
```
cd external/ghc-modern/ghc-9.2.8 && \
    patch -p1 < ../../../docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/probe20-21-stack-walk.patch
```

Reverse with `patch -p1 -R`.  Live patch dir is gitignored, but
the patched file regenerates the same probe data deterministically
on rebuild.

[`scripts/exp-stage2-probe20.sh`](../../../scripts/exp-stage2-probe20.sh)
— probe runner.  Compiles M5.hs under multiple flag sets and
captures `PROBE20*` lines.

Logs in [`log/session20/probe20-*`](../../../log/session20/) (last
runs from the deref iteration).
