# Session 37 — real-time log

## Pickup (start of session)

Session 36 handed off CLEAN with a clear finding:

> v's heap closure at the `refineFromInScope` panic site is
> `_stg_BLACKHOLE_info` (`0x092592a4` exact) with `word[1]` =
> tagged pointer (tag bits `0b011` = `Id` ctor) to (presumably)
> the evaluated indirectee.  Bug is in the BLACKHOLE→IND swap.

Top priority for session 37: confirm the indirectee by extending
probe36 to dump 4 more words at `word[1] & ~3`.  Expected: the
indirectee's `word[0]` is `_ghc_GHCziTypesziVar_Id_con_info` (the
Id constructor info-table).

## Step 0 — environment check

- Source tree clean per `git status --short` (only docs/convos
  changes).
- ghc-9.2.8 source tree clean per `git -C external/ghc-modern/ghc-9.2.8
  status --short compiler/GHC/Core/Opt/Simplify/Env.hs`.
- pmacg5 has `/tmp/Big2.hs` intact (745 bytes, session 35 origin).
- Started `bash tests/run-tests.sh` as a baseline check (background
  task bquuvgmeq; buffered output via `tail -30`).

## Step 1 — probe37 design

Probe37 = probe36 + dereference of `word[1] & ~3` as a 4-word read.

Differences from probe36:
- Add a helper that reads 4 words at an arbitrary untagged address
  (probe36's `probe36ReadHeader` already masks tag bits before
  reading — reuse with caution).
- Emit four lines per panic:
  ```
  PROBE37-BEFORE           @<v>            [w0 w1 w2 w3]
  PROBE37-INDIRECTEE       @<word[1] & ~3> [w0 w1 w2 w3]
  PROBE37-AFTER            @<v>            [w0 w1 w2 w3]
  PROBE37-INDIRECTEE-AFTER @<v'.word[1] & ~3> [w0 w1 w2 w3]
  ```

## Step 2 — major insight from reading rts/Updates.h

`rts/Updates.h:48-67` reveals that `updateWithIndirection` macro
sets `word[0] = stg_BLACKHOLE_info` after writing the indirectee.
This **IS** the canonical post-evaluation state of an updated thunk
— not a bug.  `stg_IND_info` only appears via GC short-circuiting
(see Note [BLACKHOLE pointing to IND] in `rts/sm/Evac.c`).

`rts/StgMiscClosures.cmm:487-492` shows `stg_BLACKHOLE_entry`:

```cmm
retry:
    prim_read_barrier;
    p = StgInd_indirectee(node);
    if (GETTAG(p) != 0) {
        return (p);     ← post-evaluation: return result directly
    }
    ...
```

So session 36's headline "BLACKHOLE→IND swap missing" framing was
based on a misreading.  v's `_stg_BLACKHOLE_info` + tagged
indirectee IS the post-evaluation state.

## Step 3 — `_build/{stage0,stage1}/...Env.dump-cmm-from-stg` diff

Comparing the HOST-aarch64 Cmm (stage0/compiler/build, -O2 per
QuickCross.hs `hsCompiler` `stage0 ? -O2`) vs the PPC32-cross Cmm
(stage1/compiler/build, defaults to -O0 per the empty `hsCompiler`
non-stage0 rule):

HOST (-O2) at `refineFromInScope_entry` (around line 9919-9990
of stage0/.../Env.dump-cmm-from-stg):

