# LLVM-7 r4 → LLVM-8 r5 cross-toolchain swap — plan (status: open, blocked)

> **Status (2026-05-09, session 18):** swap **attempted, rolled back**.
> Indium's host-cross `clang-8` binary predates the BUG-003 fix and
> indium can't currently rebuild (Xcode/CommandLineTools is in a state
> where `<new>` isn't found by `clang++`).  See
> [`docs/sessions/2026-05-09-session-18-llvm8-toolchain-swap/README.md`](../sessions/2026-05-09-session-18-llvm8-toolchain-swap/README.md)
> for the play-by-play.
>
> The plan below is still the right shape; what's needed first is an
> indium environment fix and a fresh `build-llvm8` that picks up the
> uncommitted BUG-003 patch in
> `LLVM-8-Branch/llvm/lib/Target/PowerPC/InstPrinter/PPCInstPrinter.cpp`
> on indium.  Bumped target version r4 → r5 to match the latest sister
> release (r5 = r4 binary + freestanding-headers fix).

## Goal

Move the `-fllvm` codegen path used by our stage1 cross-build from
the **LLVM-7 r4** (`clang 7.1.1`) toolchain we currently bundle to
**LLVM-8 r5** (`clang 8.0.1`) from the sister
[llvm-darwin8-ppc](https://github.com/cellularmitosis/llvm-darwin8-ppc/releases/tag/v8.0.1-r5)
project.

> **Side note from session 18:** GHC's `-fllvm` flag is a no-op for
> our build — the unregisterised target ABI silently routes everything
> through the C codegen.  So the toolchain swap is really about which
> clang compiles the C output of `compiler/GHC/CmmToC.hs`, not about
> the `.ll` IR pipeline.  All the compiled `.o`s (libraries, RTS,
> stage1 compiler library) go through that one clang.  Fixes/regressions
> in clang therefore have a lot of leverage.

## Why

Per the sister project's session 032 outreach
([`llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/outreach-to-ghc.md`](../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/outreach-to-ghc.md))
and rationale
([`rationale-llvm7-freeze.md`](../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/rationale-llvm7-freeze.md)):

- **LLVM-7 is frozen at v7.1.1-r9** (last patch release).  LLVM-8
  is the actively-maintained primary line going forward.
- **LLVM-7 ≡ LLVM-8 for PPC** per Iain Sandoe ([darwin-toolchains
  discussion #19](https://github.com/iains/darwin-toolchains-start-here/discussions/19)).
  No PPC backend feature gain or loss between 7 and 8.
- **Cleaner BUG-003 fix.**  We benefit from this directly — the
  PPC asm-printer ZERO/r0 round-trip was what unblocked profiling
  (v0.10.0).  LLVM-8 r4 has the better-shaped patch.
- **No `-Os` miscompile family** (sister project's BUG-004 through
  BUG-008) which silently affected LLVM-7 r1–r4.  Those didn't
  bite us in v0.10.0, but quietly being on the side that did
  ship them is a footgun.
- **Smaller and faster.**  v8.0.1-r4 stripped is 22 MB vs LLVM-7
  r9's 45 MB.  Cross-builds will link faster.
- **Consolidated maintenance attention.**  Bug fixes will land on
  LLVM-8 first; the LLVM-7 line is in maintenance mode.

## Why not now (urgency)

Not blocking anything.  The current `-fllvm` path on LLVM-7 r4
works for v0.10.0's profiling and v0.11.0's stage2 cross-build.
This is a quality / forward-compatibility move, not a bug fix.

The natural moment to do the swap is **either**:

- The next time we touch the cross-toolchain (e.g. when we try to
  fix the stage2 GC bug — at that point we'll likely want to
  rebuild stage1 anyway and might as well swap the LLVM dep).
- Or the next time we ship a release that has a cross-toolchain
  reason to bump (e.g. a new stage1 patch, a hadrian flavour
  tweak, a different `-O`-level investigation).

## Concrete steps

### 1. Install LLVM-8 r4 on the host

```sh
# Host-side (uranium / arm64 Mac).  Cross-clang for ppc-darwin.
curl -L -o /tmp/clang8-cross.tar.gz \
  https://github.com/cellularmitosis/llvm-darwin8-ppc/releases/download/v8.0.1-r4/clang-8.0.1-cross-arm64-to-ppc-darwin8.tar.gz
mkdir -p $HOME/.local/ghc-ppc-xtools-8
tar -C $HOME/.local/ghc-ppc-xtools-8 -xzf /tmp/clang8-cross.tar.gz
```

(Exact tarball name needs to be verified against the sister
project's release page — they publish both arm64-cross and
ppc-native variants.  We need the cross flavour.)

### 2. Update the cross-CC wrapper

[`scripts/ppc-cc.sh`](../../scripts/ppc-cc.sh) currently points at:

```
CLANG="$HOME/.local/ghc-ppc-xtools/clang"
```

Either:

- Repoint `~/.local/ghc-ppc-xtools` to the LLVM-8 install (simplest;
  callers don't change), **or**
- Add a `LLVM_VARIANT=8` env knob and make the wrapper pick between
  `~/.local/ghc-ppc-xtools-7/clang` and `~/.local/ghc-ppc-xtools-8/clang`.

The cleaner choice is option 1 — the path is supposed to be
"the cross-clang we use", not "any LLVM 7 install".

### 3. Update GHC's `lib/settings`

The bindist's [`lib/settings`](../../../external/ghc-modern/ghc-9.2.8/_build/stage1/lib/settings)
points at `llc`, `opt`, `clang`.  These are looked up by name
in `$PATH` at runtime.  If we put LLVM-8's binaries on `$PATH`
under their unsuffixed names (i.e. `llc` is `llc-8`), GHC picks
them up automatically.  No source change needed.

### 4. Rebuild stage1 from scratch

```sh
cd external/ghc-modern/ghc-9.2.8
rm -f _build/hadrian/.shake.database
source ~/claude/ghc-darwin8-ppc/scripts/cross-env.sh
./hadrian/build --flavour=quick-cross --docs=none -j8
```

Expect ~50 minutes on M-series Mac (same as v0.10.0 / v0.11.0
rebuild times).

### 5. Verify nothing regressed

- 25-program test battery: `./tests/run-tests.sh` should be 30/34
  PASS byte-identical to host (same as v0.10.0 baseline).
- v0.10.0 profiling demo (`demos/v0.10.0-mandel-prof.hs`) still
  emits a clean `.prof` + `.hp`.
- v0.11.0 stage2 demo (`demos/v0.11.0-stage2-native.sh`) still
  works with the `+RTS -A1G` wrapper.

If any of those regress, the swap exposed a previously-latent issue;
investigate before merging.

### 6. Update bindist + cut a release

The bindist tarball doesn't ship LLVM itself (clang/llc/opt are
runtime dependencies on the host), so the tarball contents don't
mechanically change.  But we should bump a release tag so users
who reproduce against the new toolchain have a clear version
boundary.  Probable name: **v0.12.0**.

## Risks

- **Latent miscompile difference between LLVM-7 r4 and LLVM-8 r4
  on our specific Cmm output.**  Unlikely (both pass the BUG-003
  fix and Iain's audit) but possible.  Mitigated by re-running the
  test battery in step 5.
- **Settings file or wrapper path mismatch.**  The cross-cc and
  GHC's `lib/settings` both reference `clang`/`llc`/`opt`.  Easy
  to mis-edit one and not the other.  Step 3's "let `$PATH` do
  the work" approach minimises surface.
- **Sister project releases the cross-toolchain in a different
  layout than v7.1.1-r4 did.**  Need to sanity-check the tarball
  shape before committing to the install location.

## Pre-requisites

- Sister project's v8.0.1-r4 `clang-8.0.1-cross-arm64-to-ppc-darwin8.tar.gz`
  (or equivalent) must be downloadable from the GitHub releases page.
  As of session 17 (2026-04-30), v8.0.1-r4 is published — verify the
  cross-tarball flavour exists when picking this proposal up.

## Cross-references

- LLVM-7 freeze rationale (sister project session 032):
  [`rationale-llvm7-freeze.md`](../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/rationale-llvm7-freeze.md)
- Outreach to this project:
  [`outreach-to-ghc.md`](../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/outreach-to-ghc.md)
- The clarification that the stage2 binding-loss bug we briefly
  thought might be LLVM's is in fact our RTS GC:
  [`ghc-bug-correction.md`](../../../llvm-7-darwin-ppc/docs/sessions/032-llvm8-primary-and-ghc/ghc-bug-correction.md)
- Our own BUG-003-corollary (when we picked up LLVM-7 r4):
  [`docs/sessions/2026-04-29-session-16-profiling/`](../sessions/2026-04-29-session-16-profiling/)
