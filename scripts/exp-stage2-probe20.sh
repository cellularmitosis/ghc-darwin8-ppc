#!/bin/bash
# exp-stage2-probe20.sh
#
# SESSION 20 PROBE — once the PROBE20-instrumented stage2 is deployed
# to pmacg5, compile M5.hs and capture per-GC stack-walk stats.
#
# Output is formatted lines like:
#     PROBE20 gc_no=N N=g major=0/1 tso=0x... stk=0x... sp=0x... end=0x...
#             words=W heap_ptr=H evacd=E g0=G0 g1=G1 other=O
#             rCurNurs=0x... rCurAlloc=0x... rCurTSO=0x...
#
# Usage:  ./scripts/exp-stage2-probe20.sh [SSH_HOST]

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$REPO_ROOT/docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/logs"
mkdir -p "$LOGDIR"

GHC_DEBUG="/opt/ghc-stage2/bin/ghc-real-debug"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Ensure M5.hs is in place
ssh -q "$PPC_HOST" 'cat > /tmp/M5.hs' <<'EOF'
module M5 where
five = (5::Int)
six = (6::Int)
EOF

run_one () {
    local label="$1"
    local rts_flags="$2"
    local logfile="$LOGDIR/probe20-${label}.log"
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
    echo "    PROBE20 lines: $(grep -c '^PROBE20' "$logfile")"
    if grep -q "panic\|impossible" "$logfile"; then
        echo "    PANIC: $(grep -m1 'variable not found\|impossible' "$logfile")"
    fi
    grep -m1 'M5.o size' "$logfile" -A1 | tail -1 | sed 's/^/        /'
}

# Multiple iterations to capture non-determinism
for i in 1 2 3; do
    run_one "iter$i-vanilla-A1m" '+RTS -A1m -RTS'
done

# With sanity (deterministic mode)
run_one "iter1-sanity-A1m" '+RTS -A1m -DS -RTS'

# Control: working case (-A1G, exactly one GC)
run_one "iter1-vanilla-A1G" '+RTS -A1G -RTS'

echo
echo "All probes done.  Logs in $LOGDIR/probe20-*"
echo
echo "Per-probe summary (iter, num_GCs, total_heap_ptr, total_evacd, total_g0):"
for f in "$LOGDIR"/probe20-*.log; do
    label=$(basename "$f" .log | sed 's/probe20-//')
    n_gc=$(grep -c '^PROBE20' "$f")
    sum_heap=$(grep '^PROBE20' "$f" | awk '{for(i=1;i<=NF;i++)if($i~/^heap_ptr=/){gsub(/heap_ptr=/,"",$i);s+=$i}}END{print s+0}')
    sum_evacd=$(grep '^PROBE20' "$f" | awk '{for(i=1;i<=NF;i++)if($i~/^evacd=/){gsub(/evacd=/,"",$i);s+=$i}}END{print s+0}')
    sum_g0=$(grep '^PROBE20' "$f" | awk '{for(i=1;i<=NF;i++)if($i~/^g0=/){gsub(/g0=/,"",$i);s+=$i}}END{print s+0}')
    echo "  $label: n_gc=$n_gc heap_ptr=$sum_heap evacd=$sum_evacd g0=$sum_g0"
done
