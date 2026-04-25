# Session 12 — findings (across 12a, 12b, 12c, 12d)

The TH-on-Tiger investigation went 4 levels deep.  Each one exposed
a real layer of the cross-iserv stack that needed work.

## Layer 1: ghc-iserv builds for PPC ✅ (v0.7.0)

Hadrian gates iserv + libiserv behind `not cross`.  Flipping that
ran into hadrian's "copy stage1 program from stage0" cross-compile
branch — that branch assumes stage1 programs are host-side tools.
iserv must be a **target** binary; special-cased the rule.

Result: 29.7 MB PPC `ghc-iserv` that runs on Tiger (prints its
usage banner).

## Layer 2: SSH-piped binary protocol works ✅ (v0.7.0)

`pgmi-shim.sh` — 30 lines of bash.  Bridges ghc's local-iserv pipe
fds to remote ghc-iserv on Tiger via SSH stdio.  Cross-ghc spawns
the shim with `-pgmi=`, the shim ssh's to Tiger.

Verified: ghc → pgmi-shim → ssh → iserv → loadObj request → response
back to ghc.  No corruption, no hangs.

## Layer 3: filesystem-namespace mismatch (v0.7.1: pragmatic fix)

iserv on Tiger receives ghc's `loadObj` with a path like
`/Users/cell/.../HSghc-prim-0.8.0.o`.  Tiger doesn't have that path.

**Workaround:** rsync the host's `lib/ppc-osx-ghc-9.2.8/` tree to
the same path on Tiger.  install.sh in v0.7.1 ships this as a
documented manual step; future versions could automate via a
`--mirror-to-target` flag.

The right long-term fix is `iserv-proxy` + `remote-iserv` over TCP
(GHC's official architecture: proxy ships `.o` bytes over the wire,
target spills to temp files).  Skipped here because of `network`
package needing Tiger SDK workarounds.

## Layer 4: dlopen libgmp (v0.7.1)

iserv's `dlopen("libgmp.dylib")` failed on Tiger.  We cross-link
against `/opt/gmp-6.2.1/lib/libgmp.dylib` but the dyld search path
doesn't see it by default.

**Fix:** `pgmi-shim.sh` now sets
`DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib` for the
remote iserv.  Configurable via `$REMOTE_DYLD`.

## Layer 5: missing `__eprintf` symbol (v0.7.1)

When iserv `loadObj`'d HSghc-bignum-1.2.o, it failed with
"unknown symbol `___eprintf`".  This is an old-gcc helper for
`assert()` macros that gmp emits references to.  It IS in
Tiger's `/usr/lib/libSystem.B.dylib`'s `_eprintf.o`, but **not
exported** — `dlsym(RTLD_DEFAULT, "__eprintf")` returns NULL.

**Fix:** patch 0011 — provide a stub `__eprintf` in the RTS
(in `rts/linker/MachO.c`, gated on `powerpc_HOST_ARCH`) and
register it in `rts/RtsSymbols.c` via a new
`RTS_PPC_DARWIN_SYMBOLS` macro that's added to the symbol-table
expansion alongside `RTS_DARWIN_ONLY_SYMBOLS`.  Stub does what
the real one does (fprintf + abort).

After this, iserv successfully loads HSghc-bignum-1.2.o.  Then...

## Layer 6: BR24 jump-island out of range ❌ (deferred to 12e)

When iserv tries to load HSbase-4.16.4.0.o (a large object,
multi-MB `__text`), our PPC loader hits:

```
relocateSectionPPC: BR24 jump island also out of range in
HSbase-4.16.4.0.o; word=0x305f910
```

The text section has external `bl` calls that need a jump island
to reach (because the target is `_puts` etc., far away in dyld
space).  The jump island lives in `oc->symbol_extras`, allocated
by `ocAllocateExtras_MachO` at end-of-image
(`oc->image + roundUpToPage(oc->fileSize)`).

In 9.2.8 with **per-section mmap**, `oc->image` is the original
loaded `.o` blob; each section is independently mmap'd elsewhere.
For HSbase, the `__text` section's mmap is far enough from
`oc->image` (and thus from `symbol_extras`) that even a BR24
displacement to the jump island exceeds ±32 MB.

This is the same per-section-mmap restructuring issue we hit in
12a's `resolveImports` bug, but it's deeper: the SymbolExtras
allocation needs to either be:
- Adjacent to the text section's mmap (small per-section reservation
  alongside each loaded text section), OR
- Use the `Stub` infrastructure (per-section stubs, what aarch64
  does in 9.2.8) — `SectionFormatInfo.stub_offset/stub_size/stubs`.

Both are non-trivial to graft onto our existing PPC path.  Deferred
to session 12e.

## What ships in v0.7.1

- `patches/0011-rts-eprintf-stub.patch` (31 lines): the
  `__eprintf` stub + RTS_PPC_DARWIN_SYMBOLS registration.
- `patches/0009-restore-ppc-runtime-macho-loader.patch` grew
  from 461 → 476 lines: the stub function definition lives inside
  `rts/linker/MachO.c` so 0009 owns it.
- `scripts/pgmi-shim.sh` updated to set `DYLD_LIBRARY_PATH`.
- Bindist with the eprintf stub baked in.
- This findings.md doc.

What works now (with the v0.7.1 bindist + manual rsync mirror):
- iserv runs.
- TH `loadObj` succeeds for small Haskell `.o`s (ghc-prim, integer-gmp, bignum).
- Most TH splices that don't pull in `base` should work.

What doesn't work yet:
- TH splices that load `base` or any other large `.o` — BR24 OOR.

## Next session (12e)

Fix the BR24-out-of-range for large `.o`s.  Two options:

1. **Per-section symbol extras:** allocate a small `symbol_extras`
   region alongside each text section's mmap (within ±32 MB).  Each
   section's text relocs use *its* symbol_extras.  More invasive
   to GHC's code but matches the underlying ABI constraint.
2. **NEED_PLT for PPC:** define `NEED_PLT` and use the same
   per-section stub infrastructure aarch64 uses in 9.2.8.  The
   `Stub` records in `SectionFormatInfo` already exist; we'd need
   `plt_ppc.{c,h}` modeled on `plt_aarch64.c`.

Option 2 is more aligned with the modern 9.2.8 architecture but
requires more code.  Option 1 is closer to what 8.6.5 did and
might be a smaller patch.

Estimated effort: 1–2 sessions either way.
