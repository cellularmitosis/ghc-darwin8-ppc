import re, sys

dump = open('log/session21/catch-cross/catch-O2.dump').read()

# Find each "block_cXXX_info" with rep StackRep [False, True, False] AND its body
# Body is the immediately following block.
# Extract _blk_NAME() {{ ... }} that contains rep: StackRep [False, True, False]

# Approach: split on _blk_ definitions
pattern = re.compile(r'_blk_(\w+)\(\)[^{]*\{[^}]*?info_tbls:\s*\[\((\w+),\s*label:\s*block_(\w+)_info\s*rep:\s*StackRep\s*\[([^\]]+)\][^]]*\)\]\s*stack_info:\s*arg_space:\s*\d+\s*\}\s*\{offset(.*?)\n\s*\}\s*\}', re.DOTALL)

count = 0
for m in pattern.finditer(dump):
    blk_name, label, info_label, stackrep, body = m.groups()
    if stackrep.strip() != "False, True, False":
        continue
    count += 1
    print(f"=== Frame {count}: _blk_{blk_name} (info=block_{info_label}_info) StackRep [{stackrep}]")
    # Search body for Sp+8 reads (RHS) and writes (LHS)
    for line in body.split('\n'):
        line = line.strip()
        if not line: continue
        # Match "= ... [Sp + 8] ..." (read on RHS) OR "= P32[Sp + 8]" 
        # Match "P32[Sp + 8] = ..." or "I32[Sp + 8] = ..." (write on LHS)
        if re.search(r'(?:P32|I32|F32|W32|\bp\b)\s*\[\s*Sp\s*\+\s*8\s*\]', line):
            print(f"   {line}")
        elif 'Sp +' in line:
            # Show all Sp-relative things for context
            pass
    print()
print(f"Total [F,T,F] frames found: {count}")
