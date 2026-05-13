# Session 35 — real-time work log

Start: 2026-05-13 01:49 CDT (06:49 UTC).
End:   2026-05-13 ~03:15 CDT (08:15 UTC).

## Setup (01:49)

- Working dir: `/Users/cell/claude/ghc-darwin8-ppc`.
- Source-tree state: only the long-standing baseline patches
  (CmmToC pi-Double, hadrian build, rts) are dirty in
  `external/ghc-modern/ghc-9.2.8`.  No probe patches in flight.
- pmacg5 stage2: clean v0.12.0+ rebuild from session 34.

## Baseline tests (01:50–02:03)

Ran `bash tests/run-tests.sh`.  Result: **30 PASS, 4 FAIL_OUTPUT**
(01_int_arith, 14_env_args, 24_ffi, 25_numeric_boundaries — all
documented test-design issues per `tests/RESULTS.md`, NOT
regressions).  Baseline is green.  Log at
`logs/baseline-tests.log`.

## Phase 1 — `-ddump-stg-final` on AArch64/CodeGen.hs (02:03–02:16)

### Plan

Add `-ddump-stg-final -ddump-cmm-from-stg -ddump-simpl -ddump-to-file
-dppr-debug` to `OPTIONS_GHC` of
`compiler/GHC/CmmToAsm/AArch64/CodeGen.hs`.  Rebuild
`_build/stage1/.../libHSghc-9.2.8.a`.  Grep dump for `s71L` to
identify which textual `ncgPlatform config` occurrence at line
142/392/406 corresponds to the Uniq seen in session 33.

### Execution (02:03 → 02:10, build = 6m18s)

Patched, ran `hadrian/build --flavour=quick-cross -j8` for
libHSghc-9.2.8.a.  Build completed cleanly (the `error:`-prefixed
messages in build1-stg-dump.log are GHC's standard
"warning includes from Block.h" formatting noise; build exit 0).

### Findings

Six STG-level `ncgPlatform config` thunk bindings in
AArch64/CodeGen.dump-stg-final (= three textual source occurrences
× simplifier inline copies).  `sat_s71L` is at STG-dump line 27066,
in the context:

```
sat_s71M = \r [config1] ->
  let sat_s71L = (ncgPlatform config1)
  in  getRegister' config1 sat_s71L e
... getConfig >>= sat_s71M
```

This is the desugaring of:

```haskell
-- AArch64/CodeGen.hs:404-407
getRegister :: CmmExpr -> NatM Register
getRegister e = do
  config <- getConfig
  getRegister' config (ncgPlatform config) e
```

Wrapped in a recursive call from `MO_XX_Conv _from to -> swizzleRegisterRep
(intFormat to) <$> getRegister e` at `:652`.

`-ddump-cmm-from-stg` corroborates: `sat_s71L{v}_entry` is `HeapRep 1 ptrs
{ Thunk }`, with NLP relocations to `_ghc_GHCziCmmToAsmziConfig_ncgPlatform_closure`
and a tail-call to `getRegister'_entry`.

Source-line for `s71L`: **`compiler/GHC/CmmToAsm/AArch64/CodeGen.hs:406`**.

Excerpts saved to `logs/stg-dump-ncgPlatform-sites.txt` and
`logs/cmm-from-stg-s71L-entry.txt`.

Reverted the OPTIONS_GHC pragma.

## Phase 2 — probe35 WHNF-verifying probe (02:16–02:31)

### Patch design

`compiler/GHC/Core/Opt/Simplify/Env.hs` modified to add
`probe35WhnfDump :: a -> String` which:

1. Captures BEFORE: heap address of `unsafeCoerce x :: Any` via
   `aToWordzh`, reads 4 words at that address.
2. Eagerly flushes BEFORE to stderr (so it survives even if seq
   segfaults).
3. Runs `x \`seq\` return ()` to force x to WHNF.
4. Captures AFTER: same as BEFORE but post-seq.
5. Returns AFTER as a String embedded in pprPanic's message.

Patch saved to `probe35-whnf-dump.patch` (75 lines including header).

### Build + deploy (02:16–02:29, build2 = 6m06s, deploy ~1m30s)

Patched, rebuilt stage1, ran `scripts/deploy-stage2.sh pmacg5`.
Smoke-test (`ghc --version`, compile+run trivial Haskell) PASS.

### Sweeps (02:30–02:34)

#### Targeted sweep at session-33-known REFINE zones {650, 850, 900, 1700}

