# Handoff from session 32 → session 33

**For:** the next claude session.
**From:** session 32 (env-var bisect + heap-address probe; 2026-05-12).
**Recommended pickup:** probe **what's AT the trigger heap address**
(closure header + payload) and find a structural commonality
across the three captured addresses.  Single-blind-spot-address
is dead; we need a new hypothesis for the bug condition.

## TL;DR (mandatory read)

- **Session 31's "any env var dodges" claim is wrong.**  PASS/FAIL
  is non-monotonic in env-var length, with five distinct surface
  errors observed.  A FIFTH surface (`depSortStgBinds: Found
  cyclic SCC`) joins REFINE / SCOPE / STGCMM as bug indicators.
- **The single-blind-spot-virtual-address hypothesis is
  FALSIFIED.**  PROBE32 (added a heap-address dump to
  `refineFromInScope`) captured THREE distinct trigger addresses
  in three different megablocks: 0xe003348, 0xcce80d0, 0xbe30ddc.
  Different env-sizes pin the bug to different addresses; the bug
  isn't anchored to a specific virtual address.
- **The bug fires deterministically (5/5 iters) for a given
  process configuration.**  Same env → same address → same Var
  dropped.
- **Same-length env vars with different bytes give different
  results** (e.g., `A=AAAAAAAAAAAAAAAAA` vs `PROBE31_VERBOSE=0`
  at 17 bytes), so the dodge isn't pure size.
- v0.12.0 unchanged.  Source tree clean.  Stage2 on pmacg5 is
  the clean redeploy.
- **Caveat**: stage2's build appears to be non-deterministic.  My
  session-32-end clean rebuild produces a binary that hits Big2
  no-env at FAIL_SCOPE (`'swap' is not in scope during type
  checking`) instead of FAIL_REFINE.  Same bytes-size (193188676)
  as session-31-end binary, but presumably differs by embedded
  timestamps / cabal hashes.  **The bug still reproduces** —
  just at a different surface.  If session 33 sees SCOPE where
  the docs say REFINE, that's expected.  Use env-var zones to
  hit a REFINE if needed (e.g., on the session-32-end binary,
  env-len 650-700 still hits REFINE on the clean stage2).

## Read in order

1. **This file.**
2. [`README.md`](README.md) — narrative of session 32.
3. [`findings.md`](findings.md) — full data + analysis.
4. [`log.md`](log.md) — real-time work log.
5. [`probe32-refineFromInScope-addr.patch`](probe32-refineFromInScope-addr.patch) — the panic-site address probe.  Re-apply with `git apply` from inside `external/ghc-modern/ghc-9.2.8`.
6. (Reference) Session 31 [`HANDOFF.md`](../2026-05-12-session-31-per-event-root-walker-trace/HANDOFF.md) — note that its top priority (env-var bisect) is now done; "any env var dodges" claim disproved.

## What NOT to redo

- **Don't redo cross-run address-stream diff** — session 31 ruled
  out.
- **Don't redo `scavenge_stack` iteration probes** — session 31
  ruled out.
- **Don't hypothesize "single fixed virtual address X is the
  blind spot"** — session 32 ruled out via the heap-address probe.
  Three distinct addresses trigger the same bug class.
- **Don't trust "ANY env var dodges"** — session 32 ruled out.
  Many env-var configurations FAIL with various surfaces.
- **Don't expect the dodge to be size-only** — session 32 showed
  same-length different-content env vars yield different
  outcomes.  Bytes-in-environ matters, not just byte-count.

## What to try next, in priority order

### Top: dump closure-header + payload at the trigger heap address

The three captured addresses (0xe003348, 0xcce80d0, 0xbe30ddc)
all share "the bug fires here" but nothing else structurally.
Hypothesis: the trigger closures share a SPECIFIC SHAPE — info
pointer, header bits, payload pattern — that the GC walker
misclassifies.

Plan:
1. Re-apply PROBE32 to get back the address.
2. Extend probe to also dump the words at v-0x4, v, v+0x4,
   v+0x8 (info pointer and first few payload words).
