#!/bin/bash
# Run a curated subset of upstream's GHCi DEBUGGER testsuite against
# the deployed stage2 ghc on a PPC Tiger host.
#
# This is the session-57 companion to session-56's run-ghci-subset.sh.
# Same harness shape (stage files, ssh-run, fetch back, normalise +
# diff), different source dir
# (testsuite/tests/ghci.debugger/scripts/) and different extras
# layout: many tests pull companion files from the parent dir (e.g.
# ../Test.hs, ../QSort.hs), some pull from same dir with mixed-case
# names.
#
# Selection criteria (mirrors session 56):
#   INCLUDE: any test in all.T whose option list is just `normal`,
#            `combined_output`, or `extra_files([...])`.
#   SKIP:    expect_broken / extra_hc_opts / extra_run_opts
#            (e.g. hist001/hist002 use '+RTS -I0' which we don't wire).
#   SPECIAL: T13825-debugger is expect_broken on powerpc64 (not us),
#            so it stays in.  break006 is expect_broken only under
#            compiler_debugged() (we're release), so it stays in.
#
# Usage:
#   ./run-ghci-debugger.sh                # runs against pmacg5
#   ./run-ghci-debugger.sh imacg4         # explicit host
#
# Output: per-test PASS/FAIL line on stdout; full per-test artifacts
# under $LOGDIR/<test>/.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
GHC_SRC="${GHC_SRC:-/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8}"
SCRIPTS_DIR="$GHC_SRC/testsuite/tests/ghci.debugger/scripts"
SESSION_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$SESSION_DIR/logs/ghci-debugger"
REMOTE_BASE="/tmp/ghci-debugger-$$"

# Test list.  Format:  "name combined_output(0|1) extra1 extra2 ..."
# - extra paths are relative to SCRIPTS_DIR.  "../Test.hs" pulls
#   from the parent ghci.debugger/ dir; bare basenames pull from
#   SCRIPTS_DIR.  All land as basenames in the per-test work dir.
TESTS=(
  # print* — Printing / :print / :sprint / :force
  "print001 0"
  "print002 0 ../Test.hs"
  "print003 0 ../Test.hs"
  "print004 0"
  "print005 0 ../QSort.hs"
  "print006 0 ../Test.hs"
  "print007 0 ../Test.hs"
  "print008 0 ../Test.hs"
  "print009 0"
  "print010 0 ../Test.hs"
  "print011 0 ../Test.hs"
  "print012 0 ../GADT.hs ../Test.hs"
  "print013 0 ../GADT.hs"
  "print014 0 ../GADT.hs"
  "print016 0 ../Test.hs"
  "print017 0 ../Test.hs"
  "print018 0 ../Test.hs"
  "print019 0 ../Test.hs"
  "print020 0 ../HappyTest.hs"
  "print021 0"
  "print022 0"
  "print023 0 ../Test.hs"
  "print024 0 ../Test.hs"
  "print025 0"
  "print026 0"
  "print027 0"
  "print028 0"
  "print029 0"
  "print030 0 print029.hs"
  "print031 0"
  "print032 0 print029.hs"
  "print033 0"
  "print034 0 ../GADT.hs ../Test.hs"
  "print035 0 ../Unboxed.hs"
  "print037 0"
  # break* — :break / :step / bytecode breakpoints
  "break001 0 ../Test2.hs"
  "break002 0 ../Test2.hs"
  "break003 0 ../Test3.hs"
  "break005 0 ../QSort.hs"
  "break006 0 ../Test3.hs"
  "break007 0 Break007.hs"
  "break008 0 ../Test3.hs"
  "break009 1 ../Test6.hs"
  "break010 0 ../Test6.hs"
  "break011 1 ../Test7.hs"
  "break012 0"
  "break013 0"
  "break014 0"
  "break016 1"
  "break017 1 ../QSort.hs"
  "break019 0 ../Test2.hs"
  "break020 0 Break020b.hs"
  "break021 0 Break020b.hs break020.hs"
  "break024 1"
  "break025 0"
  "break026 0"
  "break027 0 ../QSort.hs"
  "break029 0 break029.hs"
  # dynbrk* — dynamic breakpoint manipulation
  "dynbrk001 0 ../QSort.hs"
  "dynbrk002 0 ../QSort.hs"
  "dynbrk003 0"
  "dynbrk004 0 ../mdo.hs"
  "dynbrk007 0"
  "dynbrk008 0"
  "dynbrk009 0"
  # Misc
  "result001 0"
  "listCommand001 1 ../Test3.hs"
  "listCommand002 0"
  "T2740 0"
  # T2950 and T3000 use camelcase-suffixed companion files (T2950M.hs,
  # T2950S.hs, T3000S.hs) that don't match the auto-discover globs
  # <name>.* or <name>_*.  all.T leaves them out of extra_files()
  # because upstream's driver stages every file in the test dir;
  # we list them explicitly.
  "T2950 0 T2950M.hs T2950S.hs"
  "T3000 0 T3000.hs T3000S.hs"
  "getargs 0 ../getargs.hs"
  "T7386 0"
  "T8487 0"
  "T8557 0"
  "T12458 0"
  "T13825-debugger 0"
  "T14628 0"
  "T14690 0"
  "T16700 0"
  "T2215 0"
  "T17989 0 T17989A.hs T17989B.hs T17989C.hs T17989M.hs"
  "T19157 0"
)

