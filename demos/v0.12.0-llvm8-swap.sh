#!/bin/bash
# v0.12.0 demo: cross-toolchain swapped from LLVM-7 to LLVM-8.
#
# Functionally indistinguishable from v0.11.0 to a user — same demo
# programs, same output, same workflow.  The change is under the hood:
# our cross-clang is now LLVM-8.0.1 (with the BUG-010 patch landing
# the PPC32 Darwin "power" alignment field-cap that LLVM-8 dropped),
# instead of LLVM-7.1.1.
#
# This script reuses v0.11.0's demo to prove the swap is invisible at
# the user-program level.  The interesting bit is the version banner
# from `clang --version` we capture along the way to confirm we're on
# LLVM-8 r5+ on the host side; the produced PPC binaries themselves
# are byte-identical-shape to v0.11.0's.
#
# Prereqs: same as v0.11.0, plus the patched LLVM-8 cross-clang installed
# at $HOME/.local/ghc-ppc-xtools/clang-8 (or whatever the install
# convention puts it).  See scripts/cross-env.sh for the install
# procedure now.

set -euo pipefail

PPC_HOST="${1:-pmacg5}"

echo "==> 0. host cross-clang version"
~/.local/ghc-ppc-xtools/clang --version | head -3

echo
echo "==> 1..4. v0.11.0 demo (compile + run on Tiger)"
exec "$(dirname "$0")/v0.11.0-stage2-native.sh" "$PPC_HOST"
