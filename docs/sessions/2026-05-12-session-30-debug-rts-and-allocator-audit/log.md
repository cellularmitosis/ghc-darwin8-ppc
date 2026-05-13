# Session 30 log — debug-RTS revisit + PROBE30 allocator-state probe

## Plan on arrival

Per session-29 HANDOFF: top priority is rebuild stage2 with DEBUG /
sanity-check RTS, run Big2.hs `-A1m -G1 -DS` to catch corruption
inside `GarbageCollect()`.

**Caveat I noted before starting:** session 19 already tried `-DS`
on M5.hs at default `-A` and `-DS` did NOT fire (heap was internally
consistent; the bug is missed-root, not corrupted-heap-state).  But
that was a different reproducer (M5.hs, `$trModule2_ruq` panic);
session 28-29's repro is Big2.hs `-A1m -G1` producing
`refineFromInScope`.  The session-28 framing of "one bug, two
victim data structures" makes a redo of `-DS` worthwhile.

## Step 0 — baseline

```
ssh pmacg5
MD5 (Big2.hs) = 78b5eb77f66d284948fcea9d96013f81
Big2 -A1m -G1 × 5: rc=1 5/5, all `refineFromInScope` STG-time panic.
```

Matches session-29 README exactly.

## Step 1 — build & deploy debug-RTS stage2

`bash scripts/exp-deploy-stage2-debug.sh pmacg5` ran cleanly using
the script left over from session 19.  Produced
`/opt/ghc-stage2/bin/ghc-real-debug` on pmacg5 (193 MB).
`+RTS --info` confirms `RTS way = rts_debug`; `nm` confirms
`_checkSanity`, `_checkHeapChain`, `_checkNurserySanity` etc. linked.

Smoke test: `ghc-real-debug -c Big2.hs +RTS -A1G -RTS` produced a
valid 46340-byte `Big2.o` (rc=0).  Debug variant works for the
"unbroken" workaround flag combo.

## Step 2 — Big2 -A1m -G1 -DS

```
ghc-real-debug -c Big2.hs +RTS -A1m -G1 -DS -RTS
→ ghc-real-debug: panic! ... refineFromInScope ...
→ (Sp 706:30 simplify)
→ no `barf`, no `sanity`, no `inconsistent`, no `invariant`, no `assert` lines
→ no `Sanity check` output at all
```

15-line output total.  Just the panic and the call stack.  Sanity
check ran (silent on success) and DID NOT catch a corrupt heap.

Cross-verified with `-DS -DZ` (zero freed memory): **same panic
signature, same InScope set, same missing `$dNum_a1kO`.**  If the
missed data were "present-but-stale" (still readable from a freed
block), `-DZ` would convert reads to zero-deref.  Since the panic
is identical, the lost data isn't stale — it's been reused by a
fresh allocation.

This replicates session 19's step1 finding for the new (Big2,
refineFromInScope) reproducer:

- Sanity check passes → heap is internally consistent after GC.
- `-DZ` doesn't change panic → the lost slot's memory got REUSED
  by a fresh allocation post-GC, not freed-and-zero'd.

Combined: **a pointer that should be a GC root isn't being walked.
The closure it points to is therefore not evacuated.  Its
from-space block is freed and recycled.  The mutator reads through
the now-dangling pointer and sees fresh data — not the dictionary
binding it expected.**

## Step 3 — re-read sessions 20-24 + 28-29 to consolidate ruleouts

