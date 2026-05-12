#!/bin/bash
# Run the session-29 PROBE29 matrix.
#
# PROBE29 extends PROBE28 with per-closure-type histograms emitted
# from rts/sm/Scav.c::scavenge_block and rts/sm/Evac.c::evacuate,
# plus a forwarding-pointer hit count.  Output:
#   PROBE28 gc=<n> N=<gen> maj=<0|1> ng=<gens> preMutN=... staticChain=... copiedW=... liveW=... liveB=...
#   PROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...
#   PROBE29 gc=<n> evac e<type>=<count> ...
#
# Matrix (focused on the cleanest discriminator):
#   M5.hs    +RTS -A1m -G1 -RTS  — PASS baseline (session 28: 5/5 OK)
#   Big2.hs  +RTS -A1m -G1 -RTS  — FAIL baseline (session 28: 5/5 panic)
#
# Goal: identify the closure type whose count diverges between the
# passing M5 GCs and the failing Big2 GC.
#
# Usage:  ./run-probe-matrix.sh [SSH_HOST] [N_ITERS]
set -uo pipefail

PPC_HOST="${1:-pmacg5}"
N_ITERS="${2:-5}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/log/session29"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Stage inputs on pmacg5 (same as session 28).
ssh -q "$PPC_HOST" 'cat > /tmp/M5.hs' <<'EOF'
module M5 where
five = (5::Int)
six = (6::Int)
EOF

ssh -q "$PPC_HOST" 'cat > /tmp/Big2.hs' <<'EOF'
module Big2 where
import Data.List (sort, group)
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe)

freqMap :: Ord a => [a] -> M.Map a Int
freqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]

topK :: Ord a => Int -> [a] -> [(Int, a)]
topK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs
  where swap (a, b) = (b, a)

dedup :: Ord a => [a] -> [a]
dedup = map head . group . sort

countOf :: Ord a => a -> M.Map a Int -> Int
countOf k m = fromMaybe 0 (M.lookup k m)

shift :: Int -> [Int] -> [Int]
shift n = map (+ n)

scaleAndShift :: Int -> Int -> [Int] -> [Int]
scaleAndShift s n = map (\x -> x * s + n)

allPositive :: [Int] -> Bool
allPositive = all (> 0)

cumsum :: Num a => [a] -> [a]
cumsum = scanl1 (+)
EOF

run_cell () {
    local input="$1"
    local label="$2"
    local rts="$3"
    local logbase="$LOGDIR/${input}-${label}"
    echo "=== ${input}.hs iters=${N_ITERS} flags='${rts}' ==="
    local pass=0 fail=0
    for i in $(seq 1 "$N_ITERS"); do
        local log="${logbase}.iter${i}.log"
        ssh -q "$PPC_HOST" "
            cd /tmp
            rm -f ${input}.hi ${input}.o
            $DYLD $GHC_REAL -c ${input}.hs $rts 2>&1
            echo \"GHC_EXIT=\$?\"
        " > "$log" 2>&1
        local rc
        rc=$(grep -m1 '^GHC_EXIT=' "$log" | sed 's/GHC_EXIT=//' || echo '?')
        local sig
        if [ "$rc" = "0" ]; then
            pass=$((pass+1)); sig="OK"
        else
            fail=$((fail+1))
            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found|not in scope)' "$log" 2>/dev/null | head -c 120)
            [ -z "$sig" ] && sig="UNKNOWN_FAIL_rc=$rc"
        fi
        local gcs
        gcs=$(grep -c '^PROBE28 ' "$log" 2>/dev/null || echo 0)
        printf '  iter%02d rc=%s gcs=%s : %s\n' "$i" "$rc" "$gcs" "$sig"
    done
    echo "  SUMMARY: pass=${pass} fail=${fail} of ${N_ITERS}"
    echo
}

run_cell M5     a1m-g1  "+RTS -A1m -G1 -RTS"
run_cell Big2   a1m-g1  "+RTS -A1m -G1 -RTS"