DYLD_ENV='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real
# Mirrors upstream's testsuite/mk/test.mk TEST_HC_OPTS +
# TEST_HC_OPTS_INTERACTIVE (with debugger tests it's the same; nothing
# debugger-specific in those flags).
HC_FLAGS="--interactive -v0 -ignore-dot-ghci -fno-ghci-history \
-fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never"

mkdir -p "$LOGDIR"
rm -rf "$LOGDIR"/* 2>/dev/null

# Stage all files locally, then tar+ssh in one shot.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

for entry in "${TESTS[@]}"; do
  read -r name combined extras <<< "$entry"
  dest="$STAGE/$name"
  mkdir -p "$dest"
  cp "$SCRIPTS_DIR/$name.script" "$dest/"
  [ -f "$SCRIPTS_DIR/$name.stdout" ] && cp "$SCRIPTS_DIR/$name.stdout" "$dest/expected.stdout"
  [ -f "$SCRIPTS_DIR/$name.stderr" ] && cp "$SCRIPTS_DIR/$name.stderr" "$dest/expected.stderr"
  # Auto-include any companion files matching $name.* or $name_*
  # (e.g. break012.hs, T17989_*.hs).  Skip script/stdout/stderr.
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

# Ship.
ssh -e none "$PPC_HOST" "mkdir -p $REMOTE_BASE"
(cd "$STAGE" && tar cf - .) | ssh -e none "$PPC_HOST" "cd $REMOTE_BASE && tar xf -"

# Build a remote runner.
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

# Fetch artifacts.
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

# Any per-test extras (e.g. normalise_version('base') for tests whose
# expected files quote a specific base version).
norm_args_for() {
  case "$1" in
    *) echo "" ;;
  esac
}

echo
echo "=== GHCi debugger subset results (host=$PPC_HOST, ghc=$GHC) ==="
pass=0; fail=0
declare -a FAILED
for entry in "${TESTS[@]}"; do
  read -r name combined extras <<< "$entry"
  dir="$LOGDIR/$name"
  fail_reasons=()

  rc=$(grep "^TEST $name rc=" "$LOGDIR/remote-run.log" | tail -1 | sed 's/.*rc=//')
  if [ "$rc" = 127 ] || [ "$rc" = 137 ] || [ "$rc" = 134 ] || [ "$rc" = 139 ]; then
    fail_reasons+=("ghc rc=$rc")
  fi

  nargs=$(norm_args_for "$name")
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
    printf "  PASS  %-20s  (rc=%s)\n" "$name" "$rc"
  else
    fail=$((fail+1))
    FAILED+=("$name")
    printf "  FAIL  %-20s  (rc=%s)  %s\n" "$name" "$rc" "$(IFS='; '; echo "${fail_reasons[*]}")"
  fi
done

echo
echo "=== Summary: $pass PASS / $fail FAIL out of ${#TESTS[@]} tests ==="
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed: ${FAILED[*]}"
  echo "Diffs in $LOGDIR/<test>/{actual,expected}.* "
fi
