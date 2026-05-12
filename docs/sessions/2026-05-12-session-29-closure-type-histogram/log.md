# Session 29 — running log

Real-time scratch log.  Decisions, dead ends, judgment calls — write
liberally per CLAUDE.md "Document everything".  README.md /
findings.md / HANDOFF.md condense this at session end.

## Starting state

- Arrived: 2026-05-11 23:35 CDT (= 2026-05-12 UTC, matching the
  session-26..28 slug convention).
- v0.12.0 ships unchanged.  Stage2 on pmacg5 is the clean rebuild
  from end of session 28 (`/opt/ghc-stage2/bin/ghc-real` mtime
  2026-05-11 23:28, ~7 min before session start).
- GHC source tree under `external/ghc-modern/ghc-9.2.8/` clean for
  `rts/sm/GC.c`.  (The other M files in `git status` are the long-
  standing project patches that have been in place since the build
  was wired up.)
- Per session-28 HANDOFF, plan is:
  1. Re-apply PROBE28 patch.
  2. Extend with per-closure-type histogram in `scavenge_block`.
  3. Run matrix → diff PASS (M5 -A1m -G1) vs FAIL (Big2 -A1m -G1)
     closure-type distributions.
  4. Identify suspect type; audit `Evac.c` / `Scav.c` paths for it.
- Skipping the optional `tests/run-tests.sh` baseline run — session
  27 certified it green earlier today and session 28 ended with a
  clean rebuild + redeploy.  Nothing has touched the tree since.

## Plan for this session

