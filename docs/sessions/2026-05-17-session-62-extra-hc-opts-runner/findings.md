# Session 62 findings

## TL;DR

Extended session 60's `run-ghci-tnum.sh` runner with
`extra_hc_opts(...)` support — six new cases in `run_opts_for()`,
six new TESTS entries — and added a trailing-blank-line trim to
`normalise.py` to absorb upstream's stray expected-file newlines.
**171/172 PASS** (T8042 = HFS+ mtime race; alternates with T17549
as the unlucky coin-flip per run).  All 6 new tests pass.  No GHC
source changes, no new patches, no release.

## 1. `extra_hc_opts` and `extra_run_opts` wire to the same place

Upstream's testsuite distinguishes the two annotations because they
live in different phases of a normal compile-then-run test:
`extra_hc_opts` goes on the `ghc -c Foo.hs` command, `extra_run_opts`
goes on the resulting `./Foo` invocation.  But ghci_script tests
compile and run in **one** `ghc --interactive` invocation, so both
sets of flags end up on the same GHC command line.  Our runner's
`run_opts_for()` is the right place for both — same case statement,
just additional entries.  This was sketched in session 60's HANDOFF
and held exactly:

> "extra_hc_opts tests… Same harness shape as session 60's
>  extra_run_opts extension but `$opts` is appended to the
>  *compilation* line.  In practice, since we use `ghc --interactive`
>  (compile and run in one invocation), the wiring is identical to
>  session 60's: just add cases to `run_opts_for`."

## 2. T13385 + T14342 have empty `.script` files

```
$ wc -c T13385.script T14342.script
0 T13385.script
0 T14342.script
0 total
```

The tests are just "does GHCi `--interactive` startup-and-immediate-
EOF crash with `-XRebindableSyntax` / `-XOverloadedStrings
-XRebindableSyntax` enabled?"  No script content, no commands, no
expected output (`.stdout`/`.stderr` files don't exist).  Our
runner's existing logic handles this fine: empty actual matches a
missing expected, so PASS.

## 3. T9293 needs `ghci057.hs`, *not* its own `T9293.hs`

`T9293.script` does `:load ghci057.hs`.  But there's *also* a
`T9293.hs` file in `scripts/` that's byte-identical to `ghci057.hs`
(`module Test where data T a where C :: T Int`) — probably an
abandoned earlier-version filename.  The auto-discovery loop in
the runner copies `T9293.hs` into the per-test dir (which is
harmless — it isn't referenced by the script), and we add the
explicit `ghci057.hs` extras dependency to the TESTS entry:

```
"T9293 0 ghci057.hs"
```

The script's `:load ghci057.hs` then resolves locally.

## 4. T16563's expected file has a stray trailing newline

`T16563.script` is one line:
```
putStrLn "hello world"
```

`T16563.stdout` is two bytes longer than what GHCi actually
produces:

```
expected: "hello world\n\n"    (12 + 1 + 1 = 14 bytes)
actual:   "hello world\n"      (12 + 1     = 13 bytes)
```

Reproduced this on **the host's** `ghc-9.2.8 --interactive` (bare
arm64-Darwin) — same single-newline output.  So upstream's expected
file just has an extra blank line that doesn't reflect what GHCi
emits.  Not a PPC bug.

Why doesn't upstream's CI hit this?  Upstream's `compare_outputs`
for stdout uses `whitespace_normaliser=lambda x:x` (default), so
it would normally fail too.  Possibilities: the test passes for
upstream because of how their tar/git stripped a final newline, or
the file was committed via `--accept` after a run that did emit
the extra newline (maybe an older GHC version printed a blank
line at EOF?), or upstream's CI runs with `--allow-deviations`
on this test.  No need to investigate further; the test-data
discrepancy is real on both arm64-Darwin host GHC and ppc-Darwin
stage2 GHC, so it's not a PPC issue.

## 5. The normaliser trim is principled, not ad-hoc

`normalise.py` already mirrors a chunk of upstream's `testlib.py`
normalisers (`normalise_callstacks`, `INSTANCES_OUT_OF_SCOPE_RE`,
`BIGNUM_VERSION_RE`, etc.).  Adding `s.rstrip('\n')` at the end
slots into the same philosophy: textual differences that don't
reflect a real runtime difference should be normalised away.
Upstream's own `normalise_whitespace` does the more-aggressive
`' '.join(s.split())` for stderr; ours does the conservative
trailing-only version for both stdout and stderr.

Risk of masking real failures: low.  The trim only affects trailing
blank lines, not internal blank lines between error messages.  If
GHC emitted an extra error at the end of stderr that the expected
file didn't have, the lines themselves would still differ.  The
only failures masked are "exact same content modulo trailing
whitespace" — which is exactly what we want.

## 6. T8042 vs T17549 — they alternate

Session 58/59/60/61 all called out the HFS+ 1-second mtime
granularity race as the floor for this test family.  Both T8042
and T17549 have the same shape: `writeFile X → :load X → writeFile
X → :reload`.  If both writeFiles land in the same HFS+ second,
the mtime doesn't change and `:reload` is a no-op.

T1914 has the same write/reload shape but explicitly bumps mtimes
with `:! touch -t`, which is why T1914 reliably passes.  T8042 +
T17549 don't have the touch and so flip between PASS and FAIL run
to run.

This session: T17549 PASSed, T8042 FAILed.  Session 60+61: T17549
FAILed, T8042 PASSed.  Session 58: both FAILed.  The steady state
is "exactly one of {T8042, T17549} fails per run."  Touching
upstream's scripts to add `:! touch -t` would fix both
deterministically but is out of scope — this is upstream's
testsuite, not GHC.

## 7. Effort breakdown

- Reading session 61 HANDOFF + roadmap context: ~5 min.
- Copying runner + normaliser, extending `run_opts_for()`,
  inserting 6 TESTS entries: ~5 min.
- First runner run on pmacg5: ~7 min wall-clock (most spent
  ssh'ing per-test outputs back).
- Investigating T16563 trailing-newline diff (host GHC repro,
  upstream `testlib.py` reading): ~15 min.
- Normaliser trim + re-run: ~8 min wall-clock + 1 min coding.
- Session docs (README/findings/HANDOFF/commits): ~15 min.
- README/state.md/roadmap.md updates + commit: ~5 min.

Total: ~60 min.  Squarely a "verification-only" session — no
toolchain work, no source changes.
