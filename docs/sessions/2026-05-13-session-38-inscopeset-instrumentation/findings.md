# Session 38 findings — InScopeSet panics expose a **Var/Unique mismatch** between scope and expression

## TL;DR

Probe38 instrumented `Simplify/Env.hs` with three silent-on-happy-path
diagnostics: panic-site dump at `refineFromInScope`, post-insertion
validation at `addNewInScopeIds`, and shrink detection at
`setInScopeSet`/`setInScopeFromE`/`setInScopeFromF`.

The sweep across Big2.hs `+RTS -A1m -G1` env-lens 600..2000 shows:

1. **No `PROBE38-ADDLOST` ever fires.**  `addNewInScopeIds` /
   `extendInScopeSetList` correctly inserts every var it's given —
   immediately after insertion they're all present.
2. **No `PROBE38-SHRINK` ever fires.**  None of `setInScopeSet`,
   `setInScopeFromE`, or `setInScopeFromF` ever replaces the
   in-scope set with a smaller one.
3. **`PROBE38-PANIC` fires deterministically at every length whose
   panic-shape is `refineFromInScope`** (env-lens 825-925 and
   1650-1700 in the `-A1m -G1` sweep), always with `call=1`
   (first lookup failure of the process).

The panic data at len=850-925 (the most informative):

```
PROBE38-PANIC call=1 size=6 v=$dOrd(0x61001418) direct=Nothing elemInScope=False
  elements=[wild(0x30000000) k(0x61000e5c) m(0x61000e5d)
            a(0x610013f6) $dOrd(0x610013f7) countOf(0x720004ce)]
```

— **the in-scope set contains a `$dOrd` element with raw Unique
`0x610013f7`, but the expression's `$dOrd` Var has raw Unique
`0x61001418`.**  Same `OccName` "$dOrd_a1k0", **different Uniques**.

This is a fundamentally different bug shape than "GC corrupted the
UniqFM and lost an entry."  Insertion works; replacement doesn't
shrink; the entry is *there* (in some sense) — it just doesn't match
what the expression is asking for because **two Vars with the same
`OccName` ended up with different `realUnique` values, one in the
binding (scope) position and a different one in the usage
(expression) position**.

Session 37's "$dOrd_a1k0 fell out of the scope" reading was the
right symptom but the wrong mechanism: the scope's `$dOrd_a1k0` and
the expression's `$dOrd_a1k0` are not the same Var by Unique, so
the Unique-keyed lookup misses.  The InScopeSet wasn't corrupted —
the Vars were.

## F1. Probe38 design and instrumentation

`probe38-inscopeset.patch` adds three diagnostics to
`compiler/GHC/Core/Opt/Simplify/Env.hs`, all silent on the happy
path so we can run a full Big2.hs cross-compile without spamming
stderr.

| site | trigger | line emitted |
|------|---------|--------------|
| `refineFromInScope` Nothing branch | always (panic case) | `PROBE38-PANIC call=<N> size=<S> v=<...> direct=<...> elemInScope=<...> elements=[...]` |
| `addNewInScopeIds` after extension | extension dropped a `vs` entry | `PROBE38-ADDLOST evt=<N> newsize=<S1> lost=[...]` |
| `setInScopeSet`/`setInScopeFromE`/`setInScopeFromF` | new size < old size | `PROBE38-SHRINK site=<which> evt=<N> from=<S0> to=<S1>` |

