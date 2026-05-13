# Session 33 — stage2 GC bug, round 15 (closure-shape probe; CUT SHORT)

**Dates:** 2026-05-13 (continuing the stage2 GC bug hunt from
session 32, autonomous-loop continuation).

**⚠ SESSION CUT SHORT:** at ~00:37 local, user requested capture-
and-handoff so they could do project reorganization in a
separate Claude session.  The major v1 finding is captured;
v2 sweep returned no REFINE samples in the tested range.

**Status on arrival:** v0.12.0 ships unchanged.  Session 32
falsified the "single fixed virtual address X is the blind
spot" hypothesis (sessions 19/30/31's framing).  Three
distinct trigger addresses (0xe003348, 0xcce80d0, 0xbe30ddc)
captured across three REFINE zones — different megablocks, no
shared alignment.  Session-32 HANDOFF top priority: probe
closure header + payload at trigger addresses to look for
closure-SHAPE commonality.

**Status on exit (DIRTY, mid-investigation):**

- **PROBE33-v1 (4-word closure dump)** wrote a heap-address +
  header + 3 payload words at the simplifier's
  `refineFromInScope` panic.  Captured FOUR REFINE samples
  across env-zones 650, 850, 900, 1700.
- **CRITICAL FINDING: all four samples share the same info
  pointer 0x08c62bac (`_s71L_info`, a THUNK_1_0 info table)
  AND the same w3 value 0x092577e0 (`_ghczmprim_GHCziTypes_
  Wzh_con_info`, the W# constructor's static info table).**
  Different heap addresses, different megablocks, different
  Var uniqs — but ONE shared closure shape.
- **The bug locus is a SPECIFIC CLOSURE TYPE, not a specific
  virtual address.**  Session 32's falsification of "single
  blind spot address" is replaced by "single blind-spot
  closure type".
- `_s71L_info` is a compiler-generated thunk-info-table name
  that appears in MULTIPLE .o files of the compiled GHC.
  Determining WHICH module's `_s71L_info` lives at 0x08c62bac
  was NOT done this session — see HANDOFF.
- **PROBE33-v2 (8-word closure dump)** rebuilt + deployed but
  its sweep in env-lens 100..2500 returned NO REFINE samples
  (the larger binary shifted the bug zones).  v2's panic
  surfaces are SCOPE / STGCMM / DEPSORT — our probe is at
  refineFromInScope only.
- **Source tree DIRTY**: probe33-v2 applied to Env.hs.
  **Stage2 on pmacg5 = probe33-v2 build (NOT clean v0.12.0).**

HANDOFF for session 34: see [`HANDOFF.md`](HANDOFF.md).  The
next session needs to either pick up the probe (find REFINE
zones for the v2 binary by sweeping different env-lens, or
add probes to other panic surfaces) OR revert to clean and
redo from scratch.

## What we did, in order

### Step 1 — extended PROBE32 → PROBE33-v1 (4-word closure dump)

Patched `compiler/GHC/Core/Opt/Simplify/Env.hs:706` to dump
4 words at the heap-address of `v` (after masking PPC32's 2-bit
constructor tag).  Uses the same `aToWordzh` foreign-import-prim
that `GHC.Exts.Heap.Closures` uses.

Rebuilt stage1 ghc library (5m50s) + stage2 (~8m) + deployed.

### Step 2 — PROBE33-v1 sweep, captured 4 REFINE samples

| env-len | tagged    | w0 (info ptr) | w1         | w2         | w3        |
|---------|-----------|---------------|------------|------------|-----------|
| 650     | 0xd9b1ce0 | `_s71L_info`  | 0x55e3a5d  | 0xd96ee20  | `W#_con_info` |
| 850     | 0xcce0cbc | `_s71L_info`  | 0xcce00c1  | 0xcc94c6c  | `W#_con_info` |
| 900     | 0xcce0cbc | `_s71L_info`  | 0xcce00c1  | 0xcc94c6c  | `W#_con_info` |
| 1700    | 0xcf9a5e0 | `_s71L_info`  | 0xdb8589a  | 0xdbca644  | `W#_con_info` |

**Same w0, same w3.  Different heap addresses, different
megablocks.**

### Step 3 — identified the shared symbols

Via `nm` on pmacg5:

- 0x08c62bac → `_s71L_info` in `(__DATA,__const)`.
- 0x092577e0 → `_ghczmprim_GHCziTypes_Wzh_con_info`.

Dumped raw bytes of `_s71L_info`:

```
08c62bac: 019e2620 00010000 00100001
          entry    layout   type|srt
```

Per `ClosureTypes.h`: **type 0x0010 = 16 = THUNK_1_0**
(generic thunk capturing 1 pointer + 0 non-pointer).

### Step 4 — extended probe to 8 words (PROBE33-v2), redeployed

Same approach but dumping offsets 0..28 (8 4-byte words).
Rebuilt + deployed (~14 min total).

### Step 5 — PROBE33-v2 sweep — no REFINE samples in range

The v2 binary's size differs slightly from v1 (extended probe
code) so the bug zones shifted.  In the tested env-len range
(100..3000), NO `refineFromInScope` panics fired — all FAILs
were SCOPE, STGCMM, or DEPSORT (panics without our probe firing).

### Step 6 — SESSION CUT SHORT

User requested capture-and-handoff.  Source + stage2 left dirty.

## Status on exit (DIRTY)

- **v0.12.0 release unchanged** in tags/source; my changes are
  uncommitted local-tree modifications.
- **Source tree DIRTY**: probe33-v2 in
  `compiler/GHC/Core/Opt/Simplify/Env.hs`.
  Patch saved as [`probe33-closure-dump.patch`](probe33-closure-dump.patch).
- **Stage2 on pmacg5 DIRTY**: `/opt/ghc-stage2/bin/ghc-real` is
  the probe33-v2 build (8-word dump, larger than session-32-end's
  clean binary).
- Logs at `log/session33/`:
  - `probe33-zones.log` — PROBE33-v1 results (the canonical data
    for this session's finding).
  - `probe33-v2-zones.log` — PROBE33-v2 partial sweep, 22/23 env-
    lens captured, no REFINE samples in tested range.

## Files added this session

- [`README.md`](README.md) (this), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), [`log.md`](log.md),
  [`commits.md`](commits.md) — writeup.
- [`probe33-closure-dump.patch`](probe33-closure-dump.patch) —
  PROBE33-v2 (8-word dump) over clean Env.hs.
