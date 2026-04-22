# Cross-toolchain strategy for Phase 3

Per [`plan.md`](../plan.md) open question #2, we need a
`powerpc-apple-darwin8` cross-toolchain on a modern host to drive
the Path B cross-compile of GHC 9.2.x in unregisterised mode.

This note commits to a strategy and captures the first-contact
probing that informs it.

## The three candidate toolchains

Listed in the plan:
1. cctools-port + a GCC cross-built from GNU GCC source
2. Iain Sandoe's `darwin-xtools`
3. The sibling `llvm-7-darwin-ppc` project's clang output

All three can produce PPC Mach-O `.o` files. The tiebreakers are
ease of adoption and project-level coupling.

## Strategy: use the sibling LLVM-7 project's clang

**Decision: option 3 — reuse the `llvm-7-darwin-ppc` project's
working clang.** Rationale:

- It's already built and working on `indium`
  (`~/tmp/claude/llvm-7-darwin-ppc/build-phase0/bin/clang`).
- It's been validated against real programs (multi-file wc, zlib,
  bzip2, SQLite, libpng per their state.md) and against Apple
  GCC 4.0.1 output in their ABI test suite.
- The linker story is solved (their Phase 2 & 3 work — they use
  Tiger's `/opt/ld64-97.17-tigerbrew` / cctools linker chain).
- They have the SDK extracted at
  `~/tmp/claude/llvm-7-darwin-ppc/sdks/MacOSX10.4u.sdk`.
- Zero additional toolchain work for us before Phase 3 can start.

The only downside: cross-project coupling. If the LLVM-7 project
changes its file layout we have to re-probe. Acceptable —
they're both slow-burn retrocomputing projects; their output
surface is stable once proved.

Fallback if LLVM-7's clang turns out to not be enough (e.g. GHC
emits Cmm that its C backend-via-gcc wouldn't need to handle,
and clang doesn't compile the emitted C): switch to option 1,
cctools-port + GCC 4.x cross-build. Don't bother with option 2
unless something really specific fails.

## First-contact probe

Confirmed on 2026-04-22:

```sh
# On indium (arm64 macOS 15):
CLANG=~/tmp/claude/llvm-7-darwin-ppc/build-phase0/bin/clang
SDK=~/tmp/claude/llvm-7-darwin-ppc/sdks/MacOSX10.4u.sdk
cat > /tmp/t.c <<'EOF'
#include <stdio.h>
int main(void) { puts("ok"); return 0; }
EOF
$CLANG -target powerpc-apple-darwin8 -isysroot $SDK -c /tmp/t.c -o /tmp/t.o
file /tmp/t.o
# => /tmp/t.o: Mach-O object ppc

$CLANG --version
# => clang version 7.1.1
# => Target: arm-apple-darwin24.3.0    ← host target, not relevant
# => Thread model: posix
```

Works. GHC's Phase 3 build can invoke this clang via
`CC=$CLANG CFLAGS="-target powerpc-apple-darwin8 -isysroot $SDK"`
in the ghc `./configure` environment.

## Build host for Phase 3

Two plausible host machines:
- `uranium` (this Mac) — where the git tree lives, no cross-toolchain yet
- `indium` (M1 mini arm64) — has the working clang, SDK, and
  existing build tree

**Use `indium` as the Phase 3 build host.** This mirrors the
LLVM-7 project's own indium-hosted build. Workflow:

- Git tree, edits, planning, logs → `uranium`
- GHC source, cross-builds, artefacts → `indium`
- Target runs → `pmacg5` (Tiger PPC)

Transfer conventions: rsync GHC source to indium once, edit on
uranium and sync (or fetch-back) patches as they stabilize.

## Linker for Phase 3

The LLVM-7 project's Phase 2 established that:
- `/opt/ld64-97.17-tigerbrew/bin/ld` on Tiger handles clang's
  stubless output
- Tiger's stock `/usr/bin/ld` (pre-ld64 classic) does NOT — that's
  a known gap they left as future work

For **cross-compiling**, we run the linker on indium via
cctools-port or Thomas Poechtrager's ld64. Check the LLVM-7
project's notes/patches for their exact linker invocation in
Phase 3 (experiments/007 etc.) and replicate it.

## Bootstrap GHC for Phase 3

GHC's cross-compile build mode uses the host GHC to compile
Haskell source for the target. So we need a modern GHC on indium
(arm64 macOS 15).

Options:
- `brew install ghc` — gets us whatever GHC version Homebrew
  currently has (probably 9.4+ or 9.6+ as of April 2026).
- `ghcup install ghc 9.2.8` — explicit version match.

Version alignment: we need the HOST GHC's `base`/`Cabal` ABIs to
be compatible enough with the TARGET GHC source to drive the
stage-1 cross-build. GHC's `configure --target=$TRIPLE` step will
complain if the host is too far ahead; the remedy is either
downgrading the host GHC or bumping the target GHC version.

**Tentative choice: host GHC 9.2.8** (matches target). Install via
ghcup on indium, not brew, because ghcup offers exact-version
pinning.

## Next action

In next session, on indium:

```sh
curl -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh
ghcup install ghc 9.2.8
ghc --version  # sanity
```

Then from the GHC 9.2.8 source tree (rsynced from uranium):

```sh
./boot  # if the tree is a git clone, needs bootstrapping
./configure \
    --target=powerpc-apple-darwin8 \
    --enable-unregisterised \
    CC=$CLANG \
    CFLAGS="-target powerpc-apple-darwin8 -isysroot $SDK"
```

Expect failure at the `configure` target-recognition step (the
374e44704b hunk deleted `powerpc-darwin` from the recognized
triples). That becomes our first patch: `0001-restore-configure-ac-target-darwin-powerpc.patch`.
