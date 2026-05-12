# Session 27 commits

- `059bfd7` Session 27: stage2 GC bug investigation, round 9
  (non-perturbing deterministic repro nailed; `-G1` is partial
  workaround on small inputs; bug has two distinct corruption
  modes — STG-time and typecheck-time — only the STG-time variant
  is suppressed by `-G1`).

## Source-tree changes that did NOT make it into git

None this session.  No patches to `external/ghc-modern/ghc-9.2.8/`.

## Stage1 / stage2 / pmacg5 state changes

- `external/ghc-modern/ghc-9.2.8/` — no edits.
- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSghc-9.2.8.a`
  — unchanged from session-26 end (matches v0.12.0).
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — unchanged from
  session-26 end (matches v0.12.0).
- No rebuild, no redeploy this session.  Pure measurement +
  analysis + documentation.
