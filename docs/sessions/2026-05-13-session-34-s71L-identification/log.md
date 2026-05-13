# Session 34 log

Real-time work log.  Continuing immediately after session 33
(autonomous-loop mode).

## Arrival state

- Source DIRTY: `compiler/GHC/Core/Opt/Simplify/Env.hs` has probe33-v2.
- pmacg5 `/opt/ghc-stage2/bin/ghc-real` is the probe33-v2 build
  (193,199,236 bytes, mtime 2026-05-13 00:35).
- Session 33 captured 4 REFINE samples sharing
  `_s71L_info` (a THUNK_1_0 info table) and w3 = `_ghczmprim_GHCziTypes_Wzh_con_info`.

## Step 1 — find `_s71L_info` in the deployed v2 stage2 (nm on pmacg5)

`nm` on pmacg5 yielded FIVE distinct `_s71L_info` static (non-external)
symbols in `(__DATA,__const)`:

```
08b906e8 s _s71L_info
08cc0ce4 s _s71L_info
08ef7c74 s _s71L_info
08f9961c s _s71L_info
0902260c s _s71L_info
```

(Note: session 33's enumeration of `_build/stage1` listed 6 .o files
with `_s71L_info`, including `Core/Opt/Simplify/Env.o`.  In v2, the
probe-patched Env.o no longer has a `_s71L_info` — the local Uniq
supply shifted under the patch — so only 5 remain.)

## Step 2 — read closure-type for each candidate

Reading the info-table words (entry / layout / type+srt) at each
address in v2:

| candidate addr | entry      | ptrs/nptrs | type | type name |
|----------------|------------|------------|------|-----------|
| 0x08b906e8     | 0x00a6e410 | 1 / 0      | 0x10 | **THUNK_1_0** |
| 0x08cc0ce4     | 0x020bcd20 | 0 / 0      | 0x0f | THUNK |
| 0x08ef7c74     | 0x04c9e800 | 2 / 0      | 0x12 | THUNK_2_0 |
| 0x08f9961c     | 0x05891730 | 2 / 0      | 0x12 | THUNK_2_0 |
| 0x0902260c     | 0x062ad9e0 | 3 / 0      | 0x0f | THUNK |

**Only ONE candidate is THUNK_1_0: 0x08b906e8.**

Session 33 captured `type = 0x0010 = 16 = THUNK_1_0` for all four
v1 REFINE samples.  Therefore the buggy thunk must be the
0x08b906e8 candidate.

## Step 3 — identify which module the THUNK_1_0 belongs to

Looking at the symbol neighbors of each candidate in the linked binary:

| candidate  | nearest preceding `_ghc_...` symbol           | nearest following `_ghc_...` symbol                     |
|------------|------------------------------------------------|---------------------------------------------------------|
| 0x08b906e8 | `_ghc_GHCziCmmziLRegSet_insertLRegSet_info`    | `_ghc_GHCziCmmToAsmziAArch64ziCodeGen_cmmTopCodeGen_info` |
| 0x08cc0ce4 | `_ghc_GHCziDriverziBackpack_*`                 | `_ghc_GHCziDriverziCodeOutput_*`                          |
| 0x08ef7c74 | `_ghc_GHCziRenameziUtils_checkShadowedRdrNames_info` (immediate ±) | `_ghc_GHCziRenameziUtils_mapFvRn_info` (immediate ±) |
| 0x08f9961c | `_ghc_GHCziTcziInstanceziFamily_newFamInst_info` | (none in window)                                          |
| 0x0902260c | (none in window)                               | `_ghc_GHCziTypesziBasic_*`                                |

This gives a tentative module mapping.  Confirmed against the five
.o files in `_build/stage1` that contain `_s71L_info`:

| .o file                                        | _s71L_info layout    | type |
|------------------------------------------------|----------------------|------|
| `GHC/Types/Basic.o`                            | 3 ptrs, 0 nptrs      | THUNK (0x0f) |
| `GHC/Driver/CodeOutput.o`                      | 0 ptrs, 0 nptrs      | THUNK (0x0f) |
| `GHC/Rename/Utils.o`                           | 2 ptrs, 0 nptrs      | THUNK_2_0 (0x12) |
| `GHC/CmmToAsm/AArch64/CodeGen.o`               | **1 ptr, 0 nptrs**   | **THUNK_1_0 (0x10)** |
| `GHC/Tc/Instance/Family.o`                     | 2 ptrs, 0 nptrs      | THUNK_2_0 (0x12) |

The only THUNK_1_0 candidate is **`GHC/CmmToAsm/AArch64/CodeGen.o`**'s
`_s71L_info`.  Layout matches.

## Step 4 — byte-for-byte confirmation via entry-code comparison

Disassembled the entry code at 0x00a6e410 in pmacg5's stage2 AND
at 0x00047ce0 in `_build/stage1/compiler/build/GHC/CmmToAsm/AArch64/CodeGen.o`.
Both produce the IDENTICAL instruction sequence (modulo the literal
`lis ha16(...)` constants, which the linker rewrites — the structure
and the relocation targets match):

```
b    +0x4
lis  r2, ha16(<MainCapability NLP>)
lwz  r2, lo16(<MainCapability NLP>)(r2)
lwz  r3, 0xc(r2)                              # r3 = Cap->Sp
stw  r3, 0xfff0(r1)                           # save Sp
lwz  r3, 0x324(r2)                            # r3 = Cap->Hp
addi r3, r3, 0xfff4                           # Hp -= 12
lwz  r2, 0x328(r2)                            # r2 = Cap->HpLim
cmplw r3, r2
bge  GC_fail                                  # heap check
... (allocation path) ...
```

