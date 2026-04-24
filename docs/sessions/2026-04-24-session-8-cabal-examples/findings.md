# Session 8 findings

## 1. Transitive splitmix

Any package depending on `aeson`, `scientific`, `uuid-types`, or
`QuickCheck` transitively pulls `random` → `splitmix`, so needs
our vendored splitmix.  Examples that need the `../../../vendor/splitmix/`
reference:

- `aeson-generics/` (direct aeson)
- `full-stack-cli/` (aeson + vector)
- Any future example using aeson / QuickCheck / uuid-types / etc.

The `cabal.project.tiger` template includes this by default so users
don't need to think about it.

## 2. `run-one.sh`'s happy paths

- With a `cabal.project` in the example dir: uses it as-is.
- Without: writes `packages: .` as default.

This means the `random/` example's `cabal.project` (which adds vendored
splitmix) is preserved, and simpler examples without `cabal.project`
just get `packages: .`.

## 3. Binary locations via `find`

`dist/build/ppc-osx/ghc-9.2.8/<pkg>-<ver>/x/<exe>/build/<exe>/<exe>`
is the predictable cabal layout.  run-one.sh uses `find dist/build
-type f -perm -u+x` to locate without hardcoding the path.

## 4. `--with-hsc2hs` essential even when hsc2hs isn't needed directly

The examples that don't use .hsc files still pass `--with-hsc2hs`
because cabal insists on having one for the build plan, even if
unused.  If we don't pass it, cabal cross-builds `hsc2hs` as a ppc
binary and then can't run it.

## 5. Full-stack-cli = "real" demo

aeson + vector + optparse + people.json + sorting + table output
is genuinely useful code.  41 MB binary runs cleanly on Tiger:

```
$ /tmp/full-stack-cli --input /tmp/people.json --desc
NAME       AGE
------------------
charlie    42
alice      30
bob        25
dana       19
```

This is what we've been working toward for 8 sessions.
