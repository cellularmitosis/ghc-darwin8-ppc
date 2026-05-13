# Session 37 findings — major reframe: BLACKHOLE+indirectee is *normal*; the real bug is InScopeSet corruption

## TL;DR

Probe37 — extending probe36 with a follow-through to `word[1] & ~3`
(the indirectee) — revealed that the panic site is *not* a thunk-
update bug at all.  Three findings, in order of importance:

1. **v's BLACKHOLE+tagged-indirectee state is the canonical post-
   evaluation state of an updated thunk.**  Session 36's "BLACKHOLE→IND
   swap missing" framing was wrong — based on a misreading of
   `rts/Updates.h`'s `updateWithIndirection` macro.
2. **The indirectee at `word[1] & ~3` is a real, fully-evaluated `Id`
   constructor closure.**  Confirmed via `nm`: `word[0]` =
   `_ghc_GHCziTypesziVar_Id_con_info` exact match.
3. **The panic site's `InScope` set legitimately doesn't contain v.**
   Only 3 entries (`{wild_00, v_B1, allPositive}`), all local
   bindings from the function being simplified.  The missing
   `$dOrd_a1k0` (typeclass dictionary) should have been added to
   the in-scope set by the simplifier descent, but is absent.

This connects the dragon back to sessions 19-28's GC-corruption-of-
data-structures framing.  **The closure-shape investigation of
sessions 33-36 was a wild goose chase.**

## F1.  `updateWithIndirection` and the canonical post-eval state

`rts/Updates.h:48-67` (Cmm version):

```c
#define updateWithIndirection(p1, p2, and_then) \
    W_ bd;                                                      \
    prim_write_barrier;                                         \
    bd = Bdescr(p1);                                            \
    if (bdescr_gen_no(bd) != 0 :: bits16) {                     \
      ...                                                       \
      recordMutableCap(p1, TO_W_(bdescr_gen_no(bd)));           \
      TICK_UPD_OLD_IND();                                       \
    } else {                                                    \
      TICK_UPD_NEW_IND();                                       \
    }                                                           \
    OVERWRITING_CLOSURE(p1);                                    \
    StgInd_indirectee(p1) = p2;                                 \
    prim_write_barrier;                                         \
    SET_INFO(p1, stg_BLACKHOLE_info);                           \
    LDV_RECORD_CREATE(p1);                                      \
    and_then;
```

After thunk-update, the closure is:

```
word[0] = stg_BLACKHOLE_info        (info pointer)
word[1] = tagged-pointer-to-result  (indirectee)
```

**`stg_IND_info` does NOT appear here.**  `stg_IND_info` is reserved
for the GC's old-generation indirection short-circuit path (see
Note [BLACKHOLE pointing to IND] in `rts/sm/Evac.c`).

`rts/StgMiscClosures.cmm:479-531`'s `stg_BLACKHOLE_entry`:

```cmm
INFO_TABLE(stg_BLACKHOLE,1,0,BLACKHOLE,"BLACKHOLE","BLACKHOLE")
    (P_ node)
{
    ...
retry:
    prim_read_barrier;
    p = StgInd_indirectee(node);
    if (GETTAG(p) != 0) {
        return (p);   ← post-evaluation: just return the result
    }
    ...    ← otherwise: BLOCKING_QUEUE/TSO blocking-evaluator case
}
```

The non-zero tag of the indirectee signals "evaluation completed,
the result is at `p`."  The entry code returns the tagged result;
callers proceed with the WHNF value.

So a BLACKHOLE_info closure with a tagged indirectee IS a valid
WHNF closure for any caller that goes through the entry code (case-
matching, function application, seq).

**This invalidates session 36's "BLACKHOLE→IND swap missing"
diagnosis.  The probe data was correct; the interpretation was
wrong.**

## F2.  Probe37 — extended capture confirms indirectee is a real Id

`probe37-indirectee.patch` adds a 4-word dump at `word[1] & ~3`
(the untagged indirectee pointer) on top of probe36's
BEFORE/AFTER lines.

