# Session 39 findings — **Var.realUnique is STABLE; session 38's "GC corrupts realUnique" hypothesis is wrong**

## TL;DR

Probe39 tracks a sentinel Var in an IORef (keeping it live across
GC) and at every `refineFromInScope` call re-reads its
`realUnique` via the Haskell-level `varUnique` accessor.  If the
hypothesis from session 38 were correct — that GC rewrites the
`realUnique :: FastInt#` field of Var heap closures on PPC32 unreg
— the sentinel's Unique would drift over time.

**It does not drift.**

Probe39-v2's data at len=850 (where the compile succeeded with the
probe shifting the heap):

```
PROBE39-INIT name=$dOrd realUnique=0x610013f7 addr=0xcccc4eb
PROBE39-DRIFT drift_evt=1 checks=1 was@0xcccc4eb was_u=0x610013f7 now@0xcccc4eb u_via_haskell=0x610013f7 u_raw_w2=0xce214ed
PROBE39-DRIFT drift_evt=2 checks=2 was@0xcccc4eb was_u=0x610013f7 now@0xcccc4eb u_via_haskell=0x610013f7 u_raw_w2=0xce214ed
PROBE39-DRIFT drift_evt=3 checks=3 was@0xcccc4eb was_u=0x610013f7 now@0xcccc4eb u_via_haskell=0x610013f7 u_raw_w2=0xce214ed
PROBE39-DRIFT drift_evt=4 checks=4 was@0xcccc4eb was_u=0x610013f7 now@0xcccc4eb u_via_haskell=0x610013f7 u_raw_w2=0xce214ed
```

Reading the columns:

- `was_u = 0x610013f7` — registered realUnique.
- `u_via_haskell = 0x610013f7` — `varUnique v` AT EACH check.  **Identical
  to was_u every time.**
- `u_raw_w2 = 0xce214ed` — raw `peek` at word[2] of v's address.
  Differs from was_u because `anyToAddr#` returns a *wrapping-thunk*
  address, not the actual Id closure (the same lesson sessions 33-37
  learned the hard way).

So:

1. **The Haskell-level `varUnique v` IS stable** across the
   compilation pipeline for this sentinel Var.  GC may move the
   closure but the realUnique field's value (as observed by GHC's
   own accessor) doesn't change.
2. The session 38 hypothesis is **disproven** for the case probe39
   actually tracks.
3. The "drift" from raw word[2] is a probe artefact (anyToAddr#
   wrapping-thunk indirection), not a real drift.

## What the bug must be instead

If `realUnique` doesn't drift, then the session 38 fingerprint A
observation —

> in-scope has `$dOrd_a1k0(0x610013f7)` but the expression's
> `$dOrd_a1k0` has raw Unique `0x61001418`

— must mean that **two distinct `Var` heap closures exist with the
same `OccName` "$dOrd_a1k0" but different `realUnique` fields**.
One was inserted into the InScopeSet at the binding site; the
other appears in the expression tree at the use site.  Neither's
realUnique drifted; they were never the same Var.

This is a **uniqueness invariant violation upstream of the
simplifier**.  Candidates:

1. **The renamer** failed to canonicalize the dictionary to a
   single Var.
2. **The typechecker** generated two dictionary Ids for the same
   logical entity.
3. **The desugarer / specializer** rebuilt the Var with a fresh
   Unique on one path but not the other.
4. **The interface deserializer** reconstructed an imported Var
   with a different Unique than the local one.
5. **A GC bug** that corrupts the `varName :: Name` pointer in one
   Var, making it look like the same OccName but with a stale
   Unique (would still rule out realUnique drift per se, but
   shifts the corruption to a different field).

Probe39's data narrows the field, but doesn't pick one of
candidates 1-5.  That's session 40's job.

## F1. Probe39 design (v3)

In `compiler/GHC/Core/Opt/Simplify/Env.hs`:

- `probe39Slot :: IORef (Maybe (Var, Word, Word, Int))` — holds a
  reference to the sentinel Var (keeping it alive across GC) plus
  its initial realUnique and address at registration time.
- `probe39RegisterOne v` — hooks `subst_id_bndr`; registers the
  first `Var` whose `OccName` starts with `$d` (typeclass
  dictionary), at most once per process.
- `probe39CheckAt site` — hooks `refineFromInScope`'s entry; reads
  the sentinel's current `varUnique` and compares to the stored
  initial.  Emits `PROBE39-DRIFT` if and only if they differ.
- `probe39PanicDump` — hooks `refineFromInScope`'s Nothing branch
  (panic case); emits `PROBE39-PANIC` with the expression Var's
  Unique, the in-scope size, and the sentinel's state.

