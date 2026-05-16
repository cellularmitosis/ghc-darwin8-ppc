# Handoff from session 64 → session 65

**For:** the next claude session.
**From:** session 64 — **v0.15.0 released**.  Patch 0010 carve-out
extended to `[iserv, unlit, ghcPkg, hsc2hs, hp2ps]`; new patch 0018
disables hadrian's bindist-side `ghc-pkg recache` for cross-builds.
`scripts/deploy-stage2.sh` ships ghc-pkg.  Runner extended with
T6106 + T19650 — the last unwired `pre_cmd(...)` annotations in the
T-prefix subset.  **175/177 PASS** (both new tests PASS; 2 failures
remain the HFS+ T8042 + T17549 coin-flips).  Bindist re-rolled +
tarball at `_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`;
demo + README + state.md + roadmap.md updated; tag pushed; GitHub
release uploaded.

**Recommended pickup:** **exploratory items** — every annotation
flavour in the T-prefix `tests/ghci/scripts/all.T` subset is now
wired into `run-ghci-tnum.sh`, so the natural next direction is
breadth (other test-suite areas) rather than deeper-into-the-same-
runner.  Highest-value targets:
1. Stage2 native-compile sweep (run upstream's broader testsuite
   using the ppc-native stage2 as the test compiler).
2. `prog001..prog019` (compile-and-run tests in `tests/ghci/prog0*/`).
3. Bug-numbered `T<num>/` subdirs (the *directory* variants).
4. Third-party library audit (Hackage top packages cross-build sweep).

## ✅ SESSION EXIT STATE

* `docs/sessions/2026-05-17-session-64-v0.15.0-ghc-pkg/scripts/run-ghci-tnum.sh`
  — session 63's runner with two new `pre_cmd_for()` arms (T6106
  `--make T6106_preproc -v0`, T19650 `ghc-pkg latest base >
  my_package_env`), one new arm each in `run_opts_for()` (T19650's
  `-package-env -v1`) and `norm_args_for()` (T19650's
  `--filter-stdout-regex 'Loaded package env.*'`), `eval`-wrap on
  the `norm` call sites, and two new TESTS entries (T6106 with
  explicit `../shell.hs` extras, T19650).
* `docs/sessions/2026-05-17-session-64-v0.15.0-ghc-pkg/scripts/normalise.py`
  — session 63's normaliser plus a new `filter_stdout_lines()`
  function and `--filter-stdout-regex` CLI flag.
* `docs/sessions/2026-05-17-session-64-v0.15.0-ghc-pkg/logs/00-runner-diff.log`,
  `logs/00-normalise-diff.log` — diffs vs session 63.
* `docs/sessions/2026-05-17-session-64-v0.15.0-ghc-pkg/logs/01-run1.log`
  — full run (**175/177 PASS**, both new tests PASS).
* `patches/0010-hadrian-cross-iserv.patch` — amended to add `ghcPkg`,
  `hsc2hs`, `hp2ps` to the carve-out.
* `patches/0018-hadrian-bindist-cross-skip-recache.patch` — new.
* `scripts/deploy-stage2.sh` — also `scp`s ghc-pkg to remote.
* `external/ghc-modern/ghc-9.2.8/hadrian/src/Rules/{Program,BinaryDist}.hs`
  — live source matches patches 0010 + 0018.
* `external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`
  — the v0.15.0 bindist tarball.
* `demos/v0.15.0-ghc-pkg.sh` — ghc-pkg smoke-test demo.
* `demos/README.md` — "What's here" header bumped to v0.15.0;
  v0.15.0 row added.
* `README.md` — Latest-release line replaced; GHCi REPL row updated
  with session 64 + v0.15.0 details; Releases table gained a row.
* `docs/state.md` — top entry bumped to session 64.
* `docs/roadmap.md` — §C session 64 entry added; last-reviewed bumped.

The tree is clean: source-tree edits all captured in the patches/
files; deploy-stage2.sh diff captured; bindist re-rolled; tag pushed;
GitHub release published.

## TL;DR — the session-64 work

Same shape as v0.14.1 / v0.14.2:
1. Identify a packaging or runtime bug from prior session.
2. Patch GHC source (here: hadrian's Rules/Program.hs +
   Rules/BinaryDist.hs).
3. Rebuild stage1.
4. Cross-build new helper(s); deploy to pmacg5.
5. Wire any newly-unblocked tests into the runner.
6. Re-roll bindist + tarball.
7. Demo + README + state.md + roadmap.md.
8. Tag + push + GitHub release.

What's distinctive this time: the *two* patches (carve-out extension
+ bindist-recache-skip) and the *three* new ppc helper binaries
(ghc-pkg / hp2ps / hsc2hs) — broader than v0.14.1's single `unlit`
fix.  All four newly-cross-built binaries are real `Mach-O executable
ppc` files; only ghc-pkg is auto-deployed by `deploy-stage2.sh`
(hp2ps + hsc2hs ride in the bindist for `install.sh` users).

## What to try next, in priority order

### Top: stage2 native-compile sweep

