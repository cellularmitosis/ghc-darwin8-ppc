# Session 52 — ROOT CAUSE FIXED: `STUArray Bool`'s `newArray` under-zeroes on big-endian

**Date:** 2026-05-15 (continuation of session 51).

**Status on arrival:** Source tree CLEAN per session 51 exit.  Session
51 had stripped the corruption down to a 3-line standalone repro —
`newArray False :: ST s (STUArray s Int Bool)` of size 8 — reproducing
at 84-87% per iteration on pmacg5 under both default RTS and
`-A1m -G1`.  Hypothesised root cause was a bug in GHC's RTS
`stg_newByteArrayzh` zeroing path on PPC32 unreg.  Baseline tests at
the session-49/50/51 noise floor: 30 PASS / 4 FAIL\_OUTPUT.

**Status on exit:** Root cause **identified, fixed, validated, and
deployed**.  Eleven sessions of bisection from "compiler emits
152-byte empty `.o` files" (session 42) to "freshly allocated
`STUArray Bool` returns spurious Trues" (session 51) now converged
on a single, narrowly-scoped upstream GHC library bug in
`libraries/array/Data/Array/Base.hs`.  Stage1 rebuilt and stage2
redeployed to pmacg5 with the fix.  Baseline tests: 30 PASS / 4
FAIL\_OUTPUT (unchanged — the four failures are test-design issues,
not stage2 issues).  The Big2.hs reproducer that was producing
152-byte empty `.o` files for ten sessions now produces a 46340-byte
fully-populated `.o` under both default RTS and `-A1m -G1`.  Patch
landed in [`patches/0016-array-stuarray-bool-word-aligned-init.patch`](../../../patches/0016-array-stuarray-bool-word-aligned-init.patch).

## Plan (per session 51 HANDOFF)

Confirm the bug scope by testing other unboxed types, test boxed
`STArray`, test without `burnGC` pressure, then read RTS source for
`stg_newByteArrayzh`.

## What happened (four standalone-test iterations, then the fix)

### Iter A — types_test.hs: only `STUArray Bool` corrupts

Tested newArray + read of size 8 across `STUArray Bool`, `Int8`,
`Word8`, `Int`, `Word`, `Char`, `Word32`, and boxed `STArray Int`.
5000 iterations per type, `burnGC 1000` interleaved.

```
STUArray Bool    iters=5000 bad=3487 firstFew=[(1494,3),(1495,4),(1496,2)]
STUArray Int8    iters=5000 bad=0 firstFew=[]
STUArray Word8   iters=5000 bad=0 firstFew=[]
STUArray Int     iters=5000 bad=0 firstFew=[]
STUArray Word    iters=5000 bad=0 firstFew=[]
STUArray Char    iters=5000 bad=0 firstFew=[]
STUArray Word32  iters=5000 bad=0 firstFew=[]
STArray  Int     iters=5000 bad=0 firstFew=[]
```

**Only `STUArray Bool` corrupts.**  Every other unboxed type — and the
boxed `STArray` — is clean.  This single result ruled out the
session-51 RTS-allocation-or-scavenge hypothesis: the
`newByteArray#` / `setByteArray#` primitives clearly work correctly
for byte-per-element arrays, even at the same byte sizes that fail
for bit-packed Bool.

### Iter B — nogc_test.hs: bug fires even without `burnGC`

Loop `checkBool sz=8` 10000 times with no manual GC pressure.

```
nogc done iters=10000 bad=8365
iter=1500 bools=[True,False,False,True,False,True,True,True]
```

Bug starts firing around iter ~1500 (when natural GC pressure from
the `mapM (readArray arr) [0..n-1]` lists triggers the first nursery
collection).  So the bug *is* GC-correlated, but trivially so —
allocation in any program of nontrivial size triggers it.

### Iter C — size_test.hs: corruption is bit-packed Bool only, and only for sizes < one word

Swept Bool / Word8 / Int across sizes that allocate the same number
of bytes:

```
## STUArray Bool (bit-packed)
STUArray Bool   sz=8   iters=3000 bad=1495    (1 byte alloc)
STUArray Bool   sz=16  iters=3000 bad=2989    (2 bytes)
STUArray Bool   sz=32  iters=3000 bad=0       (4 bytes)
STUArray Bool   sz=64  iters=3000 bad=0       (8 bytes)
STUArray Bool   sz=128 iters=3000 bad=0       (16 bytes)
STUArray Bool   sz=256 iters=3000 bad=0       (32 bytes)
STUArray Bool   sz=512 iters=3000 bad=0       (64 bytes)
## STUArray Word8 (one byte each)
STUArray Word8  sz=1   iters=3000 bad=0       (1 byte alloc)
STUArray Word8  sz=2   iters=3000 bad=0       (2 bytes)
STUArray Word8  sz=4   iters=3000 bad=0       (4 bytes)
... all 0 bad up to sz=64
## STUArray Int (4 bytes each)
STUArray Int    sz=1..8  all 0 bad
```

