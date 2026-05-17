# Handoff from session 66 → session 67

**For:** the next claude session.
**From:** session 66 — verification-only, **7/8 PASS** on the
`tests/ghci/T<num>/` per-dir bug-numbered subset.  New runner
`scripts/run-ghci-Tdir.sh`.  No GHC source changes, no patches,
no release.  ONE new real PPC-port issue surfaced and bisected:
T16525a SIGSEGV during post-unload `performGC`.

**Recommended pickup, in priority order:**

1. **`tests/ghci/should_run/` and `tests/ghci/should_fail/`** —
   the next highest-yield breadth target.  `should_run/all.T` has
   ~40+ `ghci_script` entries.  Likely 2–4h depending on annotation
   variety.  Use `run-ghci-Tdir.sh` as the starting shape (per-dir
   staging if needed, or per-file if those tests follow the
   `scripts/` flat-file shape — check first).
2. **Stage2 native-compile sweep** — the session-64-HANDOFF
   top option.  Run upstream's broader testsuite (`tests/simple/`,
   `tests/codeGen/`, `tests/typecheck/`) using the ppc-native stage2
   as the test compiler, not just GHCi scripts.  Half-day to full
   day.
3. **T16525a SIGSEGV RTS fix** — investigate `rts/Linker.c`'s
   `unloadObj` machinery vs the GC's code-scan path.  The bisection
   in `logs/T16525a-segv-bisect.md` gives a 5-line reproducer; the
   tricky part is figuring out where in the GC the dangling Cmm
   pointer gets followed.  Could be a multi-session investigation,
   could be a one-line fix.  Worth scoping with a proposal under
   `docs/proposals/` first.

## ✅ SESSION EXIT STATE

* `docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/scripts/run-ghci-Tdir.sh`
  — new runner.  Strict subset of session 65's runner: drops
  `shell.hs` staging, test-name/dir-name split, and remote
  `HC`/`HC_OPTS`/`ghciWayFlags` exports.  Adds `expect_broken`
  pass/fail inversion.  Adds SIGSEGV (rc=139) + SIGBUS (rc=138) to
  the lethal-signal detection list (previously only 127/134/137).
* `docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/scripts/normalise.py`
  — verbatim copy of session 65's normaliser.  No new rules.
* `docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/logs/01..04-*.log`
  — four run logs; the final two both 7/8 PASS.
* `docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/logs/T16525a-segv-bisect.md`
  — minimal-trigger characterisation of the T16525a SIGSEGV.
* `docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/logs/ghci-Tdir/`
  — per-test staged inputs + actual outputs + expected outputs.

No changes to `external/ghc-modern/ghc-9.2.8/` — verification only.

## TL;DR — the session-66 work

Same shape as sessions 56 / 57 / 62 / 63 / 65 (pure verification):

1. Pick a new test subdir family in upstream's testsuite.
2. Read every test's annotation; classify in-scope vs out-of-scope.
3. Adapt the existing runner shape to whatever new harness this
   family needs (in this case: simplify, not extend).
4. Run, debug to convergence, commit notes.

What's distinctive this time: a real PPC RTS bug fell out of the
verification work.  Took ~10 minutes of bisection to characterise
T16525a's SIGSEGV down to a 5-line reproducer.  Worth a future
RTS-focused investigation — the bisection narrows the search to
"GC code-scan walk vs `rts/Linker.c` `unloadObj`."

## What to try next, in priority order

### Top: `tests/ghci/should_run/` and `tests/ghci/should_fail/`

`tests/ghci/should_run/all.T` has ~40+ `ghci_script` entries.
`tests/ghci/should_fail/all.T` similar size.  Highest test-count-
per-session-effort ratio remaining.

Check first whether these tests follow the per-file shape
(like `tests/ghci/scripts/`) or per-dir shape (like
`tests/ghci/prog0NN/` and `tests/ghci/T<num>/`).  If per-file,
adapt session 64's `run-ghci-tnum.sh`.  If per-dir, adapt
session 66's `run-ghci-Tdir.sh`.

Estimated 2–4h depending on annotation variety.

### Second: stage2 native-compile sweep

The session-64-HANDOFF top option, repeated for visibility.  Run
upstream's broader testsuite (`tests/simple/`, `tests/codeGen/`,
`tests/typecheck/`) using the ppc-native stage2 as the test
compiler, not just GHCi scripts.

Options:
(a) Run upstream's Python testsuite driver on pmacg5 itself
    (`tiger.sh` provides python3.10).
(b) Write a `compile_and_run`-shaped wrapper that ssh's per-test
    (cross-build the .hs to .o on uranium, scp, ssh-run on pmacg5).

