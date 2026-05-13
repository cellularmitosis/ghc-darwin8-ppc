# Session 38 — real-time log

## Pickup (start of session)

Session 37 handed off with a major reframe: the closure-shape probe
trail of sessions 33-36 was dissolved.  The actual bug is visible in
the panic body:

```
ghc-real: panic! ...
  refineFromInScope ...
  InScope {wild_00 v_B1 allPositive}    ← only 3 entries
  $dOrd_a1k0                             ← missing var (Ord dict)
```

The `Ord` typeclass dictionary `$dOrd_a1k0` was supposed to be in
scope at this `refineFromInScope` call site but isn't.  Theory: GC
corruption of the UniqFM-backed InScopeSet dropped the entry between
when it was added and when `refineFromInScope` queries it.

Session 38 picks up by **instrumenting InScopeSet construction** to
either (a) catch the moment the entry vanishes, or (b) prove it was
never inserted in the first place.

## Step 0 — environment check

* Source tree clean per `git status --short` (only docs changes and
  session 37 untracked directory).
* ghc-9.2.8 source tree clean per `git -C external/ghc-modern/ghc-9.2.8
  status --short compiler/GHC/Core/Opt/Simplify/Env.hs`.
* pmacg5 has `/tmp/Big2.hs` intact (session 35 origin).
* Stage2 on pmacg5 = clean v0.12.0+ rebuild (session 37 redeploy).

## Step 1 — probe38 design

Probe38 is a **silent-on-happy-path** diagnostic with three sites in
`compiler/GHC/Core/Opt/Simplify/Env.hs`:

### (A) refineFromInScope panic-site dump

At the `Nothing` branch (just before `pprPanic`), emit one
PROBE38-PANIC line containing:

```
PROBE38-PANIC call=<N> size=<S> v=<name>(0x<key>)
              direct=<Just(name(0x<key>))|Nothing>
              elemInScope=<True|False>
              elements=[name1(0x<k1>) name2(0x<k2>) ...]
```

### (B) addNewInScopeIds self-validation

After `let !in_scope1 = in_scope \`extendInScopeSetList\` vs`, walk
`vs` and check `elemInScopeSet x in_scope1`.  Log on violation.

### (C) Shrink detection on set-replacement

Wrap `setInScopeSet`, `setInScopeFromE`, `setInScopeFromF`.  Log
when new in-scope set is strictly smaller than the old.

## Step 2 — patch applied to Simplify/Env.hs

Patch saved as `probe38-inscopeset.patch` in this session dir.

Implementation uses `unsafePerformIO` + `IORef Int` for the
sequence counters.  `getOccString` from `GHC.Types.Name` gives us
name strings.  `nonDetEltsUniqSet` came from
`GHC.Types.Unique.Set` after the first build attempt failed
(Var.Set re-exports `sizeVarSet` but not `nonDetEltsUniqSet`).

## Step 3 — build stage1

11m35s build (`logs/build1-probe38.log`, EXIT=0).  No warnings or
errors after the import fix.  The stage0 rebuild of Env.o cascaded
through the stage1 cross-compile of all libraries + the compiler
to PPC, then re-archived `libHSghc-9.2.8.a`.

## Step 4 — deploy + smoke-test

`bash scripts/deploy-stage2.sh pmacg5` — cross-link of ghc-stage2
+ scp of libs + settings file + smoke test
("stage2 native ghc on Tiger: ok").  EXIT=0.
`logs/deploy1-probe38.log`.

## Step 5 — single-shot panic at len=1650

`bash scripts/trigger-one.sh pmacg5 1650 > logs/panic-trigger-len1650.log`:

```
ghc-real: panic! (the 'impossible' happened)
  (GHC version 9.2.8:
PROBE38-PANIC call=1 size=3 v=$dOrd(0x610013dc) direct=Nothing elemInScope=False
  elements=[wild(0x30000000) v(0x42000001) allPositive(0x720004d1)]
        refineFromInScope PROBE38-PANIC call=1 size=3 ...
  InScope {wild_00 v_B1 allPositive}
  $dOrd_a1k0
```

Observations:

- `call=1` — first refineFromInScope failure of the process.
- `size=3` — three elements.
- `direct=Nothing` — Unique-only lookup also fails.
- `elemInScope=False` — sanity check consistent.
- No PROBE38-ADDLOST line above the panic.
- No PROBE38-SHRINK line above the panic.

So the InScopeSet *was correctly built with only 3 entries.*
Insertion didn't lose anything; replacement didn't shrink anything.
The set just legitimately doesn't have the var.

## Step 6 — broad sweep (step 50, env-lens 600..2000)

