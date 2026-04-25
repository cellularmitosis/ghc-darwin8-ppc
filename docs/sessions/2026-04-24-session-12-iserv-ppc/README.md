# Session 12 — iserv plumbing for TemplateHaskell

**Date:** 2026-04-24.
**Starting state:** v0.6.0 released.  PPC Mach-O runtime loader works
end-to-end for hand-compiled C `.o`s.  TemplateHaskell still doesn't
work because the host ghc has no way to talk to a target-side
interpreter.
**Goal:** get TH splices working on Tiger via the
`iserv-proxy` / `remote-iserv` over-the-network architecture (or a
simpler ssh-piped variant).
**Ending state (session 12a):** found and fixed a pre-existing 9.2.8
loader bug that prevented loading real Haskell `.o`s; v0.6.1 cut.
Full iserv plumbing pushed to 12b+.

## Session 12a — Haskell-`.o` loader test (✅ shipped as v0.6.1)

The simple greeter.c test in v0.6.0 covered VANILLA + BR24-with-jump-
island, but didn't exercise PPC's HI16/LO16/HA16 halves or scattered
SECTDIFF — those are how Haskell's PPC32 codegen emits 32-bit address
constants.  Wrote a Haskell module Greeter.hs that produces those
relocs (261 in __text, plus a fistful in __const, __data, __eh_frame,
__nl_symbol_ptr, __mod_init_func), and a HaskellDriver.hs that loads
it.

### The bug

First attempt ran into:
```
haskell-driver: internal error: checkProddableBlock: invalid fixup
in runtime linker: 0x8fce84
```

Root cause: a *pre-existing* 9.2.8 bug in `resolveImports()` (handler
for `__la_symbol_ptr` / `__nl_symbol_ptr` / `__pointers` /
`__jump_table`).  It writes through `(oc->image + sect->offset)`,
which was correct for the old monolithic-image layout (where the
whole `.o` got copied to a single contiguous in-memory region).  But
9.2.8 restructured to per-section mmap — each section now lives at
its own independent address (`oc->sections[i].start`), and the
original `oc->image` is still around but isn't where the writable
section copy lives.  Writing to `oc->image + sect->offset` either
hits the original read-only image (unproddable) or a totally
unrelated address.

The bug had been latent because:
- Modern macho on aarch64 / x86_64 doesn't generate `__nl_symbol_ptr`
  in the same way; non-cross test coverage is hosted elsewhere.
- Our v0.6.0 C test was a single function with an external `puts`
  call routed via a BR24 jump-island, never touching `__nl_symbol_ptr`.
- A real Haskell `.o` does use it, heavily.

### The fix

Added a `Section *sect_in_mem` parameter to `resolveImports` and
write through `sect_in_mem->start` instead of `oc->image + sect->offset`.
Updated all 3 callers in `ocResolve_MachO`.

### Result

```
$ ./tests/macho-loader/run-haskell.sh
[1/3] cross-compiling Greeter.hs to a PPC Haskell object...
[2/3] cross-compiling HaskellDriver.hs...
[3/3] shipping to pmacg5 and running...
initLinker: ok
loadObj "Greeter.o" => 1
resolveObjs => 1
lookupSymbol(_Greeter_haskellAnswer_entry) => 0x008f9040
lookupSymbol(_Greeter_haskellGreet_entry) => 0x008f98b0
test ok: Haskell .o loaded, resolved, and symbols found
PASS: macho-loader handles real Haskell .o.
```

Patch 0009 grew from 389 → 461 lines (just the resolveImports
parameter change + the Tiger-side call updates).

This validates that all the reloc paths I ported in v0.6.0 actually
work for Haskell-emitted code.  HI16/LO16/HA16 (both scattered and
non-scattered), scattered SECTDIFF/LOCAL_SECTDIFF — all green.

## Session 12b — iserv (⏸ multi-session)

For TH end-to-end we need the host ghc to be able to evaluate splices
that target PPC.  GHC's documented approach for cross-compile is the
**iserv-proxy + remote-iserv** pair:

```
host (uranium arm64)                target (pmacg5 PPC Tiger)
─────────────────────               ───────────────────────────
ghc -fexternal-interpreter ──┐      ┌── remote-iserv (PPC binary)
  -pgmi=iserv-proxy ─────────┼─────►│   listening on :5000
                             │  TCP │
                             └──────┘
```

Build inputs:
- `iserv-proxy` — host arm64 binary, talks to `remote-iserv` over
  TCP, relays the binary protocol to/from host ghc over pipes.
- `remote-iserv` — PPC binary, listens on a port, executes splices,
  uses our restored runtime loader to materialize compiled splice
  modules.
- `libiserv` — shared library, needed for both host and target
  builds (for protocol code).

### Blockers for 12b

1. **`network` package** — both `iserv-proxy` and `libiserv -fnetwork`
   pull in the `network` Hackage package.  Tiger's 10.4 SDK lacks
   `SOCK_CLOEXEC` (added in 10.7); session 7 worked around this by
   pinning `network < 3.0` for cabal-based builds.  We'd need the
   same in hadrian's libiserv build, which is more invasive.
2. **Hadrian gates** — `hadrian/src/Settings/Default.hs:125-126`
   currently has `[ iserv | not cross ]` and `[ libiserv | not cross ]`.
   Need to flip those for our cross flavour, then handle the
   network-dep fallout.
3. **iserv-proxy needs a target-aware port** — the proxy itself is a
   regular host-side Haskell program; should compile with our normal
   bootstrap ghc 9.2.8 just fine.  But it depends on `libiserv` and
   `ghci`, so we'd need those in the host's package db too.

### Alternative: ssh-piped iserv

A pragmatic shortcut: skip the network architecture entirely.
Build just `iserv` (the local-pipe variant) for PPC.  Spawn it as
`ssh pmacg5 /tmp/iserv <r-fd> <w-fd>` from a small `pgmi-shim.sh`
wrapper that uses `ssh -o ServerAliveInterval=...` to keep the
session alive and forwards stdio.  ghc treats it as a local process;
the wrapper hides the SSH entirely.

This avoids the network-package problem and the iserv-proxy build
entirely.  Probably 1 day of plumbing.

Filed as a sub-proposal under [docs/proposals/iserv-ssh-shim.md](../../proposals/iserv-ssh-shim.md).

### Hand-off to 12b

Try the ssh-shim route first — minimal new code, leverages our
working ssh+scp infrastructure.  If that snags on iserv's expectation
of a real fd (not a pipe-through-ssh), fall back to the proxy/remote
trio with the network workaround.

## Where we are after session 12a

- Loader: tested with C and Haskell `.o`s; all reloc types covered.
- Tarball: v0.6.1 = v0.6.0 plus the resolveImports per-section-mmap fix.
- Tests: `run.sh` (C) and `run-haskell.sh` (Haskell) both pass.
- iserv: scoped, awaiting an implementation session.
