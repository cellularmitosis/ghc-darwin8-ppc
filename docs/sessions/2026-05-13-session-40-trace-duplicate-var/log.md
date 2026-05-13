# Session 40 — real-time log

## Pickup

Session 39 disproved the "GC corrupts Var.realUnique" hypothesis
via sentinel tracking.  The remaining hypothesis was that two
distinct Var heap closures exist with the same OccName but
different Uniques, created upstream of the simplifier.  Session
40 picks up to trace where the duplicate Var is constructed.

## Step 1 — dump Core from clean PPC stage2 compile

`-A1m` fails; `-A16m + dumps` ALSO fails (the session-38 claim
that `-A16m` produces a clean compile was an artifact of
`head -8` truncating the panic message).  **`-A256m` + dumps
produces a CLEAN compile** on PPC stage2.

```
ssh pmacg5 ... ghc-real -c Big2.hs +RTS -A256m -RTS \
  -ddump-tc -ddump-ds -ddump-simpl -ddump-spec -ddump-occur-anal
RC=0  (1079 lines of dump)
```

## Step 2 — diff PPC vs uranium host Core (with -dsuppress-uniques)

`diff` output: **one line only** (`< RC=0`).  The structural
Core is byte-identical between PPC `-A256m` and uranium host
`-A1m -G1` with `-dsuppress-uniques`.  Without suppress, only
the Unique-suffix decorations differ — slightly different Unique
allocations between platforms is expected and doesn't indicate
a bug.

## Step 3 — locate $dOrd_a1k0 / $dOrd_a1k8 in the clean dump

In the clean -A256m dump, `Big2.allPositive`'s RHS:

```haskell
Big2.allPositive
  = Data.Foldable.all
      @[]
      @GHC.Types.Int
      $dFoldable_a1jY
      (GHC.Prim.rightSection
         ... (GHC.Classes.> @GHC.Types.Int $dOrd_a1k8) ...)
```

References top-level `$dFoldable_a1jY` and `$dOrd_a1k8`.  In a
failing compile, the panic site's missing var is
`$dOrd_a1k0` — same OccName-prefix as `$dOrd_a1k8`, different
Unique suffix.  These are different builds' allocation of the
same logical "Ord Int" dictionary.

## Step 4 — design probe40

Probe40 extends probe38's panic-site dump.  At every
`substId env v` call where v isn't in env's `seIdSubst` AND
v is a local Id not in `seInScope` (i.e., the path that fires
`refineFromInScope` Nothing), emit:

```
PROBE40-FAIL call=<N> v=<name>(0x<key>)
  scope_size=<S1> subst_size=<S2>
  scope_first20=[ <name>(0x<key>) ... ]
  subst_keys_first20=[ 0x<key> ... ]
```

Hook: `substId` instead of `refineFromInScope` directly, because
`refineFromInScope` doesn't have access to `seIdSubst`.

Patch saved: `probe40-subst-fail.patch` (97 lines).

## Step 5 — build + deploy

Build (~6m): `logs/build1-probe40.log`, EXIT=0.
Deploy (~6m): `logs/deploy1-probe40.log`, EXIT=0, smoke-test
PASS.

## Step 6 — trigger panics at len=850, 1650, 700

### len=850 (refine panic family)

```
PROBE40-FAIL call=1 v=$dOrd(0x61001418) scope_size=6 subst_size=0
  scope_first20=[wild(0x30000000) k(0x61000e5c) m(0x61000e5d)
                 a(0x610013f6) $dOrd(0x610013f7) countOf(0x720004ce)]
  subst_keys_first20=[]
```

### len=1650 (refine panic family)

```
PROBE40-FAIL call=1 v=$dOrd(0x610013dc) scope_size=3 subst_size=0
  scope_first20=[wild(0x30000000) v(0x42000001) allPositive(0x720004d1)]
  subst_keys_first20=[]
```

### len=700 (depSort panic family)

Different panic type — `depSortStgBinds Found cyclic SCC` on
`$trModule` bindings.  Not a refineFromInScope panic, so
probe40 doesn't fire.  This panic happens in STG, after the
simplifier.

## Step 7 — interpret probe40 data

**Critical finding: subst_size=0 at every refineFromInScope panic.**

The env at the panic site has:
- `seInScope`: init_in_scope's `{wild}` + only the binders for
  the *current function being descended into*.  No top-levels.
- `seIdSubst`: completely empty.

This is the shape of a freshly-created SimplEnv (from
`mkSimplEnv mode`) plus a tiny descent.  But `mkSimplEnv` is
only called ONCE per simplifier iteration (per Pipeline.hs:734),
and its output flows into `simplTopBinds` which populates
seInScope with ALL top-level binders via `simplRecBndrs`.

The panic-site env doesn't match what simplTopBinds' env1 would
look like.  Yet the simplifier reached refineFromInScope from
within a function body.  Either:

- (a) GC corrupted the SimplEnv's seInScope and seIdSubst
  pointer fields, resetting them to fresh-env defaults.
- (b) A simplifier path constructs a fresh env on the fly
  (not via mkSimplEnv) and uses it for descent — e.g., the
  specializer, rule-firing, unfolding-expansion.

(a) is consistent with the heap-layout-sensitive triggering
documented in sessions 28-29.  (b) needs codebase exploration.

## Step 8 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` —
  probe reverted.
* Stage1 clean rebuild: `logs/build2-clean.log`, EXIT=0.
* Stage2 redeploy: `logs/deploy2-clean.log` (the first attempt's
  `bash deploy-stage2.sh` invocation got dropped by the
  background-task wrapper; second attempt succeeded), EXIT=0,
  smoke-test PASS.
* Baseline tests: `logs/baseline-tests-end.log` — _TBD_.

Session ends CLEAN with the major new lead captured in findings.md.
