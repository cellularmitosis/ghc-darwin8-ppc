#!/bin/bash
# pgmi-shim.sh — bridge GHC's local-iserv pipes to a remote ghc-iserv on Tiger.
#
# GHC's `-fexternal-interpreter -pgmi=<this script>` invokes us with
# two file-descriptor numbers as positional args: `<wfd1> <rfd2> [-v]`.
# Those fds are *inherited* from ghc and connected to two pipes:
#   wfd1 — iserv writes here, ghc reads.
#   rfd2 — iserv reads here, ghc wrote.
#
# We can't run iserv locally (cross-target arch).  Instead we spawn it
# on $PPC_HOST through SSH, with our local fds bridged to the SSH
# stdio:
#   ssh stdin  ← rfd2 (so remote iserv sees ghc's writes)
#   ssh stdout → wfd1 (so remote iserv's writes reach ghc)
# The remote iserv is told to use fds 1 and 0 (its own stdout/stdin).
#
# Env vars:
#   PPC_HOST           ssh alias of the Tiger box (default: pmacg5)
#   REMOTE_ISERV       absolute path to ghc-iserv on the target (default:
#                      /opt/ghc-ppc/lib/bin/powerpc-apple-darwin8-ghc-iserv)

set -uo pipefail

PPC_HOST=${PPC_HOST:-pmacg5}
REMOTE_ISERV=${REMOTE_ISERV:-/opt/ghc-ppc/lib/bin/powerpc-apple-darwin8-ghc-iserv}

if [ $# -lt 2 ]; then
    echo "pgmi-shim: expected <wfd1> <rfd2> [iserv args...]; got $*" >&2
    exit 2
fi

WFD=$1
RFD=$2
shift 2
# Remaining args (e.g. -v) are passed through to remote iserv.

# Bridge local fds to remote stdio.
#  - SSH inherits stdin from rfd2, stdout to wfd1.
#  - Remote iserv args are "1 0 [...]" so it talks via stdout/stdin.
#  - DYLD_LIBRARY_PATH ensures iserv can dlopen libgmp.dylib + friends
#    that the cross-bindist links against.
REMOTE_DYLD=${REMOTE_DYLD:-/opt/gmp-6.2.1/lib:/opt/gcc14/lib}
# `-e none` disables SSH's `~`-escape character (which can corrupt binary
# data sent over stdin if the data contains a `~` after a newline).
# `-T` suppresses pseudo-tty allocation so stdio is not line-cooked.
exec ssh -e none -T -q "$PPC_HOST" \
    "DYLD_LIBRARY_PATH=$REMOTE_DYLD $REMOTE_ISERV 1 0 $*" \
    <&"$RFD" >&"$WFD"
