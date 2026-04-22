# GHC 8.6.5 → 9.2.8 file mapping for the PPC/Darwin port

GHC underwent a large module reorganization between 8.6 and the
modern series — most notably, the `compiler/` source tree was
moved into a `GHC.*` namespace (`compiler/nativeGen/PPC/CodeGen.hs`
became `compiler/GHC/CmmToAsm/PPC/CodeGen.hs`, etc.). The RTS
also got restructured, with platform-specific adjustor code split
out of the monolithic `rts/Adjustor.c` into per-architecture
files under `rts/adjustor/`.

This note maps every file touched by the removal commit
[`374e44704b`](../ref/ghc-removal-commit-374e447.diff) from its
8.6.5 location to its 9.2.8 equivalent, so that the per-hunk port
to a modern GHC has a starting address.

Local clones used to derive the mapping:
- 8.6.5: [`external/ghc-8.6.5/`](../../external/ghc-8.6.5/)
- 9.2.8: [`external/ghc-modern/ghc-9.2.8/`](../../external/ghc-modern/ghc-9.2.8/)

## Compiler — native code generator

| 8.6.5 path | 9.2.8 path | Notes |
|---|---|---|
| `compiler/nativeGen/PPC/CodeGen.hs` | `compiler/GHC/CmmToAsm/PPC/CodeGen.hs` | 8.6.5: 2443 lines. 9.2.8: 2516 lines. Same shape (the `GenCCallPlatform` ADT, `genCCall'`). Hunks should apply with line-shift tolerance. |
| `compiler/nativeGen/PPC/Ppr.hs` | `compiler/GHC/CmmToAsm/PPC/Ppr.hs` | 8.6.5: 1083 lines. 9.2.8: 1108 lines. **THIS IS THE FILE WHERE BARRACUDA156 GOT STUCK** — `pprImm` was rewritten from function-as-cases to `\case` block syntax in modern GHC. The 374e447 hunks need translation, not just patch-apply. |
| `compiler/nativeGen/PPC/Instr.hs` | `compiler/GHC/CmmToAsm/PPC/Instr.hs` | 5-line hunk. |
| `compiler/nativeGen/PPC/Regs.hs` | `compiler/GHC/CmmToAsm/PPC/Regs.hs` | 2-line hunk. Trivial. |
| `compiler/nativeGen/PIC.hs` | `compiler/GHC/CmmToAsm/PIC.hs` | 62-line hunk. Same module name (`PIC`), one directory up. |

## Compiler — STG / register dispatch

| 8.6.5 path | 9.2.8 path | Notes |
|---|---|---|
| `compiler/codeGen/CodeGen/Platform.hs` | `compiler/GHC/Platform.hs` | **Different module name AND location.** The dispatch logic moved into the central `GHC.Platform` module. Look for the `callerSaves` / `activeStgRegs` / `haveRegBase` / `globalRegMaybe` / `freeReg` exports. |
| `compiler/codeGen/CodeGen/Platform/PPC.hs` | `compiler/GHC/Platform/PPC.hs` | Same module style: CPP shim over `includes/CodeGen.Platform.hs`. |
| `compiler/codeGen/CodeGen/Platform/PPC_Darwin.hs` | **DOES NOT EXIST** | This is the file the removal commit deleted. Need to recreate it as `compiler/GHC/Platform/PPC_Darwin.hs` with the same 11-line CPP shim, plus `import GHC.Prelude` instead of `import GhcPrelude`. |
| `compiler/cmm/CmmPipeline.hs` | `compiler/GHC/Cmm/Pipeline.hs` | 7-line hunk. The `usingInconsistentPicReg` predicate. |
| `compiler/ghc.cabal.in` | `compiler/ghc.cabal.in` | Same path, but a much longer file in 9.2.8. Add `GHC.Platform.PPC_Darwin` (not `CodeGen.Platform.PPC_Darwin`) to the exposed-modules list. |

## Includes (CPP-shared)

