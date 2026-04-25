# Session 12 commits

| SHA | Description |
|-----|-------------|
| 2aa238e | Session 12a: fix resolveImports per-section-mmap bug; add Haskell .o loader test (v0.6.1). |

12a-only this session.  12b (iserv plumbing) deferred to a later
session.

The patch update grows `patches/0009-restore-ppc-runtime-macho-loader.patch`
from 389 → 461 lines: the additional 72 lines are the
`resolveImports` parameter change (`Section *sect_in_mem`) plus the
3 ocResolve_MachO call-site updates.
