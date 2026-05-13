# Sessions

One directory per work session, dated + slugged.  Each session dir
contains:

- `README.md` — narrative of what happened.  First paragraph =
  status-on-arrival.  Last paragraph = status-on-exit.
- `HANDOFF.md` — primer for the next session, written when there's
  specific unfinished work, open questions, suggested next moves,
  or gotchas to pass forward. Skip when the session ended at a
  clean stopping point and the README's exit-state paragraph is
  enough on its own. Include a literal prompt-block at the bottom
  for paste-into-fresh-session use. Convention borrowed from
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
3. **Write `HANDOFF.md`** if work continues into the next session
   and there's nontrivial context to pass forward — open
   questions, in-flight experiments, the "I'd start with #N
   next" recommendation, or gotchas the next-you would otherwise
   re-step on. Include a paste-into-fresh-session prompt block
   at the bottom. Skip if the session ended cleanly and the
   README's exit-state paragraph is enough.
4. Update [`docs/state.md`](../state.md) if the big picture changed.
5. Update [`docs/roadmap.md`](../roadmap.md) if priorities shifted.
6. Commit the session notes (and HANDOFF.md if you wrote one).
