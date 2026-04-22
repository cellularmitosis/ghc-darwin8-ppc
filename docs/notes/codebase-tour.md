# GHC 8.6.5 codebase tour — what touches PowerPC/Darwin

The last release with PowerPC/Darwin support is **GHC 8.6.5**
(release 2019-04-23; HEAD `92b6a0237e0195cee4773de4b237951addd659d9`
on `ghc-8.6.5-release` tag in the gitlab.haskell.org tree). Removal
commit `374e44704b` was authored on 2018-12-30 against master and
landed for the 8.8.1 release. So the layout below is what 8.6.5
ships — every line of the removal commit applies cleanly to it.

The local clone is at [`external/ghc-8.6.5/`](../../external/ghc-8.6.5/).

This tour catalogs **where the PPC/Darwin code lives**, how big each
piece is in 8.6.5, and what role it plays. Use it to prioritize
study, and as the source-of-truth-mapping when forward-porting to a
modern GHC (file paths have moved; see
[file-mapping-86-vs-modern.md](file-mapping-86-vs-modern.md)).

## Compiler — native code generator

The Haskell side that emits PowerPC assembly. Lives in
`compiler/nativeGen/PPC/`. As of 8.6.5:

```
compiler/nativeGen/PPC/
  CodeGen.hs   2443 lines  — Cmm -> PPC instruction selection
  Cond.hs       ~50 lines  — condition codes
  Instr.hs    ~1350 lines  — PPC instruction representation
  Ppr.hs      1083 lines   — PPC instruction pretty-printer (asm syntax)
  RegInfo.hs   ~80 lines   — small reg-related helpers
  Regs.hs     ~600 lines   — PPC register classes / allocator hooks
```

PPC/Darwin-specific pieces inside these (per `git grep` against 8.6.5):

- **`PPC/CodeGen.hs`**: a `GenCCallPlatform` ADT with
  `GCPLinux | GCPDarwin | GCPLinux64ELF !Int | GCPAIX`; the call
  generator branches on this in `genCCall'`. The Darwin arm of the
  branch implements the PowerOpen-derived Mac OS X PPC ABI:
    - 24-byte linkage area at the top of every stack frame
    - Reserve parameter stack space even for register-passed args
    - When a float arg goes to FPR, advance GPR cursor too
    - I64 → two I32 halves (high word first), 4-byte aligned
  These rules are documented in a long comment block at lines
  ~1578-1602. They map directly to Apple's
  *"Mac OS X ABI Function Call Guide"*, PowerPC chapter.

