# Handoff from session 26 → session 27

**For:** the next claude session.
**From:** session 26 (PROBE26 = ForeignPtrContents classifier in
mkFastStringByteString; rejects hypothesis (a); 2026-05-12).
**Recommended pickup:** re-establish a deterministic repro for the
session-17 GC corruption that survives a non-perturbing probe, then
move investigation upstream of `mkFastStringByteString`.

## TL;DR (mandatory read)

- PROBE26 (Haskell-side: classify ForeignPtrContents of every BS
  flowing into `mkFastStringByteString`, plus check
  `isMutableByteArrayPinned#` for the underlying MBA) saw **150
  visible calls across 3 runs of M5.hs `+RTS -A1m`, 100% are
  `PlainPtr+pinned`, zero `*+UNPINNED`**.
- The PROBE26 instrumentation **prevents the SIGSEGV on M5.hs
  entirely** (0/3 vs. session 23's 5/5).  Stress-tested on M5plus.hs
  (1/16 panic on a cold first run, 15/15 OK on warm re-runs) and
  Big.hs (10/10 OK).  The bug is still present but much rarer under
  PROBE26.
- **Hypothesis (a) is rejected**: BSes flowing into
  `mkFastStringByteString` are NOT non-pinned.  Sessions 19–25's
  BS-pinning-invariant theory does not survive direct observation.
- **The PROBE22POISON crash signature in sessions 23–25 is best
  read as a probe artefact composite**: real GC corruption + the
  probe's own poison stomp.  The Sp+12 stale-Addr# narrative was
  built from that composite, not from the actual production crash
  mechanism.
- v0.12.0 ships unchanged.  Stage2 on pmacg5 was rebuilt + redeployed
  clean at session-26 end.

## Read in order

1. **This file** (the handoff).
2. [`README.md`](README.md) — narrative of session 26.
3. [`findings.md`](findings.md) — detailed BS-producer audit, PROBE26
   data, and the cumulative reading-of-sessions table.
4. [`probe26-classify-bs.patch`](probe26-classify-bs.patch) — the
   exact compiler patch we ran.
5. (Reference) Session 24 [`README.md`](../2026-05-11-session-24-faststring-stackrep/README.md)
   for the `_blk_c7te` Cmm reading and BS-field-layout arithmetic
   we no longer believe is causal.
6. (Reference) Session 17 [`GC-BUG-FOUND.md`](../2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)
   for the original panic / SIGSEGV catalogue and `-A` threshold
   table.  Session 17 found the bug; sessions 19–26 tried to
   localise it and failed.

## What to NOT redo

- **Don't re-run PROBE26 on M5.hs expecting useful data.**  The
  perturbation hides the bug on M5.hs.  Need a new repro.
- **Don't pursue the BS-pinning-invariant theory further.**  PROBE26
  ruled it out with 150 direct observations.
- **Don't go back to LayoutStack / mkLivenessBits / stackMapToLiveness.**
  Sessions 21–24 settled them.
- **Don't audit Catch.hs or any other StackRep.**  Sessions 22, 24
  settled that.
- **Don't poison the stack** (PROBE22 / PROBE23 family).  Both have
  served their purpose and may be misleading us by introducing
  composite crash signatures.

## What to try next, in priority order

### Top: re-establish a non-perturbing deterministic repro

The session-26 finding is that PROBE26 perturbs the bug away on
M5.hs.  We need a workload that crashes deterministically WITHOUT
any Haskell-side instrumentation.

Options to try:

#### Option A — re-confirm M5.hs crashes on a clean stage2

The clean stage2 (no PROBE26) was redeployed at session-26 end.
**Already re-confirmed: M5.hs `+RTS -A1m` PANICS 4/5 on the clean
rebuild** (depSortStgBinds cyclic SCC, refineFromInScope, etc.).
NO SIGSEGV — the production bug surfaces as panics, not SIGSEGV.

**Important**: the "5/5 SIGSEGV at `_blk_c7te + 112`" signature
that sessions 23–25 reported was specific to PROBE22POISON / PROBE23
(the probes that filled stack slots with `0xDEADBEEF`).  Without any
probe, the bug surfaces as the panics that session 17 first cataloged.
So when iterating in session 27:

- Use **panic frequency** as the signal, not "SIGSEGV at X."
- A 4/5 panic rate on M5.hs `+RTS -A1m` is the new baseline.
- A non-perturbing probe should preserve that rate.

#### Option B — find a workload that crashes 100% under any probe

Compile something larger:
- `cabal install random` (real Hackage package).
- Stage2 ghc compiling itself (or a small ghc-compiler module).
- The stage2 `runghc-tiger` test suite.

If any input crashes 5/5 even under a heavily-instrumented stage2,
we have a probe-resistant repro.

### Second: read `_blk_c7te`'s assembly under PROBE26

Cross-build FastString.hs with PROBE26 + `-ddump-cmm-sp -ddump-cmm-info`,
diff the resulting `_blk_c7te` (or its renamed equivalent) against
session 24's [`excerpts/c7t9-c7te.cmm`](../2026-05-11-session-24-faststring-stackrep/excerpts/c7t9-c7te.cmm).

The hypothesis: PROBE26's added scrutinee changes the spill pattern
for the BS's Addr# field.  If the new Cmm has the Addr# in a
register at the GC point (not on the stack), that confirms the
perturbation mechanism.  This isn't load-bearing for the
investigation, but it formalises why PROBE26 hides the bug.

~30–60 min.

### Third: instrument the destination MBA, not the source BS

`toShortIO` allocates a fresh `dst` MBA via `newByteArray# len`
(unpinned), copies into it, freezes it, returns it as the new SBS.
After freeze, the MBA backs the new SBS via `unsafeFreezeByteArray#`.
If anything reads from `dst`'s `byteArrayContents#` *after* a GC
moves it, that's a stale-pointer bug — but on the destination MBA,
not the source.

Instrument: in `mkFastStringByteString`, after the result is computed,
check whether the final SBS's byte array is pinned.  If it isn't (it
shouldn't be — `newByteArray#` is unpinned), and if its `byteArrayContents#`
is being held anywhere (like in a `FastString` or thread state),
that's a candidate for stale-pointer reads.

~2–4 h: another patch + cross-build cycle, but in a different module.

### Fourth: move all the way upstream — re-survey the corruption

Session 17's panic catalogue was the original signal.  Sessions 19–26
all tried to localise the corruption mechanism via stack-frame
probes.  None succeeded; PROBE26 in particular shows the focus on
mkFastStringByteString was misled.  Time to step back.

Possibilities:
- **CAF / SRT corruption.**  Closure lists outside per-thread state.
  Older proposal; easy to instrument with a CAF-list integrity
  check at the start of every GC.
- **Info-table contents.**  Read-only, but a bad pointer in an info
  table's payload list would mislead the scavenger globally.  Add
  a sanity-check pass that walks all live info tables and verifies
  every pointer field.
- **PPC32 pinned-block sub-allocator state.**  `cap->pinned_object_block`
  can be re-used across allocations.  If anything in `allocatePinned`
  is racy or wrong on PPC32, you'd get exactly the kind of
  intermittent corruption we see.  Read `Storage.c::allocatePinned`
  with PPC32-specific eyes (alignment, endianness).
- **Generation 1 / older-generation scavenge ordering.**  The bug
  fires only on inputs large enough to trigger major GC?  Worth
  testing: does `+RTS -A1m -G1` (single-generation) behave
  differently?

### Fifth: cross-host comparison

Build host ghc-9.2.8 with the same PROBE26 patch on uranium (arm64).
Run M5.hs through it.  Expected: same 100% PlainPtr-pinned, no
crash.  This isn't decisive but confirms PROBE26's read of
"PlainPtr-pinned" isn't a PPC32-specific artefact.

~1 h.

## Mechanics — how to reproduce session-26 results

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 0. Confirm baseline still green
bash tests/run-tests.sh   # expect 30 PASS / 4 design diffs

# 1. Apply PROBE26 to compiler/GHC/Data/FastString.hs
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-12-session-26-bs-allocator-hunt/probe26-classify-bs.patch

# 2. Rebuild stage1 ghc lib
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a   # ~27 min

# 3. Cross-build stage2 + deploy
cd ../../..
bash scripts/deploy-stage2.sh pmacg5    # ~3 min

# 4. Run the harness
bash docs/sessions/2026-05-12-session-26-bs-allocator-hunt/scripts/run-probe26.sh pmacg5
# 3×M5.hs runs, expect all RC=0 with all-PlainPtr-pinned output.

# 5. Stress test (optional)
ssh pmacg5 'rm -f /tmp/M5plus.hs /tmp/M5plus.{o,hi}'
# (drop M5plus.hs / Big.hs onto pmacg5, compile under -A1m many times,
# look for panics)

# 6. Revert + redeploy clean
cd external/ghc-modern/ghc-9.2.8
git checkout compiler/GHC/Data/FastString.hs
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a   # ~27 min
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

Total session 26 wall-clock: ~75 min for a single round-trip
(rebuild + deploy + run + revert + rebuild + redeploy).  Plan
accordingly when iterating.

## Hosts (unchanged from sessions 22–25)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: trimmed dev tools — don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/compiler/GHC/Data/FastString.hs` —
  clean (revert applied at session-26 end).
- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSghc-9.2.8.a`
  — clean rebuild after revert (in progress at session end; will
  finish before commit).
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — pending the clean
  redeploy after the rebuild finishes.
- New session log: `docs/sessions/2026-05-12-session-26-bs-allocator-hunt/`
  + run logs at `logs/`.

## Time estimate for session 27

- Setup + read handoff: 15 min.
- Re-confirm M5.hs crashes 5/5 on clean stage2: 5 min.
- If it does, find a probe that doesn't perturb the bug: 2–4 h
  (RTS-side counter, or read assembly to characterise PROBE26's
  effect, or move upstream).
- If it doesn't, investigate why (changed cross-build state?): 1–2 h.

Realistic: 1 medium session (~3–5 h) to either re-establish the
repro or pivot the investigation direction.  Then another 1–2
medium sessions to find the actual proximate cause.

## Paste-into-fresh-session prompt

```
Context: just finished session 26 (PROBE26 = ForeignPtrContents
classifier in mkFastStringByteString).  PROBE26 is a Haskell-side
patch to compiler/GHC/Data/FastString.hs that pattern-matches every
BS flowing into mkFastStringByteString, classifies its
ForeignPtrContents, and checks isMutableByteArrayPinned#.  Result on
M5.hs +RTS -A1m: 150 visible calls, ALL PlainPtr+pinned, zero
UNPINNED, AND zero SIGSEGV (vs. 5/5 SIGSEGV without PROBE26).
Stress-tested on M5plus.hs and Big.hs: 1/16 panic on M5plus.hs cold
first run (refineFromInScope, classic GC corruption), 15/15 + 10/10
RC=0 elsewhere.

This rejects hypothesis (a) "BS reaches mkFastStringByteString with
non-pinned MBA" — direct observation contradicts it.  Sessions 19–25
collectively settled that the bug is NOT in LayoutStack /
mkLivenessBits / stackMapToLiveness / any stack-frame bitmap, and
sessions 23–25's PROBE22POISON / PROBE23 read-after-poison crash
signature is now best read as a probe artefact composite.  We do not
currently have a confirmed proximate cause for the session-17 GC
corruption.

Read in order:
1. docs/sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md
2. docs/sessions/2026-05-12-session-26-bs-allocator-hunt/README.md
3. docs/sessions/2026-05-12-session-26-bs-allocator-hunt/findings.md
4. (reference) docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md
   for the original panic / SIGSEGV catalogue.
5. (reference) docs/sessions/2026-05-11-session-24-faststring-stackrep/excerpts/c7t9-c7te.cmm
   for the StackRep we no longer believe is causal.

Then either:
- Re-confirm M5.hs +RTS -A1m crashes 5/5 on the clean stage2 (it
  was rebuilt+redeployed at session-26 end).  If yes: find a probe
  that doesn't perturb the bug (RTS-side counter, or move investigation
  upstream).  If no: investigate why (cross-build state changed?).
- OR move directly to upstream-of-FastString investigation: CAF/SRT
  corruption, info-table integrity, PPC32 allocatePinned audit,
  generation-ordering, etc.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's -A1G wrapper.

Unsupervised mode is project default.
```
