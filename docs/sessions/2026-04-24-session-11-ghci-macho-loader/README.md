# Session 11 — GHCi MachO loader (roadmap C)

**Date:** 2026-04-24.
**Starting state:** v0.5.0 released.  Cross-compile + cabal +
runghc-tiger + ghc-pkg all work.  The single biggest user-visible
gap is **TemplateHaskell** — `$(deriveJSON ...)` and friends fail
with `Couldn't find a target code interpreter` because GHC's runtime
Mach-O loader for PPC was deleted in commit 374e44704b (Dec 2018,
the GHC 8.8.1 release).
**Goal:** restore enough of the runtime PPC Mach-O loader to make
`-fexternal-interpreter` (or in-process iserv) work for TH splices on
a Tiger box.
**Ending state:** scoping doc only this session — full implementation
needs multiple sessions.

## What's already in place

The patches we landed earlier already cover the data-structure side:

- **patch 0002** (`restore 32-bit MachOTypes`): `MachOTypes.h` knows
  about ppc/i386 32-bit Mach-O headers, nlist entries, scattered
  reloc records.
- **patch 0003** (`restore loadarchive ppc-darwin`): `LoadArchive.c`
  has the PPC case for parsing `lib*.a` archives.
- **patch 0004** (`macho-c ppc symbol-extras and reloc include`):
  - `ocAllocateExtras_MachO` for PPC restored at MachO.c:183-215.
  - `<mach-o/ppc/reloc.h>` included so `PPC_RELOC_*` constants are in
    scope.

So `ocVerifyImage_MachO`, `ocGetNames_MachO`, `ocAllocateExtras_MachO`,
and the symbol-extras allocation all compile and (presumably) work.

## What's missing

The big one: **`relocateSection` for PPC** — at MachO.c:1589-1599 we
currently `errorBelch` and return 0.  This is the function that walks
each section's relocation table and applies the actual word-level
patches: vanilla 32-bit fixups, scattered SECTDIFF pairs,
`PPC_RELOC_HI16/LO16/HA16` halves, `PPC_RELOC_BR24` branch islands,
etc.

## Reference impl available on disk

`external/ghc-8.6.5/rts/linker/MachO.c` is the *last* GHC source tree
that shipped a working PPC Mach-O loader (8.6.5 was the final 8.6
patch release, and 8.8.1 deleted it).  Lines 789-1348 of that file
contain `relocateSection` with all the PPC branches active.  Roughly:

| Reloc type | Lines (8.6.5) | What it does |
|------------|---------------|--------------|
| `GENERIC_RELOC_VANILLA` (scattered + non-scattered) | 1037-44, 1200-02 | 32-bit absolute fix |
| `PPC_RELOC_SECTDIFF` family (scattered) | 1046-67 | section-difference (PIC) |
| `PPC_RELOC_HI16/LO16/HA16/LO14` (scattered) | 1069-1109 | 16-bit halves of 32-bit addr (label+offset) |
| `PPC_RELOC_HI16/LO16/HA16` (non-scattered) | 1203-15, 1275-94 | same, but for normal label refs |
| `PPC_RELOC_BR24` | 1216-19, 1295-1327 | unconditional branch ±32 MB; jump-island fallback |

About 250 lines of code carved out of the 558-line `relocateSection`.

## API drift between 8.6.5 and 9.2.8

The 9.2.8 `relocateSectionAarch64` (MachO.c:618 in 9.2.8) has been
restructured around `oc->info->...`.  The signature changed:

```c
// 8.6.5 — passes everything explicitly
relocateSection(ObjectCode* oc, char *image,
                MachOSymtabCommand *symLC, MachONList *nlist,
                int nSections, MachOSection* sections,
                MachOSection *sect);

// 9.2.8 (aarch64 path)
relocateSectionAarch64(ObjectCode * oc, Section * section);
```

In 9.2.8, the per-section data lives under
`oc->info->macho_sections[i]`, the symtab is `oc->info->symCmd`, the
nlist is `oc->info->nlist`, and `image` is `oc->image`.  Symbol
lookup went from `lookupSymbol_(nm)` to
`lookupDependentSymbol(nm, oc)`.

