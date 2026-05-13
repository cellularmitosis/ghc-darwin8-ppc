# Handoff from session 28 → session 29

**For:** the next claude session.
**From:** session 28 (PROBE28 RTS-side discriminator; session-27's
"two distinct corruption modes" downgraded to "one bug, two victim
data structures"; mut_list and static_objects paths ruled out;
2026-05-12).
**Recommended pickup:** enhance PROBE28 with a per-closure-type
histogram and then audit `rts/sm/Evac.c` / `rts/sm/Scav.c::scavenge_block`
with PPC32 eyes.

## TL;DR (mandatory read)

- PROBE28 (slim RTS-side per-GC printf in `rts/sm/GC.c`) shows that
  the static_objects scavenge code path runs identically (~175k chain
  walks per major GC) for both M5.hs `-G1` (PASS) and Big2.hs `-G1`
  (FAIL).  **`scavenge_static` / `scavenge_thunk_srt` / `scavenge_fun_srt`
  ruled out** as the bug.
- Under `-G1`, mut_lists are unused (the older-gen scavenge loop is
  empty, mut_list[0] is always 0).  Big2.hs `-A1m -G1` panics 5/5 in
  this configuration.  **mut_list / write-barrier path ruled out**
  as the root cause (still a possible contributor under `-G2` only).
- **Under PROBE28, Big2.hs `-A1m -G1` panics with `refineFromInScope`
  (STG-time) 5/5 — NOT with session 27's "swap not in scope" TC-time
  signature.**  The probe's tiny per-GC timing perturbation is
  enough to shift which downstream data structure (Simplifier
  InScopeSet vs Typechecker TcTypeEnv) catches the corrupted closure.
  Both signatures are reads from corrupted IntMap-backed VarEnv
  structures — same root corruption, different victim.
- **Remaining suspects:** `evacuate()` / `copy_tag()` / `copy()` in
  `rts/sm/Evac.c`, `scavenge_block()` dispatch in `rts/sm/Scav.c`,
  forwarding-pointer machinery, info-table reads on PPC32 (32-bit
  big-endian).
- v0.12.0 ships unchanged.  Source tree clean.  Probe saved as a
  patch under this session dir; reverted before session end; stage2
  on pmacg5 rebuilt+redeployed clean.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — narrative of session 28.
3. [`findings.md`](findings.md) — full per-GC data + analysis.
4. [`probe28-rts-gc.patch`](probe28-rts-gc.patch) — the probe diff,
   ready to re-apply.
5. (Reference) Session 27 [`HANDOFF.md`](../2026-05-12-session-27-non-perturbing-repro/HANDOFF.md)
   — the context this session built on.
6. (Reference) Session 27 [`findings.md`](../2026-05-12-session-27-non-perturbing-repro/findings.md)
   — particularly the "Open hypotheses" section, several of which
   are now ruled out.

## What to NOT redo

- **Don't audit `rts/Updates.cmm`, `rts/PrimOps.cmm::stg_writeMutVarzh`,
  `rts/sm/Storage.c::dirty_MUT_VAR`, or `rts/sm/Scav.c::scavenge_capability_mut_lists`.**
  PROBE28 shows the mut_list path is empty when Big2.hs `-G1` panics —
  the bug doesn't need any mut_list activity to fire.  Session 27's
  HANDOFF priority-2 audit is no longer load-bearing.
- **Don't audit `scavenge_thunk_srt`, `scavenge_fun_srt`, or
  `scavenge_static`.**  PROBE28 shows the same chain length is walked
  on every GC in both M5 `-G1` (PASS) and Big2 `-G1` (FAIL).  Session
  27's HANDOFF priority-3 audit is dead.
- **Don't write more Haskell-side instrumentation.**  Even PROBE28's
  RTS-side `debugBelch` slightly perturbed timing (M5 `-A1m` dropped
  from 10/10 fail to 2/5 fail).  Haskell-side instrumentation (PROBE26
  style) is strictly worse.
- **Don't treat the TC-time "swap not in scope" signature as a
  separate bug.**  Session 27 framed it as a second corruption mode;
  PROBE28 shows it's the same bug, different victim.
