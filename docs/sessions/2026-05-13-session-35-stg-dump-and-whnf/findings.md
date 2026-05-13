# Session 35 findings — `s71L` source line pinned + WHNF probe lands surprising data

## TL;DR

Three distinct deliverables this session:

1. **`s71L` (session 33's captured info pointer)** — via
   `-ddump-stg-final` on `AArch64/CodeGen.hs` — corresponds
   structurally to the `ncgPlatform config1` thunk at
   `compiler/GHC/CmmToAsm/AArch64/CodeGen.hs:406`, inlined into
   `getRegister'`'s `MO_XX_Conv` branch at `:652`.  HOWEVER, see
   point (3) — this finding turned out to be moot, because v's
   heap memory wasn't actually being read.
2. **WHNF probe (probe35-v1) captured 6 REFINE samples** across
   env-lens 600..2000.  BEFORE and AFTER reads consistently
   showed THUNK_1_0 info-tables 16 bytes apart in `__DATA`, with
   the symbols `_s7iu_info` (BEFORE) and `_s7iW_info` (AFTER),
   both from `Simplify/Env.o` (the patched file).  Word[3] always
   showed `_Wzh_con_info`, suggesting the W#-box-allocation
   immediately followed the captured closure in the heap.
3. **CRITICAL: the probe is reading WRAPPING-THUNK memory, not
   v's actual heap closure.**  Confirmed via
   `-ddump-stg-final` on `Env.hs` with the probe35 patch:
   `aToWordzh (unsafeCoerce v :: Any)` compiles such that
   `aToWordzh` is called on the THUNK that wraps `unsafeCoerce v`
   — not on v directly.  `_s7iu_info` and `_s7iW_info` ARE the
   info-tables of those two wrapping thunks in our probe code.
   **Session 33's `_s71L_info` finding (and session 34's
   AArch64.CodeGen-thunk identification) was the same artifact:
   we've never actually read v's closure header.**  See F4 below.

## F1.  `s71L` ← AArch64/CodeGen.hs:406 (line 406 in baseline source)

### Method

Added `-ddump-stg-final -ddump-cmm-from-stg -ddump-simpl -ddump-to-file -dppr-debug`
to `OPTIONS_GHC` of `compiler/GHC/CmmToAsm/AArch64/CodeGen.hs`, ran
`hadrian/build --flavour=quick-cross -j8 _build/stage1/.../libHSghc-9.2.8.a`,
inspected the resulting `_build/stage1/compiler/build/compiler/GHC/CmmToAsm/AArch64/CodeGen.dump-stg-final`.

### Result

`AArch64/CodeGen.hs` produces six STG-level `ncgPlatform config`
thunks, one per textual occurrence (after simplifier inlining):

| STG-dump line | sat-binder | Uniq | Source line (in unmodified CodeGen.hs) |
|--------------:|------------|------|----------------------------------------|
|          3292 | `sat_s6rl` | s6rl | line 142 (`pdoc (ncgPlatform config) block`) — `basicBlockCodeGen` |
|          4944 | `sat_s6uf` | s6uf | line 142 (different inline copy)         |
|          5292 | `sat_s6u0` | s6u0 | line 142 (different inline copy)         |
|         27066 | `sat_s71L` | s71L | **line 406 — `getRegister' config (ncgPlatform config) e`** inside `getRegister` |
|         37890 | `sat_s7eC` | s7eC | line 392 (`pprPanic` in `getFloatReg`)    |
|         42792 | `sat_s7lU` | s7lU | another inline copy                       |

(Three textual occurrences in source × multiple inline copies = six
STG bindings.)

The structural fingerprint that pinned `s71L` to line 406:

```
(STG, dump lines 27053-27077)

sat_s71N = \u [] ->
  let sat_s71M = \r [config1] ->
        let sat_s71L = (ncgPlatform config1)        -- ← the thunk
        in  getRegister' config1 sat_s71L e
  in getConfig >>= sat_s71M
```

That is the canonical desugaring of:

```haskell
-- compiler/GHC/CmmToAsm/AArch64/CodeGen.hs:404-407
getRegister :: CmmExpr -> NatM Register
getRegister e = do
  config <- getConfig
  getRegister' config (ncgPlatform config) e
```

