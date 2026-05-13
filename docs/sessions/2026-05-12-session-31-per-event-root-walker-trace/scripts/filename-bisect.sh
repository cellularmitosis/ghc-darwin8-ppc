#!/bin/bash
# Filename 1-byte bisect.  Take the EXACT Big2.hs body, swap just the
# module name + filename, compile each variant with +RTS -A1m -G1.
# Goal: find a 1-byte filename flip that flips PASS↔FAIL.
#
# Module name must match filename (Haskell), so we vary both in lockstep.
# A name "N" → module file "/tmp/N.hs" containing "module N where ...".
#
# Usage:  ./filename-bisect.sh [SSH_HOST]
set -uo pipefail

PPC_HOST="${1:-pmacg5}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/logs"
mkdir -p "$LOGDIR"

GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

# Body (everything after `module XXX where`).  No leading/trailing
# whitespace mods; byte-identical to Big2.hs except module name.
read -r -d '' BODY <<'EOF'
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

run_name () {
    local name="$1"
    local f="/tmp/${name}.hs"
    # Stage the file
    ssh -q "$PPC_HOST" "cat > $f" <<EOI
module $name where
$BODY
EOI
    # Compile
    local out
    out=$(ssh -q "$PPC_HOST" "
        cd /tmp
        rm -f ${name}.hi ${name}.o
        $DYLD $GHC_REAL -c ${name}.hs +RTS -A1m -G1 -RTS 2>&1
        echo \"RC=\$?\"
    ")
    local rc
    rc=$(printf '%s\n' "$out" | grep -m1 '^RC=' | sed 's/RC=//')
    local sig
    if [ "$rc" = "0" ]; then
        sig="PASS"
    else
        sig=$(printf '%s\n' "$out" | grep -m1 -E '(refineFromInScope|panic|Bus error|Segmentation|<<loop>>|internal error|variable not found)' | head -c 80)
        sig="FAIL:${sig:-rc=$rc}"
    fi
    printf '%-8s %s\n' "$name" "$sig"
}

# Sweep 1: single-char names A..Z
echo "=== Single-char names (A..Z) ===" | tee "$LOGDIR/filename-bisect.log"
for c in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
    run_name "$c" | tee -a "$LOGDIR/filename-bisect.log"
done

# Sweep 2: 2-char names AA..AZ
echo "" | tee -a "$LOGDIR/filename-bisect.log"
echo "=== 2-char names A[A..Z] ===" | tee -a "$LOGDIR/filename-bisect.log"
for c in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
    run_name "A$c" | tee -a "$LOGDIR/filename-bisect.log"
done

# Sweep 3: 2-char names B[A..Z]
echo "" | tee -a "$LOGDIR/filename-bisect.log"
echo "=== 2-char names B[A..Z] ===" | tee -a "$LOGDIR/filename-bisect.log"
for c in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
    run_name "B$c" | tee -a "$LOGDIR/filename-bisect.log"
done

# Sweep 4: 3-char names AAA, AAB, AAC, AA D etc. - explore the
# session-29 found-failure of "AA"
echo "" | tee -a "$LOGDIR/filename-bisect.log"
echo "=== 3-char names AA[A..Z] ===" | tee -a "$LOGDIR/filename-bisect.log"
for c in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
    run_name "AA$c" | tee -a "$LOGDIR/filename-bisect.log"
done
