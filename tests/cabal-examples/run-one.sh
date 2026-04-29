#!/bin/bash
# Build one cabal example and run it on $PPC_HOST (default: pmacg5).
#
# Usage:
#   ./run-one.sh <example-dir> [--args-to-binary...]
#
# E.g.:
#   ./run-one.sh random
#   ./run-one.sh optparse --name alice --count 3
#   ./run-one.sh full-stack-cli --input people.json --desc

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
PPC_HOST=${PPC_HOST:-pmacg5}

[ $# -ge 1 ] || { echo "usage: $0 <example-dir> [args...]"; exit 2; }
EXAMPLE="$1"; shift
[ -d "$SCRIPT_DIR/$EXAMPLE" ] || { echo "error: no such example: $SCRIPT_DIR/$EXAMPLE"; exit 1; }

source "$REPO_ROOT/scripts/cross-env.sh" > /dev/null 2>&1
STAGE1=$REPO_ROOT/external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc
HSC2HS=$REPO_ROOT/external/ghc-modern/ghc-9.2.8/_build/stage0/bin/powerpc-apple-darwin8-hsc2hs

cd "$SCRIPT_DIR/$EXAMPLE"

# Projects that need a cabal.project but don't have one inherit the
# default: .
if [ ! -f cabal.project ]; then
    echo "packages: ." > cabal.project
fi

echo "== Building $EXAMPLE =="
EXTRA_FLAGS=()
# OpenSSL paths: pass via env so https-get and friends can find headers/libs.
if [ -n "${OPENSSL_PREFIX:-}" ]; then
    EXTRA_FLAGS+=("--extra-include-dirs=$OPENSSL_PREFIX/include")
    EXTRA_FLAGS+=("--extra-lib-dirs=$OPENSSL_PREFIX/lib")
fi
cabal --store-dir=./.cabal-store \
      build \
      --with-compiler=$STAGE1 \
      --with-hsc2hs=$HSC2HS \
      --builddir=./dist \
      "${EXTRA_FLAGS[@]}" 2>&1 | tail -5

# Find the executable.  Restrict to PPC Mach-O so we don't pick up
# stray host-side helpers (e.g. autoconf's `config.status`, which is
# also marked executable when a vendored package shipped a configure).
BIN=$(find dist/build -type f -perm -u+x ! -name "*.o" ! -name "*.hi" \
        | while read -r f; do
            file "$f" 2>/dev/null | grep -q 'Mach-O.*ppc' && echo "$f"
          done | head -1)
[ -x "$BIN" ] || { echo "error: no binary produced"; exit 1; }

echo ""
echo "== Running $BIN on $PPC_HOST =="
EXE_NAME=$(basename "$BIN")
scp -q "$BIN" "$PPC_HOST:/tmp/$EXE_NAME"
# DYLD_LIBRARY_PATH set up so HsOpenSSL/libgmp linked binaries can find their
# runtime deps on Tiger.  Adds nothing for examples that don't need them.
REMOTE_DYLD=${REMOTE_DYLD:-/opt/openssl-1.1.1t/lib:/opt/gmp-6.2.1/lib:/opt/gcc14/lib}
ssh -q "$PPC_HOST" "DYLD_LIBRARY_PATH=$REMOTE_DYLD /tmp/$EXE_NAME" "$@"
