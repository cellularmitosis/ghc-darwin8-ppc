# Handoff from session 62 → session 63

**For:** the next claude session.
**From:** session 62 — extended `run-ghci-tnum.sh` with
`extra_hc_opts(...)` support; **171/172 PASS** on the now-172-test
T-prefix subset.  All 6 new tests (T2452, T2182ghci2, T9293, T13385,
T14342, T16563) pass.  Normaliser gained a trailing-blank-line trim
to absorb upstream's stray expected-file newlines.  No GHC source
changes, no new patches, no release.

**Recommended pickup:** **`reqlib` or `pre_cmd` runner extensions**,
or shift to one of session 59's exploratory items.  After session 62
the deterministic-fail set in this 172-test subset is empty —
only the alternating T8042 / T17549 HFS+ mtime race remains.

## ✅ SESSION EXIT STATE

* `docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/scripts/run-ghci-tnum.sh`
  — session 61's runner extended with `extra_hc_opts` cases in
  `run_opts_for()` and 6 new TESTS entries.
* `docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/scripts/normalise.py`
  — session 61's normaliser plus a final `s.rstrip('\n')` (one extra
  newline re-appended if non-empty).
* `docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/logs/00-runner-diff.log`
  — diff against session 61's runner for quick audit.
* `docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/logs/01-run1.log`
  — first run (170/172, T16563 fails on trailing newline).
* `docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/logs/02-run2-after-normaliser-trim.log`
  — second run after normaliser fix (**171/172, T8042 = HFS+ race**).
* `docs/state.md` — top entry bumped to session 62.
* `docs/roadmap.md` — §C session 62 entry added; last-reviewed
  date bumped.
* `README.md` — Implementation-status table's "GHCi REPL" row
  updated to mention the new 171/172 number.

The tree is clean: no source-tree edits, no patches/, no release tag.

## TL;DR — the session-62 work

Three-line patch to the harness — six new cases in `run_opts_for()`
— and six new entries in the TESTS list.  Five of the six tests
pass clean on the first run; T16563 fails on a 1-byte trailing-newline
discrepancy (upstream's expected `.stdout` has `hello world\n\n` but
GHCi actually emits `hello world\n` — reproduced on the host's
bare ghc-9.2.8 too, so it's a test-data issue not a runtime
difference).  Fixed by adding a final `s.rstrip('\n')` step to the
normaliser — same philosophy as upstream's `normalise_whitespace`
for stderr, applied conservatively (trailing-only).  Second run
hits **171/172 PASS**, with T8042 (the HFS+ mtime-race coin-flip
that alternates with T17549) as the lone failure.

## What to try next, in priority order

### Top: extend the runner to handle more annotations

Session 60 HANDOFF's "second" priority is still the cleanest
forward direction.  Remaining groups (in order of likely-value):

- **`reqlib` tests** (T5979 — needs `transformers`).  ~1 more test,
  but requires verifying `transformers` is installed in the stage2
  ghc-pkg's package.conf.d first.  If it isn't, may need a
  `cabal-cross` step to install it.  Probably the quickest of the
  remaining groups if `transformers` is already there.
- **`pre_cmd` tests** (T5975a, T5975b, T6106, T19650 — 4 tests).
  Each pre_cmd is bespoke: T5975a/b do `touch föøbàr1.hs` /
  `touch föøbàr2.hs`; T6106 runs `$MAKE T6106_prep`; T19650 runs
  `$MAKE T19650_setup` (likely needs a package-env build step too).
  T6106 + T19650 need at least a `Makefile` extraction or shell-
  prelude shim — harder than the others.

### Second + onwards

The session 59 HANDOFF's optional/exploratory list still applies,
unchanged:

- bug-numbered `T<num>/` subdirs (the *directory* variants, not the
  `.script` variants in this subset)
- `prog001`..`prog019` (compile-and-run tests in `tests/ghci/prog0*/`)
- GHCi over a real ssh tty (interactive editing, history, completion)
- extend session 57's debugger runner with `pre_cmd` / `extra_files`
- stage2 native-compile sweep (run upstream's broader testsuite
  using the ppc-native stage2 as the test compiler, not just GHCi
  scripts)
