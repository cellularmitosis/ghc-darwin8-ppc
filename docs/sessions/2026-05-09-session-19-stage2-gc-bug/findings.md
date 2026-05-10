# Session 19 findings — things learned that will matter later

## The big search-space reductions

### 1. Sanity check passes — the heap is internally consistent

We linked stage2 against the DEBUG variant of the RTS
(`libHSrts-1.0.2_debug.a`) and ran `M5.hs` compiles under `+RTS -DS
-RTS` (sanity check after every GC).  **No `barf`/`Sanity`/
`inconsistent` lines fire.**  Across the entire walk of all
reachable closures, every invariant holds.

So the bug is **not** in the evacuation/scavenge bookkeeping.  GC
correctly produces a heap that's internally consistent.  Some live
data is just no longer reachable from any root after GC.

### 2. The bug is NOT specifically in gen0→gen1 promotion

`+RTS -G1` (single-generation GC, eliminates the gen0→gen1 copy
entirely) **still fires the bug**.  Produces a partial M5.o with
only `six`, missing `five`.

So the bug is in the basic minor-GC nursery-scavenge cycle, not in
generation promotion.

### 3. Memory ordering / atomic miscompile is ruled out (under our build)

The 9.2.8 RTS introduced `RELAXED_LOAD/RELEASE_STORE/ACQUIRE_LOAD/
SEQ_CST_*/RELEASE_FENCE/SEQ_CST_FENCE` macros over `__atomic_*` C11
builtins, with 301 call sites across the RTS.  Suggested in
session 17's hypothesis list.

But: in the **non-threaded** build path (which is what stage2 uses
— `Support SMP=NO`, `ghc-stage2` linked against vanilla
`libHSrts-1.0.2.a`/`_debug.a` with no `_thr` suffix), all of those
macros expand to **plain `*ptr` reads/writes with no fences and no
atomics** (see `includes/stg/SMP.h:493-525`):

```c
#define RELAXED_LOAD(ptr) *ptr
#define ACQUIRE_LOAD(ptr) *ptr
#define RELEASE_STORE(ptr,val) *ptr = val
#define SEQ_CST_FENCE()
```

So memory ordering / atomic-builtin codegen on PPC32 cannot be the
cause.  **The handoff's "missing PPC barrier" hypothesis is dead
under our build configuration.**

### 4. The `large_alloc_lim` 32-bit-overflow hypothesis is also ruled out

`large_alloc_lim` on PPC32 with default `-A1m` is 1 MiB of words;
with `-A1G` it's 256 MiB.  Comfortably within `W_` (32-bit unsigned,
4 GiB).  No overflow at any reasonable nursery size.

### 5. The bug is non-deterministic (5/5 runs)

Same binary, same input (M5.hs), same flags (`+RTS -A1m -RTS`):
- 4/5 runs produce empty 152-byte `.o` (0 closures)
- 1/5 produces 356-byte `.o` (1 closure: `_ruj_bytes`, a
  typechecker temp name)
- 0/5 produces the full 868-byte `.o` (3 user closures)

Adding `-DS` makes the failure deterministic at the next layer:
5/5 panic with `GHC.StgToCmm.Env: variable not found
$trModule2_ruq`.

Non-determinism is the hallmark of memory corruption / use-of-
freed / use-of-uninitialised — not a deterministic miscompile.

## What remains in play

The combination "heap consistent, bindings missing, non-
deterministic" implies: **a GC root is not being scanned**.  The
unscanned root holds live data; the data isn't evacuated; the gen0
blocks are reset; reused for fresh allocations; subsequent reads
through the unscanned root see new (different, valid) data, but
not what they expected, so a typechecker map lookup fails.

Sanity check doesn't catch this because it walks reachable closures
post-GC, but the unreachable-but-pointed-to data is unreachable
*from any root* — and the stale pointers themselves live in
locations that GC cleared/overwrote.

Candidate "missed root" structures to investigate next, ranked by
probability:

1. **dyn_caf_list** — populated by `keepCAFsForGHCi`, walked by
   `markCAFs`.  9.2.8 changed the end-of-list test; functionally
   identical for valid lists, but worth printf-instrumenting to
   confirm the CAF count is stable across GCs.
2. **Mutable list (`mut_list`)** — IORefs, MutableArrays, MVars
   etc. that hold cross-generation pointers.  The FastString table
   (a global IORef) is a heavy user.
3. **TSO stack walk** — all the typechecker's continuation/state
   lives here.
4. **Stable pointers** — used by hs_init.

Also worth investigating but less probable:

- **Pointer tag bits**.  `TAG_BITS = 2` on PPC32 (vs 3 on 64-bit).
  All uses go through `TAG_MASK`/`UNTAG_CLOSURE` macros — we
  grepped and found no hardcoded `7`/`& 0x7` masks in the GC code.

## Methodology notes

### How to link stage2 against the debug RTS

Pass `-debug` to ghc when building stage2 (cross-build).  Stage1
ghc picks `libHSrts-1.0.2_debug.a` instead of the vanilla one.
Done in [`scripts/exp-deploy-stage2-debug.sh`](../../../scripts/exp-deploy-stage2-debug.sh).

Sister probe scripts:
[`scripts/exp-stage2-debug-rts-probe.sh`](../../../scripts/exp-stage2-debug-rts-probe.sh)
runs M5.hs through 8 RTS-flag combinations and dumps to
`log/session19/`.

### How to rebuild only the RTS

Hadrian invocation that rebuilds `_debug` and vanilla rts archives
without rebuilding everything:

```
./hadrian/build --flavour=quick-cross -j8 \
   _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a \
   _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
```

Don't pass `--freeze1` — that explicitly skips stage1 builds.  If
you've changed an RTS source file, wipe the corresponding object in
`_build/stage1/rts/build/c/...` first to force the rebuild.  Each
RTS-only rebuild is ~3-15 seconds (most of the work is `ar`+
`ranlib` re-archiving).

After RTS rebuild, redeploy stage2 by running
`scripts/exp-deploy-stage2-debug.sh pmacg5` (which re-cross-builds
ghc/Main.hs and re-links via the pmacg5-side gcc).  ~10-20 minutes.

### `+RTS -DG` is uninformative when keepCAFs is set

`-DG` (gccafs trace) walks `debug_caf_list` after each GC and stubs
unvisited CAFs.  But `debug_caf_list` is **only populated** when
`keepCAFs == false`.  Stage2 ghc has `keepCAFs == true` (set by
the `__attribute__((constructor))` in
`compiler/cbits/keepCAFsForGHCi.c`), so `debug_caf_list` is empty.

Output is always `0 CAFs live` and the diagnostic gives no signal.
For stage2 we have to instrument `markCAFs` directly — see
[`probe-markCAFs-count.patch`](probe-markCAFs-count.patch).

### Wrapper tag in handoff was wrong

The session-18 HANDOFF.md said `+RTS -DC -RTS` for sanity-check.
Actually `-DC` is "compact" debug (`rts/RtsFlags.c:469`); the
sanity flag is `-DS`.  Updated probe script accordingly.

### Cross-link via pmacg5 is the bottleneck

`scripts/ppc-ld-tiger.sh` rsyncs all `.o`/`.a` inputs to pmacg5,
runs gcc14 there for the link (because the 10.4u SDK's crt1.o etc.
are PPC), and scp's the result back.  For a 193MB stage2 binary
this is 10-20 minutes total, dominated by the rsync and remote
link.  Both phases are sequential per-link.
