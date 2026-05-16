#!/bin/bash
# v0.14.1 demo: literate Haskell (.lhs) end-to-end on PPC/Tiger.
#
# What this demonstrates: the `unlit` literate-Haskell pre-processor
# in the v0.14.1 bindist is a real PPC binary that runs on Tiger.
# In v0.14.0 (and silently since v0.7.0) it shipped as a *host*
# arm64 binary with a `powerpc-apple-darwin8-` filename prefix —
# Hadrian's cross-mode helper-binary-copy path in
# `hadrian/src/Rules/Program.hs` excluded `iserv` but missed
# `unlit`.  Any `.lhs` source produced exit code 126 ("cannot
# execute binary file") from kernel `execve`.  T10989 (`:l dummy.lhs`)
# in upstream's GHCi testsuite catches it; session 58 surfaced it.
# v0.14.1's patch 0010 update fixes the underlying packaging bug —
# `unlit` now falls through to hadrian's `buildBinary`, which uses
# the cross-ghc + cross-cc to produce a real PPC Mach-O binary.
#
# This script:
#   1. scps the v0.14.1 .lhs demo file to Tiger.
#   2. Compiles it with stage2 native ghc on Tiger — the .lhs
#      pre-processor invocation routes through the (now PPC) unlit.
#   3. Runs the resulting binary, showing factorial / sort / collatz
#      output from a .lhs source.
#   4. Loads the same .lhs file into the GHCi REPL and calls into it
#      to exercise the `:l foo.lhs` REPL path (T10989's exact shape).
#
# Session: docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/
#
# Prereqs: v0.14.1 stage2 deployed to $PPC_HOST via deploy-stage2.sh
# (or v0.14.1 bindist installed via install.sh).

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
DYLD='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real
LHS="$(cd "$(dirname "$0")" && pwd)/v0.14.1-literate-haskell.lhs"

echo "==> 0. confirm unlit on Tiger is a real PPC binary"
ssh -e none -T -q "$PPC_HOST" 'file /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit'

echo
echo "==> 1. ship the .lhs to Tiger"
scp -q "$LHS" "$PPC_HOST:/tmp/literate.lhs"
ssh -e none -T -q "$PPC_HOST" 'head -3 /tmp/literate.lhs; echo "..."; wc -l /tmp/literate.lhs'

echo
echo "==> 2. compile the .lhs with stage2 native ghc on Tiger"
ssh -e none -T -q "$PPC_HOST" "
  set -e
  cd /tmp
  rm -f literate.o literate.hi literate
  $DYLD $GHC -O0 literate.lhs -o literate 2>&1 | tail -20
"

echo
echo "==> 3. run the compiled .lhs binary"
ssh -e none -T -q "$PPC_HOST" "$DYLD /tmp/literate"

echo
echo "==> 4. :load the .lhs into the GHCi REPL (T10989-shape exercise)"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC --interactive -ignore-dot-ghci 2>&1" <<'EOF'
:load /tmp/literate.lhs
factorial 25
take 8 (collatz 27)
:t collatz
:t factorial
main
:q
EOF

echo
echo "v0.14.1 demo done.  Literate Haskell works on PPC/Tiger."
