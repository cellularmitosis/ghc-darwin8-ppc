# Session 36 findings — probe36 reveals v is a `_stg_BLACKHOLE_info` at the panic site

## TL;DR

The probe redesign worked.  We now have **v's actual heap closure
header** at every `refineFromInScope` panic.  The answer is the
same in all 4 captures across 2 distinct env-len zones:

**v's info-pointer is `_stg_BLACKHOLE_info`.  v's word[1] is a
tagged pointer (tag=3) to an evaluated `Id` constructor closure.
`seq v` is a no-op.**

This means: **v's evaluation produced a result, the result was
stored at v's word[1] as an indirectee, BUT the closure header was
never updated from `_stg_BLACKHOLE_info` to `_stg_IND_info`.**

That is the bug.  PPC unreg's thunk-update mechanism fails to swap
the BLACKHOLE info-pointer for the IND info-pointer after evaluation
completes.

This dissolves the "v is a wrapping thunk artefact" framing of
sessions 33-35 AND the "isLocalId doesn't force v" framing of
theory 1.  v IS forced, the evaluation completes, but the closure
header retains BLACKHOLE.  When `lookupInScope` later goes to
inspect v's `realUnique` to do a UniqMap lookup, the BLACKHOLE entry
forwarding may or may not correctly route through to the indirectee
— and we can see in this session that `lookupInScope` returns
`Nothing`, triggering the panic.

## F1.  Probe36 design — `anyToAddr#` (no wrapping thunk)

### Why probe35 was broken

`aToWordzh (unsafeCoerce v :: Any)` in probe35-style code:

```
sat_s7iu{v} :: Any Type
[LclId] = CCCS {(v{v s7ip} :: Var)} \u []
              unsafeCoerce (v{v s7ip})
case __primcall ghc aToWordzh [(sat_s7iu{v} ...)] :: Prim WordRep of ...
```

`aToWordzh` is called on `sat_s7iu` — the wrapping thunk that holds
`unsafeCoerce v` — not on v.  Captured info-pointer is the wrapping
thunk's, not v's.  (See session 35's `findings.md` F1-F4.)

### Why probe36 is right

`compiler/GHC/Builtin/primops.txt.pp:3297`:

```
primop   AnyToAddrOp "anyToAddr#" GenPrimOp
   a -> State# RealWorld -> (# State# RealWorld, Addr# #)
```

`compiler/GHC/StgToCmm/Prim.hs:353`:

```haskell
AnyToAddrOp -> \[arg] -> opIntoRegs $ \[res] ->
  emitAssign (CmmLocal res) arg
```

— register-to-register move.  Argument `v` is passed directly, no
allocation, no wrapping.

STG dump of probe36 (`-O`) confirms:

```
anyToAddr#{v} [(x{v s2WN} ...) (ghc-prim:GHC.Prim.void#{...})]
```

— `x` passed directly to the primop.  No `sat_sNNN` wrapping thunk.

### Standalone runtime verification

Confirmed on both uranium host-ghc and PPC cross-stage1 that the
probe correctly distinguishes thunk vs WHNF.  Logs at
`logs/verify-host-O0.log`, `logs/verify-host-O1.log`,
`logs/verify-ppc.log`.

| Fixture       | Host BEFORE word[0]  | Host AFTER word[0]  | PPC BEFORE word[0] | PPC AFTER word[0]  |
|---------------|----------------------|---------------------|--------------------|--------------------|
| `Just 42`     | constructor          | same (WHNF)         | constructor        | same (WHNF)        |
| `Just $! ...` | THUNK info           | indirection (IND)   | THUNK info         | rebound to Just    |
| `SimVar 7`    | constructor          | same (WHNF)         | constructor        | same (WHNF)        |

For a CAF thunk on PPC unreg, `seq` correctly forces the closure and
changes its info-pointer.  **The probe is sound.**

## F2.  Sweep results (probe36 in `refineFromInScope`)

`docs/.../logs/sweep1-broad.log` (env-len 600..2000 step 50,
`Big2.hs` trigger on pmacg5):

```
len=850   MISSING=$dNum_a1ko   PROBE36-BEFORE @0xcf86198 [0x92592a4 0xccaf06b 0xd93265c 0xddfe4d0]
                                        AFTER @0xcf86198 [0x92592a4 0xccaf06b 0xd93265c 0xddfe4d0]
len=900   MISSING=$dNum_a1ko   PROBE36-BEFORE @0xcf86198 [0x92592a4 0xccaf06b 0xd93265c 0xddfe4d0]
                                        AFTER @0xcf86198 [0x92592a4 0xccaf06b 0xd93265c 0xddfe4d0]
len=1650  MISSING=$dOrd_a1k0   PROBE36-BEFORE @0xdbca6dc [0x92592a4 0xd9bda6b 0xcf1b000 0xcf165c4]
                                        AFTER @0xdbca6dc [0x92592a4 0xd9bda6b 0xcf1b000 0xcf165c4]
len=1700  MISSING=$dOrd_a1k0   PROBE36-BEFORE @0xdbca6dc [0x92592a4 0xd9bda6b 0xcf1b000 0xcf165c4]
                                        AFTER @0xdbca6dc [0x92592a4 0xd9bda6b 0xcf1b000 0xcf165c4]
```

### Observations

1.  **BEFORE address = AFTER address in EVERY capture.**  `seq v` did
    not relocate v.  (Compare to the standalone T2 fixture where seq
    rebound the variable to a different heap location.)
2.  **BEFORE 4-word header = AFTER 4-word header in EVERY capture.**
    `seq v` did not update v's closure header.  Either GHC's
    strictness analyzer DCE'd the `seq` (the compiler's view is that
    v is already in WHNF by the time the panic branch is reached,
    via `case isLocalId v of ...`), or BLACKHOLE-entry forwarding
    completed without rewriting the BLACKHOLE→IND.
