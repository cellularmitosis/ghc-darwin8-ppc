# Experiment 005: Fixing final stage1 link — hello.hs end-to-end

Date: 2026-04-22 (continuing from 004).

## Status

Stage1 GHC cross-compiler fully built.  `_build/stage1/bin/powerpc-apple-darwin8-ghc` (134 MB) plus 33 libraries registered.  Got down to the final hello.hs link, which surfaced two more Tiger-specific issues.

## Link errors hit on hello.hs

```
Undefined symbols:
  "_hs_xchg64", referenced from:
     -u command line option
  "_pthread_set_name_np", referenced from:
      _initTicker in libHSrts-1.0.2.a(Itimer.o)
```

### Fix 1: `_hs_xchg64` (32-bit target gap)

`libraries/ghc-prim/cbits/atomic.c` guards `hs_xchg64` and `hs_cmpxchg64` with `#if WORD_SIZE_IN_BITS == 64`, but `rts/package.conf.in` and `rts/rts.cabal.in` emit `-Wl,-u,_hs_xchg64` unconditionally.  On 32-bit PPC this asks the linker to keep a symbol that's never compiled.

Fix: patch `rts/package.conf.in` + `rts/rts.cabal.in` to gate the xchg64 force-link behind `WORD_SIZE_IN_BITS == 64` / `flag(64bit)`.  Saved as `patches/0007-rts-gate-hs_xchg64-on-64bit.patch`.

### Fix 2: `pthread_set_name_np` (Tiger absent, but SDK header declares it)

The RTS code at `rts/posix/Itimer.c` / `rts/posix/itimer/Pthread.c` / `rts/posix/OSThreads.c` has this guard chain:

```c
#if defined(HAVE_PTHREAD_SET_NAME_NP)
    pthread_set_name_np(thread, "ghc_ticker");
#elif defined(HAVE_PTHREAD_SETNAME_NP)
    pthread_setname_np(thread, "ghc_ticker");
#elif defined(HAVE_PTHREAD_SETNAME_NP_DARWIN)
    pthread_setname_np("ghc_ticker");
#endif
```

The top-level autoconf probes all three against the 10.4u SDK's `<pthread.h>`.  That header *declares* `pthread_set_name_np` (it's part of the BSD extension set) so all three probes return YES.  But Tiger's actual libSystem only *exports* `pthread_setname_np` (Darwin flavor, single-arg) starting in 10.6, and the BSD-flavor `pthread_set_name_np` doesn't exist anywhere.  Result: undefined symbol at link.

`scripts/tiger-config.site` already sets:
```
ac_cv_func_pthread_setname_np=no
ac_cv_func_pthread_set_name_np=no
```
but those overrides only help when autoconf re-runs.  The `mk/config.h` generated during our initial `./configure` run still had all three set to 1, because `CONFIG_SITE` wasn't sourced (or the sub-configure for ghc-bignum's configure runs with its own env).

Fix: patch `mk/config.h` directly with `/* #undef HAVE_PTHREAD_SETNAME_NP */`, `/* #undef HAVE_PTHREAD_SETNAME_NP_DARWIN */`, `/* #undef HAVE_PTHREAD_SET_NAME_NP */`.  Hadrian's `generateGhcAutoconfH` reads `mk/config.h` and slides undefined entries through to `_build/stage*/lib/ghcautoconf.h`, so the derived copies inherit the fix.  Same treatment for `HAVE_EVENTFD` (Tiger has no eventfd).

### Fix 3: gmp.h findable for ghc-bignum configure

Touching `mk/config.h` invalidated many build targets, including `ghc-bignum`'s configure.  That configure is invoked with `CPPFLAGS=-I_build/stage1/lib` (no `/opt/homebrew/include`).  On arm64 uranium our system gmp is at `/opt/homebrew/include/gmp.h`; the cross-CC wrapper passes `-isysroot $SDK` which hides homebrew headers.  Workaround: drop a copy of `/opt/homebrew/include/gmp.h` at `_build/stage1/lib/gmp.h` so configure's `AC_CHECK_HEADER([gmp.h])` succeeds.  Link-test for `-lgmp` also passes because our fake-link wrapper always returns 0.

Longer-term we should enable `intree-gmp` in `hadrian/cfg/system.config` and let hadrian cross-build gmp-6.2.1 for PPC Darwin.  That's a bigger lift (needs autotools cross-configure inside hadrian).

## Other fixes already in flight

* `patches/0001-libffi-gate-go-closure-on-ppc-darwin.patch`
* `patches/0002-restore-32bit-machotypes-for-ppc.patch`
* `patches/0003-restore-loadarchive-ppc-darwin.patch`
* `patches/0004-macho-c-ppc-symbol-extras-and-reloc-include.patch`
* `patches/0005-posixsource-h-no-posix-c-source-on-darwin.patch`
* `patches/0006-quickcross-static-only.patch`
* `patches/0007-rts-gate-hs_xchg64-on-64bit.patch` ← new

## Outstanding

* Actual PPC `libgmp` on pmacg5 — `-lgmp` at final hello link should resolve through `/opt/gcc14/lib/libgmp.dylib` (tiger gcc14 bundle).  Not yet verified.
* `hadrian-46.log` run in progress — mk/config.h edit forced stage0 compiler full rebuild.  ETA ~30–45 min.
