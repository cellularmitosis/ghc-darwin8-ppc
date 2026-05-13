# Session 40 findings — **seIdSubst is EMPTY at the panic site**; the SimplEnv looks freshly created

## TL;DR

Probe40 extended probe38's panic-site dump to also report
`seIdSubst`'s size + first 20 element Uniques.  Result is
**dramatic and consistent**: at every `refineFromInScope` panic
on probe40 stage2, the `seIdSubst` has size **0** — no
substitution entries at all.

```
PROBE40-FAIL call=1 v=$dOrd(0x61001418) scope_size=6 subst_size=0
  scope_first20=[wild(0x30000000) k(0x61000e5c) m(0x61000e5d)
                 a(0x610013f6) $dOrd(0x610013f7) countOf(0x720004ce)]
  subst_keys_first20=[]
```

At len=1650:

```
PROBE40-FAIL call=1 v=$dOrd(0x610013dc) scope_size=3 subst_size=0
  scope_first20=[wild(0x30000000) v(0x42000001) allPositive(0x720004d1)]
  subst_keys_first20=[]
```

Combined with the in-scope set's contents:

- **wild_00** — the initial `mkInScopeSet (unitVarSet (mkWildValBinder Many unitTy))` element.
- A handful of *only* the binders local to the current function
  (`countOf` body: `k, m, a, $dOrd, countOf`; `allPositive`
  body: `v_B1, allPositive`).
- **No top-level binders** from any other function (`freqMap`,
  `topK`, `cumsum`, `dedup`, etc. are absent — yet they should
  all be in scope because `simplTopBinds` calls `simplRecBndrs`
  on `bindersOfBinds binds0` first).

This shape — `init_in_scope` + a few descend-derived locals,
empty `seIdSubst` — is **what a fresh SimplEnv created by
`mkSimplEnv mode`** would look like after a tiny descent.

## F1. What "fresh env at the panic site" means

`mkSimplEnv` in `Simplify/Env.hs:392`:

```haskell
mkSimplEnv :: SimplMode -> SimplEnv
mkSimplEnv mode
  = SimplEnv { seMode      = mode
             , seInScope   = init_in_scope
             , seIdSubst   = emptyVarEnv
             , seTvSubst   = emptyVarEnv
             , seCvSubst   = emptyVarEnv
             , seCaseDepth = 0 }
```

`init_in_scope :: InScopeSet = mkInScopeSet (unitVarSet (mkWildValBinder Many unitTy))`.

So a fresh env has:
- `seInScope = {wild_00}` (one element)
- `seIdSubst = emptyVarEnv` (zero elements)
- `seTvSubst = emptyVarEnv`
- `seCvSubst = emptyVarEnv`

Probe40's observed panic-site state is **exactly this**, plus
2-5 binders added by descending into one function body (lambda
binders, the function name itself).  **seIdSubst stays at 0.**

This strongly suggests the simplifier is descending into a
function body via an env that was *freshly created*, not the env
returned by `simplTopBinds`'s `simplRecBndrs` (which would have
ALL top-level binders in scope and translations for any that
were renamed by `uniqAway` in `seIdSubst`).

## F2. The split between expected env vs observed env

In `simplTopBinds`:

```haskell
simplTopBinds env0 binds0
  = do  { !env1 <- simplRecBndrs env0 (bindersOfBinds binds0)
        ; (floats, env2) <- simpl_binds env1 binds0
        ; ...
```

After `simplRecBndrs`, env1's `seInScope` should contain ALL
top-level binders (`freqMap, topK, cumsum, dedup, countOf,
shift, scaleAndShift, allPositive, swap_aUU, $dOrd_a1k8, $dNum_a1ka, …`).
`env1`'s `seIdSubst` should contain translations for any
top-level binder whose Unique was changed by `uniqAway` — typically
empty for simple cases, but non-empty if there were collisions.

The panic site's env has neither.  So the env at the panic site
is not `env1` (nor any descendant that extended `env1` with
local binders).  It's a **separately constructed env**.

## F3. Candidate sources of a fresh env in the simplifier

`mkSimplEnv` is called only twice in the codebase:

1. `compiler/GHC/Core/Opt/Pipeline.hs:734`: `simpl_env = mkSimplEnv mode` — once per simplifier iteration.
2. `compiler/GHC/Core/Opt/Simplify/Utils.hs:865`: in the GHCi
   `simpleOptExpr` style helper — not on the main compile path.

So during a normal compile, `mkSimplEnv` is only called ONCE.
That single fresh env then flows into `simplTopBinds env0 binds0`,
which constructs `env1` (with all top-levels in scope) from it.

For the panic-site env to look "fresh," one of:

- (a) The env data structure was **rewritten in memory** to look
  fresh — e.g., GC corruption rewrote the seInScope and
  seIdSubst pointers to point at the init values.
- (b) The simplifier is **descending via a code path** that
  constructs a fresh env on the fly (e.g., a rule-firing path,
  an unfolding-expansion path, or a specializer-internal path).
- (c) The lookup is happening on **a different env** than the
  one simplTopBinds returned — e.g., a stale env from a prior
  simplifier iteration whose seIdSubst was zapped via
  `zapSubstEnv`.

`zapSubstEnv` looks suspicious:

```haskell
zapSubstEnv :: SimplEnv -> SimplEnv
zapSubstEnv env = env {seTvSubst = emptyVarEnv,
                       seCvSubst = emptyVarEnv,
                       seIdSubst = emptyVarEnv}
```

This zaps all 3 substitution envs but PRESERVES `seInScope`.  If
this were the source, we'd expect a LARGE seInScope and empty
seIdSubst.  But probe40 shows BOTH are small/empty.  So
zapSubstEnv alone isn't it.

