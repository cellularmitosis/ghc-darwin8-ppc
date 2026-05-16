# Handoff from session 63 → session 64

**For:** the next claude session.
**From:** session 63 — extended `run-ghci-tnum.sh` with `reqlib(...)`
and simple `pre_cmd(...)` support; **173/175 PASS** on the now-175-
test T-prefix subset.  All 3 new tests (T5979, T5975a, T5975b) pass
clean on the first run.  Both T8042 + T17549 failed (HFS+ mtime
race; same shape as sessions 58/60/61/62 but unlucky on both
coin-flips at once).  No GHC source changes, no new patches, no
release.

**Recommended pickup:** **`$MAKE`-style `pre_cmd` tests** (T6106,
T19650, ghci056) — the last unwired annotation group in the T-prefix
subset.  Both need extra plumbing beyond the simple `pre_cmd_for()`:
either a native-compile step (T6106 needs `ghc --make T6106_preproc`
plus `../shell.hs`) or `ghc-pkg` deployment on pmacg5 (T19650).  Or
shift to one of session 59's exploratory items (bug-numbered `T<num>/`
subdirs, `prog001..prog019`, stage2 native-compile sweep, GHCi over
real ssh tty, etc.).

## ✅ SESSION EXIT STATE

* `docs/sessions/2026-05-17-session-63-reqlib-and-pre-cmd/scripts/run-ghci-tnum.sh`
  — session 62's runner extended with `pre_cmd_for()` lookup +
  one new arm each in `run_opts_for()` (T5975b) and `norm_args_for()`
  (T5979) + three new TESTS entries.
* `docs/sessions/2026-05-17-session-63-reqlib-and-pre-cmd/scripts/normalise.py`
  — byte-identical copy of session 62's normaliser (no new rules
  needed — `--version pkg` already supported since session 58).
* `docs/sessions/2026-05-17-session-63-reqlib-and-pre-cmd/logs/00-runner-diff.log`
  — diff against session 62's runner for quick audit.
* `docs/sessions/2026-05-17-session-63-reqlib-and-pre-cmd/logs/01-run1.log`
  — full run (**173/175 PASS**, both HFS+ flakes failed, all 3 new
  tests pass).
* `docs/state.md` — top entry bumped to session 63.
* `docs/roadmap.md` — §C session 63 entry added; last-reviewed
  date bumped.
* `README.md` — Implementation-status table's "GHCi REPL" row
  updated to mention the new 173/175 number + reqlib/pre_cmd
  coverage.

The tree is clean: no source-tree edits, no patches/, no release tag.

## TL;DR — the session-63 work

One new dispatcher function (`pre_cmd_for`) + one new
`run_opts_for()` arm (T5975b) + one new `norm_args_for()` arm (T5979)
+ three new TESTS entries.  All three new tests pass clean on the
first run.  No fixable failures introduced; the 2 failures are
pre-existing HFS+ mtime-race flakes (T8042 + T17549).  Empty .hs +
empty .script + `-v0` produces zero bytes — confirmed on host
ghc-9.14.1 before the pmacg5 run, then confirmed on pmacg5's 9.2.8.
UTF-8 filenames round-trip through SSH + bash heredoc + remote bash
cleanly with `LANG=en_US.UTF-8`.

## What to try next, in priority order

### Top: `$MAKE`-style `pre_cmd` tests (T6106, T19650, ghci056)

The three tests in the T-prefix subset that need richer pre-cmd
plumbing than `touch`:

**T6106** — `pre_cmd('$MAKE -s --no-print-directory T6106_prep')`
where `T6106_prep` is:

```makefile
T6106_prep:
	'$(TEST_HC)' $(TEST_HC_OPTS) -v0 --make T6106_preproc
```

i.e. compile `T6106_preproc.hs` to a native binary using the test
compiler.  Plus `extra_files(['../shell.hs'])` — a peer of
`scripts/`, not auto-discovered by our globs.

Plan:
1. Add `T6106` to TESTS list with explicit `shell.hs T6106_preproc.hs`
   extras (the runner's auto-glob already catches them via
   `${name}.*` for `T6106_*`).  For `../shell.hs`, the staging loop
   needs a new code path or a hardcoded copy.
2. Add a `pre_cmd_for(T6106)` returning something like
   `"/opt/ghc-stage2/bin/ghc-real --make T6106_preproc -v0"` —
   the same compiler used for the interactive test, run as a
   native build step on pmacg5.
3. Run.  Watch for the second `:reload` to detect that
   `T6106_preproc` regenerated `T6106.hs` between loads (this is
   what the test actually tests — that `:reload` re-runs the
   preprocessor).

**T19650** — `pre_cmd('$MAKE -s --no-print-directory T19650_setup')`
where `T19650_setup` is:

```makefile
T19650_setup:
	'$(GHC_PKG)' latest base > my_package_env
```

i.e. needs `ghc-pkg` on pmacg5.  As of session 63, `/opt/ghc-stage2/bin/`
contains only `ghc`, `ghc-real`, `ghc-real-debug`.  No `ghc-pkg`.
The stage2 ghc has its own `ghc-pkg` somewhere in the bindist
(`bin/ghc-pkg-9.2.8` in the binary-dist-dir layout); it just wasn't
deployed.

Plan:
1. Either ship `ghc-pkg` as part of the v0.15.0 bindist (small
   addition to the deploy script), or wire `pre_cmd_for(T19650)` to
   call the cross-built ghc-pkg from uranium and `scp` the result.
   The former is cleaner — `ghc-pkg` is genuinely missing from our
   deployed stage2 and adding it benefits every future test that
   needs it.
