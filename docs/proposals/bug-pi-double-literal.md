# bug-pi-double-literal — plan

## Bug

`pi :: Double` returns `8.619197891656e97` on ppc-darwin8, instead of
`3.141592653589793`.  See the full writeup in
[tests/RESULTS.md](../../tests/RESULTS.md#bug-1).

## Hypothesis

`pi` in `Floating Double` instance is defined as
`pi = 3.141592653589793238` — 19 significant digits, one more than
Double can represent exactly.

In unregisterised codegen the constant is emitted to `.hc` C source
as `(StgWord)0x400921FB54442D18ULL`.  `StgWord` on PPC32 is 32-bit.
The cast truncates the 64-bit IEEE bit pattern to its low 32 bits.
Clang issues `-Wconstant-conversion` for this (saw the warning at
build time).  At runtime `pi` resolves to the truncated bit pattern
reinterpreted as Double → garbage.

Other Double literals (`1.5`, `2.5`, `3.14`, even
`3.14159265358979`) come out correctly because their `Rational` →
`Double` goes through a different StgToCmm emission path.

## Fix options

### Option A: GHC codegen fix (correct, larger scope)

Find where Double constants hit the 32-bit `StgWord` cast.  Probably
in `compiler/GHC/StgToCmm/Lit.hs` or `compiler/GHC/CmmToC.hs` for the
unregisterised path.  Emit 64-bit constants as two 32-bit big-endian
stores on PPC32.

Benefit: fixes all Double constants, not just `pi`.
Cost: needs someone who can read GHC internals confidently; might also
need matching fixes for other 64-bit literals (Word64, Int64) in
unregisterised mode.

### Option B: base workaround (quick, ugly)

Edit `libraries/base/GHC/Float.hs` to use ≤17 digits:
`pi = 3.141592653589793` (works in our test).  Ditto for any other
over-precision constant if we find them.

Benefit: unblocks users today.
Cost: diverges base from upstream; doesn't fix the underlying codegen
issue so similar constants in other libraries will keep breaking.

## Next steps

1. Write a minimal reproducer in the GHC source tree — a single
   `Foo.hs` with `foo :: Double; foo = 3.141592653589793238` and see
   the emitted `.hc`.
2. Inspect the `.hc` to confirm the `(StgWord)` cast and its
   truncation.
3. Grep `compiler/GHC/StgToCmm/` for how Double lit constants are
   currently emitted.
4. Prototype option A.  If it looks tractable in a day, do it; else
   fall back to option B.