(a) is closer to upstream's design; (b) reuses the `runghc-tiger`
pattern from v0.5.0.  Pilot a small starting target
(`tests/typecheck/should_compile/` is probably tightest) and see
which shape converges faster.

Estimated half-day to a full day.

### Third: T16525a SIGSEGV RTS fix (or scoped proposal)

The bisection in `logs/T16525a-segv-bisect.md` characterises the
trigger to 3 conditions and 5 .script lines.  Next steps:
- Read `rts/Linker.c` `unloadObj`, `markObjectCode`, and friends.
- Read `rts/sm/Sanity.c` / the GC code-scan path
  (`scavenge_stack` etc).
- Try reproducing under `+RTS -Dl -Dg` to log linker + GC activity.
- Hypothesis: the GC's evac of a closure pointing at unloaded Cmm
  doesn't trigger the "this closure points at dead code, replace
  with a tombstone" path that x86_64 must have.

Could be a one-line fix (some platform-conditional ifdef missing)
or a multi-session investigation.  Worth scoping with a proposal
under `docs/proposals/` before committing to the work.

### Fourth: ghci-ext way for T16392 / prog001

Same item as session 65 HANDOFF.  Still worth doing for cross-
exercise of the iserv path.

### Maintenance: HFS+ T8042 / T17549 mitigation

Same item as sessions 64+65 HANDOFFs.  Still worth doing.

### Maintenance: propagate SIGSEGV/SIGBUS detection to other runners

Session 66 added rc=138/139 to lethal-signal detection in
`run-ghci-Tdir.sh`.  The same fix should land in:
- `docs/sessions/2026-05-17-session-65-ghci-progNNN-runner/scripts/run-ghci-progNNN.sh`
- `docs/sessions/2026-05-17-session-64-ghci-...` (run-ghci-tnum.sh)
- Any prior runners that grep for `rc=`.

Five minutes of edits per runner.  Drop-in patch.

## What NOT to redo

* **Don't add T13786, T16670_unboxed, or T16670_th to this runner.**
  All three are `makefile_test` — they want a different driver that
  runs the dir's Makefile against the test compiler.  Out of shape
  for a ghci-script runner.  See session 65's HANDOFF for the same
  guidance about prog004.
* **Don't try to "fix" T11827 to remove the expected-broken flip.**
  Upstream marks it `expect_broken(11827)` because the test's own
  comments acknowledge the `-v0` behaviour is wrong for asserting on
  module-load errors.  Our runner correctly inverts pass/fail; the
  test is exercising the right codepath but its assertion is
  fundamentally broken in upstream too.  If we ever start tracking
  upstream master, the day GHC adds an error-print path that
  bypasses `-v0`, this test will go from `expected-broken: ...` to
  `UNEXPECTED PASS` and we should remove the expect_broken=1 flag.
* **Don't extend the runner to do the `extra_ways(['ghci-ext'])`
  way for T16392.**  Same reasoning as session 65 for prog001 —
  it'd be a future iserv-bridge investment, not load-bearing for
  current correctness.

## Hosts (unchanged)

* **uranium**: runner driver.
* **pmacg5**: runs the v0.15.0 ppc stage2 ghc-real.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 66 of the ghc-darwin8-ppc project extended GHCi
test coverage to tests/ghci/T<num>/ per-dir bug-numbered tests.
7/8 PASS on the in-scope subset.  One real PPC-port runtime-linker
bug surfaced: T16525a produces correct output then SIGSEGVs during
post-unload `performGC`.  Bisected to a 3-condition / 5-line
trigger; documented in
docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/logs/T16525a-segv-bisect.md.
Verification only — no GHC source changes, no patches, no release.
Reusable runner at
docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/scripts/run-ghci-Tdir.sh
— strict subset of session 65's runner plus `expect_broken` flip
and SIGSEGV/SIGBUS detection.

Combined GHCi-script testsuite coverage at session 66 exit:
175/177 (scripts/), 17/17 (prog0NN), 7/8 (T<num>/) = 199/202 across
three families.  Three known issues: HFS+ flakes in T8042/T17549,
and the T16525a SIGSEGV.

Top next moves: tests/ghci/should_run/ + should_fail/ (~40+ tests,
2-4h), pilot the stage2 native-compile sweep (half-day to full day),
or open a proposal for the T16525a RTS-linker investigation.

Read in order:
1. docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/HANDOFF.md
2. docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/README.md
3. docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/findings.md
4. docs/sessions/2026-05-17-session-66-ghci-Tdir-runner/logs/T16525a-segv-bisect.md
5. docs/roadmap.md (for the broader priority list)

Hosts: uranium for source edits + cross-builds; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 67 ends, write the next handoff at:
`docs/sessions/<DATE>-session-67-<slug>/HANDOFF.md`.