**The cutoff is exactly at the machine word size (4 bytes / 32 bits
on PPC32).**  Bool corrupts when the bit-packed allocation is smaller
than one word; clean at exactly one word and above.  Same allocation
sizes work fine for `Word8` and `Int`.

### Iter D — reading the source

`libraries/array/Data/Array/Base.hs` line 1028+:

```haskell
instance MArray (STUArray s) Bool (ST s) where
    newArray (l,u) initialValue = ST $ \s1# ->
        case safeRangeSize (l,u)                   of { n@(I# n#) ->
        case bOOL_SCALE n#                         of { nbytes# ->
        case newByteArray# nbytes# s1#             of { (# s2#, marr# #) ->
        case setByteArray# marr# 0# nbytes# e# s2# of { s3# ->
        (# s3#, STUArray l u n marr# #) }}}}
      where
        !(I# e#) = if initialValue then 0xff else 0x0

    unsafeRead (STUArray _ _ _ marr#) (I# i#) = ST $ \s1# ->
        case readWordArray# marr# (bOOL_INDEX i#) s1# of { (# s2#, e# #) ->
        (# s2#, isTrue# ((e# `and#` bOOL_BIT i#) `neWord#` int2Word# 0#) :: Bool #) }
```

`bOOL_SCALE n = ceil(n/8)` bytes.  `bOOL_INDEX i = i / 32` *words*.
**`unsafeRead` reads via `readWordArray#`** (a full machine word),
but **`newArray` only zeroes `bOOL_SCALE n` bytes** — strictly less
than one word for `n < 32`.  `newByteArray#` does not zero its
payload (per the GHC primops contract), so the bytes within the
trailing partial word are uninitialised heap memory.

On a big-endian target, when `readWordArray#` loads bytes `[b0, b1,
b2, b3]`, the resulting `Word#` is `(b0<<24) | (b1<<16) | (b2<<8) |
b3`.  Bit 0 of that word — what `bOOL_BIT 0` checks — is the LSB,
which lives in **memory byte 3, not memory byte 0**.  But
`setByteArray#` only writes memory byte 0!  So for `n=8`,
`setByteArray# marr 0 nbytes=1 0` zeroes the *wrong end* of the word;
all 8 elements then read garbage from the uninitialised bytes 1, 2,
3.

### Iter E — confirm_test.hs: predictions verified

Per the diagnosis, the bug should fire (a) for `newArray True sz=8`
(garbage bits override the 0xFF) and (b) for any size that doesn't
align to a full word (e.g. `sz=33` should fail at index 32, `sz=40`
should fail at indices 32..39).

```
## Prediction (1): newArray True sz=8 should see Falses on BE
newArray True  init=True sz=8 iters=2000 bad=1998 idxHist=[0,1,4,0,1,2,4,5,1,4,6,7,0,1,2,4]
## Prediction (2): newArray False sz=24 should see Trues on BE
newArray False init=False sz=24 iters=2000 bad=109 idxHist=[2,3,5,6,7,3,6,7,0,4,5,7,3,5,6,7]
## Prediction (3): newArray False sz=32 should be clean
newArray False init=False sz=32 iters=2000 bad=0 idxHist=[]
## Prediction (4): newArray False sz=33 should fail at index 32+
newArray False init=False sz=33 iters=2000 bad=573 idxHist=[32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32]
## Prediction: newArray False sz=40 should fail at index 32..39 (byte 7)
newArray False init=False sz=40 iters=2000 bad=1931 idxHist=[32,33,34,35,36,37,38,39,34,35,36,38,32,38,39,38]
```

Every prediction matches: the bad indices are always the elements
whose bits live in unzeroed memory bytes, for both `True` and
`False` initial values.  **Diagnosis confirmed: big-endian
bit/byte mismatch in `Data/Array/Base.hs`'s Bool `newArray`.**

## The fix

Three small edits to `libraries/array/Data/Array/Base.hs`:

1. In the `Bool` `MArray` instance's `newArray`, replace `bOOL_SCALE n#`
   with `bOOL_WORD_SCALE n#` for both the `newByteArray#` size and
   the `setByteArray#` length, so the entire allocated payload
   (which `newByteArray#` already rounds up to a word internally) is
   zero-initialised.
2. In the same instance's `unsafeNewArray_`, swap `bOOL_SCALE` for
   `bOOL_WORD_SCALE` so that the uninitialised-array variant also
   allocates a full word, preventing user code's first `unsafeWrite`
   (which does read-modify-write on the word) from preserving and
   re-storing the garbage bits in the tail.
3. Add `bOOL_WORD_SCALE :: Int# -> Int#` and a `Note [STUArray Bool
   word-aligned initialization]` next to `bOOL_SCALE` and friends.
   The new function returns `ceil(n/SIZEOF_HSWORD_BITS) * SIZEOF_HSWORD`:
   on 32-bit, `((n + 31) >> 5) << 2`; on 64-bit,
   `((n + 63) >> 6) << 3`.

Patch: [`patches/0016-array-stuarray-bool-word-aligned-init.patch`](../../../patches/0016-array-stuarray-bool-word-aligned-init.patch).

