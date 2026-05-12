# Session 24 commits

(SHAs to be filled in after `git commit`.  This file is the
chronological list of commits landed in this session.)

- ccb5c97 — Session 24: stage2 GC bug investigation, round 6
  (FastString StackRep is correct; bitmap codegen narrative is
  dead).  Audits `_blk_c7te`'s StackRep from cross-built FastString.o;
  finds `[False, True, True]` IS the correct answer given the Cmm
  IR.  Slot Sp+12 holds an `Addr#`, not a misclassified pointer.
  Reframes sessions 19–23's "bitmap codegen is broken" hypothesis
  to "either an invariant violation upstream, or PROBE22POISON
  itself was the bug."  HANDOFF scopes PROBE23 for session 25.
- _TBD_ — Session 24 commits.md: backfill the SHAs.
