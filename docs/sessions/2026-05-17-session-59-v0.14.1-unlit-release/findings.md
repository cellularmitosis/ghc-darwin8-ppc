# Session 59 findings

## TL;DR

Hadrian's cross-mode `unlit` packaging bug from session 58 is
fixed at the source.  Patch 0010 amended with a four-line change.
v0.14.1 ships.

## 1. The patch shape

```diff
   case (cross, stage) of
-    (True, s) | s > Stage0 && package /= iserv -> do
+    (True, s) | s > Stage0 && package `notElem` [iserv, unlit] -> do
         srcDir <- buildRoot <&> (-/- (stageString Stage0 -/- "bin"))
         copyFile (srcDir -/- takeFileName bin) bin
     (False, s) | s > Stage0 && (package `elem` [touchy, unlit]) -> do
```

`unlit` is already in scope (it's used in the non-cross arm
immediately below).  No new imports.  The original logic copied
*every* stage0 (host) binary into stage1 except iserv in cross
mode; the fix extends the exclusion to include unlit, sending it
through `buildBinary` instead — same path iserv takes.

## 2. Hadrian's buildBinary works fine on `unlit`'s pure-C sources

Session 58's HANDOFF wasn't 100% sure this would Just Work — `unlit`
is declared `Main-Is: unlit.c` + `C-Sources: fs.c` in its
`unlit.cabal`, and `buildBinary` defaults to `Ghc LinkHs` (the
Haskell-aware link mode used for normal Haskell executables).  In
practice it does work — hadrian's cabal-driven `cSrcs` /
`hsObjects` accounting handles a pure-C `Main-Is:` cleanly:

```
| Run Ghc CompileCWithGhc Stage1: utils/unlit/unlit.c => ...c/unlit.o
| Run Ghc CompileCWithGhc Stage1: utils/unlit/fs.c    => ...c/fs.o
| Run Ghc LinkHs Stage1: ...c/fs.o (and 1 more) => ...lib/bin/powerpc-apple-darwin8-unlit
| Successfully built program 'unlit' (Stage1).
| Executable: _build/stage1/lib/bin/powerpc-apple-darwin8-unlit
```

`Ghc LinkHs` here invokes the cross-ghc, which routes through
`scripts/ppc-cc.sh` for compile and `scripts/ppc-ld-tiger.sh` for
final link (per the standard cross-toolchain wiring).  Resulting
binary: `Mach-O executable ppc`, 47 KB.

## 3. Why the hadrian-built binary is 47 KB vs session 58's 14 KB

Session 58's `build-unlit-ppc.sh` invokes `$CROSS_CC` directly
(plain clang + Tiger linker), producing a 14 KB binary that's
just `unlit.o + fs.o + libc/Tiger crt1`.  Hadrian's `Ghc LinkHs`
adds GHC's standard executable wrapper machinery — the C-program
case still links through `ghc` rather than the bare `cc`, picking
up a small amount of additional runtime + the GHC-default linker
flag set (dead-strip, header-pad, etc.).

Functionally identical.  Both run `dummy.lhs` through unlit's
bird-track stripper correctly.

## 4. The first hadrian run looked like a no-op (and was)

After applying the source edit, the first
`hadrian --flavour=quick-cross binary` target invocation:

```
[ 99 of 101] Compiling Rules.Program ( src/Rules/Program.hs, ...Rules/Program.o )
Linking ...hadrian-0.1.0.0/x/hadrian/build/hadrian/hadrian ...
Total                               0.837s  100%
Build completed in 0.84s
```

— rebuilt hadrian-itself (since the source rule changed), but
didn't regenerate the unlit binary because shake's file-based
caching sees `_build/stage1/lib/bin/powerpc-apple-darwin8-unlit`
exists and tracks file mtime + content rather than rule-source
identity.  Deleting the existing arm64 binary forced hadrian to
re-execute the rule (now a `buildBinary` call instead of the prior
`copyFile`) on the next invocation.

Lesson for future patch updates that toggle a hadrian rule
between `copyFile` and `buildBinary`: always remove the existing
target file before rebuilding, otherwise hadrian silently keeps
the prior-rule-produced artifact.

## 5. The `--delete` side-effect on pmacg5

`scripts/deploy-stage2.sh`'s rsync uses `--delete` to sync the
stage1 lib tree to `/opt/ghc-stage2/lib/`.  This deleted session
58's `.arm64.broken` forensics backup at
`/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.arm64.broken`
(which wasn't in the source tree, so rsync removed it as extraneous).

No data loss in absolute terms — the broken arm64 binary is
byte-identical to `_build/stage0/bin/powerpc-apple-darwin8-unlit`
on uranium, which is the same host binary hadrian previously
copied via `copyFile`.  If forensics needs it again, it's a
`scp` away.

Worth noting in session 60+ if anyone needs to compare the
broken vs. fixed binaries directly — the canonical "broken"
version is uranium's stage0 binary.
