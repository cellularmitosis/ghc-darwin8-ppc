# Handoff from session 59 → session 60

**For:** the next claude session.
**From:** session 59 — v0.14.1 committed and tagged locally.
Hadrian patch 0010 amended (`unlit` joins `iserv` in the cross-mode
helper-copy carve-out); stage1 rebuilt; stage2 re-cross-built and
deployed to pmacg5; bindist re-rolled (`_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`);
demo + README updates landed.  Session-58's runner re-ran clean
against the new bindist (161/163 PASS — only the two HFS+
mtime-race tests remain).  **Tag push + GitHub release upload
deferred to the user** — v0.14.0 was also tagged-locally but
never pushed / never uploaded to GitHub (the most recent GitHub
release is v0.13.0), so this session left both v0.14.0 and v0.14.1
local tags untouched.  When the user wants to ship, the bindist
tarball is at the path above.
**Recommended pickup:** no single obvious next-must-do.  Roadmap
A ✅, B ✅, C ✅, D ✅, G ✅, H ✅.  The remaining items are
smaller, exploratory, or "nice to have" — pick by appetite.
Session 58's HANDOFF priorities 2–10 are still valid (since they
were follow-on work *after* the v0.14.1 release).  See below for
the trimmed-down version.

## ✅ SESSION EXIT STATE

* `patches/0010-hadrian-cross-iserv.patch` amended in-place
  (`package /= iserv` → `package `notElem` [iserv, unlit]`).
* `external/ghc-modern/ghc-9.2.8/hadrian/src/Rules/Program.hs` —
  matching live-source edit.
* `_build/stage1/lib/bin/powerpc-apple-darwin8-unlit` — now 47 KB
  ppc Mach-O (was 84 KB arm64 Mach-O from the host copy).
* Stage2 ghc-real on pmacg5 rebuilt and redeployed (~199 MB, size
  unchanged from v0.14.0 — only the `lib/` tree changed, ghc itself
  is the same code).
* `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` on pmacg5 —
  now the hadrian-built 47 KB ppc binary (was session-58's 14 KB
  bespoke ppc; rsync `--delete` also removed the
  `.arm64.broken` forensics backup).
* `demos/v0.14.1-literate-haskell.{lhs,sh}` + `demos/README.md`
  row added.
* `README.md` — Latest-release paragraph, GHCi REPL status row's
  pending-v0.14.1 note (now ✅), Releases table all updated.
* `docs/state.md` — top bumped to session 59.
* `docs/roadmap.md` — §C session 59 entry added.
* Session 59 dir complete: README.md, findings.md, commits.md,
  this file, logs/.
* Tag `v0.14.1` created locally on the session-59 commit.  **Not
  pushed to origin.** GitHub release **not** created.  Bindist
  tarball at `_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`
  awaiting upload.

The tree is clean and v0.14.1 is locally tagged.  The user
controls whether/when to push tags and upload assets to GitHub.

## TL;DR — the session-59 work

Four-line patch (`patches/0010-hadrian-cross-iserv.patch`) routes
`unlit` from `copyFile` (which copied the host arm64 binary
verbatim into the bindist) to `buildBinary` (which routes through
stage1 ghc → cross-cc and produces a real PPC Mach-O).  `unlit`
was already in scope below, no new imports needed.

Hadrian's `Ghc LinkHs` path handles `unlit.cabal`'s
`Main-Is: unlit.c` + `C-Sources: fs.c` declaration cleanly — the
C sources compile via `Run Ghc CompileCWithGhc`, then link via
`Run Ghc LinkHs`, producing a 47 KB ppc binary (vs. session 58's
14 KB bare-cc build — see [findings §3](findings.md)).

Re-running session 58's `run-ghci-tnum.sh` against the new bindist:
**161/163 PASS**.  T10989 (the only `.lhs` test in the
testsuite/tests/ghci/scripts/ subset) now passes natively from
the freshly installed bindist.  The two remaining failures — T8042
and T17549 — are still the HFS+ 1-second mtime granularity races
in the upstream test scripts.

## What to try next, in priority order

(Session 58 HANDOFF's priorities 2 onward, minus #1 which is now
done.)

### Top: skip T8042 / T17549 from the runner (cosmetic)

If we want a clean "X / X PASS" headline in future runs, exclude
T8042 and T17549 from the TESTS list in
`docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh`
with a comment pointing to
[session 58 findings.md §3](../2026-05-17-session-58-ghci-tnum-scripts/findings.md).
Session 58 chose honesty over clean numbers; that's a defensible
reversal post-v0.14.1.

### Second: extend the runner to handle more annotations

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

### Third: bug-numbered T<num>/ subdirs