Reading order: session 19 step1 + step3 + HANDOFF; session 24's
README (which closes sessions 20-23's bitmap framing); session 27
exit; session 28 exit; session 29 README.  Consolidated remaining
suspects below.

What's ruled out by data, not theory:

- Session 19 PROBE19 → CAF list (`dyn_caf_list`) walking is correct.
  CAF counts are monotonically non-decreasing; never truncated.
- Session 19 + step1 → SMP atomics not at fault (non-threaded RTS
  uses no atomics on the GC path); `large_alloc_lim` doesn't
  overflow.
- Sessions 20-24 → stack-frame bitmap codegen produces correct
  bitmaps for the cases tested.  PROBE22POISON's read-after-poison
  crash is a stale-Addr# bug, not a bitmap mis-classification.
- Session 26 → ForeignPtrContents pinning is correct.  Zero
  `*+UNPINNED` BSes ever observed.
- Session 28 → `mut_list` scavenge and `static_objects` scavenge
  paths ruled out (PROBE28 per-cap, per-gen counters identical
  under M5 -A1m -G1 [PASS] and Big2 -A1m -G1 [FAIL]).
- Session 29 → per-closure-type scavenge / evacuate buggy-dispatch
  ruled out by the filename-sensitivity experiment.  Same source
  bytes, different filename → different pass/fail outcome.
- Session 30 (today) → `-DS` doesn't catch the bug.  Heap is
  internally consistent after every GC.

What remained per session 29 HANDOFF:

1. Audit `alloc_in_moving_heap` / `todo_block_full` for PPC32
   block-boundary bugs.
2. Audit forwarding-pointer / info-pointer 32-bit alignment paths.
3. Per-closure-SIZE histogram (vs per-type) to catch variable-size
   closure misclassification.
4. Bisect filename more aggressively to find a 1-byte flip.

Session 30 addresses #1 + #3 in one combined probe (PROBE30).

## Step 4 — design + implement PROBE30

Goal: instrument the to-space allocator paths so we can see *which
path the allocator takes* per GC, not just *what types it allocates*.
If a PPC32 block-boundary or big-object bug fires the GC corruption,
it'll show as a path-counter anomaly at Big2 GC 17.

Counters added in `rts/sm/GC.c` (static W_):

| name                       | what it counts                                   |
|----------------------------|--------------------------------------------------|
| `probe30_aim_calls`        | every `alloc_in_moving_heap` invocation          |
| `probe30_aim_pre_overflow` | aim invocations where `todo_free+size > todo_lim` (calls `todo_block_full`) |
| `probe30_tbf_can_extend`   | `todo_block_full` in-place extension hits        |
| `probe30_tbf_push_new`     | `todo_block_full` push-out + alloc-new hits      |
| `probe30_tbf_freed_empty`  | push-new path freed an empty block (closure spans block edge) |
| `probe30_atb_part_reuse`   | `alloc_todo_block` reused a `part_list` block    |
| `probe30_atb_alloc_group`  | `alloc_todo_block` called `allocGroup_sync` (closure > BLOCK_SIZE_W → BIG OBJECT path) |
| `probe30_atb_alloc_blocks` | `alloc_todo_block` refilled `gct->free_blocks`   |
| `probe30_atb_free_blocks`  | `alloc_todo_block` grabbed from `gct->free_blocks` |
| `probe30_evac_large_calls` | every `evacuate_large` invocation                |
| `probe30_size_hist[12]`    | log2-ish bucketed size of every `alloc_in_moving_heap` size arg |

Bumps:

- `rts/sm/Evac.c::alloc_in_moving_heap`: bump `aim_calls` +
  `size_hist[bucket]`, then if overflow bump `aim_pre_overflow`.
- `rts/sm/Evac.c::evacuate_large` (top): bump `evac_large_calls`.
- `rts/sm/GCUtils.c::todo_block_full`: bump `tbf_can_extend` or
  `tbf_push_new`; bump `tbf_freed_empty` on the empty-block-free
  path.
- `rts/sm/GCUtils.c::alloc_todo_block`: bump one of `atb_part_reuse`,
  `atb_alloc_group`, `atb_alloc_blocks`, `atb_free_blocks` per the
  branch taken.

Reset all at GC start.  Emit two debugBelch lines per GC alongside
PROBE28/29 (one line of counters, one line of size hist).

Patch lives at [`probe30-rts.patch`](probe30-rts.patch) — re-applies
PROBE28+PROBE29 from session 29 PLUS the PROBE30 additions.

## Step 5 — rebuild + deploy

```
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh >/dev/null
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a
# 4.84 s
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
# ~3 min cross-link
```

Stage2 smoke-test confirmed PROBE30 lines in output.  Sample from a
trivial `putStrLn` program GC 1:

```
PROBE30 gc=1 aim=103 aimPre=0 tbfExt=0 tbfNew=0 tbfFreedEmpty=0 atbPart=0 atbGrp=0 atbBlks=0 atbFree=0 evacLarge=5
PROBE30 gc=1 sizeHist s1=27 s2=62 s3=6 s4=5 s5=2 s7=1
```

Tiny workload — no `todo_block_full` overflow needed.  Numbers are
sane.

## Step 6 — run probe matrix

[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) =
session-29's matrix runner, retargeted to `logs/`.

```
=== M5.hs   iters=5 flags='+RTS -A1m -G1 -RTS' ===  5/5 PASS, 13 GCs each
=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===  5/5 FAIL, 17 GCs each, refineFromInScope
```

Matches session 28+29.  PROBE30 doesn't suppress or flip the bug —
single-ALU-op bumps don't perturb enough.

## Step 7 — analyse PROBE30 data

**All 5 Big2 GC-17 PROBE30 lines are byte-identical across iters
(md5 match).  All 5 M5 GC-13 PROBE30 lines are byte-identical too.**
Just like PROBE28+29, the bug is fully deterministic on input.

### Headline numbers

| Field                | M5 GC 13 (PASS) | Big2 GC 17 (FAIL) | Big2/M5 |
|----------------------|---------------:|------------------:|--------:|
| `aim`                |         96 968 |           120 079 |   1.24× |
| `aimPre`             |          2 873 |             3 638 |   1.27× |
| `tbfExt`             |          2 508 |             3 180 |   1.27× |
| `tbfNew`             |            365 |               458 |   1.25× |
| `tbfFreedEmpty`      |              0 |                 0 |     —   |
| `atbPart`            |              5 |                 2 |   0.40× |
| `atbGrp`             |              0 |                 0 |     —   |
| `atbBlks`            |             23 |                30 |   1.30× |
| `atbFree`            |            338 |               427 |   1.26× |
| `evacLarge`          |             17 |                 8 |   0.47× |

The "workload baseline" Big2/M5 ratio is ~1.27× (from copiedW).
Every allocator path that scales with workload sits in 1.24–1.30×.
**No allocator path is uniquely fired at Big2 GC 17.**

Two values are *under*-represented:
- `atbPart` (5 → 2) — part-block reuse goes down.  Tiny absolute
  counts.
- `evacLarge` (17 → 8) — large evacs go down at Big2 GC 17, while
  total work goes UP.  Surprising but not a smoking gun on its own.

### Size histogram

Big2 GC 17 vs M5 GC 13 size-bucket Big2/M5 ratios:

| bucket | size range | M5 GC 13 | Big2 GC 17 | Big2/M5 |
|-------:|-----------:|---------:|-----------:|--------:|
| s1     |          1 |   20 680 |     24 696 |   1.19× |
| s2     |          2 |   55 825 |     67 837 |   1.22× |
| s3     |        3-4 |   18 731 |     24 668 |   1.32× |
| s4     |        5-8 |    1 217 |      2 052 |   1.69× |
| s5     |       9-16 |      246 |        556 |   2.26× |
| s6     |      17-32 |        1 |          1 |   1.00× |
| s7     |     33-64  |      259 |        260 |   1.00× |
| s8     |     65-128 |        7 |          7 |   1.00× |
| s9     |    129-256 |        1 |          1 |   1.00× |
| s10    |    513-1024|        1 |          1 |   1.00× |
| s11    |     > 1024 |        0 |          0 |     —   |

Buckets s6..s10 are **identical** between M5 and Big2 — same
absolute count.  Buckets s1..s5 scale with workload (1.19–2.26×).
**No size bucket is uniquely fired at Big2 GC 17.**

### What this rules out

1. **The "big object" path is never hit in either run** (`atbGrp=0`
   for every GC of every iter, and `s11=0` everywhere).  No closure
   size > BLOCK_SIZE_W = 1024 words gets copied through
   `alloc_todo_block`'s `size > BLOCK_SIZE_W` branch.  So the
   session-29 HANDOFF's hypothesis "PPC32 block-boundary bug in the
   multi-block-group allocator path" is **disproved by data**.

2. **`tbfFreedEmpty=0` everywhere.**  No closure ever spans a block
   edge leaving an empty block behind.  Rules out the
   "evacuate-into-second-block" pathology.

3. **No allocator state is uniquely fired at the failing GC.**  Every
   counter scales with workload at the 1.24–1.30× baseline.

4. **No size class is uniquely fired at the failing GC.**  Buckets
   either scale with workload (small) or match exactly (medium /
   large).

5. **Per-closure-type histograms scale identically (PROBE29).**  No
   type is uniquely fired.

Combining 1-5: **no aggregate per-GC counter discriminates Big2
GC 17 from a typical GC.**  This strongly implies the bug is a
*single-event-at-a-specific-address* error, invisible to any
aggregate counter.  Each GC processes hundreds of thousands of
closures uniformly; only one address-or-pointer interaction during
GC 17 of Big2 goes wrong.

### What this means for next steps

The "specific address mishandling" framing kills aggregate
instrumentation as a useful approach.  The probe family we've been
using (PROBE28/29/30) is now exhausted.  Next-session probe
strategies need to track *individual* events, not aggregates.

Top candidates for session 31:

A. **Track which root-walker misses the lost pointer.**  Add
   per-iteration logging to `markCAFs`, `scavenge_static`, the
   stack walker, `scavenge_capability_mut_lists`, etc., printing
   the addresses they hand to `evacuate`.  Compare the address
   stream from a passing GC to a failing GC.  If the failing GC
   visits a *different* root set, that's the smoking gun.

B. **Track the saved/restored mutator state.**  Print
   `Capability->r.rCurrentTSO`, `cap->r.rCurrentNursery`,
   `cap->r.rCurrentAlloc`, etc., before/after every GC.  If any
   field shifts unexpectedly across GC 17 in Big2, that's the
   StgRegTable mis-offset session 19 flagged.

C. **Bisect filename to a 1-byte flip.**  Mechanical, cheap.  Just
   needs many runs.  Doesn't require a probe.  Per session 29: A.hs
   passes, AA.hs fails; B.hs/BB.hs pass, BBB.hs fails.  If we can
   find a single (filename1, filename2) pair differing in one byte
   that flips pass/fail, the heap shift is extremely small and may
   be reverse-engineerable.

D. **Track scavenge_stack frame-by-frame.**  Per session 24 the
   bitmap is correct for the FastString case examined, but the
   walking *loop* through stack frames hasn't been instrumented.
   Add a per-frame address dump.

E. **Use `+RTS -Dg`** (GC trace) on `ghc-real-debug`.  Voluminous
   per-GC trace lines (push/pop block, scan/copy progress).  Will
   produce ~MB of output, but may reveal a transition step where
   Big2 GC 17 differs from a typical GC.  Cost: 0 build time
   (debug RTS is already deployed), ~30 s per run.

## Step 8 — revert + clean redeploy

```
cd external/ghc-modern/ghc-9.2.8
git checkout -- rts/sm/GC.c rts/sm/Evac.c rts/sm/Scav.c rts/sm/GCUtils.c
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a
# 4.91 s

cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Smoke test: Big2 -A1m -G1 panics 3/3 with `refineFromInScope`,
zero PROBE lines in output → clean v0.12.0-equivalent stage2.

The debug-RTS-linked stage2 (`/opt/ghc-stage2/bin/ghc-real-debug`)
is **kept on pmacg5** for session 31's potential use of `-Dg` /
`-DZ` etc.  Sessions 19's HANDOFF removed it at end-of-session to
avoid confusion; session 30 leaves it, on the rationale that it's
informative and clearly distinct from `ghc-real`.  Session 31 can
remove it via `ssh pmacg5 'rm /opt/ghc-stage2/bin/ghc-real-debug'`
if they want a clean slate.
