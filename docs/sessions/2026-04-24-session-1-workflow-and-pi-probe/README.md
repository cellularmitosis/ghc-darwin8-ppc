# Session 1 — Workflow adoption + pi-Double bug first probe

**Date:** 2026-04-24.
**Starting state:** Post-v0.1.0 release.  Test battery ran 20/25
PASS byte-identical.  One real bug catalogued: `pi :: Double` returns
`8.6e97` instead of `3.14159`.  A `subprojects/` workflow had been
tried but found too heavy; user asked to migrate to the lighter
sessions workflow (adapted from sibling project `golang-darwin8-ppc`).

**Goal:** adopt sessions workflow; begin pi-Double investigation
following `docs/proposals/bug-pi-double-literal.md`.

## Part 1 — Workflow migration

`subprojects/` was removed.  Content rehomed:

- Each `subprojects/<slug>/plan.md` → `docs/proposals/<slug>.md`.
- `subprojects/stage1-cross/post-mortem.md` → `docs/stage1-cross-post-mortem.md`.
- `subprojects/*/README.md` stubs deleted (they were just pointers).
- `subprojects/test-battery/log.md` — content already captured in
  `tests/RESULTS.md`; deleted.

`docs/sessions/` now exists with a README explaining the per-session
layout.  `CLAUDE.md` was rewritten to describe the sessions workflow
and a new `## Repo layout` section reflects the current tree.

## Part 2 — pi-Double first probe

Per [`docs/proposals/bug-pi-double-literal.md`](../../proposals/bug-pi-double-literal.md),
step 1 is a minimal reproducer with `-keep-hc-files` to inspect what
`.hc` (unregisterised C output) the cross-ghc emits for various
Double literals.

`/tmp/dlits.hs`:

```haskell
d17    = 3.14159265358979       -- ≤17 digits: works
d17pi  = 3.141592653589793      -- 17-digit rounded pi: expected to work
d19    = 3.141592653589793238   -- 19 digits: same as base's `pi`, expected to fail
simple = 1.5                    -- baseline known-good
```

Compile via cross-ghc with `-keep-hc-files`, then grep the emitted
`.hc` for each closure's initializer.

### Finding: the `.hc` emissions are IDENTICAL for d17pi and d19

```
Main_simple_closure[] = {
    (W_)&ghczmprim_GHCziTypes_Dzh_con_info, (StgWord64)0x3ff8000000000000ULL
Main_d17pi_closure[] = {
    (W_)&ghczmprim_GHCziTypes_Dzh_con_info, (StgWord64)0x400921fb54442d18ULL
Main_d19_closure[] = {
    (W_)&ghczmprim_GHCziTypes_Dzh_con_info, (StgWord64)0x400921fb54442d18ULL
Main_d17_closure[] = {
    (W_)&ghczmprim_GHCziTypes_Dzh_con_info, (StgWord64)0x400921fb54442d11ULL
```

Both `d17pi` (17 digits, `3.141592653589793`) and `d19` (19 digits,
`3.141592653589793238`) emit the IDENTICAL IEEE bit pattern
`0x400921fb54442d18`.  That's correct — those two decimal strings both
round to the same Double.

Note `d17` shows `...d11` (ends in `d11`, not `d18`) — because
`3.14159265358979` (≤17 digits, one less precision) is a slightly
different Double value than pi.

**So the generated `.hc` has the right 64-bit value.** The bug must
be later.

### Next hypothesis: `(StgWord64)` cast interacts badly with the initializer

The closure is declared as `StgWord[]` (32-bit words on PPC32), but
initialized with `(StgWord64)0x400921fb54442d18ULL`.  Clang sees a
`StgWord64` (64-bit) value being stored into a `StgWord[]` (32-bit)
array element — and may either:

1. Issue the `-Wconstant-conversion` warning we saw earlier, and
   truncate to 32 bits.  That would leave `Main_d19_closure[1]` = 0x54442d18
   (the low 32 bits of pi).
2. Or: clang emits the 64-bit value as two 32-bit words.  On big-endian
   PPC, the high word goes first, then low.  So memory layout would be:
   `[0]=Dzh_con_info, [1]=0x400921fb, [2]=0x54442d18`.
   Three slots total, not two.

If the allocation is 2 `StgWord`s (8 bytes on PPC32) but clang writes
three (12 bytes), we overrun.  If the allocation is 3 `StgWord`s (12
bytes, matching the Double-holding Dzh closure layout) but clang writes
only 2 (truncating), the third word is uninitialised → random memory.
Reading that as bits 0..31 of the Double gives a near-zero subnormal
(what we see as `3.18e-317` in some tests) or similar.

To confirm: check `sizeof(Main_d19_closure)` at compile time (clang
may emit a warning if the array has too few initializers), and count
how many 32-bit slots pi actually takes in the Dzh con layout.

Next concrete action: look at the Dzh (Double-constructor) closure
layout in `includes/ClosureTypes.h` / `stg/Closures.h` or a generated
header.

**Session ending here** because the workflow migration chewed through
the time budget.  The `.hc` inspection was the first real step — we
know the bit pattern reaches clang correctly, so the bug is in how the
`StgWord64` initializer expands on PPC32.

## Ending state

- Repo workflow migrated to `docs/sessions/` + `docs/proposals/`.
- CLAUDE.md updated.
- pi-Double investigation: `.hc` emits correct 64-bit value.  Bug is
  downstream of the literal expansion — hypothesised in the
  `(StgWord64)` → `StgWord[]` initializer mismatch.  Next session
  picks up at the Dzh closure layout.
