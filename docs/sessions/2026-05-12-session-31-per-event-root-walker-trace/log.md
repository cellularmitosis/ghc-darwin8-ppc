# Session 31 — work log

**Started:** 2026-05-12.
**Continues:** session 30 (per HANDOFF.md).

## Plan on arrival

Per session-30 HANDOFF priority order:

1. (Cheap, mechanical) **Filename 1-byte bisect** — does flipping one
   byte in the filename across an alphabet flip PASS↔FAIL?  Bound the
   heap-layout-sensitivity better than session 29's coarser
   `A.hs` vs `AA.hs` ladder.
2. (Cheap, no rebuild) **`+RTS -Dg` GC trace** on Big2 with the
   already-deployed `ghc-real-debug`.  Look for per-event anomalies
   in block-push/pop/limit lines around GC 17.
3. (Big) **PROBE31** — per-event address-stream trace of every root
   walker (`markCAFs`, `scavenge_capability_mut_lists`,
   `scavenge_static`, `scavenge_stack`, `markWeakPtrList`, stable
   pointer table).  Diff M5 GC 13 (PASS) vs Big2 GC 17 (FAIL).

Cheap wins first; they may reshape the PROBE31 design.

## Step 0 — environment sanity

- pmacg5 reachable.  Both `/opt/ghc-stage2/bin/ghc-real` (193 MB,
  clean v0.12.0) and `/opt/ghc-stage2/bin/ghc-real-debug` (193 MB,
  debug-RTS-linked) are in place.  Source tree clean
  (`rts/sm/*.c` untouched after session-30 revert).
- Reproducer verified: Big2.hs `+RTS -A1m -G1` panics with the
  exact session-30 message
  (`refineFromInScope ... $dNum_a1jO`), M5.hs passes.

## Step 1 — filename 1-byte bisect (HANDOFF priority #2)

Took session 30's quick-win candidate first.  Compiled the
EXACT Big2.hs body (modulo the `module N where` header) under
104 module names: `A..Z`, `AA..AZ`, `BA..BZ`, `AAA..AAZ`.

Script: [scripts/filename-bisect.sh](scripts/filename-bisect.sh).
Log: [log/session31/filename-bisect.log](../../../log/session31/filename-bisect.log).

### Distribution by name length

| name set | PASS | FAIL |
|----------|-----:|-----:|
| A..Z (26) |  13  |  13  |
| AA..AZ    |   7  |  19  |
| BA..BZ    |   0  |  26  |
| AAA..AAZ  |  21  |   5  |

### Failure modes observed

Two distinct surface failures, both indicating the SAME class of GC
bug (a name that was in scope at the renamer is lost by the next
phase):

1. **`* GHC internal error: 'swap' is not in scope during type
    checking, but it passed the renamer`** — TC-time failure.
    `swap` is a local where-bound function inside `topK`'s body.
    The error dump shows `tcl_env` containing every top-level
    identifier (`rjN..rjU`) but the local `swap` is GONE.  This is
    earlier in the pipeline than `refineFromInScope`.
2. **`refineFromInScope ... $dNum_*`** — the original Big2 STG-time
    panic from session 28-30.

These are the same root cause (a missed GC root drops some closure),
manifesting at different pipeline points depending on which closure
gets dropped.

### Headline finding — 1-bit filename flips DO flip PASS↔FAIL

Cleanest 1-bit ASCII flip pair:

- **`D.hs` (0x44)** → FAIL (TC: 'swap' not in scope, 5/5).
- **`E.hs` (0x45)** → PASS (5/5).

Only one bit of the input differs (bit 0 of the module-name byte).
GC stats `+RTS -s`:

|        | D.hs (FAIL) | E.hs (PASS) |
|--------|------------:|------------:|
| alloc  |  65.50 MB   |  66.49 MB   |
| copied |  36.11 MB   |  41.28 MB   |
| max res|   6.99 MB   |   8.19 MB   |
| GCs    |   17        |   18        |

D fails after 17 GCs (then bails at TC).  E does 18 GCs and
succeeds (the 18th covers post-TC phases).  GC workload is
near-identical for the first 17.

### What this gives us for PROBE31

