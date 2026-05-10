# Handoff from session 18 → next session

**For:** the next claude session.
**From:** session 18, 2026-05-09 close-out (post-v0.12.0).
**Recommended pickup:** **GC bug investigation** (stage2 native ghc's
`-A1G` workaround removal).  Long-running, possibly multi-session,
high-leverage if it lands.

## TL;DR

- v0.12.0 is shipped clean — LLVM-8 cross-toolchain swap done, all
  demos / test battery green.  Working state is stable.
- The next obvious open work is the **stage2 GC bug** that we
  worked around in v0.11.0 with `+RTS -A1G -RTS`.  Removing that
  workaround means stage2 ghc would behave like a normal compiler
  (no special heap pre-allocation) on G3/G4 PowerMacs without
  enough RAM to spare a gig.
- This handoff lays out the investigation path with everything you
  need to start cold.  Plan for 1–3 sessions; could fail to find
  a fix but should pin down the proximate cause regardless.

## Read in order before starting

1. **This file** (the handoff).
2. [`../2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md`](../2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)
   — the threshold table, the gdb backtrace (`updateNurseriesStats`
   crash inside `stat_startGC`), and the four "what to investigate
   when fixing the GC bug" hypotheses we never followed up on.
3. [`../2026-04-29-session-17-stage2-O0-experiment/findings.md`](../2026-04-29-session-17-stage2-O0-experiment/findings.md)
   — the meta-lesson that "passes drop data structures" was actually
   a GC-induced corruption.
