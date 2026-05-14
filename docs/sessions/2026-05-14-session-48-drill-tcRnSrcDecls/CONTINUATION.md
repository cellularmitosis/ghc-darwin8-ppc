# Session 48 — CONTINUATION HANDOFF (mid-session, not a new session)

**For:** the next claude conversation continuing session 48.
**From:** the in-flight session 48 — probe48-v3 is currently
deployed on pmacg5 and ready to trigger.  Context window of
the prior conversation was nearly full, so this handoff is
written to keep continuity within the SAME session dir
(`docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/`).

**Important:** continue writing to THIS dir.  Do NOT start a
session 49 dir.  When session 48's actual work is done, write
HANDOFF.md → session 49 in the normal way.

## Status snapshot at handoff

- **probe48-v3 is deployed** on pmacg5 (`b1zf2x3no` task
  completed).  The stage2 binary at `/opt/ghc-stage2/bin/ghc-real`
  has 6 hook points inside `tcRnSrcDecls` / `tcTopSrcDecls` /
  `tc_rn_src_decls`.
- Source tree: ghc-9.2.8 has probe48-v3 applied; patch is
  `probe48-tcRnSrcDecls.patch` in this dir.
- v0.12.0 release unchanged.

## What probe48-v3 already revealed (v2 run, before v3 hooks added)

Probe48-v2 (4 hooks inside tcRnSrcDecls — `tc_rn_src_decls`,
`mkTypeableBinds`, `zonkTcGblEnv binds'`, `tcg_env'_final`):

| env-len | tc_rn_src_decls | mkTypeable | zonk binds' | tcg_env'_final |
|---------|-----------------|------------|-------------|----------------|
| clean   | **8**           | 9          | 9           | 9              |
| 600     | **2**           | 3          | 3           | 3              |
| 1650    | **2**           | 3          | 3           | 3              |

`tc_rn_src_decls` itself produces 2-8 binders; mkTypeableBinds
adds exactly 1 (the `Big2.$trModule`).  All downstream steps
preserve count.

Then v2.5 (added `after_rnTopSrcDecls`, `after_tcTopSrcDecls`):

| env-len | rnTopSrcDecls | tcTopSrcDecls | tc_rn_src_decls |
|---------|---------------|---------------|------------------|
| clean   | 0             | **8**         | 8                |
| 600     | 0             | **2**         | 2                |
| 1650    | 0             | **2**         | 2                |

`rnTopSrcDecls` (renamer) produces 0 binders.
**`tcTopSrcDecls` (typechecker) is where binders count becomes 2/8.**

## What probe48-v3 should now reveal

v3 adds 3 hooks INSIDE `tcTopSrcDecls`:
- `after_tcTyClsInstDecls`
- `after_tcTopBinds_val_binds`
- `after_tcTopBinds_deriv_binds`

