#!/bin/bash
# v0.14.0 demo: GHCi REPL on PPC/Tiger.
#
# The internal interpreter (the in-process bytecode interpreter that
# powers `ghc --interactive`, `ghc -e`, and `ghci`) now runs on a real
# PowerMac G5 under Mac OS X 10.4 Tiger.  All the plumbing for this has
# been in place since v0.8.0 (TemplateHaskell): runtime Mach-O loader
# (patches 0007 + 0009 + 0012), BCO byte-swap on host/target endian
# mismatch (patch 0014), `__eprintf` stub (patch 0011), iserv +
# pgmi-shim for the external-interpreter path (patch 0010).
# v0.13.0 unblocked the last gating dependency by fixing the STUArray
# Bool big-endian miscompile (patch 0016) so stage2 native ghc could
# compile real programs without `-A1G`.
#
# v0.14.0 is the small turn of the key that finally lights up the REPL
# itself: `scripts/deploy-stage2.sh` now compiles `ghc/Main.hs` with
# `-DHAVE_INTERNAL_INTERPRETER` (and the `-i$GHC_SRC/ghc` /
# `-package exceptions -package time` extras the cabal flag would
# otherwise wire in).  No new patches.
#
# Session: docs/sessions/2026-05-15-session-55-ghci-repl-attempt/
#
# Prereqs: stage2 redeployed via v0.14.0+ `scripts/deploy-stage2.sh`.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
DYLD='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real

run_ghci() {
  local description=$1; shift
  echo "--- $description"
  ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC --interactive -ignore-dot-ghci 2>&1" "$@"
  echo
}

echo "==> 1. ghc -e: one-shot expression evaluation"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC -e 'sum [1..100]'"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC -e 'Data.List.sort [3,1,4,1,5,9,2,6,5,3,5]'"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC -e 'product [1..15 :: Integer]'"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC -e 'putStrLn \"hello from the REPL on Tiger PPC\"'"

echo
echo "==> 2. --interactive with stdin: types, arithmetic, let, lambdas"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC --interactive -ignore-dot-ghci 2>&1" <<'EOF'
:t reverse
:t (+)
let f = \x -> x*x + 1
map f [1..6]
take 12 (iterate (*2) 1)
import Data.Char
map toUpper "tiger powerpc"
import qualified Data.Map.Strict as M
M.toList (M.fromListWith (+) [(c, 1 :: Int) | c <- "supercalifragilisticexpialidocious"])
:q
EOF

echo
echo "==> 3. :load a real Haskell module, then call functions in it"
ssh -e none -T -q "$PPC_HOST" 'cat > /tmp/RepoDemo.hs' <<'EOF'
module RepoDemo where
import Data.List (sort, nub)
greet :: String -> String
greet who = "hello, " ++ who ++ "!"
factorial :: Integer -> Integer
factorial 0 = 1
factorial n = n * factorial (n - 1)
fib :: Int -> Int
fib 0 = 0
fib 1 = 1
fib n = fib (n - 1) + fib (n - 2)
sortUnique :: Ord a => [a] -> [a]
sortUnique = nub . sort
EOF
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC --interactive -ignore-dot-ghci 2>&1" <<'EOF'
:load /tmp/RepoDemo.hs
greet "tiger"
factorial 20
map fib [0..12]
sortUnique [3,1,4,1,5,9,2,6,5,3,5]
:t factorial
:t fib
:q
EOF

echo
echo "==> 4. Multi-line :{ :} block, then evaluate"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC --interactive -ignore-dot-ghci 2>&1" <<'EOF'
:{
collatz :: Int -> [Int]
collatz 1 = [1]
collatz n
  | even n    = n : collatz (n `div` 2)
  | otherwise = n : collatz (3 * n + 1)
:}
length (collatz 27)
maximum (collatz 27)
take 10 (collatz 27)
:q
EOF

echo
echo "v0.14.0 demo done.  GHCi REPL is alive on PPC/Tiger."
