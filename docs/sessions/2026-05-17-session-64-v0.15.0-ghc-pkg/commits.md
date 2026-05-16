# Session 64 commits

| SHA | Subject |
|-----|---------|
| [`575e6a1`](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/575e6a1c6bf99058fb391cb3eba868a1a4c22c0a) | v0.15.0: hadrian carve-out adds ghc-pkg/hp2ps/hsc2hs; skip cross bindist recache; T6106 + T19650 wired; 175/177 PASS. |

## Commit message

```
v0.15.0: hadrian carve-out adds ghc-pkg/hp2ps/hsc2hs; skip cross bindist recache; T6106 + T19650 wired; 175/177 PASS.

Same shape as v0.14.1's unlit fix, applied to ghc-pkg (and to
hp2ps + hsc2hs for "complete bindist" hygiene).

Two patch changes:
  - patches/0010-hadrian-cross-iserv.patch (amended):
    `[iserv, unlit]` → `[iserv, unlit, ghcPkg, hsc2hs, hp2ps]`.
    Cross-mode `buildProgram` now routes all five through
    `buildBinary` instead of copying the stage0 (host arm64) binary
    verbatim, producing real ppc Mach-O helpers.
  - patches/0018-hadrian-bindist-cross-skip-recache.patch (new):
    Skip hadrian's bindist-side `ghc-pkg recache` step when
    cross-compiling.  Post-patch-0010 the bindist's ghc-pkg is a
    target (ppc) binary that can't run on the arm64 host; `install.sh`
    re-caches on the target as part of its install sequence, so the
    user always gets a fresh cache there.

scripts/deploy-stage2.sh: also scp's `ghc-pkg` to
`/opt/ghc-stage2/bin/`.  hp2ps + hsc2hs ride in the bindist for
`install.sh` users but aren't needed by the deploy-script workflow.

Runner extension (sessions 60/62/63 shape):
  - Two new `pre_cmd_for()` arms: T6106 (`ghc-real --make
    T6106_preproc -v0`) and T19650 (`ghc-pkg latest base >
    my_package_env`).
  - One new `run_opts_for()` arm: T19650 (`-package-env -v1`).
  - One new `norm_args_for()` arm: T19650
    (`--filter-stdout-regex 'Loaded package env.*'`).
  - normalise.py gains a `filter_stdout_lines()` function and
    `--filter-stdout-regex` CLI flag, mirroring upstream's
    `testlib.py::filter_stdout_lines`.
  - Runner `norm` call sites wrapped with `eval` so multi-word
    regex args (single-quotes) round-trip through bash
    word-splitting.
  - TESTS list grows by two (175 → 177): T6106 (with explicit
    `../shell.hs` extras for the peer-of-scripts/ shell.hs helper)
    and T19650.

Result: 175/177 PASS on the now-177-test T-prefix subset.  Both
new tests PASS clean on the first run.  Two failures are again
both T8042 and T17549 (independent HFS+ 1-second mtime-granularity
coin-flips in upstream's `:reload` scripts; not PPC bugs).  All
annotation flavours in this subset are now wired; ghci056
($MAKE-style `pre_cmd`) is ghciNNN-shaped so out of scope for the
T-prefix runner.

Bindist re-rolled; tarball at
`_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`.
Demo at `demos/v0.15.0-ghc-pkg.sh` exercises `ghc-pkg --version`,
`list`, `latest base`, `field base version`, `field transformers id`
on pmacg5; all succeed.

README + demos/README.md + state.md + roadmap.md updated; tag pushed;
GitHub release with bindist asset uploaded.
```
