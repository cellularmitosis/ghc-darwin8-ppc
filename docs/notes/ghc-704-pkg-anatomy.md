# GHC 7.0.4 .pkg anatomy and Tiger-install plan

The 7.0.4 binary distribution from
<https://downloads.haskell.org/~ghc/7.0-latest/krabby/GHC-7.0.4-powerpc.pkg>
(the "krabby" build, dated 2011-07-13, 164 MB) is the **last
semi-official PPC/Darwin GHC binary**. Cached locally at
`external/ghc-7.0.4-powerpc-darwin.pkg`. This note documents what's
inside and how we plan to install it on Tiger.

## Surface

```
ghc-7.0.4-powerpc-darwin.pkg          (Apple .pkg, flat format)
└── (after `pkgutil --expand`)
    ├── Distribution                  (XML installer script)
    ├── Resources/
    └── ghc.pkg/                      (the actual component package)
        ├── PackageInfo
        ├── Bom                       (file list)
        ├── Payload                   (gzipped cpio archive, 164 MB)
        └── Scripts/                  (postinstall, relocate, …)
```

The `PackageInfo` bundle metadata says:

```
identifier="org.haskell.ghc.7.0.4-powerpc"
install-location="/Library/Frameworks"
bundle path="./GHC.framework"
inner bundle path="./Versions/7.0.4-powerpc"
installKBytes="750076" numberOfFiles="5047"
```

So the .pkg installs `/Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/`
(750 MB on disk, 5047 files), then runs `postinstall` to populate
`/usr/bin` with symlinks.

## Payload contents

`gunzip -c Payload | cpio -id` yields:

```
GHC.framework/
└── Versions/
    ├── Current → 7.0.4-powerpc
    └── 7.0.4-powerpc/
        ├── Resources/   (Info.plist, English.lproj — bundle metadata)
        ├── Tools/       (Uninstaller, create-links — admin scripts)
        └── usr/
            ├── bin/     (ghc, ghci, ghc-pkg, runhaskell, hsc2hs,
            │            hpc, hp2ps, haddock — all shell wrappers)
            ├── lib/
            │   └── ghc-7.0.4/
            │       ├── ghc            (the actual compiler binary —
            │       │                   Mach-O ppc_7400, ~10 MB)
            │       ├── ghc-7.0.4
            │       ├── ghc-pkg
            │       ├── ghc-asm        (Perl post-processor)
            │       ├── ghc-split      (Perl post-processor)
            │       ├── extra-gcc-opts (just "-fwrapv")
            │       ├── base-4.3.1.0/
            │       ├── ghc-prim-0.2.0.0/
            │       ├── integer-gmp-*/
            │       ├── containers-0.4.0.0/
            │       ├── bytestring-0.9.1.10/
            │       ├── array-0.3.0.2/
            │       ├── directory-1.1.0.0/
            │       ├── filepath-1.2.0.0/
            │       ├── Cabal-1.10.2.0/
            │       └── … (one dir per shipped library)
            └── share/   (man pages, html docs)
```

The ghc binary file is `Mach-O executable ppc_7400` — built for G4
(PowerPC 7400). Will run on G3 (PPC 750) too; G4-specific
instructions don't appear in compiler code, only opt-in places like
hand-tuned vector code that GHC doesn't emit. **G3 fleet hosts
should run this fine.**

## Wrapper script (`/usr/bin/ghc`)

```sh
#!/bin/sh
exedir="/Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/usr/lib/ghc-7.0.4"
exeprog="ghc-stage2"
executablename="$exedir/$exeprog"
datadir=".../usr/share"
bindir=".../usr/bin"
topdir="$exedir"
pgmgcc="/Developer/usr/bin/gcc"
executablename="$exedir/ghc"
exec "$executablename" -B"$topdir" \
    -pgmc "$pgmgcc" -pgma "$pgmgcc" -pgml "$pgmgcc" \
    -pgmP "$pgmgcc -E -undef -traditional" \
    ${1+"$@"}
```

Key facts:

- **All paths are absolute and hardcoded** to
  `/Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/`. If
  we install elsewhere, we either rewrite the wrapper or symlink
  `/Library/Frameworks/...` to the real location.
- **`ghc-stage2` is shadowed** to `ghc` via the duplicate
  `executablename=` line. Probably a build-system artefact;
  doesn't matter at install time.
- **`/Developer/usr/bin/gcc`** is hardcoded as the C
  compiler/assembler/linker/preprocessor (`-pgmc`, `-pgma`, `-pgml`,
  `-pgmP`). On Xcode 2.5 (Tiger), `/Developer/usr/bin/gcc` is the
  Apple GCC 4.0.1 toolchain frontend. Same path on Xcode 3 (Leopard).
  **Available on every fleet host with Xcode installed.**

## Library dependencies (the libiconv trap)

`otool -L .../usr/lib/ghc-7.0.4/ghc` on the binary:

```
/usr/lib/libncurses.5.4.dylib  (compatibility version 5.4.0)
/usr/lib/libSystem.B.dylib     (compatibility version 1.0.0)
/usr/lib/libiconv.2.dylib      (compatibility version 7.0.0)  ← trap
/usr/lib/libgcc_s.1.dylib      (compatibility version 1.0.0)
```

The binary asks for `libiconv.2.dylib` with **compatibility version
≥ 7.0.0**. That's a Leopard-introduced ABI bump. Tiger ships
`libiconv.2.dylib` at compatibility version **5.0.0**. Loading the
binary on Tiger via dyld results in:

