# Handoff from session 60 → session 61

**For:** the next claude session.
**From:** session 60 — `run-ghci-tnum.sh` extended with
`extra_run_opts(...)` support; 164/166 PASS on the now-166-test
T-prefix subset.  T12091 + T17500 PASS clean.  **T9878b surfaces a
real PPC/Tiger bug** in the runtime Mach-O loader's `__dso_handle`
handling (`rts/Linker.c::lookupDependentSymbol` strcmps against
`"__dso_handle"` but Mach-O preserves the leading underscore, so the
loader sees `"___dso_handle"` and the special case misses).  Filed
as [`docs/proposals/rts-dso-handle-mach-o.md`](../../proposals/rts-dso-handle-mach-o.md)
with a v0.14.2 release sketch.  No GHC source changes this session,
no new patches, no release.

**Recommended pickup:** **the v0.14.2 release** that ships the
two-line `__dso_handle` fix.  Shape is the same as v0.14.1 (small
patch → stage1 rebuild → stage2 redeploy → bindist re-roll → demo
→ release tag).  The proposal has the full release sketch.

After that — or instead, if you prefer harness work over toolchain
work — the rest of session 59's HANDOFF priority list is still
valid (priorities 2 onward, minus what session 60 just did).

## ✅ SESSION EXIT STATE

* `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/run-ghci-tnum.sh`
  — copy of session 58's runner extended with `run_opts_for()` +
  three new TESTS entries (T9878b, T12091, T17500).
* `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/normalise.py`
  — byte-identical copy of session 58's normaliser (no new rules
  needed).
* `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/00-runner-diff.log`
  — diff against session 58's runner for quick audit.
* `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/01-run1.log`
  — full PASS/FAIL log (164/166) + captured per-test outputs.
* `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/02-T9878b-stderr.log`
  — extracted runtime-loader error for forensics.
* `docs/proposals/rts-dso-handle-mach-o.md` — v0.14.2 release sketch.
* `docs/state.md` — top entry bumped to session 60.
* `docs/roadmap.md` — §C session 60 entry added.
* `README.md` — Implementation-status table's "GHCi REPL" /
  "TemplateHaskell" rows updated to mention the new T9878b
  finding + proposal.

The tree is clean: no source-tree edits, no patches/, no release tag.

## TL;DR — the session-60 work

Three-line patch to the harness — `run_opts_for() { case ... }`
lookup + `$opts` inserted into the per-test GHC command — and three
new entries in the TESTS list.  Two pass clean; one (T9878b)
surfaces a real upstream-shaped Mach-O bug: `rts/Linker.c`'s
`__dso_handle` special-case was written for ELF (no underscore
prefix) but Mach-O preserves the leading underscore, so on PPC
the loader sees `"___dso_handle"` and the strcmp misses.  Resolution
falls through to `dlsym`, which on Tiger doesn't expose this symbol
because it's resolved at link time via `dylib1.o`/`crt1.o`, not by
dyld.

## What to try next, in priority order

### Top: ship v0.14.2 — `__dso_handle` Mach-O fix

Two-line C change in `rts/Linker.c::lookupDependentSymbol` — either
match both `"__dso_handle"` and `"___dso_handle"`, or strip one
leading underscore for `OBJFORMAT_MACHO` before the strcmp.  Full
release sketch in
[`docs/proposals/rts-dso-handle-mach-o.md`](../../proposals/rts-dso-handle-mach-o.md):

1. Add `patches/0017-rts-dso-handle-mach-o-underscore.patch`.
2. Rebuild stage1 — only `rts/Linker.c` changes, hadrian re-link
   is fast.
3. `scripts/deploy-stage2.sh pmacg5` re-cross-builds + redeploys.
4. `binary-dist-dir` re-roll.
5. Re-run session 60's runner — T9878b should flip to PASS, target
   165/166 (only T17549 HFS+ mtime race remaining).
6. Demo: a `static`-pointer / `-fobject-code` REPL one-liner.
7. README + state.md + roadmap.md + Releases-table row + tag.

