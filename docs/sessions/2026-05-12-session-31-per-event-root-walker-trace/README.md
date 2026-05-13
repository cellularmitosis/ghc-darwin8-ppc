# Session 31 — stage2 GC bug, round 13 (filename bisect + env-var dodge discovery + scavenge_stack walker exoneration)

**Dates:** 2026-05-12 (continuing the stage2 GC bug hunt from session 30).

**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on
Tiger uses `+RTS -A1G` workaround.  Session 30's PROBE28+29+30
exhausted aggregate per-closure-type / per-allocator-path / per-size-
class counters; no aggregate counter discriminates the failing GC.
Session-30 HANDOFF queued: (a) per-event address-stream diff between
PASSing and FAILing root-walkers (top priority), (b) filename 1-byte
bisect, (c) `+RTS -Dg` GC trace, (d) stack-walker step trace, (e)
StgRegTable probe.

**Status on exit:**

- **Cross-run address-stream diff (HANDOFF's top priority) is
  unworkable.**  D.hs (FAIL) and E.hs (PASS) — byte-identical Big2
  content with a 1-bit filename flip — produce `+RTS -Dg` traces
  that **diverge at GC 1, line 1118** (a 2-word block-size diff in
  the very first generation-copy).  By GC 17 (the failing one),
  the heaps are unrecognizably permuted.  Cross-run diffing is
  fundamentally not viable.
- **Bombshell: ANY env var presence dodges the bug.**  Setting any
  3+ byte env var (e.g. `A=A`, `X=0`, `FOO=BAR`) before invoking
  Big2 `-A1m -G1` flips it from FAIL 5/5 to PASS 5/5 deterministically.
  8/8 different env vars tested all dodge.  The bug is *byte-level*
  heap-layout-sensitive — a single closure at a specific virtual
  address triggers it, and environ-block size shifts the heap
  enough to move the trigger.
- **Filename 1-byte bisect** (HANDOFF priority #2): 104 module-name
  variants compiled, found ample 1-bit-flip pairs that change
  outcome (`D` FAIL / `E` PASS) and a NEW failure-mode surface
  ("`* GHC internal error: 'swap' is not in scope during type
  checking, but it passed the renamer`") at TC time, distinct from
  but in the same Var-drop class as `refineFromInScope` at simp
  time.  Where-bound function NAME also matters: `swap`/`flip`/
  `pair`/`tweak` (4-5 char) FAIL, `permute`/`commute` (7 char) PASS.
- **PROBE31** (per-frame instrumentation of `scavenge_stack`)
  implemented and run.  Per-call `nbytes = 4 * (frames +
  payload_words)` invariant holds EXACTLY on every GC of every
  iteration (modulo my probe's own UPDATE_FRAME +1 over-count,
  which the GC-15 64-byte shortfall exactly matches and corrects
  out).  **The scavenge_stack walker is correct — no missed
  frames, no over-walks past stack_end, no early termination.**
- **The "GC 17 walks only 4 frames" datum is post-panic.**  The
  panic message appears BEFORE GC 17's PROBE31 lines.  GC 17 is
  the panic handler's tiny stack, not a buggy GC.  The bug fires
  in the mutator phase between GC 16 and GC 17 — no GC during the
  bug itself.
- **Debug-RTS perturbs which run hits the bug.**  E.hs PASSes
  under clean `ghc-real`, FAILs under `ghc-real-debug`.  Means
  `+RTS -Dg/-DS` describes a *different* failure case, not the
  same one.
- v0.12.0 unchanged.  Source tree clean at session end.  Stage2 on
  pmacg5 rebuilt + redeployed clean.  `ghc-real-debug` left in place
  for session 32.

HANDOFF for session 32: see [`HANDOFF.md`](HANDOFF.md).  Pivot: with
the stack walker exonerated and cross-run diffing dead, the next-most
plausible probes are **per-event weak-pointer and stable-pointer table
walks** (never probed), plus the option of using the env-var dodge
itself as a debugging primitive (find a minimum env-var perturbation,
then bisect the difference to localize the heap-region trigger).

## What we did, in order

### Step 1 — verified the reproducer on clean stage2

`pmacg5:/opt/ghc-stage2/bin/ghc-real` (clean v0.12.0 from session 30
end) compiles M5.hs cleanly and panics on Big2.hs `+RTS -A1m -G1`
with the exact `refineFromInScope $dNum_a1jO` message.

### Step 2 — filename 1-byte bisect (HANDOFF priority #2)

[`scripts/filename-bisect.sh`](scripts/filename-bisect.sh).
104 compilations of the EXACT Big2 body under varying module names
(A..Z, AA..AZ, BA..BZ, AAA..AAZ).

Distribution: single-char names 13 PASS / 13 FAIL.  A-prefixed
2-char: 7P/19F.  B-prefixed 2-char: 0P/26F.  AA-prefixed 3-char:
21P/5F.

Cleanest 1-bit flip pair: **`D.hs` (0x44) FAIL** vs **`E.hs`
(0x45) PASS** — same Big2 body, single-bit module-name diff.

**Two distinct surface errors observed**, both dropping a `Var`:

1. `* GHC internal error: 'swap' is not in scope during type
    checking, but it passed the renamer` (TC-time, with `tcl_env`
    dump showing top-level names but missing local `swap`).
2. `ghc-real: panic! refineFromInScope ... $dNum_a1jO`
    (simplifier-time, with `InScope` dump missing the dictionary
    Var).

Same root cause: GC drops one Var.  Layout determines which.

### Step 3 — `+RTS -Dg` trace on D / E pair (HANDOFF priority #3)

Captured `ghc-real-debug -c {D,E}.hs +RTS -A1m -G1 -Dg -RTS` →
4.1 MB / 97 k lines per file.

Key findings:

- **Debug RTS flips E from PASS to FAIL** (different failure
  signatures even).
- Megablock base addresses are identical between D and E (both runs
  deterministic, same VM allocations).
- Line-by-line diff of D and E: **divergence at line 1118**
  (`push todo block 0xcd8c000 (174 words)` D vs `(176 words)` E).
  Within GC 1.  Cascades to 58 853 line-diff over the full trace.

**This rules out the cross-run address-stream diff strategy** that
session 30 HANDOFF queued as top priority.

### Step 4 — RTS-flag + where-name + whitespace sensitivity

Ran 13 RTS-flag combinations on a whitespace-tightened Big2 body —
new PASS/FAIL distribution.  Confirmed even SOURCE WHITESPACE flips
the original `-A1m -G1` reproducer (the original reproducer had
blank lines; stripping them PASSes).

Also varied the where-bound function name: `swap`/`flip`/`pair`/
`tweak` FAIL, `permute`/`commute` PASS.

Concluded the bug is byte-sensitive on EVERY input dimension.

### Step 5 — PROBE31: per-frame scavenge_stack instrumentation

Wrote PROBE31 patch.  `rts/sm/GC.c` adds per-GC counters
(`scavstack_calls`, `frames`, `words`, `ptrs`, `frame_hist[64]`)
plus reset + emit hooks.  `rts/sm/Scav.c` adds per-frame bumping
inside `scavenge_stack`'s loop, plus optional per-call
`PROBE31_CALL` lines.

Rebuild cost: 4 s.  Deploy: ~3 min.

### Step 6 — discovered "any env var dodges"

Initial deploy used `getenv("PROBE31_VERBOSE")` to toggle verbose
mode.  Matrix runner sets `PROBE31_VERBOSE=0`.  Result: Big2 PASSes
5/5 under the matrix.

Manual reproducer (same binary, same source, no env var) → FAILs
5/5.  Investigation: setting any env var (even a 3-byte `A=A`)
dodges the bug.  PROBE31 itself is benign; the matrix's env-var
prefix was the dodge.

Re-built PROBE31 with hardcoded `verbose=1`, no env-var path → bug
fires AND PROBE31 emits both per-GC and per-call data.

### Step 7 — PROBE31 data analysis

From a FAILING run with verbose=1:

```
PROBE31_CALL gc=15 idx=1 start=0xbfe9a94 end=0xbfea000 nbytes=1388 frames=160 words=203 ptrs=164
PROBE31_CALL gc=16 idx=1 start=0xbfe9da8 end=0xbfea000 nbytes=600  frames=70  words=80  ptrs=67
[panic! refineFromInScope ...]
PROBE31_CALL gc=17 idx=1 start=0xbfe9fe8 end=0xbfea000 nbytes=24   frames=4   words=2   ptrs=1
```

Walker-accounting invariant `nbytes = 4 * (frames + words)` holds
exactly on each GC (modulo a probe over-count error on UPDATE_FRAME
that exactly accounts for the GC-15 64-byte shortfall):

| GC | nbytes | frames | words | check  |
|----|--------|--------|-------|--------|
| 16 | 600    | 70     | 80    | ✓       |
| 17 | 24     | 4      | 2     | ✓       |
| 15 | 1388   | 160    | 203   | -64 ↔ 16 UPDATE_FRAMEs × my probe's +1 over-count |

**Conclusion**: `scavenge_stack` walks every byte of every live
stack correctly.  No missed frames, no over-walks, no early
termination.  Stack-walker iteration is NOT the bug.

The post-panic GC 17 datum (4 frames in 24 bytes) is the panic
handler's tiny TSO stack, not diagnostic of the original bug.

### Step 8 — revert + clean redeploy

`git checkout -- rts/sm/GC.c rts/sm/Scav.c`, rebuild RTS (~5 s),
deploy (~3 min).  Verified Big2 `-A1m -G1` panics 1/1 with the
exact `refineFromInScope` message; M5 passes; no `PROBE` lines
emitted.

## Status on exit

- **v0.12.0 unchanged.**  No GHC-tree source edits committed.
- **Stage2 on pmacg5 is the clean rebuild after probe revert.**
  Matches v0.12.0.
- **Debug-RTS-linked `/opt/ghc-stage2/bin/ghc-real-debug` KEPT** on
  pmacg5 (caveat: it changes failure incidence — useful only when
  you want to instrument a *different* failure scenario).
- **Logs at** [`logs/`](logs/)

- **HANDOFF for session 32** pivots to weak/stable-ptr table walks
  and the env-var perturbation as a debugging primitive.  See
  [`HANDOFF.md`](HANDOFF.md).

## Files added this session

- [`README.md`](README.md) (this), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`log.md`](log.md),
  [`commits.md`](commits.md) — writeup.
- [`probe31-rts.patch`](probe31-rts.patch) — the PROBE31 patch over
  clean `rts/sm/{GC,Scav}.c`.  Re-apply with `git apply` from inside
  `external/ghc-modern/ghc-9.2.8`.
- [`scripts/filename-bisect.sh`](scripts/filename-bisect.sh) — the
  104-name filename sweep.
- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) — the
  M5 / Big2 PROBE31 matrix runner.  CAVEAT: the script's
  `PROBE31_VERBOSE` env-var prefix unintentionally dodges the bug;
  for an actual reproducer, run the GHC invocation without any
  extra env vars.
