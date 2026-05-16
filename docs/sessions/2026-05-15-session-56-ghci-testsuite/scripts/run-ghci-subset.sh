#!/bin/bash
# Run a curated subset of upstream's GHCi testsuite against the
# deployed stage2 ghc on a PPC Tiger host.
#
# Why this exists: session 55 / v0.14.0 enabled the in-process GHCi
# REPL on PPC/Tiger but only smoke-tested it.  Upstream's full GHCi
# testsuite has hundreds of tests; this script runs ~20 of them
# end-to-end (ssh up, run, diff) without porting the testsuite
# driver.  Picks live in the curated list below; chosen to spread
# across feature areas (basic eval, :info, :load, :{ :}, TH splice
# from REPL, prompts, shadowing, type families, UTF-8 input, etc).
#
# Usage:
#   ./run-ghci-subset.sh                 # runs against pmacg5
#   ./run-ghci-subset.sh imacg4          # explicit host
#
# Output: per-test PASS/FAIL line on stdout; full actual outputs
# captured under $LOGDIR/<test>/actual.{stdout,stderr,combined}.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
GHC_SRC="${GHC_SRC:-/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8}"
SCRIPTS_DIR="$GHC_SRC/testsuite/tests/ghci/scripts"
SESSION_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$SESSION_DIR/logs/ghci-subset"
REMOTE_BASE="/tmp/ghci-subset-$$"

# Test list.  Format: "name combined_output(0|1) extra_files..."
# Picked from upstream all.T: all `normal` / `combined_output` ghciNNN
# script tests.  Skipped: anything with reqlib/req_th/req_interp/
# expect_broken/extra_hc_opts/etc (those need test-driver behaviour
# we don't reproduce).  Also skipped two that pull files from outside
# the scripts/ dir (ghci026 needs ../prog002, ghci038 needs ../shell.hs).
TESTS=(
  "ghci001 1"
  "ghci002 1"
  "ghci003 1"
  "ghci005 1"
  "ghci007 1"
  "ghci008 1"
  "ghci009 1"
  "ghci011 0"
  "ghci012 0"
  "ghci013 0"
  "ghci018 0"
  "ghci019 0"
  "ghci020 0"
  "ghci021 0"
  "ghci022 0"
  "ghci023 0"
  "ghci025 0 Ghci025B.hs Ghci025C.hs Ghci025D.hs"
  "ghci027 0"
  "ghci028 0"
  "ghci029 0"
  "ghci030 0"
  "ghci031 0"
  "ghci032 0"
  "ghci033 0"
  "ghci034 0"
  "ghci035 0"
  "ghci036 0"
  "ghci039 0"
  "ghci040 0"
  "ghci041 0"
  "ghci042 0"
  "ghci043 0"
  "ghci044 0"
  "ghci044a 0"
  "ghci045 0"
  "ghci046 0"
  "ghci047 0"
  "ghci048 0"
  "ghci049 0"
  "ghci050 0"
  "ghci051 0"
  "ghci052 0"
  "ghci053 0"
  "ghci054 0"
  "ghci055 1"
  "ghci059 0"
  "ghci060 0"
  "ghci061 0"
  "ghci063 0"
  "ghci064 0"
  "ghci066 0"
)

DYLD_ENV='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real
# Flags chosen to match upstream's testsuite/mk/test.mk (TEST_HC_OPTS +
# TEST_HC_OPTS_INTERACTIVE) plus testsuite/config/ghc.  Without
# -fshow-warning-groups / -fno-diagnostics-show-caret the warning
# format differs from the expected files.
HC_FLAGS="--interactive -v0 -ignore-dot-ghci -fno-ghci-history \
-fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never"

