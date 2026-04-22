# Plan: GHC on `powerpc-apple-darwin8` (Mac OS X 10.4 Tiger)

Bring the Glasgow Haskell Compiler back to PowerPC Tiger. PPC/Darwin
was a first-class GHC target until commit
[`374e44704b`](https://gitlab.haskell.org/ghc/ghc/-/commit/374e44704b64afafc1179127e6c9c5bf1715ef39)
(Peter Trommler, 2018-12-30, "PPC NCG: Remove Darwin support";
fixes [#16106](https://gitlab.haskell.org/ghc/ghc/-/issues/16106)),
which surgically deleted PPC/Darwin from one branch in the 8.7
window — landing in 8.8.1. The diff is small, focused, and
reversible: 20 files, +118/-711, with the bulk in five places we
already know about (Mach-O linker, native-code-generator pretty
printer, adjustor thunks, STG context switch, and the small
PPC-Darwin code-gen platform module that was deleted outright).
This plan resurrects that work, ports it forward to a modern GHC,
and drives it to a usable Haskell compiler on Tiger hardware.

This is bounded archaeology, not research. Multi-month, slow burn,
small reversible steps, validated against real PPC Tiger hardware.

## Goal

End-to-end: a `ghc` binary that runs on **`powerpc-apple-darwin8`**
(Mac OS X 10.4 "Tiger"), compiles a small Haskell program from
source, links it against `base`/`ghc-prim`/`integer-{gmp,simple}`,
and produces a Mach-O PPC executable that runs correctly on Tiger
hardware. Stretch: `cabal install` of a small pure-Haskell library
(e.g. `parsec`, `containers`).

Success looks like:

```
imacg52$ ghc --version
The Glorious Glasgow Haskell Compilation System, version <X.Y.Z>
imacg52$ ghc -O hello.hs -o hello && ./hello
hello, world
imacg52$ file hello
hello: Mach-O executable ppc
```

## Explicit non-goals

- **Upstreaming** to `gitlab.haskell.org/ghc/ghc`. The official tree
  has shipped without PPC/Darwin since 8.8 and the maintainers
  ([bgamari](https://gitlab.haskell.org/bgamari),
  [trommler](https://gitlab.haskell.org/trommler)) require
  named owners + working CI before any reintroduction. We may
  upstream eventually, but planning for it locks us into their
  cadence — treat it as a fork forever and bonus if it lands.
- **GHCi (the byte-code interpreter / REPL).** GHCi on PPC needs
  the in-tree dynamic linker (`rts/linker/MachO.c`) to work, which
  is the largest single chunk of the removal commit (267 lines).
  We'll attempt it after compiled-code works, not before. A
  compiler that produces working executables but can't load
  bytecode at REPL is still a hugely useful deliverable.
- **Template Haskell.** TH requires GHCi-style runtime loading
  on non-cross-compiler hosts. Same reasoning as GHCi — defer.
- **Profiling, parallel runtime (`-threaded`), DWARF.** All built
  on top of the basic RTS/codegen story; not worth touching until
  the simple path works.
- **Hackage at large.** The cabal-build ecosystem assumes a recent
  base/Cabal. Many packages won't compile against an old `base`,
  many use TH, many have C dependencies that themselves need
  patching for Tiger. Scope is "we have a working `ghc` and stdlib";
  any given package working is a per-package project.
- **PPC64 / Leopard-only G5 64-bit userland.** PPC32 first; PPC64
  on Darwin was a fringe target even in its day and no GHC release
  ever shipped for it.
- **Self-hosting bootstrap.** We will use a cross-built bootstrap
  binary from a modern host. Re-bootstrapping the entire chain
  natively from Apple GCC 4.0 is out of scope.
- **Stack, cabal-install modern features, HLS, anything Hackage-y
  built on those.** All assume modern GHC + TH + dynamic linking.

## Why this is tractable

Several things that would otherwise be hard are already done by
others or already on the fleet:

1. **The removal commit is small and surgical.**
   [`374e44704b`](https://gitlab.haskell.org/ghc/ghc/-/commit/374e44704b64afafc1179127e6c9c5bf1715ef39)
   removed PPC/Darwin in a single self-contained patch (+118/-711
   across 20 files). Reversion is a defined finite task, not an
   open-ended port. Files involved
   ([full diff cached locally](ref/ghc-removal-commit-374e447.diff)):

   | File | Lines removed | Role |
   |---|---|---|
   | `rts/linker/MachO.c` | 267 | RTS dynamic linker (GHCi, packages) |
   | `rts/AdjustorAsm.S` | 102 | FFI callback trampolines |
   | `compiler/nativeGen/PPC/CodeGen.hs` | 94 | NCG calling convention |
   | `compiler/nativeGen/PPC/Ppr.hs` | 85 | NCG asm pretty-printer |
   | `compiler/nativeGen/PIC.hs` | 62 | PIC base-register init |
   | `rts/StgCRun.c` | 40 | C ↔ STG world transitions |
   | `rts/Adjustor.c` | 32 | FFI callback C side |
   | `compiler/codeGen/CodeGen/Platform.hs` | 21 | Platform dispatch |
   | `includes/stg/MachRegs.h` | 16 | STG-register → real-register map |
   | `configure.ac` | 11 | Build-system target enable |
   | `compiler/codeGen/CodeGen/Platform/PPC_Darwin.hs` | 11 | DELETED — Darwin reg conventions |
   | `rts/RtsSymbols.c` | 9 | Symbol-table entries |
   | `includes/CodeGen.Platform.hs` | 9 | Reserved-register list |
   | `rts/linker/LoadArchive.c` | 8 | Static archive loader |
   | `compiler/cmm/CmmPipeline.hs` | 7 | Cmm passes (PIC) |
   | `compiler/nativeGen/PPC/Instr.hs` | 5 | Stack-frame sizing |
   | `compiler/nativeGen/PPC/Regs.hs` | 2 | Reg classes |
   | `rts/linker/MachOTypes.h` | 5 | Linker types |
   | `compiler/ghc.cabal.in` | 1 | Cabal module list |
   | `testsuite/tests/rts/all.T` | 2 | Test gating |

2. **Trommler is reachable and helpful.** The author of the removal
   commit also maintains the PPC native code generator on Linux,
   has written publicly that "I might be able to help with
   explaining how and where things are done in the PowerPC native
   code generator," and gave a clear how-to-resurrect recipe in
   [issue #16106](https://gitlab.haskell.org/ghc/ghc/-/issues/16106):

   > I would not waste my time trying to fix old versions from the
   > 7 series of GHC. Just cross-compile the GHC version that you
   > want for MacPorts and then fix that version. To get many
   > potential PowerPC issues out of the picture I recommend an
   > unregisterised compiler first (`configure --enable-unregisterised`).
   > Then you have a working compiler that you can use to resurrect
   > native code support for Darwin. Commit 374e4470 can be a
   > reference for what needs to be done, the files/modules,
   > however, have been moved around since.

   This is the playbook. We follow it.

3. **Prior in-progress attempt to learn from.** A MacPorts
   contributor (`barracuda156`) attempted this in 2022 and made
   real but partial progress, documented in
   [MacPorts ticket #64698](https://trac.macports.org/ticket/64698)
   and [GHC issue #21371](https://gitlab.haskell.org/ghc/ghc/-/issues/21371).
   Outcomes worth inheriting:

   - On **Snow Leopard PPC (darwin-10)** they got 7.6.3 building
     end-to-end from a 7.0.1 bootstrap. Hello world ran. This
     proves the legacy ladder works on at least one Darwin/PPC OS.
   - On **Tiger (darwin-8)** they hit a libiconv ABI mismatch with
     the 7.0.1 binary (system `libiconv.2.dylib` provides v5.0.0,
     ghc-pwd needs v7.0.0+). This is fixable; may need building
     7.0.1 from source rather than using the prebuilt tarball.
   - Every attempted rung above 7.6 (7.7, 7.8.x, 7.10.3) failed
     with `ghc-stage1: internal error: evacuate(static): strange
     closure type`. Trommler's reading: probably weak-memory-ordering
     race conditions or big-endian bugs, not a single fixable bug.
     **Lesson:** stop trying to climb the legacy ladder past 7.6.x.
     Cross-compile a modern release instead.
   - They started a 9.2.2 in-tree resurrection (issue #21371) but
     ran out of energy at the asm pretty-printer rewrite. Their
     sketch is reusable as a reference.

4. **Cross-target validation host exists.** Debian PowerPC ships
   working modern GHC (8.8.4 at the time of #16106; newer now —
   adelie/Debian still maintain it). We can use a native PPC Linux
   build as the ground-truth oracle for what working PPC codegen
   should look like at the assembly level.

5. **TigerTube infrastructure is reusable as-is.** Same fleet, same
   `tiger.sh` /opt system, same `imacg3-dev` skill, same
   `tiger-rsync.sh`, same Xcode 2.5 + `MacOSX10.4u.sdk` already
   present on every Tiger host. Nothing to invent at the
   environment layer.

## Two paths, chosen order

Two routes to the goal, with very different cost/risk profiles:

### Path A — Legacy ladder (quick win, capped value)

Bootstrap an old GHC binary on Tiger, climb the ladder version-by-version
as far as it will go before the `evacuate(static)` wall.

- **Likely ceiling:** GHC 7.6.3 (proven on Snow Leopard by barracuda156).
- **Pro:** Very high probability of getting *something* running in
  weeks not months. Useful proof-of-life for the project. Validates
  the entire build/run/deploy pipeline on Tiger. Confirms the
  fleet's Apple GCC 4.0 + ld + libSystem can produce working GHC
  output. Gives us a *known-working* GHC that we can use to study
  what real PPC/Darwin codegen looks like.
- **Con:** GHC 7.6.3 is from 2013. `base` 4.6, `Cabal` 1.16, no
  modern language extensions, can't compile most of Hackage.
  This is a museum piece.
- **Workflow:** acquire 7.0.4 binary `.pkg` (the krabby build —
  last semi-official PPC/Darwin release), unpack manually, install
  by hand (the `.pkg` framework layout doesn't match `make install`
  layout), use it to build 7.6.3 from source. Stop there. Don't
  attempt 7.8+.

### Path B — Modern cross-bootstrap (real deliverable, hard)

Cross-compile a modern GHC for `powerpc-apple-darwin8` from a
working host (Linux/PPC or amd64-with-cross-toolchain), starting
unregisterised to dodge the native code generator entirely, then
revive the NCG by reverting the work in commit 374e447 and
forward-porting it to the modern compiler/RTS layout.

- **Likely target:** GHC 9.2.x (last branch before bigger
  refactors; barracuda156's prior attempt also targeted 9.2.2; new
  enough to be useful, old enough that the file paths in the
  removal commit are still recognizable).
- **Pro:** Actually useful — modern Haskell, can build modern
  packages (within the limits of TH/GHCi support), compatible with
  recent `cabal-install` (cross-compile mode). Aligns with
  trommler's recommended path.
- **Con:** Cross-bootstrapping GHC is notoriously fiddly even when
  the target is a *supported* platform. Doing it for a target
  that's been removed for 7+ years adds Mach-O linker work, asm
  pretty-printer work, RTS adjustor work, and inevitable
  bit-rot-discovery work. Realistic timeline measured in months.

### Order

**Path A first (proof of life, ~weeks), then Path B (real work,
months).** The Path A artifacts (working GHC 7.6.3 binary, dump of
its real `as` output, working executables) become the
ground-truth references for Path B. Path B without the Path A
artifacts is harder to debug because we have no on-Tiger oracle
for "what should good codegen look like."

## Machines and workflow

### Dev hosts

| Host | Role |
|---|---|
| **uranium** (this Mac) | Edits, Claude Code, plan/logs/experiments in this repo. Hub for ssh aliases into the PPC fleet. The cross-bootstrap Linux/PPC oracle (via VM or remote Debian/PPC) lives here too if we go remote. |
| **build host (TBD in Phase 0)** | The fast modern Mac for cross-bootstrap of a Path-B compiler. Likely an arm64 mini, like indium in the LLVM project. Decide once we know whether we need a Linux/PPC chroot or whether the cross-toolchain runs natively. |

### The Tiger PPC fleet

Same fleet as `llvm-7-darwin-ppc` and `golang-darwin8-ppc` —
documented at [`~/TigerTube/docs/fleet/fleet.md`](../../TigerTube/docs/fleet/fleet.md).
All hosts are ssh-reachable as `macuser`, key-based auth,
hostnames aliased in `~/.ssh/config`.

**Primary target host: `imacg52` (G5 2.0 GHz, Tiger 10.4.11, 1.5+ GB RAM,
9.5+ GB free).** GHC compiles itself; this is the slowest possible
build on the slowest possible CPU, and the G5 is the only Tiger box
that won't be torturous. Single-precision G5 also exposes any 64-bit
PPC fallout if/when we extend later.

**Validation matrix (run final binaries on each):**

| Host | CPU | AltiVec | Notes |
|---|---|---|---|
| **imacg52** | PPC 970 2.0 | yes | **Primary dev/build host.** G5 Tiger, 64-bit-capable on 32-bit userland. |
| pmacg5 | PPC 970MP dual 2.3 | yes | Fastest in fleet — backup build host if imacg52 thermals struggle. Tiger on `/dev/disk0s5`. |
| pmacg3 | PPC 750 400 | no | G3 baseline, oldest |
| imacg3 | PPC 750cx 600 | no | The host the `imacg3-dev` skill was written around |
| ibookg3 | PPC 750fx 900 | no | G3 reference |
| ibookg37 | PPC 750fx 900 | no | 14" G3 reference |
| emac | PPC 7447a 1.42 | yes | G4 AltiVec validation |

Same Leopard hosts available (`pbookg42`, `mdd`, `pmacg5`-Leopard-partition)
for darwin-9 cross-validation if Path B reaches that ambition.

### Already-in-place infrastructure

Inheriting wholesale from prior PPC projects:

- **`MacOSX10.4u.sdk`** on every Tiger host via Xcode 2.5.
- **Apple GCC 4.0.1** on every Tiger host as the C toolchain. **GCC
  4.2 also available** on Leopard hosts. GHC builds historically
  used GCC 4.0/4.2 — they're the right C compilers for this work.
- **Modern GCC in `/opt`** (4.9.4, 10.3.0) via `tiger.sh` for any
  C build that chokes on 4.0.1.
- **`tiger-rsync.sh`** handles the Tiger rsync protocol-27 quirk.
- **`tiger.sh` / `leopard.sh`** for installing modern packages
  (`bash` 3.2+, modern `curl` with TLS, `perl` 5.36, `gmp` if not
  present) into `/opt`.
- **The `imacg3-dev` Claude skill**
  ([`~/TigerTube/.claude/skills/imacg3-dev/SKILL.md`](../../TigerTube/.claude/skills/imacg3-dev/SKILL.md)) —
  applies uniformly to every Tiger host. Load it whenever working
  on Tiger. It covers: never use `/bin/bash` (too old), never use
  stock `curl` (TLS too old), never use `/tmp` (cleared at boot),
  use `/Users/macuser/tmp` instead, perl 5.36 path, modern GCC
  paths, the `Availability.h` rewrite (Tiger has only
  `AvailabilityMacros.h`), and `getcontext`/`setcontext` being
  Leopard-only — both will bite GHC's RTS.

## Phases

### Phase 0 — Reconnaissance and tooling

Goal: have a clean local checkout of GHC, a chosen base version,
a test corpus, and a mental model of what the removal commit did.

- [ ] Clone GHC. Check out `ghc-8.6.5-release` (last release with
      PPC/Darwin still in tree) and pin commit `374e44704b~1` from
      master as the equivalent if there's drift; the 8.6.5 tag
      predates the removal commit by the widest comfortable margin.
- [ ] Cache the removal commit diff locally as
      [`docs/ref/ghc-removal-commit-374e447.diff`](ref/ghc-removal-commit-374e447.diff)
      so we can study it offline.
- [ ] Browse `compiler/nativeGen/PPC/`, `compiler/codeGen/CodeGen/Platform/`,
      `rts/linker/MachO.c`, `rts/AdjustorAsm.S`, `rts/StgCRun.c`,
      `rts/Adjustor.c`, `includes/stg/MachRegs.h`. Write a one-page
      tour at [`docs/notes/codebase-tour.md`](notes/codebase-tour.md).
- [ ] Identify the equivalent files in modern GHC (HEAD or 9.6 LTS).
      Module reorganization across the GHC tree means file paths
      differ; we need a mapping. Capture it in
      [`docs/notes/file-mapping-86-vs-modern.md`](notes/file-mapping-86-vs-modern.md).
- [ ] Document the bootstrap-chain reality at
      [`docs/notes/bootstrap-chain.md`](notes/bootstrap-chain.md):
      what versions of GHC are bootstrapable from what other
      versions, with citations from upstream's
      [`docs/users_guide/bootstrap.rst`](https://gitlab.haskell.org/ghc/ghc/-/blob/master/docs/users_guide/bootstrap.rst).
- [ ] Pick a small Haskell test corpus: hello world, a `Data.Map`
      walk, a `Data.IORef` mutator, an FFI-via-`foreign import` to
      `puts`, a forkIO-and-join smoke test, a small `Maybe`/`Either`
      monadic computation. Six to ten programs total. Stash under
      [`testprogs/`](../testprogs/).

### Phase 1 — Path A: legacy GHC 7.0.4 binary on Tiger

Goal: get *some* GHC running on a real Tiger box. Doesn't matter
which; we just need a Haskell hello world to exit 0.

- [ ] Download the krabby `GHC-7.0.4-powerpc.pkg` from
      `downloads.haskell.org/~ghc/7.0-latest/krabby/`. Verify it
      hasn't rotted off the mirror; if it has, source from the
      Wayback Machine. Cache locally in `external/`.
- [ ] On a Mac (any Mac, not necessarily PPC), expand the `.pkg`
      payload (`pkgutil --expand` then `cpio -i` on the embedded
      Payload) to extract the `GHC.framework` directory tree.
- [ ] Survey the framework layout. The `usr/` subtree inside
      `GHC.framework/Versions/.../` is roughly what `make install`
      would have produced under `--prefix=/opt/ghc-7.0.4/`. Write
      an install script that lays it down at `/opt/ghc-7.0.4/`
      with the correct symlinks. The 7.0.4 binary is darwin-9-built
      so test on a Leopard host first (`pbookg42` or `mdd`); then
      port to Tiger.
- [ ] On Tiger, the libiconv ABI mismatch barracuda156 hit
      (system `libiconv.2.dylib` provides v5.0.0, ghc-pwd needs v7.0.0+)
      will likely also bite us. Two workaround paths:
      (a) build a newer libiconv into `/opt` and `install_name_tool`
      the GHC binary to use it (small surgery, contained);
      (b) build GHC 7.0.4 from source against Tiger's libraries.
      Try (a) first — it's hours, not days. See
      [`notes/iconv-abi-mismatch.md`](notes/iconv-abi-mismatch.md).
- [ ] **Goal of phase:** `ghc-7.0.4 hello.hs && ./hello` exits 0
      on `imacg52` running Tiger. Document in
      [`experiments/001-ghc-704-on-tiger.md`](experiments/001-ghc-704-on-tiger.md).

### Phase 2 — Path A: climb to GHC 7.6.3

Goal: replicate barracuda156's Snow Leopard 7.6.3 build, but on
Tiger. End with `ghc-7.6.3` running on Tiger producing working
PPC Mach-O binaries.

- [ ] Get GHC 7.6.3 source from `downloads.haskell.org/~ghc/7.6.3/`.
- [ ] On `imacg52`, with `GHC=/opt/ghc-7.0.4/bin/ghc`, configure
      with `--prefix=/opt/ghc-7.6.3/ --with-macosx-deployment-target=10.4`.
      Build. This will take many hours; run via the
      `imacg3-dev` long-builds pattern (background script,
      `tail -f` log).
- [ ] Iterate on whatever fails. Likely candidates:
      (a) `gcc-4.0` chokes on something — fall back to `/opt/gcc-4.9.4`;
      (b) Tiger-specific syscall headers missing some flag;
      (c) the `iconv` story bites again at the `base` level.
- [ ] Run the test corpus from Phase 0 against the resulting compiler.
- [ ] Cross-validate output: build `hello.hs` with `ghc-7.6.3` on
      `imacg52`, ship the binary to every Tiger fleet host (`pmacg3`,
      `imacg3`, `ibookg3`, `ibookg37`, `emac`), confirm it runs.
- [ ] Document at [`experiments/002-build-ghc-763-from-704.md`](experiments/002-build-ghc-763-from-704.md).

**Path A exit:** at this point we have a usable-if-ancient Haskell
on Tiger. Decide whether to cap Path A here (probably) or attempt
7.8.x knowing it will likely fail (probably not — trust trommler).

### Phase 3 — Path B prep: cross-compile a modern GHC unregisterised

Goal: get a modern (target ~9.2.x or 9.6.x) GHC cross-built on a
modern host, targeting `powerpc-apple-darwin8`, in
**unregisterised** mode (LLVM-via-GCC backend, no native code
generator). This dodges the entire NCG resurrection until we have
a working compiler to bootstrap with.

- [ ] Pick the GHC version. Decision criteria: (i) close to the
      removal commit so file layouts match (8.10 LTS is closest);
      (ii) modern enough to be useful (9.2 LTS is the first really
      modern series); (iii) still able to bootstrap from older GHCs
      we can actually obtain. **Tentative pick: 9.2.x.** Confirm
      after reading bootstrap notes in Phase 0.
- [ ] Pick the cross-toolchain. Need:
      (a) `powerpc-apple-darwin8`-targeted `gcc` and `ld`. cctools-port
      + the SDK; or build from `iains/darwin-xtools` (already
      surveyed in the `llvm-7-darwin-ppc` project — see
      [`~/claude/llvm-7-darwin-ppc/docs/plan.md`](../../llvm-7-darwin-ppc/docs/plan.md));
      (b) a working modern GHC on the host. Apple `ghc` from Homebrew
      / nixpkgs / ghcup is fine.
- [ ] `configure --target=powerpc-apple-darwin8 --enable-unregisterised`.
      Read GHC's
      [Building a cross compiler](https://gitlab.haskell.org/ghc/ghc/-/wikis/building/cross-compiling)
      wiki page; specifically the "GHC as a cross-compiler" section.
- [ ] Expect this to fail. The `configure.ac` change in commit
      374e447 deleted PPC/Darwin from the recognized targets — the
      first patch in Path B is to revert that hunk so the configure
      script accepts the triple at all.
- [ ] Likely subsequent failures: (i) `Adjustor.c` won't compile
      without the deleted PPC/Darwin block; (ii) `MachRegs.h` lacks
      the STG-register layout for PPC/Darwin; (iii) `MachO.c`
      missing PPC reloc handling. Each gets its own experiment
      file with the patch and the rationale.
- [ ] **Goal of phase:** unregisterised `ghc-stage1` cross-compiles
      `hello.hs` to a Mach-O PPC executable on the build host. The
      executable is then transferred to `imacg52` and runs.

### Phase 4 — Path B: native bootstrap unregisterised on Tiger

Goal: take the Phase 3 cross-compiler's output, bootstrap a stage-2
GHC *natively on Tiger*, still unregisterised. End state: a Tiger
machine with a working modern GHC (slow because unregisterised) but
self-contained.

- [ ] Cross-build the unregisterised stage-1 binary on the build host.
- [ ] Cross-build the registerised library set unregisterised
      (`base`, `ghc-prim`, `integer-gmp`, `Cabal`, ...).
- [ ] Bundle into an installable tarball the way upstream does
      (`make binary-dist`).
- [ ] Ship to `imacg52`, install at `/opt/ghc-9.2-unreg/`.
- [ ] Run the Phase 0 test corpus.
- [ ] **Goal of phase:** Tiger box with a self-contained modern GHC.
      Slow (3-5x slower than registerised, per typical
      unregisterised vs NCG benchmarks) but functionally complete
      for our test corpus.

### Phase 5 — Path B: revive the native code generator

Goal: re-enable PPC/Darwin in the NCG so the resulting compiler
emits PPC asm directly (no `gcc` round-trip), restoring competitive
performance.

This is the heart of the removal-commit reversion. Forward-porting
374e447 to the modern code-gen layout. Files involved (modern
paths; map established in Phase 0):

- `compiler/GHC/CmmToAsm/PPC/CodeGen.hs` — was `compiler/nativeGen/PPC/CodeGen.hs`
- `compiler/GHC/CmmToAsm/PPC/Ppr.hs` — was `compiler/nativeGen/PPC/Ppr.hs`
- `compiler/GHC/CmmToAsm/PIC.hs` — was `compiler/nativeGen/PIC.hs`
- `compiler/GHC/Platform.hs` and friends — was `compiler/codeGen/CodeGen/Platform/`

Order of attack:

- [ ] Restore the platform dispatch (`PPC_Darwin.hs` equivalent).
      Smallest, most contained.
- [ ] Restore the asm pretty-printer's Mach-O syntax cases. This
      is where barracuda156 got stuck — the syntax changed from
      function-as-cases to `\case` in the modern tree, so the
      patch can't be applied verbatim and needs translation.
- [ ] Restore the codegen's calling-convention bits (Darwin
      PowerOpen-derived ABI: r3-r10 for ints, f1-f13 for floats,
      24-byte linkage area, 16-byte stack alignment).
- [ ] Restore PIC base-register init (`bcl 20,31,1f; 1: mflr reg`).
- [ ] Restore stack-frame sizing.
- [ ] Per-piece, validate against (a) Apple GCC 4.0.1 asm output
      for equivalent C; (b) the Path-A 7.6.3 NCG's asm output for
      equivalent Haskell; (c) the Debian PPC modern GHC's asm
      output for equivalent Haskell (oracle for what *modern* GHC
      PPC codegen should look like).
- [ ] **Goal of phase:** modern GHC built with NCG enabled
      (`--enable-registerised`, no `--enable-unregisterised`)
      produces PPC asm matching the cross-validation oracle, and
      executables run correctly on Tiger.

### Phase 6 — Path B: revive the RTS Mach-O linker (GHCi)

Goal: the in-process Mach-O linker (`rts/linker/MachO.c`) loads
PPC `.o` files at runtime, enabling GHCi and Template Haskell.

This is the largest single chunk of the removal commit (267 lines
of MachO.c alone). It's also *only* needed for GHCi/TH; compiled
executables work without it.

- [ ] Restore PPC reloc kinds in `MachO.c`: `PPC_RELOC_VANILLA`,
      `PPC_RELOC_BR24`, `PPC_RELOC_BR14`, `PPC_RELOC_HI16`,
      `PPC_RELOC_LO16`, `PPC_RELOC_HA16`, `PPC_RELOC_LO14`, plus
      the scattered (`PPC_RELOC_*_SECTDIFF`) variants.
- [ ] Restore `LoadArchive.c` PPC handling.
- [ ] Restore `AdjustorAsm.S` PPC trampolines (FFI callbacks).
- [ ] Restore `StgCRun.c` PPC `StgRun`/`StgReturn` (the C-to-STG
      and STG-to-C transitions).
- [ ] **Goal of phase:** GHCi prompt on Tiger. `ghci -e '1+2'`
      prints `3`. `ghc -e 'putStrLn "hello"'` works.

### Phase 7 — Hardening and validation corpus

Goal: convince ourselves it really works, not just for hello world.

- [ ] Run GHC's own testsuite (`make test`) on Tiger. Triage
      failures into (a) genuine PPC/Darwin bugs we own,
      (b) general PPC bugs upstream owns (Trommler's note: PPC is
      maintained but big-endian sees less testing), (c) test-harness
      problems unrelated to our work.
- [ ] Cross-build a small representative library — `containers`,
      `bytestring`, `text` (probably), `parsec`. Each is a discrete
      experiment.
- [ ] Compare runtime perf vs (a) Path A 7.6.3, (b) `ghc` on Debian
      PPC for the same input. We don't expect to beat Debian PPC
      (it's been continuously maintained), but we want to be in
      the same order of magnitude.

### Phase 8 — Optional: 64-bit / Leopard / cabal-install

Aspirational, in priority order:

- `powerpc-apple-darwin9` (Leopard 10.5) variant. Mostly free if
  Tiger works — Leopard preserves the 10.4 userland and adds
  things like `getcontext`. Validate on `pbookg42`/`mdd`.
- `powerpc64-apple-darwin9` for G5 64-bit userland on Leopard. PPC64
  on Darwin was always niche; only do if a downstream consumer asks.
- A working `cabal-install` (the executable, not the library).
  Many modern `cabal-install` features depend on TH / GHCi /
  package-database invariants we may or may not have. Probably
  ships an old enough `cabal-install` from the binary-dist tarball.

## Risk register

| # | Risk | Mitigation |
|---|---|---|
| R1 | Path A 7.0.4 binary unobtainable (mirror rot) | Wayback Machine has a copy. Worst case, build 7.0.4 from source on Leopard PPC where prior native binaries existed. |
| R2 | Tiger libiconv ABI mismatch blocks Path A entirely | Build modern libiconv into `/opt`, `install_name_tool` GHC binary to use it. Or build 7.0.4 against Tiger's iconv. Already have `tiger.sh` install scripts that handle this kind of thing. |
| R3 | `evacuate(static): strange closure type` while climbing past 7.6.3 | Don't climb. Stop at 7.6.3 and switch to Path B. Trommler explicitly warned this would happen. |
| R4 | Cross-toolchain unavailable / broken on the modern host | Reuse cctools-port as the macports community does. Alternatively reuse the LLVM-7-Darwin-PPC project's toolchain — that project has gotten clang to produce correct PPC Mach-O. |
| R5 | GHC source from 9.2.x has drifted enough that 374e447 doesn't apply cleanly | Expected. The whole point of Phase 0's file-mapping doc is to enumerate the renames. Do the port hunk-by-hunk, not patch-apply. |
| R6 | `MachRegs.h` STG-register choices for PPC/Darwin conflict with Tiger's libSystem use of those registers | Cross-check against the Apple "Mac OS X ABI Function Call Guide" (PowerPC chapter) for which GPRs are caller- vs callee-saved on Darwin. Same trap the Go port doc (`golang-darwin8-ppc/plan.md`) calls out: r2 / r13 are "free" on Darwin in ways they aren't elsewhere; the original GHC PPC/Darwin port relied on this. |
| R7 | Unregisterised compiler too slow to be useful | Expected; that's why Phase 5 (NCG revival) exists. Unregisterised is a stepping stone, not a final state. |
| R8 | GHC RTS uses `getcontext`/`setcontext` (Leopard+) | Tiger doesn't have these. Inspect `rts/posix/OSThreads.c` etc. for use; if present, gate behind a Tiger ifdef and fall back to setjmp/longjmp or pthreads. The `imacg3-dev` skill calls this out as the canonical Tiger trap; openssl needed `no-async` for the same reason. |
| R9 | GHC RTS uses `clock_gettime` (Leopard+) | Same as R8. Use `mach_absolute_time` + `mach_timebase_info` and `gettimeofday` instead. |
| R10 | GHC RTS depends on `<Availability.h>` (Leopard+) | `imacg3-dev` skill has the canonical fix: rewrite to `<AvailabilityMacros.h>` + `MAC_OS_X_VERSION_*` defines. Will likely bite the RTS build first. |
| R11 | We forget that PPC is **big-endian** and a bug-hunt rabbit hole emerges from byte-order assumptions baked into modern GHC code that hasn't been exercised on a BE host since 8.8 | Keep the Debian/PPC oracle compiler running; any test that produces different output on Debian/PPC vs our Tiger build is a BE-vs-LE bug, not a Darwin bug. Trommler's GHC issue #16998 is the relevant tracker. |
| R12 | The Go port doc warns `pthread_setname_np` and `dispatch_semaphore` are 10.6+; GHC RTS may use them | Same workaround as R8/R9: ifdef + fallback. We won't know until the RTS compile failures show up. |
| R13 | `make install` of the Path-A 7.0.4 framework layout doesn't drop into `/opt/ghc-7.0.4/` cleanly | Manually replicate barracuda156's `.macports.ghc.state`-style trick: skip configure/build, hand-place files in destroot. Hours of fiddling, not days. |
| R14 | Maintainer-level questions (`bgamari`, `trommler`) require asking | Don't burn their time until we have specific blockers. Same rule as the LLVM project: only contact with concrete progress and absolute-blocker questions. Both are documented as responsive when approached well. |
| R15 | We accidentally produce a working compiler that miscompiles silently because we never wrote a test that would catch it | Phase 7's testsuite work is the antidote. Don't skip it. The canonical Haskell test program `nofib` is the right cross-validation oracle for codegen correctness. |

## Open questions (resolve in Phase 0)

1. **Which exact GHC version for Path B.** 9.2.x is the leading
   candidate; confirm against bootstrap-chain reality (what GHC can
   bootstrap what GHC).
2. **Cross-toolchain provenance.** Build our own (cctools-port
   route, slow but predictable), reuse iains' darwin-xtools (faster
   bootstrap, but documented as 'WIP'), or reuse the
   `llvm-7-darwin-ppc` project's clang? The LLVM-7 clang produces
   correct PPC/Darwin Mach-O; using it would be a nice cross-project
   reuse story.
3. **Do we need a Linux/PPC oracle host on the LAN?** Debian PPC in
   QEMU is plausible but slow; a real G4 running Debian (the
   `gentoo-g3` / `debian-g4` ssh aliases visible in `~/.ssh/config`
   suggest something like this exists on the network already).
4. **GMP source.** GHC has historically depended on GMP. Tiger
   doesn't ship one. `tiger.sh` should be able to install one, or
   build it natively. Confirm before Phase 4.
5. **Where to keep the working GHC fork.** A GitHub fork of
   `ghc/ghc` with branches per phase (`tiger-path-a-704`,
   `tiger-path-b-9.2-unreg`, etc.). Decide whether to mirror the
   official `gitlab.haskell.org/ghc/ghc` to `github.com/<us>/ghc`
   or work directly off a local clone.
6. **Llvm backend as an alternative to NCG.** GHC has an `-fllvm`
   path that emits LLVM IR and lets LLVM do codegen. The
   `llvm-7-darwin-ppc` project produces a working LLVM 7 with a
   PPC/Darwin target. **Could we skip Phase 5 entirely by routing
   GHC through that LLVM?** GHC 9.2 wants LLVM 9-12, so there's
   a version gap, but it might be smaller than the NCG-revival
   work. Worth a one-day spike in Phase 0.

## Reference links

### Primary

- GHC issue removing PPC/Darwin: <https://gitlab.haskell.org/ghc/ghc/-/issues/16106>
- The removal commit: <https://gitlab.haskell.org/ghc/ghc/-/commit/374e44704b64afafc1179127e6c9c5bf1715ef39>
- barracuda156's revival attempt (issue): <https://gitlab.haskell.org/ghc/ghc/-/issues/21371>
- MacPorts ticket #64698: <https://trac.macports.org/ticket/64698>
- Reddit thread: <https://www.reddit.com/r/haskell/comments/svwkv0/haskell_for_powerpc_mac/>

### Bootstraps and tools

- 6.10.4 binary: <https://downloads.haskell.org/~ghc/6.10-latest/maeder/ghc-6.10.4-powerpc-apple-darwin.tar.bz2>
- 7.0.1 binary: <https://downloads.haskell.org/~ghc/7.0.1/maeder/ghc-7.0.1-powerpc-apple-darwin.tar.bz2>
- 7.0.4 .pkg installer: <https://downloads.haskell.org/~ghc/7.0-latest/krabby/GHC-7.0.4-powerpc.pkg>
- GHC bootstrap source archives: <https://downloads.haskell.org/~ghc/>
- GHC cross-compiling wiki: <https://gitlab.haskell.org/ghc/ghc/-/wikis/building/cross-compiling>
- kencu's older-Darwin GHC repo: <https://github.com/kencu/ghc-for-older-darwin-systems>

### Related Anthropic / Claude PPC projects (sibling)

- LLVM 7 + Clang for PPC/Darwin: [`~/claude/llvm-7-darwin-ppc/docs/plan.md`](../../llvm-7-darwin-ppc/docs/plan.md) — produces working clang for our target; a possible LLVM backend for GHC's `-fllvm` path
- Go for darwin-8 PPC: [`~/claude/golang-darwin8-ppc/plan.md`](../../golang-darwin8-ppc/plan.md) — same target, similar archaeology problem; useful prior-art for ABI / RTS / runtime traps (especially §5)
- IonPower Node: [`~/claude/ionpower-node/docs/plan.md`](../../ionpower-node/docs/plan.md) — different language, same fleet, good template for the "scope is fixed, ecosystem is bottomless" problem

### Apple / Darwin reference

- Mac OS X ABI Function Call Guide (PowerPC chapter) — Apple
- Mac OS X ABI Mach-O File Format Reference — Apple
- xnu-792 source (Tiger kernel) — `osfmk/ppc/` for thread state

## Progress tracking

Same scheme as the LLVM-7 project. Layout:

```
docs/
  plan.md                       # this file — revised as we learn
  state.md                      # living "where are we right now" snapshot
  ref/                          # immutable reference material
    ghc-removal-commit-374e447.diff
    ghc-issue-16106-discussion.md
    macports-ticket-64698.md
  log/                          # dated session logs
    YYYY-MM-DD-<slug>.md
  experiments/                  # individual experiments, numbered
    NNN-<slug>.md
  notes/                        # topic-oriented notes
    codebase-tour.md
    file-mapping-86-vs-modern.md
    bootstrap-chain.md
    iconv-abi-mismatch.md
    ...
  patches/                      # patches, numbered
    NNNN-<slug>.patch
testprogs/                      # the small test corpus
external/                       # downloaded tarballs (gitignored)
```

`state.md` is the front door — updated end of every session, must
be readable in five minutes and tell the next reader (including
future-us) exactly what to do next.

Session logs and experiments follow the LLVM-7 conventions
(hypothesis, method, result, conclusion). Patches are individually
numbered so we can rebase / re-order / drop them as the GHC base
moves.

---

## Verification: fleet awareness and `imacg3-dev` skill

Per the request, confirming what's in scope:

**Fleet:** I'm aware of the full TigerTube PowerPC fleet, documented
at `~/TigerTube/docs/fleet/fleet.md` — primary Tiger hosts are
`pmacg3`, `imacg3`, `ibookg3`, `ibookg37`, `emac`, `imacg52`, plus
`pmacg5` (which dual-boots Tiger and Leopard); Leopard hosts are
`pbookg42`, `mdd`, and `pmacg5`'s Leopard partition. All reachable
as `macuser` over ssh with key-based auth and aliases in
`~/.ssh/config` on this host. Primary build target for this project
is **`imacg52`** (G5 2.0 GHz Tiger) — fastest single-CPU Tiger box,
appropriate for the multi-hour GHC self-builds; `pmacg5` (970MP
dual-core 2.3) is an even faster option if the dual-core
single-thread concerns documented in the fleet doc don't bite.
Wider fleet is the validation matrix for the resulting binaries.

**`imacg3-dev` skill:** I'm aware of and will load the skill at
`~/TigerTube/.claude/skills/imacg3-dev/SKILL.md` whenever working
on any Tiger host. The skill applies uniformly across every Tiger
machine in the fleet and covers the canonical Tiger gotchas that
will absolutely bite GHC bring-up: don't use `/bin/bash` (2.05b,
too old), don't use stock `curl` (TLS too old), don't use `/tmp`
(cleared at boot — use `/Users/macuser/tmp` instead), use perl
5.36 from `/opt` for any modern configure script, the
`Availability.h` → `AvailabilityMacros.h` rewrite, and the
`getcontext`/`setcontext`-are-Leopard-only trap. The skill also
documents `tiger.sh` for installing modern packages into `/opt`
and `tiger-rsync.sh` for the Tiger-rsync-protocol-27 quirk. All
of this is reused as-is from the prior PPC projects; nothing
needs to be re-invented at the environment layer.
