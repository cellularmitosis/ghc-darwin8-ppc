# Session 28 findings — PROBE28 discriminator data downgrades session-27's "two distinct bugs" to "one bug, two victim data structures"

## TL;DR

- **PROBE28** (slim RTS-side per-GC printf, no Haskell-side
  instrumentation) confirms the bug fires regardless of:
  - mut_list scavenge activity (under `-G1` mut_lists are empty;
    Big2 still fails),
  - static_objects scavenge load (M5 `-G1` passes despite walking
    the same ~175k-entry static chain on every GC that Big2 `-G1`
    walks).
- **Big2.hs `-A1m -G1` panic signature changed under the probe.**
  Session 27 (no probe): 10/10 fail with `* GHC internal error:
  'swap' is not in scope during type checking, but it passed the
  renamer` (TC-time variant).  Session 28 (with PROBE28): 5/5 fail
  with `panic! refineFromInScope` (STG-time variant).  The probe's
  small per-GC timing perturbation is enough to shift the corruption
  to a different downstream victim data structure.  **Strong evidence
  the TC-time and STG-time signatures are the same underlying bug.**
- **`-A1m -G2` TC-time signature persists under the probe** for Big2
  (5/10 still produce "swap not in scope").  So the TC-time
  manifestation is real, just timing-fragile; it's a different
  victim, not a different bug.
- M5 `-A1m -G2` failure rate dropped from 10/10 (session 27, no
  probe) to 2/5 with PROBE28 — confirming the probe is mildly
  perturbing but does not suppress the bug.
- **Removed from suspect list:** `scavenge_capability_mut_lists` /
  `scavenge_mutable_list`, `scavenge_static`, `scavenge_thunk_srt`,
  `scavenge_fun_srt`.  All run identically (or more, under `-G1`) in
  the passing case (M5 `-G1`) and the failing case (Big2 `-G1`).
- **Remaining suspects:** `rts/sm/Evac.c::evacuate` / `copy_tag` /
  `copy`, `rts/sm/Scav.c::scavenge_block` dispatch by closure type,
  forwarding-pointer / info-table machinery, PPC32-specific block
  arithmetic in `bdescr` / `BLOCK_SIZE` macros.
- v0.12.0 ships unchanged.  Probe reverted at session end; clean
  stage2 redeployed.

## The probe

3 insertion points in `rts/sm/GC.c`.  See
[`probe28-rts-gc.patch`](probe28-rts-gc.patch) for the full diff.

### File-static state (line ~123)

```c
#define PROBE28_MAX_GENS 8
static StgWord64 probe28_gc_no = 0;
static W_ probe28_pre_mut[PROBE28_MAX_GENS];
```

### Pre-GC snapshot (just before the `prepare_collected_gen` loop)

```c
probe28_gc_no++;
{
    uint32_t pg_ng = RtsFlags.GcFlags.generations;
    if (pg_ng > PROBE28_MAX_GENS) pg_ng = PROBE28_MAX_GENS;
    for (uint32_t gg = 0; gg < PROBE28_MAX_GENS; gg++) {
        probe28_pre_mut[gg] = 0;
    }
    for (uint32_t gg = 0; gg < pg_ng; gg++) {
        W_ s = 0;
        for (uint32_t c = 0; c < getNumCapabilities(); c++) {
            s += countOccupied(capabilities[c]->mut_lists[gg]);
        }
        probe28_pre_mut[gg] = s;
    }
}
```

### Post-GC summary line (just before `stat_endGCWorker`)

```c
{
    uint32_t pg_ng = RtsFlags.GcFlags.generations;
    if (pg_ng > PROBE28_MAX_GENS) pg_ng = PROBE28_MAX_GENS;
    W_ static_chain = 0;
    StgClosure *sp = gct->scavenged_static_objects;
    while (sp != END_OF_STATIC_OBJECT_LIST && static_chain < 1000000) {
        StgClosure *up = UNTAG_STATIC_LIST_PTR(sp);
        const StgInfoTable *info = get_itbl(up);
        StgClosure **link = STATIC_LINK(info, up);
        sp = (StgClosure *)RELAXED_LOAD(link);
        static_chain++;
    }
    debugBelch("PROBE28 gc=%llu N=%u maj=%d ng=%u",
               (unsigned long long)probe28_gc_no, N, (int)major_gc, pg_ng);
    for (uint32_t gg = 0; gg < pg_ng; gg++) {
        debugBelch(" preMut%u=%lu", gg, (unsigned long)probe28_pre_mut[gg]);
    }
    debugBelch(" staticChain=%lu copiedW=%lu liveW=%lu liveB=%lu\n",
               (unsigned long)static_chain, (unsigned long)copied,
               (unsigned long)live_words, (unsigned long)live_blocks);
}
```

