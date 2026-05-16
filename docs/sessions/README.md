# Sessions

One directory per work session, dated + slugged.  Each session dir
contains:

- `README.md` — narrative of what happened.  First paragraph =
  status-on-arrival.  Last paragraph = status-on-exit.
- `HANDOFF.md` — primer for the next session.  **Write one every
  session.**  The only valid reason to skip is that the entire
  project has run out of roadmap and there is literally nothing
  left to do — and even then a HANDOFF.md saying so is more
  useful than silence.  A "clean stopping point" is not a reason
  to skip; a release boundary is itself worth flagging in a
  HANDOFF so the next session knows the center-of-gravity moved.
  Include the open punch list (priority-ordered), methodology
  gotchas a future you would re-step on, where the canonical
  artifacts live now, and a literal prompt-block at the bottom
  for paste-into-fresh-session use.  Convention borrowed from
  sister project `llvm-7-darwin-ppc`; canonical example at
  [`../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/HANDOFF.md`](../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/HANDOFF.md).
- `findings.md` — "things we learned this session that will matter
  later." Bullets are fine.
- `commits.md` — commits landed this session, one-liner each.
- `logs/` (optional) — raw command output / sweep data / probe
  traces / disasm dumps captured during the session.  Tracked
  in git (not gitignored) so future sessions can audit the
  point-in-time evidence behind findings.  Most are <100 KB;
  occasional `+RTS -Dg` traces run into the MBs.  Scripts in
  this session's `scripts/` should write here (relative path
  `$session_dir/logs/`) rather than the now-removed top-level
  `log/` directory.

Historical context for work done before this workflow existed lives in
[`docs/experiments/`](../experiments/) (phase write-ups) and
[`docs/state.md`](../state.md) (the all-time status snapshot).

## Start-of-session checklist

1. Skim the most recent session's `README.md` for context.
2. **If a `HANDOFF.md` exists alongside that README, read it
   first** — it's the explicit pickup doc and supersedes anything
   ambiguous in the README. Reading order, suggested next moves,
   and gotchas-not-to-re-step-on live there.
3. Glance at [`docs/roadmap.md`](../roadmap.md) for priorities.
4. Run `tests/run-tests.sh` to confirm the baseline is green before
   changing anything load-bearing.

## End-of-session ritual

1. Commit your work.
2. Write this session's `README.md` + `findings.md` + `commits.md`.
3. **Write `HANDOFF.md`.**  Every session, not just the messy
   ones.  Open questions, in-flight experiments, the "I'd start
   with #N next" recommendation, gotchas the next-you would
   re-step on, and where the canonical artifacts live after
   anything moved this session.  Include a paste-into-fresh-
   session prompt block at the bottom.  The only valid skip is
   total project roadmap exhaustion — and even then, a HANDOFF.md
   saying so is better than silence.
4. Update [`docs/state.md`](../state.md) if the big picture changed.
5. Update [`docs/roadmap.md`](../roadmap.md) if priorities shifted.
6. **Update the project README** to reflect anything user-visible
   that changed this session — status table flips, perf numbers,
   sister-project version bumps, deprecations.  Even sessions that
   don't ship a release usually move the status forward in some
   way.  If a release *did* ship, additionally update the Releases
   section and tag the commit.
7. Commit the session notes (and HANDOFF.md if you wrote one).
