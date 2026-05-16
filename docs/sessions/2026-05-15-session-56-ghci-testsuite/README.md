# Session 56 — GHCi testsuite subset on PPC/Tiger

**Date:** 2026-05-15 (continuation of session 55).

**Status on arrival:** v0.14.0 shipped (session 55) enabled the
in-process GHCi REPL on PPC/Tiger.  Verified at the time only via
hand-typed smoke tests in `demos/v0.14.0-ghci-repl.sh` (~15-20
expressions).  Roadmap §C ✅; session 55's HANDOFF flagged the top
follow-up as "run a curated subset of upstream's GHCi testsuite on
pmacg5" since the full driver isn't easily portable to a remote
PPC stage2.

**Status on exit:** **51/51 PASS on a curated subset of upstream's
ghci/scripts/ tests** — every clean (non-reqlib, non-expect_broken,
non-extra_hc_opts) `ghciNNN` test in
`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T`,
plus the two combined_output ones with embedded callstacks
(ghci055) and base-version refs (ghci008).  No PPC bugs surfaced;
every failure during the run-debug loop was a harness-side issue
matched in upstream's test driver (`-fno-diagnostics-show-caret`,
`-fshow-warning-groups`, the " error:" / bullet strip, callstack
elision, `diff -w`).  Adds a reusable
[`scripts/run-ghci-subset.sh`](scripts/run-ghci-subset.sh) +
[`scripts/normalise.py`](scripts/normalise.py) harness for future
GHCi sweeps.  **No GHC source-tree changes, no new patches, no
release.**

## Why this matters

Session 55 turned on the REPL with one CPP flag, then verified it
worked across ~15-20 hand-typed expressions.  The internal
interpreter sits on top of: runtime Mach-O loader (patches
0009/0012), BCO byte-swap (0014), `__eprintf` stub (0011), iserv
plumbing (0010), stage2 native compiles without `-A1G` (patch 0016
/ v0.13.0).  All of these have failure modes that hand-typed smoke
tests would miss — e.g. specific opcodes in the bytecode dispatch
loop, or `:browse`'s walk over the symbol table.

Running upstream's own tests exercises far more REPL surface than
we'd think to write by hand.  Of the 51 tests, several specifically
exercise pieces that nothing else in our project has hit:

- **TH splice driven from the REPL** (ghci018): `$( do runIO ...;
  [| 'x' |] )` typed at the prompt.  This is a different code path
  from v0.8.0's TH-via-file end-to-end, because the splice's host
  computation runs in the *same* interpreter the REPL is hosted on.
- **`:browse`, `:browse!`, `:instances`** (ghci023, ghci025, ghci064):
  walk the symbol/instance tables for `Data.Maybe`, exported
  modules, and overlapping instance candidates.
- **`:reload` with file-timestamp tricks** (ghci063): manipulate
  mtime to fool the build-state cache, force a real reparse.  Tests
  GHCi's interface-file cache invariants.
- **GADTs in REPL** (ghci030), **type-family in REPL** (ghci046),
  **record-wildcards in REPL** (ghci049), **promoted constructors
  in `:i`** (ghci053).  Each one walks a different chunk of the
  pretty-printer + scope resolution.
- **`:doc` on a built-in** (ghci066): pulls haddock metadata via
  the in-process interpreter.
- **Static pointers** (ghci061): exercises the StaticPointers
  language extension's table machinery from the REPL.

Hand smoke tests wouldn't have hit most of these.  All work.

## What was run

[`docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/run-ghci-subset.sh`](scripts/run-ghci-subset.sh)
selects 51 tests from upstream's
`testsuite/tests/ghci/scripts/all.T`.  Selection criteria:
- annotation is `normal` or `combined_output` (skip `reqlib`,
  `req_th`, `req_interp`, `expect_broken`, `expect_fail`, `fragile`,
  `extra_hc_opts`, `when(...)`, `unless(...)`, `skip`);
- file-only (no `../shell.hs` / `../prog002` cross-dir refs — that
  excluded ghci026 and ghci038).

Final list of 51:

