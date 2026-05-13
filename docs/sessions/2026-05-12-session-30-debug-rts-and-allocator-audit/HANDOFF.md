# Handoff from session 30 → session 31

**For:** the next claude session.
**From:** session 30 (debug-RTS revisit + PROBE30 allocator-state probe;
**aggregate counters can't see the bug**; **big-object path ruled out
by data**; 2026-05-12).
**Recommended pickup:** pivot from aggregate counters to **per-event
tracing of root-walkers**.  Run PROBE31 = log every address handed to
`evacuate` from each root source (CAFs, mut_lists, static_objects,
stack walker, weak ptrs, stable ptrs).  Diff Big2 GC 17 vs M5 GC 13's
address stream and look for what's in M5's stream but missing from
Big2's, OR present in both streams but pointing to different memory.

## TL;DR (mandatory read)

- **`+RTS -DS` doesn't catch the bug.**  Replicates session 19's
  result for Big2 / `refineFromInScope`.  Heap is internally
  consistent post-every-GC.  The bug is a **missed GC root**.
- **`+RTS -DZ` doesn't change the panic.**  Lost data is reused-by-
  fresh-allocation, not stale.  Confirms missed-root.
- **PROBE30** instrumented every allocator path in `rts/sm/Evac.c`
  and `rts/sm/GCUtils.c` + a size histogram.  ALL counters scale
  1.24-1.30× with workload between M5 GC 13 (PASS) and Big2 GC 17
  (FAIL).  Medium/large size buckets are exactly equal.  **No
  allocator state is uniquely fired at Big2 GC 17.**
- 🟥 **The big-object path NEVER fires.**  `atbGrp=0` everywhere
  in every iter of both runs; `s11=0` everywhere.  **Disproves
  session-29 HANDOFF's "PPC32 block-boundary big-object bug"
  hypothesis.**  Closures never exceed BLOCK_SIZE_W = 1024 words.
- 🟥 **No aggregate per-GC counter discriminates Big2 GC 17.**
  Per-closure-type (PROBE29), per-allocator-path (PROBE30), per-
  size-class (PROBE30 size histogram) — all match the workload-
  scaled baseline.  The bug is a single-event mishandling at one
  specific address, invisible to aggregate counters.
- v0.12.0 ships unchanged.  Source tree clean at session end.
  Stage2 on pmacg5 is the clean redeploy after probe revert.
  Debug-RTS-linked `/opt/ghc-stage2/bin/ghc-real-debug` is **kept
  on pmacg5** for session 31's potential use of `-Dg` / `-Db`.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — narrative of session 30.
3. [`findings.md`](findings.md) — full PROBE30 data + ruleouts +
   PPC32 arithmetic audit.
4. [`log.md`](log.md) — real-time work log.
5. [`probe30-rts.patch`](probe30-rts.patch) — the probe diff, ready
   to re-apply.
6. (Reference) Session 29 [`HANDOFF.md`](../2026-05-12-session-29-closure-type-histogram/HANDOFF.md)
   — its #4 hypothesis (per-size histogram) is now ruled out; its
   #2 (big-object path) is also ruled out.  Other priorities
   (filename bisect, sanity check, stack walker audit) still hold.
7. (Reference) Session 19 [`step1-debug-rts-findings.md`](../2026-05-09-session-19-stage2-gc-bug/step1-debug-rts-findings.md)
   — established the "missed-root" framing.  Confirmed again today
   for the Big2 reproducer.

## What to NOT redo

- **Don't try `-DS`, `-DZ`, or any other sanity-check variant.**
  Heap is consistent.  Data is reused, not stale.
- **Don't probe the `alloc_in_moving_heap` / `todo_block_full` /
  `alloc_todo_block` path for aggregate anomalies.**  PROBE30 has
  exhausted that direction.  Counters match workload-baseline.
- **Don't probe the big-object path (`atbGrp`, `s11`, multi-block
  group).**  PROBE30 confirmed it never fires.
