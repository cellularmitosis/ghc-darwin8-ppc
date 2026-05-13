#!/bin/bash
# Session 32: env-var perturbation trial.
#
# Runs ghc-real -c Big2.hs +RTS -A1m -G1 -RTS, N times, with an optional
# env-var assignment prefix.  Classifies each iteration as:
#   PASS           — no output, rc=0
#   FAIL_REFINE    — refineFromInScope (simplifier-time)
#   FAIL_SCOPE     — "not in scope during type checking" (TC-time)
#   FAIL_OTHER     — anything else nonzero
#
# Usage: ./env-trial.sh HOST N [ENV1=VAL ...]
#   HOST    pmacg5 (default)
#   N       iterations (default 5)
#   ENVN    optional additional env vars to set on the child (whitespace-
#           separated, will be passed to ssh as prefix).
set -uo pipefail

HOST="${1:-pmacg5}"
N="${2:-5}"
shift 2 || true
EXTRA_ENV="$*"

# Generate sequence portably (Tiger has no seq).
build_seq () {
    local n="$1" s="" i=1
    while [ "$i" -le "$n" ]; do s="$s $i"; i=$((i+1)); done
    echo "$s"
}
SEQ="$(build_seq "$N")"

# Run on the remote.  Use awk (Tiger has it) instead of head -c.
ssh -q "$HOST" "
ENV_PREFIX='$EXTRA_ENV'
ENV_LEN=\${#ENV_PREFIX}
echo \"env_prefix='\$ENV_PREFIX' env_len=\$ENV_LEN\"
pass=0
fail_refine=0
fail_scope=0
fail_stgcmm=0
fail_other=0
for i in $SEQ; do
    cd /tmp && rm -f Big2.hi Big2.o
    out=\$(env \$ENV_PREFIX DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1)
    rc=\$?
    if [ \"\$rc\" -eq 0 ]; then
        kind=PASS
        pass=\$((pass+1))
    elif echo \"\$out\" | grep -q refineFromInScope; then
        kind=FAIL_REFINE
        fail_refine=\$((fail_refine+1))
    elif echo \"\$out\" | grep -q 'not in scope during'; then
        kind=FAIL_SCOPE
        fail_scope=\$((fail_scope+1))
    elif echo \"\$out\" | grep -q 'StgToCmm.Env: variable not found'; then
        kind=FAIL_STGCMM
        fail_stgcmm=\$((fail_stgcmm+1))
    else
        kind=FAIL_OTHER
        fail_other=\$((fail_other+1))
    fi
    echo \"i=\$i rc=\$rc \$kind\"
done
echo \"SUMMARY pass=\$pass refine=\$fail_refine scope=\$fail_scope stgcmm=\$fail_stgcmm other=\$fail_other of $N\"
"
