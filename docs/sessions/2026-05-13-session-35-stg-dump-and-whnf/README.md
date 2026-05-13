# Session 35 — `-ddump-stg-final` for `s71L`, plus a WHNF-verifying probe that revealed the probe itself was the bug

**Dates:** 2026-05-13 (same-day continuation of session 34;
autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-34 exit (only
the canonical `compiler/GHC/CmmToC.hs` pi-Double patch + hadrian
build-system patches + rts patches in `external/ghc-modern/ghc-9.2.8`).
`pmacg5:/opt/ghc-stage2/bin/ghc-real` is the clean v0.12.0+ rebuild.
v0.12.0 release unchanged.

**Status on exit:** CLEAN.  Probes reverted, stage1 rebuilt, stage2
redeployed to pmacg5 + smoke-test PASS.

## Plan (executed in order, with a twist)

1. **Top-priority follow-up from session-34 HANDOFF: identify
   which textual `ncgPlatform config` line in
   `compiler/GHC/CmmToAsm/AArch64/CodeGen.hs` is `s71L`.**
   ✓ Done — confirmed via `-ddump-stg-final` that `s71L` is the
   `ncgPlatform config1` thunk inside `getRegister` (line 406),
   recursively called from `getRegister'`'s `MO_XX_Conv` case
   (line 652).
2. **Second-priority follow-up: a WHNF-verifying probe (probe35)
   that captures v's closure-header BEFORE and AFTER `seq v`.**
   ✓ Done — got 6 REFINE captures across 3 distinct zones in env-len
   600..2000.
3. **Plot twist: a third `-ddump-stg-final` rebuild — this time on
   `compiler/GHC/Core/Opt/Simplify/Env.hs` (with probe35 still
   applied) — to identify what `_s7iu_info` and `_s7iW_info` (the
   info-pointers consistently captured by probe35) correspond to.**
   ✓ Done — and the answer reframes the entire investigation.
4. **Revert all probes, rebuild stage1 clean, redeploy stage2 to
   pmacg5, smoke-test.**  ✓ Done.

## What we did, in order

(See [`log.md`](log.md) for the real-time trace and
[`findings.md`](findings.md) for the distilled outcome.  The short
version is below.)

### Phase 1 — `s71L` ← AArch64/CodeGen.hs:406

Added a `{-# OPTIONS_GHC -ddump-stg-final -ddump-cmm-from-stg
-ddump-to-file -dppr-debug #-}` pragma to `AArch64/CodeGen.hs`,
rebuilt stage1.  The dump shows six STG-level `ncgPlatform config`
thunk bindings (three textual occurrences × inline copies).  `sat_s71L`
is the binding for:

```haskell
-- AArch64/CodeGen.hs:404-407
getRegister e = do
  config <- getConfig
  getRegister' config (ncgPlatform config) e
```

inlined into `getRegister'`'s `MO_XX_Conv _from to -> ... <$> getRegister e`
case at line 652.

### Phase 2 — probe35 WHNF-verifying probe

Reused session 33's v1 probe shape (4-word closure dump via
`aToWordzh` on `unsafeCoerce v :: Any`), augmented to:
1. Print a BEFORE state to stderr eagerly (so we still see it if
   the post-seq read segfaults).
2. Run `v \`seq\` return ()` to force v to WHNF.
3. Re-read v's closure header AFTER seq.
4. Return AFTER as a string embedded in `pprPanic`'s header.

Built + deployed.  Smoke-test PASS.

Swept env-lens 600..2000.  Captured 6 REFINE samples across 3 zones:

| env-len | missing var      | BEFORE info-ptr | AFTER info-ptr |
|---------|------------------|-----------------|----------------|
| 650/700 | `$dNum_a1kb`     | `0x8c63a7c`     | `0x8c63a8c`    |
| 850/900 | `$dNum_a1ko`     | `0x8c63a7c`     | `0x8c63a8c`    |
| 1650/1700 | `$dOrd_a1k0`   | `0x8c63a7c`     | `0x8c63a8c`    |

