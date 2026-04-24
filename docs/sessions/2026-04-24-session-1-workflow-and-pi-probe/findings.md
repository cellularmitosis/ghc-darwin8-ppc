# Session 1 findings

## 1. `pi` bug root cause + fix (CmmToC.hs `decomposeMultiWord`)

Fixed by [`patches/0008-cmmtoc-split-w64-double-on-32bit.patch`](../../../patches/0008-cmmtoc-split-w64-double-on-32bit.patch).

`compiler/GHC/CmmToC.hs` has a helper `staticLitsToWords` for emitting
static closure init lists.  It calls `foldMap decomposeMultiWord` to
break multi-word literals into word-sized pieces.

`decomposeMultiWord` had two relevant cases:

```haskell
decomposeMultiWord (CmmFloat n W64)
  = [doubleToWord64 n]             -- returns a W64 integer
decomposeMultiWord (CmmInt n W64)
  | W32 <- wordWidth platform
  = [CmmInt hi W32, CmmInt lo W32] -- splits W64 int into two W32
```

The intent was for the Float-W64 case to produce a W64 int which
would then be broken up by the W64-int case "on the next iteration on
32-bit platforms" (per a comment).  But **there is no next iteration**
— `foldMap` is single-pass.  So on 32-bit, `CmmFloat pi W64` became
`[CmmInt piBits W64]` and was emitted as
`(StgWord64)0x400921fb54442d18ULL` directly into a `StgWord[]` array.

Clang silently truncated (with `-Wconstant-conversion`) to the low 32
bits.  The runtime then read a broken Double — low 32 bits interpreted
as the high half of the Double → exponent of `0x5444` → ~5e97.

Fix: make the Float-W64 case recurse on the int it just produced when
on a 32-bit platform.  One-line change (plus a Note [...] comment for
future spelunkers).

## 2. Dzh constructor closure layout (for future PPC work)

A Double-holding `Dzh` constructor closure on 32-bit BE:

```
offset 0: con_info_ptr    (1 StgWord = 4 bytes)
offset 4: Double hi 32    (1 StgWord = 4 bytes)
offset 8: Double lo 32    (1 StgWord = 4 bytes)
total:    12 bytes
```

Before the fix, the emitted `StgWord closure[] = { info, (StgWord64)bits }`
allocated only 8 bytes because clang treated the 64-bit cast as a
single (truncated) initializer for the flex array.  After the fix the
initializer has 3 elements → 12 bytes → Dzh_con_info's ptrs/nptrs
layout matches.

## 3. Test-battery harness bug (`set -u` + empty array)

`tests/run-tests.sh` crashes on the summary line when `FAIL_COMPILE`
or `FAIL_RUN` is empty:

```
./run-tests.sh: line 94: FAIL_COMPILE[*]: unbound variable
```

This doesn't affect the PASS/FAIL arrays themselves, but truncates the
Summary banner.  Fix by either pre-initializing `FAIL_COMPILE=()` and
friends, or removing `set -u` from the script, or using `${FAIL_COMPILE[*]:-}`.

Noted for next session — not blocking.

## 4. RTS Cabal `flag mingwex` default is `True` upstream

`rts/rts.cabal` has `flag mingwex` with `default: True`.  This leaks
`-lmingwex` (a Windows-only lib) into the rts `extra-libraries` on
non-Windows platforms.  When we re-register the rts package, it shows
up again and our stage1→Tiger links fail on `library not found
for -lmingwex`.

Workaround: edit `rts/rts.cabal` to set `default: False` (done this
session).

Upstream fix would be to gate the flag's default on `os(mingw32) or
os(windows)`, but Cabal's flag syntax doesn't support conditional
defaults directly — would need a top-level `@CabalMingwex@` autoconf
substitution that knows the target OS.  Our in-place edit is pragmatic
for now.

## 5. Workflow: sessions > subprojects for this project

Earlier session tried `subprojects/<slug>/` layout (chunks by theme).
Each chunk wanted README + plan + log + post-mortem, and the chunks
didn't cleanly correspond to what a real session looks like (one
session = one mix of bugfix + infra + docs).  Sessions (chunks by
date) match the work better.  Adapted from sibling project
`golang-darwin8-ppc`'s convention.

Forward-looking plans live in `docs/proposals/` as standalone files
until picked up.
