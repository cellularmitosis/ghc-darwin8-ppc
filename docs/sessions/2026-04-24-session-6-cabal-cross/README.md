# Session 6 — Cabal cross-compile (roadmap F extension / new direction)

**Date:** 2026-04-24.
**Starting state:** v0.3.0 tagged.  Battery 34 programs, 30 PASS.
User asked to take on Cabal-on-Tiger unsupervised for 8 hours.
**Goal:** get `cabal build --with-compiler=<cross-ghc>` working for
real Hackage packages — proof that the toolchain is useful for
real Haskell, not just our hand-written 34 tests.
**Ending state:** **5 Hackage packages (+1 transitive) building and
running on Tiger** via cabal cross-compile.  Vendored splitmix with
a Tiger-friendly init.c.  Full recipe documented.  TH limitation
confirmed + documented.  network limitation identified + documented.

## The big win

`cabal-install` on uranium + `--with-compiler=<cross-ghc>` just
works for pure-Haskell packages.  No patches needed to cabal
itself.  The solver correctly uses our cross-ghc's installed
package database, builds deps from Hackage, links with
`ppc-ld-tiger`, produces PPC Mach-O executables.

Verified packages:

| Package | Exercises |
|---------|-----------|
| `random` + `splitmix` + `data-array-byte` | RNG, C FFI, /dev/urandom |
| `async` | High-level concurrency (wait, concurrently) |
| `vector` + `vector-stream` + `primitive` | Unboxed arrays, stream fusion |
| `aeson` (+ ~20 transitive) | JSON encode/decode with Generics |
| `optparse-applicative` (+ `prettyprinter`, `ansi-terminal`) | CLI parsing, help text, ANSI output |

Each was built, scp'd to pmacg5, and ran producing correct output.

## Vendored splitmix

The only patch needed so far.  `splitmix-0.1.3.2`'s
`cbits-apple/init.c` uses `Security/SecRandom.h` to seed the RNG,
but Tiger's SDK predates that framework.  `vendor/splitmix/` is
a local copy with:

- `cbits-apple/init.c` rewritten to use `/dev/urandom` (Tiger
  has it since always).
- `frameworks: Security` stripped from `splitmix.cabal`'s apple
  conditional.

Users pull it in via `cabal.project`:

```
packages:
  .
  /path/to/ghc-darwin8-ppc/vendor/splitmix/
```

See `docs/cabal-cross.md` for the full recipe.

## Limitations found

### 1. Template Haskell is cleanly unsupported

Any `$(spliceFn ...)` or `deriveJSON`-style macro fails with:

```
powerpc-apple-darwin8-ghc: Couldn't find a target code interpreter.
Try with -fexternal-interpreter
```

Root cause: TH requires GHCi-in-reverse — the splice runs on the
HOST and injects code into the TARGET binary.  That needs a working
host-side GHCi, which in turn needs our runtime Mach-O loader
restored (roadmap C).

Workaround: `GHC.Generics` derivation works fine.  `instance ToJSON
Person` via Generic produces the same JSON as
`$(deriveJSON defaultOptions ''Person)`.

### 2. `network-3.2.8.0` hits a Tiger SDK gap

hsc2hs-preprocessed `Cbits.hsc` references `SOCK_CLOEXEC` which
doesn't exist in Tiger's `<sys/socket.h>`.  Fixable by vendoring
with a guard, or using network ≤ 3.0.  Deferred to a future session.

### 3. Build-tools need HOST paths

Packages that preprocess with `hsc2hs` need cabal to know about
the host-side hsc2hs, not a cross-built one.  Pass
`--with-hsc2hs=<arm64-hsc2hs>` (our stage0/bin has one).  Without
this, cabal happily builds hsc2hs FROM SOURCE with our cross-ghc,
producing a PPC binary, then tries to run it on arm64 → fails.

Same principle applies to `happy`, `alex`, and other build-tools.
Point cabal at the host-side copies.

## Recipe

See [`docs/cabal-cross.md`](../../cabal-cross.md) for the quick-start
and full guide.

## Packaging

Vendored splitmix committed to `vendor/splitmix/`.  Cabal cross
recipe added as `docs/cabal-cross.md`.  No bindist changes needed
(users bring their own cabal-install).

## Hand-off

Next sessions can tackle:
- **Patch more packages** — a weekly "vendor one troublesome
  Hackage pkg" cadence could unblock `network`, `time-compat`,
  `pretty-simple`, etc.
- **TH via external-interpreter** — if we can route TH splices
  through ssh-to-pmacg5-and-run-a-ppc-iserv, TH works even without
  restoring the MachO loader on-host.  Speculative but clever.
- **Roadmap C (GHCi loader)** — the Real Fix for TH.
