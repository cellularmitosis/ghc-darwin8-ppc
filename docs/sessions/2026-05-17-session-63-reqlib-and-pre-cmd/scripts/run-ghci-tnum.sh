#!/bin/bash
# Run the bug-numbered T<NUM>.script subset of upstream's GHCi
# testsuite (tests/ghci/scripts/all.T) against the deployed stage2
# ghc on a PPC Tiger host.
#
# Why this exists: sessions 56 / 57 covered the `ghciNNN` and
# `ghci.debugger` scripts but left the ~160 bug-numbered T<NUM>
# regression scripts in tests/ghci/scripts/ untouched.  Several
# (T4127, T4127a, T5566, T8831, T10466, T11098) exercise
# TemplateHaskell through the REPL in ways session 56's ghci018
# didn't.  Same runner shape as session 56; just a different TESTS
# list.
#
# Session 60 extension: also handle upstream's `extra_run_opts(...)`
# annotation by threading those flags onto the GHC invocation
# (looked up in `run_opts_for` below).  Adds T9878b, T12091, T17500
# to the TESTS list — the three `extra_run_opts` tests in
# tests/ghci/scripts/all.T that weren't already skipped by some
# other annotation (T17669 is also `extra_run_opts(...)` but is
# upstream-`expect_broken(17669)` so we don't run it; ghci017 has
# `reqlib('haskell98')`; ghci056 has `pre_cmd($MAKE)`).
#
# Session 62 extension: also handle upstream's `extra_hc_opts(...)`
# annotation.  Wiring is identical to `extra_run_opts(...)` — both
# end up appended to the same GHC `--interactive` command (compile
# and run happen in one invocation, so compile-flags and run-flags
# both arrive on the same command line).  Adds six tests: T2452,
# T2182ghci2, T9293, T13385, T14342, T16563 — every
# `extra_hc_opts(...)` ghci script in all.T that isn't already
# skipped (ghci057 + ghci065 are ghciNNN-shaped so are out of this
# T<num> runner's scope; T5975b also has `pre_cmd`; T19650 also has
# `pre_cmd` + `filter_stdout_lines`).
#
# Session 63 extension: also handle upstream's `reqlib(...)` and
# simple `pre_cmd(...)` annotations.  Adds three tests:
#  - T5979 (reqlib('transformers')): the stage2 ghc-pkg already has
#    transformers-0.5.6.2 installed.  Test expects a "Could not find
#    module" error with package-version suggestions; we reuse the
#    existing `normalise_version` machinery (via norm_args_for() →
#    `--version transformers`) to elide the embedded version number.
#  - T5975a, T5975b (pre_cmd 'touch föøbàr<N>.hs'): UTF-8 filename
#    smoke test.  T5975b additionally has extra_hc_opts('föøbàr2.hs')
#    which threads through run_opts_for() the same way other
#    extra_hc_opts tests do.
# T6106 (pre_cmd '$MAKE T6106_prep' = compile preproc + extra_files
# ../shell.hs) and T19650 (pre_cmd '$MAKE T19650_setup' = needs
# ghc-pkg on the PPC host) are deliberately *not* wired yet — they
# need either a native compile step or ghc-pkg deployment that's
# outside this session's scope.
#
# Usage:
#   ./run-ghci-tnum.sh                 # runs against pmacg5
#   ./run-ghci-tnum.sh imacg4          # explicit host
#
# Output: per-test PASS/FAIL line on stdout; full actual outputs
# captured under $LOGDIR/<test>/actual.{stdout,stderr,combined}.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
GHC_SRC="${GHC_SRC:-/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8}"
SCRIPTS_DIR="$GHC_SRC/testsuite/tests/ghci/scripts"
SESSION_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$SESSION_DIR/logs/ghci-tnum"
REMOTE_BASE="/tmp/ghci-tnum-$$"