Effort: roughly half a session-59.  No new testsuite debugging.

### Second: extend the runner to handle more annotations

Session 59 HANDOFF's "second" priority, minus the `extra_run_opts`
group which session 60 just did.  In order of likely-value:

- `extra_hc_opts` tests (T2452, T2182ghci2, T9293, T13385, T14342,
  T16563) — thread compiler flags through.  Same harness shape as
  `extra_run_opts` but `$opts` is appended differently (these go on
  the *compilation* line, but since we're using `ghc --interactive`
  both compile and run in one invocation, the wiring is identical
  — pass through `$opts`).  ~6 more tests.
- `reqlib` tests (T5979 — needs `transformers`).  ~1 more test, but
  needs `cabal-cross` to first verify the lib is installed in our
  stage2 ghc-pkg's package.conf.d.
- `pre_cmd` tests (T5975a/b, T6106, T19650) — needs a Makefile or
  shell prelude.  ~4 more tests.  Harder than the others; each
  pre_cmd is bespoke.

### Third + onwards

Identical to session 59 HANDOFF — bug-numbered T<num>/ subdirs,
prog001..prog019, GHCi over a real ssh tty, extend debugger runner,
stage2 native-compile sweep, patch 0016 refactor, third-party lib
audit.  All still optional / exploratory.

## What NOT to redo

* **Don't re-run session 60's runner** against the v0.14.1 bindist
  expecting different numbers.  T17549 is non-deterministic (HFS+
  mtime race); T8042 same family but lucky this run.  T9878b is
  deterministic until the proposal lands.
* **Don't try to backport `dlsym` for `___dso_handle`** — the symbol
  isn't exposed in Tiger's dyld namespace, so `dlsym` won't find it.
  Fix `lookupDependentSymbol` instead.
* **Don't re-extend `run_opts_for` with redundant cases** — both
  `T9878b` and `T12091` use the same `-fobject-code`, share the case
  arm.  Future additions should follow the same pattern.

## Hosts (unchanged from session 59)

* **uranium**: source edits, harness scripts, hadrian builds, bindist
  re-roll, cross-builds.
* **pmacg5**: runs the ppc stage2 ghc binary.  `/opt/ghc-stage2/bin/ghc-real`
  is the v0.14.1 binary (~199 MB).  Untouched this session.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 60 of the ghc-darwin8-ppc project extended session 58's
ghci-tnum runner with `extra_run_opts(...)` support and added the
three runnable extra_run_opts tests (T9878b, T12091, T17500) to its
TESTS list.  T12091 + T17500 PASS; T9878b surfaces a real PPC/Tiger
bug: rts/Linker.c::lookupDependentSymbol's `__dso_handle` special
case strcmps against the ELF spelling but the Mach-O loader passes
the underscore-prefixed `"___dso_handle"`, so it misses and the
StaticPointers SPT-init __cxa_atexit reference goes unresolved.
Result: 164/166 PASS (T17549 still flakes on HFS+ mtime race;
T9878b is the new, deterministic, fixable failure).  Filed as
docs/proposals/rts-dso-handle-mach-o.md with a v0.14.2 release
sketch.  No GHC source changes, no patches, no release.

Top next move: ship v0.14.2 with the two-line __dso_handle fix.
Same shape as v0.14.1's hadrian-patch-amendment release cycle —
patch → stage1 rebuild → stage2 redeploy → bindist re-roll → demo
→ tag.  Proposal has the full sketch.

Read in order:
1. docs/sessions/2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md
2. docs/sessions/2026-05-17-session-60-extra-run-opts-runner/README.md
3. docs/sessions/2026-05-17-session-60-extra-run-opts-runner/findings.md
4. docs/proposals/rts-dso-handle-mach-o.md
5. docs/roadmap.md (for the broader priority list)

Hosts: uranium for source edits + cross-builds; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 61 ends, write the next handoff at:
`docs/sessions/<DATE>-session-61-<slug>/HANDOFF.md`.
