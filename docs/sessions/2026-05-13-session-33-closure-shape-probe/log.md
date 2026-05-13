# Session 33 log

Real-time work log.  Continuing from session 32 (autonomous-loop
mode).  **SESSION CUT SHORT** by user request at 00:39 local for
project reorganization in a separate Claude session.

## Setup

- 2026-05-13.  Continuing from session 32.
- HANDOFF top priority: extend PROBE32 to dump closure header +
  payload at trigger addresses; compare across known REFINE zones
  to find a structural commonality.

## Step 1 — extend PROBE32 → PROBE33-v1 (4-word dump)

Wrote PROBE33-v1 in `compiler/GHC/Core/Opt/Simplify/Env.hs`:

- Re-imports `aToWordzh` for the heap-address trick.
- Masks the low-2-bit tag (PPC32 TAG_BITS=2, TAG_MASK=3).
- Uses `Foreign.Storable.peek` on the untagged address to read
  4 words (info pointer at offset 0 + 3 payload words).

Rebuilt stage1 (5m50s) and stage2 (~8m).  Deployed to pmacg5.

## Step 2 — PROBE33-v1 sweep across env-zones

Sweep results in `log/session33/probe33-zones.log` (24 lines).

REFINE zones in v1-probe-deployed binary (env-len, addresses):

| env-len | tagged    | untag     | w0 (info ptr) | w1         | w2         | w3        |
|---------|-----------|-----------|---------------|------------|------------|-----------|
| 650     | 0xd9b1ce0 | 0xd9b1ce0 | **0x8c62bac** | 0x55e3a5d  | 0xd96ee20  | **0x92577e0** |
| 850     | 0xcce0cbc | 0xcce0cbc | **0x8c62bac** | 0xcce00c1  | 0xcc94c6c  | **0x92577e0** |
| 900     | 0xcce0cbc | 0xcce0cbc | **0x8c62bac** | 0xcce00c1  | 0xcc94c6c  | **0x92577e0** |
| 1700    | 0xcf9a5e0 | 0xcf9a5e0 | **0x8c62bac** | 0xdb8589a  | 0xdbca644  | **0x92577e0** |

**Critical finding: ALL FOUR captured Vars at four different heap
addresses share THE SAME w0 (info pointer 0x8c62bac) and THE SAME
w3 (0x92577e0).**

## Step 3 — identify the shared symbols

Resolved via `nm` on pmacg5:

- `0x08c62bac` → `_s71L_info` in `(__DATA,__const)`.
- `0x092577e0` → `_ghczmprim_GHCziTypes_Wzh_con_info` (the static
  `W#` constructor info table) in `(__DATA,__const)`.

Dumped raw bytes of `_s71L_info`:

```
08c62bac: 019e2620 00010000 00100001
          ^^^^^^^^ entry: 0x019e2620 (in __TEXT)
                   ^^^^^^^^ layout: ptrs=0x0001, nptrs=0x0000 (1 ptr, 0 nptr)
                            ^^^^^^^^ type=0x0010, srt=0x0001 → THUNK_1_0
```

Confirmed against `includes/rts/storage/ClosureTypes.h`:
**type 16 = THUNK_1_0** (a thunk with 1 ptr field + 0 nptr field).

Note: `_s71L_info` is a compiler-generated info-table name that
appears in MANY .o files (.../GHC/Types/Basic.o, .../GHC/Driver/
CodeOutput.o, .../GHC/Rename/Utils.o, .../GHC/Tc/Instance/Family.o,
.../GHC/CmmToAsm/AArch64/CodeGen.o, .../GHC/Core/Opt/Simplify/
Env.o).  Determining which specific module's `_s71L_info` lives
at 0x08c62bac would require correlating link-time addresses with
the linker map (not done this session).

## Step 4 — extend probe to 8 words (PROBE33-v2)

Modified probe to dump 8 words (offsets 0..28) instead of 4.
Rebuilt stage1 (5m28s) and stage2 (~8m).  Deployed.

## Step 5 — PROBE33-v2 sweep — partial, no REFINE samples

Sweep at env-lens 100..3000 returned NO `refineFromInScope` lines.
The v2 binary (larger due to extended probe) shifted the bug
zones again — at the tested env-lens, the bug surfaces only at
SCOPE / STGCMM / DEPSORT (panics without our probe firing).

To get v2 probe data, would need to either:
- Sweep a finer / different env-len range to find REFINE zones
  in the v2 binary, or
- Add similar dump probes to the SCOPE / STGCMM / DEPSORT panic
  sites so we capture data at the surfaces that DO fire in v2.

## SESSION CUT SHORT

At ~00:37 local, user requested capture-and-handoff so they
could do project reorganization in a separate Claude session.
The probe33-v2-zones.log captured 22 of 23 planned env-lens
(partial run during interrupt).

## State at session end (DIRTY)

- **Source tree DIRTY**: `compiler/GHC/Core/Opt/Simplify/Env.hs`
  has PROBE33-v2 applied (see [`probe33-closure-dump.patch`](probe33-closure-dump.patch)).
- **Stage1 + stage2 DIRTY**: `_build/stage1/lib/...libHSghc-9.2.8.a`
  and `pmacg5:/opt/ghc-stage2/bin/ghc-real` both contain PROBE33-v2.
- **No clean revert/rebuild done this session** — the next session
  must either pick up the probe (rerun sweeps on the v2 binary)
  or revert and redo from clean.
- v0.12.0 source unchanged in tags/releases.  Pre-session-32
  stage2 binary was clean; PROBE33-v1 build replaced it; PROBE33-v2
  build replaced that.

## Key takeaway for session 34

**PROBE33-v1 captured 4 REFINE samples in 3 megablocks at 3
different heap addresses — and ALL FOUR have the same info
pointer (THUNK_1_0 at `_s71L_info` 0x8c62bac).**

This **narrows the GC bug from "specific virtual address" to
"closures of one specific THUNK_1_0 info table"**.  The bug locus
is no longer about *where* a closure is in memory; it's about
*what type* of closure it is.

This is a major refinement of session 32's finding (which
falsified the single-virtual-address hypothesis).  Closure-shape
commonality IS the smoking gun.

Next session must:
1. Identify which specific module's `_s71L_info` lives at 0x08c62bac.
2. Look at the entry code at 0x019e2620 to see what the thunk computes.
3. Understand why GC misclassifies *this specific* THUNK_1_0.
