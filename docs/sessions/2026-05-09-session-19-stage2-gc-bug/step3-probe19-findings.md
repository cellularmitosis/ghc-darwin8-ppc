# Step 3 — PROBE19 markCAFs instrumentation result

## What we did

1. Edited `rts/sm/GCAux.c::markCAFs` to fprintf a per-GC summary
   line:

   ```
   PROBE19 markCAFs gc_no=N dyn=K rev=L dyn_head=0x... rev_head=0x...
   ```

   (Patch archived at [`probe-markCAFs-count.patch`](probe-markCAFs-count.patch).
   Live edit in `external/ghc-modern/ghc-9.2.8/rts/sm/GCAux.c`,
   gitignored.  Revert before any release.)

2. Rebuilt `libHSrts-1.0.2_debug.a` (~3 sec hadrian, only GCAux
   recompiled).
3. Re-cross-built and redeployed `ghc-real-debug` on pmacg5.
4. Ran `M5.hs` compiles:
   - 3× `+RTS -A1m -RTS` (vanilla, non-deterministic empty `.o`)
   - 3× `+RTS -A1m -DS -RTS` (sanity, deterministic panic)
   - 1× `+RTS -A1G -RTS` (control: working case, 1 GC)

## The data

Per-iteration CAF counts (one number per GC):

| Variant         | GC sequence (`dyn` count per GC) |
|-----------------|---|
| `-A1m` iter1    | 90 616 635 636 636 1343 1761 1761 1764 2681 2997 3030 3030 3059 3067 3067 3070 3105 3105 3105 3105 3105 3277 3401 3418 |
| `-A1m` iter2    | (identical to iter1) |
| `-A1m` iter3    | (identical to iter1) |
| `-A1m -DS` iter1 | 90 616 635 636 636 1343 1761 1761 1764 2681 2997 3030 3030 3059 3067 3067 3070 3105 3105 3105 3105 3105 3223 3463 |
| `-A1m -DS` iter2 | (identical to -DS iter1) |
| `-A1m -DS` iter3 | (identical to -DS iter1) |
| `-A1G` (1 GC)   | 3550 |

`rev` is always 0 (we don't use the dynamic linker's revertible
CAF mechanism).

## Findings

### 1. CAF traversal is correct — count is monotonically non-decreasing

In every run, the CAF count starts at 90 (just-after-`hs_init`)
and grows through about 3450-3550 by the end of compilation.  At
no point does the count *drop* between GCs.  When new CAFs are
entered, they show up at the next GC and stay.

If the markCAFs walk were terminating early (the suspected
"`(c|3)==3` end-of-list" hypothesis), the count would be variably
truncated across runs.  It isn't.

**The CAF-list hypothesis is ruled out.**

### 2. The trace is deterministic — same trace across runs

`-A1m` × 3 runs → identical 25-GC sequence ending at 3418.
`-A1m -DS` × 3 runs → identical 24-GC sequence ending at 3463.

So the *GC's view* of program state is deterministic.  But the
program's output (M5.o symbols) is non-deterministic.  This is
a striking inversion — same GC behavior, different outputs —
which means the corruption isn't *caused by* GC variance; the
mutator's downstream interpretation is what differs.

This adds a new constraint: the bug is in something **downstream
of** the GC-tracked state.  Like, the GC correctly evacuates and
preserves all heap objects, but some non-heap state (a register?
the StgRegTable?  a stack slot saved across GC?) holds a stale
pointer that *was* valid before GC and isn't anymore.

### 3. -A1G's single GC has 3550 CAFs and works fine

In the working `-A1G` case, ONE GC fires (because the giant nursery
suppresses further collections), and it walks 3550 CAFs in one
pass.  The compile succeeds.

In the failing `-A1m` case, 25 GCs fire, each walking the
current CAF count (the list grows over time as more code is
entered).  Each individual walk is correct.

## What this rules out (added to step1-debug-rts-findings.md):

7. **CAF-list traversal**: ruled out.  CAFs aren't being lost.

## What's still in play

The non-determinism in M5.o output, combined with the
deterministic GC trace, points at:

1. **Stack slots saved across GC** — when a GC fires, the
   mutator's stack slots are saved/restored.  If a saved
   slot's pointer isn't updated (because the slot was missed
   in the stack walk), restoring it gives a stale pointer.
2. **Saved register state** — in a non-threaded build, the
   single `StgRegTable` holds the mutator's logical registers
   (R1-R10, F1-F4, D1-D2).  Pointers in registers must be
   updated by the GC.  If a register isn't being walked correctly
   on PPC32 (e.g., a wrong offset into `Capability->r`), pointers
   in that register go stale.
3. **TSO stack walk** — the running thread's stack is walked by
   `scavenge_stack`.  If a stack slot's info table isn't
   recognized, that slot's children might not be evacuated.
4. **`Capability->r.rCurrentTSO` and friends** — fields of the
   StgRegTable that hold pointers.  Each one must be updated by
   GC.  PPC32's `Capability` layout might differ subtly from x86_64's
   in a way that causes one of those fields to be at the wrong
   offset.

The most actionable next probe: instrument
`scavenge_capability_mut_lists` and `mark_root` (the entry points
that walk the per-cap roots) to log:
  (a) `cap->r.rCurrentTSO` address (the running thread).
  (b) the StgRegTable register values that hold pointers
      (rCurrentNursery, rCurrentAlloc).
At each GC.  If those values change between GCs in unexpected
ways (e.g., `rCurrentNursery` gets stuck at an old freed-block
address), that's the smoking gun.

Or: instrument `evacuate` to log when it sees a closure whose
*payload* points to gen0 memory after evacuation.  That'd catch
a "this closure is in to-space but its children weren't
forwarded" scenario.

## Where the rebuild artefacts live

- Patched source: `external/ghc-modern/ghc-9.2.8/rts/sm/GCAux.c`
  (gitignored — wipe with `git -C ... checkout -- rts/sm/GCAux.c`
  in the gitfor that subtree if needed; or apply the inverse of
  `probe-markCAFs-count.patch`).
- Rebuilt RTS: `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a` and `libHSrts-1.0.2.a`.
- Deployed binary: `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug`
  (193 MB, contains the PROBE19 string).
- Probe runner: [`scripts/exp-stage2-probe19.sh`](../../../scripts/exp-stage2-probe19.sh).
- Logs: [`logs/probe19-*.log`](logs/).