```
dyld: Library not loaded: /usr/lib/libiconv.2.dylib
  Referenced from: .../ghc-pwd
  Reason: Incompatible library version: ghc-pwd requires version 7.0.0
          or later, but libiconv.2.dylib provides version 5.0.0
```

This is **the same failure barracuda156 hit in 2022**
([MacPorts ticket #64698](https://trac.macports.org/ticket/64698)).
It blocks the krabby 7.0.4 binary from working on Tiger out of the
box. See [`iconv-abi-mismatch.md`](iconv-abi-mismatch.md) for the
Tiger workaround plan.

The other three deps are fine: ncurses, libSystem, and libgcc_s
all have Tiger-compatible versions.

## Postinstall script

```sh
INSTALL_DEST="$2"          # = /Library/Frameworks (from PackageInfo)
INSTALL_BASE="$3"          # = / (root volume)
[ "$INSTALL_BASE" = / ] && INSTALL_BASE=/usr
VERSION=7.0.4-powerpc
GHC_BASE="$INSTALL_DEST/GHC.framework/Versions/$VERSION"

mkdir -p "$INSTALL_BASE/bin"
ln -sf "$GHC_BASE"/usr/bin/* "$INSTALL_BASE/bin/"

mkdir -p "$INSTALL_BASE/share/man/man1"
ln -sf "$GHC_BASE"/usr/share/man/man1/* "$INSTALL_BASE/share/man/man1/"
ln -sf "$GHC_BASE"/usr/share/doc/ghc "$INSTALL_BASE/share/doc/"
```

So after a normal install:
- Framework at `/Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/`
- `/usr/bin/{ghc,ghci,ghc-pkg,runhaskell,...}` symlinks back

## `relocate` script (vestigial?)

```sh
INSTALL_DIR=`pwd`
CONTENTS_FOLDER_PATH=GHC.framework/Versions/Current

cd ${CONTENTS_FOLDER_PATH}/ghc; \
  ./configure --prefix=${INSTALL_DIR}/${CONTENTS_FOLDER_PATH}/usr
cd ${CONTENTS_FOLDER_PATH}/ghc; \
  make install
```

Looks like a build-system leftover — implies a `ghc` source-bindist
sub-tree that gets re-`./configure`d and re-`make install`ed. **No
such directory exists in the actual payload** — the `usr/` tree is
fully prebuilt. Also, the .pkg's `<scripts>` element only lists
`postinstall`, not `relocate`. So `relocate` is dead code. Ignore.

## Tiger install plan

1. **Don't run the .pkg installer on Tiger directly.** It will
   succeed at file copying but the `/usr/bin/ghc` wrapper will fail
   the moment it `exec`s the binary, because of the libiconv ABI
   mismatch.

2. **Hand-place the framework.** Mirror what the installer would
   have done, manually:

   ```bash
   # On the main Mac (already extracted):
   tar -C /tmp/ghc-704-payload -cf /tmp/ghc-704.tar GHC.framework
   ~/bin/tiger-rsync.sh /tmp/ghc-704.tar pmacg5:/tmp/

   # On pmacg5 (over ssh):
   sudo mkdir -p /Library/Frameworks
   sudo tar -C /Library/Frameworks -xf /tmp/ghc-704.tar
   sudo ln -sf /Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/usr/bin/* \
       /usr/local/bin/
   ```

3. **Patch the libiconv reference.** Two ways:

   a. **`install_name_tool`** the binary to point at
      `/opt/libiconv-1.16/lib/libiconv.2.dylib`:

      ```bash
      sudo install_name_tool -change \
          /usr/lib/libiconv.2.dylib \
          /opt/libiconv-1.16/lib/libiconv.2.dylib \
          /Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/usr/lib/ghc-7.0.4/ghc
      # repeat for ghc-pkg, ghc-pwd, hsc2hs, runghc helper binaries
      ```

   b. **`DYLD_FALLBACK_LIBRARY_PATH=/opt/libiconv-1.16/lib`** at
      runtime, exported from a wrapper around the wrapper.

   (a) is cleaner and survives shell mode changes. (b) is reversible
   without touching the binary. **Try (a) first.**

4. **Verify.** `ghc-7.0.4 --version` should print
   "The Glorious Glasgow Haskell Compilation System, version 7.0.4".
   `echo 'main = putStrLn "ok"' > t.hs && ghc-7.0.4 t.hs && ./t`
   should print "ok".

## Open questions

- Does the wrapper's hardcoded `/Library/Frameworks/...` path matter
  if we instead install at `/opt/ghc-7.0.4/`? Quick answer: yes —
  the wrapper does `exec $exedir/$exeprog` and `exedir` is hardcoded.
  Either install at the canonical `/Library/Frameworks/` location
  (cleanest) or rewrite the wrapper (also fine; it's a 12-line shell
  script).

- Does `/Developer/usr/bin/gcc` exist on the target Tiger boxes?
  On pmacg5 the Xcode install is presumed; should verify in
  Phase 1 before commit-to-install.

- Are there other binaries with the libiconv reference besides the
  main `ghc` binary? `ghc-pkg`, `ghc-pwd`, `hsc2hs` likely. Sweep
  with `find . -type f | xargs file | grep Mach-O` and `otool -L`
  the lot in Phase 1.
