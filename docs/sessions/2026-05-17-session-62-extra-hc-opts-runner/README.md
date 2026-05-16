# Session 62 — Extend ghci-tnum runner with `extra_hc_opts(...)` support

**Date:** 2026-05-17 (continuation of session 61).

**Status on arrival:** Session 61 shipped v0.14.2 (the
`__dso_handle` Mach-O underscore fix in `rts/Linker.c`).  Session 60's
runner re-runs at 165/166 PASS on the bug-numbered `T<NUM>.script`
subset; the lone failure is T17549 (HFS+ 1-second mtime-granularity
race in upstream's `:reload` script, not a PPC bug).  Session 61
HANDOFF's top recommendation: extend the runner to cover the six
`extra_hc_opts(...)` tests in upstream's `tests/ghci/scripts/all.T`
that the session-60 runner skipped (T2452, T2182ghci2, T9293,
T13385, T14342, T16563).  Wiring is "identical to session 60's"
because `ghc --interactive` does compile+run in one invocation, so
compile-flags and run-flags both end up on the same command line.

**Status on exit:** **171/172 PASS.**  All 6 new `extra_hc_opts`
tests pass.  The lone failure (T8042) is the same HFS+ mtime race
as T17549 — they alternate as the unlucky coin-flip; T17549 passed
clean this run.  Three-line patch to the harness — extend
`run_opts_for()` with the six `extra_hc_opts` cases — plus six
new entries in the TESTS list (one with an `extra_files` ref to
`ghci057.hs`), plus a small normaliser fix to absorb stray trailing
blank lines in upstream's expected `.stdout`/`.stderr` files.  No
GHC source changes, no new patches, no release.

## What was done

### 1. Runner extension

Extended [`scripts/run-ghci-tnum.sh`](scripts/run-ghci-tnum.sh)'s
per-test flag lookup with six `extra_hc_opts` cases.  Diff vs
session 61's runner at [`logs/00-runner-diff.log`](logs/00-runner-diff.log).

```bash
run_opts_for() {
  case "$1" in
    # extra_run_opts(...) (session 60)
    T9878b|T12091) echo "-fobject-code" ;;
    T17500)        echo "-ddump-to-file -ddump-bcos" ;;
    # extra_hc_opts(...) (session 62)
    T2452)         echo "-fno-implicit-import-qualified" ;;
    T2182ghci2)    echo "-XNoImplicitPrelude" ;;
    T9293)         echo "-fno-ghci-leak-check" ;;
    T13385)        echo "-XRebindableSyntax" ;;
    T14342)        echo "-XOverloadedStrings -XRebindableSyntax" ;;
    T16563)        echo "-clear-package-db -global-package-db" ;;
    *)             echo "" ;;
  esac
}
```

TESTS list grew by 6 entries (166 → 172), inserted in approximately
bug-number-ordered positions:

| Test | Flag | Notes |
|------|------|-------|
| T2452 | `-fno-implicit-import-qualified` | tests `:set ±fimplicit-import-qualified` toggles |
| T2182ghci2 | `-XNoImplicitPrelude` | orphan-instance import-via-`Prelude` regression |
| T9293 | `-fno-ghci-leak-check` | needs `ghci057.hs` (entry: `"T9293 0 ghci057.hs"`); `:load` + `:set/:unset/:seti -XGADTs` interaction |
| T13385 | `-XRebindableSyntax` | empty script; just "ghci doesn't crash with this flag" |
| T14342 | `-XOverloadedStrings -XRebindableSyntax` | same shape as T13385 — empty script |
| T16563 | `-clear-package-db -global-package-db` | `putStrLn "hello world"` smoke test |

### 2. Normaliser fix — strip trailing blank lines

First run produced 170/172 PASS.  The new failure (T16563) was
a 1-byte trailing-newline discrepancy:

```
expected.stdout = "hello world\n\n"   (upstream file has trailing blank line)
actual.stdout   = "hello world\n"     (GHCi doesn't actually emit it)
```

Reproduced on the host's own bare `ghc-9.2.8 --interactive` — same
single-newline output — so upstream's expected file simply has a
stray trailing blank line that doesn't match GHCi's real output.
Not a PPC bug.

Fix: extend
[`scripts/normalise.py`](scripts/normalise.py)'s `normalise()` with
a final `s.rstrip('\n')` + re-add one newline if non-empty.  This
mirrors upstream `testlib.py`'s `normalise_whitespace`
(`' '.join(s.split())`, which collapses *all* whitespace) but
applied conservatively to trailing-only — internal blank lines
between error messages are preserved.

Re-run with the normaliser fix: **171/172 PASS**.

### 3. Verification — second run

```
=== Summary: 171 PASS / 1 FAIL out of 172 tests ===
Failed: T8042
```

T8042 is the known HFS+ 1-second mtime-granularity race in
upstream's `:reload` script — same shape as T17549.  See [session 58
findings](../2026-05-17-session-58-ghci-tnum-scripts/findings.md)
for the full diagnosis.  T8042 + T17549 alternate as the unlucky
coin-flip from run to run; this run T17549 passed and T8042 failed,
session-61's run had T17549 failing and T8042 passing.

Per-test diff:

```
actual.stdout:
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

The missing line `[3 of 3] Compiling T8042A ( T8042A.hs, T8042A.o )`
between the first "Ok" and the second comes from `:reload` deciding
that T8042A.hs hadn't changed — its mtime was unchanged because
both `writeFile`s landed in the same HFS+ second.

Full log at [`logs/02-run2-after-normaliser-trim.log`](logs/02-run2-after-normaliser-trim.log).

## What this means

- All six `extra_hc_opts` tests pass once they're wired in.  Same
  shape as session 60's `extra_run_opts` extension — both
  annotations end up appended to the same `ghc --interactive`
  command line, so the wiring is identical.
- T16563's "stray trailing newline" in the upstream expected file
  is a test-data discrepancy, not a runtime difference.  The
  normaliser fix is a runner-side fix that strips trailing blank
  lines from both expected and actual outputs — same effect as
  upstream's `normalise_whitespace` for stderr but more conservative
  (trailing only, not all whitespace).
- The T8042 / T17549 HFS+ flake is the steady-state floor.  171/172
  is "all real, fixable tests pass; one HFS+ flake per run."  No
  more deterministic failures in this 172-test subset.

## Files added this session

- `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
- `scripts/run-ghci-tnum.sh` — session 61's runner with six new
  `extra_hc_opts` cases in `run_opts_for()` and six new TESTS
  entries.
- `scripts/normalise.py` — session 61's normaliser with a
  trailing-blank-line trim added to `normalise()`.
- `logs/00-runner-diff.log` — diff vs session 61's runner for
  quick audit.
- `logs/01-run1.log` — first runner run; 170/172 PASS (T16563
  fails on trailing-newline).
- `logs/02-run2-after-normaliser-trim.log` — second run after
  normaliser fix; **171/172 PASS** (T8042 = HFS+ race only).

## Hosts

- **uranium** — runner edits, normaliser edits.
- **pmacg5** — runs the ppc stage2 ghc binary.  Unchanged this
  session.
- **indium** — not used.

## What's next

See [`HANDOFF.md`](HANDOFF.md).