A **D.hs (FAIL) vs E.hs (PASS) pair** is a much tighter comparison
baseline than session 30's M5 vs Big2:

- M5 (PASS) ≠ Big2 (FAIL): different content, different workload
  scaling (1.27×), different GC count (13 vs 17).
- D vs E: BYTE-IDENTICAL content modulo the 1-bit module-name flip,
  same allocator workload (65 vs 66 MB), same GC pattern (17 vs 18
  GCs).

For PROBE31, this means the per-event address streams should be
*almost* equal, with a divergence localized to the GC where the
filename-byte-dependent layout difference causes a root to be
missed.

### Side-finding: B*.hs ALL FAIL

26/26 names of form `B[A-Z]` fail.  AA..AZ: only 7/26 fail.
AAA..AAZ: only 5/26 fail.  PASS-rate grows with name length;
suggests a heap-locality feature whose distribution depends on
how many bytes the module name occupies in some packed structure.

### Failure-mode signature: it's always a Var

Both failure modes drop a Var binding:

- TC error: `swap` (a where-bound local Var in `topK`) missing from
  `tcl_env`.  The dump shows top-level names rjN..rjU all present,
  but the local Var with uniq aUU (or similar) is absent.
- `refineFromInScope`: similarly drops a Var from the simplifier's
  in-scope set.

The dropped Var has a small (uppercase letter?) Uniq number, usually
in the range aUg..aUU (lexer-fresh, allocated late in renamer).

## Step 2 — +RTS -Dg trace (HANDOFF priority #3) — partial

Ran `+RTS -A1m -G1 -Dg -RTS` on D.hs and E.hs with `ghc-real-debug`.
Captured to `/tmp/{D,E}-Dg.log` (~4.1 MB each, ~97 k lines each).

### Critical finding: debug RTS perturbs the bug

E.hs PASSes under clean `ghc-real`, but **FAILs under
`ghc-real-debug`** with the panic `refineFromInScope ... InScope
{wild_00 k_aUS xs_aUT a_a1jR $dOrd_a1jS $dOrd_a1kA topK}` looking
for `swap_aUU`.  Same `swap` Var, different surface error.

So the debug RTS itself (with its extra assertion headers and
padding) shifts heap layout enough to flip E from PASS to FAIL.
This means `+RTS -Dg` cannot be used as a non-perturbing diagnostic;
its output describes a *different* failing run, not the same.

### D vs E -Dg trace diverges at GC 1

Both -Dg logs start byte-identical (megablock addresses match —
the OS gives both deterministic runs the same VM addresses).  Diff
between the two:

- 58 853 line-diff out of 97 879 lines.
- **First divergence: line 1118** — within GC 1, in
  `push todo block 0xcd8c000` — sizes `174 words` (D) vs
  `176 words` (E).  8 bytes / 2 words apart.
- That tiny GC-1 divergence cascades for the entire remaining
  trace.

**This rules out the cross-run address-stream diff strategy** that
session 30's HANDOFF queued as the top PROBE31 priority.  D and E
diverge essentially at GC 1, so by the time the bug fires at GC 17
the entire heap is permuted and the streams can't be matched.

### Body-content / RTS-flag matrix

For deeper sensitivity check, varied the where-bound name and the
RTS heap params on top of Big2.hs:

**Where-bound function name (filename fixed `Big2.hs`, `-A1m -G1`):**

| name      | length | result |
|-----------|-------:|--------|
| `swap`    | 4 ch   | FAIL: `refineFromInScope` |
| `flip`    | 4 ch   | FAIL: TC `not in scope` |
| `pair`    | 4 ch   | FAIL: TC `not in scope` |
| `tweak`   | 5 ch   | FAIL: TC `not in scope` |
| `permute` | 7 ch   | PASS |
| `commute` | 7 ch   | PASS |

Same body, different name string → different outcome.  4-5 char
names FAIL, 7-char names PASS.  Confirms heap-layout sensitivity
extends to *every* byte in the source.

**RTS flags (with whitespace-tightened Big2.hs body):**

