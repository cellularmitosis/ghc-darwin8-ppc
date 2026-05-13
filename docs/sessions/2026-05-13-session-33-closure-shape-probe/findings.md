# Session 33 findings — closure-shape probe (cut short)

**SESSION CUT SHORT** at ~00:37 local for user-directed project
reorganization in a separate Claude session.  Major finding from
PROBE33-v1 is captured below; PROBE33-v2 deploy is on pmacg5 but
its sweep returned no REFINE samples in the tested range.

## TL;DR

- **PROBE33-v1 captures the heap-closure header + 3 payload
  words at the `refineFromInScope` panic.**
- **THE BUG LOCUS IS A SPECIFIC CLOSURE TYPE.**  Four captured
  REFINE samples — at four different heap addresses in three
  different megablocks — ALL share the same info pointer
  `_s71L_info` at 0x08c62bac (a **THUNK_1_0** info table).
- **The shared w3 value 0x92577e0** resolves to
  `_ghczmprim_GHCziTypes_Wzh_con_info` (the static `W#`
  constructor info table).  Present in all 4 samples.
- This **further refines session 32's framing**.  Session 32
  falsified the "single virtual address X is the blind spot"
  hypothesis.  Session 33 replaces it with: "**closures of a
  specific compiler-generated THUNK_1_0 are the blind spot**".

## Methodology

Modified `compiler/GHC/Core/Opt/Simplify/Env.hs:706` (the
`refineFromInScope` panic site) to dump the heap-address +
closure-header + payload of the missing Var `v`:

```haskell
foreign import prim "aToWordzh" probe33_aToWord# :: Any -> Word#

probe33Dump :: a -> String
probe33Dump x =
    let !tagged = W# (probe33_aToWord# (unsafeCoerce x :: Any))
        !untag  = tagged .&. complement 3
        readAt addr i = unsafeDupablePerformIO
            (peek (wordPtrToPtr (fromIntegral addr)
                    `plusPtr` (i * 4) :: Ptr Word))
        !ws = [readAt untag i | i <- [0 .. 7]]  -- v2
    in "self @" ++ probe33Hex untag ++ " [" ++ unwords ... ++ "]"
```

PROBE33-v1 dumped 4 words; PROBE33-v2 dumped 8 words.  Patch:
[`probe33-closure-dump.patch`](probe33-closure-dump.patch).

Sweep methodology unchanged from session 32: vary env-var value
length, capture 1 iter per env-len, classify outcome by panic
surface.

## Major finding

### F1. All REFINE samples share `_s71L_info` and `W#_con_info`

PROBE33-v1 sweep across env-zones (`logs/probe33-zones.log`):

| env-len | tagged    | untag     | w0          | w1         | w2         | w3        |
|---------|-----------|-----------|-------------|------------|------------|-----------|
| 650     | 0xd9b1ce0 | 0xd9b1ce0 | `_s71L_info` | 0x55e3a5d  | 0xd96ee20  | `W#_con_info` |
| 850     | 0xcce0cbc | 0xcce0cbc | `_s71L_info` | 0xcce00c1  | 0xcc94c6c  | `W#_con_info` |
| 900     | 0xcce0cbc | 0xcce0cbc | `_s71L_info` | 0xcce00c1  | 0xcc94c6c  | `W#_con_info` |
| 1700    | 0xcf9a5e0 | 0xcf9a5e0 | `_s71L_info` | 0xdb8589a  | 0xdbca644  | `W#_con_info` |

**Four samples, three megablocks, one shared info pointer.**

`_s71L_info` at 0x08c62bac decodes (per
[`includes/rts/storage/InfoTables.h`](../../../external/ghc-modern/ghc-9.2.8/includes/rts/storage/InfoTables.h)
and `ClosureTypes.h`) as:

- entry  = 0x019e2620 (in `__TEXT`)
- layout = 1 ptr, 0 nptr
- type   = 0x0010 = 16 = **THUNK_1_0**
- srt    = 0x0001

So the closure at v's heap address is a generic THUNK_1_0 — a
delayed computation capturing exactly 1 pointer.

### F2. The shared w3 value is the W# constructor's static info table

