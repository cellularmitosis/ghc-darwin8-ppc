# Session 28 — stage2 GC bug, round 10 (RTS-side per-GC probe; session-27's "two distinct corruption modes" hypothesis downgraded to "one bug, two victim data structures")

**Dates:** 2026-05-12 (continuation of session 27).

**Status on arrival:** v0.12.0 ships unchanged.  Session 27 nailed a
deterministic non-perturbing repro (M5.hs `+RTS -A1m` panics 10/10 on
clean stage2 with the STG-time panic family) and discovered that
`+RTS -A1m -G1` (single-generation) fully suppresses the M5.hs panic
but does NOT suppress Big2.hs's failure — under `-G1`, Big2.hs panics
10/10 with a new, previously-uncatalogued signature: `* GHC internal
error: 'swap' is not in scope during type checking, but it passed
the renamer`.  Session 27 framed this as "the bug has at least two
distinct corruption modes" — STG-time (suppressed by `-G1`) and TC-
time (not suppressed) — and queued discriminating "one bug, two
victims" vs "two bugs" as session 28's top priority via a slim RTS-
side probe.

**Status on exit:**

- **PROBE28 implemented** as 3 instrumentation points in
  [`rts/sm/GC.c`](../../../external/ghc-modern/ghc-9.2.8/rts/sm/GC.c)
  (file-static state + pre-GC mut_list snapshot + post-GC summary
  line via `debugBelch`).  RTS-side only — no Haskell-side
  perturbation.  Patch saved at
  [`probe28-rts-gc.patch`](probe28-rts-gc.patch).
- **Probe rebuilt + redeployed**, matrix run, then source reverted
  and clean stage2 redeployed at session end.  v0.12.0 ships
  unchanged.
- **One-bug hypothesis strongly supported.**  With PROBE28 enabled,
  Big2.hs `+RTS -A1m -G1` now panics 5/5 with the STG-time
  `refineFromInScope` signature — the **same** family as M5.hs's
  `-A1m` failures and **not** session 27's "swap not in scope"
  TC-time signature.  The probe adds tiny timing delays
  (debugBelch per GC); that's enough to shift which downstream
  data structure ends up holding the corrupted closure pointer.
  Same root corruption, different downstream victim.  Big2.hs
  `+RTS -A1m` (default `-G2`) still produces "swap not in scope"
  5/10 even with the probe, so the TC-time signature is real but
  is not a separate bug.
- **Static_objects scavenge ruled out as the cause.**  Under `-G1`
  every GC is major; PROBE28 shows the `scavenged_static_objects`
  chain is walked at ~174–181k entries on every GC for both M5.hs
  (PASS) and Big2.hs (FAIL).  Same load both ways; M5 doesn't
  crash, Big2 does — so the static_objects code path is not the
  bug.
- **mut_list scavenge ruled out as the cause.**  Under `-G1`, gen-0
  has no mut_list (preMut0 = 0 always; preMut1 doesn't exist
  because ng=1).  Big2.hs `-G1` still fails 5/5 with the corruption.
  So the bug fires WITHOUT any mut_list scavenging happening.  The
  remaining mut_list audit queued by session 27 is therefore lower
  priority.
- **Bug fires at deterministic GC indices.**  M5 `-A1m -G2`: fail at
  GC 24 (when the heuristic picks major) or pass at GC 25 (when it
  defers).  Big2 `-A1m -G1`: fail at GC 17 (after liveB ≈ 1.7M
  words).  Big2 `-A1m -G2`: fail at GC 41 (5/10) or pass at GC 42
  (5/10).  In every failing run the failing GC is a major collection
  with copiedW ≈ 365–465k.
- **Remaining suspects** after probe data: `evacuate()`, `copy()` /
  `copy_tag()`, `scavenge_block()` dispatch, info-table / forwarding-
  pointer machinery in `rts/sm/Evac.c` and `rts/sm/Scav.c`.  These run
  on every GC regardless of `-G` and would fire identically across
  M5/Big2 EXCEPT that Big2 has more closures of whatever type
  triggers the bug.
- v0.12.0 unchanged.  Source tree clean at session end.  Stage2 on
  pmacg5 rebuilt+redeployed to match v0.12.0.  No commits to the
  GHC tree this session.

HANDOFF for session 29: see [`HANDOFF.md`](HANDOFF.md).  Top of
queue: enhance PROBE28 with a per-closure-type histogram so we can
identify which closure type's evacuate/scavenge fires the bug.  Then
audit `rts/sm/Evac.c::evacuate` and `rts/sm/Scav.c::scavenge_block`
with PPC32 eyes.

## What we did, in order

### Step 1 — verify baseline

Started `tests/run-tests.sh` in the background as part of arrival
sanity; killed it once Phase 2 reached `12_show_read` because by
then we'd queued an RTS source edit and the in-flight Phase-2 tests
would have linked against half-old / half-new RTS.  Session 27 had
already certified v0.12.0 stage2 green on the same day, so we
accepted that certification and moved on.  (Phase 1 host-compile
passed all 30 programs cleanly during the partial run.)