The surrounding STG context (specifically the `MO_XX_Conv from to`
case at `MO_XX_Conv _from to -> swizzleRegisterRep (intFormat to) <$> getRegister e`
at line 652) confirms this is `getRegister` *inlined* into
`getRegister'`'s `MO_XX_Conv` handler — a recursive callback.

The `-ddump-cmm-from-stg` dump corroborates: `sat_s71L_info` is
`HeapRep 1 ptrs { Thunk }`, type-tag bytes `[80,108,97,116,102,111,114,109]` = `"Platform"`,
desc bytes `<GHC.CmmToAsm.AArch64.CodeGen.sat_s71L{v}>`, and its entry
code does `call stg_ap_p_fast(ncgPlatform_closure, captured_ptr)`
followed by a tail-call into `getRegister'{v r1W3}_entry`.

### Why this still matters

This confirms session 34's static-analysis finding from a completely
independent angle: `s71L` is what session 33's probe captured at v's
heap address.  Source line 406, inside `getRegister`, in
`GHC.CmmToAsm.AArch64.CodeGen` — a module that should NEVER execute
under PPC dispatch.

## F2.  Probe35 captures (WHNF verification probe)

### Probe design

A 4-word probe modelled after session 33's v1, augmented to interrogate
WHNF status:

```haskell
probe35WhnfDump x = unsafePerformIO $ do
    let !addr1 = (W# (aToWordzh (unsafeCoerce x :: Any))) .&. complement 3
    ws1 <- mapM (probe35Read addr1) [0 .. 3]
    hPutStrLn stderr ("PROBE35-BEFORE @" ++ hex addr1 ++ " [" ++ unwords (map hex ws1) ++ "]")
    hFlush stderr
    -- Force x.  If x's info-pointer is bogus and entry-code segfaults
    -- on bad payload memory, we die here -- but BEFORE is already on stderr.
    x `seq` return ()
    let !addr2 = (W# (aToWordzh (unsafeCoerce x :: Any))) .&. complement 3
    ws2 <- mapM (probe35Read addr2) [0 .. 3]
    return $ "PROBE35-AFTER @" ++ hex addr2 ++ " [" ++ unwords (map hex ws2) ++ "]"
```

### Sweep result (env-len 600..2000 step 50, 6 captures, 3 REFINE zones)

```
len=650  MISSING=$dNum_a1kb  BEFORE @0xbe15cdc [0x8c63a7c 0x95e2009 0xdb3f55c 0x92588e4]  AFTER @0xbe18744 [0x8c63a8c 0x95e201a 0xdb3f55c 0x92588e4]
len=700  MISSING=$dNum_a1kb  BEFORE @0xbe15cdc [0x8c63a7c 0x95e2009 0xdb3f55c 0x92588e4]  AFTER @0xbe18744 [0x8c63a8c 0x95e201a 0xdb3f55c 0x92588e4]
len=850  MISSING=$dNum_a1ko  BEFORE @0xcce88e4 [0x8c63a7c 0x33      0xccae07c 0x92588e4]  AFTER @0xcceb0a0 [0x8c63a8c 0x7       0xccae07c 0x92588e4]
len=900  MISSING=$dNum_a1ko  BEFORE @0xcce88e4 [0x8c63a7c 0x33      0xccae07c 0x92588e4]  AFTER @0xcceb0a0 [0x8c63a8c 0x7       0xccae07c 0x92588e4]
len=1650 MISSING=$dOrd_a1k0  BEFORE @0xc922278 [0x8c63a7c 0xc9222be 0xdbcb03c 0x92588e4]  AFTER @0xc912cc0 [0x8c63a8c 0x925929c 0xdbcb03c 0x92588e4]
len=1700 MISSING=$dOrd_a1k0  BEFORE @0xc922278 [0x8c63a7c 0xc9222be 0xdbcb03c 0x92588e4]  AFTER @0xc912cc0 [0x8c63a8c 0x925929c 0xdbcb03c 0x92588e4]
```

### Symbol resolution (`nm /opt/ghc-stage2/bin/ghc-real`)

