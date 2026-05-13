#!/bin/bash
# identify-symbols.sh
#
# Given a sweep log (with PROBE37-BEFORE/INDIRECTEE/AFTER lines),
# resolve every word[0] address in each capture to a symbol name via nm.
#
# Usage: identify-symbols.sh <sweep-log>
# Requires: pmacg5:/opt/ghc-stage2/bin/ghc-real to be the probe37 binary
#           (i.e. matches when the sweep log was captured).

set -u
HOST=${HOST:-pmacg5}
GHC_REAL=${GHC_REAL:-/opt/ghc-stage2/bin/ghc-real}
SWEEP_LOG=${1:?usage: identify-symbols.sh <sweep-log>}

WORKDIR=$(mktemp -d)
trap "rm -rf $WORKDIR" EXIT

echo "==> rsync nm output from $HOST" >&2
ssh -q "$HOST" "nm -n $GHC_REAL" > "$WORKDIR/nm.txt"
echo "    $(wc -l < "$WORKDIR/nm.txt") symbols" >&2

resolve() {
    # binary search: greatest address <= query
    local q=$1
    awk -v q="$q" '
        /^[0-9a-f]+ / {
            addr = strtonum("0x" $1)
            qn   = strtonum(q)
            if (addr <= qn) { last_addr=$1; last_sym=$3 }
            else { print last_addr " " last_sym " (offset +" qn-strtonum("0x" last_addr) ")"; exit }
        }
    ' "$WORKDIR/nm.txt"
}

# Pull out unique word[0] addresses from PROBE37-* lines
grep -oE 'PROBE37-[A-Z-]+ @0x[0-9a-f]+ \[0x[0-9a-f]+' "$SWEEP_LOG" | \
    awk '{print $3}' | sed 's/\[//' | sort -u | while read w0; do
    sym=$(resolve "$w0")
    printf '%-12s -> %s\n' "$w0" "$sym"
done
