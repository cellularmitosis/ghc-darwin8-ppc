# 2026-04-22 — Phase 0 completion and Path A pivot

Overnight session. Target: make real progress against the plan
while the human sleeps; document everything; commit at logical
boundaries; make assumptions where needed to stay unblocked.

## Goal

Work through Phase 0 (reconnaissance/tooling) and attempt Phase 1
(install the prebuilt GHC 7.0.4 on Tiger) as per the plan.

## What happened

### Phase 0 — completed

Set up the repository skeleton: `git init`, `.gitignore`, and the
`docs/{ref,log,experiments,notes,patches}` subtree. First commit
`e7487dd` has plan + removal-commit diff + .gitignore.

Probed the fleet. 8 of 9 hosts reachable, `pmacg3` offline (not
blocking; we already have G3 coverage via imacg3/ibookg3/ibookg37).
Identified `pmacg5` as the right primary build host:
- 970MP dual-core 2.3 GHz, 2 GB RAM
- **51 GB free on /**, vs 7.8 GB on imacg52 — decisive for GHC
  self-builds
- Already has all the /opt deps we'll need (GMP, libiconv, libffi,
  ncurses, gcc 4.9 + 10.3 + 14, cctools, ld64-97)

Cloned GHC 8.6.5 (last-release-with-PPC/Darwin) and 9.2.8
(target for Path B forward-port) into `external/`. Sparse,
checkout-ref-only depth 1. 100 MB each.

Downloaded all the bootstrap candidates:
- `ghc-7.0.4-powerpc.pkg` (krabby .pkg, 164 MB)
- `ghc-7.0.4-src.tar.bz2` (24 MB)
- `ghc-7.0.1-powerpc-apple-darwin.tar.bz2` (maeder binary, 145 MB)
- `ghc-6.10.4-src.tar.bz2` (8 MB)
- `ghc-6.10.4-powerpc-apple-darwin.tar.bz2` (maeder binary, 111 MB)
- `ghc-7.6.3-src.tar.bz2` (56 MB)

Wrote six Phase 0 notes. Main insights captured in each:

- `codebase-tour.md` — catalog of every file the removal commit
  374e44704b touches, with line counts. Largest single piece is
  `rts/linker/MachO.c` (267 lines, the RTS dynamic linker; only
  needed for GHCi/TH, not compiled executables). Compiler side is
  only 217 lines across 6 files — well-bounded.
- `file-mapping-86-vs-modern.md` — 1-to-1 mapping from 8.6.5 file
  paths to 9.2.8 equivalents. Big finding: `rts/Adjustor.c` was
  reorganized into `rts/adjustor/Native<Arch>.c` files, and
  `rts/StgCRun.c`'s asm bodies moved to `rts/StgCRunAsm.S`. Means
  we can't just patch-apply the removal hunks; must re-emit against
  the modern layout.
- `bootstrap-chain.md` — documents theoretical and empirical
  bootstrap chain. Commits to the strategy: legacy ladder caps at
  7.6.3; modern target is 9.2.x.
- `ghc-704-pkg-anatomy.md` — what's inside the krabby .pkg, how
  the framework is laid out, how to install.
- `iconv-abi-mismatch.md` — documents the Tiger 5.0.0 vs
  Leopard 7.0.0 libiconv ABI split, three workaround strategies.
- `fleet-recon.md` — fleet reachability + pmacg5's capabilities.

Also built the test corpus: 12 programs (`01-hello.hs` through
`12-forkio.hs`) that exercise different compiler/RTS subsystems.
Portable back to GHC 7.0 so the same corpus validates either path.

Second commit `da20d84` lands all this.

### Phase 1 — attempted, failed, pivot documented

Expanded the 7.0.4 .pkg. Confirmed:
- Framework at `GHC.framework/Versions/7.0.4-powerpc/usr/{bin,lib,share}/`
- 27 Mach-O binaries inside, all referencing `/usr/lib/libiconv.2.dylib`
  with `compatibility version 7.0.0` (Leopard-era ABI)
- Wrapper `/usr/bin/ghc` is a shell script that hardcodes
  `/Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/...`
  paths and uses `/Developer/usr/bin/gcc` as the back-end C compiler

Attempted `install_name_tool -change /usr/lib/libiconv.2.dylib
/opt/libiconv-1.16/lib/libiconv.2.dylib` on the host side. **Failed**
— modern install_name_tool on arm64 macOS 15 refuses to process
the older 32-bit PPC Mach-O with "malformed load command 0
(cmdsize is zero)". Noted for the record; may come back to this
if we need to do the surgery on a Tiger host where cctools is
contemporary to the binary.

Pivoted to `DYLD_LIBRARY_PATH` wrapper approach. Wrote
`scripts/install-ghc-704-on-tiger.sh` that:
- extracts the framework into `/Library/Frameworks/`
- writes per-binary wrappers in `/usr/local/bin/` that set
  `DYLD_LIBRARY_PATH=/opt/libiconv-1.16/lib` before exec'ing

First attempt used `DYLD_FALLBACK_LIBRARY_PATH` by mistake —
didn't work because the install-name path exists on Tiger (just
at the wrong ABI version), so dyld errors out before FALLBACK
kicks in. Corrected to `DYLD_LIBRARY_PATH`; confirmed via
`DYLD_PRINT_LIBRARIES` that library resolution now succeeds.

**But then the binary bus-errors at startup** in libSystem's
`_malloc_initialize` during `hs_init` / `setFullProgArgv`. The
crash log stack trace:

```
EXC_BAD_ACCESS / KERN_PROTECTION_FAILURE at 0x00000000
Thread 0:
0  libSystem.B.dylib  _malloc_initialize + 1016
1  libSystem.B.dylib  calloc + 52
2  ghc                stgCallocBytes + 32
3  ghc                setFullProgArgv + 56
4  ghc                hs_init + 112
5  ghc                startupHaskell + 40
```

Null-deref inside Tiger's libSystem malloc-zone init. The binary
was built on Snow Leopard (gdb shows build tree under
`/Users/patriciajohnson/byron/ghc/7.0.4/`, and the libiconv compat
7.0.0 dep places it at ≥10.5) and its early init assumes a
libSystem layout Tiger doesn't have. Not fixable without rebuilding.

Sanity-checked: `ghc-pkg list` works fine (smaller binary, different
init path). `ghc --help`, `ghc --version`, `ghc --info` exit 0
with no output — these probably go through driver-level
early-return paths that never do full RTS init. `ghc --numeric-version`
and `ghc -B<topdir> --version` trigger full init and bus-error.

Also confirmed that the **6.10.4 maeder bin-dist has the same
problem**: `otool -L` shows `libiconv.2.dylib (compatibility
version 7.0.0)` — so 6.10.4 is also a Leopard+ build. `./configure`
fails at the `ghc-pwd` step because ghc-pwd is the first binary
that tries to run full Haskell RTS.

**Conclusion**: no prebuilt PPC/Darwin GHC on haskell.org runs on
Tiger. Path A as planned (install, bootstrap from 7.6.3) is
non-starter without a Leopard intermediate host.

Documented in `experiments/001-ghc-704-pkg-on-tiger.md` with the
full diagnosis. Also tried shipping the framework to `mdd` (Leopard
host) for the cross-check, but sudo requires a password there and
I can't answer password prompts overnight; deferred.

## Result

Phase 0 complete. Phase 1 attempted and blocked, with the root
cause identified and the pivot strategy documented.

**Substantive progress tonight:**
- Repository bootstrapped with full documentation scaffolding
- 6 Phase-0 notes, each load-bearing for later phases
- Test corpus designed (12 programs, portable GHC 7.0+)
- 5 of 6 plan questions resolved:
  - Q1 (primary build host): pmacg5 decided
  - Q2 (sdk strategy): SDK is already on every Tiger host
  - Q3 (when to contact maintainers): deferred till Phase 3 blocker
  - Q5 (rebuild time budget): measured — GHC 6.10.4 configure alone
    fails, so this is actually moot until Path B is live
  - Q7 (PPC32 vs 32+64): starting 32-bit, will revisit
- Critical negative result: no prebuilt GHC bin works on Tiger;
  Path A as planned is non-viable; Path B prioritized earlier
- Plan intact otherwise; just Phase ordering changes

**Revised phase order (implicit update to plan.md):**
- Phase 0: done
- Phase 1 (install 7.0.4 on Tiger): **SKIPPED** — see
  experiments/001
- Phase 2 (build 7.6.3 from 7.0.4): **SKIPPED**
- Phase 3 (cross-compile modern GHC unregisterised): **NOW THE
  NEXT WORK**
- Phases 4-8 unchanged

We will leave Phase 1/2 scripts and notes in place as "if someone
ever takes the Leopard-intermediate route" reference material.

## Addendum — Phase 3 prep also done tonight

Didn't stop at the pivot. Went further:

- **Cross-toolchain strategy** decided: reuse the sibling
  `llvm-7-darwin-ppc` project's clang on `indium`. Confirmed it
  produces PPC Mach-O for a trivial C program with `-target
  powerpc-apple-darwin8 -isysroot $SDK`.
- **Host GHC on indium installed**: 9.2.8 bindist from
  haskell.org (aarch64-apple-darwin, 179 MB xz) extracted at
  `~/tmp/ghc-9.2.8-aarch64-apple-darwin/`, `./configure
  --prefix=~/.local/ghc-9.2.8 && make install` ran cleanly.
  `hello.hs` compiles and runs on indium (arm64).
- **Discovered indium is LAN-only**: it can reach the fleet and
  uranium but not the internet. Captured in
  `notes/cross-toolchain-strategy.md`. Not blocking (we can always
  download on uranium and rsync).
- **Synced GHC 9.2.8 source tree to indium**: 275 MB (with
  submodules) at `~/tmp/ghc-modern/ghc-9.2.8-src/`. Also landed
  the git submodule update (libffi-tarballs, ghc-boot, etc.)
  in the local uranium clone and pushed to indium.
- **`./boot` attempt on indium**: silently exits after "Booting
  libraries/process/" without producing a `configure` script.
  Noted in state.md as the next-session starting point. Likely a
  five-minute fix (missing autotools deps, or env-var quirk).

## Next

Fix the `./boot` issue on indium, then run `./configure
--target=powerpc-apple-darwin8 --enable-unregisterised`, expect
it to fail at target detection, forward-port the configure.ac
hunk first.

See [`state.md`](../state.md) for immediate next-steps checklist
and the full resume recipe.

## Artefacts

Commits:
- `e7487dd` — plan + removal diff + .gitignore
- `da20d84` — Phase 0 notes + test corpus
- *(this session)* expected final commit — experiments/001, state.md,
  this log, install script, maybe a plan.md update marking the pivot

Files added this session:
- `docs/notes/{codebase-tour,file-mapping-86-vs-modern,bootstrap-chain,iconv-abi-mismatch,ghc-704-pkg-anatomy,fleet-recon}.md`
- `docs/experiments/001-ghc-704-pkg-on-tiger.md`
- `docs/state.md`
- `docs/log/2026-04-22-phase0-and-path-a-pivot.md` (this file)
- `docs/ref/ghc-removal-commit-374e447.diff` (from download)
- `scripts/install-ghc-704-on-tiger.sh`
- `testprogs/{01..12}-*.hs`, `testprogs/run-all.sh`, `testprogs/README.md`
- `external/ghc-{6.10.4,7.0.1,7.0.4}-*` (gitignored)
- `external/ghc-8.6.5/` (gitignored, shallow clone)
- `external/ghc-modern/ghc-9.2.8/` (gitignored, shallow clone)

Machines touched:
- uranium (this Mac): all the writing, downloading, git
- pmacg5: framework install attempts; it's sitting at
  `/Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/`
  doing nothing harmful but also nothing useful
- imacg52, pmacg5, imacg3, ibookg3, ibookg37, emac: probed for
  recon, nothing mutated
- mdd: attempted install, failed on sudo password