`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/T11827/`,
`T13786/`, `T16670/`, `T18060/`, `T18071/`, `T18262/`, etc.  Each
has its own Makefile driving a small scenario.  Less uniform
than `scripts/`; each one may need bespoke setup.  Cherry-pick
the ones whose Makefiles are short.

### Fourth: prog001..prog019 multi-module `:load` tests

Multi-module `:load` exercise.  Each is a directory with several
`.hs` files and a `.script`.  Tests `:load`'s multi-module
dependency tracking + reload invalidation.  Probably all pass,
but worth running.

### Fifth: GHCi over a real ssh tty

All script-based runs use piped stdin.  A real `ssh pmacg5` +
`/opt/ghc-stage2/bin/ghc-real --interactive` exercises haskeline's
terminal handling on Tiger.  Should "just work" — haskeline is
statically baked in — but hasn't been verified.  Low effort: ssh
in, try arrow keys, history, ctrl-r, multi-line editing, tab
completion.

### Sixth: extend the debugger runner to handle extra_run_opts /
subdir extras

Trivial.  Unlocks hist001, hist002, T1620 from session 57's
testsuite subset.

### Seventh: stage2 native-compile sweep

Cabal-examples sweep, but native (ssh in, compile + run on
pmacg5) rather than cross-compile.  Modest interest.

### Eighth: refactor patch 0016 to upstream's smaller form

Still on the list from session 54.  Cosmetic.  Needs a stage1
rebuild + stage2 redeploy to validate — see if it can ride along
on whatever the next stage1-touching session is.

### Ninth: audit third-party libs for the setByteArray# /
readWordArray# granularity-mismatch

Still on the list from session 53/54.  Upstream contribution
opportunity.

## What NOT to redo

* **Don't re-run sessions 56 / 57 / 58 test subsets** unless the
  stage2 binary changes.  v0.14.1's bindist re-roll already
  triggered the re-runs in this session.
* **Don't roll back the patch 0010 amendment** — it's now the
  shipped form, and the hadrian build path through `buildBinary`
  is verified to work for `unlit`'s pure-C source.
* **Don't reimplement the runner** — `run-ghci-tnum.sh` works.
  Extending its TESTS list and adding flags-pass-through is
  cheaper than rewriting.
* **Don't believe HANDOFF text that says `req_th` annotations
  exist in `tests/ghci/scripts/all.T`** — they don't.  Session
  57 HANDOFF's priority #1 was based on that stale claim.  The
  real TH-from-REPL coverage came from running T4127 etc., not
  from any `req_th` filter.

## Hosts (unchanged from session 58)

* **uranium**: source edits, harness scripts, hadrian builds,
  bindist re-roll, cross-builds.
* **pmacg5**: runs the ppc stage2 ghc binary.
  `/opt/ghc-stage2/bin/ghc-real` is the v0.14.1 binary
  (~199 MB).  `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit`
  is the hadrian-built 47-KB ppc binary deployed this session.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 59 of the ghc-darwin8-ppc project shipped v0.14.1.
This was the "ritualistic re-release" turn of session 58's
in-place pmacg5 unlit fix — patch 0010 amended (`package /= iserv`
→ `package `notElem` [iserv, unlit]`), stage1 rebuilt, stage2
re-cross-built and deployed, bindist re-rolled, demo + README +
release tag shipped.  The literate-Haskell `unlit` pre-processor
in the v0.14.1 bindist is now a real PPC Mach-O (47 KB) instead
of the host arm64 binary that v0.7.0..v0.14.0 shipped with a
`powerpc-apple-darwin8-` prefix.  Session 58's runner re-runs at
161/163 PASS against the new bindist (T8042 + T17549 still flake
on HFS+'s 1-second mtime granularity in the upstream scripts).

No new patches added (patch 0010 was amended in-place, project
convention).  All other patches unchanged.  Roadmap A/B/C/D/G/H
all ✅ closed; remaining work is exploratory.

Top next move: no single obvious must-do.  Pick from session 59
HANDOFF's priority list — they're all small, scoped, and
optional.  Suggestions: thread `extra_run_opts` / `extra_hc_opts`
through the ghci-tnum runner (~10 more tests unlocked), real-ssh-
tty GHCi sanity check, or cherry-pick a few `T<num>/` Makefile-
driven subdirs.

Read in order:
1. docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/HANDOFF.md
2. docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/README.md
3. docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/findings.md
4. docs/roadmap.md (for the broader priority list)

Hosts: uranium for source edits + cross-builds; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 60 ends, write the next handoff at:
`docs/sessions/<DATE>-session-60-<slug>/HANDOFF.md`.
