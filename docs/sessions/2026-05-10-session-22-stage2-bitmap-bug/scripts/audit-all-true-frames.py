"""Audit every block-StackRep with at least one True in catch-cross dump."""
import re

dump = open('log/session21/catch-cross/catch-O2.dump').read()

pattern = re.compile(
    r'_blk_(\w+)\(\)[^{]*\{[^}]*?info_tbls:\s*\[\((\w+),\s*label:\s*block_(\w+)_info\s*'
    r'rep:\s*StackRep\s*\[([^\]]+)\][^]]*\)\]\s*stack_info:\s*arg_space:\s*\d+\s*\}\s*'
    r'\{offset(.*?)\n\s*\}\s*\}',
    re.DOTALL)

count = 0
for m in pattern.finditer(dump):
    blk, label, info, sr, body = m.groups()
    if 'True' not in sr:
        continue
    bools = [b.strip() for b in sr.split(',')]
    # slot index where True appears
    true_slots = [i for i, b in enumerate(bools) if b == 'True']
    count += 1
    print(f"=== {blk} info=block_{info}_info {sr}  T-slots={true_slots}")
    # For each true-slot index, slot i = Sp + 4*(i+1) = Sp + (4i+4)
    for tsi in true_slots:
        byte_off = 4 * (tsi + 1)
        # Match reads of Sp+byte_off (RHS reference)
        for line in body.split('\n'):
            line = line.strip()
            if not line:
                continue
            m_rhs = re.search(r'=\s.*(?:P32|I32|F32|W32)\s*\[\s*Sp\s*\+\s*' + str(byte_off) + r'\s*\]', line)
            m_lhs = re.search(r'^\s*(?:P32|I32|F32|W32)\s*\[\s*Sp\s*\+\s*' + str(byte_off) + r'\s*\]\s*=', line)
            if m_lhs:
                print(f"   slot{tsi}@Sp+{byte_off} WRITE: {line}")
            elif m_rhs:
                print(f"   slot{tsi}@Sp+{byte_off} READ:  {line}")
    print()
print(f"Total True-containing frames: {count}")
