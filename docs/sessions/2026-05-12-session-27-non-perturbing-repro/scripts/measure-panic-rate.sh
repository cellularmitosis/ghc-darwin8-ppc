#!/bin/bash
# Measure the panic rate of stage2 ghc compiling a small input under
# various RTS flag combos.  Goal: lock down a reliable, non-perturbing
# repro for the session-17 GC corruption bug after session 26 ruled
# out the BS-pinning-invariant theory.
#
# Default: 20 iterations of M5.hs, multiple +RTS profiles.
#
# Usage:  ./measure-panic-rate.sh [SSH_HOST] [N_ITERS] [INPUT]
# Default SSH_HOST=pmacg5, N_ITERS=20, INPUT=M5

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
N_ITERS="${2:-20}"
INPUT="${3:-M5}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/docs/sessions/2026-05-12-session-27-non-perturbing-repro/logs"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Make sure the input exists on pmacg5 (only really needed for M5 / a
# few standards — caller may pre-place other inputs).
case "$INPUT" in
  M5)
    ssh -q "$PPC_HOST" 'cat > /tmp/M5.hs' <<'EOF'
module M5 where
five = (5::Int)
six = (6::Int)
EOF
    ;;
  Hello)
    ssh -q "$PPC_HOST" 'cat > /tmp/Hello.hs' <<'EOF'
module Main where
main :: IO ()
main = putStrLn "Hello, World!"
EOF
    ;;
  M5plus)
    ssh -q "$PPC_HOST" 'cat > /tmp/M5plus.hs' <<'EOF'
module M5plus where
import Data.List (sort)
import qualified Data.Map.Strict as M
five :: Int
five = 5
six :: Int
six = 6
sortedKeys :: M.Map Int String -> [Int]
sortedKeys m = sort (M.keys m)
sampleMap :: M.Map Int String
sampleMap = M.fromList [(1,"a"),(2,"b"),(3,"c"),(4,"d"),(5,"e")]
EOF
    ;;
esac

run_profile () {
    local label="$1"
    local rts_flags="$2"
    local logbase="$LOGDIR/${INPUT}-${label}"
    echo "=== $INPUT iters=$N_ITERS flags='$rts_flags' ==="
    local pass=0 fail=0
    : > "$logbase.summary"
    for i in $(seq 1 "$N_ITERS"); do
        local log="$logbase.iter${i}.log"
        ssh -q "$PPC_HOST" "
            cd /tmp
            rm -f ${INPUT}.hi ${INPUT}.o
            $DYLD $GHC_REAL -c ${INPUT}.hs $rts_flags 2>&1
            echo \"GHC_EXIT=\$?\"
        " > "$log" 2>&1
        local rc
        rc=$(grep -m1 '^GHC_EXIT=' "$log" | sed 's/GHC_EXIT=//' || echo '?')
        local sig=""
        if [ "$rc" = "0" ]; then
            pass=$((pass+1))
            sig="OK"
        else
            fail=$((fail+1))
            # Extract first panic / error line for symptom classification
            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found)' "$log" 2>/dev/null \
                  | head -c 100)
            if [ -z "$sig" ]; then sig="UNKNOWN_FAIL_rc=$rc"; fi
        fi
        printf 'iter%02d rc=%s : %s\n' "$i" "$rc" "$sig" | tee -a "$logbase.summary"
    done
    echo
    echo "  SUMMARY: pass=$pass fail=$fail of $N_ITERS"
    echo "  Symptom histogram:"
    awk -F': ' '/^iter/ {print $2}' "$logbase.summary" | sort | uniq -c | sort -rn
    echo
}

# A1G control — should never crash.
run_profile a1g  "+RTS -A1G -RTS"

# A1m — the load-bearing repro.
run_profile a1m  "+RTS -A1m -RTS"

# A1m -G1 — single-generation; rules out gen0→gen1 promote-ordering quirks.
run_profile a1m-g1  "+RTS -A1m -G1 -RTS"

# A512k — smaller area, more frequent GC, should crash at least as often.
run_profile a512k  "+RTS -A512k -RTS"

# A4m — larger area, fewer GCs.  See where the threshold is.
run_profile a4m  "+RTS -A4m -RTS"
