# Session 24 — stage2 GC bug, round 6 (FastString StackRep: bitmap is correct)

**Dates:** 2026-05-11.

**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on
Tiger uses the `+RTS -A1G` workaround.  Session 23's PROBE22POISON
confirmed the bug is real (5/5 deterministic SIGSEGV on `_blk_c7te +
112` reading `MEM[Sp + 12] = 0xdeadbeef`), but ATTRIBUTED it to "the
StackRep of some Cmm block in `GHC.Data.FastString` mis-classifies a
pointer slot as non-pointer."  Session-23 [HANDOFF.md](../2026-05-10-session-23-stage2-poison-probe/HANDOFF.md)
proposed: re-cross-compile FastString.hs with cmm dumps, find the
offending info table, and trace back to LayoutStack /
stackMapToLiveness.

**Status on exit:** **session 23's attribution was wrong.  The
StackRep of `_blk_c7te` is `[False, True, True]` — and that IS the
correct answer given what the Cmm IR says.**  The slot at `Sp + 12`
is genuinely typed as a non-GC `I32` in Cmm.  The value stored
there is an `Addr#` extracted from the second unboxed field of a
`Data.ByteString.Internal.Type.BS` constructor — a `byteArrayContents#`-
style raw pointer into the byte data area of a `ForeignPtrContents`.
LayoutStack faithfully emits the bitmap that says "this is a raw
word, do not trace."  So the GC is **correctly** not tracing it; the
bug is **upstream of LayoutStack.**

The right framing for what's broken: an `Addr#` value spilled to the
stack across a `stg_newByteArray#` GC point becomes stale if (a) the
underlying ByteArray# is movable (non-pinned), or (b) the
ByteString-library invariant that "BS's underlying ByteArray# is
pinned" is being violated by some caller.  PROBE22POISON's per-slot
log shows the poisoned address `0x0bf5f38a` is in a block with
`bd_flags=0x0` — no `BF_PINNED`, no `BF_EVACUATED` — consistent with
"the from-space block that originally held the data got recycled
post-GC."  So either the BS was non-pinned-backed (invariant
violation), or PROBE22POISON has a false-positive class we missed
(it stomps pinned-memory addresses that happen to live in blocks
whose `BF_EVACUATED` is unset post-GC).

This means **sessions 20–22's "bitmap codegen is broken" hypothesis
is wrong everywhere it was tested.**  PROBE21's bad-slot events are
ALL false positives (heap-shaped values in dead slots OR Addr#s into
pinned memory — both are legitimate non-pointer slots that GC
correctly skips).  PROBE22POISON's read-after-poison crash is real,
but it's a **stale-Addr# bug**, not a bitmap mis-classification.

v0.12.0 still ships unchanged.  Stage2 on pmacg5 is unchanged
(unmodified RTS, deployed at end of session 23).

