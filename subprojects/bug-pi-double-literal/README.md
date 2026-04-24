# bug-pi-double-literal

Status: 🔜 next up.  `pi :: Double` on ppc-darwin8 returns
`8.619197891656e97` instead of `3.141592653589793`.

Caused by the 19-digit literal `pi = 3.141592653589793238` in
`libraries/base/GHC/Float.hs` hitting a 64→32-bit `StgWord` truncation
in the unregisterised codegen's `.hc` emission.  Other Double literals
with ≤17 digits come out correctly.

See [plan.md](plan.md) for fix options.
