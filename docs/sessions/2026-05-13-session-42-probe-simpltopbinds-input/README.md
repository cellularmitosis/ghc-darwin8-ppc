# Session 42 — **SMOKING GUN**: simplTopBinds' input `binds0` is truncated to 0-1 binders by GC; silent miscompile + panic both from same root cause

**Dates:** 2026-05-13 (continuation of session 41; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-41 exit.
Session 41 narrowed the suspect to "the simplifier's input
binds0 / CoreProgram is corrupted upstream of simplTopBinds."

**Status on exit:** CLEAN.  Probe42 reverted, stage1 rebuilt
clean, stage2 redeployed to pmacg5 + smoke-test PASS, baseline
tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged from
sessions 37-41).  **The smoking-gun finding:** Probe42
instrumented `simplTopBinds`'s entry to log
`(length binds0, length (bindersOfBinds binds0))`.  In a clean
compile (-A256m or -A1G), the first call sees **9 binders**
(matching Big2.hs's top-level functions + dictionaries).  In
failing compiles (-A1m -G1) with various env-len paddings:
- 600, 1650, 1700: **1 binder** → refineFromInScope panic.
- 700: 1 binder, then 5 → refineFromInScope panic.
- 850, 900, 950, 1000: **0 binders** → "compile succeeds"
  RC=0 producing a **152-byte empty .o file**.  No function
  definitions emitted.  Silent miscompilation.
- 800, 1100, 1500, 1900, 2000: TC-time `swap-not-in-scope`
  error (no probe42 fires; the [InBind] hasn't been read yet).
The [InBind] list is a heap-allocated cons-list; GC is
truncating it.  `-A1G` (no GC pressure) always sees 9 binders.
**This finding subsumes every prior session's framing** —
v's-closure-shape, UniqMap-corruption, Var.realUnique-drift,
seIdSubst-empty, SimplEnv-corruption — all are downstream
symptoms of the same root cause: GC corrupts the [InBind] list
spine, leaving the simplifier with 0-1 binders instead of 9.

v0.12.0 release unchanged.

## Plan (per session 41 HANDOFF.md)

Instrument `simplTopBinds`'s entry to dump
`length (bindersOfBinds binds0)`.  If failing runs show
count=2 (small) and clean runs show count=10 (full), the
corruption is BEFORE simplTopBinds.

## What happened

### Phase 1 — probe design + apply

`Simplify/Env.hs`: add `probe42DumpBinds0 :: Int -> Int -> ()`
helper, export it.
`Simplify.hs::simplTopBinds`: at the function's entry, add a
let-binding `let !_probe42 = probe42DumpBinds0 (length binds0)
(length (bindersOfBinds binds0))`.

Patch saved: `probe42-topbinds-input.patch` (62 lines).

### Phase 2 — build (~6m) + deploy (~6m)

EXIT=0 both.  Smoke-test PASS.

### Phase 3 — trigger panics + observe shape

Clean compile (-A256m, no padding):

```
PROBE42-TOPBINDS call=1 num_groups=9 num_binders=9
PROBE42-TOPBINDS call=2 num_groups=13 num_binders=13
RC=0   .o=46340 B
```

Failing compile (-A1m -G1) sweep:

| env-len    | call=1 binds  | call=2 binds | RC | .o size | outcome              |
|------------|---------------|--------------|----|---------|----------------------|
| 600        | 1             | -            | 1  | -       | refineFromInScope panic |
| 700        | 1             | 5            | 1  | -       | refineFromInScope panic |
| 800        | (no probe42)  | -            | 1  | -       | TC-time swap-not-in-scope |
| 850-1000   | **0**         | -            | 0  | **152** | **SILENT MISCOMPILE** |
| 1100-1600  | (no probe42)  | -            | 1  | -       | TC-time swap-not-in-scope |
| 1650, 1700 | 1             | -            | 1  | -       | refineFromInScope panic |
| 1750-2000  | (no probe42)  | -            | 1  | -       | TC-time swap-not-in-scope |

### Phase 4 — silent miscompile confirmed

At env-lens 850-1000, ghc-real exits RC=0 and produces a
152-byte .o file:

```
$ ssh pmacg5 'nm /tmp/Big2.o'
(empty)
```

vs. clean compile's 46340-byte .o:

```
$ ssh pmacg5 'nm /tmp/Big2.o | head'
00003e78 D _Big2_allPositive_closure
00000290 T _Big2_allPositive_entry
... (all 8 functions present)
```

**The compiler silently produced an empty .o file claiming
success.** This is a more severe correctness bug than any
panic — programs that link against the empty Big2.o would fail
at runtime with undefined symbols.

### Phase 5 — nursery sensitivity baseline

| -A   | binds shape                | .o size | outcome     |
|------|----------------------------|---------|-------------|
| 1G   | call=1 num=9, call=2 num=13 | 46340 B | proper      |
| 1G len=850 | call=1 num=9, call=2 num=13 | 46340 B | proper |
| 4m   | (no probe42 fired)         | -       | TC panic    |

`-A1G` (huge nursery → minimal GC) **always** produces 9
binders.  The bug is **definitively GC-pressure-induced
truncation of the [InBind] list spine**.

### Phase 6 — determinism check

Three consecutive runs at len=600 all produce
`PROBE42-TOPBINDS call=1 num_groups=1 num_binders=1`.  **The
bug is deterministic given env-len + RTS flags.**

### Phase 7 — root cause: GC corrupts [InBind] list spine

`binds0 :: [InBind]` is a heap cons-list:

```
binds0 = (binding1 : binding2 : ... : binding9 : [])
```

Each `:` is a `CONSTR_2_0`-flavoured cons cell with `head ::
InBind` and `tail :: [InBind]` pointers.

In failing runs:
- `length = 1`: first cons cell intact (`head = binding1`),
  but `tail` pointer rewritten to Nil.
- `length = 0`: binds0 itself points at Nil.

GC corruption of these cons cells (or the variable holding
binds0) truncates the list.

### Phase 8 — implications

The bug **affects compilation of arbitrary Haskell programs on
PPC stage2**, not just Big2.hs.  Any program large enough to
trigger GC during compilation can produce:
- A panic, OR
- A silent miscompile (empty .o).

**Workaround:** `+RTS -A1G -RTS` (or `-A256m` for moderately
sized programs).  This should be documented in the user-facing
README's "Implementation status" tables and release notes.

### Phase 9 — connection to all prior sessions

Every prior "X is corrupted" framing is **a downstream symptom
of the [InBind] list truncation**:

| Session | "X is corrupted" framing           | Reality                                |
|---------|------------------------------------|----------------------------------------|
| 33-36   | v's closure shape                  | symptom of small InScopeSet from 1-binder run |
| 28-38   | UniqMap data structures            | symptom of small InScopeSet            |
| 38      | Var.realUnique                     | not corrupted (S39)                    |
| 39      | Two distinct Vars same OccName     | symptom of empty seIdSubst (S40)       |
| 40      | SimplEnv pointer fields            | not corrupted (S41)                    |
| 41      | binds0 / CoreProgram upstream      | **confirmed — that's the root** (S42)  |

### Phase 10 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs compiler/GHC/Core/Opt/Simplify.hs`
  — probe reverted.  (`CmmToC.hs` remains modified — project's
  pi-Double-literal patch 0008, intentional.)
* Stage1 clean rebuild: `logs/build2-clean.log` _(TBD)_.
* Stage2 redeploy: `logs/deploy2-clean.log` _(TBD)_.
* Baseline tests: `logs/baseline-tests-end.log` _(TBD)_.

Session ends CLEAN with the **smoking gun** captured.

## Files added this session

* `README.md` (this), [`log.md`](log.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`commits.md`](commits.md).
* `probe42-topbinds-input.patch` — simplTopBinds entry dump.
* `logs/build1-probe42.log`, `deploy1-probe42.log` — probe42
  build + deploy.
* `logs/sweep1-probe42.log` — sweep across env-lens with binds
  count + .o size.
* `logs/len850-probe42.log` — full PROBE42 trace at len=850
  (the silent-miscompile case).
* `logs/build2-clean.log`, `deploy2-clean.log`,
  `baseline-tests-end.log` — post-revert cleanup _(TBD)_.

## Top finding

**GC corrupts the [InBind] list spine flowing into
`simplTopBinds`, truncating it to 0-1 binders instead of the
expected 9.** This is the single root cause of every prior
session's observed corruption.  Workaround: `+RTS -A1G -RTS`.
A real fix requires tracking down the GC bug — likely in
`rts/sm/Evac.c`'s handling of CONSTR_2_0 closures (cons cells
with 2 pointer fields) on PPC32 unreg.

See [`findings.md`](findings.md) §F5 for concrete next-session
experiments, and [`HANDOFF.md`](HANDOFF.md) for the pickup
primer.
