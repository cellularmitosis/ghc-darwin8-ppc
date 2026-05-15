# Handoff from session 51 → session 52

**For:** the next claude session.
**From:** session 51 (five test iterations, narrowing from
`Data.Graph.scc` down to `newArray False :: ST s (STUArray s
Int Bool)`).
**Recommended pickup:** test other unboxed STUArray types,
check if pinned arrays avoid the bug, then read the RTS source
for `stg_newByteArrayzh` on PPC32 unreg.

## ✅ SESSION CLEAN EXIT

No GHC source changes this session — only standalone Haskell
test programs.  Baseline tests at end: 30 PASS / 4 FAIL_OUTPUT
(matches session-49/50 noise floor).  v0.12.0 release unchanged.

## TL;DR — TRUE MINIMAL REPRO (3 lines)

```haskell
checkFresh :: Int -> [Bool]
checkFresh n = runST $ do
  arr <- newArray (0, n - 1) False :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]
```

Loop this 10000 times with `burnGC 1000` interleaved.  Count
iters where any element is True.

**Result on pmacg5 (PPC32 unreg)**:
- Default RTS: **8431/10001 bad**.
- `-A1m -G1`:  **8655/10001 bad**.

**Result on uranium (arm64 reg)**: **0/10001 bad**.

The freshly-allocated `STUArray Int Bool` has spurious True
bits on PPC32 unreg.  This is independent of `scc`,
`Data.Graph`, the GHC compiler, or any application code.

## Pipeline narrowed: sessions 42-51

| Session | Hook                                        | Failing count          |
|---------|---------------------------------------------|------------------------|
| 42      | `simplTopBinds` entry                       | 0-1 binders (was 9)    |
| 43      | `core2core` entry                           | 1-3 binders (was 9)    |
| 44      | `deSugar` `final_prs`                       | 3-6 (was 9)            |
| 45      | `deSugar` `tcg_binds` entry                 | 3-6 (was 9)            |
| 46      | `hsc_typecheck` exit                        | 3-5 (was 9)            |
| 47      | `tcRnSrcDecls` output                       | 2-5 (was 9)            |
| 48      | `tcTopBinds` OUTPUT                         | 2-3 (was 8)            |
| 49      | `tcTopBinds` INPUT                          | 2-3 (was 8)            |
| 50      | `Data.Graph.scc` in `stronglyConnCompG`     | 0, 3 (was 1, 8)        |
| **51**  | **`newArray False :: ST s (STUArray Int Bool)`** | **random True bits** |

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session narrative (five phases).
3. [`findings.md`](findings.md) — F1..F8 analysis with the
   stuarray_test.hs minimal repro.
4. [`stuarray_test.hs`](stuarray_test.hs) — the 30-line repro.
5. (Reference) Session 50
   [`HANDOFF.md`](../2026-05-15-session-50-drill-rnValBindsRHS/HANDOFF.md).

## What to try next, in priority order

### Top: confirm bug scope with other unboxed types

Modify `stuarray_test.hs` to test:
- `STUArray Int8 = ... 0 :: ST s (STUArray s Int Int8)` — read back, check zero.
- `STUArray Word8` — same.
- `STUArray Int` — same.
- `STUArray Word` — same.
- `STUArray Char` — same.
- Boxed `STArray` — should NOT corrupt (since the bug seems to be
  in the byte-array zeroing, and STArray uses pointer arrays).

Hypothesis: all unboxed types corrupt; boxed doesn't.

### Second: pinned vs unpinned

Try `newPinnedByteArray#` (or the high-level wrapper).  Pinned
arrays don't get scavenged; if they don't corrupt, the bug is
in scavenge.  If they DO corrupt, the bug is in the allocation
zeroing.

### Third: no-GC-pressure test

Without `burnGC` around the call, does the bug fire?  If yes,
the array isn't being zeroed properly at allocation.  If no,
GC scavenge is the corruption site.

### Fourth: read RTS source for `stg_newByteArrayzh`

In `rts/PrimOps.cmm`, find the byte-array allocation primitive.
Look for the zeroing loop.  See if there's any PPC32 / unreg
specific code.  Likely the bug is in the zeroing.

