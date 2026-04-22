# 003 — Hadrian cross-build succeeds through Stage0, fails at Stage1 RTS

## Hypothesis

Switching from `make` to Hadrian (GHC's Shake-based build system,
also shipped with 9.2.8) will get past the make-system dep-file
generation issue documented in
[`002`](002-cross-configure-and-first-make.md) and let us reach
real cross-compile bitrot.

## Method

1. Keep the existing configure state
   ([`002`](002-cross-configure-and-first-make.md)) but delete
   the partial `make` build artefacts.
2. Add Tiger-specific configure cache at
   [`scripts/tiger-config.site`](../../scripts/tiger-config.site):
   force `ac_cv_func_clock_gettime=no`,
   `ac_cv_func_pthread_condattr_setclock=no`, plus other 10.5+
   APIs that autoconf probed on the HOST and got wrong answers
   for. Re-run configure with
   `CONFIG_SITE=tiger-config.site ./configure`.
3. `./hadrian/build --flavour=quick-cross --docs=none -j8`.

## Result

**Big win: Stage0 mostly succeeds, then we hit Stage1 RTS.**

### What Hadrian built successfully

Stage0 tools (build tools, run on the host to drive the compile):

- `_build/stage0/bin/powerpc-apple-darwin8-unlit`
- `_build/stage0/bin/powerpc-apple-darwin8-hp2ps`
- `_build/stage0/bin/powerpc-apple-darwin8-genapply`
- `_build/stage0/bin/powerpc-apple-darwin8-compareSizes`
- `_build/stage0/bin/powerpc-apple-darwin8-deriveConstants`
- `_build/stage0/bin/powerpc-apple-darwin8-genprimopcode`
- `_build/stage0/bin/powerpc-apple-darwin8-hsc2hs`

Stage0 libraries (compiled by host GHC, these are the boot
libraries):

- `ghc-boot-th`, `transformers`, `binary`, `mtl`, `ghc-heap`,
  `template-haskell`, `hpc`, `ghc-boot`, `exceptions`, `ghci`,
  `text`, `parsec`

Plus it started compiling the stage0 `compiler` library (GHC
itself as a Haskell library) and `haddock`, reaching partway
through before hitting the RTS issue.

Raw log: [`docs/ref/hadrian-2-full-output.txt`](../ref/hadrian-2-full-output.txt)
(2838 lines).

### Where it failed: Stage1 RTS compile

Hadrian tries to configure stage1 rts (`cabal-configure for
_build/stage1/rts/setup-config`), which drives a compile of some
RTS code using the CROSS CC. That invokes our `ppc-cc` wrapper
against real RTS source, and clang emits 98+ errors from
`includes/rts/storage/ClosureMacros.h`, `Closures.h`,
`StablePtr.h`, `SMP.h`.

Every error is actually a warning upgraded to error:

```
includes/rts/storage/ClosureMacros.h:204:12: error:
    warning: cast to smaller integer type 'StgWord' (aka 'unsigned int')
    from 'const StgClosure *' (aka 'const struct StgClosure_ *')
    [-Wpointer-to-int-cast]
    204 |     return (StgWord)p & TAG_MASK;
```

Analysis:

- `StgWord = unsigned int` = 32 bits
- `StgClosure *` on `powerpc-apple-darwin8` should be 32 bits (PPC32)
- Cast of 32-bit pointer to 32-bit int should NOT be a
  "smaller-integer" warning

Clang is treating the pointer as 64-bit. Most likely cause:
clang's `-target powerpc-apple-darwin8` flag isn't being applied
to these particular compiles. **Hadrian may be invoking our
wrapper without `-c`**, which makes the wrapper detect
link-mode and send the args to the fake linker for a `.s` file
that isn't a link job at all. Log shows:

```
clang-7: error: no such file or directory: '/var/folders/.../ghc_1.s'
clang-7: error: no input files
`ppc-cc' failed in phase `Assembler'. (Exit code: 1)
```

The `ghc_1.s` file is a temporary assembly file produced by GHC
driver; our wrapper treats the invocation as a link, which drops
the `.s` file from the command line.

So there are likely two distinct issues:

1. **Our CC wrapper's link-mode detection is over-eager.** It
   triggers for assembler phase (`-o foo` with `.s` input) and
   messes up arg passing. Need a smarter heuristic — maybe detect
   `-c` / `-S` / `-E` / presence of `.o`/`.a`/`.so`/`.dylib` in the
   arg list.
2. **Clang-as-assembler target mismatch.** When clang is invoked
   to assemble, it may not get the target flag. Even if we fix the
   wrapper, we need `-target powerpc-apple-darwin8` in the actual
   command.

Plus the underlying **pointer-to-int-cast warning** which, if real
(i.e. clang treats the pointer as host-width), breaks the whole
RTS. That needs to be understood fully before writing a patch.

### Proof we hit real bitrot

The configure cache fix (clock_gettime=no) got us PAST the
`clockid_t` error in `OSThreads.h`. So the tiger-config.site
approach is sound — we just need to enumerate more Tiger-unsafe
APIs as we discover them.

## Conclusion

**Hadrian gets us dramatically further than make.** We're now
inside the real cross-compile with real clang invocations against
real RTS source. 24 stage0 artifacts built cleanly. The remaining
work is:

### Next session priority list

1. **Fix the `ppc-cc` wrapper's link-mode detection.** Too eager.
   Look at the exact invocation pattern for the assembler phase
   and only route to fake-ld for actual link invocations. Likely
   heuristic: link if the args include a `.o` file OR contain
   `-dylib`, `-shared`, `-bundle`, etc. Don't infer from the
   absence of `-c`.
2. **Verify `-target powerpc-apple-darwin8` is being applied.**
   Run a failing compile manually and check the clang command
   line. If the target flag is missing, figure out why Hadrian
   is dropping it (or why our wrapper isn't adding it in that
   mode).
3. **Classify the 98 RTS errors.** If they're all pointer-to-int
   warnings and the pointer IS actually being treated as 64-bit
   by clang, the target-flag fix will solve them. If they remain
   after the target fix, they're real RTS bugs and need patches
   (probably `-Wno-pointer-to-int-cast` in the flavour file).

### Expand tiger-config.site

Add every other Leopard-only or Snow-Leopard-only function GHC
might probe for:
- `posix_spawn` (Leopard+)
- `fdatasync` (Linux-only, not Darwin)
- `eventfd` (Linux-only)
- `timerfd_create` (Linux-only)
- `nanosleep` (available)
- `strnlen` (in POSIX.1-2008, post-Tiger)

### Artefacts produced

- `_build/stage0/` — 24 stage0 tools and libraries. Kept.
- `docs/ref/hadrian-2-full-output.txt` — full build log. Committed.
- `scripts/tiger-config.site` — configure cache with known Tiger
  unavailabilities. Committed.