- **`PPC/Ppr.hs`**: `pprGotDeclaration`, `pprImportedSymbol`,
  Mach-O section names (`__TEXT,__text`, `__DATA,__data`,
  `__TEXT,__picsymbolstub1`, `__DATA,__la_symbol_ptr`), Darwin
  asm syntax for `LO`/`HI`/`HA` operand modifiers (`@l`, `@h`,
  `@ha` differ between Darwin's as and GNU as), and the lazy /
  non-lazy pointer stub emission used for dyld lazy binding.

- **`PIC.hs`** (one level up at `compiler/nativeGen/PIC.hs`):
  Position-independent code emission. PPC/Darwin specifics:
    - `howToAccessLabel ... OSDarwin ...` — picks DataReference vs
      JumpReference vs symbol-stub strategy
    - `pprImportedSymbol` for `ArchPPC, OSDarwin` (line 572) —
      emits the `__picsymbolstub1` thunks
    - `initializePicBase_ppc ArchPPC OSDarwin` (line 831) — emits
      `bcl 20,31,1f; 1: mflr <picReg>` to load the PIC base into
      the chosen register, since PPC has no equivalent of x86's
      `call .+5; pop %eax`. The branch link is a known "PPC trick"
      that some processors handle specially in their branch
      predictor.

- **`PPC/Regs.hs`** and **`PPC/Instr.hs`**: small Darwin-specific
  carve-outs around register conventions and stack-frame size.
  `Instr.hs` line ~602 has a comment "This is 16 both on PPC32 and
  PPC64 at least for Darwin, and Linux (see ELF processor specific
  supplements)" — even where Darwin and Linux agree, the conditions
  are tracked separately.

## Compiler — STG / register dispatch

The "platform" abstraction that picks register conventions for the
abstract STG machine on each target.

- **`compiler/codeGen/CodeGen/Platform.hs`** — top-level dispatch
  table. Has a special case `(ArchPPC, OSDarwin) -> PPC_Darwin.foo`
  versus the generic `PPC.foo` for non-Darwin PPC. Five entries:
  `callerSaves`, `activeStgRegs`, `haveRegBase`, `globalRegMaybe`,
  `freeReg`.

- **`compiler/codeGen/CodeGen/Platform/PPC_Darwin.hs`** — 11 lines,
  a CPP shim over `includes/CodeGen.Platform.hs`:

  ```haskell
  module CodeGen.Platform.PPC_Darwin where
  import GhcPrelude
  #define MACHREGS_NO_REGS 0
  #define MACHREGS_powerpc 1
  #define MACHREGS_darwin 1
  #include "../../../../includes/CodeGen.Platform.hs"
  ```

  This single file is **deleted outright** by 374e44704b. It exists
  precisely because PPC/Darwin's STG-register layout differs from
  PPC/Linux's. Restoring it is the first patch in the NCG revival.

- **`compiler/cmm/CmmPipeline.hs`** — Cmm-pass scheduling. PPC/Darwin
  is special because (like x86/Darwin) it needs proc-points split
  before PIC-base insertion. Removal commit removed the
  `(ArchPPC, OSDarwin, pic) -> pic` line from `usingInconsistentPicReg`.

- **`compiler/ghc.cabal.in`** — the Haskell module list. Just the
  one line referencing `CodeGen.Platform.PPC_Darwin` to remove/restore.

## Includes (CPP-shared between compiler and RTS)

- **`includes/stg/MachRegs.h`** — the master STG-register → real-PPC-register
  map. PPC/Darwin block (line 213+ in 8.6.5):

  ```c
  # if defined(MACHREGS_darwin)
  ... darwin-specific reservations of r2/r13 ...
  # endif
  ```

  Non-Darwin PPC OSes use r2 as TOC (AIX) or for thread-local-storage
  (Linux uses r13 for TLS). Darwin uses neither, so r2 and r13 can
  be used as STG registers — which is the whole point of having a
  separate platform table.

- **`includes/CodeGen.Platform.hs`** — the CPP-driven body that the
  compiler-side `CodeGen.Platform.PPC*` modules `#include`. Same
  content as `MachRegs.h` rules but as Haskell. Comments include
  *"most non-darwin powerpc OSes use r2 as a TOC pointer or
  something like that"* — a one-line summary of the whole problem.

## RTS — runtime system

The C/asm runtime that GHC-compiled programs link against. **This
is the bulkier half of the work** (~600 of the 711 deleted lines
live here):

### `rts/StgCRun.c`  (~1049 lines, 40 deleted by 374e447)

The C ↔ STG-machine context switch. `StgRun()` saves the C
caller-saved registers, jumps into STG code; `StgReturn` is the
inverse. Handwritten asm per architecture. Lines 621-680ish have a
PPC block; the Darwin branch is gated on `darwin_HOST_OS` and uses
PPC-Darwin assembler syntax (e.g. `lwz r3, 8(r1)` rather than
`lwz 3, 8(1)`; mnemonic register names rather than bare numbers).

Note from the source: "Differences from the Darwin/Mac OS X version:
no Red Zone as in the Darwin ABI, Linux: 4(r1), Darwin 8(r1)" —
documents that the Darwin frame layout (saved LR at offset 8(r1),
back chain at 0(r1)) differs from Linux's (saved LR at offset 4(r1)
in the SVR4 ABI). A real ABI difference, not just a syntax difference.

