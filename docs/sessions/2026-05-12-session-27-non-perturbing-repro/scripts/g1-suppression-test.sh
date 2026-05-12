#!/bin/bash
# Test whether +RTS -A1m -G1 suppresses the stage2 GC bug across
# multiple workload sizes.  Session 27 already confirmed:
#   M5.hs +RTS -A1m       → 10/10 panic   (deterministic non-perturbing repro)
#   M5.hs +RTS -A1m -G1   → 10/10 PASS    (bug suppressed!)
#
# Question: does -G1 hold on slightly larger inputs that exercise
# more of the typechecker / simplifier?
#
# Usage:  ./g1-suppression-test.sh [SSH_HOST] [N_ITERS]
# Default: pmacg5, 5 iters each (we mainly want pass/fail signal).

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
N_ITERS="${2:-5}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/log/session27"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Place inputs on pmacg5.
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

ssh -q "$PPC_HOST" 'cat > /tmp/Big.hs' <<'EOF'
module Big where
import Data.List (sort, group)
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe)

freqMap :: Ord a => [a] -> M.Map a Int
freqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]

topK :: Ord a => Int -> [a] -> [(a, Int)]
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

run_profile () {
    local input="$1"
    local label="$2"
    local rts_flags="$3"
    local logbase="$LOGDIR/${input}-${label}"
    echo "=== $input.hs iters=$N_ITERS flags='$rts_flags' ==="
    local pass=0 fail=0
    : > "$logbase.summary"
    for i in $(seq 1 "$N_ITERS"); do
        local log="$logbase.iter${i}.log"
        ssh -q "$PPC_HOST" "
            cd /tmp
            rm -f ${input}.hi ${input}.o
            $DYLD $GHC_REAL -c ${input}.hs $rts_flags 2>&1
            echo \"GHC_EXIT=\$?\"
        " > "$log" 2>&1
        local rc
        rc=$(grep -m1 '^GHC_EXIT=' "$log" | sed 's/GHC_EXIT=//' || echo '?')
        local sig=""
        if [ "$rc" = "0" ]; then
            pass=$((pass+1)); sig="OK"
        else
            fail=$((fail+1))
            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found)' "$log" 2>/dev/null | head -c 100)
            [ -z "$sig" ] && sig="UNKNOWN_FAIL_rc=$rc"
        fi
        printf 'iter%02d rc=%s : %s\n' "$i" "$rc" "$sig" | tee -a "$logbase.summary"
    done
    echo "  SUMMARY: pass=$pass fail=$fail of $N_ITERS"
    echo
}

# M5plus
run_profile M5plus  a1m     "+RTS -A1m -RTS"
run_profile M5plus  a1m-g1  "+RTS -A1m -G1 -RTS"

# Big
run_profile Big     a1m     "+RTS -A1m -RTS"
run_profile Big     a1m-g1  "+RTS -A1m -G1 -RTS"
