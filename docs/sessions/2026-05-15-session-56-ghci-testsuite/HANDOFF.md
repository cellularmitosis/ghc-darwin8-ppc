# Handoff from session 56 → session 57

**For:** the next claude session.
**From:** session 56 — verification milestone.  51/51 PASS on a
curated subset of upstream's `testsuite/tests/ghci/scripts/`.
No new patches, no source changes, no release.  Built a reusable
`run-ghci-subset.sh` + `normalise.py` harness that mirrors enough
of upstream's test driver to drive ghci tests from a remote PPC
stage2.

**Recommended pickup:** the v0.14.0 REPL is now well-verified on
the simple-script subset.  Next-best uses of the harness, in
priority order, all extend it to surface area we *haven't* tested
yet — see below.  None are blocking.

## ✅ SESSION EXIT STATE

* No GHC source-tree changes, no new patches, no release tag.
* Stage2 ghc-real on pmacg5 unchanged (still the v0.14.0 binary
  from session 55, ~199 MB, GHCi-enabled).
* New `docs/sessions/2026-05-15-session-56-ghci-testsuite/` dir
  with the run harness + per-test logs.
* README + state.md + roadmap.md updated to reflect the
  verification result.
* Tree should be clean modulo the docs/ changes for this session.

## TL;DR — the session-56 finding

The v0.14.0 REPL on PPC/Tiger passes every test in upstream's
`tests/ghci/scripts/all.T` that's annotated `normal` or
`combined_output` and doesn't require special harness (reqlib,
req_th, expect_broken, extra_hc_opts, cross-dir extras).  51
tests in total.  Among them: TH splice typed at the REPL prompt
(ghci018), `:browse` over Data.Maybe (ghci023, ghci025),
`:instances Maybe`/`:instances [_]` etc (ghci064), `:reload` with
file-timestamp tricks (ghci063), exception with callstack (ghci055),
`:doc` haddock metadata (ghci066), static pointers (ghci061),
type families / GADTs / records in REPL (ghci030, ghci046, ghci049,
ghci050, ghci053).

All seven initial test failures during the harness debug arc were
testsuite-drift / harness omissions, matched by upstream's
`TEST_HC_OPTS` flags + `normalise_errmsg` + companion-file glob.
See [`findings.md`](findings.md) for the catalog.

## What to try next, in priority order

There's no single must-do.  The remaining work is all "extend
the verification footprint" — pick one based on appetite.

### Top: GHCi debugger testsuite

`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci.debugger/`
is the `:break` / `:step` / `:trace` / `:print` / `:list` /
`:back` / `:forward` / `:show context` family.  These tests
exercise *bytecode breakpoint placement*, *suspended-thunk
introspection*, *call-stack walking from BCOs* — code paths that
nothing in our project has tested yet.  Most likely place for a
PPC-specific bug to actually surface (vs the scripts/ subset which
turned up zero).

Approach: the debugger tests are split across `scripts/` (a
similar shape to what we already handle) and `should_run/`
(programs that compile + run + are stepped through).  Start with
the `scripts/` ones — should be a small extension of our existing
runner: same script-stdin-then-diff shape, just with
`:break`/`:step` interspersed.  The `should_run/` ones need the
test driver to compile a program first; deferrable.

### Second: `req_th` GHCi script tests

Filtered out of session 56's run because we didn't want to deal
with the `req_th` (requires TemplateHaskell) annotation.  Reading
all.T, several `req_th` ghci scripts test TH driven via the REPL
in ways ghci018 doesn't:

```
grep "req_th\b" external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T
```

(About 6-8 tests.)  Since `req_th` is just "this test uses TH",
and v0.8.0 already proved TH works on PPC, we can drop the
annotation filter and just run them.  Easy extension to the
existing runner — add the names to the TESTS list, possibly with
`-XTemplateHaskell` added to HC_FLAGS.

### Third: bug-numbered `T<num>` ghci regression tests