3.  **word[0] = `0x92592a4` in ALL 4 captures.**  Resolved via `nm`:

```
0925928c S _stg_IND_info
092592a4 S _stg_BLACKHOLE_info        ← what we're seeing
092592b0 S _stg_CAF_BLACKHOLE_info
092592bc S ___stg_EAGER_BLACKHOLE_info
```

    Exact match (no offset).  v's heap closure is `_stg_BLACKHOLE_info`.
4.  **word[1] tag bits = `0b011` (= 3) in every capture.**  GHC's
    pointer-tagging encodes the constructor index in the low bits.
    For the `Var` ADT, the 3rd constructor is `Id`.  So word[1] is a
    tagged pointer to an evaluated `Id` constructor closure.

    | capture      | word[1]      | untagged (& ~3)  |
    |--------------|--------------|------------------|
    | len=850/900  | `0xccaf06b`  | `0xccaf068`      |
    | len=1650/1700| `0xd9bda6b`  | `0xd9bda68`      |

5.  **Address tag bits of v itself = `0b00`.**  v is held as an
    untagged pointer; the binding-site / call-site never re-tagged
    it to point at the indirectee.  (Compare to the standalone T2
    AFTER address `0x1914e0a`, tag bits `0b10` — Just constructor —
    once seq rebinds.)
6.  **All 3 missing variables are TYPECLASS DICTIONARIES** (`$dNum_a1ko`,
    `$dOrd_a1k0`).  Two of the four captures are dups of the same
    panic (same address, same header, just different env-len
    triggers).  Net unique panics: 2.  Session 35 saw 3 zones; this
    session saw 2 zones.  The 650-700 zone from session 35 didn't
    fire here, likely because probe36's binary layout differs and
    GC behaviour shifts the trigger point slightly.

### Why `_stg_BLACKHOLE_info` + indirectee + no IND swap?

