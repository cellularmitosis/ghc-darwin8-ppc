# Session 18 commits

| SHA | Subject |
|---|---|
| `4be313c` | docs: mark llvm7-bug-report-draft obsolete + propose LLVM-8 r4 swap |
| `fd773b7` | Session 18 attempt 2: built clang-8 on uranium; new RTS miscompile blocks the swap |
| (TBD)   | v0.12.0: cross-toolchain swapped to LLVM-8 (sister-project BUG-010 patch) |

`v0.12.0` tagged at the third commit.

GitHub release: https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.12.0

Assets:
- `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz` (~213 MB) — stage1 bindist (rebuilt with patched clang-8).
- `ghc-9.2.8-stage2-native-ppc-darwin8.tar.xz` (~14 MB) — stage2 PPC-native ghc + wrapper, deployable to `/opt/ghc-stage2/`.

## Notes

- Two prior commits (`4be313c`, `fd773b7`) shipped the proposal +
  rolled-back-attempts narrative.  Tag lands on the third commit
  which captures the swap-actually-landing.
- Sister project's BUG-010 fix is at
  `llvm-7-darwin-ppc/docs/patches-llvm8/0013-ppc32-darwin-power-alignment.patch`
  (their commit, not in our repo).
