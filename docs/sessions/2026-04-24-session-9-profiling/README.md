# Session 9 — Profiling support investigation

**Date:** 2026-04-24.
**Starting state:** v0.4.0 released.  `-prof` flag fails because
`libraryWays = [vanilla]` in QuickCross — no `_p.a` profiling
archives built.
**Goal:** add `profiling` (and matching RTS profiling ways) to
QuickCross, rebuild, verify a `-prof` compile + heap profile via
`hp2ps`.
**Ending state:** Hit a clang-7 integrated-assembler limitation
that emits PPC displacement-form instructions with bare `0`
instead of `r0` base register.  Reverted, documented, deferred.

## What broke

After enabling `[vanilla, profiling]` libraryWays + matching RTS
ways, the rebuild progressed through Stage0/Stage1 RTS compiles
until clang-7's assembler emitted:

```
ghc_1.s:2317:13: error: unexpected integer value
        lwz r2, 16(0)
                   ^
ghc_1.s:2321:13: error: unexpected integer value
        lwz r2, 20(0)
                   ^
ghc_1.s:2348:14: error: unexpected integer value
        lwz r26, 12(0)
                    ^
ghc_1.s:2366:13: error: unexpected integer value
        stw r3, 12(0)
                   ^
```

Source: GHC's `-DPROFILING` build path emits LLVM IR that lowers
through clang-7's PPC backend with `0` (bare integer) as the base
register operand of displacement-form load/store.  Apple's
historical `as` accepts this Apple-PPC syntax convention; clang-7's
integrated assembler does not.

## Why this is hard

Three options to unblock:

1. **Switch to non-integrated `as`** — pass `-fno-integrated-as` and
   use cctools-port's PPC `as`.  The cctools `as` is Apple-derived
   and may accept the bare `0`.  But our cctools-port build uses
   ld64-253.9 which targets a more modern assembly syntax; the
   cctools `as` at this version may not be compatible with this
   Apple-style oddity either.  Worth trying.

2. **Post-process the `.s` file** — sed `(0)` → `(r0)` on every
   `\b(stw|lwz|stwu|lwzu|stb|lbz|sth|lhz|lwa)\b r\d+, \d+\(0\)`
   pattern before passing to the assembler.  Hacky but bounded.

3. **Patch the profiling RTS to avoid the offending C constructs.**
   The bare-`0` emission likely comes from a specific use of `&foo`
   in profiling code where `foo` is a global at offset.  Could
   refactor that one site.  Hardest because it requires finding
   the specific input pattern.

Time-wise, #1 is the quickest experiment.  Saving for a future
session.

## What stays in v0.4.0

The status-quo bindist works for everyone who doesn't need
profiling.  -prof fails with a clear error message
("Could not find module 'Prelude' / Perhaps you haven't installed
the profiling libraries").  Users can use timing-style profiling
(`time foo`) or RTS stats (`+RTS -s`) without `-prof`.

## Hand-off

Reverted QuickCross.hs back to vanilla-only.  Comment in the
flavour file expanded to explain why profiling is off.  No release
needed — the toolchain is unchanged from v0.4.0.

Next session: pivot to runghc + ghc-pkg-list, or take a swing at
the GHCi loader instead.