In GHC's RTS, a thunk's lifecycle is:

```
1. Allocate:                THUNK_N_M_info | <free vars>
                                                            ↓ entered by some thread
2. Lazy/eager blackhole:    BLACKHOLE_info | <free vars>
                                                            ↓ evaluation completes
3. Update via UPD_IND:      IND_info       | result-pointer
                                                            ↓ GC short-circuit (later)
4. Indirection elim:        gone — pointer rewired to result-pointer directly
```

Step 2 is what's called "lazy blackholing" — performed by the GC,
not at entry-time.  Step 3 is performed by the update frame popped
when evaluation returns.

We're seeing **step 2-and-a-half**: BLACKHOLE_info + indirectee
populated, but no IND swap.  Possible mechanisms:

(a) **The update frame got popped but wrote the indirectee to word[1]
    without updating word[0] from BLACKHOLE_info to IND_info.**  This
    is a bug in PPC unreg's emission of `UPD_IND_DIRECT` /
    `stg_update_thunk_info` C-code.
(b) **GC walked the heap mid-evaluation, set BLACKHOLE, then the
    thread evaluated and wrote indirectee, but the update path
    expected BLACKHOLE_info ≠ original-thunk-info and skipped the
    info-write.**  Specific to lazy-blackhole-GC interaction on PPC.
(c) **The update macro on PPC32 uses byte-swapped writes** (PPC is
    big-endian; if the macro forgets to byte-swap the info pointer,
    word[0] would retain BLACKHOLE_info from the GC pass).
(d) **`stg_update_thunk_info` reads/writes the wrong slot** — e.g.,
    writes to the indirectee field but not the info field.

(d) is supported by the fact that **only the info field is wrong**:
the indirectee is correctly populated, and even pointer-tagged
properly (so the evaluator KNEW the result was an Id and chose tag
3 for it).

## F3.  Why `lookupInScope` returns `Nothing` despite v being evaluated

Once `case isLocalId v of` enters v's BLACKHOLE_info entry code,
the standard `_stg_BLACKHOLE_entry` (`rts/StgMiscClosures.cmm`)
follows the indirectee (word[1]) and forwards execution to the
evaluated Id closure.  `isLocalId` then sees the real Id, returns
True.

Then `lookupInScope in_scope v` is called.  `compiler/GHC/Types/Var/Env.hs:152`:

```haskell
lookupInScope (InScope in_scope) v = lookupVarSet in_scope v
```

This computes v's `Unique` (via `getUnique`, which reads
`realUnique`) and looks it up in the in-scope `VarSet`.  Reading
`realUnique` requires entering v again — another BLACKHOLE forward.

If the BLACKHOLE entry code on PPC unreg ALWAYS forwards correctly,
the lookup should succeed.  But the lookup returns `Nothing`.  So
either:

(i)  The BLACKHOLE_entry forwarding mis-routes on PPC, returning
     garbage for the realUnique field.  But the standalone CAF test
     showed forwarding-via-update WORKED for `Just $! ...` — so
     this would have to be a different code path.
(ii) The InScopeSet was built when v was still a regular THUNK_N_M.
     After GC blackhole'd it, the `Unique`-key-lookup uses the
     CURRENT v's pointer-identity instead of value-identity, and
     pointer-identity changed.
(iii) The Unique stored in the in-scope set is the evaluated Id's
      Unique, but the lookup queries with v's BLACKHOLE-closure's
      "Unique" which on PPC unreg reads garbage from the BLACKHOLE
      payload words.

I lean toward (iii): the BLACKHOLE entry code on PPC unreg, when
forwarding to the indirectee for field access, may not correctly
re-enter and read the field — instead reading from the BLACKHOLE's
payload offset.

## F4.  Why `seq v` is a no-op

Two possibilities:

(α) The strictness analyzer determined that v is in WHNF after
    `case isLocalId v of ...`, and DCE'd the `seq` from the probe's
    `unsafePerformIO` block.  We can verify by inspecting the STG
    dump of probe36's compiled form — TBD if needed.