- **Don't redo per-closure-type histograms** — PROBE29 already did,
  and the filename experiment disproved per-type as the trigger.
- **Don't redo `mut_list` / `static_objects` / SRT** — sessions
  27-28 ruled them out.
- **Don't redo stack-frame BITMAP codegen audits** — sessions
  20-24 ruled them out.  But — *do* feel free to instrument the
  stack-WALK (the loop itself), since that hasn't been done.
- **Don't rebuild the world** for an RTS-only change.  ~5 s with
  `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`
  (+ `_debug.a` if needed).
- **Don't remove `/opt/ghc-stage2/bin/ghc-real-debug`** unless you
  decide you want a clean slate.  It's useful for `+RTS -Dg/-Db`
  traces with zero rebuild cost.

## What to try next, in priority order

### Top: PROBE31 — per-event address-stream trace of root walkers

The session-30 ruleouts have narrowed the bug to "a single pointer
that should be a GC root isn't being walked, in a way that depends
on exact heap layout."  Aggregate counters can't see this.

Plan: extend PROBE28+29+30 with **per-iteration logging**:

1. **`markCAFs`** (rts/sm/GCAux.c) — currently logs CAF count per
   GC (session 19 PROBE19).  Extend: log the ADDRESS of every CAF
   walked.  ~3000 lines per GC, ~50000 across the run.
2. **`scavenge_capability_mut_lists`** (rts/sm/Scav.c) — log
   every closure pointer fed to `evacuate` from per-cap mut_lists.
3. **`scavenge_static`** (rts/sm/Scav.c) — log each static object
   visited.
4. **`scavenge_stack`** (rts/sm/Scav.c) — log each TSO's stack
   walk: TSO address, frame info-table, frame size, payload
   pointers fed to evacuate.
5. **`markWeakPtrList`** (rts/sm/MarkWeak.c) — log each weak ptr.
6. **`markScheduler`** / **`markStableTables`** (rts/sm/Sanity.c,
   rts/StableName.c) — log stable ptr / TSO table entries.

Run M5 -A1m -G1 (PASS) and Big2 -A1m -G1 (FAIL).  Diff the address
streams.

What we expect:
- Most addresses will be different (different allocations).
- BUT: the COUNT of addresses per root-source should be very close
  (PROBE28+29+30 already established this aggregately).
- IF Big2 GC 17 visits one FEWER address from one root-source
  compared to a similar passing GC, that's the smoking gun.
- IF Big2 GC 17 has an address that maps to a different bdescr/
  flag/type than M5's corresponding GC's nearest analog, that's
  also a smoking gun.

This is voluminous instrumentation.  Output will be 10-50 MB of
trace.  Diff-tooling will need to be careful (address values
shift, but counts/types/flags should match).

Cost: ~2 h to write probe + tooling, then ~30 min/run.

### Second: filename 1-byte bisect

Mechanical, cheap, no probe required.

Session 29 found: `A.hs` PASS, `AA.hs` FAIL; `B.hs`/`BB.hs` PASS,
`BBB.hs` FAIL.  Different content under those filenames.

The richer experiment: take the EXACT Big2.hs content, vary just
the filename across an alphabet of 1- and 2-char names, find a
(name1, name2) pair differing in 1 byte that flips PASS↔FAIL.

Cost: ~30 min for a thorough sweep.  Outcome: confirms the heap-
layout-sensitivity bound and may suggest which structure carries
filename bytes through to GC 17 allocations.

Run on pmacg5 directly — no rebuild needed, just shell loops.

### Third: `+RTS -Dg` GC trace on Big2

`ghc-real-debug` is already deployed on pmacg5.  `-Dg` enables the
GC trace via `debugTrace(DEBUG_gc, ...)`.  Voluminous (~ MB per GC)
but no rebuild needed.  Look for:
- `push todo block <addr> ...` lines
- `increasing limit for <addr> to <addr>` lines
- `alloc new todo block <addr> for gen N` lines

