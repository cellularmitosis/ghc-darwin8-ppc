# Handoff from session 65 → session 66

**For:** the next claude session.
**From:** session 65 — verification-only, **17/17 PASS** on the
`tests/ghci/prog001..prog019` subset.  New runner
`scripts/run-ghci-progNNN.sh`.  No GHC source changes, no patches,
no release.

**Recommended pickup:** The HANDOFF priority list inherited from
session 64 remains valid; prog0NN is now done so the top three
remaining items are:
1. Bug-numbered `T<num>/` subdirs in `tests/ghci/` (HANDOFF
   priority #3 from session 64).  ~9 dirs: T11827, T13786, T16392,
   T16525a, T16525b, T16670, T16793, T18060, T18071, T18262.
   Each has its own `all.T` to parse; smaller than `prog0NN` but
   more bespoke.
2. Stage2 native-compile sweep — broader-scope (session 64
   HANDOFF priority #1).  Probably curated subset of
   `tests/simple/` or `tests/codeGen/`.
3. `tests/ghci/should_fail/` and `tests/ghci/should_run/` —
   sibling directories of the prog0NN family.  Different all.T
   format (one big all.T per directory with many test entries).
   Probably the cleanest natural follow-on since the staging
   shape is closest to what `run-ghci-progNNN.sh` already does.

## ✅ SESSION EXIT STATE

* `docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/scripts/run-ghci-progNNN.sh`
  — new runner, modelled on session 64's `run-ghci-tnum.sh` with
  three deltas: per-test-dir staging (recursive `cp -R`), test-name
  vs dir-name split for `ghci.prog00{7,8,9,10}`, and remote `HC` /
  `HC_OPTS` / `ghciWayFlags` env-var exports for scripts that do
  `:shell "$HC" ... -c X.hs` mid-test.
* `docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/scripts/normalise.py`
  — verbatim copy of session 64's normaliser.  No new rules.
* `docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/logs/01-run1.log`,
  `logs/02-run2.log` — both 17/17 PASS.
* `docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/logs/ghci-progNNN/`
  — per-test staged inputs + actual outputs + expected outputs.

No changes to `external/ghc-modern/ghc-9.2.8/` — verification only.

## TL;DR — the session-65 work

Same shape as sessions 56 / 57 / 62 / 63 (pure verification):
1. Pick a new test subdir family in upstream's testsuite.
2. Read every test's annotation; classify in-scope vs out-of-scope.
3. Adapt the existing runner shape to whatever new harness this
   family needs.
4. Run, debug to convergence, commit notes.

What's distinctive this time: per-test-dir staging (rather than
flat .script files in a single dir).  Came in clean first try
because session 64's runner had already absorbed every annotation
flavour the prog0NN subset uses.

## What to try next, in priority order

### Top: `tests/ghci/T<num>/` bug-numbered subdirs

10 directories: T11827, T13786, T16392, T16525a, T16525b, T16670,
T16793, T18060, T18071, T18262.  Each has its own `all.T` (or
`<name>.T`) plus per-test source files.

Different from the prog0NN family in two ways:

1. Each subdir's all.T may declare MORE than one test (some have a
   plain test + a `-prof` variant + a `-th` variant).  Need to
   parse and filter — annotations like `req_th`, `expect_broken`,
   etc. may apply per-test rather than per-directory.
2. Some use `compile_and_run` or `multimod_compile_and_run` rather
   than `ghci_script` — those won't fit this runner's REPL-driven
   shape.  Filter to `ghci_script`-shape tests only.

Estimated 1–2h.

### Second: `tests/ghci/should_run/` and `should_fail/`

`tests/ghci/should_run/all.T` has many `ghci_script` entries (a
quick `wc -l` says ~40+).  Similar shape to the prog0NN family —
multiple individual tests with various `extra_files` / `req_th` /
`reqlib` annotations.  Likely the path with the highest test-count-
per-session-effort ratio.

Estimated 2–4h depending on annotation variety.

### Third: stage2 native-compile sweep