(β) `seq` runs and enters v's BLACKHOLE_entry, which forwards
    correctly to the indirectee, but DOESN'T rewrite v's header.
    This is consistent with the update-skip theory (F2-d): even when
    BLACKHOLE forwards correctly, the BLACKHOLE→IND swap doesn't fire.

Either way, the existing probe data is conclusive about the
BLACKHOLE+indirectee state.

## F5.  Implications for the next session

The bug is in the **BLACKHOLE→IND update path** on PPC unreg.
Specific suspects:

1.  **`UPD_IND` / `UPD_IND_DIRECT` / `stg_update_thunk_info`** in
    `rts/Updates.h` and `rts/StgUpdates.cmm`.  Trace through the C
    code generated for the unregisterised PPC backend.
2.  **The PPC unreg backend's emission of the thunk-update sequence
    in `compiler/GHC/StgToCmm/Bind.hs`'s `emitUpdate*` family.**
3.  **`evacuate`/`scavenge` in the GC** — specifically how lazy
    blackholing interacts with the update path.  See
    `rts/sm/Compact.c`, `rts/sm/Scav.c`.

### Concrete next-session experiments

1.  **Confirm by reading the indirectee.**  Extend probe36 to also
    peek into word[1]'s heap (after untagging), so we can see the
    indirectee's info-table.  Expected: `_ghc_GHCziTypesziVar_Id_con_info`.
    Probe-v2 would dump 4 words at v + 4 words at v.word[1] & ~3.
2.  **Look at `stg_update_thunk_info` in the linked binary.**  Find
    the address in nm output and disassemble.  Compare to host GHC.
3.  **Build with `-debug` / RTS `-Dg`** and re-run the trigger.  GC
    debug output may show the BLACKHOLE→IND timeline.
4.  **Force eager blackholing OFF / lazy blackholing OFF.**  See
    `rts/GenericGC.h` and the compile-time flags.  If turning off
    blackholing eliminates the bug, that confirms the BLACKHOLE→IND
    path is the issue.
5.  **Reproduce on uranium host GHC + 9.2.8 with the same Big2.hs
    program.**  Should NOT panic.  Diff the simplifier's behaviour.

### What can be ruled out

- **Theory W (probe reads wrapping-thunk memory)** — ruled out by
  the standalone verifier on both host and PPC.  probe36 reads v's
  actual closure.
- **Theory 1 (isLocalId doesn't force v on PPC)** — partially ruled
  out.  isLocalId DID force v: the indirectee is populated with the
  evaluated Id.  But the closure header retained BLACKHOLE_info, so
  *subsequent* field reads via lookupInScope see the stale header
  and route through BLACKHOLE_entry forwarding (which may have its
  own bug).
- **Theory 4 (pointer-bytes coincidence)** — definitively ruled out.
  word[0] is EXACTLY `_stg_BLACKHOLE_info`, not a near-miss.

### What's still possible

- **Theory 3 (GC walker bug)** — recast: lazy-blackholing GC sets
  BLACKHOLE_info on a still-unentered thunk, the thunk gets
  evaluated normally, but the BLACKHOLE_info doesn't get replaced
  with IND_info by the update path.  PPC-unreg-specific.
- **Theory NEW (BLACKHOLE→IND swap missing)** — the headline finding
  of session 36.

## F6.  All three missing variables are typeclass dictionaries (still true)

`$dNum_a1ko`, `$dOrd_a1k0`.  Compiler-generated dictionary Ids.
Dictionaries are heap-allocated THUNK_1_0 closures emitted by the
specializer / desugarer.  The fact that the BLACKHOLE-non-update
bug only manifests on dictionary thunks suggests it's specific to
the THUNK_1_0 layout's update path — OR it's specific to how
dictionaries are GC'd before being entered.
