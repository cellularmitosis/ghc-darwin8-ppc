#!/bin/bash
# Test the native stage2 ghc on Tiger.
#
# Assumes /opt/ghc-stage2/bin/ghc-stage2 (or wherever you installed it)
# is the cross-compiled-to-PPC ghc-bin executable, plus the matching
# lib tree (we'll rsync the cross-bindist's lib for stage2 to use).
set -euo pipefail
PPC_HOST=${PPC_HOST:-pmacg5}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

scp -q "$SCRIPT_DIR/NoMain.hs" "$SCRIPT_DIR/Hello.hs" "$PPC_HOST":/tmp/
echo "=== ghc --version ==="
ssh -e none -T -q "$PPC_HOST" 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc --version'

echo
echo "=== ghc -c NoMain.hs (Typeable-free non-main module) ==="
ssh -e none -T -q "$PPC_HOST" 'cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc -c NoMain.hs 2>&1; ls -la NoMain.o NoMain.hi 2>&1' || true

echo
echo "=== ghc -c -dno-typeable-binds NoMain.hs ==="
ssh -e none -T -q "$PPC_HOST" 'cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc -dno-typeable-binds -c NoMain.hs 2>&1; ls -la NoMain.o NoMain.hi 2>&1' || true

echo
echo "=== ghc Hello.hs -o hello (full main module) ==="
ssh -e none -T -q "$PPC_HOST" 'cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc Hello.hs -o hello 2>&1' || true
echo
echo "=== ./hello ==="
ssh -e none -T -q "$PPC_HOST" 'cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib ./hello 2>&1' || true
