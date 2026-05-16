#!/bin/bash
# Cross-build the upstream `unlit` utility for PPC/Tiger.
#
# Why: the v0.14.0 bindist ships an *arm64* unlit at
# /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit, because
# Hadrian's cross-build path in `hadrian/src/Rules/Program.hs`
# copies stage0 (host) helper binaries to stage1 for every package
# except `iserv`.  patch 0010 carved out iserv but missed unlit.
# Result: literate Haskell support (`.lhs`, the `:l foo.lhs` path
# in GHCi, etc.) is broken on the deployed stage2 because the unlit
# pre-processor can't actually execute.
#
# This script cross-builds a real PPC `unlit` from the GHC 9.2.8
# source tree using our cross-cc.  Output is dropped next to this
# script as `powerpc-apple-darwin8-unlit.ppc`.  To install:
#
#     scp powerpc-apple-darwin8-unlit.ppc pmacg5:/tmp/unlit
#     ssh pmacg5 'mv /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit \
#                     /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.broken-host && \
#                  mv /tmp/unlit /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit && \
#                  chmod +x /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit'
#
# This is a *stopgap* — the real fix is a Hadrian patch that adds
# `unlit` (and `touchy`, for completeness) to patch 0010's
# "don't copy stage0 binary in cross mode" exclusion list, then a
# stage1 rebuild + stage2 re-cross-build + new bindist.  That's a
# v0.14.1 release-grade fix, scoped in session 58 HANDOFF.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
GHC_SRC="${GHC_SRC:-$REPO_ROOT/external/ghc-modern/ghc-9.2.8}"
UNLIT_SRC="$GHC_SRC/utils/unlit"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$SCRIPT_DIR/powerpc-apple-darwin8-unlit.ppc"

# shellcheck source=../../../../scripts/cross-env.sh
source "$REPO_ROOT/scripts/cross-env.sh" >/dev/null

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cp "$UNLIT_SRC/unlit.c" "$UNLIT_SRC/fs.c" "$UNLIT_SRC/fs.h" "$WORK/"
cd "$WORK"

# Compile each .c separately (the ppc-cc wrapper routes compile-only
# invocations to clang directly; compile+link from .c goes through the
# fake-linker path and produces a 16-byte stub).
"$CROSS_CC" -O2 -c unlit.c
"$CROSS_CC" -O2 -c fs.c
# Link via tiger_link (pure-link path: no source files in args).
"$CROSS_CC" -o powerpc-apple-darwin8-unlit unlit.o fs.o

# Sanity-check.
file powerpc-apple-darwin8-unlit | grep -q 'Mach-O executable ppc' \
  || { echo "ERROR: built binary is not Mach-O ppc"; exit 1; }

install -m 0755 powerpc-apple-darwin8-unlit "$OUT"
echo "Built: $OUT"
file "$OUT"
