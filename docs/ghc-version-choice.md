# Why GHC 9.2.8?

Context for someone whose last Haskell was Hugs98: GHC is the dominant
Haskell compiler today, released in roughly one major series per year.
Each major has a minor-release tail; `.x` releases are bug-fix only, no
new features.

## GHC series since 2019

| Series | First | Last `.x` | Notable changes |
|--------|-------|-----------|-----------------|
| 8.6    | 2018-09 | 8.6.5 (2019-04) | last series with PPC/Darwin support |
| 8.8    | 2019-08 | 8.8.4 (2020-07) | PPC/Darwin removed (commit 374e44704b) |
| 8.10   | 2020-03 | 8.10.7 (2021-08) | last broadly-deployed "legacy" |
| **9.0**    | 2021-02 | 9.0.2 (2022-01) | BlockArguments, linear types (beta) |
| **9.2**    | 2021-10 | **9.2.8 (2023-04)** | ghc-bignum, GHC2021 language option |
| 9.4    | 2022-08 | 9.4.8 (2023-11) | hadrian-only (Make removed), big NCG refactor |
| 9.6    | 2023-03 | 9.6.7 (2025-?) | JS backend (prototype), wasm, docs improvements |
| 9.8    | 2023-10 | 9.8.4 (2025-?) | more JS/wasm |
| 9.10   | 2024-05 | 9.10.1 | GHC2024 language, type-level `@` |
| 9.12   | 2024-12 | 9.12.1 | |

## Why specifically 9.2.8 for us

1. **It already works.**  We have a running cross-compile toolchain
   that produces ppc Mach-O binaries that run on real Tiger hardware.
   Changing compiler versions mid-stream would cost weeks.

2. **PPC removal was recent enough to undo.**  8.8 deleted PPC
   support, but many of the structural bits (MachO linker, reloc
   types, stg macros) still had vestiges in 9.2's source that we could
   re-enable with small patches (our `patches/0002`–`0004`).  By 9.4+,
   further refactoring (e.g. the Cmm backend reorg for the JS
   backend's introduction) has removed those vestiges; a fresh PPC
   port on 9.4+ would be a larger archaeology project.

3. **Stable, done.**  9.2.8 is the final release of the 9.2 line.  No
   new bugs get introduced by pulling minor updates.

4. **Wide library ecosystem.**  Most of Hackage supports 9.2.  Newer
   series (9.6+) sometimes lag on dependent libraries.

5. **Hadrian but still has Make scaffolding.**  9.4 dropped Make
   entirely; in 9.2 we could fall back to Make if Hadrian had been
   uncooperative (we ended up using Hadrian anyway).

6. **Unregisterised mode still supported.**  The "NO_REGS
   USE_MINIINTERPRETER" path that makes PPC builds tractable without a
   native code generator is healthy in 9.2; 9.6+ is actively trying to
   deprecate it (GHC developers have noted maintenance burden).
   Without unregisterised mode we'd need a working PPC NCG or LLVM-7
   bitcode emission path — neither is free.

## What we lose by not being on a newer series

- **JS / wasm backends** (9.6+): irrelevant — we're targeting native PPC.
- **Better type error messages** (ongoing): nice but not a blocker for
  a resurrection project.
- **`GHC2021` / `GHC2024` language sets**: we use the pre-2021 default
  (`Haskell2010`) in all our patches; our code doesn't need the new
  defaults.
- **Linear types, dependent types**: experimental in 9.2, more mature
  in 9.4+.  Not relevant to the compiler-bringup goal.
- **Speedups**: incremental — 9.4 specialized class method dispatch a
  bit, 9.6 improved simplifier, 9.8 improved stranger corners.
  Measured in percentage points, not orders of magnitude.

## When we might revisit

- If we want a feature that only ships in 9.6+.
- If 9.2's ecosystem drops off a cliff (unlikely for a few more years).
- If someone upstream cares enough to actually land the PPC port,
  then we follow them to whatever branch they want to merge to.
