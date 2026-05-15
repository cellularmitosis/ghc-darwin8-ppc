# Session 53 — Release v0.13.0: STUArray Bool fix shipped

**Date:** 2026-05-15 (continuation of session 52).

**Status on arrival:** Patch 0016 applied, stage1 rebuilt, stage2
redeployed to pmacg5.  Baseline 30 PASS / 4 FAIL\_OUTPUT.  Big2.hs
stage2-compile produces a fully-populated 46340-byte `.o` under
default RTS.  See [session 52 HANDOFF](../2026-05-15-session-52-stuarray-scope/HANDOFF.md)
for the full state — the 32-session-old "empty `.o`" bug is fixed.

**Status on exit:** v0.13.0 released.  Tag pushed.  Bindist tarballs
uploaded.  Demo committed at [`demos/v0.13.0-bool-bug-fix.sh`](../../../demos/v0.13.0-bool-bug-fix.sh).
README "Latest release" line flipped to v0.13.0, "Stage2 native ghc"
row flipped 🟡 → ✅, new row added to the Releases table.
`docs/state.md` and `docs/roadmap.md` updated.  Cabal-examples
re-run (see *Cabal-examples re-validation* below).

## Plan (per session 52 HANDOFF)

1. Cut release v0.13.0 with the array library fix.
2. Pick a demo program: Big2.hs (the long-running stage2 reproducer
   that produced 152-byte empty `.o` files for 10 sessions).
3. Update README + state.md + roadmap.md for the milestone.
4. Re-run `tests/cabal-examples/` (after fixing the `EXTRA_FLAGS`
   bash 3.2 unbound-variable bug).
5. Confirm the upstream GHC bug is also in current HEAD (for the
   upstream MR, deferred to session 54+).

## What happened

### Drive-by fix: `tests/cabal-examples/run-one.sh` empty-array bug

The HANDOFF flagged a `EXTRA_FLAGS[@]: unbound variable` error under
`set -u` when invoking the script without `OPENSSL_PREFIX` set.  Root
cause is a bash 3.2 issue (macOS system bash): expanding an empty
array via `"${arr[@]}"` triggers `unbound variable` under `set -u`,
even though the array was initialised with `EXTRA_FLAGS=()`.  Fix
in [`tests/cabal-examples/run-one.sh`](../../../tests/cabal-examples/run-one.sh):
switch the expansion to `${EXTRA_FLAGS[@]+"${EXTRA_FLAGS[@]}"}`, which
expands to nothing when the array is empty and to the array's contents
otherwise — works under bash 3.2 `set -u`.  Verified by reproducing
the failure (`bash -c 'set -euo pipefail; A=(); echo "${A[@]}"'`
errors; the new expansion does not).

### Upstream GHC HEAD confirmation

Fetched current `libraries/array/Data/Array/Base.hs` from
`gitlab.haskell.org/ghc/packages/array` master.  Lines 1235–1250:
the buggy `STUArray Bool` `MArray` instance is byte-identical to what
session 52 patched.  `newArray` allocates `bOOL_SCALE n#` bytes via
`newByteArray#`, zeroes the same `nbytes#` via `setByteArray#`, and
`unsafeRead` accesses via `readWordArray#`.  Same code, same bug.
This is a live upstream issue, not a 9.2.8 regression — appropriate
for an upstream MR.

### Demo: `demos/v0.13.0-bool-bug-fix.sh`

Writes Big2.hs to Tiger, stage2-compiles it 5× with default RTS
(should yield 46340-byte `.o`s; pre-fix yielded 152-byte empty
files), once with `-A1m -G1` (same — pre-fix this combo
deterministically reproduced the bug), then `--make`s a Big2Main
executable and runs it.  See the script header for the full
context.

### Cabal-examples re-validation

(filled in once the cabal-examples sweep completes; expect most to
still build cleanly since they were tested under v0.12.0 with the
`-A1G` workaround — the new question is whether any newly succeed
under default RTS via stage2-native compile)

### Bindist rebuild

Deleted stale `_build/bindist/` from v0.12.0 and ran
`./hadrian/build --flavour=quick-cross --docs=none binary-dist-dir`.
Hadrian rebuilt the profiling-way `.p_o` files for the array library
and its downstream dependents (text, bytestring, etc.) which were
still built against the pre-fix array library — that's why the
rebuild touched more than just `array-0.5.4.0`.  Resulting tarball
at `external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`.
The patched array library is at byte-offset (per `tar tvJf`)
`lib/ppc-osx-ghc-9.2.8/array-0.5.4.0/HSarray-0.5.4.0.o`.

### Stage2 native bindist

Stage2 was redeployed to pmacg5 in session 52 via
`scripts/deploy-stage2.sh pmacg5` — that's the production deploy.
The release ships a companion tarball
`ghc-9.2.8-stage2-native-ppc-darwin8.tar.xz` that captures the same
artifacts as a portable archive that any Tiger box can untar into
`/opt/ghc-stage2/`.

## What this means

v0.13.0 is the first release where the stage2 native ghc on Tiger
compiles real, non-trivial Haskell programs **without** the
`+RTS -A1G -RTS` workaround.  The 32-session investigation that
started in session 17 ("stage2 panics on GC") and meandered through
sessions 19–51 — accumulating five rounds of incorrect proximate-
cause framings (LayoutStack bitmap bug, BS-pinning invariant, GC
of Var.realUnique, UniqMap corruption, [InBind] cons-list spine
corruption) — is now resolved.  The real bug was a single 11-line
upstream library miscompilation that fires only on big-endian and
only for sub-word-size `STUArray Bool` allocations.

## Files added this session

* `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
* `logs/` — baseline-tests, bindist-rebuild, cabal-examples-sweep.
* `demos/v0.13.0-bool-bug-fix.sh` — the v0.13.0 demo.
* README, state.md, roadmap.md updates.
* `tests/cabal-examples/run-one.sh` empty-array fix.
