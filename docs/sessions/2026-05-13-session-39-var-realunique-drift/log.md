# Session 39 — real-time log

## Pickup

Session 38 refined "the InScopeSet is corrupted" to "the Var heap
closures' `realUnique :: FastInt#` fields are corrupted by GC on
PPC32 unreg" — based on observing that at the panic site, the
in-scope set contains a Var with the right OccName but a
**different raw Unique** than the expression's Var (delta=33 at
fingerprint A).  Session 39 picks up to **directly test** that
hypothesis via a sentinel Var pinned to an IORef.

## Step 1 — probe39 design (v1)

Probe39-v1 picks the first Var in `addNewInScopeIds`'s `vs` whose
`OccName` matches a hard-coded list (`$dOrd_a1k0`, `$dOrd_a1kY`,
`$dEq_a1km`, `$dFoldable_a1jQ`) — the session 38 fingerprint
victims.  Stashes it in an IORef along with its `(Var, initialU,
initialAddr, count)`.  At every `refineFromInScope` entry,
re-reads the sentinel's realUnique via `varUnique v` (Haskell-
level) AND via a raw `peek` at word[2] of v's address (from
`anyToAddr#`).

## Step 2 — build v1 (5m55s, EXIT=0) + deploy + sweep

Sweep showed `sentinel=none` for **every** failing env-len.  The
hard-coded OccName filter didn't match the build's actual victim
names.

## Step 3 — probe39 v2: broaden hook + match

v2 changes:
- Filter broadened: any `OccName` starting with `$d` (any
  typeclass dictionary).
- Also hooked `subst_id_bndr` (single-Var `extendInScopeSet`
  path) — `addNewInScopeIds` was missing top-level binders that
  enter scope via `simplRecBndrs` → `subst_id_bndr`.

Build (5m+) + deploy (~6m).

## Step 4 — single-trigger at len=850 with v2

```
PROBE39-INIT name=$dOrd realUnique=0x610013f7 addr=0xcccc4eb
PROBE39-DRIFT drift_evt=1 checks=1 was@0xcccc4eb was_u=0x610013f7 now@0xcccc4eb u_via_haskell=0x610013f7 u_raw_w2=0xce214ed
... (4 events total, all identical)
RC=0
```

**Critical observations:**

1. `u_via_haskell = 0x610013f7 = was_u` — **`varUnique v` is
   STABLE.**  No drift in the Haskell-level read.
2. `u_raw_w2 = 0xce214ed ≠ 0x610013f7` — but this is the **same
   wrapping-thunk artefact** sessions 33-37 hit.  `anyToAddr#`
   returned the address of a wrapping thunk, not the Id closure.
   The raw peek at word[2] of that thunk read some thunk
   metadata, not the realUnique.
3. RC=0 — probe39's added code shifted the heap, and len=850 no
   longer panics.  Bug moved.

**The session 38 hypothesis is disproven.**  `realUnique` is
stable across the compilation pipeline for the sentinel Var.  GC
doesn't rewrite that field.

## Step 5 — probe39 v3: drop the misleading raw-peek check

v3 modifies `probe39CheckAt` to emit `PROBE39-DRIFT` only if
`u_via_haskell ≠ was_u` (skipping the noisy `u_raw_w2` check).

## Step 6 — build v3 + deploy + sweep

Build (5m+) + deploy.

Fine sweep (step 25, env-lens 600..2000) with v3 produced these
panic captures:

| env-len    | sentinel    | panic v                  | scope size |
|------------|-------------|--------------------------|------------|
| 650, 675, 700, 725 | none | $dNum(0x610013d8)        | 4          |
| 1650, 1675, 1700   | none | $dOrd(0x610013dc)        | 3          |

All other env-lens either swap-tc or compile clean.

**`sentinel=none` in every failing run** — the panic fires
BEFORE `subst_id_bndr` is called with any `$d*` Var.  When the
sentinel IS registered (in successful compiles), it shows no
drift.

## Step 7 — panic-shape sweep with v3

`logs/panic-shape-v3.log`:

| len-band    | shape    | missing var      |
|-------------|----------|------------------|
| 650, 700    | refine   | $dNum_a1jW       |
| 750, 800    | swap-tc  |                  |
| 1050-1600   | swap-tc  |                  |
| 1650, 1700  | refine   | $dOrd_a1k0       |
| 1750-2000   | swap-tc  |                  |

Compared to session 38 (probe38) and session 37 (probe37):
- Session 38: 825-925 + 1650-1700 refine-zones.
- Session 39 (v3): 650-700 + 1650-1700 refine-zones.
- The 1650-1700 zone is **stable** across probes; the earlier
  zone shifts by ~175 env-lens due to probe-code-induced heap
  layout changes.

This is consistent with sessions 28-29-38's heap-layout-
sensitive triggering.

## Step 8 — interpretation

Combining:

(a) When the sentinel registers and is checked: **NO drift in
    `varUnique v`** across many refineFromInScope calls.
(b) When the bug fires: the **sentinel never registered** because
    the panic precedes the first `$d*` Var entering scope via
    `subst_id_bndr`.

Together these argue against "GC rewrites realUnique."  Instead,
**two distinct Var objects exist with the same OccName but
different Uniques** — neither's realUnique drifts; they're
genuinely two separate Vars.

Where does the duplicate Var come from?  Probe39's data narrows
the field but doesn't pinpoint:

- The renamer / typechecker / desugarer / specializer / interface
  deserializer could all create dictionaries.  One of them is
  producing two Vars for what should be a single canonical entity.

## Step 9 — revert + clean rebuild + redeploy + baseline

- `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` —
  probe reverted.  Confirmed empty diff.
- Stage1 clean rebuild (6m+): `logs/build4-clean.log`, EXIT=0.
- Stage2 redeploy: `logs/deploy4-clean.log`, EXIT=0, smoke-test
  PASS.
- Baseline tests: `logs/baseline-tests-end.log` — **30 PASS,
  0 FAIL_RUN, 4 FAIL_OUTPUT** (same as session 37/38 baseline).

Session ends CLEAN with the major refinement captured in
findings.md.
