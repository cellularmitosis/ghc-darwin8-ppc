#!/bin/bash
# sweep-full.sh — like sweep.sh but captures the full per-length
# output (PROBE38-* lines and panic body) into logs/sweep-full/.
#
# Usage: sweep-full.sh HOST START END STEP OUTDIR
# Default: sweep-full.sh pmacg5 600 2000 50 logs/sweep-full

set -u
HOST=${1:-pmacg5}
START=${2:-600}
END=${3:-2000}
STEP=${4:-50}
OUTDIR=${5:-logs/sweep-full}

mkdir -p "$OUTDIR"

mk_padding() {
    local n=$1
    awk "BEGIN{for(i=1;i<=$n;i++) printf \"A\"}"
}

for n in $(seq $START $STEP $END); do
    pad=$(mk_padding $((n-2)))
    e="A=${pad}"
    out=$(ssh -q "$HOST" "cd /tmp && rm -f Big2.hi Big2.o; \
        env $e DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
        /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; \
        echo RC=\$?")
    f="$OUTDIR/len-$(printf '%04d' $n).log"
    echo "$out" > "$f"
    # Quick summary line:
    panic=$(echo "$out" | grep "^PROBE38-PANIC" | head -1 | cut -c1-200)
    addlost=$(echo "$out" | grep -c "^PROBE38-ADDLOST")
    shrink=$(echo "$out" | grep -c "^PROBE38-SHRINK")
    rc=$(echo "$out" | grep "^RC=" | head -1)
    printf 'len=%-5s addlost=%-3s shrink=%-3s rc=%-5s panic=%s\n' \
        "$n" "$addlost" "$shrink" "${rc:-?}" "${panic:-?}"
done
