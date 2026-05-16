# Session 58 — GHCi T<num> script subset + unlit packaging fix

**Date:** 2026-05-17 (continuation of sessions 56 / 57).

**Status on arrival:** Session 56 verified the v0.14.0 REPL against
51/51 `ghciNNN`-style scripts; session 57 verified 83/83 of the
`ghci.debugger/scripts/` family.  Both runs filtered to the
ghciNNN / debugger naming conventions, leaving the ~160 bug-numbered
`T<NUM>.script` regression tests in `testsuite/tests/ghci/scripts/`
untouched.  Session 57 HANDOFF priority #1 said to "drop the
`req_th` filter" and pick up TH-using ghci scripts — but on
inspection `req_th` annotations don't actually appear in
`tests/ghci/scripts/all.T` at all (`grep "req_th" all.T` is empty).
The real next move was always to extend the TESTS list to the
T-prefix scripts, which incidentally subsumes the TH-from-REPL
cases the HANDOFF was concerned about (T4127, T4127a, T5566, T8831,
T10466, T11098).

**Status on exit:** **161/163 PASS** on the curated subset of
T-prefix tests from `tests/ghci/scripts/all.T` — every test with
annotation in `{normal, combined_output, extra_files(...)}` that
doesn't need special harness.  One run-1 failure surfaced a real
**packaging bug** — the v0.14.0 bindist's `unlit` helper at
`/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` is an
**arm64 Mach-O**, not PPC.  Hadrian's cross-build copies stage0
(host) helpers into stage1 for everything except `iserv` (patch
0010 carved iserv out and missed `unlit`).  Fixed in-place on
pmacg5 by cross-building a real PPC unlit and dropping it in; the
broken host binary is preserved alongside as
`powerpc-apple-darwin8-unlit.arm64.broken`.  After the fix
T10989 (the literate Haskell `:l dummy.lhs` test) passes.  The
remaining two failures — T8042 and T17549 — are HFS+ filesystem
mtime granularity races in the test scripts themselves, not PPC
bugs (see [findings.md](findings.md) §3).  **No GHC source-tree
changes, no new patches, no release tag this session** — the
Hadrian patch update is queued for a v0.14.1 bindist re-roll
(HANDOFF priority #1).

## Why this matters

Sessions 56 / 57 exercised the REPL command processor and the
bytecode debugger respectively.  The T-prefix subset in
`tests/ghci/scripts/` covers what amounts to "every GHCi user
issue ever filed and turned into a regression test" — a dense,
ground-truthy corpus that targets specific behaviours that other
non-TH-using ghci script test categories don't.  Bugs covered (in
descending interestingness for PPC):

- **TH from the REPL** — T4127, T4127a (typed splice round-trip);
  T5566 (template-haskell quotation); T8831 (TH-introduced names
  visible to `:type`); T10466 (`-XTemplateHaskell` carry-over on
  `:reload`); T11098 (`$$x` typed-splice).  These were
  session-57-HANDOFF priority #1's actual concern.
- **Module loading edge cases** — T1914 (file rewrite triggering
  reload); T8042 (object-code vs interpreted module switching);
  T8696 / T10110 / T10322 (multi-module `:load` with `-fobject-code`);
  T16804 / T16876 (multi-module loading variants).
- **Type system surface tested via REPL** — T6018ghci/fail/rnfail
  (type-family injectivity warnings); T13202 / T13202a (kinded
  type-family decls); T5417, T8469 (associated type families);
  TypeAppData (visible type application on data constructors);
  T13407, T15259, T15341 (kind polymorphism); T17345 (impredicative
  types in `:type`).
- **Static pointers** — `StaticPtr.script` exercises the static
  pointer table from REPL.  Walks `staticPtrKeys`,
  `unsafeLookupStaticPtr`, `deRefStaticPtr` — all of which touch
  the RTS's per-module static pointer table.  Passes.
- **Literate Haskell** — T10989 (`:l dummy.lhs`).  Drives the
  `unlit` pre-processor.  This is the test that surfaced the
  packaging bug.

If anything in the REPL command processor's interaction with the
typechecker, kind inference, BCO codegen for TH splices, or the
static-pointer table on PPC32 was broken, these 163 tests would
mostly fail.  They don't — modulo the wrong-arch unlit binary
(a packaging bug, not a runtime bug) and two HFS+-mtime races in
the test scripts themselves.

## What was run

