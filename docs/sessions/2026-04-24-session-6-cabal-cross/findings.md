# Session 6 findings

## 1. cabal-install recognizes cross-ghc correctly

`cabal-install 3.16.1.0` (the Homebrew-shipped version) reads the
cross-ghc's `settings` file, sees `"cross compiling": "YES"`, and:

- Uses the cross-ghc's installed package DB as the starting point
  for solving.
- Solves the dep graph against Hackage, downloads missing pkgs.
- Builds each dep with the cross-ghc → PPC `.o` / `.a`.
- Registers each dep into `.cabal-store/ghc-9.2.8/<pkg-hash>/`.
- Links the final executable using our `powerpc-apple-darwin8-ld`
  (via the cross-ghc's settings).

No cabal patches needed.

## 2. `-w <cross-ghc>` + `--with-hsc2hs <host-hsc2hs>` is the magic incantation

```
cabal build \
  --with-compiler=<cross-ghc> \
  --with-hsc2hs=<arm64-host-hsc2hs> \
  --store-dir=./.cabal-store
```

`--with-compiler` tells cabal the target.  `--with-hsc2hs` tells
cabal which hsc2hs runs during build (on HOST).  Without the
second, cabal naïvely cross-builds hsc2hs for PPC and then
tries to run it on arm64 — fails.

Same principle would apply to `--with-happy` / `--with-alex` for
packages that need those.  Our `stage0/bin/` has arm64 copies.

## 3. The `dist/build/ppc-osx/ghc-9.2.8/<pkg>/` output layout

Cabal uses the target triple in the build dir name.  Makes it
obvious these are PPC artifacts, not confused with host builds.

## 4. Pure-Haskell Hackage mostly Just Works

5 top-level packages tried; all built successfully, all ran on
Tiger, all produced correct output.  No surprises in the numeric
/ list / ADT / generic / class paths.

## 5. TH: clean failure, no cryptic error

```
powerpc-apple-darwin8-ghc: Couldn't find a target code interpreter.
Try with -fexternal-interpreter
```

This is a GHC error, not a cabal error.  Clear and actionable
(even if the action is "wait for us to restore the GHCi loader").

## 6. Vendored package override via `cabal.project`

`packages: /path/to/vendored/pkg/` in `cabal.project` lets users
inject a patched copy.  Cabal's solver picks the higher-priority
local copy over the Hackage version automatically.  This is the
clean way to patch ecosystem packages for Tiger.

## 7. `/dev/urandom` works on Tiger

Tiger has had `/dev/urandom` since always.  The splitmix init.c
rewrite that replaces `Security/SecRandom` with a stdio read is
~15 lines.  This pattern will work for many other packages that
reach for macOS crypto frameworks.

## 8. Network SDK gap

`SOCK_CLOEXEC` (10.7+) is referenced unconditionally in network's
Cbits.hsc.  Symptom of a broader issue: packages that "assume
macOS has feature X" without checking macOS version.  Fixable per-
package, but the ecosystem assumes a recent macOS.

## 9. Cabal's warning about `--with-compiler`

Network's `./configure` prints:
```
configure: WARNING: unrecognized options: --with-compiler
```

Cabal passes `--with-compiler` to the package's own `./configure`
(for packages with custom-setup).  Network's configure doesn't
know this flag and ignores it — which is fine, it's not fatal.
Just noise.
