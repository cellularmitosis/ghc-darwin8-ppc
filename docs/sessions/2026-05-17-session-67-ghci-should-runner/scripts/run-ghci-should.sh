#!/bin/bash
# Run the should_run/ + should_fail/ subsets of upstream's GHCi
# testsuite (tests/ghci/should_{run,fail}/all.T) against the deployed
# stage2 ghc on a PPC Tiger host.
#
# Why this exists: HANDOFF priority #1 from session 66.
# tests/ghci/should_run/all.T and should_fail/all.T are the two
# remaining flat-per-file ghci_script families (like
# tests/ghci/scripts/, which we covered in sessions 56–64).  Together
# they have ~37 in-scope tests across two annotation shapes:
#
#   - ghci_script (29 from should_run/ + 7 from should_fail/) — same
#     shape as session 62's run-ghci-tnum.sh: pipe .script into
#     `ghc --interactive`, compare actual.{stdout,stderr} to expected.
#   - compile_and_run + only_ways(['ghci']) (8 from should_run/) — new
#     shape this session.  Mirrors upstream's
#     testsuite/driver/testlib.py::interpreter_run: generate a tiny
#     synthetic "genscript" that does `:set prog X`, `:set args`,
#     echoes a delimiter, then `runIOFastExit Main.main`.  Run as
#     `ghc --interactive $name.hs < genscript`, then split the
#     actual.{stdout,stderr} at the delimiter and compare the
#     post-delimiter portion to expected.
#
# Out-of-scope (skipped):
#   - BinaryArray (should_run): `normal` way only, not GHCi-only.
#     Would need a compile-to-native + remote-run shape (the
#     `runghc-tiger` flow), which is outside this runner's scope.
#   - T3171 (should_run): `makefile_test`.
#   - T18064 (should_run): `when(leading_underscore(),skip)` —
#     Mach-O has leading underscores, so upstream skips it on our
#     platform (it'd print "_blah" instead of "blah" in the error).
#   - T15633a, T15633b (should_run): `pre_cmd($MAKE -s ... tc-plugin-ghci
#     package.plugins01)` builds a typechecker plugin via Makefile.
#     Out of shape for a ghci-script runner; would also require the
#     plugin to load on ppc.
#
# Usage:
#   ./run-ghci-should.sh                 # runs against pmacg5
#   ./run-ghci-should.sh imacg4          # explicit host
#
# Output: per-test PASS/FAIL line on stdout; full actual outputs
# captured under $LOGDIR/<test>/actual.{stdout,stderr,combined} and
# (for compile_and_run) {comp,run}.{stdout,stderr}.

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
GHC_SRC="${GHC_SRC:-/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8}"
SR_DIR="$GHC_SRC/testsuite/tests/ghci/should_run"
SF_DIR="$GHC_SRC/testsuite/tests/ghci/should_fail"
SESSION_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOGDIR="$SESSION_DIR/logs/ghci-should"
REMOTE_BASE="/tmp/ghci-should-$$"

# Test list.  Format: "name kind family combined"
#   name     = test name (also basename of .script/.stdout/.stderr/.hs)
#   kind     = ghci_script | compile_and_run
#   family   = sr (should_run) | sf (should_fail)
#   combined = 0 | 1   (combined_output annotation: stdout+stderr merged)
TESTS=(
  # ---- should_fail / ghci_script (7) ----
  "T10549    ghci_script      sf 0"
  "T10549a   ghci_script      sf 0"
  "T15055    ghci_script      sf 0"
  "T16013    ghci_script      sf 0"
  "T16287    ghci_script      sf 0"
  "T18052b   ghci_script      sf 0"
  "T18027a   ghci_script      sf 0"

  # ---- should_run / ghci_script (29) ----
  "T9914     ghci_script      sr 0"
  "T9915     ghci_script      sr 0"
  "T10145    ghci_script      sr 0"
  "T7253     ghci_script      sr 0"
  "T10857a   ghci_script      sr 0"
  "T10857b   ghci_script      sr 0"
  "T11328    ghci_script      sr 0"
  "T11825    ghci_script      sr 0"
  "T12128    ghci_script      sr 0"
  "T12456    ghci_script      sr 0"
  "T12525    ghci_script      sr 0"
  "T12549    ghci_script      sr 0"
  "T13456    ghci_script      sr 1"
  "T14125a   ghci_script      sr 0"
  "T13825-ghci ghci_script    sr 0"
  "T14608    ghci_script      sr 0"
  "T14963a   ghci_script      sr 0"
  "T14963b   ghci_script      sr 0"
  "T14963c   ghci_script      sr 0"
  "T15007    ghci_script      sr 0"
  "T15806    ghci_script      sr 0"
  "T15369    ghci_script      sr 0"
  "T16012    ghci_script      sr 0"
  "T16096    ghci_script      sr 0"
  "T507      ghci_script      sr 0"
  "T18027    ghci_script      sr 0"
  "T18594    ghci_script      sr 0"
  "T18562    ghci_script      sr 0"
  "T19460    ghci_script      sr 0"

  # ---- should_run / compile_and_run + only_ways(['ghci']) (8) ----
  "ghcirun001 compile_and_run sr 0"
  "ghcirun002 compile_and_run sr 0"
  "ghcirun003 compile_and_run sr 0"
  "ghcirun004 compile_and_run sr 0"
  "T2589      compile_and_run sr 0"
  "T2881      compile_and_run sr 0"
  "T8377      compile_and_run sr 0"
  "T19628     compile_and_run sr 0"
)