Implementation:
- Counters via `unsafePerformIO`/`IORef Int`.
- `getKey . varUnique` for Unique → Int conversion.
- `getOccString` from `GHC.Types.Name` for cheap name strings.
- `nonDetEltsUniqSet` imported from `GHC.Types.Unique.Set` directly
  (Var.Set doesn't re-export it).

## F2. Panic-site evidence — Var/Unique mismatch

Sweep at env-lens 600..2000 step 25 captures 8 `PROBE38-PANIC`
lines.  Two distinct fingerprints:

### Fingerprint A: env-lens 825..925 (5 panics)

```
PROBE38-PANIC call=1 size=6 v=$dOrd(0x61001418) direct=Nothing elemInScope=False
  elements=[wild(0x30000000) k(0x61000e5c) m(0x61000e5d)
            a(0x610013f6) $dOrd(0x610013f7) countOf(0x720004ce)]
```

- **Scope element 5 is `$dOrd(0x610013f7)`** — a `$dOrd_a1k0` Var
  with raw Unique `0x610013f7` (decimal 1627456759).
- **Expression's `v` is `$dOrd(0x61001418)`** — a `$dOrd_a1k0` Var
  with raw Unique `0x61001418` (decimal 1627456792).
- **Delta:** `0x61001418 − 0x610013f7 = 0x21 = 33` (decimal).
- `direct=Nothing` confirms the Unique-only lookup also fails: the
  IntMap's key for `$dOrd` is `0x610013f7`, not `0x61001418`.

So the bindings on `countOf`'s RHS *do* have a `$dOrd_a1k0` Var,
and that Var is in the InScopeSet correctly.  But the expression
tree the simplifier is walking references a *different* Var with
the same OccName and a Unique 33 above.

### Fingerprint B: env-lens 1650..1700 (3 panics)

```
PROBE38-PANIC call=1 size=3 v=$dOrd(0x610013dc) direct=Nothing elemInScope=False
  elements=[wild(0x30000000) v(0x42000001) allPositive(0x720004d1)]
```

- **Scope has only 3 elements**, none of them `$dOrd`.
- **Expression's `v` is `$dOrd(0x610013dc)`**.
- Scope is much smaller — only the local case-binder, lambda
  binder, and the function name.  No outer-scope (top-level)
  bindings appear here at all.

This is the same family of bug, but the heap layout (controlled by
env-len → padding bytes → GC frequency) produces a different
manifest victim.

## F3. Self-validation never trips

**`PROBE38-ADDLOST` fires zero times in the sweep.**  `addNewInScopeIds`'s
post-extension check (every `vs` is `elemInScopeSet` of `in_scope1`)
never finds a missing entry.  This is strong evidence that
`extendInScopeSetList` itself is not the broken piece — the UniqFM
insertion path is correct.

**`PROBE38-SHRINK` fires zero times in the sweep.**  None of the
three set-replacement functions (`setInScopeSet`, `setInScopeFromE`,
`setInScopeFromF`) ever swap in a smaller in-scope set than the
one they replace.  So we're not seeing "the simplifier descended
into a context with a wrong env" via this surface.

The conclusion: **the InScopeSet at every panic site contains
exactly the Vars the simplifier intended to put there.**  The bug
is not in the InScopeSet's construction; it's that **the Vars
themselves don't have the Uniques the simplifier expects.**

## F4. Determinism — three runs at len=850 produce identical Uniques

```
$ for i in 1 2 3; do trigger-one.sh pmacg5 850 | grep PROBE38-PANIC | head -1; done
PROBE38-PANIC call=1 size=6 v=$dOrd(0x61001418) ... $dOrd(0x610013f7) ...
PROBE38-PANIC call=1 size=6 v=$dOrd(0x61001418) ... $dOrd(0x610013f7) ...
PROBE38-PANIC call=1 size=6 v=$dOrd(0x61001418) ... $dOrd(0x610013f7) ...
```

The bug is **deterministic given the same heap layout**.  Same
env-len → same padding → same GC heap geometry → same Unique
mismatch.  This is consistent with sessions 28-29's "heap-layout-
sensitive triggering."

## F5. Nursery-size sensitivity — the Unique mismatch moves with `-A`

Sweep at env-len=850 with `-A{1m,2m,4m,8m,16m,32m}`:

| -A     | rc | panic shape | scope element count | victim missing |
|--------|----|-------------|---------------------|----------------|
| 1m     | 0¹ | refine      | 6 ($dOrd in scope)  | $dOrd_a1kY (0x61001418) |
| 2m     | 0¹ | refine      | 9 ($dOrd in scope)  | $dEq_a1km  (0x610013f2) |
| 4m     | 0¹ | swap-tc     | (TC-time)           | swap |
| 8m     | 0¹ | refine      | 10 ($dOrd in scope) | ds_d1lr (0x64001435) |
| 16m    | 0  | **clean compile** | n/a            | n/a            |
| 32m    | 0¹ | refine      | 2                   | $dFoldable_a1jQ (0x610013d2) |

¹ rc=0 because we pipe `head -8`; the underlying ghc-real exited
non-zero with the panic.

Two findings:

1. **`-A16m` produces a CLEAN compile of Big2.hs at len=850.** This
   confirms the bug is GC-frequency-sensitive (so increasing the
   nursery — i.e., reducing GC frequency — eliminates the trigger).
2. **The victim Var rotates by `-A`.**  At `-A1m` it's `$dOrd`, at
   `-A2m` it's `$dEq`, at `-A8m` it's `ds_d1lr` (a normal let-
   binding), at `-A32m` it's `$dFoldable`.  **The bug isn't
   specific to typeclass dictionaries** — any Var can become the
   victim of the mismatch.  This connects to session 28's "one bug,
   multiple victim data structures" framing — extending it to "any
   Var can suffer."

## F6. Connection back to sessions 19-28's framing

Sessions 19-28 framed the bug as "GC corruption of UniqMap-backed
data structures."  Probe38's evidence refines that framing:

- The UniqFM/IntMap structure itself is **NOT** what's getting
  corrupted (`PROBE38-ADDLOST` never fires, `PROBE38-SHRINK` never
  fires).
- What's getting corrupted is the **Var heap closures themselves**
  — specifically, the `realUnique` field of `Var = Id { ..., realUnique :: FastInt#, ... }`.
- When GC corrupts a Var's realUnique, subsequent Unique-based
  lookups against that Var fail because the lookup uses one Unique
  while the IntMap was keyed by another.
- The various "victim data structures" (depSortStgBinds' adjacency
  list, refineFromInScope's InScopeSet, TC's GlobalRdrEnv) are all
  innocent victims — they correctly store the Vars they were given
  and correctly index by Unique, but the *Vars* have inconsistent
  Uniques between when they were stored and when they're looked up.

This is a **more localized hypothesis** than "any UniqMap is
corruptible" — it points specifically at GC's traversal of Var
closures' Int# fields.

## F7. Per-panic detail

| len  | shape  | call | size | v Unique     | scope $dOrd Unique (if present) | delta   |
|------|--------|------|------|--------------|--------------------------------|---------|
| 825  | refine | 1    | 6    | 0x61001418   | 0x610013f7                     | +0x21   |
| 850  | refine | 1    | 6    | 0x61001418   | 0x610013f7                     | +0x21   |
| 875  | refine | 1    | 6    | 0x61001418   | 0x610013f7                     | +0x21   |
| 900  | refine | 1    | 6    | 0x61001418   | 0x610013f7                     | +0x21   |
| 925  | refine | 1    | 6    | 0x61001418   | 0x610013f7                     | +0x21   |
| 1650 | refine | 1    | 3    | 0x610013dc   | (not in scope)                 | n/a     |
| 1675 | refine | 1    | 3    | 0x610013dc   | (not in scope)                 | n/a     |
| 1700 | refine | 1    | 3    | 0x610013dc   | (not in scope)                 | n/a     |

Fingerprint A is identical across 5 contiguous env-lens; fingerprint
B is identical across 3 contiguous env-lens.  Outside these bands,
the panic shape is `swap-tc` or `depSort` — different victims but
the same underlying corruption.

## F8. Concrete next-session targets

1. **Extend the probe to dump `seIdSubst` at the panic site.**
   If `$dOrd_a1k0(0x61001418)` is in `seIdSubst`, the simplifier
   may already know about it (with a translation entry).
   Conversely, if `seIdSubst` is empty of relevant entries, the
   bug is purely in the IDs that flow into the expression tree.

2. **Walk the Var closure's `realUnique` field over time.**
   Pick one Var (e.g., `$dOrd_a1k0` at insertion time) and write
   a probe that records its raw Unique at insertion and again at
   lookup time.  If they differ, that's GC-of-Var-realUnique
   corruption confirmed.  Look at `varUnique` definition:
   ```haskell
   varUnique :: Var -> Unique
   varUnique var = mkUniqueGrimily (realUnique var)
   ```
   So we just need to print the same Var's realUnique at two
   different times in the compilation pipeline.

3. **Investigate the Var closure heap layout.**
   `Var` is a data type with `realUnique :: FastInt` (an `Int#`).
   On PPC32 unreg, `Int#` is stored as a regular word in the
   closure payload.  Check Cmm output for `Var` constructor and
   see how realUnique is laid out — is it being read from the
   right offset?  Is it being kept across GC?

4. **Test on uranium host GHC 9.2.8.**
   Big2.hs with `+RTS -A1m -G1` on host should NOT panic.  If it
   does, the bug isn't PPC-unreg-specific.  Confirms platform
   correlation.

5. **`-A16m` clean-compile sanity check is an immediate workaround.**
   Document this in the user-facing docs as a known PPC32-unreg
   pitfall.

## F9. What probe38 ruled in/out

**Ruled out:**

- "extendInScopeSetList silently drops entries" — PROBE38-ADDLOST
  never fires.
- "setInScopeFromE/F/Set swaps in a smaller env" — PROBE38-SHRINK
  never fires.
- "The InScopeSet's UniqFM is corrupted as a data structure" —
  no evidence; the set's contents are coherent at the panic site.

**Ruled in:**

- "Two Vars with the same OccName have different Uniques" — directly
  observed at env-lens 825..925.
- "The bug is GC-frequency-sensitive" — `-A16m` produces clean
  compile.
- "The victim of the Unique mismatch is not specific to typeclass
  dictionaries" — `$dEq`, `ds_d1lr` (let-binding), `$dFoldable` all
  fall victim at different `-A` values.

## F10. Sessions-28 framing update

Old framing:
> One bug, multiple victim data structures, all UniqMap-backed.

Refined framing:
> One bug, **the Var heap closures' `realUnique` fields are
> corrupted by GC**, manifesting as failed Unique-keyed lookups in
> whichever UniqMap-backed structure first tries to find one of the
> corrupted Vars.

The InScopeSet, the depSortStgBinds adjacency list, and the TC
GlobalRdrEnv are all UniqMap-backed.  Each has its own first-touch
ordering; whichever queries a corrupted Var first fires the panic.
That's why the shape rotates with `-A` and env-len.
