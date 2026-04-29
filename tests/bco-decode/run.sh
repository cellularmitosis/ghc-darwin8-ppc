#!/bin/bash
# tests/bco-decode/run.sh — regression test for the cross-built `binary`
# library's Generic-derived sum encoding (patch 0013) and CreateBCO's
# endianness byte-swap (patch 0014).
#
# Compiles three target programs that exercise:
#   1. MyEnumTest:    a hand-rolled 5-constructor sum (mirrors ResolvedBCOPtr's
#                     shape).  Roundtrips encode + decode + cross-check
#                     against a fixed input.  Must produce 9-byte output
#                     (Word8 tag), NOT 16-byte (Word64 tag).
#   2. MinimalTest:   directly decode a single ResolvedBCOPtr from a hand-
#                     crafted byte stream.  Must succeed.
#   3. DecodeBCO:     decode the captured `bco-blob.bin` (a real BCO from a
#                     TH splice).  Must succeed and report 1 ResolvedBCO.
#
# All three previously failed with "Unknown encoding for constructor" on
# target due to the binary library's Generic-derived sum picking Word64
# tag (host picks Word8).  Patch 0013 forces direct numeric comparisons
# in `Generic.hs`'s gput/gget so both sides agree on Word8.
#
# Env vars:
#   PPC_HOST  — ssh alias of the Tiger box (default: pmacg5)
#   STAGE1    — path to the cross-ghc binary

set -euo pipefail

PPC_HOST=${PPC_HOST:-pmacg5}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/../../scripts/cross-env.sh" >/dev/null 2>&1 || true
STAGE1=${STAGE1:-$SCRIPT_DIR/../../external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc}

cd "$SCRIPT_DIR"
rm -f *.hi *.o myenum-test minimal-test decode-bco

echo "[1/3] compiling MyEnumTest..."
"$STAGE1" -package binary MyEnumTest.hs -o myenum-test 2>/dev/null
echo "[2/3] compiling MinimalTest..."
"$STAGE1" -package ghci -package ghc-boot -package binary MinimalTest.hs -o minimal-test 2>/dev/null
echo "[3/3] compiling DecodeBCO..."
"$STAGE1" -package ghci -package ghc-boot -package binary DecodeBCO.hs -o decode-bco 2>/dev/null

echo "--- shipping to $PPC_HOST ---"
scp -q myenum-test minimal-test decode-bco bco-blob.bin "$PPC_HOST":/tmp/

PASS=true

myenum_out=$(ssh -e none -T -q "$PPC_HOST" 'cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib ./myenum-test' 2>&1)
echo "$myenum_out"
if echo "$myenum_out" | grep -q 'size=9'; then
    echo "  PASS: MyEnum encodes with Word8 tag (9 bytes)"
else
    echo "  FAIL: MyEnum used wrong tag size"; PASS=false
fi

min_out=$(ssh -e none -T -q "$PPC_HOST" 'cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib ./minimal-test' 2>&1)
echo "$min_out"
if echo "$min_out" | grep -q 'ResolvedBCOStaticPtr (RemotePtr 95110952)'; then
    echo "  PASS: MinimalTest decoded ResolvedBCOPtr"
else
    echo "  FAIL: MinimalTest"; PASS=false
fi

dec_out=$(ssh -e none -T -q "$PPC_HOST" 'cd /tmp && DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib ./decode-bco' 2>&1)
echo "$dec_out"
if echo "$dec_out" | grep -q 'decoded 1 ResolvedBCOs'; then
    echo "  PASS: DecodeBCO decoded the full BCO blob"
else
    echo "  FAIL: DecodeBCO"; PASS=false
fi

ssh -e none -T -q "$PPC_HOST" 'rm -f /tmp/myenum-test /tmp/minimal-test /tmp/decode-bco /tmp/bco-blob.bin' >/dev/null 2>&1 || true

if $PASS; then
    echo "PASS: bco-decode regression suite green."
    exit 0
else
    echo "FAIL: bco-decode regression suite has failures."
    exit 1
fi