| Captured info-pointer | Address     | Symbol              | Source .o                              |
|-----------------------|-------------|---------------------|----------------------------------------|
| BEFORE (always)       | `0x8c63a7c` | `_s7iu_info`        | **`Simplify/Env.o` @0x2c644**          |
| AFTER  (always)       | `0x8c63a8c` | `_s7iW_info`        | **`Simplify/Env.o` @0x2c654**          |
| Word[3] (always)      | `0x92588e4` | `_Wzh_con_info`     | `ghczmprim:GHCziTypes` (W# constructor)|

Both `_s7iu_info` and `_s7iW_info` exist in 5+ different `.o` files.
The pair that is **exactly 0x10 apart** — matching the linked-binary
offsets `0x8c63a7c` / `0x8c63a8c` — exists in ONLY ONE `.o` file:
**`GHC/Core/Opt/Simplify/Env.o`**, at offsets `0x2c644` and `0x2c654`.

Reading the info-table words at the linked addresses:

```
_s7iu_info @ 0x08c63a7c: entry=0x019e2990  layout=0x00010000 (1ptr/0nptr)  type+srt=0x00100001 (THUNK_1_0, srt=1)
_s7iW_info @ 0x08c63a8c: entry=0x019e2d80  layout=0x00010000 (1ptr/0nptr)  type+srt=0x00100001 (THUNK_1_0, srt=1)
```

Both are **THUNK_1_0**.

### Observations

1.  **BEFORE info-pointer = AFTER info-pointer + 0x10 every time.**  They
    are two consecutive static THUNK_1_0 info tables in
    `Simplify/Env.o`'s `__DATA,__const`.
2.  **BEFORE and AFTER addresses always differ within a capture**
    (e.g., capture 1: 0xbe15cdc → 0xbe18744, delta = 0x2a68 ≈ 11 KB).
    Between BEFORE and AFTER, GC may have moved x, or x's binding now
    points to a different closure.
3.  **`seq v` does NOT change v's apparent closure-type.**  AFTER is
    still THUNK_1_0, just a different one.  Either:
    *  the probe is reading wrapping-thunk memory not v itself
       (theory W below),
    *  `seq v` is being DCE'd by the compiler before reaching runtime,
    *  PPC unreg's update mechanism is not actually updating closure
       memory after evaluation.
4.  **Word[3] = `_Wzh_con_info`-address (`0x92588e4`) in every capture
    BEFORE and AFTER.**  THUNK_1_0 closures are only 8 bytes (info-ptr
    + 1 payload word); reading 16 bytes (4 words) overruns into
    *whatever lies next in the heap*.  The consistent appearance of
    `_Wzh_con_info` at offset +12 suggests our probe's
    `W# (probe35_aToWord# (unsafeCoerce x :: Any))` is allocating
    `W#`-wrapped Word values on the heap, adjacent to whatever we
    captured at `addr1`/`addr2`.  See theory W.
5.  **All 3 distinct REFINE zones miss a TYPECLASS DICTIONARY
    variable** (`$dNum_a1kb`, `$dNum_a1ko`, `$dOrd_a1k0`).  The
    bug is consistently about lost typeclass-dictionary Ids.

## F3.  The four theories (revised)

Session 34 listed four theories:

  1. `isLocalId v` doesn't actually force v on PPC unreg.
  2. `aToWordzh` returns the wrong address on PPC32.
  3. GC walker corrupts v's heap memory.
  4. Pointer-bytes coincidence (4× in session 33; now 6×).

Session 35's probe results recast them:

### Theory W (NEW — supersedes 2):  the probe is reading wrapping-thunk memory, not v's actual heap closure

Strongest evidence:

* The captured BEFORE/AFTER info-pointers (`_s7iu_info`, `_s7iW_info`)
  resolve to two consecutive THUNK_1_0 info tables in
  **`Simplify/Env.o`** — the very file we patched.  If the probe
  were reading v's REAL heap closure (a `Var`/`Id` constructor),
  we'd see an `_ghc_GHCziTypesziVar_Id_con_info` or similar header,
  not THUNK_1_0s from our own patched module.
* The consecutive 16-byte spacing matches "consecutive Uniqs in
  the same source module" — i.e., two intermediate thunks in our
  probe code itself.
* Hypothesis: GHC compiles `aToWordzh (unsafeCoerce x :: Any)` such
  that `aToWordzh` is invoked on the *wrapping thunk that GHC
  constructed at the call site `probe35WhnfDump v`*, not on v's
  underlying closure.  In that case the returned pointer is to the
  wrapping thunk, whose info-table is necessarily
  `_<some-sNN>_info` from `Simplify/Env.o` (the module the call
  site is in).

If theory W is correct, **session 33's `_s71L_info` captures were
ALSO artifact** — the wrapping thunk happened to have been
allocated by AArch64/CodeGen code paths in session 33's binary
layout because some earlier compilation step had emitted those
thunks (or the wrapping happened to alias to that thunk type
via some compiler-internal sharing).  We need a more robust probe
to know v's true closure-type at the panic site.

### Theory 1 (unchanged):  v actually is a thunk; PPC unreg's pattern-match doesn't force it

`isLocalId v` *should* force v to WHNF at the source level.  If the
PPC unreg backend compiles pattern-matching such that the forcing
doesn't actually happen, v would still be a thunk inside the panic
branch.  Probe35's BEFORE captures (showing THUNK_1_0) are
consistent with this.  But theory W says we don't actually know
because we're not reading v's memory.

### Theory 3 (unchanged):  GC walker bug overwrites v's heap memory

A GC walker mistype/misclassification could overwrite v's payload
words with bit-patterns that happen to look like info-table
addresses.  But this doesn't explain the consistency of
`_s7iu_info` / `_s7iW_info` from Env.o across 3 distinct REFINE
zones, or the 0x10 spacing.

### Theory 4 (now stronger):  the captured bit-patterns are artifacts of OUR PROBE's intermediate allocations

Same as theory W, framed differently: the addresses
`_s7iu_info`/`_s7iW_info`/`_Wzh_con_info` happen to be allocated
*by the probe itself* (the intermediate Word/Any wrapping plus the
W# constructor invocation), and `aToWordzh` returns pointers to
*those* allocations rather than to v.

## F4.  Implications for next session

The probe35 design is **fundamentally compromised** — we may be
reading our own intermediate-thunk memory, not v.

To progress, the next session should:

### Top priority: identify what `_s7iu_info` and `_s7iW_info` REALLY are

**CONFIRMED — Theory W is the truth.** Session 35 did the
`-ddump-stg-final` rebuild on Env.hs (with the probe35 patch still
applied), and the captured STG is unambiguous (see
`logs/probe35-wrapping-thunks-stg.txt`):

```
-- @ STG-dump line 3162 (one of two), Env.dump-stg-final
sat_s7iu{v} :: ghc-prim:GHC.Types.Any Type
[LclId] =
    CCCS {(v{v s7ip} :: ghc:GHC.Types.Var.Var)} \u []
        unsafeCoerce (v{v s7ip} :: ghc:GHC.Types.Var.Var)
```

`sat_s7iu` is the THUNK_1_0 created by GHC for the expression
`unsafeCoerce x :: Any` inside `probe35WhnfDump`.  It captures `v`
(1 pointer payload) and, when forced, evaluates to `unsafeCoerce v`.

Two lines later in the STG:

```
case
    __primcall ghc aToWordzh [(sat_s7iu{v} ...)] :: Prim WordRep
of ...
```

**`aToWordzh` is called on `sat_s7iu` — the wrapping thunk —
NOT on v directly.**  `aToWordzh` returns the heap address of its
argument's closure (which is the wrapping thunk's address).

The same pattern repeats for `sat_s7iW` (lines 3256-3276), the
second `unsafeCoerce v :: Any` wrapping thunk (for the AFTER probe).
The two STG bindings have consecutive Uniqs → consecutive info
tables in `__DATA,__const` → exactly the observed 16-byte spacing
between `_s7iu_info` and `_s7iW_info` in the linked binary.

**Implication:** session 33's `_s71L_info` captures, session 34's
"this is `ncgPlatform config` in AArch64.CodeGen" finding, and
this session's `_s7iu_info`/`_s7iW_info` captures all describe
**the same artifact:** the heap address of the probe's
`unsafeCoerce v :: Any` wrapping thunk, whose info-table is in
WHATEVER MODULE the wrapping thunk happened to be inlined into.

Session 33's probe33-v1 captured `_s71L_info` because (apparently)
when probe33's `unsafeCoerce v` got inlined / floated through the
simplifier, the wrapping thunk ended up labelled with a Uniq that
collided structurally with AArch64.CodeGen's `ncgPlatform config`
thunk — OR, more boringly, the wrapping thunk's info-table was
just a different `_sNNN_info` from Simplify/Env.o that happens
to share the THUNK_1_0 layout, and session 34's symbol-neighbor
analysis mistakenly matched it to AArch64.CodeGen's `_s71L_info`
because both have THUNK_1_0 layout (the most common THUNK shape).

The "GC walker bug" / "AArch64.CodeGen thunk where it shouldn't be"
puzzle from session 34 is **dissolved**: there is no AArch64.CodeGen
thunk in v's heap memory.  We've been reading the probe's own
wrapping-thunk memory the entire time.

### Second priority: redesign the probe to bypass wrapping-thunk artifacts

Options:
* Write the probe in Cmm directly (`compiler/GHC/StgToCmm/Prim.hs`
  or an `.cmm` shim) so we can call into a primop that reads v's
  closure header without going through Haskell's `aToWordzh +
  unsafeCoerce` machinery.
* Use `Debug.Trace.traceShow` with a custom Show instance that
  captures v's heap address via `getHeapHeader#` (a hypothetical
  primop) and prints the header bytes.