| flags        | result |
|--------------|--------|
| `-A1m -G1`   | PASS (whitespace-changed body!) |
| `-A1m -G2`   | PASS |
| `-A1m -G3`   | FAIL: TC `not in scope` |
| `-A2m -G1`   | FAIL: `refineFromInScope` |
| `-A2m -G2`   | FAIL: TC `not in scope` |
| `-A4m -G1`   | PASS |
| `-A8m -G1`   | PASS |
| `-A16m -G1`  | PASS |
| `-A32m -G1`  | PASS |
| `-A1m -G1 -kc1k`  | PASS (rc=1 reported but no error sig — script artifact) |
| `-A1m -G1 -kc64k` | FAIL: `refineFromInScope` |

Even **stripping blank lines from the source** flips the original
`-A1m -G1` reproducer to PASS.  The body is byte-identical (without
blank lines) but the heap layout produced is sufficiently different
to dodge the bug.

This means *every* dimension of input (filename, where-name,
whitespace, RTS heap params) acts as an axis of heap-layout
sensitivity.  The PASS/FAIL outcome depends on a delicate
combination of all of them.

### Implications for the rest of session 31

1. **Cross-run address diff is dead.**  Even minor changes diverge at
   GC 1.
2. **Aggregate counters are exhausted** (PROBE19/28/29/30).
3. **The bug victim is a Var** (specifically a where-bound function
   Var or a freshly-introduced dictionary Var).
4. The most plausible remaining root-walker bugs (per session-30
   findings.md):
   - **scavenge_stack walk** (the per-frame WALK loop, not the bitmap
     codegen — that was ruled out in sessions 20-24).
   - Weak pointers.
   - Stable pointers.

Of these, scavenge_stack is the most complex code path and the most
likely candidate for a PPC32-specific bug (it deals with raw stack
words and bitmap-indexed dispatch).  Sessions 20-24 only verified
that the bitmap *values* are correct; the walker's *iteration* over
frames hasn't been probed event-by-event.

Pivoting PROBE31 to: **per-frame instrumentation of `scavenge_stack`.**

## Step 3 — PROBE31 implementation + matrix

Wrote PROBE31 instrumenting `rts/sm/Scav.c::scavenge_stack` with:

- per-call counters: calls, total frames, total payload words,
  total pointer slots (computed via small-bitmap zero-bit popcount);
- per-GC `frame_hist[64]`: histogram of info-type t* for every
  frame walked;
- per-call (verbose) `PROBE31_CALL` log line with start/end stack
  pointers, byte-diff, frame count, words, ptrs.

Implementation hits both `rts/sm/GC.c` (counter decls + reset +
emit) and `rts/sm/Scav.c` (per-frame logic inside `scavenge_stack`).
Build cost: ~4 sec.

### PROBE31 — initial deploy + matrix (verbose off, env var set)

First deploy used `getenv("PROBE31_VERBOSE")` to toggle verbose
mode.  Big2 `-A1m -G1` PASSED 3/3 (18 GCs each) under the matrix
runner.  Smoke test.

But re-running the SAME binary on the SAME `/tmp/Big2.hs` WITHOUT
`PROBE31_VERBOSE` set in environ produces 5/5 FAIL (panic at GC
17, the original symptom).

### Bombshell: ANY env var presence dodges the bug

Tested with `X=0`, `X=1`, `A=A`, `FOO=BAR`,
`ABCDEFGHIJKLMNOPQRS=0`, `PROBE31_VERBOSE=0`.  All 8/8 PASS (18
GCs).  No env var (`NONE`) → FAIL (17 GCs, panic).  Even adding
**3 bytes** to the environ block dodges the bug.

This means PROBE31 itself is NOT what dodges — the env-var perturb
does.  Setting `PROBE31_VERBOSE=0` adds 19 bytes to environ, which
shifts the program's heap layout enough to dodge.

### Re-deployed PROBE31 with hardcoded `verbose=1`

Removed the `getenv` path entirely.  `probe31_verbose` is now a
compile-time constant `1`.  No env var needed.

Re-tested Big2 `-A1m -G1`: FAIL 5/5 deterministically with
`refineFromInScope $dNum_a1jO`.  Bug fires AND PROBE31 emits both
per-GC and per-call lines.

### PROBE31_CALL data from a FAILING run

