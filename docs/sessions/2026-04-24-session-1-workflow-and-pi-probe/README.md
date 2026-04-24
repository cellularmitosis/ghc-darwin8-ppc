# Session 1 — Workflow adoption + pi-Double codegen fix

**Date:** 2026-04-24.
**Starting state:** Post-v0.1.0 release.  Test battery: 20/25 PASS
byte-identical, with one real bug catalogued (`pi :: Double` returns
`8.6e97` instead of `3.14159`).  A `subprojects/` workflow had been
tried the previous session but found too heavy; user asked to migrate
to the lighter sessions workflow (adapted from sibling project
`golang-darwin8-ppc`).

**Goal going in:** adopt sessions workflow; diagnose and (if
tractable) fix the pi-Double bug.

**Ending state:** Both done.  `v0.2.0` tagged and released.
Test battery now 21/25 PASS byte-identical (was 20), 0 real bugs
remaining.  Workflow migrated cleanly; `docs/sessions/` + `docs/proposals/`
now in place, `subprojects/` removed.

## Part 1 — Workflow migration

- `subprojects/` dir removed.
- `subprojects/<slug>/plan.md` → `docs/proposals/<slug>.md` (four files).
- `subprojects/stage1-cross/post-mortem.md` → `docs/stage1-cross-post-mortem.md`.
- `subprojects/*/README.md` stubs deleted (they were just pointers).
- `subprojects/test-battery/log.md` deleted (content already captured in `tests/RESULTS.md`).
- `docs/sessions/` introduced with a README describing the per-session layout.
- `CLAUDE.md` rewritten to describe the new layout + a `## Repo layout` section.

## Part 2 — pi-Double codegen fix

Walked the proposed plan in [`docs/proposals/bug-pi-double-literal.md`](../../proposals/bug-pi-double-literal.md):

### Step 1: minimal reproducer

`/tmp/dlits.hs` with four Double literals:

```haskell
d17    = 3.14159265358979       -- ≤17 digits
d17pi  = 3.141592653589793      -- 17-digit pi
d19    = 3.141592653589793238   -- 19-digit pi (same as base's `pi`)
simple = 1.5
```

### Step 2: inspect the .hc

Ran cross-ghc with `-keep-hc-files`.  The emitted .hc had identical
patterns for every Dzh closure:

```c
StgWord Main_simple_closure[] = {
  (W_)&ghczmprim_GHCziTypes_Dzh_con_info,
  (StgWord64)0x3ff8000000000000ULL
};
```

— the `(StgWord64)` cast is being assigned to a `StgWord[]` (32-bit
word array on PPC32).  Clang warns and truncates.

### Step 3: trace to the emission site

Found `staticLitsToWords` in `compiler/GHC/CmmToC.hs`:

```haskell
staticLitsToWords platform = go . foldMap decomposeMultiWord
  where
    decomposeMultiWord (CmmFloat n W64)
      = [doubleToWord64 n]             -- W64 int; relies on "next iteration"
    decomposeMultiWord (CmmInt n W64)
      | W32 <- wordWidth platform
      = [CmmInt hi W32, CmmInt lo W32] -- would split W64 → [W32, W32]
```

The Float-W64 case produces a W64 int, but `foldMap` is single-pass
so the Int-W64 case is never reached.

### Step 4: the patch

Make the Float-W64 case recurse on the W64 int it produces when on a
32-bit platform.  Saved as `patches/0008-cmmtoc-split-w64-double-on-32bit.patch`.

### Step 5: rebuild + verify

- Nuked `_build/stage0/compiler/build/GHC/CmmToC.{o,hi}` to force
  stage0 ghc's compiler library to rebuild with the patch.
- Nuked `libraries/base/GHC/Float.{o,hi}` and `libHSbase.a` so base
  gets re-emitted by the fixed ghc.
- Ran hadrian.  Cascade rebuilt stage0 ghc + stage1 RTS + base + downstream.
- Compile the reproducer again.  The `.hc` now shows
  `{info_ptr, (W_)0x400921fbU, (W_)0x54442d18U}` — three StgWords, correct layout.
- Shipped to pmacg5: all four Double literals printed correctly.
- Re-ran full test battery: 21/25 PASS (was 20/25).  `02_double_literal`
  now byte-identical.

## Part 3 — Cleanups

- `tests/run-tests.sh` — fixed `set -u + empty array` crash in Summary.
- `tests/RESULTS.md` — updated pass count, moved BUG-1 to "Fixed bugs".
- `docs/state.md` — patch 0008 listed; test battery summary added.
- `docs/roadmap.md` — A. Bug fixes marked complete.
- `rts/rts.cabal` — flipped `flag mingwex` default to False so re-registration
  doesn't reintroduce `-lmingwex` on Darwin.

## Part 4 — v0.2.0 release

Bindist rebuilt + re-tarred (117 MB .xz).  Pushed main, cut
`v0.2.0` tag, uploaded bindist as release asset.

URL: https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.2.0
SHA-256: `2abdd179bca1f36af5a20416c6068ae5459876fd6db16a8ec888bd4d4e98170f`

## Lessons

- **Don't trust "next iteration" comments.**  The existing
  `decomposeMultiWord` had a comment saying the W64 int would be
  "broken up further on the next iteration on 32-bit platforms" but
  there was no such iteration.  That comment had been lying for years.
- **Sessions workflow → lighter.**  Moving from `subprojects/<slug>/`
  (chunks by theme, 4 files per chunk) to `docs/sessions/YYYY-MM-DD-...` 
  (chunks by date, 3 files per session) eliminated a lot of scaffolding
  with no loss of information.
- **`-keep-hc-files` is invaluable** when debugging GHC unreg-codegen
  bugs.  Without it the bug would have been much harder to isolate.

## Hand-off

Next session should pick up D (bindist-installer) from the roadmap —
the actual install script that rewrites `lib/settings` for a target
user's machine.  pi was A.  B (stage2 native) and C (GHCi) remain
stretch goals.