### Step 2 — design + implement PROBE28

PROBE28 lives entirely in
[`rts/sm/GC.c`](../../../external/ghc-modern/ghc-9.2.8/rts/sm/GC.c).
Three insertion points:

1. **File-static state** (near `consec_idle_gcs`) — `probe28_gc_no`
   counter and `probe28_pre_mut[8]` snapshot array.
2. **Pre-GC snapshot** (after `collect_pinned_object_blocks();`
   before `prepare_collected_gen` loop) — `countOccupied` per gen
   across all caps, stored in `probe28_pre_mut`.  Must run before
   the prepare loops because they throw away or stash the mut_lists.
3. **Post-GC summary** (just before `stat_endGCWorker` /
   `stat_endGC`) — walks `gct->scavenged_static_objects` via
   `STATIC_LINK` macros (safety-capped at 1M iterations) and emits
   a single `debugBelch` line per GC:

```
PROBE28 gc=<n> N=<gen> maj=<0|1> ng=<gens> preMut0=<w> preMut1=<w> ...
        staticChain=<count> copiedW=<w> liveW=<w> liveB=<blocks>
```

No Haskell-side instrumentation, no heap allocation, no atomic
ops.  Cost: one printf per GC + walks of mut_lists (1-block typical)
and static_objects (~175k entries on major GCs).  Slight perturbation
expected from the extra stderr writes during GC; quantified below.

Patch saved at [`probe28-rts-gc.patch`](probe28-rts-gc.patch) for
re-application.

### Step 3 — RTS rebuild + redeploy

```bash
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
# (3.3 s — only RTS bits affected, ranlib + rsync)
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

The HANDOFF's path
`_build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/rts/libHSrts-1.0.2.a`
does not parse for Hadrian.  Corrected path:
`_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`.

Stage2 smoke test passed cleanly; PROBE28 lines visible in the
smoke-test stderr.

### Step 4 — run the probe matrix

[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) runs
each cell 5×, captures all stderr (including PROBE28 lines) per
iter.

```
=== M5.hs   iters=5 flags='+RTS -A1m -RTS'    === pass=3 fail=2   (depSortStgBinds, both at gc 24)
=== M5.hs   iters=5 flags='+RTS -A1m -G1 -RTS' === pass=5 fail=0   (suppressed; 13 GCs)
=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' === pass=0 fail=5   (**refineFromInScope** at gc 17, NOT "swap not in scope")
=== Big2.hs iters=5 flags='+RTS -A1G -RTS'    === pass=5 fail=0   (control; 1 GC)
```

[`scripts/big2-a1m-test.sh`](scripts/big2-a1m-test.sh) added Big2
`-A1m` (default `-G2`) at N=10:

```
  iter01 rc=1 gcs=41 : `swap' is not in scope during type checking
  iter02 rc=1 gcs=41 : `swap' is not in scope during type checking
  iter03 rc=0 gcs=42 : OK
  iter04 rc=1 gcs=41 : `swap' is not in scope during type checking
  iter05 rc=0 gcs=42 : OK
  iter06 rc=0 gcs=42 : OK
  iter07 rc=0 gcs=43 : OK
  iter08 rc=1 gcs=41 : `swap' is not in scope during type checking
  iter09 rc=0 gcs=42 : OK
  iter10 rc=1 gcs=41 : `swap' is not in scope during type checking
```

5/10 with the TC-time "swap" signature.  Probe perturbation lowered
the fail rate from 9/10 (session 27, no probe) to 5/10, but the
TC-time signature is preserved — the probe didn't make the TC-time
manifestation impossible.

See [`findings.md`](findings.md) for the full per-GC analysis.

### Step 5 — revert + clean redeploy

Saved the probe as [`probe28-rts-gc.patch`](probe28-rts-gc.patch),
ran `git checkout -- rts/sm/GC.c`, rebuilt the RTS lib (3.5 s),
re-ran `deploy-stage2.sh pmacg5`.  Stage2 now matches v0.12.0
again.  Source tree is clean.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with the `+RTS -A1G` wrapper.
- **No GHC-tree source edits committed this session.**  Probe lives
  only as the patch in this session dir.
- **Stage2 ghc on pmacg5 is the clean rebuild after probe revert.**
- **Logs at** [`../../../log/session28/`](../../../log/session28/)
  (gitignored).
- **HANDOFF for session 29** queues per-closure-type probe
  enhancement + `Evac.c` / `Scav.c` audit.

## Files added this session

- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — writeup.
- [`probe28-rts-gc.patch`](probe28-rts-gc.patch) — the RTS-side
  probe as a git-format patch.  Re-apply with `git apply` from
  inside `external/ghc-modern/ghc-9.2.8`.
- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) —
  M5 / Big2 × `-A1m` / `-A1m -G1` / `-A1G` matrix (5 iters each).
- [`scripts/big2-a1m-test.sh`](scripts/big2-a1m-test.sh) — Big2 at
  default `-G2` (10 iters) to verify TC-time signature persistence.
