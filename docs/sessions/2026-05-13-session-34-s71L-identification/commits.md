# Session 34 commits

This session did no source-tree changes — its work was a static
analysis of the PROBE33-v2 stage2 binary already on pmacg5 and the
corresponding `_build/stage1` artifacts already on uranium.  No
patches were authored, no rebuilds (other than the final revert +
clean rebuild at session end) were initiated.

The only commits associated with this session are the session-dir
writeup files themselves:

- 0d89e58  Session 34: identify `_s71L_info` as `ncgPlatform config`
  thunk in `GHC.CmmToAsm.AArch64.CodeGen`.

The revert + clean rebuild + redeploy at session end restored
pmacg5's `/opt/ghc-stage2/bin/ghc-real` to the v0.12.0 source-tree
state.

Pre-rebuild source-tree state:

- `compiler/GHC/Core/Opt/Simplify/Env.hs` had probe33-v2 applied
  (from session 33).
- `compiler/GHC/CmmToC.hs` had `patches/0008-cmmtoc-split-w64-double-on-32bit.patch`
  applied (long-standing, part of v0.12.0+ canonical source state).

Post-revert source-tree state:

- `compiler/GHC/Core/Opt/Simplify/Env.hs` reverted to baseline.
- `compiler/GHC/CmmToC.hs` left as-is (canonical state).
