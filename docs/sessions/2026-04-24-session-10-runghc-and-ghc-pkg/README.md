# Session 10 — `runghc` analog + verified ghc-pkg commands

**Date:** 2026-04-24.
**Starting state:** Session 9 deferred profiling.  No quick way to
"run a Haskell script" the way `runghc foo.hs` does on a normal GHC
install — because that wouldn't make sense for a cross-compiler.
**Goal:** ship a pragmatic equivalent + verify ghc-pkg query
commands work.
**Ending state:** ✅ `scripts/runghc-tiger` ships in scripts/.  Args
forward, exit codes propagate, temp file cleanup on both sides.
✅ All standard `ghc-pkg` query commands (list, describe, field,
latest, check) work via the cross `powerpc-apple-darwin8-ghc-pkg`.

## `runghc-tiger`

Why we can't just have `runghc` cross: `runghc foo.hs` compiles to
host arch and runs it.  Our compiler outputs PPC binaries — which
the host can't run.

`scripts/runghc-tiger foo.hs [args...]` does the obvious thing:

1. Compile `foo.hs` with the cross-ghc.
2. `scp` the binary to `$PPC_HOST` (default `pmacg5`).
3. `ssh $PPC_HOST <bin> [args]` and forward args.
4. Capture exit code + clean up the remote binary.

```
$ runghc-tiger /tmp/runghc-test.hs alpha beta gamma
args = ["alpha","beta","gamma"]
computing 2^30...
1073741824
ok
$ echo $?
0

$ runghc-tiger /tmp/runghc-test.hs fail
args = ["fail"]
computing 2^30...
1073741824
$ echo $?
7
```

Args and exit code forwarding both verified.

## ghc-pkg commands

All standard query commands work:

| Command | Verified working |
|---------|------------------|
| `ghc-pkg list` | yes — lists all 33 registered packages |
| `ghc-pkg describe <pkg>` | yes — full registration info |
| `ghc-pkg field <pkg> <field>` | yes — e.g. `field base exposed-modules` |
| `ghc-pkg latest <pkg>` | yes |
| `ghc-pkg check` | yes (warns about missing haddock dirs in our flavour, expected) |

These all work on the cross-toolchain because `ghc-pkg` is itself an
arm64-host binary that just reads/writes the package conf database.

## What we don't have

- `runghc` (real one): doesn't make conceptual sense for a cross
  compiler.  Use `runghc-tiger` instead.
- `ghci`: needs the GHCi runtime loader for PPC (roadmap C).
- `runhaskell`: same as runghc, see above.
- `haddock`: built only when `not cross` in `defaultPackages
  Stage1` (haddock is a host-side tool).

## Hand-off

`runghc-tiger` is ready to ship.  Adding it to the bindist tarball
+ documenting in cabal-cross.md / README.  Cut as part of v0.5.0
or held back depending on what else lands.
