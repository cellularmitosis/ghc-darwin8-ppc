#!/bin/bash
# Sweep env-len START..END step STEP, capture probe37
# BEFORE/INDIRECTEE/AFTER/INDIRECTEE-AFTER lines from each
# refineFromInScope panic.
#
# Requires: probe37-applied stage2 already deployed to pmacg5.
# Trigger: /tmp/Big2.hs (carried over from session 35).
# Output: prints per-length lines for each panicking length.

set -u
HOST=${1:-pmacg5}
START=${2:-600}
END=${3:-2000}
STEP=${4:-50}

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

    before=$(echo "$out" | grep "^PROBE37-BEFORE" | head -1)
    indir=$(echo "$out"  | grep "^PROBE37-INDIRECTEE " | head -1)
    after=$(echo "$out"  | grep "^PROBE37-AFTER" | head -1)
    indir2=$(echo "$out" | grep "^PROBE37-INDIRECTEE-AFTER " | head -1)
    missing=$(echo "$out" | awk '/InScope/{found=1; next} found && /^  / && !/^  Call/ {gsub(/^[[:space:]]+/, ""); print; exit}')

    if [ -n "$before" ]; then
        printf 'len=%-5s MISSING=%-30s\n  %s\n  %s\n  %s\n  %s\n' \
            "$n" "${missing:-?}" "$before" "$indir" "$after" "$indir2"
    fi
done
