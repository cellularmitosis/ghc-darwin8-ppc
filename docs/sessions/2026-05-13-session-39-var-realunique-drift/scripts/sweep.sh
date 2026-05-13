#!/bin/bash
# Sweep env-len START..END step STEP, capture probe39 PANIC/ADDLOST/SHRINK
# diagnostics emitted by the instrumented refineFromInScope &
# addNewInScopeIds & setInScopeFrom{E,F,Set} on each Big2.hs panic.
#
# Requires: probe39-applied stage2 already deployed to pmacg5.
# Trigger: /tmp/Big2.hs (carried over from session 35).
# Output: per-length lines for every length that emitted any probe line.

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

    panic=$(echo "$out" | grep "^PROBE39-PANIC" | head -1)
    addlost_n=$(echo "$out" | grep -c "^PROBE39-ADDLOST")
    shrink_n=$(echo "$out" | grep -c "^PROBE39-SHRINK")
    panic_kind=$(echo "$out" | grep -E "^(ghc-real: panic|depSortStgBinds|swap|refineFromInScope)" | head -1)

    if [ -n "$panic" ] || [ "$addlost_n" -gt 0 ] || [ "$shrink_n" -gt 0 ]; then
        printf 'len=%-5s addlost=%-3s shrink=%-3s panic=%s\n' \
            "$n" "$addlost_n" "$shrink_n" "${panic_kind:-?}"
        [ -n "$panic" ] && printf '  %s\n' "$panic"
    fi
done
