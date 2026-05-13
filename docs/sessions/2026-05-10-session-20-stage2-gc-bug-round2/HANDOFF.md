# Handoff from session 20 → session 21

**For:** the next claude session.
**From:** session 20 (stage2 GC bug, round 2; 2026-05-10).
**Recommended pickup:** find WHY GHC's cross-codegen produces wrong
stack-frame bitmaps on PPC32, and fix it.

## TL;DR

- v0.12.0 still ships unchanged.  Stage2 still uses `-A1G`
  workaround.
- Bug **proximate cause found**: the typechecker's stack contains
  ~184 slots whose enclosing stack-frame bitmaps mark them as
  non-pointer, but the slots actually hold real heap pointers.
  GC dutifully skips, pointers go stale post-GC, typechecker
  reads garbage when accessing those slots later, panic.
- Affects 14+ distinct info tables across 6+ Haskell modules
  (Data.Map.Strict.Internal, Control.Monad.Catch, GHC.Iface.Binary,
  GHC.Base, GHC.List, Data.Map.Internal …).  Systematic bug, not
  per-module.
- **Why** the bitmaps are wrong is unknown.  Most likely candidate:
  GHC's StgToCmm liveness analysis on host-arm64 → target-PPC32
  cross-build is doing something wrong with 32-bit-target slot
  layout.

## Read in order

1. **This file** (the handoff).
2. [`README.md`](README.md) — what session 20 actually did.
3. [`findings.md`](findings.md) — the data + the deductions, in
   detail.  Especially the "Why is the bitmap wrong?" hypothesis
   list and the affected-modules table.
4. (Reference) [`probe20-21-stack-walk.patch`](probe20-21-stack-walk.patch)
   — re-apply this if you want to re-run any of the probes.

## What to NOT redo

- Don't re-disassemble Storage.o for `r.rCurrentNursery` /
  `r.rCurrentAlloc` offsets — they match DerivedConstants.h.
  Sister project's BUG-010 fix is in effect.
- Don't re-run PROBE20.A (per-GC counts) without modifying it.
  The numbers are 4779/4564 = 215 stale words across 25 GCs,
  bit-for-bit deterministic across iter1/2/3.
- Don't re-run PROBE21 with same questions.  100% of BAD slots
  are `is_ptr=0` per the bitmap; bug is in the bitmap, not in
  the GC walker.
- Don't pursue the "missed root in non-heap state" framing from
  session-19 HANDOFF in any form except "wrong bitmap".  The
  session-19 framing was correct in identifying *where* (running
  TSO stack) but wrong about *why* (it's not StgRegTable
  offset).

## What to try next, in priority order

### Top: identify which Haskell-source-level construct produces a wrong bitmap

The ~184 BAD slots come from 14 distinct info-table addresses
(see [`findings.md`](findings.md) "Affected info tables span
multiple modules" table).  Pick ONE — say, `_c8m6_info` at
0x9186474 in Data.Map.Strict.Internal — and identify:

1. **The Haskell function that produced this info table.**  The
   local label `_c8m6_info` doesn't trivially map back.  Approaches:
   - Use `objdump --line-numbers` on the binary (if DWARF info
     is present).
   - Re-cross-build Data.Map.Strict.Internal with `-ddump-cmm
     -ddump-stg-final` and grep the output for `c8m6`.  Cmm dumps
     identify info tables by label.
   - Use `addr2line` if line tables are available.

2. **The bitmap GHC emitted vs the bitmap that's correct.**
   Once we know the function, we can read the Cmm and check what
   liveness should be at this RET point.  The current bitmap
   (e.g., 0x3e89 = size=9, bits=0x1f4 = "slots 5,7 non-ptr") is
   wrong; the correct bitmap presumably says slots 5,7 ARE
   pointers.

3. **Compare with HOST GHC's bitmap for the same source.**
   If host arm64 ghc compiles the same module and produces a
   DIFFERENT (correct) bitmap, the bug is in the cross-codegen
   path.  If host produces the same wrong bitmap, the bug is
   higher up (in source / type system).

### Second: bisect StgToCmm for cross-build vs native

GHC.StgToCmm.Layout / GHC.Cmm.Info are where stack-frame liveness
gets computed and emitted.  Look for any place that uses HOST
word size instead of TARGET word size during analysis or
emission.  Search hot files:

- `compiler/GHC/Cmm/Info.hs` (mkLivenessBits)
- `compiler/GHC/Data/Bitmap.hs` (mkBitmap, intsToReverseBitmap)
- `compiler/GHC/StgToCmm/Layout.hs` (mkVirtHeapOffsetsWithPadding,
  similar)
- `compiler/GHC/StgToCmm/Bind.hs` (where stack-frame layout for
  case continuations gets decided)

Hint: the bug skews to `payload[1]` (slot 1 of frame) — 96 of
184 BADs are at pay=1.  That's a strong fingerprint.

### Third: check 64-bit-value slots on 32-bit target

A specific hypothesis worth testing: **GHC's bitmap correctly
marks Int64#/Word64#/Double# slots as non-pointer, but on PPC32
those values occupy 2 machine words while the bitmap reserves
only 1 bit.**  If subsequent slots are mis-counted, pointer
slots could end up at "non-pointer" bit positions.

Test: find a BAD frame whose corresponding Haskell function uses
Int64# / Word64# / Double#.  If the bug correlates with these,
that's the mechanism.  Data.Map.Strict.Internal uses Int as
size hints — Int# on PPC32 is 1 word, but Int64# (if used
internally) would be 2.

