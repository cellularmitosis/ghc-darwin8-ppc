# Handoff from session 21 → session 22

**For:** the next claude session.
**From:** session 21 (stage2 GC bug, round 3; 2026-05-10).
**Recommended pickup:** identify the StgToCmm / LayoutStack code
path that produces a `StackRep [False, True, False]` (PNP) frame
where the middle slot is **wrongly** marked non-pointer.

## TL;DR

- v0.12.0 still ships unchanged.  Stage2 still uses `-A1G`
  workaround.
- Bug **narrowed by another layer**: the bitmap-encoding step
  (`mkLivenessBits` in `compiler/GHC/Cmm/Info.hs`) is correct.
  The cross-built .o faithfully encodes whatever StackRep GHC's
  Cmm IR specifies.  9 `PN`/`PNP` info tables in cross-built
  Catch.o exactly match 9 `[F, T, F]` / `[F, T]` StackReps in
  the same module's `-ddump-cmm` output.
- Compile-time and runtime **agree** on
  `BITMAP_BITS_SHIFT = 5` for PPC32.  Earlier shift-mismatch
  hypothesis is **dead.**
- 93/106 of BAD pay=1 events trace to **just 4 info tables**
  with bitmap=0x42 (PN size 2) or 0x43 (PNP size 3) — middle
  slot always marked non-pointer.
- The bug therefore lives in `LayoutStack.hs::stackMapToLiveness`
  or earlier `StackMap` construction (StgToCmm pass): a saved
  pointer-typed register either doesn't make it into `sm_regs`,
  has wrong byte-offset, or has its `LocalReg` type misclassified
  so `isGcPtrType` returns False.

## Read in order

1. **This file** (the handoff).
2. [`README.md`](README.md) — narrative of session 21.
3. [`findings.md`](findings.md) — measurements, decoded bitmap
   structure, deduction chain.
4. [`scripts/decode-info-tables.py`](scripts/decode-info-tables.py)
   and
   [`scripts/correlate-probe21-bads.py`](scripts/correlate-probe21-bads.py)
   — reusable analysis tools.
5. (Reference) Session 20's
   [`probe20-21-stack-walk.patch`](../2026-05-10-session-20-stage2-gc-bug-round2/probe20-21-stack-walk.patch)
   if you want to re-run the runtime probes.

## What to NOT redo

- Don't re-decode bitmap word semantics.  PPC32 uses
  `BITMAP_BITS_SHIFT=5`, `BITMAP_SIZE_MASK=0x1F`.  bit i==1 →
  slot i is non-pointer.  The polarity in StackRep `[Bool]` is
  *True ⇔ non-pointer/dead* (per
  `compiler/GHC/StgToCmm/Types.hs:178`).
- Don't re-investigate `pc_BITMAP_BITS_SHIFT`: confirmed = 5 for
  the cross-build.
- Don't re-prove that the `_c8m6_info` style labels can't be
  re-derived by recompiling — GHC's unique-name supply is
  non-deterministic between compiles.  Use *structural* matching
  (search for size+bitmap or `[F,T,F]` pattern) instead.
- Don't pursue Word64#/Int64#/Double# misalignment as the
  primary hypothesis — the dominant fingerprint is **size-2/3**
  frames, way too small for Word64-caused slot drift.
- Don't try to use the host's PPC nm/otool from `/usr/bin` —
  use the cctools-port versions at
  `$HOME/.local/cctools-ppc/install/bin/powerpc-apple-darwin8-{nm,otool}`.

## What to try next, in priority order

### Top: identify the Cmm-level *value* being saved at slot 1

Pick one `block_cXXX_info` from
`log/session21/catch-cross/catch-O2.dump` whose StackRep is
`[False, True, False]`.  Then:

1. Look at the surrounding Cmm to find where Sp-relative writes
   put a value at the slot-1 position (i.e. `I32[Sp + 8] = ...`
   or `P32[Sp + 8] = ...` after `Sp = Sp - 12;`).  **What
   register or expression is written?**
2. Re-cross-build the same module with `-ddump-cmm-final` (the
   *post-LayoutStack* IR with concrete byte offsets) instead of
   `-ddump-cmm`.  That dump shows the actual Sp-relative writes
   inserted by the spilling pass.
3. If the value written is an R1 spill (the GHC pointer reg) or
   a `P32[…]` (32-bit pointer load), then the StackMap really
   should classify the slot as pointer.  That's a clear
   StgToCmm/LayoutStack bug.
4. If the value written is e.g. an `I32` literal or an arithmetic
   result, then the bug is upstream — STG itself thinks the
   value is non-pointer but at runtime a pointer ends up there
   via type erasure / coercion.

### Second: bisect `cmmLayoutStack` with a debug print

Add a temporary print in
`compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` that emits
the resulting Liveness alongside the contributing `sm_regs`
content.  Re-build stage1 (~17 min) and recompile Catch.hs
to collect the new dump.  For each `[F, T, F]` frame, look at
which LocalRegs are in scope — specifically check whether any
`LocalReg` of `gcWord` type maps to slot 1's byte offset.

If a pointer LocalReg IS at slot-1's offset but its type isn't
classified as `isGcPtrType` → bug in `localRegType`/CmmType
classification.

If no LocalReg covers slot 1 at all → bug in spill placement
(LayoutStack assigns a stack slot to a value but doesn't add it
to `sm_regs`).

### Third: cross-check with HOST GHC 9.2.8 on the same source

