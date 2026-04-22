# Fleet recon — 2026-04-22

Snapshot of the PowerPC fleet as observed at the start of this
project. Captured via SSH probes from uranium.

## Reachability sweep

```
imacg3   : OK 10.4.11 powerpc
imacg52  : OK 10.4.11 powerpc
pmacg5   : OK 10.4.11 powerpc          ← currently booted into Tiger
ibookg37 : OK 10.4.11 powerpc
emac     : OK 10.4.11 powerpc
ibookg3  : OK 10.4.11 powerpc
mdd      : OK 10.5.8  powerpc           ← Leopard
pbookg42 : OK 10.5.8  powerpc           ← Leopard
pmacg3   : timed out, no route          ← off / disconnected
```

8 of 9 attempted hosts reachable. Tiger fleet (darwin-8) is
solid. Leopard fleet (darwin-9) up. **`pmacg3` is down and we
will not block on it** — its role is G3-baseline validation, and
we already have G3 coverage via `imacg3`, `ibookg3`, `ibookg37`.

## Primary build host: `pmacg5`

PowerMac11,2 (Late 2005 PCI-E dual-core 970MP @ 2.3 GHz, 2 GB
PC2-4200, GeForce 6600). Currently booted into Tiger 10.4.11
on `/dev/disk0s5` (Leopard partition exists on `/dev/disk0s3` per
the LLVM-7 project notes; can be selected via `bless --setBoot`).

Resources:
- 2 cores, 2 GB RAM
- **51 GB free on /** — comfortable for GHC self-builds
- `tiger.sh -j` reports `-j2` — can use parallelism
- `tiger.sh --cpu` → `g5`, `tiger.sh -mcpu` → `-mcpu=970`

This is the right primary build host for this project. The original
plan tentatively named `imacg52`; **switching to `pmacg5`** because
of the disk headroom (51 GB vs 7.8 GB on imacg52) and the second
core. The original plan's caveat about dual-core single-thread
migrations from the `mdd` decode-bench finding doesn't apply much
here — GHC's `-jN` is genuinely parallel and benefits from the
extra core; thread migration cost is small relative to GHC compile
unit duration.

`imacg52` (G5 2.0 single-core, 7.8 GB free) becomes secondary
build / validation host.

## Pre-installed deps on pmacg5

`/opt` already populated with most of what we need:

- **C toolchains:** `/opt/gcc-4.9.4`, `/opt/gcc-10.3.0`, `/opt/gcc-libs-4.9.4`
- **GMP:** `/opt/gmp-4.3.2`, `/opt/gmp-6.2.1` (GHC needs 5+; 6.2.1 is the right one)
- **libiconv:** `/opt/libiconv-1.16`, `/opt/libiconv-bootstrap-1.16` (the modern compat-7 ABI)
- **libffi:** `/opt/libffi-3.4.2` (newer GHC may use it for adjustors)
- **ncurses:** `/opt/ncurses-6.3` (for ghci REPL)
- **python:** `/opt/python-3.11.2` (modern GHC needs python; old GHC is fine)
- **System gcc:** `/usr/bin/gcc-4.0.1` (Apple GCC 4.0.1, the canonical Tiger C compiler)
- **Linker:** `/opt/cctools-667.3`, `/opt/ld64-97.17-tigerbrew` (modern alternative
  linkers if the system ld balks)
- **SDKs:** `/Developer/SDKs/MacOSX10.4u.sdk`, `MacOSX10.3.9.sdk`

Same package set on `imacg52`.

What we DON'T have anywhere yet:
- Any GHC binary
- LLVM (would need for `-fllvm` backend; the
  `llvm-7-darwin-ppc` sibling project produces this)

## /Users/macuser/tmp clutter

`/Users/macuser/tmp` on each Tiger host has accumulated artefacts
from prior projects (TigerTube source, ionpower-node mozjs build,
chicken-scheme bootstrap material, etc.). **Don't delete anything**;
those projects are also active. We'll create our own
`/Users/macuser/tmp/ghc/` subdirectory for our work.

## SDKs and Xcode

`/Developer/SDKs/MacOSX10.4u.sdk` — present, owned by root, untouched
since Oct 2007. This is the canonical Tiger SDK (10.4 SDK is in
Xcode 2.5; the "u" suffix means "universal", supports both ppc and
i386 host slices). For our purposes pure-PPC.

`MacOSX10.3.9.sdk` is also present — older still, irrelevant to us
unless something insists on building against 10.3. (Doesn't apply
to GHC.)

## Workflow conventions inherited from imacg3-dev skill

All Tiger work follows the imacg3-dev playbook:
- ssh in via `ssh pmacg5` (key auth, ControlMaster on)
- Long builds: write a script in `/Users/macuser/tmp/ghc/`, launch
  in background, poll with `tail` and `ps`. Don't hold a foreground
  ssh for 6 hours.
- Use `/opt/tigersh-deps-0.1/bin/bash` (3.2) for shebangs in our
  build scripts. `/bin/bash` (2.05b) is too old.
- Use `/opt/tigersh-deps-0.1/bin/curl` with `--cacert /Users/macuser/tmp/cacert-2026-03-19.pem`
  for HTTPS downloads from Tiger.
- File transfer: `~/bin/tiger-rsync.sh` from uranium (NOT plain
  rsync — Tiger ships an old wire protocol).
- Perl: `/opt/perl-5.36.0/bin/perl` if needed (system 5.8.6 is too old
  for modern Configure scripts; GHC 7.6.3 era should be fine with 5.8).

## Validation matrix (final binaries)

Once we have a GHC running on `pmacg5`, validate produced binaries
on every reachable host. The matrix:

| Host | CPU | AltiVec | Why test here |
|---|---|---|---|
| pmacg5 | 970MP dual 2.3 | yes | Build host — must work here |
| imacg52 | 970 single 2.0 | yes | G5 single-core, baseline G5 |
| ibookg37 | 750fx 900 | no | G3 reference |
| ibookg3 | 750fx 900 | no | G3 alternate |
| imacg3 | 750cx 600 | no | Smaller G3 |
| emac | 7447a 1.42 | yes | G4 baseline |
| (pmacg3) | 750 400 | no | (when it's back online) Oldest G3 |

Leopard hosts (`mdd`, `pbookg42`) are darwin-9 — out of primary
scope but useful for cross-validation of "does our compiler also
produce something that works on Leopard PPC."

## Snapshots saved

Raw probe outputs from this session captured in
[`log/2026-04-22-fleet-recon.md`](../log/2026-04-22-fleet-recon.md).
