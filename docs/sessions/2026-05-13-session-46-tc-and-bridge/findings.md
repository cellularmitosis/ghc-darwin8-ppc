# Session 46 findings — corruption is AT or BEFORE the typechecker exit

## TL;DR

Probe46 hooks 3 points in `compiler/GHC/Driver/Main.hs`:

1. `hsc_typecheck_exit` — just before `hsc_typecheck` returns
   `(tc_result, rn_info)`.
2. `hscDesugar_entry` — in `hscDesugar`'s body (the wrapper).
3. `hscDesugarPrime_entry` — in `hscDesugar'`'s body (the
   actual desugarer driver).

All log `lengthBag (tcg_binds tc_env)`.

### Results

| env-len | hsc_typecheck_exit | hscDesugar'_entry | outcome |
|---------|---------------------|-------------------|---------|
| clean   | 9                   | 9                 | proper  |
| 600     | **3**               | 3                 | panic   |
| 1650    | **5**               | 5                 | panic   |

### Observations

1. **The typechecker's output is already truncated.** At
   `hsc_typecheck_exit` (the LAST line before
   `return (tc_result, rn_info)`), `tcg_binds` is 3 or 5
   instead of 9 in failing runs.
2. **The bridge code preserves the count.**
   `hscDesugar'_entry` shows the same count as
   `hsc_typecheck_exit`.  No corruption in Driver.Main bridge
   code.
3. **`hscDesugar_entry` never fires.** Big2.hs's compile path
   doesn't call `hscDesugar` (which wraps `hscDesugar'`); it
   calls `hscDesugar'` directly through a different path
   (probably `hscIncrementalCompile`).

The corruption is **AT or BEFORE** `hsc_typecheck`'s return,
which means it's in:

- `tcRnModule'` — the actual typechecker call.
- `extract_renamed_stuff` (unlikely; it doesn't modify
  `tc_result`).
- Or GC corruption of the heap-allocated `Bag (LHsBindLR
  GhcTc GhcTc)` DURING typechecking.

## F1. Probe46 design

In `compiler/GHC/Driver/Main.hs`:

- Added `tcg_binds` import from `GHC.Tc.Types`.
- Added `hPutStrLn, stderr, hFlush` from `System.IO` and
  `unsafePerformIO` from `System.IO.Unsafe`.
- Defined helper `probe46LogTcgBinds :: String -> TcGblEnv -> ()`
  that logs `lengthBag (tcg_binds tc_env)`.
- Added hook calls at three sites.

Patch: `probe46-tc-bridge.patch` (68 lines).

## F2. The locus narrowing

Pipeline-wide localization across sessions 42-46:

| Session | Hook point                       | Count clean / failing |
|---------|----------------------------------|-----------------------|
| 42      | simplTopBinds entry              | 9 / 0-1               |
| 43      | core2core entry                  | 9 / 1-3               |
| 44      | deSugar final_prs                | 9 / 3-6               |
| 45      | deSugar tcg_binds (entry)        | 9 / 3-6               |
| **46**  | **hsc_typecheck exit**           | **9 / 3-5**           |

The count drops from clean's 9 to failing's 3-5 at
hsc_typecheck_exit.  All subsequent points preserve this count.

The corruption happens IN the typechecker (or in GC during
typechecking).

## F3. What's inside hsc_typecheck

```haskell
hsc_typecheck keep_rn mod_summary mb_rdr_module = do
    ...
    tc_result <- if hsc_src == HsigFile && not (isHoleModule inner_mod)
        then ioMsgMaybe $ tcRnInstantiateSignature ...
        else
         do hpm <- ...
            tc_result0 <- tcRnModule' mod_summary keep_rn' hpm
            if hsc_src == HsigFile
                then ... tcRnMergeSignatures hsc_env hpm tc_result0 iface
                else return tc_result0
    rn_info <- extract_renamed_stuff mod_summary tc_result
    return (tc_result, rn_info)
```

