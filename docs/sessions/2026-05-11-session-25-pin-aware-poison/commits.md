# Commits — session 25

(SHAs to be backfilled after the session-end commit lands.)

- _TBD_ Session 25: stage2 GC bug investigation, round 7.  PROBE23
  (PROBE22POISON + `BF_PINNED` filter + no-poison `PROBE23PINNED`
  log) confirms hypothesis (a) — the BS reaching
  `mkFastStringByteString` really is non-pinned-backed.  Hypothesis
  (b2) "PROBE22POISON was wrongly stomping pinned-Addr#s" is
  rejected.  RTS patch archived; cross-tree reverted.
- _TBD_ Session 25 commits.md: backfill the SHAs.
