#!/bin/bash
# exp-stage2-debug-rts-probe.sh
#
# SESSION 19 EXPERIMENT — once exp-deploy-stage2-debug.sh has put
# /opt/ghc-stage2/bin/ghc-real-debug on pmacg5, run a series of
# small-input compiles under increasingly aggressive RTS debug
# flags and capture the output for analysis.
#
# Usage:  ./scripts/exp-stage2-debug-rts-probe.sh [SSH_HOST]
#
# Output: written to /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-09-session-19-stage2-gc-bug/logs/

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$REPO_ROOT/docs/sessions/2026-05-09-session-19-stage2-gc-bug/logs"
mkdir -p "$LOGDIR"

GHC_DEBUG="/opt/ghc-stage2/bin/ghc-real-debug"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Use the simplest reproducer that already triggers the bug at -A1m:
# M5.hs (two trivial Int bindings).  Failure mode: empty 152-byte .o
# (no closures) under default -A.  Working under -A1G.
PROBE_HS='module M5 where
five = (5::Int)
six = (6::Int)
'

ssh -q "$PPC_HOST" 'cat > /tmp/M5.hs' <<EOF
$PROBE_HS
EOF

run_probe () {
    local label="$1"
    local rts_flags="$2"
    local logfile="$LOGDIR/probe-${label}.log"
    echo "==> probe: $label  ($rts_flags)"
    ssh -q "$PPC_HOST" "
        cd /tmp
        rm -f M5.hi M5.o
        $DYLD $GHC_DEBUG -c M5.hs $rts_flags 2>&1
        echo '----- M5.o symbols -----'
        nm M5.o 2>/dev/null | grep -E 'closure\$|_five_|_six_' | sort -u
        echo '----- M5.o size -----'
        ls -la M5.o
    " > "$logfile" 2>&1
    echo "    log: $logfile  ($(wc -l < "$logfile") lines)"
    # Quick at-a-glance summary
    if grep -q "Sanity check\|sanity\|inconsistent\|invariant\|barf" "$logfile"; then
        echo "    !!! SANITY/INVARIANT FIRED !!!"
        grep -i "sanity\|inconsistent\|invariant\|barf\|panic" "$logfile" | head -5 | sed 's/^/        /'
    fi
}

# Probe 1: vanilla, big nursery (control — should work, no GC fires)
run_probe vanilla-A1G '+RTS -A1G -RTS'

# Probe 2: vanilla, default nursery (control — should fail, classic bug)
run_probe vanilla-A1m '+RTS -A1m -RTS'

# Probe 3: sanity-check GC, default nursery
run_probe sanity-A1m '+RTS -DS -A1m -RTS'

# Probe 4: GC tracing + sanity, default nursery
run_probe gc-trace-A1m '+RTS -Dg -DS -A1m -RTS'

# Probe 5: zero-on-gc + sanity
run_probe zero-on-gc-A1m '+RTS -DZ -DS -A1m -RTS'

# Probe 6: block-allocator tracing
run_probe block-trace-A1m '+RTS -Db -DS -A1m -RTS'

# Probe 7: single-generation GC (no gen0->gen1 promotion).
# If the bug goes away with -G1, that strongly implicates the
# evacuation/promotion path between gen0 and gen1.
run_probe gen1-A1m '+RTS -G1 -A1m -RTS'

# Probe 8: -G1 + sanity, to also assert what's left
run_probe gen1-sanity-A1m '+RTS -G1 -DS -A1m -RTS'

echo
echo "All probes done.  See $LOGDIR/ for output."
