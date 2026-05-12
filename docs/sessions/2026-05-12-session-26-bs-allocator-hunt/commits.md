# Session 26 commits

(Filled in after the session ends and commits land.)

## Plan

- One commit for the session writeup (this directory + log/session26
  is gitignored).
- The PROBE26 patch to `compiler/GHC/Data/FastString.hs` is reverted
  at session end and not committed to the GHC tree; it's archived as
  `probe26-classify-bs.patch` in this directory for re-apply.
- No change to `docs/state.md` or `docs/roadmap.md` unless PROBE26
  yields a definitive root cause for the GC bug (in which case the
  status of "stage2 native ghc" gets updated).
