# Handoff from session 19 → session 20

**For:** the next claude session.
**From:** session 19 (stage2 GC bug, round 1; 2026-05-09 → 2026-05-10).
**Recommended pickup:** continue the GC-bug investigation, focused
on the new top suspect (saved register state / TSO stack walk).

## TL;DR

- v0.12.0 still ships unchanged.  Stage2 still uses `-A1G` workaround.
- Three big hypotheses ruled out this session: SMP atomics, large_alloc_lim
  overflow, CAF-list truncation.  See [`README.md`](README.md) and
  [`step1`](step1-debug-rts-findings.md), [`step2`](step2-rts-diff-notes.md),
  [`step3`](step3-probe19-findings.md) findings.
- Most surprising new datapoint: **with PROBE19 instrumentation,
  the per-GC CAF count sequence is bit-for-bit identical across
  iterations of the same flag combo, but the M5.o output is
  non-deterministic.**  GC's view of state is deterministic;
  corruption is downstream.  Strong signal that the bug is in
  non-heap state — saved registers, stack slots, or
  `StgRegTable` field interpretation on PPC32.
- The session-19 reproduction loop (debug-RTS rebuild → cross-build
  stage2 → ppc-side link → deploy → probe) takes ~15-20 min per
  RTS edit.  Workable for printf-bisection iterations.

## Read in order

1. **This file** (the handoff).
2. [`README.md`](README.md) — what session 19 actually did.
3. [`step3-probe19-findings.md`](step3-probe19-findings.md) —
   the per-GC CAF data and the "non-heap state" deduction.