- patch 0016 refactor (the array `STUArray Bool` fix — propose
  upstream)
- third-party library audit (check Hackage's most-depended-on
  packages for any that don't cross-build cleanly)

### Possibly: propose upstream

Several local fixes are upstream-shaped:

- **patch 0017** (this session's PR base — `__dso_handle` Mach-O
  underscore matching).  Would help any Mach-O cross-GHC where the
  host doesn't have a live dyld exporting `___dso_handle`.
- **patch 0016** (`STUArray Bool` word-aligned init — found on
  PPC/big-endian but applicable to any big-endian platform that
  builds `array` from source).
- **T16563's stray trailing newline** in upstream's expected
  `.stdout` — could ship a one-line patch to upstream's
  `testsuite/tests/ghci/scripts/T16563.stdout` removing the trailing
  blank line.  Tiny but tidies the test for everyone.  Same patch
  shape as our patch 0017.

## What NOT to redo

* **Don't try to fix T8042 / T17549** by editing upstream's `.script`
  files to add `:! touch -t` between the two `writeFile`s.  Those
  files are upstream property; the workaround is appropriate at
  *our* test-runner level (e.g., "rerun the test until it passes")
  but the right durable fix is upstream's, not ours.  See [session
  58 findings](../2026-05-17-session-58-ghci-tnum-scripts/findings.md#section-3-hfs-mtime-1s-granularity)
  for the full diagnosis.
* **Don't extend `normalise.py`'s trim to general whitespace**
  (`s.strip()` / `' '.join(s.split())`) just because upstream
  `normalise_whitespace` does.  Our conservative trailing-only trim
  is enough for the failures we've seen; aggressive whitespace
  collapse could mask real GHCi-emits-wrong-error-shape bugs.  If a
  future test surfaces a real internal-whitespace difference, add
  a narrow regex for that specific pattern.
* **Don't extend `run_opts_for()` with redundant cases**.
  `extra_hc_opts` and `extra_run_opts` share the same dispatch arm
  because of the ghci_script compile-and-run-in-one-invocation
  shape.

## Hosts (unchanged from session 61)

* **uranium**: runner / normaliser edits.
* **pmacg5**: runs the v0.14.2 ppc stage2 ghc binary
  (`/opt/ghc-stage2/bin/ghc-real`).  Untouched this session.
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 62 of the ghc-darwin8-ppc project extended session
60/61's ghci-tnum runner with `extra_hc_opts(...)` support — six
new cases in `run_opts_for()` and six new TESTS entries (T2452,
T2182ghci2, T9293, T13385, T14342, T16563).  All 6 pass clean.
`normalise.py` also gained a trailing-blank-line trim to absorb
upstream's stray expected-file newlines (T16563's `.stdout` has
`hello world\n\n` but GHCi emits `hello world\n` — reproduced on
host ghc-9.2.8 too).  Result: 171/172 PASS on the now-172-test
T-prefix subset.  The lone failure is T8042 (the HFS+ 1-second
mtime-granularity race in upstream's `:reload` script — alternates
with T17549 as the unlucky coin-flip per run).  No GHC source
changes, no patches, no release.

Top next move: pick from session 60's "second" priority list —
`reqlib` tests (T5979 needs `transformers`) or `pre_cmd` tests
(T5975a/b, T6106, T19650).  Or shift to one of session 59 HANDOFF's
exploratory items (prog001..019, stage2 native compile sweep, etc.).

Read in order:
1. docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/HANDOFF.md
2. docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/README.md
3. docs/sessions/2026-05-17-session-62-extra-hc-opts-runner/findings.md
4. docs/sessions/2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md (for the priority list)
5. docs/roadmap.md (for the broader priority list)

Hosts: uranium for runner edits; pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 63 ends, write the next handoff at:
`docs/sessions/<DATE>-session-63-<slug>/HANDOFF.md`.