mkdir -p "$LOGDIR"
rm -rf "$LOGDIR"/* 2>/dev/null

# Stage all test files into a single tarball, scp once.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

for entry in "${TESTS[@]}"; do
  read -r name combined extras <<< "$entry"
  dest="$STAGE/$name"
  mkdir -p "$dest"
  cp "$SCRIPTS_DIR/$name.script" "$dest/"
  [ -f "$SCRIPTS_DIR/$name.stdout" ] && cp "$SCRIPTS_DIR/$name.stdout" "$dest/expected.stdout"
  [ -f "$SCRIPTS_DIR/$name.stderr" ] && cp "$SCRIPTS_DIR/$name.stderr" "$dest/expected.stderr"
  # Auto-include any other companion files matching $name.* or $name_*.*
  # (e.g. ghci023.ghci, ghci027_1.hs, ghci027_2.hs) -- upstream's driver
  # picks these up via testname-pattern even when all.T doesn't declare
  # extra_files.
  for f in "$SCRIPTS_DIR/$name."* "$SCRIPTS_DIR/${name}_"*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.script|*.stdout|*.stderr) ;;
      *) cp "$f" "$dest/" ;;
    esac
  done
  if [ -n "${extras:-}" ]; then
    for x in $extras; do
      cp "$SCRIPTS_DIR/$x" "$dest/"
    done
  fi
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
  read -r name combined extras <<< "$entry"
  if [ "$combined" = "1" ]; then
    # combined_output: must merge at runtime (kernel-level 2>&1) so
    # interleaving matches what upstream's test driver sees -- a
    # post-hoc 'cat stdout stderr' loses ordering.
    remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$name'
  $GHC $HC_FLAGS < '$name.script' > actual.combined 2>&1
  rc=\$?
  echo \"TEST $name rc=\$rc\"
)"
  else
    remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$name'
  $GHC $HC_FLAGS < '$name.script' > actual.stdout 2> actual.stderr
  rc=\$?
  echo \"TEST $name rc=\$rc\"
)"
  fi
done

ssh -e none "$PPC_HOST" "$remote_script" > "$LOGDIR/remote-run.log" 2>&1

# Fetch all artifacts back.
ssh -e none "$PPC_HOST" "cd $REMOTE_BASE && tar cf - ." | (cd "$LOGDIR" && tar xf -)

# Cleanup remote.
ssh -e none "$PPC_HOST" "rm -rf $REMOTE_BASE"

NORMALISE="$SESSION_DIR/scripts/normalise.py"

# norm() applies the upstream-equivalent test-driver normalisations to
# a file in place.  Mirrors: " error:" strip, bullet strip, callstack
# line/col elision, ImplicitParams→HasCallStack, plus per-test
# normalise_version('base'|...) when --version is passed.
norm() {
  local f=$1; shift
  [ -f "$f" ] || return 0
  python3 "$NORMALISE" "$@" < "$f" > "$f.norm"
  mv "$f.norm" "$f"
}

# Per-test extra normaliser args.  Mirrors annotations in upstream all.T.
norm_args_for() {
  case "$1" in
    ghci008) echo "--version base" ;;
    *) echo "" ;;
  esac
}

# Diff each test and emit summary.
echo
echo "=== GHCi subset results (host=$PPC_HOST, ghc=$GHC) ==="
pass=0; fail=0
declare -a FAILED
for entry in "${TESTS[@]}"; do
  read -r name combined extras <<< "$entry"
  dir="$LOGDIR/$name"
  fail_reasons=()

  rc=$(grep "^TEST $name rc=" "$LOGDIR/remote-run.log" | tail -1 | sed 's/.*rc=//')
  if [ "$rc" = 127 ] || [ "$rc" = 137 ] || [ "$rc" = 134 ]; then
    fail_reasons+=("ghc rc=$rc")
  fi

  nargs=$(norm_args_for "$name")
  # Normalise BOTH expected and actual through the same pipeline so a
  # mismatch only signals real differences.
  if [ "$combined" = 1 ]; then
    norm "$dir/expected.stdout" $nargs
    norm "$dir/actual.combined" $nargs
    if [ ! -f "$dir/expected.stdout" ]; then
      [ -s "$dir/actual.combined" ] && fail_reasons+=("combined output non-empty but no expected.stdout")
    elif ! diff -qw "$dir/expected.stdout" "$dir/actual.combined" > /dev/null 2>&1; then
      fail_reasons+=("combined output mismatch")
    fi
  else
    norm "$dir/expected.stdout" $nargs
    norm "$dir/expected.stderr" $nargs
    norm "$dir/actual.stdout" $nargs
    norm "$dir/actual.stderr" $nargs
    if [ -f "$dir/expected.stdout" ]; then
      if ! diff -qw "$dir/expected.stdout" "$dir/actual.stdout" > /dev/null 2>&1; then
        fail_reasons+=("stdout mismatch")
      fi
    else
      [ -s "$dir/actual.stdout" ] && fail_reasons+=("stdout non-empty but no expected.stdout")
    fi
    if [ -f "$dir/expected.stderr" ]; then
      if ! diff -qw "$dir/expected.stderr" "$dir/actual.stderr" > /dev/null 2>&1; then
        fail_reasons+=("stderr mismatch")
      fi
    else
      [ -s "$dir/actual.stderr" ] && fail_reasons+=("stderr non-empty but no expected.stderr")
    fi
  fi

  if [ ${#fail_reasons[@]} -eq 0 ]; then
    pass=$((pass+1))
    printf "  PASS  %-10s  (rc=%s)\n" "$name" "$rc"
  else
    fail=$((fail+1))
    FAILED+=("$name")
    printf "  FAIL  %-10s  (rc=%s)  %s\n" "$name" "$rc" "$(IFS='; '; echo "${fail_reasons[*]}")"
  fi
done

echo
echo "=== Summary: $pass PASS / $fail FAIL out of ${#TESTS[@]} tests ==="
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed: ${FAILED[*]}"
  echo "Diffs in $LOGDIR/<test>/{actual,expected}.* "
fi