Compile Catch.hs with the bootstrap host GHC
(`~/.local/ghc-9.2.8/bin/ghc -O2 -ddump-cmm`) and count
`[F, T, F]` StackReps.  If host produces ZERO PNP frames but
cross-build produces 8, the bug is **target-platform-specific**
in StgToCmm / LayoutStack — strong narrowing.  If host produces
the same PNP count, the bug is in the *source* (something like
wrong INLINE behavior, type-class instance selection) and we
need to look at upstream STG.

### Fourth: examine the specific Haskell sources

`Control.Monad.Catch.uninterruptibleMask1` was named in session
20 as containing closures referenced by BAD slots.  Read that
function and identify whether it has any unusual constructs
(unsafeCoerce, foreign call returning a tagged pointer,
explicit type annotations that mention `IntPtr`/`Addr#`/etc.).

## Mechanics — how to reproduce session-21 results

### Decode bitmap words from a cross-built .o

```
cd /Users/cell/claude/ghc-darwin8-ppc
python3 docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/scripts/decode-info-tables.py \
    external/ghc-modern/ghc-9.2.8/_build/stage1/libraries/exceptions/build/Control/Monad/Catch.o \
    --filter-pnp
```

### Re-attribute PROBE21 BADs (uses session-20 logs)

```
python3 docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/scripts/correlate-probe21-bads.py \
    log/session20/probe20-iter1-vanilla-A1m.log 1
```

(Last arg = pay= filter; omit for all pays.)

### Cross-compile a single library module with -ddump-cmm

```
cd /Users/cell/claude/ghc-darwin8-ppc
PPC_GHC=$PWD/external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc
SRC=$PWD/external/ghc-modern/ghc-9.2.8/libraries/exceptions/src
mkdir -p log/session22/cross
cd log/session22/cross
$PPC_GHC --make -c -O2 \
    -ddump-cmm -ddump-cmm-final -ddump-stg-final \
    -outputdir . -odir . -hidir . \
    -i$SRC -hide-package exceptions \
    $SRC/Control/Monad/Catch.hs > catch-O2.dump 2>&1
```

(For other modules, swap in the appropriate `-i` and source path.
Containers' Internal.hs needs `-I$INC` for `containers.h` —
see session-21's actual invocation.)

### Build a debug stage1 and rerun

If you need to instrument the GHC compiler itself (e.g., add a
debug print to LayoutStack.hs):

```
cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null 2>&1
# edit compiler/GHC/Cmm/LayoutStack.hs
./hadrian/build --flavour=quick-cross -j8 _build/stage1/bin/powerpc-apple-darwin8-ghc
# ~12-15 min for incremental compiler rebuild
```

The new stage1 ghc is in-place; re-run the cross-compile
recipe above to get fresh dumps that include your debug output.

## Hosts (unchanged from session 20)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  ssh works without password.  Where the bug fires.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: trimmed dev tools — don't use for clang or hadrian
  builds (no Xcode).

## What's clean / dirty in the source tree

- `compiler/GHC/Cmm/LayoutStack.hs`, `compiler/GHC/Cmm/Info.hs`,
  `compiler/GHC/StgToCmm/*` — **untouched** by session 21
  (read-only investigation).
- `external/ghc-modern/ghc-9.2.8/_build/stage1/...` — **unchanged**
  cross-built tree.  No probe / instrumentation patches applied.
- `log/session21/cmm-cross/` and `log/session21/catch-cross/`
  exist with cross-compile artifacts (~7 MB Cmm dumps).
  Both are gitignored.  Clean up with `rm -rf log/session21/{cmm,catch}-cross/`
  if needed.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` — **does not exist**
  (session 20 removed it on close; session 21 didn't recreate).
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — unchanged
  (production stage2 with `-A1G` wrapper).

## Time estimate for session 22

- Setup + read handoff: 15 min.
- Run -ddump-cmm-final on Catch.hs and trace one `[F, T, F]`
  frame's slot-1 write: 1-2 hours.
- Read upstream Cmm to identify the saved value: 30-60 min.
- Build a debug stage1 with print added to `stackMapToLiveness`:
  20 min build + 30 min interpretation.
- Compare host vs cross-build StackReps for same source: 1 hour.

Realistic: 1 session to pin down "what value is at slot 1" and
classify the bug as either (a) `LocalReg` type misclassification
(b) missing entry in `sm_regs` (c) STG-level pointer-erasure.
Subsequent session(s) for the actual fix.

## Paste-into-fresh-session prompt

```
Context: just finished session 21 (stage2 GC bug round 3).
Bug narrowed: bitmap-encoding step is correct (mkLivenessBits in
compiler/GHC/Cmm/Info.hs faithfully encodes whatever StackRep the
Cmm IR specifies).  Cross-built Catch.o has 9 PN/PNP info tables
matching exactly 9 [F,T,F]/[F,T] StackReps in the same module's
-ddump-cmm output.  Compile-time and runtime agree on
BITMAP_BITS_SHIFT=5 for PPC32 — host/target shift mismatch theory
disproved.  93/106 of BAD pay=1 events trace to just 4 info tables
of bitmap shape PN (size 2) or PNP (size 3) — middle slot wrongly
marked non-pointer.

Bug therefore lives in compiler/GHC/Cmm/LayoutStack.hs's
stackMapToLiveness or earlier StackMap construction (StgToCmm
pass).  A saved pointer-typed register isn't surviving as
isGcPtrType in sm_regs.

Read in order:
1. docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/HANDOFF.md
2. docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/findings.md
3. docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/README.md

Then start with the top experiment: pick a `block_cXXX_info`
from log/session21/catch-cross/catch-O2.dump with StackRep
[False, True, False], use `-ddump-cmm-final` to see what value
is being written to slot 1's Sp-relative address, and classify.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's `-A1G` wrapper.

Unsupervised mode is project default.
```
