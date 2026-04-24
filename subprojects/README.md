# Subprojects

| Slug | Status | One-line |
|------|--------|----------|
| [stage1-cross](stage1-cross/) | ✅ done | arm64 host → PPC Mach-O cross-compile. Hello/Fib/stdin verified on Tiger. |
| [test-battery](test-battery/) | ✅ initial pass done | 25 programs. 20 PASS byte-identical; 1 real bug (`pi`). |
| [stage2-native](stage2-native/) | ⏸ deferred | ppc-native `ghc` binary runs `--version` but can't compile — tcl_env empty. |
| [bug-pi-double-literal](bug-pi-double-literal/) | 🔜 next | `pi :: Double` returns `8.6e97`. 19-digit literal truncation in `.hc` codegen. |
| [bindist-installer](bindist-installer/) | 📋 planned | Package + install script that rewrites `lib/settings` paths. |
| [ghci-macho-loader](ghci-macho-loader/) | 📋 planned | Restore `relocateSection` for PPC to get GHCi / TemplateHaskell. |

## Ordering

Rough dependency chain:
- `stage1-cross` unblocks everything else.
- `bug-pi-double-literal` is independent; fix any time.
- `bindist-installer` depends on `stage1-cross` being stable; can land now.
- `test-battery` keeps evolving as we find more classes of bugs.
- `stage2-native` and `ghci-macho-loader` are both stretch goals with unknown
  time to completion.  Neither blocks the other.
