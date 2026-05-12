#!/bin/bash
# Run M5.hs through the PROBE23-instrumented stage2 ghc on pmacg5
# under various RTS flag combos.  Adapts session 23's run-poison.sh to
# also count PROBE23PINNED lines (the no-poison "denominator" log of
# pinned-block addresses on stack).
#
# The decision matrix from HANDOFF.md (session 24):
#
#   All 5/5 crash gone (exit 0)     → PROBE22POISON was the bug.
#                                     False-positive class is pinned
#                                     Addr#s; the actual GC-bug
#                                     mechanism is elsewhere.
#   Crash still fires (5/5 SIGSEGV) → BS really is non-pinned-backed.
#                                     Real bug.  Find the BS allocator.
#   Crash fires sometimes (1-4/5)   → Mixed signal.  Investigate.
#
# Usage:  ./run-poison.sh [SSH_HOST]
# Default SSH_HOST=pmacg5.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/log/session25"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Same M5.hs as session 19/20/23.
ssh -q "$PPC_HOST" 'cat > /tmp/M5.hs' <<'EOF'
module M5 where
five = (5::Int)
six = (6::Int)
EOF

run_one () {
    local label="$1"
    local rts_flags="$2"
    local logfile="$LOGDIR/poison-${label}.log"
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
    echo "    PROBE23 lines:        $(grep -c '^PROBE23 ' "$logfile" 2>/dev/null || echo 0)"
    echo "    PROBE23POISON lines:  $(grep -c '^PROBE23POISON' "$logfile" 2>/dev/null || echo 0)"
    echo "    PROBE23PINNED lines:  $(grep -c '^PROBE23PINNED' "$logfile" 2>/dev/null || echo 0)"
    if grep -q 'variable not found\|panic\|impossible' "$logfile"; then
        echo "    PANIC seen: $(grep -m1 'variable not found\|panic\|impossible' "$logfile")"
    fi
    if grep -qiE '0xdeadbeef|deadbeef|segmentation|bus error' "$logfile"; then
        echo "    DEADBEEF / segfault: $(grep -miE '0xdeadbeef|deadbeef|segmentation|bus error' "$logfile" | head -3)"
    fi
    echo
}

# Multiple iterations to capture non-determinism (mirrors session 23).
for i in 1 2 3 4 5; do
    run_one "iter${i}-A1m" '+RTS -A1m -RTS'
done

# Sanity-check mode (deterministic per session 19).
run_one "iter1-A1m-DS" '+RTS -A1m -DS -RTS'

# Control: -A1G should still work.
run_one "iter1-A1G" '+RTS -A1G -RTS'

echo
echo "All runs done.  Logs in $LOGDIR/poison-*.log"
echo "Summary by exit code:"
for f in "$LOGDIR"/poison-*.log; do
    label=$(basename "$f" .log | sed 's/poison-//')
    e=$(grep -m1 GHC_EXIT= "$f" 2>/dev/null | sed 's/GHC_EXIT=//' || echo "?")
    n_probe=$(grep -c '^PROBE23 ' "$f" 2>/dev/null || echo 0)
    n_poison=$(grep -c '^PROBE23POISON' "$f" 2>/dev/null || echo 0)
    n_pinned=$(grep -c '^PROBE23PINNED' "$f" 2>/dev/null || echo 0)
    panic=$(grep -m1 -E 'variable not found|deadbeef|panic|impossible' "$f" 2>/dev/null | head -c 80 || echo "")
    printf "  %-20s exit=%-4s gc=%-3s poisoned=%-3s pinned=%-3s  %s\n" \
        "$label" "$e" "$n_probe" "$n_poison" "$n_pinned" "$panic"
done
