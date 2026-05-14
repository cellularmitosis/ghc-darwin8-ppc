# Session 48 findings — **Smoking gun: corruption is INSIDE `tcTopBinds val_binds val_sigs`**

## TL;DR

Probe48-v3 hooks 10 points across `tcRnSrcDecls`,
`tc_rn_src_decls`, and `tcTopSrcDecls` in
`compiler/GHC/Tc/Module.hs`.  All log
`lengthBag (tcg_binds tc_env)` (or `lengthBag binds` for the
hooks that hold the binds list directly).

### Results (full 10-hook trace)

| evt | site                                | clean | len=600 | len=1650 |
|-----|--------------------------------------|-------|---------|----------|
| 1   | `after_rnTopSrcDecls`                | 0     | 0       | 0        |
| 2   | `after_tcTyClsInstDecls`             | 0     | 0       | 0        |
| 3   | **`after_tcTopBinds_val_binds`**     | **8** | **2**   | **3**    |
| 4   | `after_tcTopBinds_deriv_binds`       | 8     | 2       | 3        |
| 5   | `after_tcTopSrcDecls`                | 8     | 2       | 3        |
| 6   | `after_tc_rn_src_decls`              | 8     | 2       | 3        |
| 7   | `after_mkTypeableBinds`              | 9     | 3       | 4        |
| 8   | `after_zonkTcGblEnv_binds_prime`     | 9     | 3       | 4        |
| 9   | `tcg_env_prime_final`                | 9     | 3       | 4        |
| 10  | `binds_mf_after_zonk_main`           | 0     | 0       | 0        |

All three failing runs `RC=0` (silent miscompile).
`binds_mf_after_zonk_main` is 0 in all runs because it
measures the *split-module* binds that the test module
doesn't produce.

### Localization

- `after_rnTopSrcDecls` is always 0 — the renamer doesn't add
  to `tcg_binds`.
- `after_tcTyClsInstDecls` is always 0 — this step handles
  type/class/instance decls; no plain value bindings.
- **`after_tcTopBinds_val_binds` is 8 in clean but 2/3 in
  failing.**  The count is built up from 0 → N here.
- `after_tcTopBinds_deriv_binds` is unchanged from
  `_val_binds` — `Big2.hs` has no derived bindings.
- `after_tcTopSrcDecls`, `after_tc_rn_src_decls`,
  `binds_mf_after_zonk_main` all preserve the count.
