#!/bin/sh
# Compile + run every test program with $GHC (default `ghc`).
# Tally pass/fail. Exit nonzero on any failure.
set -u

GHC="${GHC:-ghc}"
GHCFLAGS="${GHCFLAGS:--O0}"
PASS=0
FAIL=0
FAILED=""
TMPDIR="${TMPDIR:-/tmp}/ghc-testprogs-$$"
mkdir -p "$TMPDIR"
trap 'rm -rf "$TMPDIR"' EXIT

cd "$(dirname "$0")"
echo "GHC=$($GHC --version 2>/dev/null || echo 'NOT FOUND')"
echo "GHCFLAGS=$GHCFLAGS"
echo "TMPDIR=$TMPDIR"
echo

for hs in [0-9][0-9]-*.hs; do
  name="${hs%.hs}"
  out="$TMPDIR/$name"

  printf "%-25s " "$name"

  if ! "$GHC" $GHCFLAGS -outputdir "$TMPDIR/build-$name" \
        -o "$out" "$hs" >"$TMPDIR/$name.compile.log" 2>&1
  then
    echo "COMPILE FAIL"
    FAIL=$((FAIL+1))
    FAILED="$FAILED $name(compile)"
    continue
  fi

  if ! "$out" >"$TMPDIR/$name.run.log" 2>&1
  then
    echo "RUN FAIL"
    cat "$TMPDIR/$name.run.log" | head -3
    FAIL=$((FAIL+1))
    FAILED="$FAILED $name(run)"
    continue
  fi

  expected="OK $name"
  actual="$(head -1 "$TMPDIR/$name.run.log")"
  if [ "$actual" = "$expected" ] || [ "${actual%% *}" = "OK" ]; then
    echo "OK"
    PASS=$((PASS+1))
  else
    echo "WRONG OUTPUT: $actual"
    FAIL=$((FAIL+1))
    FAILED="$FAILED $name(output)"
  fi
done

echo
echo "passed: $PASS"
echo "failed: $FAIL"
[ -n "$FAILED" ] && echo "failed:$FAILED"

[ $FAIL -eq 0 ]
