# ghci-macho-loader

Status: 📋 planned.

GHCi and TemplateHaskell require GHC's runtime Mach-O linker to load
compiled object files dynamically.  The PPC relocation handling code
was deleted when PPC support was removed from GHC in commit
`374e44704b` (Dec 2018).

Currently `rts/linker/MachO.c` only defines `relocateSection` for
`x86_64_HOST_ARCH` and `relocateSectionAarch64` for aarch64.  Our stub
(in the patch for experiment 006) prints an error at runtime if the
loader is invoked.

Restoring it means re-implementing PPC relocation handling:
`PPC_RELOC_VANILLA`, `PPC_RELOC_BR14`/`BR24`, `PPC_RELOC_HI16`/`LO16`/`HA16`,
`PPC_RELOC_PAIR`, `PPC_RELOC_SECTDIFF`, `PPC_RELOC_LOCAL_SECTDIFF`,
`PPC_RELOC_PB_LA_PTR`, `PPC_RELOC_LO14`, branch-island (jump stub)
insertion for out-of-range `bl`s.

The pre-2018 code is available in GHC's git history at the commit
before 374e44704b, modulo adaptation to 9.2.8's runtime linker API.

See [plan.md](plan.md) for more detail.