**Plan: drop in a new `relocateSectionPPC(ObjectCode *oc, int sectIdx)`
modeled on the aarch64 signature.**  Body adapted line-by-line from
the 8.6.5 PPC branches.  Then dispatch from `ocResolve_MachO`'s
existing `#elif defined(powerpc_HOST_ARCH)` branch (currently the
errorBelch stub at MachO.c:1589).

## Testing strategy

The runtime loader can't easily be unit-tested on uranium (host is
arm64; the loader runs on the *target*, and we don't have stage2
working).  Two options:

1. **Compile-only smoke** — make sure the new code compiles + links
   into stage1 (libHSrts is built as part of the cross-bindist
   regardless of GHCi).  This catches typos and stale APIs but not
   semantic bugs.
2. **End-to-end via stage2** — once stage2 ghc works on Tiger
   (currently broken; see roadmap B), `ghci hello.hs` and TH splice
   tests would exercise the loader.  Until then, we can ship a small
   C test driver that:
   - Mocks an `ObjectCode` from a hand-built `foo.o`.
   - Calls `ocResolve_MachO` on it.
   - Verifies the patched bytes match expected.

   This driver lives in `tests/macho-loader/` and is itself
   cross-compiled to PPC, scp'd to pmacg5, run there.

The long-term win is option 2.  In this session we only need 1 to
land — getting the code compiling.  Option 2 is its own session.

## Plan for the implementation sub-sessions

**11a (this session): scoping doc + survey.**  Done.

**11b: port the relocateSectionPPC body.**
- New file `rts/linker/macho/relocateSection_ppc.c` (or inline in MachO.c).
- 8.6.5's `relocateSection` PPC paths copied over, signature switched,
  symbol-lookup API updated.
- Wire into `ocResolve_MachO` dispatch.
- Build stage1 with the new code; check no warnings/errors.
- Static smoke test: pick a TH-using `.hs` like aeson's `deriveJSON`
  fixture, compile it (won't actually run TH because `Use interpreter`
  in lib/settings is `YES` but we still don't have iserv set up — but
  the binary should at least link).

**11c: bytecode interpreter / iserv plumbing.**
- 9.2.8 supports out-of-process iserv as the primary TH route now.
- For PPC we'd need a PPC-built `ghc-iserv` binary that runs on Tiger
  and talks to the host ghc over a pipe.
- Cross-compile `ghc-iserv-9.2.8` for PPC, ship it, configure the
  cross-bindist's `lib/settings` to point `*.IServ` flags at it.

**11d: TH splice end-to-end.**
- Pick a known-failing test from session 8 (e.g. aeson-TH instead of
  aeson-Generics) and reproduce the failure.
- Apply 11b + 11c, re-run, verify it now succeeds.
- Add to the test battery.

## Risks / unknowns

- **Reloc semantics drift.**  `PPC_RELOC_BR24` etc. are stable Mach-O
  ABI; unlikely to have changed.  But the surrounding GHC RTS APIs
  (`makeSymbolExtra`, `relocateAddress`, the proddable-block check)
  may have moved fields or renamed.
- **Endianness in scattered reloc parsing.**  8.6.5 was native-endian
  on PPC because the host *was* PPC.  Our 9.2.8 cross is host-arm64,
  target-PPC — but the loader runs on the *target*, so it sees PPC
  bytes natively too.  The image is a target-PPC `.o` parsed by a
  target-PPC RTS.  Should be fine but worth a sanity-check.
- **Jump-island sizing.**  `ocAllocateExtras_MachO` for PPC reserves
  one slot per UNDEFINED EXTERNAL.  If a single TH splice loads
  enough symbols that the BR24 ±32 MB window can't reach all of them,
  we need a richer allocator.  Practical TH splices are small;
  unlikely to hit this.
- **`-fexternal-interpreter` may be the easier path.**  Skip the
  in-process loader entirely; iserv talks to host ghc over a socket.
  Whether that's *easier* depends on whether iserv is buildable for
  our cross.

## Hand-off for next session

This session is a scoping doc only.  No code changes.  Next session
(11b) starts the actual port: open
`external/ghc-8.6.5/rts/linker/MachO.c` at line 789 and
`external/ghc-modern/ghc-9.2.8/rts/linker/MachO.c` at line 1582 side
by side, and start moving PPC branches over.

Estimated effort 1–2 days for 11b alone, more if API drift surprises.