3. Run across the three known REFINE zones (env-len 650-700,
   850-900, 1700) and compare the captured closure bytes.
4. Look for a common pattern: shared low byte? shared info-ptr
   target? shared closure-type tag in header?

If the closures share a bit pattern, that's our smoking gun —
the walker has a check that misclassifies that pattern.

Cost: ~1 h (write probe, rebuild stage1, deploy, run sweep).

### Second: extend probe to other panic surfaces

PROBE32 only fires at refineFromInScope.  For the SCOPE,
STGCMM, and DEPSORT surfaces, we don't have addresses.  Adding
similar probes:

- **SCOPE** at TC time: panic site is in `compiler/GHC/Tc/Utils/
  Env.hs` or `compiler/GHC/Rename/Env.hs`.  Find the
  "is not in scope during type checking" message and add the
  Var's heap address.
- **STGCMM** at codegen: panic site is `compiler/GHC/StgToCmm/
  Env.hs:153`.  Add address dump there.
- **DEPSORT** at STG dep sort: panic site is `compiler/GHC/Stg/
  DepAnal.hs` or wherever `depSortStgBinds` lives.  Add address
  dump.

With addresses across all four FAIL surfaces, we may see a
unified pattern.

Cost: ~2-3 h (find sites, add probes, rebuild, run).

### Third: track the trigger Var's lifecycle (GHC-side)

Add a probe to `mkLocalVar` / `mkGlobalVar` that logs each
Var's address at creation.  Then we know the original address
of every Var that gets dropped — and we can correlate with
the panic-time address.  If they differ, GC moved the Var
correctly but lost track somewhere; if they match, the Var
was never moved (live but not scavenged).

Cost: ~3-4 h.  Heavy; do after #1 if #1 doesn't pin a pattern.

### Fourth: weak/stable-ptr per-event probe (session 31 priority #2)

Session 31's queued priority — never started.  With the new
"closure-shape" framing, weak/stable-ptr-table walks are less
likely to be the bug (since they walk specific tables not
arbitrary Vars).  But still worth trying as a control: confirm
they walk consistently across PASS / FAIL runs.

Cost: ~2 h.

### Fifth: bisect environ CONTENT (not just length)

Same-length different-content env vars give different results.
Try systematic content variation: vary each byte of a fixed-length
env var and see which bytes flip outcomes.  This tells us
whether the perturbation is via:
- Byte hash → libc malloc/getenv path
- Byte content shifting environ block offset of unrelated env vars
- Specific bytes triggering specific malloc behaviors

Cost: ~1-2 h.

## Mechanics — reproducing session 32 results

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 0. Baseline sanity (skip if just continuing)
bash tests/run-tests.sh

# 1. Verify clean reproducer (Big2 -A1m -G1 panics REFINE on no-env)
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

# 2. Verify baseline (10/10 FAIL_REFINE expected)
bash docs/sessions/2026-05-12-session-32-env-var-bisect/scripts/env-trial.sh pmacg5 10
# Expected: pass=0 refine=10 scope=0 stgcmm=0 other=0 of 10

# 3. Re-apply PROBE32 to get heap addresses
cd external/ghc-modern/ghc-9.2.8
git apply ../../../docs/sessions/2026-05-12-session-32-env-var-bisect/probe32-refineFromInScope-addr.patch
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5

# 4. Run a few env-sizes that produce REFINE with addresses
for n in 650 700 850 900 1700; do
    pad=$(awk "BEGIN{for(i=1;i<=$((n-2));i++) printf \"A\"}")
    e="A=${pad}"
    ssh -q pmacg5 "cd /tmp && rm -f Big2.hi Big2.o; env $e DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1" | grep refineFromInScope
done
# Expected output:
#   refineFromInScope 0xe003348   (or similar — exact bytes shift if probe is extended)
#   refineFromInScope 0xe003348
#   refineFromInScope 0xcce80d0
#   refineFromInScope 0xcce80d0
#   refineFromInScope 0xbe30ddc

# 5. At session end — REVERT
cd external/ghc-modern/ghc-9.2.8
git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

