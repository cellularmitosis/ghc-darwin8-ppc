#!/bin/bash
# Link ppc Mach-O on pmacg5 (real Tiger) because ld64-253.9 on uranium
# can't handle the 10.4u SDK's crt1.o / dylib1.o / libgcc_s etc.
#
# Strategy:
#   1. Parse args: classify into inputs (.o/.a/.dylib), -L dirs,
#      -l<lib> names, -o output, and other flags.
#   2. For each -l<name>, search the local -L dirs for lib<name>.dylib
#      / lib<name>.a and ship it along with the inputs.
#   3. rsync all inputs and library files to pmacg5:/tmp/ghc-link-$$/.
#   4. Run gcc14 there (which includes a working ppc ld).  Paths in
#      args are rewritten to basename-under-$LINK_DIR.
#   5. scp the output back.

set -e
LINK_DIR="/tmp/ghc-link-$$"
OUT=""
REMOTE_ARGS=()
LOCAL_INPUTS=()
LOCAL_LIBDIRS=()
LIB_NAMES=()

is_linkable() {
    case "$1" in
        -*) return 1;;
        *.o|*_o|*.a|*.so|*.dylib) return 0;;
    esac
    return 1
}

# Given a local input path, compute a unique remote basename by
# replacing / with __.  Strips leading ./, _build/, and any absolute
# prefix.
unique_name() {
    local p="$1"
    # Strip common prefixes
    p="${p#./}"
    p="${p#_build/}"
    p="${p#/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/}"
    p="${p#_build/}"
    # Replace / with __
    echo "${p//\//__}"
}

LOCAL_RENAMES=()

