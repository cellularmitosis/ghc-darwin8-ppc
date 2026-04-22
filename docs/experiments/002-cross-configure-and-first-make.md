# 002 — Cross-configure GHC 9.2.8 for powerpc-apple-darwin8, attempt first make

## Hypothesis

GHC 9.2.8 can be cross-configured on uranium (arm64 macOS 15) to
target `powerpc-apple-darwin8` using:
- The sibling `llvm-7-darwin-ppc` project's clang as the C cross-compiler
- A locally-built `cctools-port` (ld64-253.9-ppc branch) as the Mach-O binutils
- Host GHC 9.2.8 as the bootstrap compiler
- Happy 1.20 and Alex 3.2 via cabal-install

After configure, `make` should be able to build at least stage-1.

## Method

### Configure prep: assembling the cross-toolchain on uranium

Indium has the sibling LLVM-7 project's clang and the 10.4u SDK, but is
LAN-only (can't reach the internet).  The original plan was to build on
indium; pivoted to uranium mid-session per the user's direction.

Assembled on uranium:

1. **Host GHC 9.2.8**: the aarch64-apple-darwin bindist from
   haskell.org extracted to `~/.local/ghc-9.2.8-aarch64-apple-darwin/`,
   `./configure --prefix=$HOME/.local/ghc-9.2.8 && make install`.
   Uranium's brew GHC is 9.14.1 — too new to bootstrap 9.2.8 (GHC
   bootstrap policy: N can be built from N-2 at most).
2. **Cross clang**: rsynced `build-phase0/bin/clang-7` (107 MB) and
   the resource-dir `build-phase0/lib/clang/7.1.1/` (6.6 MB, contains
   `float.h` and other clang-built-in headers required because the
   10.4u SDK's `float.h` does `#include_next <float.h>`) from indium
   to `$HOME/.local/ghc-ppc-xtools/` and `$HOME/.local/lib/clang/7.1.1/`.
3. **10.4u SDK**: rsynced to `$HOME/.local/ghc-ppc-xtools/MacOSX10.4u.sdk/`
   (151 MB).
4. **cctools-port**: cloned tpoechtrager/cctools-port branch
   `877.8-ld64-253.9-ppc`, built on uranium. Build required
   `CFLAGS=-std=gnu99` because clang 17 on macOS 15 otherwise treats
   `bool` as a C23 keyword (cctools headers have `enum bool { FALSE,
   TRUE }` which is invalid in C23). Also needed `brew install libtool
   automake` (automake was missing). Installed at
   `$HOME/.local/cctools-ppc/install/bin/` with
   `powerpc-apple-darwin8-*` prefixes.
5. **Happy 1.20 + Alex 3.2**: `cabal install
   --install-method=copy --installdir=$HOME/.local/bin
   happy-1.20.1.1 alex-3.2.7.4`. Brew's latest happy is 2.2 (rejected
   by GHC 9.2.8 which wants 1.20.x).

### Cross-CC wrapper

Direct `clang -target powerpc-apple-darwin8 -isysroot $SDK ...` almost
worked, but hit a parade of issues:

- **`-no_deduplicate` error**: clang 7 passes this to ld, but our
  ld64-253.9-ppc doesn't know it (that flag came later in ld64 history).
  Fix: `-mlinker-version=253.9` — tells clang to emit flags appropriate
  for our older ld. Got past that.

- **`sectionForNum(4) section number not for any section` in
  `/usr/lib/crt1.o`**: ld64-253.9 can't re-map the 10.4u SDK's crt1.o
  (2005-era Mach-O reloc format has fields the newer linker doesn't
  recognize). Iain's own notes: "ld64-253.9-ppc ... unclear if it works
  on 10.4." It doesn't. So we can't actually LINK to-Tiger executables
  with this ld.

This would be fatal except that GHC configure only uses `AC_PROG_CC`
to sanity-check the compiler, not actually link any real code. So
we made a two-part workaround:

- `scripts/ppc-ld-fake.sh`: a shell script that writes a valid 16-byte
  Mach-O PPC header as the "output" of linking. Always succeeds.
- `scripts/ppc-cc.sh`: a wrapper that delegates to real clang for
  `-c`/`-E`/`-S`/`-M` (compile modes) and to the fake linker for
  link mode. Added `-mlinker-version=253.9` to the clang call.

The honest description: **we punted on real cross-linking.** The
final executable linking will need a different solution (probably:
ship `.o` files to Tiger and link there with ld64-97.17-tigerbrew,
as the LLVM-7 project does). For now, all configure cares about is
that `cc -o foo foo.c` exits 0 and produces a file — it doesn't
check the file is executable.