4. (Optional, for session-18 context) [this session's README](README.md)
   — confirms LLVM-8 swap doesn't help the GC bug, so the
   workaround stays in place pre- and post-v0.12.0.

## Bug recap (so you don't have to re-derive)

Stage2 native ghc on Tiger crashes during the very first major GC
unless given a giant nursery (`+RTS -A1G -RTS`).  Symptom is data-
structure corruption: the typechecker's `Bag` of bindings comes back
partially empty, downstream passes panic in
`refineFromInScope` / `GHC.StgToCmm.Env: variable not found` /
`depSortStgBinds Found cyclic SCC`.

Threshold (from session 17's table):

| `+RTS -A…` | M5.o symbol count | observation |
|-----------|-------------------|-------------|
| default (~1m)  | 0  | broken |
| `-A8m`/`-A16m`/`-A32m`/`-A64m` | 0 | broken |
| `-A128m` | 3 (works for tiny modules) | partial |
| `-A256m` | 3 | works for tiny modules |
| `-A1G`   | 3 | shipped default in `scripts/ghc-stage2-wrapper.sh` |

Bug fires after the first major GC.  With a big enough nursery,
no GC happens during a small compile, no bug.

What was already ruled out:
- LLVM-8 vs LLVM-7 (v0.12.0 swap doesn't change the symptom)
- The `-O` level on the libraries (session 17's `-O0` rebuild)
- `simpleOptPgm` / pass-level miscompile (the early hypothesis)
- All the user-code probes (`Bag` traversal, `fetchAddWordAddr#`,
  `mkSplitUniqSupply`-shaped recursion) — they all run correctly
  on Tiger when stage1-cross-built

So the bug has to be in something that happens **inside** GHC at GC
time.  Probably the RTS itself (likely candidates: the nursery /
generation block accounting, or a pointer-update barrier missing
on PPC32 Darwin).

## Investigation path

**Step 1 — exercise stage2 with the debug RTS** (~30 min wall, low risk)

Tiger has `+RTS -DC -RTS` (debug RTS sanity-check).  Build a stage2
that links against the *debug* RTS variant, ship to Tiger, run
`hello.hs` compile under `+RTS -A1m -DC -RTS` and grep the output.
The debug RTS asserts a lot of GC invariants; if any fire, we get
a much sharper description of what's wrong than "NULL+12 deref."

The `quick-cross` flavour already builds the debug rts ways
(`debug`, `thr_debug`).  Linking against them might just need a
flag tweak — see hadrian's `rtsWays` in
[`hadrian/src/Settings/Flavours/QuickCross.hs`](../../../external/ghc-modern/ghc-9.2.8/hadrian/src/Settings/Flavours/QuickCross.hs).

**Step 2 — diff PPC-relevant RTS code: 9.2.8 vs 8.6.5** (~1–2 hours)

GHC 8.6.5 is the last release with official PPC support.  We have
both source trees locally:

- `external/ghc-8.6.5/rts/`
- `external/ghc-modern/ghc-9.2.8/rts/`

Hot files to diff:
- `rts/sm/Storage.c`, `rts/sm/Storage.h` (where `updateNurseriesStats`
  lives in 9.2.8 at line 1584)
- `rts/sm/GC.c`, `rts/sm/GCThread.h`, `rts/sm/Evac.c`, `rts/sm/Sanity.c`
- `rts/Capability.c`, `rts/Capability.h`
- `rts/Stats.c` (the `stat_startGC` entry point in the backtrace)
- `rts/posix/OSThreads.c`, `rts/SMP.h` (any atomic/barrier macros)
- `includes/rts/Capability.h`, `includes/rts/storage/*.h`
- `includes/Cmm.h`, `includes/stg/SMP.h`

Look for: code that 8.6.5 had under `#if defined(powerpc_HOST_ARCH)`
that 9.2.8 dropped or replaced; new write/read barriers added in 9.x
that PPC32 doesn't actually have a working primitive for; nursery /
block-allocator changes around 9.0.

The session-17 GC-BUG-FOUND.md flagged "missing PPC memory fences"
and "CAF-table or `large_alloc_lim` 32-bit overflow" as suspects.
Confirm or rule out from the diff.

**Step 3 — narrow the trigger** (~1 hour)

What's special about a "first major GC"?  Mostly: blocks get evacuated
from the nursery for the first time.  That exercises:
- `Evac.c::copy_tag` → `evacuate_block` → block-descriptor allocation
- the gen0->gen1 promotion path

Add `Debug.Trace`-style printf to the suspected code path, rebuild
RTS only (`hadrian build _build/stage1/rts/build/...`), redeploy
stage2.  Bisect by enabling/disabling the printfs to find the exact
function whose output goes wrong.

**Step 4 — once you have a probable culprit, check the C output**

The stage1 cross-build keeps `.s` and (with `-keep-tmp-files`)
intermediate `.c` files.  For a suspect RTS function, look at:
- The unreg-C-codegen output that GHC emitted (in `_build/stage1/rts/build/cmm/...`)
- The `.s` clang produced

Compare with what 8.6.5's RTS would produce.  If we can match the
8.6.5 generated assembly for the suspect function, that's a
conservative fix.

**Step 5 — produce a fix**

Likely shapes:

- Patch `rts/sm/Storage.c` (or wherever the trigger is) to use
  PPC32-friendly atomic ops or barriers.  A new `patches/00NN-...patch`
  in our repo.
- Or define a missing `#define` in `rts/SMP.h` that PPC32 needs.
- Or hadrian-flavour-side tweak to enable a debug RTS feature on
  PPC32 by default.

Once a fix candidate exists, drop `-A1G` from
[`scripts/ghc-stage2-wrapper.sh`](../../../scripts/ghc-stage2-wrapper.sh)
(or replace with a more reasonable `-A4m` or whatever the default
becomes), redeploy stage2, run the v0.11.0 demo + test battery.
If it passes without the workaround, ship as v0.13.0.

**Step 6 — even partial wins are worth shipping**

If you can shrink the workaround from `-A1G` to e.g. `-A256m` or
`-A64m` by patching one specific RTS function, that's a real
improvement and worth shipping.  Don't hold out for the full fix
if a partial one is in hand.

## Tools and scripts available

- `scripts/deploy-stage2.sh pmacg5` — rebuild stage2 + deploy + smoke
  test in one step.  Run after any stage1 RTS change.
- `demos/v0.11.0-stage2-native.sh pmacg5` — the canonical "is stage2
  working?" probe.  Tests Hello + Data.Map.Strict.
- `tests/run-tests.sh` — 35-program battery; sanity-check no
  regressions when changing the RTS.
- `scripts/ghc-stage2-wrapper.sh` — the workaround itself; touch when
  declaring a fix.
- `scripts/runghc-tiger` — use to test small Haskell programs cross-
  compiled with the new stage1.

## Hosts

- **uranium** (this Mac) — host for the cross-build.  Build clang-8
  here (~8 min), build hadrian stage1 here (~17 min with clang-8),
  run the test battery from here.
- **pmacg5** — PowerMac G5, Tiger 10.4.11.  Run stage2 binaries
  here.  This is where the bug fires.  ssh works without a password.
- **imacg3** — also accessible via ssh, smaller-RAM PowerMac G3 if
  you want to test under more memory pressure (where `-A1G` would
  be more painful).
- **indium** — has trimmed dev tools; don't try to build clang there.
  Per session 18's findings, build LLVM/clang on uranium going
  forward.

## What NOT to redo

- Don't re-investigate `simpleOptPgm` (session 14 ruled it out).
- Don't re-investigate "is this a Bag traversal bug?" (session 17's
  `BagTest.hs` probe ruled it out).
- Don't try to swap the LLVM toolchain again — v0.12.0 just landed
  the LLVM-8 swap, it doesn't help the GC bug.
- Don't try `-O0` everywhere as a workaround — session 17 tried it,
  doesn't fix the bug.

## Time / scope estimate

- Step 1 (debug RTS): ~30 min if the link works first try; 1–2 hours
  if hadrian needs convincing to link debug rts ways.
- Step 2 (RTS diff): 1–2 hours to read carefully and produce a list
  of "things 8.6.5 had that 9.2.8 dropped".  Maybe 4 hours if you
  follow GitLab MR history for the most-suspect bits.
- Step 3 (narrow trigger): bounded by 1 hadrian rebuild per
  hypothesis = ~17 min each.  Maybe 4–8 iterations realistic.
- Step 4 (C output diff): 1–2 hours, mostly reading.
- Step 5 (fix): unbounded.  Could be a 1-line patch, could be
  multi-file.
- Step 6 (ship): 1 hour for release ritual.

Realistic total: 1 session if step 1 hits gold (the debug RTS asserts
fire something obvious), 2–3 sessions otherwise.

## Things to weigh against this

The other open future-work item is **HTTP client higher-level
libraries** (`http-client`, `req`, `wreq`).  Those are bounded
plumbing work — vendor a few packages, work around any Tiger-isms,
ship a TLS-based HTTP demo.  Probably 1 session.

GC bug is more open-ended but higher-leverage (removes a real
limitation for users on smaller PowerMacs).  Pick based on appetite.

## Paste-into-fresh-session prompt

```
Context: just finished session 18 (LLVM-7 → LLVM-8 toolchain swap,
shipped as v0.12.0).  Working state is clean.  Picking up next: the
stage2 GC bug investigation that we worked around in v0.11.0 with
`+RTS -A1G -RTS`.  Goal: fix the bug so stage2 doesn't need the
giant nursery, or at least pin down the proximate cause.

Read in order:

1. docs/sessions/2026-05-09-session-18-llvm8-toolchain-swap/HANDOFF.md
   (this primer — investigation path, hosts, what NOT to redo)
2. docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md
   (threshold table, backtrace, the four hypotheses we never
   followed up on)
3. docs/sessions/2026-04-29-session-17-stage2-O0-experiment/findings.md

Then start with step 1 in the handoff: exercise stage2 with the
debug RTS.  If the debug RTS doesn't fire any assertions, fall
through to step 2 (diff GHC 9.2.8 vs 8.6.5 RTS).

Hosts: uranium for builds, pmacg5 for runs.  imacg3 also available.
Don't use indium for clang work (it's missing dev tools post-trim).

Unsupervised mode is project default.  If you hit an LLVM-8 codegen
issue, drop a note in
~/claude/llvm-7-darwin-ppc/docs/inbox/<topic>.md instead of trying
to fix LLVM-side.
```
