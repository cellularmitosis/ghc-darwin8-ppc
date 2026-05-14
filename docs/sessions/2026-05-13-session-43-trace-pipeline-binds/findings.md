# Session 43 findings — corruption is BEFORE `core2core` entry; the truncated `[InBind]` arrives at the optimizer pipeline already broken

## TL;DR

Probe43 hooks two points in `Pipeline.hs`:

1. **`core2core` entry** (just after `ModGuts` is received from
   the caller — typically HscMain after the desugarer).
2. **`runCorePasses`** — initial mg_binds length AND each
   pass's before/after lengths.

In failing runs, `mg_binds` is **ALREADY truncated at
`core2core` entry**.  The corruption happens BEFORE any Core
pipeline pass runs.

### probe43-v2 sweep with `-A1m -G1`

| env-len | core2core entry | runCorePasses entry | Simplifier pass        | RC | outcome           |
|---------|-----------------|---------------------|------------------------|----|--------------------|
| clean (-A256m) | 9         | 9                   | 9 → 13                 | 0  | proper compile     |
| 600     | **1**           | **1**               | (panic before simplify)| 1  | refineFromInScope panic |
| 850     | **2**           | **2**               | 2 → 5, then panic      | 1  | refineFromInScope panic |
| 1650    | **2**           | **2**               | **2 → 0 *** DROPPED**  | 0  | SILENT MISCOMPILE  |

### The bug is upstream of core2core

In every failing run, the count at `core2core`'s entry **equals**
the count at `runCorePasses`'s entry (no drop in between).  But
it's already 1-3 (vs clean's 9).

So the truncation happens **before the optimizer pipeline starts**
— in the desugarer's output, in HscMain's handling of ModGuts
between the desugarer and core2core, or in GC while ModGuts is
sitting in memory between those phases.

### Additional finding: the Simplifier itself can drop binds

At len=1650, the Simplifier received 2 binders and produced 0
(`*** DROPPED`).  This is a SEPARATE corruption point — even
when the input is already truncated, the simplifier itself can
further drop binders during its iteration.

Whether this is a legitimate dead-code-elimination (where the
simplifier decides 2 binders are dead because nothing references
them — plausible because the rest of mg_binds is gone and may
have been the consumer) OR a second instance of the GC list-
truncation, is unclear.  Probably the former: with most
top-level binders missing from binds0, the surviving ones look
unreferenced and get DCE'd.

## F1. Probe43 design

In `Simplify/Env.hs`: helpers exported for use from `Pipeline.hs`:

- `probe43LogCore2CoreEntry :: Int -> ()` — logs at core2core
  entry.
- `probe43LogInitial :: Int -> ()` — logs at runCorePasses entry.
- `probe43LogPass :: String -> Int -> Int -> ()` — logs before
  and after each Core pipeline pass.

In `Pipeline.hs::core2core`:

```haskell
do { let !_probe43_c2c = probe43LogCore2CoreEntry (length (mg_binds guts))
   ; ...
```

In `Pipeline.hs::runCorePasses`:

```haskell
runCorePasses passes guts
  = let !_probe43 = probe43LogInitial (length (mg_binds guts))
    in foldM do_pass guts passes
  where
    do_pass guts CoreDoNothing = ...
    do_pass guts pass = do
      ...
      let !n_before = length (mg_binds guts)
      guts' <- ... doCorePass pass guts
      let !n_after = length (mg_binds guts')
          !_probe43 = probe43LogPass pname n_before n_after
      ...
```

## F2. Probe43-v1 vs v2 results

**v1** (only INITIAL + PASS, no CORE2CORE hook):

| env-len | INITIAL | PASS | outcome |
|---------|---------|------|---------|
| clean   | 9       | 9 → 13 | proper |
| 600     | 1       | -    | panic |
| 850     | 1       | 1 → 5 | panic |
| 1650    | 3       | -    | panic |

**v2** (added CORE2CORE hook):

| env-len | CORE2CORE | INITIAL | PASS | outcome |
|---------|-----------|---------|------|---------|
| clean   | 9         | 9       | 9 → 13 | proper |
| 600     | 1         | 1       | -    | panic |
| 850     | 2         | 2       | 2 → 5 | panic |
| 1650    | 2         | 2       | **2 → 0 DROPPED** | silent miscompile |

v2 confirms the corruption is **already present at core2core
entry** — there's no drop between CORE2CORE and INITIAL.