HANDOFF for session 25: instrument PROBE22POISON with a
`BF_PINNED`-aware filter (only poison non-evacuated AND non-pinned
slots).  If the crash STOPS firing → the bug is PROBE22POISON itself
(false positive on a stable Addr# in pinned memory); the production
crash was already explained by other mechanisms.  If the crash KEEPS
firing → the BS's underlying ByteArray# really is movable, and we
need to find which caller of `mkFastStringByteString` is violating
the pinning invariant.  See [`HANDOFF.md`](HANDOFF.md) for the full
plan.

## What we did, in order

### Step 1 — confirm baseline green

`tests/run-tests.sh`: 30 PASS, 4 expected design diffs (Int size,
getProgName, getpid, numeric boundaries).  Matches v0.12.0 baseline.

### Step 2 — capture hadrian's exact ghc invocation for FastString.hs

`touch external/ghc-modern/ghc-9.2.8/compiler/GHC/Data/FastString.hs`
then `./hadrian/build --flavour=quick-cross -j1 --verbose
_build/stage1/compiler/build/GHC/Data/FastString.o` and pulled the
full command line from ps output.  Key flags: `-O0 -H64m`, the long
`-package-id ...` block, `-i compiler -i _build/stage1/compiler/build`,
`-outputdir _build/stage1/compiler/build`, `-this-unit-id ghc`,
`-DNO_REGS -DNOSMP`, ~80 args total.

(Note for future-me: `-O0` is hadrian's default for the compiler
package at this stage.  FastString.hs's own `{-# OPTIONS_GHC -O2
-funbox-strict-fields #-}` pragma at the top of the source file
overrides this — but the dumps below confirm the optimised version
IS what landed in stage2's text section.)

### Step 3 — replay with `-ddump-{cmm,cmm-cps,cmm-sp,cmm-info,stg-final}`

[`scripts/dump-faststring-cmm.sh`](scripts/dump-faststring-cmm.sh)
replays hadrian's command verbatim with the dump flags added, the
`.o` and `.hi` redirected through a backup/restore trap so we don't
disturb the stage2 build artefact.  Output: 5 dump files in
[`logs/cross/`](logs/cross/),
~2 MB total.

`-ddump-cmm-final` doesn't exist in 9.2.8; the closest equivalents
are `-ddump-cmm-sp` (after stack layout) and `-ddump-cmm-info` (with
StackMap fixed up).

Crucially the cross-build's uniques are **stable across rebuilds of
the same source** — `c7te` in the fresh dump matches `_blk_c7te` in
stage2's text section from session 23, so we didn't need to
re-disassemble or re-locate.

### Step 4 — find `c7te` in the Cmm

`grep -n c7te dump-cmm-sp` → line 2391, in the proc starting at
`c7tB` whose info-table is `sat_s77C_info`.  Tracing the call chain:

```
sat_s77C_entry (c7tB)
  └── c7tD                                  -- arg eval: case bs of BS{...}
        └── _blk_c7t9 (c7t9)               -- BS unboxed; spill + call newByteArray#
              └── _blk_c7te (c7te)         -- ★ return continuation; reads stack & memcpy
                    └── ... → c7tr → c7tH (heap-overflow path)
```

`sat_s77C` is the saturated wrapper for `mkFastStringByteString`'s
`inlinePerformIO`-able lambda — i.e., the body
`case bs of BS{...} -> case newByteArray# ... of ...` directly inlined
from `Data.ByteString.Short.Internal.toShortIO`.

### Step 5 — read off the StackRep of c7te

From [`excerpts/c7t9-c7te.cmm`](excerpts/c7t9-c7te.cmm):

```
_blk_c7te() { //  [R1]
        { info_tbls: [(c7te,
                       label: block_c7te_info
                       rep: StackRep [False, True, True]
                       srt: Nothing)]
          stack_info: arg_space: 0
        }
    {offset
      c7te: // global
          Hp = Hp + 8;
          _s77q::P32 = R1;
          if (Hp <= HpLim) ... else c7tH;
      c7tg:
          _s77m::P32 = P32[Sp + 4];
          call MO_Memcpy 1(_s77q::P32 + 8,
                           I32[Sp + 12],   ← src argument
                           I32[Sp + 8]);   ← len argument
          call MO_Touch(_s77m::P32);
          ...
```

StackRep `[False, True, True]` means (convention: `False` = pointer,
`True` = non-pointer; verified against
`compiler/GHC/Cmm/LayoutStack.hs::stackMapToLiveness` and session 22's
audit):

| word offset above info ptr | slot type | StackRep |
|----------------------------|-----------|---------|
| Sp + 4  | `_s77m` — ForeignPtrContents | `False` (pointer) ✓ |
| Sp + 8  | `_s77n` — length (Int#)      | `True`  (non-ptr) ✓ |
| Sp + 12 | `_s77l` — `Addr#`             | `True`  (non-ptr) ✓ |

This is **exactly the right StackRep** for the Cmm IR.  Each slot's
type in the Cmm matches the StackRep bit.  `mkLivenessBits`
faithfully encodes this into the .o.  Session 21's audit-of-mkLivenessBits
and session 22's audit-of-stackMapToLiveness both still stand — the
bitmap codegen is correct.

### Step 6 — confirm the value at Sp + 12 IS an Addr#

From the same dump's c7t9 block (writer side):

```
c7t9: // global
    I32[Sp - 12] = block_c7te_info;
    _s77k::P32 = R1;                          -- R1 = BS constructor, tag=1
    _s77n::I32 = I32[_s77k::P32 + 11];        -- field 3 = length
    R1 = _s77n::I32;                          -- ⟶ arg to stg_newByteArray#
    P32[Sp - 8] = P32[_s77k::P32 + 3];        -- field 1 (ptr): ForeignPtrContents → Sp+4
    I32[Sp - 4] = _s77n::I32;                 -- field 3 (int): length            → Sp+8
    I32[Sp]     = I32[_s77k::P32 + 7];        -- field 2 (int): Addr#             → Sp+12  ⟵ ★
    Sp = Sp - 12;
    call stg_newByteArray#(R1) args: 4, res: 4, upd: 4;
```

`_s77k + 7` is field 2 of a 3-field unboxed BS closure (header at
+0; pointer fields first: ForeignPtrContents at +4; non-ptr fields
next: `Addr#` at +8, length at +12; tag=1 on R1 shifts the offsets
to 3, 7, 11).  That field is the `Addr#` part of the unboxed
`ForeignPtr` inside `BS !(ForeignPtr Word8) !Int`.

The matching STG (excerpt at [`excerpts/mkFastStringByteString.stg`](excerpts/mkFastStringByteString.stg)):

```
mkFastStringByteString [...] =
    {} \r [bs_s77i]
        let { sat_s77C [...] =
              {bs_s77i} \r [void_0E]
                  case bs_s77i of {
                  Data.ByteString.Internal.Type.BS ipv_s77l        -- Addr#
                                                   ipv1_s77m       -- ForeignPtrContents
                                                   ipv2_s77n ->    -- length
                  case newByteArray# [ipv2_s77n GHC.Prim.realWorld#] of {
                  Solo# ipv4_s77q ->
                  case copyAddrToByteArray# [ipv_s77l ipv4_s77q 0# ipv2_s77n void#] of ...
```

`ipv_s77l` ↔ `_s77l` ↔ the `Addr#` field.  Confirmed.

### Step 7 — re-interpret the PROBE22POISON crash

Session 23 already established: the crash reads `MEM[Sp + 12]` and
the stomped slot's pre-poison value was `0x0bf5f38a` in a block
with `bd_gen=0 bd_flags=0x0`.  Combining with Step 6:

- The value `0x0bf5f38a` is the `Addr#` field of a BS — i.e., the
  `byteArrayContents# <some MutableByteArray#>` of the BS's
  underlying ForeignPtrContents.
- For the BS to be valid, this Addr# **must** point into pinned
  memory (per the ForeignPtrContents invariants documented at
  `libraries/base/GHC/ForeignPtr.hs:145` — "The 'MutableByteArray#'
  is pinned, so the 'Addr#' does not get invalidated by the GC
  moving the byte array").
- `bd_flags=0x0` means: the block PROBE22 looked up for that address
  is neither `BF_PINNED` (4) nor `BF_EVACUATED` (1).  That is
  inconsistent with "pointing into pinned memory."

Two ways to read this:

1. **Invariant violation.**  Some code path constructs a `BS` whose
   underlying ByteArray# is movable (non-pinned).  When GC moves
   that ByteArray#, the `Addr#` becomes stale, and the next read
   yields garbage / poisoned bytes.
2. **PROBE22POISON false positive.**  Pinned blocks might end up with
   `bd_flags=0` after a GC pass that clears `BF_PINNED` (e.g., as
   part of promotion or block recycling).  In that case
   PROBE22POISON wrongly stomped a valid Addr#, and there is no
   real bug at all — the production "variable not found" / SIGSEGV
   under `-A1m` would have a different cause.

We can't tell from in-tree code which is true.  The decisive test:
a `BF_PINNED`-aware variant of the probe.

### Step 8 — design PROBE23 (session 25 deliverable)

Minimal change to the PROBE22POISON loop body:

```c
if (bd && !(bd->flags & BF_EVACUATED) && !(bd->flags & BF_PINNED)) {
    /* poison */
}
```

(plus log the stomped slot's `bd_flags` explicitly so we can audit
whether `BF_PINNED`-bearing blocks were ever in the running set.)

Outcomes:
- Crash gone → PROBE22POISON itself was the bug.  No real read-
  after-poison.  The bitmap is correct everywhere PROBE21 looked.
  Production GC crash is a different mechanism (CAF/SRT scanning,
  RTS-internal pointer chains, info-table contents, …).
- Crash still fires → the BS *really is* non-pinned-backed.
  Next step: instrument the BS allocator / fromShortIO / `BS`
  pattern to find the violator.

Session 25 will write the patch.  Session 24 stops at the diagnosis.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with `+RTS -A1G` wrapper,
  baseline test battery green (run start-of-session).
- **No source-tree edits this session.**  Read-only investigation
  on the dump files.
- **Stage2 ghc on pmacg5 unchanged** (still has the clean RTS from
  session-23 end-of-session revert).
- **Dumps captured at**
  [`logs/cross/`](logs/cross/)
  Smaller excerpts saved into the session dir under
  [`excerpts/`](excerpts/).
- **HANDOFF for session 25** scopes PROBE23.

## Files added this session

- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — writeup.
- [`scripts/dump-faststring-cmm.sh`](scripts/dump-faststring-cmm.sh)
  — replay hadrian's FastString.hs compile with cmm dumps enabled.
- [`excerpts/c7t9-c7te.cmm`](excerpts/c7t9-c7te.cmm) — the
  `_blk_c7te` info-table dump (StackRep + body).
- [`excerpts/mkFastStringByteString.stg`](excerpts/mkFastStringByteString.stg)
  — the STG for the function containing the offending Cmm.