Run upstream's broader testsuite using the ppc-native stage2 as the
test compiler, not just GHCi scripts.  Scope: probably the `simple/`
or `ghc-api/` test dirs first — they don't need TH/REPL/static-pointer
plumbing.  Caveat: the testsuite driver itself is Python and may
have host-vs-target assumptions; might need a wrapper that ssh's to
pmacg5 per test.

Or alternatively: pick one specific compiler feature area
(`tests/typecheck/`, `tests/codeGen/`, `tests/simpl/`) and run a
curated subset, same shape as session 56's `run-ghci-subset.sh`.

### Second: `prog001..prog019`

`tests/ghci/prog0*/` are compile-and-run tests (multi-module, with
explicit `:load` and Main entry points).  Different shape from the
`scripts/` tests — each has its own subdir with multiple .hs files
plus a `prog0NN.script`.  Would need a small variant of
`run-ghci-tnum.sh` that handles per-test-dir staging.  ~19 tests.

### Third: bug-numbered `T<num>/` subdirs

The directory variants (not the `.script` files in
`tests/ghci/scripts/`).  These tend to be larger, multi-module
regressions — eg. `tests/ghci/T13366/`, `tests/ghci/T17832/`.  Each
has its own `all.T` to parse.  Less mechanical than the
single-`.script` cases.

### Possibly: ship `runghc` / `haddock` / `hpc`

`hadrian/src/Settings/Default.hs:stage1Packages` lists these as
`| not cross` — they're skipped entirely in cross-builds.  Bringing
them up is a larger project than v0.15.0 (each needs Haskell cross-
compilation, RTS, and possibly some platform-specific guards).
Could be a v0.16.0 release theme — "complete bindist part 2".

`runghc` is the highest-value of these three: it'd give us a
working "literate scripting" path on Tiger and unlock any prog/script
that uses a `#!/usr/bin/env runghc` shebang.

### Possibly: propose patch 0018 upstream

`unless cross $ do { ghc-pkg recache }` is upstream-shaped — applies
to any cross-build of GHC that ships a real target ghc-pkg in its
bindist.  Patch text is tiny.  Worth a GHC GitLab MR.

### Maintenance: HFS+ flake mitigation

T8042 + T17549 are independent HFS+ mtime-granularity coin-flips.
A local mitigation: retry these two tests up to N times each in
`run-ghci-tnum.sh`, PASS if any iteration passes.  Cleaner reporting
("175 deterministic + 2 flaky"); cleaner failure signal (if all N
retries fail, that's an actual regression).  Out of scope for this
session but worth considering.

## What NOT to redo

* **Don't add more helpers to the carve-out without checking they
  cross-build.**  ghc-pkg, hp2ps, hsc2hs all worked first try; future
  candidates (runghc, haddock, hpc) might not.  Sanity-check with
  `_build/stage1/bin/powerpc-apple-darwin8-<name>` first.
* **Don't deploy hp2ps + hsc2hs via `deploy-stage2.sh`.**  They ship
  in the bindist for users.  The test-runner workflow doesn't need
  them.  Adding them to the deploy script is harmless but unnecessary.
* **Don't try to remove the `package.cache` file from `_build/stage1/lib/`.**
  It was generated by stage0 (host) ghc-pkg at stage1-build time and
  is host-neutral within GHC 9.2.8.  Our `deploy-stage2.sh` rsyncs
  it to pmacg5 and the ppc ghc-pkg reads it fine.

## Hosts (unchanged)

* **uranium**: source edits, hadrian builds, runner.
* **pmacg5**: runs the v0.15.0 ppc stage2 ghc-real + ghc-pkg.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 64 of the ghc-darwin8-ppc project shipped v0.15.0
— the ghc-pkg packaging fix, same shape as v0.14.1's unlit fix.
Patch 0010 carve-out extended to `[iserv, unlit, ghcPkg, hsc2hs,
hp2ps]`; new patch 0018 disables hadrian's bindist-side `ghc-pkg
recache` for cross-compiles (after the carve-out fix that step
would try to exec a target ppc binary on the arm64 host).  Deployed.
Runner extended with T6106 + T19650 — the last unwired `pre_cmd(...)`
annotations in the T-prefix subset.  Result: 175/177 PASS (both new
tests PASS; 2 failures remain the HFS+ T8042 + T17549 coin-flips).
Tag pushed; GitHub release uploaded; bindist tarball at
`_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`.

Top next move: stage2 native-compile sweep (run upstream's broader
testsuite using the ppc-native stage2 as the test compiler, not just
GHCi scripts).  Other options: prog001..prog019, bug-numbered
T<num>/ subdirs, runghc / haddock / hpc bring-up (would be a v0.16.0
"complete bindist part 2" theme).

Read in order:
1. docs/sessions/2026-05-17-session-64-v0.15.0-ghc-pkg/HANDOFF.md
2. docs/sessions/2026-05-17-session-64-v0.15.0-ghc-pkg/README.md
3. docs/sessions/2026-05-17-session-64-v0.15.0-ghc-pkg/findings.md
4. docs/roadmap.md (for the broader priority list)

Hosts: uranium for source edits + cross-builds; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 65 ends, write the next handoff at:
`docs/sessions/<DATE>-session-65-<slug>/HANDOFF.md`.