What about `mkContEx`?

```haskell
mkContEx :: SimplEnv -> InExpr -> SimplSR
mkContEx (SimplEnv { seTvSubst = tvs, seCvSubst = cvs, seIdSubst = ids }) e
  = ContEx tvs cvs ids e
```

ContEx captures the substitution envs of the current SimplEnv
and stores them in a `SimplSR`.  When the simplifier later
processes the `ContEx`, it reconstructs the SimplEnv with these
captured envs.  If at capture-time the env was empty,
re-application would also be empty.

There's no obvious "make a fresh env mid-compile" call.  So
candidate (a) — **GC corruption rewriting the SimplEnv data
structure** — moves up the suspect list.

## F4. The bug pattern: pointer-payload corruption of SimplEnv

If GC corrupts a SimplEnv's seInScope and seIdSubst pointer
fields, rewriting them to point at `init_in_scope` and
`emptyVarEnv` respectively, we'd see exactly this:

- seInScope shrinks back to {wild_00} (then grows during local
  descent to small size like 3-6).
- seIdSubst becomes empty.
- Top-level binders fall out of scope.
- All other substitution envs (seTvSubst, seCvSubst) probably
  also empty.

Probe38's PROBE38-SHRINK detection only checks size *during
explicit set-replacement Haskell operations* (`setInScopeFromE`,
`setInScopeFromF`, `setInScopeSet`).  If GC rewrites the
pointer fields directly without going through these Haskell
functions, PROBE38-SHRINK never fires.

This explains:
- Why session 38's PROBE38-SHRINK never fired.
- Why session 38's PROBE38-ADDLOST never fired (the InScopeSet
  isn't being corrupted at insertion — it's being *replaced*
  later).
- Why probe40 sees empty seIdSubst alongside small seInScope.
- Why the bug is heap-layout-sensitive (the SimplEnv heap
  closure's position determines whether GC corrupts it).

## F5. What's still ambiguous

If GC rewrites the SimplEnv's pointer fields, both seInScope
and seIdSubst (and seTvSubst/seCvSubst) should be reset to
their fresh-env values.  Probe40 confirms seIdSubst is reset
to 0.  But the seInScope at the panic site has more than just
{wild_00} — it has `{wild, k, m, a, $dOrd, countOf}` (6
elements at len=850) or `{wild, v_B1, allPositive}` (3
elements at len=1650).

Interpretation: the SimplEnv was reset at some point earlier,
THEN the descent into the current function added a few binders.
Or: the reset happened DURING the descent, after some binders
had been added.

A more refined probe would track the seInScope size at multiple
descent points (before/after each addNewInScopeIds /
substIdBndr call) and look for non-monotonic shrinkage —
moments where size goes from N to <N without an explicit
set-replacement.

## F6. Concrete next-session targets

1. **Track seInScope size deltas across simplExpr / simplBind
   recursion.**  Build a probe that snapshots seInScope size at
   simplExpr entry and exit; report any case where size at
   exit < size at entry without a setInScope* call.  This
   would catch a GC-induced reset mid-recursion.
2. **Track SimplEnv heap addresses across the simplifier.**
   Like probe39 but on the env itself: pick a "main"
   SimplEnv right after simplTopBinds' simplRecBndrs, stash it,
   periodically check `varSetMaxKey (getInScopeVars (seInScope env))`
   to see if it's getting clobbered.
3. **Use -dverbose-core2core + -dverbose-stg2stg dumps with
   `-A1G`** (huge nursery to avoid GC) to verify a CLEAN
   compile's per-iteration env state, then compare with a
   failing compile's env state shortly before panic.
4. **Test with `+RTS -DG` (GC verbose flags)** to see if GC
   activity correlates with the panic timing.

## F7. Comparison with prior session findings

Sessions 33-37 framed the bug as v's closure shape.  Session 37
dissolved that (v IS the evaluated Id).
Sessions 28-38 framed it as UniqMap corruption.  Session 38
dissolved that (PROBE38-ADDLOST/SHRINK never fire).
Session 38 then framed it as Var.realUnique corruption.  Session
39 dissolved that (sentinel's varUnique is stable).

**Session 40's framing: SimplEnv data structure corruption by
GC.**  Specifically the SimplEnv's `seInScope :: !InScopeSet`
strict field and `seIdSubst :: SimplIdSubst` lazy field appear
to have their values reset to fresh-env defaults somewhere
between simplTopBinds' construction and the simplifier's
descent into a function body.

The strictness annotation on seInScope (`!`) is interesting.
For a `!`-strict field, GHC's heap rep stores the value (or
its pointer for boxed types) directly inline in the closure.
If the field is corrupted, it'd be a direct payload overwrite.
For a non-strict field like `seIdSubst`, the field holds a
thunk-or-value pointer; GC corruption would replace the
pointer.  Both are consistent with the observed data.

## F8. What probe40 directly ruled in/out

**Ruled in:**

- The env at the refineFromInScope panic site has **empty
  seIdSubst** (subst_size=0 across 2 panic captures).
- The seInScope at the panic site has init_in_scope +
  current-function-only binders (no top-levels).

**Ruled out:**

- "The expression Var was rebadged with a fresh Unique by
  the simplifier" — substId's lookup misses because
  seIdSubst is empty, not because of a translation issue.

**Implied (not directly proven):**

- The SimplEnv at the panic site is "freshly created" — looks
  like the output of `mkSimplEnv mode` plus a tiny descent.
- Whether this is GC corruption or a legitimate simplifier
  path that creates fresh envs needs more investigation.
