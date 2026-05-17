# Handoff from session 67 → session 68

**For:** the next claude session.
**From:** session 67 — verification-only, **44/44 PASS** on the
`tests/ghci/should_run/` + `tests/ghci/should_fail/` subsets.  New
runner `scripts/run-ghci-should.sh`.  No GHC source changes, no
patches, no release.  Zero new PPC-port issues surfaced.

**Recommended pickup, in priority order:**

1. **Stage2 native-compile sweep** — promoted from #2 of session 66's
   HANDOFF.  Now that GHCi-script coverage is comprehensive across 5
   families (243/246 tests), the next high-leverage move is running
   upstream's broader native-compile testsuite using the ppc-native
   stage2 as the test compiler.  Half-day to a full day; see the
   "Pilot shape" section below.

2. **T16525a SIGSEGV RTS investigation (or scoped proposal)** —
   carried forward from session 66.  The bisection in
   `docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/logs/T16525a-segv-bisect.md`
   characterises the trigger to 3 conditions and 5 .script lines.
   Next steps: read `rts/Linker.c` `unloadObj`, `markObjectCode`,
   and the GC code-scan paths (`rts/sm/Sanity.c`, `scavenge_stack`),
   then try reproducing under `+RTS -Dl -Dg`.  Worth scoping with a
   proposal under `docs/proposals/` before committing to the work.

3. **Remaining ghci test subdirs (low yield):**
   - `tests/ghci/linking/` — runtime-linker stress tests.  Worth
     checking for ppc-relevant coverage.
   - `tests/ghci/caf_crash/` — CAF reachability under bytecode/object
     load mix.  Small.
   - `tests/ghci/Makefile` references — anything `makefile_test`
     that needs a separate harness; eg. T13786, T16670_unboxed,
     T16670_th from session 66.  Build the `makefile_test` harness
     once and you unlock all `makefile_test` GHCi tests at once.

## ✅ SESSION EXIT STATE

* `docs/sessions/2026-05-17-session-67-ghci-should-runner/scripts/run-ghci-should.sh`
  — new runner.  Handles two source dirs (`should_run/` +
  `should_fail/`) and two test kinds (`ghci_script` +
  `compile_and_run`) in one shape.  ~270 lines; ~50 of those are
  net-new beyond session 62's runner.  Synthetic genscript replicates
  upstream's `testsuite/driver/testlib.py::interpreter_run` for the
  compile_and_run path.
* `docs/sessions/2026-05-17-session-67-ghci-should-runner/scripts/normalise.py`
  — verbatim copy of session 66's normaliser.
* `docs/sessions/2026-05-17-session-67-ghci-should-runner/logs/0[1-3]-*.log`
  — three run logs; the final two both 44/44 PASS.
* `docs/sessions/2026-05-17-session-67-ghci-should-runner/logs/ghci-should/`
  — per-test staged inputs + actual outputs + expected outputs +
  (for `compile_and_run`) `{comp,run}.{stdout,stderr}` splits.

No changes to `external/ghc-modern/ghc-9.2.8/` — verification only.

## TL;DR — the session-67 work

Same shape as sessions 56 / 57 / 62 / 63 / 65 / 66 (pure verification):

1. Pick a new test family in upstream's testsuite.
2. Read every test's annotation; classify in-scope vs out-of-scope.
3. Adapt the existing runner to whatever new harness this family
   needs.  This time: extend, not simplify — added two-family
   source-dir selection and the `compile_and_run`-ghci shape.
4. Run, debug to convergence, commit notes.

What's distinctive this time: the runner is now the first one to
handle two source dirs and two test kinds in one file.  After the
~50 lines of extension code, all 44 in-scope tests passed.  One
companion-filename whitespace issue (T18027) was the only debug.

## What to try next, in priority order

### Top: stage2 native-compile sweep

Session 66 had this as priority #2; now promoted to #1 since the
GHCi-script families are largely exhausted (243/246 = 98.8%
combined pass rate across 5 families).

**Pilot shape (suggested):**

Start with `tests/typecheck/should_compile/` — typecheck-only tests
that don't need to link or run, so they're maximally
infrastructure-light.  Build a runner that:

1. For each test: scp the `.hs` to pmacg5.
2. Run `ghc -c -fno-code <name>.hs` remotely (or `ghc --make`
   without `-o`).  Captures typecheck stderr.
3. Compare against the expected `.stderr`.

If that lands cleanly, extend to:
- `tests/typecheck/should_fail/` — same shape but expecting
  non-zero rc.
- `tests/codeGen/should_run/` — needs full compile + run via
  `runghc-tiger` semantics (which we already have).
- `tests/simple/`.

Alternative: run upstream's Python driver on pmacg5 directly
(`tiger.sh` provides python3.10).  Heavier setup but closer to
upstream behaviour.

Estimated half-day to a full day depending on which sub-suite is
piloted first.

### Second: T16525a SIGSEGV RTS investigation

Unchanged from session 66's HANDOFF — same reasoning, same starting
steps.  Worth a `docs/proposals/` write-up before committing.

### Third: low-yield ghci subdirs

`tests/ghci/linking/`, `tests/ghci/caf_crash/`, and the
`makefile_test` family.  Each is small; together they might add 10
or so more tests to the count.  Lowest leverage of the three.

### Maintenance: propagate the lethal-signal detection update

Same item carried from session 66.  rc=138 (SIGBUS) and rc=139
(SIGSEGV) detection landed in `run-ghci-Tdir.sh` (session 66) and
this session's `run-ghci-should.sh`.  Still pending in:
- `docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/scripts/run-ghci-progNNN.sh`
- `docs/sessions/2026-05-17-session-{60,62,63,64}-*/scripts/run-ghci-tnum.sh`

Five minutes of edits per runner.  Drop-in patch.

### Maintenance: HFS+ T8042/T17549 mitigation

Same item carried from sessions 64+65+66 HANDOFFs.

## What NOT to redo

* **Don't try to wire BinaryArray, T3171, T18064, T15633a, T15633b
  into this runner.**  Each is out-of-shape for the reasons
  documented in the runner header.  BinaryArray belongs in the
  future native-compile sweep; T3171 / T15633a / T15633b need a
  makefile/plugin harness; T18064 is correctly skipped on
  leading-underscore platforms.

* **Don't try to extend the runner to handle pre_cmd($MAKE ...).**
  If we ever do plugin tests, build them in the staging step from
  uranium (where Make is reliable), not as a remote pre_cmd.

## Hosts (unchanged)

* **uranium**: runner driver.
* **pmacg5**: runs the v0.15.0 ppc stage2 ghc-real.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 67 of the ghc-darwin8-ppc project extended GHCi
test coverage to tests/ghci/should_run/ + tests/ghci/should_fail/.
44/44 PASS on the in-scope subset across two consecutive runs.
Zero new PPC-port issues.  Verification only — no GHC source
changes, no patches, no release.  Reusable runner at
docs/sessions/2026-05-17-session-67-ghci-should-runner/scripts/run-ghci-should.sh
— first runner to handle two source dirs and two test kinds
(ghci_script + compile_and_run) in one shape.  compile_and_run
support replicates upstream's interpreter_run via a synthetic
genscript.

Combined GHCi-style testsuite coverage at session 67 exit:
175/177 (scripts/), 17/17 (prog0NN), 7/8 (T<num>/), 7/7
(should_fail), 37/37 (should_run) = 243/246 across five families.
Three known issues unchanged: HFS+ flakes in T8042/T17549, and
the T16525a SIGSEGV.

Top next moves: pilot the stage2 native-compile sweep (starting
with tests/typecheck/should_compile/, half-day to full day), or
open a proposal for the T16525a RTS-linker investigation.

Read in order:
1. docs/sessions/2026-05-17-session-67-ghci-should-runner/HANDOFF.md
2. docs/sessions/2026-05-17-session-67-ghci-should-runner/README.md
3. docs/sessions/2026-05-17-session-67-ghci-should-runner/findings.md
4. docs/roadmap.md (for the broader priority list)

Hosts: uranium for source edits + cross-builds; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 68 ends, write the next handoff at:
`docs/sessions/<DATE>-session-68-<slug>/HANDOFF.md`.
