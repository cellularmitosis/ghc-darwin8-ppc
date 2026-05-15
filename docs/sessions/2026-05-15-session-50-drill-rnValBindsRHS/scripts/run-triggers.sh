#!/bin/bash
# probe50 trigger: clean + len=600 + len=1650 cases.
set -u
SESSION_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$SESSION_DIR/logs/v1-triggers.log"

{
echo "=== clean (-A256m) ==="
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A256m -RTS 2>&1; echo RC=\$?" \
  | grep -E "PROBE50|RC="

echo
echo "=== failing len=600 (-A1m -G1) ==="
pad=$(awk 'BEGIN{for(i=1;i<=598;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; echo RC=\$?" \
  | grep -E "PROBE50|panic|RC="

echo
echo "=== failing len=1650 (-A1m -G1) ==="
pad=$(awk 'BEGIN{for(i=1;i<=1648;i++) printf "A"}')
ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env A=${pad} \
  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
  /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; echo RC=\$?" \
  | grep -E "PROBE50|panic|RC="
} | tee "$OUT"
