# Session 29 — stage2 GC bug, round 11 (PROBE29 per-closure-type histogram; the filename-sensitivity plot twist)

**Dates:** 2026-05-12 (continuing the stage2 GC bug hunt).

**Status on arrival:** v0.12.0 ships unchanged.  Session 28 nailed
the "one bug, two victim data structures" framing (PROBE28 timing
perturbation flipped Big2 `-A1m -G1` from session-27's TC-time
"swap not in scope" signature to STG-time `refineFromInScope`,
proving they're the same root corruption with different downstream
victims).  Session 28 also ruled out `mut_list scavenge` and
`static_objects scavenge` paths.  Remaining suspects per session
28's HANDOFF: `rts/sm/Evac.c::evacuate / copy_tag / copy`,
`rts/sm/Scav.c::scavenge_block dispatch`, forwarding-pointer
machinery, info-table reads on PPC32.  Top queued item: extend
PROBE28 with a per-closure-type histogram to identify which type
fires the bug.

**Status on exit:**

- **PROBE29 implemented** as additions to `rts/sm/GC.c`
  (declarations + reset + per-GC print), `rts/sm/Scav.c::scavenge_block`
  (bump per closure scavenged), `rts/sm/Evac.c::evacuate`
  (forwarding-pointer hit count + bump per fresh evacuation).
  Patch saved at [`probe29-rts.patch`](probe29-rts.patch); reverted
  before session end, clean stage2 redeployed to pmacg5.
- **Probe rebuilt + redeployed**, matrix run (M5 `-A1m -G1` 5/5
  PASS, Big2 `-A1m -G1` 5/5 FAIL at GC 17 — reproduces session 28
  exactly).  Source reverted, clean stage2 redeployed.  v0.12.0
  ships unchanged.
- **Histograms across all 5 Big2 failing-GC iters are BYTE-IDENTICAL.**
  fwdHits=51890, every t<n> count identical.  Full determinism
  confirmed.
- **Histogram diff (M5 GC 13 PASS vs Big2 GC 17 FAIL):** largest
  workload-relative anomaly is **ARR_WORDS at 1.66x** (4853 vs
  8047).  THUNK_2_0 at 1.42x, CONSTR_1_0 at 1.31x, THUNK_1_0 at
  1.32x.  In evac only: **BLACKHOLE at 4.81x** (130 vs 625).
  But — **no closure type is unique to Big2's failing GC**; every
  type present in GC 17 also appeared in earlier GCs.  See
  [findings.md](findings.md) for the full diff.
- **🟥 Major finding — the bug is filename-sensitive.**  Compiling
  the byte-identical Big2.hs source under the filename `Big2.hs`
  panics 5/5 at GC 17.  Compiling the SAME bytes under filename
  `B0.hs` (or `BB.hs`, or `X.hs`) **passes** through GC 18.  The
  trigger depends on cumulative heap state, not source content.
  Length sweeps show `A.hs` (1 char) passes but `AA.hs` (2 chars)
  fails; `B.hs` and `BB.hs` pass but `BBB.hs` fails.  Different RTS
  flags shift which filenames trigger the bug.  **This rules out a
  per-closure-type scavenge bug** — such a bug would fire whenever
  type X is scavenged, not at specific (filename, flags) tuples.
  See [findings.md](findings.md) for the full data + interpretation.
- **Implication for next-session audit direction:** the bug is in
  heap geometry, block-boundary / alignment, or info-table-read
  paths that depend on EXACT memory layout.  Per-closure-type audit
  of `scavenge_block`'s switch dispatch is unlikely to find it.
  Better directions: (a) rebuild RTS with `DEBUG` / `-DS` sanity
  checks to catch corruption inside GC, (b) audit block/MBLOCK
  boundary handling on PPC32 with 4 KB blocks, (c) audit forwarding-
  pointer + info-pointer 32-bit alignment paths, (d) per-closure-
  SIZE histogram (rather than per-type) to see whether large/odd-
  sized closures correlate with the trigger.
