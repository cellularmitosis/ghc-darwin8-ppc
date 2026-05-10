# Session 19 commits

## Landed in this session

- `80a3c7b` Session 19: stage2 GC bug investigation, round 1.
  Adds `docs/sessions/2026-05-09-session-19-stage2-gc-bug/`
  (README, HANDOFF, findings, step1/2/3 write-ups, PROBE19 patch).
- `69b39c0` Session 19: helper scripts for stage2 debug-RTS probing.
  Adds three `scripts/exp-*.sh` helpers (deploy debug stage2, run
  debug-RTS probe suite, run PROBE19 probe).
- `4e668ef` Session 19: state.md + roadmap.md reflect search-space
  narrowing.  Earlier "missing PPC memory fences" hypothesis
  marked dead.

(This file's own update follows in a small follow-on commit.)

## Key local artifacts (not committed to repo, kept for reproducibility)

- `external/ghc-modern/ghc-9.2.8/rts/sm/GCAux.c` — temporarily
  modified with PROBE19 instrumentation in `markCAFs`.  Patch
  archived at
  [`probe-markCAFs-count.patch`](probe-markCAFs-count.patch).
  Should be reverted before any release build.
- Rebuilt RTS variants:
    `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a`
    `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`
- Built and deployed:
    `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked
    stage2 with PROBE19 instrumentation.  Sits alongside the
    normal `ghc-real` and the wrapper `ghc`.
