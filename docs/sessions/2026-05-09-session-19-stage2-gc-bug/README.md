# Session 19 — stage2 GC bug investigation, round 1

**Dates:** 2026-05-09 → 2026-05-10 (continued from session 18 close).
**Status on arrival:** v0.12.0 just shipped — LLVM-7 → LLVM-8 swap
landed clean.  Stage2 native ghc on Tiger still ships
`scripts/ghc-stage2-wrapper.sh` which appends `+RTS -A1G -RTS` to
work around an unfixed RTS GC bug that corrupts the typechecker's
`Bag`-based binding store.

**Goal (per
[session 18 HANDOFF.md](../2026-05-09-session-18-llvm8-toolchain-swap/HANDOFF.md)):**
fix the bug, or pin down the proximate cause.

**Status on exit:** root cause **not yet found**, but the search
space is now much smaller than session 17 left it.  Three big
hypotheses are ruled out; one new strong angle ("missed root that's
*not* a CAF") is teed up for session 20.  Stage2 still ships with
the `-A1G` workaround.  No regressions to v0.12.0 — baseline test
battery green at start and end of session.

## What we did, in order

### Step 1 — exercise stage2 with the debug RTS

Wrote [`scripts/exp-deploy-stage2-debug.sh`](../../../scripts/exp-deploy-stage2-debug.sh)
to cross-build a `ghc-stage2-debug` binary (`ghc -debug …`) linked
against `libHSrts-1.0.2_debug.a` and deploy it as
`/opt/ghc-stage2/bin/ghc-real-debug` on pmacg5.

Wrote [`scripts/exp-stage2-debug-rts-probe.sh`](../../../scripts/exp-stage2-debug-rts-probe.sh)
to compile `M5.hs` under 8 different RTS-flag combinations and
capture stderr + the resulting `M5.o`.  Logs in
[`logs/probe-*.log`](logs/).

Detail: [step1-debug-rts-findings.md](step1-debug-rts-findings.md).

Headline:

- **`+RTS -DS` (sanity check after every GC) fires no assertions.**
  The heap is internally consistent; the bug is not in evac/scav
  bookkeeping.
- **`+RTS -G1` (single-generation GC) still fires the bug**, so the
  bug is not specifically in gen0→gen1 promotion.
- **`+RTS -DZ` (zero on free) doesn't change the symptom**, so the
  data loss happens at GC, not via use of freed memory.
- The bug is **non-deterministic** at the file-level (4/5 runs
  produce empty `.o`, 1/5 produces partial; same binary, same
  flags), but **deterministic** under `-DS` (5/5 panic with
  `variable not found $trModule2_ruq`).
- A small handoff fix: the session-18 HANDOFF said `+RTS -DC -RTS`
  for sanity check; the actual flag is `-DS` (`-DC` is "compact"
  debug).

### Step 2 — diff PPC-relevant RTS code 9.2.8 vs 8.6.5

Detail: [step2-rts-diff-notes.md](step2-rts-diff-notes.md).

- Examined `includes/stg/SMP.h`: 9.2.8 introduced 301 call sites
  using `RELAXED_LOAD/RELEASE_STORE/ACQUIRE_LOAD/SEQ_CST_*` etc.
  over `__atomic_*` C11 builtins.  But in the **non-threaded
  build** (which our stage2 uses — `Support SMP=NO`, no `-threaded`
  link), these all expand to **plain `*ptr` reads/writes with no
  fences and no atomics**.  **The "missing PPC memory fence"
  hypothesis is dead under our build configuration.**
- `large_alloc_lim` 32-bit overflow ruled out (1 MiB at default,
  256 MiB at `-A1G`, both well within `W_`'s 4 GiB).
- Non-moving GC code is dead (default `useNonmoving=false`, all
  paths guarded).
- `markCAFs` end-of-list test changed (`c != END_OF_CAF_LIST` →
  `(c|3) != END_OF_CAF_LIST`); functionally equivalent but worth
  instrumenting (became Step 3).

### Step 3 — instrument markCAFs to test CAF-list-truncation

Detail: [step3-probe19-findings.md](step3-probe19-findings.md).

Patch: [`probe-markCAFs-count.patch`](probe-markCAFs-count.patch).

Added a fprintf in `rts/sm/GCAux.c::markCAFs` to log per-GC CAF
counts.  Rebuilt RTS only (~3 sec hadrian incremental + ~10 min
ppc link).  Ran the M5.hs probe 7 times.

**Result: CAF count is monotonically non-decreasing in every run
(starts at 90, ends ~3450), and the trace is bit-for-bit identical
across iterations of the same flag combo.**  CAFs are not being
lost.  **The CAF-list hypothesis is also ruled out.**

A new and strong angle emerges from this data: same flags →
identical 25-GC sequence → different M5.o output across runs
implies the corruption is *downstream of* GC-tracked state.  The
GC correctly evacuates and preserves all heap objects.  Some
non-heap state (a saved register, a stack slot, an `StgRegTable`
field) holds a stale pointer that *was* valid before GC and
isn't anymore.

The PROBE19 instrumentation has been reverted; RTS rebuilt clean;
the probed binary on pmacg5 has been removed.  Source tree is
back to the v0.12.0 baseline.

## Net effect on the search space

Hypotheses ruled OUT this session:

1. ~~Missing PPC memory fences in 9.2.8's atomic-builtin migration.~~
2. ~~`large_alloc_lim` 32-bit overflow.~~
3. ~~Non-moving GC code interfering with our moving-GC path.~~
4. ~~`markCAFs` truncating the CAF list.~~
5. ~~Bug specifically in gen0→gen1 promotion.~~
6. ~~Bug in heap bookkeeping (sanity check passes).~~

Hypotheses NEW or escalated:

- **Saved register state across GC.**  In a non-threaded build, the
  `StgRegTable` (in `Capability->r`) holds the mutator's logical
  registers.  If a register field is at the wrong offset on PPC32,
  pointers in it go stale across GC.  Bumped to top spot.
- **TSO stack walk during GC.**  If the stack walker misses a slot
  (wrong info table interpretation, wrong frame size), the slot's
  pointer goes stale.
- **`mut_list` scavenging changes.**  Less likely (`-G1` doesn't
  scavenge mut_list and the bug still fires) but non-zero.

## Status on exit

- **v0.12.0 release stays unchanged.**  Stage2 still works with
  the `+RTS -A1G` workaround, baseline test battery green
  (30 PASS / 4 expected design-diffs).
- **Instrumentation patch + probe scripts committed** so session
  20 can pick up cold and immediately re-probe new RTS hot spots.
- **Three rebuild + deploy cycles** completed (15-20 min each)
  — confirmed the loop is workable for printf-bisection.
- **HANDOFF.md** for session 20 points at the saved-register and
  stack-walk hypotheses, with concrete probe ideas.
