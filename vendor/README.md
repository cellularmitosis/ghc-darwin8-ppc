# vendor/

Local copies of Hackage packages with Tiger-targeting patches.

- `splitmix/` — `splitmix-0.1.3.2` with `cbits-apple/init.c` rewritten
  to use `/dev/urandom` instead of `Security/SecRandom.h` (which
  Tiger's 10.4u SDK predates).  Upstream untouched fork:
  https://hackage.haskell.org/package/splitmix-0.1.3.2

Users pull these in via `cabal.project`:

```
packages:
  .
  /absolute/path/to/ghc-darwin8-ppc/vendor/splitmix/
```

See [`docs/cabal-cross.md`](../docs/cabal-cross.md) for the full
recipe.