## Hosts (unchanged)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — production stage2 (clean,
    v0.12.0).
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked,
    kept from session 30.  CAVEAT: flips failure incidence.
- **imacg3**: not used this session.
- **indium**: don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/compiler/GHC/Core/Opt/Simplify/Env.hs`
  — clean (PROBE32 reverted via `git checkout`).
- Other GHC tree files (compiler/, hadrian/, rts/linker/,
  libraries/) — pre-existing project patches, unchanged this
  session.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real` — clean rebuild +
  redeploy at session-32 end, matches v0.12.0.
- `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` — left from
  session 30, unchanged.
- New session dir: `docs/sessions/2026-05-12-session-32-env-var-bisect/`.
- Run logs gitignored at `log/session32/`.

## Time estimate for session 33

- Setup + read handoff + reproduce: 15-30 min.
- PROBE32-EXT (closure-header + payload dump): 1-2 h.
- Cross-comparison of closure bytes across three trigger
  addresses: 30-60 min.
- If a common pattern emerges → propose a GC-walker bug
  hypothesis: 30 min.
- If no pattern → move to SCOPE/STGCMM/DEPSORT panic-site
  address probes: 2-3 h.

Realistic: 1 medium session (~4-6 h) to either pin a closure-
shape commonality or rule out closure-shape as the trigger.

## Paste-into-fresh-session prompt

```
Context: session 32 of the GHC darwin8-ppc project just wrapped up.

Session 32 delivered three major findings:
(a) Session 31's "any env var dodges" claim is wrong.  The
    bug's PASS/FAIL pattern is non-monotonic in env-var
    length, with FIVE distinct surface errors (REFINE, SCOPE,
    STGCMM, DEPSORT, PASS) cycling as env-size grows.
(b) PROBE32 captured the heap address of the dropped Var
    at the refineFromInScope panic.  THREE distinct addresses
    triggered the bug across three REFINE zones: 0xe003348,
    0xcce80d0, 0xbe30ddc.
(c) THE SINGLE-BLIND-SPOT-VIRTUAL-ADDRESS HYPOTHESIS IS
    FALSIFIED.  Different env-sizes pin the bug to different
    addresses in different megablocks.  The bug isn't anchored
    to one specific virtual address X.

Same-length env vars with different content yield different
outcomes (A=AAAAAAAAAAAAAAAAA = SCOPE, PROBE31_VERBOSE=0 = PASS),
so the dodge isn't size-only.

For a fixed env configuration, the bug fires deterministically
(5/5 iters identical).

Read in order:
1. docs/sessions/2026-05-12-session-32-env-var-bisect/HANDOFF.md
2. docs/sessions/2026-05-12-session-32-env-var-bisect/README.md
3. docs/sessions/2026-05-12-session-32-env-var-bisect/findings.md
4. docs/sessions/2026-05-12-session-32-env-var-bisect/log.md
5. (reference) docs/sessions/2026-05-12-session-31-per-event-root-walker-trace/HANDOFF.md

Top priority: extend PROBE32 to ALSO dump the closure header
+ first few payload words at the trigger address.  Compare
across the three known REFINE zones (env-len 650-700, 850-900,
1700) to find a structural commonality.  Hypothesis: the
trigger closures share a closure-shape that the GC walker
misclassifies, INDEPENDENT of virtual address.

Second priority: add similar address-dump probes to the SCOPE,
STGCMM, and DEPSORT panic sites so we get heap-address data
across ALL four FAIL surfaces.

Don't redo cross-run address diffing (session 31 ruled out).
Don't redo scavenge_stack iteration probes (session 31 ruled
out).  Don't hypothesize single-blind-spot-address (session 32
ruled out).  ALWAYS revert probes + rebuild + redeploy clean
stage2 at session end.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-12-session-32-env-var-bisect/HANDOFF.md`](docs/sessions/2026-05-12-session-32-env-var-bisect/HANDOFF.md).

When session 33 ends, write the next handoff at:
`docs/sessions/<DATE>-session-33-<slug>/HANDOFF.md`.