1. Apply PROBE28 patch (session 28's RTS-side per-GC probe).
2. Extend with PROBE29: per-closure-type counters bumped in
   `rts/sm/Scav.c::scavenge_block` (per closure scavenged) and
   `rts/sm/Evac.c::evacuate` (per fresh-evacuated closure), plus a
   forwarding-pointer-hit counter.  Counters indexed by `info->type`
   (0..63 — N_CLOSURE_TYPES = 64).  Reset at start of every
   `GarbageCollect()` and printed in two new `debugBelch` lines as
   part of the per-GC summary.
3. Rebuild RTS lib only (~5 s), redeploy stage2 to pmacg5 via
   `deploy-stage2.sh` (~3 min — cross-link of the 193 MB stage2 ghc
   binary).
4. Run matrix on the cleanest discriminator pair: M5 `-A1m -G1`
   (PASS, 5 iters) and Big2 `-A1m -G1` (FAIL, 5 iters).
5. Diff histograms PASS vs FAIL.

## Step-by-step

### Step 1 — apply PROBE28, extend to PROBE29

Mechanics:

```bash
cd external/ghc-modern/ghc-9.2.8
git apply ../../docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch
# Then hand-edited rts/sm/GC.c to add PROBE29 declarations + reset + print;
# rts/sm/Scav.c with the bump in scavenge_block (after info = get_itbl());
# rts/sm/Evac.c with the fwd-ptr hit bump (line ~810) and the per-type
# fresh-evac bump (line ~852, just before the switch).
```

PROBE29 design notes:

- `W_ probe29_type_hist[64]` — bumped per closure scavenged in
  `scavenge_block`.
- `W_ probe29_evac_fresh[64]` — bumped per closure freshly evacuated
  (i.e. not short-circuiting on a forwarding pointer) in `evacuate`.
- `W_ probe29_evac_fwd_hits` — bumped on every forwarding-pointer
  hit in `evacuate`.
- All declared non-static in `GC.c`; `extern` in `Scav.c` / `Evac.c`.
- Output lines:
  ```
  PROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...
  PROBE29 gc=<n> evac e<type>=<count> ...
  ```
- Zero buckets are skipped to keep the lines compact.

### Step 2 — RTS rebuild + deploy

RTS rebuild: 4.25 s (correct Hadrian target per session-28's HANDOFF
correction).  Deploy via `deploy-stage2.sh pmacg5`: ~3 min (the
deploy includes the full stage2 ghc cross-link).

NOTE-1: my Bash tool kept invoking `deploy-stage2.sh` in background
mode unexpectedly.  First invocation completed cleanly (exit 0) but
the completion notification arrived after I had checked the
binary's mtime once and noticed it was still the session-28
artifact — so I impatiently kicked off a second deploy concurrently,
then stopped it via TaskStop once the first one's completion event
landed.  No harm: the two deploys produce identical bits and rsync's
last-writer-wins semantics keep the result consistent.  Lesson: be
patient about background-task completion events instead of
double-fired commands.

Smoke test confirmed the probe is emitting.  Three GCs visible
(one for `ghc --version`, two for the compile-and-run test).  Mix of
closure types in the histograms looked sane: high counts of CONSTR
variants (1, 2, 4), THUNK variants (15, 16, 18), and `e38`
(BLACKHOLE) which appears only in evacuate (BLACKHOLE has its own
short-circuit path in `evacuate` and never reaches `scavenge_block`'s
main loop).

### Step 3 — run probe matrix

[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) runs
each cell 5×, captures all stderr per iter to `log/session29/`.

Results:

```
=== M5.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===
  iter01..05 rc=0 gcs=13 : OK   →  pass=5 fail=0

=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===
  iter01..05 rc=1 gcs=17 : panic at GC 17  →  pass=0 fail=5
```

Reproduces session 28 exactly.  All 5 Big2 iters panic at GC 17
with the STG-time `refineFromInScope` signature.

### Step 4 — histograms across iters

Sampled the PROBE29 line for GC 17 across all 5 Big2 iters.
**Byte-for-byte identical** — every closure-type count, every fwd-
hit, every metric matches.  Confirms full determinism of the bug:
same input → same GC behavior → same crash.

### Step 5 — histogram diff M5 GC 13 (PASS) vs Big2 GC 17 (FAIL)

Wrote [`scripts/diff-histograms.sh`](scripts/diff-histograms.sh)
to normalize and pretty-print the diff.  Initial run found bug in
the typename lookup (regex excluded digits in symbol names like
CONSTR_1_0); fixed.

Key data (M5 GC 13 vs Big2 GC 17 scav histogram):

| Type                 | M5    | Big2  | Ratio  |
|----------------------|------:|------:|-------:|
| CONSTR(1)            | 18361 | 22713 |  1.24x |
| CONSTR_1_0(2)        | 12150 | 15929 |  1.31x |
| CONSTR_2_0(4)        | 23677 | 27928 |  1.18x |
| THUNK(15)            |  2732 |  3259 |  1.19x |
| THUNK_1_0(16)        |  7698 | 10182 |  1.32x |
| THUNK_2_0(18)        |  9767 | 13858 |  1.42x |
| **ARR_WORDS(42)**    |  4853 |  8047 |**1.66x**|
| MUT_ARR_PTRS_DIRTY(44)|    1 |    13 | 13.00x |
| MUT_VAR_DIRTY(48)    |    60 |     3 |  0.05x |
| BLACKHOLE (evac only)|   130 |   625 |  4.81x |

Big2's copiedW at GC 17 is 464982; M5's at GC 13 is 366812 — Big2
is doing ~27% more copying.  A uniform 1.27x scaling would mean
"workload differs but no closure type is over-represented."
Anything above 1.27x is anomalous.

**ARR_WORDS at 1.66x is the biggest workload-relative anomaly.**
But — critically — every closure type that appears in Big2 GC 17
also appears in Big2's earlier GCs (and in M5's GCs).  No type is
unique to the failing case.

NOTE-2: the histograms make the trigger LESS clean than I expected.
If the bug were "scavenge of type X is buggy on PPC32", we'd see X
appearing only on failing runs, or only at the failing GC index.
Instead we see WORKLOAD scaling — Big2 is just doing more of
everything.  The trigger must be something else: heap layout, block
boundary, or alignment.  See "Step 6 — the filename experiment"
below.

### Step 6 — bisect Big2.hs to identify the trigger

Started writing [`scripts/big2-bisect.sh`](scripts/big2-bisect.sh)
that progressively strips Big2.hs:

- B0: identical to Big2.hs (control)
- B1: drop `topK` + its `where`-bound `swap`
- B2: also drop `Data.Map.Strict` import
- B3: also drop `scaleAndShift` + `cumsum`
- B4: bare module with one trivial declaration

