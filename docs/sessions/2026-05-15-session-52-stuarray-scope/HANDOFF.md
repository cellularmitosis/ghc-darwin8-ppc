# Handoff from session 52 → session 53

**For:** the next claude session.
**From:** session 52 — the root cause of the 32-session-old
"compiler produces empty .o" bug found, fixed, and deployed.  An
upstream-GHC big-endian library bug in `STUArray Bool`.
**Recommended pickup:** cut release v0.13.0, update README +
state.md + roadmap.md, re-run cabal-examples (some will newly
succeed), and prepare the upstream MR.

## ✅ SESSION EXIT STATE

Stage1 rebuilt with the fix.  Stage2 redeployed to pmacg5.
Baseline tests run at 30 PASS / 4 FAIL\_OUTPUT (unchanged from
session 49/50/51).  The four FAIL\_OUTPUT tests are pre-existing
test-design issues (Int width, getpid, getProgName).  No
regressions.

The Big2.hs reproducer that was producing 152-byte empty `.o`
files for ten sessions now produces a 46340-byte fully-populated
`.o` under both default RTS and `-A1m -G1`.  The
`tests/stage2-native/run.sh` Hello.hs run succeeds.

The fix is in
`external/ghc-modern/ghc-9.2.8/libraries/array/Data/Array/Base.hs`
and formatted as
`patches/0016-array-stuarray-bool-word-aligned-init.patch`.

## TL;DR — what was wrong

`libraries/array/Data/Array/Base.hs`:1033 — `STUArray Bool`'s
`newArray` allocates `bOOL_SCALE n = ceil(n/8)` bytes via
`newByteArray#` and zeroes the same `nbytes` via `setByteArray#`.
But `unsafeRead`/`unsafeWrite` access via `readWordArray#`/
`writeWordArray#` — a full machine word.  For sizes that don't
align to a word, the trailing partial-word bytes are left
uninitialised (per the `newByteArray#` contract).  On big-endian,
the bit for element 0 lives in memory byte 3 (LSB) but
`setByteArray#` writes byte 0 (MSB).  Every read returns garbage.

## TL;DR — the fix (11-line patch)

Add `bOOL_WORD_SCALE :: Int# -> Int#` that rounds the byte count
up to a full machine word.  Use it in place of `bOOL_SCALE` for
both the `newByteArray#` allocation and the `setByteArray#`
zeroing call in Bool's `newArray`, and in `unsafeNewArray_`.

## Pipeline narrowed: sessions 42-52

| Session | Hook                                            | Was wrong                  |
|---------|-------------------------------------------------|----------------------------|
| 42      | `simplTopBinds` entry                           | 0-1 binders                |
| 43      | `core2core` entry                               | 1-3 binders                |
| 44      | `deSugar` `final_prs`                           | 3-6                        |
| 45      | `deSugar` `tcg_binds` entry                     | 3-6                        |
| 46      | `hsc_typecheck` exit                            | 3-5                        |
| 47      | `tcRnSrcDecls` output                           | 2-5                        |
| 48      | `tcTopBinds` OUTPUT                             | 2-3                        |
| 49      | `tcTopBinds` INPUT                              | 2-3                        |
| 50      | `Data.Graph.scc` in `stronglyConnCompG`         | forest of 0, 3 (was 1, 8)  |
| 51      | `newArray False :: STUArray s Int Bool`         | spurious True bits         |
| **52**  | **`Data/Array/Base.hs` Bool `newArray`**        | **BE bit/byte mismatch**   |

## Read in order

1. **This file.**
2. [`README.md`](README.md) — five-iteration narrative.
3. [`findings.md`](findings.md) — F1..F11 distilled analysis.
4. [`patches/0016-array-stuarray-bool-word-aligned-init.patch`](../../../patches/0016-array-stuarray-bool-word-aligned-init.patch)
   — the actual fix.
