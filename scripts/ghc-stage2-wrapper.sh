#!/bin/bash
# ghc-stage2-wrapper.sh
#
# Launcher for the stage2 native ghc binary on Tiger PPC.
#
# Workaround for the PPC-Darwin RTS GC bug investigated in session 17
# (docs/sessions/2026-04-29-session-17-stage2-O0-experiment/).  Garbage
# collection corrupts compiler state -- the typechecker/renamer's
# `Bag`-based binding store loses entries after the first major GC.
#
# `-A1G` pre-allocates 1GB so most user-program compiles never collect.
# That side-steps the bug for the common cases.
#
# Override by exporting GHCRTS yourself, e.g. for very large compiles:
#
#     GHCRTS='-A4G -H4G' ghc Big.hs -o big
#
# Tiger PowerMac G5 has up to 8GB RAM; -A1G is comfortable.  G3/G4
# machines with less RAM can lower this -- the threshold for losing
# bindings is ~-A128m for trivial single-binding modules and grows
# with module/import size.
#
# Long-term: fix the actual GC bug.  See session 17 docs.

# Usage: install at <prefix>/bin/ghc and rename real ghc binary to
# <prefix>/bin/ghc-real.  Adjust the path below as needed.

GHC_REAL="$(dirname "$0")/ghc-real"

if [ ! -x "$GHC_REAL" ]; then
    echo "ghc-stage2-wrapper: real ghc binary not found at $GHC_REAL" >&2
    exit 127
fi

exec "$GHC_REAL" "$@" +RTS -A1G -RTS