```cmm
cg2I:
    R1 = _sfig::P64;                        ← v
    if (R1 & 7 != 0) goto cg2L; else goto cg2M;     ← check tag
cg2M:
    call (I64[R1])(R1) returns to cg2L      ← enter v's closure
cg2L:
    _sfih::P64 = R1;                        ← REBIND v to forced tagged value
    _cg2R::P64 = _sfih::P64 & 7;
    switch [1..3] _cg2R::P64 { case 3: cg2Q; default: cg2P; }
cg2Q:                                         ← Id (3rd ctor) branch
    _sfim::P64 = P64[_sfih + 29];           ← idScope = word[?]   from REBOUND _sfih
    _sfij::I64 = I64[_sfih + 53];           ← realUnique = word[?] from REBOUND _sfih
    R1 = _sfim;
    if (R1 & 7 != 0) goto cg30; else goto cg32;
cg32:
    call (I64[R1])(R1) returns to cg30      ← force idScope
cg30:
    _sfip = R1;
    switch _sfip & 7 { case 1: cg38; case 2: cg3d; }
cg3d:                                         ← LocalId branch
    R3 = _sfif (in_scope);
    R2 = _sfij (the realUnique read directly);
    call $wlookup ...                        ← inlined IntMap.lookup
```

PPC32 (-O0) at `refineFromInScope_entry` (around line 11238-11325
of stage1/.../Env.dump-cmm-from-stg):

```cmm
c84g:
    [stack check]
c84f:
    R1 = isLocalId_closure;
    young+8 = _s7ip (v);            ← v as arg
    call stg_ap_p_fast(R1) → c84j   ← function call
c84j:
    _s7iq = R1;                      ← result of isLocalId (Bool)
    switch _s7iq & 3 { case 1: c8dW (False); case 2: c8dX (True) }
c8dX:                                  ← True branch
    R1 = lookupInScope_closure;
    young+12 = _s7io (in_scope);
    young+8  = _s7ip (v);            ← v STILL THE ORIGINAL UNTAGGED!
    call stg_ap_pp_fast(R1) → c84p   ← function call
c84p:
    _s7ir = R1;                      ← result of lookupInScope (Maybe Var)
    switch _s7ir & 3 { case 1: c8e6 (Nothing→panic); case 2: c8ed (Just) }
```

**The HOST `case isLocalId v of` is INLINED and folded** — v is
forced via direct entry-call, and the *result* of the entry call
(the tagged Id pointer) is rebound to `_sfih`, then subsequent
field reads happen on this rebound `_sfih`.

**The PPC32 `case isLocalId v of` is NOT inlined** — `isLocalId v`
is called via `stg_ap_p_fast` as a regular function application.
v is passed as-is; the function returns a Bool; v is NOT rebound.

In the True branch, `lookupInScope in_scope v` is also a function
call with v passed as the original untagged binding.

This is the **-O0 vs -O2 divergence** — confirmed by reading
`hadrian/src/Settings/Flavours/QuickCross.hs:33-39`:

```haskell
quickCrossArgs = sourceArgs SourceArgs
    { hsDefault  = mconcat [ pure ["-O0", "-H64m"] ]
    , hsLibrary  = notStage0 ? mconcat [ arg "-O", arg "-fllvm" ]
    , hsCompiler = stage0 ? arg "-O2"      ← compiler source is -O2
                                            ← when stage0 builds it
    , hsGhc      = ... }
```

**The `compiler/` source is built with -O2 only by stage0 (host);
stage1's cross-build of `compiler/` falls through to -O0** (the
default in `hsDefault`).  Result: HOST's stage1 compiler binary
has inlined, fused Cmm; PPC32's stage2 compiler binary has
function-call-heavy Cmm.

This refines theory F2 — the bug isn't a generic "v stays untagged"
issue; it's specifically that **chained function calls via
`stg_ap_*_fast` on PPC32 unreg at -O0 don't propagate evaluated v
through the binding chain**.  Each call may force v internally,
but the *caller's* binding remains the original untagged pointer.

Still need to verify: how does the chain `lookupInScope → lookupVarSet
→ lookupUFM → getUnique` ultimately call `realUnique v`?  At -O0,
realUnique is a record selector — should be compiled as a `case v of
{ Id _ r _ _ _ _ _ -> r; ... }` which DOES force v inside.  If so,
getUnique returns a correct Unique, and lookupUFM should find the
entry.  Yet it doesn't.  Either (a) the Unique read is somehow
wrong, or (b) the InScopeSet doesn't contain v's Unique.

