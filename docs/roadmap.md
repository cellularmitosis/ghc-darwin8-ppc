# Roadmap — GHC 9.2.8 on PPC/Darwin 8

Last reviewed: 2026-04-24 session 6.

## What's done (baseline)

- Stage1 cross-compiler on arm64 macOS → produces running PPC Mach-O binaries.
- 25-program test battery: 21 PASS byte-identical to host, 4 test-design
  diffs, 0 real bugs.
- ~117 MB `.tar.xz` cross-bindist packaged; tagged v0.1.0, v0.2.0 (pi fix),
  v0.3.0 (installer).
- **pi-Double codegen bug fixed** (patch 0008) — `CmmToC.decomposeMultiWord`
  now recurses on 32-bit targets.
- **One-command install** — `./install.sh --prefix --ppc-host` bundled
  in the tarball.  Verifies prereqs, copies tree, writes settings,
  smoke-tests.
- Stage2 ppc-native `ghc` binary: runs `--version`, can't compile yet
  (see *Stage2 native ghc* below).

## Open engineering work

Ordered by the user's stated priority: **A → D → F → C → B → E**
(done ✅ = struck through).

### ~~A. Bug fixes from stress testing~~ ✅ done

*No user-facing bugs currently known.*
- ~~Double literals codegen~~ fixed by patch 0008 (session 1).

### ~~D. Bindist / install experience~~ ✅ done (v0.3.0)

- ~~Installer script that handles tarball + settings rewrite + smoke test~~.
- Follow-ups (later sessions):
  - CI (GitHub Actions can't run ppc; need custom runners or self-hosted).
  - Homebrew formula.
  - Bundle clang/SDK/cctools into one combined installer.

### F. More test coverage — mostly done (sessions 3 + 4 + 6)

✅ Done: threaded RTS, STM, Data.Time, long-running GC, MVar
stress, POSIX signals, Data.Map, weak refs + performGC, STM
retry+orElse (battery 30/34 PASS byte-identical).

✅ **Cabal cross-compile** (session 6, v0.4.0): 30+ Hackage
packages verified — random, splitmix (vendored), async, vector,
aeson, optparse-applicative, megaparsec + transitive deps.
Recipe in [`docs/cabal-cross.md`](cabal-cross.md).

Remaining untested / future sessions:
- Profiling (`-prof`, `hp2ps`)
- Socket / network IO (blocked on `SOCK_CLOEXEC` gap in Tiger SDK;
  vendor `network` with `#ifdef` guards)
- Dynamic linking (`-dynamic` disabled by QuickCross; 24-bit scattered reloc limit)
- `runghc` execution path
- `ghc-pkg list/describe/expose/hide` commands
- TLS / HTTPS (needs Tiger-compatible `openssl`)

### C. Stretch: GHCi / TemplateHaskell

Restore PPC runtime Mach-O loader in `rts/linker/MachO.c`.
- `PPC_RELOC_VANILLA`, `PPC_RELOC_BR14`/`BR24`, `PPC_RELOC_HI16`/`LO16`/`HA16`, pair relocs, section-diff relocs.
- Branch-island (jump stub) insertion for out-of-range `bl`s.
- Restore from GHC git history at commit 374e44704b^.
- `ocAllocateExtras_MachO` for PPC (partially in patch 0004, not yet wired up).
- Testing requires stage2 to work first (see next section) — *or* a
  direct C test driver that calls `loadArchive` in the RTS.

Estimated effort: 1–2 days drop-in, up to a week if the runtime
linker API has drifted.

### B. Stretch: stage2 native `ghc` bug

Current 128 MB ppc-native `ghc` binary runs `--version` but panics on
compile with `StgToCmm.Env: variable not found $trModule3_rwD`.
Typeable binding generation works in TC but fails in codegen.  Bypass
with `-dno-typeable-binds` lets non-main modules compile.

`:Main.main` synthesis also fails separately — `tcLookupId main_name`
finds empty tcl_env.

Both smell like "runtime state isn't wired up" — `HscEnv`, `DynFlags`
IORefs, maybe something specific to PPC32 atomics (given our earlier
`_hs_xchg64` patch, the atomics ABI is suspect).

Needs gdb on pmacg5 for a ppc-native Haskell runtime trace, or
careful comparison against a known-good stage2 build (chicken-and-egg).

See [`docs/experiments/006-stage2-native-ghc.md`](experiments/006-stage2-native-ghc.md)
and [`docs/proposals/stage2-native.md`](proposals/stage2-native.md).

### ~~E. Upstream contribution~~ on hold (user request)

Paused until we're further down the road.

## Sister project touch-points

- **llvm-7-darwin-ppc** (private) — source of our cross clang + SDK
  + the underlying LLVM-7 PPC backend.  Our patch 0008 to
  `compiler/GHC/CmmToC.hs` is pure-Haskell and doesn't affect LLVM;
  no change to that project needed.
- **rogerppc** (private) — unrelated to this project.