2. Also need `extra_hc_opts('-package-env my_package_env -v1')` —
   already wired via `run_opts_for()` (one new arm).
3. Also `filter_stdout_lines(r'Loaded package env.*')` — a new
   normaliser arg, e.g. `--filter-stdout-regex 'Loaded package env.*'`.

**ghci056** — `pre_cmd('$MAKE -s --no-print-directory ghci056_setup')`,
in a `ghciNNN`-shaped test name so it'd belong to session 56's
`run-ghci-numbered.sh` runner, not the T-prefix one.  Out of scope
for this runner but the same plumbing pattern applies.

### Second: handle the HFS+ flake at the runner level

Session 62 / 63 both said "the right durable fix is upstream's, not
ours."  But a *local* mitigation is also reasonable: rerun T8042 +
T17549 N times each and PASS if any run passes.  Implementation: a
loop in the runner's diff step for these two tests (or a generic
`flaky_tests` set).

Pros: noise-free PASS/FAIL reporting; the runner score becomes a
clean signal that catches new regressions.  Cons: hides legitimate
breakage in T8042 / T17549.  Mitigation: only allow up to 3 retries
before still reporting FAIL.

### Third + onwards

Unchanged from session 62 HANDOFF:

- bug-numbered `T<num>/` subdirs (the *directory* variants, not the
  `.script` variants in this subset).
- `prog001..prog019` (compile-and-run tests in `tests/ghci/prog0*/`).
- GHCi over a real ssh tty (interactive editing, history, completion).
- extend session 57's debugger runner with `pre_cmd` / `extra_files`.
- stage2 native-compile sweep (run upstream's broader testsuite
  using the ppc-native stage2 as the test compiler, not just GHCi
  scripts).
- patch 0016 refactor (the array `STUArray Bool` fix — propose
  upstream).
- third-party library audit (check Hackage's most-depended-on
  packages for any that don't cross-build cleanly).

### Possibly: ship `ghc-pkg` in the v0.15.0 bindist

Independent of T19650, the deployed stage2 is missing `ghc-pkg`,
`runghc`, `runhaskell`, `haddock`, `hpc`, and probably others.
Worth a separate sweep over the binary-dist-dir contents to see
what's available and what's currently in `/opt/ghc-stage2/bin/` —
this could be a v0.15.0 release theme ("complete bindist") that
benefits every test that uses one of the missing tools.

## What NOT to redo

* **Don't try to fix T8042 / T17549** by editing upstream's `.script`
  files.  Same advice as session 62 — upstream's testsuite, not GHC.
  If you want a local fix, do it in the runner (retries), not the
  scripts.
* **Don't widen `pre_cmd_for()` to handle `$MAKE` targets** with a
  one-liner.  The Make targets each call into upstream's
  `mk/test.mk` substitution machinery (`$(TEST_HC)`, `$(GHC_PKG)`,
  `$(TEST_HC_OPTS)`).  Either implement those substitutions in
  bash, or use a different harness shape entirely (e.g., let
  `pre_cmd_for` return a full shell snippet that uses our absolute
  paths directly).
* **Don't re-extend `norm_args_for()` for every reqlib test** with
  redundant `--version pkg` flags.  Only tests whose expected file
  has a literal version number need this.  T5979 was the only one
  in this subset; check the actual upstream expected file before
  adding an arm.
* **Don't trust session 62's claim that exactly one of T8042/T17549
  fails per run.**  Both can fail (sessions 58, 63).  Treat them as
  independent coin-flips.

## Hosts (unchanged from session 62)

* **uranium**: runner / normaliser edits.
* **pmacg5**: runs the v0.14.2 ppc stage2 ghc binary
  (`/opt/ghc-stage2/bin/ghc-real`).  Untouched this session.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 63 of the ghc-darwin8-ppc project extended session
62's ghci-tnum runner with `reqlib(...)` and simple `pre_cmd(...)`
support — a new `pre_cmd_for()` lookup function, one new arm each
in `run_opts_for()` (T5975b) and `norm_args_for()` (T5979), and
three new TESTS entries (T5975a, T5975b, T5979).  All three new
tests pass clean on the first run.  Result: 173/175 PASS on the
now-175-test T-prefix subset.  The two failures are both T8042
*and* T17549 (HFS+ mtime race — both writeFile-pairs landed in the
same HFS+ second in this run).  No GHC source changes, no patches,
no release.

Top next move: wire the `$MAKE`-style `pre_cmd` tests (T6106,
T19650).  T6106 needs a native compile step (`ghc --make
T6106_preproc`) + the `../shell.hs` extra-file.  T19650 needs
`ghc-pkg` deployed on pmacg5 (currently missing — only `ghc`,
`ghc-real`, `ghc-real-debug` are in `/opt/ghc-stage2/bin/`).  Or
shift to one of session 59 HANDOFF's exploratory items (prog001..019,
stage2 native compile sweep, etc.).

Read in order:
1. docs/sessions/2026-05-17-session-63-reqlib-and-pre-cmd/HANDOFF.md
2. docs/sessions/2026-05-17-session-63-reqlib-and-pre-cmd/README.md
3. docs/sessions/2026-05-17-session-63-reqlib-and-pre-cmd/findings.md
4. docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/HANDOFF.md (for prior context)
5. docs/roadmap.md (for the broader priority list)

Hosts: uranium for runner edits; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 64 ends, write the next handoff at:
`docs/sessions/<DATE>-session-64-<slug>/HANDOFF.md`.
