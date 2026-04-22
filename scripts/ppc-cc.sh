#!/bin/bash
# Cross-CC for powerpc-apple-darwin8.
#
# Dispatch rules:
#   * If args have -c / -E / -S / -M / -MM / -MF: compile-only mode,
#     pass through to real clang.
#   * If args look like a probe (-v, --version, --print-*, -###, no
#     input files): pass through to real clang so the probe gets
#     real info.
#   * If args contain ANY .c/.cpp/.cc/.cxx/.m/.mm/.s/.S input and
#     no -c: it's compile-to-link.  Real link on ppc-apple-darwin8
#     isn't possible on uranium (ld64-253.9 can't map the 10.4u SDK
#     crt1.o).  Two options:
#       - Compile each input to .o via clang-with-target
#       - Pretend-link via fake linker
#     For now: write dummy Mach-O header via fake linker.
#   * If args contain .o/.a/.dylib/.so without source inputs: pure
#     link, fake linker.
#   * Otherwise: pass through to real clang.
SDK="$HOME/.local/ghc-ppc-xtools/MacOSX10.4u.sdk"
CLANG="$HOME/.local/ghc-ppc-xtools/clang"

pass_through() {
    exec "$CLANG" -target powerpc-apple-darwin8 -mlinker-version=253.9 \
                  -isysroot "$SDK" "$@"
}

fake_link() {
    exec "$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-fake" "$@"
}

is_compile_only=0
is_probe=0
has_source=0
has_objlike=0

for arg in "$@"; do
    case "$arg" in
        -c|-E|-S|-M|-MM|-MF) is_compile_only=1;;
        -v|--version|-\#\#\#|-print*|--print*|-dumpversion|-dumpmachine) is_probe=1;;
        *.c|*.cc|*.cpp|*.cxx|*.m|*.mm|*.s|*.S) has_source=1;;
        *.o|*.a|*.dylib|*.so) has_objlike=1;;
    esac
done

if [ $is_probe -eq 1 ] || [ $is_compile_only -eq 1 ]; then
    pass_through "$@"
fi

# At this point: not -c, not probe.
# If has source files, this is compile+link.  Fake the link step.
# If has .o/.a files but no source, pure link.  Fake it too.
if [ $has_source -eq 1 ] || [ $has_objlike -eq 1 ]; then
    fake_link "$@"
fi

# No -c, no source, no object, no probe flags?  Pass through (safe
# default).
pass_through "$@"
