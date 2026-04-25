# Session 9 findings

## 1. clang-7's integrated assembler rejects Apple-PPC bare-`0` displacement form

PPC instructions like `stw r3, 12(0)` (store word r3 at displacement
12 from register 0) use `0` as a *literal* indicator that there is
no base register and the displacement is the absolute address.
Apple's original `as` accepted this `0` form.

Modern clang's PPC backend / integrated assembler insists on
`stw r3, 12(r0)` — even though `r0` in displacement form means the
same thing (PPC ISA: displacement-form with rA=0 means "0", not
"contents of r0").

When GHC compiles RTS C files with `-DPROFILING -O2` through clang-7,
clang's own optimizer emits the bare-`0` form, then clang's own
assembler rejects it.  This appears to be a clang version-specific
inconsistency where the codegen and the assembler disagree.

Repro point: any RTS profiling build via `libraryWays = [..., profiling]`
in QuickCross.

## 2. Possible workarounds (not attempted)

- `-fno-integrated-as` + cctools-port `as`: forces a different
  assembler.  cctools-port's `as` was forked from Apple-PPC `as`;
  it likely accepts the bare `0`.
- `-Wa,-mppc -Wa,-mApple-PPC` or similar assembler flags.
- Post-processing `.s` with `sed -E 's/\((0)\)/\(r0\)/g'`.
- Patching specific RTS files that produce this codegen.

## 3. Profiling without -prof is partially possible

Users can still get RTS allocation stats via `+RTS -s` (no profiling
libs needed).  Timing via `/usr/bin/time` works.  Heap profiling
via `-hp` / `hp2ps` needs `-prof` — currently broken.

## 4. The hadrian rebuild loop is expensive

Touching `hadrian/src/Settings/Flavours/QuickCross.hs` triggers a
full hadrian re-bootstrap (the ghc that drives our cross-build is
hadrian-as-Haskell-program; changing its source means rebuilding
the hadrian binary).  Each iteration is several minutes of overhead
even before the actual cross-build starts.

For future profiling work: prototype the workaround in a stand-alone
.s file first (just feed `stw r3, 12(0)` to ppc-cc -c and watch it
fail), validate the workaround on that, *then* wire it into the
flavour.
