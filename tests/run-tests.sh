#!/bin/bash
# Run all tests through the cross-ghc and execute on pmacg5 Tiger.
# Expected outputs are in tests/expected/ (generated from host ghc).
# Actual outputs go in tests/actual/.  Diffs printed at the end.

set -u
cd "$(dirname "$0")"
source ../scripts/cross-env.sh > /dev/null 2>&1

STAGE1=../external/ghc-modern/ghc-9.2.8/_build/stage1/bin/powerpc-apple-darwin8-ghc
HOST_GHC=${HOST_GHC:-$HOME/.local/ghc-9.2.8/bin/ghc}

mkdir -p expected actual bin

declare -a PASS FAIL_COMPILE FAIL_RUN FAIL_OUTPUT

generate_expected() {
  # Generate expected output by compiling+running on host GHC
  local prog=$1
  local stem=$(basename "$prog" .hs)
  local host_bin="bin/${stem}-host"
  rm -f "$host_bin"
  if ! $HOST_GHC -v0 "$prog" -o "$host_bin" 2>&1 | head -20 > "/tmp/${stem}.host-compile.log"; then
    echo "HOST-COMPILE-FAIL $stem"
    return 1
  fi
  if [ ! -x "$host_bin" ]; then
    echo "HOST-NO-BIN $stem"
    return 1
  fi
  "$host_bin" > "expected/${stem}.out" 2> "/tmp/${stem}.host-run.err" || {
    echo "HOST-RUN-FAIL $stem (exit=$?)"
    return 1
  }
  return 0
}

cross_build_and_run() {
  local prog=$1
  local stem=$(basename "$prog" .hs)
  local ppc_bin="bin/${stem}-ppc"
  rm -f "$ppc_bin"
  if ! $STAGE1 -v0 "$prog" -o "$ppc_bin" 2>&1 | head -20 > "/tmp/${stem}.cross-compile.log"; then
    FAIL_COMPILE+=("$stem")
    return 1
  fi
  if [ ! -x "$ppc_bin" ]; then
    FAIL_COMPILE+=("$stem")
    return 1
  fi
  # Ship to pmacg5 and run
  scp -q "$ppc_bin" pmacg5:/tmp/ghc-test-bin 2>/dev/null
  if ! ssh -q pmacg5 "/tmp/ghc-test-bin" > "actual/${stem}.out" 2> "/tmp/${stem}.tiger-run.err"; then
    FAIL_RUN+=("$stem")
    return 1
  fi
  # Compare outputs
  if diff -q "expected/${stem}.out" "actual/${stem}.out" > /dev/null 2>&1; then
    PASS+=("$stem")
  else
    FAIL_OUTPUT+=("$stem")
  fi
}

# Collect all tests
PROGS=$(ls programs/*.hs | sort)

# Phase 1: generate expected (on host)
echo "=== Phase 1: Generate expected outputs (host ghc) ==="
for p in $PROGS; do
  stem=$(basename "$p" .hs)
  printf "  %-40s " "$stem"
  if generate_expected "$p"; then
    echo "ok"
  else
    # don't fail overall; mark stem as unavailable
    : > "expected/${stem}.out"
    echo "SKIPPED (host compile failed)"
  fi
done

# Phase 2: cross-build and run on Tiger
echo ""
echo "=== Phase 2: Cross-build + Tiger run ==="
for p in $PROGS; do
  stem=$(basename "$p" .hs)
  printf "  %-40s " "$stem"
  cross_build_and_run "$p" && echo "PASS" || echo "FAIL"
done

echo ""
echo "=== Summary ==="
echo "PASS:         ${#PASS[@]} - ${PASS[*]}"
echo "FAIL_COMPILE: ${#FAIL_COMPILE[@]} - ${FAIL_COMPILE[*]}"
echo "FAIL_RUN:     ${#FAIL_RUN[@]} - ${FAIL_RUN[*]}"
echo "FAIL_OUTPUT:  ${#FAIL_OUTPUT[@]} - ${FAIL_OUTPUT[*]}"

echo ""
echo "=== Output diffs (FAIL_OUTPUT) ==="
for stem in "${FAIL_OUTPUT[@]}"; do
  echo "--- $stem ---"
  diff "expected/${stem}.out" "actual/${stem}.out" | head -30
  echo ""
done
