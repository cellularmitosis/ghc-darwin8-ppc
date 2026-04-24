# Sessions

One directory per work session, dated + slugged.  Each session dir
contains:

- `README.md` — narrative of what happened.  First paragraph =
  status-on-arrival.  Last paragraph = status-on-exit.
- `findings.md` — "things we learned this session that will matter
  later." Bullets are fine.
- `commits.md` — commits landed this session, one-liner each.

Historical context for work done before this workflow existed lives in
[`docs/experiments/`](../experiments/) (phase write-ups) and
[`docs/state.md`](../state.md) (the all-time status snapshot).

## Start-of-session checklist

1. Skim the most recent session's `README.md` for context.
2. Glance at [`docs/roadmap.md`](../roadmap.md) for priorities.
3. Run `tests/run-tests.sh` to confirm the baseline is green before
   changing anything load-bearing.

## End-of-session ritual

1. Commit your work.
2. Write this session's `README.md` + `findings.md` + `commits.md`.
3. Update [`docs/state.md`](../state.md) if the big picture changed.
4. Update [`docs/roadmap.md`](../roadmap.md) if priorities shifted.
5. Commit the session notes.