| 8.6.5 path | 9.2.8 path | Notes |
|---|---|---|
| `includes/stg/MachRegs.h` | `includes/stg/MachRegs.h` | Same path. **Content has drifted significantly:** in 9.2.8, the file uses `defined(darwin_HOST_OS) || defined(ios_HOST_OS)` consistently (treating Apple OSes as one family), and the PPC sections have been simplified. The 16-line removal-commit hunk needs a re-read against modern context — not patch-apply. |
| `includes/stg/MachRegsForHost.h` | **NEW in 9.2.8** | The `MACHREGS_*` autodetection moved here. Contains `#define MACHREGS_darwin 1` for Apple targets (line 67). Our `PPC_Darwin.hs` shim sets `MACHREGS_darwin` directly, bypassing this file, so we don't need to touch it. |
| `includes/CodeGen.Platform.hs` | `includes/CodeGen.Platform.hs` | Same path. **Still has** `# if defined(MACHREGS_darwin)` block (line 209 in 9.2.8) — Trommler's removal partially missed it, or it's been added back for ios. We may be able to reuse the existing shape rather than restoring deleted code. |

## RTS

| 8.6.5 path | 9.2.8 path | Notes |
|---|---|---|
| `rts/StgCRun.c` | `rts/StgCRun.c` | 8.6.5: 1049 lines. 9.2.8: 984 lines. **Reorganized in 9.2:** the asm bodies moved out to a separate `rts/StgCRunAsm.S` file. The Darwin asm (deleted in 374e447) needs to come back **into the new `StgCRunAsm.S`**, not the old `StgCRun.c`. |
| `rts/StgCRunAsm.S` | `rts/StgCRunAsm.S` | **NEW in 9.2.8.** New home for the architecture-specific asm. Receiver of the Darwin asm chunks. |
| `rts/Adjustor.c` | `rts/Adjustor.c` | Was 1324 lines. **Now only 66 lines** — a tiny dispatch stub. The platform-specific bodies moved to `rts/adjustor/Native<Arch>.c`. The 32-line darwin-removal hunk no longer applies to this file at all. |
| `rts/AdjustorAsm.S` | `rts/AdjustorAsm.S` | Still exists (172 lines in 9.2.8 vs 202 in 8.6.5). Receives the 102-line removal-hunk's restoration. |
| (n/a) | `rts/adjustor/NativePowerPC.c` | **NEW in 9.2.8.** 406-line PowerPC adjustor logic, **with all darwin-specific code already removed**. The Darwin function-descriptor handling and trampoline emission need to come back here, not in `rts/Adjustor.c`. |
| (n/a) | `rts/adjustor/Nativei386.c`, `NativeAmd64.c`, etc. | New per-arch files. Reference for shape. |
| (n/a) | `rts/adjustor/LibffiAdjustor.c` | Alternative libffi-based adjustor. Probably can be ignored for our purposes — Darwin PPC doesn't have a usable libffi. |
| `rts/linker/MachO.c` | `rts/linker/MachO.c` | 8.6.5: 1951 lines. 9.2.8: 1626 lines. Got SLIMMER — the post-deletion code path was further cleaned up. The 267-line PPC-restoration hunk does NOT apply cleanly; needs to be re-emitted against the new shape. |
| `rts/linker/LoadArchive.c` | `rts/linker/LoadArchive.c` | Same path. 8-line hunk; should mostly apply. |
| `rts/linker/MachOTypes.h` | `rts/linker/MachOTypes.h` | Same path. 5-line hunk. Trivial. |
| `rts/RtsSymbols.c` | `rts/RtsSymbols.c` | Same path. 9-line hunk. |

## Build system

