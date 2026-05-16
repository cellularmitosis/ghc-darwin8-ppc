# Session 60 — Extend ghci-tnum runner with `extra_run_opts`

**Date:** 2026-05-17 (continuation of session 58 / 59).

**Status on arrival:** v0.14.1 shipped end-to-end in session 59.
The session-58 runner `run-ghci-tnum.sh` ran clean at 161/163 PASS
on the T-prefix subset of upstream's `tests/ghci/scripts/all.T`, but
skipped every test annotated with `extra_run_opts(...)` — three
runnable tests (T9878b, T12091, T17500) plus three already
filtered for other reasons (ghci017's `reqlib`, ghci056's `pre_cmd`,
T17669's `expect_broken`).  Session 59's HANDOFF flagged
`extra_run_opts` as the easiest of the "extend the runner to handle
more annotations" follow-ons; this session does it.

**Status on exit:** runner extended; **164/166 PASS** end-to-end.
T12091 + T17500 pass clean.  **T9878b surfaces a real, new,
upstream-shaped PPC/Tiger bug** in the runtime Mach-O loader's
`__dso_handle` handling — `rts/Linker.c::lookupDependentSymbol`'s
ELF-shaped strcmp misses the Mach-O underscore-prefixed form
`"___dso_handle"`, so static-pointer SPT init's `__cxa_atexit`
reference goes unresolved.  Filed as
[`docs/proposals/rts-dso-handle-mach-o.md`](../../proposals/rts-dso-handle-mach-o.md)
for a future v0.14.2 release cycle.  T17549 still flakes on the
HFS+ mtime race (same as session 58/59); T8042 happened to pass
this run (also HFS+ race, both directions of the coin).
No GHC source changes, no new patches, no release.

## What was done

### 1. Inspect upstream `all.T` for `extra_run_opts` usage

```
$ grep -n extra_run_opts external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T
43:test('ghci017', [reqlib('haskell98'), extra_run_opts('-hide-package haskell98')], ghci_script, ...)
94:      extra_run_opts('ghci056_c.o')],
219:test('T9878b', [extra_run_opts('-fobject-code')], ghci_script, ...)
262:test('T12091', [extra_run_opts('-fobject-code')], ghci_script, ...)
320:test('T17500', [extra_run_opts('-ddump-to-file -ddump-bcos')], ghci_script, ...)
322:test('T17669', [extra_run_opts('-fexternal-interpreter -fobject-code'), expect_broken(17669)], ghci_script, ...)
```

Six hits, three runnable.  The other three are already-filtered:

- `ghci017` — `reqlib('haskell98')` (no Haskell 98 lib in our PPC bindist).
- `ghci056` — `pre_cmd('$MAKE -s ...')` (makefile-driven harness).
- `T17669` — `expect_broken(17669)` (upstream itself doesn't run this).

### 2. Extend the runner

Copied session 58's `run-ghci-tnum.sh` + `normalise.py` into
[`scripts/`](scripts/), added:

- A `run_opts_for() { case "$1" in T9878b|T12091) echo "-fobject-code";; T17500) echo "-ddump-to-file -ddump-bcos";; *) echo "";; esac }` lookup.
- `opts=$(run_opts_for "$name")` inside the per-test command-builder loop.
- `$opts` slotted into both `combined=0` and `combined=1` GHC
  invocations.
- Three new TESTS-list entries: `"T9878b 0"`, `"T12091 0"`, `"T17500 0"`.

Total diff vs session 58's runner: ~18 inserted lines, 2 modified.
See [`logs/00-runner-diff.log`](logs/00-runner-diff.log).

### 3. Run against pmacg5

`bash scripts/run-ghci-tnum.sh pmacg5` — full log at
[`logs/01-run1.log`](logs/01-run1.log).  Result:

```
=== Summary: 164 PASS / 2 FAIL out of 166 tests ===
Failed: T9878b T17549
```

### 4. Triage T9878b

T9878b stderr:

```
ghc-real:
lookupSymbol failed in resolveImports
/private/tmp/ghci-tnum-XXXX/T9878b/T9878b.o: unknown symbol `___dso_handle'
ghc-real: Could not load Object Code .../T9878b.o.
```

Three underscores in `___dso_handle` (Mach-O symbol-table prefix
preserved); `rts/Linker.c::lookupDependentSymbol`'s special case
strcmps against `"__dso_handle"` (two underscores, ELF spelling).
Miss → returns NULL → resolveImports fails → module load fails.
See [findings §3](findings.md) for the full chain and
[`docs/proposals/rts-dso-handle-mach-o.md`](../../proposals/rts-dso-handle-mach-o.md)
for the release sketch.

### 5. Triage T12091 + T17500 (PASS)

Both are principled passes — neither truly exercises the Mach-O
object loader's harder paths:

- T12091's script is pure REPL bindings (`x = 5; x`) — no `:l`
  directive, so `-fobject-code` is effectively a no-op (interactive
  bindings always live in the in-process bytecode interpreter).
- T17500's script loads a module but in bytecode mode (no
  `-fobject-code`); `-ddump-to-file -ddump-bcos` exercises the
  BCO-dump-to-file machinery, which produces `T17500.dump-BCOs`,
  `Ghci1.dump-BCOs`, `Ghci2.dump-BCOs` cleanly.

That's three light verifications of `-ddump-to-file -ddump-bcos`
and a smoke for `-fobject-code` on REPL-only scripts.

## What this means

- The session-58 runner family now covers `extra_run_opts(...)`-
  annotated tests — well-scoped harness extension, future-proof for
  similar groups (`extra_hc_opts`, `reqlib`, `pre_cmd`).
- 2 new tests added clean (T12091, T17500).
- 1 new, real, upstream-shaped PPC/Tiger bug surfaced: the runtime
  Mach-O loader can't resolve `___dso_handle`.  This is exactly the
  "new coverage finds new bugs" value-add we wanted out of extending
  the runner.  Fix is small (one-hunk patch); a v0.14.2 release is
  scoped in [the proposal](../../proposals/rts-dso-handle-mach-o.md).
- No GHC source changes, no new patches landed, no release tag.

## Files added this session

- `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
- `scripts/run-ghci-tnum.sh` — copied from session 58, extended.
- `scripts/normalise.py` — unchanged copy of session 58's (no new
  normalisation rules needed for the 3 new tests).
- `logs/00-runner-diff.log` — diff of the runner against session
  58's, for quick audit.
- `logs/01-run1.log` — full per-test PASS/FAIL log and the captured
  actual.{stdout,stderr} for each test.
- `logs/02-T9878b-stderr.log` — extracted runtime-loader error
  output for forensics.
- `../../proposals/rts-dso-handle-mach-o.md` — release sketch for
  the v0.14.2 fix.

## On pmacg5

No deploy changes.  `/opt/ghc-stage2/bin/ghc-real` and
`/opt/ghc-stage2/lib/` are the v0.14.1 bindist as deployed in
session 59.

## What's next

See `HANDOFF.md`.
