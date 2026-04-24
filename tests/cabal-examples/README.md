# Cabal cross-compile examples for PPC/Darwin8

Each subdirectory is a self-contained cabal project that builds and
runs on Tiger.  Use them as starting points for your own programs.

| Example | Exercises |
|---------|-----------|
| [`random/`](random/) | `random` + (vendored) `splitmix` for seeded RNG. |
| [`async/`](async/) | `async` high-level concurrency (wait, concurrently). |
| [`vector/`](vector/) | `vector` boxed + unboxed arrays. |
| [`aeson-generics/`](aeson-generics/) | JSON encode/decode via `GHC.Generics`. |
| [`optparse/`](optparse/) | CLI arg parsing + `--help` via `optparse-applicative`. |
| [`megaparsec/`](megaparsec/) | Parser combinators. |
| [`network-echo/`](network-echo/) | TCP echo server + client (pinned `network < 3.0`). |
| [`full-stack-cli/`](full-stack-cli/) | JSON file reader combining aeson + vector + optparse. |

## Build any example

From this directory:

```
cd <example>

source ../../scripts/cross-env.sh
STAGE1=$PWD/../../external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc
HSC2HS=$PWD/../../external/ghc-modern/ghc-9.2.8/_build/stage0/bin/powerpc-apple-darwin8-hsc2hs

cabal --store-dir=./.cabal-store \
      build \
      --with-compiler=$STAGE1 \
      --with-hsc2hs=$HSC2HS \
      --builddir=./dist

BIN=$(find dist/build -name <exe-name> -type f -perm -u+x | head -1)
scp -q "$BIN" your-tiger-box:/tmp/ && ssh your-tiger-box /tmp/<exe-name>
```

## The cabal.project.tiger template

`cabal.project.tiger` at this directory's root is the shared template
each example copies as `cabal.project`.  It:
- Pulls in our vendored splitmix.
- Pins `network < 3.0` so older Tiger-safe network is picked.

If you're starting a new Tiger project from scratch, copy this file
as `cabal.project` and edit `packages:` to reference your project.

## Why we keep these as source-only (no prebuilt binaries)

Prebuilt PPC binaries would balloon this repo.  The recipe above
takes ~1–15 minutes per example to build (most of that is cabal
resolving + first-build of each dep; subsequent builds are fast).
