#!/bin/bash
# Run a -prof Haskell program on Tiger and verify .prof / .hp output.
set -euo pipefail
PPC_HOST=${PPC_HOST:-pmacg5}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/../../scripts/cross-env.sh" >/dev/null 2>&1 || true
STAGE1=${STAGE1:-$SCRIPT_DIR/../../external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc}

cd "$SCRIPT_DIR"
rm -f Mandel.hi Mandel.o mandel mandel.prof mandel.hp mandel.aux mandel.ps

echo "[1/3] cross-compile with -prof + cost centres..."
"$STAGE1" -O -prof -fprof-auto Mandel.hs -o mandel
file mandel | head -1

echo "[2/3] ship to $PPC_HOST..."
scp -q mandel "$PPC_HOST":/tmp/mandel

echo "[3/3] run with +RTS -p (time profiling) and -h (heap profiling)..."
ssh -e none -T -q "$PPC_HOST" '
cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib ./mandel +RTS -p -h -RTS > /tmp/mandel.out 2>&1
echo "--- output (first 5 rows) ---"; head -5 /tmp/mandel.out
echo "--- mandel.prof (first 30 lines) ---"; head -30 mandel.prof 2>&1
echo "--- mandel.hp (first 5 lines) ---"; head -5 mandel.hp 2>&1
echo "--- file sizes ---"
ls -la mandel mandel.prof mandel.hp 2>&1
'
