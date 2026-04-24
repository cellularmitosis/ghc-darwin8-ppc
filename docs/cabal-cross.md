# Cabal cross-compile recipe

How to use our PPC/Darwin8 cross-compiler with `cabal` (cabal-install)
to build Hackage packages for Tiger.

## Quick start

```
source scripts/cross-env.sh
STAGE1=$PWD/external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc

# In your project dir, create a cabal.project that knows about our
# vendored splitmix (only if you need random/splitmix directly or
# transitively).
cat > cabal.project <<EOF
packages:
  .
  $PWD/vendor/splitmix/
EOF

cabal --store-dir=./.cabal-store \
      build \
      --with-compiler=$STAGE1 \
      --builddir=./dist
```

Cabal will:

1. Resolve your deps against Hackage (`--offline` to skip network).
2. Build each dep with the cross-ghc.
3. Link your executable for `ppc-osx` (PPC Mach-O).
4. Place the binary at `dist/build/ppc-osx/ghc-9.2.8/<pkg>-<ver>/x/<exe>/build/<exe>/<exe>`.

## scp + run

```
BIN=$(find dist/build -name myexe -type f -perm -u+x | head -1)
scp -q "$BIN" pmacg5:/tmp/
ssh -q pmacg5 /tmp/myexe
```

## Hackage packages known to work

All verified end-to-end via `cabal build --with-compiler=<cross-ghc>`
+ scp to pmacg5 + run, 2026-04-24 session 6:

| Package | Deps pulled in | Notes |
|---------|----------------|-------|
| `random-1.3.1` | `splitmix-0.1.3.2`, `data-array-byte-0.1.0.2` | Requires vendored splitmix. |
| `splitmix-0.1.3.2` | — | **Use our vendored copy** (`vendor/splitmix/`). Upstream depends on `Security/SecRandom.h` which doesn't exist on Tiger. |
| `async-2.2.6` | `hashable`, `unordered-containers`, `primitive` | Pure, no patch. |
| `vector-0.13.2.0` | `primitive`, `vector-stream` | Pure. |
| `aeson-2.2.4.1` | ~20 pkgs incl `scientific`, `text-iso8601` | Works for Generics-derived ToJSON/FromJSON.  TH derivation via `deriveJSON` does NOT work (see below). |
| `optparse-applicative-0.19.0.0` | `prettyprinter`, `ansi-terminal` | Pure.  CLI parsing + help text fully working on Tiger. |

## Packages with known issues

### Template Haskell — clean error, workaround exists

Any package that uses TH splices at compile time fails with:
```
powerpc-apple-darwin8-ghc: Couldn't find a target code interpreter.
Try with -fexternal-interpreter
```

Cross-compiling TH needs GHCi-in-reverse: the splice runs on the
HOST, the result is inserted into the TARGET binary.  That requires
a working GHCi host-side, which in turn requires our runtime Mach-O
loader ([roadmap C](roadmap.md)).  Deferred.

**Workaround:** use Generics + `instance ToJSON Person` instead of
`$(deriveJSON defaultOptions ''Person)`.  Verified to work with
aeson-2.2.4.1.

### `network-3.2.8.0` — needs Tiger SDK patches

Fails at hsc2hs preprocessing of `Cbits.hsc` because network
references `SOCK_CLOEXEC` unconditionally, but the 10.4u SDK's
`<sys/socket.h>` doesn't define it (added 10.7).

Fixable by vendoring network with a `#ifdef SOCK_CLOEXEC` guard, or
using an older network version (≤ 3.0) that predates the reference.
Deferred.

### Anything depending on 10.5+ macOS frameworks

`Security`, `CoreFoundation`, `SystemConfiguration`, `DispatchKit` —
not in Tiger's SDK.  Workaround: vendor the offending package and
replace the framework-specific code with `/dev/urandom`, sysctl,
plain POSIX, etc., following the splitmix pattern.

### TLS / OpenSSL

Haven't tried but expect trouble: Tiger predates the current
openssl/libcrypto APIs.  For HTTP, start with unencrypted HTTP and
add TLS as a separate project.

## Why vendor splitmix?

`splitmix`'s `cbits-apple/init.c` includes `Security/SecRandom.h` to
seed the RNG.  Tiger's 10.4u SDK has no Security framework.

Our `vendor/splitmix/` is a copy of `splitmix-0.1.3.2` with:

- `cbits-apple/init.c` rewritten to read from `/dev/urandom` (which
  Tiger has).
- `splitmix.cabal`'s `frameworks: Security` stripped from the apple
  branch.

Pointed to via `packages:` in your `cabal.project`.

## Common pitfalls

### "cannot satisfy -package X"

Cabal's solver doesn't know about packages in our cross-ghc's global
DB unless you use `--with-compiler`.  Always pass `--with-compiler`
explicitly — don't rely on PATH.

### "fatal error: 'Security/SecRandom.h' file not found"

See splitmix note above.  Other packages with similar issues: anything
importing `Foundation.framework`, `CoreServices.framework`.

### "library not found for -lmingwex"

You're hitting an old copy of `rts-1.0.2.conf`.  Upgrade to
ghc-9.2.8-stage1-cross-to-ppc-darwin8 ≥ v0.2.0 where
`rts/rts.cabal` has `flag mingwex` default `False`.

### Template Haskell splices hang / error

TH requires the GHCi runtime linker on the *host* GHC, NOT the cross
ghc.  Until our GHCi is restored (roadmap C), stick with Generics
for derivation — it avoids TH entirely.

## Putting installed libs in the cross-ghc package DB

Cabal-built libs land in `.cabal-store/ghc-9.2.8/` by default.  They
are NOT auto-registered in our cross-ghc's global package DB.  Each
`cabal build` invocation tells ghc about them via `-package-db`
flags in the build plan.

If you want them permanently available (for `ghc -package random
foo.hs` without cabal), you'd need to:

```
powerpc-apple-darwin8-ghc-pkg \
  --global-package-db=$PWD/external/ghc-modern/ghc-9.2.8/_build/stage1/lib/package.conf.d \
  register .cabal-store/ghc-9.2.8/random-1.3.1-<hash>/registration.conf
```

— but the paths in that registration are relative to the store, so
you'd need to rewrite them.  Easier to stick with `cabal build`
per-project.
