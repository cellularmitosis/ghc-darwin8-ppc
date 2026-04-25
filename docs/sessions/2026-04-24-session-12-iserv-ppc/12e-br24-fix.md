# Session 12e — BR24 jump-island fix (v0.7.2)

**The deepest manifestation of the per-section-mmap restructuring
issue from v0.6.1.**  Same shape: 9.2.8 broke an assumption that
8.6.5's PPC code relied on; we put it back.

## The bug

When iserv tried to load `HSbase-4.16.4.0.o` (a multi-MB Haskell
object), the runtime loader hit:

```
relocateSectionPPC: BR24 jump island also out of range in
HSbase-4.16.4.0.o; word=0x305f910
```

`word=0x305f910` ≈ 50 MB.  PPC's `bl` instruction has a 26-bit
signed displacement, so ±32 MB is the hard limit.  Even our
fallback jump-island — meant to extend the reachable range — was
itself too far away to reach.

## Why the jump island was too far

In **GHC 8.6.5**, an `.o` was loaded as one contiguous mmap region:
`oc->image` held the entire file, with `symbol_extras` (where jump
islands live) appended at the end.  Text sections lived at known
offsets within `oc->image`.  Distance from any text section to
symbol_extras = at most a few KB.  Always within BR24 range.

In **GHC 9.2.8**, the loader was restructured to **per-section mmap**:
- `oc->image` still holds the original `.o` blob.
- But each section gets its own `mmap()` region (or sits inside
  a segment-wide compound mmap allocated by
  `ocBuildSegments_MachO`).
- `symbol_extras` is allocated by `ocAllocateExtras` BEFORE the
  segment is built, into either:
  - A separate region near `oc->image` (`USE_CONTIGUOUS_MMAP` path), or
  - The `m32` allocator pool (default path).

Either way, `symbol_extras` and the per-section text mmap are
**independent allocations** that can land far apart.  For small
`.o`s they happen to be close; for `base.o` (multi-MB), they end
up >32 MB apart.

(This is the third level of the same root cause we hit in v0.6.1's
`resolveImports` bug.  The per-section restructuring broke
addressing assumptions all over the PPC path.)

## The fix

[`patches/0012-rts-ppc-contiguous-mmap-and-symbol-extras-near-text.patch`](../../../patches/0012-rts-ppc-contiguous-mmap-and-symbol-extras-near-text.patch)
(23 lines): enable `SHORT_REL_BRANCH` for PPC (so `USE_CONTIGUOUS_MMAP`
gets defined) and extend the macro condition to include Darwin.

But that alone isn't enough — the `mmap_32bit_base` mechanism that's
supposed to keep consecutive mmaps adjacent doesn't reliably work on
Darwin PPC (the kernel ignores address hints).  So we also need to
**physically include `symbol_extras` inside the RX segment's mmap**.

That's done in `patches/0009-restore-ppc-runtime-macho-loader.patch`
(grew from 461 → 524 lines) by modifying `ocBuildSegments_MachO`:
- Increase `size_rxSegment` by `extras_size` for PPC.
- After laying out the RX segment, place `oc->symbol_extras` at
  `(curMem + roundUpToAlign(orig_size_rxSegment, 8))` — i.e., right
  after the section data, still inside the same mmap.

Now `symbol_extras` is guaranteed to be within ±32 MB of every text
section in the loaded object (because they share one mmap).  BR24
jump islands always reach.

The original m32-allocated `symbol_extras` region is leaked (a few KB
per loaded object).  Acceptable for now.

## What this unblocks

All `.o` files load successfully via iserv, regardless of size:
- ghc-prim (~30 KB) ✅
- integer-gmp (~50 KB) ✅
- ghc-bignum (~280 KB) ✅
- **base (~3 MB) ✅** ← was the blocker

Both basic loader tests still pass:
- `tests/macho-loader/run.sh` (C) ✅
- `tests/macho-loader/run-haskell.sh` (Haskell) ✅

## What's still broken (12f)

After all `.o`s load, iserv attempts to evaluate the splice and
something in the binary protocol over our SSH shim goes wrong:

```
powerpc-apple-darwin8-ghc-iserv: Data.Binary.Get.runGet at position 133:
Unknown encoding for constructor
CallStack (from HasCallStack):
  error, called at libraries/binary/src/Data/Binary/Get.hs:345:5
```

This fires from `Data.Binary.Generic.checkGetSum` — a sum-type
deserializer reads a constructor tag that exceeds the type's
constructor count.

Possible causes:
1. **Endianness or word-size encoding mismatch** between host
   (arm64 LE 64-bit) and target (PPC32 BE).  Some hidden field
   uses native encoding rather than Data.Binary's portable one.
2. **SSH stdio corruption** of binary data.  We tried `-T` (no tty)
   and `-e none` (no escape).  Could be something else.
3. **Version skew** in the iserv protocol — host's iserv libraries
   compile differently than target's.

We have a debug shim (`/tmp/pgmi-shim-debug.sh`) that tee's both
directions to `/tmp/iserv-trace/`.  The host-to-target stream looks
correctly framed (constructor tags, length prefixes, paths), but
something specific to one of the messages confuses iserv's
deserializer.

Next session (12f) should:
1. Add verbose printf to iserv's `serv` loop to see which message
   it failed on.
2. Compare host's outgoing serialization with target's expected
   parse — possibly write a host-side validator that calls
   `getMessage` on the captured bytes to confirm host and target
   would parse them the same way (i.e., the encoding really is
   self-consistent and the bug is on iserv side).
3. Suspect the GHC.Heap closures: `instance Binary StgInfoTable`
   and friends may have non-portable encoding.

## Bindist

`ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz` (123 MB).  Same as
v0.7.1 plus the BR24 fix in libHSrts.a.

sha256: `de2096f74abaa34d0780116f565915f0ca017064211c6f782824262f4fa5ab71`