These will localize whether the truncation happens in:
- `tcTyClsInstDecls` (class/instance/derive)
- `tcTopBinds val_binds val_sigs` (main value-binding typecheck — most likely)
- `tcTopBinds deriv_binds deriv_sigs` (derived bindings)
- Or LATER in tcTopSrcDecls (tcInstDecls2 / tcForeignExports / tcg_env' construction)

## Resume from here

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# probe48-v3 is already deployed on pmacg5.  Re-confirm:
ssh pmacg5 "ls -la /opt/ghc-stage2/bin/ghc-real"
# (should show today's mtime)

# Trigger and observe:
echo "=== clean (-A256m) ==="
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A256m -RTS 2>&1; echo RC=\$?" \
  | grep -E "PROBE48|RC="

echo "=== failing len=600 ==="
pad=$(awk 'BEGIN{for(i=1;i<=598;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; echo RC=\$?" \
  | grep -E "PROBE48|panic|RC="

echo "=== failing len=1650 ==="
pad=$(awk 'BEGIN{for(i=1;i<=1648;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; echo RC=\$?" \
  | grep -E "PROBE48|panic|RC="
```

Save the output as `logs/v3-triggers.log`.

## Interpretation guide for v3 output

Expected new lines (in evt= order):
- `after_rnTopSrcDecls n=0` (constant)
- `after_tcTyClsInstDecls n=?` ← NEW
- `after_tcTopBinds_val_binds n=?` ← NEW
- `after_tcTopBinds_deriv_binds n=?` ← NEW
- `after_tcTopSrcDecls n=?`
- `after_tc_rn_src_decls n=?`
- `after_mkTypeableBinds n=?`
- `after_zonkTcGblEnv_binds_prime n=?`
- `tcg_env_prime_final n=?`
- `binds_mf_after_zonk_main n=0` (constant)

Decision tree:
- **If `after_tcTopBinds_val_binds` is 8 in clean but 2 in failing**:
  the truncation is INSIDE `tcTopBinds` (which is in
  `GHC.Tc.Gen.Bind`).  Next session probe48-v4 drills there.
- **If `after_tcTopBinds_val_binds` is 8 in BOTH clean and failing**
  but `after_tcTopSrcDecls` is 8 in clean and 2 in failing:
  the truncation is in `tcInstDecls2`/`tcForeignExports`/etc
  (steps AFTER `tcTopBinds`).  Drill those.
- **If `after_tcTyClsInstDecls` is 0 in both** (likely — it
  handles type/class/instance decls, not value bindings), the
  initial count starts at 0 and `tcTopBinds val_binds` builds
  it up.  Look at val_binds value count.

## After analysis: clean-exit checklist

1. Revert probe48 (all 3 versions are in
   `compiler/GHC/Tc/Module.hs`):
   ```
   cd external/ghc-modern/ghc-9.2.8
   git checkout -- compiler/GHC/Tc/Module.hs
   ```
2. Clean rebuild stage1, redeploy stage2, smoke-test PASS,
   baseline tests.
3. Write the regular session 48 docs:
   - `README.md` — full narrative with v1/v2/v3 data tables.
   - `findings.md` — `tcTopBinds` localization (or wherever
     v3 points).
   - `log.md` — real-time log.
   - `HANDOFF.md` — recommended pickup for session 49.
   - `commits.md` — commit message (TBD SHA).
4. Update `docs/state.md` (round 30) and `docs/roadmap.md`.
5. Commit twice: session 48 body, then SHA backfill.

## Files already in this dir

- `probe48-tcRnSrcDecls.patch` — current v3 patch with 6 hook
  sites (latest version, includes v1+v2+v3 cumulative).
- `logs/build1-probe48.log`, `build2-probe48v2.log`,
  `build3-probe48v3.log` — three build logs (all EXIT=0).
- `logs/deploy1-probe48.log`, `deploy2-probe48v2.log`,
  `deploy3-probe48v3.log` — three deploy logs (all PASS).

## Files yet to write

- `README.md`, `log.md`, `findings.md`, `HANDOFF.md`,
  `commits.md` (none yet, since session 48 isn't done).
- `logs/v3-triggers.log` — capture the v3 trigger output.
- `logs/build4-clean.log` — clean rebuild after revert.
- `logs/deploy4-clean.log` — clean redeploy.
- `logs/baseline-tests-end.log` — baseline tests.

## Pipeline progress chain (sessions 42-48)

| Session | Locus                       | Count clean / failing |
|---------|-----------------------------|-----------------------|
| 42      | simplTopBinds entry         | 9 / 0-1               |
| 43      | core2core entry             | 9 / 1-3               |
| 44      | deSugar final_prs           | 9 / 3-6               |
| 45      | deSugar tcg_binds entry     | 9 / 3-6               |
| 46      | hsc_typecheck exit          | 9 / 3-5               |
| 47      | tcRnSrcDecls output         | 9 / 2-5               |
| **48 (so far)** | **tcTopSrcDecls output** | **8 / 2** (+1 from mkTypeable → final 9 / 3) |

## What NOT to redo

- Don't pursue closure-shape / UniqMap / Var.realUnique /
  SimplEnv / BLACKHOLE-IND theories — all subsumed.
- Don't start session 49 yet — session 48 isn't finished.
  Drill v3 → analyze → revert → rebuild → docs → commit, all
  in session 48.

## Hosts (unchanged)

- **uranium**: cross-build host.
- **pmacg5**: probe48-v3 stage2 is currently deployed.  After
  finishing session 48, redeploy the clean (probe-reverted)
  stage2.

## Paste-into-next-conversation prompt

```
Context: I'm continuing session 48 of the GHC darwin8-ppc
project (mid-session, not a new session).  Read
docs/sessions/2026-05-14-session-48-drill-tcRnSrcDecls/CONTINUATION.md
for the snapshot.

probe48-v3 is already deployed on pmacg5.  Next steps:
1. Trigger compiles at clean/-A256m, len=600, len=1650 with
   -A1m -G1 and save output to logs/v3-triggers.log.
2. Analyze: which hook (tcTyClsInstDecls / tcTopBinds_val_binds /
   tcTopBinds_deriv_binds) is where the count truncates.
3. Revert probe48 in compiler/GHC/Tc/Module.hs.
4. Clean rebuild, redeploy, smoke-test, baseline tests.
5. Write session 48's README/findings/log/HANDOFF/commits.
6. Update docs/state.md (round 30) and docs/roadmap.md.
7. Commit.

Don't start session 49 yet — finish session 48 first.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
Unsupervised mode is project default.
```
