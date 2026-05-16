# Session 64 — Release v0.15.0: ghc-pkg packaging fix shipped; T6106 + T19650 wired

**Date:** 2026-05-17 (continuation of session 63).

**Status on arrival:** Session 63 shipped 173/175 PASS on the
175-test T-prefix subset, having wired `reqlib(...)` (T5979) and
simple `pre_cmd(...)` (T5975a/b) annotations.  Session 63 HANDOFF's
top recommendation: `$MAKE`-style `pre_cmd` tests (T6106, T19650,
ghci056) — each needs richer plumbing.  Diagnosis from session 63:
T6106 needs a native compile of the preproc + `../shell.hs`;
T19650 needs `ghc-pkg` deployed on pmacg5 (which it wasn't — the
cross-build was producing a host arm64 ghc-pkg via the same patch-
0010 carve-out hole that v0.14.1 fixed for unlit).

**Status on exit:** *(to be filled in after runner + release)*

## What was done

### 1. Patch 0010 amendment (v0.15.0 fix)

Same shape as v0.14.1's unlit amendment.  The cross-mode arm of
`buildProgram` in `hadrian/src/Rules/Program.hs` changed from

```haskell
(True, s) | s > Stage0 && package `notElem` [iserv, unlit] -> ...
```

to

```haskell
(True, s) | s > Stage0 && package `notElem` [iserv, unlit, ghcPkg, hsc2hs, hp2ps] -> ...
```

All three new entries were already imported in scope.  Cross-mode
`ghc-pkg`, `hsc2hs`, and `hp2ps` now fall through to `buildBinary`
and produce real PPC Mach-O binaries instead of copying the stage0
(host) arm64 binaries verbatim.  Live source edit at
[`hadrian/src/Rules/Program.hs`](../../../external/ghc-modern/ghc-9.2.8/hadrian/src/Rules/Program.hs);
patch file at
[`patches/0010-hadrian-cross-iserv.patch`](../../../patches/0010-hadrian-cross-iserv.patch).

### 2. Stage1 rebuild — cross-build the three helpers

```bash
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh
./hadrian/build --flavour=quick-cross --docs=none -j8 \
  _build/stage1/bin/powerpc-apple-darwin8-ghc-pkg
# → Build completed in 1m25s.
./hadrian/build --flavour=quick-cross --docs=none -j8 \
  _build/stage1/bin/powerpc-apple-darwin8-hp2ps \
  _build/stage1/bin/powerpc-apple-darwin8-hsc2hs
# → Build completed in 44s.
```

Resulting binaries:

| Binary | Pre-v0.15.0 | Post-v0.15.0 |
|--------|-------------|--------------|
| `powerpc-apple-darwin8-ghc-pkg` | Mach-O 64-bit executable arm64 | Mach-O executable ppc |
| `powerpc-apple-darwin8-hp2ps`   | Mach-O 64-bit executable arm64 | Mach-O executable ppc |
| `powerpc-apple-darwin8-hsc2hs`  | Mach-O 64-bit executable arm64 | Mach-O executable ppc |

### 3. `deploy-stage2.sh` updated; ghc-pkg deployed to pmacg5

`scripts/deploy-stage2.sh` now also `scp`s
`_build/stage1/bin/powerpc-apple-darwin8-ghc-pkg` to
`/opt/ghc-stage2/bin/ghc-pkg` and chmods +x.  hp2ps and hsc2hs are
not yet deployed by the script (they ship in the bindist for users
who run `install.sh`, but the deployed runtime tree doesn't need
them for the test-runner workflow).

Smoke test:

```
$ ssh pmacg5 'DYLD_LIBRARY_PATH=... /opt/ghc-stage2/bin/ghc-pkg --version'
GHC package manager version 9.2.8

$ ssh pmacg5 'DYLD_LIBRARY_PATH=... /opt/ghc-stage2/bin/ghc-pkg latest base'
base-4.16.4.0
```

### 4. Runner extension — `pre_cmd_for(T6106|T19650)` + extras