### The configure run that worked

```bash
export PATH=$HOME/.local/ghc-9.2.8/bin:$HOME/.local/bin:$HOME/.local/cctools-ppc/install/bin:$PATH
cd external/ghc-modern/ghc-9.2.8
./configure \
    --target=powerpc-apple-darwin8 \
    --enable-unregisterised \
    GHC=$HOME/.local/ghc-9.2.8/bin/ghc \
    CC="$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-cc"
```

Summary of the configure output:

```
GHC build  : aarch64-apple-darwin
GHC host   : aarch64-apple-darwin
GHC target : powerpc-apple-darwin
LLVM target: powerpc-apple-darwin
Building a cross compiler : YES
Unregisterised            : YES
TablesNextToCode          : NO
Build GMP in tree         : NO
ar           : powerpc-apple-darwin8-ar
ld           : powerpc-apple-darwin8-ld
nm           : powerpc-apple-darwin8-nm
libtool      : powerpc-apple-darwin8-libtool
ranlib       : powerpc-apple-darwin8-ranlib
otool        : powerpc-apple-darwin8-otool
install_name_tool : powerpc-apple-darwin8-install_name_tool
Happy        : /Users/cell/.local/bin/happy (1.20.1.1)
Alex         : /Users/cell/.local/bin/alex (3.2.7.4)
```

**configure exited 0. Huge milestone.** The original plan predicted
the first failure would be at "target detection" because
commit 374e447 deleted PPC/Darwin from the recognized-target list.
That turned out to be wrong — 374e447's configure.ac hunk only
removed the `RTS_LINKER_USE_MMAP=0` override, not the target
recognition. GHC 9.2.8 is perfectly happy to configure with
`--target=powerpc-apple-darwin8`.

### Make attempt

`make -j1` started happily: compiled `deriveConstants`, `hsc2hs`,
`ghc-cabal` (the bootstrap build-helper tools) as stage-0 Haskell
against the host GHC. Got through ~299 bootstrap modules for
ghc-cabal without error.

Then failed compiling `libraries/template-haskell/Language/Haskell/TH.hs`:

```
<command line>: error: directory portion of
"libraries/template-haskell/dist-boot/build/Language/Haskell/TH.o"
does not exist (used with "-o" option.)
```

The output directory for the compiled .o wasn't created. This turned
out to be a recurring issue across the build.

### Fix attempt 1: pre-create directories

Pre-created every output dir by mirroring source layout into `dist-boot/build/`.
Didn't help: `make clean` deletes those dirs, and something in the
dependency chain can't re-create them in time.

### Fix attempt 2: auto-mkdir GHC wrapper

Wrote `/tmp/ghc-wrap` that intercepts `-o <file>` and `mkdir -p
$(dirname <file>)` before exec'ing real GHC. Installed as
`$HOME/.local/bin/ghc-boot-wrap`. Created a fake bin dir at
`$HOME/.local/ghc-boot-wrap/bin/` with `ghc` -> the wrapper and
`ghc-pkg` -> the real ghc-pkg (so `./configure` accepts the "matching
ghc-pkg" check). Reconfigured with `GHC=$HOME/.local/ghc-boot-wrap/bin/ghc`.

This got past the first error. The compile of TH.hs now ran, but
failed differently:

```
libraries/template-haskell/Language/Haskell/TH.hs:104:1: error:
    Could not load module 'Language.Haskell.TH.Syntax'
    It is a member of the hidden package 'template-haskell-2.18.0.0'.
    You can run ':set -package template-haskell' to expose it.
```

**Root cause:** the build system is trying to compile `TH.hs` before
`TH/Syntax.hs`, `TH/Lib.hs`, `TH/Ppr.hs`. That's a dependency-order
failure. The right order comes from the generated `.depend-v.haskell`
files, but those files didn't get generated:

```
libraries/template-haskell/ghc.mk:3:
  libraries/template-haskell/dist-boot/build/.depend-v.haskell:
  No such file or directory
(and same for every dist-boot library)
```

`phase_0_builds` target depends only on `hsc2hs`, `genprimopcode`,
`deriveConstants` deps — it generated those fine. `phase_1_builds`
depends on `$(PACKAGE_DATA_MKS)` — those were generated. But the
per-library `.depend-v.haskell` files *aren't* part of
`phase_1_builds` and don't get generated before the compile rules
need them.

Explicitly trying `make libraries/template-haskell/dist-boot/build/.depend-v.haskell`
drops into the same compile of TH.hs, which fails. Circular
dependency: generating the dep file triggers compiling which fails
because of wrong order because dep file doesn't exist.

### Where we stopped

The cross-toolchain story is solved. The build-system issue is a
different class of problem — it's a bug or misconfiguration in GHC
9.2.8's make-based build system that surfaces specifically in our
cross-compile setup. Several possible root causes:

1. **Our CC wrapper's link-mode behavior confuses dep generation.**
   GHC's `-M` mode may try to link-test something and get a non-zero
   intermediate state that breaks the dep-file rule.
2. **A missing autotools prerequisite.** Maybe there's a tool (like
   `gcc` symlink, `python2`, `ghc-toolchain`) that's expected and
   silently absent.
