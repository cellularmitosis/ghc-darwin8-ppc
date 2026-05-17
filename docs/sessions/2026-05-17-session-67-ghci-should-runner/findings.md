# Session 67 findings

## TL;DR

New runner for `tests/ghci/should_run/` + `tests/ghci/should_fail/`
— **44/44 PASS** across two consecutive runs.  Zero new PPC-port
issues identified.  First runner to handle two upstream source
dirs and the `compile_and_run` GHCi shape in one file.

## 1. `compile_and_run` GHCi shape

Upstream's `testsuite/driver/testlib.py::interpreter_run` runs
`compile_and_run` tests under the `ghci` way by:

1. Generating a synthetic "genscript" with:
   - `:set prog <name>` — matches the compiled environment's argv[0].
   - `:set args <extra_run_opts>` — runtime args.
   - `:! echo ===== program output begins here` to stdout.
   - `:! echo 1>&2 ===== program output begins here` to stderr.
   - `System.IO.hSetBuffering ... LineBuffering`.
   - `GHC.TopHandler.runIOFastExit Main.main >> return ()` — runs
     the test's `main`.

2. Invoking `ghc --interactive <name>.hs < genscript` with stdout
   and stderr captured.

3. Splitting captured streams at the delimiter — pre-delimiter is
   compiler/banner output, post-delimiter is program output.
   Compare post-delimiter to the expected `.stdout`/`.stderr`.

We replicate this faithfully.  None of our 8 compile_and_run tests
use `extra_run_opts`, so `:set args` is empty.  Worked first try
on all 8 (ghcirun001..004 + T2589 + T2881 + T8377 + T19628 — the
last one even with multi-module loading thanks to the staged
`T19628a.hs` extras_for entry).

## 2. T18027 — `:script` with spaces in the filename

T18027 exercises `:script` (GHCi's load-and-execute-a-script
command) with a filename containing literal spaces:

```
:script T18027\ SPACE\ IN\ FILE\ NAME.script
:script "T18027 SPACE IN FILE NAME.script"
```

The companion file is `T18027 SPACE IN FILE NAME.script`.  Our
auto-discovery glob `$src/$name.*` doesn't match it — the next
char after `T18027` is a space, not a dot.

Fix: explicit `extras_for()` entry, with `:` as a placeholder for
space (since the `for x in $extras` loop splits on whitespace),
decoded at copy time via `tr ':' ' '`.

Same trick may be useful for any future test with whitespace in
its companion filenames; cheap to keep.

## 3. T15055 — `normalise_version('ghc')`

T15055's `.stderr` hardcodes `'ghc-8.5'`:

```
Could not load module 'GHC'
It is a member of the hidden package 'ghc-8.5'.
```

Upstream normalises both expected and actual to `ghc-<VERSION>`
via `normalise_version('ghc')`.  Our normalise.py already
supports `--version ghc`; we wire it through `norm_args_for()`
for this one test.  Our actual stderr says `ghc-9.2.8` (the
current series), which normalises to the same `ghc-<VERSION>`.
Match.

## 4. T18064 skipped — `leading_underscore()`

T18064 carries:
```python
when(leading_underscore(),skip)
```

On Mach-O platforms (macOS, including PowerPC Darwin), symbol
names have leading underscores in object files.  The test's
`.stderr` expects `Could not load 'blah'`, but our actual output
would be `Could not load '_blah'` (we prefix `_` in
`GHCi.ObjLink.lookupClosure`'s error path).  Upstream skips the
test on these platforms.  We do too — listed in the runner header
as out-of-scope.

## 5. T15633a/b skipped — typechecker plugin

Both T15633a and T15633b use:
```python
pre_cmd('$MAKE -s --no-print-directory -C tc-plugin-ghci package.plugins01 TOP={top}')
extra_hc_opts("-package-db tc-plugin-ghci/pkg.plugins01/local.package.conf -fplugin TcPluginGHCi")
```

The `pre_cmd` builds a local typechecker plugin via Makefile,
which is then loaded via `-fplugin`.  Out of shape for a
ghci-script runner — would need:
- A local Make + GHC build of the plugin against the cross-target.
- Plugin loading on PPC at runtime.

Skipped.  Could be revisited if/when plugin support becomes a
priority.

## 6. BinaryArray skipped — `normal` way

`test('BinaryArray', normal, compile_and_run, [''])` — runs the
test in the `normal` way (compile to native, run binary), not
GHCi.  Our runner is GHCi-only; running BinaryArray would need
the cross-build-and-remote-run flow that we already have via
`runghc-tiger`.  Out of scope for this runner.

If we ever extend coverage to the native-compile testsuite (the
"stage2 native-compile sweep" item from session 64's HANDOFF),
this test should be included there.

## 7. Runner shape: 5 lines of new code for the `compile_and_run` path

The new runner is ~270 lines.  About 50 lines are net-new beyond
session 62's `run-ghci-tnum.sh`:

- `family` column + `src_dir_for()` resolver (~10 lines).
- `kind` column + the `compile_and_run` branch in the
  staging + execution + comparison loops (~30 lines).
- `split_by_delim()` helper (~15 lines).
- `:` ↔ space encoding for whitespace in companion filenames (~5
  lines).

This is the first runner that does enough scaffolding to feel
like a generic upstream-driver replica; future test families
(eg. ghci/linking/, ghci/caf_crash/) should fit without
substantial new code.

## 8. Effort breakdown

- Read session 66 HANDOFF + the two source dirs' `all.T`: ~10 min.
- Read upstream's `interpreter_run` to understand
  `compile_and_run`-ghci shape: ~5 min.
- Write `run-ghci-should.sh` (mostly cloned + extended): ~15 min.
- First run: 43/44 PASS — investigate T18027 + add `extras_for`
  fix: ~5 min.
- Sanity re-runs (×2 at 44/44): ~5 min.
- Session docs (README/findings/HANDOFF/commits): ~25 min.

Total: ~65 min.  Faster than session 66 — the runner shape was
within striking distance after sessions 56/62/65/66, and the only
two judgement calls (genscript shape, whitespace-in-filenames)
both had clean answers.

## 9. No new PPC issues this session

Unlike session 66 (which surfaced the T16525a RTS-linker SIGSEGV),
this session uncovered zero new PPC-port issues.  All 37 in-scope
tests from `should_run/` passed; all 7 from `should_fail/` passed.
The runtime-linker, GHCi parser, `:script` / `:def` / `:set` /
`:t` / `:i` / `:kind` / `:instances` / `:type` commands, error
recovery, and `compile_and_run` (load + execute via bytecode)
paths all work as expected at v0.15.0.

## 10. Coverage milestone

Combined GHCi-style testsuite coverage at session 67 exit:

| Family | Count |
|--------|-------|
| tests/ghci/scripts/ T-prefix | 175/177 |
| tests/ghci/prog0NN | 17/17 |
| tests/ghci/T\<num\>/ | 7/8 |
| tests/ghci/should_fail/ | 7/7 |
| tests/ghci/should_run/ | 37/37 |
| **Total** | **243/246** |

Three known failures: HFS+ mtime-granularity flakes in
T8042/T17549 (session 64) and the T16525a SIGSEGV (session 66).
No new failures this session.
