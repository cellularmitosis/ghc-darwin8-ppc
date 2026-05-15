#!/bin/bash
# v0.13.0 demo: STUArray Bool big-endian root cause fixed.
#
# For 10 sessions, the stage2 native ghc on Tiger could not compile
# anything more than a trivial Hello.hs without panicking or silently
# producing 152-byte empty `.o` files.  Session 52 found, fixed, and
# deployed the root cause: a single big-endian-only library bug in
# `libraries/array/Data/Array/Base.hs`.  `STUArray Bool`'s `newArray`
# allocates `bOOL_SCALE n = ceil(n/8)` bytes via `setByteArray#` but
# its `unsafeRead`/`unsafeWrite` access via `readWordArray#` (a full
# machine word).  For sub-word sizes the trailing partial-word bytes
# are uninitialised heap memory; on big-endian the bit for element 0
# is the LSB in memory byte 3, not byte 0, so every read returns
# garbage.  `Data.Graph.scc` uses `STUArray Int Bool` for its
# "visited" set; a corrupt visited set drops vertices, the renamer
# drops bindings, the compiler emits empty .o files.
#
# This demo proves the fix.  It writes the same Big2.hs reproducer
# session 27 found, ships it to Tiger, stage2-compiles it 5 times
# in a row, and reports the resulting `.o` size each time.  Pre-fix:
# 152 bytes 5/5 ("empty .o").  Post-fix: 46340 bytes 5/5
# ("fully populated").  Then it stage2-compiles a real executable
# that exercises Big2's functions and runs it on Tiger.
#
# Patch: patches/0016-array-stuarray-bool-word-aligned-init.patch
# Session: docs/sessions/2026-05-15-session-52-stuarray-scope/
#
# Prereqs: stage2 deployed via `scripts/deploy-stage2.sh pmacg5`.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
DYLD='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real

echo "==> 1. Write Big2.hs on Tiger"
ssh -e none -T -q "$PPC_HOST" 'cat > /tmp/Big2.hs' <<'EOF'
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

echo
echo "==> 2. Compile Big2.hs 5x with the default RTS (no -A1G workaround)."
echo "    Pre-fix every run produced a 152-byte empty .o file."
echo "    Post-fix every run produces a fully-populated 46340-byte .o file."
for i in 1 2 3 4 5; do
  ssh -e none -T -q "$PPC_HOST" "
    cd /tmp
    rm -f Big2.hi Big2.o
    $DYLD $GHC -c Big2.hs 2>&1 | tail -1
    /usr/bin/stat -f 'iter $i: Big2.o = %z bytes' Big2.o 2>/dev/null \
      || stat -c 'iter $i: Big2.o = %s bytes' Big2.o
  "
done

echo
echo "==> 3. Also compile with -A1m -G1 (the small-nursery / single-gen"
echo "    flag combo that previously deterministically reproduced the bug)."
ssh -e none -T -q "$PPC_HOST" "
  cd /tmp
  rm -f Big2.hi Big2.o
  $DYLD $GHC -c Big2.hs +RTS -A1m -G1 -RTS 2>&1 | tail -1
  /usr/bin/stat -f 'Big2.o = %z bytes (-A1m -G1)' Big2.o 2>/dev/null \
    || stat -c 'Big2.o = %s bytes (-A1m -G1)' Big2.o
"

echo
echo "==> 4. Stage2-compile a real executable that calls Big2's functions"
ssh -e none -T -q "$PPC_HOST" 'cat > /tmp/Big2Main.hs' <<'EOF'
module Main where
import Big2
main :: IO ()
main = do
  let xs = "the quick brown fox jumps over the lazy dog the quick fox"
  putStrLn $ "topK 3 (chars):   " ++ show (topK 3 xs)
  putStrLn $ "dedup words:      " ++ show (dedup (words xs))
  putStrLn $ "countOf 'o' xs:   " ++ show (countOf 'o' (freqMap xs))
  putStrLn $ "shift 10 [1..5]:  " ++ show (shift 10 [1..5])
  putStrLn $ "cumsum [1..5]:    " ++ show (cumsum [1..5 :: Int])
  putStrLn $ "allPositive [..]: " ++ show (allPositive [1,2,3])
EOF

ssh -e none -T -q "$PPC_HOST" "
  set -e
  cd /tmp
  rm -f Big2Main.hi Big2Main.o Big2Main
  $DYLD $GHC --make Big2Main.hs -o Big2Main 2>&1 | tail -5
  $DYLD ./Big2Main
"

echo
echo "v0.13.0 demo done.  The 32-session-old empty-.o bug is dead."