Extended [`scripts/run-ghci-tnum.sh`](scripts/run-ghci-tnum.sh) with
two new `pre_cmd_for()` arms (paraphrasing the upstream `$MAKE`
targets in `testsuite/tests/ghci/scripts/Makefile`):

```bash
T6106)  echo "/opt/ghc-stage2/bin/ghc-real --make T6106_preproc -v0" ;;
T19650) echo "/opt/ghc-stage2/bin/ghc-pkg latest base > my_package_env" ;;
```

Plus one new arm in `run_opts_for()` for T19650's
`extra_hc_opts('-package-env my_package_env -v1')`, one new arm in
`norm_args_for()` for T19650's `filter_stdout_lines(r'Loaded package
env.*')`, and two new TESTS entries (T6106 with explicit
`../shell.hs` extras for the peer-of-`scripts/` shell.hs helper;
T19650).

### 5. `normalise.py` — `--filter-stdout-regex` flag

New flag mirroring upstream's `testlib.py::filter_stdout_lines` — the
`re.findall(regex, s)`-joined-by-newlines transform.  Applied first in
the pipeline so subsequent rules only see the matching lines.

### 6. Runner call-site refactor — `eval`-wrap `norm`

Multi-word regex args (e.g. `'Loaded package env.*'`) need their
embedded single-quotes preserved through bash's word-splitting.
Wrapped each `norm "$dir/<file>" $nargs` call with `eval` so the
inner quotes re-parse correctly.  No behavior change for tests
whose `norm_args_for()` returns an empty string or single-token args.

### 7. Verification — first run

*(to be filled in)*

### 8. Bindist re-roll + release

*(to be filled in)*

## What this means

- **The "complete bindist" theme:** v0.14.1 fixed `unlit`, v0.14.2
  fixed `__dso_handle` Mach-O linkage, v0.15.0 fixes `ghc-pkg` +
  `hp2ps` + `hsc2hs`.  The bindist's helper-binary set is now fully
  ppc.  Remaining `bin/` helpers (`haddock`, `hpc`, `runghc`,
  `runhaskell`) aren't shipped by hadrian's cross-stage1 (they're
  guarded by `not cross` in `hadrian/src/Settings/Default.hs`'s
  `stage1Packages`); enabling those would be a separate, larger
  scope (potentially their own release).
- **T19650 + T6106 are the last `pre_cmd` tests in the T-prefix
  subset.**  ghci056 is `ghciNNN`-shaped (out of scope for this
  runner; belongs to session 56's `run-ghci-numbered.sh`).  Every
  test annotation our T-prefix runner sees is now wired.
- **The filter-stdout-regex machinery is generic.**  Other tests
  that need line-pattern filtering can reuse it via `norm_args_for()`.

## Files added this session

- `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
- `scripts/run-ghci-tnum.sh` — session 63's runner with two new
  `pre_cmd_for()` arms, one new `run_opts_for()` arm (T19650), one
  new `norm_args_for()` arm (T19650 — multi-word regex), `eval`-wrap
  on the `norm` call sites, and two new TESTS entries.
- `scripts/normalise.py` — session 63's normaliser plus a new
  `filter_stdout_lines` function and `--filter-stdout-regex` CLI flag.
- `logs/00-runner-diff.log` — diff vs session 63's runner.
- `logs/01-run1.log` — full PASS/FAIL log for this session's run.
- `patches/0010-hadrian-cross-iserv.patch` — amended to add `ghcPkg`,
  `hsc2hs`, `hp2ps` to the cross-mode carve-out.
- `scripts/deploy-stage2.sh` — now also `scp`s ghc-pkg to remote.
- `demos/v0.15.0-ghc-pkg.{sh}` — ghc-pkg smoke-test demo.

## Hosts

- **uranium** — source edits, hadrian builds, runner.
- **pmacg5** — runs the v0.15.0 ppc stage2 ghc-real + the newly
  deployed ghc-pkg.
- **indium** — not used.

## What's next

See [`HANDOFF.md`](HANDOFF.md).
