# Session 32 findings — env-var bisect + heap-address probe

## TL;DR

- **Session 31's "any env var dodges" claim is wrong.**  The bug's
  PASS/FAIL pattern is **non-monotonic** in env-var length, and the
  bug surfaces at **at least FIVE distinct pipeline stages** as
  the heap shifts.
- **Five surface errors** observed, all "GHC dropped a `Var` from
  some in-scope data structure":
  1. `refineFromInScope` (simplifier).  The original session-31 bug.
  2. `'X' is not in scope during type checking` (TC-time).
  3. `StgToCmm.Env: variable not found` (codegen).
  4. `depSortStgBinds: Found cyclic SCC` (STG sort).  NEW.
  5. (None = PASS = compile succeeds.)
- **The probe captured THREE distinct heap addresses** for the
  dropped Var (in three different REFINE zones):
  - 0xe003348 (env-len 650-700)
  - 0xcce80d0 (env-len 850-900)
  - 0xbe30ddc (env-len 1700)
- **For a fixed env-len, the address is fully deterministic** (5/5
  iters return identical address).
- **The "blind spot" is NOT a single fixed virtual address.**  The
  bug fires at multiple, unrelated heap addresses across different
  env-len zones.  Whatever the root cause is, it's a condition
  satisfied by multiple addresses, not one specific address.
- **PASS zones span hundreds of bytes; FAIL zones are interleaved.**
  PASS/FAIL/SCOPE/STGCMM/DEPSORT cycle as env-len grows.

## Methodology

All runs on pmacg5 (PowerMac G5, Tiger 10.4.11) using
`/opt/ghc-stage2/bin/ghc-real`.  Each trial:

```
env $ENV_VAR DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS
```

5 iterations per trial.  Outcome classified by output:

- `PASS`         — rc=0.
- `FAIL_REFINE`  — output contains `refineFromInScope`.
- `FAIL_SCOPE`   — output contains `not in scope during`.
- `FAIL_STGCMM`  — output contains `StgToCmm.Env: variable not found`.
- `FAIL_DEPSORT` — output contains `depSortStgBinds: Found cyclic SCC`.
- `FAIL_OTHER`   — anything else nonzero.

Script: [`scripts/env-trial.sh`](scripts/env-trial.sh).  Sweep
driver: [`scripts/full-sweep.sh`](scripts/full-sweep.sh).  Detail
extractor: [`scripts/extract-fail-detail.sh`](scripts/extract-fail-detail.sh).

## Major findings

### F1. PASS/FAIL/SHIFT zones are non-monotonic in env-var length

(see `log/session32/sweep-2-300-step4.log`,
`log/session32/sweep-300-2000.log`,
`log/session32/probe-addrs.log`)

Sweep of `A=A...A` (varying value length) via the `env` wrapper.
Stable iters 2-5 results:

| env-var length (bytes) | iter 1 | iters 2-5    |
|------------------------|--------|--------------|
| 0 (no env var)         | REFINE | REFINE       |
| 2-6                    | REFINE | REFINE       |
| 7-12                   | SCOPE  | REFINE       |
| 13-16                  | PASS   | REFINE       |
| 17-22                  | PASS   | SCOPE        |
| 23-166                 | PASS   | PASS         |
| 170-174                | REFINE | PASS         |
| 178-320                | REFINE | REFINE       |
| 350-450                | STGCMM | STGCMM       |
| 500                    | PASS w/ gcc warning | PASS |
| 550-600                | PASS   | PASS         |
| 650-700                | REFINE | REFINE       |
| 750-800                | SCOPE  | SCOPE        |
| 850-900                | REFINE | REFINE       |
| 950-1000               | STGCMM | STGCMM       |
| 1050-1600              | SCOPE  | SCOPE        |
| 1700                   | REFINE | REFINE       |
| 1800-2000              | SCOPE  | SCOPE        |
| 2100                   | DEPSORT | DEPSORT     |
| 2200-2400              | SCOPE  | SCOPE        |
| 2500-3000              | PASS   | PASS         |

