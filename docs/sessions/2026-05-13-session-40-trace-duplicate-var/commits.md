# Session 40 commits

- _TBD: backfill SHA after `git commit`._  Session 40: probe40
  extends probe38's panic-site dump to also report seIdSubst's
  size and keys at every `substId env v` call where v's
  lookup-in-scope fails (the path that fires
  `refineFromInScope` panic).  Also dumped pre-simplifier Core
  from PPC stage2 (-A256m clean compile) and uranium host
  (-A1m -G1 clean compile) and compared them — with
  `-dsuppress-uniques` they are byte-identical, confirming the
  bug is dynamic (at simplifier descent time), not in the
  pipeline producing the simplifier's input.  Discovered that
  session 38's claim of `-A16m` producing a clean compile was
  an artifact of `head -8` truncating the panic body; the real
  clean-compile threshold is `-A256m`.  **Major finding:** at
  every refineFromInScope panic on probe40 stage2,
  **seIdSubst is empty (subst_size=0)**, and seInScope has
  only init_in_scope's `{wild_00}` plus the binders for the
  current function being descended into (no top-level binders,
  no substitutions).  This is the shape of a freshly-created
  SimplEnv (`mkSimplEnv mode` output) plus a tiny descent,
  but `mkSimplEnv` is called only once per simplifier iteration
  per `Pipeline.hs:734`, and its output flows into
  `simplTopBinds` which populates seInScope with all top-level
  binders via `simplRecBndrs`.  The panic-site env doesn't
  match that expected post-simplRecBndrs shape.  **New
  hypothesis:** GC corrupts the SimplEnv heap closure's
  `seInScope :: !InScopeSet` and `seIdSubst :: SimplIdSubst`
  fields, resetting them to fresh-env defaults somewhere
  during the simplifier's descent.  This is consistent with
  sessions 28-29's heap-layout-sensitive triggering and with
  probe38's PROBE38-SHRINK never firing (PROBE38-SHRINK only
  catches Haskell-level set replacements via `setInScope*`
  functions; a GC pointer rewrite of the SimplEnv data
  structure bypasses those).  v0.12.0 ships unchanged; probe
  applied for measurement only and reverted at session end;
  stage2 on pmacg5 rebuilt+redeployed clean + smoke-test PASS
  + baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (same
  long-standing test-design divergences as sessions 37-39).
