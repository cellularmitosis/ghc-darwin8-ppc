# bindist-installer — plan

## Goal

Someone on arm64 macOS (or any host we support as a cross build host)
can download our release tarball, run an install script, and have a
working `powerpc-apple-darwin8-ghc` in their PATH.

## What's in the tarball

Already produced by `./hadrian/build binary-dist-dir`:

```
ghc-9.2.8-powerpc-apple-darwin8/
├── INSTALL
├── Makefile
├── README
├── bin/
│   ├── powerpc-apple-darwin8-ghc          (arm64 binary, the cross-compiler)
│   ├── powerpc-apple-darwin8-ghc-pkg      (arm64)
│   ├── powerpc-apple-darwin8-hsc2hs       (arm64)
│   └── ...
├── configure
├── config.guess / config.sub
├── lib/
│   ├── settings                          (absolute paths baked in!)
│   ├── ghcautoconf.h, ghcplatform.h
│   ├── package.conf.d/                   (33 registered packages)
│   └── ppc-osx-ghc-9.2.8/                (867 MB of ppc .a + .hi files)
├── mk/
└── wrappers/
```

## Install flow

```
$ curl -LO https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/download/v...
$ tar xJf ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz
$ cd ghc-9.2.8-powerpc-apple-darwin8
$ ./configure --prefix=$HOME/.local/ghc-cross-ppc-darwin8
$ make install
```

## Issues to solve

1. **`lib/settings` absolute paths.**  Currently points to
   `/Users/cell/.local/...`.  The `make install` step needs to rewrite
   settings to the new `$prefix`.  Upstream GHC's bindist Makefile
   already does this for `$topdir`, but we've added new paths
   (`-L/opt/gmp-6.2.1/lib`, `--target=powerpc-apple-darwin`) that need
   tokenizing.

2. **Dependent tools on the install host.**  The cross-compile depends
   on:
   - `powerpc-apple-darwin8-ld` (our cctools-port shim)
   - `powerpc-apple-darwin8-ar`, `nm`, `ranlib`, `otool`,
     `install_name_tool`, `libtool` (all cctools-port)
   - clang 7.1.1 (from the `llvm-7-darwin-ppc` sibling project)
   - 10.4u SDK
   - `ppc-cc` wrapper (in `scripts/ppc-cc.sh`)
   - `ppc-ld-tiger.sh` (the SSH-to-ppc-box linker)
   - a reachable PPC Tiger machine (for final link)

   The installer should either bundle all of this or fail early with a
   clear diagnostic if any is missing.

3. **PPC Tiger box on the install host.**  The final-link step needs
   ssh access to a Tiger/Leopard PPC machine with gcc14 + gmp.  The
   installer should ask the user for the ssh host alias and verify it
   before writing into settings.

## Phases

1. **Phase 1: "tarball plus instructions"** — current state.  Upload
   the .tar.xz to GitHub releases.  Document manually what the user
   needs to do.
2. **Phase 2: Install script** — `./install.sh --prefix --ppc-host`
   that untars, rewrites settings, verifies ssh, smoke-compiles
   hello.hs.
3. **Phase 3: Homebrew formula / similar** — only if there's demand.
