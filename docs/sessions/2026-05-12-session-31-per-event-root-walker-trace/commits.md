# Session 31 commits

| SHA | one-line |
|-----|----------|
| 6740be4 | Session 31: stage2 GC bug investigation, round 13 (filename 1-byte bisect produces 1-bit-flip PASS/FAIL pairs and a new TC-time failure mode; +RTS -Dg trace on D/E shows cross-run divergence at GC 1 ruling out session-30 HANDOFF's top priority of address-stream diffing; BOMBSHELL discovery that ANY env var presence dodges the bug deterministically [3-byte A=A is enough] — narrows bug to one specific virtual address sensitive to environ-block-size heap shift; PROBE31 per-frame scavenge_stack instrumentation confirms walker iteration is correct via the nbytes = 4*(frames+payload_words) invariant, ruling out stack-walker as the bug locus; the failing-run GC 17 is post-panic (panic handler's tiny stack) not diagnostic of the real bug which fires in the mutator phase between GC 16 and the panic; debug RTS itself flips failure incidence so +RTS -Dg/-DS measure different runs; pivot for session 32 to using the env-var dodge as a controlled debugging primitive plus per-event weak/stable-pointer table probes). |

(SHA backfilled after the commit lands.)
