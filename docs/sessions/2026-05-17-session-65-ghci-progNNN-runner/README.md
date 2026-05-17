# Session 65 — prog001..prog019 runner; 17/17 PASS

**Date:** 2026-05-17 (continuation of session 64).

**Status on arrival:** v0.15.0 shipped in session 64 — `ghc-pkg`,
`hp2ps`, `hsc2hs` cross-build as real ppc binaries; patch 0018 skips
the bindist-side `ghc-pkg recache` for cross-builds.  The
`tests/ghci/scripts/all.T` T-prefix subset is at 175/177 PASS (the
2 failures are the HFS+ T8042 + T17549 coin-flips).  Every
annotation flavour in that subset is now wired.  Session 64
HANDOFF's recommended pickup: breadth — extend coverage into
another tests/ghci/ family.  Listed options, in order: stage2
native-compile sweep, `prog001..prog019`, bug-numbered `T<num>/`
subdirs, third-party library audit.  Picked option #2 (`prog001..
prog019`) as the most tractable in one session and the most
directly leveraging the existing runner shape.

**Status on exit:** New runner
[`scripts/run-ghci-progNNN.sh`](scripts/run-ghci-progNNN.sh) at
**17/17 PASS** across two consecutive runs.  No GHC source changes,
no new patches, no release.  prog004 (`makefile_test`) and prog014
(`expect_fail` + `pre_cmd($MAKE)`) are deliberately skipped as
out-of-shape for a ghci-script runner.

## What was done

### 1. Scoped the prog0NN test family

19 `prog0NN` directories under `tests/ghci/`; each has a single `.T`
file declaring one test.  Read all 19 `.T` files; classified into
in-scope vs out-of-scope:

| Test | Notes |
|------|-------|
| prog001 | `ghci_script`, extra_files (../shell.hs), `:shell "$HC" ... -c D.hs`, ghciWayFlags. |
| prog002 | `ghci_script`, extra_files (../shell.hs), `:shell "$HC" ...`, ghciWayFlags. |
| prog003 | `ghci_script`, extra_files (../shell.hs), `:shell "$HC" ...`, ghciWayFlags, `when(opsys('mingw32'), skip)`. |
| **prog004** | **SKIP — `makefile_test('ghciprog004')`, not `ghci_script`.** |
| prog005 | `ghci_script`, extra_files only.  Uses `:!` (not `:shell`), `:! sleep 1`, `:! touch A.hs`. |
| prog006 | `ghci_script`, extra_files including `Boot.hs-boot`. |
| prog007 | `ghci_script` named `ghci.prog007`, extra_files including `C.hs-boot`. |
| prog008 | `ghci_script` named `ghci.prog008`, extra_files. |
| prog009 | `ghci_script` named `ghci.prog009`, extra_files. |
| prog010 | `ghci_script` named `ghci.prog010`, extra_files (../shell.hs), `:shell "$HC" ...`, ghciWayFlags. |
| prog011 | `ghci_script`, `normal` — simplest (no extras). |
| prog012 | `ghci_script`, extra_files (../shell.hs). |
| prog013 | `ghci_script`, extra_files. |
| **prog014** | **SKIP — `expect_fail` + `pre_cmd('$MAKE -s prog014')`.** Bytecode interpreter doesn't support foreign-import-prim; out of shape for this runner. |
| prog015 | `ghci_script`, extra_files with `Level2/` subdirectory. |
| prog016 | `ghci_script`, extra_files with `Level2/` subdirectory. |
| prog017 | `ghci_script`, extra_files with `Level2/` subdirectory. |
| prog018 | `ghci_script`, `combined_output`, extra_files. |
| prog019 | `ghci_script`, `extra_hc_opts('-fkeep-going')`, extra_files. |

17 in-scope; 2 skipped.

### 2. Designed the runner

Mostly session 64's `run-ghci-tnum.sh` shape, with three deltas:

1. **Per-test directory** instead of per-test single .script.  The
   staging loop does `cp -R "$GHCI_DIR/$dir" "$dest"` — recursive
   copy catches `Level2/` automatically.
2. **Test-name vs dir-name split**.  For `ghci.prog00{7,8,9,10}`
   the .T's test name has a `ghci.` prefix while the directory is
   just `prog00N`.  The TESTS array stores both: `dir name combined
   need_shell_hs`.
3. **Remote env vars** `HC`, `HC_OPTS`, `ghciWayFlags`.  Some
   scripts execute `:shell "$HC" $HC_OPTS $ghciWayFlags
   -fforce-recomp -c X.hs` to do partial native compilation between
   `:reload`s.  Set the three env vars in the remote runner's
   `export` block once and they're visible to every test (and to
   every `:shell`-launched subshell via the inherited environment).

`HC_OPTS` mirrors a subset of upstream `TEST_HC_OPTS` (see
`testsuite/mk/test.mk:39`).  Dropped: `-dcore-lint -dstg-lint
-dcmm-lint -Werror=compat -dno-debug-output` (developer-mode
hygiene, not needed for output diffing).  Kept: `-fshow-warning-
groups -fno-diagnostics-show-caret -fdiagnostics-color=never
-fno-warn-missed-specialisations -no-user-package-db`.

`ghciWayFlags` is set empty — we only run the default way, never
the `ghci-ext` way that prog001's `extra_ways(['ghci-ext'])` would
introduce on upstream.  The `cmd_prefix('ghciWayFlags=' +
config.ghci_way_flags)` annotation produces an empty string for the
default way anyway.

Per-test `extra_hc_opts` for prog019 (`-fkeep-going`) routed through
the same `run_opts_for()` shape as session 60/62/63/64.

### 3. Verification

Run 1: **17/17 PASS** (~3-4 minutes wall on pmacg5).  Run 2 (sanity
re-run for HFS+ flake check): **17/17 PASS**.

No new normaliser rules needed — session 64's `normalise.py` (with
`normalise_errmsg`, `normalise_callstacks`, the trailing-blank
trim, and the `filter_stdout_lines` machinery from session 64) is
sufficient.

### 4. Reload-after-touch flake risk: covered upstream

The HFS+ 1-second mtime-granularity race that flakes T8042 / T17549
in the `scripts/` runner could in principle bite any test that
does `writeFile X → :load X → writeFile X → :reload`.  In this
subset the candidates are prog001/002/003/005/006/010/012 — all
of which do `cp` or `touch` between :load and :reload.  All seven
explicitly contain `:! sleep 1` (or `:shell sleep 1`) before the
second write.  Two consecutive runs both passed clean; we don't
observe the flake here.

## What this means

- **Three new dimensions covered**: per-test-dir staging,
  `.hs-boot` files in the source tree, recursive `Level2/`
  subdirectory.  All three Just Work via `cp -R` + tar over ssh.
- **`$HC`-style scripted re-compile path works on PPC/Tiger.**
  prog001/002/003/010 each invoke `$HC` mid-script (compile a .hs
  to a .o, :reload to pick up the object code over the bytecode).
  Stage2 ghc on PPC compiles + caches + reloads these object files
  during a live GHCi session without trouble.  This is the same
  load path that v0.14.2's `__dso_handle` Mach-O fix unblocked for
  `StaticPtr`, exercised here over a much broader compile-graph
  shape.
- **`combined_output` works** (prog018) — stderr from `:set -v1`
  diagnostic chatter merges into stdout for the diff.
- **`-fkeep-going` works** (prog019) — `:load` continues past
  module-level type errors.

## Files added this session

- `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
- `scripts/run-ghci-progNNN.sh` — the new runner.
- `scripts/normalise.py` — verbatim copy of session 64's.
- `logs/01-run1.log`, `logs/02-run2.log` — run logs.
- `logs/ghci-progNNN/<dir>/...` — per-test staged inputs + actuals
  + expecteds.

## Hosts

- **uranium** — runner driver.
- **pmacg5** — runs the v0.15.0 ppc stage2 ghc-real.
- **indium** — not used.

## What's next

See [`HANDOFF.md`](HANDOFF.md).
