# Session 57 — GHCi debugger testsuite subset on PPC/Tiger

**Date:** 2026-05-16 (continuation of session 56).

**Status on arrival:** Session 56 verified the v0.14.0 REPL against
51/51 tests from upstream's `testsuite/tests/ghci/scripts/` — the
"simple-script" subset.  Its [HANDOFF.md](../2026-05-15-session-56-ghci-testsuite/HANDOFF.md)
flagged the next-best target as `tests/ghci.debugger/scripts/` — the
`:break` / `:step` / `:trace` / `:print` / `:force` / `:list` family —
on the grounds that **nothing in the project had previously tested the
bytecode-breakpoint machinery or call-stack-walking-from-BCOs code
paths**, making it the most likely place for a PPC-specific bug to
surface.

**Status on exit:** **83/83 PASS on a curated subset of upstream's
`testsuite/tests/ghci.debugger/scripts/`** — every clean
(non-`expect_broken`, non-`extra_run_opts`, non-`extra_hc_opts`,
non-`reqlib`) test in
`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci.debugger/scripts/all.T`.
No PPC bugs surfaced.  Two iterations of harness-side fixing flipped
the four run-1 failures to PASS; all four were testsuite-drift /
companion-file-discovery issues already encountered in session 56's
arc.  **Notably `T13825-debugger` passes** — that test is annotated
`expect_broken(14455)` for **powerpc64** but we're powerpc32 / unreg,
so it stayed in the subset, and it works.  **No GHC source-tree
changes, no new patches, no release tag.**

## Why this matters

Session 55 turned on the in-process REPL; session 56 covered the
basics (`:type`, `:info`, `:load`, `:reload`, `:browse`, `:m`,
`:def`, `:set prompt`, etc.).  The **debugger family** exercises code
paths that nothing in sessions 55 / 56 hit:

- **Bytecode breakpoint insertion** — `:break NAME` / `:break NUM`
  patches the BCO instruction stream with `BRK_FUN` opcodes that
  intercept execution at a precise source-mapped point.  This walks
  the BCO byte-swap path (patch 0014) at a different angle than
  forward-execution: forward-execution streams bytecode in;
  breakpoint insertion mutates it in place.
- **Suspended-thunk introspection** — `:print` / `:sprint` walk a
  heap value WITHOUT forcing it.  Exercises the runtime's closure-type
  dispatch (`THUNK`, `THUNK_SELECTOR`, `BLACKHOLE`, `WHITEHOLE`,
  partial-app structures), all of which are layout-sensitive on
  32-bit big-endian.
- **`:force`** — drives a thunk through `IND` redirection while live,
  then rebinds `_result`.  Touches indirection-following machinery
  in the bytecode dispatch loop.
- **`:step` / `:steplocal` / `:stepmodule`** — set transient
  breakpoints at every subexpression of the next reduction, runs
  until any fires.  Exercises the per-tick breakpoint table.
- **`:trace` + `:hist` + `:back` + `:forward`** — record a sliding
  window of recent breakpoint stops, replay them.  Walks the call
  stack of suspended BCOs.
- **`:list` / `:list NAME` / `:list NUM`** — source-location mapping
  from a BCO offset back to a file:line:col span.  Exercises the
  debug-info tables built into the BCO.
- **`:show breaks` / `:show context` / `:show bindings`** —
  state-inspection commands that walk the per-module breakpoint
  array and the current call-context's let-binding chain.
- **Dynamic breakpoint manipulation** — `:disable` / `:enable` /
  `:delete` mutate the breakpoint array at runtime.

If any of the layout assumptions in the BCO machinery were wrong on
PPC32 (32-bit pointers, big-endian word order, alignment) — or if
the suspended-thunk introspection path mishandled big-endian closure
headers — the debugger tests would surface it loudly.  They didn't.

## What was run

[`docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/scripts/run-ghci-debugger.sh`](scripts/run-ghci-debugger.sh)
selects 83 tests from upstream's
`testsuite/tests/ghci.debugger/scripts/all.T`.  Selection criteria
mirror session 56 with one extension:

- annotation is `normal` / `combined_output` / `extra_files(...)`
  (skip `reqlib`, `req_th`, `expect_broken`, `extra_run_opts`,
  `extra_hc_opts`);
- conditional `expect_broken` / `fragile` for archs other than ours
  (ppc32) is treated as "applies elsewhere, include here";
  specifically `T13825-debugger` (broken on `powerpc64`) and
  `break006` (broken under `compiler_debugged()`, which we are not).