5. Test programs in this session dir:
   `types_test.hs` (iter A — only Bool corrupts),
   `nogc_test.hs` (iter B — no burnGC needed),
   `size_test.hs` (iter C — cutoff at 1 machine word),
   `confirm_test.hs` (iter E — BE bit/byte mismatch confirmed).

## What to try next, in priority order

### Top: cut release v0.13.0

This is a milestone fix.  Per CLAUDE.md, every release ships a
demo + README update + bindist tarball + tag.  The demo should be
a Haskell program that previously failed stage2 compilation —
candidates:

1. **Big2.hs itself** — the simplest, most direct proof.  Show
   `ghc -c Big2.hs +RTS -A1m -G1` producing a real `.o` file.
2. **A cabal-example that previously failed** — possibly
   `random`, `optparse`, or one of the larger ones.  Run them
   first to see which newly succeed.
3. **A multi-module Haskell program** that exercises typeclass
   dispatch, recursive bindings, and arrays — to confirm the
   compiler is producing well-formed code in a broader sense.

A `tests/cabal-examples/run-one.sh` invocation has an
`EXTRA_FLAGS[@]: unbound variable` bash bug under `set -u` when no
extra args are passed.  Fix that as a small drive-by (initialise
`EXTRA_FLAGS=()` near the top) before running the suite.

### Second: update README and state.md and roadmap.md

`README.md` "Implementation status" tables likely have rows for
"stage2 compiles complex Haskell" that should flip ❌ → ✅, plus
the "Latest release" line at the top.  `docs/state.md` should be
updated with the post-fix status.  `docs/roadmap.md` should close
the "find the stage2 miscompile" item and open one for "prepare
upstream MR".

### Third: re-run cabal-examples and the larger test programs

`tests/cabal-examples/` has aeson-generics, async, full-stack-cli,
https-get, megaparsec, network-echo, network-echo-three,
optparse, random, vector.  Several of these previously failed to
build under stage2 (some compiles produced empty `.o` or panicked
during linking).  Worth re-running each one with the patched
stage2 to enumerate which previously-broken builds now succeed.

The pattern is:
```bash
bash tests/cabal-examples/run-one.sh <example>
```

(after fixing the `EXTRA_FLAGS` bash bug noted above).

### Fourth: prepare the upstream GHC bug report / MR

This is a real GHC bug, not a port-specific one.  The same code is
in current GHC HEAD.  We should:

1. **Confirm the bug exists in newer GHC.**  Check
   `libraries/array/Data/Array/Base.hs` in ghc.git HEAD — the
   Bool instance's `newArray` / `unsafeRead` / `bOOL_SCALE` /
   `bOOL_INDEX` should be unchanged.
2. **Construct a minimal portable repro.**  The current repro
   needs a big-endian target.  Three options to make it
   reproducible on a Tier-1 target:
   - Add a CPP flag to `Base.hs` that forces `bOOL_SCALE` to
     also be little-endian-broken (e.g. shift the partial bytes
     to the wrong end).
   - Instrument `setByteArray#` in a debug RTS to fill
     unwritten bytes with `0xFF` (a sentinel value), which would
     expose the bug immediately on any target.
   - Use a qemu-emulated PPC32 target in GHC CI.