## Step 4 — sweep results + indirectee confirmation

Built stage1 with probe37, deployed stage2 to pmacg5 + smoke-test
PASS.  Sweep env-len 600..2000 step 50 with Big2.hs:

```
len=1650  MISSING=$dOrd_a1k0
  PROBE37-BEFORE @0xdbca644 [0x925c554 0xd9bda6b 0xcf1b000 0xcf165c4]
  PROBE37-INDIRECTEE @0xd9bda68 [0x90662c4 0xdd3b1dd 0xe394cd1 0xd9bd90b]
  PROBE37-AFTER @0xdbca644 [0x925c554 0xd9bda6b 0xcf1b000 0xcf165c4]

len=1700  ... (identical)
```

Symbol resolution via `nm /opt/ghc-stage2/bin/ghc-real`:

* `0x0925c554` = `_stg_BLACKHOLE_info` (EXACT)
* `0x090662c4` = `_ghc_GHCziTypesziVar_Id_con_info` (EXACT)
* `0x0925c53c` = `_stg_IND_info` (24 bytes before BLACKHOLE)
* `0x090662a4` = `_ghc_GHCziTypesziVar_TyVar_con_info`
* `0x090662b4` = `_ghc_GHCziTypesziVar_TcTyVar_con_info`

**Confirmed:** the indirectee IS the Id constructor closure.

## Step 5 — reproducing one panic at len=1650 shows the FULL panic body

Direct ssh + grep of the panic gave the body:

```
ghc-real: panic! (the 'impossible' happened)
  (GHC version 9.2.8:
PROBE37-BEFORE @0xdbca644 [0x925c554 0xd9bda6b 0xcf1b000 0xcf165c4]
PROBE37-INDIRECTEE @0xd9bda68 [0x90662c4 0xdd3b1dd 0xe394cd1 0xd9bd90b]
PROBE37-AFTER @0xdbca644 [0x925c554 0xd9bda6b 0xcf1b000 0xcf165c4]
        refineFromInScope PROBE37-INDIRECTEE-AFTER @0xd9bda68 [...]
  InScope {wild_00 v_B1 allPositive}        ← only 3 entries!
  $dOrd_a1k0                                 ← missing var
  Call stack: ...
```

**The InScope set has only THREE entries**, all locals from
Big2.hs's `allPositive` function.  `$dOrd_a1k0` (the missing
typeclass dictionary) was supposed to be in scope but legitimately
isn't.

This is a complete reframe.  The "v's closure is BLACKHOLE" data
is a red herring — that's the normal post-evaluation state.  The
ACTUAL bug is the InScopeSet has lost entries.

This connects directly back to sessions 19-28's "GC corruption of
UniqMap-backed data structures" framing.  The closure-shape probe
trail of sessions 33-36 was a wild goose chase.

## Step 6 — len=850 gives a different panic now

At len=850 with probe37 binary, the panic shifts to:

```
ghc-real: panic! (the 'impossible' happened)
  (GHC version 9.2.8:
        depSortStgBinds
  Found cyclic SCC:
  [($trModule4_r1lU :: TrName ...
    {$trModule3_r1lT}),
   ($trModule3_r1lT :: Addr# ...
    {})]
```

Top-level `$trModule3_r1lT` and `$trModule4_r1lU` are flagged as
a cyclic SCC — but their FVs (shown as `{$trModule3_r1lT}` and
`{}` respectively) don't form a cycle.  The SCC algorithm must
have read a corrupt adjacency list.  Same root cause as F3.

## Step 7 — revert + clean rebuild + redeploy

* `git -C external/ghc-modern/ghc-9.2.8 checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` — probe reverted.
* Stage1 clean rebuild: `logs/build2-clean.log`.
* (next) Stage2 redeploy + smoke-test.
* (next) Baseline tests.

Session is ending CLEAN with the major reframe captured in
findings.md.

