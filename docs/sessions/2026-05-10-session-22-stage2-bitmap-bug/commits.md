# Session 22 commits

- [`a9fe1f1`](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/a9fe1f1) — Session 22: stage2 GC bug investigation, round 4 (per-block audit shows Catch.hs PNP frames are correctly marked dead; the dominant PROBE21 BAD events for those frames are false positives).
- [`be53bce`](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/be53bce) — Session 22: state.md + roadmap.md reflect bitmap-content hypothesis disproved.

This session is read-only investigation: no edits to
`external/ghc-modern/`, no edits to `compiler/` or `rts/`, no
new probe binaries on pmacg5.  All deliverables are in
`docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/`:

- `README.md` — narrative.
- `findings.md` — measurements + decision rules.
- `HANDOFF.md` — pickup doc for session 23 with the
  poison-on-stale-slot RTS patch as the recommended next
  experiment.
- `scripts/audit-ftf-frames.py` — extracts every `_blk_NAME`
  with StackRep `[False, True, False]` and reports
  reads/writes at `Sp+8`.
- `scripts/audit-all-true-frames.py` — generalised; works
  for any True-containing StackRep pattern.

Plus one transient log artifact (gitignored):

- `log/session22/host/catch-host-O2.dump` — host GHC 9.2.8
  `-ddump-cmm` output for `Catch.hs`, used in the
  cross-vs-host StackRep comparison.
