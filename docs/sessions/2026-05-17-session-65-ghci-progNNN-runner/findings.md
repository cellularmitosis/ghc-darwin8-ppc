# Session 65 findings

## TL;DR

New runner for `tests/ghci/prog001..prog019` — 17/17 PASS across two
consecutive runs.  Verification only.  No GHC source changes, no
patches, no release.  Skipped prog004 (makefile_test) + prog014
(expect_fail + pre_cmd $MAKE).

## 1. Per-test-dir staging shape

The session 56 / 58 / 60 / 62 / 63 / 64 runners stage individual
`.script` files from a single source directory
(`tests/ghci/scripts/`).  The prog0NN family wants the *whole
per-test directory* staged (each contains 3–7 `.hs` files plus the
`.script` plus the expected `.stdout` / `.stderr`).  Two adaptations:

1. `cp -R "$GHCI_DIR/$dir" "$dest"` — recursive copy catches
   subdirectories (prog015/016/017 have a `Level2/` subdir holding
   `Level2.hs`) and non-`.hs` files (prog006 has `Boot.hs-boot`,
   prog007 has `C.hs-boot`).
2. The single tar stream `(cd $STAGE && tar cf - .) | ssh ...` then
   preserves the per-test directory shape on the remote.  No
   per-test scp.

This makes the runner trivially extensible to other per-dir test
families — `T<num>/` subdirs (HANDOFF priority #3) would use the
same staging loop with a different TESTS list.

## 2. Test-name vs dir-name split

`tests/ghci/prog007/prog007.T` declares `test('ghci.prog007', ...)`.
The directory is `prog007/`; the test name (used as the `.script`
basename) is `ghci.prog007`.  Four tests do this: prog007, prog008,
prog009, prog010.  TESTS array stores both:

```
"prog007 ghci.prog007 0 0"
```

`prog001..prog006` and `prog011..prog019` have matching dir/test
names.  prog004 (makefile_test) is `ghciprog004` (no dot) — not
relevant since we skip it.

## 3. `$HC` + `$HC_OPTS` env vars

Four scripts (prog001, prog002, prog003, prog010) invoke ghc
mid-script to compile a `.hs` to a `.o`:

```
:shell "$HC" $HC_OPTS $ghciWayFlags -fforce-recomp -c D.hs
```

That's testing "GHCi picks up an object file dropped in alongside
the interpreted modules and uses it for subsequent loads".  Upstream
sets these env vars from `testlib.py:1301`:

```python
cmd = 'HC={{compiler}} HC_OPTS="{flags}" {{compiler}} ...'
```

We mirror that in the remote runner with an `export` block before
the test loop.

`HC_OPTS` is set to a subset of upstream `TEST_HC_OPTS`
(`testsuite/mk/test.mk:39`): kept the cosmetic flags
(`-fshow-warning-groups -fno-diagnostics-show-caret
-fdiagnostics-color=never -fno-warn-missed-specialisations
-no-user-package-db`), dropped the developer-mode lints
(`-dcore-lint -dstg-lint -dcmm-lint -Werror=compat
-dno-debug-output`).  The lints aren't required for output diffing
and would just slow down the test.

## 4. `ghciWayFlags` and `extra_ways`

prog001's .T has `extra_ways(['ghci-ext'])` — upstream runs prog001
twice, once in the normal way and once with `-fexternal-interpreter`
(the iserv way).  Upstream's `cmd_prefix('ghciWayFlags=' +
config.ghci_way_flags)` produces `ghciWayFlags=` (empty) for the
normal way and `ghciWayFlags=-fexternal-interpreter` for ghci-ext.

We run the normal way only.  Set `ghciWayFlags=''` in the export
block — the scripts' `:shell "$HC" $HC_OPTS $ghciWayFlags -c X.hs`
resolves to a regular compile.

If we ever want to add the ghci-ext way for prog001 we'd need to
arrange a `-pgmi=` SSH bridge or similar — but the iserv
infrastructure is already in place from v0.7.0 (TH).  prog001
ghci-ext would be a future addition.

## 5. Reload-after-touch flake — none observed

T8042 / T17549 in the `scripts/` runner flake on HFS+ 1-second mtime
granularity (`writeFile X → :load X → writeFile X → :reload` skips
the reload when both writes land in the same second).  Many prog
scripts have the same shape — prog001/002/003/005/006/010/012 all
do `:! sleep 1 ; :! touch X.hs ; :reload` or equivalent.

All of them explicitly bake in a 1-second sleep BEFORE the touch.
Run 1 and run 2 both passed clean.  This subset doesn't reproduce
the T8042/T17549 flake.  Speculation: the prog scripts are older
than T8042/T17549 (lower test numbers) and were authored when the
HFS+ issue was already known to test maintainers; the T-prefix
tests authored later (T8042 dates to issue #8042 which is from
2013-ish, T17549 to 2019-ish) appear to have forgotten the
convention.

T1914 in the scripts/ subset uses `:! touch -t 01010001 X.hs` to
force mtime explicitly, which is the most robust approach but
relies on the host's `touch` supporting `-t` (POSIX, fine).

## 6. `combined_output` semantics

prog018 is the only `combined_output` test in this subset.  The
script uses `:set -v1` to make ghc verbose; `:load C.hs` produces a
mix of progress chatter on stderr and module/symbol output on
stdout.  Upstream merges these into a single `.stdout` file via
`combined_output`'s `simple_run` machinery.  Our runner does the
same with `> actual.combined 2>&1`.

The merged ordering matches upstream's expected because both stdout
and stderr are line-buffered in this scenario and ghc emits them
roughly sequentially.  Not robust if a future test interleaves
heavily, but works here.

## 7. `-fkeep-going`

prog019 has `extra_hc_opts('-fkeep-going')` — instructs ghc to
continue past per-module compilation errors when loading a multi-
module program.  Routed through `run_opts_for()` the same way
session 60/62/63/64 routed other `extra_hc_opts` / `extra_run_opts`
flags.

The flag arrives on the `--interactive` command line; ghci honors
it during `:load A`'s walk over A, B, B1, B2, C, D, E (some of
which are deliberately broken to exercise the keep-going path).

## 8. `.hs-boot` files

prog006 has `Boot.hs-boot` listed as a regular extra_files entry.
prog007 has `C.hs-boot`.  These are .hs-boot stubs (forward-
declaration files for mutually-recursive modules).  Staged
verbatim via `cp -R`; ghc picks them up during `:l` because they're
in the same directory.

No special handling needed — `.hs-boot` is a normal file from the
filesystem's point of view; ghc's module finder discovers them by
extension.

## 9. Effort breakdown

- Read session 64 HANDOFF + roadmap context: ~10 min.
- Scope prog0NN family (read all 19 .T files + many scripts +
  expected outputs): ~15 min.
- Design runner (decide TESTS-array shape, env-var plumbing,
  staging recursion): ~10 min.
- Write `run-ghci-progNNN.sh` (mostly cloned + adapted from
  session 64): ~15 min.
- First run + analysis: ~5 min (no debugging needed).
- Second run for stability: ~5 min.
- Session docs (README/findings/HANDOFF/commits): ~30 min.

Total: ~1.5h.  Verification-only session shape, cleaner than
session 58's first-run iteration loop because session 64's runner
had absorbed every annotation flavour this subset needs.
