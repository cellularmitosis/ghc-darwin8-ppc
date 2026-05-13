# Handoff from session 31 → session 32

**For:** the next claude session.
**From:** session 31 (filename bisect + env-var-dodge discovery +
scavenge_stack walker exoneration; 2026-05-12).
**Recommended pickup:** **use the env-var dodge as a debugging
primitive.**  Bisect environ-block sizes to identify exactly which
heap-layout offset triggers the bug.  Then per-event probe the
weak-pointer and stable-pointer tables (still untouched), since
they're the remaining unexamined root walkers.

## TL;DR (mandatory read)

- **The bug is byte-level heap-layout sensitive.**  Adding even a
  3-byte env var (`A=A`) to the child process flips Big2 `-A1m -G1`
  from FAIL 5/5 to PASS 5/5 deterministically.  8/8 env-var
  variants tested all dodge.  This is the strongest single datum
  of the session: it tells us the bug locus is at one specific
  virtual address, which environ-size shifts away from.
- **Cross-run address-stream diff (session 30's top priority) is
  dead.**  D.hs and E.hs `-Dg` traces diverge at line 1118 (within
  GC 1).  By GC 17, the heaps are unrecognizable.  Don't redo this.
- **PROBE31 exonerates `scavenge_stack` iteration.**  Per-call
  `nbytes = 4*(frames+payload_words)` invariant holds exactly.
  The walker reads every byte of the live stack.  Not the bug.
- **GC 17 in the failing run is post-panic** (panic handler's tiny
  stack).  The bug fires in the mutator phase between GC 16 and
  the panic.  No GC during the bug.
- **Failure mode is always "a Var binding gets dropped"** — `swap`
  (a where-bound local Var) at TC time, OR `$dNum_a1jO`
  (a class-method dictionary Var) at simplifier time.  Same root
  cause; different surfaces.
- v0.12.0 unchanged.  Source tree clean.  Stage2 on pmacg5 is the
  clean redeploy.  `ghc-real-debug` still on pmacg5.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — narrative of session 31.
3. [`findings.md`](findings.md) — full data + analysis.
4. [`log.md`](log.md) — real-time work log.
5. [`probe31-rts.patch`](probe31-rts.patch) — the per-frame
   `scavenge_stack` probe, hardcoded verbose ON.  Re-apply if you
   want stack-walker per-call data.
6. (Reference) Session 30 [`HANDOFF.md`](../2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md) — note that its #1 (cross-run diff) is now ruled out.
7. (Reference) Session 19 [`step1-debug-rts-findings.md`](../2026-05-09-session-19-stage2-gc-bug/step1-debug-rts-findings.md) — established the "missed root" framing, still the working hypothesis.

## What NOT to redo

- **Don't try cross-run address diffing.**  Sessions diverge at GC
  1; the streams can't be matched.
- **Don't probe `scavenge_stack` iteration further.**  PROBE31
  established it walks correctly.  (Per-frame *address* logging
  could still be useful for a different question, e.g. "which
  closure is at each frame's payload" — but the iteration itself
  is exonerated.)
- **Don't try `-DS`, `-DZ`, or any other sanity-check variant.**
  Heap is consistent (session 19 + 30).  Debug RTS also flips
  failure incidence (session 31 finding).
- **Don't probe big-object path / mut_list / static_objects / SRT
  / per-closure-type / per-allocator-path** — sessions 28-30
  exhausted these aggregately.
- **Don't run with any env var set in the child process** when you
  expect the bug to fire.  Set zero extra env vars to reproduce.
  Inside a probe, hardcode any knobs (no `getenv` calls).
- **Don't trust `+RTS -Dg/-Db` to describe the same run** — debug
  RTS shifts heap layout and changes which run hits the bug.

## What to try next, in priority order

### Top: use the env-var dodge as a debugging primitive

The "any extra env var dodges" finding is a controlled
perturbation.  Use it to **bisect the trigger location**.

Concept: the failing run has the bug at heap-address X.  Adding N
bytes to environ shifts X by ~N bytes.  Find the minimum N that
dodges, and bisect.

Concrete plan:

1. Run with environ size E_0 (baseline, no extra var) → FAIL.
2. Run with environ size E_0 + 1 byte → can we?  (env vars are
   `NAME=VALUE\0`, so minimum is 2 bytes for `=\0`.  Actually
   `A\0` would be just a name with no `=`; some libcs reject.)
3. Run with environ size E_0 + 2, +3, ... +K.  Each may or may
   not dodge.  Look for the smallest dodging delta.
4. The fault address shifts by approx that delta.

Adjacent angles:
- Set env var to a string of variable length to vary delta
  precisely.  `A=` then `A=A` then `A=AA` etc.
- Or set MULTIPLE env vars to vary total environ size.

Cost: ~30 min for the sweep.  Outcome: tight numeric bound on the
heap-shift granularity (e.g., "shifts of 1, 5, 9 bytes dodge but
shifts of 2, 6, 10 don't"), which directly tells us the alignment
class of the trigger closure.

### Second: per-event probe weak-pointer + stable-pointer tables

Of the remaining root-walker candidates, these two are the smallest
and easiest:

- `markWeakPtrList` (rts/sm/MarkWeak.c) — walks `weak_ptr_list`,
  calling `evacuate` on the key + value + finalizer fields of
  each weak.  Log each weak's address + each pointer fed to
  `evacuate`.
- `markStableTables` / `enlargeStableNameTable` (rts/StablePtr.c,
  rts/sm/Sanity.c) — walks the stable-ptr table.  Log entries.

Even if these tables are SMALL (a few entries on a fresh compile),
per-event logging is cheap.  If either table has an inconsistent
walk on a failing run, that's our smoking gun.

Cost: ~1-2 h to write probe + run matrix.

### Third: GHC-side track Var lifecycle

A different audit direction.  Since the dropped binding is always
a `Var`, instrument GHC's Var creation/lookup machinery:

- At every `mkLocalVar` / `mkGlobalVar` / `mkLclId` call site,
  log the new Var's address + Uniq + name.
- At every `lookupInScope` / `extendInScope` call, log the InScope
  set's identity.
- Right before the `refineFromInScope` panic, log the InScope set
  contents and the Var being looked up.

The goal: find the GC where `$dNum_a1jO` was created, then check
if its closure address is reachable from a GC root after the next
GC.

Cost: ~3-4 h.  Heavier than the env-var bisect; do it if the
env-var bisect doesn't pin a clear region.

### Fourth: per-frame ADDRESS logging in scavenge_stack

PROBE31 confirmed walker iteration is correct, but we don't yet
have per-frame ADDRESS data.  Extend PROBE31 to also log the
address handed to `evacuate` from each bitmap slot.  Compare M5
(PASS) vs Big2 (FAIL) for the addresses ranges hit.  Cross-run
diffing won't align (we already established), but maybe one
particular bitmap slot has an obviously wrong address (e.g., off
by 1 alignment unit).

Cost: ~2 h.

### Fifth: StgRegTable saved-register state probe

Session 19 / 30 queued this.  Check `Capability->r.rCurrentNursery`,
`Capability->r.rCurrentTSO`, etc.  Before/after every GC.  Low
priority but mechanical.

## Mechanics — reproducing session 31 results

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 0. Baseline sanity (skip if just continuing)
bash tests/run-tests.sh

# 1. Verify clean reproducer (Big2 -A1m -G1 panics 1/1, no env vars)
ssh pmacg5 'cat > /tmp/Big2.hs' <<'EOF'
module Big2 where
import Data.List (sort, group)
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe)

freqMap :: Ord a => [a] -> M.Map a Int
freqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]

