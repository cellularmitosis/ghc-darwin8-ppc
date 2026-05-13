# Session 34 findings — `_s71L_info` source module identified

## TL;DR

Building on session 33's finding that the GC-bug locus is a specific
**closure type** (a THUNK_1_0 named `_s71L_info`, not a specific
virtual address), session 34 identifies which Haskell module emits
that info table:

**`_s71L_info` (the THUNK_1_0 captured in all four v1 REFINE
samples) is emitted by `GHC.CmmToAsm.AArch64.CodeGen` and is the
info-table for an `ncgPlatform config` thunk** — a thunk that, when
forced, applies `ncgPlatform :: NCGConfig -> Platform` to its
captured `config :: NCGConfig`.

This is a static analysis on the deployed PROBE33-v2 stage2 binary
+ the corresponding `_build/stage1/compiler/build/GHC/CmmToAsm/AArch64/CodeGen.o`
on uranium — no new probe runs were needed.

This finding **deepens the puzzle**: AArch64.CodeGen code paths
should never execute during PPC compilation (the dispatch in
`nativeCodeGen` is keyed on `ArchPPC` for PPC builds), so no
`ncgPlatform config` thunk should ever be heap-allocated.  Yet
session 33's probe sees `_s71L_info` (= this thunk's info pointer)
at v's heap address across four independent failures.

## Methodology

1. **Enumerate `_s71L_info` candidates in the linked stage2.**
   `nm` on `/opt/ghc-stage2/bin/ghc-real` shows 5 distinct
   `_s71L_info` static symbols in `(__DATA,__const)` — same count
   as the .o files in `_build/stage1` carrying that symbol (one per
   module).
2. **Read the info-table layout (3 words: entry, layout, type+srt)
   at each candidate address.**  Of the 5 candidates, exactly ONE
   is THUNK_1_0:
   - `0x08b906e8`: entry `0x00a6e410`, layout `0x00010000`
     (1 ptr, 0 nptrs), type+srt `0x00100001` → type 0x10 = 16 =
     **THUNK_1_0**.
   - The other 4 are THUNK (0 ptrs), THUNK (3 ptrs), or
     THUNK_2_0 (2 ptrs).
   - Session 33's captured info pointer was always THUNK_1_0
     (layout `0x00010000`, type `0x00100001`), so the buggy thunk
     must be 0x08b906e8.
3. **Identify which .o file the THUNK_1_0 came from.**
   - Symbol neighbors of 0x08b906e8 in the linked nm output:
     between `_ghc_GHCziCmmziLRegSet_*` and
     `_ghc_GHCziCmmToAsmziAArch64ziCodeGen_cmmTopCodeGen_info`.
   - Five .o files in `_build/stage1` contain `_s71L_info`:
     `Types/Basic.o`, `Driver/CodeOutput.o`, `Rename/Utils.o`,
     `Tc/Instance/Family.o`, `CmmToAsm/AArch64/CodeGen.o`.
     (Session 33 also listed `Core/Opt/Simplify/Env.o`, but the
     probe33-v2 patch shifted Env.o's local Uniqs so its
     `_s71L_info` no longer exists.)
   - Reading each .o's `_s71L_info` info-table layout: only
     `CmmToAsm/AArch64/CodeGen.o` has layout 1 ptr / 0 nptrs / type
     0x10.  Match.
4. **Byte-for-byte confirmation.**  Disassembled the entry code at
   `0x00a6e410` in pmacg5's stage2 and at `0x00047ce0` in
   `CmmToAsm/AArch64/CodeGen.o`.  Same instruction sequence and
   same relocation targets (modulo linker-rewritten `ha16/lo16`
   immediates).  Confirmed identity.
5. **Decode NLP relocations** to identify what symbols the thunk
   uses.  The .o's `__DATA,__nl_symbol_ptr` indirect-symbol table
   resolves them.

## Major findings

### F1. The buggy thunk is `_s71L_info` in `GHC.CmmToAsm.AArch64.CodeGen.o`

Of 5 candidate `_s71L_info` symbols in the linked binary, the one
that matches session 33's THUNK_1_0 type signature is the one in
`GHC/CmmToAsm/AArch64/CodeGen.o`.  The other 4 candidates have
different closure types (THUNK with 0/3 ptrs, THUNK_2_0).

### F2. The thunk computes `ncgPlatform config`

The thunk's entry code references these NLP entries:

| symbol                                          | role                                     |
|-------------------------------------------------|------------------------------------------|
| `_MainCapability`                               | the RTS Capability struct (Sp/Hp/etc)    |
| `_ghc_GHCziCmmToAsmziConfig_ncgPlatform_closure`| the `ncgPlatform :: NCGConfig -> Platform` function's closure |
| `_stg_ap_p_fast`                                | RTS apply-1-pointer-arg fast path        |
| `_stg_upd_frame_info`                           | RTS update-frame info table              |
| `_stg_gc_unpt_r1`                               | RTS GC routine for unpointed R1          |

The allocation path pushes an update frame and dispatches via
`_stg_ap_p_fast` to `ncgPlatform_closure` with the captured ptr as
the argument.  This is the canonical compiled form of the Haskell
expression `ncgPlatform config`.

### F3. Three textual candidates for the source location of `s71L`

