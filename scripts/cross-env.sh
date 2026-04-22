# Source this before any GHC cross-configure/build on uranium.
# Sets up paths to the cross-toolchain and host GHC.
#
# Prerequisites on uranium (install once):
#   1. Host GHC 9.2.8:
#        tar -xJf external/ghc-9.2.8-aarch64-apple-darwin.tar.xz -C ~/.local/
#        cd ~/.local/ghc-9.2.8-aarch64-apple-darwin
#        ./configure --prefix=$HOME/.local/ghc-9.2.8 && make install
#   2. Cross-clang + SDK from the sibling llvm-7-darwin-ppc project:
#        rsync -a indium:~/tmp/claude/llvm-7-darwin-ppc/build-phase0/bin/clang* \
#              $HOME/.local/ghc-ppc-xtools/
#        rsync -a indium:~/tmp/claude/llvm-7-darwin-ppc/build-phase0/lib/clang/7.1.1/ \
#              $HOME/.local/lib/clang/7.1.1/   # the resource-dir (has float.h etc)
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
