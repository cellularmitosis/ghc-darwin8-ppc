# Session 12f — TH end-to-end on Tiger 🎉 (v0.8.0)

The closing of roadmap C.  TemplateHaskell splices now run on
**PowerPC Mac OS X 10.4 Tiger** for the first time since GHC 8.6.

```
$ ./tests/th-iserv/run.sh
[1 of 1] Compiling Main             ( THSplice.hs, THSplice.o )
hello from a TH splice on Tiger
```

That last line is the result of `$(stringE "hello from a TH splice on Tiger")`
evaluated by `ghc-iserv` running on a real PowerMac G5, then spliced into
the output binary by the host (arm64 macOS) GHC.

## How we got here

v0.7.2 left iserv hung on:
```
Data.Binary.Get.runGet at position 133: Unknown encoding for constructor
```

after every `.o` had loaded successfully.  Two bugs were stacked:

### Bug 1: cross-built `binary` library mis-encoded Generic-derived sum tags

The `binary` library's `GBinaryPut`/`GBinaryGet` instance for sum types
selects a tag-byte size based on the number of constructors:

```haskell
-- libraries/binary/src/Data/Binary/Generic.hs (original)
gput | PUTSUM(Word8) | PUTSUM(Word16) | PUTSUM(Word32) | PUTSUM(Word64)
     | otherwise = sizeError "encode" size
  where
    size = unTagged (sumSize :: Tagged (a :+: b) Word64)
```

Where `PUTSUM(Word8)` expands (via CPP) to:
```
(size - 1) <= fromIntegral (maxBound :: Word8) = putSum (0 :: Word8) ...
```

For a 5-constructor sum (e.g. `ResolvedBCOPtr`), `size = 5`, so all guards
match and the *first* one (Word8) wins.  At least, that's how the **host**
build of `binary-0.8.9.0` works.

The **cross-built** PPC version of `binary-0.8.9.0` didn't.  It always
took the Word64 branch — emitting an 8-byte tag where the host emitted
1 byte:

| Side | Encoding of `MyEnum.C 95110952` | Bytes |
|------|----------------------------------|-------|
| Host (arm64)  | `02 00 00 00 00 05 ab 47 28`                | 9     |
| Target (PPC)  | `00 00 00 00 00 00 00 02 00 00 00 00 05 ab 47 28` | 16    |

So host-emitted streams left target's parser 7 bytes off after every
sum read.  Position 133 in the original error happened to land in the
middle of a `RemotePtr` field where the parser thought it was reading
the *next* sum tag.

The exact root cause inside the cross-compile pipeline is unclear (the
GUARD chain works in isolation on target — it correctly returns Word8
for size=5).  Something about the multi-guard-with-`where` pattern
combined with `size` flowing in via a `Tagged Word64` class-dispatch
call mis-compiles under unregisterised PPC codegen.  Not a high-priority
investigation — the workaround is small and clean.

**Fix** ([`patches/0013-binary-generic-direct-numeric-guards.patch`](../../../patches/0013-binary-generic-direct-numeric-guards.patch),
41 lines): rewrite the GUARD chain as direct numeric comparisons:

```haskell
gput x
  | size <= 0x100        = putSum (0 :: Word8)  (fromIntegral size) x
  | size <= 0x10000      = putSum (0 :: Word16) (fromIntegral size) x
  | size <= 0x100000000  = putSum (0 :: Word32) (fromIntegral size) x
  | otherwise            = putSum (0 :: Word64) size                x
```

That compiles correctly on both host and target.  Verified end-to-end
with `tests/bco-decode/run.sh`: target now encodes `MyEnum.C 95110952`
in 9 bytes, decodes the full ResolvedBCO blob, etc.

### Bug 2: BCO array contents need byte-swap on endian mismatch

After the binary library was fixed, iserv hit:
```
The endianness of the ResolvedBCO does not match the systems endianness.
Using ghc and iserv in a mixed endianness setup is not supported!
```

