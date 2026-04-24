# Session 2 findings

## 1. GHC bindist's `Stage1Only` flag

`mk/config.mk` defines:

```makefile
CrossCompilePrefix = $(if $(filter YES,$(Stage1Only)),powerpc-apple-darwin8-,)
```

`Stage1Only` defaults to `NO`.  This means in a stock cross bindist,
`make install`'s `update_package_db` step tries to run `ghc-pkg`
(unprefixed) instead of `powerpc-apple-darwin8-ghc-pkg`, and fails
with `/bin/sh: .../bin/ghc-pkg: No such file or directory`.

Workaround: `make install Stage1Only=YES`.

## 2. GHC bindist unprefixed wrappers

Even after fixing #1, `prefix/bin/ghc` is a wrapper that invokes
`prefix/lib/ghc-9.2.8/bin/ghc-9.2.8` — which doesn't exist, because
the cross binaries are named `powerpc-apple-darwin8-ghc-9.2.8`.

Hadrian's `BinaryDist.hs` writes the wrapper list from the contents
of `wrappers/` (shipped as-is), and that dir has only `ghc` and
`ghc-9.2.8` (plus `ghci`, `ghci-9.2.8`) — no `powerpc-apple-darwin8-ghc`
wrapper at all.  `powerpc-apple-darwin8-ghc` as an invokable binary
only exists inside `lib/powerpc-apple-darwin8-ghc-9.2.8/bin/`.

Effective workaround: ignore the wrappers/, tell users to add
`prefix/lib/powerpc-apple-darwin8-ghc-9.2.8/bin/` to PATH, or write
our own wrapper in `prefix/bin/`.

Our install.sh does the latter: puts both `bin/` (arm64 binaries)
and `lib/` (ppc libs) at `prefix/` directly, with no unused
`lib/ghc-X.Y.Z/` shadow tree and no broken unprefixed wrappers.

## 3. ppc-ld-tiger's -L path prefix list was too narrow

Only `-L/Users/*` and `-L_build/*` were routed through the rsync-to-pmacg5
path.  Any other `-L` (e.g. install under `/tmp/` or `/opt/`) was
passed through verbatim and failed on the remote host.

Fixed by:
1. Expanding the explicit prefix list to `/Users`, `/tmp`, `/var`,
   `/private`, `_build`.
2. Adding a fallback heuristic for other prefixes: if the dir exists
   on uranium AND contains `libHS*`/`libC*` AND isn't under
   `/opt|/usr|/System|/Library`, treat as a build-tree path.

## 4. install.sh must support both cwd layouts

When install.sh ships *alongside* a fresh tarball extraction, it runs
from the parent of `ghc-9.2.8-powerpc-apple-darwin8/`.  When it ships
*inside* the tarball, it runs from inside that dir.  First attempt
hardcoded option 1 and broke when shipped option 2.

Fix: detect the bindist dir by looking for
`lib/package.conf.d/rts-1.0.2.conf` relative to both `.` and
`$(dirname $0)`.

## 5. Users still need prereqs we don't bundle

The tarball does NOT include:
- clang 7.1.1 + MacOSX10.4u.sdk (few hundred MB)
- cctools-port binaries (~40 MB)
- Host GHC 9.2.8 (~800 MB install)

install.sh checks for them and exits with a clear error if any is
missing.  Bundling everything would push the tarball from 117 MB to
~1.5 GB and duplicate artifacts the sibling llvm-7-darwin-ppc
project already ships.  Phase-2 of the installer (future session)
can offer `--with-llvm-ppc-tarball=...` to auto-install those too.
