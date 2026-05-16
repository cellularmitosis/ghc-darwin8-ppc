#!/bin/bash
# v0.15.0 demo: ghc-pkg works natively on Tiger PPC.
#
# Pre-v0.15.0 the deployed stage2 didn't include a working ghc-pkg
# — the cross-build produced the host arm64 binary verbatim (same
# packaging-bug shape as v0.14.1's unlit fix; patch 0010's cross-mode
# carve-out only excluded iserv and unlit).  v0.15.0 amends patch
# 0010 to add `ghcPkg`, `hsc2hs`, `hp2ps` to the carve-out, and
# `deploy-stage2.sh` now also ships ghc-pkg to /opt/ghc-stage2/bin/.
#
# Usage: ./demos/v0.15.0-ghc-pkg.sh [SSH_HOST]   (default: pmacg5)

set -euo pipefail
HOST="${1:-pmacg5}"

run() {
  echo
  echo "==> $HOST: $1"
  ssh -e none "$HOST" "DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib $1"
}

run "/opt/ghc-stage2/bin/ghc-pkg --version"
run "/opt/ghc-stage2/bin/ghc-pkg list | head -25"
run "/opt/ghc-stage2/bin/ghc-pkg latest base"
run "/opt/ghc-stage2/bin/ghc-pkg field base version"
run "/opt/ghc-stage2/bin/ghc-pkg field transformers id"

echo
echo "All ghc-pkg subcommands ran natively on the PowerMac G5 under Tiger."
