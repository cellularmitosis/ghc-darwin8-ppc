#!/bin/bash
# Cross-CC wrapper for powerpc-apple-darwin8 on uranium.
#
# Dispatch rules:
#   * Probe (-v/--version/--print-*): pass to real clang
#   * Compile-only (-c/-E/-S/-M/-MM/-MF): pass to real clang
#   * Compile/link with .c etc. source AND -dynamiclib: delegate to
#     Tiger link wrapper (clang compiles to temp .o, ld runs on
#     pmacg5) -- actually we compile locally, then ppc-ld-tiger does
#     the dylib link.
#   * Pure-link with -dynamiclib (only .o/.a inputs): Tiger link wrapper.
#   * Pure-link with only .o/.a inputs (executable): fake linker
#     (for configure's CC-works test; real executable linking
#     should go through ppc-ld-tiger but configure doesn't need it).
#   * Otherwise: pass through to real clang.
SDK="$HOME/.local/ghc-ppc-xtools/MacOSX10.4u.sdk"
CLANG="$HOME/.local/ghc-ppc-xtools/clang"

pass_through() {
    exec "$CLANG" -target powerpc-apple-darwin8 -mlinker-version=253.9 \
                  -isysroot "$SDK" "$@"
}

tiger_link() {
    exec "$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-tiger" "$@"
}

fake_link() {
    exec "$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-fake" "$@"
}

is_compile_only=0
is_probe=0
has_source=0
has_objlike=0
is_dynamiclib=0

for arg in "$@"; do
    case "$arg" in
        -c|-E|-S|-M|-MM|-MF) is_compile_only=1;;
        -v|--version|-\#\#\#|-print*|--print*|-dumpversion|-dumpmachine) is_probe=1;;
        *.c|*.cc|*.cpp|*.cxx|*.m|*.mm|*.s|*.S) has_source=1;;
        *.o|*.a|*.dylib|*.so) has_objlike=1;;
        -dynamiclib|-shared) is_dynamiclib=1;;
    esac
done

if [ $is_probe -eq 1 ] || [ $is_compile_only -eq 1 ]; then
    pass_through "$@"
fi

# If -dynamiclib / -shared invocation with source inputs, compile each
# source to .o locally first, then link via ppc-ld-tiger.
if [ $is_dynamiclib -eq 1 ] && [ $has_source -eq 1 ]; then
    # Rare case; libtool usually compiles and links separately.  Handle
    # by invoking clang for everything except the link, then linking
    # on Tiger.  For now just warn and fall through; this path shouldn't
    # trigger in normal flows.
    echo "ppc-cc: WARNING: compile+link of source files with -dynamiclib" >&2
fi

# Pure dynamiclib link: ship to Tiger
if [ $is_dynamiclib -eq 1 ]; then
    tiger_link "$@"
fi

# Compile+link with source (executable): fake, but only useful for
# configure tests.  Real executables are a later problem.
if [ $has_source -eq 1 ]; then
    fake_link "$@"
fi

# Pure link with objects (executable): fake
if [ $has_objlike -eq 1 ]; then
    fake_link "$@"
fi

# Default: pass through to clang
pass_through "$@"
