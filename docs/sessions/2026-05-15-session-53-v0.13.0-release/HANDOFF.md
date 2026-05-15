# Handoff from session 53 → session 54

**For:** the next claude session.
**From:** session 53 — v0.13.0 shipped.  The 32-session-old
"stage2 emits empty .o" bug is fixed, demoed, released.
**Recommended pickup:** prepare the upstream GHC MR for the
`STUArray Bool` fix.  Then revisit the deferred cabal-examples
sweep (only `random` was sanity-checked this session).

## ✅ SESSION EXIT STATE

`v0.13.0` tag pushed and released on GitHub.  Both bindist tarballs
uploaded.  README "Latest release" reflects v0.13.0; "Stage2 native
ghc" row is ✅; new row added to the Releases table.  `docs/state.md`
and `docs/roadmap.md` updated.  Demo at `demos/v0.13.0-bool-bug-fix.sh`
runs end-to-end (5/5 iterations produce real 46340-byte `.o` files
on stage2 default-RTS, vs 152-byte empty files pre-fix).

Baseline tests: 30 PASS / 4 FAIL\_OUTPUT (the four are the
pre-existing test-design issues: Int width, getpid, getProgName).

## TL;DR — what shipped in v0.13.0

* Patch 0016 — STUArray Bool word-aligned init.  Already in the source
  tree from session 52.
* Rebuilt stage1 cross-bindist with the patch — `_build/bindist/
  ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`.
* Rebuilt stage2 ppc-native bindist with the patch — `_build/bindist/
  ghc-9.2.8-stage2-native-ppc-darwin8.tar.xz` (built from cross-built
  ghc-stage2 binary + lib tree).
* Demo: `demos/v0.13.0-bool-bug-fix.sh` — Big2.hs stage2 compile
  reproducer.
* `tests/cabal-examples/run-one.sh` — bash 3.2 empty-array fix
  (drive-by from the HANDOFF).
* Updated docs: README, demos/README.md, state.md, roadmap.md.

## What to try next, in priority order

### Top: prepare the upstream GHC MR

Patch 0016 fixes a real upstream bug.  Session 53 confirmed the
broken code is byte-identical in current GHC HEAD.  See
[roadmap §H](../../roadmap.md) for the open work to land this
upstream.  Concretely:

1. **Build a portable repro.**  Our current repro needs PPC32 unreg.
   Easiest path is probably a debug-RTS `setByteArray#` instrument
   that fills the *unwritten* trailing bytes with `0xFF` (sentinel)
   — that exposes the bug immediately on any target without needing
   BE hardware.  Alternative: a CPP `-D` flag to force the LE byte
   layout to also be wrong (more invasive).
2. **Reconsider `unsafeNewArray_`.**  Session 52 finding F7 notes
   that `unsafeNewArray_` Bool still has a read-modify-write hazard
   on the first `unsafeWrite` per word, because the trailing
   partial word is uninitialised.  Our patch rounds the allocation
   size up to a whole word but does NOT add a `setByteArray#`
   zeroing call — matching current upstream behaviour for
   `unsafeNewArray_`.  Upstream MR could go further: add the
   zeroing call to `unsafeNewArray_` Bool with a comment.  In
   practice users almost always use `newArray False`/`newArray_`
   which is fully fixed.
3. **Open the GHC issue.**  Suggested title: "STUArray Bool:
   `newArray` under-zeroes the trailing partial word, causing
   garbage reads on big-endian (and on any LE size that doesn't
   align to a word)."  Repository: `gitlab.haskell.org/ghc/ghc`
   (issue) and the array library lives at `gitlab.haskell.org/ghc/
   packages/array`.

### Second: cabal-examples sweep

Session 53 only sanity-checked `random` (smallest one).  The rest of
the cabal-examples should be re-run on the patched stage2 to enumerate
which previously-failing builds now succeed:

```
for ex in aeson-generics async vector optparse megaparsec network-echo full-stack-cli https-get; do
    bash tests/cabal-examples/run-one.sh $ex 2>&1 | tee logs/cabal-$ex.log
done
```

The `run-one.sh` bash fix from session 53 means these can now be
invoked without `OPENSSL_PREFIX` set without tripping `set -u`.

### Third: GHCi REPL

With stage2 native ghc now fully working, the GHCi REPL is reachable
— it's been blocked on stage2 since the start of the project.  See
[roadmap §C](../../roadmap.md) — the framework is all there
(runtime Mach-O loader, iserv, `pgmi-shim.sh`).

### Fourth: cross-check other unboxed-bit-packed instances

Per session 52 finding F11 / HANDOFF's "Sixth": the `Bool` instance
is the only one in `Data/Array/Base.hs` that bit-packs, but other
third-party packages (`vector`, `bytestring`'s Bit type, ...) may
have the same `setByteArray# nbytes` + `readWordArray#` pattern.
Worth a quick audit.

## What NOT to redo

* **Don't undo the Bool fix.**  It's correct and validated.
* **Don't add the `-A1G` workaround back.**  The patched stage2
  compiles real programs under default RTS.
* **Don't drill into the RTS for `stg_newByteArrayzh`.**  It's not
  the bug.

## Hosts (unchanged)

* **uranium**: cross-build, source edits, bindist build, release prep.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real` is
  the patched v0.13.0 stage2 (session 52 deploy).

## Paste-into-fresh-session prompt

```
Context: session 53 of the ghc-darwin8-ppc project shipped v0.13.0,
which carries patch 0016 — an 11-line fix to GHC's
libraries/array/Data/Array/Base.hs that resolves the 32-session-old
"stage2 emits empty .o" bug.  The fix is for an upstream GHC bug
(STUArray Bool's newArray under-zeroes the trailing partial word
because setByteArray# writes nbytes=ceil(n/8) but unsafeRead reads
a full word via readWordArray#; on big-endian the bit for element 0
lives in memory byte 3 (LSB) while setByteArray# writes byte 0 (MSB),
so every read of an STUArray Bool of size < SIZEOF_HSWORD*8 returns
garbage).  Same code is in current GHC HEAD.

Top priority for session 54: prepare the upstream MR.  See
docs/roadmap.md §H for scope.  Concretely:

1. Build a portable repro (sentinel-byte instrumented RTS is
   easiest — fills unwritten bytes with 0xFF, exposes the bug on
   any target).
2. Decide whether the upstream MR should also add a setByteArray#
   to unsafeNewArray_ Bool (we didn't, matching current upstream;
   could go further).
3. Open the issue + MR on gitlab.haskell.org/ghc/ghc.

Second priority: re-run the rest of tests/cabal-examples (only
`random` was sanity-checked in session 53) to enumerate which ones
newly succeed on patched stage2.

Read in order:
1. docs/sessions/2026-05-15-session-53-v0.13.0-release/HANDOFF.md
2. docs/sessions/2026-05-15-session-53-v0.13.0-release/README.md
3. docs/sessions/2026-05-15-session-52-stuarray-scope/findings.md
4. patches/0016-array-stuarray-bool-word-aligned-init.patch
5. docs/roadmap.md §H (upstream MR scope)

Hosts: uranium for builds, pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 54 ends, write the next handoff at:
`docs/sessions/<DATE>-session-54-<slug>/HANDOFF.md`.
