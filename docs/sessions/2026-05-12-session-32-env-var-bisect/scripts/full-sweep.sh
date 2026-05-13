#!/bin/bash
# Sweep env-var lengths and classify outcomes.
# Usage: ./full-sweep.sh HOST N_ITERS START STEP END
set -uo pipefail

HOST="${1:-pmacg5}"
N="${2:-5}"
START="${3:-2}"
STEP="${4:-2}"
END="${5:-250}"

n="$START"
while [ "$n" -le "$END" ]; do
    pad=$(awk "BEGIN{for(i=1;i<=$((n-2));i++) printf \"A\"}")
    e="A=${pad}"
    out=$(bash "$(dirname "$0")/env-trial.sh" "$HOST" "$N" "$e" 2>&1 | grep SUMMARY)
    echo "len=${#e}: $out"
    n=$((n + STEP))
done
