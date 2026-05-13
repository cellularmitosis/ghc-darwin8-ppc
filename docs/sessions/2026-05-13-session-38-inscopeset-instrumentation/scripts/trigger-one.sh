#!/bin/bash
# trigger-one.sh — reproduce ONE panic at a specific env-len and capture
# the FULL output including the PROBE38-* lines.
#
# Usage: trigger-one.sh [HOST=pmacg5] [LEN=1650]
#
# Output: full stderr/stdout of one compilation, to stdout.

set -u
HOST=${1:-pmacg5}
LEN=${2:-1650}

pad=$(awk "BEGIN{for(i=1;i<=$((LEN-2));i++) printf \"A\"}")
ssh -q "$HOST" "cd /tmp && rm -f Big2.hi Big2.o; \
    env A=${pad} DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; \
    echo RC=\$?"
