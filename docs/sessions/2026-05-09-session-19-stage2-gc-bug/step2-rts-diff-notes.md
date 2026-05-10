# Step 2 prep — RTS diff GHC 9.2.8 vs GHC 8.6.5

Pre-computed during the wait for the debug-RTS stage2 build.  These
are *anchors* to come back to once Step 1 (debug RTS sanity) returns
data, so we know where to look first.

## Sizes of suspect files

| File                          | 8.6.5 lines | 9.2.8 lines | diff lines |
|-------------------------------|------------:|------------:|-----------:|
| rts/sm/Storage.c              |        1581 |        1920 |       1263 |
| rts/sm/Storage.h              |         198 |         209 |         63 |
| rts/sm/GC.c                   |        1895 |        2297 |       1941 |
| rts/sm/GCThread.h             |         215 |         213 |         66 |
| rts/sm/Evac.c                 |        1303 |        1545 |        854 |
| rts/sm/Sanity.c               |        1017 |        1302 |        739 |
| rts/Capability.c              |        1242 |        1376 |        726 |
| rts/Capability.h              |         476 |         512 |        193 |
| rts/Stats.c                   |        1539 |        1753 |       1045 |
| rts/posix/OSThreads.c         |         397 |         488 |        233 |
| includes/Cmm.h                |         931 |         918 |        315 |
| includes/stg/SMP.h            |         303 |         579 |        424 |

GC.c, Storage.c, Evac.c, Sanity.c are big diffs — most likely
location for the bug.

## Hypothesis status

### ❌ RULED OUT: missing PPC memory fences / atomic miscompile

Investigated `includes/stg/SMP.h`.  Big change between 8.6.5 and
9.2.8 — 9.2.8 introduced `RELAXED_LOAD/RELEASE_STORE/ACQUIRE_LOAD/
SEQ_CST_*/RELEASE_FENCE/SEQ_CST_FENCE` macros built on the
`__atomic_*` C11 builtins, with explicit memory orders, and 301
call sites across the RTS use them.  However:

- We ship a **non-threaded RTS** (settings file says
  `("Support SMP", "NO")`; ghc-stage2 is linked without
  `-threaded`, so it picks `libHSrts-1.0.2.a` (vanilla) or
  `libHSrts-1.0.2_debug.a` (debug), never `_thr_*`).
- In the non-threaded path of `SMP.h`, **all the new macros expand
  to plain `*ptr` reads/writes** with no fences:

  ```c
  #else /* !THREADED_RTS */
  #define RELAXED_LOAD(ptr) *ptr
  #define ACQUIRE_LOAD(ptr) *ptr
  #define RELEASE_STORE(ptr,val) *ptr = val
  #define SEQ_CST_LOAD(ptr) *ptr
  ...
  #define RELEASE_FENCE()
  #define SEQ_CST_FENCE()
  ```

- The PPC-specific `lwsync`/`sync` asm is identical between 8.6.5
  and 9.2.8, but it's only invoked inside the THREADED_RTS branch.

So memory ordering / atomics on PPC32 cannot be the bug for our
single-threaded stage2.  **The handoff's "missing PPC memory
barrier" hypothesis is dead** under our build configuration.

### ❌ RULED OUT (likely): `large_alloc_lim` 32-bit overflow

`large_alloc_lim` is set in `rts/sm/Storage.c:243-247` to either
`RtsFlags.GcFlags.largeAllocLim * BLOCK_SIZE_W` or
`RtsFlags.GcFlags.minAllocAreaSize * BLOCK_SIZE_W`.  On PPC32 with
default `-A1m`, this is `256 blocks * 1024 W = 262144` words = 1 MiB
of words.  Even with `+RTS -A1G`, it's `256 MiB`.  Comfortably
within `W_` (32-bit unsigned, 4 GiB max).  No overflow.

### ❌ RULED OUT: non-moving GC enabled accidentally

`RtsFlags.GcFlags.useNonmoving` defaults to `false` and we don't
turn it on.  All non-moving code paths are guarded by this flag,
so the `NonMoving*.c/h` files are dead code in our build.

### Still in play

- **Generational copy/promotion bug.**  The bug fires after the
  *first major GC*, which is when stuff first gets evacuated from
  gen0 (nursery) to gen1.  The `evacuate_block` / `copy_tag` path
  in `rts/sm/Evac.c` is hot territory — 854 diff lines vs 8.6.5.
  Could be a missing scan/evac for some closure type, or a wrong
  pointer-tag mask on PPC32.
- **PPC pointer tag bits.**  GHC uses lower bits of pointers as
  constructor tags: `TAG_BITS = log2(sizeof(W_))` = 2 on PPC32
  (4-byte alignment), 3 on 64-bit (8-byte alignment).  If 9.2.8
  added GC code that hardcoded `7` (3-bit mask) instead of using
  `TAG_MASK`, it'd corrupt pointers on PPC32.  Worth grepping.
- **Block-allocator changes.**  `rts/sm/BlockAlloc.c` has
  significant churn between 8.6.5 and 9.2.8 — could include
  PPC-relevant assumption changes.
- **CAF list / static-object handling.**  `dyn_caf_list`,
  `debug_caf_list`, `revertible_caf_list` get reorganised in
  9.x.  The handoff mentioned CAF as a suspect.

## Order of investigation if step 1 doesn't pinpoint

1. `rts/sm/Evac.c` — copy_tag, evacuate, evacuate_block.
2. `rts/sm/GC.c` — scavenge_one, scavenge_loop, scavenge_static,
   GarbageCollect entrypoint.
3. `rts/sm/Storage.c` — allocateMightFail, allocate, addNewBlock_lock_,
   the large_alloc accounting.
4. `rts/sm/BlockAlloc.c` — block descriptor management.
5. PPC pointer-tag mask uses (`grep -rn "& 7\|& 0x7\|TAG_MASK"`).
