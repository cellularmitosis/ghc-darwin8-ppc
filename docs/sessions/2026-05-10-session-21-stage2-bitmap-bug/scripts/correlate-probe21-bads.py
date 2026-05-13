#!/usr/bin/env python3
"""For a PROBE21 log, attribute BAD-pay-N events to specific info tables.

Walks the log line by line. PROBE21FRAME line records the current frame's
info= and bitmap_raw=. Subsequent PROBE21BAD lines (until next FRAME) are
attributed to that frame.

Usage:
  python3 correlate-probe21-bads.py docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/logs/probe20-iter1-vanilla-A1m.log
"""
import re, sys
from collections import Counter

if len(sys.argv) < 2:
    print(__doc__); sys.exit(2)
LOG = sys.argv[1]
PAY_FILTER = int(sys.argv[2]) if len(sys.argv) > 2 else None

frame_info = None
counter = Counter()
all_pays = Counter()

with open(LOG) as f:
    for line in f:
        if 'PROBE21FRAME' in line:
            m = re.search(r'info=(0x[0-9a-fA-F]+) bitmap_raw=(0x[0-9a-fA-F]+) size=(\d+) bits=(0x[0-9a-fA-F]+)', line)
            if m:
                frame_info = m.group(1)
                frame_bitmap_raw = m.group(2)
                frame_size = int(m.group(3))
                frame_bits = int(m.group(4), 16)
        elif 'PROBE21BAD' in line:
            m = re.search(r'pay=(\d+)', line)
            if m and frame_info:
                pay = int(m.group(1))
                all_pays[pay] += 1
                if PAY_FILTER is None or pay == PAY_FILTER:
                    counter[(frame_info, frame_bitmap_raw, frame_size, frame_bits)] += 1

print(f"Total BAD events by pay= position: {dict(all_pays.most_common())}")
print()
filt = f"pay={PAY_FILTER}" if PAY_FILTER is not None else "all pays"
print(f"Top info tables for BAD ({filt}):")
print(f"{'info':<14} {'bitmap':<10} {'size':>4} {'bits':<8} {'count':>5}  pat")
for (info, raw, sz, bits), c in counter.most_common(20):
    pat = ''.join('P' if (bits >> i) & 1 == 0 else 'N' for i in range(sz))
    print(f"{info:<14} {raw:<10} {sz:>4} {hex(bits):<8} {c:>5}  pat={pat}")