Skipped:
- `print036` — `expect_broken(9046)`.
- `break015` — `expect_broken(1532)`.
- `break018` — `expect_broken(18004)`.
- `dynbrk005` — `expect_broken(1530)`.
- `hist001`, `hist002` — `extra_run_opts('+RTS -I0')` (the runner
  doesn't wire that through; deferrable).
- `T1620` — needs a subdirectory `T1620/` staged (the runner today
  does flat-file extras only).

Final list of 83 tests covers:
```
print001..print037 (35 tests; print036 skipped)
break001..break029 (22 tests; break015/018 skipped)
dynbrk001..dynbrk009 (6 tests; dynbrk005/006 skipped)
result001 listCommand001 listCommand002
T2740 T2950 T3000 T7386 T8487 T8557 T12458 T13825-debugger
T14628 T14690 T16700 T2215 T17989 T19157 getargs
```

For each, the runner:
1. Stages `<name>.script` + `<name>.stdout` + `<name>.stderr` +
   auto-discovered companion files (`<name>.*`, `<name>_*`) +
   explicit `extras` (pulled from `../` or same dir) into
   `pmacg5:/tmp/ghci-debugger-<pid>/<name>/`.
2. Runs the same `ghc --interactive` invocation session 56 uses
   (-v0 -ignore-dot-ghci -fno-ghci-history -fshow-warning-groups
   -fno-diagnostics-show-caret -fdiagnostics-color=never) and
   captures stdout + stderr separately (or merged via `2>&1` for
   combined_output tests).
3. Pipes both expected and actual through session-56's
   `scripts/normalise.py` (now extended — see below).
4. `diff -qw` (ignore whitespace) against expected.

## What happened (the harness debug arc)

**Run 1 (83 tests):** 79 PASS / 4 FAIL.

- `print019`, `break006`: stderr off-by-one in the
  "`...plus N instances involving out-of-scope types`" footer.
  Expected said 13 / 12; actual said 14 / 13.  Same shape as
  session 56's ghci008 fix (base-version drift); upstream's
  `normalise_errmsg` has a dedicated regex for this footer
  (`testlib.py:2261`) that masks the count.  Backported into the
  shared `normalise.py`:
  ```python
  s = re.sub(r'\.\.\.plus ([a-z]+|[0-9]+) instances involving out-of-scope types',
             r'...plus N instances involving out-of-scope types', s)
  ```
  Also pulled in `ghc-bignum-X.Y.Z` → `ghc-bignum-<VERSION>` from
  the same upstream function while we were touching it.
- `T2950`, `T3000`: companion files named
  `<testname><CapitalSuffix>.hs` (`T2950M.hs`, `T2950S.hs`,
  `T3000S.hs`) were missing from the staged test dir.  Our
  auto-discovery glob is `<name>.*` and `<name>_*` — neither matches
  `T2950M` (no separator).  Upstream's `all.T` leaves them out of
  `extra_files()` because upstream's driver stages every file in
  the test dir indiscriminately.  Fix: list them explicitly in
  the runner's TESTS array.

**Run 2 (same 83):** 83/83 PASS.

CPU time on pmacg5 for the 83-test pass: ~7 minutes (stage2 ghc
startup is the dominant cost; tests themselves run quickly).

## What this proves about the v0.14.0 REPL

For the debugger surface covered by these 83 scripts:

| Area | Tests | Status |
|---|---|---|
| `:print` / `:sprint` on thunks, lists, lambdas, GADTs | print001..print037 | ✅ (35 tests) |
| `:force` (drive a thunk through IND) | print001..print035 + break001..break009 | ✅ |
| `:break NUM` (set breakpoint by line number) | break001, break002, break009, break010, break011 | ✅ |
| `:break NAME` (set breakpoint on a function) | T3000, break019, break020, break021 | ✅ |
| `:break MOD.NAME` (qualified function break) | T3000, T2950 | ✅ |
| `:break MOD NUM` (set break in named module) | break001 | ✅ |
| `:step` / single-step execution | break003, break005, break006, break008..break014, T2740 | ✅ |
| `:steplocal` / `:stepmodule` | break026 | ✅ |
| `:trace` + `:hist` + `:back` + `:forward` | break003, break012, break013, break024..break027 | ✅ |
| `:list` / `:list NAME` / `:list NUM` | listCommand001, listCommand002 | ✅ |
| `:show breaks` / `:show context` / `:show bindings` | break001, break005, T3000 | ✅ |
| Dynamic enable/disable/delete of breakpoints | dynbrk001..dynbrk009 | ✅ |
| Polymorphic types preserved through breakpoint | break012 | ✅ |
| Unboxed-tuple types in `:print` | print035 (Unboxed.hs) | ✅ |
| GADT types in `:print` | print012..print014, print034 | ✅ |
| Function types in `:print` | print020, print021 | ✅ |
| `_result` binding rebinding | result001, T2740 | ✅ |
| Exception flow through suspended computation | T7386, T8487, T8557 | ✅ |
| Regression tests for specific issues | T2215, T2950, T3000, T12458, T13825-debugger, T14628, T14690, T16700, T17989, T19157 | ✅ |
| `expect_broken(14455)` for ppc64 — **we pass on ppc32** | T13825-debugger | ✅ |

Zero PPC- or endian-specific failures across the entire set.

## What this session did NOT do

* Did not run `tests/ghci.debugger/scripts/` tests with
  `extra_run_opts` (`hist001`, `hist002`) — those need `+RTS -I0`
  threaded through.  Easy follow-up if needed.
* Did not run `T1620` — pulls a subdirectory not flat files.
  Easy follow-up.
* Did not run the `tests/ghci.debugger/` `should_run/` subdir if
  any exists (it doesn't — debugger tests are all `ghci_script`).
* Did not run `tests/ghci/scripts/` `req_th` tests (session-56
  HANDOFF priority #2).
* Did not change any GHC source, did not produce a new bindist,
  did not tag a release.  Pure verification.

## Files added this session

- `docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/`
  - `README.md` (this)
  - `findings.md`
  - `commits.md`
  - `HANDOFF.md`
  - `scripts/run-ghci-debugger.sh` — the runner.
  - `scripts/normalise.py` → symlink to session 56's normaliser
    (now extended for `...plus N instances` and `ghc-bignum-<VERSION>`).
  - `logs/run-1-initial.log` — first run (79/83).
  - `logs/run-2-fixes.log` — second run (83/83).
  - `logs/ghci-debugger/` — per-test working dirs.
- `docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/normalise.py`
  — added the two upstream `normalise_errmsg` rules used by this
  session's run-2 (`...plus N instances` count erasure;
  `ghc-bignum-<VERSION>`).  Pure addition; session 56's expected
  output is unchanged because session 56's tests don't exercise
  either pattern.
- `README.md` — Implementation-status table updated.
- `docs/state.md` — top-of-file bumped to session 57.
- `docs/roadmap.md` — §C note added re: 83/83 debugger subset.
