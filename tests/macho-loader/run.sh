#!/bin/bash
# tests/macho-loader/run.sh — end-to-end test of the runtime PPC Mach-O loader.
#
# Compiles greeter.c to a fresh PPC Mach-O object and Driver.hs to a
# PPC executable, ships both to $PPC_HOST, runs the driver which:
#   loadObj("greeter.o") → resolveObjs() → lookupSymbol("_answer")/("_greet")
# Expected output:
#   answer() returned 42
#   relocateSectionPPC: hello from a runtime-loaded .o!
#
# Env vars (with sane defaults):
#   PPC_HOST  — ssh alias of the Tiger box (default: pmacg5)
#   STAGE1    — path to the cross-ghc binary (default: dev-tree)

set -euo pipefail

PPC_HOST=${PPC_HOST:-pmacg5}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

source "$SCRIPT_DIR/../../scripts/cross-env.sh" >/dev/null 2>&1 || true

STAGE1=${STAGE1:-$SCRIPT_DIR/../../external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc}
[ -x "$STAGE1" ] || { echo "macho-loader test: cannot find $STAGE1"; exit 1; }

CC=${CROSS_CC:-ppc-cc}

cd "$SCRIPT_DIR"
rm -f greeter.o driver Driver.hi Driver.o

echo "[1/3] compiling greeter.o (PPC Mach-O object)..."
"$CC" --target=powerpc-apple-darwin -c greeter.c -o greeter.o
file greeter.o | grep -q 'Mach-O object ppc' || { echo "FAIL: greeter.o is not PPC Mach-O"; exit 1; }

echo "[2/3] compiling driver (PPC executable)..."
"$STAGE1" -v0 Driver.hs -o driver

echo "[3/3] shipping to $PPC_HOST and running..."
scp -q driver greeter.o "$PPC_HOST":/tmp/

# Capture output to compare.
out=$(ssh -q "$PPC_HOST" 'cd /tmp && ./driver greeter.o; echo "rc=$?"')
ssh -q "$PPC_HOST" 'rm -f /tmp/driver /tmp/greeter.o' >/dev/null 2>&1 || true

echo "$out"

# Check expected substrings.
if echo "$out" | grep -q 'answer() returned 42' \
&& echo "$out" | grep -q 'relocateSectionPPC: hello from a runtime-loaded' \
&& echo "$out" | grep -q 'rc=0'; then
    echo "PASS: macho-loader runtime relocation works."
    exit 0
else
    echo "FAIL: macho-loader test did not pass."
    exit 1
fi
