# Session 30 — stage2 GC bug, round 12 (debug-RTS revisit + PROBE30 allocator-state probe; aggregate counters can't see the bug)

**Dates:** 2026-05-12 (continuing the stage2 GC bug hunt from session 29).

**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on
Tiger uses `+RTS -A1G` workaround.  Session 29 ruled out per-closure-
type scavenge / evacuate bugs and uncovered the **filename-sensitivity
plot twist** — byte-identical Big2.hs source compiled under filename
`Big2.hs` panics 5/5 at GC 17; under `B0.hs` (or `BB.hs`, `X.hs`) it
PASSES.  The trigger is heap-layout-dependent, not closure-type-
dependent.  Session 29 HANDOFF queued: (a) rebuild with DEBUG/sanity-
check RTS, (b) audit `alloc_in_moving_heap` / `todo_block_full` for
PPC32 block-boundary bugs, (c) per-closure-SIZE histogram, (d) bisect
filename to a 1-byte flip.

**Status on exit:**

- **`+RTS -DS` does NOT catch the Big2 -A1m -G1 bug.**  Heap is
  internally consistent after every GC.  Replicates session 19's
  step1 finding for the new (Big2, `refineFromInScope`) reproducer.
- **`+RTS -DZ` doesn't change the panic.**  Lost data is reused-by-
  fresh-allocation, not present-but-stale.  Classic dangling-pointer-
  to-recycled-block signature → confirms the bug is a **missed GC
  root**, exactly as session 19 predicted.
- **PROBE30 implemented**: 10 allocator-state counters
  (alloc_in_moving_heap calls, todo_block_full extend-vs-push-new
  splits, alloc_todo_block paths, evacuate_large) + log2-ish size-
  class histogram of every `alloc_in_moving_heap` size param.
  Counters declared in `rts/sm/GC.c`, bumps in `rts/sm/Evac.c` and
  `rts/sm/GCUtils.c`.  Patch saved at
  [`probe30-rts.patch`](probe30-rts.patch); reverted before session
  end, clean stage2 redeployed.
- **PROBE30 matrix run** (M5.hs `-A1m -G1` 5/5 PASS, Big2.hs `-A1m -G1`
  5/5 FAIL at GC 17 — reproduces session 28+29 exactly).
- **All 5 Big2 GC 17 PROBE30 lines byte-identical (md5 match).**
  Full determinism confirmed at the allocator level too.
- **🟥 No aggregate per-GC counter discriminates Big2 GC 17 from M5
  GC 13.**  Allocator-path counters: 1.24-1.30× workload-baseline.
  Size buckets: medium/large bytes-identical, small scale uniformly.
  Combined with PROBE29's per-type histograms (also workload-scaled),
  **the bug is invisible to aggregate per-GC counters**.  The
  mishandling is a single-event at a specific address, not a
  systematic pattern that aggregates can see.
- **The "big object" path NEVER FIRES** in either run (`atbGrp=0` for
  every GC of every iter; `s11=0` always).  No closure ever needs the
  multi-block-group allocator.  **Disproves session 29 HANDOFF's #2
  hypothesis** ("PPC32 block-boundary bug in `alloc_todo_block`'s big-
  object branch").
- **Incidental PPC32 arithmetic audit** of `rts/sm/GCUtils.c`,
  `rts/sm/Evac.c`, and `includes/rts/storage/Block.h` found no
  arithmetic bugs.  `BLOCK_SIZE_W = 1024` on PPC32; `BLOCK_SIZE`
  uses `UL` suffix; `(W_)p` arithmetic in `Bdescr()` macro is
  correct on PPC32's 4-byte W_; `IS_FORWARDING_PTR` bit-0 check is
  fine on PPC32 (4-byte alignment of closure pointers).
- v0.12.0 unchanged.  Source tree clean at session end.  Stage2 on
  pmacg5 rebuilt + redeployed to match v0.12.0.  Debug-RTS-linked
  `/opt/ghc-stage2/bin/ghc-real-debug` left in place for session 31's
  potential use of `-Dg` / `-Db` / `-DZ`.  No commits to the GHC
  tree this session.

HANDOFF for session 31: see [`HANDOFF.md`](HANDOFF.md).  Pivot:
aggregate counters are exhausted; the next probes need to track
*individual events*.  Top of queue: per-iteration logging of which
ROOT-WALKER returns which addresses to `evacuate`, comparing the
address stream from a passing GC to a failing GC.  Alternative
quick wins: filename 1-byte bisect; `+RTS -Dg` GC trace on
`ghc-real-debug`.

## What we did, in order

### Step 1 — verified -DS still doesn't fire on Big2

Session 19 already proved `-DS` is silent on the M5.hs reproducer
(at default `-A`, panic `$trModule2_ruq`).  Re-verified on
sessions 28-29's Big2.hs `-A1m -G1` reproducer (`refineFromInScope`
panic).  Same outcome: 15-line output, zero sanity-check / barf /
inconsistent / invariant / assert messages.  Heap is consistent
post-GC.