# Per-test extra companion files to stage (relative to source dir).
# Auto-discovery picks up $name.* and ${name}_*, so this is only for
# cross-test shared sources (eg. T19628a.hs is shared by T19628).
extras_for() {
  case "$1" in
    T19628) echo "T19628a.hs" ;;
    # T18027 exercises `:script` with a spaces-containing path.  The
    # companion `T18027 SPACE IN FILE NAME.script` doesn't match the
    # `$name.*` auto-discovery glob (next char is a space, not a dot).
    # Quoting it lets the loop see one token; the cp loop unquotes.
    T18027) echo "T18027:SPACE:IN:FILE:NAME.script" ;;
    *)      echo "" ;;
  esac
}

# Per-test extra GHC flags.  Mirrors upstream's `extra_hc_opts(...)`
# annotations.
hc_opts_for() {
  case "$1" in
    T10857b) echo "-XMonomorphismRestriction -XNoExtendedDefaultRules" ;;
    T14963c) echo "-fdefer-type-errors" ;;
    *)       echo "" ;;
  esac
}

# Per-test extra normaliser args.  T15055 needs --version ghc to
# canonicalise "ghc-X.Y.Z" → "ghc-<VERSION>" (the .stderr file
# hardcodes the historical "ghc-8.5" string).
norm_args_for() {
  case "$1" in
    T15055) echo "--version ghc" ;;
    *)      echo "" ;;
  esac
}

DYLD_ENV='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real
HC_FLAGS="--interactive -v0 -ignore-dot-ghci -fno-ghci-history \
-fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never"

# Marker line emitted by the genscript to separate compile output
# from program output.  Same string upstream uses.
DELIM="===== program output begins here"

