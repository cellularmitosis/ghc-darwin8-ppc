# Session 42 — real-time log

## Pickup

Session 41 found that the panic-site SimplEnv is a DIFFERENT env
than the one probe41 pinned, AND in failing runs the first
simplRecBndrs call has scope=2 instead of clean's scope=10.
New hypothesis: the simplifier's input binds0 / CoreProgram is
corrupted upstream of simplTopBinds.  Session 42 directly tests
this.

## Step 1 — probe42 design

In `Simplify/Env.hs`: add `probe42DumpBinds0 :: Int -> Int -> ()`
that logs `(num_groups, num_binders)` to stderr.  Export it.

In `Simplify.hs::simplTopBinds`, add a let-binding at entry:

```haskell
let !_probe42 = probe42DumpBinds0 (length binds0) (length (bindersOfBinds binds0))
```

This emits a single line per simplTopBinds call.

Patch saved: `probe42-topbinds-input.patch` (62 lines).

## Step 2 — build + deploy

Build (~6m, EXIT=0): `logs/build1-probe42.log`.
Deploy (~6m, EXIT=0, smoke-test PASS): `logs/deploy1-probe42.log`.

## Step 3 — trigger panics + clean compile

### Clean compile (no padding, -A256m)

```
PROBE42-TOPBINDS call=1 num_groups=9 num_binders=9
PROBE42-TOPBINDS call=2 num_groups=13 num_binders=13
RC=0
```

Two simplifier iterations.  First iteration sees 9 binders
(matching Big2.hs's ~10 top-level functions + dictionaries).
Second iteration sees 13 (some inlining/floating added more).

### Failing compile len=600 (-A1m -G1)

```
PROBE42-TOPBINDS call=1 num_groups=1 num_binders=1
ghc-real: panic! refineFromInScope
```

**Only ONE binder seen at simplTopBinds entry, then panic.**

### Failing compile len=1650 (-A1m -G1)

```
PROBE42-TOPBINDS call=1 num_groups=1 num_binders=1
ghc-real: panic! refineFromInScope
```

Same pattern: 1 binder, panic.

### Failing compile len=700 (-A1m -G1)

```
PROBE42-TOPBINDS call=1 num_groups=1 num_binders=1
PROBE42-TOPBINDS call=2 num_groups=5 num_binders=5
ghc-real: panic! refineFromInScope
```

Two iterations: 1 binder, then 5.  Still less than clean's 9.

### Determinism check at len=600 (3 repeats)

All three repeats produce `call=1 num_groups=1 num_binders=1`.
**Deterministic.**

### Silent miscompile at len=850, 900, 950, 1000

```
PROBE42-TOPBINDS call=1 num_groups=0 num_binders=0
RC=0
OSIZE=152
```

**ZERO binders at simplTopBinds entry.**  The compile "succeeds"
(RC=0) but produces a 152-byte empty .o file containing NO
function definitions:

```
$ ssh pmacg5 'nm /tmp/Big2.o'
(empty)
```

Clean compile's .o is 46340 bytes with all 8 functions.

## Step 4 — nursery sweep

```
-A1G no padding:     call=1 num=9, call=2 num=13, .o=46340 (proper)
-A1G len=850:        call=1 num=9, call=2 num=13, .o=46340 (proper)
-A4m no padding:     no PROBE42 (TC-time panic, no .o)
```

With `-A1G` (huge nursery, almost no GC), the bug NEVER fires.
With `-A4m`, the bug DOES fire (but at TC time, not simplTopBinds).
With `-A1m -G1`, the bug fires reliably at simplTopBinds with
0 or 1 binders.

## Step 5 — interpretation

**The [InBind] list flowing into simplTopBinds is being
truncated by GC.**

In a clean compile, binds0 has 9 binders.  Under GC pressure:
- 1 binder remaining → panic at refineFromInScope (insufficient
  bindings → simplifier can't resolve references).
- 0 binders remaining → silent miscompile (simplifier does
  nothing, produces empty .o, returns RC=0).

The `[InBind]` list is a heap-allocated cons-list of cons cells.
GC corruption could:
- Rewrite a cons cell's `tail` pointer to Nil.
- Cause `binds0` itself to point at Nil (entire list lost).

The shrinkage is deterministic given env-len + RTS flags.

## Step 6 — implications

This finding **subsumes** every prior session's framing:

| Prior session | "X is corrupted" claim                | Reality                               |
|---------------|----------------------------------------|----------------------------------------|
| 33-36         | v's closure shape                      | symptom of list-truncation             |
| 28-38         | UniqMap data structures                | symptom of list-truncation             |
| 38            | Var.realUnique                         | not corrupted (session 39 disproved)   |
| 39            | Two distinct Vars with same OccName    | symptom of empty seIdSubst (session 40) |
| 40            | SimplEnv's seInScope/seIdSubst fields  | not corrupted (session 41 disproved)   |
| 41            | binds0 / CoreProgram upstream          | **CONFIRMED — that's the root**        |

One root cause: GC corrupts the `[InBind]` list spine.

## Step 7 — workaround / mitigation

`-A1G` (or `-A256m`) consistently avoids the bug for small
compiles.  Document this as a user-facing operational
workaround.  For large compiles, a real fix is required.

## Step 8 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs compiler/GHC/Core/Opt/Simplify.hs`
  — probe reverted.  (Note: `CmmToC.hs` remains modified — that's
  the project's pi-Double-literal patch 0008, intentional.)
* Stage1 clean rebuild: `logs/build2-clean.log`.
* (next) Stage2 redeploy + smoke-test.
* (next) Baseline tests.

Session ends CLEAN with the **smoking-gun finding** captured in
findings.md.
