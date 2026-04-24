# stage1-cross — post-mortem

Subproject completed 2026-04-23.

## What worked

- **Unregisterised codegen + clang -target powerpc-apple-darwin8.**  Once
  we got the CC wrapper right (probe vs compile-only vs
  compile-and-link vs pure-object-link dispatch), all the library
  sources compiled cleanly.  No need for a ppc NCG.
- **SSH-to-pmacg5 for final linking.**  The cross ld64 on uranium
  couldn't handle Tiger's crt1.o reloc layout; gcc14's native ld on
  pmacg5 handles it fine.  Rsync + ssh shim worked reliably.
- **Hadrian.**  Despite scary complexity, hadrian was easier than the
  legacy Make build once we figured out the quick-cross flavour.
- **`tiger-config.site`.**  ~50 `ac_cv_*` overrides; the autoconf
  cache-override approach was the cleanest way to tell sub-configures
  "Tiger lacks this, don't probe the host".

## What didn't

- **Prebuilt GHC 7.0.4 on Tiger** (our first attempt, Phase 1).  The
  binary existed, but libiconv ABI mismatch + `_malloc_initialize`
  null-deref made it unusable.  Abandoned in favour of cross-build.
- **cctools-port under C23** — clang 15+ rejects `enum bool`.  Fixed
  with `CFLAGS=-std=gnu99`.
- **`@response_file` expansion in CC wrapper.**  GHC passes long
  linker arg lists via `@rsp`; initial wrapper didn't know to expand
  those, so our flag detection broke.  Fixed with python3 shlex.
- **0-byte .o files from parallel builds** — race condition where two
  threads tried to write the same object.  Worked around with
  `find ... -size 0 -delete && retry`.

## Surprises

- **PPC Mach-O's 24-bit scattered reloc limit.**  `GHC.Hs.Instances.dyn_o`
  exceeded 16 MB in the section.  Worked around by setting
  `libraryWays = [vanilla]` in QuickCross — static-only build.
- **ld64-253.9 branch-range bug** on the 47 MB Cabal merged object —
  "bl branch out of range" even for `-r` (relocatable).  Worked around
  by routing `ld` itself via SSH shim to pmacg5.
- **`_hs_xchg64` force-link despite `WORD_SIZE_IN_BITS == 32`.**  The
  rts `-Wl,-u,_hs_xchg64` was emitted unconditionally; `atomic.c`
  defines `hs_xchg64` only when word size is 64.  Gated in patch 0007.

## Time spent

Roughly 14 working sessions over a week.  Most of the time was wait
time (SSH round-trips, Hadrian cold-builds) not debugging.  The actual
fixes — once diagnosed — were small.
