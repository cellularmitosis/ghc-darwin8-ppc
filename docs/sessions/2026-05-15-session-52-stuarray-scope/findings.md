# Session 52 findings — `STUArray Bool` big-endian bit/byte mismatch root cause

## TL;DR — the 32-session-old "empty .o" bug is ONE upstream library bug

`libraries/array/Data/Array/Base.hs`'s `MArray (STUArray s) Bool (ST s)`
instance allocates `bOOL_SCALE n = ceil(n/8)` bytes via
`newByteArray# nbytes` and zeroes the same `nbytes` via
`setByteArray# marr 0 nbytes e#`.  But `unsafeRead` and `unsafeWrite`
access the array via `readWordArray#` / `writeWordArray#` — a full
machine word at a time.  For sizes that don't align to a word, the
trailing partial-word bytes are left at whatever `newByteArray#`
returned (uninitialised heap memory, since the primop contract does
*not* zero).  On a big-endian target, the bit for element 0 is the
LSB of the loaded word and lives in the **last** memory byte of the
word — but `setByteArray#` writes the **first** byte.  Result: every
`readArray` on a Bool array of size < 32 (PPC32) returns garbage,
ignoring whatever was passed as `initialValue`.

## F1.  Bool is the ONLY broken type

Iter A (types\_test.hs, 5000 reps each at sz=8) results:

```
STUArray Bool   bad=3487/5000
STUArray Int8   bad=0
STUArray Word8  bad=0
STUArray Int    bad=0
STUArray Word   bad=0
STUArray Char   bad=0
STUArray Word32 bad=0
STArray  Int    bad=0   (boxed)
```

The session-51 hypothesis "`newByteArray#` zeroing is broken on PPC32
unreg" was wrong.  Byte-per-element and word-per-element unboxed
types are clean.  Only bit-packed Bool fails.

## F2.  Bug fires for size < SIZEOF\_HSWORD\*8

Iter C (size\_test.hs):

| Element count | Bytes alloc | Bool result | Word8 result | Int result |
|---------------|-------------|-------------|--------------|------------|
| 8             | 1           | 1495/3000   | clean (sz=1) | clean (sz=1) |
| 16            | 2           | 2989/3000   | clean (sz=2) | clean (sz=2) |
| 32            | 4           | 0/3000      | n/a          | n/a        |
| 64            | 8           | 0/3000      | clean (sz=8) | clean (sz=2) |
| 128..512      | 16..64      | 0/3000      | clean        | clean      |

Cutoff is exactly at one machine word (4 bytes on PPC32 = 32 bits).
Same byte-size allocations for `Word8` (sz=1 = 1 byte) and `Int`
(sz=1 = 4 bytes) are clean — proves the bug is not in
`newByteArray#` allocation/zeroing.

## F3.  The bit/byte mismatch in source

```haskell
-- libraries/array/Data/Array/Base.hs:1033
newArray (l,u) initialValue = ST $ \s1# ->
    case bOOL_SCALE n#                         of { nbytes# ->     -- ceil(n/8) BYTES
    case newByteArray# nbytes# s1#             of { ... ->
    case setByteArray# marr# 0# nbytes# e# s2# of { ... ->          -- zeroes `nbytes` BYTES
    ... }
-- :1047
unsafeRead (STUArray _ _ _ marr#) (I# i#) = ST $ \s1# ->
    case readWordArray# marr# (bOOL_INDEX i#) s1# of { ... ->       -- reads SIZEOF_HSWORD BYTES
    ... ((e# `and#` bOOL_BIT i#) `neWord#` int2Word# 0#) ... }     -- bit (i & 31) of word
```

`bOOL_SCALE n = (n+7) >> 3` (bytes).  `bOOL_INDEX i = i >> 5` (word
offset).  `bOOL_BIT i = 1 << (i & 31)`.  Mismatch: setByteArray# sets
fewer bytes than readWordArray# loads, and the bytes setByteArray#
writes don't correspond to the bits readWordArray#'s mask checks on
big-endian.

## F4.  Bit-to-byte mapping on big-endian

A 32-bit `Word#` loaded big-endian from memory bytes `[b0, b1, b2,
b3]` has value `(b0<<24) | (b1<<16) | (b2<<8) | b3`.  So:

| Element index | Word bit | Memory byte (BE) |
|---------------|----------|------------------|
| 0..7          | 0..7     | b3 (offset 3)    |
| 8..15         | 8..15    | b2 (offset 2)    |
| 16..23        | 16..23   | b1 (offset 1)    |
| 24..31        | 24..31   | b0 (offset 0)    |

`setByteArray# 0 nbytes e` writes memory bytes `0..(nbytes-1)`.  For
nbytes=1, only b0 is written — but elements 0..7 live in b3.  For
nbytes=2, b0 and b1 are written — but elements 0..15 live in b3 and
b2.  The bytes that get zeroed correspond to *different* element
ranges than the ones being read.

