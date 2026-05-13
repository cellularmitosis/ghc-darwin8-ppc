# Session 31 findings — per-event root-walker probe + heap-layout sensitivity audit

## TL;DR

- **The bug is "any extra byte in `environ` dodges it"** — adding even
  a 3-byte env var like `A=A` to the child process flips
  Big2.hs `+RTS -A1m -G1` from FAIL 5/5 to PASS 5/5 deterministically.
  Every env var tested (8 different sizes / contents) dodges.
- **The cross-run address-stream diff strategy (session-30 HANDOFF
  top priority) is unworkable.**  `D.hs` and `E.hs` — byte-identical
  Big2 content with a 1-bit filename flip — produce `+RTS -Dg` GC
  traces that diverge at **GC 1, line 1118**.  By the time GC 17
  fires (the failing one), the heap is permuted everywhere and the
  streams can't be aligned.
- **Failure mode signature: the bug always drops a `Var` from an
  in-scope set.**  Either `swap` (a where-bound local Var) at TC
  time, or `$dNum_a1jO` (a class-method dictionary Var) at
  simplifier time.  Two surface errors, same underlying drop class.
- **PROBE31 (per-frame `scavenge_stack` instrumentation) rules out
  the stack-walker iteration loop.**  Per-call `nbytes` exactly
  matches `4 * (frames + payload_words)` over every GC of every run
  (modulo my probe's own UPDATE_FRAME +1-word over-count, which
  cancels out on inspection).  The walker reads every byte of the
  live stack — no missed frames, no over-walks past `stack_end`.
- **The 4-frame GC 17 in the failing run is post-panic.**  The
  panic message is printed BEFORE GC 17's PROBE31 lines.  GC 17
  is the panic handler's tiny stack, not the buggy GC.  The real
  bug fires in the mutator phase between GC 16 and GC 17.
- v0.12.0 ships unchanged.  Probe reverted, stage2 rebuilt + redeployed
  clean.  `ghc-real-debug` left in place on pmacg5 for session 32.

## Major findings

### F1. Heap-layout sensitivity is at byte granularity

Three independent axes confirmed to flip PASS↔FAIL:

1. **Filename** (1-bit flip).  Big2 body under `D.hs` (0x44) FAILs
   5/5; under `E.hs` (0x45) PASSes 5/5.  Same body bytes; only the
   `module N where` header differs by 1 ASCII bit.
2. **Where-bound function name length.**  Big2 with `swap` /
   `flip` / `pair` / `tweak` (4-5 chars) FAILs; with `permute` /
   `commute` (7 chars) PASSes.
3. **Source whitespace.**  Big2 with original blank lines, `-A1m
   -G1` FAILs.  Big2 with blank lines stripped, `-A1m -G1` PASSes.
4. **`+RTS` heap params.**  `-A1m -G1` fails; `-A2m -G1` fails;
   `-A4m -G1` passes; `-A1m -G2` passes; `-A1m -G3` fails.  No
   monotonic relationship — pure heap-layout sensitivity.
5. **Process environ.**  Adding ANY env var to the child process
   dodges:

| env var                           | result      |
|-----------------------------------|-------------|
| (none)                            | FAIL (panic) |
| `A=A`                             | PASS (18 GCs) |
| `X=0`                             | PASS         |
| `X=1`                             | PASS         |
| `X=00`                            | PASS         |
| `FOO=BAR`                         | PASS         |
| `PROBE31_VERBOSE=0`               | PASS         |
| `ABCDEFGHIJKLMNOPQRS=0`           | PASS         |

The minimum perturbation (3 bytes `A=A` in environ) is enough to
shift the heap layout past the bug.

### F2. Failure modes — two surface errors, one root cause

Both errors involve a `Var` (a GHC compiler-pipeline name binding)
that was present in the renamer's output but missing from the
TC / simplifier's in-scope set:

1. **TC-time:** `* GHC internal error: 'swap' is not in scope
    during type checking, but it passed the renamer`.  The error
    dump shows `tcl_env` containing every top-level identifier
    (`rjN..rjU` for the module's TopLevelLets) but the local
    where-bound `swap` Var (uniq `aUU`) is GONE.
2. **Simplifier-time:** `ghc-real: panic! ... refineFromInScope
    ... InScope {wild_00 a_a1jJ $dNum_a1jK countOf cumsum ...}
    $dNum_a1jO`.  The InScope set is missing the dictionary Var
    `$dNum_a1jO`.

The bug drops ONE specific Var from a binding set.  Which Var
depends on heap layout.

### F3. Cross-run address-stream diff is dead

`D.hs` (FAIL) and `E.hs` (PASS) under `+RTS -Dg` — 4.12 MB / 97 k
lines each — diverge at line 1118 (within GC 1) in the
`push todo block 0xcd8c000` line, sizes `174 words` (D) vs `176
words` (E) — a 2-word / 8-byte difference.  Diff explodes to
58 853 lines across the full run.

This rules out session 30 HANDOFF's "top priority: PROBE31 per-
event address-stream diff between PASSing and FAILing runs."  The
heaps are permuted from GC 1; you can't align the streams.

### F4. Debug RTS perturbs which run hits the bug

Under `ghc-real-debug` (debug-RTS-linked), E.hs FAILs with
`refineFromInScope ... swap_aUU`.  Under clean `ghc-real`, E.hs
PASSes.  The debug RTS's extra closure headers + bookkeeping shift
heap layout enough to flip E from PASS to FAIL.

This is bad news for using `+RTS -Dg` or `+RTS -DS` on the
non-bug-firing run: the debug RTS measures a *different* failing
scenario, not the same one.

### F5. PROBE31 — scavenge_stack walker iteration is correct

Per-call data from a FAILING run:

```
PROBE31_CALL gc=13 idx=1 nbytes=1084 frames=114 ...
PROBE31_CALL gc=14 idx=1 nbytes=968  frames=104 ...
PROBE31_CALL gc=15 idx=1 nbytes=1388 frames=160 ...
PROBE31_CALL gc=16 idx=1 nbytes=600  frames=70  ...
PROBE31_CALL gc=17 idx=1 nbytes=24   frames=4   ...  ← AFTER PANIC
```

Invariant: `nbytes = 4 * (frames + payload_words)` should hold
exactly on PPC32 (1 info-pointer per frame + bitmap-described
payload, 4 bytes per word).

| GC | nbytes | frames | words | check         |
|----|--------|--------|-------|---------------|
| 16 | 600    | 70     | 80    | 4*(70+80)=600 ✓ |
| 17 | 24     | 4      | 2     | 4*(4+2)=24   ✓ |
| 15 | 1388   | 160    | 203   | 4*(160+203)=1452 — 64 OFF |

The GC 15 shortfall (-64 bytes / -16 words) is my probe's own
UPDATE_FRAME over-count: `p31_this_words += sizeofW(StgUpdateFrame)`
adds 2 for each UPDATE_FRAME, but the info-ptr is already counted
via `frames++`.  GC 15 has 16 UPDATE_FRAMEs × 1 word = 64 bytes
over-count.  Exact match — probe bug, not RTS bug.

**Conclusion: `scavenge_stack` walks the live stack correctly.
No missed frames.  No over-walks.  No early termination.**  Rules
out stack-walker iteration as the bug locus.

### F6. The post-panic GC 17 datum is not diagnostic

The panic message (`ghc-real: panic! refineFromInScope ...`) is
emitted BEFORE GC 17's PROBE31 lines in the captured stdout/stderr
stream.  GC 17 is therefore the panic handler's allocation
triggering a final GC — its tiny 4-frame stack is the panic-handler
TSO's stack, not a live compilation stack.

The actual bug fires in the mutator phase between GC 16 and the
panic message.  No GC happens during the bug.  This is consistent
with session 19 / 30's framing: the GC dropped a closure earlier,
the mutator reads through a now-dangling pointer, panics.

The drop must have happened at some GC X ≤ 16.

### F7. Implications for further investigation

Combined with session 30's findings (aggregate counters exhausted),
the heap-layout-byte-sensitivity finding rules out big classes of
hypotheses and points to:

- A single virtual address X is a "blind spot" for the GC
  walker.  Layouts that put a needed-live closure at X cause
  panic; layouts that put something else at X (or nothing) pass.
  The 3-byte minimum perturbation suggests the blind spot is at
  the granularity of single closures.

- **Remaining suspects (NOT yet per-event probed):**
  - Weak pointer table walker (`markWeakPtrList`).
  - Stable pointer table walker (`markStableTables`,
    `enlargeStableNameTable`).
  - SRT scavenge per-frame (sessions 28 only counted aggregately).
  - `markCAFs` per-address logging (session 19 was aggregate
    count only).
  - Per-block `scavenge_one` invocations.
  - StgRegTable / saved-register state (a Capability field).

- **Plausible PPC32-specific bug shapes:**
  - A pointer in a root-walker table mis-computed by 1 alignment
    unit (e.g., 4-byte vs 8-byte offset).
  - A closure-type field offset wrong for some closures aligning
    to a specific boundary.
  - A forwarding-pointer check (`IS_FORWARDING_PTR(p) = ((StgWord)p
    & 1)`) that misfires for pointers with specific low bits — but
    session 30 audited this and found it correct.

## Methodology notes

### What worked

- The **filename 1-byte bisect** (HANDOFF priority #2) immediately
  produced strong data on layout-sensitivity, including a clean
  1-bit pair (`D` FAIL vs `E` PASS) and a new failure mode
  ("swap not in scope during TC").
- The **env-var dodge experiment** was an accidental discovery
  while diagnosing a "PROBE31 dodges the bug" red herring.  It's
  the single most valuable datum of the session.
- The **`+RTS -Dg` trace** (HANDOFF priority #3) immediately showed
  the cross-run divergence problem and saved building PROBE31 as a
  diff-tool.

### What didn't work

- **The probe's getenv path** caused a false-positive "probe dodges
  bug" reading.  Setting `PROBE31_VERBOSE=0` was just the way the
  matrix runner happened to run — that env var, like all others,
  dodges.  Required hardcoding `verbose=1` to confirm the probe
  itself is benign.
- **My probe's UPDATE_FRAME word-counting** double-counted info-
  pointers (off-by-one per UPDATE_FRAME).  Fortunately the error
  was self-evident from the invariant check on GC 15.

### What I'd do differently

- Skip the env-var configurability — hardcode the probe's verbose
  knob from the start.
- For walker invariant checks, count TOTAL frame bytes (info-ptr
  + bitmap-described payload) in one place, not split between
  per-case bumps.

## Files added this session

- `README.md`, this `findings.md`, `HANDOFF.md`, `log.md`,
  `commits.md` — writeup.
- `probe31-rts.patch` — final probe diff over clean
  `rts/sm/{GC,Scav}.c`.  Reapply with `git apply`.
- `scripts/filename-bisect.sh` — the 1-byte filename sweep
  (104 compilations across A..Z, AA..AZ, BA..BZ, AAA..AAZ).
- `scripts/run-probe-matrix.sh` — the M5 / Big2 PROBE31 matrix
  runner (note: the script's `PROBE31_VERBOSE=0` env var
  unintentionally dodges the bug; for a real reproducer remove
  the `$ENV` prefix).
- Run logs at `logs/`:
  - `filename-bisect.log` — full filename sweep results.
  - `Big2-fail-verbose.log` — the failing run's PROBE31 trace
    with hardcoded `verbose=1` (captures the post-panic GC 17).
  - `M5-a1m-g1.iter{1,2,3}.log`, `Big2-a1m-g1.iter{1,2,3}.log` —
    matrix runs (Big2 ones PASSed due to env-var dodge; useful
    as the "PASSing reference" for per-GC frame counts).