These map to PROBE30's counters but with addresses + per-event
data.  May reveal whether a specific block-push-pop sequence at
GC 17 visits a problematic address.

Cost: ~5 min per run.  Analysis 1-2 h.

### Fourth: stack-walker step trace

Sessions 20-24 examined stack-frame BITMAPS and concluded they're
correct for the cases tested.  But the stack-WALK loop in
`scavenge_stack` (rts/sm/Scav.c) processes frames one at a time
using info-table dispatch.  Per-frame instrumentation could reveal:
- A frame whose info-table type is misclassified on PPC32.
- A stack pointer that walks past the end (Sp/SpLim mismatch).
- A frame size computation that's off by one.

Cost: ~1 h to probe; voluminous output.

### Fifth: StgRegTable / saved register state probe

Session 19's #1 candidate.  Probe `Capability->r.rCurrentNursery`,
`Capability->r.rCurrentAlloc`, `cap->r.rCurrentTSO` before/after
every GC.  If any field shifts unexpectedly, the StgRegTable layout
on PPC32 is at fault.

Cost: ~1 h.  Lower prior than (1) but mechanical.

## Mechanics — reproducing session 30 results

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 0. Optional baseline (skip if just continuing PROBE work)
bash tests/run-tests.sh    # ~10 min; 30 PASS / 4 design diffs

# 1. Re-apply the probe (combined PROBE28+29+30)
cd external/ghc-modern/ghc-9.2.8
git apply ../../docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch

# 2. Rebuild RTS + deploy stage2
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# 3. Run the matrix (logs at log/session30/)
bash docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/scripts/run-probe-matrix.sh \
    pmacg5 5

# 4. Inspect specific GCs
grep "^PROBE30 gc=13 " log/session30/M5-a1m-g1.iter1.log
grep "^PROBE30 gc=17 " log/session30/Big2-a1m-g1.iter1.log

# 5. Determinism check
for f in log/session30/Big2-a1m-g1.iter*.log; do
  grep "^PROBE30 gc=17 " "$f" | md5
done
# Expected: all 5 iters produce md5 f859e676adef6e1a0dd06c44566ae315

# 6. Sanity-check rerun (no probe needed)
ssh pmacg5 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real-debug -c /tmp/Big2.hs +RTS -A1m -G1 -DS -RTS 2>&1' \
    | head -20
# Expected: 15-line panic output, no sanity messages

# 7. When done — REVERT before any user-facing run
cd external/ghc-modern/ghc-9.2.8
git checkout -- rts/sm/GC.c rts/sm/Scav.c rts/sm/Evac.c rts/sm/GCUtils.c
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

**Expected:** with probe, M5 `-A1m -G1` passes 5/5 (13 GCs each),
Big2 `-A1m -G1` panics 5/5 at GC 17 with `refineFromInScope`.
PROBE30 lines are byte-identical across all 5 iters of each input.
Big2 GC 17 PROBE30 counters scale 1.24-1.30× over M5 GC 13's.
`atbGrp=0` and `s11=0` for every GC.

## Hosts (unchanged)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — production stage2 (clean).
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked, kept
    for session 31.
