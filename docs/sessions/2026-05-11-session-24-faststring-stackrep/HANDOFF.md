# Handoff from session 24 → session 25

**For:** the next claude session.
**From:** session 24 (stage2 GC bug round 6; the StackRep is correct;
the bug is upstream of LayoutStack; 2026-05-11).
**Recommended pickup:** patch PROBE22POISON to skip `BF_PINNED`
blocks (call it **PROBE23**), redeploy stage2 to pmacg5, re-run the
5×iteration M5.hs harness under `+RTS -A1m -RTS`, decide between
"real upstream invariant violation" vs "PROBE22POISON false positive
all along."

## TL;DR (mandatory read)

- Session 23 said: "the bug is a bitmap in some FastString frame's
  StackRep."  Session 24 read the actual StackRep: `[False, True,
  True]`.  Slot 2 (Sp + 12) is correctly `True` (non-pointer)
  because the value being stored is an **`Addr#`** — the second
  unboxed field of a `Data.ByteString.Internal.Type.BS` constructor.
- An `Addr#` is **supposed** to be stable across GC because BS's
  invariants require the underlying `ForeignPtrContents` to wrap a
  **pinned** `MutableByteArray#`.
- PROBE22POISON's per-slot log reports `bd_flags=0x0` for the stomped
  block — no `BF_PINNED`, no `BF_EVACUATED`.  Either (a) the
  invariant was violated (some BS reaches FastString with a
  non-pinned underlying byte array), or (b) PROBE22POISON had a
  false-positive class we missed (e.g., pinned blocks transiently
  lose `BF_PINNED` mid-GC).
- **One probe distinguishes (a) from (b)**: PROBE23, which adds
  `&& !(bd->flags & BF_PINNED)` to the poison filter.
- v0.12.0 ships unchanged.  Stage2 on pmacg5 is unchanged
  (PROBE22POISON was reverted at the end of session 23).

## Read in order

1. **This file** (the handoff).
2. [`README.md`](README.md) — narrative of session 24.
3. [`findings.md`](findings.md) — measurement detail + StackRep
   interpretation.
4. [`excerpts/c7t9-c7te.cmm`](excerpts/c7t9-c7te.cmm) — the
   smoking-gun Cmm slice (info_tbls + body).
5. [`excerpts/mkFastStringByteString.stg`](excerpts/mkFastStringByteString.stg)
   — the STG that the Cmm came from.
6. (Reference) [Session 23 findings](../2026-05-10-session-23-stage2-poison-probe/findings.md)
   — PROBE22POISON results, slot/value correlations.
7. (Reference) `libraries/base/GHC/ForeignPtr.hs:85-165` — the
   `ForeignPtrContents` documentation that establishes the pinning
   invariant.

## What to NOT redo

- **Don't re-audit FastString.hs's StackRep.**  This session settled
  it: `[False, True, True]` is correct.  The Cmm IR types the slot
  as `I32`; the bitmap faithfully encodes it.
- **Don't pursue "find the wrong info table in another module."**
  Sessions 19–24 progressively eliminated bitmap misclassification
  as the bug.  Almost certainly nothing in PROBE21's 184 stranded-
  slots is a true bitmap bug.  Stop looking on the stack alone.
- **Don't poison without filtering pinned blocks.**  PROBE22POISON's
  one read-after-poison is plausibly a self-inflicted artefact; an
  unconditional poison can't tell that from a real bug.

## What to try next, in priority order

### Top: write PROBE23 (pin-aware poison)

The minimal diff to PROBE22POISON's loop body:

```c
if (bd && !(bd->flags & BF_EVACUATED) && !(bd->flags & BF_PINNED)) {
    fprintf(stderr,
            "PROBE23POISON gc_no=%u slot=%ld old=0x%08lx "
            "bd_gen=%u bd_flags=0x%lx\n",
            probe23_gc_no, ...);
    *p = (StgWord)0xDEADBEEF;
    n_poisoned++;
}
```

Plus a second pass that *just logs* (no poison) the pinned-block-
addresses-on-stack so we can quantify "how many Addr#'s into pinned
memory are live on the typechecker's stack at gc_no=2."  That's
PROBE22POISON's denominator if (b) is right.

Patch file goes to
`docs/sessions/2026-05-XX-session-25-pin-aware-poison/probe23-poison-stack.patch`
(adapt the date to actual session-25 date).

### Mechanics — full reproduction sequence

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 0. Confirm baseline still green
bash tests/run-tests.sh   # expect 30 PASS / 4 design diffs

# 1. Apply PROBE23 to rts/sm/GC.c.  Insertion point: same as PROBE22,
#    just before `resize_nursery();` in GarbageCollect().

# 2. RTS-only rebuild + redeploy
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a    # ~3 min
cd ../../..
bash scripts/deploy-stage2.sh pmacg5                                   # ~5 min

# 3. Run the same harness from session 23
bash docs/sessions/2026-05-10-session-23-stage2-poison-probe/scripts/run-poison.sh pmacg5
# 5×M5.hs under -A1m, plus controls.

# 4. Collect results
ssh pmacg5 'cat ~/Library/Logs/CrashReporter/ghc-real.crash.log' \
  > log/session25/ghc-real.crash.log
# Look for: did the 5/5 SIGSEGV pattern hold?  Or did it stop?

# 5. End-of-session ritual: revert GC.c, rebuild RTS, redeploy clean.
cd external/ghc-modern/ghc-9.2.8 && git checkout rts/sm/GC.c
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

