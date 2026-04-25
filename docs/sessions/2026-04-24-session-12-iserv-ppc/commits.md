# Session 12 commits

| SHA | Description |
|-----|-------------|
| 2aa238e | Session 12a: fix resolveImports per-section-mmap bug; add Haskell .o loader test (v0.6.1). |
| 13bb96c | Session 12b/c: iserv cross-build + pgmi-shim.sh (v0.7.0). |

12a (Haskell `.o` loader test) shipped as v0.6.1.  12b/c (iserv
cross-build + ssh-piped TH protocol) shipped as v0.7.0.  12d (path
mirroring or iserv-proxy) still TBD; needs the next session.

The patch update grows `patches/0009-restore-ppc-runtime-macho-loader.patch`
from 389 → 461 lines: the additional 72 lines are the
`resolveImports` parameter change (`Section *sect_in_mem`) plus the
3 ocResolve_MachO call-site updates.

`patches/0010-hadrian-cross-iserv.patch` (38 lines) enables
`iserv` + `libiserv` for cross-builds and special-cases the
hadrian program-rule's stage0-copy path so iserv builds from
source for the target.