### Fifth: file GHC bug report

Title suggestion: "PPC32-unreg: freshly-allocated `STUArray
Bool` (and likely other unboxed types) has uninitialized data —
80%+ corruption rate under moderate GC pressure."

Include the 3-line minimal repro from F1 of findings.md, the
reproduction rate, GHC version (9.2.8), and platform info.

### Sixth: fix and validate

Once the RTS fix is known (likely a small zeroing fix in C / Cmm
code), apply the patch, rebuild stage1, redeploy stage2.  Re-run
the test battery.  All 30+ tests that PASS today should still
PASS; tests that exercise stage2-compiles-Haskell should now
PASS more reliably.

## Mechanics — how session 51 ran

This session **does not need a GHC rebuild between iterations**.
The bug reproduces in standalone Haskell programs.  Per
iteration:

```bash
cd /Users/cell/claude/ghc-darwin8-ppc
# Edit test in docs/sessions/2026-05-15-session-51-isolate-scc/<name>.hs
cp docs/sessions/2026-05-15-session-51-isolate-scc/<name>.hs /tmp/<name>.hs
rm -f /tmp/<name>.{o,hi}; rm -f /tmp/<name>
source scripts/cross-env.sh > /dev/null
external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc \
  -rtsopts -o /tmp/<name> /tmp/<name>.hs
scp /tmp/<name> pmacg5:/tmp/<name>
ssh -q pmacg5 "DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /tmp/<name>"
```

Each iteration takes ~30 seconds, not 7 minutes.

## What NOT to redo

* **Don't hook anywhere in GHC compiler source.**  The bug is
  in the RTS, not the compiler.
* **Don't drill `Data.Graph.scc` further.**  Sessions 50 and 51
  already pinned the corruption upstream of `scc` — `scc` is the
  victim of a corrupt `STUArray Bool`.
* **Don't try `STArray` (boxed).**  Session 51 phase 4 showed
  boxed arrays don't reproduce — bug is unboxed-specific.

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real`
  is the clean v0.12.0+ rebuild (session-end-50 redeploy).

## Paste-into-fresh-session prompt

```
Context: session 51 of the GHC darwin8-ppc project found the
TRUE MINIMAL REPRO of the 32-session-old "compiler produces
empty .o" bug.

THE BUG (3 lines):
  arr <- newArray (0, 7) False :: ST s (STUArray s Int Bool)
  bools <- mapM (readArray arr) [0..7]
  -- expected: [False]*8
  -- actual on pmacg5: random True bits in 84% of iterations

This is independent of `Data.Graph.scc`, of GHC's compiler,
of `-A1m -G1`.  It fires under DEFAULT RTS on PPC32 unreg.
Pipeline chain S42-S51: simplTopBinds=0-1 → core2core=1-3 →
deSugar=3-6 → hsc_typecheck=3-5 → tcRnSrcDecls=2-5 →
tcTopBinds=2-3 → scc forest_len=0-3 → STUArray Bool corrupted.

Standalone test in
docs/sessions/2026-05-15-session-51-isolate-scc/stuarray_test.hs
reproduces 84-87% bad rate, no GHC rebuild needed.

v0.12.0 ships unchanged.  Source tree clean.  Stage2 on pmacg5
rebuilt+redeployed clean.  Baseline tests 30 PASS, 4
FAIL_OUTPUT.

Read in order:
1. docs/sessions/2026-05-15-session-51-isolate-scc/HANDOFF.md
2. docs/sessions/2026-05-15-session-51-isolate-scc/README.md
3. docs/sessions/2026-05-15-session-51-isolate-scc/findings.md
4. docs/sessions/2026-05-15-session-51-isolate-scc/stuarray_test.hs

Top priority: confirm bug scope.  Test STUArray Int8, Word8,
Int, Word, Char.  Test boxed STArray.  Test pinned arrays.  Test
without burnGC (no GC pressure).  This will tell us whether the
bug is in newArray's zeroing or in GC scavenge.  Then read
rts/PrimOps.cmm for stg_newByteArrayzh on PPC32 unreg.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide

When session 52 ends, write the next handoff at:
`docs/sessions/<DATE>-session-52-<slug>/HANDOFF.md`.
