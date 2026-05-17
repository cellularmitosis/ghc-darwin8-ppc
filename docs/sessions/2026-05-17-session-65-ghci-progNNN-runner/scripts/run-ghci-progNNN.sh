#!/bin/bash
# Run the prog001..prog019 subset of upstream's GHCi testsuite
# (tests/ghci/prog0*/) against the deployed stage2 ghc on a PPC Tiger
# host.
#
# Why this exists: sessions 56 / 57 / 58 / 60 / 62 / 63 / 64 wired
# every annotation flavour in tests/ghci/scripts/all.T's T-prefix
# subset (175/177 PASS at v0.15.0).  The next breadth target listed
# in session 64's HANDOFF is prog001..prog019 — multi-module
# compile-and-run-via-REPL tests, each in its own subdirectory under
# tests/ghci/.  Different harness shape from the scripts/ tests:
#  - each test has a per-test directory with multiple .hs (and
#    optionally .hs-boot) files
#  - some tests reference upstream's `../shell.hs` helper, copied
#    in from tests/ghci/shell.hs
#  - some tests use `:shell "$HC" $HC_OPTS $ghciWayFlags -c X.hs`
#    inside the script to do partial native compilation between
#    :reload steps, so we must export those env vars before invoking
#    ghc
#  - some have subdirectories (prog015/Level2, prog016/Level2,
#    prog017/Level2) which need recursive staging
#  - prog019 has `extra_hc_opts('-fkeep-going')`
#  - prog018 has `combined_output`
#
# Skipped:
#  - prog004 — `makefile_test` (not ghci_script)
#  - prog014 — `expect_fail` + `pre_cmd($MAKE -s prog014)` — out of
#    scope (foreign-import-prim Haskell prog that's broken by design
#    for the bytecode interpreter)
#
# Usage:
#   ./run-ghci-progNNN.sh                 # runs against pmacg5
#   ./run-ghci-progNNN.sh imacg4          # explicit host
#
# Output: per-test PASS/FAIL line on stdout; full actual outputs
# captured under $LOGDIR/<test>/actual.{stdout,stderr,combined}.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
GHC_SRC="${GHC_SRC:-/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8}"
GHCI_DIR="$GHC_SRC/testsuite/tests/ghci"
SESSION_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$SESSION_DIR/logs/ghci-progNNN"
REMOTE_BASE="/tmp/ghci-progNNN-$$"

# Test list.  Format: "dir name combined need_shell_hs"
#   dir            = per-test subdir name under tests/ghci/
#   name           = the `test('<name>', ...)` identifier from .T, used
#                    for the .script / .stdout / .stderr basenames
#   combined       = 1 if the test annotates `combined_output`
#   need_shell_hs  = 1 if the test annotates `extra_files(['../shell.hs', ...])`
TESTS=(
  "prog001 prog001 0 1"
  "prog002 prog002 0 1"
  "prog003 prog003 0 1"
  "prog005 prog005 0 0"
  "prog006 prog006 0 0"
  "prog007 ghci.prog007 0 0"
  "prog008 ghci.prog008 0 0"
  "prog009 ghci.prog009 0 0"
  "prog010 ghci.prog010 0 1"
  "prog011 prog011 0 0"
  "prog012 prog012 0 1"
  "prog013 prog013 0 0"
  "prog015 prog015 0 0"
  "prog016 prog016 0 0"
  "prog017 prog017 0 0"
  "prog018 prog018 1 0"
  "prog019 prog019 0 0"
)

DYLD_ENV='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real
# Interactive flags.  Identical to session 64's run-ghci-tnum.sh.
HC_FLAGS="--interactive -v0 -ignore-dot-ghci -fno-ghci-history \
-fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never"
# HC_OPTS that scripts see via `:shell "$HC" $HC_OPTS ...` when they
# do partial native compilation between :reload steps.  Mirrors the
# subset of upstream `TEST_HC_OPTS` (testsuite/mk/test.mk:39) that is
# safe + relevant for our paths.  Notably we DROP `-dcore-lint
# -dstg-lint -dcmm-lint -Werror=compat -dno-debug-output` because
# those are upstream-developer-mode hygiene that isn't needed to
# reproduce a test's expected output, and DROP `-rtsopts` because
# our scripts don't pass RTS args via the produced .o.
REMOTE_HC_OPTS="-fshow-warning-groups -fno-diagnostics-show-caret \
-fdiagnostics-color=never -fno-warn-missed-specialisations \
-no-user-package-db"

# Per-test extra GHC flags.  Mirrors `extra_hc_opts(...)` annotations
# in upstream tests/ghci/prog0*/<name>.T.
run_opts_for() {
  case "$1" in
    prog019) echo "-fkeep-going" ;;
    *)       echo "" ;;
  esac
}