The entry-code byte structure matches.  **CONFIRMED: `_s71L_info`
in the deployed stage2 is the `_s71L_info` exported by
`GHC.CmmToAsm.AArch64.CodeGen`.**

## Step 5 — decode NLP references to identify what the thunk computes

Resolved the .o file's non-lazy-symbol-pointer (NLP) references
that the entry code uses:

| NLP offset | resolves to                                         |
|------------|-----------------------------------------------------|
| 0x93b00    | `_MainCapability`                                   |
| 0x93d5c    | **`_ghc_GHCziCmmToAsmziConfig_ncgPlatform_closure`** |
| 0x93f90    | `_stg_ap_p_fast`                                    |
| 0x93fa0    | `_stg_ap_ppp_fast`                                  |
| 0x93fbc    | `_stg_gc_unpt_r1`                                   |
| 0x93fcc    | `_stg_upd_frame_info`                               |

The entry-code allocation path stores `_stg_upd_frame_info` as an
update-frame info, captures the 1 payload ptr (the captured config),
and dispatches via `_stg_ap_p_fast` (apply 1 pointer arg) to
`_ghc_GHCziCmmToAsmziConfig_ncgPlatform_closure`.

**This is exactly the shape of a `ncgPlatform config` thunk** —
a THUNK_1_0 that, when forced, applies `ncgPlatform :: NCGConfig -> Platform`
to its captured `config :: NCGConfig`.

In `AArch64/CodeGen.hs` there are three textual occurrences of
`ncgPlatform config`:

- line 142: `pdoc (ncgPlatform config) block`
- line 392: `pprPanic "can't do getFloatReg on" (pdoc (ncgPlatform config) expr)`
- line 406: `getRegister' config (ncgPlatform config) e`  (in `getRegister`)

Any of these would compile to a THUNK_1_0 of this exact shape.
Without `-ddump-stg-final` it's not possible to tell from the
binary which Uniq `s71L` corresponds to.  The session-end revert
will preserve the option to re-introduce a dump probe in a later
session.

## Step 6 — the mystery

`nativeCodeGen` in `compiler/GHC/CmmToAsm.hs:153` dispatches by
target arch:

```haskell
case ... of
  ArchPPC     -> nCG' (PPC.ncgPPC config)
  ArchAArch64 -> nCG' (AArch64.ncgAArch64 config)
  ...
```

For a PPC target (which Big2.hs is, compiling on the PPC stage2),
the AArch64 branch is unreachable, so `GHC.CmmToAsm.AArch64.CodeGen`
code should never enter at runtime.  Yet session 33's probe sees
`_s71L_info` from THIS module as the info pointer at v's heap
address — across four independent panics, three different
megablocks, four different heap addresses.

This is internally inconsistent in one of these ways:

1. **`isLocalId v` is NOT in fact forcing v to WHNF** (a compiler
   bug in the PPC backend), so v remains a thunk and v's heap
   address legitimately points at a thunk closure.  But: why is
   it a `ncgPlatform config` thunk from a code path that never
   runs?
2. **v's heap memory is being misread by the probe.**  E.g.,
   `aToWordzh` on this stage2 is returning a stale or wrong
   address.  But `aToWordzh` is just `return clos` — there's
   little surface area for it to be wrong.
3. **v's heap memory is being overwritten by heap reuse.** v
   was forced to an Id, then the GC reclaimed and reused the
   slot for a `_s71L` thunk.  But this requires AArch64.CodeGen
   to have ALLOCATED such a thunk at some point during the
   compile — which it shouldn't, since the AArch64 branch is
   unreachable.  Unless a CAF-init path or `pprPanic`-style
   debug machinery touched it once.
4. **The info-pointer bytes at v's heap address coincidentally
   match `_s71L_info`'s linker address.**  Across four captures
   this is improbable (a 28-bit pointer collision four times in
   a row).

The next session should:

- Verify whether v is actually in WHNF at the probe site (add an
  extra `seq v` and dump v's closure header before vs after).
- Sweep more env-lens to capture more REFINE samples, see if the
  shared `_s71L_info` continues to hold or if it was a coincidence
  of the four captures (unlikely, but worth confirming).
- If the closure-type assertion still holds, investigate which
  code path in PPC compilation can possibly ALLOCATE a thunk with
  AArch64.CodeGen's `_s71L_info` — that's the smoking gun.

## Step 7 — revert + clean rebuild + redeploy

- `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` — revert
  probe33-v2 patch.
- Intentionally left `compiler/GHC/CmmToC.hs` modified — that's
  `patches/0008-cmmtoc-split-w64-double-on-32bit.patch`, the
  canonical v0.12.0+ source state.
- Rebuilt stage1 `libHSghc-9.2.8.a` via
  `./hadrian/build --flavour=quick-cross -j8`.  Total 5m52s.
- Ran `bash scripts/deploy-stage2.sh pmacg5` — cross-compiled
  stage2 ghc binary, scp'd to pmacg5, wrote Tiger lib/settings,
  smoke-tested with a "hello world" compile + run.
- Smoke test passed: `stage2 native ghc on Tiger: ok`.

## Step 8 — session-end state

- Source tree: clean (modulo the unrelated CmmToC.hs canonical
  patch, which is intentional).
- pmacg5 `/opt/ghc-stage2/bin/ghc-real`: clean v0.12.0+ rebuild,
  smoke-tested OK.
- All session writeup files in
  `docs/sessions/2026-05-13-session-34-s71L-identification/`.
- v0.12.0 release tag unchanged.

