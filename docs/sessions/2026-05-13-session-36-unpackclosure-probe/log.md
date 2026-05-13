# Session 36 — real-time log

## Pickup (start of session)

Session 35 handed off with **CLEAN** state and a major reframing:
sessions 33-35's probes all read the WRAPPING THUNK's info-pointer
created by `aToWordzh (unsafeCoerce v :: Any)`, not v's actual
closure header.  Session 35's `findings.md` and `HANDOFF.md` both
diagnose this clearly.

Top priority for session 36, per HANDOFF: **redesign the probe to
read v's actual closure header**, then re-run the WHNF sweep.

Baseline tests (start of session): 30 PASS, 0 FAIL_COMPILE, 0
FAIL_RUN, 4 FAIL_OUTPUT — matches session 35's exit state.
Captured at `logs/baseline-tests.log`.

## Step 1 — pick the right primop

Session 35 HANDOFF suggested two options:

* **A.** Custom `.cmm` shim — invasive (`probeReadClosureHeaderzh`
  in `HeapPrim.cmm`); requires hadrian rebuild of `base`/`ghc-prim`.
* **B.** Use `GHC.Exts.unpackClosure#` directly — already exists,
  but COPIES the closure and pointers into two new arrays (heavy),
  plus may force x to WHNF (would defeat the BEFORE-vs-AFTER design).

I found a third, cleaner option while reading
`compiler/GHC/Builtin/primops.txt.pp`:

* **C.** Use `anyToAddr#` directly.  Signature is
  `a -> State# RealWorld -> (# State# RealWorld, Addr# #)` —
  polymorphic over any lifted type `a`, returns the closure pointer
  AS-IS without allocation, copying, or forcing.

`anyToAddr#` is documented as "essentially an `unsafeCoerce#`, but
implemented as an opaque primop so the core lint pass doesn't
complain.  Only appears in cmm (where the copy propagation pass
will get rid of it)."  Compiled in `compiler/GHC/StgToCmm/Prim.hs`
as:

```haskell
AnyToAddrOp -> \[arg] -> opIntoRegs $ \[res] ->
  emitAssign (CmmLocal res) arg
```

— a register-to-register move.  The argument `v` is passed directly;
no wrapping thunk needed.  Compare with the broken probe35 STG which
let-binds `unsafeCoerce v :: Any` to `sat_sNNN` thunk.

## Step 2 — stand-alone verifier

Wrote [`probe36_verify.hs`](probe36_verify.hs) with three test
fixtures:

1. T1 — known WHNF: `knownWhnf = Just 42`.  Expected: tagged
   constructor pointer; BEFORE == AFTER.
2. T2 — known thunk: `knownThunk = Just $! lengthListN 100`
   (CAF).  Expected: THUNK info-pointer BEFORE; indirection or
   constructor AFTER.
3. T3 — strict newtype: `simVar = SimVar 7`.  Expected: tagged
   constructor pointer; BEFORE == AFTER.

### STG dump verification

Compiled with `-ddump-stg-final -ddump-to-file`, inspected
`host-dumps/probe36_verify.dump-stg-final`:

```
anyToAddr#{v} [(x{v s2eM} ...) (ghc-prim:GHC.Prim.void#{...})]
```

Argument `x` is passed DIRECTLY to the primop.  **No `sat_sNNN`
wrapping thunk anywhere.**  Compare session 35:

```
sat_s7iu{v} :: Any Type
[LclId] = CCCS {(v{v s7ip} :: Var)} \u []
              unsafeCoerce (v{v s7ip})
case __primcall ghc aToWordzh [(sat_s7iu{v} ...)] :: Prim WordRep of ...
```

