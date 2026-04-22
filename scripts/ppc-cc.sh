#!/bin/bash
# Cross-CC wrapper for powerpc-apple-darwin8:
# - compile mode: real clang targeting ppc
# - link mode: fake linker (writes dummy Mach-O ppc header) for
#   configure purposes.  Real linking happens on Tiger.
SDK="$HOME/.local/ghc-ppc-xtools/MacOSX10.4u.sdk"
CLANG="$HOME/.local/ghc-ppc-xtools/clang"

# Detect link mode: no -c, -E, -S, -M flag
link_mode=1
for arg in "$@"; do
    case "$arg" in
        -c|-E|-S|-M|-MM) link_mode=0; break;;
    esac
done

if [ $link_mode -eq 1 ]; then
    # Link mode: invoke fake linker
    exec "$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-fake" "$@"
fi

# Compile mode: real clang
exec "$CLANG" -target powerpc-apple-darwin8 -mlinker-version=253.9 -isysroot "$SDK" "$@"
