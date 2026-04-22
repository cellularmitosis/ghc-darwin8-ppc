#!/bin/bash
# Fake linker for configure tests.  Writes an empty but valid output file so
# autoconf's AC_PROG_CC link check succeeds.  Not a real linker -- will fail
# for anything nontrivial.  Replace with real ld before production use.
outfile="a.out"
while [ $# -gt 0 ]; do
    case "$1" in
        -o) outfile="$2"; shift 2;;
        *) shift;;
    esac
done
echo -ne "\xfe\xed\xfa\xce\x00\x00\x00\x12\x00\x00\x00\x00\x00\x00\x00\x02" > "$outfile"
chmod +x "$outfile"
exit 0
