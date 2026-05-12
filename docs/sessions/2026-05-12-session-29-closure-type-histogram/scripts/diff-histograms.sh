#!/bin/bash
# Compute per-closure-type differential between a PASS GC and a FAIL GC.
# Usage:  ./diff-histograms.sh PASS_LOG PASS_GC FAIL_LOG FAIL_GC
set -euo pipefail

PASS_LOG="$1"
PASS_GC="$2"
FAIL_LOG="$3"
FAIL_GC="$4"

REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
CTH="$REPO_ROOT/external/ghc-modern/ghc-9.2.8/includes/rts/storage/ClosureTypes.h"

# Map t<n> → name.
typename () {
    local n="$1"
    awk -v n="$n" '
      /^#define +[A-Z_0-9]+ +[0-9]+$/ {
        if ($3 == n) { print $2; exit }
      }' "$CTH"
}

parse_line () {
    local log="$1" gc="$2" prefix="$3"
    grep "^PROBE29 gc=${gc} ${prefix}" "$log" | head -1 |
        tr ' ' '\n' | grep -oE "^[te][0-9]+=[0-9]+$" || true
}

echo "PASS log : $PASS_LOG (gc=$PASS_GC)"
echo "FAIL log : $FAIL_LOG (gc=$FAIL_GC)"
echo
echo "scavenge_block dispatch (per closure scavenged):"
printf "  %-30s %10s %10s %10s\n" "TYPE" "PASS" "FAIL" "FAIL/PASS"

pass_scav=$(parse_line "$PASS_LOG" "$PASS_GC" "scav")
fail_scav=$(parse_line "$FAIL_LOG" "$FAIL_GC" "scav")

# union of indices
indices=$(printf '%s\n%s\n' "$pass_scav" "$fail_scav" | sed 's/^t//' | cut -d= -f1 | sort -un)

for t in $indices; do
    p=$(echo "$pass_scav" | grep "^t${t}=" | cut -d= -f2 || true); p=${p:-0}
    f=$(echo "$fail_scav" | grep "^t${t}=" | cut -d= -f2 || true); f=${f:-0}
    ratio=$(awk -v p="$p" -v f="$f" 'BEGIN{ if(p+0==0){print(f+0==0?"-":"NEW")} else {printf "%.2fx", f/p} }')
    name=$(typename "$t")
    printf "  %-30s %10d %10d %10s\n" "$name($t)" "$p" "$f" "$ratio"
done

echo
echo "evacuate() dispatch (per closure freshly evacuated):"
printf "  %-30s %10s %10s %10s\n" "TYPE" "PASS" "FAIL" "FAIL/PASS"

pass_evac=$(parse_line "$PASS_LOG" "$PASS_GC" "evac")
fail_evac=$(parse_line "$FAIL_LOG" "$FAIL_GC" "evac")

indices=$(printf '%s\n%s\n' "$pass_evac" "$fail_evac" | sed 's/^e//' | cut -d= -f1 | sort -un)

for t in $indices; do
    p=$(echo "$pass_evac" | grep "^e${t}=" | cut -d= -f2 || true); p=${p:-0}
    f=$(echo "$fail_evac" | grep "^e${t}=" | cut -d= -f2 || true); f=${f:-0}
    ratio=$(awk -v p="$p" -v f="$f" 'BEGIN{ if(p+0==0){print(f+0==0?"-":"NEW")} else {printf "%.2fx", f/p} }')
    name=$(typename "$t")
    printf "  %-30s %10d %10d %10s\n" "$name($t)" "$p" "$f" "$ratio"
done
