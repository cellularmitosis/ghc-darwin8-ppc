# Session 56 findings

## TL;DR

51/51 of upstream's `ghci/scripts/` testsuite (the subset that
doesn't need extra harness — `normal` / `combined_output`
annotations, no `reqlib` / `req_th` / `expect_broken` /
`extra_hc_opts`) PASS on PPC/Tiger via the deployed v0.14.0
stage2 ghc.  No new patches, no source changes, no PPC bugs
surfaced.  All seven initial run-3 failures were testsuite-drift
or harness omissions: matching upstream's `normalise_errmsg` +
`normalise_callstacks` + `normalise_version` + `-fno-diagnostics-
show-caret` + `-fshow-warning-groups` + `diff -w` flipped them
all to PASS.

## Important harness lessons (for the next sweep)

### 1. Match `TEST_HC_OPTS` exactly

The upstream `testsuite/mk/test.mk` adds these to every test invocation,
and several `.stdout` / `.stderr` files only make sense under them:

```
-fno-warn-missed-specialisations    # only matters at -O; ghci tests are -O0
-fshow-warning-groups               # turns "[-Wfoo]" into "[-Wfoo (in -Wgroup)]"
-fdiagnostics-color=never           # strip ANSI VT codes
-fno-diagnostics-show-caret         # strip the |...|^^^^ source snippets
-Werror=compat                      # turn -Wcompat warnings into errors
-dno-debug-output                   # silence misc debug spew
```

Plus interactive-mode adds:
```
--interactive -v0 -ignore-dot-ghci -fno-ghci-history
```

Without `-fshow-warning-groups`, ghci031's deprecated-flag warning
diff'd off-by-`(in -Wdefault)`.  Without `-fno-diagnostics-show-caret`,
the same file's `|...|` snippet block was added unexpectedly.

### 2. Apply `normalise_*` to BOTH sides before diffing

Upstream's `compare_outputs` passes both expected and actual through
the same normaliser chain:

```python
expected_str = normaliser(read_no_crs(expected_path))
actual_str   = normaliser(actual_raw)
if whitespace_normaliser(expected_str) == whitespace_normaliser(actual_str):
    return True
```

The key transforms (`testlib.py:normalise_errmsg`):

- ` error:` → `` (strip the keyword)
- ` Warning:` → ` warning:`
- bullet `•` → `` (no replacement)
- `, called at PATH:LINE:COL in PKG:` → `, called at PATH:<line>:<column> in <package-id>:`
- `from ImplicitParams` → `from HasCallStack`
- `CallStack (from -prof):\n  ...` → ``
- Per-test `normalise_version('base'|'array'|...)`: `base-X.Y.Z` →
  `base-<VERSION>`

These exist precisely because `.stdout`/`.stderr` files in the tree
were generated against earlier GHC/base versions and the test
authors didn't want every base bump to break them.  Skipping these
normalisations means false-positive failures unrelated to the
compiler under test.

### 3. `combined_output` requires runtime stderr merge

`cat actual.stdout actual.stderr > actual.combined` after the fact
produces *wrong interleaving* because the streams flush at different
rates.  Use `ghc ... > combined 2>&1` so the kernel merges in write
order — this is what upstream's driver does (via `combined_output`).

### 4. Companion-file discovery is more than `<name>.*`

Upstream's driver auto-includes both `<testname>.*` AND `<testname>_*`
(underscore-suffixed).  Examples in our run:

- `ghci023.ghci` matched `ghci023.*`.
- `ghci027_1.hs`, `ghci027_2.hs` did NOT — they needed the
  underscore glob.

Explicit `extra_files(['Ghci025B.hs', ...])` in all.T is for
*differently-named* files (e.g. capitalisation as a module name).

### 5. Use `diff -w` (or `normalise_whitespace`)

ghci036's stderr had `    • Variable not in scope` → after bullet
strip → `     Variable not in scope` (one extra space).  Upstream
fixes this by calling `diff -uw` and also by collapsing whitespace
in a second pass.  `diff -qw` was enough for our purposes.

## What this proves about the v0.14.0 REPL

Section "What this proves" in [`README.md`](README.md) has the full
table.  Highlight: **TH splice driven from the REPL works**
(ghci018 PASS).  This is a fresh code-path stress test for the
in-process interpreter + BCO machinery + runtime Mach-O loader —
none of session 55's hand smoke tests typed TH at the REPL.

## What this leaves untested

- `tests/ghci/scripts/` tests filtered out by `reqlib`, `req_th`,
  `expect_broken`, `extra_hc_opts`, etc.  Several `req_th` ones are
  worth running (they'd cross-stress TH-at-REPL more).
- `tests/ghci/` subdirs other than `scripts/`: `T11827`, `T13786`,
  `T16670`, etc. (bug-numbered regressions), `prog001..prog019`
  (multi-module load tests), `should_run/`, `should_fail/`,
  `caf_crash/`, `linking/`.
- `tests/ghci.debugger/` (the `:break`/`:step`/`:trace`/`:print`
  family — never exercised on PPC).
- Real-tty interactive use of the REPL on Tiger (haskeline's
  terminal handling).  Still on the session-55 carry-forward list.

## Reusable artifacts

`scripts/run-ghci-subset.sh` + `scripts/normalise.py` are
self-contained.  To run again (e.g. after a stage2 redeploy):

```bash
bash docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/run-ghci-subset.sh
```

Override host: `bash run-ghci-subset.sh imacg4`.  Logs land under
`docs/sessions/.../logs/ghci-subset/<test>/`.

## What was NOT a real bug

Just to make this explicit (because the failure mode looks scary
the first time you see it):

- The actual stderr saying `<interactive>:1:1: error: Variable not
  in scope: nub` is **correct GHC 9.2.8 behaviour**.  The expected
  file just predates the `error:` keyword convention.  Not a bug.
- `base-4.16.4.0:Data.OldList.isPrefixOf` is the correct module
  qualifier for our base version.  Expected says `base-4.13.0.0`.
  Not a bug.
- Bullet characters in error messages are part of GHC's pretty-printer
  for `•`-separated `Variable not in scope:` hint sections.  Correct.

If you see these in a future sweep, run the actual output through
`scripts/normalise.py` first.
