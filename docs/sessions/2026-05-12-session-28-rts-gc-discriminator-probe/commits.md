# Session 28 commits

- `XXXXXXX` Session 28: stage2 GC bug investigation, round 10
  (PROBE28 RTS-side per-GC discriminator probe; session-27's "two
  distinct corruption modes" framing downgraded to "one bug, two
  victim data structures"; mut_list and static_objects scavenge
  paths ruled out as the bug).

## Source-tree changes that did NOT make it into git

The PROBE28 patch in `rts/sm/GC.c` was applied, used to gather data,
then reverted before session end.  The patch is preserved at
`docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch`
so it can be re-applied verbatim by the next session.

## Stage1 / stage2 / pmacg5 state changes

- `external/ghc-modern/ghc-9.2.8/` — no edits committed.  Probe
  applied for matrix runs, then reverted via `git checkout`.
- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSrts-1.0.2.a`
  — rebuilt twice during the session (once with probe, once after
  revert).  Final state matches v0.12.0.
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — rebuilt + redeployed
  twice (with probe, then clean).  Final state matches v0.12.0.
