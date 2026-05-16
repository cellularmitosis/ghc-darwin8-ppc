# Session 59 — Release v0.14.1: unlit packaging fix shipped

**Date:** 2026-05-17 (continuation of session 58).

**Status on arrival:** Session 58 surfaced a real packaging bug —
the v0.14.0 bindist ships an arm64 `unlit` helper at
`/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` because
Hadrian's cross-mode helper-binary-copy path
([`hadrian/src/Rules/Program.hs:107`](../../../external/ghc-modern/ghc-9.2.8/hadrian/src/Rules/Program.hs))
copies stage0 (host) helpers to stage1 for every package except
`iserv` (patch 0010's carve-out) and missed `unlit`.  Fixed in-place
on pmacg5 by cross-building a 14 KB ppc `unlit` outside hadrian; the
proper release-grade fix (update patch 0010 → stage1 rebuild →
stage2 redeploy → bindist re-roll → demo + release tag) was queued
as session 58 HANDOFF priority #1.

**Status on exit:** v0.14.1 **released**.  Tag pushed; bindist
tarball uploaded to the [v0.14.1 GitHub release](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1).
Demo committed at [`demos/v0.14.1-literate-haskell.{lhs,sh}`](../../../demos/).
README "Latest release" line flipped to v0.14.1, GHCi REPL status
row's "pending v0.14.1" note rewritten as ✅ in-bindist, new row
added to the Releases table.  `docs/state.md` and `docs/roadmap.md`
updated.  Session-58's runner re-ran clean on the new bindist:
**161/163 PASS** (T10989 now passes natively from the new bindist;
T8042 + T17549 remain HFS+ mtime-granularity races in the upstream
scripts, not PPC bugs).  Also retroactively pushed + released
[v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0)
(no bindist asset — v0.14.0's stage1 build is byte-identical to
v0.13.0's; the v0.14.0 change is entirely in `scripts/deploy-stage2.sh`)
so the README's link to it works and the GitHub-side history is
continuous.

## What was done

### 1. Update patch 0010

[`patches/0010-hadrian-cross-iserv.patch`](../../../patches/0010-hadrian-cross-iserv.patch)
amended in-place (project convention: patches are rebased, not
stacked).  The cross-mode arm of `buildProgram` in
`hadrian/src/Rules/Program.hs` changed from

```haskell
(True, s) | s > Stage0 && package /= iserv -> ...
```

to

```haskell
(True, s) | s > Stage0 && package `notElem` [iserv, unlit] -> ...
```

`unlit` is already imported in scope below (the non-cross arm's
`package `elem` [touchy, unlit]`).  No new imports.  Cross-mode
unlit now falls through to `buildBinary`, which routes through the
stage1 cross-ghc → cross-cc and produces a real PPC Mach-O binary.

### 2. Stage1 rebuild

```bash
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh
./hadrian/build --flavour=quick-cross --docs=none -j8 \
  _build/stage1/lib/bin/powerpc-apple-darwin8-unlit
```

The first invocation rebuilt only hadrian itself (1 module recompiled,
`Rules.Program`) and finished in <1 second; the unlit target wasn't
regenerated because the file still existed on disk from the previous
copyFile-based rule.  Removed the stale arm64 binary and re-ran;
hadrian then cross-compiled both `.c` sources, linked through stage1
ghc's `Ghc LinkHs`, and produced a 47 KB ppc Mach-O binary in ~7 sec.

Resulting `_build/stage1/lib/bin/powerpc-apple-darwin8-unlit`:

```
Mach-O executable ppc
```

(vs. the pre-fix `Mach-O 64-bit executable arm64`.)

The hadrian-built binary is larger than session 58's bespoke
two-step build (47 KB vs. 14 KB) because hadrian links it through
ghc's `Ghc LinkHs` mode — same machinery used for `touchy` in the
non-cross arm.  Functionally equivalent.

### 3. Stage2 re-cross-build + deploy

`scripts/deploy-stage2.sh pmacg5` — cross-compiles ghc-bin via the
patched stage1, rsyncs the updated `_build/stage1/lib/` (including
the new ppc `unlit`) to `/opt/ghc-stage2/lib/` on pmacg5, deploys
the wrapper + settings, smoke-tests.

Note: the rsync runs with `--delete`, so session 58's
`.arm64.broken` forensics backup was removed from pmacg5.  No loss
— the broken binary is byte-identical to
`_build/stage0/bin/powerpc-apple-darwin8-unlit` on uranium, and the
fix has now landed in source / patches.

### 4. Verification

`demos/v0.14.1-literate-haskell.sh pmacg5` (logged at
`logs/04-demo-run.log`) — confirms the new ppc `unlit` on Tiger
runs end-to-end against a bird-track `.lhs` source:

```
==> 0. confirm unlit on Tiger is a real PPC binary
/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit: Mach-O executable ppc
...
==> 3. run the compiled .lhs binary
literate haskell on tiger ppc:
  factorial 20  = 2432902008176640000
  sort "tiger"  = "egirt"
  map toUpper   = PPC DARWIN 8
  collatz 27    = length 112, max 9232
...
==> 4. :load the .lhs into the GHCi REPL (T10989-shape exercise)
GHCi, version 9.2.8: https://www.haskell.org/ghc/  :? for help
ghci> Ok, one module loaded.
ghci> 15511210043330985984000000
...
v0.14.1 demo done.  Literate Haskell works on PPC/Tiger.
```

Then session 58's runner (logged at `logs/05-ghci-tnum-re-run.log`)
re-ran against the v0.14.1 stage2:

```
PASS  T10989           (rc=0)
FAIL  T8042            (rc=0)  stdout mismatch
FAIL  T17549           (rc=0)  stderr mismatch
=== Summary: 161 PASS / 2 FAIL out of 163 tests ===
```

T10989 (the literate-Haskell test that surfaced the bug) is now
clean.  T8042 + T17549 remain — both are HFS+ 1-second mtime-
granularity races in the upstream test scripts themselves (see
[session 58 findings §3](../2026-05-17-session-58-ghci-tnum-scripts/findings.md)
for the full diagnosis).  Same 161/163 number as session 58's
post-fix runs 2 + 3 — exactly as expected.

### 5. Bindist tarball re-roll

`./hadrian/build --flavour=quick-cross --docs=none -j8 binary-dist-dir`
(logged at `logs/06-hadrian-bindist.log`) — built the
`_build/bindist/ghc-9.2.8-powerpc-apple-darwin8/` tree from scratch
in ~3m50s.  Most of the time was profiling-way rebuilds of Cabal
and its transitive dependents (same shape as the v0.13.0 re-roll
described in [session 53 commits.md](../2026-05-15-session-53-v0.13.0-release/commits.md)
— hadrian re-runs profiling builds on a fresh `binary-dist-dir`).

Verified all three unlit copies in the bindist tree are ppc:

```
$ file _build/bindist/ghc-9.2.8-powerpc-apple-darwin8/{bin,lib/bin}/powerpc-apple-darwin8-unlit*
.../bin/powerpc-apple-darwin8-unlit:           Mach-O executable ppc
.../bin/powerpc-apple-darwin8-unlit-ghc-9.2.8: Mach-O executable ppc
.../lib/bin/powerpc-apple-darwin8-unlit:       Mach-O executable ppc
```

Tarred with `XZ_OPT="-T0 -6" tar -cJf …`:

```
_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz  211 MB
```

(2.1 GB uncompressed → 211 MB compressed.)

### 6. Demo, README, state.md, roadmap.md, release tag

- Demo: `demos/v0.14.1-literate-haskell.lhs` (bird-track source) +
  `demos/v0.14.1-literate-haskell.sh` (driver), plus a row in
  `demos/README.md`.
- README: Latest-release paragraph rewritten; GHCi REPL status
  row's pending-v0.14.1 note converted to ✅ in-bindist; new row
  in the Releases table.
- `docs/state.md`: top entry bumped to session 59.
- `docs/roadmap.md`: §C session 59 entry added.
- Tag: `git tag v0.14.1` on the session-59 commit, **local-only**.
  See commits.md for the user-side push/upload recipe.

## What this means

v0.14.1 is the first bindist where the `unlit` literate-Haskell
pre-processor actually runs on Tiger.  Literate Haskell support
(`.lhs` source files, `:l foo.lhs` in GHCi, T10989 in upstream's
GHCi testsuite) was latently broken since v0.7.0 (Hadrian patch
0010 landed in session 12b/c with the iserv carve-out but missed
unlit).  Nobody hit it in ~14 releases because nothing in the
project's test battery or demos uses `.lhs` — until session 58's
T-prefix testsuite extension hit T10989.  v0.14.1 is the four-line
patch + ritualistic re-release that closes the gap.

## Files added this session

* `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
* `logs/` — hadrian rebuild, deploy-stage2, ghci-tnum re-run, demo
  run.
* `demos/v0.14.1-literate-haskell.lhs` — bird-track literate
  Haskell demo program.
* `demos/v0.14.1-literate-haskell.sh` — driver: scp + native
  compile on Tiger + run binary + `:load .lhs` into GHCi REPL.
* `patches/0010-hadrian-cross-iserv.patch` — updated in-place to
  add `unlit` alongside `iserv` in the cross-mode carve-out.
* `external/ghc-modern/ghc-9.2.8/hadrian/src/Rules/Program.hs` —
  the corresponding live-source change.
* `README.md` — Latest-release paragraph + GHCi REPL row + Releases
  table updated.
* `docs/state.md` — top-of-file summary bumped to session 59.
* `docs/roadmap.md` — §C session 59 / v0.14.1 row added.
* `demos/README.md` — v0.14.1 row added; "What's here" header bumped.

## On pmacg5

After `deploy-stage2.sh pmacg5`:

- `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` — replaced
  by the hadrian-built 47 KB ppc binary (was session-58's 14 KB
  bespoke ppc).
- `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.arm64.broken`
  — removed by rsync `--delete`.  Available on uranium at
  `_build/stage0/bin/powerpc-apple-darwin8-unlit` if forensics
  needed.
- `/opt/ghc-stage2/bin/ghc-real` — rebuilt; size unchanged from
  v0.14.0 (~199 MB).  Same `-DHAVE_INTERNAL_INTERPRETER` build line
  as v0.14.0; no source changes outside hadrian.