4. [`step1-debug-rts-findings.md`](step1-debug-rts-findings.md) —
   the rule-outs (sanity passes, `-G1` doesn't help, etc.).
5. [`step2-rts-diff-notes.md`](step2-rts-diff-notes.md) — RTS diff
   findings.
6. (Reference) [`../2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md`](../2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)
   — original bug write-up + threshold table.

## What to NOT redo

- Don't re-probe sanity (`+RTS -DS`) thinking it'll catch the bug.
  It catches nothing.  Heap is consistent.
- Don't pursue the "memory fences on PPC" hypothesis.  Non-threaded
  RTS uses no atomics on the path that matters.
- Don't pursue `large_alloc_lim` overflow.  Doesn't overflow.
- Don't pursue CAF-list truncation.  PROBE19 disproves it.
- Don't try `-G1` thinking it'll bypass the bug.  Same bug, just
  one fewer generation to confuse you.
- Don't try `-O0`, `-fllvm` toggling, or LLVM toolchain changes.
  Sessions 14, 17, 18 already covered.

## What to try next, in priority order

### Top candidate: PPC32 `StgRegTable` field offset mismatch

In a non-threaded RTS, the mutator's logical registers live in
`Capability->r` of type `StgRegTable` (defined in
`includes/rts/storage/TSO.h` and friends).  Each "logical
register" (R1-R10, F1-F4, D1-D2, Sp, SpLim, ...) is a struct field.

The miniinterpreter (`USE_MINIINTERPRETER`, which is what we
use — see settings file) accesses these fields by computed offsets
in `Cmm.h` and friends.  If the offset for, say, `rCurrentNursery`
or `rCurrentAlloc` is wrong on PPC32 (because of struct-padding
differences vs x86_64), the GC would read the wrong address as
"the running nursery block", and never update the *real* register.

**Probe**: instrument `gc_thread::evac_gen_no` initialization or
the per-cap mark_root entry point to dump
`Capability->r.rCurrentNursery`, `cap->r.rCurrentAlloc`, and the
addresses of those struct fields, before and after each GC.

Hot files:
- `includes/rts/storage/TSO.h` and `Closures.h`
- `includes/Cmm.h` (`stg/MachRegs.h`)
- `rts/sm/Storage.c` (the `updateNurseriesStats` path that
  caused the LLVM-8 attempt-2 SIGBUS — same data path)
- Compare struct layouts via `gdb` on stage1 binary or via
  `pahole` on the unreg-C output.

### Second candidate: TSO stack walk on PPC32

`scavenge_stack` walks one TSO's stack frames, identifying each
by its info table.  PPC32's calling convention is different from
x86_64; if any of the stack-frame info tables are computed wrong
(e.g., a frame size in bytes vs words confusion), a frame could
be misread, its slots not evacuated.

**Probe**: instrument `scavenge_stack` to log the info-table type
of each frame it processes, plus the frame size.  Compare to a
non-PPC build's trace.

Hot files:
- `rts/sm/Scav.c::scavenge_stack`
- `includes/rts/storage/Closures.h` (frame layouts)
- `rts/StgMiscClosures.cmm` (info table definitions)

### Third candidate: instrument `evacuate` to detect post-evac stale pointers

A stronger version of the sanity check: after `evacuate(p)` returns,
verify `*p` no longer points into gen0 nursery memory.  If it does,
that's a definite "this slot was missed" diagnostic.

**Probe**: in `rts/sm/Evac.c::evacuate`, after the early-return cases
(forwarding pointer, BF_EVACUATED), assert that the to-space pointer
isn't in gen0 nursery space.  If the pointer IS still in nursery,
print the offset and closure type.

### Long-shot but cheap: instrument `IF_DEBUG(sanity, …)` macros

There are many `IF_DEBUG(sanity, ...)` calls scattered through the
RTS that the existing sanity check skips.  Walk these and see if
any can be tightened to actually catch the lost-binding scenario.

## Mechanics — how the dev loop works

This was hard-won during session 19; it's worth front-loading.

### Edit RTS source

Live tree:
```
external/ghc-modern/ghc-9.2.8/rts/sm/{GC.c,GCAux.c,Scav.c,Evac.c,Storage.c,Sanity.c}
external/ghc-modern/ghc-9.2.8/rts/{Capability.c,Threads.c,Schedule.c}
```

This dir is gitignored.  Reverts via `git -C external/ghc-modern
checkout -- ...` if external is its own git tree, or just a manual
edit.

### Rebuild RTS only (~3-15 sec)

```
cd external/ghc-modern/ghc-9.2.8
rm -f _build/stage1/rts/build/c/sm/<file>.* \
      _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a \
      _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
source ../../../scripts/cross-env.sh >/dev/null 2>&1
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
```

**Don't pass `--freeze1`** — that explicitly skips stage1 rebuild,
which is what you want to do.

### Cross-link + deploy debug stage2 (~15-20 min)

```
bash scripts/exp-deploy-stage2-debug.sh pmacg5
```

Slow because the stage1 ghc cross-compiles `ghc/Main.hs` (~17
sec on uranium), then `ppc-ld-tiger.sh` rsyncs all `.o`/`.a`
inputs to pmacg5 (where gcc14 lives), runs `gcc14` there to
produce the binary, and scp's it back (~10-15 min on slow link).

To avoid the cross-compile step (you only changed RTS, not
ghc), patch the script to skip the recompile and only re-link.
The link itself takes ~10 min on the G5.

### Run the probe

```
bash scripts/exp-stage2-probe19.sh pmacg5
```

Edit that script's `run_one` calls to taste.  Logs to
`logs/probe19-*.log` (rename / move directory for a new
session).

## Hosts (unchanged from session 18)

- **uranium** (this Mac): host for the cross-build.  Has the GHC
  source tree in `external/ghc-modern/ghc-9.2.8/`, hadrian, the
  cross clang-8.  Use this for all RTS edits + RTS rebuilds.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs the actual ppc
  binaries.  ssh works without a password.  This is where the bug
  fires.  Also where the ppc-side gcc14 link runs.
- **imacg3**: smaller-RAM PPC G3, available if you want to test
  under more memory pressure.
- **indium**: trimmed dev tools; **don't use for clang or hadrian
  builds** (no Xcode).

## What's clean / dirty in the source tree

- `rts/sm/GCAux.c` — reverted to baseline (PROBE19 instrumentation
  removed at session-19 close).
- `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2*.a`
  — rebuilt clean, no PROBE19.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` — **removed at
  session-19 close** to avoid confusing the next session.
  Re-create it via `bash scripts/exp-deploy-stage2-debug.sh pmacg5`
  when needed.
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — unchanged
  (production stage2 with the `-A1G` wrapper, working).

## Time estimate for session 20

- Setup + read handoff: 15 min.
- One probe iteration (edit + rebuild + deploy + probe): ~20 min.
- Probably 3-6 iterations to either find the bug or to rule out
  the StgRegTable hypothesis.

Realistic: 1 session to either confirm StgRegTable is the bug
(then session 21 to fix), or rule it out and move to TSO stack
walk.

## Paste-into-fresh-session prompt

```
Context: just finished session 19 (stage2 GC bug round 1).  Search
space is much smaller than session 17 left it: SMP atomics,
large_alloc_lim overflow, and CAF-list truncation are all ruled
out.  Sanity check passes — heap is consistent.  Bug is in non-heap
state (saved registers, stack slots, or StgRegTable interpretation
on PPC32).

Read in order:
1. docs/sessions/2026-05-09-session-19-stage2-gc-bug/HANDOFF.md
2. docs/sessions/2026-05-09-session-19-stage2-gc-bug/README.md
3. docs/sessions/2026-05-09-session-19-stage2-gc-bug/step3-probe19-findings.md

Then start with the top candidate: PPC32 StgRegTable field offset
mismatch.  Probe by instrumenting `cap->r.rCurrentNursery` /
`cap->r.rCurrentAlloc` reads pre/post-GC; if those addresses go
stale across a GC, that's the smoking gun.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's `-A1G` wrapper.

Unsupervised mode is project default.
```
