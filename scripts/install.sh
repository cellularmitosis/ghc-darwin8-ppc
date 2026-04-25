#!/bin/bash
# install.sh — install the ghc-9.2.8-stage1-cross-to-ppc-darwin8 bindist.
#
# Usage:
#   ./install.sh --prefix=/opt/ghc-ppc --ppc-host=pmacg5 [options]
#
# This is a thin alternative to GHC's own bindist `configure && make install`.
# The upstream Makefile has cross-compile warts (unprefixed wrapper names,
# redundant trees); we do the right thing directly:
#
# 1. Copy `ghc-9.2.8-powerpc-apple-darwin8/{bin,lib}` to `$PREFIX/{bin,lib}`.
# 2. Write `$PREFIX/lib/settings` pointing at this host's cross-tools.
# 3. Recache ghc-pkg.
# 4. Smoke-test: compile hello.hs, scp to $PPC_HOST, run, check output.

set -euo pipefail

# --- defaults ---
PREFIX=""
PPC_HOST=""
CROSS_CC=""
CROSS_LD=""
CCTOOLS_BIN=""
GMP_INCLUDE="/Users/cell/.local/ghc-ppc-xtools/include-ppc"
GMP_LIB_REMOTE="/opt/gmp-6.2.1/lib"
SKIP_SMOKE=0

usage() {
    cat <<EOF
Usage: $0 --prefix=<DIR> --ppc-host=<SSH_ALIAS> [options]

Required:
  --prefix=DIR         install root (e.g. /opt/ghc-ppc or \$HOME/.local/ghc-ppc)
  --ppc-host=ALIAS     ssh alias of a PPC Tiger/Leopard box with gcc14+gmp
                       (used for final link step and smoke test)

Optional (auto-detected from PATH if missing):
  --cross-cc=PATH      the ppc-cc wrapper (default: lookup ppc-cc in PATH)
  --cross-ld=PATH      the ppc-ld-tiger wrapper
  --cctools-bin=DIR    dir with powerpc-apple-darwin8-{ar,ranlib,nm,otool,...}
  --gmp-include=DIR    host-side PPC-native gmp.h dir
                       (default: /Users/cell/.local/ghc-ppc-xtools/include-ppc)
  --gmp-lib-remote=DIR PPC target's libgmp.dylib dir on \$PPC_HOST
                       (default: /opt/gmp-6.2.1/lib)
  --skip-smoke         don't run hello.hs smoke test

Prerequisites that must already exist on this machine:
  * bindist tarball extracted in the current directory
    (dir named ghc-9.2.8-powerpc-apple-darwin8/)
  * cctools-port with --target=powerpc-apple-darwin8
  * clang 7.1.1 + MacOSX10.4u.sdk
  * our ppc-cc / ppc-ld-tiger wrappers installed and in PATH

Prerequisites that must exist on \$PPC_HOST:
  * gcc 14.2 + ld at /opt/gcc14/bin/{gcc,ld}
  * libgmp.dylib at \$GMP_LIB_REMOTE
  * rsync + ssh working both ways

After install, invoke the compiler as:
  \$PREFIX/bin/powerpc-apple-darwin8-ghc hello.hs -o hello-ppc
EOF
    exit 2
}

for arg in "$@"; do
    case "$arg" in
        --prefix=*) PREFIX="${arg#--prefix=}" ;;
        --ppc-host=*) PPC_HOST="${arg#--ppc-host=}" ;;
        --cross-cc=*) CROSS_CC="${arg#--cross-cc=}" ;;
        --cross-ld=*) CROSS_LD="${arg#--cross-ld=}" ;;
        --cctools-bin=*) CCTOOLS_BIN="${arg#--cctools-bin=}" ;;
        --gmp-include=*) GMP_INCLUDE="${arg#--gmp-include=}" ;;
        --gmp-lib-remote=*) GMP_LIB_REMOTE="${arg#--gmp-lib-remote=}" ;;
        --skip-smoke) SKIP_SMOKE=1 ;;
        -h|--help) usage ;;
        *) echo "unknown flag: $arg"; usage ;;
    esac
done

[ -n "$PREFIX" ]  || { echo "error: --prefix required"; usage; }
[ -n "$PPC_HOST" ] || { echo "error: --ppc-host required"; usage; }

