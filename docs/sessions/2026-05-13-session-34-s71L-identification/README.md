# Session 34 — identify `_s71L_info`

**Dates:** 2026-05-13 (continuing immediately after session 33;
same day, autonomous-loop continuation).

**Status on arrival:** session 33 was CUT SHORT mid-investigation.
Source tree DIRTY (probe33-v2 patch on `Simplify/Env.hs`), pmacg5
stage2 DIRTY (probe33-v2 binary).  v0.12.0 release unchanged.

**Status on exit:** CLEAN.  Source tree reverted, stage2 rebuilt
and redeployed.

## Plan (executed)

1. Static analysis on the deployed PROBE33-v2 stage2 +
   `_build/stage1` artifacts to identify which Haskell module's
   `_s71L_info` was hit in session 33's REFINE samples.
2. Revert + clean rebuild + redeploy at session end.
3. No new probe runs — purely binary forensics.

## What we did, in order

### Step 1 — enumerate `_s71L_info` candidates in v2 stage2

`nm` on `/opt/ghc-stage2/bin/ghc-real` (the PROBE33-v2 build
inherited from session 33) yielded 5 distinct `_s71L_info` static
symbols in `(__DATA,__const)`:

```
08b906e8 s _s71L_info
08cc0ce4 s _s71L_info
08ef7c74 s _s71L_info
08f9961c s _s71L_info
0902260c s _s71L_info
```

These map to 5 of the 6 .o files session 33 identified.  The 6th
(`Core/Opt/Simplify/Env.o`) lost its `_s71L_info` in v2 because
the probe-patched source shifted the local Uniq supply.

### Step 2 — read closure-type for each candidate

Read the info-table words (entry / layout / type+srt) at each of
the 5 addresses.  Result: only ONE is THUNK_1_0 (1 ptr, 0 nptrs,
type 0x10).  The other four are THUNK with 0 or 3 ptrs, or
THUNK_2_0.  Session 33's captured info-pointer signature was
THUNK_1_0, so the buggy thunk MUST be:

- **0x08b906e8** in v2 (entry 0x00a6e410).

### Step 3 — identify the source .o file

Cross-checked symbol-neighbors in the linked stage2 against
per-.o `_s71L_info` info-table layouts.  Only
`GHC/CmmToAsm/AArch64/CodeGen.o`'s `_s71L_info` has THUNK_1_0
layout.  Confirmed via byte-for-byte entry-code comparison
between v2's 0x00a6e410 and the .o file's 0x00047ce0 — same
instructions, same relocation targets modulo linker-rewritten
`ha16/lo16` immediates.

### Step 4 — decode what the thunk computes

The .o file's `__DATA,__nl_symbol_ptr` indirect-symbol table
resolves the entry-code's NLP references.  Key entry:
`_ghc_GHCziCmmToAsmziConfig_ncgPlatform_closure` plus
`_stg_ap_p_fast` and `_stg_upd_frame_info`.  This is the
canonical compiled form of the Haskell expression
**`ncgPlatform config`** (a thunk that, when forced, applies the
strict accessor `ncgPlatform :: NCGConfig -> Platform` to its
captured 1-pointer `config`).

### Step 5 — three textual candidates in source

`compiler/GHC/CmmToAsm/AArch64/CodeGen.hs` contains
`ncgPlatform config` verbatim at three places (lines 142, 392,
406).  Any compiles to THUNK_1_0 of the observed shape.
Without a `-ddump-stg-final` build we cannot tell which Uniq
`s71L` corresponds to — this is the top-priority follow-up for
session 35.

### Step 6 — the deepening puzzle

`nativeCodeGen` (compiler/GHC/CmmToAsm.hs:153) dispatches by
target arch — for ArchPPC, the AArch64 codegen branch is
unreachable.  So no `ncgPlatform config` thunk from
AArch64.CodeGen should ever be heap-allocated at runtime.  Yet
session 33's probe sees this thunk's info pointer at v's heap
address across 4 captures.  See `findings.md` §F4 for the 4
candidate theories (WHNF/aToWordzh/GC-walker/coincidence).

### Step 7 — revert + clean rebuild + redeploy

Source-tree revert: `git checkout --
compiler/GHC/Core/Opt/Simplify/Env.hs`.  The unrelated
`compiler/GHC/CmmToC.hs` modification was intentionally left in
place — it's `patches/0008-cmmtoc-split-w64-double-on-32bit.patch`,
the canonical v0.12.0+ source state.

Rebuilt stage1 `libHSghc-9.2.8.a` via
`hadrian/build --flavour=quick-cross -j8`.  Redeployed via
`scripts/deploy-stage2.sh pmacg5`.

## Status on exit (CLEAN)

- Source tree: clean per `git status --short`.
- pmacg5 `/opt/ghc-stage2/bin/ghc-real`: clean v0.12.0+ rebuild
  (no probes).
- v0.12.0 release unchanged.
- Logs at `logs/`: empty (no probe runs this session — analysis
  was static).

## Files added this session

- [`README.md`](README.md) (this), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`log.md`](log.md),
  [`commits.md`](commits.md) — writeup.
- No new patches.  No log files.