- **Don't rebuild the world via `./hadrian/build` without a target.**
  The RTS rebuild for the probe takes ~3 seconds with the corrected
  Hadrian target:
  `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`
  (note: NOT the path the previous HANDOFF gave — `ghc-9.2.8/rts/...`
  doesn't parse).

## What to try next, in priority order

### Top: per-closure-type histogram probe

Extend PROBE28 to count `info->type` per GC and print a compact
histogram.  The simplest implementation: add a static `W_
probe28_type_hist[64]` indexed by `info->type` (which is an enum with
~60 values).  Increment in `scavenge_block` for each closure
processed.  Print as part of the post-GC summary line.  Reset to 0 at
the start of each GC.

Goal: identify which closure type appears in Big2's failing GC but
not in M5 `-G1`'s passing GCs.  If we find e.g. `THUNK_2_0` only
appears in Big2 — that's the suspect for an `evacuate` /
`scavenge_block` bug.

Cost: ~1 RTS rebuild + redeploy + 4 probe-matrix runs (~20 min).

Note: the histogram bump happens per closure, not per GC.  That's
millions of increments per GC — but they're just ALU ops, no I/O.
Should perturb timing far less than per-GC debugBelch already does.

Implementation skeleton (apply to `rts/sm/Scav.c::scavenge_block`):

```c
#include "GC.h"  // for probe28_type_hist (declared extern in GC.c)
...
// inside the main loop of scavenge_block, after const StgInfoTable *info = get_itbl(...);
if ((int)info->type < 64) probe28_type_hist[info->type]++;
```

And in `rts/sm/GC.c`, declare:

```c
W_ probe28_type_hist[64];  // not file-static — Scav.c needs access
```

Reset at pre-GC snapshot point.  Print in the post-GC summary line as
`type{T_N=count, ...}` (skip zero buckets for compactness).

### Second: audit `rts/sm/Evac.c::evacuate` and `copy_tag`

PPC32-specific concerns:

- **Info-pointer reads**: `evacuate` does `info = ACQUIRE_LOAD(&q->header.info)`.
  In the non-threaded RTS, `ACQUIRE_LOAD` expands to a plain load.
  On PPC32, info pointers are 32-bit; check there's no path that
  treats them as 64-bit.
- **Forwarding pointer tag**: `IS_FORWARDING_PTR(p)` tests the low
  bit of the info pointer.  `((StgWord)p) & 1`.  PPC32 ensures
  pointers are 4-byte aligned, so the low 2 bits are always clear in
  a valid pointer; setting bit 0 marks a forward.  Look at how
  `UN_FORWARDING_PTR` recovers the new address.
- **`copy_tag` and `copy`**: alloc to-space block via `alloc_for_copy`,
  then `memcpy_words` for the closure body.  `memcpy_words` is in
  `rts/sm/GCUtils.c` — a hand-rolled word-copy loop.  Read with PPC32
  alignment eyes.
- **Closure-size lookup**: `closure_sizeW(p)` reads `info->layout.payload.ptrs`
  and `nptrs`.  Check `StgInfoTable` struct layout on PPC32 (it's a
  packed struct in `includes/rts/storage/InfoTables.h`).

Concrete file list:

- `rts/sm/Evac.c` lines ~100 (`copy`), ~150 (`copy_tag`), ~250
  (`evacuate1`), ~620 (`evacuate`).
- `rts/sm/GCUtils.c::memcpy_words`.
- `includes/rts/storage/InfoTables.h::StgInfoTable`.
- `includes/rts/storage/ClosureMacros.h::closure_sizeW`.

### Third: audit `rts/sm/Scav.c::scavenge_block`

`scavenge_block` is the big switch by `info->type`.  Every closure
type has its own scavenge logic.  Risk areas:

- The pointer-advance arithmetic at end of each case — `p += sizeofW(StgFoo)`
  or `p = (StgPtr)((StgFun *)p + 1)` style.  Getting this wrong by
  one word reads the next closure's header as a pointer field of
  the current closure, which then gets scribbled by evacuate.
- The big-bitmap and small-bitmap scavenge routines: `scavenge_large_bitmap`,
  `scavenge_small_bitmap` (`rts/sm/Scav.c` lines ~80–~180).  Bitmap
  is a 32-bit pattern saying which slots are pointers.  Iterate bits,
  call `evacuate` on pointer slots.

### Fourth: bisect Big2.hs

Cheap exploratory test: strip Big2.hs progressively (remove `topK`,
remove the `where` clause, remove the `Data.Map.Strict` import) and
see which removal turns 5/5 fail → 0/5 pass.  The first one that
clears the bug names the offending closure shape.  Smaller heap →
fewer closures of the suspect type.  Cheaper than the probe enhancement
if you want a quick hypothesis, but less informative.

## Mechanics — reproducing session 28 results

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 0. Optional: baseline still green?
bash tests/run-tests.sh    # ~10 min; expect 30 PASS / 4 design diffs

# 1. Re-apply the probe
cd external/ghc-modern/ghc-9.2.8
git apply ../../docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch

# 2. Rebuild + deploy
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# 3. Run the matrix (writes logs to logs/)
bash docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/run-probe-matrix.sh \
    pmacg5 5
bash docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/big2-a1m-test.sh \
    pmacg5 10

# 4. When done — REVERT before any user-facing run
cd external/ghc-modern/ghc-9.2.8
git checkout rts/sm/GC.c
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

**Expected:** with probe, the matrix produces (5-iter samples):
- M5 `-A1m`: pass=3 fail=2
- M5 `-A1m -G1`: pass=5 fail=0
- Big2 `-A1m -G1`: pass=0 fail=5 (5× `refineFromInScope` at GC 17)
- Big2 `-A1G`: pass=5 fail=0
- Big2 `-A1m` (10 iter): pass=5 fail=5 (5× "swap not in scope" at GC 41)

## Hosts (unchanged)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/` — clean.  Probe reverted before
  session end.
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — clean rebuild+redeploy
  at session-28 end, matches v0.12.0.
- New session dir: `docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/`
  + run logs at `logs/`.

## Time estimate for session 29

- Setup + read handoff + verify session-28 numbers (re-apply probe +
  rebuild + 5×4 = 20 runs): 30–45 min.
- Implement closure-type histogram (Scav.c + GC.c edit + rebuild +
  redeploy + 4 probe-matrix cells): 1.5–2.5 h.
- Analyse histogram, identify suspect closure type, narrow audit:
  30–60 min.
- Audit + first hypothesis test on `Evac.c` or `Scav.c`: 2–4 h.

Realistic: 1 medium-to-long session (~5–7 h) to identify the
closure type and pinpoint the buggy scavenge routine.  Then 1 short
session to write + test the fix and ship it.

## Paste-into-fresh-session prompt

```
Context: session 28 of the GHC darwin8-ppc project just wrapped up.
Session 28 wrote PROBE28 — an RTS-side per-GC printf in rts/sm/GC.c
(no Haskell-side perturbation) — and used it to discriminate between
session 27's "one bug, two victims" and "two bugs" framings.

Result: ONE BUG, TWO VICTIM DATA STRUCTURES.  With PROBE28 enabled,
Big2.hs +RTS -A1m -G1 panics 5/5 with the STG-time refineFromInScope
signature instead of session 27's TC-time "swap not in scope" — the
probe's small timing perturbation shifted which downstream IntMap-
backed VarEnv catches the corrupted closure.  Both signatures come
from the same root corruption.

PROBE28 also ruled out two of session 27's audit targets:
- scavenge_capability_mut_lists / mut_list scavenge: under -G1 the
  mut_list is empty, yet Big2 -G1 panics 5/5.
- scavenge_static / scavenge_thunk_srt / scavenge_fun_srt: under
  -G1 every GC walks the same ~175k-entry static_objects chain in
  both M5 (PASS) and Big2 (FAIL).

Remaining suspects: rts/sm/Evac.c (evacuate, copy_tag, copy),
rts/sm/Scav.c (scavenge_block dispatch), forwarding-pointer
machinery, info-table reads on PPC32.

Read in order:
1. docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md
2. docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/README.md
3. docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/findings.md
4. docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch
5. (reference) docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md

Top priority: extend PROBE28 with a per-closure-type histogram
(increment per-type counter in scavenge_block's main switch, print
in the post-GC summary).  Run on M5 -A1m-G1 (PASS) and Big2 -A1m-G1
(FAIL); compare histograms to find the closure type that fires only
in the failing case.  Then audit Evac.c / Scav.c's scavenge for that
type with PPC32 (32-bit big-endian) eyes.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's -A1G wrapper.  ALWAYS
revert the probe + rebuild + redeploy clean stage2 at session end.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md`](docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md).

When session 29 ends, write the next handoff at:
`docs/sessions/<DATE>-session-29-<slug>/HANDOFF.md`.