# Auto-detect tools — honour cross-env.sh's $CROSS_CC if already set,
# then fall back to PATH-based lookup.
if [ -z "$CROSS_CC" ]; then
    CROSS_CC="${CROSS_CC:-${CROSS_CC_ENV:-}}"
    [ -z "$CROSS_CC" ] && CROSS_CC=$(command -v ppc-cc || true)
    # Also check the canonical install location.
    [ -z "$CROSS_CC" ] && [ -x "$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-cc" ] && \
        CROSS_CC="$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-cc"
fi
if [ -z "$CROSS_LD" ]; then
    CROSS_LD=$(command -v ppc-ld-tiger || true)
    [ -z "$CROSS_LD" ] && [ -x "$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-tiger" ] && \
        CROSS_LD="$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-tiger"
fi
if [ -z "$CCTOOLS_BIN" ]; then
    AR=$(command -v powerpc-apple-darwin8-ar || true)
    [ -n "$AR" ] && CCTOOLS_BIN=$(dirname "$AR")
    # Canonical location fallback.
    [ -z "$CCTOOLS_BIN" ] && [ -d "$HOME/.local/cctools-ppc/install/bin" ] && \
        CCTOOLS_BIN="$HOME/.local/cctools-ppc/install/bin"
fi

# Locate the bindist source dir.  Support two layouts:
#   1. Running from alongside a freshly-extracted `ghc-9.2.8-powerpc-apple-darwin8/`.
#   2. Running from *inside* that dir (which is the case when install.sh
#      ships embedded in the tarball itself).
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
if [ -d "./ghc-9.2.8-powerpc-apple-darwin8" ]; then
    BINDIST_SRC="./ghc-9.2.8-powerpc-apple-darwin8"
elif [ -f "$SCRIPT_DIR/lib/package.conf.d/rts-1.0.2.conf" ]; then
    BINDIST_SRC="$SCRIPT_DIR"
elif [ -f "./lib/package.conf.d/rts-1.0.2.conf" ]; then
    BINDIST_SRC="."
else
    echo "error: can't find the bindist.  Run this script from either the"
    echo "       parent of ghc-9.2.8-powerpc-apple-darwin8/, or from inside it."
    exit 1
fi

echo "== Install config =="
echo "  prefix:          $PREFIX"
echo "  ppc-host:        $PPC_HOST"
echo "  cross-cc:        $CROSS_CC"
echo "  cross-ld:        $CROSS_LD"
echo "  cctools-bin:     $CCTOOLS_BIN"
echo "  gmp-include:     $GMP_INCLUDE"
echo "  gmp-lib-remote:  $GMP_LIB_REMOTE"
echo ""

# Prereq checks
for req in "$CROSS_CC" "$CROSS_LD"; do
    [ -x "$req" ] || { echo "missing: $req (use --cross-cc / --cross-ld)"; exit 1; }
done
for t in ar nm ranlib otool install_name_tool libtool ld; do
    [ -x "$CCTOOLS_BIN/powerpc-apple-darwin8-$t" ] || {
        echo "missing: $CCTOOLS_BIN/powerpc-apple-darwin8-$t"
        exit 1
    }
done
[ -f "$GMP_INCLUDE/gmp.h" ] || {
    echo "missing: $GMP_INCLUDE/gmp.h (--gmp-include)"
    exit 1
}
ssh -q -o ConnectTimeout=5 "$PPC_HOST" "ls /opt/gcc14/bin/gcc $GMP_LIB_REMOTE/libgmp.dylib > /dev/null" || {
    echo "error: couldn't reach $PPC_HOST or find gcc14/libgmp there"
    exit 1
}

# Copy tree
echo "== Copying to $PREFIX =="
mkdir -p "$PREFIX"
cp -R "$BINDIST_SRC/bin" "$PREFIX/"
cp -R "$BINDIST_SRC/lib" "$PREFIX/"

# Install scripts/runghc-tiger if present (compile + scp + ssh-run wrapper).
if [ -f "$BINDIST_SRC/cross-scripts/runghc-tiger" ]; then
    cp "$BINDIST_SRC/cross-scripts/runghc-tiger" "$PREFIX/bin/runghc-tiger"
    chmod +x "$PREFIX/bin/runghc-tiger"
    # Patch the script's PPC_HOST default to the user's --ppc-host.
    /usr/bin/sed -i.bak "s|^PPC_HOST=.*|PPC_HOST=\${PPC_HOST:-$PPC_HOST}|" "$PREFIX/bin/runghc-tiger"
    rm -f "$PREFIX/bin/runghc-tiger.bak"