mkdir -p "$LOGDIR"
rm -rf "$LOGDIR"/* 2>/dev/null

# Stage all test files into a single tarball, scp once.
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

# Resolve source dir per test family.
src_dir_for() {
  case "$1" in
    sr) echo "$SR_DIR" ;;
    sf) echo "$SF_DIR" ;;
  esac
}

for entry in "${TESTS[@]}"; do
  read -r name kind family combined <<< "$entry"
  src=$(src_dir_for "$family")
  dest="$STAGE/$name"
  mkdir -p "$dest"

  # Always stage expected outputs if they exist.
  [ -f "$src/$name.stdout" ] && cp "$src/$name.stdout" "$dest/expected.stdout"
  [ -f "$src/$name.stderr" ] && cp "$src/$name.stderr" "$dest/expected.stderr"

  # Kind-specific staging.
  if [ "$kind" = "ghci_script" ]; then
    cp "$src/$name.script" "$dest/"
  else  # compile_and_run
    cp "$src/$name.hs" "$dest/"
    # Synthesize a genscript that mirrors upstream's interpreter_run.
    # (`:set args` is empty since none of our compile_and_run tests
    # use extra_run_opts.)
    cat > "$dest/genscript" <<EOF
:set prog $name
:set args
:! echo $DELIM
:! echo 1>&2 $DELIM
System.IO.hSetBuffering System.IO.stdout System.IO.LineBuffering
GHC.TopHandler.runIOFastExit Main.main Prelude.>> Prelude.return ()
EOF
  fi

  # Auto-discover companion files matching $name.* and ${name}_*,
  # excluding the .script/.stdout/.stderr we've handled.  Same
  # pattern as run-ghci-tnum.sh.
  for f in "$src/$name."* "$src/${name}_"*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.script|*.stdout|*.stderr) ;;
      *) cp "$f" "$dest/" ;;
    esac
  done

  # Explicit extras (shared cross-test sources).  We split on
  # whitespace via the unquoted expansion, so source filenames
  # containing spaces must be encoded with `:` placeholders and
  # decoded here at copy time.
  extras=$(extras_for "$name")
  if [ -n "$extras" ]; then
    for x in $extras; do
      fname=$(echo "$x" | tr ':' ' ')
      cp "$src/$fname" "$dest/"
    done
  fi
done

# Ship tarball + run script.
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
  read -r name kind family combined <<< "$entry"
  opts=$(hc_opts_for "$name")
  if [ "$kind" = "ghci_script" ]; then
    if [ "$combined" = "1" ]; then
      remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$name'
  $GHC $HC_FLAGS $opts < '$name.script' > actual.combined 2>&1
  rc=\$?
  echo \"TEST $name rc=\$rc\"
)"
    else
      remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$name'
  $GHC $HC_FLAGS $opts < '$name.script' > actual.stdout 2> actual.stderr
  rc=\$?
  echo \"TEST $name rc=\$rc\"
)"
    fi
  else  # compile_and_run
    remote_script+=$'\n'"(
  cd '$REMOTE_BASE/$name'
  $GHC $HC_FLAGS $opts '$name.hs' < genscript > actual.stdout 2> actual.stderr
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

# Split a captured actual.{stdout,stderr} at the delimiter line.
# Pre-delimiter content (compiler banner / messages) → comp.<stream>.
# Post-delimiter content (program output) → run.<stream>.
# If the delimiter is absent, treat everything as run output.
split_by_delim() {
  local f=$1; local pre=$2; local post=$3
  if [ ! -f "$f" ]; then
    : > "$pre"; : > "$post"; return 0
  fi
  if grep -q -F "$DELIM" "$f"; then
    awk -v d="$DELIM" -v pre="$pre" -v post="$post" '
      BEGIN { phase = "pre" }
      {
        if (phase == "pre" && index($0, d) == 1) { phase = "post"; next }
        if (phase == "pre") print > pre
        else print > post
      }
    ' "$f"
    # awk only creates files if it actually writes to them; make sure
    # both exist so downstream diff steps work.
    [ -f "$pre" ] || : > "$pre"
    [ -f "$post" ] || : > "$post"
  else
    cp "$f" "$post"
    : > "$pre"
  fi
}

# Diff each test and emit summary.
echo
echo "=== GHCi should_{run,fail} results (host=$PPC_HOST, ghc=$GHC) ==="
pass=0; fail=0
declare -a FAILED
for entry in "${TESTS[@]}"; do
  read -r name kind family combined <<< "$entry"
  dir="$LOGDIR/$name"
  nargs=$(norm_args_for "$name")
  fail_reasons=()

  rc=$(grep "^TEST $name rc=" "$LOGDIR/remote-run.log" | tail -1 | sed 's/.*rc=//')
  # Detect lethal signals.  128+N: 134=SIGABRT, 137=SIGKILL,
  # 138=SIGBUS, 139=SIGSEGV.  127 = command-not-found.
  if [ "$rc" = 127 ] || [ "$rc" = 134 ] || [ "$rc" = 137 ] || [ "$rc" = 138 ] || [ "$rc" = 139 ]; then
    fail_reasons+=("ghc rc=$rc (lethal signal)")
  fi

  if [ "$kind" = "compile_and_run" ]; then
    # Split actual stdout/stderr by the delimiter, then compare the
    # post-delimiter portion (program output) to expected.
    split_by_delim "$dir/actual.stdout" "$dir/comp.stdout" "$dir/run.stdout"
    split_by_delim "$dir/actual.stderr" "$dir/comp.stderr" "$dir/run.stderr"
    norm "$dir/expected.stdout" $nargs
    norm "$dir/expected.stderr" $nargs
    norm "$dir/run.stdout" $nargs
    norm "$dir/run.stderr" $nargs
    if [ -f "$dir/expected.stdout" ]; then
      if ! diff -qw "$dir/expected.stdout" "$dir/run.stdout" > /dev/null 2>&1; then
        fail_reasons+=("stdout mismatch")
      fi
    else
      [ -s "$dir/run.stdout" ] && fail_reasons+=("stdout non-empty but no expected.stdout")
    fi
    if [ -f "$dir/expected.stderr" ]; then
      if ! diff -qw "$dir/expected.stderr" "$dir/run.stderr" > /dev/null 2>&1; then
        fail_reasons+=("stderr mismatch")
      fi
    else
      [ -s "$dir/run.stderr" ] && fail_reasons+=("stderr non-empty but no expected.stderr")
    fi
  elif [ "$combined" = "1" ]; then
    norm "$dir/expected.stdout" $nargs
    norm "$dir/actual.combined" $nargs
    if [ ! -f "$dir/expected.stdout" ]; then
      [ -s "$dir/actual.combined" ] && fail_reasons+=("combined output non-empty but no expected.stdout")
    elif ! diff -qw "$dir/expected.stdout" "$dir/actual.combined" > /dev/null 2>&1; then
      fail_reasons+=("combined output mismatch")
    fi
  else  # ghci_script, separate streams
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
    printf "  PASS  %-13s  (%s/%s, rc=%s)\n" "$name" "$family" "$kind" "$rc"
  else
    fail=$((fail+1))
    FAILED+=("$name")
    printf "  FAIL  %-13s  (%s/%s, rc=%s)  %s\n" "$name" "$family" "$kind" "$rc" "$(IFS='; '; echo "${fail_reasons[*]}")"
  fi
done

echo
echo "=== Summary: $pass PASS / $fail FAIL out of ${#TESTS[@]} tests ==="
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "Failed: ${FAILED[*]}"
  echo "Diffs in $LOGDIR/<test>/{actual,expected,run,comp}.* "
fi
