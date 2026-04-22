# 004 — CC wrapper fixed; Hadrian now fails at libffi

## Hypothesis

The Stage1 RTS compile failure in
[`003`](003-hadrian-cross-build.md) was caused by our `ppc-cc`
wrapper's over-eager link-mode detection. Fixing the detection
will unstick the RTS.

## Method

Rewrote `ppc-cc` with explicit rule classification:

- **Probe mode** (`--version`, `-v`, `--print-*`, etc.): pass
  through to real clang (GHC needs to learn the CC's real info).
- **Compile-only** (`-c`, `-E`, `-S`, `-M`, etc.): pass through.
- **Compile-and-link** (source file input, no `-c`): fake the
  linker (because ld64-253.9 can't link against the 10.4u SDK's
  crt1.o).
- **Pure link** (`.o`/`.a` input, no source): fake the linker.
- **Default** (no input, no probe, no link): pass through.

New wrapper committed as [`scripts/ppc-cc.sh`](../../scripts/ppc-cc.sh).

## Result

**Huge progress.** Hadrian now gets past the Stage1 RTS setup.
Instead of 98 cast-warning errors, it ran cleanly through
configure and proceeded to... libffi.

Libffi's `src/powerpc/ffi_darwin.c` fails with:

```
../src/powerpc/ffi_darwin.c:1114:22: error: unknown type name 'ffi_go_closure'
ffi_prep_go_closure (ffi_go_closure* closure,
                     ^
../src/powerpc/ffi_darwin.c:1172:31: error: unknown type name 'ffi_go_closure'
ffi_go_closure_helper_DARWIN (ffi_go_closure*, void *,
```

Analysis:

- `ffi_go_closure` is declared in `include/ffi.h.in` only under
  `#if FFI_GO_CLOSURES`.
- `ffi_darwin.c`'s implementation of
  `ffi_prep_go_closure` and `ffi_go_closure_helper_DARWIN` uses
  the type *unconditionally* — no `#if FFI_GO_CLOSURES` gate in
  the `.c` file.
- For PPC-Darwin, `FFI_GO_CLOSURES` is presumably not defined
  by configure, so `ffi.h` doesn't declare the type, but the
  `.c` file tries to define functions using it.

This is a **pre-existing bug in libffi 3.3-rc2** when
`FFI_GO_CLOSURES=0` for PPC-Darwin. The libffi-tarballs GHC 9.2.8
ships (`libffi-3.3-rc2+git20191103+88a7647.tar.gz`) has this bug.

Full build log: [`docs/ref/hadrian-3-after-wrapper-fix.txt`](../ref/hadrian-3-after-wrapper-fix.txt)

## Fix (for next session)

Options:

1. **Patch libffi-tarballs' ffi_darwin.c** to gate the
   `ffi_prep_go_closure` and `ffi_go_closure_helper_DARWIN`
   definitions with `#if FFI_GO_CLOSURES`. Small, local, pragmatic.
2. **Upgrade libffi** to a newer version where this has been
   fixed. libffi 3.4+ has better PPC-Darwin coverage, but changing
   the libffi version means re-generating the tarball GHC 9.2.8
   expects, which might break other things.
3. **Disable libffi** if possible. GHC uses libffi for FFI
   callbacks via `rts/Adjustor.c`. Without it we lose FFI callbacks
   but still get forward-FFI (Haskell → C).  Look for
   `--disable-libffi` or `BUILD_LIBFFI=NO` hadrian flag.

**Recommendation:** Option 1. Write `patches/0001-libffi-gate-go-closure-on-darwin-ppc.patch`
that wraps the offending function definitions in `#if FFI_GO_CLOSURES`.

## Sketch of the patch

```c
// At top of libffi-tarballs/libffi-3.3-rc2/src/powerpc/ffi_darwin.c,
// after existing #includes, add:
#if !FFI_GO_CLOSURES
#define ffi_go_closure void /* unreachable, but lets the file compile */
#endif
```

This is a hack; the proper fix is to gate the function definitions.
But the hack might unblock us faster. Try both.

## Higher-level point

**We are now in real bitrot territory.** Each issue we hit is a
discrete, fixable problem that belongs in `patches/NNNN-*.patch`.
The cross-toolchain and configure are solid. From here on, we
just iterate: hit error → write patch → apply → retry.

## Next steps for the next session

1. Write `patches/0001-libffi-gate-go-closure-on-darwin-ppc.patch`.
2. Apply it to the libffi-tarballs source tree (or patch the
   extracted `.tar.gz`).
3. Re-run Hadrian. See what the next error is.
4. Repeat.

## Artefacts

- Updated `scripts/ppc-cc.sh` — the smarter wrapper.
- `docs/ref/hadrian-3-after-wrapper-fix.txt` — 182-line log ending
  at the libffi error.
