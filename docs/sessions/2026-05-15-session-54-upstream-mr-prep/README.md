# Session 54 — Upstream MR prep for the STUArray Bool fix

**Date:** 2026-05-15 (continuation of session 53).

**Status on arrival:** v0.13.0 shipped.  Patch 0016 carries the
11-line STUArray Bool word-aligned init fix.  Baseline green
(30 PASS / 4 FAIL\_OUTPUT, all four the pre-existing test-design
issues: Int width, getpid, getProgName).  Stage2 native ghc on
pmacg5 patched and verified.  Session 53 confirmed the buggy code
is byte-identical in current GHC HEAD's
`packages/array/Data/Array/Base.hs`.

**Status on exit:** No upstream MR to prepare — the bug was already
fixed upstream in May 2023 (commit
[`9cc80b5`](https://gitlab.haskell.org/ghc/packages/array/-/commit/9cc80b51cf98c13a140b00effb38329e7210d03c)
"Round up unboxed Bool arrays to whole-word sizes" by Matthew Craven,
motivated by [ghc#23132](https://gitlab.haskell.org/ghc/ghc/-/issues/23132),
shipped in `array-0.5.6.0`).  Session 53's "live upstream issue" claim
turned out wrong: the `MArray (STUArray s) Bool (ST s)` instance code
in upstream HEAD is byte-identical to ours, but `bOOL_SCALE` itself
(which the instance calls) was changed to round up to a whole word.
Patch 0016 is the equivalent backport into our 9.2.8 tree (which
ships `array-0.5.4.0`, pre-dating the upstream fix).

Cabal-examples sweep: 6/9 PASS cleanly on pmacg5 (random, async,
vector, megaparsec, aeson-generics, network-echo); 2/9 missing-args
test-harness gaps (optparse, full-stack-cli); 1/9 missing host-side
PPC-cross OpenSSL (https-get).  Zero regressions from patch 0016.
See [sweep-notes.md](sweep-notes.md).

Docs updated: roadmap §H closed ✅ "already fixed upstream",
[`docs/state.md`](../../state.md) top-of-file bumped to session 54,
session 53's README amended with the correction, top-level README's
Latest-release paragraph + Releases table row de-claim "real upstream
GHC bug — same code in current HEAD", patch 0016 prologue
cross-references the upstream commit.  No GHC source changes this
session; baseline 30 PASS / 4 FAIL\_OUTPUT unchanged.

## Plan (per session 53 HANDOFF + roadmap §H — now obsolete)

1. ~~**Portable repro.**~~ Moot — fix is upstream.
2. ~~**`unsafeNewArray_` decision.**~~ Moot — upstream chose the
   simpler "modify `bOOL_SCALE` itself" approach which fixes
   `unsafeNewArray_` for free (it calls `bOOL_SCALE`).
3. ~~**Draft the upstream issue + MR text.**~~ Moot — fix is in
   upstream as of May 2023.
4. Cabal-examples sweep — done.

## What happened

### Upstream-status check (the main finding)

The HANDOFF said session 53 confirmed "the broken code is byte-
identical in current GHC HEAD."  I sanity-checked that claim by
cloning `gitlab.haskell.org/ghc/packages/array` (depth 1, then full
for history), comparing `Data/Array/Base.hs` line-by-line.

The `MArray (STUArray s) Bool (ST s)` instance (around line 1235)
IS byte-identical.  But `bOOL_SCALE`'s definition (around line 1557)
is NOT — upstream's `bOOL_SCALE` rounds the byte count up to a
whole word, exactly matching what our patch's `bOOL_WORD_SCALE`
does.  Functionally identical fix, different implementation
strategy.

`git log --all -- Data/Array/Base.hs` shows the fix landed as
commit `9cc80b5` on 2023-05-04 by Matthew Craven, with subject
"Round up unboxed Bool arrays to whole-word sizes".  The commit
message cites `ghc#23132` (we couldn't fetch the issue page itself
— gitlab.haskell.org sits behind an Anubis bot wall — but the
commit text + the changelog entry "Unboxed Bool arrays no longer
cause spurious alarms when used with `-fcheck-prim-bounds`" are
unambiguous).  The fix ships in `array-0.5.6.0` (July 2023) and
later; GHC 9.2.8 ships `array-0.5.4.0`, predating the fix.

See [findings.md](findings.md) for the full discovery write-up and
the cross-version comparison table.

### Doc updates flowing from the finding

* `patches/0016-array-stuarray-bool-word-aligned-init.patch` —
  patch prologue now cross-references commit `9cc80b5` and explains
  that this is a backport, not a novel fix.
* `docs/roadmap.md` — §H reformulated and closed ✅ "already fixed
  upstream".  The "open work to land this upstream" subsections are
  removed; what remains is a one-paragraph note that captures the
  upstream-prior-art finding and what our project still adds (the
  BE-silent-miscompile narrative).
* `docs/state.md` — top-of-file `Updated:` line bumped to session
  54 with the session-54 summary; session-52 summary demoted to
  `(Prior summary, session 52:)` and amended to remove the
  "identical code in current GHC HEAD" claim.
* `docs/sessions/2026-05-15-session-53-v0.13.0-release/README.md`
  — added a "Correction (added in session 54)" paragraph under
  "Upstream GHC HEAD confirmation".
* Top-level `README.md` — Latest-release paragraph + Releases-table
  row reframed to credit upstream's prior fix.

### Cabal-examples sweep (the second-priority pickup)

Driver: `/tmp/cabal-sweep-54.sh` (transient).  Each example invoked
via `bash tests/cabal-examples/run-one.sh <example>`, logs at
[`logs/cabal-examples/<example>.log`](logs/cabal-examples).
Results in [sweep-notes.md](sweep-notes.md):

| Example | Result |
|---|---|
| random | ✅ PASS |
| async | ✅ PASS |
| vector | ✅ PASS |
| megaparsec | ✅ PASS |
| aeson-generics | ✅ PASS |
| network-echo | ✅ PASS |
| optparse | ⚠️ harness gap (binary works, run-one.sh doesn't pass `-n NAME`) |
| full-stack-cli | ⚠️ harness gap (binary works, run-one.sh doesn't pass `-i FILE`) |
| https-get | ⚠️ host-toolchain gap (no PPC-cross OpenSSL at `$OPENSSL_PREFIX`) |

Zero regressions.  Caveat: this sweep uses *stage1 cross-compile*,
not stage2 native compile, so doesn't exercise the bool-bug code
path.  The v0.13.0 demo (Big2.hs stage2-compiled on pmacg5) remains
the clearest "newly works" demo.

### Other-bit-packed-instances audit (the fourth-priority pickup)

A quick local check of our `libraries/array/Data/Array/Base.hs`
confirms Bool is the only bit-packed unboxed instance.  Other
unboxed `MArray (STUArray s)` instances use `wORD_SCALE`,
`elemsToBytes`, etc. — one machine word (or known fixed size) per
element, no byte/word granularity mismatch.  External libraries
(`vector`, `bytestring`) could carry the same anti-pattern; that
audit is deferred.

## What this session did NOT do

* No GHC source-tree changes (patch 0016 unchanged in content;
  only its prologue commentary was updated).
* No new releases.
* No stage1 / stage2 rebuilds.
* No HANDOFF-suggested portable-repro work (moot — fix is upstream).

## Files added this session

* `README.md` (this), `findings.md`, `sweep-notes.md`, `commits.md`,
  `HANDOFF.md`.
* `logs/cabal-examples/*.log` + `SUMMARY.txt`.
* Updates to: `patches/0016-array-stuarray-bool-word-aligned-init.patch`
  (prologue only), `docs/roadmap.md` (§H rewrite), `docs/state.md`
  (top-of-file new summary), `docs/sessions/2026-05-15-session-53-v0.13.0-release/README.md`
  (correction paragraph), `README.md` (top-level — Latest-release
  paragraph + Releases-table row).
