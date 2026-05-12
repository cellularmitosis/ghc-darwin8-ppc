#!/bin/bash
# Re-test -G1 suppression with a CORRECT Big.hs (no type errors).
# Session 27's first Big.hs had a real type error that masked the
# corruption signal; this script uses Big2.hs which compiles cleanly
# on host ghc.
#
# Usage:  ./g1-big2-test.sh [SSH_HOST] [N_ITERS]
set -uo pipefail

PPC_HOST="${1:-pmacg5}"
N_ITERS="${2:-10}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/log/session27"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

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

run_profile () {
    local label="$1"
    local rts_flags="$2"
    local logbase="$LOGDIR/Big2-${label}"
    echo "=== Big2.hs iters=$N_ITERS flags='$rts_flags' ==="
    local pass=0 fail=0
    for i in $(seq 1 "$N_ITERS"); do
        local log="$logbase.iter${i}.log"
        ssh -q "$PPC_HOST" "
            cd /tmp
            rm -f Big2.hi Big2.o
            $DYLD $GHC_REAL -c Big2.hs $rts_flags 2>&1
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
        printf 'iter%02d rc=%s : %s\n' "$i" "$rc" "$sig"
    done
    echo "  SUMMARY: pass=$pass fail=$fail of $N_ITERS"
    echo
}

run_profile a1g     "+RTS -A1G -RTS"
run_profile a1m     "+RTS -A1m -RTS"
run_profile a1m-g1  "+RTS -A1m -G1 -RTS"
