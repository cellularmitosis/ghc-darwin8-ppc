#!/bin/bash
# sweep-panic-shape.sh
#
# Like sweep.sh but doesn't require probe37 to be applied.  At each
# env-len, classifies the panic shape and (where applicable) extracts
# the InScope set contents and the missing var.
#
# Usage: sweep-panic-shape.sh <HOST> <START> <END> <STEP>
# Output: one line per panicking length:
#
#   len=NNN  shape=<refine|depSort|swap-tc|other>  missing=<var>  inscope=<{...}>

set -u
HOST=${1:-pmacg5}
START=${2:-600}
END=${3:-2000}
STEP=${4:-50}

for n in $(seq $START $STEP $END); do
    pad=$(awk "BEGIN{for(i=1;i<=$((n-2));i++) printf \"A\"}")
    out=$(ssh -q "$HOST" "cd /tmp && rm -f Big2.hi Big2.o; \
        env A=${pad} DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
        /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1")

    shape="ok"
    missing=""
    inscope=""

    if echo "$out" | grep -q "refineFromInScope"; then
        shape="refine"
        missing=$(echo "$out" | awk '/InScope \{/{found=1; next} found && /^  / && !/^  Call/ {gsub(/^[[:space:]]+/, ""); print; exit}')
        inscope=$(echo "$out" | grep -oE "InScope \{[^}]*\}" | head -1)
    elif echo "$out" | grep -q "depSortStgBinds"; then
        shape="depSort"
    elif echo "$out" | grep -q "swap' is not in scope"; then
        shape="swap-tc"
    elif echo "$out" | grep -q "impossible"; then
        shape="other-rts"
    fi

    if [ "$shape" != "ok" ]; then
        printf 'len=%-5s shape=%-10s missing=%-20s inscope=%s\n' "$n" "$shape" "${missing:-?}" "${inscope:-?}"
    fi
done