`-DZ` (zero freed memory) also tested.  Same panic, same InScope
set, same missing `$dNum_a1kO`.  Lost data is reused-by-fresh-
allocation, not stale.

### Step 2 — designed + implemented PROBE30

10 allocator-state counters + a 12-bucket size histogram.  See
[findings.md](findings.md) for the full table.  Patch lives at
[`probe30-rts.patch`](probe30-rts.patch).

### Step 3 — rebuild + deploy

```
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh >/dev/null
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a
# 4.84 s
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Stage2 smoke-test confirmed PROBE30 lines in output, sane numbers.

### Step 4 — probe matrix

[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh):

```
=== M5.hs   iters=5 flags='+RTS -A1m -G1 -RTS' ===
  iter01..05 rc=0 gcs=13 : OK         pass=5 fail=0

=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===
  iter01..05 rc=1 gcs=17 : panic      pass=0 fail=5
```

Matches session 28+29.

### Step 5 — PROBE30 analysis

Byte-identical lines across all 5 iters (md5).  Allocator-path
counters scale 1.24-1.30× over M5 (workload baseline = 1.27×).
Size buckets s6-s10 exactly equal between M5 and Big2 GCs.  Big-
object path (`atbGrp`, `s11`) never fires.  **No counter is
uniquely fired at Big2 GC 17.**

Combined with PROBE29's per-closure-type result, this rules out all
aggregate-counter-visible bug classes.

### Step 6 — revert + clean redeploy

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

Smoke test: Big2 -A1m -G1 panics 3/3 with `refineFromInScope`, zero
PROBE lines in output — clean v0.12.0-equivalent stage2 confirmed.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with the `+RTS -A1G` wrapper.
- **No GHC-tree source edits committed this session.**  Probe lives
  only as the patch in this session dir.
- **Stage2 ghc on pmacg5 is the clean rebuild after probe revert.**
- **Debug-RTS-linked `ghc-real-debug` on pmacg5 KEPT** for session
  31.  Session 19 ritually removed it; session 30 leaves it because
  it's clearly distinct from `ghc-real` and immediately useful for
  `-Dg` / `-Db` traces in the next round.
- **Logs at** [`logs/`](logs/)

- **HANDOFF for session 31** pivots the audit strategy from aggregate
  counters to per-event traces (see [`HANDOFF.md`](HANDOFF.md)).

## Files added this session

- [`README.md`](README.md), this; [`findings.md`](findings.md);
  [`HANDOFF.md`](HANDOFF.md); [`log.md`](log.md);
  [`commits.md`](commits.md) — writeup.
- [`probe30-rts.patch`](probe30-rts.patch) — the combined PROBE28 +
  PROBE29 + PROBE30 patch over clean `rts/sm/{GC,Scav,Evac,GCUtils}.c`.
  Re-apply with `git apply` from inside `external/ghc-modern/ghc-9.2.8`.
- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) —
  M5 / Big2 × `-A1m -G1` (5 iters each), retargeted to
  `logs/`.