Note the heap-layout-sensitivity: lengths differ slightly between
v1 and v2 runs (probe code shifted the heap), but always small
(1-3 vs clean's 9).

## F3. -A1G baseline

`-A1G` (huge nursery → essentially no GC pressure) always
produces:

```
PROBE43-CORE2CORE evt=1 mg_binds=9
PROBE43-INITIAL evt=2 mg_binds=9
PROBE43-PASS evt=3 pass=Simplifier before=9 after=13
```

Confirms the bug is GC-pressure-induced.

## F4. The corruption locus

ModGuts flows roughly:

```
HsModule
  → renamer (TcGblEnv)
  → typechecker (TcGblEnv + ModGuts skeleton)
  → desugarer (HsToCore.deSugar) — produces ModGuts with mg_binds populated
  → ??? (any work between deSugar and core2core)
  → core2core(guts) — PROBE43-CORE2CORE here
  → runCorePasses — PROBE43-INITIAL here
  → Simplify pass — PROBE43-PASS here
  → ... more passes
  → CorePrep → CodeGen → .o output
```

probe43-v2 shows mg_binds=1-3 at the core2core hook, but clean
shows 9.  So the truncation happens in one of:

- (a) `HsToCore.deSugar` produces a truncated mg_binds in failing
  runs (the desugarer's output is wrong).
- (b) Code between deSugar and core2core (in HscMain) corrupts
  mg_binds.
- (c) GC corrupts the heap-allocated `[InBind]` while mg_binds
  is in memory between deSugar and core2core.

(c) is most consistent with the heap-layout-sensitivity.  The
[InBind] list is heap-allocated cons cells; if GC runs between
deSugar and core2core's entry and corrupts those cons cells,
core2core would see a truncated list without any explicit code
path modifying it.

## F5. The simplifier's 2 → 0 drop at len=1650

At len=1650, the simplifier received 2 binders and produced 0.
This could be:

- (i) Legitimate DCE: with most top-level binders missing, the
  surviving 2 are unreferenced and dead; the simplifier drops
  them.
- (ii) A second instance of the list-truncation bug — GC
  corrupting the binds list during the simplifier's run.

(i) is more plausible.  The simplifier's job includes removing
dead code.  Without the consumers (the missing 7+ binders), the
2 surviving binders look dead and get DCE'd.  This would
explain why probe42 (session 42) saw num=0 at simplTopBinds for
some env-lens — the simplifier had ALREADY done DCE on the
1-binder input from the prior iteration.

## F6. Concrete next-session targets

1. **Hook the desugarer's output.**  Add a probe at
   `HsToCore.deSugar`'s return point to dump
   `length (mg_binds guts)` right before ModGuts is passed back
   to HscMain.  If failing runs show count=9 there but 1-3 at
   core2core, the corruption is in HscMain (between deSugar
   and core2core).  If failing runs show count=1-3 at the
   desugarer's output, the corruption is in the desugarer
   itself OR earlier.

2. **Hook earlier still — typechecker output.**  If desugarer
   output is also truncated, hook the typechecker's
   `TcGblEnv` data construction.

3. **Pin mg_binds in IORef before deSugar returns and check
   length at core2core entry.**  This directly tests whether
   GC corrupts the heap-allocated list between these phases.
   If `length pinned` shrinks between pin point and check
   point, GC is corrupting heap-allocated cons cells in
   transit.

4. **Investigate `deSugarModule` in `HscMain.hs`.**  This is
   the bridge between the typechecker and core2core.  Audit
   what it does to `mg_binds`.

## F7. Severity update

The session-42 finding of silent miscompiles at -A1m -G1 is
**confirmed across multiple env-lens** by session 43.  At
len=1650 (with probe43-v2), ghc-real exits RC=0 producing
output despite the simplifier dropping binds 2 → 0.  This is
the second silent-miscompile env-len observed (session 42
found 850-1000; session 43 finds 1650 too).

The bug is **endemic** at low nursery sizes.  Real fix or
operational workaround (`+RTS -A1G -RTS`) required.

## F8. What probe43 directly ruled in

**Confirmed:**

- The truncation of `[InBind]` happens BEFORE `core2core`'s
  entry — at HscMain time or earlier (in the desugarer or
  typechecker, or during GC between phases).
- `-A1G` consistently produces 9 binders.
- Multiple env-lens produce silent miscompiles, not just panics.

**Implied:**

- The bug is most plausibly GC corrupting the heap-allocated
  `[InBind]` cons-list between the desugarer's output and
  `core2core`'s call — a time window during which mg_binds
  sits in memory while HscMain does various things.

## F9. Big picture

Combined with all prior sessions, the picture is now:

1. Desugarer produces ModGuts with full `[InBind]` (~9 binders).
2. **GC runs between desugarer and core2core** under
   `-A1m -G1` pressure.
3. **GC corrupts the heap-allocated `[InBind]` cons-list spine**,
   truncating it to 0-3 elements.
4. core2core receives the truncated mg_binds.
5. Simplifier processes the truncated list — sometimes panics
   (missing references → refineFromInScope failure), sometimes
   silently produces empty/incomplete output.

The "X is corrupted" hypotheses from earlier sessions are all
downstream symptoms of (3).

The root fix would be **in GHC's runtime GC** on PPC32 unreg —
specifically the evac/scav handling of CONSTR_2_0 closures
(cons cells with 2 pointer fields: head, tail).  Until then,
`-A1G` is the workaround.
