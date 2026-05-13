# Session 30 findings — `-DS` revisit + PROBE30 allocator-state probe

## TL;DR

- **Sanity check (`+RTS -DS`) does NOT catch the Big2 -A1m -G1 bug.**
  The heap is internally consistent after every GC.  Replicates
  session 19's finding for the new (Big2, `refineFromInScope`)
  reproducer.  Confirms the bug is **missed-root**, not corrupted-
  scavenge-bookkeeping.
- **`-DZ` (zero freed memory) doesn't change the panic.**  The lost
  data isn't "present but stale" — it's been *reused* by a fresh
  allocation post-GC.
- **PROBE30** (allocator-state counters + per-evac size histogram)
  shows **no allocator path or size class is uniquely fired at
  Big2 GC 17.**  All path counters scale with workload at 1.24–
  1.30× over M5 GC 13; medium/large size buckets are exactly equal.
- **The "big object" path never fires** in either run
  (`atbGrp=0` for every GC; `s11=0` always).  No closure ever takes
  the multi-block-group allocator path.  This **disproves the
  session-29 HANDOFF's hypothesis** that the bug lives in PPC32
  block-boundary handling for big objects.
- **Combining PROBE29 + PROBE30: no aggregate per-GC counter
  discriminates Big2 GC 17.**  Per-closure-type, per-evacuator-
  flavor, per-allocator-path, per-size-class — all match the
  workload-scaled baseline.  The bug is a single-event mishandling
  at a specific address that no aggregate counter can see.
- Probe reverted.  Clean stage2 redeployed.  v0.12.0 ships
  unchanged.  Debug-RTS-linked `ghc-real-debug` left on pmacg5 for
  session 31's optional use.

## What the probe revealed (and ruled out)

### Setup: Big2 -A1m -G1 baseline reproducer (sessions 28-29)

```
M5.hs:    13 GCs, 5/5 PASS
Big2.hs:  17 GCs, 5/5 FAIL (refineFromInScope STG-time panic)
```

Big2 GC 17 is the last GC of the run.  M5 GC 13 is the last GC of
its run.  copiedW for Big2 GC 17 (464982) is ~27% larger than M5
GC 13 (366812), so the workload-scaling baseline is **1.27×**.

### Debug-RTS sanity check

`ghc-real-debug -c Big2.hs +RTS -A1m -G1 -DS -RTS` produces a
15-line output: just the `refineFromInScope` panic and call stack.
Zero `barf`, `sanity`, `inconsistent`, `invariant`, or `assert`
lines.  Heap is internally consistent post-every-GC.

`-DZ` adds zero-on-free to the GC.  Same panic, same InScope set,
same missing `$dNum_a1kO`.  If the missed data had been "still
readable but stale," `-DZ` would convert the read to a zero-deref
crash.  Since the panic is unchanged, **the lost slot's memory has
been REUSED by a fresh allocation** — a classic dangling-pointer-
to-fresh-allocation symptom of a missed GC root.

This replicates session 19's step1 finding on the new reproducer.
The framework: a pointer that should be a GC root isn't being
walked → its target closure isn't evacuated → the from-space block
is freed and reused → the mutator reads through the now-dangling
pointer and sees the new content (a fresh `*$dXxx` dictionary or
similar), not the dictionary it expected (`$dNum_a1kO`).

### PROBE30 allocator-state counters

Counters added (see [log.md](log.md) for full table):

- `aim` calls, of which `aimPre` overflowed to `todo_block_full`
- `tbf` extend hits, push-new hits, freed-empty hits
- `atb` part-reuse, alloc-group (big-object), alloc-blocks, free-blocks
- `evacLarge` calls (BF_LARGE path)
- `sizeHist[12]` log2-ish buckets of every aim size param

Big2 GC 17 vs M5 GC 13:

