#!/bin/bash
# ghc-stage2-wrapper.sh
#
# Launcher for the stage2 native ghc binary on Tiger PPC.
#
# In v0.11.0/v0.12.0 this wrapper added `+RTS -A1G -RTS` to dodge an
# unidentified GC bug -- a major collection during a compile would
# truncate the typechecker's binding bag and the compiler would emit
# empty `.o` files or panic on `refineFromInScope`.  Investigated
# across sessions 17-52.
#
# Session 52 (2026-05-15) found and fixed the root cause: it was
# never an RTS GC bug, it was a single 11-line big-endian-only bug
# in `libraries/array/Data/Array/Base.hs`'s `STUArray Bool` `newArray`
# (allocate `bOOL_SCALE n = ceil(n/8)` bytes via `setByteArray#` but
# read full machine words via `readWordArray#` -- on BE the trailing
# partial-word bytes go uninitialised and `Data.Graph.scc`'s visited
# set is corrupt, which makes the renamer drop bindings).  Fixed by
# `patches/0016-array-stuarray-bool-word-aligned-init.patch`,
# shipping in v0.13.0.
#
# As of v0.13.0 this wrapper no longer needs to force `-A1G`.  It's
# kept for backwards compatibility with existing /opt/ghc-stage2/
# layouts -- `scripts/deploy-stage2.sh` still installs it as
# /opt/ghc-stage2/bin/ghc and the real binary as /opt/ghc-stage2/
# bin/ghc-real.  If you want the old -A1G behaviour for some reason
# (very large compiles benefit from a big nursery), set GHCRTS.

GHC_REAL="$(dirname "$0")/ghc-real"

if [ ! -x "$GHC_REAL" ]; then
    echo "ghc-stage2-wrapper: real ghc binary not found at $GHC_REAL" >&2
    exit 127
fi

exec "$GHC_REAL" "$@"
