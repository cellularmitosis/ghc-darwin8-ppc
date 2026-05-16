# Handoff from session 57 → session 58

**For:** the next claude session.
**From:** session 57 — verification milestone.  83/83 PASS on a
curated subset of upstream's `testsuite/tests/ghci.debugger/scripts/`.
No new patches, no source changes, no release.  Added a reusable
`run-ghci-debugger.sh` runner alongside session 56's
`run-ghci-subset.sh`; extended the shared `normalise.py` with two
upstream `normalise_errmsg` rules (`...plus N instances`,
`ghc-bignum-<VERSION>`).

**Recommended pickup:** session 56 HANDOFF's priority list remains.
Priority #1 is now closed (debugger testsuite).  Next-best is
priority #2 (`req_th` GHCi script tests), all priority items
unchanged below.

## ✅ SESSION EXIT STATE

* No GHC source-tree changes, no new patches, no release tag.
* Stage2 ghc-real on pmacg5 unchanged (still the v0.14.0 binary
  from session 55, ~199 MB).
* New `docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/`
  dir with the run harness + per-test logs.
* Shared `normalise.py` (session 56's) gained two rules.  Session 56
  re-runs would still produce 51/51 PASS — both new rules are pure
  additions that don't apply to session 56's expected files.
* README + state.md + roadmap.md updated to reflect the verification.

## TL;DR — the session-57 finding

The v0.14.0 REPL on PPC/Tiger passes every test in upstream's
`tests/ghci.debugger/scripts/all.T` that's annotated `normal` /
`combined_output` / plain `extra_files` and doesn't require special
harness (`reqlib`, `req_th`, `expect_broken` applicable to ppc32,
`extra_hc_opts`, `extra_run_opts`).  83 tests covering the entire
debugger surface:

- `:print` / `:sprint` / `:force` (37 tests across print*/break*)
- `:break NAME` / `:break NUM` / `:break MOD.NAME` (22 tests across break*)
- `:step` / `:steplocal` / `:stepmodule` / `:trace` / `:hist` /
  `:back` / `:forward` (across break*/T2740/listCommand*)
- `:list` / `:list NAME` / `:list NUM` (listCommand001..002)
- Dynamic break enable/disable/delete (dynbrk*, 6 tests)
- Regression tests T<NNN> for specific issues (15 tests)

The most likely place for a PPC-specific bug to surface (per session
56 HANDOFF) — surfaces nothing.  See [`findings.md`](findings.md)
for the catalog and [`README.md`](README.md) for the per-area table.

Two run-1 failures, both harness-side:
- `print019` / `break006`: stderr off-by-one in
  "...plus N instances" footer (base-version drift). Matched
  upstream `testlib.py:2261`.
- `T2950` / `T3000`: companion files named `<test><CapitalSuffix>.hs`
  not auto-discovered.  Listed explicitly.

## What to try next, in priority order

(Carried forward from session 56 HANDOFF; #1 now closed.)

### Top: `req_th` GHCi script tests

Filtered out of sessions 56 / 57 because we didn't want to deal with
the `req_th` (requires TemplateHaskell) annotation.  Several
`req_th` ghci scripts test TH driven via the REPL in ways
session 56's ghci018 doesn't:

```
grep "req_th\b" external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T
```

Since `req_th` is just "this test uses TH", and v0.8.0 already
proved TH works on PPC, we can drop the annotation filter and just
run them.  Easy extension to session 56's
`run-ghci-subset.sh` — add the names to the TESTS list, possibly
with `-XTemplateHaskell` added to HC_FLAGS.

### Second: bug-numbered `T<num>` ghci regression tests

`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/T11827/`,
`T13786/`, `T16670/`, `T18060/`, `T18071/`, `T18262/`, etc.  Each
has its own `Makefile` driving a small scenario (often a regression
for a specific issue).  Less uniform than `scripts/`; each one
may need bespoke setup.  Cherry-pick the ones whose Makefiles are
short.

### Third: prog001..prog019

Multi-module `:load` tests.  Each is a directory with several `.hs`
files and a `.script` that walks them.  Tests `:load`'s
multi-module dependency tracking + reload invalidation.  Probably
all pass, but worth running.

### Fourth: GHCi over a real ssh tty

Still untested.  Sessions 55/56/57 all use piped stdin.  A real
`ssh pmacg5` + `/opt/ghc-stage2/bin/ghc-real --interactive`
exercises haskeline's terminal handling on Tiger.  Should "just
work" — haskeline is statically baked in — but hasn't been
verified.  Low effort: ssh in, try arrow keys, history, ctrl-r,
multi-line editing, tab completion.

### Fifth: extend the debugger runner to handle `extra_run_opts`

Trivial: thread the value through to the remote runner's ghc
invocation.  Would unlock `hist001` and `hist002` (`+RTS -I0`).
Also useful for any future test that needs RTS flags.

### Sixth: extend the debugger runner to handle subdir extras

Trivial: in the staging loop, if `extras` contains a dir name
(ends with `/`), do `cp -r` instead of `cp`.  Would unlock
`T1620` (one test, but easy).

### Seventh: stage2 native-compile sweep (carry-forward from S54)

Cabal-examples sweep, but native (ssh in, compile + run on
pmacg5) rather than cross-compile.  Modest interest.

### Eighth: refactor patch 0016 to upstream's smaller form

Still on the list from session 54.  Cosmetic.  Needs a stage1
rebuild + stage2 redeploy to validate.  Defer unless touching the
patch for another reason.

### Ninth: audit third-party libs for the `setByteArray# / readWordArray#` granularity-mismatch

Still on the list from session 53/54.  Upstream contribution.

## What NOT to redo

* **Don't re-run session 56's 51-test subset** unless the stage2
  binary changes.  Output is cached in
  `docs/sessions/2026-05-15-session-56-ghci-testsuite/logs/ghci-subset/`.
* **Don't re-run session 57's 83-test subset** either.  Cached in
  `docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/logs/ghci-debugger/`.
* **Don't reimplement the normaliser** — `scripts/normalise.py`
  now ports five upstream `testlib.py` functions and is
  reused-as-is.
* **Don't tag a release for the verification result** — it doesn't
  ship a new artifact.  v0.14.0 is unchanged.

## Hosts (unchanged from session 56)

* **uranium**: source edits, harness scripts, sweeps from here.
* **pmacg5**: runs the ppc stage2 ghc binary.
  `/opt/ghc-stage2/bin/ghc-real` is the v0.14.0 GHCi-enabled
  binary (~199 MB).  No changes this session.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 57 of the ghc-darwin8-ppc project added a second
verification milestone for the v0.14.0 GHCi REPL — 83/83 PASS on a
curated subset of upstream's testsuite/tests/ghci.debugger/scripts/
(the :break/:step/:trace/:print/:force/:list family).  Picked every
`normal` / `combined_output` / `extra_files` test that doesn't need
special harness.  Reusable runner at
docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/scripts/.

No new patches, no source changes, no release.  Stage2 ghc-real on
pmacg5 unchanged from v0.14.0.

There's no single next-must-do.  Pick from the session 57 HANDOFF
priority list:
1. `req_th` ghci script tests (TH already works; just drop the filter).
2. Bug-numbered T<num>/ ghci regression tests.
3. prog001..prog019 multi-module :load tests.
4. GHCi over real ssh tty (vs piped stdin).
5. Extend debugger runner for extra_run_opts (unlocks hist001/hist002).
6. Extend debugger runner for subdir extras (unlocks T1620).
7. Stage2 native-compile sweep.
8. Refactor patch 0016 to upstream's smaller form (cosmetic).
9. Audit third-party libs for setByteArray#/readWordArray# anti-pattern.

Read in order:
1. docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/HANDOFF.md
2. docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/README.md
3. docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/findings.md
4. docs/roadmap.md (priorities)

Hosts: uranium for harness + builds, pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 58 ends, write the next handoff at:
`docs/sessions/<DATE>-session-58-<slug>/HANDOFF.md`.
