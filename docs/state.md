# state.md — where are we right now

*Updated: 2026-04-22 late night, after the second big push.*

## Current phase

**Phase 3 (cross-compile modern GHC) is in progress on uranium.**
Configure fully succeeded. `make` is broken at stage-0 dep-file
generation. Details in
[`experiments/002-cross-configure-and-first-make.md`](experiments/002-cross-configure-and-first-make.md).

Path A was dropped earlier in the session (see experiments/001); the
cross-compile is now the only active path.

## What is known to work

### Repository / plan / notes (from Phase 0)

- Full plan, 7 topic notes, session logs, test corpus (12 programs),
  6.10.4/7.0.1/7.0.4/7.6.3 sources + binaries downloaded, GHC 8.6.5
  and 9.2.8 source trees (with submodules) in `external/`.

### Fleet

- 8 of 9 Tiger/Leopard hosts reachable. pmacg3 offline.
- pmacg5 (Tiger G5 970MP dual-core 2.3, 51 GB free) is the primary
  test-run host for final executables.
- Indium has the sibling LLVM-7 project's working clang but is
  **LAN-only** (no internet).

### Cross-toolchain on uranium (arm64 M1 Pro)

- **Host GHC 9.2.8** at `~/.local/ghc-9.2.8/bin/ghc`. Brew's 9.14.1 was
  too new to bootstrap 9.2.8.
- **Cross clang 7.1.1** at `~/.local/ghc-ppc-xtools/clang` (copied
  from sibling llvm-7-darwin-ppc project). Produces correct
  PPC Mach-O for trivial C programs with `-target
  powerpc-apple-darwin8 -mlinker-version=253.9 -isysroot $SDK`.
- **Clang resource-dir** at `~/.local/lib/clang/7.1.1/` (contains
  float.h et al; required because 10.4u SDK's float.h does
  `#include_next`).
- **10.4u SDK** at `~/.local/ghc-ppc-xtools/MacOSX10.4u.sdk/`.
- **cctools-port 877.8-ld64-253.9-ppc** built and installed at
  `~/.local/cctools-ppc/install/bin/` with
  `powerpc-apple-darwin8-*` prefix. Provides ar, ld, nm, ranlib,
  libtool, otool, as, strip, install_name_tool, etc.
