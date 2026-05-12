# Session 27 findings — non-perturbing repro nailed; two distinct corruption modes; `-G1` partial workaround

## TL;DR

- **The clean-stage2 production bug is a deterministic non-perturbing
  repro:** `M5.hs +RTS -A1m -RTS` panics 10/10 times.  Confirmed on
  the clean rebuild + redeploy at session-26 end.
- **`+RTS -A1m -G1` (single-generation) fully suppresses the bug on
  small inputs** (M5.hs 10/10 OK, M5plus.hs 5/5 OK).  This is a new,
  cheaper-than-`-A1G` workaround for the M5.hs-sized panic family.
- **`-G1` does NOT suppress on slightly larger inputs.**  Big2.hs
  (a clean Haskell module ~30 LOC with Data.Map.Strict + small
  functions) compiles 10/10 OK at `-A1G`, but fails 9/10 at `-A1m`
  AND fails 10/10 at `-A1m -G1`.  -G1 changes the corruption
  signature, doesn't eliminate it.
- **The bug has at least two distinct manifestations** — the
  M5.hs-style STG-time panic family (depSortStgBinds /
  refineFromInScope / "variable not found") and the Big2.hs-style
  **typecheck-time corruption** (`* GHC internal error: 'swap' is
  not in scope during type checking, but it passed the renamer`).
  The TC-time variant is a genuinely new signature first observed
  this session — sessions 17–26 catalogued only the STG-time family.