`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/T11827/`,
`T13786/`, `T16670/`, `T18060/`, `T18071/`, `T18262/`, etc.  Each
has its own `Makefile` driving a small scenario (often a regression
for a specific issue).  Less uniform than `scripts/`; each one
may need bespoke setup.  Cherry-pick the ones whose Makefiles are
short.

### Fourth: prog001..prog019

Multi-module `:load` tests.  Each is a directory with several `.hs`
files and a `.script` that walks them.  Tests `:load`'s
multi-module dependency tracking + reload invalidation.  Probably
all pass, but worth running.

### Fifth: GHCi over a real ssh tty (carry-forward from session 55)

Still untested.  Our session 56 (and 55) tests all use piped stdin.
A real `ssh pmacg5` + `/opt/ghc-stage2/bin/ghc-real --interactive`
exercises haskeline's terminal handling on Tiger.  Should "just
work" — haskeline is statically baked in — but hasn't been
verified.  Low effort: ssh in, try arrow keys, history, ctrl-r,
multi-line editing, tab completion.

### Sixth: stage2 native-compile sweep (carry-forward from session 54)

Cabal-examples sweep, but native (ssh in, compile + run on
pmacg5) rather than cross-compile.  Modest interest; the
existing cross-compile sweep + Big2.hs + GHCi `:load` of multi-
module programs already exercise stage2.

### Seventh: refactor patch 0016 to upstream's smaller form

Still on the list from session 54.  Cosmetic.  Needs a stage1
rebuild + stage2 redeploy to validate.  Defer unless we're
touching the patch for another reason.

### Eighth: audit third-party libs for the `setByteArray# / readWordArray#` granularity-mismatch

Still on the list from session 53/54.  Upstream contribution, not
blocking us.

## What NOT to redo

* **Don't re-run the 51-test subset** unless the stage2 binary
  changes.  Output is cached in
  `docs/sessions/2026-05-15-session-56-ghci-testsuite/logs/ghci-subset/`.
* **Don't reimplement the normaliser** — `scripts/normalise.py`
  ports the relevant `testlib.py` functions and is reused-as-is.
* **Don't tag a release for the verification result** — it doesn't
  ship a new artifact.  v0.14.0 is unchanged.

## Hosts (unchanged from session 55)

* **uranium**: source edits, harness scripts, sweeps from here.
* **pmacg5**: runs the ppc stage2 ghc binary.
  `/opt/ghc-stage2/bin/ghc-real` is the v0.14.0 GHCi-enabled
  binary (~199 MB).  No changes this session.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 56 of the ghc-darwin8-ppc project added a verification
milestone for the v0.14.0 GHCi REPL — 51/51 PASS on a curated subset
of upstream's testsuite/tests/ghci/scripts/.  Picked every `normal` /
`combined_output` `ghciNNN` test that doesn't need extra harness.
Reusable runner + upstream-equivalent normaliser landed at
docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/.

No new patches, no source changes, no release.  Stage2 ghc-real on
pmacg5 unchanged from v0.14.0.

There's no single next-must-do.  Pick from the session 56 HANDOFF
priority list:
1. GHCi debugger testsuite (tests/ghci.debugger/) — :break/:step/
   :trace/:print/:list, the most likely place for an actual PPC bug.
2. `req_th` ghci script tests (we filtered them out; TH already works).
3. Bug-numbered T<num>/ ghci regression tests.
4. prog001..prog019 multi-module :load tests.
5. GHCi over real ssh tty (vs piped stdin) — carry-forward from S55.
6. Stage2 native-compile sweep — carry-forward from S54.
7. Refactor patch 0016 to upstream's smaller form (cosmetic).
8. Audit third-party libs for setByteArray#/readWordArray# anti-pattern.

Read in order:
1. docs/sessions/2026-05-15-session-56-ghci-testsuite/HANDOFF.md
2. docs/sessions/2026-05-15-session-56-ghci-testsuite/README.md
3. docs/sessions/2026-05-15-session-56-ghci-testsuite/findings.md
4. docs/roadmap.md (priorities)

Hosts: uranium for harness + builds, pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 57 ends, write the next handoff at:
`docs/sessions/<DATE>-session-57-<slug>/HANDOFF.md`.
