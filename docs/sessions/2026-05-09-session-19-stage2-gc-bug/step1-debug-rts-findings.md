# Step 1 — debug-RTS-linked stage2 — findings

## What we did

1. Built a parallel `ghc-stage2-debug` binary linked against
   `libHSrts-1.0.2_debug.a` (the DEBUG variant of the RTS, which
   adds invariant assertions, sanity-check support, etc.) by adding
   `-debug` to the stage2 ghc invocation in
   [`scripts/exp-deploy-stage2-debug.sh`](../../../scripts/exp-deploy-stage2-debug.sh).
   Deployed to `/opt/ghc-stage2/bin/ghc-real-debug` on pmacg5.
2. Ran [`scripts/exp-stage2-debug-rts-probe.sh`](../../../scripts/exp-stage2-debug-rts-probe.sh)
   which compiles the canonical `M5.hs` reproducer under 8 different
   RTS-flag combinations, capturing stderr + the resulting `M5.o`
   symbol table.
3. Sidequest: ran `M5.hs` 5×5×3 times under different flags to
   characterise non-determinism.

Logs in [`log/session19/probe-*.log`](../../../log/session19/).

## Probe summary

| Probe                  | RTS flags                | M5.o size | symbols     | panic? |
|------------------------|--------------------------|----------:|-------------|:------:|
| vanilla-A1G (control)  | `-A1G`                   |       868 | 5 (works)   | no     |
| vanilla-A1m (control)  | `-A1m`                   |       152 | 0           | no     |
| sanity-A1m             | `-DS -A1m`               | (no .o)   | (panic)     | **YES** |
| gc-trace-A1m           | `-Dg -DS -A1m`           | (no .o)   | (panic)     | **YES** |
| zero-on-gc-A1m         | `-DZ -DS -A1m`           | (no .o)   | (panic)     | **YES** |
| block-trace-A1m        | `-Db -DS -A1m`           | (no .o)   | (panic)     | **YES** |
| gen1-A1m (single gen)  | `-G1 -A1m`               |       616 | 1 (`six` only) | no  |
| gen1-sanity-A1m        | `-G1 -DS -A1m`           | (no .o)   | (panic)     | **YES** |

The panic is invariably `GHC.StgToCmm.Env: variable not found
$trModule2_ruq` at `compiler/GHC/StgToCmm/Env.hs:153`.

## Non-determinism characterisation (5 runs each)

| flags                | size=152 (empty) | size=356 (partial) | panic |
|----------------------|------------------|--------------------|-------|
| `+RTS -A1m`          | 4/5              | 1/5                | 0/5   |
| `+RTS -A1m -DS`      | 0/5              | 0/5                | 5/5   |
| `+RTS -A1m -DG`      | 3/3              | 0/3                | 0/3   |

Same binary, same input, same flags — different output across runs.
Confirms session 17's non-determinism finding.  Memory corruption,
not a determinist pass-level miscompile.

## What this tells us

### 1. Sanity check passes — heap is internally consistent

The single biggest signal.  `-DS` runs the GC sanity checker after
every collection.  It walks all reachable closures, validates info
pointers, checks block bookkeeping, etc.  **Zero `barf`/`Sanity`/
`inconsistent` lines fire** across all probe runs.

So the bug is **not** in evacuation/scavenge bookkeeping — the GC
correctly produces a heap that is internally consistent.  Just,
some live data is no longer reachable from any root after GC.

### 2. The bug is in the basic minor-GC cycle, not in promotion

`+RTS -G1` (single-generation GC, no gen0→gen1 promotion at all)
**still fires the bug** — produces a partial M5.o with only `six`
surviving.  So evacuation between generations isn't the suspect.
The bug is in the generic nursery-evacuate-and-scavenge cycle.

### 3. The corruption happens at GC time, not before/after

