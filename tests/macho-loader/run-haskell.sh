#!/bin/bash
# tests/macho-loader/run-haskell.sh — load a real Haskell .o on Tiger.
#
# Cross-compiles Greeter.hs to a PPC Mach-O object that exercises the
# full reloc surface (HI16/LO16/HA16 halves, scattered SECTDIFF pairs,
# BR24 with jump-island fallback for puts), then has HaskellDriver.hs
# load it via the runtime PPC Mach-O loader, resolveObjs, and
# lookupSymbol the entry points.
#
# Companion to run.sh which uses a tiny C source.  This Haskell test
# stresses the reloc paths that simple C output doesn't generate.
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

cd "$SCRIPT_DIR"
rm -f Greeter.o Greeter.hi HaskellDriver.hi HaskellDriver.o haskell-driver

echo "[1/3] cross-compiling Greeter.hs to a PPC Haskell object..."
"$STAGE1" -v0 -c Greeter.hs -o Greeter.o
file Greeter.o | grep -q 'Mach-O object ppc' || { echo "FAIL: Greeter.o is not PPC Mach-O"; exit 1; }

echo "[2/3] cross-compiling HaskellDriver.hs..."
"$STAGE1" -v0 HaskellDriver.hs -o haskell-driver

echo "[3/3] shipping to $PPC_HOST and running..."
scp -q haskell-driver Greeter.o "$PPC_HOST":/tmp/

out=$(ssh -q "$PPC_HOST" 'cd /tmp && ./haskell-driver Greeter.o; echo "rc=$?"')
ssh -q "$PPC_HOST" 'rm -f /tmp/haskell-driver /tmp/Greeter.o' >/dev/null 2>&1 || true

echo "$out"

if echo "$out" | grep -q 'test ok: Haskell .o loaded' \
&& echo "$out" | grep -q 'lookupSymbol(_Greeter_haskellAnswer_entry)' \
&& echo "$out" | grep -q 'lookupSymbol(_Greeter_haskellGreet_entry)' \
&& echo "$out" | grep -q 'rc=0'; then
    echo "PASS: macho-loader handles real Haskell .o."
    exit 0
else
    echo "FAIL: Haskell .o loader test did not pass."
    exit 1
fi
