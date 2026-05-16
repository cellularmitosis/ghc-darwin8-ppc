# Handoff from session 58 → session 59

**For:** the next claude session.
**From:** session 58 — extended verification milestone + packaging
bug repair.  161/163 PASS on the curated T-prefix subset of
upstream's `testsuite/tests/ghci/scripts/all.T`.  Real packaging
bug surfaced (Hadrian copies the host's `unlit` binary into the
cross-mode bindist with a `powerpc-apple-darwin8-` prefix);
repaired in-place on pmacg5 via a cross-built ppc `unlit`.
No new patches, no source changes, no release tag.

**Recommended pickup:** **v0.14.1 release** — properly fix the
unlit packaging bug in the Hadrian build, rebuild stage1 + stage2,
re-roll the bindist, ship.  This is the highest-priority follow-up
because it's a real bug in v0.14.0's binary, and we've already
done all the diagnosis + prototyped the fix.

## ✅ SESSION EXIT STATE

* No GHC source-tree changes (no edits under `external/`,
  `patches/`).
* No new release tag.  v0.14.0 still the latest.
* Stage2 ghc-real on pmacg5 unchanged (still the v0.14.0 binary,
  ~199 MB).
* `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` REPLACED
  on pmacg5 with the session-58-cross-built ppc binary (14 KB).
  Original arm64 helper preserved as
  `powerpc-apple-darwin8-unlit.arm64.broken` for forensics.
* New `docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/`
  dir with the run harness + unlit cross-build script + the
  built ppc binary + per-test logs.
* README + state.md + roadmap.md updated.

## TL;DR — what session 58 found

1. **The v0.14.0 REPL passes the T-prefix subset of ghci script
   tests, including all six TH-from-REPL regressions.**
   `T4127`, `T4127a`, `T5566`, `T8831`, `T10466`, `T11098` — every
   TemplateHaskell-driven-through-the-REPL regression in
   upstream's testsuite — PASS on PPC/Tiger.  This was the
   *actual* concern behind session 57 HANDOFF's priority #1
   (which talked about `req_th` annotations that don't exist in
   the ghci/scripts subdir).

2. **The v0.14.0 bindist ships an arm64 `unlit` helper.**
   Hadrian's `Rules/Program.hs` cross-mode copies stage0 (host)
   binaries to stage1 for every package except `iserv`
   (patch 0010 carved iserv out but missed `unlit`).  The
   resulting binary at `/opt/ghc-stage2/lib/bin/powerpc-apple-
   darwin8-unlit` is the build-host's arm64 unlit with a ppc
   filename prefix — it can't execute on Tiger.  Literate
   Haskell support (`.lhs` files, the `:l foo.lhs` path in
   GHCi) is broken in v0.14.0.  This has been latent since
   v0.7.0 (when patch 0010 landed).

3. **T17549 and T8042 fail due to HFS+'s 1-second mtime
   granularity.**  Both are `writeFile X → :load X → writeFile X
   → :reload` patterns where the second writeFile lands in the
   same second as the initial :load, so :reload skips.  T1914
   has the same shape but explicitly bumps mtimes with `:! touch
   -t` — T8042 / T17549 omit it.  Not PPC bugs; upstream
   test-design issues.

## What to try next, in priority order

### Top: v0.14.1 release — bindist re-roll with corrected unlit

The work is small but ritualistic.  Specifically:

1. **Patch 0010 update.**  Change the cross-mode arm of
   `hadrian/src/Rules/Program.hs:108` from
   ```haskell
   (True, s) | s > Stage0 && package /= iserv -> ...
   ```
   to
   ```haskell
   (True, s) | s > Stage0 && package `notElem` [iserv, unlit] -> ...
   ```
   (`unlit` is imported in the existing pattern below — no new
   imports needed).  Either edit patch 0010 in place to reflect
   this, or add a new patch 0017 if we want a clean lineage.
   Patches in this project are typically rebased rather than
   stacked, so edit-in-place is fine.

2. **Stage1 rebuild.**  `hadrian -j build` against the corrected
   patch.  ~16 minutes on uranium.