```
ghci001 ghci002 ghci003 ghci005 ghci007 ghci008 ghci009
ghci011 ghci012 ghci013 ghci018 ghci019 ghci020 ghci021 ghci022 ghci023
ghci025 ghci027 ghci028 ghci029 ghci030 ghci031 ghci032 ghci033 ghci034
ghci035 ghci036 ghci039 ghci040 ghci041 ghci042 ghci043 ghci044 ghci044a
ghci045 ghci046 ghci047 ghci048 ghci049 ghci050 ghci051 ghci052 ghci053
ghci054 ghci055 ghci059 ghci060 ghci061 ghci063 ghci064 ghci066
```

For each, the runner:
1. Stages the `<name>.script` + `<name>.stdout` + `<name>.stderr` +
   auto-discovered companion files (`<name>.*` and `<name>_*.*`) to
   `pmacg5:/tmp/ghci-subset-<pid>/<name>/`.
2. Runs `ghc --interactive -v0 -ignore-dot-ghci -fno-ghci-history
   -fshow-warning-groups -fno-diagnostics-show-caret
   -fdiagnostics-color=never < <name>.script` capturing stdout +
   stderr.  combined_output tests use `2>&1` at the shell level so
   interleaving matches upstream's diff.
3. Normalises BOTH expected and actual outputs via
   `scripts/normalise.py` (mirrors `normalise_errmsg` /
   `normalise_callstacks` / `normalise_version` from
   `testsuite/driver/testlib.py`).
4. `diff -qw` (ignore whitespace) against expected, mirroring the
   upstream driver's `diff -uw` + `normalise_whitespace`.

## What happened (the harness debug arc)

The result is "51/51 PASS" but it took five runs to get there.
Each round of failures was harness-side, not PPC-side; documenting
the iterations because the next person doing a sweep will see the
same failure shapes:

**Run 1 (21-test seed):** 18 PASS / 3 FAIL.
- ghci005: combined_output mismatch.  Concatenating stderr after
  stdout (`cat actual.stdout actual.stderr > combined`) gives the
  wrong interleaving — error lines must be merged at runtime via
  `2>&1` so the kernel preserves write ordering.
