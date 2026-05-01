#!/bin/bash
# v0.11.0 demo: stage2 native ghc on Tiger.
#
# Stage1 cross-compiler runs on the host (uranium / arm64 macOS) and
# emits PPC Mach-O.  Stage2 is the native ghc binary that runs *on Tiger*
# and compiles Haskell to PPC Mach-O without going through the host.
#
# This demo:
#   1. SSH's to Tiger.
#   2. Writes a small Haskell source file there.
#   3. Compiles it on Tiger with stage2 ghc.
#   4. Runs the resulting binary.
#   5. Compiles a second program that imports Data.Map.Strict and runs
#      it, proving real .hi-file ingestion works through stage2.
#
# Stage2 ghc is wrapped (scripts/ghc-stage2-wrapper.sh) so it always
# launches with `+RTS -A1G -RTS`.  That works around the PPC-Darwin
# RTS GC bug investigated in session 17 -- a major GC during a compile
# corrupts the typechecker's binding bag.  -A1G keeps a small compile
# inside one allocation block, no GC fires, no bug.
#
# Prereqs:
#   * Stage1 built (`hadrian/build --flavour=quick-cross --docs=none`).
#   * Stage2 deployed via `scripts/deploy-stage2.sh pmacg5`
#     (or whatever your tiger ssh alias is).
#
# Usage:
#   $ ./demos/v0.11.0-stage2-native.sh           # uses pmacg5
#   $ ./demos/v0.11.0-stage2-native.sh ibookg37  # specific host

set -euo pipefail

PPC_HOST="${1:-pmacg5}"
DYLD='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc

echo "==> 1. ghc --version"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC --version"

echo
echo "==> 2. write a small Haskell source on Tiger"
ssh -e none -T -q "$PPC_HOST" 'cat > /tmp/stage2-hello.hs' <<'EOF'
module Main where
main :: IO ()
main = putStrLn "Compiled and run natively on Tiger PPC."
EOF

echo "==> 3. compile + run"
ssh -e none -T -q "$PPC_HOST" "
  set -e
  cd /tmp
  rm -f stage2-hello.o stage2-hello.hi stage2-hello
  $DYLD $GHC stage2-hello.hs -o stage2-hello 2>&1 | tail -3
  $DYLD ./stage2-hello
"

echo
echo "==> 4. compile a program with Data.Map.Strict"
ssh -e none -T -q "$PPC_HOST" 'cat > /tmp/stage2-words.hs' <<'EOF'
module Main where
import qualified Data.Map.Strict as M
main :: IO ()
main = do
  let text = "the quick brown fox jumps over the lazy dog the quick fox"
      counts = M.toList (M.fromListWith (+) [(w, 1::Int) | w <- words text])
  mapM_ print counts
EOF

ssh -e none -T -q "$PPC_HOST" "
  set -e
  cd /tmp
  rm -f stage2-words.o stage2-words.hi stage2-words
  $DYLD $GHC stage2-words.hs -o stage2-words 2>&1 | tail -3
  $DYLD ./stage2-words
"

echo
echo "stage2 native ghc demo done."
