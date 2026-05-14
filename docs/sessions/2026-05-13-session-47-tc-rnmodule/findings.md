# Session 47 findings — **Smoking gun: corruption is INSIDE `tcRnSrcDecls`**

## TL;DR

Probe47 hooks 4 points in `compiler/GHC/Tc/Module.hs::tcRnModuleTcRnM`:

1. `after_tcRnImports` — after the imports are processed.
2. `after_tcRnSrcDecls` — after the main typechecker pass.
3. `after_checkHiBootIface` — after boot iface checking.
4. `tcRnModuleTcRnM_exit` — last step before return.

All log `lengthBag (tcg_binds tc_env)`.

### Results

| env-len | after_tcRnImports | after_tcRnSrcDecls | after_checkHiBootIface | exit | RC |
|---------|-------------------|-------------------|------------------------|------|----|
| clean   | 0                 | **9**             | 9                      | 9    | 0  |
| 600     | 0                 | **5**             | 5                      | 5    | 1 panic |
| 1650    | 0                 | **2**             | 2                      | 2    | 0  |

### Localization

- `after_tcRnImports` is always 0 (imports don't add to tcg_binds).
- `after_tcRnSrcDecls` is where tcg_binds transitions from 0 to
  N.  Clean: 9.  Failing: 2-5.
- `after_checkHiBootIface` and `exit` preserve the count.

**The truncation is INSIDE `tcRnSrcDecls`** — the main
typechecker pass that processes the module's source
declarations and populates `tcg_binds`.

## F1. Probe47 design

In `compiler/GHC/Tc/Module.hs`:

- Helper `probe47Log :: String -> TcGblEnv -> ()` inline.
- 4 hook calls inside `tcRnModuleTcRnM` at strategic points.

v1 hooked only `tcRnModuleTcRnM_exit` — confirmed tcg_binds
already truncated there.
v2 added `after_tcRnImports`, `after_tcRnSrcDecls`,
`after_checkHiBootIface` to narrow.

Patch: `probe47-tc-rnmodule.patch` (67 lines).

## F2. The locus: tcRnSrcDecls

`tcRnSrcDecls explicit_mod_hdr export_ies local_decls` is
called at line 336 of `GHC.Tc.Module`:

```haskell
else {-# SCC "tcRnSrcDecls" #-}
     tcRnSrcDecls explicit_mod_hdr export_ies local_decls
```

This function:
1. Runs the renamer + typechecker on local declarations.
2. Builds `tcg_binds` from typechecked binders.
3. Returns the populated `TcGblEnv`.

The function itself is defined around line 461.  It has many
internal steps (`tc_rn_src_decls`, `simplifyTop`, etc).

## F3. Heap-layout sensitivity continues

In session 47:
- len=600: `tcRnSrcDecls` produces 5 (was 3 in session 46;
  probe code shifted heap).
- len=1650: `tcRnSrcDecls` produces 2 (was 5 in session 46).

Heap-layout sensitivity remains, but the qualitative pattern is
consistent: clean produces 9, failing produces <9.

## F4. RC=0 at len=1650 with 2 binders — silent miscompile

`len=1650` shows `RC=0` with only 2 binders.  That's a silent
miscompile — the compile "succeeded" but produced near-empty
output.  Pattern matches session 42's silent miscompiles at
env-lens 850-1000 with 0 binders.

## F5. Pipeline progress chain (sessions 42-47)

| Session | Hook point                | Count clean / failing |
|---------|---------------------------|-----------------------|
| 42      | simplTopBinds entry       | 9 / 0-1               |
| 43      | core2core entry           | 9 / 1-3               |
| 44      | deSugar final_prs         | 9 / 3-6               |
| 45      | deSugar tcg_binds (entry) | 9 / 3-6               |
| 46      | hsc_typecheck exit        | 9 / 3-5               |
| **47**  | **tcRnSrcDecls output**   | **9 / 2-5**           |

The corruption is now narrowed to **WITHIN `tcRnSrcDecls`**.
`tcRnSrcDecls` is the main typechecker pass; it has many
internal steps.

## F6. Concrete next-session targets

1. **Hook inside `tcRnSrcDecls`.**  Find its return point and
   the major internal steps (`tc_rn_src_decls`, `simplifyTop`,
   `zonkTopDecls`, etc).  Add hooks to narrow further.
2. **Hook `tc_rn_src_decls`'s return** specifically — this is
   where typechecking actually populates tcg_binds.
3. **Hook the final zonking step (`zonkTopDecls`)** — zonking
   walks the entire Core tree to substitute metavariables; it's
   a heavy traversal that GC could interrupt at unpredictable
   points.
4. **Pin tcg_binds INSIDE tcRnSrcDecls at multiple
   checkpoints.**  Walk a stored reference's length to catch
   GC truncation in real time.
5. **File a GHC bug report.**  We now have conclusive evidence
   that GC corruption in PPC32 unreg affects compilation of
   small Haskell programs.

## F7. What probe47 directly ruled in

**Confirmed:**

- `tcRnImports` does NOT contribute to tcg_binds (count is 0
  after it in all runs).
- `tcRnSrcDecls` is where tcg_binds is built up.  Clean: 9.
  Failing: 2-5.
- Subsequent steps (`checkHiBootIface`, plugin/dump) preserve
  the count.

**Ruled out:**

- Corruption in `checkHiBootIface` or later — they preserve
  the count.

**Next localization needed:**

- WITHIN `tcRnSrcDecls`'s body.  Many sub-steps to probe:
  `tc_rn_src_decls`, `simplifyTop`, `zonkTopDecls`,
  `finalizeRn`, `rnExports`, etc.