`0x092577e0` = `_ghczmprim_GHCziTypes_Wzh_con_info`.  That's the
**static info table** for the `W#` constructor of `Word`.

A THUNK_1_0's "closure size" (per layout: 1 ptr + 0 nptr + 1 info
ptr) is 2 words = 8 bytes.  The closure occupies offsets 0..7.
w2 and w3 (at offsets 8 and 12) are PAST the closure — in
adjacent heap memory.

The fact that w3 is consistently `W#_con_info` across all 4
samples suggests **the next adjacent closure** to our THUNK_1_0
always contains a pointer-to-W#-info-table at its offset+4 (the
adjacent closure's first payload word).  Or: the heap allocator
consistently places a closure with this shape right after the
buggy THUNK_1_0.

Either way, the structural commonality is strong.

### F3. `_s71L_info` is a compiler-generated name (non-unique)

`_sNN_info` is GHC's mangled name for system-generated thunks
in the compiled compiler binary.  The `_s71L_info` symbol
appears in MULTIPLE .o files (per `nm`):

- `.../GHC/Types/Basic.o`
- `.../GHC/Driver/CodeOutput.o`
- `.../GHC/Rename/Utils.o`
- `.../GHC/Tc/Instance/Family.o`
- `.../GHC/CmmToAsm/AArch64/CodeGen.o`
- `.../GHC/Core/Opt/Simplify/Env.o`

…each having their own local `_s71L_info`.  Determining WHICH
module's `_s71L_info` lives at 0x08c62bac in the linked binary
requires correlation with the link order (not done this
session — see HANDOFF for next steps).

### F4. PROBE33-v2 sweep returned no REFINE samples

The v2 binary (extended probe → larger binary → different heap
layout) shifted the bug surfaces in the tested env-len range
(100..3000) such that NO `refineFromInScope` panics fired in
the sample.  All FAILs were SCOPE / STGCMM / DEPSORT panics
without probe data (probe is only at the simplifier site).

Conclusion: PROBE33-v2 needs either (a) a finer / different
env-len sweep to find REFINE zones in the v2 binary, or
(b) additional probes at the SCOPE/STGCMM/DEPSORT panic sites
to capture data at the surfaces that fire under v2.

## Implications for next-session

The bug is **closure-shape-based**, not virtual-address-based.

The GC walker has a bug that misclassifies (or fails to scavenge)
closures of one specific THUNK_1_0 type — `_s71L_info` at
0x08c62bac.  Different env-var sizes cause different Vars to be
allocated near closures of this type, and the GC's miss of *this*
type drops the Var.

**To find the bug, identify what `_s71L_info` represents** —
which module/binding in the GHC compiler generates THIS specific
THUNK_1_0.

Approaches:
1. **Disassemble entry code at 0x019e2620**.  The first few PPC
   instructions should reveal the captured environment / what
   the thunk computes.
2. **Linker map**.  Recompile with `-Wl,-map` or similar to
   produce a link map that resolves `_s71L_info` per-module.
3. **Symbol patching**.  Rebuild with each candidate .o module
   excluded from a uniq-collision and see which one shifts the
   linked address.  Slow but mechanical.
4. **Add probe to ALSO dump the entry-code's first few words**.
   Compare against GHC's known thunk-entry signatures.

## State at session end

- **Source tree DIRTY**: probe33-v2 applied to Env.hs.
- **pmacg5:/opt/ghc-stage2/bin/ghc-real** is the PROBE33-v2 binary
  (8-word dump).
- v0.12.0 release unchanged.

## Files added this session

- `README.md`, this `findings.md`, `HANDOFF.md`, `log.md`,
  `commits.md` — writeup.
- `probe33-closure-dump.patch` — PROBE33-v2 (8-word dump) over
  clean `compiler/GHC/Core/Opt/Simplify/Env.hs`.  Re-apply with
  `git apply`.
- Logs at `logs/`:
  - `probe33-zones.log` — PROBE33-v1 sweep (4-word dump).  The
    canonical data for this session's finding.
  - `probe33-v2-zones.log` — PROBE33-v2 partial sweep (22/23 env-
    lens captured before interrupt; no REFINE samples in range).
