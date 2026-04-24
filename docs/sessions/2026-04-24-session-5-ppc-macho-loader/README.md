# Session 5 — PPC Mach-O runtime loader (roadmap C, scoping)

**Date:** 2026-04-24.
**Starting state:** Battery 34 tests / 30 PASS.  Zero real bugs in
the static-compile path.  GHCi + TemplateHaskell currently unavailable
because our `rts/linker/MachO.c` stubs out `relocateSection` for PPC
with an error-belch.
**Goal:** scope the work, study the existing stub, outline the
reloc-by-reloc restoration plan so a follow-up session can
implement.  Not aiming to finish the loader this session.
**Ending state:** plan + findings captured.  Implementation deferred.

## Why not just dive in?

Restoring the pre-2018 PPC Mach-O runtime loader is substantial:
- Multiple reloc types (`PPC_RELOC_VANILLA`, `BR14`, `BR24`, `HI16`,
  `LO16`, `HA16`, `PAIR`, `SECTDIFF`, `LOCAL_SECTDIFF`, `PB_LA_PTR`, `LO14`).
- Branch-island (jump stub) insertion for out-of-range `bl`s.
- Interaction with our already-landed `ocAllocateExtras_MachO` (patch 0004).
- Testing requires either a working stage2 (currently deferred — bug B)
  OR a bespoke C test driver that calls `loadArchive` in the RTS.

Any of those is days of focused work, and the project state is green
enough to spend this session setting up the research rather than
banging on code.

## What we already have (patch 0004 + our stub)

- `ocAllocateExtras_MachO` for PPC — patch 0004 restored the pre-2018
  "count UNDEF externals, reserve jump-island slot for each" logic.
  Already in tree.
- `ocResolve_MachO`'s per-section dispatch has a PPC arm that prints
  an error.  This is where the real `relocateSection` will plug in.

From `rts/linker/MachO.c` current:

```c
#if defined(aarch64_HOST_ARCH)
    if (!relocateSectionAarch64(oc, &oc->sections[i]))
        return 0;
#elif defined(powerpc_HOST_ARCH) || defined(powerpc64_HOST_ARCH) || defined(powerpc64le_HOST_ARCH)
    errorBelch("PPC runtime Mach-O relocation not implemented; "
               "GHCi/TemplateHaskell need re-adding the old PPC "
               "relocateSection code.");
    return 0;
#else
    if (!relocateSection(oc, i))
        return 0;
#endif
```

## What's needed (from the old code)

Pre-2018 PPC `relocateSection` (let's call it `relocateSection_PPC`
to match the x86_64 naming convention) walks `msect->reloc_info[i]`
and dispatches by `r_type`:

| Reloc type | What | Where used |
|------------|------|-------------|
| `PPC_RELOC_VANILLA` | 32-bit absolute or PC-rel | most data refs |
| `PPC_RELOC_BR14` | 14-bit conditional branch | `bc`, `bdnz`, etc |
| `PPC_RELOC_BR24` | 24-bit `bl` / `b` target | function calls |
| `PPC_RELOC_HI16` | high 16 bits of 32-bit target | `lis` of a symbol address |
| `PPC_RELOC_LO16` | low 16 bits of 32-bit target | `ori` after `lis` |
| `PPC_RELOC_HA16` | high-adjusted 16 bits (signed) | `lis` when low is signed |
| `PPC_RELOC_PAIR` | 2nd half of HI16/HA16 + LO16 pair | follows the above |
| `PPC_RELOC_SECTDIFF` | (target - other_symbol), 32-bit | position-independent refs |
| `PPC_RELOC_LOCAL_SECTDIFF` | (target - other_symbol_local) | PIC in current section |
| `PPC_RELOC_PB_LA_PTR` | lazy-bound symbol ptr fixup | PIC stubs |
| `PPC_RELOC_LO14` | 14-bit displacement form | certain load/store insns |

Plus helpers:
- `makeJumpIsland(oc, symbol, addr)` — allocate a SymbolExtras entry and write
  `lis/ori/mtctr/bctr` into it, returning the island address.
- Branch-range check: `bl` can reach ±32 MB.  If target > 32 MB away, use
  the jump island instead of the direct target.

## Retrieval strategy for the old code

Option A: `git clone https://gitlab.haskell.org/ghc/ghc.git` at commit
`374e44704b^` and extract `rts/Linker.c` (pre-split) or
`rts/linker/MachO.c` (if split by then).  Pro: ground truth.  Con:
~2 GB clone.

Option B: `curl` the specific file version at that SHA via GitLab's
raw-blob API.  Pro: fast.  Con: need to know exactly which files
and what revision.

Option C: Look in downstream distributions (MacPorts, NetBSD pkgsrc,
the GHC 7.10.x release tarballs on gitlab) for archived copies.

Option D: Reference implementation in cctools' `ld` source or
Apple's open-source `dyld` source — the relocation logic is the
same at the bit level.  Pro: publicly mirrored.  Con: needs
adaptation to GHC's ObjectCode structure.

Option A or B is cleanest.  Next session: do B with `git ls-tree`
+ `git show $SHA:rts/linker/MachO.c` to extract the file, then
hand-merge into our current MachO.c.

## Adaptation work

Even with the old code in hand, it won't just drop in:

- `ObjectCode` struct has evolved (new fields, renames).
- `Section *` layout may differ; `msect` accessors may have changed.
- `lookupSymbol` API likely still the same signature.
- `makeSymbolExtra` API — verify signature matches our 9.2.8 version.
- `errorBelch` / `barf` / `IF_DEBUG` macros — should be unchanged.

Expect ~1–2 days of adaptation + testing once the old code is extracted.

## Testing plan

Before wiring into GHCi (which needs stage2 native to work, blocked):
1. Write a small C driver in `rts/linker/` that:
   - Loads a known-good PPC `.o` we ship (say, from our test battery).
   - Calls the runtime loader API (`loadArchive`, `lookupSymbol`).
   - Calls the loaded symbol via a function pointer.
2. Run that driver on pmacg5.
3. When it works for a 1-symbol .o, add a 10-symbol .o with
   cross-section refs (exercises BR24 + HI16/LO16 pairs).
4. Eventually hook up to GHCi — which requires a working stage2 ghc.

## Deliverable this session

- This README (plan).
- [findings.md](findings.md) — notes on patch 0004 + current stub.
- [commits.md](commits.md) — empty (no code change).

## Next session

Option A: Extract the old `relocateSection` code from GHC git
history, adapt, build, test with a C driver.

Option B: Dial back ambition — pick a smaller reloc type to
implement first (e.g. just `PPC_RELOC_VANILLA`) and get the
dispatch + framework + one reloc working, then incrementally add
the others.
