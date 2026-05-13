#!/bin/bash
# Run M5.hs through the PROBE22POISON-instrumented stage2 ghc on pmacg5
# under various RTS flag combos.  Each iteration captures the exit
# status and the last few stderr lines (where a 0xDEADBEEF segfault
# or "variable not found" panic would land).
#
# Usage:  ./run-poison.sh [SSH_HOST]
# Default SSH_HOST=pmacg5.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/docs/sessions/2026-05-10-session-23-stage2-poison-probe/logs"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# M5.hs from session 19/20.
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
    echo "    PROBE22 lines: $(grep -c '^PROBE22 ' "$logfile" 2>/dev/null || echo 0)"
    echo "    PROBE22POISON lines: $(grep -c '^PROBE22POISON' "$logfile" 2>/dev/null || echo 0)"
    if grep -q 'variable not found\|panic\|impossible' "$logfile"; then
        echo "    PANIC seen: $(grep -m1 'variable not found\|panic\|impossible' "$logfile")"
    fi
    if grep -qiE '0xdeadbeef|deadbeef|segmentation|bus error' "$logfile"; then
        echo "    DEADBEEF / segfault: $(grep -miE '0xdeadbeef|deadbeef|segmentation|bus error' "$logfile" | head -3)"
    fi
    echo
}

# Multiple iterations to capture non-determinism.
for i in 1 2 3 4 5; do
    run_one "iter${i}-A1m" '+RTS -A1m -RTS'
done

# Sanity-check mode (deterministic per session 19).
run_one "iter1-A1m-DS" '+RTS -A1m -DS -RTS'

# Control: -A1G should still work (fewer GCs, no poisoning of live slots).
run_one "iter1-A1G" '+RTS -A1G -RTS'

echo
echo "All runs done.  Logs in $LOGDIR/poison-*.log"
echo "Summary by exit code:"
for f in "$LOGDIR"/poison-*.log; do
    label=$(basename "$f" .log | sed 's/poison-//')
    e=$(grep -m1 GHC_EXIT= "$f" 2>/dev/null | sed 's/GHC_EXIT=//' || echo "?")
    n_poison=$(grep -c '^PROBE22POISON' "$f" 2>/dev/null || echo 0)
    n_probe=$(grep -c '^PROBE22 ' "$f" 2>/dev/null || echo 0)
    panic=$(grep -m1 -E 'variable not found|deadbeef|panic|impossible' "$f" 2>/dev/null | head -c 80 || echo "")
    printf "  %-20s exit=%-4s gc=%s poisoned=%s  %s\n" "$label" "$e" "$n_probe" "$n_poison" "$panic"
done