`bash scripts/sweep.sh pmacg5 600 2000 50` → `logs/sweep1-broad.log`:

```
len=850   addlost=0   shrink=0   panic=ghc-real: panic! ...
  PROBE38-PANIC call=1 size=6 v=$dOrd(0x61001418) direct=Nothing elemInScope=False
    elements=[wild(0x30000000) k(0x61000e5c) m(0x61000e5d)
              a(0x610013f6) $dOrd(0x610013f7) countOf(0x720004ce)]
len=900   ... (identical to 850)
len=1650  ... (size=3, like the single-shot)
len=1700  ... (identical to 1650)
```

**Key new finding:** at len=850, the scope HAS a `$dOrd` element
with Unique `0x610013f7`, but the lookup is for `$dOrd` with Unique
`0x61001418`.  Two different Vars, same OccName.  Delta=33.

## Step 7 — fine sweep (step 25)

`bash scripts/sweep.sh pmacg5 600 2000 25` → `logs/sweep2-fine.log`.

Eight panics total:
- 825, 850, 875, 900, 925 — all identical fingerprint A.
- 1650, 1675, 1700 — all identical fingerprint B.

Outside these bands, the panic shape is `swap-tc` or `depSort`
(other UniqMap-backed victims).

## Step 8 — determinism check

`for i in 1 2 3; do bash scripts/trigger-one.sh pmacg5 850 | grep PROBE38; done`
→ `logs/determinism-len850.log`:

All three runs produce **identical** Uniques.  Deterministic given
heap layout.

## Step 9 — nursery-size sensitivity

`logs/nursery-sweep.log` — sweep `-A1m`..`-A32m` at len=850:

| -A   | victim Var       |
|------|------------------|
| 1m   | $dOrd_a1kY       |
| 2m   | $dEq_a1km        |
| 4m   | (swap-tc, no refine panic)  |
| 8m   | ds_d1lr (let-binding) |
| 16m  | **clean compile** |
| 32m  | $dFoldable_a1jQ  |

Findings:
1. `-A16m` → clean compile.  Increasing nursery → no GC → no bug.
2. The victim is not specific to typeclass dictionaries — at -A8m
   it's `ds_d1lr` (a plain let-binding).

## Step 10 — panic-shape sweep

`bash scripts/sweep-panic-shape.sh pmacg5 600 2000 50` →
`logs/panic-shape-sweep.log`:

| len-band  | panic shape    |
|-----------|----------------|
| 650, 700  | depSort        |
| 750, 800  | swap-tc        |
| 850, 900  | refine (fingerprint A) |
| 1050-1600 | swap-tc        |
| 1650, 1700 | refine (fingerprint B) |
| 1750-2000 | swap-tc        |

Confirms session 37's table.  No env-len in 600..2000 produces a
clean compile under `-A1m -G1`.

## Step 11 — interpretation

Old framing (sessions 19-28):
> One bug, multiple victim data structures, all UniqMap-backed.

Refined framing:
> One bug, **the Var heap closures' `realUnique` fields are
> corrupted by GC**, manifesting as failed Unique-keyed lookups in
> whichever UniqMap-backed structure first tries to find one of the
> corrupted Vars.

Evidence ruling **out** UniqMap-data-structure corruption:
- PROBE38-ADDLOST never fires.
- PROBE38-SHRINK never fires.
- The InScopeSet at the panic site contains coherent Var entries
  (the scope's `$dOrd(0x610013f7)` and surrounding bindings are
  well-formed).

Evidence ruling **in** Var-realUnique-corruption:
- The expression's `$dOrd` and the scope's `$dOrd` have the SAME
  OccName but DIFFERENT raw Uniques.
- Same heap layout (env-len) → same Unique mismatch.  Deterministic.
- Different `-A` → different victim Var.  Heap-pressure-sensitive.
- `-A16m` → no bug.  GC-frequency-sensitive.

This is consistent with **GC corrupting the `Int#` realUnique field
of Var closures during evac/scav on PPC32 unreg**.

## Step 12 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` — probe
  reverted.
* `git diff compiler/GHC/Core/Opt/Simplify/Env.hs` — empty.  Confirmed.
* Stage1 clean rebuild (6m09s): `logs/build2-clean.log`, EXIT=0.
* Stage2 redeploy: `logs/deploy2-clean.log`, EXIT=0, smoke-test
  "stage2 native ghc on Tiger: ok".
* Baseline tests: `logs/baseline-tests-end.log` — **30 PASS, 0
  FAIL_RUN, 4 FAIL_OUTPUT** (same long-standing Int-size /
  process-pid / program-name divergences as session 37).

Session ends CLEAN with the major refinement captured in findings.md.
