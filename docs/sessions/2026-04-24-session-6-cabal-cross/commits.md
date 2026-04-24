# Session 6 commits

| SHA | Description |
|-----|-------------|
| 6ce2fb9 | Session 6: cabal cross-compile works; 5 Hackage pkgs verified on Tiger. |

Tags cut: `v0.4.0` ([release on GitHub](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.4.0), bindist unchanged from v0.3.0).

After the initial commit this session expanded the verified-packages
list to 6 (added `megaparsec`) + an integrated full-stack CLI demo
(aeson + vector + optparse-applicative reading a JSON file).  Those
demos weren't committed to tests/ (they live in `/tmp/cabal-cross-test/`)
but the recipe in `docs/cabal-cross.md` covers everything.