i=0
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
            shift 2
            ;;
        -L/Users/*|-L_build/*|-L/tmp/*|-L/var/*|-L/private/*)
            # Local build-tree / install-tree path; strip it (we'll
            # rewrite to $LINK_DIR).  Remember the original dir so we
            # can search for -l libs.
            LOCAL_LIBDIRS+=("${1#-L}")
            shift
            ;;
        -L)
            LOCAL_LIBDIRS+=("$2")
            shift 2
            ;;
        -L*)
            # Heuristic: if the path exists locally on this host AND
            # contains a libHS*.{a,dylib} or libC*.{a,dylib}, treat as
            # a local build-tree path that needs rsyncing.  Otherwise
            # assume it's a system path (/opt/..., /usr/...) that
            # also exists on the remote PPC host.
            ldir="${1#-L}"
            if [ -d "$ldir" ] && ls "$ldir"/lib*.{a,dylib} >/dev/null 2>&1 \
               && ! echo "$ldir" | grep -qE '^(/opt|/usr|/System|/Library)'; then
                LOCAL_LIBDIRS+=("$ldir")
            else
                REMOTE_ARGS+=("$1")
            fi
            shift
            ;;
        -lmingwex)
            # Windows-only library; irrelevant on Darwin.  Drop silently.
            shift
            ;;
        -Wl,-rpath,*|-Wl,-rpath|-rpath)
            # -rpath requires 10.5+, we target 10.4.  Drop.
            if [ "$1" = "-rpath" ] || [ "$1" = "-Wl,-rpath" ]; then
                shift 2
            else
                shift
            fi
            ;;
        -Wl,-dead_strip_dylibs)
            # Harmless but verbose; safe to drop on older ld too.
            shift
            ;;
        -Wl,-headerpad,*|-headerpad)
            # OK on Tiger ld too, keep it
            REMOTE_ARGS+=("$1")
            shift
            ;;
        -Wl,-read_only_relocs,suppress)
            # Tiger ld64-97 accepts this via -Wl,-read_only_relocs=suppress
            # or -Wl,-read_only_relocs,suppress.  Try keeping.
            REMOTE_ARGS+=("$1")
            shift
            ;;
        -l*)
            # Library name.  Remember it; we'll ship the file if found
            # in our LOCAL_LIBDIRS.
            LIB_NAMES+=("${1#-l}")
            REMOTE_ARGS+=("$1")
            shift
            ;;
        -F|-arch|-install_name|-current_version|-compatibility_version|-framework|-u)
            REMOTE_ARGS+=("$1" "$2")
            shift 2
            ;;
        --target=*)
            shift
            ;;
        --target)
            shift 2
            ;;
        -mmacosx-version-min=*)
            shift
            ;;
        -isysroot)
            shift 2
            ;;
        -mlinker-version=*)
            shift
            ;;
        -Qunused-arguments|-mdynamic-no-pic|-fno-use-rpaths)
            shift
            ;;
        -lmingwex)
            shift
            ;;
        *)
            REMOTE_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ -z "$OUT" ]; then
    # No -o: default to a.out (autoconf conftest convention)
    OUT="./a.out"
    REMOTE_ARGS+=("-o" "$LINK_DIR/a.out")
fi

# Always add the remote link dir as a -L path so libraries we ship land there
REMOTE_ARGS+=("-L$LINK_DIR")

# Scan LOCAL_LIBDIRS for each -l<name>, ship matching libs.
# These keep their filenames (no remote-rename) since they're referenced
# by -l<name> which maps to lib<name>.dylib inside the remote -L path.
EXTRA_LIBS=()
for lib in "${LIB_NAMES[@]}"; do
    for dir in "${LOCAL_LIBDIRS[@]}"; do
        for suffix in .dylib .a; do
            cand="$dir/lib${lib}${suffix}"
            if [ -f "$cand" ]; then
                EXTRA_LIBS+=("$cand")
                break 2
            fi
        done
    done
done

# Full command logged for debug
echo "[$(date +%H:%M:%S)] tiger-link -> $OUT" >> /tmp/ppc-ld-tiger-trace.log
echo "  LOCAL_LIBDIRS: ${LOCAL_LIBDIRS[*]}" >> /tmp/ppc-ld-tiger-trace.log
echo "  LIB_NAMES: ${LIB_NAMES[*]}" >> /tmp/ppc-ld-tiger-trace.log
echo "  LOCAL_INPUTS[last 5]: ${LOCAL_INPUTS[@]: -5}" >> /tmp/ppc-ld-tiger-trace.log

# Prepare remote dir
ssh -q pmacg5 "rm -rf $LINK_DIR && mkdir -p $LINK_DIR"

# Ship LOCAL_INPUTS (renamed to unique remote names).  Use tar to
# preserve in one ssh call rather than many scps.
if [ ${#LOCAL_INPUTS[@]} -gt 0 ]; then
    staging=$(mktemp -d)
    trap 'rm -rf "$staging"' EXIT
    for idx in "${!LOCAL_INPUTS[@]}"; do
        ln "${LOCAL_INPUTS[$idx]}" "$staging/${LOCAL_RENAMES[$idx]}" 2>/dev/null || \
            cp "${LOCAL_INPUTS[$idx]}" "$staging/${LOCAL_RENAMES[$idx]}"
    done
    # Use rsync for speed (one connection)
    rsync -q -a "$staging/" "pmacg5:$LINK_DIR/"
fi

# Ship extra libs (keep their original name so -l<name> resolution works)
if [ ${#EXTRA_LIBS[@]} -gt 0 ]; then
    scp -q "${EXTRA_LIBS[@]}" "pmacg5:$LINK_DIR/"
fi

# Run on pmacg5.  Add -Wl,-undefined,dynamic_lookup ONLY when
# linking libffi.*.dylib (libffi has unresolvable ffi_call_go_AIX
# and mkostemp symbols that we defer to runtime).  For all other
# dylibs, use the default (libSystem linked automatically), which
# lets the linker produce proper picsymbol stubs for libSystem
# functions like memcmp.  Using -undefined dynamic_lookup for all
# dylibs on PPC triggers "bl branch out of range" errors because
# the linker skips stub allocation for dynamic-lookup symbols.
EXTRA_FLAGS=""
case "$OUT" in
    *libffi*)
        for a in "${REMOTE_ARGS[@]}"; do
            if [ "$a" = "-dynamiclib" ]; then
                EXTRA_FLAGS="-Wl,-undefined,dynamic_lookup"
                break
            fi
        done
        ;;
esac

# Always link against libiconv on Darwin (base uses libiconv-prefixed API
# names: libiconv, libiconv_open, libiconv_close, locale_charset).  These
# are in /usr/lib/libiconv.dylib on Tiger.
EXTRA_FLAGS="$EXTRA_FLAGS -liconv"

# gmp lives at /opt/gmp-6.2.1 on pmacg5 (Tigerbrew bottle), not in gcc14's
# default search path.  Add it for ghc-bignum-using executables.
EXTRA_FLAGS="$EXTRA_FLAGS -L/opt/gmp-6.2.1/lib"

echo "  ssh pmacg5 '/opt/gcc14/bin/gcc ${REMOTE_ARGS[*]} $EXTRA_FLAGS'" >> /tmp/ppc-ld-tiger-trace.log

if ! ssh -q pmacg5 "cd $LINK_DIR && /opt/gcc14/bin/gcc ${REMOTE_ARGS[*]} $EXTRA_FLAGS" 2>&1; then
    echo "ppc-ld-tiger: remote gcc failed on pmacg5 (LINK_DIR=$LINK_DIR)" >&2
    ssh -q pmacg5 "rm -rf $LINK_DIR" >/dev/null 2>&1 || true
    exit 1
fi

# Copy result back
scp -q "pmacg5:$LINK_DIR/$(basename "$OUT")" "$OUT" || {
    echo "ppc-ld-tiger: scp failed for $OUT" >&2
    ssh -q pmacg5 "rm -rf $LINK_DIR" >/dev/null 2>&1 || true
    exit 1
}
ssh -q pmacg5 "rm -rf $LINK_DIR" >/dev/null 2>&1
