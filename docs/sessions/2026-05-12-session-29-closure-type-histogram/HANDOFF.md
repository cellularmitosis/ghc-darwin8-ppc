# Handoff from session 29 → session 30

**For:** the next claude session.
**From:** session 29 (PROBE29 per-closure-type histogram; **bug
proved heap-layout-dependent — filename-sensitive on byte-identical
source**; 2026-05-12).
**Recommended pickup:** rebuild stage2 with DEBUG / sanity-check
RTS to catch corruption inside `GarbageCollect()`, then audit
`rts/sm/Evac.c::alloc_in_moving_heap` + `rts/sm/GCUtils.c::todo_block_full`
+ forwarding-pointer arithmetic for PPC32 block-boundary /
alignment bugs.

## TL;DR (mandatory read)

- **PROBE29 (per-closure-type histogram in `scavenge_block` and
  `evacuate`)** ran cleanly.  All 5 Big2 `-A1m -G1` failing GCs
  produce byte-identical histograms — bug is fully deterministic.
- **Histogram diff (M5 GC 13 PASS vs Big2 GC 17 FAIL)** shows
  ARR_WORDS at 1.66× workload-relative, THUNK_2_0 at 1.42×,
  BLACKHOLE evac at 4.81×.  But **no closure type is unique to the
  failing GC** — every type at Big2 GC 17 also appears in Big2 GCs
  1–16 and in M5's passing GCs.
- **🟥 The bug is filename-sensitive.**  Byte-identical Big2.hs
  source compiled under filename `Big2.hs` panics 5/5 at GC 17;
  under filename `B0.hs` (or `BB.hs`, `X.hs`, `A.hs`) it PASSES at
  GC 18.  `md5` confirms identical bytes.  Length sweep: `A.hs`
  passes, `AA.hs` fails; `BB.hs` passes, `BBB.hs` fails.  Different
  RTS flags shift which (filename, flags) tuples trigger the bug.
- **This rules out a per-closure-type scavenge / evacuate bug.**
  Type-X-mishandling would fire on every input containing type X.
  Instead the bug fires only when the heap at GC 17 reaches a
  specific *layout* — which depends on filename-derived allocations.
- **New audit framing:** heap geometry, block-boundary crossings,
  allocator state, info-pointer alignment, ROUNDUP / sizeofW
  arithmetic at variable-size closures on PPC32 (32-bit big-endian,
  4 KB blocks = 1024 words).
- v0.12.0 ships unchanged.  Source tree clean at session end.
  Stage2 on pmacg5 is the clean redeploy after probe revert.
  Probe saved as a patch under this session dir.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — narrative of session 29.
3. [`findings.md`](findings.md) — full PROBE29 data + filename
   experiment + analysis.
4. [`log.md`](log.md) — real-time work log with all the dead ends.
5. [`probe29-rts.patch`](probe29-rts.patch) — the probe diff, ready
   to re-apply.
6. (Reference) Session 28 [`HANDOFF.md`](../2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)
   — for the audit-target ruleouts that still hold.

## What to NOT redo

- **Don't audit `scavenge_block`'s per-type dispatch as if the bug
  is type-X-specific.**  The filename experiment proves the trigger
  is heap-layout-dependent, not closure-type-dependent.  Anything
  framed "find the buggy `case` in `scavenge_block`'s switch" is
  unlikely to find it.
- **Don't redo the ARR_WORDS / THUNK_2_0 / BLACKHOLE evacuate
  audit.**  Those were the workload-disproportionate types in the
  histogram diff, but they appear in many GCs of many inputs
  without firing the bug.  Same logic kills the MUT_ARR_PTRS_DIRTY
  hypothesis.
- **Don't redo `scavenge_capability_mut_lists` / `scavenge_static`
  / SRT-scavenge audits** — session 28 ruled them out.
- **Don't write more Haskell-side instrumentation** — PROBE28's
  per-GC printf already perturbs timing enough to flip failure
  signatures.  PROBE29's per-closure bumps are fine (ALU-only) but
  any Haskell-side allocation perturbation is strictly worse.
- **Don't rebuild the world** for an RTS-only change.  ~5 s with
  the correct Hadrian target:
  `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`.

## What to try next, in priority order

### Top: rebuild with DEBUG / sanity-check RTS

The non-threaded RTS supports `+RTS -DS` (sanity check) and
`+RTS -DG` (GC debug trace) IF the runtime is built with DEBUG.
Hadrian already produces `libHSrts-1.0.2_debug.a` during a normal
`quick-cross` build; the question is whether stage2 links against
the debug or non-debug variant.

Steps:

1. Confirm what stage2 currently links against:
   `nm /opt/ghc-stage2/bin/ghc-real | grep -i sanity` — if it
   has sanity-check symbols, stage2 is already DEBUG-flavored.
   If not, rebuild stage2 with the debug RTS linked.
2. Run Big2.hs `-A1m -G1 -DS` and see if the corruption is caught
   inside `GarbageCollect()` rather than leaking to the next
   mutator phase.
3. If `-DS` catches a corrupted closure, the panic message will
   include a specific address.  Read the surrounding heap state
   to identify the corrupted closure's type, size, and contents.