## Data — pass/fail matrix under PROBE28

All on pmacg5 (PowerMac G5 / Tiger 10.4.11), `/opt/ghc-stage2/bin/ghc-real`
built with PROBE28 applied to `rts/sm/GC.c`.

| Input    | RTS flags         | iters | pass | fail | dominant symptom                                                |
|----------|-------------------|------:|-----:|-----:|-----------------------------------------------------------------|
| M5.hs    | `+RTS -A1m -RTS`  |    5  |   3  |   2  | depSortStgBinds (both fails at GC 24, both major)               |
| M5.hs    | `+RTS -A1m -G1`   |    5  |   5  |   0  | suppressed (13 GCs, all major under `-G1`)                       |
| Big2.hs  | `+RTS -A1m -G1`   |    5  |   0  |   5  | **refineFromInScope** at GC 17 (5/5) — **not** "swap not in scope"|
| Big2.hs  | `+RTS -A1G -RTS`  |    5  |   5  |   0  | control (1 GC)                                                   |
| Big2.hs  | `+RTS -A1m -RTS`  |   10  |   5  |   5  | "swap not in scope" (TC-time, at GC 41 in failing iters)        |

### Comparison to session 27 (clean stage2, no probe)

| Cell                       | Session 27 fail rate / signature          | Session 28 (probe) fail rate / signature        |
|----------------------------|-------------------------------------------|--------------------------------------------------|
| M5.hs `-A1m`               | 10/10 (depSortStgBinds + refineFromInScope) | 2/5 (depSortStgBinds)                            |
| M5.hs `-A1m -G1`           | 0/10 (suppressed)                         | 0/5 (suppressed)                                  |
| Big2.hs `-A1m -G1`         | **10/10 ("swap not in scope")**           | **5/5 (refineFromInScope)** ← **signature shift** |
| Big2.hs `-A1G`             | 0/10                                      | 0/5                                              |
| Big2.hs `-A1m` (default `-G2`) | 9/10 (8× "swap", 1× depSortStgBinds)  | 5/10 (5× "swap")                                  |

**The probe lowers the fail rate but does not suppress the bug.**
Critically, Big2 `-G1` flips from TC-time to STG-time under the
probe — this is the discriminator.

## Why the probe-induced signature shift is conclusive

The "two distinct bugs" reading from session 27 predicted that one bug
fired the STG-time family and a separate bug fired the TC-time family.
Under that reading, perturbing the GC with a printf shouldn't move a
failure from the TC-time bug to the STG-time bug — they have different
mechanisms.

The "one bug, two victim data structures" reading predicted that
adding tiny delays between mutator and GC phases would change which
in-memory IntMap / VarEnv / TcTypeEnv the corruption lands in.  That
is exactly what we observe: Big2 `-A1m -G1` deterministically panics
with `refineFromInScope` (STG-time, Simplify/Env.hs:706) under the
probe, while without the probe (session 27) it deterministically
panics with the TC-time signature.

Both signatures are reading from a corrupted VarEnv / IntMap chain
(LocalRdrEnv → TcTypeEnv → SimplifierEnv → ... — these are all
`Data.IntMap`-backed `VarEnv` newtypes deep down).  The corruption
is the same; the victim depends on which of these maps holds the
freshly-corrupted node when the bug surfaces.

## Why static_objects scavenge is ruled out

PROBE28 reports `staticChain` (the length of
`gct->scavenged_static_objects` walked via `STATIC_LINK`) per GC.

| Cell                     | staticChain per major GC | major GCs / total GCs | result |
|--------------------------|--------------------------|-----------------------|--------|
| M5.hs `-A1m -G1` (PASS)  | ~175 000–181 000         | 13 / 13 (all major)   | PASS   |
| Big2.hs `-A1m -G1` (FAIL)| ~174 000–181 000         | 17 / 17 (all major)   | FAIL   |
| M5.hs `-A1m` (FAIL iter) | ~174 000–180 000         | 4 / 24                | FAIL at GC 24 (major) |
| Big2.hs `-A1m` (FAIL)    | ~174 000–180 000         | 5 / 41                | FAIL at GC 41 (major) |

