#!/bin/bash
# deploy-stage2.sh
#
# Cross-build the stage2 native ghc binary, deploy to a Tiger PPC host,
# install the GC-workaround wrapper, write the Tiger lib/settings, and
# smoke-test it.
#
# Usage: ./scripts/deploy-stage2.sh [SSH_HOST]   (default: pmacg5)
#
# After this completes, the native ghc on the Tiger host is at:
#     /opt/ghc-stage2/bin/ghc          (wrapper, calls ghc-real with -A1G)
#     /opt/ghc-stage2/bin/ghc-real     (the actual PPC Mach-O binary)
#
# Tiger smoke test:
#     ssh tiger 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
#                /opt/ghc-stage2/bin/ghc --version'
#     ssh tiger 'cd /tmp && /opt/ghc-stage2/bin/ghc Hello.hs -o hello && ./hello'

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GHC_SRC="$REPO_ROOT/external/ghc-modern/ghc-9.2.8"
STAGE1="$GHC_SRC/_build/stage1/bin/powerpc-apple-darwin8-ghc"
STAGE1_LIB="$GHC_SRC/_build/stage1/lib"
WRAPPER="$REPO_ROOT/scripts/ghc-stage2-wrapper.sh"

source "$REPO_ROOT/scripts/cross-env.sh" >/dev/null 2>&1

[ -x "$STAGE1" ] || { echo "stage1 ghc not built: $STAGE1" >&2; exit 1; }
[ -x "$WRAPPER" ] || { echo "wrapper missing: $WRAPPER" >&2; exit 1; }

echo "==> [1/5] cross-compile ghc-bin (ghc/Main.hs)"
mkdir -p /tmp/stage2-build
cd /tmp/stage2-build
rm -f *.hi *.o ghc-stage2

"$STAGE1" \
  -package ghc -package ghci -package haskeline \
  -outputdir /tmp/stage2-build \
  -no-hs-main \
  -optc-DNON_POSIX_SOURCE \
  "$GHC_SRC/ghc/Main.hs" \
  "$GHC_SRC/ghc/hschooks.c" \
  -o /tmp/stage2-build/ghc-stage2

echo "==> [2/5] verify PPC Mach-O"
file /tmp/stage2-build/ghc-stage2 | head -1

echo "==> [3/5] deploy to $PPC_HOST"
ssh "$PPC_HOST" 'mkdir -p /opt/ghc-stage2/bin /opt/ghc-stage2/lib'
scp -q /tmp/stage2-build/ghc-stage2 "$PPC_HOST:/opt/ghc-stage2/bin/ghc-real"
scp -q "$WRAPPER" "$PPC_HOST:/opt/ghc-stage2/bin/ghc"
ssh "$PPC_HOST" 'chmod +x /opt/ghc-stage2/bin/ghc /opt/ghc-stage2/bin/ghc-real'
rsync -a --delete "$STAGE1_LIB/" "$PPC_HOST:/opt/ghc-stage2/lib/" >/dev/null

echo "==> [4/5] write Tiger lib/settings"
cat > /tmp/tiger-stage2-settings <<'SETTINGS_EOF'
[("GCC extra via C opts", "-fwrapv -fno-builtin")
,("C compiler command", "/opt/gcc14/bin/gcc")
,("C compiler flags", "")
,("C++ compiler flags", "")
,("C compiler link flags", "-L/opt/gmp-6.2.1/lib -liconv ")
,("C compiler supports -no-pie", "NO")
,("Haskell CPP command", "/opt/gcc14/bin/gcc")
,("Haskell CPP flags", "-E -undef -traditional -Wno-invalid-pp-token -Wno-unicode -Wno-trigraphs")
,("ld command", "/opt/gcc14/bin/ld")
,("ld flags", "")
,("ld supports compact unwind", "YES")
,("ld supports build-id", "NO")
,("ld supports filelist", "YES")
,("ld is GNU ld", "NO")
,("Merge objects command", "/opt/gcc14/bin/ld")
,("Merge objects flags", "-r")
,("ar command", "/usr/bin/ar")
,("ar flags", "qcls")
,("ar supports at file", "NO")
,("ranlib command", "/usr/bin/ranlib")
,("otool command", "/usr/bin/otool")
,("install_name_tool command", "/usr/bin/install_name_tool")
,("touch command", "touch")
,("dllwrap command", "/bin/false")
,("windres command", "/bin/false")
,("libtool command", "/usr/bin/libtool")
,("unlit command", "$topdir/bin/powerpc-apple-darwin8-unlit")
,("cross compiling", "NO")
,("target platform string", "powerpc-apple-darwin")
,("target os", "OSDarwin")
,("target arch", "ArchPPC")
,("target word size", "4")
,("target word big endian", "YES")
,("target has GNU nonexec stack", "YES")
,("target has .ident directive", "YES")
,("target has subsections via symbols", "YES")
,("target has RTS linker", "YES")
,("Unregisterised", "YES")
,("LLVM target", "powerpc-apple-darwin")
,("LLVM llc command", "llc")
,("LLVM opt command", "opt")
,("LLVM clang command", "clang")
,("Use interpreter", "YES")
,("Support SMP", "NO")
,("RTS ways", "v thr l debug thr_debug thr_l thr p thr_p debug_p thr_debug_p")
,("Tables next to code", "NO")
,("Leading underscore", "YES")
,("Use LibFFI", "YES")
,("RTS expects libdw", "NO")
]
SETTINGS_EOF
scp -q /tmp/tiger-stage2-settings "$PPC_HOST:/opt/ghc-stage2/lib/settings"

echo "==> [5/5] smoke-test on $PPC_HOST"
ssh -e none -T -q "$PPC_HOST" '
  set -e
  cd /tmp
  cat > /tmp/_stage2_hello.hs <<EOF
module Main where
main = putStrLn "stage2 native ghc on Tiger: ok"
EOF
  rm -f /tmp/_stage2_hello.o /tmp/_stage2_hello.hi /tmp/_stage2_hello
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc --version
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc /tmp/_stage2_hello.hs -o /tmp/_stage2_hello 2>&1 | tail -3
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /tmp/_stage2_hello
'

echo
echo "stage2 deployment to $PPC_HOST done."
echo "Native ghc: /opt/ghc-stage2/bin/ghc"
