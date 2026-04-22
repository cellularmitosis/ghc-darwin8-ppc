# Tiger libiconv ABI mismatch

The single biggest blocker to running prebuilt PPC/Darwin GHC
binaries on Tiger is a libiconv ABI version mismatch. Documenting
in one place so we don't rediscover it.

## Symptom

```
dyld: Library not loaded: /usr/lib/libiconv.2.dylib
  Referenced from: .../ghc-pwd
  Reason: Incompatible library version: ghc-pwd requires version 7.0.0
          or later, but libiconv.2.dylib provides version 5.0.0
```

(Quoted from
[barracuda156's MacPorts ticket #64698](https://trac.macports.org/ticket/64698),
2022; reproduced from the GHC 7.0.1 prebuilt binary on Tiger.)

## Root cause

| OS | `/usr/lib/libiconv.2.dylib` compat version |
|---|---|
| Tiger 10.4 | **5.0.0** |
| Leopard 10.5 | **7.0.0** |
| Snow Leopard 10.6 | 7.0.0+ |

Apple bumped libiconv between Tiger and Leopard. The compat-version
bump is dyld's signal that ABI changed and old clients can't safely
load the new lib (and, conversely, new clients can't run on a host
that has only the old lib).

The GHC prebuilt binaries we care about — 7.0.1 from maeder, 7.0.4
from krabby — were both **built on Leopard or later**, so they
embed `compat 7.0.0` in their `LC_LOAD_DYLIB` for libiconv. Tiger
won't load them.

## Workaround on Tiger

Install a modern libiconv at `/opt/libiconv-1.16/` (already done on
the fleet via `tiger.sh` — verified present on `imacg52` and
`pmacg5`). Modern libiconv ships its own `.dylib` with the newer
ABI. Then make the GHC binary use it instead of the system one.

### Option A: `install_name_tool -change`

```bash
sudo install_name_tool -change \
    /usr/lib/libiconv.2.dylib \
    /opt/libiconv-1.16/lib/libiconv.2.dylib \
    "$BIN"
```

Per binary that links against libiconv. `install_name_tool` is
shipped on Tiger (it's part of cctools / Xcode); no need to bring
a newer one. It rewrites the `LC_LOAD_DYLIB` entry in the Mach-O
header in place. Reversible: re-run with the inverse mapping.

**Caveat:** `install_name_tool -change` requires the new path to be
no longer than the old one **unless** the binary was linked with
`-headerpad_max_install_names`. We don't control how krabby/maeder
linked their binaries; if the rewrite fails with "larger updated
load commands do not fit" we have to go to Option B.

### Option B: `DYLD_FALLBACK_LIBRARY_PATH`

Wrap the GHC entry-point script:

```sh
#!/bin/sh
DYLD_FALLBACK_LIBRARY_PATH=/opt/libiconv-1.16/lib:${DYLD_FALLBACK_LIBRARY_PATH:-/usr/local/lib:/lib:/usr/lib}
export DYLD_FALLBACK_LIBRARY_PATH
exec /Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/usr/bin/ghc.real "$@"
```

Pros: doesn't modify the binary. Easy to undo.
Cons: every callable wrapper needs the env-var injection; child
processes that re-exec the unwrapped binary lose it.

### Option C: shadow `/usr/lib/libiconv.2.dylib`

Don't. We are not in the business of altering the OS-shipped
libraries.

### Option D: build a 7.0.x binary from source against Tiger's libiconv

Cleanest but most work. Requires having an even-older GHC running
on Tiger to bootstrap from — and the only options are 6.10.x or
older, which themselves have the same problem (or were never built
for Tiger). We may end up here eventually, but try (A) first.

## Detection / verification

To find which binaries are affected after extracting the .pkg:

```bash
find /tmp/ghc-704-payload -type f -perm -111 -exec sh -c \
    'file "$1" | grep -q Mach-O && echo "$1"' _ {} \; | \
    while read f; do
        if otool -L "$f" 2>/dev/null | grep -q libiconv.2; then
            echo "AFFECTED: $f"
            otool -L "$f" | grep libiconv
        fi
    done
```

To verify the fix on Tiger after install_name_tool surgery:

```bash
ssh pmacg5 'otool -L /Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/usr/lib/ghc-7.0.4/ghc | grep libiconv'
# should show /opt/libiconv-1.16/lib/libiconv.2.dylib (compat 7.0.0)
```

To smoke-test:

```bash
ssh pmacg5 '/usr/local/bin/ghc-7.0.4 --version'
ssh pmacg5 'echo "main = putStrLn \"ok\"" > /tmp/t.hs && /usr/local/bin/ghc-7.0.4 /tmp/t.hs -o /tmp/t && /tmp/t'
```

## Same trap, different forms — appears elsewhere

This is one instance of the broader Tiger pattern documented in the
`imacg3-dev` skill: **prebuilt binaries from Leopard or later
generally won't run on Tiger** because of OS-shipped library
ABI bumps that happened between 10.4 and 10.5. Other manifestations
we may hit during this project:

- `getcontext`/`setcontext`/`makecontext` are Leopard-only
  (introduced in 10.5). Anything that links against them won't
  even load on Tiger; `_getcontext` will be undefined at runtime.
- `clock_gettime` is even later (Sierra 10.12). GHC's RTS uses it
  in some places; Tiger needs `mach_absolute_time` + `gettimeofday`
  fallback.
- `dispatch_*` (Grand Central Dispatch) is 10.6+. Probably not
  used by GHC, but other things in our build stack might.
- `<Availability.h>` is 10.5+; only `<AvailabilityMacros.h>` exists
  on Tiger.
- `pthread_setname_np` is 10.6+. GHC's RTS may set thread names.

When porting, expect to ifdef each one out and provide a Tiger
fallback. The skill documents the pattern; openssl's `no-async`
build flag is the canonical example.
