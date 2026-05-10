#!/bin/bash
# exp-deploy-stage2-debug.sh
#
# SESSION 19 EXPERIMENT — build a stage2 native ghc linked against the
# *debug* RTS variant and deploy alongside the normal one.
#
# After this completes, on the Tiger host:
#     /opt/ghc-stage2/bin/ghc-real-debug   — debug-RTS-linked ghc
#     /opt/ghc-stage2/bin/ghc-real         — normal stage2 (unchanged)
#     /opt/ghc-stage2/bin/ghc              — wrapper (unchanged)
#
# To run a compile against the debug RTS with sanity checking:
#     ssh pmacg5 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
#                 /opt/ghc-stage2/bin/ghc-real-debug -v0 Hello.hs -o hello \
#                 +RTS -DS -A1m -RTS' 2>&1 | tee debug-rts.log
#
# Useful debug flags:
#   -DS  sanity-check GC after every collection (the big one)
#   -Dg  trace each GC
#   -Db  trace block allocator
#   -DZ  zero freed memory during GC (catches use-after-free)

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GHC_SRC="$REPO_ROOT/external/ghc-modern/ghc-9.2.8"
STAGE1="$GHC_SRC/_build/stage1/bin/powerpc-apple-darwin8-ghc"

source "$REPO_ROOT/scripts/cross-env.sh" >/dev/null 2>&1

[ -x "$STAGE1" ] || { echo "stage1 ghc not built: $STAGE1" >&2; exit 1; }

echo "==> [1/3] cross-compile ghc-bin (ghc/Main.hs) with -debug"
mkdir -p /tmp/stage2-build-debug
cd /tmp/stage2-build-debug
rm -f *.hi *.o ghc-stage2-debug

"$STAGE1" \
  -debug \
  -package ghc -package ghci -package haskeline \
  -outputdir /tmp/stage2-build-debug \
  -no-hs-main \
  -optc-DNON_POSIX_SOURCE \
  "$GHC_SRC/ghc/Main.hs" \
  "$GHC_SRC/ghc/hschooks.c" \
  -o /tmp/stage2-build-debug/ghc-stage2-debug

echo "==> [2/3] verify PPC Mach-O"
file /tmp/stage2-build-debug/ghc-stage2-debug | head -1

echo "==> [3/3] deploy to $PPC_HOST as /opt/ghc-stage2/bin/ghc-real-debug"
scp -q /tmp/stage2-build-debug/ghc-stage2-debug "$PPC_HOST:/opt/ghc-stage2/bin/ghc-real-debug"
ssh "$PPC_HOST" 'chmod +x /opt/ghc-stage2/bin/ghc-real-debug'

echo
echo "Debug-RTS stage2 deployed.  Try:"
echo "  ssh $PPC_HOST 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug --version'"