- v0.12.0 unchanged.  Source tree clean at session end.  Stage2 on
  pmacg5 rebuilt+redeployed to match v0.12.0.  No commits to the
  GHC tree this session.

HANDOFF for session 30: see [`HANDOFF.md`](HANDOFF.md).  Top of
queue: rebuild stage2 with debug sanity checks, then audit block-
boundary / alignment paths in `rts/sm/Evac.c` and `rts/sm/GCUtils.c`.
Heap-layout sensitivity is the new framing.

## What we did, in order

### Step 1 — design + implement PROBE29

PROBE29 = PROBE28 + per-closure-type histograms:

1. **`rts/sm/GC.c`** — declare `W_ probe29_type_hist[64]`,
   `W_ probe29_evac_fresh[64]`, `W_ probe29_evac_fwd_hits` as non-
   static (so Scav.c / Evac.c can extern them).  Reset all to 0 at
   the start of every `GarbageCollect()` (right after PROBE28's
   pre-GC mut_list snapshot).  Print two new lines as part of the
   post-GC summary, skipping zero buckets:
   ```
   PROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...
   PROBE29 gc=<n> evac e<type>=<count> ...
   ```
2. **`rts/sm/Scav.c`** — add `extern` for `probe29_type_hist`.
   Bump it once per closure scavenged, right after
   `info = get_itbl((StgClosure *)p);` in `scavenge_block`'s main
   loop (line ~458 in the unpatched source).
3. **`rts/sm/Evac.c`** — add `extern` for `probe29_evac_fresh` and
   `probe29_evac_fwd_hits`.  Bump `fwd_hits` in the
   `if (IS_FORWARDING_PTR(info))` branch of `evacuate` (line ~810).
   Bump per-source-type counter just before the
   `switch (INFO_PTR_TO_STRUCT(info)->type)` (line ~852).

The bump operations are one ALU op per closure scavenged / evacuated
— millions per GC, but no I/O, so far less perturbing than
PROBE28's debugBelch-per-GC.

### Step 2 — rebuild + deploy

Rebuilt RTS lib in 4.25 s via:

```bash
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Stage2 smoke-test confirmed PROBE29 lines visible in stderr and the
histogram numbers were sane (high CONSTR / THUNK counts; BLACKHOLE
appears only in evac as expected; e3 [CONSTR_0_1] and e38 [BLACKHOLE]
correctly absent from scav since they short-circuit in evacuate).

### Step 3 — probe matrix

[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) runs
the two cells that cleanest discriminator pair from session 28:

```
=== M5.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===
  iter01..05 rc=0 gcs=13 : OK      pass=5 fail=0

=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===
  iter01..05 rc=1 gcs=17 : panic   pass=0 fail=5