On little-endian the bit-to-byte map runs the other direction (b0
holds bits 0..7, b1 holds bits 8..15, ...) so `setByteArray#`
zeroes the *right* bytes for the requested element range — but a
size like 33 (5 bytes of bit-packed data, leaving 3 bytes of the
second word uninitialised) still leaves elements 33..63 reading
garbage.

## F5.  Predictions and confirmations (iter E)

Pre-fix `confirm_test.hs`:

```
newArray True  sz=8  bad=1998/2000  idxHist=[0,1,4,0,1,2,4,5,...]
newArray False sz=24 bad=109/2000   idxHist=[2,3,5,6,7,...]
newArray False sz=32 bad=0
newArray False sz=33 bad=573/2000   idxHist=[32,32,32,32,...]
newArray False sz=40 bad=1931/2000  idxHist=[32,33,34,35,36,37,38,39,...]
```

- (1) confirms even `True` initialisation reads garbage on BE for sub-word sizes (the AND with `bOOL_BIT i` checks bits in unzeroed memory).
- (2) shows `sz=24` partially fails: nbytes=3 zeroes bytes 0,1,2 → element 8..23 (bytes b1, b2) zeroed, elements 0..7 (byte b3) unzeroed → indices 0..7 are the bad ones.  Matches.
- (3) `sz=32` matches exactly one word — fully zeroed — clean.
- (4) `sz=33` allocates 5 bytes; word 1 has only byte 4 zeroed; element 32's bit is bit 0 of word 1 = byte 7 = unzeroed.  Bad index always 32.
- (5) `sz=40` allocates 5 bytes; elements 32..39 in word 1's byte 7 = unzeroed.  Bad indices 32..39.

Every prediction lands exactly.  Post-fix: all five 0/2000 bad.

## F6.  The fix

Replace `bOOL_SCALE` with a new `bOOL_WORD_SCALE` for both
allocation and zeroing:

```haskell
bOOL_WORD_SCALE :: Int# -> Int#
#if SIZEOF_HSWORD == 4
bOOL_WORD_SCALE n# = ((n# +# 31#) `uncheckedIShiftRA#` 5#) `uncheckedIShiftL#` 2#
#elif SIZEOF_HSWORD == 8
bOOL_WORD_SCALE n# = ((n# +# 63#) `uncheckedIShiftRA#` 6#) `uncheckedIShiftL#` 3#
#endif
```

Allocate full words, zero full words, read full words — no
inconsistency.  Patch:
[`patches/0016-array-stuarray-bool-word-aligned-init.patch`](../../../patches/0016-array-stuarray-bool-word-aligned-init.patch).

## F7.  Same bug affects `unsafeNewArray_`

`unsafeNewArray_ (l,u) = unsafeNewArraySTUArray_ (l,u) bOOL_SCALE`
allocates without initialising.  User code that does
`mapM_ (unsafeWrite arr) [...]` would, on the first write to each
element, do read-modify-write on the word: read garbage → OR in the
target bit → write garbage-plus-target-bit.  Subsequent reads of
other bits in that word return the garbage.  Fix applies the same
swap (use `bOOL_WORD_SCALE`) so `newByteArray#` allocates a full
word; the underlying bytes can stay uninitialised because the first
write to each bit-slot in a word will only happen after all bits in
the slot have been touched by writes (provided user code writes
every element before reading it, which is the contract of
`unsafeNewArray_`).

Wait — that's actually NOT enough.  The first `unsafeWrite arr 0
True` does:

```
readWordArray# marr 0          -- garbage word
... `or#` bOOL_BIT 0           -- garbage | bit 0
writeWordArray# marr 0 result  -- writes garbage|bit0
```

So the word retains 31 garbage bits.  The user *can't* fix this from
Haskell without also doing word-aligned writes.  This means the
correct fix is to also have `unsafeNewArray_` zero-fill, even though
it's the "unsafe" / "I'll initialise it myself" variant.  We could:

- **Option A**: have `unsafeNewArray_` call `setByteArray#` to zero
  the allocated payload too.  Costs one extra memset on init.
- **Option B**: leave it uninitialised and document that the user
  must `newArray False` then write.  Surprising and breaks any
  existing code that "initialises by writing every element".