For Big2.hs (a normal `.hs` file, not `.hsig`), the path is:
- `hpm <- hscParse' mod_summary` (parser).
- `tc_result0 <- tcRnModule' mod_summary keep_rn' hpm` (renamer + typechecker).
- `tc_result = tc_result0`.

So the suspect is `tcRnModule'` (which calls `tcRnModule`).

## F4. tcRnModule and tcg_binds construction

`tcRnModule` is the renamer + typechecker entry.  Its
implementation is in `GHC/Tc/Module.hs`.  The `tcg_binds`
field of `TcGblEnv` is populated during typechecking.

If `tcRnModule` returns `tc_result` with `tcg_binds = 3
elements` (in failing runs), then EITHER:

- (a) The typechecker actually emitted only 3 binders
  (compiler bug, unlikely for Big2.hs's straightforward code).
- (b) `tcg_binds` was correctly 9 inside `tcRnModule` but
  corrupted by GC before `hsc_typecheck` reads it.

Hypothesis (b) is most consistent with the heap-layout-
sensitivity from sessions 28-45.  The `Bag` is a heap-
allocated structure with `TwoBags` cons cells (CONSTR_2_0).
If GC corrupts these between when the typechecker constructs
them and when downstream code reads them, the Bag's effective
length shrinks.

## F5. Concrete next-session targets

1. **Hook the typechecker's tcRnModule output.**  Find where
   `tc_result` is constructed in `GHC.Tc.Module` and add a
   probe at its return point.  If clean=9 and failing=3-5
   there, the truncation is within `tcRnModule` or earlier.
2. **Hook tcRnSrcDecls / tcRnModule entry points.**  These are
   the lower-level typechecker entry points.  Trace
   `tcg_binds` through them.
3. **Pin the TcGblEnv in IORef at typechecker construction.**
   Walk its length at later checkpoints to detect GC-in-
   transit corruption.
4. **Add GC instrumentation: `+RTS -DG -RTS` (verbose GC
   logs).**  Capture GC runs between typechecker construction
   and `hsc_typecheck` exit.  Correlate with the truncation.

## F6. Connection to all prior sessions

The chain from sessions 28-46:

```
typechecker (tcRnModule)                       — produces tcg_binds = ? (this is where we are now)
  ↓
hsc_typecheck exit                             — 3-5 in failing runs (S46)
  ↓
hscDesugar' entry                              — same 3-5 (S46)
  ↓
deSugar tcg_binds (entry)                      — same 3-5 (S45)
  ↓
desugarer internal steps                       — all preserve count (S45)
  ↓
deSugar final_prs                              — same 3-5 (S44 — slight DCE difference)
  ↓
simpleOptPgm                                   — drops further (legitimate DCE on broken input)
  ↓
core2core entry                                — 1-3 (S43)
  ↓
runCorePasses → Simplifier passes              — preserves or DCEs
  ↓
simplTopBinds (eventually)                     — 0-1 (S42)
  ↓
codegen → empty/incomplete .o file
```

All "X is corrupted" hypotheses from earlier sessions are
downstream symptoms of: **GC truncates the heap-allocated
`Bag (LHsBindLR GhcTc GhcTc)` during typechecking on PPC32
unreg.**

## F7. The CONSTR_2_0 connection

Both `[InBind]` cons cells AND `Bag.TwoBags` are CONSTR_2_0
closures (2 pointer fields).  The same GC bug affects both:
when the typechecker assembles the Bag, GC's evac/scav on
PPC32 unreg corrupts TwoBags pointers, truncating the Bag.

## F8. What probe46 directly ruled in

**Confirmed:**

- `hsc_typecheck`'s `tc_result.tcg_binds` is already 3-5 in
  failing runs vs 9 in clean.
- Driver.Main's bridge code between `hsc_typecheck` exit and
  `hscDesugar'` entry preserves the count.
- The corruption is AT or BEFORE `hsc_typecheck`'s return.

**Ruled out:**

- Corruption in Driver.Main's pipeline-bridging code.

**Next localization needed:**

- Within `tcRnModule` / `tcRnModule'` (the typechecker
  proper).
