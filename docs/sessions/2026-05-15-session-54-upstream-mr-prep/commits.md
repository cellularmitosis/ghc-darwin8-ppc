# Session 54 commits

| SHA | Subject |
|---|---|
| `1b23133` | Session 54: STUArray Bool fix already upstream (ghc#23132). |

## Files changed

No GHC source-tree changes.  Doc + patch-prologue updates only.

### Patches

* [`patches/0016-array-stuarray-bool-word-aligned-init.patch`](../../../patches/0016-array-stuarray-bool-word-aligned-init.patch)
  — patch *body* unchanged; *prologue* now cross-references upstream
  commit `9cc80b5` "Round up unboxed Bool arrays to whole-word sizes"
  (May 2023, Matthew Craven, motivated by
  [ghc#23132](https://gitlab.haskell.org/ghc/ghc/-/issues/23132)),
  explains that this patch is the equivalent backport into
  `array-0.5.4.0` (which is what GHC 9.2.8 ships), and points at
  session 54 findings for the discovery write-up.

### Top-level README

* `README.md` — Latest-release paragraph (~line 50) and the
  Releases-table row for v0.13.0 (~line 232) reframed to credit
  upstream's prior fix instead of claiming "Real upstream GHC bug —
  same code in current HEAD."

### State + roadmap

* [`docs/state.md`](../../state.md) — new session-54 summary at the
  top-of-file (`Updated:` line bumped from session 52 to session 54);
  former session-52 summary demoted to a `(Prior summary, session 52:)`
  block and its "identical code in current GHC HEAD" claim removed.
* [`docs/roadmap.md`](../../roadmap.md) — §H "Upstream MR for the
  `STUArray Bool` big-endian fix" reformulated as
  "~~H. Upstream MR ...~~ ✅ already fixed upstream"; the open-work
  subsections are removed; what remains is a one-paragraph summary
  of the prior-art finding and what our project still adds.

### Session-53 record

* [`docs/sessions/2026-05-15-session-53-v0.13.0-release/README.md`](../2026-05-15-session-53-v0.13.0-release/README.md)
  — added a "Correction (added in session 54)" paragraph under
  "Upstream GHC HEAD confirmation" pointing at the session-54 finding.

### Session-54 record (this dir)

* `docs/sessions/2026-05-15-session-54-upstream-mr-prep/`
  * `README.md` — narrative + exit state.
  * `findings.md` — upstream prior-art discovery, cross-version
    comparison, why session 53 missed it.
  * `sweep-notes.md` — cabal-examples sweep table + caveats.
  * `commits.md` — this file.
  * `HANDOFF.md` — primer for session 55.
  * `logs/cabal-examples/` — per-example build+run logs and
    `SUMMARY.txt`.

## Notes

* Session 54 ended at a clean stopping point.  No tree-state changes,
  no patches added or removed, no release.  Just docs + patch-prologue
  cross-reference.
* If session 55 chooses to refactor patch 0016 to match upstream's
  form (modify `bOOL_SCALE` rather than add `bOOL_WORD_SCALE`), that
  would be a stage1 rebuild + a fresh v0.13.1 — purely cosmetic since
  the fix is functionally identical.  Deferred unless we're touching
  it for another reason.
