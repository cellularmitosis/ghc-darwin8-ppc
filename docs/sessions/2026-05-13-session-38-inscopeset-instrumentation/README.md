# Session 38 — probe38 instruments InScopeSet and discovers the bug is a **Var/Unique mismatch**, not InScopeSet corruption

**Dates:** 2026-05-13 (continuation of session 37's reframe; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-37 exit.
`pmacg5:/opt/ghc-stage2/bin/ghc-real` is the clean v0.12.0+
rebuild (no probes).  v0.12.0 release unchanged.  Session 37
dissolved the closure-shape-of-v probe trail and reframed the bug
as "GC corruption of UniqMap-backed data structures."  Visible
symptom: `refineFromInScope` panics with
`InScope {wild_00 v_B1 allPositive}` (only 3 entries) and missing
`$dOrd_a1k0` (the `Ord` typeclass dictionary).

**Status on exit:** CLEAN.  Probe38 reverted, stage1 rebuilt clean,
stage2 redeployed to pmacg5 + smoke-test PASS.  **Major refinement
to session 28's framing:** the InScopeSet is *not* corrupted —
`addNewInScopeIds`'s self-validation never fired, `setInScope*`'s
shrink-detection never fired.  What's broken is **the Var heap
closures themselves**: two Vars with the same `OccName`
"$dOrd_a1k0" exist with **different raw Uniques** — one is
correctly inserted into the InScopeSet (at the binding site), the
other is in the expression tree the simplifier is walking (at the
use site).  The Unique-keyed lookup fails because they don't
match.  This shifts the hypothesis from "UniqFM IntMap corruption"
to "GC-of-Var-realUnique corruption," and connects to the
sessions 19-28 GC-sensitivity findings via a tighter mechanism.
v0.12.0 release unchanged.

## Plan (per session 37 HANDOFF.md)

Instrument InScopeSet construction in `Simplify/Env.hs` with three
diagnostics, all silent on the happy path:

1. **`refineFromInScope` panic site.** Emit one line listing the
   call counter, size of `in_scope`, every element as
   `name(uniqueKey)`, v's `name(uniqueKey)`, whether
   `lookupInScope_Directly` (Unique-only lookup) finds v, and
   whether `elemInScopeSet v in_scope` agrees.
2. **`addNewInScopeIds` self-validation.** After
   `extendInScopeSetList`, verify every var in `vs` is now an
   `elemInScopeSet` of the post-extension set.  Log only if any
   were lost.
3. **Set-replacement shrinkage detection.** Wrap `setInScopeSet`,
   `setInScopeFromE`, `setInScopeFromF` to log only when the new
   size is strictly less than the old size.

Probe38 lives in `probe38-inscopeset.patch` (this dir).

## What happened

### Phase 1 — patch + build + deploy

Patched `compiler/GHC/Core/Opt/Simplify/Env.hs` with the three
diagnostic sites (177-line patch, including imports of
`Data.IORef`, `Numeric`, `System.IO`, `System.IO.Unsafe`, plus
`getKey`, `nonDetEltsUniqSet`, `getOccString` from the relevant
GHC modules).

First build failed because I'd assumed `nonDetEltsUniqSet` was
re-exported through `Var.Set` — added explicit import from
`Unique.Set` and rebuilt (11m35s).  Deploy to pmacg5 took ~6 min
(stage2 link + scp + smoke-test PASS).

### Phase 2 — focused trigger at len=1650

```
ghc-real: panic! (the 'impossible' happened)
  (GHC version 9.2.8:
PROBE38-PANIC call=1 size=3 v=$dOrd(0x610013dc) direct=Nothing elemInScope=False
  elements=[wild(0x30000000) v(0x42000001) allPositive(0x720004d1)]
  ...
  InScope {wild_00 v_B1 allPositive}
  $dOrd_a1k0
```

The panic reproduces session 37's data — **and** also shows:
- `direct=Nothing` (Unique-only lookup also fails)
- The Vars all have their Uniques printed: `$dOrd`'s lookup is for
  raw Unique `0x610013dc`, but no element of the set has that
  Unique.

### Phase 3 — broad sweep + fingerprints

Two fingerprints across env-lens 600..2000 step 25:

**Fingerprint A (env-lens 825..925, 5 panics):**
```
PROBE38-PANIC call=1 size=6 v=$dOrd(0x61001418) direct=Nothing elemInScope=False
  elements=[wild(0x30000000) k(0x61000e5c) m(0x61000e5d)
            a(0x610013f6) $dOrd(0x610013f7) countOf(0x720004ce)]
```

Element 5 IS a `$dOrd` Var with raw Unique `0x610013f7`.  But the
expression's `$dOrd` Var has raw Unique `0x61001418` — **two
different Vars with the same OccName**.  Delta `0x21 = 33`.

**Fingerprint B (env-lens 1650..1700, 3 panics):**
```
PROBE38-PANIC call=1 size=3 v=$dOrd(0x610013dc) direct=Nothing elemInScope=False
  elements=[wild(0x30000000) v(0x42000001) allPositive(0x720004d1)]
```

Scope size 3, no `$dOrd` element at all.

### Phase 4 — determinism + nursery-size sensitivity

Three runs at len=850 produce **identical** Uniques (same victim,
same scope Var, same in-scope set).  Same heap layout → same bug
fingerprint.

Sweeping `-A1m`..`-A32m` at len=850: the victim Var rotates — at
`-A2m` it's `$dEq`, at `-A8m` it's `ds_d1lr` (a normal let-binding,
not a typeclass dictionary).  **The bug isn't dictionary-specific**;
it's a general Unique-mismatch that hits whatever Var happens to
be the first refineFromInScope failure.  **`-A16m` produces a clean
compile** at len=850, confirming GC-frequency-sensitive triggering.

### Phase 5 — interpretation

The classical "GC corrupts UniqFM" framing doesn't fit:

- `PROBE38-ADDLOST` never fires → insertion is correct.
- `PROBE38-SHRINK` never fires → replacement is correct.
- The InScopeSet at the panic site contains the Var the simplifier
  intended to put there (in fingerprint A: `$dOrd(0x610013f7)`).
- But the **same conceptual `$dOrd_a1k0`** in the expression tree
  has a different raw Unique (`0x61001418`).

The refined hypothesis: **GC corrupts the `realUnique :: FastInt`
field of Var heap closures.**  When the simplifier inserts Var `v`
into the InScopeSet, the IntMap key is `varUnique v` at insertion
time.  When the simplifier later looks up the SAME `v` in the
expression tree, `varUnique v` returns a different value because
GC has rewritten `v`'s `realUnique` field.

This explains every observation:

- The IntMap is internally consistent (no ADDLOST/SHRINK).
- Different `-A` values trigger the bug on different Vars (because
  GC traverses different closures depending on heap pressure).
- The bug is filename-sensitive (session 29) because filename →
  heap layout → which Var closures land in which GC region.
- The bug is platform-specific (PPC32 unreg) because the Var
  closure's `Int#`-field layout / GC traversal on PPC32 unreg
  differs from arm64/x86_64.

### Phase 6 — revert + clean rebuild + redeploy

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` — probe
  reverted.
* Stage1 clean rebuild (6m09s): `logs/build2-clean.log`, EXIT=0.
* Stage2 redeploy: `logs/deploy2-clean.log`, EXIT=0,
  smoke-test PASS ("stage2 native ghc on Tiger: ok").
* Baseline tests (post-revert): `logs/baseline-tests-end.log` —
  **30 PASS, 0 FAIL_RUN, 4 FAIL_OUTPUT** (01_int_arith, 14_env_args,
  24_ffi, 25_numeric_boundaries — the long-standing
  Int-size/process-pid/program-name divergences).  Identical to
  session 37 baseline.

Session ends CLEAN.

## Files added this session

* `README.md` (this), [`log.md`](log.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`commits.md`](commits.md).
* `probe38-inscopeset.patch` — instrumentation of `Simplify/Env.hs`.
* `scripts/sweep.sh` — sweep helper, PROBE38-prefixed greps.
* `scripts/sweep-panic-shape.sh` — copied from session 37.
* `scripts/sweep-full.sh` — sweep capturing full output per len.
* `scripts/trigger-one.sh` — one-shot panic capture at a specific len.
* `logs/build1-probe38.log` — probe38 build.
* `logs/deploy1-probe38.log` — probe38 deploy.
* `logs/panic-trigger-len1650.log` — focused single-len panic.
* `logs/sweep1-broad.log` — sweep at step 50.
* `logs/sweep2-fine.log` — sweep at step 25.
* `logs/panic-shape-sweep.log` — panic-shape sweep at step 50.
* `logs/determinism-len850.log` — 3 consecutive runs, identical.
* `logs/nursery-sweep.log` — `-A1m`..`-A32m` victim rotation.

## Top finding to carry into session 39

**The InScopeSet isn't corrupted; the Var heap closures'
`realUnique` fields are.**  Future probes should:

1. Track a specific Var's `realUnique` across the compilation
   pipeline (insertion-time vs. lookup-time read).
2. Investigate PPC32-unreg Cmm layout of the Var data constructor,
   especially the `Int#` realUnique field and its GC traversal.
3. If applicable, study how `realUnique` survives GC's evac/scav
   passes for non-pointer Int# fields on PPC32 unreg.

See [`findings.md`](findings.md) §F8 for concrete experiment
recipes, and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
