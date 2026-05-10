# Session 19 commits

## Landed in this session

(filled in at end of session — see `git log --oneline` since session 18)

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