### Interpreting the result

| Outcome under PROBE23           | Conclusion |
|---------------------------------|-----------|
| All 5/5 crash gone (exit 0)     | PROBE22POISON was the bug.  No real read-after-poison.  The 184 stranded slots in PROBE21 / PROBE22 are ALL false positives (pinned-Addr#s or dead heap-shapes).  Production GC crash is a different mechanism — back to looking at CAFs, info-tables, RTS scavenger state. |
| Crash still fires (5/5 SIGSEGV) | The BS really is non-pinned-backed.  Real bug.  Next: instrument BS allocator (e.g., add a `cap_check_pinned` print at the `BS` constructor site, or wrap `mallocByteString` to count callers) to find which caller of `mkFastStringByteString` produces a non-pinned-backed BS. |
| Crash fires sometimes (1–4/5)   | Mixed signal.  Investigate further — maybe PROBE22POISON had 1 real + N false positives. |

### Second-priority: confirm the StackRep reading on the host

The host (arm64 macOS) ghc 9.2.8 must emit a "comparable" Cmm for
the same source.  Either:
- It emits the same `[False, True, True]` StackRep (with appropriate
  64-bit word offsets), in which case the bug shape is portable and
  pinned memory really IS the only thing keeping it from firing on
  x86_64.
- It emits a different layout — e.g., the optimiser keeps Addr# in
  a register across the call, eliminating the spill — in which case
  the bug is PPC32-specific because of unregisterised codegen.

Cheap experiment: run the host `ghc` on the same FastString.hs with
`-ddump-cmm-sp -ddump-cmm-info -dno-suppress-uniques -O2 -c
-fno-asm-shortcutting`, diff the StackRep of the equivalent block,
note differences.  20 minutes.  Useful background for whichever
direction PROBE23 points.

### Third-priority: trace which BS the runtime actually has

If PROBE23 says "real bug, non-pinned BS," we need to find the
culprit.  Easiest path: patch the BS pattern site in the cross-built
RTS / library to print `bd->flags` for the underlying ForeignPtrContents
whenever a `case bs of BS ipv_l ipv_m ipv_n` runs in `mkFastStringByteString`.
That requires a Haskell-level print inside the hot loop — tricky.

Alternatively: add an RTS-level probe in `evacuate` that prints "I
just moved a non-pinned ByteArray# that has a finalizer/back-pointer
into a movable block; its old address was X" — then correlate X with
the post-GC stale addresses on the stack.

## Hosts (unchanged from sessions 22–23)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: trimmed dev tools — don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/rts/sm/GC.c` — clean (untouched
  this session).
- `external/ghc-modern/ghc-9.2.8/_build/stage1/compiler/build/GHC/Data/FastString.{o,hi}`
  — clean (script's EXIT trap restored).
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — clean (matches v0.12.0).
- New session log: `docs/sessions/2026-05-11-session-24-faststring-stackrep/`
  + cmm dumps gitignored at `log/session24/cross/`.

## Time estimate for session 25

- Setup + read handoff: 15 min.
- Apply PROBE23 + rebuild RTS + deploy: 15 min.
- Run + collect crash log: 5 min.
- Interpret: 15 min.
- Writeup: 30 min.

Realistic: 1 short session (~1.5 h) to settle the (a)-vs-(b)
question.  Then session 26 starts the right next thread, either
"find the BS invariant violator" or "look at non-stack GC roots."

## Paste-into-fresh-session prompt

```
Context: just finished session 24 (stage2 GC bug round 6; FastString
StackRep audit).  Session 23's read-after-poison crash at _blk_c7te +
112 is real but the slot it reads is correctly typed non-pointer in
the Cmm IR — it's an Addr# field of a Data.ByteString.Internal.Type.BS
constructor.  StackRep [False, True, True] is the right answer; the
bitmap is NOT misclassifying.

Two open hypotheses:
(a) Some BS reaching mkFastStringByteString is backed by a non-pinned
    MutableByteArray# (invariant violation); the Addr# is stale post-GC,
    real bug.
(b) PROBE22POISON has a false-positive class on pinned-memory Addr#s
    whose bdescr has neither BF_PINNED nor BF_EVACUATED at the moment
    PROBE22 runs.

Decisive test: PROBE23 = PROBE22POISON + `&& !(bd->flags & BF_PINNED)`.
If the crash disappears under PROBE23, (b) is correct and session
24's narrative reframes ALL of PROBE21 (sessions 20–22's "the bitmap
is wrong" hypothesis is false everywhere it was tested).
If the crash persists, (a) is correct and we go find the BS
invariant violator.

Read in order:
1. docs/sessions/2026-05-11-session-24-faststring-stackrep/HANDOFF.md
2. docs/sessions/2026-05-11-session-24-faststring-stackrep/README.md
3. docs/sessions/2026-05-11-session-24-faststring-stackrep/findings.md
4. docs/sessions/2026-05-11-session-24-faststring-stackrep/excerpts/c7t9-c7te.cmm

Then write PROBE23 (~10 line diff to rts/sm/GC.c), rebuild RTS,
deploy to pmacg5, re-run the session-23 5×iteration harness, classify.

Hosts: uranium builds, pmacg5 runs.  v0.12.0 stays shipped — don't
break stage2's -A1G wrapper.

Unsupervised mode is project default.
```