- **Top hypothesis revised:** the STG-time variant is consistent
  with a missed-`mut_list`-entry / promotion-path bug (because
  `-G1` disables the whole older-gen mut_list scavenge code path
  via `scavenge_capability_mut_lists`'s `for (g = generations-1;
  g > N; g--)` loop being empty).  But the TC-time variant runs
  fine under `-G1` so EITHER (a) the bug has two mechanisms, OR
  (b) one mechanism but two victim data structures and the TC-env
  IntMap doesn't go through the gen-1 mut_list at all (it lives
  in gen-0 long enough to be fully corrupted by a different code
  path).  Need a single-cause vs two-cause discriminator.
- v0.12.0 ships unchanged.

## Data — clean-stage2 panic rates

All on pmacg5 (PowerMac G5 / Tiger 10.4.11) against `/opt/ghc-stage2/bin/ghc-real`,
which was rebuilt+redeployed clean at session-26 end (no PROBE patches,
matches v0.12.0).

### M5.hs (3 lines, no imports)

```haskell
module M5 where
five = (5::Int)
six = (6::Int)
```

| RTS flags             | iters | pass | fail | dominant symptom                          |
|-----------------------|------:|-----:|-----:|-------------------------------------------|
| `+RTS -A1G -RTS`      |   10  |  10  |   0  | control                                    |
| **`+RTS -A1m -RTS`**  |   10  |   0  |  10  | **depSortStgBinds cyclic SCC (9/10), 1× refineFromInScope** |
| **`+RTS -A1m -G1 -RTS`** |  10  |  10  |   0  | **bug suppressed**                         |
| `+RTS -A512k -RTS`    |   10  |   9  |   1  | 1× "variable not found"                    |
| `+RTS -A4m -RTS`      |   10  |  10  |   0  | suppressed (larger nursery)                |

### M5plus.hs (Data.List + Data.Map.Strict imports, 5 small bindings)

| RTS flags             | iters | pass | fail | symptom        |
|-----------------------|------:|-----:|-----:|----------------|
| `+RTS -A1m -RTS`      |    5  |   4  |   1  | 1× panic       |
| `+RTS -A1m -G1 -RTS`  |    5  |   5  |   0  | suppressed     |

### Big2.hs (same imports + 9 small typed functions; compiles fine on host)

| RTS flags             | iters | pass | fail | dominant symptom                                                   |
|-----------------------|------:|-----:|-----:|--------------------------------------------------------------------|
| `+RTS -A1G -RTS`      |   10  |  10  |   0  | control                                                             |
| **`+RTS -A1m -RTS`**  |   10  |   1  |   9  | **"`swap` not in scope during type checking, but it passed the renamer" (8×), 1× depSortStgBinds panic** |
| **`+RTS -A1m -G1 -RTS`** |  10  |   0  |  10  | **same "`swap` not in scope" (10×) — `-G1` does NOT suppress this variant** |

The "`swap`-not-in-scope" message includes the full `tcl_env`
(TcTypeEnv) at the moment of lookup, which lists 9 entries (4 outer
type-variable / argument bindings + 5 top-level identifiers, including
`topK` and `freqMap`).  `swap` is the `where`-bound local that should
be the 10th entry; it's missing.  See
[`../../../log/session27/Big2-a1m-g1.iter1.log`](../../../log/session27/Big2-a1m-g1.iter1.log)
for a full dump.

### Big.hs (Big2.hs with a deliberate type-error variant) — discarded

First attempt at a larger input had a real type error in `topK`
(returned `[(a, Int)]` instead of `[(Int, a)]`).  Cross stage2 at
`-A1m`: mix of real-type-error (good!), refineFromInScope panic,
and false-success.  At `-A1m -G1`: 5/5 "swap not in scope" — the
GC corruption overrode the real type error in the report.  Useful
data point that the corruption can mask or replace legitimate error
messages, but the noisy signal led us to rewrite as Big2.hs (which
compiles cleanly on host).

## The two corruption signatures

### STG-time family (sessions 17–26 catalogue)

- `depSortStgBinds Found cyclic SCC` — fires in `GHC.Stg.DepAnal`
  when SCC analysis of top-level STG bindings finds a cyclic SCC.
  Implies the FV set of a binding contains a name that's either a
  self-reference or a sibling in the same group, which shouldn't
  happen for top-level bindings.
- `refineFromInScope` — fires in
  `GHC.Core.Opt.Simplify.Env::refineFromInScope` when a local Var
  isn't found in the simplifier's InScopeSet.  Implies VarEnv /
  IntMap corruption.
- `GHC.StgToCmm.Env: variable not found` — `pprPanic` at line 153 of
  `compiler/GHC/StgToCmm/Env.hs`.  Same family — VarEnv lookup fails.

All three suppressed by `-G1` on M5.hs.

### TC-time family (newly observed this session)

- `GHC internal error: 'swap' is not in scope during type checking,
  but it passed the renamer` — fires in `GHC.Tc.Utils.Env` (or
  similar) when the renamer's OccName→Name map (`LocalRdrEnv`) and
  the typechecker's Name→TcTyThing map (`TcTypeEnv` / `tcl_env`)
  disagree.

NOT suppressed by `-G1`.  Big2.hs hits this 10/10 under
`+RTS -A1m -G1`.

## Why `-G1` suppresses one family but not the other

`scavenge_capability_mut_lists` at `rts/sm/Scav.c:1714`:
```c
for (uint32_t g = RtsFlags.GcFlags.generations-1; g > N; g--) {
    scavenge_mutable_list(cap->saved_mut_lists[g], &generations[g]);
    freeChain_sync(cap->saved_mut_lists[g]);
    cap->saved_mut_lists[g] = NULL;
}
```

With `generations=1` (`-G1`), the loop bound is `g > N` starting from
`g = 0`, so the loop body executes 0 times.  **The entire older-gen
mut_list scavenging code path is dead under `-G1`.**

If the bug were *only* "mut_list missing some entries → minor GCs
miss roots from older gens → stale gen-0 pointers in promoted gen-1
data," `-G1` would fix all cases.  The fact that Big2.hs's TC-time
corruption persists under `-G1` means there's a second mechanism
that doesn't depend on the older-gen mut_list.

Two plausible readings:

1. **Two bugs.**  A: missing mut_list entry on PPC32 (write-barrier
   bug, mutator-side, in Updates.cmm or similar).  B: a separate
   corruption that hits even with single-gen GC.  Both produce
   similar-looking IntMap / VarEnv damage, surfacing as different
   panic messages depending on which compilation phase is unlucky.

2. **One bug, two manifestations.**  A single GC bug — e.g.,
   `scavenge_one` mis-scavenging some closure type on PPC32 —
   corrupts heap state.  With `-G2`, gen-0 churn is fast and the
   STG/Simplifier data structures get caught.  With `-G1`,
   different objects survive different lengths and the
   typecheck-time IntMap gets caught instead.  Same heap-level
   damage; different victims.

The (1) reading predicts that fixing the mut_list path eliminates
the M5.hs panic family but leaves the Big2.hs TC-time error.  The
(2) reading predicts that fixing the (one) bug eliminates both.

## Upstream code surface relevant to the mut_list hypothesis

- `rts/sm/Scav.c::scavenge_capability_mut_lists` (line 1697): the
  loop that re-scavenges older-gen mut_lists.  Already inspected;
  no obvious PPC32-specific issue, but the work it does is iterate
  blocks (`bd`), walk slot pointers (`q = bd->start..bd->free`),
  and call `scavenge_one(*q)`.  If `bd->free` is wrong on PPC32
  for a freshly-stashed block, entries would be skipped.
- `rts/sm/Storage.c::dirty_MUT_VAR` (line 1402): the C-level write
  barrier.  Adds the closure to `mut_lists[g]` via
  `recordClosureMutated`.
- `rts/Updates.cmm` (not yet read): Cmm-level write barriers for
  IND_OLDGEN, BLACKHOLE updates, thunk → IND transitions.
- `rts/PrimOps.cmm::stg_writeMutVarzh` and friends: mutator-side
  mut_var update + dirty-flag.
- `compiler/GHC/StgToCmm/Bind.hs::emitBlackHoleCode`: where
  blackholing happens in Cmm.  If the BH write barrier on PPC32
  is wrong, gen-1 → gen-0 IND pointers might be missed.

## Open hypotheses for the TC-time corruption

Sessions 17–26 implicitly assumed all symptoms shared a cause.  The
new TC-time signature makes that less certain.  Some candidates that
don't require the mut_list path:

- **Static-closure / SRT scavenging.**  `scavenge_thunk_srt`,
  `scavenge_fun_srt`, `scavenge_static`.  These run on EVERY GC under
  `-G1` (since major_gc is always true with single gen) AND on major
  GCs under `-G2`.  If they have a PPC32-specific bug, both regimes
  would surface it.
- **Info-table contents.**  The static_link / static_objects chain
  uses STATIC_LINK macros that decode pointer fields from info
  tables.  PPC32 alignment / endian could subtly break the chain.
- **PAP / AP scavenging.**  `scavenge_PAP_payload` walks function-
  argument lists using `GET_FUN_LARGE_BITMAP` and friends.  If any
  bitmap decoding is wrong on PPC32, PAP/AP arguments could be
  mis-scavenged.  (Sessions 21–22 ruled out stack-frame bitmaps;
  PAP/AP bitmaps are a separate codepath.)
- **`scavenge_AP_stack`** for STACK-typed thunks.  Stacks-as-thunks
  use stack-frame bitmaps for their body — same machinery as session
  21 — but the *interaction* between the AP_STACK header and the
  bitmap-tagged stack inside might be wrong.

## What's next

Session 28 should pick from the following, in priority order:

1. **Distinguish "one bug, two victims" vs "two bugs."**  Cheapest
   test: re-introduce a slim RTS-side probe (e.g. count mut_list
   entries per GC, print at exit) that doesn't touch Haskell code
   at all.  Run on M5.hs `-A1m` and Big2.hs `-A1m`.  If the mut_list
   bookkeeping looks identical (same lengths, same per-gen counts)
   when one crashes and the other doesn't, the mut_list-missing
   hypothesis becomes harder to defend.
2. **Audit `rts/Updates.cmm` and `rts/PrimOps.cmm`'s
   `dirty_MUT_VAR_GC` / `recordClosureMutated` machinery for PPC32-
   isms.**  Especially: pointer arithmetic when growing the mut_list,
   info-pointer reads/writes in the write-barrier hot path.
3. **Read `scavenge_thunk_srt` / `scavenge_fun_srt` plus
   `scavenge_static`** with PPC32 eyes — alignment, endian,
   `STATIC_LINK` macro expansion.  If a bug there fires on every
   major GC (including `-G1`), it would explain why Big2.hs fails
   regardless of `-G`.
4. **Try `+RTS -A1m -G1 -F0.5`** (lower the promotion-survival
   factor) on Big2.hs to see if reducing object lifetime fixes
   the TC-time variant.

## Files added this session

- [`README.md`](README.md), `findings.md`, `HANDOFF.md`, `commits.md`
  — writeup.
- [`scripts/measure-panic-rate.sh`](scripts/measure-panic-rate.sh) —
  per-profile harness (M5.hs across `-A1G`, `-A1m`, `-A1m -G1`,
  `-A512k`, `-A4m`).
- [`scripts/g1-suppression-test.sh`](scripts/g1-suppression-test.sh)
  — M5plus.hs and Big.hs `-G1` suppression tests (Big.hs version
  had a real type error; results kept for context but Big.hs
  itself was discarded).
- [`scripts/g1-big2-test.sh`](scripts/g1-big2-test.sh) — Big2.hs
  (corrected) `-A1G`, `-A1m`, `-A1m -G1` suite.
- Run logs at [`../../../log/session27/`](../../../log/session27/)
  (gitignored).