- ghci023: stdout missing last two lines, stderr has "file does
  not exist" exception.  The script does `:cmd readFile
  "ghci023.ghci"`; we hadn't shipped the companion `.ghci` file.
- ghci031: stderr `[-Wdeprecated-flags]` vs expected
  `[-Wdeprecated-flags (in -Wdefault)]`, plus the actual had the
  `|...|` source-snippet that the expected omits.
  Fixes: (a) auto-discover any `<name>.*` companion files; (b)
  add `-fshow-warning-groups -fno-diagnostics-show-caret` (which
  upstream's `testsuite/mk/test.mk` adds via `TEST_HC_OPTS`).

**Run 2 (same 21):** 21/21 PASS.

**Run 3 (expanded to 51):** 44 PASS / 7 FAIL.
- ghci008: `base-4.16.4.0` (actual) vs `base-4.13.0.0` (expected).
  Upstream handles this via `normalise_version('base')`.
- ghci021, ghci022, ghci048: `error:` keyword shows up in actual
  but is stripped from expected.  Upstream's `normalise_errmsg`
  does the strip on BOTH sides.
- ghci036: bullet character `•` removed by normalisation but the
  trailing space remains, creating a 1-space offset.
- ghci055: callstack line/column numbers in `GHC/Err.hs` shifted
  between base versions.  Upstream's `normalise_callstacks`
  rewrites `, called at PATH:LINE:COL in PKG:` to a fixed token.
- ghci027: stdout completely empty, but expected has 10 lines.
  Companion files `ghci027_1.hs` / `ghci027_2.hs` weren't picked
  up (auto-discover only matched `ghci027.*`, not `ghci027_*`).
  Fix: also glob `${name}_*`.

**Run 4 (with `normalise.py`):** 49 PASS / 2 FAIL.  ghci008,
ghci021, ghci022, ghci048, ghci055 all flipped to PASS via the
normalisations.  ghci027 still failed (no companion files);
ghci036 still failed (whitespace).

**Run 5 (with `_*` glob + `diff -qw`):** 51/51 PASS.

Total CPU time on pmacg5 for the 51-test pass: about 5 minutes
(stage2 ghc startup + script execution serially, no parallelism).

## What this proves about the v0.14.0 REPL

For the GHCi REPL surface area covered by the 51 scripts:

| Area | Tests | Status |
|---|---|---|
| `:type` / `:t` on builtins, ops, user-defined | 001, 011, 012, 013, 020, 042 | ✅ |
| `:info` / `:i` on classes, instances, GADTs, records | 011, 030, 042, 050, 053 | ✅ |
| `:set` / `:unset` flags, `+t`, `+s`, prompt-function | 005, 035, 060, 061 | ✅ |
| `:def`, `:undef`, `:cmd` macros | 005 | ✅ |
| `:load`, `:reload`, `:r`, `:l` (with .hs companions) | 019, 022, 027, 031, 033, 063 | ✅ |
| `:browse`, `:browse!`, `:instances` | 023, 025, 064 | ✅ |
| `:m`, `:m +`, `:m -`, `import` hiding/as | 002, 036, 041, 045 | ✅ |
| `:main`, `:run`, `:set args`, `:set prog` | 009, 029 | ✅ |
| Multi-line `:{ :}` blocks | 023, 039 | ✅ |
| Layout in REPL (indent, layout rule) | 023, 028 | ✅ |
| UTF-8 input on stdin | 028 | ✅ |
| TemplateHaskell splice driven from REPL | 018 | ✅ |
| `:doc` haddock metadata lookup | 066 | ✅ |
| Static pointers | 061 | ✅ |
| Type/data shadowing diagnostics | 040, 048, 052 | ✅ |
| Type-family, GADT, record-wildcards in REPL | 030, 046, 049, 050 | ✅ |
| Deprecation / scope warnings | 031, 034, 035, 036 | ✅ |
| Exception output + callstacks | 055 | ✅ |
| `getCurrentDirectory` and other side-effecting IO at prompt | 032 | ✅ |
| `System.Exit.exitFailure` from REPL doesn't kill the host | 007 | ✅ |
| `it` rebinding semantics | 003 | ✅ |

Zero PPC- or endian-specific failures across this set.

## What this session did NOT do

* Did not run `tests/ghci/` subdirs *other* than `scripts/`
  (i.e. `T11827`, `T13786`, `T16670`, etc. — bug-numbered
  regression tests; also `prog001..prog019`, `should_run/`,
  `should_fail/`, `caf_crash/`, `linking/`).  Each subdir has
  its own driver shape and would need a per-test (or per-subdir)
  ingestor.  Reasonable next step but out of scope here.
* Did not test the GHCi *debugger* (`:break`, `:step`, `:trace`,
  `:print`, `:list`, `:back`, `:forward`, `:show context`).  Most
  debugger tests live under `tests/ghci.debugger/`.  Different
  testsuite tree; would benefit from a separate sweep.
* Did not run `tests/ghci/scripts/` tests that were filtered out
  (`reqlib('QuickCheck')`, `req_th`, `expect_broken(NNNN)`, etc.).
  Many of those are worth running — `req_th` ones especially —
  but each filter category needs the runner to handle e.g.
  package availability checks.
* Did not test the REPL over a real ssh tty (haskeline's terminal
  handling on Tiger).  Still on the carry-forward list from
  session 55.
* Did not change any GHC source, did not produce a new bindist,
  did not tag a release.  This session is pure verification.

## Files added this session

- `docs/sessions/2026-05-15-session-56-ghci-testsuite/`
  - `README.md` (this)
  - `findings.md`
  - `commits.md`
  - `HANDOFF.md`
  - `scripts/run-ghci-subset.sh` — the harness.
  - `scripts/normalise.py` — upstream-equivalent output normaliser.
  - `logs/run-{1..5}-*.log` — the harness-debug arc.
  - `logs/ghci-subset/` — per-test working dirs (script, expected,
    actual.{stdout,stderr,combined}) for the final run.
- `README.md` — Implementation-status table updated.
- `docs/state.md` — top-of-file bumped to session 56.
- `docs/roadmap.md` — §C note added re: 51/51 testsuite subset.
