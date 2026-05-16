# Handoff from session 61 → session 62

**For:** the next claude session.
**From:** session 61 — **v0.14.2 released** end-to-end.  Two-line
`__dso_handle` Mach-O underscore fix (patch 0017); stage1 rebuilt;
stage2 redeployed; session-60 runner re-runs at **165/166 PASS**;
bindist re-rolled; demo committed; release tag pushed + bindist
uploaded.

**Recommended pickup:** **harness work**.  v0.14.2 closes the last
deterministic failure in the 166-test T-prefix subset.  The
remaining failure (T17549) is the HFS+ mtime-granularity race in
upstream's `:reload` script — fixing it would require touching
upstream's test script, not GHC, and is not a PPC bug.  Forward
priorities live in [session 60 HANDOFF's "second" section](../2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md#second-extend-the-runner-to-handle-more-annotations) (extending the runner
to handle more annotations) or session 59 HANDOFF's priorities
2-onwards (the open exploratory work).

## ✅ SESSION EXIT STATE

* `external/ghc-modern/ghc-9.2.8/rts/Linker.c` — two strcmps in the
  `__dso_handle` special case, plus a four-line Note update.
* `patches/0017-rts-dso-handle-mach-o-underscore.patch` — the patch.
* `demos/v0.14.2-static-pointers.hs` — `StaticPtr` demo module.
* `demos/v0.14.2-static-pointers.sh` — driver.
* `demos/README.md` — header bumped to v0.14.2; new row in the
  per-release table.
* `README.md` — Latest-release paragraph, GHCi REPL row, Releases
  table row, Layout patches-count all updated.
* `docs/state.md` — top entry bumped to session 61.
* `docs/roadmap.md` — §C session 61 entry added; last-reviewed date
  bumped.
* `docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/{README,findings,HANDOFF,commits}.md`
  — session notes.
* `docs/sessions/.../scripts/{run-ghci-tnum.sh,normalise.py}` —
  byte-identical copies of session 60's runner artefacts
  (unchanged; the runner was verification, not change-under-test).
* `docs/sessions/.../logs/` — five logs covering rebuild, deploy,
  test re-run, demo run, bindist re-roll.

On pmacg5: `/opt/ghc-stage2/` is the v0.14.2 stage2.  Its
`ghc-real` contains both `__dso_handle` and `___dso_handle` strings
in its compiled-in Linker.c text segment.  Verified end-to-end via
the v0.14.2 demo.

On origin: `v0.14.2` annotated tag pushed; bindist tarball uploaded
to the [v0.14.2 GitHub release](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2).

## TL;DR — the session-61 work

Three-line C code change (plus a four-line comment), one tiny
patch file, one stage1 rebuild (~3.4 sec), one stage2 deploy
(~30 sec), one runner re-run (165/166 PASS), one demo
authored + tested, one bindist re-roll (~3m09s), one tag push +
gh release upload, one round of README / state / roadmap / demos
updates.  No surprises, no new bugs surfaced — the proposal's
"two-line fix → 165/166" prediction landed exactly.

## What to try next, in priority order

### Top: extend the runner to handle more annotations

Session 60 HANDOFF's "second" priority is still the cleanest
forward direction.  In order of likely-value:

- `extra_hc_opts` tests (T2452, T2182ghci2, T9293, T13385, T14342,
  T16563) — thread compiler flags through.  Same harness shape as
  session 60's `extra_run_opts` extension but `$opts` is appended
  to the *compilation* line.  In practice, since we use `ghc
  --interactive` (compile and run in one invocation), the wiring
  is identical to session 60's: just add cases to `run_opts_for`.
  ~6 more tests.
- `reqlib` tests (T5979 — needs `transformers`).  ~1 more test, but
  requires `cabal-cross` to first verify the lib is in the stage2
  ghc-pkg's package.conf.d.
- `pre_cmd` tests (T5975a/b, T6106, T19650) — needs a Makefile or
  shell prelude.  ~4 more tests.  Harder than the others; each
  pre_cmd is bespoke.

### Second + onwards

The session 59 HANDOFF's optional/exploratory list still applies:
bug-numbered T<num>/ subdirs, prog001..prog019, GHCi over a real
ssh tty, extend debugger runner, stage2 native-compile sweep,
patch 0016 refactor, third-party lib audit.

### Possibly: propose patch 0017 upstream

The fix is upstream-shaped — any Mach-O cross-GHC where the host
doesn't have a live dyld exporting `___dso_handle` (which is the
normal Mach-O state — the symbol is provided at link time by
`dylib1.o`/`crt1.o`, not at run time) would hit the same bug.
Worth a GHC GitLab MR once we want to do upstream work.  Same
pattern as patch 0016 (`STUArray Bool` — found locally, applicable
upstream).

## What NOT to redo

* **Don't re-run session-60's runner against v0.14.2 expecting
  different numbers.**  T17549 is non-deterministic (HFS+ mtime
  race); T8042 same family but lucky this run (and session 60's).
  The 165/166 with T17549 as the FAIL is the steady state.
* **Don't try the `#ifdef OBJFORMAT_MACHO` variant** of the patch
  thinking it's "cleaner".  The OR variant is what shipped; both
  are functionally equivalent and the unconditional OR matches the
  rest of `lookupDependentSymbol`'s style.
* **Don't forget `export GHC=...`** when re-running hadrian.
  Source `cross-env.sh` AND `export GHC=$HOME/.local/ghc-9.2.8/bin/ghc`,
  or hadrian's cabal dispatch will pick up homebrew's ghc-9.14 and
  fail dep resolution.  (Recommended follow-up: bake this into
  `cross-env.sh`.)

## Hosts (unchanged from session 60)

* **uranium**: source edits, harness scripts, hadrian builds,
  bindist re-roll, cross-builds.
* **pmacg5**: runs the ppc stage2 ghc binary.
  `/opt/ghc-stage2/bin/ghc-real` is now the v0.14.2 binary (~199 MB).
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 61 of the ghc-darwin8-ppc project executed session
60's v0.14.2 release sketch.  Two-line C change in
`rts/Linker.c::lookupDependentSymbol` matches both the ELF spelling
`__dso_handle` and the Mach-O spelling `___dso_handle` for the
synthetic-handle special case.  Patch 0017 added; stage1 rebuilt
in 3.4 sec; stage2 re-cross-built + deployed to pmacg5; bindist
re-rolled in 3m09s; tarball + tag pushed to the v0.14.2 GitHub
release.  Session-60 runner re-runs at 165/166 PASS (T9878b ✅;
only T17549's HFS+ mtime race remains).  Demo at
`demos/v0.14.2-static-pointers.{hs,sh}`.  No other source changes.

Top next move: pick from session 60 HANDOFF's "second" list
(extend the runner to handle more annotations: `extra_hc_opts` is
the easiest next group).  Or shift to one of session 59 HANDOFF's
exploratory items.

Read in order:
1. docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/HANDOFF.md
2. docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/README.md
3. docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/findings.md
4. docs/sessions/2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md (for the priority list)
5. docs/roadmap.md (for the broader priority list)

Hosts: uranium for source edits + cross-builds; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 62 ends, write the next handoff at:
`docs/sessions/<DATE>-session-62-<slug>/HANDOFF.md`.
