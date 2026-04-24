#!/bin/bash
SDK="$HOME/.local/ghc-ppc-xtools/MacOSX10.4u.sdk"
CLANG="$HOME/.local/ghc-ppc-xtools/clang"

echo "$(date +%H:%M:%S) ppc-cc: $*" >> /tmp/ppc-cc-trace.log

# Expand @response_file args.  Pass the expanded args to downstream.
all_args=()
for arg in "$@"; do
    if [ "${arg:0:1}" = "@" ]; then
        rsp="${arg#@}"
        if [ -f "$rsp" ]; then
            while IFS= read -r expanded; do
                all_args+=("$expanded")
            done < <(python3 -c "import shlex,sys; print('\n'.join(shlex.split(open(sys.argv[1]).read())))" "$rsp")
            continue
        fi
    fi
    all_args+=("$arg")
done

pass_through() {
    exec "$CLANG" -target powerpc-apple-darwin8 -mlinker-version=253.9 \
                  -mmacosx-version-min=10.4 \
                  -isysroot "$SDK" \
                  -Wno-error \
                  -Wno-unused-value \
                  -Wno-parentheses-equality \
                  -Wno-tautological-compare \
                  -Wno-deprecated-declarations \
                  "${all_args[@]}"
}

tiger_link() {
    exec "$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-tiger" "${all_args[@]}"
}

fake_link() {
    exec "$HOME/.local/ghc-ppc-xtools/bin-wrap/ppc-ld-fake" "${all_args[@]}"
}

is_compile_only=0
is_probe=0
has_source=0
has_objlike=0
is_dynamiclib=0

for arg in "${all_args[@]}"; do
    case "$arg" in
        -c|-E|-S|-M|-MM|-MF) is_compile_only=1;;
        -v|--version|-\#\#\#|-print*|--print*|-dumpversion|-dumpmachine) is_probe=1;;
        *.c|*.cc|*.cpp|*.cxx|*.m|*.mm|*.s|*.S) has_source=1;;
        *.o|*.a|*.dylib|*.so) has_objlike=1;;
        -dynamiclib|-shared) is_dynamiclib=1;;
    esac
done

echo "  $(date +%H:%M:%S) [co=$is_compile_only probe=$is_probe src=$has_source obj=$has_objlike dyn=$is_dynamiclib]" >> /tmp/ppc-cc-trace.log

if [ $is_probe -eq 1 ] || [ $is_compile_only -eq 1 ]; then
    pass_through
fi

if [ $is_dynamiclib -eq 1 ]; then
    tiger_link
fi

if [ $has_source -eq 1 ]; then
    fake_link
fi

if [ $has_objlike -eq 1 ]; then
    fake_link
fi

pass_through
