#!/bin/bash
# Run M5.hs through the PROBE26-instrumented stage2 ghc on pmacg5,
# capture the PROBE26 classifier output, and look for any UNPINNED
# entries (the smoking gun: a BS reaching mkFastStringByteString
# whose underlying MutableByteArray# is non-pinned).
#
# Decision matrix:
#   At least one PROBE26 ... +UNPINNED ... line  → that's the violator.
#                                                  Find its caller and patch.
#   No UNPINNED lines, crash still fires         → the non-pinned MBA the
#                                                  Addr# points into is
#                                                  produced upstream of
#                                                  mkFastStringByteString
#                                                  (e.g., via Short.fromShort
#                                                  with a buggy isPinned
#                                                  primop result).  Or
#                                                  another mechanism.
#   No UNPINNED, no crash                        → instrumentation perturbed
#                                                  the layout; bug timing-
#                                                  sensitive.  Re-investigate.
#
# Usage:  ./run-probe26.sh [SSH_HOST]
# Default SSH_HOST=pmacg5.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/log/session26"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Same M5.hs as session 19/20/23/25.
ssh -q "$PPC_HOST" 'cat > /tmp/M5.hs' <<'EOF'
module M5 where
five = (5::Int)
six = (6::Int)
EOF

run_one () {
    local label="$1"
    local rts_flags="$2"
    local logfile="$LOGDIR/probe26-${label}.log"
    echo "==> $label  ($rts_flags)"
    ssh -q "$PPC_HOST" "
        cd /tmp
        rm -f M5.hi M5.o
        $DYLD $GHC_REAL -c M5.hs $rts_flags
        echo \"GHC_EXIT=\$?\"
    " > "$logfile" 2>&1
    local exit_status=$?
    echo "    log: $logfile (ssh exit=$exit_status)"
    echo "    GHC_EXIT line: $(grep -m1 GHC_EXIT= "$logfile" 2>/dev/null || echo '(missing — likely segfault)')"
    echo "    PROBE26 lines:           $(grep -c '^PROBE26 ' "$logfile" 2>/dev/null || echo 0)"
    echo "    PROBE26 UNPINNED lines:  $(grep -c 'UNPINNED' "$logfile" 2>/dev/null || echo 0)"
    echo "    PROBE26 PlainPtr lines:  $(grep -c '^PROBE26 .*PlainPtr' "$logfile" 2>/dev/null || echo 0)"
    echo "    PROBE26 MallocPtr lines: $(grep -c '^PROBE26 .*MallocPtr' "$logfile" 2>/dev/null || echo 0)"
    echo "    PROBE26 FinalPtr lines:  $(grep -c '^PROBE26 .*FinalPtr' "$logfile" 2>/dev/null || echo 0)"
    echo "    PROBE26 PlainFP lines:   $(grep -c '^PROBE26 .*PlainForeignPtr' "$logfile" 2>/dev/null || echo 0)"
    if grep -q 'UNPINNED' "$logfile"; then
        echo "    *** SMOKING GUN: UNPINNED entries follow ***"
        grep 'UNPINNED' "$logfile" | head -10
    fi
    echo
}

# Iter 1: -A1G — should compile cleanly (no GC, no probe data of interest)
run_one iter1-A1G  "+RTS -A1G -RTS"

# Iter 2: -A1m  — should crash
run_one iter2-A1m  "+RTS -A1m -RTS"

# Iter 3: -A1m again (deterministic crash check)
run_one iter3-A1m  "+RTS -A1m -RTS"

echo "==> Aggregate UNPINNED hits across all iters:"
grep -h 'UNPINNED' "$LOGDIR"/probe26-*.log | sort | uniq -c | sort -rn | head -20
echo
echo "==> Tag histogram (across ALL iters, ALL calls):"
grep -h '^PROBE26' "$LOGDIR"/probe26-*.log \
  | sed -E 's/^PROBE26 #[0-9]+ ([A-Za-z+]+) .*/\1/' \
  | sort | uniq -c | sort -rn
