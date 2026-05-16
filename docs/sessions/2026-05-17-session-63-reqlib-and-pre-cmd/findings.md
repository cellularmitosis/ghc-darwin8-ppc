# Session 63 findings

## TL;DR

Extended session 62's `run-ghci-tnum.sh` with a new `pre_cmd_for()`
lookup function plus one extra arm each in the existing
`run_opts_for()` and `norm_args_for()` tables.  Adds three tests:
T5975a, T5975b (UTF-8 filename `pre_cmd('touch ...')` smoke tests)
and T5979 (`reqlib('transformers')` + `normalise_version`).  All
three pass clean on the first run.  Result: **173/175 PASS**, with
the two failures being both T8042 *and* T17549 — the same HFS+
mtime-race flake seen in sessions 58/60/61/62, except this run was
unlucky on both coin-flips at once.  No GHC source changes, no new
patches, no release.

## 1. `reqlib` is essentially a TESTS-list addition for libs already in our package db

T5979's only requirement is that `transformers` be importable from
the stage2 ghc.  Checked once via:

```
$ ssh pmacg5 'find /opt/ghc-stage2/lib -name "transformers*.conf"'
/opt/ghc-stage2/lib/package.conf.d/transformers-0.5.6.2.conf
```

— present.  Our `transformers-0.5.6.2` is newer than upstream's
expected `0.5.2.0`, but `normalise_version("transformers")` (already
in `normalise.py` from session 58) reduces both to
`transformers-<VERSION>`.

If a future `reqlib` test references a library *not* in the stage2
package.conf.d, we'd need `cabal-cross` (or similar) to install it
into the stage2 ghc-pkg first.  T5979 is the only un-skipped `reqlib`
test in our T-prefix subset, so this stays hypothetical for now.

## 2. `pre_cmd` for simple shell snippets is a one-function extension

The new `pre_cmd_for()` mirrors the shape of the existing
`run_opts_for()` and `norm_args_for()` lookups, returning a shell
string that's injected into the per-test block between the `cd` and
the `ghc --interactive` line:

```
cd '<remote-base>/<test>'
$pre                                # ← new
ghc --interactive $opts < script > actual.stdout 2> actual.stderr
```

For `pre_cmd_for()` returning the empty string (the common case),
the injection becomes a blank line — harmless.

Tests whose `pre_cmd` is `$MAKE ...` (T6106, T19650, ghci056) need
either a Makefile shim or a more sophisticated pre-runner step
(compile a preprocessor, run `ghc-pkg latest base > my_package_env`,
etc.).  Those are deliberately deferred.

## 3. T5979's module-suggestion order matches upstream's 9.2.x

The expected `T5979.stderr` lists suggestions in
`State, Class, Cont` order:

```
Control.Monad.Trans.State (from transformers-<VERSION>)
Control.Monad.Trans.Class (from transformers-<VERSION>)
Control.Monad.Trans.Cont (from transformers-<VERSION>)
```

Our 9.2.8 stage2 produced the same order.  On the host's
`ghc-9.14.1`, the order was different (`State, Cont, Class`) — so
the suggestion-list sorter changed somewhere between 9.2 and 9.14,
but we don't care because we're testing 9.2.8 against itself.

If a future GHC bump (9.4? 9.6? 9.14?) is targeted, this test may
need a list-sort normaliser arm or be re-`--accept`ed.

## 4. UTF-8 filenames pass through SSH + bash heredoc + remote bash cleanly

Both `föøbàr1.hs` and `föøbàr2.hs` round-trip through:

```
local bash → remote_script construction → ssh → remote bash → touch
                                                            → ghc
```

with `LANG=en_US.UTF-8` exported on the remote side and no quoting
gymnastics needed.  The bytes survive every layer.  `ps -ef` shows
the bytes as `M-CM-6M-CM-8bM-C\240r2.hs` (which is just `ps`'s
escape for the high bytes); the actual filenames are UTF-8 on disk.

This was the only "could plausibly go wrong" piece of the wiring;
it just worked.

## 5. Empty `.script` + empty `.hs` + `-v0` produces zero bytes

T5975a's script is `:load föøbàr1.hs` (load an empty .hs file).
T5975b's script is empty (0 bytes) — `ghc --interactive` reads
stdin, hits EOF immediately, and exits.

With our standard flags (`-v0 -ignore-dot-ghci -fno-ghci-history
-fshow-warning-groups -fno-diagnostics-show-caret
-fdiagnostics-color=never`):

- T5975a: 0 bytes stdout, 0 bytes stderr.  `:load` of an empty .hs
  file is silent under `-v0`.
- T5975b: 0 bytes stdout, 0 bytes stderr.  ghci loading an empty
  positional `.hs` and then immediately exiting on stdin EOF is
  silent.

Verified locally with the host's `ghc-9.14.1` before the pmacg5 run;
pmacg5's 9.2.8 behaved the same.

## 6. Session 62's "exactly one HFS+ flake per run" was an undersample

Session 62 wrote:

> "T8042 + T17549 alternate as the unlucky coin-flip from run to run"
> "exactly one of {T8042, T17549} fails per run"

based on three data points (sessions 60/61/62 each had exactly one
of the pair failing).  Session 58, before the runner was extended,
had *both* failing.  This session also has *both* failing.

The shape: each test does `writeFile X → :load → writeFile X →
:reload`.  If both `writeFile`s land in the same HFS+ second, the
mtime doesn't change and `:reload` is a no-op.  Each test has its
own independent pair of writeFiles, so each test has its own
independent coin-flip — they don't alternate, they're independently
unlucky.

The steady-state floor for the 175-test subset is therefore:

- 175/175 (rare) — both lucky.
- 174/175 (likely) — one unlucky.
- 173/175 (also common) — both unlucky.

The "fix" remains either upstream-side (`:! touch -t` between the
writeFiles, as T1914 does) or local runner-side ("rerun the test
until it passes" — not done here).

## 7. Effort breakdown

- Reading session 62 HANDOFF + roadmap + extracting all.T entries:
  ~10 min.
- Probing host ghc-9.14.1 for T5975a/b/T5979 behaviour: ~5 min.
- Verifying `transformers-0.5.6.2` is in pmacg5's package.conf.d:
  ~1 min.
- Copying runner + normaliser, adding `pre_cmd_for()`, one new
  `run_opts_for()` arm, one new `norm_args_for()` arm, three new
  TESTS entries: ~10 min.
- Baseline run (171/172): ~7 min wall.
- Session 63 run1 (173/175): ~8 min wall.
- Session docs (README/findings/HANDOFF/commits): ~25 min.
- README/state.md/roadmap.md updates + commit: ~5 min.

Total: ~70 min.  Squarely a "harness extension only" session — no
toolchain work, no source changes.