* Force the probe to inline (`{-# INLINE probe35WhnfDump #-}`) so
  the wrapping thunk doesn't get allocated.
* Read the closure header using `peek :: Ptr Word -> IO Word` directly
  on a `StablePtr v` (which is guaranteed by the RTS to point at the
  actual closure).

### Third priority: instrument the actual `case isLocalId v of ...` codegen

If theory 1 is the bug, then the compiled PPC assembly of
`refineFromInScope` is wrong in some way — the pattern match
doesn't actually generate a thunk-entry sequence.  Dump the
generated assembly for `refineFromInScope` and compare to what
GHC's PPC unreg backend should emit.

### Fourth: scope the GC walker — only if theory 3 survives the W cleanup

If we can verify (via redesigned probe) that v IS in WHNF post-isLocalId,
then theory 3 (GC corruption) is dead, and we're looking at a
codegen bug (theory 1).  If v is genuinely a thunk pre-`isLocalId`,
then look at how PPC unreg compiles strict pattern-matching on
nullary constructors.

## F5.  All three missing variables are typeclass dictionaries

Observed missing vars (across 3 REFINE zones):
* `$dNum_a1kb`, `$dNum_a1ko` — `Num` typeclass dictionaries
* `$dOrd_a1k0` — `Ord` typeclass dictionary

The bug consistently strikes typeclass-dictionary Ids.  This
narrows where to look in the simplifier's substitution-tracking
logic — likely in how dictionary thunks are floated vs.
substituted around `case` boundaries.

## State at session end

- `compiler/GHC/Core/Opt/Simplify/Env.hs`: probe35 reverted at session end.
- `compiler/GHC/CmmToAsm/AArch64/CodeGen.hs`: dump-stg pragma reverted at session end.
- Stage1 + stage2 rebuilt clean and redeployed to pmacg5 at session end.
- v0.12.0 release unchanged.
- The probe35 patch is preserved at `probe35-whnf-dump.patch` for
  future re-application.
- The STG-dump excerpts are preserved at `logs/stg-dump-ncgPlatform-sites.txt`
  and `logs/cmm-from-stg-s71L-entry.txt`.
- The probe35 sweep captures are preserved at
  `logs/sweep1-known-zones.log` and `logs/sweep2-broad-zones.log`.
- Build logs at `logs/build1-stg-dump.log`, `logs/build2-probe35.log`,
  `logs/build3-env-dump.log`, `logs/deploy2-probe35.log`.