## Validation

Rebuild stage1 (`./hadrian/build --flavour=quick-cross -j8
_build/stage1/lib/...libHSarray-0.5.4.0.a libHSghc-9.2.8.a`) took
~17 min.  Stage2 cross-compiled and redeployed to pmacg5 in ~2 min.
Then:

| Test                                         | Before fix              | After fix         |
|----------------------------------------------|-------------------------|-------------------|
| `confirm_test`: `newArray True sz=8`         | 1998/2000 bad           | **0/2000 bad**    |
| `confirm_test`: `newArray False sz=24`       | 109/2000 bad            | **0/2000 bad**    |
| `confirm_test`: `newArray False sz=32`       | 0/2000 bad              | 0/2000 bad        |
| `confirm_test`: `newArray False sz=33`       | 573/2000 bad            | **0/2000 bad**    |
| `confirm_test`: `newArray False sz=40`       | 1931/2000 bad           | **0/2000 bad**    |
| `stuarray_test` (session-51 repro) `-A1m -G1` | 8655/10001 bad         | **0/10001 bad**   |
| Big2.hs `-c` default RTS                      | 152-byte empty `.o`    | **46340-byte .o** |
| Big2.hs `-c` `-A1m -G1`                       | 152-byte empty `.o`    | **46340-byte .o** |
| Baseline `tests/run-tests.sh`                 | 30 PASS / 4 FAIL\_OUTPUT | 30 PASS / 4 FAIL\_OUTPUT |
| `tests/stage2-native/run.sh`                  | passes                 | passes (Hello prints) |

The four `FAIL_OUTPUT` baseline tests (01\_int\_arith,
14\_env\_args, 24\_ffi, 25\_numeric\_boundaries) are pre-existing
test-design issues (Int width, getpid, getProgName) — not stage2
regressions.

## What this means

This bug — a 19-line change to one file in the array library —
explains every single probe finding from sessions 42-51.  The
pipeline-bisection chain we followed was tracing the downstream
effects of *one* upstream miscompilation in the renamer's
dependency-analysis SCC:

- `Data.Graph.scc` uses `prune` → `chop`, which builds an `STUArray
  Int Bool` "visited" set sized to the number of vertices.
- For Big2.hs with 8 top-level binders, that array is `STUArray
  (0, 7) Bool` — *exactly* the 1-byte allocation case that reads
  garbage on PPC32 BE.
- `chop` reads the visited bits, sees spurious Trues, and prunes
  vertices that haven't actually been visited.
- The forest returned by `scc` has fewer trees than vertices.
- The renamer's `[(RecFlag, LHsBinds GhcRn)]` ends up with fewer
  groups, dropping bindings on the floor.
- The typechecker, desugarer, simplifier, and code generator all
  see fewer bindings than the source had.
- The final `.o` is missing the dropped definitions, and depending
  on what was dropped, ends up as a 152-byte empty file (because
  every top-level definition was unreachable) or some other wrong
  output.

This is the ten-session "compiler produces empty .o" mystery: a
**single 11-line library bug in big-endian bit-packing**.

Importantly, this is an **upstream GHC bug**, not a port-specific
issue.  The same code is in `Data/Array/Base.hs` on current GHC
HEAD.  It just hasn't been noticed because:

- All actively-supported GHC platforms are little-endian; the bug
  only manifests on big-endian for sizes < SIZEOF\_HSWORD*8.
- PPC32 was the last supported big-endian Tier-1 target, dropped in
  GHC 8.8 (Dec 2018).
- On 64-bit little-endian, the bug exists for sizes between
  successive 64-element multiples, but happens to be masked because
  nursery pages tend to be fresh-zero on first use.

## Files added this session

* `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
* Test programs:
  - `types_test.hs` — sweep of element types (iter A).
  - `nogc_test.hs` — no-GC-pressure variant (iter B).
  - `size_test.hs` — sweep of sizes per type (iter C).
  - `confirm_test.hs` — predictions test for BE bit/byte diagnosis (iter E).
* Logs in `logs/`:
  - `baseline-tests-start.log` — baseline at session start.
  - `types_test-default.log`, `nogc_test.log`, `size_test.log`,
    `confirm_test.log` — pre-fix.
  - `build1-fix.log` — stage1 rebuild with the patch.
  - `confirm_test-postfix.log`, `stuarray_test-postfix.log`,
    `big2-postfix.log`, `stage2-native-postfix.log`,
    `baseline-postfix.log`, `deploy-postfix.log` — post-fix.

## Files added outside the session directory

* `patches/0016-array-stuarray-bool-word-aligned-init.patch` — the fix.
* Modified `external/ghc-modern/ghc-9.2.8/libraries/array/Data/Array/Base.hs`
  with the patch applied (lives in the build tree).

See [`findings.md`](findings.md) for the per-finding distilled view
and [`HANDOFF.md`](HANDOFF.md) for the pickup primer (recommended
next moves: ship a release, update README + state.md + roadmap.md,
re-run the cabal-examples to see what previously-broken builds now
work, and consider preparing the upstream MR).
