# Session 8 — cabal-examples (usable templates + run-one.sh)

**Date:** 2026-04-24.
**Starting state:** v0.4.0 released, cabal cross-compile recipe
documented, 7 verified Hackage packages.  All the working example
code lived in `/tmp/cabal-cross-test/` and wasn't reproducible
for a fresh user.
**Goal:** package each verified pattern as a standalone `cabal-examples/<name>/`
project with a `.cabal`, a `Main.hs`, and a `cabal.project` where
needed.  Add a `run-one.sh` that builds + ships + runs in one
command.
**Ending state:** ✅ 8 self-contained cabal examples under
`tests/cabal-examples/`, each smoke-tested end to end against pmacg5.

## The 8 examples

| Dir | Main dep | What it demonstrates |
|-----|----------|----------------------|
| `random/` | `random` (+ vendored splitmix) | Seeded RNG |
| `async/` | `async` | High-level concurrency |
| `vector/` | `vector` | Boxed + unboxed arrays |
| `aeson-generics/` | `aeson` | JSON via Generics (no TH) |
| `optparse/` | `optparse-applicative` | CLI parsing + help text |
| `megaparsec/` | `megaparsec` | Parser combinators |
| `network-echo/` | `network < 3.0` | TCP server + client |
| `full-stack-cli/` | aeson + vector + optparse | JSON file reader with sorting |

## run-one.sh

`tests/cabal-examples/run-one.sh <example> [args...]` does:
1. Sets up cross-env + finds cross-ghc + host-hsc2hs.
2. Writes a default `cabal.project` if the example doesn't have one.
3. `cabal build` with `--with-compiler` + `--with-hsc2hs`.
4. Locates the compiled executable.
5. `scp` to `$PPC_HOST` (default `pmacg5`).
6. `ssh $PPC_HOST <exe> [args]`.

Example invocations tested this session:
```
./run-one.sh optparse --name world --count 2   # Hello, world! x 2
./run-one.sh random                             # seed-42 RNG → 49
./run-one.sh full-stack-cli --input /tmp/people.json  # sorted table
```

## `cabal.project.tiger`

Shared template at `tests/cabal-examples/cabal.project.tiger` for
users starting new projects.  Pulls in our vendored splitmix and
pins `network < 3.0`.

## Mid-session fix

`full-stack-cli` and `aeson-generics` need the vendored splitmix
because `aeson → scientific → random → splitmix` is their
transitive graph.  Added `cabal.project` to each pointing at
`../../../vendor/splitmix/`.

## Hand-off

Test coverage of the cabal-cross surface is now as good as it gets
without vendoring more packages:
- 8 runnable examples covering the major patterns.
- `cabal.project.tiger` template for user onboarding.
- `run-one.sh` makes a build + Tiger-smoke-test a one-liner.

Sessions 6, 7, 8 taken together deliver the "cabal works" story
end to end.  Users can clone the repo, install the bindist
(via v0.3.0+ `install.sh`), copy an example dir, adapt it, and
have their first cross-compiled Hackage-package-using Tiger
binary in minutes.
