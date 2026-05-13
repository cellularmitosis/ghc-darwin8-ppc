# Session 41 findings — pinned env doesn't drift; panic-site env is a **different** SimplEnv than the simplTopBinds env

## TL;DR

Probe41 (v1 + v2) pinned a SimplEnv reference in an IORef at every
`simplRecBndrs` call, then at every `substId` failure compared the
pinned env's current `seInScope`/`seIdSubst` sizes against
registration-time sizes.

Two distinct findings emerged:

1. **The pinned env's seInScope/seIdSubst sizes are STABLE** —
   `pinned_was=(2,0)` and `pinned_now=(2,0)` at the panic site.
   GC does NOT corrupt the SimplEnv data structure's
   seInScope/seIdSubst fields for the env probe41 pins.
2. **The panic-site env is a DIFFERENT SimplEnv than the pinned
   one.**  In failing runs (len=600 example), the pinned env has
   scope_size=2 (from a tiny simplRecBndrs call), while the
   panic-site `substId` failure shows `fail_scope=5 fail_subst=0`
   (a different env with more binders).

The session-40 hypothesis ("GC corrupts the SimplEnv heap closure's
seInScope/seIdSubst fields") is **partially disproven**: the env
probe41 tracks doesn't drift.  But probe41 may have pinned the
"wrong" env — the panic site uses a different env entirely.

## F1. Probe41 design

In `compiler/GHC/Core/Opt/Simplify/Env.hs`:

- **v1:** At every `simplRecBndrs` call where the resulting env's
  `seInScope` has size >= 5, register the env in
  `probe41PinnedEnv :: IORef (Maybe (SimplEnv, Int, Int))`
  (storing env + initial scope/subst sizes).  Only register once.
- **v2:** Log EVERY simplRecBndrs call's env size, and update the
  pin to the LARGEST env seen so far (broadens the threshold from
  ≥5 to "track everything; keep the biggest").

At every `substId env v` call where v's lookup-in-scope fails
(the path that fires `refineFromInScope`), emit `PROBE41-FAIL`
with the failing env's scope/subst sizes alongside the pinned
env's CURRENT scope/subst sizes.

## F2. Clean compile baseline

Big2.hs `-A256m` (clean compile) probe41-v2 trace:

```
PROBE41-RECBNDRS call=1 scope=10 subst=0 pin=yes
PROBE41-RECBNDRS call=2 scope=18 subst=0 pin=yes
PROBE41-RECBNDRS call=3 scope=14 subst=0 pin=no
PROBE41-RECBNDRS call=4 scope=18 subst=0 pin=no
RC=0
```

- **First simplRecBndrs call: scope=10** — matches Big2.hs's
  ~10 top-level binders.  This IS the simplTopBinds-entry call.
- Subsequent calls grow to 18 (later simplifier iterations
  inline more, add floats).
- All have `subst=0` at simplRecBndrs entry — substitutions get
  populated AFTER simplRecBndrs returns.

## F3. Failing compile at len=600 — different env shape

`-A1m -G1` len=600 padding probe41-v2 trace:

```
PROBE41-RECBNDRS call=1 scope=2 subst=0 pin=yes
PROBE41-FAIL v=$dNum(0x610013d0) fail_scope=5 fail_subst=0
             pinned_was=(2,0) pinned_now=(2,0)
ghc-real: panic! refineFromInScope
  InScope {wild_00 s_aXl n_aXm x_aXn scaleAndShift}
  $dNum_a1jO
```

- **First simplRecBndrs call has scope=2 — much smaller than
  clean's 10.**  This is the only simplRecBndrs call before the
  panic.  Either:
  - The simplTopBinds-entry simplRecBndrs call has a tiny binders
    list (only 2 binders), OR
  - This is a non-top-level simplRecBndrs call (from inner
    let-rec) that fired before the top-level one.
- **Panic-site env has scope=5** — different from pinned env's
  scope=2.
- **Pinned env doesn't drift:** `pinned_was=(2,0)` ≡
  `pinned_now=(2,0)`.

So the pinned env stayed at scope=2, but the panic happened in a
different env with scope=5.  **Two different envs in flight.**

## F4. Failing compile at len=950 — StgToCmm-time panic

len=950 probe41-v2 trace:

```
PROBE41-RECBNDRS call=1 scope=2 subst=0 pin=yes
PROBE41-RECBNDRS call=2 scope=6 subst=0 pin=yes
ghc-real: panic! GHC.StgToCmm.Env: variable not found
  $trModule1_r1ky
  local binds for:
  $trModule3_r1kG
```

- Two simplRecBndrs calls: scope=2 then scope=6.  Still much
  smaller than clean's 10/18/14/18 sequence.
- No PROBE41-FAIL (it's a StgToCmm-time panic, after the
  simplifier, on `$trModule1_r1ky` not found in local binds).
- Different bug family — `GHC.StgToCmm.Env: variable not found`
  is from `compiler/GHC/StgToCmm/Env.hs:153`.

## F5. Interpretation — the bug is path-dependent

Combining F2-F4:

- In a CLEAN compile, simplRecBndrs's first call has scope=10
  (the simplTopBinds-entry call).
- In FAILING compiles, simplRecBndrs's first call has scope=2
  — much smaller than expected.

This shift in scope-size pattern between clean/failing runs
suggests **the simplifier's path through the codebase differs
between the two**.  In failing runs, the simplifier may:

- (i) Process top-level binders in smaller batches.
- (ii) Skip the simplTopBinds path entirely (using a different
  entry point like simpleOptExpr).
- (iii) Have its input `binds0` truncated to only 2 binders by
  earlier pipeline stages (renamer/desugarer/specializer).

The probe41 pinned env doesn't drift, ruling out
"the SimplEnv we track is corrupted by GC."  But the panic-site
env is DIFFERENT from the pinned env, so the corruption (if any)
is on a different env.

## F6. The simplRecBndrs-first-call scope shift is heap-layout-sensitive

`-A256m` (clean) vs `-A1m -G1` (failing) with same Big2.hs source
produces drastically different first-simplRecBndrs scopes (10 vs 2).
The only difference is RTS flags affecting GC frequency.

This implies the simplifier's execution PATH itself is affected
by GC pressure — which is a *much* more invasive bug than "GC
corrupts a specific data structure."  Either:

- (a) GC corruption affects the program counter / control flow
  somehow (unlikely but consistent with the path-dependence).
- (b) GC corruption affects which `simplRecBndrs` call's binders
  list, making it look like a different sub-call rather than
  the main top-level one.
- (c) The compiler IS executing simplTopBinds normally, but
  earlier in the pipeline (renamer/desugarer) GC corrupted the
  binds tree to only have 2 binders.

Hypothesis (c) is intriguing: if `bindersOfBinds binds0` returns
only 2 entries because `binds0` itself has been corrupted by
GC to only have 2 binding groups, that would explain the
scope=2 observation AND the empty seIdSubst (session 40).

## F7. Refined framing

| Session | Framing                                              | Status        |
|---------|------------------------------------------------------|---------------|
| 33-36   | "v's closure shape is corrupt"                       | dissolved S37 |
| 28-38   | "UniqMap data structures are corrupted"              | dissolved S38 |
| 38      | "GC corrupts Var.realUnique"                         | dissolved S39 |
| 39      | "Two distinct Vars with same OccName"                | dissolved S40 (seIdSubst is just empty) |
| 40      | "GC corrupts SimplEnv heap closure"                  | partially dissolved S41 (the env probe41 tracks doesn't drift; the bug is elsewhere) |
| 41      | "binds0 / binders list is corrupted upstream"        | open          |

## F8. Concrete next-session targets

1. **Instrument the input to simplTopBinds.**  Probe42 should
   hook at `simplTopBinds env0 binds0` entry and dump
   `length (bindersOfBinds binds0)`.  If this is 2 in failing
   runs and 10 in clean runs, the corruption is BEFORE
   simplTopBinds (in the desugarer or the simplifier's invoker).
2. **Trace where binds0 is constructed.**  In
   `Pipeline.hs::simplifyPgm`, find the path that produces the
   ModGuts' `mg_binds` list that flows into simplTopBinds.
   Check if any GC-of-CoreProgram corruption could shrink that
   list.
3. **Use `-ddump-prep` or `-ddump-cse` to dump the Core program
   right before simplifier entry.**  If the dumped program has
   only 2 bindings in the failing case, that's direct evidence.
4. **Add a counter at simplTopBinds entry.**  Verify whether
   simplTopBinds is even called before the panic at len=600.
   If it's NEVER called, the panic is in a totally different
   code path (maybe simplifyExpr or simpleOptExpr).

## F9. What probe41 ruled in/out

**Ruled out:**

- "GC corrupts the SimplEnv data structure that simplRecBndrs
  produces" — at least for the env probe41 pins, the seInScope
  and seIdSubst sizes are stable across the compilation.

**Strengthened (no longer just "fresh env" speculation):**

- The panic-site env is a **different SimplEnv** from any env
  probe41 pinned.  The simplifier has multiple envs in flight,
  and the failure-path env is not one we successfully tracked.

**New hypothesis:**

- The simplifier's INPUT (binds0 / CoreProgram) may itself be
  corrupted upstream, causing simplRecBndrs to see only 2
  binders instead of 10.  This shifts the suspect downstream of
  the typechecker/desugarer/specializer pipeline.
