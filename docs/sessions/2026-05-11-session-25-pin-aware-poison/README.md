# Session 25 — stage2 GC bug, round 7 (PROBE23 = pin-aware poison; rules out PROBE22 false-positive theory)

**Dates:** 2026-05-11.

**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on
Tiger uses the `+RTS -A1G` workaround.  Session 23 confirmed the bug
is real (5/5 deterministic SIGSEGV on `_blk_c7te + 112` reading
`MEM[Sp + 12] = 0xdeadbeef`).  Session 24 settled that the StackRep
of `_blk_c7te` is `[False, True, True]` and that this is **correct**
given the Cmm IR — the slot at Sp+12 is the `Addr#` field of an
unboxed `Data.ByteString.Internal.Type.BS`.  Two open hypotheses
going in:

(a) Real bug: some BS reaching `mkFastStringByteString` is
    backed by a non-pinned `MutableByteArray#`, so its `Addr#` is
    stale post-GC.

(b) Probe artefact: PROBE22POISON wrongly stomped a pinned-memory
    `Addr#` because pinned blocks transiently lose `BF_PINNED` (or
    were never tagged with it during this GC pass).

**Status on exit:** Hypothesis **(a) is supported, (b) is rejected
in its strong form.**  PROBE23 (= PROBE22POISON + `&& !(bd->flags &
BF_PINNED)` plus a no-poison `PROBE23PINNED` log of pinned-block
stack slots) ran 5×M5.hs under `+RTS -A1m`.  Result:

- 5/5 SIGSEGV at `_blk_c7te + 112` (exit 139), byte-identical
  crash signature to session 23's PROBE22POISON run.
- The smoking-gun slot at `gc_no=2 slot=6 old=0x0bf5f38a` is
  bit-identical to session 23's reading.
- **`pinned_skip = 0` across every GC of every iteration.**  No
  stack-resident value pointed into a `BF_PINNED` block during any
  of the 3 GCs of M5.hs's compile.

If (b)'s strong form had been right ("PROBE22 was wrongly stomping
pinned-Addr#s"), PROBE23 would have shown pinned_skip > 0 and the
crash would have stopped.  Neither happened.  A residual
hypothesis (b1) — "pinned blocks present `bd_flags=0` at this GC
point because BF_PINNED is transiently cleared" — remains formally
consistent with the data but requires unverified RTS behavior;
treating it as the explanation needs an `Evac.c`/`Scav.c` audit
session 25 does not do.

After session 25 the strongest hypothesis is:

> Some caller of `mkFastStringByteString` produces a `BS` whose
> `ForeignPtrContents` wraps a non-pinned `MutableByteArray#`,
> violating the pinning invariant documented at
> `libraries/base/GHC/ForeignPtr.hs:145`.  The `Addr#` field of
> that BS is spilled to Sp+12 across an `stg_newByteArray#`
> GC point inside the inlined `toShortIO` body.  After GC moves
> the underlying byte array, the `Addr#` on the stack is stale.
> The next `copyAddrToByteArray#` reads from a stale (in PROBE23,
> poisoned) address and crashes.

Sessions 19–25 collectively show: **the actual GC bug is not in
LayoutStack, not in `mkLivenessBits`, not in `stackMapToLiveness`,
not in any stack-frame bitmap PROBE21 looked at.**  It is upstream
of all of those — in the bytestring / FastString allocation
boundary.  Session 26's hunt is for the BS-allocator code path that
omits pinning.

v0.12.0 still ships unchanged.  Stage2 on pmacg5 was reverted to
clean RTS at session-25 end.