Cost: 1 RTS rebuild (5 s) + 1 deploy (3 min) + a few runs.  ~30 min.

This is the single most informative experiment available.  Sanity
check inside GC can pinpoint the bug to a specific iteration of a
specific GC's scavenge loop.

### Second: audit `alloc_in_moving_heap` / `todo_block_full`

`rts/sm/Evac.c:111` — `alloc_in_moving_heap` pre-bumps `ws->todo_free`
*before* the limit check, expecting `todo_block_full` to compensate.
Look at the interaction carefully:

```c
StgPtr to = ws->todo_free;
ws->todo_free += size;
if (ws->todo_free > ws->todo_lim) {
    to = todo_block_full(size, ws);
}
```

`todo_block_full` (rts/sm/GCUtils.c:235):

```c
ws->todo_free -= size;  // undo the pre-bump
// ... decide extend vs push-out ...
if (!urgent_to_push && can_extend) {
    ws->todo_lim = stg_min(...);
    p = ws->todo_free;
    ws->todo_free += size;
    return p;
}
// push out + alloc new block
ws->todo_bd = NULL;
ws->todo_free = NULL;
ws->todo_lim = NULL;
alloc_todo_block(ws, size);
p = ws->todo_free;
ws->todo_free += size;
return p;
```

PPC32 concerns:

- `bd->start + bd->blocks * BLOCK_SIZE_W` arithmetic with
  `BLOCK_SIZE_W = 1024` and 32-bit pointers.  Check for overflow
  in `(int)size` casts (line 337 of GCUtils.c: `bd->start + bd->blocks * BLOCK_SIZE_W - bd->free > (int)size`).
- `can_extend` (line 270): `ws->todo_free + size <= bd->start + bd->blocks * BLOCK_SIZE_W && ws->todo_free < ws->todo_bd->start + BLOCK_SIZE_W`.
  On PPC32, ws->todo_free is `StgPtr` (= `W_ *`).  `+ size` on a
  `W_ *` advances by `size * sizeof(W_) = size * 4` bytes.  Correct.
- The `&&` predicate has two conjuncts.  The second
  (`< bd->start + BLOCK_SIZE_W`) restricts extension to *within
  the first block* of a large block group.  Why?  See "Note [big
  objects]".  Suspect: this restriction interacts with multi-block
  large-object handling in a way that's correct on amd64 but wrong
  on PPC32.

### Third: audit forwarding-pointer / sizing arithmetic for variable-size closures

ARR_WORDS, MUT_ARR_PTRS, PAP, AP, AP_STACK are variable-size.
Their sizing macros:

- `arr_words_sizeW(x) = sizeofW(StgArrBytes) + ROUNDUP_BYTES_TO_WDS(x->bytes)`
- `mut_arr_ptrs_sizeW(x) = sizeofW(StgMutArrPtrs) + x->size`
- `pap_sizeW(n_args) = sizeofW(StgPAP) + n_args`

`ROUNDUP_BYTES_TO_WDS(n) = ((n) + sizeof(W_) - 1) / sizeof(W_)`.
On PPC32 sizeof(W_) = 4, so a `bytes` of e.g. 9 rounds to 3 words.
Looks right.

PPC32 concerns:

- `bytes` field on ARR_WORDS — written by the mutator.  Is it a
  full word on PPC32?  `StgArrBytes { StgHeader header; StgWord bytes; StgWord payload[]; }`
  — yes, `StgWord` is 4 bytes on PPC32.  Should be 32-bit aligned.
- `x->size` on MUT_ARR_PTRS — same.
- `n_args` on PAP — 16-bit field maybe?  Check struct layout.

For PAP/AP, the calling-convention info comes from `StgFunInfoTable`
(an extension of `StgInfoTable` for FUN closures).  PPC32-specific
ABI assumptions could break this.

### Fourth: per-closure-SIZE histogram (extension to PROBE29)

If the bug is alignment-dependent on variable-size closures, a
per-size histogram (bucketed by `closure_sizeW(p)` in scavenge_block)
would show Big2 GC 17 with a specific size class that M5 GCs lack.

Cost: small extension to PROBE29.  ~1 hour.

### Fifth: bisect filename more aggressively

We have a discriminator: Big2.hs FAIL, B0.hs PASS, byte-identical
content.  Can we find a 1-byte filename change that flips the
result?

Compare:

- `B0.hs` PASS, `BB.hs` PASS, `Big.hs` ?, `Big2.hs` FAIL.
- `A.hs` PASS, `AA.hs` FAIL.
- Try: `B.hs`, `Big1.hs`, `Big3.hs`, `Big2.hs`.  Does `Big.hs`
  pass while `Big2.hs` fails?

If we can isolate a 1-char (or 1-bit) flip that toggles the bug,
that's an extreme bisection that pinpoints the exact heap shift.

## Mechanics — reproducing session 29 results

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 0. Optional: baseline still green?
bash tests/run-tests.sh    # ~10 min; expect 30 PASS / 4 design diffs

# 1. Re-apply the probe
cd external/ghc-modern/ghc-9.2.8
git apply ../../docs/sessions/2026-05-12-session-29-closure-type-histogram/probe29-rts.patch

