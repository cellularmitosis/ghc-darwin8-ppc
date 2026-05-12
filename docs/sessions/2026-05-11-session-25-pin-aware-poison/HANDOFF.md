# Handoff from session 25 → session 26

**For:** the next claude session.
**From:** session 25 (stage2 GC bug round 7; PROBE23 = pin-aware
poison; rules out the b2 false-positive theory; 2026-05-11).
**Recommended pickup:** find the BS-allocator code path that
produces a non-pinned-backed `BS` flowing into
`mkFastStringByteString`.

## TL;DR (mandatory read)

- PROBE23 (PROBE22POISON + `BF_PINNED` filter + a no-poison
  `PROBE23PINNED` log of pinned-block stack slots) ran on M5.hs
  under `+RTS -A1m`.  **5/5 SIGSEGV, byte-identical to PROBE22**:
  same crash slot (`gc_no=2 slot=6 old=0x0bf5f38a` at `_blk_c7te +
  112`), same `r4=0xdeadbeef`, same `r5=0x10`.
- **`pinned_skip = 0` across every GC of every iteration.**  No
  stack-resident value pointed into a `BF_PINNED` block during the
  3 GCs of M5.hs's compile.  211 heap-shaped stack words seen
  cumulatively; 0 pinned.
- Conclusion: hypothesis (a) "BS reaches `mkFastStringByteString`
  with a non-pinned underlying byte array" is supported.  Hypothesis
  (b2) "PROBE22POISON was wrongly stomping pinned-Addr#s" is
  rejected.  Residual (b1) "BF_PINNED transiently cleared during
  GC" remains formally open but is contrived; pursue (a) first.
- v0.12.0 ships unchanged.  Stage2 on pmacg5 was reverted to clean
  RTS at session-25 end.

## Read in order

1. **This file** (the handoff).
2. [`README.md`](README.md) — narrative of session 25.
3. [`findings.md`](findings.md) — measurement detail + decision
   matrix.
4. [`probe23-poison-stack.patch`](probe23-poison-stack.patch) — the
   exact RTS patch we ran.
5. (Reference) [Session 24 findings](../2026-05-11-session-24-faststring-stackrep/findings.md)
   — for the `_blk_c7te` Cmm reading and BS-field-layout arithmetic.
6. (Reference) `libraries/base/GHC/ForeignPtr.hs:85-165` — the
   `ForeignPtrContents` documentation that lists the pinned vs.
   unpinned variants and their pinning invariants.
7. (Reference) `libraries/bytestring/Data/ByteString/Internal/Type.hs`
   (and `mallocByteString`, `unsafePackAddress`, etc.) — the BS
   producer set we need to audit.

## What to NOT redo

- **Don't re-run PROBE22 or PROBE23 expecting different results.**
  Both are deterministic per session 23 / 25.  They've told us
  everything they can; we now need to see what's UPSTREAM, in
  Haskell-level code, not in the RTS.
- **Don't go back to LayoutStack / mkLivenessBits / stackMapToLiveness.**
  Sessions 21–24 settled them.  The bitmap is correct; the bug is
  not in stack-frame liveness analysis.
- **Don't audit Catch.hs.**  Session 22 already settled that.
- **Don't poison without filtering by something more specific than
  block flags.**  PROBE22 / PROBE23 have served their purpose.

## What to try next, in priority order

### Top: instrument the BS allocator surface

The simplest decisive test: print, for each `BS` constructor that
flows into `mkFastStringByteString`, the runtime tag of its
`ForeignPtrContents`.  If any of them is `PlainPtr` (the unpinned
variant), we've found the violator.

There are two ways to instrument this:

#### Option A — patch the Haskell-level pattern

Add a `Debug.Trace.traceShow`-equivalent inside
`mkFastStringByteString` (or its inlinee chain) right at the
`case bs of BS p contents l -> ...` site.  Print whether `contents`
is a `PlainPtr` MBA (unpinned) vs `MallocPtr` / `PlainForeignPtr`
(pinned).  The check is:

```haskell
import GHC.ForeignPtr (ForeignPtrContents(..))
import GHC.Exts (isMutableByteArrayPinned#, MutableByteArray#, RealWorld)
import GHC.IO (unsafePerformIO)

isPinnedFPC :: ForeignPtrContents -> Bool
isPinnedFPC (PlainPtr mba)            = isTrue# (isMutableByteArrayPinned# mba)
isPinnedFPC (MallocPtr _ _)           = True   -- always pinned
isPinnedFPC (PlainForeignPtr _)       = True   -- finalizer-bearing pinned MBA
isPinnedFPC (FinalPtr)                = True   -- static, always pinned
```