### Fourth: examine Stg → Cmm conversion for `case Int# of`

If GHC sees `case (forced :: Int#) of i -> body` and emits a
case continuation, the saved value `i` is an Int# (non-pointer).
But what if `forced` was actually obtained by `unsafeCoerce#`
from a pointer type, so the runtime value is a pointer?  GHC's
bitmap would say "non-pointer" (correct per the type), but the
slot is a pointer.

Look in the typechecker for `unsafeCoerce#`/`unsafeCoerceUnlifted`
of pointers to Int.  That'd be the source.

## Mechanics — how the dev loop works

Same as session 19/20.  See [README.md](README.md) "Step 1-5" for
patterns.  Quick reference:

### Edit RTS source

```
external/ghc-modern/ghc-9.2.8/rts/sm/{GC.c,Sanity.c,Scav.c,Evac.c}
```

Tree is gitignored, revert via `git -C external/ghc-modern checkout
-- ...` if needed.

### Apply session-20 probe patch

```
cd external/ghc-modern/ghc-9.2.8 && \
    patch -p1 < ../../../docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/probe20-21-stack-walk.patch
```

### Rebuild RTS only (~5 sec)

```
cd external/ghc-modern/ghc-9.2.8
rm -f _build/stage1/rts/build/c/sm/GC.o \
      _build/stage1/rts/build/c/sm/GC.debug_o \
      _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a \
      _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
source ../../../scripts/cross-env.sh >/dev/null 2>&1
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
```

### Cross-link + deploy debug stage2 (~15-20 min)

```
bash scripts/exp-deploy-stage2-debug.sh pmacg5
```

### Run probe

```
bash scripts/exp-stage2-probe20.sh pmacg5
```

Edits its `run_one` calls to taste.  Logs to `logs/`.

## Hosts (unchanged)

- **uranium** (this Mac): host for cross-build, RTS edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  ssh works without password.  This is where the bug fires.
- **imacg3**: smaller-RAM PPC G3, available if you want to test
  under more memory pressure.
- **indium**: trimmed dev tools — don't use for clang or hadrian
  builds (no Xcode).

## What's clean / dirty in the source tree

- `rts/sm/GC.c` — reverted to baseline (PROBE20/21 instrumentation
  removed at session-20 close).
- `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2*.a`
  — rebuilt clean, no PROBE20/21.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` — **removed at
  session-20 close** to avoid confusing the next session.
  Re-create it via `bash scripts/exp-deploy-stage2-debug.sh pmacg5`
  when needed.
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — unchanged
  (production stage2 with the `-A1G` wrapper, working).

## Time estimate for session 21

- Setup + read handoff: 15 min.
- Map a single BAD info table to Haskell function: 1-2 hours
  (requires recompiling Data.Map.Strict.Internal with `-ddump-cmm`
  and matching label).
- Compare host vs cross-build bitmap for that function: 2-4 hours
  (involves rebuilding stage1 with cmm dumps enabled, or
  cross-comparing artifacts).
- If we identify a Cmm/StgToCmm fixpoint: another 1-2 hours to
  craft a fix patch.
- If we identify the issue is in pre-Cmm (Stg or Core): more
  involved, multi-session.

Realistic: 1 session to find which Cmm function produces the
wrong bitmap.  Then session 22 onward to fix.

## Paste-into-fresh-session prompt

```
Context: just finished session 20 (stage2 GC bug round 2).
Bug's proximate cause is now known: ~184 stack-slot positions in
the typechecker's frames have bitmaps that mark them as non-pointer
but actually contain real heap pointers.  GC dutifully skips, they
go stale, typechecker panics.  Affects 14+ info tables across 6+
modules (Data.Map.Strict.Internal, Control.Monad.Catch, GHC.Iface.
Binary, GHC.Base, GHC.List, Data.Map.Internal).  Systematic bug
in cross-codegen for PPC32 — not per-module.

Read in order:
1. docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/HANDOFF.md
2. docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/findings.md
3. docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/README.md

Then start with the top candidate: identify the Haskell-source
construct that produces info table 0x9186474 (in Data.Map.Strict.
Internal) and 0x9143d50 (in Control.Monad.Catch).  Both have BAD
slot at pay=1.  Approaches: re-cross-build the modules with
-ddump-cmm -ddump-stg-final, grep the output for the local labels.
Or use objdump/addr2line if DWARF is available.

Once we know the Haskell source, compare host vs cross-build Cmm
output to see where the bitmap diverges.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's `-A1G` wrapper.

Unsupervised mode is project default.
```