Sweep on pmacg5 with the same Big2.hs trigger (env-len 600..2000
step 50, `+RTS -A1m -G1`) captured 2 panics in the 1650/1700 zone
(the 850/900 zone shifted to a different trigger — see F3).
Both captures show:

```
PROBE37-BEFORE     @0xdbca644 [0x925c554 0xd9bda6b 0xcf1b000 0xcf165c4]
PROBE37-INDIRECTEE @0xd9bda68 [0x90662c4 0xdd3b1dd 0xe394cd1 0xd9bd90b]
PROBE37-AFTER      @0xdbca644 [0x925c554 0xd9bda6b 0xcf1b000 0xcf165c4]
PROBE37-INDIRECTEE-AFTER @0xd9bda68 [0x90662c4 0xdd3b1dd 0xe394cd1 0xd9bd90b]
```

Symbol resolution via `nm /opt/ghc-stage2/bin/ghc-real`:

| address      | symbol                                          |
|--------------|-------------------------------------------------|
| `0x0925c554` | `_stg_BLACKHOLE_info` (exact)                   |
| `0x0925c53c` | `_stg_IND_info`                                 |
| `0x090662c4` | `_ghc_GHCziTypesziVar_Id_con_info` (exact)      |
| `0x090662b4` | `_ghc_GHCziTypesziVar_TcTyVar_con_info`         |
| `0x090662a4` | `_ghc_GHCziTypesziVar_TyVar_con_info`           |

So:

- v's `word[0]` = `_stg_BLACKHOLE_info` (post-evaluation state).
- v's `word[1] = 0xd9bda6b` is a tagged pointer (tag bits `0b011`
  = 3) to the indirectee at `0xd9bda68`.
- The indirectee's `word[0]` = `_ghc_GHCziTypesziVar_Id_con_info`
  exactly.

The indirectee's payload follows the Id constructor layout:

| word | field      | observed value | interp                        |
|------|------------|----------------|-------------------------------|
| 0    | info       | `0x090662c4`   | `Id_con_info`                 |
| 1    | varName    | `0xdd3b1dd`    | tagged Name ptr (tag `0b01`)  |
| 2    | realUnique | `0xe394cd1`    | unboxed Int# (Unique = 238M)  |
| 3    | varType    | `0xd9bd90b`    | tagged Type ptr (tag `0b011`) |

**v WAS evaluated.  The result IS a real Id constructor closure
with sensible Name/Unique/Type fields.  The thunk-update mechanism
worked exactly as designed.**

## F3.  The panic message reveals the *real* bug: InScopeSet has only 3 entries

The full panic message body at len=1650:

```
ghc-real: panic! (the 'impossible' happened)
  (GHC version 9.2.8:
PROBE37-BEFORE @0xdbca644 [...]
PROBE37-INDIRECTEE @0xd9bda68 [0x90662c4 ...]
PROBE37-AFTER @0xdbca644 [...]
        refineFromInScope PROBE37-INDIRECTEE-AFTER @0xd9bda68 [...]
  InScope {wild_00 v_B1 allPositive}     ← only 3 entries!
  $dOrd_a1k0                              ← the missing var
  Call stack: ...
```

**The InScope set legitimately contains only `{wild_00, v_B1,
allPositive}`** — 3 entries, all local bindings within Big2.hs's
`allPositive` function:

- `wild_00`: a case-binder (`case ... of wild { ... }`).
- `v_B1`: a local Var (sequence B1).
- `allPositive`: the function itself (referenced by recursive call).

`$dOrd_a1k0` is the `Ord`-class dictionary, which SHOULD be in
scope at this point (Big2.hs's `topK` uses `Data.List.sort` which
requires `Ord`).  It's missing from the in-scope set.

Either:

(α) **The simplifier never added `$dOrd_a1k0` to seInScope.**
    Would manifest on host too — so not this.

(β) **GC corruption dropped `$dOrd_a1k0` from the UniqFM-backed
    InScopeSet between when it was added and when refineFromInScope
    queries it.**

(β) is the working theory.  This connects directly back to sessions
19-28's "GC corruption affects UniqMap-backed data structures"
framing.  The InScopeSet is built on `InScope (UniqSet Var)
(UniqFM ElemKey Var)`.

