# Session 66 — T-prefix per-dir runner; 7/8 PASS

**Date:** 2026-05-17 (continuation of session 65).

**Status on arrival:** v0.15.0 shipped in session 64 (ghc-pkg / hp2ps
/ hsc2hs cross-build as real ppc binaries; patch 0018 skips bindist-
side `ghc-pkg recache`).  Session 65 added the `prog001..prog019`
subset runner (17/17 PASS) and the `tests/ghci/scripts/all.T`
T-prefix subset stays at 175/177 PASS at v0.15.0.  Session 65's
HANDOFF priority #1: extend coverage to the bug-numbered per-test
subdirs under `tests/ghci/T<num>/` (10 dirs, mix of `ghci_script`
and `makefile_test`).

**Status on exit:** New runner
[`scripts/run-ghci-Tdir.sh`](scripts/run-ghci-Tdir.sh) at **7/8
PASS** (1 SIGSEGV — see below) across two consecutive runs, plus a
bisection log for the one failure.  No GHC source changes, no new
patches, no release.  Three tests skipped as out-of-shape for a
ghci-script runner (T13786, T16670_unboxed, T16670_th — all
`makefile_test`).

## What was done

### 1. Scoped the T-prefix per-dir family

10 `T<num>` directories under `tests/ghci/`.  Read every `all.T`
and classified:

| Dir | Tests | Shape | Decision |
|-----|-------|-------|----------|
| T11827 | 1 | `ghci_script` + `expect_broken(11827)` | **IN** — expect-broken flip |
| T13786 | 1 | `makefile_test` | OUT — wrong harness |
| T16392 | 1 | `ghci_script` + `req_interp` + conditional `extra_ways(['ghci-ext'])` | **IN** — normal way only |
| T16525a | 1 | `ghci_script` | **IN** |
| T16525b | 1 | `ghci_script` | **IN** |
| T16670 | 2 (`_unboxed` + `_th`) | both `makefile_test` | OUT — wrong harness |
| T16793 | 1 | `ghci_script` + `normal` | **IN** |
| T18060 | 1 | `ghci_script` + `normal` | **IN** |
| T18071 | 1 | `ghci_script` | **IN** |
| T18262 | 1 | `ghci_script` | **IN** |

8 in-scope; 3 skipped (2 dirs).

### 2. Designed the runner

Direct adaptation of session 65's `run-ghci-progNNN.sh`, simplified.
Three things removed because the T-dir subset doesn't need them:

1. `shell.hs` staging — no T-dir script does `:shell "$HC" ...`.
2. Test-name vs dir-name split — for all 8 T-dirs, the dir name
   matches the `.script` / `.stdout` / `.stderr` basename, so the
   TESTS array degrades to `dir expect_broken`.
3. `HC` / `HC_OPTS` / `ghciWayFlags` env exports — none of the
   scripts compile partial `.o` files mid-REPL.

One thing added:

- **`expect_broken` inversion**: T11827 carries `expect_broken(11827)`
  upstream.  Its `T11827.stderr` expects
  `A.hs:6:3: error: Not in scope: data constructor ‘C’`, but with
  `-v0` the message is suppressed (per the comment in the .script
  itself), so the test is a known mismatch in upstream.  The runner
  flips pass/fail for any test with `expect_broken=1` — a mismatch
  becomes the expected outcome, a clean match would be marked
  `UNEXPECTED PASS`.

### 3. Verification

Run 1 (initial): 8/8 PASS (but T16525a rc=139 wasn't being detected).
Run 2 (sanity re-run): same.
Run 3 (after adding SIGSEGV detection to fail logic): 7/8 PASS,
T16525a marked FAIL with `rc=139 (lethal signal)`.
Run 4 (final stability run): 7/8 PASS, same shape.

Per-test outputs and the actual-vs-expected diffs live under
`logs/ghci-Tdir/<dir>/`.

### 4. T16525a SIGSEGV bisection

T16525a (object-code unload + post-unload thread call + GC) produces
the correct expected stdout (`["a;lskdfa;lszkfsd;alkfjas"]`) then
crashes during the subsequent `performGC`.  Bisected the .script to
isolate the crash trigger; documented in
[`logs/T16525a-segv-bisect.md`](logs/T16525a-segv-bisect.md).

Crash needs all three: object-code unload via `:l []`, a forked
thread that fires AFTER the unload and holds closures referencing
the just-unloaded modules' Cmm, AND a subsequent `performGC` that
walks the heap and follows those refs.  Remove any one — clean rc=0.

This is a real PPC-port runtime-linker bug, not a test-driver
artifact.  T16525b (which fires the same pattern but with a longer-
running thread that keeps re-entering the unloaded code) is clean
rc=0 — likely because its closures stay scheduler-pinned across the
GCs.  Worth investigating later in a session focused on
`rts/Linker.c` / GC code-unload paths.

## What this means

- **`tests/ghci/T<num>/` per-dir family is now wired.**  7/8 PASS,
  1 SIGSEGV in T16525a producing correct output then crashing.
- **No new runner machinery needed.**  Session 65's runner shape
  generalises cleanly — the T-dir subset is a strict subset of
  what session 65 supported, modulo `expect_broken` flip.
- **First real PPC runtime-linker bug identified through test
  coverage.**  T16525a's SIGSEGV is reproducible, characterisable
  (3-condition minimal trigger), and points at a concrete area of
  the RTS (`rts/Linker.c`'s code-unload + GC code-scan
  interaction) for a future investigation.

## Test count update

After this session, our exercised GHCi testsuite coverage is:

- `tests/ghci/scripts/` T-prefix subset: **175/177** (v0.15.0, unchanged).
- `tests/ghci/prog001..prog019`: **17/17** (session 65, unchanged).
- `tests/ghci/T<num>/`: **7/8** (this session).

Combined: **199/202** across 3 GHCi-script test families.  Single
real PPC-port issue identified (T16525a SIGSEGV); the other 2 known
failures are the HFS+ mtime-granularity flakes in T8042 / T17549
from session 64.

## Files added this session

- `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
- `scripts/run-ghci-Tdir.sh` — the new runner.
- `scripts/normalise.py` — verbatim copy of session 65's.
- `logs/01-run1.log` ... `logs/04-run-final.log` — run logs.
- `logs/T16525a-segv-bisect.md` — bisection of the SIGSEGV.
- `logs/ghci-Tdir/<dir>/...` — per-test staged inputs + actuals
  + expecteds.

## Hosts

- **uranium** — runner driver.
- **pmacg5** — runs the v0.15.0 ppc stage2 ghc-real.
- **indium** — not used.

## What's next

See [`HANDOFF.md`](HANDOFF.md).
