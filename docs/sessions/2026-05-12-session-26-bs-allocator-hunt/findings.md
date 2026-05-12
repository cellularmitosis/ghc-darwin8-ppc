# Session 26 findings — PROBE26 = ForeignPtrContents classifier in mkFastStringByteString

## TL;DR

- **PROBE26 saw 150 BS-into-`mkFastStringByteString` events
  across 3 runs of M5.hs `+RTS -A1m`.  100% are `PlainPtr+pinned`.
  Zero `*+UNPINNED`.**  All BSes flowing into `mkFastStringByteString`
  during M5.hs's compile have a properly pinned underlying
  `MutableByteArray#` per `isMutableByteArrayPinned#`.
- **The instrumentation prevents the SIGSEGV in M5.hs.**  Without
  PROBE26: 5/5 SIGSEGV.  With PROBE26: 0/3 (M5.hs) / 0/10 (M5plus.hs)
  / 0/10 (Big.hs) plus 1/16 panic (M5plus.hs first run, GHC
  `refineFromInScope` panic, classic session-17 GC-corruption signature).
- **The bug is timing-/codegen-sensitive, not BS-pinning-specific.**
  Adding the probe perturbs `mkFastStringByteString`'s Cmm enough
  that the SIGSEGV doesn't fire on small inputs, but the underlying
  GC corruption still occasionally surfaces as a panic on slightly
  larger inputs.
- **Hypothesis (a) from session 25 ("BS reaches `mkFastStringByteString`
  with non-pinned MBA") is rejected** by direct observation.  Sessions
  19–25's framing of the bug as a BS-pinning-invariant violation does
  NOT survive PROBE26's data.
- **Sessions 23–25's PROBE22POISON / PROBE23 read-after-poison
  crash signature is now best read as a probe artefact**: the slot
  at `Sp+12` of `_blk_c7te` may be classified as the BS's `Addr#`
  by static analysis of the Cmm (session 24), but its actual run-
  time value at any given GC point may be something the probes
  inadvertently stomped that the program then reads.  The original
  session-17 GC-corruption bug is the underlying problem; PROBE22's
  crash was an additional symptom of the probe colliding with
  whatever the real corruption is.

## What we audited (read-only, before instrumenting)

### BS producer set

Every public BS producer in `libraries/bytestring` and the GHC
compiler that flows into `mkFastStringByteString` was traced to its
allocation primitive:

| Producer                                          | Backing constructor       | Pinned? |
|---------------------------------------------------|---------------------------|---------|
| `Data.ByteString.Internal.Type.createFp`         | `MallocPtr` (via `mallocPlainForeignPtrBytes`) | ✅ pinned |
| `unsafeCreateFp`, `BS.create`, `createUptoN`     | (same path)               | ✅ pinned |
| `BS.append`, `BS.concat`                          | (same path)               | ✅ pinned |
| `Char8.pack`, `packChars`, `packBytes`           | (same path)               | ✅ pinned |
| `hGet`, `hGetSome`, `hGetNonBlocking`             | (same path)               | ✅ pinned |
| `getBS` (binary deserialization)                  | (same path)               | ✅ pinned |
| `BS.unsafeTake`, `BS.unsafeDrop`                  | shares parent `fp`        | (= parent) |
| `unsafePackAddress`, `unsafePackLiteral`          | `FinalPtr`                | ✅ static (immovable) |
| `Data.ByteString.Short.Internal.fromShort`       | `PlainPtr` (fast path) or `MallocPtr` (slow path via `fromShortIO`) | ⚠️ depends on `isByteArrayPinned#` returning correctly |
| `binary`'s `getByteString n = readN n (B.unsafeTake n)` | shares `Get`'s input chunk | (= parent BS chunk) |

So `mallocPlainForeignPtrBytes` (in `libraries/base/GHC/ForeignPtr.hs`)
is the workhorse: it calls `newPinnedByteArray# size`, which in
`rts/PrimOps.cmm::stg_newPinnedByteArrayzh` calls
`allocatePinned()` in `rts/sm/Storage.c`.  `allocatePinned`
unconditionally tags the block with
`BF_PINNED | BF_LARGE | BF_EVACUATED` (line 1338 for fresh blocks,
or inherits from a re-used `cap->pinned_object_block`).  If
`newPinnedByteArray#` works as advertised on PPC32, every standard
BS producer is pinned-backed.

The only path that can produce a non-pinned-backed BS is
`Short.fromShort`'s fast path with a buggy `isByteArrayPinned#`
result, OR a hand-rolled BS constructor in some upstream consumer
that the audit missed.

### Re-examination of session 25's `pinned_skip = 0`

PROBE23's filter is:
```c
if (bd->flags & BF_EVACUATED) { n_evac_skip++; continue; }
if (bd->flags & BF_PINNED)    { n_pinned_skip++; ...; continue; }
```

Pinned blocks are tagged `BF_PINNED | BF_LARGE | BF_EVACUATED` at
allocation (`rts/sm/Storage.c::allocatePinned`).  They hit the FIRST
branch (`BF_EVACUATED`) and get counted as `evac_skip`, not
`pinned_skip`.  Session 25's `pinned_skip = 0` therefore does NOT
mean "no pinned-backed slots" — it means "no slots whose Bdescr
flags have BF_PINNED set BUT NOT BF_EVACUATED," which is empty by
construction.  The probe's discrimination between "pinned" and
"evacuated" is a phantom distinction.

Session 25's main conclusion (hypothesis (a) supported, (b2) rejected
via crash continuing) was already reframed by PROBE26 — see below.

