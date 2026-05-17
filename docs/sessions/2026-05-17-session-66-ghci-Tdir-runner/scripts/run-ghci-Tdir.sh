#!/bin/bash
# Run the T-prefix bug-numbered per-directory subset of upstream's
# GHCi testsuite (tests/ghci/T<num>/) against the deployed stage2 ghc
# on a PPC Tiger host.
#
# Why this exists: sessions 56 / 57 / 58 / 60 / 62 / 63 / 64 wired the
# tests/ghci/scripts/all.T T-prefix subset (175/177 PASS at v0.15.0);
# session 65 added tests/ghci/prog001..prog019 (17/17 PASS).  This
# runner picks up HANDOFF priority #1 from session 65: the per-test-
# directory bug-numbered T-tests under tests/ghci/.  Same per-test-dir
# shape as session 65's runner, simplified — none of these tests need
# `../shell.hs`, none invoke `:shell "$HC" ...`, no `.hs-boot` other
# than T11827's, no Level2/ subdirectories.
#
# In-scope (8 ghci_script tests):
#   T11827   — `ghci_script` + `expect_broken(11827)`.  Upstream marks
#              the test as a known failure: with `-v0`, the
#              "Not in scope: data constructor 'C'" message from A.hs
#              is suppressed and the .stderr expected file goes
#              un-matched.  We honour that — flip pass/fail for this
#              test, so a mismatch is the expected outcome.
#   T16392   — `ghci_script` + `req_interp`.  Stresses object-code
#              loading + `performMajorGC` interaction with CAF
#              reachability.  Upstream also runs in `ghci-ext` way
#              when have_RTS_linker; we run normal way only.
#   T16525a  — `ghci_script`.  `:set -fobject-code` + thread-based
#              unloading via `:l []`.  Stresses runtime linker / GC.
#   T16525b  — `ghci_script`.  Same shape as T16525a but unloads
#              while a thread is actively calling into the object.
#   T16793   — `ghci_script` + `normal`.  Simple `:instances Int`.
#   T18060   — `ghci_script` + `normal`.  `:i ->`, `:i ~`.
#   T18071   — `ghci_script`.  `:instances T/U/U2` with
#              QuantifiedConstraints.
#   T18262   — `ghci_script`.  TypeLits + DataKinds + `:instances 'B`.
#
# Skipped (3 tests in 2 dirs):
#   T13786          — `makefile_test`, not `ghci_script`.
#   T16670_unboxed  — `makefile_test`.
#   T16670_th       — `makefile_test`.
#
# Usage:
#   ./run-ghci-Tdir.sh                 # runs against pmacg5
#   ./run-ghci-Tdir.sh imacg4          # explicit host
#
# Output: per-test PASS/FAIL line on stdout; full actual outputs
# captured under $LOGDIR/<test>/actual.{stdout,stderr}.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
GHC_SRC="${GHC_SRC:-/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8}"
GHCI_DIR="$GHC_SRC/testsuite/tests/ghci"
SESSION_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$SESSION_DIR/logs/ghci-Tdir"
REMOTE_BASE="/tmp/ghci-Tdir-$$"

# Test list.  Format: "dir expect_broken"
#   dir            = per-test subdir name under tests/ghci/
#                    (same as test name for this subset; the test name
#                    used for the .script / .stdout / .stderr
#                    basenames is identical)
#   expect_broken  = 1 if the test annotates `expect_broken(NNN)` —
#                    inverts the pass/fail decision so a mismatch
#                    becomes the expected outcome.
TESTS=(
  "T11827 1"
  "T16392 0"
  "T16525a 0"
  "T16525b 0"
  "T16793 0"
  "T18060 0"
  "T18071 0"
  "T18262 0"
)

DYLD_ENV='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real
# Interactive flags.  Identical to session 65's run-ghci-progNNN.sh.
HC_FLAGS="--interactive -v0 -ignore-dot-ghci -fno-ghci-history \
-fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never"

