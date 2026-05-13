#!/bin/bash
# Big2.hs +RTS -A1m -RTS (default -G2) under PROBE28 — verify whether
# the TC-time "swap not in scope" signature from session 27 still fires
# when the probe is enabled, or whether it collapses to the STG-time
# refineFromInScope signature seen under -G1.
set -uo pipefail
PPC_HOST="${1:-pmacg5}"
N_ITERS="${2:-10}"
REPO_ROOT="$(cd "$(dirname "$0")/../../../../" && pwd)"
LOGDIR="$REPO_ROOT/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/logs"
mkdir -p "$LOGDIR"
GHC_REAL="/opt/ghc-stage2/bin/ghc-real"
DYLD="DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib"

for i in $(seq 1 "$N_ITERS"); do
    log="$LOGDIR/Big2-a1m-G2.iter${i}.log"
    ssh -q "$PPC_HOST" "
        cd /tmp
        rm -f Big2.hi Big2.o
        $DYLD $GHC_REAL -c Big2.hs +RTS -A1m -RTS 2>&1
        echo \"GHC_EXIT=\$?\"
    " > "$log" 2>&1
    rc=$(grep -m1 '^GHC_EXIT=' "$log" | sed 's/GHC_EXIT=//' || echo '?')
    sig=$(grep -m1 -E '(panic|internal error|refineFromInScope|depSortStgBinds|variable not found|not in scope)' "$log" | head -c 120)
    [ "$rc" = "0" ] && sig="OK"
    [ -z "$sig" ] && sig="UNKNOWN_FAIL_rc=$rc"
    gcs=$(grep -c '^PROBE28 ' "$log" 2>/dev/null || echo 0)
    printf '  iter%02d rc=%s gcs=%s : %s\n' "$i" "$rc" "$gcs" "$sig"
done
