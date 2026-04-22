# GHC bootstrap chain on PowerPC/Darwin

GHC is a self-hosted compiler. To build version N you need a
working version M < N. Documenting the practical chain on
PPC/Darwin so we don't burn cycles trying impossible jumps.

## Theoretical chain (upstream policy)

GHC's
[official bootstrap policy](https://gitlab.haskell.org/ghc/ghc/-/wikis/building/preparation)
is "the immediately preceding version". In practice the gap is
wider — GHC tries to keep N-2 working as a bootstrap, and contributors
sometimes report wider hops working.

Per upstream's
[`docs/users_guide/bootstrap.rst`](https://gitlab.haskell.org/ghc/ghc/-/blob/master/docs/users_guide/bootstrap.rst)
in modern releases, the chain is:

| Build target | Min bootstrap GHC |
|---|---|
| 9.6.x | 9.2 |
| 9.4.x | 9.0 |
| 9.2.x | 8.10 |
| 9.0.x | 8.8 |
| 8.10.x | 8.6 |
| 8.8.x | 8.4 |
| 8.6.x | 8.0 |
| 8.4.x | 7.10 |
| 8.2.x | 7.10 |
| 8.0.x | 7.8 |
| 7.10.x | 7.6 |
| 7.8.x | 7.6 |
| 7.6.x | 7.0 |
| 7.4.x | 7.0 |
| 7.0.x | 6.10 |
| 6.10.x | 6.6 (C-based bootstrap, unrelevant after 7.x) |

So in theory: 6.10.4 → 7.0.4 → 7.6.3 → 7.10.3 → 8.0 → 8.2 → 8.4 → 8.6 → 8.10 → 9.2 → ...

## Empirical reality on PPC/Darwin

Per
[MacPorts ticket #64698](https://trac.macports.org/ticket/64698)
(barracuda156, 2022) and Trommler's commentary in
[GHC issue #16106](https://gitlab.haskell.org/ghc/ghc/-/issues/16106):

| Step | Result | Source |
|---|---|---|
| 6.10.4 binary install on Tiger | Untested by us; binary exists. Likely the same libiconv-ABI trap as 7.0.x. | (haskell.org binary archive) |
| 7.0.1 binary install on Tiger | **Fails.** libiconv ABI mismatch (binary needs libiconv compat 7.0.0, Tiger has 5.0.0). | barracuda156 |
| 7.0.4 .pkg install on Snow Leopard 10.6.8 | **Works.** | barracuda156 |
| 7.0.4 install on Tiger | Untested; same libiconv mismatch expected. Workaround in [`iconv-abi-mismatch.md`](iconv-abi-mismatch.md). | inferred |
| 7.0.4 → 7.6.3 source build on Snow Leopard | **Works end-to-end.** Hello world runs. | barracuda156 |
| 7.6.3 → 7.6.3 self-rebuild on Snow Leopard | **Fails:** `ghc-stage1: internal error: evacuate(static): strange closure type`. | barracuda156 |
| 7.0.4 → 7.4.2 on Snow Leopard | **Fails:** same `evacuate(static)` error. | barracuda156 |
| 7.0.1 → 7.7 on Snow Leopard | **Fails:** same. | barracuda156 |
| 7.6.2 → 7.8.x on Snow Leopard | **Fails:** same. | barracuda156 |
| 7.6.2 → 7.10.3 on Snow Leopard | **Fails:** same. | barracuda156 |
| (any) → 8.x on Snow Leopard PPC | **Untried** by barracuda156 because 7.x couldn't build itself. |
| GHC 8.8.4 on Debian/PPC (Linux) | **Works** (precompiled by Debian). | kencu, 2022 |

The wall is at **7.6.x on PPC/Darwin**. Trommler diagnoses this
generically (not specific to Darwin):

> 1. It is big-endian and that is not well tested (not at all in CI)
>    and we have had several big-endian bugs and even some still in
>    HEAD. See #16998.
> 2. PowerPC has weak memory consistency and there were also quite
>    a few race conditions that might lead to the heap corruption.
>    Though the consistency (determinism) in failures you report
>    seems to suggest that is not the case in the crashes you
>    observed.

For a project with our timeline, **the legacy ladder caps at
7.6.3**. Climbing past it (7.8 or higher) is open-ended bug
hunting in a compiler that hasn't been maintained since 2013. Not
worth the time vs the modern cross-bootstrap path.

## Path A (legacy) chain we'll attempt

```
external/ghc-7.0.4-powerpc-darwin.pkg     (the krabby binary)
    │
    │  install on Tiger (fix libiconv ABI mismatch first;
    │   see iconv-abi-mismatch.md)
    ▼
ghc-7.0.4 working on pmacg5 / imacg52
    │
    │  Bootstrap GHC 7.6.3 source, --with-macosx-deployment-target=10.4,
    │   GMP from /opt/gmp-6.2.1, libiconv from /opt/libiconv-1.16
    ▼
ghc-7.6.3 working on Tiger
    │
    │  STOP HERE.  Don't try 7.7+.
    ▼
Use 7.6.3 as a usable-but-frozen Haskell on Tiger.
```

Backup options if the 7.0.4 binary won't install on Tiger even
with libiconv surgery:
- 7.0.4 source build on Tiger using a **6.10.4 binary** as the
  bootstrap. (6.10.4 may have the same libiconv issue, but if
  bootstraps build clean we never have to install the broken
  binary, only run it once.)
- Cross-compile 7.0.4 to Tiger from Snow Leopard PPC (kencu has a
  ghc-7.0.4 working there, per the macports ticket).
- Cross-compile from a modern Linux/PPC host. Debian/PPC has
  ghc-8.8.4 working; an older Debian release likely has older GHC.

## Path B (modern cross-bootstrap) chain

```
modern Linux or macOS host with working GHC 9.0+
    │
    │  Cross-toolchain: powerpc-apple-darwin8-{gcc,ld,as}
    │  Source: ghc-9.2.x with our restored PPC/Darwin patches
    │  Configure: --target=powerpc-apple-darwin8
    │             --enable-unregisterised
    ▼
Stage-1 cross-compiler (runs on host, emits ppc Mach-O)
    │
    │  Cross-build the runtime libs (ghc-prim, base, integer-{gmp,simple},
    │  Cabal) for the target.  Bundle into a binary distribution.
    ▼
ghc-9.2-unreg binary distribution for ppc-darwin8
    │
    │  Ship to pmacg5; install at /opt/ghc-9.2-unreg/.
    │  Smoke-test on the small program corpus.
    ▼
ghc-9.2-unreg working on Tiger
    │
    │  Use as bootstrap for a registerised native build
    │  with --enable-registerised once the NCG is restored.
    ▼
ghc-9.2 (registerised) on Tiger
    │
    │  Add MachO.c restorations -> GHCi works
    ▼
Modern, fast Haskell on Tiger
```

The 9.2 → unregisterised → registerised → +GHCi sequence each is a
discrete deliverable. A user has a working compiler at every stage
after Phase 4.

## Why 9.2 and not 9.6 or HEAD

- **9.2 is closest in source layout to 8.6.** Less translation
  needed when porting the removal-commit hunks forward.
  `compiler/GHC/CmmToAsm/PPC/` exists in 9.2 with the same file
  names as 8.6's `compiler/nativeGen/PPC/`. By 9.6+ the modules
  have been refactored further and Hadrian is the only build
  system shipped (no `make`).

- **9.2 still has `make`-based build alongside Hadrian.** One
  fewer variable while debugging; we use `make` until things work,
  then optionally migrate to Hadrian.

- **9.2 is barracuda156's prior target.** Their stalled 9.2.2
  attempt is recoverable as reference material via the GHC issue
  tracker (#21371). We don't have to redo the asm-syntax-dialect
  research from scratch.

- **9.2 is an LTS series.** Better long-term reasoning about
  upstream merge-back if we ever try.

If 9.2 is too painful for some reason, fall back to **8.10**, which
is even closer to 8.6 in shape but sees less use.

## Tools needed at each stage

For **building 7.6.3 on Tiger** (Path A, Phase 2):
- `ghc-7.0.4` working (Phase 1 deliverable)
- `gcc-4.0.1` (system) or `gcc-4.9.4` (`/opt`)
- `make`, `autoconf`, `python` 2 — all in `/opt`
- GMP — `/opt/gmp-6.2.1` (or 4.3.2)
- libiconv — `/opt/libiconv-1.16`
- Several GB of disk under `/Users/macuser/tmp/` (pmacg5: 51 GB free; fine)

For **cross-bootstrapping 9.2.x for darwin/ppc** (Path B, Phase 3):
- A working modern GHC on the build host (any host with `ghcup`)
- `powerpc-apple-darwin8-gcc` cross-compiler. Either:
  (a) build via cctools-port + osxcross machinery,
  (b) use clang-from-`llvm-7-darwin-ppc` (sibling project),
  (c) use Iain Sandoe's `darwin-xtools`.
- The 10.4 SDK (`MacOSX10.4u.sdk`) — already on every Tiger host
  via Xcode 2.5; tarball in the LLVM-7 project's `external/`.

## Open questions

- Does 6.10.4 binary install/run on Tiger? If yes, we have a
  pure-Tiger bootstrap path (don't need to fix libiconv first).
  Quick experiment in Phase 1 to find out.

- What's the smallest modern GHC that bootstraps from 7.6.3? If
  it's 8.0, we can extend Path A by one rung "for free." If it
  needs 8.4+, we have to skip ahead via cross-compile. Per the
  table above, 7.6 → 7.10 is the canonical hop, but it's the one
  barracuda156 couldn't make. Maybe it works on Tiger when it
  didn't on Snow Leopard? Doubt it, but cheap to try.

- Trommler suggested cross-compiling **from MacPorts** (i.e. from
  a modern macOS host that has GHC). Investigate whether `ghcup`
  / `cabal` / `nix-shell` on Apple Silicon makes the bootstrap
  trivial vs going through a Linux/PPC oracle host.