`-DZ` (zero freed memory) gives the same panic.  If the loss were
"reads of freed memory contain stale data", `-DZ` would convert the
read to a zero-deref crash.  Since the panic is unchanged, the data
is genuinely missing from the post-GC heap (not present-but-stale).

### 4. The bug is compile-specific, not generic

`ghc-real-debug --version +RTS -A1m -DS` runs cleanly, GC fires
once, sanity passes, exit 0.  So a single GC during a non-compile
workload is fine.  The bug requires the typechecker / desugarer to
be running.

### 5. `+RTS -DS` deterministically panics where vanilla is silent

Without `-DS`, the bug is a non-deterministic data-loss producing an
empty 152-byte `.o` 4/5 of the time.  With `-DS`, every run panics
deterministically with "variable not found $trModule2_ruq" — same
panic, every time.

`-DS` itself doesn't change the GC algorithm; it only adds extra
walks/checks.  But those extra walks force more thunks earlier and
extend the live root set, shifting which GCs are major and which
collect what.  The deterministic panic suggests `$trModule2_ruq` is
the first binding to be lost in this scenario, every time.

`$trModule2_ruq` is a typechecker-generated binding for the
`TypeRep`-machinery `Module` value (`$trModule = TrNameS! [parts]`).

### 6. `-DG` (gccafs trace) is uninformative for our case

`-DG` walks `debug_caf_list` after each GC and stubs CAFs that
weren't visited.  But `debug_caf_list` is **only populated** when
`keepCAFs == false` (see `rts/sm/Storage.c:625-632`, the `else`
branch of `if(keepCAFs && ...)`).

Our stage2 ghc has `keepCAFs == true` (set by the
`__attribute__((constructor))` in
`compiler/cbits/keepCAFsForGHCi.c`, which gets linked because we
use `-package ghc`).  So `debug_caf_list` is empty, `gcCAFs()`
reports `0 CAFs live` 4× per GC, and we get no diagnostic info.

To meaningfully debug the CAF path we'd need to either:
  (a) instrument `markCAFs` directly (printf in
      `rts/sm/GCAux.c::markCAFs`); or
  (b) build a stage2 *without* the keepCAFsForGHCi constructor —
      which probably breaks the GHC API but is fine for an
      M5.hs-style probe.

## Reasoning forward

Combining (1) "heap is consistent" with the bug fact "compile
output non-deterministically loses bindings" yields: **a pointer
that should be a GC root is not being scanned**.  The unscanned
data isn't evacuated; gen0 (where it lives) is reset; the blocks
get reused for fresh allocations; subsequent reads through the
unscanned root see the new data and fail to find what they expect.

Sanity check doesn't catch this because the unreachable data isn't
walked.

Candidate "missed root" structures, ranked by probability:

1. **CAF list (`dyn_caf_list`)**  — set up by `keepCAFsForGHCi`,
   walked by `markCAFs`.  9.2.8 changed the end-of-list test from
   `c != END_OF_CAF_LIST` to `((StgWord)c | 3) != END_OF_CAF_LIST`.
   Functionally identical for valid lists, but if list traversal is
   the bug, this is the place.
2. **Mutable list (`mut_list`)** — per-cap, holds cross-generation
   pointers.  IORefs (FastStringTable), MutableArrays, MVars all
   end up on this list when they hold pointers into younger gens.
3. **TSO stack** — the running thread's own stack.  GHC compiler
   passes hold a lot of state on the stack; if any stack-walk path
   misses a slot, that slot's pointer gets stale.
4. **Static objects** — text/data pointers from the binary itself.
5. **Stable pointers** — used by hs_init and friends.

## Next concrete probe (Step 3)

Add a printf to `rts/sm/GCAux.c::markCAFs` that counts how many CAFs
are in `dyn_caf_list` per GC and reports any case where the count
drops between GCs.  Single RTS rebuild (~17 min hadrian) +
stage2 rebuild + deploy (~15 min).  If the count IS dropping, that
isolates the bug to CAF-list management.  If the count is stable,
move on to mut_list scanning.
