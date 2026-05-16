#!/bin/bash
# v0.14.2 demo: StaticPointers + GHCi -fobject-code on PPC/Tiger.
#
# What this demonstrates: the v0.14.2 bindist can load Mach-O `.o`
# files that reference `___dso_handle` from their SPT init code.
# This is what happens in practice whenever GHCi-`-fobject-code`
# mode compiles a module containing a `static` pointer:
#
#   StaticPointers SPT init
#     -> __cxa_atexit(_handler, _env, _ _ _dso_handle)
#         -> the .o has an undefined `___dso_handle` external
#             -> rts/Linker.c::lookupDependentSymbol must
#                resolve it as a synthetic handle for the loaded object
#
# Pre-v0.14.2 that strcmp matched only the ELF spelling
# `__dso_handle` (two underscores), so the Mach-O form
# `___dso_handle` (three underscores) missed the special case, fell
# through to dlsym, and dlsym on Tiger doesn't find the symbol
# (it's a link-time-only artifact of dylib1.o / crt1.o).  The .o
# load aborted with `unknown symbol \`___dso_handle'`.
# v0.14.2 fixes it (patch 0017).
#
# This script:
#   1. Confirms the deployed v0.14.2 ghc-real has both spellings
#      of `dso_handle` in its compiled-in Linker.c text segment.
#   2. scp's the v0.14.2 .hs demo to Tiger.
#   3. Compiles + runs natively (the simpler path -- works on
#      any release that ships StaticPointers in the SPT machinery,
#      but bundling the demo lets the v0.14.2 release tag have a
#      runnable copy on disk).
#   4. Loads the same module into GHCi `-fobject-code` mode (the
#      load path that was broken pre-v0.14.2) and exercises
#      `deRefStaticPtr` on each of the four `static` pointers --
#      this is the new capability v0.14.2 unblocks.
#
# Session: docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/
#
# Prereqs: v0.14.2 stage2 deployed to $PPC_HOST via deploy-stage2.sh
# (or v0.14.2 bindist installed via install.sh).

set -uo pipefail

PPC_HOST="${1:-pmacg5}"
DYLD='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'
GHC=/opt/ghc-stage2/bin/ghc-real
HS="$(cd "$(dirname "$0")" && pwd)/v0.14.2-static-pointers.hs"

echo "==> 0. confirm v0.14.2 ghc-real has both __dso_handle spellings"
ssh -e none -T -q "$PPC_HOST" "strings $GHC | grep -F dso_handle | sort -u"

echo
echo "==> 1. ship the .hs to Tiger"
scp -q "$HS" "$PPC_HOST:/tmp/static-pointers.hs"

echo
echo "==> 2. compile + run natively"
ssh -e none -T -q "$PPC_HOST" "
  set -e
  cd /tmp
  rm -f static-pointers static-pointers.o static-pointers.hi
  $DYLD $GHC -O0 static-pointers.hs -o static-pointers 2>&1 | tail -10
  echo
  $DYLD /tmp/static-pointers
"

echo
echo "==> 3. :load the module into GHCi -fobject-code (the v0.14.2 path)"
ssh -e none -T -q "$PPC_HOST" "$DYLD $GHC --interactive -ignore-dot-ghci -fobject-code 2>&1" <<'EOF'
:l /tmp/static-pointers.hs
:m + GHC.StaticPtr
deRefStaticPtr staticTrue
deRefStaticPtr staticGreeting
deRefStaticPtr staticDouble 21
deRefStaticPtr staticSum [1..10]
main
:q
EOF

echo
echo "v0.14.2 demo done.  StaticPointers + GHCi -fobject-code work on PPC/Tiger."