Transitions occur at 1-byte granularity (not 4-byte / word
aligned).  Wide PASS zone ~23..166 bytes (= ~143 bytes wide).
A second PASS zone at ~500..600.  A third at ~2500..3000.

(NOTE: these zones were measured with a probe-modified stage2
binary; the binary's larger size shifts zones from the original.
The qualitative non-monotonicity holds with original v0.12.0
binary as well — see `log/session32/sweep-2-300-step4.log`,
the pre-probe baseline.)

### F2. FIVE pipeline stages can detect the dropped Var

All five surface errors are "GHC's pipeline can't find a Var that
should be there".  Each error has a different message and lives
at a different stage:

| stage          | error message                                   | which Var dropped |
|----------------|-------------------------------------------------|-------------------|
| TC             | `'swap' is not in scope during type checking`   | `swap_aUU` (local where-bound) |
| Simplifier     | `refineFromInScope ... $dNum_a1jO`              | dictionary Var |
| STG dep-sort   | `depSortStgBinds: Found cyclic SCC` w/ $trModule|`$trModule*` Vars |
| Codegen        | `StgToCmm.Env: variable not found $trModule4_r1kB` | `$trModule4` Var |
| (PASS)         | —                                               | (no Var dropped) |

The drop class is the same across all five surfaces.  Which
stage catches the corruption depends on which Var was dropped
(which depends on heap layout).

### F3. Heap-address probe — multiple blind-spot addresses

Added a probe to `refineFromInScope` (compiler/GHC/Core/Opt/
Simplify/Env.hs:706) that dumps the heap address of `v` (the
Var being looked up) right before panicking.  Patch:
[`probe32-refineFromInScope-addr.patch`](probe32-refineFromInScope-addr.patch).

The probe uses the same `aToWordzh` foreign-import-prim that
`GHC.Exts.Heap.Closures` uses for its `Box` Show instance.

Captured addresses across REFINE zones (probe-modified binary):

| env-len   | dropped-Var heap address |
|-----------|--------------------------|
| 650, 700  | 0xe003348                |
| 850, 900  | 0xcce80d0                |
| 1700      | 0xbe30ddc                |

**Determinism:** at len=700, 5/5 iterations return exactly
`refineFromInScope 0xe003348`.  Address is reproducible for a
given env-len.

**Non-monotonicity:** addresses do not move smoothly with
env-len.  Between 700 (`0xe003348`) and 850 (`0xcce80d0`) the
address jumps by ~0x132,3278 (≈ 20 MB).  Between 900 and 1700
the address jumps by ~0x1eb,d2f4 (≈ 32 MB, in opposite sign).

**Different addresses → not a single blind spot.**  Sessions
19/31 hypothesized "one specific virtual address X is a blind
spot for the GC walker."  The probe data REJECTS that:
multiple, unrelated addresses across megablocks each trigger
the same kind of panic.

Bit-level inspection of the three addresses:

| addr       | %4 (4-byte align) | %8     | %16   | megablock (X / 0x100000) | offset in mblock |
|------------|------------------|--------|-------|---------------------------|------------------|
| 0xe003348  | 0                | 0      | 8     | 0xe000000                 | 0x3348           |
| 0xcce80d0  | 0                | 0      | 0     | 0xcc00000                 | 0xe80d0          |
| 0xbe30ddc  | 0                | 4      | 12    | 0xbe00000                 | 0x30ddc          |

No shared alignment, no shared megablock offset, no shared
megablock identifier.  These addresses look "ordinary heap
addresses" — nothing structurally distinguishes them.

### F4. Determinism within an env-len

For a fixed env-var value, the bug fires identically across
runs.  Tested 5 iters at len=700 → all 5 hit
`refineFromInScope 0xe003348` with the same dropped Var.

This confirms the bug is **fully deterministic for a given
process configuration** (executable + environ + argv).  No
randomness from the kernel's ASLR / sbrk / etc.

### F5. Iter-1 anomaly persists but doesn't shift addresses

In a multi-iter batch, iter 1 sometimes gives a different
result class than iters 2-5 (e.g., iter 1 PASS / iters 2-5
REFINE in some zones).  Address (when REFINE fires) does NOT
differ between iter 1 and iters 2-5.

