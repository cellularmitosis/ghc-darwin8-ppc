# Session 2 — bindist installer (roadmap D)

**Date:** 2026-04-24.
**Starting state:** v0.2.0 tagged.  Cross-bindist tarball builds and
passes 21/25 tests.  No installer — users currently have to manually
rewrite `lib/settings` and symlink our scripts.

**Goal:** ship a working `./install.sh --prefix --ppc-host` that makes
installing the bindist as painless as untar + run + smoke-test.

**Ending state:** *(to be written at EoS)*

## Scope decisions

The bindist as shipped contains the arm64 cross-compiler binaries + PPC
target libraries + a `settings` file with absolute paths baked in.  It
does NOT contain:

- Our `scripts/ppc-cc.sh` / `ppc-ld-tiger.sh` / etc. wrappers.
- cctools-port binaries (ld/ar/nm/otool/etc).
- clang 7.1.1 + `MacOSX10.4u.sdk`.
- Host GHC.

Bundling all of these would push the tarball from 117 MB to ~500–800 MB.
Phase 1 install-script strategy instead:

- **Bundle** our wrapper scripts into the tarball under `scripts/`.
- **Require** the user to have cctools-port, clang-7 + SDK, host GHC
  already available.  The installer detects these and exits with clear
  error messages if any are missing.
- **Verify** ssh connectivity to the user's PPC box.  Detect Tiger's
  gcc + gmp paths via `ssh <host> 'ls /opt/gcc14/bin/gcc'` etc.
- **Rewrite** the absolute paths in `lib/settings` to point at what
  the installer found on this host.

Phase 2 (future) can bundle more, trading tarball size for UX.

## Plan

1. Modify hadrian's bindist or post-process: add a `scripts/`
   subdirectory to the tarball containing `ppc-cc.sh`, `ppc-ld-tiger.sh`,
   `ppc-ld-fake.sh`, `ppc-ld-shim.sh`, `tiger-config.site`,
   `install_name_tool` shim.
2. Write `install.sh` that:
   - Parses `--prefix`, `--ppc-host`, `--clang`, `--sdk`, `--cctools`
     (all optional, auto-detect where possible).
   - Checks prerequisites + prints a summary.
   - Copies the extracted tree to `$PREFIX`.
   - Rewrites `$PREFIX/lib/settings` with the correct absolute paths.
   - Writes a small `bin/powerpc-apple-darwin8-ghc` wrapper that
     sources the right env.
   - Runs a hello.hs smoke test; ssh's the binary to the PPC box and
     executes, confirms output.
3. Test the installer in a scratch `~/tmp/ghc-install/` on uranium
   itself — simulate an "other user" install.
4. Regen the bindist tarball with scripts/ included; re-release as v0.3.0.

## Out of scope

- Homebrew formula (phase 3).
- Bundling cctools/clang/SDK (phase 2).
- Automated prereq installation via brew / apt / etc.

*(rest of this README written at EoS)*
