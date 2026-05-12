# Session 29 commits

No commits to the GHC source tree (`external/ghc-modern/ghc-9.2.8/`)
this session — the PROBE29 patch was applied, used, and reverted.
The patch itself is preserved at
[`probe29-rts.patch`](probe29-rts.patch) in this session dir.

## Repository commits

(SHA backfilled after the commit lands; the commit itself comes
after the session-end ritual completes.)

- `(SHA TBD)` — Session 29: stage2 GC bug investigation, round 11
  (PROBE29 per-closure-type histogram in scavenge_block + evacuate;
  histogram diff identifies workload-disproportionate types but
  bisect-by-filename reveals the bug is HEAP-LAYOUT-DEPENDENT —
  byte-identical source compiled under different filenames produces
  different outcomes; per-closure-type scavenge-bug hypothesis ruled
  out; audit direction pivots to allocator / block-boundary /
  alignment).
