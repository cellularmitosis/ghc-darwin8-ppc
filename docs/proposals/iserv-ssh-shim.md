# Proposal — iserv via ssh-piped local-iserv

**Goal:** TemplateHaskell splices on Tiger without the
`iserv-proxy` / `remote-iserv` network plumbing.
**Status:** proposal only; would take ~1 session of focused work.
**Owner:** unassigned (next iserv-related session picks up).

## Why a shim instead of the official architecture

GHC's documented cross-compile iserv path uses three components
talking over TCP:

```
host: ghc ↔ iserv-proxy  ↔  TCP  ↔  remote-iserv (target)
```

Both sides need the `network` Hackage package built for their
respective platform.  On our target (Tiger 10.4), the SDK lacks
`SOCK_CLOEXEC` (added in 10.7), so `network` builds need a vendored
fork — same deal we hit for the cabal `network-echo` example in
session 7 (where we sidestepped by pinning `network < 3.0`).  For
hadrian-built `libiserv`, the fix would be more invasive.

A simpler path: skip TCP entirely.  Run a stock `iserv` on Tiger and
spawn it through SSH so that ghc on the host sees a normal
local-pipe iserv subprocess.

## Architecture

```
host: ghc  ──spawns──►  pgmi-shim.sh  ──ssh stdio──►  iserv (Tiger)
        ▲                                                  │
        └──────── binary protocol over fd 3/4 ◄────────────┘
```

`pgmi-shim.sh` is a tiny wrapper that:
1. Reads ghc's two pipe fds (read-fd, write-fd).
2. Opens an ssh connection to `$PPC_HOST` invoking `iserv 0 1` (so
   iserv's "wfd1" is its stdout, "rfd2" is its stdin).
3. Reads from ghc's read-fd, writes to ssh's stdin.  Reads from
   ssh's stdout, writes to ghc's write-fd.
4. Forwards exit code on close.

ghc treats it as `-pgmi=pgmi-shim.sh`.  iserv on Tiger sees normal
stdio.  The binary protocol flows transparently in both directions.

## Pieces to build

1. **PPC `iserv` binary.**  Hadrian has `[ iserv | not cross ]` in
   `hadrian/src/Settings/Default.hs:125`.  Flip that for the
   `quick-cross` flavour to include iserv in the target build.
   - Watch out: `iserv` depends on `ghci`, `libiserv`, `binary`,
     `bytestring`, `containers`, `deepseq`.  All of these are
     already built for PPC in our cross-bindist.
   - `libiserv` itself needs `iserv` flag toggling — make sure we
     don't accidentally pull in `network` (controlled by the
     `network` cabal flag, default off).

2. **`pgmi-shim.sh`.**  ~30 lines of bash:
   ```bash
   exec ssh -q $PPC_HOST $REMOTE_ISERV_PATH 0 1
   ```
   Plus PATH plumbing in `lib/settings`'s "Use interpreter" path.

3. **install.sh integration.**  Add `--iserv` flag that ships the
   PPC-built iserv to the user's Tiger box and writes the shim
   pointing at it.

4. **Test.**  Pick a tiny TH splice, e.g.:
   ```haskell
   {-# LANGUAGE TemplateHaskell #-}
   module Main where
   import Language.Haskell.TH
   $(stringE "compiled at TH-time on Tiger")
   ```
   Cross-compile + ship + run, expect the literal in the binary.

## Risks

- **Binary protocol is fragile to non-pipe stdio.**  iserv expects
  pipe semantics; ssh will buffer stdout differently.  May need
  `-T` (no tty) and possibly a small framing wrapper.
- **Tiger's iserv might want too much RAM.**  PowerMac G5s have
  enough; older G4s might not.  Test on pmacg5 first, document
  hardware floor.
- **GHCi REPL still needs in-process iserv.**  This shim only
  unblocks `-fexternal-interpreter` (and TH); a true `ghci` REPL
  on Tiger still wants stage2 working (roadmap B).

## Effort estimate

- 12b-1: build iserv for PPC and verify it runs on Tiger (~half day).
- 12b-2: pgmi-shim.sh + install.sh wiring (~half day).
- 12b-3: TH end-to-end test in the test battery + docs (~quarter day).

Total: 1 day if no surprises, 2 days if the binary protocol over
SSH stdio needs a framing wrapper.

## Why not just build the proxy/remote trio first?

We could.  But:
- More moving parts (3 binaries instead of 1 + a shim).
- network-package patching for two builds.
- The remote-iserv binary depends on libiserv with `-fnetwork`.

Once the shim works, we can revisit the proxy/remote architecture if
it turns out to have a real advantage (e.g. running splices on
multiple Tiger hosts at once).
