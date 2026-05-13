# Handoff from session 27 → session 28

**For:** the next claude session.
**From:** session 27 (non-perturbing repro nailed; `-G1` partial
workaround; bug has two distinct corruption modes; 2026-05-12).
**Recommended pickup:** decide between "one bug, two victims" vs
"two bugs" with a slim RTS-side probe.  Then audit the mut_list /
write-barrier path for the STG-time variant.

## TL;DR (mandatory read)

- **Non-perturbing deterministic repro nailed:** `M5.hs +RTS -A1m`
  on clean stage2 panics **10/10** with the STG-time panic family
  (depSortStgBinds, refineFromInScope, "variable not found").
- **`+RTS -A1m -G1` (single generation) fully suppresses M5.hs**
  (10/10 OK) and M5plus.hs (5/5 OK).
- **`-G1` does NOT suppress Big2.hs** (a clean ~30-LOC module that
  imports Data.Map.Strict and has a `where`-bound local function):
  10/10 fail with a **new corruption signature** — `* GHC internal
  error: 'swap' is not in scope during type checking, but it
  passed the renamer`.
- **The bug has at least two distinct corruption modes.**  Sessions
  17–26 catalogued only the STG-time family; the TC-time variant is
  new in session 27.  Either: (a) two separate bugs, OR (b) one bug
  with two victim data structures.  Need a discriminator.
- v0.12.0 ships unchanged.  Source tree clean.  No commits to
  external/ghc-modern this session.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — narrative of session 27.
3. [`findings.md`](findings.md) — full data tables and analysis.
4. (Reference) Session 26 [`HANDOFF.md`](../2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md)
   for the context this session built on.
5. (Reference) Session 17 [`GC-BUG-FOUND.md`](../2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)
   for the original panic catalogue.

## What to NOT redo

- **Don't bother with PROBE26-style Haskell-side BS classifiers.**
  Session 26 ruled out BS-pinning-invariant theory and showed that
  Haskell-side instrumentation in `mkFastStringByteString` perturbs
  the bug away on M5.hs.
- **Don't re-prove the BS-pinning theory is dead.**  150/150
  PlainPtr-pinned, hypothesis (a) rejected.
- **Don't audit Catch.hs StackRep, mkLivenessBits, stackMapToLiveness,
  LayoutStack, or any stack-frame bitmap path.**  Sessions 21–24
  settled them.
- **Don't poison the stack (PROBE22 / PROBE23 family).**  Both have
  served their purpose and add probe artefacts that confuse the
  picture.
- **Don't re-measure the panic rate on M5.hs.**  We have 10/10 from
  this session; treat it as deterministic.

## What to try next, in priority order

### Top: discriminate "one bug, two victims" vs "two bugs"

The cleanest single experiment: write a **slim RTS-side probe** that
prints, at every GC, a small fixed-size summary:

- `gc_no`, `N` (gen being collected), `major_gc`
- Per-gen: `mut_list` length in entries (`countOccupied(saved_mut_lists[g])`)
- Per-gen: blocks promoted in / out
- Total `static_objects` chain length scavenged this GC

Run on:
- M5.hs `+RTS -A1m` (10/10 panic — STG-time)
- M5.hs `+RTS -A1m -G1` (10/10 OK — bug suppressed)
- Big2.hs `+RTS -A1m -G1` (10/10 fail — TC-time)
- Big2.hs `+RTS -A1G` (10/10 OK — bug suppressed by no-GC)

Compare the per-GC summaries.  If the mut_list bookkeeping looks
*identical* between M5.hs (`-G1` clean) and Big2.hs (`-G1` broken),
then the mut_list path isn't the cause of the TC-time variant; the
TC-time variant has a different mechanism.

This probe is **fully RTS-side** so it doesn't perturb Cmm codegen
on the Haskell side — important after session 26's PROBE26 lesson.
Cost: ~1 RTS rebuild (~3 min for `rts/sm/GC.c` alone via Hadrian)
+ N runs.  Cheap.

### Second: audit `rts/Updates.cmm` and write-barrier code

If `-G1` suppression on M5.hs is real, the bug is somewhere in the
older-gen mut_list machinery — either:
- The mutator-side write barrier in `Updates.cmm` /
  `PrimOps.cmm::stg_writeMutVarzh` etc. is failing to add some
  closures to the mut_list on PPC32.
- The RTS-side `recordClosureMutated` / `dirty_MUT_VAR_GC` is
  buggy.
- `scavenge_mutable_list` / `scavenge_one` for some mut_list entry
  type miscalculates pointer payload on PPC32.

Concrete file list to audit, PPC32-eyes:

- `rts/Updates.cmm` — `stg_BLACKHOLE_info`, `stg_upd_frame_*`
- `rts/PrimOps.cmm` — `stg_writeMutVarzh`, `stg_writeMutVar*`,
  `stg_writeArray*`
- `rts/sm/Storage.c::dirty_MUT_VAR` (line 1402),
  `dirty_TVAR` (line 1425).
- `rts/sm/Scav.c::scavenge_mutable_list` (line 1592),
  `scavenge_capability_mut_lists` (line 1697),
  `scavenge_one` (search for `scavenge_one`).

Look especially for:
- Cmm code that uses `bdescr->free` arithmetic — endian / pointer-
  size issues.
- C code that reads/writes `bd->flags` — should be uint16_t; PPC32
  is big-endian so word-order matters in struct layout.