# 2. Rebuild + deploy
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# 3. Run the matrix (logs at logs/)
bash docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/run-probe-matrix.sh \
    pmacg5 5

# 4. Histogram diff (PASS GC vs FAIL GC)
bash docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/diff-histograms.sh \
    logs/M5-a1m-g1.iter1.log 13 \
    logs/Big2-a1m-g1.iter1.log 17

# 5. Filename-sensitivity quick check
ssh pmacg5 '
cd /tmp
for name in Big2 B0 BB X AAA; do
  cp Big2.hs ${name}.hs
  rm -f Big2.hi Big2.o ${name}.hi ${name}.o
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c ${name}.hs +RTS -A1m -G1 -RTS 2>&1 \
    | grep -c "panic"
done'

# 6. When done — REVERT before any user-facing run
cd external/ghc-modern/ghc-9.2.8
git checkout -- rts/sm/GC.c rts/sm/Scav.c rts/sm/Evac.c
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

**Expected:** with probe, M5 `-A1m -G1` passes 5/5 (13 GCs each),
Big2 `-A1m -G1` panics 5/5 at GC 17 with `refineFromInScope`.
Histograms across all 5 Big2 iters are byte-identical.  Filename
sweep shows `Big2.hs` panics but `B0.hs` (and `BB.hs`, `X.hs`)
pass.

## Hosts (unchanged)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/` — clean for `rts/sm/`.  Other
  paths under it have long-standing project patches.
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — clean rebuild+
  redeploy at session-29 end, matches v0.12.0.
- New session dir: `docs/sessions/2026-05-12-session-29-closure-type-histogram/`
  + run logs at `logs/`.

## Time estimate for session 30

- Setup + read handoff + verify session-29 numbers (re-apply
  probe + rebuild + 5×2 = 10 runs): 30–45 min.
- Rebuild stage2 with DEBUG/sanity-check RTS + run Big2 -DS: 1–2 h.
- If -DS catches the corruption: analyze + identify corrupted
  closure: 1–2 h.  Then audit the specific path that produces it.
- If -DS doesn't catch it: pivot to allocator audit
  (`alloc_in_moving_heap` + `todo_block_full`) and per-closure-SIZE
  histogram: 2–4 h.

Realistic: 1 medium-to-long session (~4–6 h) for sanity-check
rebuild + corruption pinpoint, then 1 short session for the fix.

## Paste-into-fresh-session prompt

```
Context: session 29 of the GHC darwin8-ppc project just wrapped up.
Session 29 implemented PROBE29 — extended PROBE28 with per-closure-
type histograms in rts/sm/Scav.c::scavenge_block and rts/sm/Evac.c::
evacuate, plus a forwarding-pointer hit count.  Goal was to identify
the closure type that fires the stage2 GC bug at Big2.hs +RTS -A1m
-G1 GC 17.

Result: ALL 5 Big2 GC 17 histograms are byte-identical (full
determinism confirmed), but NO closure type is unique to Big2's
failing GC.  ARR_WORDS is workload-disproportionate (1.66x) but
that doesn't trigger the bug — M5 GCs scavenge thousands of
ARR_WORDS successfully.

Then a Big2.hs bisect uncovered the BIG finding: compiling byte-
identical source under filename Big2.hs panics 5/5 at GC 17, but
under filename B0.hs (or BB.hs, X.hs) it PASSES.  md5 confirms
identical bytes.  The bug is HEAP-LAYOUT-DEPENDENT — every byte
of filename text shifts the cumulative allocation pattern, and
only specific heap layouts at GC 17 hit the trigger.

This rules out a per-closure-type scavenge bug.  The audit
direction pivots to: heap-block geometry, allocator state, block-
boundary crossings, info-pointer / forwarding-pointer alignment,
ROUNDUP / sizeofW arithmetic at variable-size closures on PPC32
(32-bit big-endian, 4KB blocks).

Read in order:
1. docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md
2. docs/sessions/2026-05-12-session-29-closure-type-histogram/README.md
3. docs/sessions/2026-05-12-session-29-closure-type-histogram/findings.md
4. docs/sessions/2026-05-12-session-29-closure-type-histogram/log.md
5. (reference) docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md

Top priority: rebuild stage2 with DEBUG / sanity-check RTS (run
with +RTS -A1m -G1 -DS).  If sanity check catches the corruption
inside GarbageCollect() rather than the next mutator phase, we'll
get a precise pinpoint of the corrupted closure.  Then audit the
specific scavenge / evacuate path that produced it — likely in
rts/sm/Evac.c::alloc_in_moving_heap, rts/sm/GCUtils.c::todo_block_full,
or the forwarding-pointer / info-table machinery.

Don't redo per-closure-type audit (proved dead by filename
experiment).  Don't redo static_objects / mut_list / SRT audits
(killed by session 28).

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's -A1G wrapper.  ALWAYS
revert the probe + rebuild + redeploy clean stage2 at session end.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md`](docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md).

When session 30 ends, write the next handoff at:
`docs/sessions/<DATE>-session-30-<slug>/HANDOFF.md`.