Iter-1 source: probably some on-disk state (Big2.hi/Big2.o
inode allocation, page cache state, or `/tmp/ghcXXXX_0/`
directory recycling).  Not investigated this session.

### F6. Same-length, different-content env vars give different
       results

| env var                 | len | result |
|-------------------------|-----|--------|
| `A=AAAAAAAAAAAAAAAAA`   | 17  | iters 2-5: SCOPE 5/5 |
| `PROBE31_VERBOSE=0`     | 17  | iters 2-5: PASS 5/5 |

Same total bytes, different bytes inside.  Means the bug
isn't just about environ-block SIZE — the exact byte content
matters.  Likely because:

- Different key/value strings hash differently in libc's
  `getenv` and DYLD's env-search, which may affect malloc /
  mmap allocation paths.
- OR the environ-array slot order (insertion-order) places
  the string at a different position, which shifts later
  memory allocations differently.

This rules out a clean "shift by N bytes" interpretation of
the dodge.

### F7. Shell-var-assignment vs `env`-wrapper give different
       results

`A=A DYLD_... ghc-real ...` (bash variable assignment prefix)
vs `env A=A DYLD_... ghc-real ...` (via /usr/bin/env) produce
different outcomes for the same A=A.

Cause: env-wrapper adds an extra fork+exec, and the
intermediate `env` process's address space sequence is
different from bash's, which influences the child's malloc/
mmap allocations on Tiger's libC.

All sweeps in this session used `env`-wrapper for consistency.

## Implications for the bug hunt

The single-blind-spot-virtual-address hypothesis (from sessions
19, 30, 31) is **falsified** by the probe data.  Multiple
unrelated addresses trigger the same bug.

Better hypotheses to investigate:

1. **Specific closure-shape blind spot.**  The bug fires when a
   Var closure has a specific bit pattern in its info pointer,
   header, or payload bytes — independent of where in memory it
   lives.  GC's walker misclassifies based on a content check
   that's wrong on PPC32.
2. **Specific surrounding-closure context.**  The bug fires
   when a Var closure is adjacent to / inside / on the boundary
   of another closure with specific properties.
3. **Specific GC-event sequence.**  The bug fires when a Var
   is allocated during a specific phase, e.g., between two GC
   passes, and the layout's evacuation order causes a missed
   update.
4. **Specific bdescr / block-descriptor inconsistency.**  The
   bug fires when a block descriptor's metadata (size, type
   flags) is inconsistent with the block contents on the
   walker's pass.

Of these, (1) and (2) are most testable: dump the closure-
header + first-few-words at the trigger address, and look for
common patterns.

## Files added this session

- `README.md`, this `findings.md`, `HANDOFF.md`, `log.md`,
  `commits.md` — writeup.
- `probe32-refineFromInScope-addr.patch` — the panic-site
  address probe.  Re-apply with `git apply` from inside
  `external/ghc-modern/ghc-9.2.8`.  Requires stage1 rebuild
  + stage2 rebuild + redeploy (~14 min total cycle).
- `scripts/env-trial.sh` — single-env-var trial driver with
  outcome classification.
- `scripts/full-sweep.sh` — length sweep driver.
- `scripts/extract-fail-detail.sh` — dropped-Var-name extractor.
- Logs at `log/session32/`:
  - `sweep-2-300-step4.log` — fine sweep, pre-probe baseline.
  - `sweep-300-2000.log` — coarse sweep, pre-probe.
  - `probe-sweep.log` — first probe sweep, sparse.
  - `probe-addrs.log` — main probe sweep, captured addresses.

## What's clean / dirty in the source tree at session end

- `external/ghc-modern/ghc-9.2.8/compiler/GHC/Core/Opt/Simplify/Env.hs`
  — clean (PROBE32 reverted via `git checkout`).
- Other GHC tree files (compiler/, hadrian/, rts/linker/,
  libraries/) — pre-existing project patches, unchanged this
  session.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real` — clean rebuild +
  redeploy at session-32 end, matches v0.12.0.
- v0.12.0 unchanged.  Source tree clean.