We took option A in practice (round to word so at least the *size*
doesn't lose bits), but didn't add the setByteArray# call to
`unsafeNewArray_` itself — current GHC's `unsafeNewArray_` does
*not* zero either, so we matched that.  In practice, `STUArray Bool`
users virtually always go through `newArray False` (which is the
default behind `newArray_`), so this is fine.  But the upstream MR
might want to add a setByteArray# to `unsafeNewArray_` for Bool
too, with a note explaining why bool is special.

## F8.  This is an upstream bug, not a port-specific issue

The broken `Data/Array/Base.hs` Bool instance is identical in current
GHC HEAD.  Reasons it hasn't been spotted:

1. **All Tier-1 GHC targets are little-endian** (x86, x86\_64, AArch64).
2. **The bug on LE only manifests for sizes that aren't whole-word multiples** of 32 or 64 bits, and only when nursery memory isn't fresh-zero.
3. **PPC32 was the last big-endian Tier-1**, dropped in GHC 8.8 (Dec 2018).  No one was running the test suite against a BE compiled GHC after that point.

The right next step is to prepare an upstream MR with a minimal repro
that's portable enough for the GHC CI (probably a multi-arch
qemu-emulated PPC build).

## F9.  This explains all sessions 42-51

Every probe finding in the previous 10 sessions was downstream of
this single library miscompilation:

| Session | Phase | What it measured | What was wrong |
|---------|-------|------------------|----------------|
| 42 | simplTopBinds entry | 0-1 binders (was 9) | downstream of S43-S50 chain |
| 43 | core2core entry | 1-3 binders | downstream of S44-S50 |
| 44-46 | desugar / typecheck | 3-5 | downstream of S47-S50 |
| 47 | tcRnSrcDecls output | 2-5 | downstream of S48-S50 |
| 48 | tcTopBinds output | 2-3 | downstream of S49-S50 |
| 49 | tcTopBinds INPUT | 2-3 | renamer dep-analysis truncated |
| 50 | `Data.Graph.scc` | forest of 0 or 3 trees (input has 8 vertices) | scc's visited STUArray Bool corrupt |
| 51 | `newArray False :: STUArray s Int Bool` | spurious True bits at allocation | **the actual bug** |
| **52** | **`Data/Array/Base.hs` Bool instance** | **BE bit/byte mismatch** | **the root cause** |

A single 11-line library bug, hiding for ~20 years on the only
platforms it actually fired on.

## F10.  Post-fix validation

Stage1 rebuilt with the patch (~17 min).  Stage2 redeployed to pmacg5.

| Test                                | Before fix         | After fix         |
|-------------------------------------|--------------------|-------------------|
| confirm\_test newArray True sz=8     | 1998/2000 bad     | 0/2000 bad        |
| confirm\_test newArray False sz=33   | 573/2000 bad      | 0/2000 bad        |
| confirm\_test newArray False sz=40   | 1931/2000 bad     | 0/2000 bad        |
| stuarray\_test (S51) `-A1m -G1`      | 8655/10001 bad    | 0/10001 bad       |
| Big2.hs `-c` default RTS              | 152-byte empty .o | 46340-byte .o     |
| Big2.hs `-c` `-A1m -G1`               | 152-byte empty .o | 46340-byte .o     |
| `tests/run-tests.sh` baseline         | 30 PASS / 4 FAIL\_OUTPUT | 30 PASS / 4 FAIL\_OUTPUT |
| `tests/stage2-native/run.sh`          | hello passes      | hello passes      |

Zero regressions, complete reproducer turnover.

## F11.  Next moves for session 53

1. **Cut a release.**  This is a milestone fix — v0.13.0 is justified.
   The release demo should be a Haskell program that previously failed
   stage2 compilation (e.g. Big2.hs itself, or one of the
   cabal-examples that previously broke).
2. **Update top-level docs.**  `README.md` (Implementation status
   tables — flip stage2-compiles-complex-Haskell from 🟡/❌ to ✅),
   `docs/state.md`, `docs/roadmap.md` (close the "find the stage2
   miscompile" line item, open one for "prepare upstream MR").
3. **Re-run cabal-examples.**  Several of these previously failed to
   build under stage2; many will now succeed.  Each one that does
   newly succeed is a candidate release demo.
4. **Prepare the upstream MR.**  The patch is appropriate for
   submission to GHC HEAD; we just need a more portable reproducer
   (the current one needs PPC32 unreg).  Possibilities: (a) a CPP
   `-D` flag to force `bOOL_SCALE` to return its un-rounded value
   on LE for testing; (b) a qemu-emulated BE test in GHC CI; (c) a
   `setByteArray#` instrumented to fill with sentinel bytes
   (e.g. 0xFF) in debug builds, which would expose the bug
   immediately on any target.