mkdir -p "$LOGDIR"
rm -rf "$LOGDIR"/* 2>/dev/null

# Stage all test dirs (recursively) into a single staging tree, scp once.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

for entry in "${TESTS[@]}"; do
  read -r dir expect_broken <<< "$entry"
  # Recursive copy catches .hs-boot files automatically.
  cp -R "$GHCI_DIR/$dir" "$STAGE/$dir"
done

# Ship tarball + run script.
ssh -e none "$PPC_HOST" "mkdir -p $REMOTE_BASE"
(cd "$STAGE" && tar cf - .) | ssh -e none "$PPC_HOST" "cd $REMOTE_BASE && tar xf -"

# Build a remote runner.  For each test:
#  - cd into its dir
#  - run ghc --interactive < script   capturing stdout/stderr separately
#  - print one TEST-LINE per test with status
remote_script=$(cat <<EOF
set -u
cd "$REMOTE_BASE"
export $DYLD_ENV
export LANG=en_US.UTF-8
EOF
)

for entry in "${TESTS[@]}"; do
  read -r dir expect_broken <<< "$entry"
  remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$dir'
  $GHC $HC_FLAGS < '$dir.script' > actual.stdout 2> actual.stderr
  rc=\$?
  echo \"TEST $dir rc=\$rc\"
)"
done

ssh -e none "$PPC_HOST" "$remote_script" > "$LOGDIR/remote-run.log" 2>&1

# Fetch all artifacts back.
ssh -e none "$PPC_HOST" "cd $REMOTE_BASE && tar cf - ." | (cd "$LOGDIR" && tar xf -)

# Cleanup remote.
ssh -e none "$PPC_HOST" "rm -rf $REMOTE_BASE"

NORMALISE="$SESSION_DIR/scripts/normalise.py"

norm() {
  local f=$1; shift
  [ -f "$f" ] || return 0
  python3 "$NORMALISE" "$@" < "$f" > "$f.norm"
  mv "$f.norm" "$f"
}

# Diff each test and emit summary.
echo
echo "=== GHCi T-dir subset results (host=$PPC_HOST, ghc=$GHC) ==="
pass=0; fail=0
declare -a FAILED
for entry in "${TESTS[@]}"; do
  read -r dir expect_broken <<< "$entry"
  tdir="$LOGDIR/$dir"
  fail_reasons=()

  rc=$(grep "^TEST $dir rc=" "$LOGDIR/remote-run.log" | tail -1 | sed 's/.*rc=//')
  # Detect lethal signals.  128+N convention: 134=SIGABRT, 137=SIGKILL,
  # 138=SIGBUS, 139=SIGSEGV.  127 = command-not-found.
  if [ "$rc" = 127 ] || [ "$rc" = 134 ] || [ "$rc" = 137 ] || [ "$rc" = 138 ] || [ "$rc" = 139 ]; then
    fail_reasons+=("ghc rc=$rc (lethal signal)")
  fi

  norm "$tdir/$dir.stdout"
  norm "$tdir/$dir.stderr"
  norm "$tdir/actual.stdout"
  norm "$tdir/actual.stderr"
  if [ -f "$tdir/$dir.stdout" ]; then
    if ! diff -qw "$tdir/$dir.stdout" "$tdir/actual.stdout" > /dev/null 2>&1; then
      fail_reasons+=("stdout mismatch")
    fi
  else
    [ -s "$tdir/actual.stdout" ] && fail_reasons+=("stdout non-empty but no expected.stdout")
  fi
  if [ -f "$tdir/$dir.stderr" ]; then
    if ! diff -qw "$tdir/$dir.stderr" "$tdir/actual.stderr" > /dev/null 2>&1; then
      fail_reasons+=("stderr mismatch")
    fi
  else
    [ -s "$tdir/actual.stderr" ] && fail_reasons+=("stderr non-empty but no expected.stderr")
  fi

  # expect_broken inversion: a mismatch is the expected outcome.
  if [ "$expect_broken" = 1 ]; then
    if [ ${#fail_reasons[@]} -gt 0 ]; then
      pass=$((pass+1))
      printf "  PASS  %-14s  (rc=%s)  expected-broken: %s\n" "$dir" "$rc" "$(IFS='; '; echo "${fail_reasons[*]}")"
    else
      fail=$((fail+1))
      FAILED+=("$dir")
      printf "  FAIL  %-14s  (rc=%s)  UNEXPECTED PASS — upstream marks expect_broken\n" "$dir" "$rc"
    fi
    continue
  fi

  if [ ${#fail_reasons[@]} -eq 0 ]; then
    pass=$((pass+1))
    printf "  PASS  %-14s  (rc=%s)\n" "$dir" "$rc"
  else
    fail=$((fail+1))
    FAILED+=("$dir")
    printf "  FAIL  %-14s  (rc=%s)  %s\n" "$dir" "$rc" "$(IFS='; '; echo "${fail_reasons[*]}")"
  fi
done

echo
echo "=== Summary: $pass PASS / $fail FAIL out of ${#TESTS[@]} tests ==="
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed: ${FAILED[*]}"
  echo "Diffs in $LOGDIR/<dir>/{actual,<name>}.* "
fi