# Test list.  Format: "name combined_output(0|1) extra_files..."
# Filter applied: all upstream tests/ghci/scripts/all.T tests
# whose name is NOT ghciNNN-shaped (i.e. T<NUM>* and miscellaneous
# capitalised ones), with annotation in {normal, combined_output,
# extra_files(...)}, and no extra_hc_opts / extra_run_opts / reqlib /
# req_th / req_interp / expect_broken / pre_cmd / skip / fragile /
# cmd_prefix / makefile_test / filter_stdout_lines.  extra_files
# outside the scripts/ dir (`../...`) skipped (T14676, Defer02).
#
# Explicit extras added below come from two sources:
#  - all.T's `extra_files([...])` (T8353, T10576a, T10576b, T16804,
#    T19667Ghci)
#  - lowercase / capital-suffix companion .hs files not caught by
#    session 56's `<name>.*` / `<name>_*` auto-discovery globs
#    (T5417a, T8469a, T8696A/B, T10110A/B/C, T10322A/B/C, T16876A/B).
TESTS=(
  "T2452 0"
  "T2766 0"
  "T1914 0"
  "T2182ghci 0"
  "T2182ghci2 0"
  "T2976 0"
  "T2816 0"
  "T789 0"
  "T3263 0"
  "T4051 0"
  "T4087 0"
  "T4015 0"
  "T4127 0"
  "T4127a 0"
  "T4316 0"
  "T4832 0"
  "T5045 0"
  "T5130 0"
  "T5417 0 T5417a.hs"
  "T5545 0"
  "T5557 1"
  "T5566 0"
  "T5975a 0"
  "T5975b 0"
  "T5979 0"
  "GhciKinds 0"
  "T5564 0"
  "T5820 0"
  "T5836 0"
  "T6027ghci 0"
  "T6007 0"
  "T6091 0"
  "T6105 0"
  "T7117 0"
  "T7587 0"
  "T7688 0"
  "T7627 0"
  "T7627b 0"
  "T7586 0"
  "T4175 0"
  "T6018ghci 0"
  "T6018ghcifail 0"
  "T6018ghcirnfail 0"
  "T7730 1"
  "T7872 0"
  "T7873 0"
  "T7939 0"
  "T7894 0"
  "T8042 0"
  "T8042recomp 0"
  "T8116 0"
  "T8113 0"
  "T8215 0"
  "T8305 0"
  "T8353 0 Defer03.hs"
  "T8357 0"
  "T8383 0"
  "T8469 0 T8469a.hs"
  "T8485 0"
  "T8535 0"
  "T8639 0"
  "T8640 0"
  "T8579 0"
  "T8649 0"
  "T8674 0"
  "T8696 0 T8696A.hs T8696B.hs"
  "T8776 0"
  "T8831 0"
  "T8917 0"
  "T8931 0"
  "T8959 0"
  "T8959b 0"
  "T9181 0"
  "T9086b 0"
  "T9140 1"
  "T9293 0 ghci057.hs"
  "T9658 0"
  "T9881 0"
  "T9878 0"
  "T9878b 0"
  "T10018 0"
  "T10059 0"
  "T10122 0"
  "T10321 0"
  "T10110 0 T10110A.hs T10110B.hs T10110C.hs"
  "T10322 0 T10322A.hs T10322B.hs T10322C.hs"
  "T10439 0"
  "T10453 0"
  "T10466 0"
  "T10501 0"
  "T10508 0"
  "T10520 0"
  "T10663 0"
  "T10989 0"
  "T11098 0"
  "T11252 0"
  "T10576a 0 T10576.hs"
  "T10576b 0 T10576.hs"
  "T11051a 0"
  "T11051b 0"
  "T11456 0"
  "TypeAppData 0"
  "T11728 0"
  "T11376 0"
  "T12007 0"
  "T12091 0"
  "T11975 0"
  "T10963 0"
  "T11721 0"
  "T12005 0"
  "T12523 0"
  "T12024 0"
  "T12158 0"
  "T12447 0"
  "T10249 0"
  "T12550 0"
  "StaticPtr 0"
  "T13202 0"
  "T13202a 0"
  "T13385 0"
  "T13420 0"
  "T13466 0"
  "GhciCurDir 0"
  "T13699 0"
  "T13988 0"
  "T13407 0"
  "T13795 0"
  "T13963 0"
  "T14342 0"
  "T14796 0"
  "T14969 0"
  "T15259 0"
  "T15341 0"
  "T15568 0"
  "T15325 0"
  "T15591 0"
  "T15743b 0"
  "T15827 0"
  "T15872 0"
  "T15898 0"
  "T15941 0"
  "T16030 0"
  "T11606 0"
  "T16089 0"
  "T14828 0"
  "T16376 0"
  "T16527 0"
  "T16563 0"
  "T16569 0"
  "T16767 0"
  "T16575 0"
  "T16509 0"
  "T16804 0 T16804a.hs T16804b.hs T16804c.hs"
  "T15546 0"
  "T16876 0 T16876A.hs T16876B.hs"
  "T17345 0"
  "T17384 0"
  "T17403 0"
  "T17431 0"
  "T17500 0"
  "T17549 0"
  "T18501 0"
  "T18644 0"
  "T18755 0"
  "T18828 0"
  "T19197 0"
  "T19158 0"
  "T19279 0"
  "T19310 0"
  "T19667Ghci 0 T19667Ghci.hs"
  "T19688 0"
  "T20019 0"
  "T20101 0"
  "T20974 0"
  "T7388 0"
)