| field         |   M5 GC13 |   Big2 GC17 |  ratio |
|---------------|----------:|------------:|-------:|
| aim           |    96 968 |     120 079 |  1.24× |
| aimPre        |     2 873 |       3 638 |  1.27× |
| tbfExt        |     2 508 |       3 180 |  1.27× |
| tbfNew        |       365 |         458 |  1.25× |
| tbfFreedEmpty |         0 |           0 |    —   |
| atbPart       |         5 |           2 |  0.40× |
| atbGrp        |         0 |           0 |    —   |
| atbBlks       |        23 |          30 |  1.30× |
| atbFree       |       338 |         427 |  1.26× |
| evacLarge     |        17 |           8 |  0.47× |

Allocator-path counters all sit at the 1.24-1.30× workload baseline.
**No path is uniquely fired at Big2 GC 17.**

### Size histogram

| bucket | size range  |  M5 GC13 | Big2 GC17 |  ratio |
|-------:|------------:|---------:|----------:|-------:|
| s1     |           1 |   20 680 |    24 696 |  1.19× |
| s2     |           2 |   55 825 |    67 837 |  1.22× |
| s3     |         3-4 |   18 731 |    24 668 |  1.32× |
| s4     |         5-8 |    1 217 |     2 052 |  1.69× |
| s5     |        9-16 |      246 |       556 |  2.26× |
| s6     |       17-32 |        1 |         1 |  1.00× |
| s7     |       33-64 |      259 |       260 |  1.00× |
| s8     |      65-128 |        7 |         7 |  1.00× |
| s9     |     129-256 |        1 |         1 |  1.00× |
| s10    |    513-1024 |        1 |         1 |  1.00× |
| s11    |      > 1024 |        0 |         0 |    —   |

Buckets s6..s10 **identical** between M5 and Big2.  Small buckets
scale with workload.  No bucket is uniquely fired at the failing GC.

### Determinism check (md5)

```
Big2 GC 17 PROBE30 lines across 5 iters: all 5 → md5 f859e676...
M5  GC 13 PROBE30 lines across 5 iters: all 5 → md5 623b6fcd...
```

Full byte-identical determinism per (input, flags) tuple.
Consistent with session 29's PROBE29 byte-identical histograms.

## What this rules out

1. **The "big object" path** (closure > 1 block, multi-block group):
   `atbGrp=0` everywhere; `s11=0` everywhere.  Path never fires.
   Disproves session 29 HANDOFF's #2 hypothesis.

2. **Block-edge-spanning closures** that leave an empty block behind:
   `tbfFreedEmpty=0` everywhere.  Path never fires.

3. **Any "the allocator state at Big2 GC 17 is different" theory** —
   all path counters scale with workload.

4. **Any "Big2 GC 17 evacuates an unusual-sized closure" theory** —
   medium-and-large size buckets are byte-identical; small buckets
   scale uniformly.

5. **Per-closure-type "type X mishandled" theory** (session 29's
   ruleout, restated): combined with PROBE29's per-type histogram
   matching at 1.27× ratios.

## What's still on the table

Given the comprehensive aggregate-counter ruleout, the bug has to be
**a single-event mishandling at a specific address**.  Per session
19's framing: a pointer that should be a GC root isn't being walked.

Candidate "missed-root" sources, with status:

| candidate                                | status                        |
|------------------------------------------|-------------------------------|
| CAF list (`dyn_caf_list`) walking        | ruled out (session 19 PROBE19) |
| `mut_list` scavenge                      | ruled out (session 28)         |
| `static_objects` scavenge                | ruled out (session 28)         |
| SRT scavenge                             | ruled out (session 28)         |
| stack-frame bitmap codegen               | ruled out (sessions 20-24)     |
| per-closure-type scavenge / evac dispatch| ruled out (session 29)         |
| big-object allocator path                | ruled out (session 30 — TODAY) |
| **stack walker (the WALK, not the bitmap)** | NOT YET PROBED              |
| **`scavenge_one`** on a specific block   | NOT YET PROBED                |
| **Saved register state / StgRegTable**   | NOT YET PROBED                |
| **Weak pointers**                        | NOT YET PROBED                |
| **Stable pointers**                      | NOT YET PROBED                |
| **`scavenge_stack` step through frames** | NOT YET PROBED                |

The remaining candidates all involve a specific *traversal* missing
a slot.  Detecting them requires per-event instrumentation, not
aggregate counters.