- `mkTypeableBinds` adds exactly 1 (the module's `$trModule`),
  giving the familiar +1 step at evt=7.

**The truncation is INSIDE `tcTopBinds val_binds val_sigs`** —
the function `GHC.Tc.Gen.Bind.tcTopBinds` that typechecks the
module's top-level value bindings.

## F1. Probe48 design — three iterations

In `compiler/GHC/Tc/Module.hs`:

- Helper `probe47Log :: String -> TcGblEnv -> ()` (reused name
  from session 47 — single `IORef` counter, unsafePerformIO,
  hPutStrLn stderr).
- Helper `probe48LogBinds :: String -> LHsBinds GhcTc -> ()`
  for the cases where we have the binds list directly, not via
  a `TcGblEnv`.

**v1** (1 hook): just `after_tc_rn_src_decls`.  Confirmed
truncation already complete at the top of `tcRnSrcDecls`'s
body.

**v2** (3 more hooks): `after_mkTypeableBinds`,
`after_zonkTcGblEnv_binds_prime`, `tcg_env_prime_final`,
`binds_mf_after_zonk_main`.  Showed all downstream steps
preserve the count.

**v2.5** (2 hooks added inside `tc_rn_src_decls`):
`after_rnTopSrcDecls`, `after_tcTopSrcDecls`.  Narrowed to
`tcTopSrcDecls`.

**v3** (3 hooks added inside `tcTopSrcDecls`):
`after_tcTyClsInstDecls`, `after_tcTopBinds_val_binds`,
`after_tcTopBinds_deriv_binds`.  Pinpointed
`tcTopBinds val_binds val_sigs`.

Patch: `probe48-tcRnSrcDecls.patch` (cumulative v3; 10 hooks).

## F2. The locus: `tcTopBinds val_binds val_sigs`

`tcTopSrcDecls` is defined in
`compiler/GHC/Tc/Module.hs` around line 1457.  Its body
typechecks each component of the source `HsGroup`:

```haskell
tcTopSrcDecls (HsGroup { hs_tyclds = tycl_decls,
                          hs_derivds = deriv_decls,
                          hs_fords  = foreign_decls,
                          hs_defds  = default_decls,
                          hs_annds  = annotation_decls,
                          hs_ruleds = rule_decls,
                          hs_valds  = hs_val_binds@(XValBindsLR (NValBinds val_binds val_sigs)) })
 = do {
        ...

        (tcg_env, inst_infos, XValBindsLR (NValBinds deriv_binds deriv_sigs))
            <- tcTyClsInstDecls tycl_decls deriv_decls val_binds ;

        setGblEnv tcg_env       $ do {
            ...

            tc_envs <- tcTopBinds val_binds val_sigs ;   -- ← THE TRUNCATING CALL
            setEnvs tc_envs $ do {
                ...

                tc_envs@(tcg_env, tcl_env)
                    <- discardWarnings (tcTopBinds deriv_binds deriv_sigs) ;
                setEnvs tc_envs $ do {
                    ...
                } } } }
```

`tcTopBinds` is defined in `compiler/GHC/Tc/Gen/Bind.hs`.  It
takes:
- `val_binds :: [(RecFlag, LHsBinds GhcRn)]` — the value
  bindings grouped by recursion structure.
- `val_sigs :: [LSig GhcRn]` — the type signatures.

…and returns a `(TcGblEnv, TcLclEnv)` where `tcg_binds` has
been populated with the typechecked binders.

`tcTopBinds` walks each group, typechecks the binders inside,
extends `tcg_binds`, and recurses.  **Somewhere in that
recursion, GC corrupts the in-progress bag and the recursion
short-counts.**

## F3. Heap-layout sensitivity continues

In session 48:
- len=600: 2 binders (was 5 in session 47, was 3 in session
  46, was 1 in session 42's `simplTopBinds` view).
- len=1650: 3 binders (was 2 in session 47).

Heap-layout sensitivity remains, but the qualitative pattern
holds: clean produces 8, failing produces 2-3 — both well
below the clean count.

## F4. RC=0 with 2-3 binders is a silent miscompile

len=600 and len=1650 both produce `RC=0` despite having only
2-3 binders out of the source's 8.  That's a silent
miscompile: the compiler "succeeds" but emits an object file
with most of the value bindings missing.  Programs that link
against `Big2.hs` would find symbols absent at link time, or
worse, get wrong code at runtime.

## F5. Pipeline progress chain (sessions 42-48)

| Session | Hook point                  | Count clean / failing       |
|---------|-----------------------------|------------------------------|
| 42      | `simplTopBinds` entry       | 9 / 0-1                      |
| 43      | `core2core` entry           | 9 / 1-3                      |
| 44      | `deSugar` `final_prs`       | 9 / 3-6                      |
| 45      | `deSugar` `tcg_binds` entry | 9 / 3-6                      |
| 46      | `hsc_typecheck` exit        | 9 / 3-5                      |
| 47      | `tcRnSrcDecls` output       | 9 / 2-5                      |
| **48**  | **`tcTopBinds val_binds val_sigs` output** | **8 / 2-3** (+1 from `mkTypeableBinds` → 9 / 3-4) |

The corruption is now narrowed to **WITHIN `tcTopBinds`** in
`GHC.Tc.Gen.Bind`.

## F6. Why `tcTopBinds` and not `tcTyClsInstDecls`?

`tcTyClsInstDecls` produces 0 binders in both clean and
failing.  That's because it handles type/class/instance decls,
not value bindings.  Most of `Big2.hs`'s declarations are
plain `f :: ... ; f x = ...` value bindings (no classes, no
instances).  So `tcTopBinds val_binds val_sigs` is the step
that converts those plain definitions into typechecked
binders — and that's the step the GC corruption interferes
with.

If we had a test module with many class/instance declarations,
the `tcTyClsInstDecls` step might also be affected — but for
`Big2.hs` we can definitively localize to `tcTopBinds`.

## F7. The "+1 from mkTypeableBinds" pattern

Every measurement shows the count goes UP by exactly 1 at the
`after_mkTypeableBinds` hook.  That's expected:
`mkTypeableBinds` synthesizes the `Module`'s Typeable instance
binding (typically `$trModule`).  This adds exactly one binder
regardless of source size.

This is also why session 46-47's "9" count is "8" in session
48: in earlier sessions the hook was after `mkTypeableBinds`
ran, in session 48 we have a hook BEFORE it
(`after_tcTopBinds_val_binds`).  The source `Big2.hs` defines
8 functions; +1 from `$trModule` = 9.

## F8. Concrete next-session targets

1. **Drill `tcTopBinds`** in `compiler/GHC/Tc/Gen/Bind.hs`.
   Add hooks inside its loop / recursion.  `tcTopBinds`
   eventually calls `tcValBinds`, `tcBindGroups`, etc.
2. **Pin a `tcg_binds` IORef snapshot at multiple checkpoints
   inside `tcTopBinds`** to catch the moment GC truncates the
   bag.
3. **Add a per-binder log** in `tcTopBinds` (one PROBE line
   per binder typechecked).  If we see "binders 1, 2, 3, ...
   8" in clean and "binders 1, 2, 3" in failing, that tells us
   the recursion is short-circuiting.  If we see all 8 in
   both and the COUNT drops only at the end, the bag is being
   truncated wholesale by GC.
4. **File a GHC bug report.**  We now have very tight
   localization.  Submit upstream as "PPC32-unreg GC corrupts
   binders bag during typechecking; reproducible at small
   source sizes with `-A1m -G1`."
5. **(Optional) Try `-A2m` or `-A4m`** on the failing case to
   confirm the heap pressure pattern.  This is reproducible at
   `-A1m -G1` but not `-A256m`; mid-sized allocation areas
   should let us bracket the pressure threshold.

## F9. What probe48 directly ruled in

**Confirmed:**

- `rnTopSrcDecls` (the renamer) does NOT populate tcg_binds
  (count is 0 after it).
- `tcTyClsInstDecls` does NOT populate tcg_binds for Big2.hs
  (no class/instance decls).
- **`tcTopBinds val_binds val_sigs`** is the step where
  tcg_binds becomes N.  Clean: 8.  Failing: 2-3.
- All subsequent steps preserve the count.
- `mkTypeableBinds` adds exactly 1 (the `$trModule`).

**Ruled out:**

- Corruption in any step AFTER `tcTopBinds val_binds val_sigs`
  — they all preserve the count.
- Corruption in `rnTopSrcDecls` or `tcTyClsInstDecls` — they
  produce 0 binders in both clean and failing.

**Next localization needed:**

- WITHIN `tcTopBinds`'s body in `compiler/GHC/Tc/Gen/Bind.hs`.
  This is where individual value bindings are typechecked and
  added to the in-progress bag.