3. **Stage2 re-cross-build.**  `scripts/deploy-stage2.sh` —
   re-cross-compiles the stage2 ghc-real with the corrected
   stage1, packages, and deploys.  Verify the unlit in the new
   bindist is `Mach-O executable ppc`.

4. **Bindist tarball + install verification.**  Re-roll
   `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`, run
   `install.sh` on a clean Tiger box, verify
   `cat /opt/ghc-darwin8/lib/bin/powerpc-apple-darwin8-unlit | file`
   says ppc.

5. **Demo + README + release tag.**  Per project workflow
   (`CLAUDE.md` → "Release workflow"):
   - Demo: `demos/v0.14.1-literate-haskell.{hs,sh}` — write a
     short program that round-trips through `unlit`
     (e.g. compile a `.lhs` with the bird-track style, run on
     Tiger, observe expected output).  The point is to show
     v0.14.1 unblocks something v0.14.0 couldn't.
   - README: bump "Latest release" to v0.14.1, add a Releases
     row.
   - Tag: `git tag v0.14.1` with release notes mentioning
     T10989 + the Hadrian patch fix.

6. **Re-run session 58's runner** to confirm 162/163 (T10989 ✅
   without the manual unlit deploy; T8042 + T17549 still
   harness-side flakes).

### Second: skip T8042 / T17549 from the runner (cosmetic)

If we want a clean "X / X PASS" headline in future runs, exclude
T8042 and T17549 from the TESTS list in
`scripts/run-ghci-tnum.sh` with a comment pointing to
[findings.md §3](findings.md).  Session 58 chose honesty over
clean numbers; that's a defensible reversal.

### Third: extend the runner to handle more tests/ghci/scripts/ annotations

Untouched groups, in order of likely-value:

- `extra_run_opts` tests (T9878b, T12091, T17500, T17669) — thread
  RTS flags through.  ~4 more tests.
- `extra_hc_opts` tests (T2452, T2182ghci2, T9293, T13385, T14342,
  T16563) — thread compiler flags through.  ~6 more tests.
- `reqlib` tests (T5979 — needs `transformers`).  ~1 more test.
- `pre_cmd` tests (T5975a/b, T6106, T19650) — needs a Makefile or
  shell prelude.  ~4 more tests.
- `req_interp` / `makefile_test` family — different harness shape;
  not script-driven.

If all of these were unlocked, we'd cover ~175-180 of the ~209
ghci scripts.  The rest are makefile-driven (`req_interp`) or
genuinely broken upstream (`expect_broken`).

### Fourth: bug-numbered T<num>/ subdirs (session 57 HANDOFF
priority #2)

`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/T11827/`,
`T13786/`, `T16670/`, `T18060/`, `T18071/`, `T18262/`, etc.  Each
has its own Makefile driving a small scenario.  Less uniform
than `scripts/`; each one may need bespoke setup.  Cherry-pick
the ones whose Makefiles are short.

### Fifth: prog001..prog019 multi-module `:load` tests