(The exact constructor names are 9.2.8-vintage; verify by reading
`libraries/base/GHC/ForeignPtr.hs`.)

Place the trace inside `mkFastStringByteString`'s body in
`compiler/GHC/Data/FastString.hs`.  Cross-compile, redeploy, run
M5.hs.  Look for the BSs that print "PlainPtr unpinned".

Caveats:
- Rebuilding stage1 ghc with a modified compiler library takes ~3–5
  min.  Then rebuild stage2 + deploy.
- `Debug.Trace` might already be in scope; if not, add
  `import Debug.Trace (trace)`.
- `isMutableByteArrayPinned#` may not be available on 9.2.8 — check
  `libraries/ghc-prim/GHC/Prim.hs`.  Fallback: lookup
  `byteArrayContents#` and check the underlying block via FFI to
  `lookupBdescr`.

#### Option B — instrument at the RTS level

Add a probe inside `stg_newByteArray#` (or `allocate`) that prints
the tag of every `MutableByteArray#` allocated with the FastString
caller's pc.  Or, more targeted: in `evacuate`, when moving a
`MUT_ARR_PTRS_FROZEN` / `ARR_WORDS` closure, print whether its
source block had `BF_PINNED` set; if not, print "moved a non-pinned
byte array."

This avoids touching Haskell source but is harder to attribute to
"this BS came from this Haskell call site."

**Recommend A first.**  It's slower per iteration but produces
attribution data the RTS-level probe can't.

### Second: read the BS allocator surface

Before instrumenting, just read these files cold and grep for
"newByteArray#" (unpinned) vs "newPinnedByteArray#" (pinned):

- `libraries/bytestring/Data/ByteString/Internal/Type.hs` — the BS
  type and its constructors.
- `libraries/bytestring/Data/ByteString/Internal.hs` —
  `mallocByteString`, `mallocPlainForeignPtrBytes`, `create`,
  `createUptoN`, `unsafePackAddress`, `packCString`, `pack`, etc.
- `libraries/bytestring/Data/ByteString/Short/Internal.hs` —
  `toShort`, `toShortIO`, `fromShort`.  `toShortIO` is what
  `mkFastStringByteString` inlines.
- `compiler/GHC/Data/FastString.hs::mkFastStringByteString` — the
  caller.

Map each BS-producer function to its pinning status.  Most are
pinned (designed-in invariant).  Find the ones that aren't.

The most likely suspects for non-pinned BS production:
- `unsafePackAddress` family — wraps a static C string, usually
  `FinalPtr` (pinned by definition) but could be `PlainPtr` if
  recently refactored.
- `pack` / `packBytes` — usually goes through `create` →
  `mallocByteString` (pinned), but check the implementation.
- Anything that goes through `Data.ByteString.Internal.fromForeignPtr`
  with a custom `ForeignPtrContents`.

Most importantly: **what calls `mkFastStringByteString`?**  Per
session 24's STG dump, the function inlines `toShortIO` from
`Data.ByteString.Short.Internal`.  But its callers are throughout
the typechecker / lexer.  Quick grep:

```
cd external/ghc-modern/ghc-9.2.8
grep -rn 'mkFastStringByteString\|mkFastString '\
   compiler/GHC/Data/FastString.hs compiler/GHC/Parser.y \
   compiler/GHC/Parser/Lexer.x compiler/GHC/Tc/ \
   compiler/GHC/Iface/ | head -30
```

The lexer's `cmtok` family (which produces FastString from a
ByteString slice) is a common hot path.

### Third: residual (b1) audit

If (a) stalls (i.e., we can't find any non-pinned BS producer), the
residual (b1) "BF_PINNED transiently cleared during GC" hypothesis
becomes worth testing.  Read `rts/sm/Evac.c` and `rts/sm/Scav.c`
for any code that touches `bd->flags &= ~BF_PINNED`.  Also check
`allocatePinned` and `pinned_object_blocks` handling.  ~30 min.

### Fourth: cross-compare host ghc 9.2.8

Suggested by session-24 HANDOFF.md as a side experiment but
deprioritized.  Worth doing if (a) still doesn't reveal a culprit:

```
ghc -ddump-cmm-sp -ddump-cmm-info -dno-suppress-uniques \
    -O2 -c -fno-asm-shortcutting compiler/GHC/Data/FastString.hs
```

Diff the StackRep of the equivalent block.  If the host emits a
different layout (e.g., the `Addr#` is kept in a register across
the GC point), the bug is PPC32-specific because of unregisterised
codegen.  20 min.

## Mechanics — how to reproduce session-25 results

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 0. Confirm baseline still green
bash tests/run-tests.sh   # expect 30 PASS / 4 design diffs

# 1. Apply PROBE23 to rts/sm/GC.c.
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-11-session-25-pin-aware-poison/probe23-poison-stack.patch

# 2. RTS-only rebuild
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a    # ~5 sec incremental

# 3. Deploy
cd ../../..
bash scripts/deploy-stage2.sh pmacg5                                  # ~3 min

# 4. Run harness
bash docs/sessions/2026-05-11-session-25-pin-aware-poison/scripts/run-poison.sh pmacg5
# 5×M5.hs under -A1m + 2 controls.

# 5. Pull crash log
ssh -q pmacg5 'tail -200 ~/Library/Logs/CrashReporter/ghc-real.crash.log' \
    > log/session25/ghc-real.crash.log

# 6. Revert + redeploy clean
cd external/ghc-modern/ghc-9.2.8
git checkout rts/sm/GC.c
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

## Hosts (unchanged from sessions 22–24)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: trimmed dev tools — don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/rts/sm/GC.c` — clean (revert
  applied at session-25 end).
- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSrts-1.0.2*.a`
  — clean RTS rebuilt + redeployed.
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — clean (matches v0.12.0).
- New session log: `docs/sessions/2026-05-11-session-25-pin-aware-poison/`
  + run logs gitignored at `log/session25/`.

## Time estimate for session 26

- Setup + read handoff: 15 min.
- Read BS-allocator source surface (option B above, no-instrumentation
  audit first): 30–60 min.
- If audit doesn't immediately localise the culprit, instrument
  `mkFastStringByteString`: cross-compile (3–5 min) + redeploy
  (3 min) + run (1 min) per iteration.  3–5 iterations likely.
- Writeup: 30 min.

Realistic: 1 medium session (~3–5 h) to identify the BS-producer
that violates the pinning invariant.  Then probably another short
session to write the fix (which is upstream of GHC — likely a
bytestring library bug or a compiler-internal misuse of the
bytestring API), and a third to verify the fix kills the GC crash
without `+RTS -A1G`.

If the BS-producer turns out to be GHC-internal (likely; the
bytestring library is widely used and well-tested elsewhere), the
fix is a 1-line patch.  If it's bytestring-library-side, we'd have
to vendor + patch bytestring (precedent: `vendor/network/`,
`vendor/HsOpenSSL/`).

## Paste-into-fresh-session prompt

```
Context: just finished session 25 (stage2 GC bug round 7; PROBE23 =
pin-aware poison).  PROBE23 = PROBE22POISON + `&& !(bd->flags &
BF_PINNED)` plus a no-poison PROBE23PINNED log of pinned-block stack
slots.  Result on M5.hs under +RTS -A1m: 5/5 SIGSEGV (byte-identical
to PROBE22POISON's session-23 run), with `pinned_skip = 0` across
every GC.  This rules out the strong form of "PROBE22POISON was
wrongly stomping pinned-Addr#s" — there were no pinned-block-backed
stack slots at all.  Conclusion: the BS reaching mkFastStringByteString
really is non-pinned-backed (hypothesis (a) from session-24 HANDOFF),
violating the BS pinning invariant documented at
libraries/base/GHC/ForeignPtr.hs:145.

Sessions 19–25 collectively settled that the bug is NOT in
LayoutStack, NOT in mkLivenessBits, NOT in stackMapToLiveness, NOT
in any stack-frame bitmap PROBE21 looked at.  The bug is upstream of
all of those.  It's in the BS-allocation pipeline — specifically,
some caller of mkFastStringByteString is producing a BS whose
ForeignPtrContents is a PlainPtr (unpinned MutableByteArray#) when
it should be one of the pinned variants.

Read in order:
1. docs/sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md
2. docs/sessions/2026-05-11-session-25-pin-aware-poison/README.md
3. docs/sessions/2026-05-11-session-25-pin-aware-poison/findings.md
4. (reference) libraries/base/GHC/ForeignPtr.hs:85-165 for the
   ForeignPtrContents variants and pinning invariants
5. (reference) libraries/bytestring/Data/ByteString/Internal/Type.hs
   for the BS constructor

Then either:
- Audit the bytestring producer functions for unpinned ByteArray#
  use, OR
- Instrument mkFastStringByteString to print the
  ForeignPtrContents tag for each BS that flows in (rebuild
  stage1, redeploy stage2, run M5.hs, look for "PlainPtr"
  output), OR
- Audit rts/sm/Evac.c / Scav.c for any BF_PINNED clearing — the
  residual (b1) hypothesis — to make sure (a) is the right path.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's -A1G wrapper.

Unsupervised mode is project default.
```
