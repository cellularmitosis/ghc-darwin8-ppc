# Session 67 — should_run + should_fail runner; 44/44 PASS

**Date:** 2026-05-17 (continuation of session 66).

**Status on arrival:** v0.15.0 shipped in session 64; session 65
added the prog001..prog019 subset runner (17/17 PASS); session 66
added the T-prefix per-dir subset runner (7/8 PASS, with T16525a
SIGSEGV documented).  Session 66's HANDOFF priority #1: cover
`tests/ghci/should_run/all.T` and `tests/ghci/should_fail/all.T`
— the two remaining flat-per-file GHCi-script families upstream.

**Status on exit:** New runner
[`scripts/run-ghci-should.sh`](scripts/run-ghci-should.sh) at
**44/44 PASS** across two consecutive runs.  No GHC source changes,
no new patches, no release.  Four tests skipped as out-of-shape
(BinaryArray, T3171, T18064, T15633a/b — see "Scope" below).

## What was done

### 1. Scoped the should_run/ + should_fail/ families

`should_fail/all.T` is 7 lines — all `ghci_script`, all in-scope.

`should_run/all.T` is 39 tests across three annotation shapes:

| Shape | Count | Tests | Decision |
|-------|-------|-------|----------|
| `ghci_script` + `just_ghci` | 29 | T9914..T19460 (see runner header) | **IN** |
| `compile_and_run` + `just_ghci` | 8 | ghcirun001..004, T2589, T2881, T8377, T19628 | **IN** — new shape this session |
| `compile_and_run` + `normal` | 1 | BinaryArray | OUT — not GHCi-only |
| `makefile_test` | 1 | T3171 | OUT — wrong harness |
| `when(leading_underscore(),skip)` | 1 | T18064 | OUT — Mach-O has leading underscores |
| `pre_cmd($MAKE ... plugin)` | 2 | T15633a, T15633b | OUT — plugin build outside ghci-script scope |

Total in-scope: 7 (should_fail) + 37 (should_run) = **44 tests**.

### 2. Designed the runner

`run-ghci-should.sh` is the first ghci runner to handle two source
dirs (`should_run/` and `should_fail/`) and two test kinds in one
shape.  Key additions vs session 62's `run-ghci-tnum.sh`:

- **Family selector** (`sr` / `sf`) per test, with `src_dir_for()`
  resolving to the right `tests/ghci/should_*/` directory at
  staging time.
- **`compile_and_run` kind**: for these tests, the runner generates
  a synthetic "genscript" that mirrors upstream's
  `testsuite/driver/testlib.py::interpreter_run`:

  ```
  :set prog <name>
  :set args
  :! echo ===== program output begins here
  :! echo 1>&2 ===== program output begins here
  System.IO.hSetBuffering System.IO.stdout System.IO.LineBuffering
  GHC.TopHandler.runIOFastExit Main.main Prelude.>> Prelude.return ()
  ```

  Invocation: `ghc --interactive <name>.hs < genscript`.  The
  delimiter line lets us split `actual.{stdout,stderr}` into
  `comp.*` (compiler banner / messages — discarded) and `run.*`
  (program output — compared to expected).
- **`split_by_delim()`** helper does the awk-based split; falls
  back to "everything is run output" if the delimiter is absent.
- **`--version ghc` normaliser** wired for T15055 only.  T15055's
  expected `.stderr` hardcodes `'ghc-8.5'`; with the normaliser
  both expected and actual become `'ghc-<VERSION>'` and match.

### 3. Verification

Run 1 (initial): 43/44 PASS.  T18027 (`:script` with spaces in the
filename) fails — its companion file `T18027 SPACE IN FILE
NAME.script` isn't matched by the `$name.*` auto-discovery glob
(next char after `T18027` is a space, not a dot).

Fix: add `extras_for() { T18027 → "T18027:SPACE:IN:FILE:NAME.script"; }`
with a `:` → ` ` translation step at copy time (so the
whitespace-split shell loop sees one token instead of five).

Run 2: 44/44 PASS.
Run 3 (stability): 44/44 PASS.

## What this means

- **`tests/ghci/should_run/` and `should_fail/` are now wired.**
  44/44 PASS, zero new PPC-port issues surfaced this session.
- **Runner now handles the `compile_and_run` GHCi shape.**  The
  synthetic-genscript pattern (mirroring upstream's
  `interpreter_run`) brings 8 previously-uncovered tests under
  test, including `ghcirun001..004` which directly exercise the
  GHCi compile + execute path.
- **Strong v0.15.0 confidence boost.**  After this session,
  exercised GHCi-script testsuite coverage stands at:

  | Family | Sub-shape | Count | Source |
  |--------|-----------|-------|--------|
  | `tests/ghci/scripts/` (T-prefix) | flat ghci_script | 175/177 | sessions 56–64 |
  | `tests/ghci/prog0NN/` | per-dir ghci_script | 17/17 | session 65 |
  | `tests/ghci/T<num>/` | per-dir ghci_script | 7/8 | session 66 |
  | `tests/ghci/should_fail/` | flat ghci_script | 7/7 | **this session** |
  | `tests/ghci/should_run/` | flat ghci_script + compile_and_run | 37/37 | **this session** |

  Combined: **243/246** GHCi-style tests across 5 families.

  Three known failures total: HFS+ mtime-granularity flakes in
  T8042 / T17549 (from session 64), and the T16525a SIGSEGV in
  the runtime-linker unload path (from session 66).  No new
  failures this session.

## Files added this session

- `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
- `scripts/run-ghci-should.sh` — the new runner.
- `scripts/normalise.py` — verbatim copy of session 66's.
- `logs/01-run1.log`, `02-run2.log`, `03-run-final.log` — run logs.
- `logs/ghci-should/<test>/...` — per-test staged inputs + actuals
  + expecteds + (for compile_and_run) {comp,run}.{stdout,stderr}
  splits.

## Hosts

- **uranium** — runner driver.
- **pmacg5** — runs the v0.15.0 ppc stage2 ghc-real.
- **indium** — not used.

## What's next

See [`HANDOFF.md`](HANDOFF.md).
