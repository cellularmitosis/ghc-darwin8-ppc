# Session 51 commits

(SHA backfilled after commit lands.)

- `2784e54` — Session 51: TRUE MINIMAL REPRO found.  A 3-line
  standalone Haskell test —
  `newArray False :: ST s (STUArray s Int Bool)` followed by
  `readArray` — has 84-87% corruption rate on pmacg5 (PPC32
  unreg) under moderate GC pressure (`burnGC 1000` between
  iterations).  Reproduces under default RTS, not just
  `-A1m -G1`.  Host uranium: 0 bad.  Bug is in GHC's RTS
  byte-array allocation/zeroing, not in the compiler.  Pipeline
  chain from session 42's "empty .o" symptom all the way to
  STUArray's allocation under PPC32 unreg now resolved across
  10 sessions.

No GHC source-tree changes (all probes were in standalone test
programs, not in the compiler).  Only session notes + test
programs + logs.