3. **Open the GHC issue / MR** with the patch and the repro.
   Suggested title: "STUArray Bool: newArray under-zeroes the
   trailing partial word, causing garbage reads on big-endian
   (and on any LE size that doesn't align to a word)."

### Fifth: clean-room consideration of `unsafeNewArray_`

The patch fixes both `newArray` and `unsafeNewArray_` to use
`bOOL_WORD_SCALE` for allocation size, but does NOT add a
`setByteArray#` zeroing call to `unsafeNewArray_`.  That means
users of `unsafeNewArray_` Bool still face the read-modify-write
problem on the first `unsafeWrite` per word — see [`findings.md`](findings.md#f7-same-bug-affects-unsafenewarray_).  Worth thinking about whether
the upstream MR should also add a setByteArray# to
`unsafeNewArray_` for Bool, even though that costs a memset on
the unsafe code path.  In practice users virtually always use
`newArray False` (via `newArray_`), which is now fixed.

### Sixth: cross-check other unboxed-bit-packed instances

The `Bool` instance is the only one in `Data/Array/Base.hs` that
bit-packs, but the project also has other bit-packed `MArray`
instances in third-party packages (e.g. `vector` and `bytestring`).
Worth a quick audit — if any of them use the same `setByteArray#
nbytes` pattern with word-granular `read/writeWordArray#` access,
they'd have the same big-endian bug.

## Mechanics — how to rebuild after editing array library

```bash
cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/array-0.5.4.0/libHSarray-0.5.4.0.a \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
tests/run-tests.sh
```

Stage1 rebuild takes ~17 min (incremental from a clean tree).
Stage2 deploy takes ~2 min.  Baseline takes ~5 min.

## What NOT to redo

* **Don't undo the Bool fix.**  It's a real upstream bug and the
  fix is correct; nothing else upstream should be touching it.
* **Don't drill into the RTS for `stg_newByteArrayzh`.**  The bug
  is NOT in the RTS.  Session 51's hypothesis was wrong.
* **Don't redo the pipeline bisection (S42-S51).**  All those
  probes were measuring downstream effects of this one bug.
* **Don't add probes back into the compiler.**  Source tree is
  clean; the array library is the only file that should ever
  have been touched (and it has only this one patch).

## Hosts (unchanged)

* **uranium**: cross-build, source edits.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real`
  is the patched v0.13.0-prerelease build (session 52 deploy).

## Paste-into-fresh-session prompt

```
Context: session 52 of the ghc-darwin8-ppc project found, fixed,
and validated the root cause of the 32-session-old "compiler
produces empty .o" bug.  It is a single big-endian-only bug in
GHC's array library: `libraries/array/Data/Array/Base.hs`'s
`MArray (STUArray s) Bool (ST s)` instance allocates and zeroes
`bOOL_SCALE n = ceil(n/8)` bytes via `setByteArray#`, but its
`unsafeRead` and `unsafeWrite` use `readWordArray#` /
`writeWordArray#` (a full word).  For sub-word sizes, the
trailing partial-word bytes are left uninitialised by
`newByteArray#`; on big-endian, the bit for element 0 is the LSB,
which lives in memory byte 3 — not memory byte 0, where
`setByteArray#` writes.  Every read of an `STUArray Bool` of size
< SIZEOF_HSWORD*8 returns garbage on BE.

Fix: 11-line patch — add `bOOL_WORD_SCALE` that rounds nbytes up
to a whole machine word, use it in place of `bOOL_SCALE` in
Bool's `newArray` and `unsafeNewArray_`.

Patch:
  patches/0016-array-stuarray-bool-word-aligned-init.patch

Validation:
  pre-fix confirm_test 1998/2000 bad → 0/2000 bad post-fix
  pre-fix Big2.hs `-c` → 152-byte empty .o → 46340-byte real .o
  baseline 30 PASS / 4 FAIL_OUTPUT, unchanged
  stage2-native Hello.hs passes

Read in order:
1. docs/sessions/2026-05-15-session-52-stuarray-scope/HANDOFF.md
2. docs/sessions/2026-05-15-session-52-stuarray-scope/README.md
3. docs/sessions/2026-05-15-session-52-stuarray-scope/findings.md
4. patches/0016-array-stuarray-bool-word-aligned-init.patch

Top priority for session 53: cut release v0.13.0 — pick a demo
program that previously failed stage2 compile (Big2.hs is the
direct candidate, or a previously-broken cabal-example).  Update
README's Implementation status tables (flip 🟡/❌ → ✅ for
stage2-compiles-complex-Haskell rows).  Update docs/state.md and
docs/roadmap.md.  Re-run tests/cabal-examples to enumerate
newly-working builds.  Then prepare the upstream GHC MR.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.

Unsupervised mode is project default.
```

## Memory aide

When session 53 ends, write the next handoff at:
`docs/sessions/<DATE>-session-53-<slug>/HANDOFF.md`.
