#!/bin/bash
# Real ld — uses pmacg5's native PPC ld when possible for relocatable (-r)
# and full link operations. Falls back to local ld64-253.9 for
# non-arch-specific operations.
#
# Hadrian calls this for "MergeObjects" with -r flag.  That concatenates
# .o files into one. Our ld64-253.9 on uranium has a branch-range bug on
# PPC (fires "bl branch out of range" even for -r). Tiger's /opt/gcc14
# ld handles this correctly.

# Route -r (relocatable link) and any other PPC work to pmacg5 via SSH.
LINK_DIR="/tmp/ghc-ld-$$"
OUT=""
LOCAL_INPUTS=()
LOCAL_RENAMES=()
REMOTE_ARGS=()

unique_name() {
    local p="$1"
    p="${p#./}"
    p="${p#_build/}"
    p="${p#/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/}"
    p="${p#_build/}"
    echo "${p//\//__}"
}

is_linkable() {
    case "$1" in
        -*) return 1;;
        *.o|*_o|*.a|*.so|*.dylib) return 0;;
    esac
    return 1
}

set -- "$@"
while [ $# -gt 0 ]; do
    if is_linkable "$1"; then
        u=$(unique_name "$1")
        LOCAL_INPUTS+=("$1")
        LOCAL_RENAMES+=("$u")
        REMOTE_ARGS+=("$LINK_DIR/$u")
        shift
        continue
    fi
    case "$1" in
        -o)
            OUT="$2"
            REMOTE_ARGS+=("-o" "$LINK_DIR/$(basename "$2")")
            shift 2;;
        *)
            REMOTE_ARGS+=("$1")
            shift;;
    esac
done

if [ -z "$OUT" ]; then
    echo "ld-shim: no -o specified" >&2
    exit 1
fi

ssh -q pmacg5 "rm -rf $LINK_DIR && mkdir -p $LINK_DIR"
if [ ${#LOCAL_INPUTS[@]} -gt 0 ]; then
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT
    for idx in "${!LOCAL_INPUTS[@]}"; do
        ln "${LOCAL_INPUTS[$idx]}" "$staging/${LOCAL_RENAMES[$idx]}" 2>/dev/null || \
            cp "${LOCAL_INPUTS[$idx]}" "$staging/${LOCAL_RENAMES[$idx]}"
    done
    rsync -q -a "$staging/" "pmacg5:$LINK_DIR/"
fi

if ! ssh -q pmacg5 "cd $LINK_DIR && /opt/gcc14/bin/ld ${REMOTE_ARGS[*]}" 2>&1; then
    echo "ld-shim: remote /opt/gcc14/bin/ld failed" >&2
    ssh -q pmacg5 "rm -rf $LINK_DIR" >/dev/null 2>&1 || true
    exit 1
fi

scp -q "pmacg5:$LINK_DIR/$(basename "$OUT")" "$OUT" || {
    echo "ld-shim: scp back failed" >&2
    ssh -q pmacg5 "rm -rf $LINK_DIR" >/dev/null 2>&1 || true
    exit 1
}
ssh -q pmacg5 "rm -rf $LINK_DIR" >/dev/null 2>&1