In `compiler/GHC/CmmToAsm/AArch64/CodeGen.hs`, the expression
`ncgPlatform config` appears verbatim at three places:

- `:142` — inside the AArch64 `pprNatCmmDecl`: `pdoc (ncgPlatform config) block`
- `:392` — inside `getFloatReg`'s `pprPanic`:
  `pprPanic "can't do getFloatReg on" (pdoc (ncgPlatform config) expr)`
- `:406` — inside `getRegister`: `getRegister' config (ncgPlatform config) e`

Any of these would compile to a THUNK_1_0 of the shape observed.
Without `-ddump-stg-final` on a clean rebuild we cannot tell from
the binary which line `s71L` corresponds to.  This is a precise
follow-up for the next session.

### F4. The puzzle — how does this thunk show up under PPC compilation?

`nativeCodeGen` in `compiler/GHC/CmmToAsm.hs:153–177` dispatches by
target architecture.  For a PPC target (the case we're running),
the `ArchPPC` branch is taken; `ArchAArch64` is not.  Therefore
**no `GHC.CmmToAsm.AArch64.CodeGen` code path executes at runtime
during PPC compilation.**  And yet:

- Session 33's probe captured `_s71L_info` (= AArch64.CodeGen's
  `ncgPlatform config` thunk) as the info pointer at v's heap
  address.
- This was consistent across 4 captures, in 3 megablocks, at 4
  different heap addresses.

So at least one of these must be true:

1. **`isLocalId v` is NOT in fact forcing v to WHNF.**  In Haskell,
   pattern-matching `(Id { idScope = LocalId _ })` strict-forces v
   to WHNF; if the unreg PPC backend has compiled this in a way
   that skips the force, v could still be a thunk at the probe
   site.  But then the thunk should be one allocated by the
   simplifier-related code path, not by a code path that never
   ran (AArch64 codegen).
2. **The probe is reading from stale heap memory** that contains
   an old, GC'd thunk.  But this requires the AArch64 codegen path
   to have allocated such a thunk earlier in the compile — which
   it shouldn't, since the dispatch never reaches AArch64.
3. **The info-pointer field at v's heap address has been
   overwritten by a GC-walker bug** (the most likely smoking gun
   so far).  GHC's GC walker is mistyping or misclassifying some
   closure; the corrupted/garbled memory happens to encode the
   pointer to `_s71L_info` because of some structural pattern in
   the GHC binary's `__DATA,__const` layout.  Why this specific
   thunk's info table consistently lands there is the question.
4. **`aToWordzh` is returning the wrong address on PPC32.**
   `aToWordzh` is just `return clos` in `HeapPrim.cmm` — minimal
   surface area for a bug, but worth ruling out.

Theory (3) is most consistent with the corpus of evidence from
sessions 19–33 (GC bug hypothesis); theory (1) would be a much
deeper compiler bug (in the PPC backend's pattern-match codegen).

## Implications for next session

The next session should:

1. **Rebuild AArch64/CodeGen.hs with `-ddump-stg-final`** and grep
   for `s71L` to pin down which of the three source lines
   generates this thunk.  This is purely diagnostic — it doesn't
   change the symptom, but it gives a precise pointer for further
   analysis.
2. **Verify v is in WHNF at the probe site** with a second probe.
   Add `seq v` and compare closure-header bytes before vs after.
   If header changes from THUNK_1_0 to Id-con-info, then the bug
   is theory (1).  If header stays THUNK_1_0, the bug is theory
   (3) or (4).
3. **Sweep more env-len ranges with the v1 (4-word) probe** to
   capture more REFINE samples.  If the `_s71L_info` info pointer
   keeps appearing, theory (3)/(4) is solid.  If a *different*
   info pointer ever shows up, the closure-type framing has a hole.
4. **If theory (3) confirms**, follow the lead in session 33's
   HANDOFF: inspect `rts/sm/Scav.c`'s THUNK_1_0 walker for a
   misclassification or off-by-one.
5. **If theory (4)**, instrument `aToWordzh` directly (or use a
   different mechanism — `unsafeAddr`-style — to read the heap
   address).

## Why this is progress

Session 33 narrowed the bug from "a specific virtual address" to
"a specific closure type" (THUNK_1_0).  Session 34 narrows it
further: that closure type is **a specific compiler-generated
thunk in a specific GHC module that should not even be running** —
which is itself a clue.  The "should not be running" part is the
strongest narrowing yet, because it bounds the bug's locus: either
the AArch64 codegen IS somehow being executed (and we need to find
the dispatch path), or the heap memory at v's address is being
corrupted to LOOK LIKE this thunk (and we need to find the GC
mistype).

## State at session end

- Source tree CLEAN (`compiler/GHC/Core/Opt/Simplify/Env.hs`
  reverted to baseline; `compiler/GHC/CmmToC.hs` retains the
  long-standing pi-Double patch — that's the canonical
  v0.12.0+ source state).
- Stage1 + stage2 rebuilt clean and redeployed to pmacg5.
- v0.12.0 release unchanged.

## Files added this session

- `README.md` (plan), this `findings.md`, `log.md`, `commits.md`,
  `HANDOFF.md`.
- No new probe patches added (analysis was static on existing
  binaries).
