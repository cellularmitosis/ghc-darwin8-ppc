# Session 12 commits

| SHA | Description |
|-----|-------------|
| 2aa238e | Session 12a: fix resolveImports per-section-mmap bug; add Haskell .o loader test (v0.6.1). |
| 13bb96c | Session 12b/c: iserv cross-build + pgmi-shim.sh (v0.7.0). |
| fc73648 | Session 12d: __eprintf stub + DYLD_LIBRARY_PATH; documents BR24 OOR for large .o (v0.7.1). |
| 7751096 | Session 12e: BR24 jump-island fix; symbol_extras placed inside RX segment (v0.7.2). |
| a295fca | Session 12f: TemplateHaskell works end-to-end on Tiger (v0.8.0). |

12a (Haskell `.o` loader test) shipped as v0.6.1.  12b/c (iserv
cross-build + ssh-piped TH protocol) shipped as v0.7.0.  12e (BR24
jump-island fix for large `.o` files) shipped as v0.7.2.  12f (binary
library Generic-derived sum tag fix + BCO endian byte-swap) shipped
as **v0.8.0** — first-ever TH on PPC/Darwin8 since 2018.

The patch update grows `patches/0009-restore-ppc-runtime-macho-loader.patch`
from 389 → 461 lines: the additional 72 lines are the
`resolveImports` parameter change (`Section *sect_in_mem`) plus the
3 ocResolve_MachO call-site updates.

`patches/0010-hadrian-cross-iserv.patch` (38 lines) enables
`iserv` + `libiserv` for cross-builds and special-cases the
hadrian program-rule's stage0-copy path so iserv builds from
source for the target.
