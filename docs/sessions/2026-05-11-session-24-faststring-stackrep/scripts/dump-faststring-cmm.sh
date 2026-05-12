#!/bin/bash
# Re-cross-compile compiler/GHC/Data/FastString.hs with -ddump-cmm and
# friends so we can find the StackRep behind `_blk_c7te` (the frame
# that PROBE22POISON caught misclassifying a stack slot in session 23).
#
# The recipe is hadrian's exact invocation for
#     _build/stage1/compiler/build/GHC/Data/FastString.o
# under the `quick-cross` flavour (captured from a `./hadrian/build
# --verbose` run on 2026-05-11), with these additions:
#
#   * -outputdir / -o redirected to a session-local scratch dir, so
#     we don't disturb the stage2 build artifact.
#   * -ddump-{stg-final,cmm,cmm-final,asm} -ddump-to-file enabled.
#   * -dsuppress-uniques NOT set, so labels keep the same `c7te` etc.
#     uniques that appear in stage2's text section (uniques are stable
#     across rebuilds of the same source).
#   * -ddump-file-prefix points the dumps at the same scratch dir.
#
# Output dir is created fresh under log/session24/cross/.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
GHC_SRC="$REPO_ROOT/external/ghc-modern/ghc-9.2.8"
GHC_CROSS="$GHC_SRC/_build/stage0/bin/powerpc-apple-darwin8-ghc"
OUT="$REPO_ROOT/log/session24/cross"
BUILD_DIR="$GHC_SRC/_build/stage1/compiler/build"

source "$REPO_ROOT/scripts/cross-env.sh" >/dev/null 2>&1

[ -x "$GHC_CROSS" ] || { echo "missing cross compiler: $GHC_CROSS" >&2; exit 1; }

rm -rf "$OUT"
mkdir -p "$OUT"

# Back up FastString.hi/.o so we can restore them after compile —
# our -hidir points at the build dir so imports resolve, but our
# -odir points elsewhere.  Even so, GHC may rewrite the .hi.
HI_BAK="$OUT/.bak"
mkdir -p "$HI_BAK"
cp -p "$BUILD_DIR/GHC/Data/FastString.hi" "$HI_BAK/FastString.hi"
cp -p "$BUILD_DIR/GHC/Data/FastString.o"  "$HI_BAK/FastString.o"

restore_artifacts() {
  cp -p "$HI_BAK/FastString.hi" "$BUILD_DIR/GHC/Data/FastString.hi"
  cp -p "$HI_BAK/FastString.o"  "$BUILD_DIR/GHC/Data/FastString.o"
}
trap restore_artifacts EXIT

cd "$GHC_SRC"

"$GHC_CROSS" \
  -Wall -fdiagnostics-color=never \
  -hisuf hi -osuf o -hcsuf hc -static \
  -hide-all-packages -no-user-package-db -package-env - \
  -package-db _build/stage1/lib/package.conf.d \
  -this-unit-id ghc-9.2.8 \
  -package-id array-0.5.4.0 \
  -package-id base-4.16.4.0 \
  -package-id binary-0.8.9.0 \
  -package-id bytestring-0.11.4.0 \
  -package-id containers-0.6.5.1 \
  -package-id deepseq-1.4.6.1 \
  -package-id directory-1.3.6.2 \
  -package-id exceptions-0.10.4 \
  -package-id filepath-1.4.2.2 \
  -package-id ghc-boot-9.2.8 \
  -package-id ghc-heap-9.2.8 \
  -package-id ghci-9.2.8 \
  -package-id hpc-0.6.1.0 \
  -package-id process-1.6.16.0 \
  -package-id template-haskell-2.18.0.0 \
  -package-id time-1.11.1.1 \
  -package-id transformers-0.5.6.2 \
  -package-id unix-2.7.2.2 \
  -i \
  -i$GHC_SRC/_build/stage1/compiler/build \
  -i$GHC_SRC/_build/stage1/compiler/build/autogen \
  -i$GHC_SRC/compiler \
  -Iincludes -I_build/stage1/lib -I_build/stage1/compiler/build \
  -I_build/stage1/compiler/build/. \
  -I_build/stage1/compiler/build/../rts/dist/build \
  -Icompiler/. -Icompiler/../rts/dist/build \
  -I$GHC_SRC/_build/stage1/lib/ppc-osx-ghc-9.2.8/process-1.6.16.0/include \
  -I$GHC_SRC/_build/stage1/lib/ppc-osx-ghc-9.2.8/unix-2.7.2.2/include \
  -I$GHC_SRC/_build/stage1/lib/ppc-osx-ghc-9.2.8/time-1.11.1.1/include \
  -I$GHC_SRC/_build/stage1/lib/ppc-osx-ghc-9.2.8/bytestring-0.11.4.0/include \
  -I$GHC_SRC/_build/stage1/lib/ppc-osx-ghc-9.2.8/base-4.16.4.0/include \
  -I/Users/cell/.local/ghc-ppc-xtools/include-ppc \
  -I$GHC_SRC/_build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-bignum-1.2/include \
  -I$GHC_SRC/_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/include \
  -I_build/stage1/lib \
  -optc-I_build/stage1/lib \
  -optP-include -optP_build/stage1/compiler/build/autogen/cabal_macros.h \
  -optc--target=powerpc-apple-darwin \
  -optP-DHAVE_INTERNAL_INTERPRETER -optP-DCAN_LOAD_DLL \
  -odir "$BUILD_DIR" -hidir "$BUILD_DIR" -stubdir "$BUILD_DIR" -dumpdir "$OUT" \
  -Wnoncanonical-monad-instances \
  -optc-Wno-unknown-pragmas -optP-Wno-nonportable-include-path \
  -c compiler/GHC/Data/FastString.hs \
  -O0 -H64m -Wall -Wno-name-shadowing \
  -Wnoncanonical-monad-instances -Wnoncanonical-monoid-instances \
  -this-unit-id ghc \
  -XHaskell2010 -XNoImplicitPrelude -XBangPatterns -XScopedTypeVariables -XMonoLocalBinds \
  -no-global-package-db \
  -package-db=$GHC_SRC/_build/stage1/lib/package.conf.d \
  -ghcversion-file=$GHC_SRC/_build/stage1/lib/ghcversion.h \
  -DNO_REGS -DNOSMP -optc-DNOSMP -Wno-deprecated-flags -Wcpp-undef \
  \
  -ddump-stg-final \
  -ddump-cmm -ddump-cmm-cps -ddump-cmm-sp -ddump-cmm-info \
  -ddump-asm \
  -ddump-to-file -ddump-file-prefix="$OUT/" \
  -dno-suppress-uniques

echo
echo "Done.  Dumps in $OUT/"
ls -la "$OUT"/*.dump-* 2>/dev/null | head