The session-64-HANDOFF top option.  Run upstream's broader
testsuite (`tests/simple/`, `tests/codeGen/`, `tests/typecheck/`,
etc.) using the ppc-native stage2 as the test compiler, not just
GHCi scripts.  This is a much larger lift — the testsuite driver
itself is Python and assumes the test compiler is on the same
machine as the driver.  We'd need either:
(a) Run the driver on pmacg5 itself (Python on Tiger — `tiger.sh`
    ships python3.10 IIRC, so feasible).
(b) Write a `compile_and_run`-shaped wrapper that ssh's per-test
    (cross-build the .hs to .o on uranium, scp, ssh-run on
    pmacg5).

(a) is closer to upstream's design; (b) reuses our `runghc-tiger`
pattern from v0.5.0.  Pick a small starting target — `tests/simple/`
or `tests/typecheck/should_compile/` — and pilot the shape.

Estimated half-day to a full day.

### Fourth: ghci-ext way for prog001

prog001's upstream annotation includes `extra_ways(['ghci-ext'])`
which runs the test additionally with `-fexternal-interpreter`.
Our iserv-via-ssh bridge (v0.7.0) plumbing is available; would
make prog001 (and prog015/016/017 + several T-prefix tests) cross-
exercise the iserv path on the same source.  Would also surface
regression risk to the v0.8.0 TH machinery whenever the BR24
jump-island arithmetic or BCO byte-swap is touched.

Estimated 2–3h to wire one test as a smoke; 1–2h more to extend
the runner to do both ways per-test.

### Maintenance: HFS+ T8042 / T17549 mitigation

Same item as session 64 HANDOFF.  Still worth doing.

## What NOT to redo

* **Don't extend the prog0NN runner with prog004 or prog014.**
  prog004 is `makefile_test` — needs a different driver entirely
  (a stub makefile that runs the per-dir Makefile).  prog014 is
  `expect_fail` plus a `pre_cmd($MAKE -s prog014)` which builds a
  C-stub `.o` to load via foreign-import-prim; bytecode interpreter
  doesn't support that primitive class, so it's deliberately
  broken upstream.  Wiring either would be more work than the
  result is worth.

* **Don't expand `HC_OPTS` to include `-dcore-lint -dstg-lint
  -dcmm-lint -Werror=compat -dno-debug-output`.**  Those are
  upstream's developer-mode hygiene flags — they slow down each
  `:shell "$HC" ... -c X.hs` invocation without changing the test
  outcome.  Verified 17/17 PASS without them.

* **Don't drop `-no-user-package-db` from `HC_OPTS`.**  If the
  remote `~/.ghc/<arch>-<ver>/environments/` directory ever picks
  up a package env (eg. the v0.15.0 ghc-pkg demo at
  `demos/v0.15.0-ghc-pkg.sh` creates one transiently), tests that
  do `:shell "$HC" ... -c X.hs` would pick up packages we don't
  want them to see.

## Hosts (unchanged)

* **uranium**: runner driver.
* **pmacg5**: runs the v0.15.0 ppc stage2 ghc-real.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 65 of the ghc-darwin8-ppc project extended GHCi
test coverage to tests/ghci/prog001..prog019.  17/17 PASS on the
in-scope subset (skipped prog004 makefile_test and prog014
expect_fail+pre_cmd $MAKE).  Verification only — no GHC source
changes, no patches, no release.  Reusable runner at
docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/scripts/run-ghci-progNNN.sh
with three notable shape changes from session 64's runner:
per-test-dir staging via `cp -R` + tar, test-name vs dir-name
split for ghci.prog00{7,8,9,10}, and remote HC/HC_OPTS/ghciWayFlags
env exports for scripts that compile partial .o files mid-REPL.

Top next moves: tests/ghci/T<num>/ bug-numbered subdirs (10 dirs,
~1-2h), tests/ghci/should_run/ and should_fail/ (~40+ tests, 2-4h),
or pilot the stage2 native-compile sweep using Python on Tiger
(half-day to full day).

Read in order:
1. docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/HANDOFF.md
2. docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/README.md
3. docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/findings.md
4. docs/roadmap.md (for the broader priority list)

Hosts: uranium for source edits + cross-builds; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 66 ends, write the next handoff at:
`docs/sessions/<DATE>-session-66-<slug>/HANDOFF.md`.