mkdir -p "$LOGDIR"
rm -rf "$LOGDIR"/* 2>/dev/null

# Stage all test dirs (recursively) into a single staging tree, scp once.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

for entry in "${TESTS[@]}"; do
  read -r dir name combined need_shell <<< "$entry"
  dest="$STAGE/$dir"
  # Copy the entire per-test dir, recursively (catches Level2/ etc).
  cp -R "$GHCI_DIR/$dir" "$dest"
  if [ "$need_shell" = 1 ]; then
    cp "$GHCI_DIR/shell.hs" "$dest/"
  fi
done

# Ship tarball + run script.
ssh -e none "$PPC_HOST" "mkdir -p $REMOTE_BASE"
(cd "$STAGE" && tar cf - .) | ssh -e none "$PPC_HOST" "cd $REMOTE_BASE && tar xf -"

# Build a remote runner.  For each test:
#  - cd into its dir
#  - export HC, HC_OPTS, ghciWayFlags so :shell-style sub-invocations
#    in the .script resolve them
#  - run ghc --interactive < script   capturing stdout/stderr separately
#  - print one TEST-LINE per test with status
remote_script=$(cat <<EOF
set -u
cd "$REMOTE_BASE"
export $DYLD_ENV
export LANG=en_US.UTF-8
export HC='$GHC'
export HC_OPTS='$REMOTE_HC_OPTS'
export ghciWayFlags=''
EOF
)

for entry in "${TESTS[@]}"; do
  read -r dir name combined need_shell <<< "$entry"
  opts=$(run_opts_for "$name")
  if [ "$combined" = "1" ]; then
    remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$dir'
  $GHC $HC_FLAGS $opts < '$name.script' > actual.combined 2>&1
  rc=\$?
  echo \"TEST $name rc=\$rc\"
)"
  else
    remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$dir'
  $GHC $HC_FLAGS $opts < '$name.script' > actual.stdout 2> actual.stderr
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

norm() {
  local f=$1; shift
  [ -f "$f" ] || return 0
  python3 "$NORMALISE" "$@" < "$f" > "$f.norm"
  mv "$f.norm" "$f"
}

# Diff each test and emit summary.
echo
echo "=== GHCi progNNN subset results (host=$PPC_HOST, ghc=$GHC) ==="
pass=0; fail=0
declare -a FAILED
for entry in "${TESTS[@]}"; do
  read -r dir name combined need_shell <<< "$entry"
  tdir="$LOGDIR/$dir"
  fail_reasons=()

  rc=$(grep "^TEST $name rc=" "$LOGDIR/remote-run.log" | tail -1 | sed 's/.*rc=//')
  if [ "$rc" = 127 ] || [ "$rc" = 137 ] || [ "$rc" = 134 ]; then
    fail_reasons+=("ghc rc=$rc")
  fi

  if [ "$combined" = 1 ]; then
    # In combined mode the expected file is always <name>.stdout
    # (upstream's testlib.py merges both into the .stdout slot).
    norm "$tdir/$name.stdout"
    norm "$tdir/actual.combined"
    if [ ! -f "$tdir/$name.stdout" ]; then
      [ -s "$tdir/actual.combined" ] && fail_reasons+=("combined output non-empty but no expected.stdout")
    elif ! diff -qw "$tdir/$name.stdout" "$tdir/actual.combined" > /dev/null 2>&1; then
      fail_reasons+=("combined output mismatch")
    fi
  else
    norm "$tdir/$name.stdout"
    norm "$tdir/$name.stderr"
    norm "$tdir/actual.stdout"
    norm "$tdir/actual.stderr"
    if [ -f "$tdir/$name.stdout" ]; then
      if ! diff -qw "$tdir/$name.stdout" "$tdir/actual.stdout" > /dev/null 2>&1; then
        fail_reasons+=("stdout mismatch")
      fi
    else
      [ -s "$tdir/actual.stdout" ] && fail_reasons+=("stdout non-empty but no expected.stdout")
    fi
    if [ -f "$tdir/$name.stderr" ]; then
      if ! diff -qw "$tdir/$name.stderr" "$tdir/actual.stderr" > /dev/null 2>&1; then
        fail_reasons+=("stderr mismatch")
      fi
    else
      [ -s "$tdir/actual.stderr" ] && fail_reasons+=("stderr non-empty but no expected.stderr")
    fi
  fi

  if [ ${#fail_reasons[@]} -eq 0 ]; then
    pass=$((pass+1))
    printf "  PASS  %-18s  (rc=%s)\n" "$name" "$rc"
  else
    fail=$((fail+1))
    FAILED+=("$name")
    printf "  FAIL  %-18s  (rc=%s)  %s\n" "$name" "$rc" "$(IFS='; '; echo "${fail_reasons[*]}")"
  fi
done

echo
echo "=== Summary: $pass PASS / $fail FAIL out of ${#TESTS[@]} tests ==="
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed: ${FAILED[*]}"
  echo "Diffs in $LOGDIR/<dir>/{actual,<name>}.* "
fi
