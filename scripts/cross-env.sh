# Source this before any GHC cross-configure/build on uranium.
# Sets up paths to the cross-toolchain and host GHC.
#
# Prerequisites on uranium (install once):
#   1. Host GHC 9.2.8:
#        tar -xJf external/ghc-9.2.8-aarch64-apple-darwin.tar.xz -C ~/.local/
#        cd ~/.local/ghc-9.2.8-aarch64-apple-darwin
#        ./configure --prefix=$HOME/.local/ghc-9.2.8 && make install
#   2. Cross-clang + SDK from the sibling llvm-7-darwin-ppc project.
#      Since v0.12.0 (session 18, attempt 3): **clang 8.0.1** with the
#      sister project's working-tree patches (BUG-003 + ABI-001 + ABI-002
#      + Tiger Mach-O LCs + BUG-010 — the last one restoring the PPC32
#      Darwin "power" struct alignment field-cap that LLVM-8 dropped).
#
#      The cross-clang is built on uranium from the source at
#      $HOME/claude/llvm-7-darwin-ppc/LLVM-8-Branch/  (1.5 GB; rsync'd
#      from indium once).  Build dir at
#      $HOME/claude/llvm-7-darwin-ppc/build-llvm8-uranium/  re-runs
#      incremental ninja in ~5 sec when their patch tree updates.
#
#        # One-time: rsync the source.
#        rsync -a indium:~/tmp/claude/llvm-7-darwin-ppc/LLVM-8-Branch/ \
#              $HOME/claude/llvm-7-darwin-ppc/LLVM-8-Branch/
#
#        # Configure + build clang.
#        mkdir -p $HOME/claude/llvm-7-darwin-ppc/build-llvm8-uranium
#        cd $HOME/claude/llvm-7-darwin-ppc/build-llvm8-uranium
#        cmake -G Ninja -DCMAKE_BUILD_TYPE=Release \
#              -DLLVM_TARGETS_TO_BUILD="PowerPC;X86" \
#              -DLLVM_ENABLE_ASSERTIONS=ON \
#              ../LLVM-8-Branch/llvm
#        ninja clang
#
#        # Install: binary + symlinks + freestanding headers.
#        cp bin/clang-8 $HOME/.local/ghc-ppc-xtools/clang-8
#        ln -sf clang-8 $HOME/.local/ghc-ppc-xtools/clang
#        ln -sf clang-8 $HOME/.local/ghc-ppc-xtools/clang++
#        # Freestanding headers from the released r5 tarball:
#        mkdir -p $HOME/.local/lib/clang/8.0.1
#        tar -C /tmp -xzf /path/to/clang-8.0.1-ppc-darwin8.tar.gz
#        cp -R /tmp/clang-8.0.1-ppc-darwin8/lib/clang/8.0.1/include \
#              $HOME/.local/lib/clang/8.0.1/
#
#        # SDK: same as before.
#        rsync -a indium:~/tmp/claude/llvm-7-darwin-ppc/sdks/MacOSX10.4u.sdk/ \
#              $HOME/.local/ghc-ppc-xtools/MacOSX10.4u.sdk/
#   3. cctools-port 877.8-ld64-253.9-ppc branch:
#        git clone --depth=1 -b 877.8-ld64-253.9-ppc \
#            https://github.com/tpoechtrager/cctools-port.git \
#            $HOME/.local/cctools-ppc/cctools-port
#        cd $HOME/.local/cctools-ppc/cctools-port/cctools
#        brew install libtool automake   # already on uranium
#        ./autogen.sh
#        ./configure --prefix=$HOME/.local/cctools-ppc/install \
#                    --target=powerpc-apple-darwin8 \
#                    CFLAGS="-std=gnu99 -Wno-error"
#        make -j$(nproc) && make install
#   4. happy 1.20 and alex via cabal-install (host ghc):
#        cabal install --install-method=copy --installdir=$HOME/.local/bin \
#                      --overwrite-policy=always happy-1.20.1.1 alex-3.2.7.4
#   5. CC wrapper at $HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-cc:
#        bash scripts/make-cross-cc-wrapper.sh

export XTOOLS=$HOME/.local/ghc-ppc-xtools
export SDK=$XTOOLS/MacOSX10.4u.sdk

# Autoconf cache: feed sub-package configures (time, base, unix, directory,
# process, etc.) correct Tiger answers so their HsXxxConfig.h doesn't claim
# clock_gettime/pthread_setname_np/etc. exist.
export CONFIG_SITE=/Users/cell/claude/ghc-darwin8-ppc/scripts/tiger-config.site

# Host GHC (needed to drive the cross-compile)
export PATH=$HOME/.local/ghc-9.2.8/bin:$PATH

# happy, alex
export PATH=$HOME/.local/bin:$PATH

# cctools-port: provides powerpc-apple-darwin8-{ar,ld,nm,libtool,otool,...}
export PATH=$HOME/.local/cctools-ppc/install/bin:$PATH

# Cross C compiler (clang from llvm-7-darwin-ppc, via our ppc-cc wrapper
# that adds -target -isysroot -mlinker-version=253.9 and uses the fake
# linker for configure's CC-works check)
export CROSS_CC=$XTOOLS/bin-wrap/ppc-cc
export CROSS_CLANG=$XTOOLS/clang
export CROSS_TRIPLE=powerpc-apple-darwin8

# Plain clang flags (when invoking clang directly, not via wrapper)
export CROSS_CFLAGS="-target $CROSS_TRIPLE -mlinker-version=253.9 -isysroot $SDK"

# The bootstrap Haskell tooling
export GHC_BOOT=$HOME/.local/ghc-9.2.8/bin/ghc

echo "cross-env loaded:"
echo "  host ghc:  $GHC_BOOT — $($GHC_BOOT --numeric-version 2>/dev/null)"
echo "  cross cc:  $CROSS_CC"
echo "  cross ld:  $(which powerpc-apple-darwin8-ld 2>/dev/null)"
echo "  sdk:       $SDK"
echo "  triple:    $CROSS_TRIPLE"
