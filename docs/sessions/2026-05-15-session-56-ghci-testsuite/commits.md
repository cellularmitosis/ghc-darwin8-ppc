# Session 56 commits

| SHA | Subject |
|---|---|
| `b9fad10` | Session 56: 51/51 PASS on curated GHCi testsuite subset. |

## Files changed

No GHC source-tree changes.  No new patches.  No bindist or
release.  Documentation + reusable test harness only.

### New session dir

* `docs/sessions/2026-05-15-session-56-ghci-testsuite/`
  * `README.md` — narrative + status-on-arrival → exit.
  * `findings.md` — what we learned that future sweeps will want
    (the upstream-driver normalisations, flag set, companion-file
    glob, combined_output ordering trap).
  * `commits.md` — this file.
  * `HANDOFF.md` — primer for session 57.
  * `scripts/`
    * `run-ghci-subset.sh` — ssh-driven harness.  Stages each
      test's files to a temp dir on pmacg5, runs `ghc --interactive`
      with the script as stdin, normalises both sides through
      `normalise.py`, and emits one PASS/FAIL line per test.
    * `normalise.py` — Python port of upstream
      `testsuite/driver/testlib.py`'s `normalise_errmsg` +
      `normalise_callstacks` + `normalise_version` for the tests
      we run.  Stripped of Windows/AIX/MSYS branches.
  * `logs/`
    * `run-1.log` — initial 21-test sweep (18 PASS / 3 FAIL).
    * `run-2.log` — same 21, harness flags + extras fixed (21 PASS).
    * `run-3-broad.log` — expanded to 51 tests (44 PASS / 7 FAIL).
    * `run-4-normalised.log` — after applying `normalise.py`
      (49 PASS / 2 FAIL).
    * `run-5-final.log` — after `${name}_*` glob + `diff -w`
      (**51 PASS / 0 FAIL**).
    * `ghci-subset/<test>/` — per-test working dirs: original
      script, expected outputs, captured actual outputs.

### Top-level README

* `README.md` — TemplateHaskell / external-interpreter table's
  "GHCi REPL" row now mentions the 51/51 testsuite verification
  and links to the harness.

### Roadmap + state

* `docs/roadmap.md` — Last-reviewed bumped to session 56; new
  bullet under §C.GHCi for the verification result.
* `docs/state.md` — top-of-file summary now opens with session 56
  verification (no STATE CLEAN bump for source — there's nothing
  to dirty); session 55 demoted to "Prior summary".

## Notes

* Session 56 produced no GHC source changes, no new patches, no
  release tag.  It's a verification milestone — proves the v0.14.0
  REPL works across 51 of upstream's GHCi tests, and ships a
  reusable harness so future sweeps don't re-derive it.
* The harness debug arc (run-1 → run-5) is captured because the
  next sweep — `tests/ghci.debugger/` or the bug-numbered
  `tests/ghci/T*` subdirs — will hit the same five classes of
  failure (TEST_HC_OPTS, normalise_errmsg, combined_output
  ordering, companion-file glob, whitespace).  Findings doc
  spells those out.
