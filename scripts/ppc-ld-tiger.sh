#!/bin/bash
# Link ppc Mach-O on pmacg5 (real Tiger) because ld64-253.9 on uranium
# can't handle the 10.4u SDK's crt1.o / dylib1.o / libgcc_s etc.
# 
# Strategy:
#   - collect input .o / .a / path-referenced files from the args
#   - rsync them to pmacg5:/tmp/ghc-link-$$/
#   - rewrite paths to point at /tmp/ghc-link-$$/
#   - run gcc14 there (which includes a working ppc ld)
#   - scp the output back to the expected path on uranium
#
# We use /opt/gcc14/bin/gcc to drive the link (because it's a working
# native PPC toolchain on Tiger with proper dependency resolution).

set -e
LINK_DIR="/tmp/ghc-link-$$"
OUT=""
REMOTE_ARGS=()
LOCAL_INPUTS=()

# Parse args: collect input files we need to ship, rewrite their paths
i=0
set -- "$@"
while [ $# -gt 0 ]; do
    case "$1" in
        -o)
            OUT="$2"
            REMOTE_ARGS+=("-o" "$LINK_DIR/$(basename "$2")")
            shift 2
            ;;
        *.o|*.a|*.so|*.dylib)
            LOCAL_INPUTS+=("$1")
            REMOTE_ARGS+=("$LINK_DIR/$(basename "$1")")
            shift
            ;;
        -L|-F|-arch|-install_name|-current_version|-compatibility_version|-framework|-u)
            REMOTE_ARGS+=("$1" "$2")
            shift 2
            ;;
        *)
            REMOTE_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ -z "$OUT" ]; then
    echo "ppc-ld-tiger: no -o output specified" >&2
    exit 1
fi

# Prepare remote dir and ship inputs
ssh -q pmacg5 "rm -rf $LINK_DIR && mkdir -p $LINK_DIR"
if [ ${#LOCAL_INPUTS[@]} -gt 0 ]; then
    scp -q "${LOCAL_INPUTS[@]}" "pmacg5:$LINK_DIR/"
fi

# Run on pmacg5.  Add -Wl,-undefined,dynamic_lookup for -dynamiclib cases
# so it doesn't fail on libffi's missing symbols.  (libffi resolves them
# at runtime against the RTS / libSystem.)
EXTRA_FLAGS=""
for a in "${REMOTE_ARGS[@]}"; do
    if [ "$a" = "-dynamiclib" ]; then
        EXTRA_FLAGS="-Wl,-undefined,dynamic_lookup"
        break
    fi
done

ssh -q pmacg5 "/opt/gcc14/bin/gcc ${REMOTE_ARGS[*]} $EXTRA_FLAGS" >&2

# Copy result back
scp -q "pmacg5:$LINK_DIR/$(basename "$OUT")" "$OUT"
ssh -q pmacg5 "rm -rf $LINK_DIR"