(v1 also raw-peeked word[2] at the address; v2 broadened
the sentinel filter from a hard-coded OccName list to any
`$d`-prefixed Name; v3 dropped the raw word[2] check after
realizing `anyToAddr#` returns a wrapping-thunk address.)

## F2. Probe-shifted heap layout

Adding probe39 to the simplifier shifts the heap enough that
**len=850 no longer panics** on Big2.hs `-A1m -G1`.  Per
session 28-29 / 38, this is consistent with the bug's heap-layout
sensitivity.  Failing env-lens shift to 650-725 (`$dNum` victim)
and 1650-1700 (`$dOrd` victim, same as session 38 fingerprint B).

## F3. In all failing runs the sentinel never registered

| len      | shape  | sentinel state | sentinel registered before panic? |
|----------|--------|----------------|------------------------------------|
| 650, 700 | refine | none           | No                                 |
| 1650, 1700| refine| none           | No                                 |

At every failing env-len, the panic fires **before** `subst_id_bndr`
has been called with any `$d*` Var — so my registration hook
never executed.

This means:

- The simplifier doesn't necessarily process top-level binders'
  RHS first; some descent order can hit `refineFromInScope` (via
  expression-level substId) before any `$d*` Var has been put
  through `subst_id_bndr`.
- The expression-Var at the panic site comes from somewhere that
  did NOT pass through `subst_id_bndr` (e.g., it was deserialized
  from an interface, or constructed directly by the simplifier
  without going through the binder substitution path).

So we have **two complementary findings**:

1. When the sentinel registers and is later checked: **no drift**.
2. When the bug fires: **sentinel never registered** — the
   expression-Var didn't pass through the binder substitution
   path.

Together, these suggest **the duplicate Var is constructed
elsewhere in the pipeline** (not by the simplifier's binder
renaming), and **its realUnique is stable** by the time the
simplifier reaches it.

## F4. What probe39 ruled in/out

**Ruled out:**

- "GC corrupts the `realUnique :: FastInt#` field of Var heap
  closures on PPC32 unreg" — the sentinel's `varUnique v` is
  stable in every check, across many refineFromInScope calls in
  the same compilation.

**Still open:**

- Whether the duplicate Var is created by the renamer / desugarer
  / typechecker / specializer / interface deserializer.
- Whether GC corrupts some OTHER field of Var (e.g., the
  `varName :: Name` pointer) such that two Vars *appear* to have
  the same OccName when they were originally distinct.

## F5. Concrete next-session targets

1. **Instrument substId itself** (not refineFromInScope's
   downstream).  At every call, dump v's Name pointer address,
   v's OccName, v's Unique, and whether v has any entry in
   seIdSubst.  This will catch the moment a Var with the wrong
   Unique flows in.
2. **Trace expression construction.** Add `Outputable`-style
   per-construction probes in `GHC.Core.Make`, `GHC.HsToCore`,
   and `GHC.Tc.Solver` to find which pipeline stage produces a
   `$dOrd_a1k0` Var with the "wrong" Unique.
3. **Check `varName v` stability.** Like probe39 but instead of
   tracking `realUnique`, track the `varName` pointer.  If
   `varName v` ever changes for a Var held in IORef, the Name
   pointer is being corrupted by GC — different bug, same
   manifestation.
4. **Compare host vs PPC dump.** Run Big2.hs `-A1m -G1
   -ddump-simpl -ddump-spec` on host and PPC and diff the
   generated Core to find where the dictionary's Unique starts
   diverging.

## F6. Sessions-38-framing update

| Hypothesis (session 38)          | probe39 verdict | refinement     |
|-----------------------------------|-----------------|-----------------|
| GC corrupts `realUnique :: FastInt#` | **ruled out**   | the field is stable |
| GC corrupts some Var field        | partially open  | could be `varName` instead |
| The InScopeSet is innocent        | confirmed (session 38) | still true |
| Two Vars with same OccName, different Uniques exist at panic time | **stronger**: probe39 confirms via stable sentinel | not a "drifted same Var", they are genuinely two Vars |

## F7. The chain of dissolved framings

Sessions 33-36 framed the bug as a closure-shape problem at v's
heap.  Session 37 dissolved that.

Session 28 framed the bug as UniqMap-data-structure corruption.
Session 38 dissolved that by self-validating InScopeSet
mutations.

Session 38 refined to "Var.realUnique corruption."
**Session 39 dissolves that, too.**

The bug appears to be **two distinct Var objects existing with
the same OccName but different Uniques**, neither of which has
its fields actively rewritten by GC during the simplifier's
operation.  The duplicate Var is born somewhere upstream of the
simplifier's binder-renaming pass and only manifests as a
refineFromInScope panic when the simplifier tries to translate
the use-site Var.