```

Matches session 28.

### Step 4 — histogram diff

Wrote [`scripts/diff-histograms.sh`](scripts/diff-histograms.sh)
that parses the PROBE29 t<n>= / e<n>= tokens and prints a side-by-
side comparison with closure-type names.

Diffed M5 GC 13 (the last, "big-drop" major GC of a PASSING run)
against Big2 GC 17 (the failing GC of a FAILING run).  Big2's
copiedW = 464982 vs M5's 366812 — Big2 is doing ~27% more copying,
so a uniform 1.27x scaling means "workload differs but no closure
type is over-represented per-unit-work."

Anomalies (above the 1.27x workload baseline):

- **ARR_WORDS (42): 1.66x** — 3194 more closures in Big2.
- **THUNK_2_0 (18): 1.42x** — 4091 more.
- **CONSTR_1_0 (2): 1.31x** — 3779 more.
- **THUNK_1_0 (16): 1.32x** — 2484 more.
- **BLACKHOLE (38, evac only): 4.81x** — 495 more.
- **MUT_ARR_PTRS_DIRTY (44): 13x** (but 1 → 13 absolute — tiny).

Crucially, **no closure type is unique to Big2's failing GC** —
every type at GC 17 also appears in Big2's earlier GCs (which
finish successfully) and in M5's GCs.  The trigger isn't "type X
appearing for the first time."

### Step 5 — Big2.hs bisect → filename plot twist

Wrote [`scripts/big2-bisect.sh`](scripts/big2-bisect.sh) to strip
Big2.hs progressively (drop `topK`, drop `Data.Map.Strict`, etc.)
and find which removal flipped fail→pass.

Plot twist: variant **B0 (byte-identical to Big2.hs)** PASSED 3/3
under the same `-A1m -G1` flags that crashed Big2.hs 5/5 minutes
earlier.  `md5` confirmed the file contents are identical.

The only difference: the filename on the command line (`B0.hs`
vs `Big2.hs`).

Followup sweep at fixed source content:

```
  Big2.hs    rc=1 gcs=17 panic   FAIL
  B0.hs      rc=0 gcs=18         PASS
  BB.hs      rc=0 gcs=18         PASS
  BigTwo.hs  rc=1 gcs=17         FAIL
  X.hs       rc=0 gcs=18         PASS
  Big22.hs   rc=1 gcs=17         FAIL
  Big2a.hs   rc=1 gcs=17         FAIL
  aBig2.hs   rc=1 gcs=17         FAIL
  ABCDEF.hs  rc=1 gcs=17         FAIL
```

Length sweep:

```
  A.hs       PASS    AA.hs      FAIL    AAA..AAAAAA.hs  FAIL
  B.hs       PASS    BB.hs      PASS    BBB..BBBBB.hs   FAIL
```

So the pass/fail boundary isn't simply length — it's specific to
the cumulative heap state induced by the filename bytes flowing
through GHC's internal data structures.

Cross-flag check (same filenames, different RTS):

```
-A1m default (=-G2):
  Big2.hs PASS, BB.hs FAIL, BBB.hs FAIL, X.hs FAIL, AAA.hs FAIL

-A2m -G1:
  Big2.hs FAIL, BB.hs PASS, BBB.hs PASS, X.hs FAIL, AAA.hs PASS
```

Different `-A` and `-G` flags shift which filenames trigger the
bug — confirming the trigger is some specific *heap configuration*
that varies with allocation patterns.

### Step 6 — revert + clean redeploy

```bash
cd external/ghc-modern/ghc-9.2.8
git checkout -- rts/sm/GC.c rts/sm/Scav.c rts/sm/Evac.c
# Rebuild RTS (4.67 s)
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Smoke-test passes with no PROBE noise.  Big2.hs under `-A1m -G1`
still panics deterministically with the `refineFromInScope` (STG-
time) signature — clean v0.12.0-equivalent stage2 confirmed.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with the `+RTS -A1G` wrapper.
- **No GHC-tree source edits committed this session.**  Probe lives
  only as the patch in this session dir.
- **Stage2 ghc on pmacg5 is the clean rebuild after probe revert.**
- **Logs at** [`logs/`](logs/)

- **HANDOFF for session 30** queues debug-RTS rebuild + heap-
  geometry / alignment audit (sees [`HANDOFF.md`](HANDOFF.md)).

## Files added this session

- [`README.md`](README.md), this; [`findings.md`](findings.md);
  [`HANDOFF.md`](HANDOFF.md); [`log.md`](log.md);
  [`commits.md`](commits.md) — writeup.
- [`probe29-rts.patch`](probe29-rts.patch) — the PROBE29 patch as a
  git-format diff over the unmodified `rts/sm/{GC,Scav,Evac}.c`.
  Re-apply with `git apply` from inside `external/ghc-modern/ghc-9.2.8`.
- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) —
  M5 / Big2 × `-A1m -G1` (5 iters each).
- [`scripts/diff-histograms.sh`](scripts/diff-histograms.sh) — pretty
  diff of two PROBE29 GCs side-by-side, with closure type names.
- [`scripts/big2-bisect.sh`](scripts/big2-bisect.sh) — the Big2.hs
  variant matrix that uncovered the filename effect.
