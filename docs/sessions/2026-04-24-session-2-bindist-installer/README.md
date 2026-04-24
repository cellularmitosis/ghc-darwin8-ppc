# Session 2 — bindist installer (roadmap D)

**Date:** 2026-04-24.
**Starting state:** v0.2.0 tagged.  Cross-bindist tarball builds and
passes 21/25 tests.  No installer — users currently have to manually
rewrite `lib/settings` and symlink our scripts.

**Goal:** ship a working `./install.sh --prefix --ppc-host` that
makes installing the bindist as painless as tar + run + smoke-test.

**Ending state:** v0.3.0 tagged and released.  Bindist tarball now
includes `install.sh` at its root and `cross-scripts/` for reference.
A fresh user can `tar xJf ... && cd ... && ./install.sh --prefix=$P
--ppc-host=$H` and get a working cross-compile that ends with a
green smoke test ("hello from installed ghc-ppc-darwin8 bindist").

## Investigation

### Upstream `configure && make install` is close but broken

GHC's own bindist flow is: untar → `./configure` → `make install`.
`./configure` does detect cross-toolchain correctly (CC, ld, ar, etc.)
and writes a proper `settings` file.  But `make install` has two
cross-compile warts:

1. **Hardcoded `CrossCompilePrefix` assumption.**  In `mk/config.mk`:

   ```
   CrossCompilePrefix = $(if $(filter YES,$(Stage1Only)),powerpc-apple-darwin8-,)
   ```

   Default `Stage1Only=NO` means `CrossCompilePrefix` is empty, so the
   Makefile's `update_package_db` rule calls `ghc-pkg` (unprefixed),
   which doesn't exist in cross-compile bindists.  Fix: pass
   `Stage1Only=YES` to make.

2. **Unprefixed wrapper names.**  `prefix/bin/ghc` is a wrapper that
   `exec`s `prefix/lib/ghc-9.2.8/bin/ghc-9.2.8` — except the actual
   binary is `powerpc-apple-darwin8-ghc-9.2.8`.  The wrapper is dead.
   And the Makefile doesn't emit a `prefix/bin/powerpc-apple-darwin8-ghc`
   wrapper at all; you have to invoke `prefix/lib/ghc-9.2.8/bin/...`
   directly.

Both fixable upstream, but rolling our own installer is easier.

### Our install.sh approach

One shell script, ~180 lines.  Flags: `--prefix`, `--ppc-host`,
`--cross-cc`, `--cross-ld`, `--cctools-bin`, `--gmp-include`,
`--gmp-lib-remote`, `--skip-smoke`.  Auto-detects tools from env +
canonical locations.

Checks prereqs before doing anything.  Copies the tree with `cp -R`
instead of `make install` (no rename / rewrap magic needed since
we're not trying to preserve the upstream Makefile's oddities).
Writes `lib/settings` from a template with the detected paths
substituted in.  Runs `ghc-pkg recache`.  Smoke-tests with ssh.

Verified end-to-end with a fresh untar + install + smoke test.

### ppc-ld-tiger path-handling bug

Hit during install smoke test when installing outside `$HOME`:

```
ld: warning: directory '/private/tmp/.../lib/../lib/ppc-osx-ghc-9.2.8/rts-1.0.2'
    following -L not found
```

`ppc-ld-tiger.sh` only rsyncs libs when the `-L` path starts with
`/Users/` or `_build/`.  Installs under `/tmp/`, `/var/`, `/private/`,
`/opt/` (for pkg-style installs) would fail.

Fix: extend the pattern to include `/tmp/`, `/var/`, `/private/`, and
add a heuristic for other prefixes (directory exists locally AND
contains `libHS*`/`libC*` AND isn't under the usual system tree).

## Work landed

See [`commits.md`](commits.md).

## Things learned

- **Upstream bindist's make install works** for cross builds *if* you
  pass `Stage1Only=YES`.  Without that flag, recache fails because
  `CrossCompilePrefix` stays empty.
- **GHC's wrapper-script install doesn't handle cross naming.**  The
  prefix-less `ghc` wrapper is broken; the cross name is only in
  `lib/ghc-X.Y.Z/bin/`.
- **ppc-ld-tiger's local-path detection was too narrow.**  Now uses
  path prefixes + a "looks like a build tree" heuristic.
- **Testing with a fresh untar is a good check.**  I'd initially
  designed install.sh to run from the parent of the bindist dir, but
  when it ships inside the tarball, users run it from inside.  Had
  to support both layouts.

## Hand-off

Next session can tackle either:
- **Roadmap F: more test coverage.**  Threaded RTS, profiling, STM,
  sockets, long-running programs, dynamic linking.  Each is a
  small piece of work.
- **Roadmap C: GHCi / TemplateHaskell.**  Restore the PPC runtime
  Mach-O loader.  Bigger piece of work (could be a week).
- **Roadmap B: Stage2 native ghc debug.**  Even bigger.

Suggest F next — easy wins, likely to surface more real bugs.
