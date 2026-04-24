# Roadmap — GHC 9.2.8 on PPC/Darwin 8

Last reviewed: 2026-04-24 session 1.

## What's done (baseline)

- Stage1 cross-compiler on arm64 macOS → produces running PPC Mach-O binaries.
- 25-program test battery: 21 PASS byte-identical to host, 4 test-design
  diffs, 0 real bugs.
- 128 MB `.tar.xz` cross-bindist packaged; v0.1.0 release on GitHub.
- **pi-Double codegen bug fixed** (patch 0008) — `CmmToC.decomposeMultiWord`
  now recurses on 32-bit targets.
- Stage2 ppc-native `ghc` binary: runs `--version`, can't compile yet
  (see B).

## Open engineering work, roughly ordered by cost

### A. Bug fixes

*No user-facing bugs currently known.*  Completed items:
- ~~Double literals codegen~~ fixed by [patch 0008](../patches/0008-cmmtoc-split-w64-double-on-32bit.patch).

### B. Stretch: native self-hosting stage2 GHC

1. **`StgToCmm.Env: variable not found $trModule3_rwD` panic.** Typeable binding generation works in TC but fails in codegen.  Bypass with `-dno-typeable-binds` lets plain modules compile.
2. **`:Main.main` synthesis fails.** `tcLookupId main_name` finds empty tcl_env.  Breaks any executable compile.  Both bugs point at "runtime state isn't wired up".
3. **Likely root cause** — stage2 ghc's internal mutable state (HscEnv, DynFlags refs, etc.) depends on Haskell runtime behavior we haven't verified on PPC.  Probably needs RTS-level debugging with gdb on pmacg5.

### C. Stretch: GHCi / Template Haskell

1. **Restore PPC runtime Mach-O loader** in `rts/linker/MachO.c`.  The old (pre-2018) PPC code handled `PPC_RELOC_VANILLA`, `PPC_RELOC_BR24`, `PPC_RELOC_HI16`/`LO16`/`HA16`, pair relocs, section-diff relocs, etc.  Needs to be restored from git history (commit ~374e44704b^).
2. **`ocAllocateExtras_MachO` / symbol stubs** for PPC branch-range extension (already partially restored in patch 0004, but the runtime-load path isn't wired up yet).
3. **Test with `ghci`** (needs stage2 to work anyway).

### D. Stretch: upstream contribution

1. Break current local changes into clean patch series for GHC trunk.
2. Engage `ghc-devs` mailing list / GHC gitlab about reviving PPC support.
3. Find a volunteer maintainer who can run CI against a PPC box.

### E. Stretch: ppc64 / ppc64le

Not in scope today; could be a future project.

### F. Packaging / distribution

1. Cabal for PPC.  Is there a working `cabal-install`?  Would need GHC 9.2.8-compatible Cabal lib (we have it) + a `cabal` binary (stage2 ghc + cabal-install package).
2. Bindist installer script (tarball → install script that patches settings).
3. CI (GitHub Actions can't run ppc; need custom runners).

### G. Known test-battery candidates for future (not yet written)

- `hp2ps` — build a program with `-hp -prof`, generate a heap profile.
- `ghc-pkg` commands — list/describe/expose/hide.
- `runghc`, `ghci` (after stretch B/C).
- Long-running programs — verify heap GC works across many allocations.
- Cabal library consumer — compile a small Hackage package via cabal build.

## Interactive planning topics for user

- **Priority:** Fix double literal bug first? Or continue stage2 native bootstrap? Or something else?
- **Bindist:** package the stage1 cross-bindist as something others can install? Docs?
- **Upstream:** is there interest in getting this merged back into GHC?
- **Scope:** focus on GHC 9.2.8, or also attempt 9.4/9.6 modernisation?
- **Tests:** is this test battery (25 programs) enough or want more coverage (benchmarks, QuickCheck-style property tests, full testsuite)?
- **Sister projects:** LLVM-7-darwin-ppc and GHC-704-on-tiger efforts that this relates to — should we unify?