The static_objects chain is the same magnitude in PASS and FAIL
cases.  Under `-G1` it gets walked on every GC (because every GC is
major and `scavenge_static` always runs on majors); under `-G2` it
gets walked on majors only.  If a bug in `scavenge_static` /
`scavenge_thunk_srt` / `scavenge_fun_srt` were responsible, M5
`-G1` would not be a clean PASS (those code paths fire 13 times
on every successful M5 `-G1` run).

This kills the "Third: address the TC-time variant separately" thread
from session 27's HANDOFF (audit `scavenge_thunk_srt` / `scavenge_fun_srt`
/ `scavenge_static`).

## Why mut_list scavenge is ruled out

Under `-G1`, `RtsFlags.GcFlags.generations == 1`, so:

- `prepare_collected_gen` for g==0 hits the `g != 0` test as false
  and is a no-op (does not stash to `saved_mut_lists`).
- `prepare_uncollected_gen` is never called (loop bound is empty).
- `scavenge_capability_mut_lists` runs the loop
  `for (g = generations-1; g > N; g--)` with `generations=1`, `N=0`:
  the loop body executes zero times.  No older-gen mut_list is
  scavenged.

PROBE28 confirms: under `-G1`, `preMut0 = 0` every GC (gen 0 has no
mut_list).  No older gen exists, so no preMut1 either.

Big2.hs `-A1m -G1` panics 5/5 with this configuration.  **The bug
fires without ANY mut_list scavenging happening.**  This kills
session 27's "Second: audit `rts/Updates.cmm` and write-barrier
code" thread as a primary direction (it can still be a contributing
factor in the `-G2` path, but it's not the root cause).

## Where the bug must be — narrowed suspect list

The bug fires:

- ✅ On every major GC under `-G1` for sufficiently large heaps
  (Big2 fails at every iteration of this configuration).
- ✅ Sometimes on major GCs under `-G2` (M5 / Big2 fail rates 0–100%
  depending on heap-shape heuristics, all failures at major GCs).
- ❌ Not via mut_list scavenge (no mut_list under `-G1`).
- ❌ Not via static_objects scavenge (M5 `-G1` walks the same chain
  size that Big2 `-G1` walks; M5 passes).

What runs on every major GC (and is reachable from `-G1`):

1. `evacuate()` (rts/sm/Evac.c) — copies live closures from from-space
   to to-space.  Reads info-table pointer, decides closure size + ptrs,
   calls `copy_tag()` to copy + tag the closure, installs forwarding
   pointer.
2. `copy_tag()` / `copy()` (rts/sm/Evac.c) — the inner copy routine.
   Includes a tight loop over the closure payload.
3. `scavenge_block()` (rts/sm/Scav.c) — iterates from-space objects
   and dispatches by `info->type` to a per-closure-type scavenge that
   calls `evacuate` on each pointer field.