- **Happy 1.20.1.1 + Alex 3.2.7.4** via cabal at `~/.local/bin/`.
  (Brew's happy is 2.2, rejected by GHC 9.2.8.)
- **Cross-CC wrapper** at
  `~/.local/ghc-ppc-xtools/bin-wrap/ppc-cc`: delegates to real
  clang for compile, writes a fake Mach-O ppc header for link
  (see "What is currently blocking" below).
- **Auto-mkdir GHC wrapper** at `~/.local/bin/ghc-boot-wrap`:
  pre-creates `-o <path>` output directories before exec'ing the
  real host GHC, because GHC 9.2.8's make-based build has a bug
  where some Haskell module .o output dirs don't get created.

Scripts to regenerate all this are committed under `scripts/`:
`cross-env.sh` (source-this-first env setup),
`make-cross-cc-wrapper.sh` (regenerates the CC + fake-linker),
`ppc-cc.sh` / `ppc-ld-fake.sh` (the generated wrappers).

### GHC 9.2.8 cross-configure

Fully succeeded at `~/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/`:

```
GHC build   : aarch64-apple-darwin
GHC host    : aarch64-apple-darwin
GHC target  : powerpc-apple-darwin
Building a cross compiler : YES
Unregisterised            : YES
```

The original plan predicted configure would fail at target
recognition. It did not; removal-commit 374e447 didn't actually
delete PPC/Darwin from the recognized-target list (just the
`RTS_LINKER_USE_MMAP=0` override).

## What is currently blocking progress

**`make` fails during stage-0 library build.** Specifically:

```
<command line>: error: directory portion of
  "libraries/template-haskell/dist-boot/build/Language/Haskell/TH.o"
  does not exist (used with "-o" option.)
```

Fixed part 1 with an auto-mkdir ghc wrapper (see above). Then
hit the next layer:

```
libraries/template-haskell/ghc.mk:3:
  libraries/template-haskell/dist-boot/build/.depend-v.haskell:
  No such file or directory
...
libraries/template-haskell/Language/Haskell/TH.hs:104:1: error:
    Could not load module 'Language.Haskell.TH.Syntax'
    It is a member of the hidden package 'template-haskell-2.18.0.0'.
```

The per-library dep files (`.depend-v.haskell`) aren't being
generated. Without them, make compiles Haskell modules in the
wrong order (trying TH.hs before TH/Syntax.hs, etc.). This is
deep in GHC 9.2.8's make-based build-system logic. Hitting this
consistently across every library.

## Key open questions

1. **Should we abandon make for Hadrian?** GHC 9.2.8 ships both
   make- and Hadrian- build systems. Hadrian (Shake-based) has
   reportedly better cross-compile support and is still maintained
   (make is deprecated upstream). Next session should try
   `./hadrian/build --flavour=quick-cross`. See
   [`experiments/002`](experiments/002-cross-configure-and-first-make.md)
   Options section for the full decision matrix.
2. **Is our CC wrapper interfering with dep generation?** The
   fake-linker may return success in a way that confuses GHC's
   dep-generation pass. Check by making the wrapper smarter.
3. **Does the real linking story have a solution?** ld64-253.9-ppc
   can't link against 10.4u SDK crt1.o (section 4 problem).
   Options: (a) ship .o to Tiger and link there with
   ld64-97.17-tigerbrew; (b) patch 253.9 to handle the older
   reloc format; (c) strip the problematic reloc from crt1.o.
   Doesn't matter until make gets further.

## Last-touched state

- Git: `main` branch, **8 commits**, clean.
- Latest commit: `232778c Phase 3 configure succeeded: GHC 9.2.8
  --target=powerpc-apple-darwin8.`
- Local clones: `external/ghc-8.6.5/`, `external/ghc-modern/ghc-9.2.8/`
  (configured, make partially ran).
- Host state: all the `~/.local/` prereqs installed on uranium.
  Indium still has its own separate setup (GHC and source tree) but
  we've pivoted away from using indium.

## Immediate next steps (for next session)

Target: get past the make dep-file issue, reach the first
**real** compile error (the removal-commit bitrot).

### Step 1: Try Hadrian instead of make

```bash
source ~/claude/ghc-darwin8-ppc/scripts/cross-env.sh
cd ~/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8
./hadrian/build --flavour=quick-cross \
    -j$(nproc) \
    --docs=none \
    --freeze1 \
    2>&1 | tee /tmp/ghc-hadrian-1.log
```

Hadrian is the Shake-based build system; its cross-compile story is
reportedly better than the ancient make-based build. Expected to
fail *eventually* at the same removal-commit-bitrot issues, but
hopefully past the dep-generation-race issue.

### Step 2 (if Hadrian fails): upgrade to GHC 9.6

`git clone --depth=1 --branch ghc-9.6.7-release
https://gitlab.haskell.org/ghc/ghc.git external/ghc-modern/ghc-9.6.7`
and retry. 9.6 is Hadrian-only and a more solid cross-compile
target.

### Step 3: write the first patch

Whichever path succeeds, the next real milestone is the first
compile error that's due to removal-commit bitrot — that's
where patches/0001 onward get written. Expected order from
[`notes/file-mapping-86-vs-modern.md`](notes/file-mapping-86-vs-modern.md):
PPC_Darwin.hs module restoration first, then PPC/Ppr.hs, then
NCG driving logic, etc.

### Full env recipe to resume, on uranium

```sh
export PATH=$HOME/.local/ghc-9.2.8/bin:$HOME/.local/bin:$HOME/.local/cctools-ppc/install/bin:$PATH
source ~/claude/ghc-darwin8-ppc/scripts/cross-env.sh
cd ~/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8
# Continue from here
```

## Files to read first for anyone picking this up

1. [`plan.md`](plan.md) — the big picture
2. [`state.md`](state.md) — this file (where we are)
3. [`experiments/002-cross-configure-and-first-make.md`](experiments/002-cross-configure-and-first-make.md) — current work
4. [`experiments/001-ghc-704-pkg-on-tiger.md`](experiments/001-ghc-704-pkg-on-tiger.md) — why Path A was abandoned
5. [`notes/cross-toolchain-strategy.md`](notes/cross-toolchain-strategy.md) — toolchain choices
6. [`notes/codebase-tour.md`](notes/codebase-tour.md) — what we need to port
7. [`notes/file-mapping-86-vs-modern.md`](notes/file-mapping-86-vs-modern.md) — per-file port plan