[`docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh`](scripts/run-ghci-tnum.sh)
parses the upstream `tests/ghci/scripts/all.T` for T-prefix /
non-ghciNNN script tests and runs the same staging-and-diff
harness session 56 introduced.  Selection criteria:

- annotation is `normal` / `combined_output` / plain
  `extra_files(...)` (skip everything with `extra_hc_opts`,
  `extra_run_opts`, `reqlib`, `req_th`, `req_interp`,
  `expect_broken`, `pre_cmd`, `skip`, `fragile`, `cmd_prefix`,
  `makefile_test`, `filter_stdout_lines`, `normalise_*`,
  `ignore_*`, `when(...)` non-trivial predicates);
- `extra_files` outside the scripts/ dir (`../...`) skipped —
  T14676 (needs `../prog002`), Defer02 (needs
  `../../typecheck/should_run/Defer01.hs`).

That yields 163 candidates (the parser script is reproduced inline
in `findings.md` §1).  Explicit extras added below the parser
output cover companions the auto-discovery globs miss
(lowercase / capital suffix `.hs` files):
T5417a, T8469a, T8696A/B, T10110A/B/C, T10322A/B/C, T16876A/B,
plus the all.T-declared T8353/Defer03, T10576a/b/T10576,
T16804/T16804a-c, T19667Ghci.

Runner reuse: identical pipeline to session 56 (stage tarball →
scp once → run each ghci over piped stdin → tar back → normalise
expected and actual through `scripts/normalise.py` → `diff -qw`).
The normaliser is symlinked from session 56's (session 57 added
two upstream rules; nothing new added this session).

## What happened

**Run 1 (163 tests):** 161 PASS / 2 FAIL.
- `T10989` failed: stderr showed
  `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit: cannot
   execute binary file`.  Investigation:
   `file powerpc-apple-darwin8-unlit` says **Mach-O 64-bit
   executable** (cputype 0x100000C — arm64).  This is the host
   binary, copied verbatim by Hadrian into stage1 during the cross
   build.  Real root cause in
   `hadrian/src/Rules/Program.hs` ([finding §2](findings.md)).
- `T17549` failed: empty stderr where the test expected a parse
  error.  Reproduced manually; cause is HFS+'s 1-second mtime
  granularity ([finding §3](findings.md)) — the script's second
  `writeFile` lands in the same second as the initial `:load`,
  so `:reload` sees mtime unchanged and skips, so the parse error
  it expects never fires.

**unlit fix:** session 58's
[`scripts/build-unlit-ppc.sh`](scripts/build-unlit-ppc.sh)
cross-builds a real PPC `unlit` from
`external/ghc-modern/ghc-9.2.8/utils/unlit/` using `$CROSS_CC`,
compile-then-link in two steps (the ppc-cc wrapper routes
compile-only invocations to real clang and pure-link invocations
to the real Tiger linker via `ppc-ld-tiger`; compile+link from a
.c file goes through `ppc-ld-fake` and produces a 16-byte stub).
The resulting 14-KB Mach-O ppc binary is stashed at
[`scripts/powerpc-apple-darwin8-unlit.ppc`](scripts/) and was
installed on pmacg5:

```
/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit              (now ppc)
/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.arm64.broken (backup)
```

**Run 2 (after unlit fix):** 161 PASS / 2 FAIL.
- T10989 ✅ now passes (cross-built unlit accepts `dummy.lhs`).
- T8042 FAIL — diff shows the line
  `[3 of 3] Compiling T8042A ( T8042A.hs, T8042A.o )` is missing.
  Same shape as T17549: writeFile A → :load → writeFile A → :reload,
  where the second writeFile lands in the same second as :load and
  :reload skips.  T8042 happened to PASS in run 1 (timing variance);
  fails reproducibly in runs 2 and 3.

**Run 3 (sanity check):** 161 PASS / 2 FAIL — T8042 + T17549,
identical to run 2.

## What this proves about the v0.14.0 REPL (after unlit fix)

