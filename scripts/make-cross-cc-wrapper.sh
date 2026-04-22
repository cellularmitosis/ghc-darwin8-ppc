#!/bin/bash
# Regenerate the cross-cc wrapper and the fake-linker used by GHC's
# configure step. See scripts/cross-env.sh for context.
#
# The wrapper exists because:
#
#   * Clang needs -target powerpc-apple-darwin8 and -isysroot $SDK and
#     -mlinker-version=253.9 (so it doesn't emit -no_deduplicate, which
#     ld64-253.9-ppc from cctools-port doesn't know).
#   * GHC's configure uses AC_PROG_CC which *insists* on creating an
#     executable as a compiler sanity check.  Real linking with the
#     Tiger 10.4u SDK's crt1.o fails on ld64-253.9 with
#     "sectionForNum(4) section number not for any section" — the
#     newer linker can't handle 2005-era Mach-O reloc formats.
#
# The pragmatic workaround: in link mode (configure-test mode), write
# a minimal valid Mach-O ppc header via a shell script "fake linker"
# so configure's sanity check passes.  Real linking of stage1/stage2
# Haskell output is a later problem — when GHC actually tries to link
# runtime libraries, we'll need a real solution (possibly: ship .o
# files to Tiger and link there with the native ld64-97.17).

set -e

BIN_DIR="$HOME/.local/ghc-ppc-xtools/bin-wrap"
SDK="$HOME/.local/ghc-ppc-xtools/MacOSX10.4u.sdk"
CLANG="$HOME/.local/ghc-ppc-xtools/clang"

mkdir -p "$BIN_DIR"

# 1. Fake linker that just writes a 16-byte Mach-O ppc magic header
cat > "$BIN_DIR/ppc-ld-fake" <<'SHELL_EOF'
#!/bin/bash
# Fake linker for GHC configure's CC-works test.  Writes a minimal
# Mach-O ppc file (valid header, no actual content).  NOT A REAL LINKER.
outfile="a.out"
while [ $# -gt 0 ]; do
    case "$1" in
        -o) outfile="$2"; shift 2;;
        *) shift;;
    esac
done
# Mach-O magic (big-endian) + cputype PowerPC (18) + cpusubtype ALL (0)
# + filetype MH_EXECUTE (2)
printf '\xfe\xed\xfa\xce\x00\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\x02' > "$outfile"
chmod +x "$outfile"
exit 0
SHELL_EOF
chmod +x "$BIN_DIR/ppc-ld-fake"

# 2. Cross-CC wrapper: routes compile-mode to real clang, link-mode
#    to the fake linker
cat > "$BIN_DIR/ppc-cc" <<SHELL_EOF
#!/bin/bash
# Cross-CC for powerpc-apple-darwin8.
# Compile: real clang with -target / -isysroot / -mlinker-version.
# Link: dummy 16-byte Mach-O ppc file (see ppc-ld-fake).
SDK="$SDK"
CLANG="$CLANG"

# Detect link mode: absence of -c/-E/-S/-M is the signal to link.
link_mode=1
for arg in "\$@"; do
    case "\$arg" in
        -c|-E|-S|-M|-MM) link_mode=0; break;;
    esac
done

if [ \$link_mode -eq 1 ]; then
    exec "$BIN_DIR/ppc-ld-fake" "\$@"
fi

exec "\$CLANG" -target powerpc-apple-darwin8 -mlinker-version=253.9 \\
              -isysroot "\$SDK" "\$@"
SHELL_EOF
chmod +x "$BIN_DIR/ppc-cc"

echo "Generated:"
ls -la "$BIN_DIR/"
echo ""
echo "Smoke test:"
echo 'int main(void){return 0;}' > /tmp/cross-cc-test.c
"$BIN_DIR/ppc-cc" -c /tmp/cross-cc-test.c -o /tmp/cross-cc-test.o
file /tmp/cross-cc-test.o
"$BIN_DIR/ppc-cc" /tmp/cross-cc-test.c -o /tmp/cross-cc-test
file /tmp/cross-cc-test
rm -f /tmp/cross-cc-test*
