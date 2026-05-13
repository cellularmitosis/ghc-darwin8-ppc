# Session 29 findings — PROBE29 histograms + the filename-sensitivity discovery

## TL;DR

- **PROBE29** (PROBE28 + per-closure-type histograms in
  `scavenge_block` and `evacuate`, plus a forwarding-pointer-hit
  counter) shows that under M5 `-A1m -G1` (PASS) and Big2 `-A1m -G1`
  (FAIL), Big2's failing GC 17 has **no closure type that's absent
  from M5's GCs**.  Every type in Big2 GC 17 also appears in M5 GC
  1–13.
- **Workload differs but no per-type smoking gun.**  Big2 GC 17 is
  ~27% larger than M5 GC 13 in copiedW; nearly every closure type
  scales by 1.1×–1.4× — a uniform-workload increase.  Most
  workload-disproportionate types are ARR_WORDS (1.66× scav),
  BLACKHOLE evacuate (4.81×), THUNK_2_0 (1.42×), but **none is the
  trigger** (see filename experiment below).
- **All 5 failing Big2 iters produce BYTE-IDENTICAL histograms at
  GC 17** — fwdHits=51890, every `t<n>=` and `e<n>=` count
  matching to the digit.  Bug is fully deterministic on input.
- **🟥 The bug is filename-sensitive.**  Byte-identical Big2.hs
  source compiled under filename `Big2.hs` panics 5/5 at GC 17;
  under filename `B0.hs` (or `BB.hs`, `X.hs`, `A.hs`) it PASSES at
  GC 18.  `md5` confirms identical bytes.  The pass/fail boundary
  isn't monotone in filename length — `A.hs` passes, `AA.hs` fails;
  `BB.hs` passes, `BBB.hs` fails.  Different RTS flags shift which
  filenames trigger.
- **This rules out a per-closure-type scavenge / evacuate bug as
  the root cause.**  Such a bug would fire whenever that type is
  processed.  The bug instead requires a specific *heap state* —
  identical source bytes can produce wildly different heap layouts
  depending on filename-derived allocations, and only some of those
  layouts trigger it.
- **New audit direction:** heap-block geometry, alignment, block-
  boundary crossings, allocator state, info-table reads at specific
  addresses — anything where exact memory layout matters on PPC32
  (32-bit, big-endian, 4 KB blocks).  Per-closure-type audit of
  `scavenge_block`'s switch is unlikely to find it.
- v0.12.0 ships unchanged.  Probe reverted at session end; clean
  stage2 redeployed.

## The probe

3 source files touched.  See [`probe29-rts.patch`](probe29-rts.patch)
for the diff.

### Declarations + reset + print (`rts/sm/GC.c`)

```c
/* near consec_idle_gcs, after PROBE28's declarations */
W_ probe29_type_hist[64];
W_ probe29_evac_fresh[64];
W_ probe29_evac_fwd_hits;

/* at the start of each GarbageCollect(), after PROBE28's pre-GC mut snapshot */
for (uint32_t tt = 0; tt < 64; tt++) {
    probe29_type_hist[tt] = 0;
    probe29_evac_fresh[tt] = 0;
}
probe29_evac_fwd_hits = 0;

/* at end of GarbageCollect(), after PROBE28's summary line */
debugBelch("PROBE29 gc=%llu scav fwdHits=%lu", ...);
for (tt < 64) if (probe29_type_hist[tt] != 0) debugBelch(" t%u=%lu", ...);
debugBelch("\nPROBE29 gc=%llu evac", ...);
for (tt < 64) if (probe29_evac_fresh[tt] != 0) debugBelch(" e%u=%lu", ...);
```

### Bumps (`rts/sm/Scav.c` and `rts/sm/Evac.c`)

Scav.c — bump in `scavenge_block`'s main loop:

```c
info = get_itbl((StgClosure *)p);
if ((uint32_t)info->type < 64) probe29_type_hist[info->type]++;   /* PROBE29 */
```

Evac.c — bump on forwarding-pointer hit:

```c
if (IS_FORWARDING_PTR(info))
{
    probe29_evac_fwd_hits++;  /* PROBE29 */
    /* existing code: shortcut to the forwarded address */
}
```