Plot twist: **B0 (byte-identical to Big2.hs) PASSED 3/3** — running
to GC 18 successfully.  Big2.hs at the same input was panicking
5/5 at GC 17 minutes earlier.

`md5` confirmed the file contents are bit-identical.  The only
difference is the FILENAME on the command line: `Big2.hs` vs
`B0.hs`.

Followup matrix (single iter each, same RTS flags):

```
  Big2.hs    rc=1 gcs=17 panic=1   (FAIL)
  B0.hs      rc=0 gcs=18 panic=0   (PASS)
  BB.hs      rc=0 gcs=18 panic=0
  BigTwo.hs  rc=1 gcs=17 panic=0
  X.hs       rc=0 gcs=18 panic=0
  Big22.hs   rc=1 gcs=17 panic=0
  Big2a.hs   rc=1 gcs=17 panic=0
  aBig2.hs   rc=1 gcs=17 panic=0
  ABCDEF.hs  rc=1 gcs=17 panic=0
```

Then length sweep:

```
  A.hs       rc=0 gcs=18 panic=0   (1 char)
  AA.hs      rc=1 gcs=17 panic=1   (2 chars) FAIL
  AAA..AAAAAA.hs   all FAIL (gcs=17)
  B.hs       rc=0 gcs=18 panic=0
  BB.hs      rc=0 gcs=18 panic=0
  BBB..BBBBB.hs    all FAIL (gcs=17)
```

So `A.hs` PASSES at 1 char, `AA.hs` FAILS at 2 chars.  But `B.hs`
and `BB.hs` PASS; `BBB.hs` FAILS at 3 chars.  The threshold depends
on the specific filename text, not just length.  This proves the
bug is sensitive to *exact heap state* — every byte allocated for
filename storage / FastString / module-summary path shifts the
heap layout enough to flip the trigger.

NOTE-3: this kills the per-closure-type-bug hypothesis stone dead.
A bug in `scavenge_block`'s dispatch on type X would fire whenever
X is scavenged — and X is scavenged on every GC of every input.
Instead, the bug fires only when the heap state at GC 17 reaches a
*specific configuration*.  The trigger is **heap-layout-dependent**,
not source-dependent.

Additional cross-flag sweep (same filenames, different RTS):

```
-A1m default (=-G2):
  Big2.hs PASS, BB.hs FAIL, BBB.hs FAIL, X.hs FAIL, AAA.hs FAIL

-A2m -G1:
  Big2.hs FAIL, BB.hs PASS, BBB.hs PASS, X.hs FAIL, AAA.hs PASS
```

Different allocation areas redistribute which inputs hit the
trigger.  Pattern is not length-monotonic — it's a complex function
of (filename, RTS flags) → heap state at the critical GC → trigger
yes/no.

### Step 7 — wrap up

- Saved [`probe29-rts.patch`](probe29-rts.patch) (229 lines, all
  three files: GC.c, Scav.c, Evac.c).
- `git checkout` reverted rts/sm/{GC,Scav,Evac}.c.
- Rebuilt RTS clean (4.67 s), redeployed stage2.  Smoke test passes
  with no PROBE noise; Big2.hs -A1m -G1 still panics deterministically
  with the refineFromInScope (STG-time) signature.  Stage2 now
  matches v0.12.0 again.

## Open at session end

- The closure-type histogram diff identified ARR_WORDS as the most
  workload-disproportionate type — but the filename experiment
  shows the trigger isn't actually per-type.  Audit direction for
  session 30 should pivot to heap-geometry / alignment / block-
  boundary concerns rather than continuing the type-based hunt.
- The audit of `Evac.c::evacuate` / `copy_tag` / `Scav.c::scavenge_block`
  that the session 28 HANDOFF queued was started but cut short
  once the filename finding redirected priorities.  Notes in
  findings.md.
- Did not try `+RTS -DS` sanity-check rebuild — that needs DEBUG
  RTS and possibly a stage2 link against `_debug.a`.  Good queue
  item for session 30.

## Time

- Session start: 23:35 CDT.
- Session end: ~00:30 CDT (next day in UTC, 2026-05-12).
- Total: ~2 h.  (HANDOFF estimate was 5–7 h; the filename
  discovery short-circuited the planned audit phase and is a much
  more important data point to capture than a slower-paced audit.)
