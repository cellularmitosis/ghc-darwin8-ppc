# Session 10 findings

## 1. ghc-pkg "just works"

Our `powerpc-apple-darwin8-ghc-pkg` is an arm64 binary that
manipulates the registered-package database.  It doesn't care about
target arch — it just reads/writes `.conf` files.  All commands
(`list`, `describe`, `field`, `latest`, `check`, `recache`) work.

## 2. runghc as a cross-compile concept

`runghc foo.hs` traditionally compiles `foo.hs` and runs the result
on the host.  For a cross-compiler this is undefined: the result
runs on the *target*.

Our `runghc-tiger` resolves this by adding the obvious extra step:
ship to target, run there.  Args + exit code forward.  Stdout/stderr
forward via ssh's terminal.

For interactive use this is good enough — slightly slower than a
real runghc because of the scp + ssh round-trip, but for scripting
purposes interactive Haskell-as-a-shell-tool works.

## 3. Why `runghc` itself isn't shipped

Hadrian's `defaultPackages Stage1` excludes `runGhc` when
`CrossCompiling`, with this reasoning:

```
++ [ runGhc   | not cross                  ]
```

The `runGhc` package is itself a Haskell program that wraps `ghc
--interactive --run`.  In cross mode, this would compile and try to
spawn a target binary on the host.  Wouldn't work.

So no `runghc-9.2.8` binary exists in our `bin/`.

Our shell-script `runghc-tiger` sidesteps that by living in
`scripts/` and being target-aware.

## 4. `ghc-pkg check` warnings

Output includes:

```
Warning: haddock-interfaces: .../docs/html/libraries/base/base.haddock doesn't exist
```

These are because the QuickCross flavour passes `--docs=none` so
haddock isn't run.  The package conf still contains the haddock-html
field pointing at where docs *would* be.  Cosmetic; package use is
fine.

If users care, we could either build haddock as a stage0 tool and
generate docs (slow), or strip the haddock fields from the package
confs at install time.  Punt for now.

## 5. arg-forwarding through ssh

`ssh host cmd "$@"` correctly forwards arguments, even with spaces
(the bash word-splitting is handled by ssh's argv reconstruction).
Tested with `runghc-tiger /tmp/foo.hs alpha "beta gamma" delta` —
the script saw `["alpha","beta gamma","delta"]`.