### `rts/Adjustor.c`  (~1324 lines, 32 deleted)

The C side of FFI callback "adjustors" — when Haskell hands a
function pointer back to C and C calls it, the adjustor is the
runtime-allocated thunk that bridges the call. Under
`#if defined(powerpc_HOST_ARCH) && defined(darwin_HOST_OS)` (line
290) sits the Darwin-specific allocation and trampoline-emission
code. Note: Darwin's PPC FFI uses function descriptors (a
"fundesc"), comment at line 298 says "powerpc64-darwin: just
guessing that it won't use fundescs" — this is the kind of "we
never actually tested it" code Trommler warned about.

### `rts/AdjustorAsm.S`  (~202 lines, 102 deleted)

The assembler half of the adjustor. Has separate PPC32-Darwin and
PPC32-Linux blocks; the Darwin block uses Darwin asm syntax and
the Darwin function-prologue convention.

### `rts/linker/MachO.c`  (~1951 lines, 267 deleted — **the largest single chunk**)

The in-process Mach-O dynamic linker. Loads `.o` files for GHCi
(REPL), Template Haskell, and `dlopen`-style runtime package loading.
The PPC bits are gated on `defined(powerpc_HOST_ARCH)` and live in
~17 `#if powerpc_HOST_ARCH` blocks (lines 32, 182, 1024, 1045, 1069,
1110, 1122, 1133, 1187, 1203, 1249, 1275, 1328, etc.).

Subsystems involved on PPC:

- `#include <mach-o/ppc/reloc.h>` — Apple's PPC Mach-O reloc-types
  header (`PPC_RELOC_VANILLA`, `PPC_RELOC_BR24`, `PPC_RELOC_BR14`,
  `PPC_RELOC_HI16`, `PPC_RELOC_LO16`, `PPC_RELOC_HA16`,
  `PPC_RELOC_LO14`, plus the `_SECTDIFF` scattered variants).
- Jump-island allocator. PPC's branch-instruction range is ±32 MB
  signed (24-bit displacement, shifted left 2). Long calls require
  hopping through trampolines ("jump islands") in nearby memory.
  PPC/Darwin's mmap doesn't support relocate-on-realloc, so the
  whole jump-island allocator runs without mmap on PPC/Darwin (see
  `configure.ac` line 1224 quote below).
- Symbol-extras infrastructure (`SymbolExtras.c`) — runtime stub
  generation, used for the same out-of-range-call problem.

### `rts/linker/LoadArchive.c`  (8 deleted)

The static archive (.a) member loader. PPC bits are tiny — just
`#if powerpc_HOST_ARCH` ifdefs that disable some optimizations.

### `rts/linker/MachOTypes.h`  (5 deleted)

Type aliases. Trivial.

### `rts/RtsSymbols.c`  (9 deleted)