`nm` lookup:
- `0x8c63a7c` = `_s7iu_info` (THUNK_1_0)
- `0x8c63a8c` = `_s7iW_info` (THUNK_1_0)
- Both 16 bytes apart in `__DATA,__const`.

Cross-referencing `.o` files showed: the only `.o` with the 16-byte-
apart `_s7iu_info`/`_s7iW_info` pair is
**`Simplify/Env.o`** — the file we patched.

Also notable: every capture has Word[3] = `_Wzh_con_info` and all
three missing variables are **typeclass dictionaries**.

### Phase 3 — STG dump on Env.hs reveals the probe is the artifact

Added the dump-stg pragma to Env.hs (probe35 still applied),
rebuilt.  The STG dump shows:

```
sat_s7iu{v} :: Any Type
[LclId] =
    CCCS {(v{v s7ip} :: Var)} \u []
        unsafeCoerce (v{v s7ip})

case __primcall ghc aToWordzh [(sat_s7iu{v} ...)] of ...
```

**`aToWordzh` is called on the wrapping thunk `sat_s7iu`, not on
v directly.**  `aToWordzh` returns the heap address of its
argument's closure → it returns `sat_s7iu`'s address, whose info
table is `_s7iu_info` (THUNK_1_0 in Env.o).  Same for `sat_s7iW`
(the second wrapping thunk for the AFTER probe).

**This reframes sessions 33 and 34's findings:**

Throughout sessions 33, 34, and 35, the probe has been reading
the heap address of its own `unsafeCoerce v :: Any` wrapping
thunks, not v's actual heap closure.  Session 34's identification
of `_s71L_info` as "AArch64.CodeGen's ncgPlatform-config thunk"
was a coincidence — the wrapping thunk's info-table happened to
share an address with the AArch64.CodeGen `_s71L_info` symbol
because the linker placed many static THUNK_1_0 info tables in
`__DATA,__const` near each other.  In session 35's binary (with
a larger probe35 patch), the Uniqs shifted, the layout differs,
and the wrapping thunks now resolve to `_s7iu_info` / `_s7iW_info`
in our own patched module.

We've never actually read v's closure header.

### Phase 4 — revert + clean rebuild + redeploy

- `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs`
- `git status` confirms clean
  (`CodeGen.hs` was already reverted at end of phase 1).
- `hadrian/build --flavour=quick-cross -j8 _build/stage1/.../libHSghc-9.2.8.a`
  (6m03s; build4-clean.log)
- `scripts/deploy-stage2.sh pmacg5` → smoke-test PASS
  (deploy4-clean.log)

## Status on exit (CLEAN)

- Source tree: clean per `git status --short`.
- pmacg5 `/opt/ghc-stage2/bin/ghc-real`: clean v0.12.0+ rebuild
  (no probes).
- v0.12.0 release unchanged.
- Logs at `logs/`: 9 files capturing every build, every sweep, and
  the key STG-dump excerpts.

## Files added this session

- `README.md` (this), [`findings.md`](findings.md),
  [`log.md`](log.md), [`HANDOFF.md`](HANDOFF.md),
  [`commits.md`](commits.md).
- `probe35-whnf-dump.patch` — the probe35-v1 patch preserved for
  future revisions.
- `logs/`:
  - `baseline-tests.log` — start-of-session test run (30 PASS, 4
    expected-diff).
  - `build1-stg-dump.log` — AArch64/CodeGen.hs dump build.
  - `build2-probe35.log` — probe35 build.
  - `build3-env-dump.log` — Env.hs dump build (revealed the
    wrapping-thunk artifact).
  - `build4-clean.log` — final clean rebuild.
  - `deploy2-probe35.log`, `deploy4-clean.log` — deploys.
  - `stg-dump-ncgPlatform-sites.txt` — 6 sat_sXXX bindings in
    AArch64/CodeGen STG dump.
  - `cmm-from-stg-s71L-entry.txt` — `sat_s71L_info` Cmm entry
    block.
  - `probe35-wrapping-thunks-stg.txt` — **the smoking-gun STG
    excerpt** showing `aToWordzh` is called on the wrapping thunk.
  - `sweep1-known-zones.log`, `sweep2-broad-zones.log` — probe35
    sweep captures.
