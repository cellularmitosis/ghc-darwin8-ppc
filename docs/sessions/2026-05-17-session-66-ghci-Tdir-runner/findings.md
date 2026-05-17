# Session 66 findings

## TL;DR

New runner for `tests/ghci/T<num>/` per-dir bug-numbered tests —
7/8 PASS across multiple consecutive runs.  One real PPC-port
SIGSEGV identified in T16525a (correct output, then crashes during
post-unload `performGC`).  Verification only.  No GHC source
changes, no patches, no release.  Skipped T13786, T16670_unboxed,
T16670_th (all `makefile_test`).

## 1. T16525a SIGSEGV is a real RTS issue

Bisected in [`logs/T16525a-segv-bisect.md`](logs/T16525a-segv-bisect.md).
Minimal trigger:

1. `:set -fobject-code`, `:load A`.
2. `forkIO` a thread whose action references symbols in A/B.
3. `:l []` — unload A and B's compiled code.
4. Wait long enough that the forked thread fires AFTER step 3, runs,
   and completes (so its closures are dead heap objects holding refs
   to unloaded code).
5. `performGC` — walks heap, follows ref into unloaded text, dies.

Each of those is necessary.  Removing any one yields rc=0.

Hypothesis: GHC's `rts/Linker.c` `unloadObj` machinery marks symbols
unresolvable but the GC's code-scan path (the one that pins Cmm
closures to keep them from being collected before their containing
thread finishes) doesn't notice the unload and follows a pointer
into munmap'd memory.

Worth investigating in a future RTS-focused session.  Not blocking
v0.15.0; not a regression of any existing functionality.

## 2. T16525b is clean — counterintuitively

T16525b stresses the SAME path harder (the thread keeps calling
INTO unloaded code across multiple `performGC` cycles, instead of
just holding a ref to it from a completed action).  Yet T16525b
runs clean rc=0.

Best guess: T16525b's thread is mid-call when each GC happens, so
its closures stay scheduler-pinned in the TSO stack and are seen as
"reachable" by the GC's normal evacuation walk.  T16525a's thread
completes BEFORE the GC and its closures are dead-but-still-on-the-
heap orphans — the kind the code-scan path is supposed to handle but
doesn't.

This is the interesting bit: the harder-looking test passes; the
easier-looking one breaks.  Argues for the bug being specifically
about orphan-but-not-yet-collected refs to unloaded code, not about
the unload+execute path generally.

## 3. T11827 `expect_broken` handling

T11827's `all.T` carries `expect_broken(11827)`.  The script does
`:load B.hs` (which transitively loads A.hs containing the broken
`f C = False`) then `:show modules`.  Upstream's `T11827.stderr`
expects:

```
A.hs:6:3: error: Not in scope: data constructor ‘C’
```

But the comment in the .script explains: with `-v0` (the default),
the error message is suppressed because module-load failures don't
print errors when verbose-zero.  So the test's expected output
literally never appears, and upstream marks it `expect_broken(11827)`
to acknowledge the mismatch.

Our runner honours this: a `expect_broken=1` test inverts pass/fail.
A mismatch = expected.  A match (which would mean upstream's bug got
fixed) would be `UNEXPECTED PASS`.

Our actual output:
- `actual.stderr` does contain the error (just without the literal
  ` error:` keyword) — interesting, this suggests our ghci IS
  printing it where upstream's wasn't.  Possibly v0/v1 default
  behaviour differs by GHC version.
- `actual.stdout` contains `:show modules` chatter (`A`, `A[boot]`),
  which upstream's `T11827.stdout` doesn't exist for.

So we differ from upstream's expected on both streams, but the
expect_broken flip treats that as the right outcome.

## 4. T16392's `extra_ways(['ghci-ext'])` not exercised

`T16392.T`'s `extra_ways` is gated on `config.have_RTS_linker` — on
upstream, that means run additionally with `-fexternal-interpreter`.
We run only the normal way.  Same decision as session 65 for
prog001's same annotation.  Future iserv-bridge work could double-
test these scripts; not blocking.

## 5. Runner shape simplifies from session 65

`scripts/run-ghci-Tdir.sh` is ~50 lines shorter than
`run-ghci-progNNN.sh`:

- No `shell.hs` staging (none of the T-tests reference upstream's
  `../shell.hs`).
- No test-name vs dir-name split (all 8 are dir == test name).
- No `HC` / `HC_OPTS` / `ghciWayFlags` env block (none of the
  scripts compile partial `.o` files mid-REPL).

The session-65 runner already had absorbed all the annotation
shapes that the T-dir family uses.  The simplification here
suggests the runner abstraction is at the right level — each new
family is "session-65's runner minus some features," not "session-
65's runner plus new features."

## 6. Detection of lethal signals

Session 65's runner only flagged rc ∈ {127, 137, 134} as fail
conditions.  Added rc ∈ {138 (SIGBUS), 139 (SIGSEGV)} this session
after T16525a needed it.  Worth porting back to session 65's runner
and to `run-ghci-tnum.sh` from session 64 — same 128+N convention
applies everywhere.

## 7. Effort breakdown

- Read session 65 HANDOFF + roadmap context: ~5 min.
- Scope T-dir family (read all 10 dirs' .T + scripts + expecteds):
  ~10 min.
- Design + write `run-ghci-Tdir.sh` (mostly cloned + simplified):
  ~10 min.
- First run + initial analysis: ~5 min.
- T16525a SIGSEGV bisection (4 .script variants): ~10 min.
- Add SIGSEGV detection + re-run + final: ~5 min.
- Session docs (README/findings/HANDOFF/commits + segv-bisect
  log): ~30 min.

Total: ~75 min.  Slightly faster than session 65 because the
runner only needed to lose features, not add them — and the
session got an unexpected useful finding (the PPC RTS-linker
unload + GC bug) in the bisection step.