HANDOFF for session 26: see [`HANDOFF.md`](HANDOFF.md).  Top of
queue: instrument the BS pattern-match in `mkFastStringByteString`
(or `mkFastStringByteString`'s callers in the typechecker / lexer)
to print whether the underlying `ForeignPtrContents` is a
`PlainPtr` (unpinned) or one of the pinned variants
(`MallocPtr`/`PlainForeignPtr` / etc.).  Alternative path: read
the source of `Data.ByteString.Short.Internal.toShortIO` (and its
direct callers) and audit which ones do `mallocByteString` /
`mallocPlainForeignPtrBytes` (pinned) vs. `byteArrayContents# .
unsafeCoerce#` of an unpinned MBA.

## What we did, in order

### Step 1 — confirm baseline green

`tests/run-tests.sh`: 30 PASS, 4 expected design diffs (Int size,
getProgName, getpid, numeric boundaries).  Matches v0.12.0.

### Step 2 — write PROBE23

[`probe23-poison-stack.patch`](probe23-poison-stack.patch).  Two
changes vs. session 23's PROBE22POISON:

1. The poison filter gains `&& !(bd->flags & BF_PINNED)`.  Pinned
   blocks are skipped, not stomped.
2. A new `PROBE23PINNED` line logs every pinned-block-backed stack
   slot (no poison).  This is PROBE22's false-positive denominator
   under hypothesis (b2).

Insertion point: same as PROBE22POISON (just before
`resize_nursery();` in `GarbageCollect()`).

### Step 3 — apply, rebuild RTS, deploy

```
# from external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
# ~5 sec incremental (RTS only, all 12 ways).
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
# ~3 min for cross-link + scp + smoke test.
```

(The first incremental RTS rebuild is suspiciously fast (~5 s) but
verified by `ls _build/stage1/rts/build/c/sm/GC.*o`: all 12 ways of
`GC.o` are present and newer than `rts/sm/GC.c`.)

### Step 4 — run the harness

```
bash docs/sessions/2026-05-11-session-25-pin-aware-poison/scripts/run-poison.sh pmacg5
```

5×M5.hs under `+RTS -A1m`, 1×M5.hs under `+RTS -A1m -DS`, 1×M5.hs
under `+RTS -A1G`.  Captures PROBE23/POISON/PINNED counts and
GHC_EXIT.  ~30 sec total.

### Step 5 — collect crash log + classify

```
ssh -q pmacg5 'tail -200 ~/Library/Logs/CrashReporter/ghc-real.crash.log' \
    > logs/ghc-real.crash.log
```

All 3 most recent crash entries match PROBE22POISON's session-23
signature: `_blk_c7te + 112`, `r4=0xdeadbeef`, `r5=0x10`, in
`__memcpy + 80`.

Per-iteration data summary table — 5/5 SIGSEGV, 9 poisons each,
0 pinned-skip each.  See [`findings.md`](findings.md) for the full
per-GC breakdown.

### Step 6 — interpretation

The decision matrix from session-24 HANDOFF.md was binary:

- "5/5 crash gone" → (b) is right.
- "5/5 crash fires" → (a) is right.

We're in the second branch.  But the additional `pinned_skip = 0`
finding refines this: even a charitable reading of (b) — "PROBE was
stomping pinned-Addr#s" — is contradicted by the absence of any
pinned-block-backed stack slots.  See [`findings.md`](findings.md)
"Why '0 pinned-skip' is informative" for the full reasoning, including
the residual (b1) hypothesis we cannot fully rule out without an RTS
audit.

### Step 7 — end-of-session ritual

```
cd external/ghc-modern/ghc-9.2.8
git checkout rts/sm/GC.c
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Stage2 on pmacg5 back to clean RTS.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with `+RTS -A1G` wrapper,
  baseline test battery green.
- **No source-tree edits this session** persist.  GC.c is back to
  upstream `dfa83462`.
- **Stage2 ghc on pmacg5 is clean.**
- **Logs at** [`logs/`](logs/)
  capture the PROBE23 run + the crash log.
- **HANDOFF for session 26** scopes the BS-allocator hunt.

## Files added this session

- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — writeup.
- [`probe23-poison-stack.patch`](probe23-poison-stack.patch) — the
  RTS patch for the experiment (not committed to GHC tree; archived
  here for re-apply).
- [`scripts/run-poison.sh`](scripts/run-poison.sh) — harness adapted
  from session 23 to count PROBE23 fields.