topK :: Ord a => Int -> [a] -> [(Int, a)]
topK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs
  where swap (a, b) = (b, a)

dedup :: Ord a => [a] -> [a]
dedup = map head . group . sort

countOf :: Ord a => a -> M.Map a Int -> Int
countOf k m = fromMaybe 0 (M.lookup k m)

shift :: Int -> [Int] -> [Int]
shift n = map (+ n)

scaleAndShift :: Int -> Int -> [Int] -> [Int]
scaleAndShift s n = map (\x -> x * s + n)

allPositive :: [Int] -> Bool
allPositive = all (> 0)

cumsum :: Num a => [a] -> [a]
cumsum = scanl1 (+)
EOF
ssh pmacg5 'cd /tmp && rm -f Big2.hi Big2.o; \
    DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1' | head -5
# Expected: ghc-real: panic! ... refineFromInScope ... $dNum_a1jO

# 2. Confirm env-var dodge
ssh pmacg5 'cd /tmp && rm -f Big2.hi Big2.o; \
    A=A DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1; echo rc=$?'
# Expected: rc=0 (PASS)

# 3. Filename bisect (104 modules, ~3 min)
bash docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/scripts/filename-bisect.sh pmacg5

# 4. Re-apply PROBE31 if you want stack-walker per-call data
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/probe31-rts.patch
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# 5. To collect FAILING-run PROBE31 data, run with NO extra env vars
ssh pmacg5 'cd /tmp && rm -f Big2.hi Big2.o; \
    DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
    /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1'

