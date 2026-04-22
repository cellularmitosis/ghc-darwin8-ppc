# state.md — where are we right now

*Updated: 2026-04-22 very late night, after many hours of pushing
through Phase 3.*

## Current phase

**Phase 3 cross-build is iterating through real bitrot.** Status:

- Cross-toolchain assembled and working
- configure passes with `--target=powerpc-apple-darwin8 --enable-unregisterised`
- `make` didn't work (dep-file issues). **Dropped.**
- **Hadrian works.** Built 24 Stage0 artefacts cleanly.
- Stage1 RTS compile hit CC-wrapper issue. **Fixed.**
- Now failing at libffi — a specific fixable bug in bundled libffi-3.3-rc2
  (`ffi_go_closure` type used unconditionally in `ffi_darwin.c`).

**Next session picks up by writing `patches/0001-libffi-gate-go-closure.patch`.**

## What is known to work

### Cross-toolchain on uranium

All installed under `~/.local/`:
- Host GHC 9.2.8 at `~/.local/ghc-9.2.8/bin/ghc`
- Auto-mkdir GHC wrapper at `~/.local/ghc-boot-wrap/bin/ghc`
  (wraps host GHC to `mkdir -p` output dirs)
- Cross clang 7.1.1 at `~/.local/ghc-ppc-xtools/clang`
- Clang resource-dir at `~/.local/lib/clang/7.1.1/` (required for
  the `float.h` #include_next path)
- 10.4u SDK at `~/.local/ghc-ppc-xtools/MacOSX10.4u.sdk/`
- cctools-port ld64-253.9-ppc at `~/.local/cctools-ppc/install/bin/`
  with `powerpc-apple-darwin8-*` prefixes
- Happy 1.20.1.1 and Alex 3.2.7.4 at `~/.local/bin/`
- **Smart** cross-CC wrapper at `~/.local/ghc-ppc-xtools/bin-wrap/ppc-cc`
  (probe / compile-only / compile-link / pure-link detection)
- **Fake linker** at `~/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-fake`
  (writes a dummy Mach-O ppc header because ld64-253.9 can't
  handle the 10.4u SDK's crt1.o reloc format)

Scripts to regenerate: `scripts/cross-env.sh`,
`scripts/make-cross-cc-wrapper.sh`, `scripts/ppc-cc.sh`,
`scripts/ppc-ld-fake.sh`, `scripts/tiger-config.site`.

### GHC 9.2.8 configure with Tiger-correct cache

```bash
CONFIG_SITE=$HOME/claude/ghc-darwin8-ppc/scripts/tiger-config.site \
./configure \
    --target=powerpc-apple-darwin8 \
    --enable-unregisterised \
    GHC=$HOME/.local/ghc-boot-wrap/bin/ghc \
    CC="$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-cc"
```

`tiger-config.site` forces `ac_cv_func_clock_gettime=no`,
`ac_cv_func_pthread_condattr_setclock=no`, and other Leopard+ APIs
that autoconf otherwise incorrectly detects as present (because it
probes the host, not the target).

### Hadrian build — 24 stage0 artefacts built

```bash
source ~/claude/ghc-darwin8-ppc/scripts/cross-env.sh
export PATH=$HOME/.local/ghc-boot-wrap/bin:$HOME/.local/ghc-9.2.8/bin:$HOME/.local/bin:$HOME/.local/cctools-ppc/install/bin:$PATH
cd external/ghc-modern/ghc-9.2.8
./hadrian/build --flavour=quick-cross --docs=none -j8
```

Built (all with `powerpc-apple-darwin8-` prefix where applicable):
- Tools: unlit, hp2ps, genapply, compareSizes, deriveConstants,
  genprimopcode, hsc2hs
- Libraries: ghc-boot-th, transformers, binary, mtl, ghc-heap,
  template-haskell, hpc, ghc-boot, exceptions, ghci, text, parsec
- Plus large chunks of stage0 `compiler` (GHC as library) and
  `haddock` before hitting libffi

## What is currently blocking progress

`libffi-3.3-rc2`'s `src/powerpc/ffi_darwin.c` uses the type
`ffi_go_closure` without the `#if FFI_GO_CLOSURES` gate that
declares the type in `ffi.h`. Per-
[`experiments/004`](experiments/004-hadrian-wrapper-fix-libffi-bitrot.md):

```
../src/powerpc/ffi_darwin.c:1114:22: error:
    unknown type name 'ffi_go_closure'
```

This is a pre-existing libffi 3.3-rc2 bug, not GHC bitrot, not
Tiger-specific. Fixable with a small patch. See experiment 004 for
three options.

## Last-touched state

- Git: `main` branch, **9 commits**, clean.
- Latest commit: 711ea63 (Phase 3: Hadrian cross-build succeeds
  for Stage0, hits Stage1 RTS bitrot).
- `external/ghc-modern/ghc-9.2.8/_build/stage0/` exists with 24
  built artefacts. `_build/stage1/rts/` partially configured.

## Immediate next steps (for next session)

**Priority 1: write `patches/0001-libffi-gate-go-closure.patch`.**

Extract libffi-tarballs, patch `src/powerpc/ffi_darwin.c` to gate
`ffi_prep_go_closure` and `ffi_go_closure_helper_DARWIN` in `#if
FFI_GO_CLOSURES`. Repack the tarball (or skip the tarball and let
Hadrian use the pre-extracted source).

Commands:

```bash
source ~/claude/ghc-darwin8-ppc/scripts/cross-env.sh
export PATH=$HOME/.local/ghc-boot-wrap/bin:$HOME/.local/ghc-9.2.8/bin:$HOME/.local/bin:$HOME/.local/cctools-ppc/install/bin:$PATH
cd ~/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8

# After the patch:
./hadrian/build --flavour=quick-cross --docs=none -j8
```

**Priority 2: deal with whatever breaks next.**

Likely candidates after libffi:
- RTS C files using Tiger-incompatible APIs. Expand `tiger-config.site`.
- The first Haskell compile for PPC target — this is where the
  removal-commit bitrot surfaces.

**Priority 3: real linking story.**

Eventually we need to actually link a PPC executable. ld64-253.9-ppc
on uranium can't handle the 10.4u SDK crt1.o. Options:
- Ship `.o` files to Tiger (pmacg5 or imacg52), link there with
  ld64-97.17-tigerbrew. Matches the LLVM-7 project's pattern.
- Patch ld64-253.9 to handle the older reloc format.
- Strip the problematic reloc from crt1.o (hack).

Don't block on this until Hadrian asks for real linking — which
will be at the end of the stage1 build, when linking the
cross-compiled `ghc-stage1` binary (which is arm64, not ppc, so
actually it WOULD use the arm64 linker). Only at stage2 would we
hit real PPC linking.

## Key open questions

1. **At what point does Hadrian need to link a real PPC executable?**
   Stage1 GHC is built to run on the BUILD host (arm64 macOS 15),
   so it's arm64-linked. Stage2 (GHC itself running on Tiger) is
   when real PPC linking happens. We'd have plenty of warning
   before hitting that.
2. **Is `--enable-unregisterised` sufficient for the NCG bitrot?**
   Trommler's recipe: yes, unregisterised dodges the NCG entirely;
   once we have a working unregisterised compiler, that's our
   bootstrap for reviving the NCG. Still accurate.
3. **Does the removal-commit content ever get touched in the
   unregisterised path?** Some of it (the `MachRegs.h` STG-register
   map) might not, because unregisterised doesn't use the STG
   register set. Some of it (RTS `StgCRun.c`, `Adjustor.c`) still
   does. Will find out when we hit it.

## Files to read first for anyone picking this up

1. [`plan.md`](plan.md) — the big picture
2. [`state.md`](state.md) — this file (where we are)
3. [`experiments/004-hadrian-wrapper-fix-libffi-bitrot.md`](experiments/004-hadrian-wrapper-fix-libffi-bitrot.md) — most recent
4. [`experiments/003-hadrian-cross-build.md`](experiments/003-hadrian-cross-build.md)
5. [`experiments/002-cross-configure-and-first-make.md`](experiments/002-cross-configure-and-first-make.md)
6. [`experiments/001-ghc-704-pkg-on-tiger.md`](experiments/001-ghc-704-pkg-on-tiger.md)
7. [`notes/cross-toolchain-strategy.md`](notes/cross-toolchain-strategy.md)
8. [`notes/codebase-tour.md`](notes/codebase-tour.md) / [`notes/file-mapping-86-vs-modern.md`](notes/file-mapping-86-vs-modern.md) — what to port