## PROBE26 results

### Per-iteration data

```
==> iter1-A1G  (+RTS -A1G -RTS)
    GHC_EXIT=0   PROBE26 lines: 50   UNPINNED: 0   PlainPtr: 50

==> iter2-A1m  (+RTS -A1m -RTS)
    GHC_EXIT=0   PROBE26 lines: 50   UNPINNED: 0   PlainPtr: 50

==> iter3-A1m  (+RTS -A1m -RTS)
    GHC_EXIT=0   PROBE26 lines: 50   UNPINNED: 0   PlainPtr: 50

==> Tag histogram (across all iters, all visible calls):
 150 PlainPtr+pinned
   0 (any other tag)
```

The lengths of the BSes are all 9–25 bytes — small FastStrings, almost
certainly the names and unique IDs that the typechecker constructs
when reading the Prelude/base interface files.

(50 is the cap on the per-call print; UNPINNED would be printed
forever past 50 with no cap.  Zero UNPINNED appeared — so even past
the cap, no UNPINNED case was ever observed.)

### Reproducibility under PROBE26

| Input        | Iters | RC=0 | RC≠0 |
|--------------|-------|-----:|-----:|
| M5.hs `-A1G` | 1     |    1 |    0 |
| M5.hs `-A1m` | 2     |    2 |    0 |
| M5plus.hs `-A1m` (cold first run, after Hello.hs leftover) | 1 | 0 | 1 (panic: refineFromInScope) |
| M5plus.hs `-A1m` (re-runs)            | 15 | 15 | 0 |
| Big.hs `-A1m`                         | 10 | 10 | 0 |

So PROBE26 dramatically reduces the bug's manifestation rate but
does NOT eliminate it.  The single panic on the first cold M5plus.hs
run is the smoking gun that the bug is still present — it just
doesn't fire on M5.hs anymore.

### Clarification: "5/5 SIGSEGV" was a probe-specific signature

After reverting PROBE26 and rebuilding/redeploying clean stage2,
M5.hs `+RTS -A1m` was re-run 5 times to verify the bug came back:

| Iter | RC | Symptom                                              |
|-----:|---:|------------------------------------------------------|
|    1 |  1 | panic: depSortStgBinds Found cyclic SCC              |
|    2 |  1 | panic: depSortStgBinds Found cyclic SCC              |
|    3 |  0 | success                                               |
|    4 |  1 | panic: depSortStgBinds Found cyclic SCC              |
|    5 |  1 | panic: refineFromInScope                              |

Result: **4/5 panic, 1/5 success.  No SIGSEGV.**  This matches
session 17's panic catalogue (depSortStgBinds, refineFromInScope,
"variable not found", etc.).

