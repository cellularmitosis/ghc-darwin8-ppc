# Session 63 — Extend ghci-tnum runner with `reqlib(...)` and simple `pre_cmd(...)` support

**Date:** 2026-05-17 (continuation of session 62).

**Status on arrival:** Session 62 shipped 171/172 PASS on the
172-test T-prefix subset of `tests/ghci/scripts/all.T`, after wiring
in `extra_hc_opts(...)` support plus a trailing-blank-line trim in
the normaliser.  The lone failure was the T8042 / T17549 HFS+
1-second mtime-granularity race in upstream's `:reload` script —
the two tests alternate as the unlucky coin-flip from run to run.
Session 62 HANDOFF's top recommendation: add `reqlib` (T5979 — needs
`transformers`) and simple `pre_cmd` tests (T5975a/b — `touch
föøbàr<N>.hs`).  T6106 + T19650 require richer harness work (Make
target or `ghc-pkg`) and were called out as out-of-scope for now.

**Status on exit:** **173/175 PASS.**  All 3 new tests (T5979,
T5975a, T5975b) pass clean on the first run.  Both T8042 + T17549
failed in this run — same HFS+ mtime-race signature as sessions
58/60/61/62 (the two tests' two `writeFile`s both landed in the same
HFS+ second, so `:reload` saw no mtime change and was a no-op).
Session 62 reported "exactly one of {T8042,T17549} fails per run"
based on sessions 60/61/62 each flipping one or the other; sessions
58 and 63 show that "both fail" is also a possible outcome of the
unsynchronised coin-flip.  No new deterministic failures introduced.
No GHC source changes, no new patches, no release.

## What was done

### 1. Runner extension — `pre_cmd_for()` (new) + one more `run_opts_for()` arm + one more `norm_args_for()` arm

Extended [`scripts/run-ghci-tnum.sh`](scripts/run-ghci-tnum.sh) with
a third per-test lookup table (`pre_cmd_for`) alongside the existing
`run_opts_for` and `norm_args_for`.  Diff vs session 62's runner
at [`logs/00-runner-diff.log`](logs/00-runner-diff.log).

```bash
pre_cmd_for() {
  case "$1" in
    T5975a) echo "touch föøbàr1.hs" ;;
    T5975b) echo "touch föøbàr2.hs" ;;
    *)      echo "" ;;
  esac
}
```

`$pre` is inserted between the `cd` and the `$GHC` line in each
test's per-test block, so it runs in the per-test directory (matching
upstream's `pre_cmd` semantics).  Empty `$pre` produces a blank
line — harmless.

T5975b's `extra_hc_opts('föøbàr2.hs')` is wired identically to
session 60/62's other `extra_hc_opts` cases — one new arm in
`run_opts_for()` that returns the bare filename, which appends to
the GHC command line as a positional arg (telling `ghc --interactive`
to load it).

T5979's `normalise_version("transformers")` is wired via a one-liner
in `norm_args_for()` that passes `--version transformers` to
[`scripts/normalise.py`](scripts/normalise.py) — which already
supports this flag (added in session 58 for the broader expansion).

TESTS list grew by 3 entries (172 → 175), inserted near T5566 in
roughly bug-number order:

| Test | Annotation | Notes |
|------|------------|-------|
| T5975a | `pre_cmd('touch föøbàr1.hs')` | empty .hs, `:load föøbàr1.hs`; no expected output |
| T5975b | `pre_cmd('touch föøbàr2.hs')`, `extra_hc_opts('föøbàr2.hs')` | empty script + empty .hs; smoke test only |
| T5979 | `reqlib('transformers')`, `normalise_version("transformers")` | stage2 has `transformers-0.5.6.2`; expected file says `0.5.2.0`; normalise to `<VERSION>` |

### 2. Verification — first run

```
=== Summary: 173 PASS / 2 FAIL out of 175 tests ===
Failed: T8042 T17549
```

All 3 new tests pass; both pre-existing HFS+ flakes failed this run.

Per-test diffs confirm both failures are the same shape as sessions
58/60/61/62 (the `:reload`-saw-no-mtime-change no-op):

```
T8042 actual.stdout:
[1 of 3] Compiling T8042B           ( T8042B.hs, T8042B.o )
[2 of 3] Compiling T8042C           ( T8042C.hs, interpreted )
[3 of 3] Compiling T8042A           ( T8042A.hs, interpreted )
Ok, three modules loaded.
                                                            ← missing
Ok, three modules loaded.                                   ← `:reload` no-op
[2 of 3] Compiling T8042C           ( T8042C.hs, interpreted )
[3 of 3] Compiling T8042A           ( T8042A.hs, interpreted )
Ok, three modules loaded.
```

```
T17549 actual.stderr:
                                                            ← (empty)

(expected: extra parse error from the post-:reload writeFile)
```

Full log at [`logs/01-run1.log`](logs/01-run1.log).

## What this means

- **`reqlib` is essentially free for tests that don't need a special
  normaliser:** the stage2 ghc already has `transformers` installed,
  and our normaliser already supports `--version pkg`.  For T5979
  the wiring was three lines (TESTS entry + `norm_args_for()` arm +
  comment).  Other `reqlib` tests in `all.T` for libraries already
  in our stage2 package.conf.d would be trivial to add — though
  T5979 was the only one not also tagged with another deferred
  annotation.
- **`pre_cmd` for simple shell snippets is one new dispatcher
  function** (`pre_cmd_for`) plus a one-line injection into the
  per-test block.  T6106 + T19650 + ghci056 need richer plumbing
  (Make target = native compile + extra_files; ghc-pkg deployment)
  and remain out of scope.
- **Session 62's "exactly one of {T8042, T17549} fails per run"
  claim is incorrect:** sessions 58 and 63 both show both tests
  failing in the same run.  The HFS+ mtime race is two independent
  coin-flips, so "both fail" has roughly the same probability as
  "exactly one fails."  The steady-state floor for this 175-test
  subset is therefore *173–175 PASS*, depending on the day's coin
  flips, with no fixable deterministic failures remaining.

## Files added this session

- `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
- `scripts/run-ghci-tnum.sh` — session 62's runner with a new
  `pre_cmd_for()` lookup function, one new arm in `run_opts_for()`
  (T5975b), one new arm in `norm_args_for()` (T5979), and three
  new TESTS entries.
- `scripts/normalise.py` — byte-identical copy of session 62's
  normaliser.  `--version transformers` was already supported (the
  flag dates from session 58).
- `logs/00-runner-diff.log` — diff vs session 62's runner.
- `logs/01-run1.log` — full PASS/FAIL log; **173/175 PASS** (both
  HFS+ flakes failed; all 3 new tests pass).

## Hosts

- **uranium** — runner edits.
- **pmacg5** — runs the v0.14.2 ppc stage2 ghc binary
  (`/opt/ghc-stage2/bin/ghc-real`).  Untouched this session.
- **indium** — not used.

## What's next

See [`HANDOFF.md`](HANDOFF.md).
