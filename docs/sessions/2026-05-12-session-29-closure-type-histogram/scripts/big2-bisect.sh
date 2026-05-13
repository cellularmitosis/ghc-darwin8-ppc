#!/bin/bash
# Bisect Big2.hs progressively to find which import/declaration triggers
# the stage2 GC bug (deterministic panic at GC 17 under -A1m -G1).
#
# Each variant is run 3 iters (deterministic — but redundant runs catch
# any flakes).  We expect EXACTLY the trigger removal to flip pass=0
# fail=3 → pass=3 fail=0.
#
# Usage:  ./big2-bisect.sh [SSH_HOST] [N_ITERS]
set -uo pipefail

PPC_HOST="${1:-pmacg5}"
N_ITERS="${2:-3}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/docs/sessions/2026-05-12-session-29-closure-type-histogram/logs"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"
RTS_FLAGS="+RTS -A1m -G1 -RTS"

# Variants:
#   B0 — the original Big2.hs (control: should fail 3/3)
#   B1 — drop topK + its where-bound swap
#   B2 — also drop Data.Map.Strict import
#   B3 — also drop scaleAndShift + cumsum
#   B4 — bare module with no imports (essentially M5)

cat > /tmp/B0.hs <<'EOF'
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

# B1: drop topK + its where-bound swap
cat > /tmp/B1.hs <<'EOF'
module Big2 where
import Data.List (sort, group)
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe)

freqMap :: Ord a => [a] -> M.Map a Int
freqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]

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

# B2: also drop Data.Map.Strict import (+ freqMap, countOf)
cat > /tmp/B2.hs <<'EOF'
module Big2 where
import Data.List (sort, group)
import Data.Maybe (fromMaybe)

dedup :: Ord a => [a] -> [a]
dedup = map head . group . sort

shift :: Int -> [Int] -> [Int]
shift n = map (+ n)

scaleAndShift :: Int -> Int -> [Int] -> [Int]
scaleAndShift s n = map (\x -> x * s + n)

allPositive :: [Int] -> Bool
allPositive = all (> 0)

cumsum :: Num a => [a] -> [a]
cumsum = scanl1 (+)
EOF

# B3: also drop scaleAndShift + cumsum, keep dedup/shift/allPositive
cat > /tmp/B3.hs <<'EOF'
module Big2 where
import Data.List (sort, group)

dedup :: Ord a => [a] -> [a]
dedup = map head . group . sort

shift :: Int -> [Int] -> [Int]
shift n = map (+ n)

allPositive :: [Int] -> Bool
allPositive = all (> 0)
EOF

# B4: bare module
cat > /tmp/B4.hs <<'EOF'
module Big2 where
foo :: Int -> Int
foo x = x + 1
EOF

for v in B0 B1 B2 B3 B4; do
  scp -q /tmp/${v}.hs "$PPC_HOST:/tmp/${v}.hs"
done

run_v () {
    local v="$1"
    echo "=== ${v}.hs iters=${N_ITERS} ==="
    local pass=0 fail=0
    for i in $(seq 1 "$N_ITERS"); do
        local log="$LOGDIR/bisect-${v}.iter${i}.log"
        ssh -q "$PPC_HOST" "
            cd /tmp
            rm -f ${v}.hi ${v}.o
            $DYLD $GHC_REAL -c ${v}.hs $RTS_FLAGS 2>&1
            echo \"GHC_EXIT=\$?\"
        " > "$log" 2>&1
        local rc
        rc=$(grep -m1 '^GHC_EXIT=' "$log" | sed 's/GHC_EXIT=//')
        if [ "$rc" = "0" ]; then
            pass=$((pass+1)); sig="OK"
        else
            fail=$((fail+1))
            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|<<loop>>|internal error|refineFromInScope|depSortStgBinds|not in scope)' "$log" 2>/dev/null | head -c 100)
            [ -z "$sig" ] && sig="UNKNOWN_FAIL_rc=$rc"
        fi
        local gcs
        gcs=$(grep -c '^PROBE28 ' "$log" 2>/dev/null || echo 0)
        printf '  iter%02d rc=%s gcs=%s : %s\n' "$i" "$rc" "$gcs" "$sig"
    done
    echo "  SUMMARY: pass=${pass} fail=${fail} of ${N_ITERS}"
    echo
}

for v in B0 B1 B2 B3 B4; do run_v "$v"; done
