# Session 11 commits

| SHA | Description |
|-----|-------------|
| 49a3c49 | Session 11a: scope GHCi MachO loader port (roadmap C). |
| (pending) | Session 11b/c: PPC runtime Mach-O loader works (v0.6.0). |

11b implemented `relocateSectionPPC` + `relocateAddressPPC` in
`rts/linker/MachO.c` (captured as
`patches/0009-restore-ppc-runtime-macho-loader.patch`).  Two real
bugs fixed during bring-up:
- `ocVerifyImage_MachO` was hard-coded to `MH_MAGIC_64` — added
  branch for 32-bit Mach-O on PPC/i386.
- PC-relative arithmetic double-counted `r_address`; reverted to
  match the 8.6.5 reference exactly.

11c added `tests/macho-loader/` (Driver.hs + greeter.c + run.sh) as
the end-to-end smoke test.  Bindist rebuilt, repacked, shipped as
v0.6.0.
