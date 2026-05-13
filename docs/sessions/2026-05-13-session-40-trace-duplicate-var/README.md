# Session 40 — probe40 reveals **seIdSubst is EMPTY** at the panic site; new lead is SimplEnv data-structure corruption

**Dates:** 2026-05-13 (continuation of session 39; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-39 exit.
`pmacg5:/opt/ghc-stage2/bin/ghc-real` is the clean v0.12.0+
rebuild (no probes).  v0.12.0 release unchanged.  Session 39
disproved the "GC corrupts Var.realUnique" hypothesis;
remaining suspect was upstream duplicate-Var construction in
the TC/DS/Specialise/Iface pipeline.

**Status on exit:** CLEAN.  Probe40 reverted, stage1 rebuilt
clean, stage2 redeployed to pmacg5 + smoke-test PASS, baseline
tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged from
sessions 37-39).  **Major new finding:** at every
`refineFromInScope` panic, **seIdSubst is EMPTY (subst_size=0)**,
and seInScope has only init_in_scope's `{wild}` plus the
binders for the current function being descended into.  No
top-level binders, no substitutions.  This is the shape of a
freshly-created SimplEnv plus a tiny descent — but `mkSimplEnv`
is only called once per simplifier iteration, and its output
flows into `simplTopBinds` which populates seInScope with all
top-levels.  **New hypothesis:** GC corrupts the SimplEnv heap
closure's `seInScope` and `seIdSubst` pointer fields, resetting
them to fresh-env defaults somewhere during descent.  This is
consistent with sessions 28-29's heap-layout-sensitive
triggering and with probe38's PROBE38-SHRINK never firing
(which only catches Haskell-level set replacements via
`setInScope*` functions; a GC pointer rewrite bypasses those).
v0.12.0 release unchanged.

## Plan (per session 39 HANDOFF.md)

Trace where the duplicate Var is constructed.  Session 39
suggested probing the dictionary-emitting sites in HsToCore /
Tc/Solver / Specialise / Iface.  Session 40 started cheaper —
no source modification needed first:

1. Compile Big2.hs on PPC stage2 with `-A256m` + dump flags
   (clean compile) and on uranium host with `-A1m -G1` + dump
   flags.  Compare the Core.  If they differ structurally,
   the bug is in the pipeline stage.  If they're identical
   (modulo Unique renumbering), the bug is dynamic.
2. Look for `$dOrd_a1k0`-class duplicates in the dump.
3. Then design a probe based on what we learn.

## What happened

### Phase 1 — clean compile + Core diff

`-A1m -G1` panics.  `-A16m` (claimed by session 38 to compile
clean) also panics — **session 38's `-A16m clean` claim was an
artifact of `head -8` truncating the output**.  The real
clean-compile threshold is `-A256m`.

`-A256m` PPC vs uranium host `-A1m -G1` Core diff:

- With `-dsuppress-uniques`: **byte-identical** (only diff:
  trailing `RC=0` line from the PPC ssh-wrapper).
- Without `-dsuppress-uniques`: only Unique-suffix decorations
  differ (`_a1jI` vs `_a1jY` etc.) — slightly different
  Unique-supply state between platforms, NOT a structural bug.

So the input to the simplifier is correct.  The bug is dynamic
(at simplifier descent time).

### Phase 2 — locate the missing dictionary in clean Core

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

References top-level `$dFoldable_a1jY` and `$dOrd_a1k8` (the
Ord Int dictionary).  In the failing compile, the panic site's
missing var is `$dOrd_a1k0` — same OccName-prefix, different
Unique suffix.  These are different builds' Unique allocations
for the same logical Ord Int dictionary.

### Phase 3 — design probe40

Probe40 extends probe38's panic-site dump to also report
`seIdSubst`'s size and keys.  Hook: `substId` instead of
`refineFromInScope` directly, because `refineFromInScope`
doesn't have access to seIdSubst — it only receives an
InScopeSet.

At every `substId env v` where v's lookup in `seIdSubst` is
Nothing AND v is a local Id not in `seInScope` (the path that
fires `refineFromInScope` panic):

```
PROBE40-FAIL call=<N> v=<name>(0x<key>)
  scope_size=<S1> subst_size=<S2>
  scope_first20=[ <name>(0x<key>) ... ]
  subst_keys_first20=[ 0x<key> ... ]
```

Patch saved as `probe40-subst-fail.patch` (97 lines).

### Phase 4 — build + deploy + trigger

Build (~6m): EXIT=0.  Deploy (~6m): EXIT=0, smoke-test PASS.