This came from `GHCi.CreateBCO.createBCO`'s pre-existing endianness check.
It's there because:
- `instrs` is a `UArray Int Word16` (bytecode opcodes/operands).
- `bitmap`, `lits` are `UArray Int Word64`.
- `putArray`/`getArray` (from `GHCi.BinaryArray`) write/read raw byte arrays
  *in host endian order*.  So a Word16 written by host as `0x0027` (LE)
  becomes bytes `27 00`, which a BE target reading as Word16 would see
  as `0x2700`.

GHC's upstream solution: error out, "we don't support mixed endianness".

But for our cross-compile (arm64 LE host → PPC BE target), this is the
*normal* case.  We can't change host's emit format.  So we byte-swap on
target.

**Fix** ([`patches/0014-ghci-bco-byteswap-on-endian-mismatch.patch`](../../../patches/0014-ghci-bco-byteswap-on-endian-mismatch.patch),
54 lines): add `byteSwapResolvedBCO` to `CreateBCO.hs` that recursively
byte-swaps `instrs` (Word16), `bitmap` (Word64), `lits` (Word64), and
nested `ResolvedBCOPtrBCO` BCOs.  Replace the error-out with a recursive
call that converts and retries.

```haskell
createBCO arr bco
  | resolvedBCOIsLE bco /= isLittleEndian = createBCO arr (byteSwapResolvedBCO bco)
createBCO arr bco
   = ... existing code ...
```

After both patches, iserv:
1. Reads CreateBCOs message correctly (Word8 tags).
2. Deserializes each ResolvedBCO with `Generic.hs`'s correct tag selection.
3. Detects the endian mismatch in createBCO and byte-swaps in place.
4. Hands the swapped BCO to `linkBCO'`/`newBCO#`.
5. The bytecode interpreter runs the splice.
6. Result is sent back to host.

## Test artifacts in tests/bco-decode/

- `MyEnumTest.hs` — minimal repro of the tag-size bug using a hand-rolled
  5-constructor enum that mirrors `ResolvedBCOPtr`'s shape.
- `MinimalTest.hs` — decode a single `ResolvedBCOPtr` from hand-crafted
  bytes.
- `DecodeBCO.hs` — decode the captured 254-byte BCO blob from the
  failing TH splice.
- `bco-blob.bin` — the captured blob for offline analysis.
- `run.sh` — runs all three on Tiger, checks output strings.

## What still doesn't work

- **GHCi REPL** still blocked on roadmap B (stage2 native ghc compile
  panic).  The loader + iserv + bytecode interpreter all work; what's
  missing is an in-process ghc that can compile fresh source on Tiger.
- **`-fexternal-interpreter` is the path**, and it now works.

## What this means for users

Hackage packages that use TH for code generation (aeson with
`$(deriveJSON …)`, lens TH, persistent, etc.) can now cross-compile to
Tiger.  Recipe:

```
cabal build --with-compiler=$STAGE1 --with-hsc2hs=$HOST_HSC2HS \
            --ghc-option=-fexternal-interpreter \
            --ghc-option=-pgmi=$PROJECT/scripts/pgmi-shim.sh
```

`pgmi-shim.sh` bridges to a remote `ghc-iserv` over SSH.  See
`docs/cabal-cross.md` for details (will be updated for v0.8.0).

Limitation: the remote Tiger box must have rsync'd lib paths matching
what host ghc emits in the iserv protocol (since iserv `loadObj`s
files by absolute path).  The simplest workaround is a filesystem
mirror — see [`docs/sessions/2026-04-24-session-12-iserv-ppc/12d-fs-mirror.md`](12d-fs-mirror.md)
(if it exists; otherwise see release notes).

## Bindist for v0.8.0

`ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz` ships:
- The patched `binary-0.8.9.0` library (patch 0013).
- The patched `ghci-9.2.8` library (patch 0014).
- Same `lib/bin/ghc-iserv` (rebuilt against the new libraries).
- Same install.sh, cross-scripts/runghc-tiger, cross-scripts/pgmi-shim.sh.