fi

# Install scripts/pgmi-shim.sh if present (TemplateHaskell SSH bridge).
if [ -f "$BINDIST_SRC/cross-scripts/pgmi-shim.sh" ]; then
    cp "$BINDIST_SRC/cross-scripts/pgmi-shim.sh" "$PREFIX/bin/pgmi-shim.sh"
    chmod +x "$PREFIX/bin/pgmi-shim.sh"
    /usr/bin/sed -i.bak "s|^PPC_HOST=.*|PPC_HOST=\${PPC_HOST:-$PPC_HOST}|" "$PREFIX/bin/pgmi-shim.sh"
    rm -f "$PREFIX/bin/pgmi-shim.sh.bak"
fi

# Write settings
echo "== Writing $PREFIX/lib/settings =="
cat > "$PREFIX/lib/settings" <<EOF
[("GCC extra via C opts", "-fwrapv -fno-builtin")
,("C compiler command", "$CROSS_CC")
,("C compiler flags", "--target=powerpc-apple-darwin ")
,("C++ compiler flags", "--target=powerpc-apple-darwin ")
,("C compiler link flags", "--target=powerpc-apple-darwin -L$GMP_LIB_REMOTE -liconv ")
,("C compiler supports -no-pie", "NO")
,("Haskell CPP command", "$CROSS_CC")
,("Haskell CPP flags", "-E -undef -traditional -Wno-invalid-pp-token -Wno-unicode -Wno-trigraphs")
,("ld command", "$CCTOOLS_BIN/powerpc-apple-darwin8-ld")
,("ld flags", "")
,("ld supports compact unwind", "YES")
,("ld supports build-id", "NO")
,("ld supports filelist", "YES")
,("ld is GNU ld", "NO")
,("Merge objects command", "$CCTOOLS_BIN/powerpc-apple-darwin8-ld")
,("Merge objects flags", "-r")
,("ar command", "$CCTOOLS_BIN/powerpc-apple-darwin8-ar")
,("ar flags", "qcls")
,("ar supports at file", "NO")
,("ranlib command", "$CCTOOLS_BIN/powerpc-apple-darwin8-ranlib")
,("otool command", "$CCTOOLS_BIN/powerpc-apple-darwin8-otool")
,("install_name_tool command", "$CCTOOLS_BIN/powerpc-apple-darwin8-install_name_tool")
,("touch command", "touch")
,("dllwrap command", "/bin/false")
,("windres command", "/bin/false")
,("libtool command", "$CCTOOLS_BIN/powerpc-apple-darwin8-libtool")
,("unlit command", "\$topdir/bin/powerpc-apple-darwin8-unlit")
,("cross compiling", "YES")
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
,("RTS ways", "v thr l debug thr_debug thr_l thr")
,("Tables next to code", "NO")
,("Leading underscore", "YES")
,("Use LibFFI", "YES")
,("RTS expects libdw", "NO")
]
EOF

# Recache
echo "== Recaching package db =="
"$PREFIX/bin/powerpc-apple-darwin8-ghc-pkg" \
    --global-package-db "$PREFIX/lib/package.conf.d" \
    recache

# Smoke test
if [ "$SKIP_SMOKE" = "0" ]; then
    echo "== Smoke test =="
    tmp=$(mktemp -d)
    cat > "$tmp/hello.hs" <<'EOF'
main = putStrLn "hello from installed ghc-ppc-darwin8 bindist"
EOF
    "$PREFIX/bin/powerpc-apple-darwin8-ghc" -v0 "$tmp/hello.hs" -o "$tmp/hello-ppc"
    scp -q "$tmp/hello-ppc" "$PPC_HOST":/tmp/install-smoke-test
    out=$(ssh -q "$PPC_HOST" /tmp/install-smoke-test)
    ssh -q "$PPC_HOST" "rm -f /tmp/install-smoke-test"
    rm -rf "$tmp"
    if [ "$out" = "hello from installed ghc-ppc-darwin8 bindist" ]; then
        echo "  PASS: '$out'"
    else
        echo "  FAIL.  Expected 'hello from installed ghc-ppc-darwin8 bindist'; got:"
        echo "  $out"
        exit 1
    fi
fi

echo ""
echo "== Done =="
echo "Add $PREFIX/bin to PATH and invoke: powerpc-apple-darwin8-ghc"
