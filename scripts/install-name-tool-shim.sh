#!/bin/bash
# install_name_tool shim: routes to pmacg5 via SSH when target is ppc Mach-O
# (host install_name_tool fails with "malformed load command" on PPC binaries).
# Transparent passthrough otherwise.

# Find the first non-flag argument (should be the target file)
target=""
prev=""
for arg in "$@"; do
    case "$prev" in
        -id|-change|-rpath|-add_rpath|-delete_rpath) prev="" ;;
        *)
            case "$arg" in
                -*) ;;
                *) [ -z "$target" ] && target="$arg" ;;
            esac
            prev="$arg"
            ;;
    esac
done

# If target is a PPC Mach-O, route to Tiger
if [ -n "$target" ] && [ -f "$target" ]; then
    arch=$(/usr/bin/file "$target" 2>/dev/null | head -1)
    case "$arch" in
        *Mach-O*ppc*)
            # Route to pmacg5
            TMPDIR="/tmp/install-name-tool-$$"
            ssh -q pmacg5 "mkdir -p $TMPDIR"
            scp -q "$target" "pmacg5:$TMPDIR/$(basename "$target")"
            # Rewrite args: replace target with remote path
            new_args=()
            found_target=0
            for arg in "$@"; do
                if [ "$arg" = "$target" ] && [ $found_target -eq 0 ]; then
                    new_args+=("$TMPDIR/$(basename "$target")")
                    found_target=1
                else
                    new_args+=("$arg")
                fi
            done
            ssh -q pmacg5 "/opt/gcc14/bin/install_name_tool ${new_args[*]}"
            rc=$?
            if [ $rc -eq 0 ]; then
                scp -q "pmacg5:$TMPDIR/$(basename "$target")" "$target"
            fi
            ssh -q pmacg5 "rm -rf $TMPDIR"
            exit $rc
            ;;
    esac
fi

# Fall through to host install_name_tool
exec /usr/bin/install_name_tool "$@"