len=850 trigger:

```
PROBE40-FAIL call=1 v=$dOrd(0x61001418) scope_size=6 subst_size=0
  scope_first20=[wild(0x30000000) k(0x61000e5c) m(0x61000e5d)
                 a(0x610013f6) $dOrd(0x610013f7) countOf(0x720004ce)]
  subst_keys_first20=[]
```

len=1650 trigger:

```
PROBE40-FAIL call=1 v=$dOrd(0x610013dc) scope_size=3 subst_size=0
  scope_first20=[wild(0x30000000) v(0x42000001) allPositive(0x720004d1)]
  subst_keys_first20=[]
```

len=700 trigger: `depSortStgBinds` panic family — different
codepath (STG, not simplifier), probe40 doesn't fire.

### Phase 5 — interpret

**Key signature:** subst_size=0 consistently.

The env at the panic site looks freshly created.  `mkSimplEnv`
returns:
- seInScope = {wild_00}
- seIdSubst = emptyVarEnv
- seTvSubst = emptyVarEnv
- seCvSubst = emptyVarEnv

Observed at panic:
- seInScope = {wild_00, k, m, a, $dOrd, countOf} (size 6 at
  len=850) or {wild_00, v_B1, allPositive} (size 3 at
  len=1650) — init_in_scope + only the current function's
  binders.
- seIdSubst = empty.

This shape ≡ mkSimplEnv output + a tiny descent.  But
`mkSimplEnv` is called only once per simplifier iteration in
`Pipeline.hs:734`, and its output flows into `simplTopBinds`
which populates seInScope with ALL top-level binders via
`simplRecBndrs`.

So the panic-site env doesn't match what simplTopBinds' env1
would look like.  Two possibilities:

- (a) **GC corruption** rewrote the SimplEnv's seInScope and
  seIdSubst pointer fields to point at fresh-env defaults.
- (b) The simplifier has an internal path that constructs a
  fresh env on the fly (not via mkSimplEnv) and descends into
  function bodies with it.

(a) is consistent with all session 28-29 findings (heap-
layout-sensitive, GC-frequency-dependent).
(b) is implementation-specific; requires codebase audit.

### Phase 6 — revert + clean rebuild + redeploy + baseline

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` —
  probe reverted.
* Stage1 clean rebuild (~6m): `logs/build2-clean.log`, EXIT=0.
* Stage2 redeploy: `logs/deploy2-clean.log`, EXIT=0,
  smoke-test PASS.
* Baseline tests: `logs/baseline-tests-end.log` —
  _TBD pending in-flight verification_.

Session ends CLEAN.

## Files added this session

* `README.md` (this), [`log.md`](log.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`commits.md`](commits.md).
* `probe40-subst-fail.patch` — substId Nothing-branch dump.
* `logs/ppc-stage2-A16m-dumps.log` — failed -A16m attempt.
* `logs/ppc-A256m-dumps.log`, `logs/ppc-A256m-uniques.log` —
  clean PPC compile dumps (with and without suppress-uniques).
* `logs/host-A1m-G1-dumps.log`, `logs/host-A1m-uniques.log` —
  uranium host clean compile dumps.
* `logs/ppc-A1m-fail-verbose.log` — failing compile with
  `-dverbose-core2core` (now shifted to `swap-tc` panic
  family due to dump-flag-induced heap shift).
* `logs/build1-probe40.log`, `logs/deploy1-probe40.log` —
  probe40 build + deploy.
* `logs/panic-trigger-len850.log`, `len1650.log`, `len700.log`
  — probe40 triggers.
* `logs/build2-clean.log`, `logs/deploy2-clean.log` —
  post-revert rebuild + redeploy.
* `logs/baseline-tests-end.log` — baseline.

## Top finding to carry into session 41

**seIdSubst is empty at every refineFromInScope panic.**  The
SimplEnv at the panic site looks freshly created — only
init_in_scope's wild plus the current function's binders.  Yet
the simplifier reached this point from inside a function body,
which should have inherited the env that simplTopBinds'
simplRecBndrs populated with ALL top-level binders.

New hypothesis: **GC corrupts the SimplEnv heap closure's
seInScope and seIdSubst pointer fields, resetting them to
fresh-env defaults somewhere during descent.**

See [`findings.md`](findings.md) §F4-F6 for the interpretation,
candidate next-experiments, and §F8 for what probe40 ruled
in/out, and [`HANDOFF.md`](HANDOFF.md) for the pickup primer.
