# Session 26 — stage2 GC bug, round 8 (PROBE26 = ForeignPtrContents classifier; rejects hypothesis (a))

**Dates:** 2026-05-12.

**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native `ghc`
on Tiger uses the `+RTS -A1G` workaround.  Sessions 23–25 settled
that the production crash on M5.hs under `+RTS -A1m` reads a stale
`Addr#` from `Sp+12` of `_blk_c7te` in `GHC.Data.FastString`'s
`mkFastStringByteString` (the inlined `toShortIO` body that copies
BS bytes into a fresh ShortByteString).  The crashing slot is the
`Addr#` field of an unboxed BS that was spilled across the
`stg_newByteArray#` GC point.  Session 25's PROBE23 ruled out the
"stomping pinned-Addr# false positive" reading of PROBE22POISON via
the deterministic crash signature.  Strongest remaining hypothesis
going in: some BS reaching `mkFastStringByteString` is backed by a
non-pinned `MutableByteArray#`, in violation of the
`libraries/base/GHC/ForeignPtr.hs:145` invariant.

**Status on exit:** **Hypothesis (a) is REJECTED by direct
observation.**  PROBE26 instruments `mkFastStringByteString` to
classify the `ForeignPtrContents` of every BS that flows in (and
test pinning of the underlying MBA via `isMutableByteArrayPinned#`).
Across 3 runs of M5.hs `+RTS -A1m`, all 150 visible BSes are
**`PlainPtr+pinned`**.  Zero `*+UNPINNED` cases ever appeared.
Independently, the PROBE26 instrumentation also **prevents the
SIGSEGV** entirely on M5.hs (0/3 vs. session 23's 5/5), and
dramatically reduces it on slightly larger inputs (0/10 on Big.hs,
1/16 panic on M5plus.hs — first cold run only, 15/15 OK on warm
re-runs).

So:

- The instrumentation perturbs the Cmm of `mkFastStringByteString`
  enough that the M5.hs `_blk_c7te+112` SIGSEGV doesn't fire.  Likely
  cause: the early scrutinee on the BS forces fields to be in
  registers / spilled differently, so Sp+12 no longer holds the
  Addr# at the GC point.
- The underlying GC corruption is still present (1/16 panic on
  M5plus.hs).  PROBE26 doesn't fix the bug, just changes its
  manifestation.
- All BSes flowing through `mkFastStringByteString` during M5.hs
  compile have a properly pinned underlying MBA.  So whatever causes
  the corruption is NOT a non-pinned BS.

After session 26 the strongest hypothesis is:

> The session-17 GC-corruption bug is real but **not** a BS-pinning-
> invariant violation at `mkFastStringByteString`.  Sessions 23–25's
> PROBE22POISON / PROBE23 read-after-poison crash signature is best
> read as a probe artefact: the slot at Sp+12 of `_blk_c7te` may be
> the BS's `Addr#` per static Cmm analysis (session 24), but the
> *runtime* value at any specific GC point may be a register-saved
> heap pointer that the probe poisoned and the program reads.  The
> proximate cause of the bug remains unknown.  The hunt for "the BS
> producer that violates pinning" was misdirected.

v0.12.0 still ships unchanged.  Stage2 on pmacg5 was reverted to a
clean rebuild (no PROBE26) at session-26 end.

HANDOFF for session 27: see [`HANDOFF.md`](HANDOFF.md).  Top of
queue: re-establish a deterministic repro after PROBE26's
perturbation analysis, or move upstream of `mkFastStringByteString`
to look for the actual corruption mechanism.

## What we did, in order

### Step 1 — confirm baseline green

`tests/run-tests.sh`: 30 PASS, 4 expected design diffs.  Matches v0.12.0.

### Step 2 — re-read the BS allocator source surface

Audited `libraries/bytestring/Data/ByteString/Internal/Type.hs`,
`Data/ByteString/Short/Internal.hs`, and `libraries/base/GHC/ForeignPtr.hs`.
Found that `mallocPlainForeignPtrBytes` (the workhorse for `BS.create`
/ `BS.append` / `BS.concat` / `Char8.pack` / `hGet` / `getBS` / etc.)
calls `newPinnedByteArray#` and produces a `MallocPtr` whose MBA is
pinned.  The only "interesting" producer is `Short.fromShort`'s fast
path which constructs `BS (ForeignPtr addr (PlainPtr ...)) len`
conditional on `isPinned b#` (=`isByteArrayPinned#`).  See
[`findings.md`](findings.md) "BS producer set" for the full table.

### Step 3 — re-examine PROBE23's `pinned_skip = 0` claim

PROBE23's filter checked `BF_EVACUATED` first, then `BF_PINNED`.
Pinned blocks are tagged `BF_PINNED | BF_LARGE | BF_EVACUATED` at
allocation, so they always hit the `BF_EVACUATED` branch and get
counted as `evac_skip`, not `pinned_skip`.  Session 25's
`pinned_skip = 0` does not mean "no pinned-backed slots" — it's a
phantom distinction.  See [`findings.md`](findings.md)
"Re-examination of session 25's `pinned_skip = 0`."

### Step 4 — write PROBE26: classify the BS at mkFastStringByteString

[`probe26-classify-bs.patch`](probe26-classify-bs.patch) modifies
`compiler/GHC/Data/FastString.hs` (~50 lines) to add:

- A global `IORef Int` counter for visible-call sequencing.
- `probe26Classify` pattern-matches `BS (ForeignPtr _ contents) _`
  and returns a tag:
  `PlainForeignPtr` / `FinalPtr` /
  `MallocPtr+pinned` / `MallocPtr+UNPINNED` /
  `PlainPtr+pinned` / `PlainPtr+UNPINNED`.
  The pin check uses `isMutableByteArrayPinned#`.
- `probe26Trace` prints the tag to stderr for every call.  Cap on
  noise: prints first 50 plus every UNPINNED forever.  `hFlush
  stderr` after each line so output isn't lost to SIGSEGV.
- `mkFastStringByteString bs` is restructured to call `probe26Trace bs`
  before `SBS.toShort bs`.

### Step 5 — apply, rebuild stage1 ghc lib, redeploy

```
# (PROBE26 patch applied directly via Edit.)
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
# 27m16s — full recompile + re-link of the ghc compiler library
# (touching FastString invalidated 545 .o + 306 .p_o dependents)
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
# ~3 min for cross-link of ghc/Main.hs + scp + smoke test
```

### Step 6 — run the harness

```
bash docs/sessions/2026-05-12-session-26-bs-allocator-hunt/scripts/run-probe26.sh pmacg5
```

3 iterations on M5.hs (`+RTS -A1G`, `+RTS -A1m`, `+RTS -A1m`).
All 3 RC=0 (clean compile).  Each iter logs 50 PROBE26 lines
(the first-50 cap), all `PlainPtr+pinned`.  Zero UNPINNED.

### Step 7 — stress-test under PROBE26

To check whether PROBE26 *fixed* the bug or just *hid* it on M5.hs,
compiled larger inputs:

- M5plus.hs (Data.List + Data.Map.Strict imports + 4 small functions):
  the FIRST cold run after a Hello.hs leftover panicked with
  `refineFromInScope` (a session-17 GC-corruption signature).  15
  warm re-runs all RC=0.
- Big.hs (more imports, more functions): 10/10 RC=0.

The single panic confirms the bug is **not** fixed by PROBE26 — just
much rarer.

### Step 8 — interpretation

Combined PROBE26 data:

- 150+50+150+ visible calls to `mkFastStringByteString`, all
  PlainPtr-pinned.  Zero UNPINNED.
- M5.hs SIGSEGV gone (5/5 → 0/3).
- M5plus.hs panic preserved (1/16).

Read together: the BS-pinning-invariant violation hypothesis (a) is
not supported by direct observation.  The bug exists but is timing-
or codegen-sensitive in a way that PROBE26's added scrutinee on the
BS happens to disturb.

### Step 9 — end-of-session ritual

```
cd external/ghc-modern/ghc-9.2.8
git checkout compiler/GHC/Data/FastString.hs
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Stage2 on pmacg5 back to clean (no PROBE26) v0.12.0-equivalent.

### Step 10 — sanity-check: confirm clean stage2 still has the bug

After redeploy, M5.hs `+RTS -A1m` × 5:

| Iter | RC | Symptom |
|-----:|---:|---------|
|    1 | 1 | panic: depSortStgBinds Found cyclic SCC |
|    2 | 1 | panic: depSortStgBinds Found cyclic SCC |
|    3 | 0 | success |
|    4 | 1 | panic: depSortStgBinds Found cyclic SCC |
|    5 | 1 | panic: refineFromInScope |

**4/5 panic, 1/5 success.  No SIGSEGV.**  This matches session 17's
panic catalogue.  The "5/5 SIGSEGV at `_blk_c7te+112` with `0xdeadbeef`"
that sessions 23–25 reported was a **PROBE22POISON / PROBE23 specific
signature**: the probes filled stack slots with `0xDEADBEEF`, the
program then read one and SIGSEGV'd.  Without any probe, the bug
surfaces as panics.  This further argues that the Sp+12 stale-Addr#
narrative was probe-induced — the actual production bug is a
different kind of corruption.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with `+RTS -A1G` wrapper,
  baseline test battery green.
- **No source-tree edits this session** persist.  FastString.hs is
  back to upstream.
- **Stage2 ghc on pmacg5 is clean** (rebuild + redeploy after revert).
- **Logs at** [`logs/`](logs/)
  capture the PROBE26 runs, the M5plus.hs panic, and the Big.hs
  reruns.
- **HANDOFF for session 27** scopes re-establishing a repro and the
  next-direction options.

## Files added this session

- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — writeup.
- [`probe26-classify-bs.patch`](probe26-classify-bs.patch) — the
  ghc-compiler patch for the experiment (not committed to the GHC
  tree; archived here for re-apply).
- [`scripts/run-probe26.sh`](scripts/run-probe26.sh) — harness adapted
  from session 25 to count PROBE26 fields and surface UNPINNED
  entries.