## PPC32 arithmetic audit (incidental)

I read through `rts/sm/GCUtils.c` and `rts/sm/Evac.c` for PPC32-
specific arithmetic concerns flagged in session 29's HANDOFF, plus
`includes/rts/storage/Block.h` for the block-geometry macros.
Findings (none rule the bug in or out, but documented for the
record):

- `BLOCK_SHIFT = 12`, `MBLOCK_SHIFT = 20`, **same on both
  platforms**.  Block = 4 KB, megablock = 1 MB.
- `BLOCK_SIZE_W = BLOCK_SIZE / sizeof(W_) = 4096/4 = 1024` on
  PPC32 vs `4096/8 = 512` on amd64.
- `LARGE_OBJECT_THRESHOLD = BLOCK_SIZE * 8 / 10` (in BYTES, not
  words).  Same on both platforms = 3276.8 bytes.  In words: 819
  words on PPC32, 409 on amd64.  Pointer-heavy closures cross the
  threshold at fewer payload entries on amd64.
- `BLOCK_SIZE` uses the `UL` suffix (`1UL<<BLOCK_SHIFT`) so
  expressions like `n*BLOCK_SIZE` promote correctly per "Note
  [integer overflow]".
- `Bdescr(p)` macro uses 32-bit arithmetic on pointers (`(W_)p`).
  On PPC32, `W_` is `unsigned long` = 4 bytes.  Pointer values
  fit; arithmetic is correct.
- `IS_FORWARDING_PTR(p) = ((StgWord)p & 1) != 0`.  PPC32 closure
  pointers are 4-byte aligned (bit 1 and bit 0 both zero).  No
  alignment issue.
- `alloc_todo_block` line 337's `bd->start + bd->blocks * BLOCK_SIZE_W - bd->free > (int)size`:
  the cast `(int)size` is fine.  `size` is uint32_t in practice
  bounded by closure sizes (max ~ a few hundred words on PPC32).
  No overflow.

The arithmetic looks correct as written.  PROBE30 data confirms
the dynamic behavior on PPC32 stays in the regime where this
arithmetic was designed (small allocs, no big-object path).
**No PPC32-specific allocator bug surfaces in audit or in data.**

## Process notes

- Debug-RTS rebuild via `exp-deploy-stage2-debug.sh` worked
  unchanged from session 19.  Produces
  `/opt/ghc-stage2/bin/ghc-real-debug` (193 MB).  Distinct from
  the normal `ghc-real`.  Adds `-debug` to ghc-bin's link line
  → RTS linked is `libHSrts-1.0.2_debug.a` instead of `.a`.
- The debug-RTS-linked stage2 is ~the same size as normal (193 MB)
  but the RTS code is bulkier (extra assertions).  Performance is
  noticeably slower (~2× per compile) due to the assertion overhead.
- `+RTS -DS` produces NO OUTPUT when sanity check passes.  Only the
  `barf` / `sanity` messages on failure.  Silent success on every
  GC of every probe iteration confirms the heap is consistent.
- Bumping a static W_ counter is ~ 1 ALU op per closure.  PROBE30
  adds 11 counters but only 1-3 bumps per closure (one in
  alloc_in_moving_heap; sometimes one in todo_block_full /
  alloc_todo_block).  Total perturbation: micro-percent, not
  measurable.  Matches session 29's PROBE29 perturbation profile.

## Files added this session

- [`README.md`](README.md), this `findings.md`,
  [`HANDOFF.md`](HANDOFF.md), [`log.md`](log.md),
  [`commits.md`](commits.md) — writeup.
- [`probe30-rts.patch`](probe30-rts.patch) — combined PROBE28 +
  PROBE29 + PROBE30 diff over clean rts/sm/{GC,Scav,Evac,GCUtils}.c.
  Re-apply with `git apply` from inside `external/ghc-modern/ghc-9.2.8`.
- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) —
  the M5 / Big2 × -A1m -G1 matrix runner, retargeted to
  `logs/`.
- Run logs at [`logs/`](logs/)

