# ghci-macho-loader — plan

## Goal

Make GHCi and TemplateHaskell splices work on ppc-darwin8.  Both
depend on GHC's runtime object loader, which for Mach-O lives in
`rts/linker/MachO.c`.

## Background

GHC's runtime has two relocation dispatch paths:
- `relocateSectionAarch64` — for aarch64 Darwin, fully implemented.
- `relocateSection` — x86_64 only.  For all other arches (prior to
  2018 this included PPC), there was separate per-arch code.

The PPC-specific code in `MachO.c` was deleted by commit 374e44704b
(Dec 2018) along with the rest of PPC support.  Our current stub in
experiment 006 just calls `errorBelch` and returns 0 — i.e. it fails
cleanly at runtime if GHCi or TH try to load a compiled object.

## Restoring the code

The easiest source is GHC git history at commit 374e44704b^.  Expect
roughly these functions:
- `relocateSection_PPC` (main dispatch)
- `makeJumpIsland` (PPC branches ±32 MB; insert stub for longer jumps)
- Handling for each `PPC_RELOC_*` type:
  - `PPC_RELOC_VANILLA` — direct address fixup
  - `PPC_RELOC_BR24` — bl target (±32 MB)
  - `PPC_RELOC_BR14` — short conditional branch
  - `PPC_RELOC_HI16`, `LO16`, `HA16` — upper/lower/adjusted half of
    a 32-bit address, via lis/ori/addis sequences
  - `PPC_RELOC_PAIR` — carries the counterpart for HI16/HA16
  - `PPC_RELOC_SECTDIFF`, `LOCAL_SECTDIFF` — inter-section differences
  - `PPC_RELOC_PB_LA_PTR` — lazy-bound address pointer
  - `PPC_RELOC_LO14` — 14-bit displacement (used with some ld insns)

Adapting to 9.2.8's runtime linker API:
- The `ObjectCode` / `Section` structs may have evolved.
- Some helpers (`makeSymbolExtra`, `lookupSymbol`, `errorBelch`) are
  standard across versions.

## Testing strategy

1. Build ghci — needs working TH-less GHCi which itself is part of a
   working stage2 ghc.
2. Or: write a small C test driver in `rts/linker/` that calls
   `loadArchive` on a known-good .a and iterates the object loads.
   This lets us validate the loader independent of ghci working.

## Dependencies

- `stage2-native` ideally working, so we can test with ghci.
  Otherwise we're limited to unit-testing the loader with a C driver.
- `ocAllocateExtras_MachO` for PPC — partially done in patch 0004,
  but the runtime-load path isn't wired up yet.

## Estimated effort

Best case: 1–2 days if the pre-2018 code drops in with minor adaptation.
Worst case: a week if the ObjectCode layout has drifted substantially.
