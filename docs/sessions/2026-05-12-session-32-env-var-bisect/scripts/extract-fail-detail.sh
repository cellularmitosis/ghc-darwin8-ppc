#!/bin/bash
# For one env-var length, run once, dump the failure's specific Var name.
# Usage: ./extract-fail-detail.sh HOST LEN
set -uo pipefail

HOST="${1:-pmacg5}"
LEN="${2:-2}"
pad=$(awk "BEGIN{for(i=1;i<=$((LEN-2));i++) printf \"A\"}")
e="A=${pad}"

ssh -q "$HOST" "
cd /tmp && rm -f Big2.hi Big2.o
out=\$(env $e DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1)
rc=\$?
if [ \"\$rc\" -eq 0 ]; then
    echo 'PASS rc=0'
else
    # Extract the offending var name from each surface
    if echo \"\$out\" | grep -q refineFromInScope; then
        # The missing Var is on the first line after the InScope dump (closing brace),
        # before the Call stack section.
        missing=\$(echo \"\$out\" | awk '/^[[:space:]]*}/{after_inscope=1; next} /Call stack/{exit} after_inscope && NF>0 {print; exit}' | tr -d ' ')
        if [ -z \"\$missing\" ]; then
            # InScope may close inline; the missing Var follows
            missing=\$(echo \"\$out\" | awk '/refineFromInScope/{flag=1; next} flag && /}/{found_close=1; next} found_close && NF>0 {print; exit}' | tr -d ' ')
        fi
        echo \"REFINE rc=\$rc missing=\$missing\"
    elif echo \"\$out\" | grep -q 'not in scope during'; then
        var=\$(echo \"\$out\" | grep -oE \"\\\`[a-zA-Z_][a-zA-Z0-9_']*' is not in scope\" | head -1)
        echo \"SCOPE rc=\$rc var=\$var\"
    elif echo \"\$out\" | grep -q 'StgToCmm.Env: variable not found'; then
        missing=\$(echo \"\$out\" | awk '/StgToCmm.Env: variable not found/{flag=1; next} flag && NF>0 {print; exit}' | tr -d ' ')
        echo \"STGCMM rc=\$rc missing=\$missing\"
    else
        echo \"OTHER rc=\$rc msg=\$(echo \"\$out\" | head -1 | cut -c1-80)\"
    fi
fi
"