# 6. At session end — REVERT
cd external/ghc-modern/ghc-9.2.8
git checkout -- rts/sm/GC.c rts/sm/Scav.c
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

## Hosts (unchanged)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — production stage2 (clean,
    v0.12.0).
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked, kept
    for session 32.  CAVEAT: it flips failure incidence (some
    failing runs become passing under debug RTS).
- **imacg3**: not used this session.
- **indium**: don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/rts/sm/` — clean (PROBE31 reverted).
- Other GHC tree files (compiler/, hadrian/, rts/linker/, libraries/)
  — pre-existing project patches, unchanged this session.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real` — clean rebuild + redeploy
  at session-31 end, matches v0.12.0.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` — left from session 30,
  unchanged.
- New session dir: `docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/`.
- Run logs at `logs/`.

## Time estimate for session 32

- Setup + read handoff + reproduce: 15-30 min.
- Env-var bisect (top priority): 30-60 min.
- Weak ptr / stable ptr per-event probe (second priority):
  1-2 h to write + run + analyze.
- Either ☝️ likely leads to a concrete hypothesis to test; if both
  fail, move to GHC-side Var lifecycle tracking (~4 h).

Realistic: 1 medium session (~4-6 h) to pin the trigger to a
specific root walker.

## Paste-into-fresh-session prompt

```
Context: session 31 of the GHC darwin8-ppc project just wrapped up.

Session 31 delivered three major findings:
(a) Cross-run address-stream diff is unworkable — D.hs and E.hs
    (1-bit filename flip) -Dg traces diverge at line 1118 within
    GC 1.
(b) BOMBSHELL: setting any 3+ byte env var (e.g. A=A) on the child
    process dodges the bug deterministically.  Big2 -A1m -G1
    FAILs 5/5 with no env vars; PASSes 5/5 with any env var
    added.  8/8 env-var variants tested all dodge.  The bug is
    byte-level heap-layout sensitive at one specific virtual
    address.
(c) PROBE31 (per-frame scavenge_stack instrumentation) confirms
    the stack-walker iteration is correct — per-call
    nbytes = 4*(frames + payload_words) holds exactly.  Walker
    is NOT the bug.

The failing GC 17 has only 4 frames because it's the panic
handler's stack — the panic message appears BEFORE GC 17's PROBE
output.  The real bug fires in the mutator phase between GC 16
and the panic.

Failure mode is always "drops one Var binding".  Either swap
(local where-bound) at TC time, or $dNum_a1jO (class dictionary)
at simplifier time.

Remaining unprobed root walkers: weak_ptr_list, stable_ptr_table,
markCAFs per-address, scavenge_one per-block, StgRegTable.

Read in order:
1. docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/HANDOFF.md
2. docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/README.md
3. docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/findings.md
4. docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/log.md
5. (reference) docs/sessions/2026-05-09-session-19-stage2-gc-bug/step1-debug-rts-findings.md

Top priority: USE THE ENV-VAR DODGE as a debugging primitive.
Bisect environ-block-size shifts to find the minimum dodging
delta — that pins the alignment class of the trigger closure.

Second priority: per-event probe weak_ptr_list and stable_ptr
tables (untouched by all prior sessions).

Don't redo cross-run address diffing (session 31 ruled out).
Don't redo scavenge_stack iteration probes (session 31 ruled
out).  Don't run with any env var set when expecting the bug to
fire (session 31 finding: ANY env var dodges).  ALWAYS revert
probes + rebuild + redeploy clean stage2 at session end.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/HANDOFF.md`](docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/HANDOFF.md).

When session 32 ends, write the next handoff at:
`docs/sessions/<DATE>-session-32-<slug>/HANDOFF.md`.