- **imacg3**: smaller-RAM PPC G3 (not used this session).
- **indium**: don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/` — **rts/sm/** is clean (the
  PROBE30 patch was applied, used, then `git checkout -- ` reverted).
- `pmacg5:/opt/ghc-stage2/bin/ghc-real` — clean rebuild + redeploy at
  session-30 end, matches v0.12.0.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked
  stage2 from this session.  KEPT (not removed at session end).
- New session dir: `docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/`
  + run logs gitignored at `log/session30/`.

## Time estimate for session 31

- Setup + read handoff + verify session-30 numbers (re-apply
  probe + rebuild + 5×2 = 10 runs): 30–45 min.
- Filename 1-byte bisect (mechanical, may be enlightening): 30 min.
- `+RTS -Dg` GC trace on Big2 + inspect for anomalies: 1-2 h.
- PROBE31 design + implement + run (per-event root-walker
  address-stream trace): 3-5 h.
- Diff-analysis of PROBE31 streams: 2-3 h.

Realistic: 1 long session (~6-8 h) for PROBE31 implementation +
first-pass analysis, then 1 short session to either pinpoint the
missed-root source or pivot strategy.

## Paste-into-fresh-session prompt

```
Context: session 30 of the GHC darwin8-ppc project just wrapped up.
Session 30 (a) rebuilt stage2 with debug-RTS and confirmed -DS does
NOT catch the Big2 -A1m -G1 bug (heap is consistent after every
GC); (b) confirmed -DZ doesn't change the panic (lost data is
reused-by-fresh-allocation, not stale); (c) implemented PROBE30
(allocator-state counters + per-evac size histogram) covering
alloc_in_moving_heap, todo_block_full, alloc_todo_block, and
evacuate_large; (d) found that NO aggregate per-GC counter
discriminates Big2's failing GC 17 from M5's passing GC 13 — all
counters scale 1.24-1.30x with workload, big-object path never
fires (atbGrp=0 always), no size class is uniquely Big2-GC-17-
specific.

This DISPROVES the session-29 HANDOFF's hypothesis that the bug
lives in PPC32 block-boundary handling for big objects.  More
importantly, combined with PROBE29's per-closure-type histograms
(also workload-scaled), it establishes that AGGREGATE COUNTERS
CANNOT SEE THIS BUG.  The mishandling is a single-event at one
specific address, not a systematic pattern.

The bug is a missed GC root (per session 19's framing, confirmed
again on the new reproducer).  Aggregate root-walker counters
(CAF count, mut_list count, static-chain count) all match between
passing and failing GCs.  But ONE pointer that should be a root
isn't being walked.

The audit direction pivots to: PER-EVENT address-stream tracing
of every root-walker (markCAFs, scavenge_capability_mut_lists,
scavenge_static, scavenge_stack, markWeakPtrList, stable ptr table,
etc.).  Diff the address stream from a passing GC vs failing GC
and look for a missing address or a misclassified one.

Quick wins also queued:
- Filename 1-byte bisect (mechanical, ~30 min).
- +RTS -Dg GC trace on the already-deployed ghc-real-debug (no
  rebuild, ~5 min/run).
- Stack-walker per-frame trace (sessions 20-24 examined BITMAPS;
  WALK loop not probed).

Read in order:
1. docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md
2. docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/README.md
3. docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/findings.md
4. docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/log.md
5. (reference) docs/sessions/2026-05-09-session-19-stage2-gc-bug/step1-debug-rts-findings.md
   — established the missed-root framing (PROBE19 ruled out CAF list).

Top priority: design PROBE31 — per-iteration logging of which
address each root-walker hands to evacuate().  Run M5 -A1m -G1
(PASS) and Big2 -A1m -G1 (FAIL); diff the streams; look for an
address present in M5 but missing from Big2, or vice-versa.

Don't redo -DS / -DZ probes (session 19 + session 30 already did,
twice).  Don't redo allocator-path or size-class aggregate counters
(PROBE30 exhausted).  Don't redo per-closure-type histograms
(PROBE29 exhausted).  Don't redo big-object path investigation
(PROBE30 proved it never fires).

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's -A1G wrapper.
`/opt/ghc-stage2/bin/ghc-real-debug` is kept on pmacg5 — feel free
to use +RTS -Dg/-Db with it.  ALWAYS revert the probe + rebuild +
redeploy clean stage2 at session end.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md`](docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md).

When session 31 ends, write the next handoff at:
`docs/sessions/<DATE>-session-31-<slug>/HANDOFF.md`.
