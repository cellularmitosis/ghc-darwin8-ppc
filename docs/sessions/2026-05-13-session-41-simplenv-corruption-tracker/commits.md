# Session 41 commits

- 3590b57 Session 41: probe41
  (pin SimplEnv reference in IORef at every simplRecBndrs call,
  track seInScope/seIdSubst drift at every substId failure)
  partially disproves session 40's "GC corrupts SimplEnv heap
  closure's seInScope/seIdSubst fields" hypothesis.  Three
  iterations.  v1 hardcoded threshold (size >= 5) didn't fire
  in failing runs because first simplRecBndrs call has scope=2.
  v2 logs EVERY simplRecBndrs call.  v2 found: in a CLEAN
  compile, first simplRecBndrs call has scope=10 (matching
  Big2.hs's ~10 top-level binders); in a FAILING compile at
  len=600, first simplRecBndrs call has scope=2.  The pinned
  env's sizes are STABLE (pinned_was = pinned_now at panic
  time) — GC does NOT corrupt the env probe41 tracks.  But
  the panic-site env is a DIFFERENT SimplEnv than the pinned
  one (fail_scope=5 vs pinned scope=2).  Multiple envs in
  flight; probe41 didn't track the right one.  v1 build had a
  `>>` / `$` precedence bug (`hPutStrLn ... $ unwords [...] >>
  hFlush stderr` parsed as `String >> IO ()` type error) —
  fixed via do-block.  Refined framing: the simplifier's
  INPUT (binds0 / CoreProgram) may be corrupted upstream,
  causing simplRecBndrs to see only 2 binders instead of 10.
  Suspect shifts to the typechecker / desugarer / specializer
  / interface deserializer pipeline.  v0.12.0 ships unchanged;
  probe applied for measurement only and reverted at session
  end; stage2 on pmacg5 rebuilt+redeployed clean + smoke-test
  PASS + baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT
  (same long-standing test-design divergences as sessions
  37-40).  Session 41 HANDOFF.md scopes probe42:
  instrument simplTopBinds entry to dump
  length (bindersOfBinds binds0) — direct test of "input is
  corrupted upstream."