```
PROBE31_CALL gc=13 idx=1 start=0xbfe9bc4 end=0xbfea000 nbytes=1084 frames=114 ...
PROBE31_CALL gc=14 idx=1 start=0xbfe9c38 end=0xbfea000 nbytes=968  frames=104 ...
PROBE31_CALL gc=15 idx=1 start=0xbfe9a94 end=0xbfea000 nbytes=1388 frames=160 ...
PROBE31_CALL gc=16 idx=1 start=0xbfe9da8 end=0xbfea000 nbytes=600  frames=70  ...
[ghc-real: panic! refineFromInScope ...]
PROBE31_CALL gc=17 idx=1 start=0xbfe9fe8 end=0xbfea000 nbytes=24   frames=4   ...
```

Key observations:

1. **stack_end is always 0xbfea000** (top of the TSO's stack block,
   a 4 KB block at `0xbfe9000`).
2. **sp moves up toward stack_end** as functions return.  Standard.
3. **GC 17 happens AFTER the panic message**.  This is the panic
   handler's tiny stack — not the buggy GC.  The original
   "PROBE31 shows GC 17 walks only 4 frames" datum is therefore
   NOT diagnostic of the bug.  The bug fires in the mutator phase
   between GC 16 and GC 17.

### Walker accounting invariant: holds (modulo a probe artifact)

For each PROBE31_CALL: `nbytes ?= 4 * (frames + words)` should hold
exactly (1 info-pointer per frame plus payload words, all 4 bytes
each on PPC32).

GC 16: 4*(70+80) = 600 ✓
GC 17: 4*(4+2) = 24 ✓
GC 15: 4*(160+203) = 1452, but nbytes = 1388 (-64 bytes / -16
words)

The shortfall is **my probe's own UPDATE_FRAME over-count**:
`p31_this_words += sizeofW(StgUpdateFrame)` adds 2 words for an
UPDATE_FRAME, but the info-pointer is already counted via
`frames++` (1 word/frame).  GC 15's frameHist has 16 UPDATE_FRAMEs
× 1 word over-count = 16 words = 64 bytes.  Exact match.

**With the probe's own arithmetic bug corrected: `scavenge_stack`
walks every byte of the live stack accounted for; no missed
frames; no over-walks past `stack_end`.**

### Hypothesis status

**scavenge_stack iteration is NOT the bug.**  The walker reads
every frame in the live stack and advances p correctly.  No frames
are silently skipped or double-counted (after correcting my
probe's UPDATE_FRAME over-count).

Remaining root-walker suspects (per session 30 findings.md):

| candidate                                    | status from session 31 |
|----------------------------------------------|------------------------|
| stack walker iteration                       | ruled out (per-call data shows correct nbytes accounting) |
| weak pointers                                | not probed             |
| stable pointers                              | not probed             |
| SRT scavenge per-frame                       | not probed             |
| markCAFs per-address (PROBE19 was aggregate) | not probed             |
| `scavenge_one` on a specific block           | not probed             |
| StgRegTable / saved-register state           | not probed             |

### Why "any env var dodges" is the most important datum

The bug is heap-layout-sensitive at the level of 3+ environ bytes.
This narrows the bug to:

- The dropped Var lives at an address that depends on environ-
  block layout (almost certainly because the libC malloc / GHC
  RTS megablock allocator starts the program's heap at an offset
  determined by environ size).
- ONE specific virtual address X is "the slot the walker
  misclassifies / skips".  Heap layouts that put a needed-live
  closure at X cause panic; layouts that put something else (or
  nothing) at X pass.
- The walker's "blind spot" is therefore at a fixed virtual
  address relative to the rest of the heap.  Not a "data
  structure type" blind spot (PROBE29 ruled that out), not an
  allocator-state blind spot (PROBE30), not a stack-walker
  iteration blind spot (PROBE31).

This points hard at:
- A pointer in a *root-walker table* (e.g., weak ptr, stable ptr)
  that's been miscomputed, OR
- A field offset in a *closure type* that's calculated wrong on
  PPC32 only for closures landing at specific alignments, OR
- A *forwarding pointer* check (bit 0 of pointer) that misfires
  for pointers with specific low bits.

