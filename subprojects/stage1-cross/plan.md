# stage1-cross — plan

## Goal

A cross-compiler on arm64 macOS (uranium) that produces ppc
Mach-O binaries targeting powerpc-apple-darwin8, with final link
shipped via SSH to a real Tiger machine (pmacg5) that has gcc14 + ld.

## Approach

Three layers:

1. **Host toolchain** — clang 7.1.1 (from the sibling
   `llvm-7-darwin-ppc` project) + cctools-port ld64-253.9-ppc +
   hand-built happy/alex.  Under `~/.local/ghc-ppc-xtools/`.

2. **GHC 9.2.8 patched** to re-enable PPC/Darwin bits that were
   deleted in 2018 (commit `374e44704b`).  See `patches/` 0001–0007.

3. **SSH link bridge** — our cross `ld` can't handle the 10.4u SDK's
   crt1.o, so `scripts/ppc-ld-tiger.sh` rsyncs the object files to
   pmacg5 and invokes its native `ld` there.  Result scp'd back.

## Milestones (all done)

- [x] Host clang + SDK installed
- [x] cctools-port builds
- [x] GHC 9.2.8 `./configure --target=powerpc-apple-darwin8` succeeds
- [x] Hadrian stage0 builds (boot tools on arm64 host)
- [x] Stage1 RTS cross-compiles
- [x] All 33 Stage1 libraries cross-compile and register
- [x] libHSghc-9.2.8.a (compiler library) cross-compiles
- [x] First hello.hs runs on Tiger — 2026-04-23
- [x] Bindist .tar.xz packaged — 128 MB