Evac.c — bump per source-type on fresh evacuation, just before the
`switch`:

```c
{
    uint32_t pt = (uint32_t)INFO_PTR_TO_STRUCT(info)->type;
    if (pt < 64) probe29_evac_fresh[pt]++;
}
switch (INFO_PTR_TO_STRUCT(info)->type) { ... }
```

The bumps are single ALU ops per closure — millions per GC but no
I/O.  Far less perturbing than PROBE28's per-GC debugBelch.

## Per-GC summary line format

After PROBE28's `PROBE28 gc=…` line, two new lines per GC:

```
PROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...
PROBE29 gc=<n> evac e<type>=<count> ...
```

Indexed by `info->type` (0..63).  Zero buckets skipped for brevity.

## Data — matrix under PROBE29

```
=== M5.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===
  iter01..05 rc=0 gcs=13 OK            pass=5 fail=0

=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===
  iter01..05 rc=1 gcs=17 panic         pass=0 fail=5
```

Reproduces session 28 exactly.

## Determinism check

All 5 Big2 GC 17 PROBE29 lines are byte-identical:

```
PROBE29 gc=17 scav fwdHits=51890 t1=22713 t2=15929 t3=5424 t4=27928
  t5=3947 t6=34 t7=12 t8=38 t9=1371 t10=930 t11=682 t15=3259
  t16=10182 t17=516 t18=13858 t22=4018 t25=401 t39=244 t40=16
  t42=8047 t43=244 t44=13 t46=8 t47=276 t48=3 t49=4 t52=1
```

`PROBE28` line for the same GC is also byte-identical across iters:

```
PROBE28 gc=17 N=0 maj=1 ng=1 preMut0=0 staticChain=174027
  copiedW=464982 liveW=485763 liveB=483
```

This confirms the bug is fully deterministic on its input.

## Histogram diff — M5 GC 13 (PASS) vs Big2 GC 17 (FAIL)

Big2's failing GC has copiedW = 464982 vs M5's last GC's 366812 —
~27% more work.  A uniform 1.27× scaling is the workload baseline.

| Type                       | Code | M5 GC 13 (PASS) | Big2 GC 17 (FAIL) | Big2/M5 |
|----------------------------|-----:|----------------:|------------------:|--------:|
| CONSTR                     |   1  |          18 361 |            22 713 |   1.24× |
| CONSTR_1_0                 |   2  |          12 150 |            15 929 |   1.31× |
| CONSTR_0_1                 |   3  |           5 029 |             5 424 |   1.08× |
| CONSTR_2_0                 |   4  |          23 677 |            27 928 |   1.18× |
| CONSTR_1_1                 |   5  |           3 827 |             3 947 |   1.03× |
| CONSTR_0_2                 |   6  |              35 |                34 |   0.97× |
| CONSTR_NOCAF               |   7  |              12 |                12 |   1.00× |
| FUN                        |   8  |              49 |                38 |   0.78× |
| FUN_1_0                    |   9  |           1 462 |             1 371 |   0.94× |
| FUN_0_1                    |  10  |             918 |               930 |   1.01× |
| FUN_2_0                    |  11  |             626 |               682 |   1.09× |
| THUNK                      |  15  |           2 732 |             3 259 |   1.19× |
| THUNK_1_0                  |  16  |           7 698 |            10 182 |   1.32× |
| THUNK_0_1                  |  17  |             519 |               516 |   0.99× |
| THUNK_2_0                  |  18  |           9 767 |            13 858 |   **1.42×** |
| THUNK_SELECTOR             |  22  |           4 036 |             4 018 |   1.00× |
| PAP                        |  25  |             327 |               401 |   1.23× |
| MVAR_CLEAN                 |  39  |             256 |               244 |   0.95× |
| MVAR_DIRTY                 |  40  |              17 |                16 |   0.94× |
| **ARR_WORDS**              |  42  |           4 853 |             8 047 | **1.66×** |
| MUT_ARR_PTRS_CLEAN         |  43  |             256 |               244 |   0.95× |
| MUT_ARR_PTRS_DIRTY         |  44  |               1 |                13 |  13.00× |
| MUT_ARR_PTRS_FROZEN_CLEAN  |  46  |               7 |                 8 |   1.14× |
| MUT_VAR_CLEAN              |  47  |             277 |               276 |   1.00× |
| MUT_VAR_DIRTY              |  48  |              60 |                 3 |   0.05× |
| WEAK                       |  49  |              16 |                 4 |   0.25× |
| TSO                        |  52  |               0 |                 1 |     new |