So the "5/5 SIGSEGV at `_blk_c7te + 112` with `0xdeadbeef`" pattern
that sessions 23–25 reported was a **PROBE22POISON / PROBE23 signature**
(the probe filled stack slots with `0xdeadbeef`, the program then
read one and SIGSEGV'd).  Without the probe, the underlying GC
corruption surfaces as panics, not SIGSEGVs.  This further weakens
the idea that "the bug is the BS Addr# at Sp+12 going stale" — the
production crash is a different kind of corruption, and Sp+12's
relevance was inferred from the probe's poison signature, not from
the production behaviour.

### Why does PROBE26 reduce the crash rate?

The probe adds a pattern-match on the BS's
`(ForeignPtr addr contents) len` shape and a strict bind to `tag`
and `len`, immediately before the existing `SBS.toShort bs`.  This
forces an early scrutinee on `bs` that the original code only does
later (inside `toShortIO`'s pattern match).  The Cmm of
`mkFastStringByteString` is therefore restructured:

- The `_blk_c7te`-shaped frame (StackRep `[False, True, True]` with
  Sp+12 = Addr# of BS) was generated because `toShortIO` lazily
  scrutinised the BS *between* extracting `len` (passed to
  `newByteArray#`) and the Sp+12 spill of the Addr#.  With PROBE26
  forcing the scrutinee earlier, the layout of the stack frame at
  the GC point changes — Sp+12 may not contain the Addr# anymore,
  may be in a register, may not be spilled at all, etc.

We didn't run `-ddump-cmm-sp` on the PROBE26 binary to confirm; it
would be the next decisive test if we wanted to characterise the
perturbation precisely.

## Cumulative reading of sessions 17–26

| Session | Hypothesis                                                   | Outcome |
|---------|--------------------------------------------------------------|---------|
| 17      | "stage2 native ghc has a GC bug"                            | Confirmed: panics, "variable not found", SIGSEGV on inputs > some size; `+RTS -A1G` workaround. |
| 19      | "SMP atomics / large_alloc_lim / CAF-list truncation"       | All ruled out.  Corruption is in non-heap state. |
| 20      | "stack-frame bitmaps are wrong on PPC32"                    | PROBE21 finds 184 stranded heap-shaped slots. |
| 21      | "bitmap encoding step is wrong"                             | Disproved.  Cmm-side and runtime-side `BITMAP_BITS_SHIFT` agree. |
| 22      | "`stackMapToLiveness` or upstream is wrong, for Catch.hs"   | Disproved.  All True-marked Catch.hs slots are dead. |
| 23      | "another module's bitmap; PROBE22POISON will find it"       | Found 1/9 read-after-poison events — in FastString. |
| 24      | "that 1 read is into a slot whose StackRep is wrong"        | Disproved.  Slot is an `Addr#`, correctly typed non-pointer. |
| 25      | "PROBE22POISON itself is the bug (pinned-Addr# false positive)" | "Disproved" via crash continuing + `pinned_skip = 0`.  But session 26 corrects the `pinned_skip` reading and reframes. |
| **26**  | **"BS reaches `mkFastStringByteString` with non-pinned MBA"** | **Disproved.  100% PlainPtr-pinned across all observed calls; PROBE26 perturbs the bug away on M5.hs.  The bug is real but not at the BS-pinning level.** |

After session 26, the strongest hypothesis is:

> The session-17 GC-corruption bug is real but its proximate cause
> is NOT a BS-pinning-invariant violation.  Sessions 22–25's
> instrumentation collided with whatever the real corruption is, and
> PROBE22POISON's `_blk_c7te+112` SIGSEGV signature was a probe-
> artefact composite of the underlying corruption + the probe's own
> stomp.  We do not currently have a confirmed proximate cause.
> The bug is timing-/codegen-sensitive.

## What's next, regardless of outcome

Suggested directions for session 27:

1. **Re-bisect the workload.**  PROBE26's "1/16 panic" is the only
   surviving data point that the bug exists.  Without M5.hs as a
   reliable repro, we need a new repro: maybe Big.hs run hundreds
   of times, or stage2 compiling itself, or Hadrian running cabal
   builds.  Without a deterministic repro, every probe is a guess.
2. **Try a less-perturbing probe.**  An RTS-side counter (read in
   `GarbageCollect()` from a Cap field) instead of a Haskell-side
   `unsafePerformIO + IORef` would minimise codegen impact on
   `mkFastStringByteString`.
3. **Read `_blk_c7te`'s assembly under PROBE26** to confirm the
   layout changed (Sp+12 no longer holds the Addr#, etc.).  This
   formalises the perturbation observation.
4. **Audit the destination side**: in `toShortIO`, the
   `newByteArray# len` allocates an *unpinned* MBA `dst`.  After
   `unsafeFreezeByteArray# dst`, this MBA backs the new SBS.  If
   anything reads from `dst` after the freeze but before GC moves
   it (e.g., another GC root holding the *Addr#* derived from
   `byteArrayContents# dst` somewhere), that's a stale-pointer
   bug — but on the destination MBA, not the source BS.
5. **Cross-host comparison**: build host ghc-9.2.8 with the same
   PROBE26 patch on uranium (arm64), run the same M5.hs.  If
   PROBE26 tags differ between host and PPC32 cross, that's a
   PPC-specific data point.  (Host is well-tested, expected to be
   100% pinned too — but worth confirming.)
6. **Move further upstream**: the corruption may not be in
   `mkFastStringByteString` at all.  Consider PROBE-21's 184
   "stranded heap-shaped slots" across other modules; maybe the
   real bug is in one of them and our focus on FastString was
   misled by PROBE22POISON's first-poison-stomps-and-bugs-out
   behaviour.

## Methodology / files added this session

- [`probe26-classify-bs.patch`](probe26-classify-bs.patch) — the
  ghc-compiler patch (~50 lines) that classifies the
  `ForeignPtrContents` of every BS at `mkFastStringByteString`.
- [`scripts/run-probe26.sh`](scripts/run-probe26.sh) — adapted from
  session 25.  Counts PROBE26 / UNPINNED lines and prints histogram.
- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — writeup.
- Logs at [`../../../log/session26/`](../../../log/session26/)
  (gitignored) capture the PROBE26 runs, plus the M5plus.hs panic
  and Big.hs reruns.