All 4 zones captured.  Each capture shows:
- BEFORE info-pointer = `0x8c63a7c`
- AFTER  info-pointer = `0x8c63a8c`
- Word[3] = `0x92588e4` (consistent across all captures)
- BEFORE address ≠ AFTER address within each capture

#### Broad sweep, env-len 600..2000 step 50

6 captures total, in 3 distinct REFINE zones:
- len ∈ {650, 700}: missing `$dNum_a1kb`
- len ∈ {850, 900}: missing `$dNum_a1ko`
- len ∈ {1650, 1700}: missing `$dOrd_a1k0`

All three missing variables are TYPECLASS DICTIONARIES.

Logs: `logs/sweep1-known-zones.log`, `logs/sweep2-broad-zones.log`.

## Phase 3 — symbol resolution + closure-layout analysis (02:34–02:50)

### Identify captured info-table symbols

On pmacg5: `nm -n /opt/ghc-stage2/bin/ghc-real > /tmp/nm-probe35.out`.
Lookup:
- `0x8c63a7c` → `_s7iu_info` (lowercase s = static)
- `0x8c63a8c` → `_s7iW_info` (16 bytes later)
- `0x92588e4` → `_ghczmprim_GHCziTypes_Wzh_con_info` (= W# constructor info table)

### Find which .o file has the 16-byte pair

Cross-referenced all `.o` files in `_build/stage1` that define both
`_s7iu_info` and `_s7iW_info`:
- Core/Opt/Monad.o: delta = 0xfc40 (negative, large)
- Core/Opt/Simplify/Env.o: delta = 0x10 ← **match**
- Core/Type.o: delta = 0x30

Only **Simplify/Env.o** has the consecutive 16-byte-apart pair.

### Info-table layout decode

Reading the 3 info-table words at each address (via `otool -X -s
__DATA __const` on local stage2 binary, then python script):

```
_s7iu_info @ 0x08c63a7c: entry=0x019e2990  layout=0x00010000  type+srt=0x00100001
_s7iW_info @ 0x08c63a8c: entry=0x019e2d80  layout=0x00010000  type+srt=0x00100001
```

Both have layout `1 ptr / 0 nptrs` and type 0x10 = **THUNK_1_0**.

## Phase 4 — `-ddump-stg-final` on Env.hs (with probe35 still applied) (02:50–02:57)

To pin down what `_s7iu_info` and `_s7iW_info` correspond to in
the probe code.

Re-added the OPTIONS_GHC dump-stg pragma to Env.hs (probe35 still
applied), rebuilt stage1.  Build = 5m51s.

### Findings — THE CRITICAL REVEAL

Env.dump-stg-final at line 3162:

```
sat_s7iu{v} :: ghc-prim:GHC.Types.Any Type
[LclId] =
    CCCS {(v{v s7ip} :: ghc:GHC.Types.Var.Var)} \u []
        unsafeCoerce (v{v s7ip} :: ghc:GHC.Types.Var.Var)
```

And at line 3174:

```
case __primcall ghc aToWordzh [(sat_s7iu{v} ...)] :: Prim WordRep of ...
```

**`aToWordzh` is called on `sat_s7iu` — the THUNK that wraps
`unsafeCoerce v` — not on v itself.**

Same pattern for `sat_s7iW` at line 3256, the second wrapping
thunk (for the AFTER read).

This means: throughout sessions 33, 34, and 35, **the probe has
been reading the heap address of its own intermediate `unsafeCoerce`
wrapping thunks, not v's heap closure.**  The "_s71L_info means
AArch64.CodeGen ncgPlatform-config thunk" finding from session 34
was a structural coincidence — both `_s71L_info` (session 33's
binary) and `_s7iu_info`/`_s7iW_info` (session 35's binary) are
just THUNK_1_0 info-tables that the linker happened to place in
`__DATA,__const`.  They never described v's real closure type.

STG excerpt saved to `logs/probe35-wrapping-thunks-stg.txt`.

Reverted the OPTIONS_GHC pragma and the probe35 patch.

## Phase 5 — clean rebuild + redeploy (~03:00–03:14)

(In progress at writeup time.)

- `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs`
- Verified `git status --short` shows no diff in the two files
  we touched.
- `hadrian/build ... libHSghc-9.2.8.a` (build4-clean.log).
- `scripts/deploy-stage2.sh pmacg5`.
- Smoke-test via `--version` + tiny compile.

## Phase 6 — session writeup (~03:00 onwards, interleaved)

- README.md, findings.md, log.md (this), commits.md, HANDOFF.md.