In `evac` (fresh-evacuate dispatch), additional rows:

| Type                       | Code | M5 GC 13 | Big2 GC 17 | ratio |
|----------------------------|-----:|---------:|-----------:|------:|
| BLACKHOLE                  |  38  |      130 |        625 | **4.81×** |

Anomalies relative to 1.27× workload baseline:

- **ARR_WORDS (42): 1.66×**, +3194 closures.
- **THUNK_2_0 (18): 1.42×**, +4091 closures.
- **CONSTR_1_0 (2): 1.31×**, +3779 closures.
- **THUNK_1_0 (16): 1.32×**, +2484 closures.
- **BLACKHOLE evac: 4.81×**, +495 fresh evacuations.

`MUT_VAR_DIRTY (48)` and `WEAK (49)` are *under*-represented in
Big2 (1/20 and 1/4 of M5's count) — interesting but on tiny absolute
counts.

**Crucially: no closure type appears in Big2 GC 17 that wasn't
already present in earlier GCs (Big2 GCs 1–16 and M5 GCs 1–13).**
The bug doesn't fire the first time type X is processed; it fires
specifically at GC 17 of Big2.

## Why "ARR_WORDS is the bug" doesn't work

ARR_WORDS is workload-disproportionate (1.66×).  Hypothesis: a bug
in evacuating ARR_WORDS on PPC32 — e.g. miscomputing `arr_words_sizeW`
on PPC32's 4-byte words.

But:

1. **M5 has 4853 ARR_WORDS in GC 13 and PASSES.**  Big2 has 8047
   in GC 17 and fails.  If ARR_WORDS were buggy, M5 should
   sometimes crash too.  It never does.
2. **Big2 GCs 1–16 also process thousands of ARR_WORDS, all
   successfully.**  GC 14 had 7708 ARR_WORDS, GC 15 had 7873, GC
   16 had 8353, GC 17 had 8047 — and only GC 17 fires the bug.
3. **The filename experiment (below) is dispositive**: the same
   source bytes (so the same ARR_WORDS workload) pass under one
   filename and fail under another.  The trigger can't be the
   number of ARR_WORDS scavenged.

Same logic kills the THUNK_2_0 / BLACKHOLE / CONSTR_1_0 hypotheses.

## The filename experiment

The original session-28 HANDOFF queued a "Big2 variant bisect" —
strip imports / functions progressively to find which removal flips
fail → pass.  When we did this with file variants `B0.hs` through
`B4.hs`:

```
  B0.hs (= byte-identical to Big2.hs)   pass=3 fail=0 of 3, gcs=18
  B1.hs (drop topK + swap)               pass=3 fail=0 of 3, gcs=17
  B2.hs (also drop Data.Map.Strict)      pass=0 fail=3 of 3, gcs=15
  B3.hs (also drop scaleAndShift,
         cumsum)                         pass=0 fail=3 of 3, gcs=15
  B4.hs (bare module)                    pass=0 fail=3 of 3, gcs=12
```

But B0.hs has the **same bytes** as Big2.hs!  `md5` confirmed.  The
only difference is the filename.

Followup single-iter sweep on byte-identical content with varying
filenames:

```
  Big2.hs    rc=1 gcs=17 panic     (FAIL)
  B0.hs      rc=0 gcs=18           (PASS)
  BB.hs      rc=0 gcs=18           (PASS)
  BigTwo.hs  rc=1 gcs=17           (FAIL)
  X.hs       rc=0 gcs=18           (PASS)
  Big22.hs   rc=1 gcs=17           (FAIL)
  Big2a.hs   rc=1 gcs=17           (FAIL)
  aBig2.hs   rc=1 gcs=17           (FAIL)
  ABCDEF.hs  rc=1 gcs=17           (FAIL)
```

Length sweep:

```
  A.hs       PASS (gcs=18)    AA.hs    FAIL (gcs=17)
  AAA..AAAAAA.hs               all FAIL (gcs=17)
  B.hs       PASS (gcs=18)    BB.hs    PASS (gcs=18)
  BBB..BBBBB.hs                all FAIL (gcs=17)
```

Boundary is name-specific, not length-monotonic.  `A.hs` flips at
2 chars; `B.hs` flips at 3 chars.

Cross-flag check:

```
-A1m default (=-G2):
  Big2.hs PASS, BB.hs FAIL, BBB.hs FAIL, X.hs FAIL, AAA.hs FAIL

-A2m -G1:
  Big2.hs FAIL, BB.hs PASS, BBB.hs PASS, X.hs FAIL, AAA.hs PASS
```

Different RTS allocation parameters redistribute which (filename,
flags) tuples hit the bug.

### What this means

The filename string flows through GHC's internal data structures —
ModSummary, source-span attributions, FastString interning of the
path, intermediate file naming for `.hi` / `.o` outputs.  Each
additional byte changes the cumulative allocation pattern.  By the
time GC 17 runs, the heap layout differs depending on filename.

So **the trigger is a specific heap layout**.  Not a specific
closure type appearing.  Not a specific volume of any type.  The
exact memory layout — which closures live where, which to-space
blocks are contiguous, which alignment boundaries get crossed.

Hypotheses consistent with the filename data:

- A **block-boundary crossing bug** in `alloc_in_moving_heap` or
  `todo_block_full` — when a closure crosses a block edge under a
  specific alignment, the scavenge reads garbage.
- An **info-pointer / forwarding-pointer alignment bug** on PPC32
  — the IS_FORWARDING_PTR test uses bit 0.  On PPC32 with 4-byte
  pointers, all valid closure pointers have bit 0 = 0.  But if a
  closure ends up at an odd address (somehow), the test
  misclassifies it.
- A **`ROUNDUP_BYTES_TO_WDS` rounding bug** on PPC32 — an ARR_WORDS
  with a `bytes` value not aligned to W_ would round up to the
  next word, but if the rounding is off by one in either direction
  the next closure's header gets read as a pointer.
- A **memory-overlap / aliasing bug** in to-space allocation — two
  closures end up overlapping if the bump allocator returns the
  same pointer twice due to an extension-vs-block-full race-free
  bug on PPC32.

Hypotheses NOT consistent with the filename data:

- "scavenge_block dispatch on type X is buggy" — type X would be
  processed in many GCs of many inputs, but the bug fires only
  on specific (filename, flags) tuples.
- "evacuate of closure type X copies the wrong number of words" —
  same logic.
- "static_objects walking is buggy" — already ruled out by
  session 28.
- "mut_list scavenge is buggy" — already ruled out by session 28.

## Open questions / next-step priorities for session 30

### Top: rebuild with DEBUG / sanity checks

The RTS supports `+RTS -DS` for sanity-checking heap invariants
after every GC.  This needs a DEBUG-flavored rebuild and a stage2
linked against `libHSrts-1.0.2_debug.a` (Hadrian produces this
artifact already during a `quick-cross` build).

If sanity check catches the corruption inside `GarbageCollect()`
rather than letting it leak to the next mutator phase, we'll get a
much more precise failure point.

Cost: 1 RTS rebuild + 1 deploy + a few runs.  ~30 min.

### Second: audit `alloc_in_moving_heap` / `todo_block_full`

These are the to-space bump allocator.  Suspect lines in
`rts/sm/Evac.c` and `rts/sm/GCUtils.c`:

- `alloc_in_moving_heap` (Evac.c:111) — pre-increments `ws->todo_free`
  before the limit check, expecting `todo_block_full` to compensate.
  Check: does the compensation hold up at block-boundary crossings?
- `todo_block_full` (GCUtils.c:235) — `ws->todo_free -= size` is the
  expected pre-decrement on entry.  Then it decides "extend" or
  "push out the block."  Is the `can_extend` predicate (line 270)
  correct on PPC32 with 4 KB blocks?
- `alloc_todo_block` (GCUtils.c:330) — `bd->start + bd->blocks * BLOCK_SIZE_W - bd->free > (int)size`
  uses `int` on the LHS-cast — on PPC32 `int` is 32-bit; if the
  arithmetic overflows for large blocks it'd return a wrong answer.

PPC32 alignment concerns:

- `BLOCK_SIZE_W = 1024` words on PPC32 (vs 512 on amd64).  Block
  bounds calculations should still be correct but check arithmetic.
- `bd->start` is aligned to `BLOCK_SIZE` (4 KB) per `BLOCK_ROUND_DOWN`.
  Check that `bd->blocks * BLOCK_SIZE_W` doesn't overflow on PPC32.

### Third: audit forwarding-pointer / info-pointer 32-bit paths

In `rts/sm/Evac.c`:

- `IS_FORWARDING_PTR` / `MK_FORWARDING_PTR` / `UN_FORWARDING_PTR`
  in `ClosureMacros.h:229-231` — these manipulate bit 0.  PPC32
  closure pointers are 4-byte aligned (bit 0 and bit 1 both 0).
- `evacuate()` line ~809: `info = ACQUIRE_LOAD(&q->header.info)`
  — non-threaded RTS expands ACQUIRE_LOAD to `*ptr`.  PPC32 32-bit
  aligned load.
- `INFO_PTR_TO_STRUCT(info)->type` — with `TABLES_NEXT_TO_CODE = NO`
  (per stage2's lib/settings), `INFO_PTR_TO_STRUCT(info) = info`
  (Identity).  So reading `info->type` is just a load from the
  info-table struct.

### Fourth: per-closure-SIZE histogram (alternative to per-type)

Add a histogram bucketed by `closure_sizeW(p)` in `scavenge_block`.
Big2's failing GC may have a specific size class that M5's GCs lack.
If we see a unique large-size closure in Big2, that's evidence for
an alignment-padding bug on variable-size closures (ARR_WORDS,
MUT_ARR_PTRS, PAP, AP_STACK, etc.).

### Fifth: dump pre-fail heap state

Add a probe that, just before the panic-causing mutator code path
reads from the corrupted closure, dumps the closure's address +
contents.  This requires identifying the corruption site in
Simplifier `refineFromInScope` and instrumenting around it.  More
invasive but would identify the EXACT corrupted closure.

## Process notes

- **PROBE29 perturbation** is small (single ALU op per closure,
  no I/O beyond PROBE28's existing per-GC printf).  Confirmed not
  bug-suppressing: same outcomes as PROBE28-only (Big2 -A1m -G1
  panics 5/5 with `refineFromInScope` signature).
- **The deploy step is slow** (~3 min) because stage2 is a 193 MB
  cross-link.  An RTS-only rebuild is 5 s but the deploy has to
  re-cross-link the whole stage2 binary.  Could potentially be
  optimized by linking only the RTS lib into a wrapper, but the
  current deploy script is fine for low-rate iteration.
- **Mind the background-task harness** — `Bash` tool sometimes
  defers long commands to background mode.  Wait for the completion
  event rather than re-issuing the command, or you end up with
  duplicate work.

## Files added this session

- [`README.md`](README.md), this `findings.md`,
  [`HANDOFF.md`](HANDOFF.md), [`log.md`](log.md),
  `commits.md` — writeup.
- [`probe29-rts.patch`](probe29-rts.patch) — the PROBE29 patch
  (re-applicable via `git apply` inside
  `external/ghc-modern/ghc-9.2.8`).
- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) —
  the M5 / Big2 × `-A1m -G1` matrix.
- [`scripts/diff-histograms.sh`](scripts/diff-histograms.sh) —
  diff two PROBE29 GCs side-by-side.
- [`scripts/big2-bisect.sh`](scripts/big2-bisect.sh) — the Big2.hs
  variant bisect (that uncovered the filename effect).
- Run logs at [`logs/`](logs/)