Re-verified under `-O` (matches `Simplify/Env.hs`'s build flags):
same clean STG, no wrapping thunk.  Logs at `host-dumps/` and
`host-dumps-O/`.

### Runtime behaviour on uranium host

```
T1-knownWhnf-BEFORE  : @0x102b7c5da [0x1028f62b8 0x102cd3629 0x3 0x102b368e0]
T1-knownWhnf-AFTER   : @0x102b7c5da [0x1028f62b8 0x102cd3629 0x3 0x102b368e0]
T2-knownThunk-BEFORE : @0x102b7c088 [0x1026a8980 0x0 0x0 0x0]
T2-knownThunk-AFTER  : @0x102b7c088 [0x102b36258 0x7000405758 0x0 0x1026a8980]
T3-simVar-BEFORE     : @0x102b7c5c1 [0x1026aaba0 0x102cd33f9 0x3 0x1028f62b8]
T3-simVar-AFTER      : @0x102b7c5c1 [0x1026aaba0 0x102cd33f9 0x3 0x1028f62b8]
```

* T1: tag bits 0b10 (Just); word[0] = constructor info-table.  Stable.
* T2: BEFORE word[0] = 0x1026a8980 (THUNK info); AFTER word[0] =
  0x102b36258 (indirection or constructor — same heap slot, in-place
  update by GC/seq).  Word[1] went from 0x0 to a target pointer.
  **`seq` actually updates the closure header in place.**
* T3: tag bits 0b01 (first ctor of SimVar); stable.

Captured in `logs/verify-host-O0.log` and `logs/verify-host-O1.log`.

### Runtime behaviour on pmacg5 (PPC32 unreg)

Cross-compiled with stage1, `scp`'d to pmacg5, ran with
`DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib`:

```
T1-knownWhnf-BEFORE  : @0x5df07a [0x5b58b0 0x3 0x5def70 0x0]
T1-knownWhnf-AFTER   : @0x5df07a [0x5b58b0 0x3 0x5def70 0x0]
T2-knownThunk-BEFORE : @0x5defc8 [0x57a8b8 0x0 0x5dea80 0x0]
T2-knownThunk-AFTER  : @0x1914e0a [0x5b58b0 0x57a8c4 0x0 0x0]
T3-simVar-BEFORE     : @0x5df071 [0x57a9d8 0x5b58b0 0x3 0x5def70]
T3-simVar-AFTER      : @0x5df071 [0x57a9d8 0x5b58b0 0x3 0x5def70]
```

Exactly analogous (modulo 32-bit space):

* T1: tag bits 0b10 (Just); word[0] = 0x5b58b0 = Just info-table.
* T2: BEFORE word[0] = 0x57a8b8 (THUNK info); AFTER different address
  0x1914e0a tag=0b10 (Just), word[0] = 0x5b58b0 (matches T1's
  Just info!).  `seq` evaluated and rebound.
* T3: tag bits 0b01 (first ctor); stable.

**Probe design validated on both host and PPC unreg target.  No
wrapping-thunk artifact.  THUNK vs constructor distinguishable
in word[0].**  Logs at `logs/verify-ppc.log`.

## Step 3 — integrate into refineFromInScope

Patched `compiler/GHC/Core/Opt/Simplify/Env.hs` to add
`probe36WhnfDump` and wire it into the existing `pprPanic` call
exactly the same way probe35 was wired.  Saved patch to
[`probe36-anyToAddr.patch`](probe36-anyToAddr.patch).

Build started…  (see `logs/build1-probe36.log`).

### Step 4 — build error fix-up

First build (build1-probe36.log) failed at `Env.hs:106: Could not
load module 'GHC.Prim'`.  GHC.Prim is in the hidden ghc-prim
package — compiler code must access primops via `GHC.Exts`
re-exports.  Fix: change `import GHC.Prim (int2Word#)` to
`import GHC.Exts (..., int2Word#)`.

Second build (build2-probe36.log) succeeded.  Note: 2 transient
`-Wunused-imports` warnings on `Data.Bits` — apparently a GHC false
positive (the `(.&.)` and `complement` operators are clearly used);
not blocking the build.

### Step 5 — deploy + sweep

Deploy via `scripts/deploy-stage2.sh pmacg5` succeeded: cross-built
stage2 main, rsync'd lib + binary, wrote settings, smoke-tested
("stage2 native ghc on Tiger: ok").  Log at
`logs/deploy1-probe36.log`.

Sweep via `scripts/sweep.sh pmacg5 600 2000 50` produced 4 captures
in 2 distinct env-len zones (sessions 35's 650-700 zone didn't
fire — different binary layout, different GC behavior).  Log at
`logs/sweep1-broad.log`:

```
len=850   MISSING=$dNum_a1ko   PROBE36-BEFORE @0xcf86198 [0x92592a4 0xccaf06b 0xd93265c 0xddfe4d0]
                                        AFTER @0xcf86198 [0x92592a4 0xccaf06b 0xd93265c 0xddfe4d0]
len=900   MISSING=$dNum_a1ko   PROBE36-BEFORE @0xcf86198 [0x92592a4 0xccaf06b 0xd93265c 0xddfe4d0]
                                        AFTER @0xcf86198 [0x92592a4 0xccaf06b 0xd93265c 0xddfe4d0]
len=1650  MISSING=$dOrd_a1k0   PROBE36-BEFORE @0xdbca6dc [0x92592a4 0xd9bda6b 0xcf1b000 0xcf165c4]
                                        AFTER @0xdbca6dc [0x92592a4 0xd9bda6b 0xcf1b000 0xcf165c4]
len=1700  MISSING=$dOrd_a1k0   PROBE36-BEFORE @0xdbca6dc [0x92592a4 0xd9bda6b 0xcf1b000 0xcf165c4]
                                        AFTER @0xdbca6dc [0x92592a4 0xd9bda6b 0xcf1b000 0xcf165c4]
```

**BEFORE == AFTER in every capture.  word[0] is exactly `0x92592a4`
across all captures.**

### Step 6 — symbol identification (`0x92592a4`)

`ssh pmacg5 'nm -n /opt/ghc-stage2/bin/ghc-real'` shows the
neighborhood:

```
0925928c S _stg_IND_info
092592a4 S _stg_BLACKHOLE_info        ← exact match
092592b0 S _stg_CAF_BLACKHOLE_info
092592bc S ___stg_EAGER_BLACKHOLE_info
```

**v's heap closure header is `_stg_BLACKHOLE_info`.**  Exact
address, no offset, no near-miss.

word[1] tag bits = `0b011` = 3 (third constructor of `Var`, which
is `Id`) → word[1] is a tagged pointer to the evaluated Id
closure (the indirectee).

This means: **v was evaluated, the result is at word[1], BUT the
BLACKHOLE→IND swap never happened.**  PPC unreg's update path
fails to write `_stg_IND_info` to word[0] after evaluation.

See [`findings.md`](findings.md) for full analysis.

### Step 7 — revert + clean rebuild + redeploy

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` reverts
  the probe.
* Stage1 rebuild: `logs/build3-clean.log`.
* Stage2 redeploy: `logs/deploy2-clean.log`.
* Smoke-test PASS.

Session ended CLEAN.
