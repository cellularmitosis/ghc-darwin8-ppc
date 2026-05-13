# Session 27 — stage2 GC bug, round 9 (non-perturbing repro nailed; `-G1` is a partial workaround; bug has two distinct corruption modes)

**Dates:** 2026-05-12 (same-day continuation of session 26).

**Status on arrival:** v0.12.0 ships unchanged.  Stage2 ghc on
pmacg5 uses the `+RTS -A1G` workaround.  Session 26 ruled out
hypothesis (a) "BS reaches `mkFastStringByteString` with non-pinned
MBA" via direct observation (PROBE26 saw 150/150 PlainPtr-pinned, 0
UNPINNED).  PROBE26 also perturbed the M5.hs SIGSEGV away entirely
(0/3 vs. session 23's 5/5).  Sessions 23–25's PROBE22POISON crash
signature `_blk_c7te+112 / 0xdeadbeef` was reread as a probe artefact
composite: the underlying bug is the panics that session 17 first
cataloged.  At session-26 end, clean stage2 was re-confirmed on M5.hs
`+RTS -A1m` as 4/5 panic.  Session-26 HANDOFF queued "re-establish a
non-perturbing deterministic repro" as top priority for session 27.

**Status on exit:**

- **Deterministic non-perturbing repro nailed:** `M5.hs +RTS -A1m`
  on clean stage2 panics **10/10**.  No instrumentation needed.
- **`+RTS -A1m -G1` (single-generation) fully suppresses the M5.hs
  panic family** (10/10 OK).  It does NOT suppress all variants of
  the bug — Big2.hs `+RTS -A1m -G1` fails 10/10 with a typecheck-
  time corruption signature.
- **A second, previously-undocumented corruption signature was
  discovered:** `* GHC internal error: 'swap' is not in scope
  during type checking, but it passed the renamer`.  Fires
  deterministically on a small clean module that uses
  Data.Map.Strict + a `where`-bound local function.  Sessions
  17–26 catalogued only the STG-time family
  (depSortStgBinds / refineFromInScope / "variable not found");
  this typecheck-time variant is new.
- **Hypothesis revised:** the STG-time variant is consistent with
  a missed `mut_list` entry on older-gen objects (because `-G1`
  disables the older-gen mut_list scavenge path entirely).  The
  TC-time variant suppressed neither by `-G1` nor by the same
  treatment, so EITHER (a) it's a second bug with a different
  mechanism, OR (b) one bug with two distinct victim data
  structures — needs more probing to discriminate.
- v0.12.0 unchanged.  Stage2 source tree clean.  No commits to the
  GHC tree this session; only session notes + harness scripts.

HANDOFF for session 28: see [`HANDOFF.md`](HANDOFF.md).  Top of
queue: design a slim RTS-side probe (no Haskell-side perturbation)
that counts mut_list entries / scavenge events, to discriminate
"one bug" vs "two bugs."

## What we did, in order

### Step 1 — confirm baseline green

`tests/run-tests.sh`: 29 PASS / 4 design diffs.  (One run earlier
had a 12_show_read transient failure caused by accidentally launching
two parallel copies of the test runner; re-running 12_show_read
manually succeeded.  Baseline is effectively v0.12.0 unchanged.)

### Step 2 — write the panic-rate harness

[`scripts/measure-panic-rate.sh`](scripts/measure-panic-rate.sh)
loops `ghc-real -c M5.hs $RTS_FLAGS` N times against pmacg5 via ssh,
captures stdout/stderr per iter, and classifies each run as PASS or
a fail-symptom-bucket.  Tested 5 RTS-flag profiles:
`-A1G` (control), `-A1m` (load-bearing), `-A1m -G1` (single-gen),
`-A512k` (smaller area), `-A4m` (larger area).

### Step 3 — measure M5.hs panic rate

Result on clean stage2 (no PROBE instrumentation):

```
=== M5 iters=10 flags='+RTS -A1G  -RTS' === pass=10 fail=0
=== M5 iters=10 flags='+RTS -A1m  -RTS' === pass= 0 fail=10  (9× depSortStgBinds, 1× refineFromInScope)
=== M5 iters=10 flags='+RTS -A1m -G1' === pass=10 fail= 0
=== M5 iters=10 flags='+RTS -A512k -RTS'=== pass= 9 fail= 1
=== M5 iters=10 flags='+RTS -A4m   -RTS'=== pass=10 fail= 0
```

**Key observation: `-A1m` is the Goldilocks zone — `-A1G` and `-A4m`
are too large (no GC fires); `-A512k` is too small or has different
allocation behaviour; `-A1m` triggers the bug 10/10.  And `-G1`
(single-generation) suppresses the bug entirely.**

`-A1G` baseline confirmation matches v0.11.0's ship workaround.

### Step 4 — confirm `-G1` suppression on slightly larger inputs

[`scripts/g1-suppression-test.sh`](scripts/g1-suppression-test.sh)
runs M5plus.hs (Data.List + Data.Map.Strict imports, 5 small bindings)
and Big.hs through the same matrix.

M5plus.hs at `-A1m`: 4 OK / 1 panic (the panic surfaced even at lower
input size).  At `-A1m -G1`: 5 OK / 0 fail — **`-G1` suppression
holds**.

Big.hs (first version) had a deliberate **real type error** in
`topK`'s return-type signature, intended to give a deterministic
non-GC failure to compare against.  Result: at `-A1m`, mix of real
type error / panic / false-success.  At `-A1m -G1`: 5/5 reports a
DIFFERENT error — `swap' is not in scope during type checking, but
it passed the renamer`.  That's a **GC-corruption signature** masking
the real type error.

### Step 5 — repeat with a syntactically clean Big2.hs

Rewrote `Big.hs` → `Big2.hs` so it compiles cleanly on host ghc
(verified: `host RC=0`).  Same matrix:

```
=== Big2.hs iters=10 flags='+RTS -A1G   -RTS' === pass=10 fail=0  (control)
=== Big2.hs iters=10 flags='+RTS -A1m   -RTS' === pass= 1 fail=9  (1× panic, 8× "swap not in scope")
=== Big2.hs iters=10 flags='+RTS -A1m -G1 -RTS' === pass= 0 fail=10 (10× "swap not in scope")
```

**`-G1` does NOT suppress the Big2.hs corruption.**  It changes the
signature: under `-A1m -G2` we get a mix of compile-success and the
TC-time error; under `-A1m -G1` we get the TC-time error 10/10.

### Step 6 — interpretation

Combined data:

| Input    | `-A1G`  | `-A1m`               | `-A1m -G1`              |
|----------|---------|----------------------|-------------------------|
| M5.hs    | 10/0    | 0/10 STG-panic       | 10/0 ✓                  |
| M5plus.hs| —       | 4/1 STG-panic        | 5/0 ✓                   |
| Big2.hs  | 10/0    | 1/9 TC-corruption    | 0/10 TC-corruption      |

Two distinct corruption modes:

- **STG-time family** (depSortStgBinds, refineFromInScope, "variable
  not found").  Suppressed by `-G1`.
- **TC-time family** (`swap` not in scope during type checking).
  NOT suppressed by `-G1`.

The TC-time error includes the full `tcl_env` (TcTypeEnv) at the
panic site, which lists 9 entries — 4 outer + 5 top-level
identifiers — but missing the `where`-bound `swap`.  The renamer
DID add `swap` to its scope; the typechecker DID look at the
correct environment; the entry just isn't there.  Classic GC-eaten-
IntMap-node.

The fact that `-G1` disables `scavenge_capability_mut_lists`'s
older-gen scavenge loop (`for (g = generations-1; g > N; g--)` —
empty when generations=1) is consistent with the STG-time bug
being in the older-gen mut_list path.  The TC-time bug must
involve a different mechanism (or hit a different victim data
structure).

See [`findings.md`](findings.md) for the full analysis.

### Step 7 — no GHC-tree edits this session

Source tree clean throughout.  We only added session notes and
harness scripts.  No rebuild, no redeploy.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with `+RTS -A1G` wrapper.
- **No GHC-tree source edits this session.**
- **Stage2 ghc on pmacg5 is the clean rebuild from session-26 end**
  (unchanged).
- **Logs at** [`logs/`](logs/)

- **HANDOFF for session 28** queues mut_list / write-barrier audit
  and a single-cause-vs-two-causes probe design.

## Files added this session

- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — writeup.
- [`scripts/measure-panic-rate.sh`](scripts/measure-panic-rate.sh)
  — M5.hs panic-rate harness across 5 RTS profiles.
- [`scripts/g1-suppression-test.sh`](scripts/g1-suppression-test.sh)
  — M5plus.hs + Big.hs (initial buggy version) `-G1` suppression test.
- [`scripts/g1-big2-test.sh`](scripts/g1-big2-test.sh) — Big2.hs
  (syntactically clean) `-A1G / -A1m / -A1m -G1` matrix.