The list of RTS symbols exported to the dynamic linker. PPC entries
are a handful of helper symbols (likely the gcc-built-in helpers
like `__divdi3`, `__udivdi3` that PPC32 needs because hardware
64-bit divide doesn't exist).

### `testsuite/tests/rts/all.T`  (2 deleted)

Test-harness gates: a couple of tests are skipped on PPC/Darwin.

## Build system

- **`configure.ac`** — 11 lines deleted. Most relevant remaining:

  ```
  case ${TargetOS} in
      darwin|ios|watchos|tvos)
          if test "$TargetArch" != "powerpc" ; then
              RtsLinkerUseMmap=1
          else
              RtsLinkerUseMmap=0
          fi
          ;;
  ```

  This `RTS_LINKER_USE_MMAP` flag is the flag the linker
  branches on for the jump-island allocator strategy mentioned above.
  The deletion of the `powerpc → 0` case is part of why the linker
  breaks on a re-enabled PPC/Darwin: without the flag set right,
  it picks the wrong codepath.

## Quick map: removal commit hunks → role

| File | Role | Lines removed |
|------|------|---------------|
| `rts/linker/MachO.c` | RTS dyn linker (GHCi, packages, TH) | 267 |
| `rts/AdjustorAsm.S` | FFI callback asm trampoline | 102 |
| `compiler/nativeGen/PPC/CodeGen.hs` | Cmm→PPC selector, PowerOpen ABI | 94 |
| `compiler/nativeGen/PPC/Ppr.hs` | PPC asm syntax (Mach-O dialect) | 85 |
| `compiler/nativeGen/PIC.hs` | PIC base, symbol stubs, lazy ptrs | 62 |
| `rts/StgCRun.c` | C↔STG transition (Darwin frame layout) | 40 |
| `rts/Adjustor.c` | FFI adjustor C side, fundesc thunks | 32 |
| `compiler/codeGen/CodeGen/Platform.hs` | Platform dispatch | 21 |
| `includes/stg/MachRegs.h` | STG→PPC reg map (Darwin variant) | 16 |
| `compiler/codeGen/CodeGen/Platform/PPC_Darwin.hs` | PPC/Darwin regs | DELETED (11) |
| `configure.ac` | RTS_LINKER_USE_MMAP, target gating | 11 |
| `rts/RtsSymbols.c` | RTS symbol export list | 9 |
| `includes/CodeGen.Platform.hs` | Reserved-reg list (Darwin variant) | 9 |
| `rts/linker/LoadArchive.c` | Static archive loader gates | 8 |
| `compiler/cmm/CmmPipeline.hs` | Cmm proc-point split (PIC) | 7 |
| `compiler/nativeGen/PPC/Instr.hs` | Stack-frame size constants | 5 |
| `rts/linker/MachOTypes.h` | Type aliases | 5 |
| `compiler/nativeGen/PPC/Regs.hs` | Reg classes | 2 |
| `compiler/ghc.cabal.in` | Module list | 1 |
| `testsuite/tests/rts/all.T` | Test gates | 2 |

## What this tells us about the work

1. **The compiler-side work is bounded and well-localized.** All
   non-PIC NCG changes touch six files in `compiler/nativeGen/PPC/`
   plus the platform-dispatch shim. ~217 lines total.

2. **The PIC story is real but contained.** PIC is one file
   (`PIC.hs`, 62 lines), with help from `CmmPipeline.hs` (7 lines)
   and `Ppr.hs` (which has the `__picsymbolstub1` syntax).

3. **The RTS work is bigger than the compiler work.** Mach-O linker
   alone is 267 lines, more than the entire compiler-side change.
   But the RTS linker is *only* needed for GHCi/TH; non-interactive
   compilation works without it. Defer this to Phase 6 per the plan.

4. **`StgCRun.c` and `AdjustorAsm.S` are PPC asm written by hand.**
   These are the highest-skill bits — they have to be byte-perfect
   for the call-frame conventions or the world ends silently. Plan
   to validate against (a) Apple GCC 4.0.1's prologue/epilogue
   output for trivial C functions, (b) the PPC/Linux equivalent in
   the same files (which has been continuously maintained, so we
   know the high-level structure is right; only the Darwin asm
   syntax + frame-offset constants differ).

5. **Darwin asm syntax matters everywhere PPC asm is written.** Two
   files of asm (`AdjustorAsm.S`, plus `StgCRun.c`'s inline asm)
   plus `Ppr.hs` for what gets emitted. The differences from GNU
   PPC asm are documented in Apple's
   *"PowerPC Assembler Guide"* — keep it open during port.

## Key references

- The removal commit diff:
  [`docs/ref/ghc-removal-commit-374e447.diff`](../ref/ghc-removal-commit-374e447.diff)
- Apple, *"Mac OS X ABI Function Call Guide"* — PowerPC chapter
- Apple, *"PowerPC Assembler Guide"*
- Apple, *"Mac OS X ABI Mach-O File Format Reference"* — relocation
  types, section types, load commands
- Local 8.6.5 source: [`external/ghc-8.6.5/`](../../external/ghc-8.6.5/)
