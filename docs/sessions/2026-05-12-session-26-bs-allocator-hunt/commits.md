# Session 26 commits

- `3d44ccc` Session 26: stage2 GC bug investigation, round 8
  (PROBE26 = ForeignPtrContents classifier; rejects hypothesis (a);
  session 25's framing of non-pinned BS at mkFastStringByteString
  disproved by direct observation).

## Source-tree changes that did NOT make it into git

- `compiler/GHC/Data/FastString.hs` was patched in-tree with
  `probe26-classify-bs.patch` for the duration of the experiment
  and reverted at session-26 end.  The patch is archived alongside
  this file for re-apply.

## Stage1 / stage2 / pmacg5 state changes

- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSghc-9.2.8.a`
  was rebuilt twice in this session: once with PROBE26 (~27 min),
  once clean after revert (~30 min).  Final state matches v0.12.0.
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` deployed twice: once
  with PROBE26, once clean.  Final state matches v0.12.0.
