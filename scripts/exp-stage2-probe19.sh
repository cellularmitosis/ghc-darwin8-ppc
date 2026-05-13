#!/bin/bash
# exp-stage2-probe19.sh
#
# SESSION 19 PROBE — once the markCAFs-instrumented stage2 is deployed
# to pmacg5, compile M5.hs and capture per-GC CAF counts.
#
# Output is formatted lines like:
#     PROBE19 markCAFs gc_no=N dyn=K rev=L dyn_head=0x... rev_head=0x...
#
# Usage:  ./scripts/exp-stage2-probe19.sh [SSH_HOST]

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$REPO_ROOT/docs/sessions/2026-05-09-session-19-stage2-gc-bug/logs"
mkdir -p "$LOGDIR"

GHC_DEBUG="/opt/ghc-stage2/bin/ghc-real-debug"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Ensure M5.hs is in place (in case we cleaned /tmp on pmacg5)
ssh -q "$PPC_HOST" 'cat > /tmp/M5.hs' <<'EOF'
module M5 where
five = (5::Int)
six = (6::Int)
EOF

run_one () {
    local label="$1"
    local rts_flags="$2"
    local logfile="$LOGDIR/probe19-${label}.log"
    echo "==> $label  ($rts_flags)"
    ssh -q "$PPC_HOST" "
        cd /tmp
        rm -f M5.hi M5.o
        $DYLD $GHC_DEBUG -c M5.hs $rts_flags 2>&1
        echo '----- M5.o size -----'
        ls -la M5.o 2>&1 | head
        echo '----- M5.o symbols -----'
        nm M5.o 2>/dev/null | grep -E 'closure\$' | sort -u || echo '(none)'
    " > "$logfile" 2>&1
    echo "    log: $logfile"
    echo "    PROBE19 lines:"
    grep "^PROBE19" "$logfile" | head -30 | sed 's/^/        /'
    echo "    summary:"
    if grep -q "panic\|impossible" "$logfile"; then
        echo "        PANIC: $(grep -m1 'variable not found\|impossible' "$logfile")"
    fi
    grep "M5.o size" "$logfile" -A1 | tail -1 | sed 's/^/        /'
}

# Multiple iterations to capture non-determinism
for i in 1 2 3; do
    run_one "iter$i-vanilla-A1m" '+RTS -A1m -RTS'
done

# With sanity to see deterministic mode
for i in 1 2 3; do
    run_one "iter$i-sanity-A1m" '+RTS -A1m -DS -RTS'
done

# Control: working case
run_one "iter1-vanilla-A1G" '+RTS -A1G -RTS'

echo
echo "All probes done.  Logs in $LOGDIR/probe19-*"
echo
echo "Summary of PROBE19 dyn counts (per probe):"
for f in "$LOGDIR"/probe19-*.log; do
    label=$(basename "$f" .log | sed 's/probe19-//')
    counts=$(grep "^PROBE19" "$f" | sed -n 's/.*dyn=\([0-9]*\).*/\1/p' | tr '\n' ' ')
    echo "  $label: $counts"
done