4. `scavenge_one()` — handles a single closure (used from mut_list
   scavenge, but also from `scavenge_block`'s general dispatch).
5. Forwarding-pointer reads/writes — `LOOKS_LIKE_INFO_PTR`, `IS_FORWARDING_PTR`,
   `MIN_INTLIKE`/`MAX_INTLIKE` macros, `getInfoTable` indirection.

All of these involve pointer arithmetic at byte / word granularity
and assume specific alignment.  PPC32 is a 32-bit big-endian target,
which is uncommon for modern GHC — bugs at the byte-order or
alignment level would survive QC on 64-bit little-endian boxes and
fire here.

## Bug-firing pattern

| Run                       | Failing GC | Pre-fail mut1 | copiedW at fail | liveB after fail GC |
|---------------------------|-----------:|--------------:|----------------:|--------------------:|
| M5 `-A1m` iter01 (FAIL)   |    GC 24   |       808     |     365 847     |       392           |
| M5 `-A1m` iter02 (PASS)   |    GC 25   |       306     |     367 208     |       412           |
| Big2 `-A1m -G1` iter01    |    GC 17   |       n/a     |     464 922     |       483           |
| Big2 `-A1m` iter01        |    GC 41   |       398     |     462 385     |       484           |

The failing major GCs all have copiedW around 365–465k words and
post-fail liveB ≈ 400–500.  The pre-fail mut1 differs (it's an
input-shape variable, not the trigger).  The shared feature is the
*shape* of the major collection's work — `evacuate` is being called
on a few hundred thousand words of live data, and somewhere in
there one closure ends up with a corrupted pointer field.

The deterministic GC index per cell tells us the bug fires at a
specific point in execution — same code path on the same input
produces the same GC number that fires.  This is consistent with
the corruption being introduced when a specific closure type appears
in from-space for the first time.

## Open questions / next-step priorities

### Top: identify WHICH closure type evacuate is mis-handling

PROBE28 captures heap-level summary but doesn't distinguish closure
types.  A focused follow-up probe: count `info->type` occurrences
per GC, emitted as a histogram in the same probe line.  If we see
that Big2's failing GC contains a closure type that M5 `-G1`'s GCs
do not contain, we have the answer.

Closure-type set worth focusing on:

- `THUNK_1_0`, `THUNK_2_0`, `THUNK_1_1`, `THUNK_2_1`, `THUNK` — high
  volume in compilation workload; payload + SRT layout differs by
  shape.
- `IND`, `IND_STATIC` — indirection chains; `IND` payload is a single
  pointer; evacuate is supposed to short-circuit them.
- `BLACKHOLE` — thunk-update marker; subtle race-free protocol with
  the write barrier.
- `PAP`, `AP`, `AP_STACK` — partial-application closures, variable-
  size payload, bitmap-driven scavenge.
- `MUT_VAR_CLEAN` / `MUT_VAR_DIRTY` — relevant only under `-G2` but
  worth distinguishing.
- `FUN_2_0` / `FUN_2_1` / `FUN_1_0` etc. — the bulk of allocated
  closures.

Also worth recording: count of forwarding-pointer hits during
evacuate (i.e. closures that were already evacuated).

### Second: read `rts/sm/Evac.c` with PPC32 eyes

Specifically:

- `evacuate1` / `evacuate` — the dispatch (line ~620).  Look at how
  `info` is read from `p->header.info` and what `IS_FORWARDING_PTR`
  test does on PPC32 (32-bit forward pointer with low-bit tag).
- `copy_tag` (line ~150) — uses `alloc_for_copy` to get to-space
  block, then `memcpy_words`.  `memcpy_words` is a hand-rolled
  copy loop on PPC32; should be a simple unrolled loop but worth
  reading.
- `copy` (line ~104) — copy without tag preservation.

### Third: read `rts/sm/Scav.c::scavenge_block` for PPC32-isms

`scavenge_block` walks a block from `bd->start` to `bd->free`,
switches on `info->type`, calls `evacuate` for each pointer
field.  Key risk areas:

- The pointer arithmetic that advances `p` past each closure.  Each
  closure type has a different size; getting the size wrong leads to
  reading the next closure's header as a pointer, which would corrupt
  the next closure's payload via `evacuate`.
- Bitmap-driven scavenge: `scavenge_PAP_payload`, `scavenge_arg_block`,
  `scavenge_large_bitmap`, `scavenge_small_bitmap`.

### Fourth: try a Big2 variant that omits `Data.Map.Strict`

Session 27 noted Big2 differs from M5 in importing `Data.Map.Strict`
and having a `where`-bound local function.  Cheap test: simplify
Big2 progressively until the bug stops firing.  The first removal
that turns 5/5 fail → 0/5 pass tells us which closure type / library
function is the trigger.

## Process notes

- **PROBE28's perturbation is real but not bug-suppressing.**  M5 `-A1m`
  drops from 10/10 fail → 2/5 fail.  Big2 `-A1m -G1` stays 5/5 fail
  but shifts signature.  For session-29's enhanced probe, prefer a
  ring-buffer or sampling approach to minimize printf overhead.
- **The probe rebuild path corrected.**  Session 27's HANDOFF said
  `_build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/rts/libHSrts-1.0.2.a`;
  the actual Hadrian target is
  `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`.
- **End-of-session cleanup** is non-negotiable: probe noise to stderr
  on every GC would break user-facing usage.  Source reverted +
  rebuilt + redeployed at session end.

## Files added this session

- [`README.md`](README.md), this `findings.md`, `HANDOFF.md`,
  `commits.md` — writeup.
- [`probe28-rts-gc.patch`](probe28-rts-gc.patch) — the RTS probe
  (re-applicable via `git apply` inside
  `external/ghc-modern/ghc-9.2.8`).
- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) —
  the M5 / Big2 × `-A1m` / `-A1m -G1` / `-A1G` matrix.
- [`scripts/big2-a1m-test.sh`](scripts/big2-a1m-test.sh) — Big2 at
  default `-G2`.
- Run logs at [`logs/`](logs/)