| 8.6.5 path | 9.2.8 path | Notes |
|---|---|---|
| `configure.ac` | `configure.ac` | Same path. The `case ${TargetOS} in darwin) … if "$TargetArch" = powerpc` logic survives in 9.2.8 (rgrep'd: still uses `RtsLinkerUseMmap`). The 11-line removal hunk likely applies with offsets. |
| `testsuite/tests/rts/all.T` | `testsuite/tests/rts/all.T` | Same path. 2-line hunk. |
| (n/a) | `hadrian/` | **NEW in 9.x:** Hadrian, the Shake-based replacement for the `make`-based build system that 8.6.5 used. 9.2.8 ships **both** `make`-based and Hadrian builds; `make` is deprecated but still works. **Use `make` first** to minimize the variables we're debugging. |

## Cross-cutting renames

A few mechanical renames that affect every restored file:

- `import GhcPrelude` → `import GHC.Prelude`
- `import qualified CodeGen.Platform.PPC_Darwin as PPC_Darwin` →
  `import qualified GHC.Platform.PPC_Darwin as PPC_Darwin`
- `import CodeGen.Platform` → (now usually unnecessary; the dispatch
  is in `GHC.Platform`)
- `OSDarwin` → still `OSDarwin` (in `GHC.Platform`)
- `ArchPPC` → still `ArchPPC`
- `Platform` constructor field names — unchanged; `platformOS`,
  `platformArch` survive.

## Forward-port strategy

Per-hunk, in this order (smallest first, validate each before
moving on):

1. **`compiler/ghc.cabal.in`** — one line. Just adds
   `GHC.Platform.PPC_Darwin` to module list. (Trivial.)
2. **`compiler/GHC/Platform/PPC_Darwin.hs`** — re-create the 11-line
   CPP shim with `import GHC.Prelude`. (Trivial.)
3. **`compiler/GHC/Platform.hs`** — restore the dispatch.
   `(ArchPPC, OSDarwin) -> PPC_Darwin.foo`. (~21 lines, 5 functions.)
4. **`compiler/GHC/CmmToAsm/PPC/Regs.hs`** — 2 lines. (Trivial.)
5. **`compiler/GHC/CmmToAsm/PPC/Instr.hs`** — 5 lines. (Trivial.)
6. **`includes/stg/MachRegs.h`** — restore the Darwin r2/r13
   reservations. **NEEDS MANUAL TRANSLATION** because the file's
   shape changed.
7. **`includes/CodeGen.Platform.hs`** — same. May already be partly
   in place; verify before re-restoring.
8. **`compiler/GHC/Cmm/Pipeline.hs`** — 7 lines. The
   `usingInconsistentPicReg` change.
9. **`configure.ac`** — restore `RtsLinkerUseMmap=0` for powerpc-darwin.
10. **`compiler/GHC/CmmToAsm/PPC/CodeGen.hs`** — 94 lines.
    Should mostly apply with offsets; ABI hasn't changed.
11. **`compiler/GHC/CmmToAsm/PIC.hs`** — 62 lines. Probably applies.
12. **`compiler/GHC/CmmToAsm/PPC/Ppr.hs`** — 85 lines. **HARDEST
    COMPILER-SIDE FILE.** `pprImm` rewritten to `\case`; need to
    re-emit each restoration block in `\case` style.
13. **`rts/RtsSymbols.c`** — 9 lines. Mechanical.
14. **`rts/StgCRun.c` + `rts/StgCRunAsm.S`** — restore the 40 lines
    of darwin StgRun/StgReturn handling, **into the new asm file**.
15. **`rts/adjustor/NativePowerPC.c`** — restore the darwin
    function-descriptor and trampoline code (was in
    `rts/Adjustor.c`).
16. **`rts/AdjustorAsm.S`** — 102 lines of asm trampoline. Probably
    applies-with-offsets.
17. **`rts/linker/LoadArchive.c`** — 8 lines.
18. **`rts/linker/MachOTypes.h`** — 5 lines.
19. **`rts/linker/MachO.c`** — 267 lines. **HARDEST RTS-SIDE FILE.**
    Cleanup happened post-removal; can't patch-apply, must re-port.
20. **`testsuite/tests/rts/all.T`** — 2 lines.

Phases 1-13 give a registerised compiler (no GHCi, no TH); 14-19
add GHCi/TH support.

## A note on "version drift" between 8.6 and 9.2

Trommler's reading is that PPC/Linux has been continuously
maintained (since he himself does it), and big-endian-related bugs
have been fixed but only on the schedule "someone notices and
files an issue." So:

- **PPC asm output (NCG)**: high confidence the hunk-by-hunk port
  to 9.2 produces the same (correct) asm shape, modulo any places
  the modern compiler emits *new* Cmm constructs the old NCG never
  had to handle. Watch for new `MO_*` ops in `PrimOp.hs` between
  8.6 and 9.2 — these may need new selector clauses.
- **RTS dynamic linker**: lower confidence, but the linker has
  also been continuously evolving for ARM64/iOS support, and the
  Mach-O relocation kinds for PPC haven't changed since the 1990s.
  Anything we restore for PPC has good odds of being correct;
  anything we have to *write* (because of new linker invariants)
  is the risk surface.
- **STG-register layout**: should be untouched. The same set of
  STG registers (`R1`-`R10`, `Hp`, `Sp`, etc.) maps to the same
  PPC GPRs it always did.

When in doubt, cross-check against the **PPC/Linux modern-GHC**
behavior (build it on Debian/PPC, dump the asm, compare to ours).
That oracle didn't exist when barracuda156 tried this; we have it.