DYLD_ENV='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real
HC_FLAGS="--interactive -v0 -ignore-dot-ghci -fno-ghci-history \
-fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never"

# Per-test extra GHC flags.  Mirrors `extra_run_opts(...)` and
# `extra_hc_opts(...)` annotations in upstream tests/ghci/scripts/all.T —
# the flags are appended to the GHC invocation for tests that need a
# specific REPL mode (eg. -fobject-code), extra dump flags (eg.
# -ddump-to-file), or extension/flag tweaks (eg. -XRebindableSyntax).
run_opts_for() {
  case "$1" in
    # extra_run_opts(...) (session 60)
    T9878b|T12091) echo "-fobject-code" ;;
    T17500)        echo "-ddump-to-file -ddump-bcos" ;;
    # extra_hc_opts(...) (session 62)
    T2452)         echo "-fno-implicit-import-qualified" ;;
    T2182ghci2)    echo "-XNoImplicitPrelude" ;;
    T9293)         echo "-fno-ghci-leak-check" ;;
    T13385)        echo "-XRebindableSyntax" ;;
    T14342)        echo "-XOverloadedStrings -XRebindableSyntax" ;;
    T16563)        echo "-clear-package-db -global-package-db" ;;
    # extra_hc_opts(...) (session 63) — UTF-8 filename loaded as a
    # positional arg (the file itself is created by pre_cmd_for below).
    T5975b)        echo "föøbàr2.hs" ;;
    *)             echo "" ;;
  esac
}

# Per-test pre-commands.  Mirrors `pre_cmd(...)` annotations in
# upstream tests/ghci/scripts/all.T — a shell snippet that runs
# (relative to the per-test directory) before the GHC invocation.
# Kept to *simple* one-liners (touch, etc.).  Tests whose pre_cmd
# is `$MAKE ...` (T6106, T19650, ghci056) need a richer harness and
# are deliberately not yet wired.
pre_cmd_for() {
  case "$1" in
    T5975a) echo "touch föøbàr1.hs" ;;
    T5975b) echo "touch föøbàr2.hs" ;;
    *)      echo "" ;;
  esac
}

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
  # (e.g. T11456.hs, T7388.hs).  Skip files belonging to a sibling test
  # whose stem starts with $name but has more chars before the dot
  # (T789 vs T7894, T7627 vs T7627b, etc).
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
  opts=$(run_opts_for "$name")
  pre=$(pre_cmd_for "$name")
  if [ "$combined" = "1" ]; then
    remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$name'
  $pre
  $GHC $HC_FLAGS $opts < '$name.script' > actual.combined 2>&1
  rc=\$?
  echo \"TEST $name rc=\$rc\"
)"
  else
    remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$name'
  $pre
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

# Per-test extra normaliser args.  Mirrors annotations in upstream all.T.
# (Most T<num> tests use plain `normal` so no per-test args.)
norm_args_for() {
  case "$1" in
    # reqlib + normalise_version("transformers") (session 63).  Mirrors
    # upstream's normalise_version() on this test — strips the embedded
    # transformers-X.Y.Z so our 0.5.6.2 install doesn't diff against
    # upstream's 0.5.2.0 expected file.
    T5979) echo "--version transformers" ;;
    *)     echo "" ;;
  esac
}

# Diff each test and emit summary.
echo
echo "=== GHCi T<num> subset results (host=$PPC_HOST, ghc=$GHC) ==="
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
    printf "  PASS  %-15s  (rc=%s)\n" "$name" "$rc"
  else
    fail=$((fail+1))
    FAILED+=("$name")
    printf "  FAIL  %-15s  (rc=%s)  %s\n" "$name" "$rc" "$(IFS='; '; echo "${fail_reasons[*]}")"
  fi
done

echo
echo "=== Summary: $pass PASS / $fail FAIL out of ${#TESTS[@]} tests ==="
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed: ${FAILED[*]}"
  echo "Diffs in $LOGDIR/<test>/{actual,expected}.* "
fi