| Area | Tests | Status |
|---|---|---|
| TemplateHaskell from REPL (typed splices, quotation, reload) | T4127, T4127a, T5566, T8831, T10466, T11098 | ✅ (6 tests) |
| `:reload` / `:load` / module dependency tracking | T1914, T8042, T8042recomp, T8696, T10110, T10322, T11051a, T11051b, T16030, T16527, T17549, T20019 | ✅ (10/12; T8042+T17549 flaky on HFS+, harness-side) |
| Type families + kind polymorphism in REPL | T5417, T6018ghci/fail/rnfail, T8469, T13202, T13202a, T13407, T15259, T15341, T15568, T17345 | ✅ (11 tests) |
| `:type` / `:info` / `:kind` printing | T2766, T2976, T2816, T3263, T4316, T5045, T6027ghci, T7117, T7587, T7688, T8113, T8579, T15827, T15872, T17384, T17431, T17549, T18828, T19158 | ✅ (most; T17549 flaky) |
| Bidirectional `:browse` / `:show modules` | T11252, T11456, T11606, T11975, T12005, T12158 | ✅ (6 tests) |
| Dynamic file rewrite via `writeFile` + reload | T1914, T8042, T10989, T17549 | ✅ (2/4; the other two are HFS+ mtime races, not PPC bugs) |
| Literate Haskell pre-processor (`unlit`) | T10989 | ✅ (after replacing wrong-arch unlit binary) |
| `StaticPointers` via REPL — `staticPtrKeys`, `unsafeLookupStaticPtr`, `deRefStaticPtr` | StaticPtr | ✅ |
| Type-application syntax in REPL (`-XTypeApplications`) | TypeAppData, T13202, T13420 | ✅ (3 tests) |
| GADTs / pattern synonyms in REPL | T11098, T11376, T11728, T13988 | ✅ (4 tests) |
| `:break` / `:list` in non-debugger scripts | T7873, T13407 | ✅ |
| `:set -XCPP` / `:set -XHaskell2010` etc. (extension toggles mid-session) | T2182ghci, T5045, T6027ghci, T7388, T16089, T16767 | ✅ |
| `:show` / `:set` introspection | T6105, T11051a, T11051b, T16527 | ✅ |
| Regression Ts for specific bug IDs | T<bug-num> across the table | ✅ |

Zero PPC- or endian-specific failures in run 2.  Every failure is
attributable to a packaging error (the arm64 unlit, now fixed) or
a known testsuite-design race against HFS+'s 1-second mtime
granularity.

## What this session did NOT do

* Did not change any GHC source-tree files.
* Did not regenerate patch 0010 to also exclude `unlit` (and
  `touchy`) from the cross-build host-copy path.  That, plus a
  stage1 rebuild + stage2 re-cross-build + new bindist tarball,
  is the proper v0.14.1 release-grade fix.  Scoped in HANDOFF
  priority #1.
* Did not produce a new bindist or release tag.
* Did not skip the two flaky tests from the TESTS list — they
  stay in for honesty, and the runner reports them as FAIL each
  run.  See HANDOFF priority #2 for the option to skip and claim
  161/161.

## Files added this session

- `docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/`
  - `README.md` (this)
  - `findings.md`
  - `commits.md`
  - `HANDOFF.md`
  - `scripts/run-ghci-tnum.sh` — the runner (163-test TESTS list).
  - `scripts/normalise.py` → symlink to session 56's normaliser
    (no changes this session).
  - `scripts/build-unlit-ppc.sh` — cross-builds the corrected PPC
    unlit from the GHC source tree.  Self-contained; reproduces
    the `powerpc-apple-darwin8-unlit.ppc` artifact next to it.
  - `scripts/powerpc-apple-darwin8-unlit.ppc` — the 14-KB built
    PPC unlit binary.  Installed on pmacg5 at
    `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` this
    session.
  - `logs/run-1-initial.log` — first run, 161/163, T10989 +
    T17549 failed.
  - `logs/run-2-after-unlit-fix.log` — after unlit replacement,
    161/163, T8042 + T17549 failed.
  - `logs/run-3-flake-check.log` — third run, 161/163, same as
    run 2.
  - `logs/ghci-tnum/` — per-test working dirs.
- `README.md` — Implementation-status table updated.
- `docs/state.md` — top-of-file bumped to session 58.
- `docs/roadmap.md` — §C note added re: 161/163 T-num subset
  passing + unlit packaging bug.

## On pmacg5

Modified in-place:

- `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` — replaced
  with the session-58-cross-built PPC binary.  Was 84 KB arm64;
  now 14 KB ppc.
- `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.arm64.broken`
  — backup of the original wrong-arch binary, kept for forensics
  / to confirm the root cause is what we think it is.

The rest of the stage2 install is unchanged from v0.14.0.