## F4.  At len=850, a *different* panic fires (`depSortStgBinds`)

The 850-900 zone from session 36 (which there missed `$dNum_a1ko`)
now triggers a different panic with the probe37 binary:

```
ghc-real: panic! (the 'impossible' happened)
  (GHC version 9.2.8:
        depSortStgBinds
  Found cyclic SCC:
  [($trModule4_r1lU :: TrName
    [GblId, Unf=OtherCon []] =
        CCS_DONT_CARE TrNameS! [$trModule3_r1lT];,
    {$trModule3_r1lT}),
   ($trModule3_r1lT :: Addr#
    [GblId, Unf=OtherCon []] =
        "Big2"#;,
    {})]
```

`$trModule3_r1lT` and `$trModule4_r1lU` are top-level GHC-generated
module-tracking metadata.  `$trModule4` depends on `$trModule3`
(uses it for the `TrNameS` constructor), and `$trModule3` is a
plain `Addr#` literal — no free vars.  These SHOULD NOT form a
cyclic SCC; the correct result is `AcyclicSCC $trModule3` followed
by `AcyclicSCC $trModule4`.

The SCC algorithm in `compiler/GHC/Stg/DepAnal.hs:144`:

```haskell
get_binds (AcyclicSCC bind) = [bind]
get_binds (CyclicSCC binds) =
  pprPanic "depSortStgBinds"
           (text "Found cyclic SCC:" $$ ppr binds)
```