(Session 57 HANDOFF priority #3.)  Multi-module `:load` exercise.
Each is a directory with several `.hs` files and a `.script`.
Tests `:load`'s multi-module dependency tracking + reload
invalidation.  Probably all pass, but worth running.

### Sixth: GHCi over a real ssh tty

(Session 57 HANDOFF priority #4.)  All script-based runs use
piped stdin.  A real `ssh pmacg5` + `/opt/ghc-stage2/bin/ghc-real
--interactive` exercises haskeline's terminal handling on Tiger.
Should "just work" — haskeline is statically baked in — but
hasn't been verified.  Low effort: ssh in, try arrow keys,
history, ctrl-r, multi-line editing, tab completion.

### Seventh: extend the debugger runner to handle extra_run_opts /
subdir extras (session 57 HANDOFF #5, #6)

Trivial.  Unlocks hist001, hist002, T1620.

### Eighth: stage2 native-compile sweep (carry-forward from S54)

Cabal-examples sweep, but native (ssh in, compile + run on
pmacg5) rather than cross-compile.  Modest interest.

### Ninth: refactor patch 0016 to upstream's smaller form

Still on the list from session 54.  Cosmetic.  Needs a stage1
rebuild + stage2 redeploy to validate — which v0.14.1's bindist
re-roll would naturally do anyway, so consider rolling into the
same session.

### Tenth: audit third-party libs for the setByteArray# /
readWordArray# granularity-mismatch

Still on the list from session 53/54.  Upstream contribution.

## What NOT to redo

* **Don't re-run session 56 / 57 / 58 test subsets** unless the
  stage2 binary changes.  v0.14.1's bindist re-roll WILL change
  it, so DO re-run all three to confirm the new bindist passes
  everything plus T10989.
* **Don't manually re-deploy the unlit fix** on pmacg5 — it's
  already there in-place.  If you wipe `/opt/ghc-stage2`, you'd
  need to reinstall v0.14.0 and then redo the manual fix (or
  install v0.14.1 once that ships).
* **Don't reimplement the runner** — `run-ghci-tnum.sh` works.
  Extending its TESTS list and adding flags-pass-through is
  cheaper than rewriting.
* **Don't believe HANDOFF text that says `req_th` annotations
  exist in `tests/ghci/scripts/all.T`** — they don't.  Session 57
  HANDOFF's priority #1 was based on that stale claim.  The real
  TH-from-REPL coverage came from running T4127 etc., not from
  any `req_th` filter.

## Hosts (unchanged from session 56/57)

* **uranium**: source edits, harness scripts, sweeps from here;
  cross-build of unlit happened here too (using existing cross-cc).
* **pmacg5**: runs the ppc stage2 ghc binary.
  `/opt/ghc-stage2/bin/ghc-real` is the v0.14.0 GHCi-enabled
  binary (~199 MB).  `/opt/ghc-stage2/lib/bin/powerpc-apple-
  darwin8-unlit` is now the session-58-cross-built 14-KB ppc
  binary; the original arm64 is preserved alongside.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 58 of the ghc-darwin8-ppc project added a third
verification milestone for the v0.14.0 GHCi REPL — 161/163 PASS
on a curated subset of upstream's testsuite/tests/ghci/scripts/
T<NUM>.script regressions (every test with `normal` /
`combined_output` / `extra_files(...)` annotation that doesn't
need special harness).  Surface: 6 TH-from-REPL regressions
(T4127, T4127a, T5566, T8831, T10466, T11098), the
:reload/:load/module-dependency family, type families + kind
polymorphism, StaticPtr, type apps, GADTs.  The two remaining
failures (T8042, T17549) are HFS+ 1s mtime races in the upstream
test scripts (not PPC bugs).  Reusable runner at
docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/.

Also: surfaced and repaired-in-place a packaging bug — the v0.14.0
bindist ships an arm64 `unlit` helper at
/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.  Hadrian's
cross-mode host-copy in Rules/Program.hs only excluded `iserv`
(patch 0010) and missed `unlit`.  Cross-built a real ppc unlit
via a two-step compile-then-link recipe through $CROSS_CC,
deployed to pmacg5 in-place (original kept as
powerpc-apple-darwin8-unlit.arm64.broken).  T10989 now PASSes.

No new patches, no source changes, no release.  v0.14.0
unchanged; pmacg5's /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-
unlit is the only thing modified.

Top next move: v0.14.1 release.  Change patch 0010's
``case (cross, stage) of (True, s) | s > Stage0 && package /= iserv``
to ``package `notElem` [iserv, unlit]``, rebuild stage1, re-cross-
compile stage2, re-roll bindist, demo + release tag.  See
session 58 HANDOFF for the full priority list.

Read in order:
1. docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/HANDOFF.md
2. docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/README.md
3. docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/findings.md
4. docs/roadmap.md (priorities)

Hosts: uranium for source edits + cross-builds; pmacg5 for runs.
The unlit fix on pmacg5 is in-place; if /opt/ghc-stage2 is wiped,
reinstall v0.14.0 then re-deploy the patched unlit from
docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/
powerpc-apple-darwin8-unlit.ppc — or, better, ship v0.14.1 first.

Unsupervised mode is project default.
```

## Memory aide

When session 59 ends, write the next handoff at:
`docs/sessions/<DATE>-session-59-<slug>/HANDOFF.md`.
