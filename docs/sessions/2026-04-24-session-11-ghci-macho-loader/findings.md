# Session 11 — findings

## The runtime PPC Mach-O loader is back ✅

What was a stub `errorBelch("PPC runtime Mach-O relocation not "
"implemented")` at `rts/linker/MachO.c:1589` is now a working
`relocateSectionPPC()` function plus a `relocateAddressPPC()` helper,
modeled on the GHC-8.6.5 reference implementation but adapted to
9.2.8's per-section restructuring (`oc->info->...`, `sect->start`,
`lookupDependentSymbol`).

Captured as `patches/0009-restore-ppc-runtime-macho-loader.patch`
(389 lines).  Layered cleanly on top of patches 0002-0004 which had
already restored the data-structure side.

## Test driver: tests/macho-loader/

A standalone Haskell program that exercises the loader end-to-end:

1. `initLinker()` — set up the symbol-table state.
2. `loadObj("greeter.o")` — parse a fresh Mach-O object compiled
   from C source.
3. `resolveObjs()` — runs `relocateSectionPPC` on the loaded object.
4. `lookupSymbol("_answer")` + `lookupSymbol("_greet")` — fish two
   functions out of the loaded object.
5. Call them via FunPtr.

Result on pmacg5 (Tiger 10.4.11, PowerMac G5):

```
initLinker: ok
loadObj "greeter.o" => 1
resolveObjs => 1
lookupSymbol(answer) => 0x008fb000
answer() returned 42
lookupSymbol(greet) => 0x008fb010
test ok
relocateSectionPPC: hello from a runtime-loaded .o!
rc=0
```

`answer()` is a leaf function (just `return 42` — exercises BLR + a
simple PPC_RELOC_VANILLA on its own __cstring entry).  `greet()`
calls `puts()`, which is an external dyld symbol that needs a
`PPC_RELOC_BR24` *plus* a jump-island to reach (since `_puts` lives
~0x9050xxxx away from the loaded `.text` at 0x008fb000, well
outside the ±32 MB range of a direct `bl`).

So both jump-island generation via `makeSymbolExtra()` and the
PPC_RELOC_BR24 patch path are working.

## What the port actually had to change

Two real bugs caught between first compile and "answer returned 42":

1. **`ocVerifyImage_MachO` was hard-coded to MH_MAGIC_64.**  Nobody
   had retested it for 32-bit Mach-O after the 2018 PPC purge.  Added
   a `#if defined(powerpc_HOST_ARCH) || defined(i386_HOST_ARCH)`
   branch that expects `MH_MAGIC` instead.
2. **My PC-relative arithmetic added an extra `r_address` term.**
   GHC-8.6.5's branch-displacement formula relies on the convention
   that `word == -r_address` at entry (set by the assembler) and the
   bias is `image + sect->offset - sect->addr`.  My initial
   translation included `+ r_address` inside that bias, double-
   counting `r_address` and producing a displacement that pointed
   somewhere random.  Caught by `greet()` SIGILL'ing on its first
   `bl` to the jump island.  Reverted to match 8.6.5 exactly.

After those two fixes: green light.

## What the port did *not* need

- Rebuilding `MachOTypes.h`: patch 0002 already had it.
- Restoring `ocAllocateExtras_MachO`: patch 0004 already had it.
- Restoring the PPC reloc-include: patch 0004 already had it.
- Touching `LoadArchive.c`: patch 0003 already had it.

So patches 0002-0004 from earlier sessions did the prep; 0009 is the
keystone that turns "the data structures parse" into "the loader
actually runs."

## What works, what's still TBD

| Capability | Status |
|------------|--------|
| `loadObj` + `resolveObjs` for a hand-compiled C `.o` | ✅ |
| `lookupSymbol` for symbols defined in the loaded `.o` | ✅ |
| Calling those symbols (no-arg, returning Int / void) | ✅ |
| `PPC_RELOC_VANILLA`, `BR24`, `BR24+jumpIsland`-via-extern | ✅ |
| `PPC_RELOC_HI16/LO16/HA16` (scattered + non-scattered) | ⚠️ untested in this session, ported but no test exercises them yet |
| `PPC_RELOC_SECTDIFF` family | ⚠️ same |
| Loading a Haskell-emitted `.o` (with curry calls, info tables) | ⚠️ untested |
| Loading an archive `.a` and resolving cross-module refs | ⚠️ untested |
| GHCi REPL on Tiger | ❌ blocked on stage2 (roadmap B) |
| TemplateHaskell on Tiger | ❌ blocked on iserv-PPC build |

## What's needed before TH actually works

- **Stage2 to compile.**  GHCi needs a stage2 ppc-native ghc that can
  compile splice expressions to byte-code or load them from disk.
  Roadmap B (currently blocked on the `StgToCmm.Env` Typeable panic).
- **OR external interpreter (iserv).**  9.2.8 supports running TH
  splices in a separate `ghc-iserv` process that talks back to the
  host ghc over a pipe.  We'd cross-compile a PPC `ghc-iserv`, ship
  it to Tiger, point our cross-bindist's `lib/settings`
  `Use interpreter` and friends at it.  Conceivable in 1–2 sessions.
- **Test on real Haskell objects.**  C `.o` exercises only a subset
  of the reloc surface.  A full Haskell `.o` has more variety
  (info-table refs, FastString tables, cross-module thunks).

## Artifacts to ship in v0.6.0

- `patches/0009-restore-ppc-runtime-macho-loader.patch` (389 lines).
- `tests/macho-loader/{greeter.c,Driver.hs,run.sh}` (smoke test).
- Bindist tarball with the new `libHSrts.a` containing the loader.
- Release notes calling this what it is: "the PPC Mach-O runtime
  loader works", with the caveat that GHCi/TH still need the iserv
  plumbing layered on top.