- The "clean → dirty" info-table swap — uses `RELAXED_STORE`; on
  non-threaded PPC32 this is just a regular store, but the info
  pointer value loaded for comparison may be cached.

### Third: address the TC-time variant separately

If the mut_list audit explains the STG-time variant (M5.hs), but the
TC-time variant (Big2.hs) survives, the next-priority audit is:

- `scavenge_thunk_srt` / `scavenge_fun_srt` (Scav.c:384, 397).
  Both gated by `if (!major_gc) return;`.  With `-G1`, every GC is
  major, so these run a LOT.  If they have a PPC32 SRT-encoding
  bug, Big2.hs `-A1m -G1` would still fail.
- `scavenge_static` (Scav.c:1729).  Walks the `static_objects`
  linked list using `STATIC_LINK(info, p)` macros.  PPC32 alignment
  of static info-table fields could be wrong.
- Info-table layout: read `includes/rts/storage/InfoTables.h` with
  PPC32 alignment eyes.  The `StgFunInfoTable` / `StgThunkInfoTable`
  inheritance via `i.layout` union — does the SRT offset
  arithmetic come out right with `__alignof__(StgFunPtr) == 4`?

### Fourth: bisect

`+RTS -A1m -G1 -F0.5` lowers the survival factor on Big2.hs; does
it help?  Conversely, `+RTS -A1m -G3` (three generations) might
expose yet another variant.  Cheap to try.

## Mechanics — reproducing session-27 results

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# 1. Baseline
bash tests/run-tests.sh   # expect 30 PASS / 4 design diffs (one test
                          # may transient-fail if you run two test
                          # runners concurrently; serialize)

# 2. M5.hs panic-rate matrix
bash docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/measure-panic-rate.sh \
    pmacg5 10 M5
# ~10 min.  Expected: -A1m 0/10, -A1m -G1 10/10, -A1G 10/0.

# 3. Big2.hs matrix
bash docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-big2-test.sh \
    pmacg5 10
# ~12 min.  Expected: -A1G 10/0, -A1m 1/9, -A1m -G1 0/10.

# 4. (If implementing the priority-1 probe) edit rts/sm/GC.c, rebuild
#    stage1 ghc lib, redeploy:
cd external/ghc-modern/ghc-9.2.8
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/rts/libHSrts-1.0.2.a
# (only RTS rebuild needed — ~3 min if only GC.c changes)
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
```

## Hosts (unchanged)

- **uranium** (this Mac): host for cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
- **imacg3**: smaller-RAM PPC G3.
- **indium**: trimmed dev tools — don't use for clang or hadrian builds.

## What's clean / dirty in the source tree

- `external/ghc-modern/ghc-9.2.8/` — clean (no source edits this
  session).
- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` — unchanged from
  session-26 end (v0.12.0-equivalent).
- New session log: `docs/sessions/2026-05-12-session-27-non-perturbing-repro/`
  + run logs at `logs/`.

## Time estimate for session 28

- Setup + read handoff + verify session-27 numbers: 30 min.
- Implement the priority-1 RTS-side probe (per-GC mut_list /
  static-object counter): 1–2 h (one focused C edit + RTS rebuild
  + redeploy + 4 short runs).
- Analyse the probe output and pick mut_list audit vs SRT/static
  audit: 30–60 min.
- Audit + first hypothesis test: 2–3 h.

Realistic: 1 medium session (~4–6 h) to either nail the STG-time
variant's mechanism or pivot.  Then 1–2 more medium sessions to
address the TC-time variant and ship a fix.

## Paste-into-fresh-session prompt

```
Context: session 27 of the GHC darwin8-ppc project just wrapped up.
Session 27 nailed a deterministic non-perturbing repro for the
stage2 GC bug — `M5.hs +RTS -A1m` panics 10/10 on clean stage2.
`+RTS -A1m -G1` (single-generation) fully suppresses M5.hs's panic
family (10/10 OK) AND M5plus.hs (5/5 OK), but does NOT suppress
Big2.hs (a clean ~30-LOC module that imports Data.Map.Strict and
uses a `where`-bound local function): Big2.hs `+RTS -A1m -G1` fails
10/10 with a new, previously-undocumented signature: `* GHC internal
error: 'swap' is not in scope during type checking, but it passed
the renamer`.  So the bug has at least two distinct corruption
modes — STG-time (suppressed by -G1) and typecheck-time (not
suppressed).

This session resets the playing field after sessions 19–26's various
dead-end hypotheses (BS-pinning invariant, mkLivenessBits, StackRep,
poison-on-stale-slot).  v0.12.0 ships unchanged; no source-tree edits
this session.

Read in order:
1. docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md
2. docs/sessions/2026-05-12-session-27-non-perturbing-repro/README.md
3. docs/sessions/2026-05-12-session-27-non-perturbing-repro/findings.md
4. (reference) docs/sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md
5. (reference) docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md

Top priority: write a slim RTS-side probe (no Haskell-side
instrumentation, just a printf at start/end of `GarbageCollect()`
reporting per-gen mut_list lengths + static-object chain length +
promotion counts) and run on M5.hs `-A1m`, M5.hs `-A1m -G1`,
Big2.hs `-A1m -G1`, Big2.hs `-A1G`.  Goal: discriminate "one bug,
two victim data structures" from "two distinct bugs."

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped — don't break stage2's -A1G wrapper.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md`](docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md).

When session 28 ends, write the next handoff at:
`docs/sessions/<DATE>-session-28-<slug>/HANDOFF.md`.