For a CyclicSCC to fire here, depAnal must have determined there's
a back-edge in the dependency graph — but the printed FVs don't
show one (`$trModule3`'s FVs are `{}`).  Either:

- The dependency graph's adjacency list was corrupted after FVs
  were computed (UniqFM corruption).
- depAnal's graph construction read stale memory and got a self-
  reference for `$trModule3`.

Both are consistent with the same GC-of-UniqMap corruption
hypothesis as F3.

## F5.  Connection back to sessions 19-28

Sessions 19-28 documented multiple panic shapes from the same
underlying bug:

- `depSortStgBinds` cyclic SCC (sessions 17, 23, 27, NOW 37).
- `refineFromInScope` (sessions 17, 27, 28, NOW 37).
- `variable not found` (session 17).
- `swap not in scope` (TC-time, session 27).

Sessions 19-22 ruled out: bitmap codegen, `mkLivenessBits`,
`stackMapToLiveness`, `LayoutStack`, StackRep.  Session 26 ruled
out: BS-pinning invariant.  Sessions 28-29: closure-type
histogram is uniform between PASS and FAIL GCs.  Session 29:
filename-sensitive (heap-layout-dependent).

Sessions 33-36 chased a closure-shape probe theory that turned
out to be a misreading of normal post-evaluation state.  **Session
37 dissolves that thread.**

The actual bug remains GC-corruption-of-UniqMap-data-structures.
The framing from session 28 — "one bug, multiple victim data
structures, all UniqMap-backed" — is the right one.

## F6.  Concrete next-session targets

1.  **Instrument InScopeSet construction.**  Patch
    `addNewInScopeIds`, `setInScopeFromE`, `setInScopeFromF` in
    `Simplify/Env.hs` to dump `size in_scope` + a digest of
    elements every time it changes.  Trigger Big2.hs `-A1m -G1`
    and find which call to refineFromInScope sees the truncated
    set.

2.  **Instrument seIdSubst too** — both seInScope and seIdSubst
    are UniqMap-backed.  Both might be losing entries.

3.  **Bisect the simplifier passes.**  Run with `-dverbose-core2core`
    and compare host vs PPC at each simplifier iteration to see
    which iteration introduces the missing-dictionary state.

4.  **Re-read sessions 28-29's GC-trace data with fresh eyes.**
    The "uniform closure-type histogram" finding plus the
    "filename-sensitive triggering" finding point at allocator
    state / block-boundary geometry on the heap.  Look at
    `MAYBE_GC()` macro invocations during `extendInScopeSet`-
    family functions on PPC32 specifically.

5.  **Try the InScopeSet probe with `-A8m` or `-A16m`**: if the
    bug is GC-frequency-dependent (and -A1m-G1 is just a fast
    repro), increasing the nursery should eliminate panics in
    Big2.hs.  Compare InScopeSet sizes across `-A` values.

## F7.  What probe37 ruled out

* **"BLACKHOLE→IND swap missing" hypothesis from session 36** —
  ruled out by reading `updateWithIndirection` macro semantics.
  BLACKHOLE+tagged-indirectee IS the canonical post-eval state.
* **"PPC unreg thunk-update path emits wrong info-pointer"** —
  ruled out; the macro doesn't write IND, it writes BLACKHOLE.
* **"Indirectee garbage" hypothesis** — ruled out;
  `nm` confirms `_ghc_GHCziTypesziVar_Id_con_info`.
* **"v's evaluation didn't complete"** — ruled out; v IS a fully-
  evaluated Id with sensible Name/Unique/Type/etc.

## F7b.  Panic-shape × env-len table (clean stage2, post-revert)

`scripts/sweep-panic-shape.sh pmacg5 600 2000 50` against the clean
v0.12.0+ stage2 (post-session-37 redeploy) shows three distinct
panic shapes across the env-len sweep:

| env-len   | shape           | missing      | InScope (size)                                  |
|-----------|-----------------|--------------|-------------------------------------------------|
| 650, 700  | refineFromInScope | `$dNum_a1kb` | `{wild_00 v_B1 n_aXk freqMap shift}` (5)      |
| 750, 800  | swap-tc         | (TC time)    | (TC error, no InScope)                          |
| 950, 1000 | other-rts       | (?)          | (depSortStgBinds likely)                        |
| 1050-1600 | swap-tc         | (TC time)    | (TC error, no InScope)                          |
| 1650, 1700| refineFromInScope | `$dOrd_a1k0` | `{wild_00 v_B1 allPositive}` (3)             |
| 1750-2000 | swap-tc         | (TC time)    | (TC error, no InScope)                          |

(`tests/RESULTS.md` baseline tests after session-37 redeploy show
the test battery passes the same way as before: 30 PASS, 0
FAIL_RUN, 4 FAIL_OUTPUT — same as session 36's exit state.  See
`logs/baseline-tests-end-rerun.log`.)

### Observations

1.  **Two distinct refineFromInScope contexts**, each with a small
    in-scope set:
    - **`freqMap` / `shift` context** (env-len 650-700) — 5 entries,
      missing `$dNum_a1kb` (Num dictionary, used by `(+)`).
    - **`allPositive` context** (env-len 1650-1700) — 3 entries,
      missing `$dOrd_a1k0` (Ord dictionary, used by `sort`).
2.  **The majority of failing env-lens trigger TC-time `swap not in
    scope`** — `swap` is also missing from the renamer/typechecker's
    `GlobalRdrEnv` (also UniqFM-backed).  Same underlying corruption,
    different victim.
3.  **`other-rts` (env-len 950-1000)** likely fires `depSortStgBinds`
    (per the len=850 manual repro in F4).  Yet another UniqFM-backed
    victim (the dependency graph's adjacency list).
4.  **No env-len in the 600..2000 range produces a clean compile.**
    Big2.hs `-A1m -G1` panics deterministically at every step.  Only
    the *flavour* of panic varies by env-len.
5.  The InScope set's missing variable is a TYPECLASS DICTIONARY in
    both refineFromInScope cases.  Dictionaries are heap-allocated
    THUNK_1_0 closures created late in compilation (specializer,
    desugarer); they're likely candidates for GC eviction if the
    allocator misses re-evacuating them.

## F8.  What it didn't (yet) rule out

The bug is upstream of refineFromInScope.  Need to identify:

- Where the InScopeSet for the simplifier descent is constructed.
- Whether it's correctly constructed and then loses entries (GC),
  or whether it's constructed wrong upstream.
- Why the bug is filename-sensitive (session 29).
- Whether it's specific to the IntMap-backed UniqFM or affects
  other UniqMap variants too.
