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
cabal --store-dir=./.cabal-store \
      build \
      --with-compiler=$STAGE1 \
      --with-hsc2hs=$HSC2HS \
      --builddir=./dist 2>&1 | tail -5

# Find the executable
BIN=$(find dist/build -type f -perm -u+x ! -name "*.o" ! -name "*.hi" | head -1)
[ -x "$BIN" ] || { echo "error: no binary produced"; exit 1; }

echo ""
echo "== Running $BIN on $PPC_HOST =="
EXE_NAME=$(basename "$BIN")
scp -q "$BIN" "$PPC_HOST:/tmp/$EXE_NAME"
ssh -q "$PPC_HOST" "/tmp/$EXE_NAME" "$@"