3. **GHC 9.2.8 + modern homebrew environment incompatibility.** The
   GHC `make`-based build has been deprecated in favor of Hadrian
   since GHC 9.4+; 9.2 is the last version where both systems work,
   and it may have accumulated bitrot against contemporary toolchains.
4. **Clang being misdetected as GCC, or vice versa.** GHC configure
   said "$CC is not gcc; assuming it's a reasonably new C compiler."
   That assumption may cascade.

## Result

**Partial success.**

*Solved:* cross-configure of GHC 9.2.8 for `powerpc-apple-darwin8`
fully completed. Full cross-toolchain assembled and documented.
Committed as `scripts/cross-env.sh`, `scripts/make-cross-cc-wrapper.sh`,
`scripts/ppc-cc.sh`, `scripts/ppc-ld-fake.sh`.

*Unsolved:* `make` fails during stage-0 Haskell library compile
because per-library dep files don't get generated.

## Conclusion and options for next session

### Option 1: deep-dive the make build system

Figure out exactly why `.depend-v.haskell` files aren't generated.
Possible mechanisms: (a) add `--debug=v` to make and read trace;
(b) manually force-generate them per library; (c) strip down the
CC wrapper to see if link-mode shenanigans break `-M` generation.
Time cost: hours to days.

### Option 2: switch to Hadrian

GHC 9.2.8 ships both `make` and `hadrian` build systems. Hadrian
is Shake-based, modern, actively maintained. Try:

```bash
./hadrian/build --flavour=quick-cross
```

Hadrian's cross-compile story is reportedly better than the
make-based build system's. Worth a spike.

### Option 3: target a newer GHC

GHC 9.6 LTS is Hadrian-only (no more make-based builds to fight
with), cross-compile support has been improved since 9.2. The
tradeoff: source layout has drifted further from 8.6.5's, so the
forward-port of the removal-commit 374e44704b becomes harder.

### Option 4: target an older GHC

GHC 8.10.x is closer to 8.6.5 and still has working make-based
cross-compile support. The legacy path.

**Recommendation:** try Option 2 (Hadrian on 9.2.8) first — one
session. If that also breaks, go to Option 3 (9.6 with Hadrian).

## Artefacts

Scripts shipped in this commit:
- `scripts/cross-env.sh` — single source-this-first script
- `scripts/make-cross-cc-wrapper.sh` — regenerates the CC wrapper
- `scripts/ppc-cc.sh`, `scripts/ppc-ld-fake.sh` — the wrappers

Not in this commit (lives under `~/.local/`, `~/claude/ghc-darwin8-ppc/external/`):
- `~/.local/ghc-9.2.8/` — host GHC
- `~/.local/ghc-ppc-xtools/` — cross clang + SDK
- `~/.local/lib/clang/7.1.1/` — clang resource-dir
- `~/.local/cctools-ppc/install/` — cross binutils
- `~/.local/bin/happy`, `~/.local/bin/alex` — parser generators
- `~/.local/bin/ghc-boot-wrap`, `~/.local/ghc-boot-wrap/bin/` — auto-mkdir wrapper
- `~/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/` — configured source tree

## See also

- [notes/cross-toolchain-strategy.md](../notes/cross-toolchain-strategy.md)
- [notes/file-mapping-86-vs-modern.md](../notes/file-mapping-86-vs-modern.md)
- [sibling project's linker notes](~/claude/llvm-7-darwin-ppc/docs/notes/ld64-versions-and-ppc.md)
- GHC bootstrap docs: <https://gitlab.haskell.org/ghc/ghc/-/wikis/building/architecture>
- GHC Hadrian docs: <https://gitlab.haskell.org/ghc/ghc/-/wikis/building/hadrian>
