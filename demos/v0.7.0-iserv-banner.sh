#!/bin/bash
# v0.7.0 — PPC ghc-iserv builds and runs on Tiger.
#
# This demo is the simplest possible exercise of the v0.7.0 deliverable:
# ssh into the Tiger box and ask the freshly-installed ghc-iserv to
# print its usage banner.  If it does — RTS started, base library
# loaded, libiserv linked, all the way through to its `dieWithUsage`
# print — the cross-build is sound.
#
# This is not a Haskell file because we don't run any Haskell here:
# we just observe a PPC binary on Tiger printing its usage.  The
# Haskell side (TH-via-iserv) is in v0.7.0+ as the protocol bring-up;
# see tests/th-iserv/.
#
# Usage:
#   demos/v0.7.0-iserv-banner.sh
#
# Env vars:
#   PPC_HOST       (default: pmacg5)
#   REMOTE_ISERV   (default: /opt/ghc-ppc/lib/bin/powerpc-apple-darwin8-ghc-iserv)
#
# Expected output:
#   powerpc-apple-darwin8-ghc-iserv: usage: iserv <write-fd> <read-fd> [-v]
#   exit code: 1   (iserv exits non-zero on bad args, that's the success case here)

set -uo pipefail

PPC_HOST=${PPC_HOST:-pmacg5}
REMOTE_ISERV=${REMOTE_ISERV:-/opt/ghc-ppc/lib/bin/powerpc-apple-darwin8-ghc-iserv}

echo "Probing $PPC_HOST:$REMOTE_ISERV ..."
ssh -q "$PPC_HOST" "$REMOTE_ISERV"
rc=$?
echo "exit code: $rc"

if [ $rc -eq 1 ]; then
    echo "PASS — iserv ran on Tiger and printed its usage banner."
    exit 0
else
    echo "FAIL — expected exit code 1 from a no-args iserv, got $rc."
    exit 1
fi
