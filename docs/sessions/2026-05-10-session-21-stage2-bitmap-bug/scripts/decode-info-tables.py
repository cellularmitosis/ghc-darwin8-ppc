#!/usr/bin/env python3
"""Decode all RET_SMALL info-table bitmap words from a PPC32 unreg-C cross-build .o.

PPC32 layout (no TABLES_NEXT_TO_CODE, no PROFILING):
  StgFunPtr     entry      (4 bytes)
  StgClosureInfo layout    (4 bytes — bitmap word for RET_SMALL)
  StgHalfWord   type       (2 bytes — 30 = RET_SMALL)
  StgSRTField   srt        (2 bytes)

bitmap encoding (PPC32, SIZEOF_VOID_P=4 → BITMAP_BITS_SHIFT=5, BITMAP_SIZE_MASK=0x1F):
  size = layout & 0x1F
  bits = layout >> 5
  bit i == 1  →  slot i is NON-pointer (don't evacuate)
  bit i == 0  →  slot i IS pointer (evacuate)

Usage:
  python3 decode-info-tables.py path/to/Module.o [--filter-pnp]
"""

import struct, subprocess, re, sys
from collections import Counter

NM = "/Users/cell/.local/cctools-ppc/install/bin/powerpc-apple-darwin8-nm"
OTOOL = "/Users/cell/.local/cctools-ppc/install/bin/powerpc-apple-darwin8-otool"

SHIFT = 5
SIZE_MASK = 0x1F

def get_const_data_section(obj):
    out = subprocess.check_output([OTOOL, "-l", obj]).decode()
    sections = re.findall(
        r'sectname (\S+)\n.*?segname (\S+)\n.*?addr (\S+)\n.*?size (\S+)\n.*?offset (\d+)',
        out, re.DOTALL)
    for sn, sg, addr, size, off in sections:
        if sn == "__const" and sg == "__DATA":
            return int(addr, 16), int(off), int(size, 16)
    return None

def main(obj, filter_pnp=False):
    sa, so, sz = get_const_data_section(obj)
    with open(obj, "rb") as f:
        f.seek(so); sect = f.read(sz)
    nm = subprocess.check_output([NM, obj]).decode()
    syms = []
    for line in nm.splitlines():
        parts = line.split()
        if len(parts) < 3 or not parts[2].endswith("_info"): continue
        try: addr = int(parts[0], 16)
        except: continue
        if sa <= addr < sa + sz:
            syms.append((addr, parts[2]))
    syms.sort()

    counts = Counter()
    for addr, name in syms:
        off = addr - sa
        if off+12 > sz: continue
        e = struct.unpack(">I", sect[off:off+4])[0]
        lay = struct.unpack(">I", sect[off+4:off+8])[0]
        tp = struct.unpack(">H", sect[off+8:off+10])[0]
        if tp != 30: continue
        size = lay & SIZE_MASK
        bits = lay >> SHIFT
        pat = ''.join('P' if (bits >> i) & 1 == 0 else 'N' for i in range(size))
        if filter_pnp and pat not in ('PN', 'PNP'):
            continue
        print(f"{addr:08x} {name:<16} layout={hex(lay):>8} size={size:>2} bits={hex(bits):>6} {pat}")
        counts[(size, bits)] += 1
    print()
    print("(size, bits) frequency:")
    for (s, b), c in counts.most_common(20):
        pat = ''.join('P' if (b >> i) & 1 == 0 else 'N' for i in range(s))
        print(f"  size={s:2} bits={hex(b):>6}  count={c:3}   pat={pat}")

if __name__ == "__main__":
    obj = sys.argv[1]
    filter_pnp = "--filter-pnp" in sys.argv[2:]
    main(obj, filter_pnp)
