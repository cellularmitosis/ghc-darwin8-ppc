# Session 17 findings — things learned that will matter later

## The stage2 dragon was a GC bug

The session-14 hypothesis (`simpleOptPgm` miscompile) was the wrong
layer.  The actual bug is in the **PPC-Darwin RTS garbage collector**:
a major GC during a compile corrupts the typechecker's `Bag`-based
binding store.  Top-level bindings drop out, downstream passes panic.

Workaround: `+RTS -A1G -RTS` keeps small compiles inside one
allocation block so GC never fires.  Shipped as
`scripts/ghc-stage2-wrapper.sh`.

Underlying GC bug not yet fixed — likely a missing PPC memory
fence in 9.2.8's RTS that 8.6.5 had.  See [`GC-BUG-FOUND.md`](GC-BUG-FOUND.md).

## How non-determinism led to the GC hypothesis

The decisive symptom: the same binary on the same input produces
different observable bindings depending on which `-d…` dump flags
are passed.  That's not consistent with a "this pass drops
bindings" miscompile — it has to be memory corruption.

Once you ask "what alters memory state during a compile?" the GC
answer falls out.  Different dump flags → different forcing order
of thunks → GC fires at different points → different parts of
the bag get nuked.

## User-code probes ruled out big bug categories

Three test programs (saved at `probes/`) exercise the same
primitives ghc uses heavily.  All run **correctly** on Tiger:

- `BagTest.hs` — `mapBagM` over a `TwoBags (UnitBag a) (UnitBag b)`.
- `AtomTest.hs` — `fetchAddWordAddr#` as an atomic counter (the
  primitive that backs ghc's UniqSupply).
- `USup.hs` — full `mkSplitUniqSupply` pattern with
  `unsafeDupableInterleaveIO` + `noDuplicate#` + recursive splitting.

Translation: there's nothing wrong with how stage1 cross-compiles
these primitives in user code.  The bug fires only inside ghc-the-
binary itself, where the same primitives live alongside hundreds
of MB of allocations.  That's a strong "GC, not codegen" signal —
the user-code probes don't allocate enough to GC.

## LLVM is not the (whole) problem

Rebuilding stage1 with `-fllvm` removed (so all libraries go through
unreg-C + gcc14 instead of LLVM-7) **does not fix** stage2.  The
unreg-C path produces stage2 that's broken in a slightly different
shape — `Sig1.hs` typechecks both bindings (LLVM build dropped
one), but `M5.hs` and `Hello.hs` still fail.

So both backends miscompile something.  And both are masked by
`-A1G`.  That's the third triangulation point pointing at the RTS,
not at codegen.

## The threshold table is useful for downstream investigation

`-A8m` … `-A64m` all fail on `M5.hs` (2 trivial bindings).  `-A128m`
works for tiny modules.  `-A256m` works for `Hello.hs` and tiny
modules but fails on `Plus.hs` (which imports `Data.List`,
`Data.Char`, `Data.Map.Strict` — i.e. real .hi-file ingestion).
`-A1G` covers the common cases tested.

When fixing the GC bug, this gives you a knob: instrument the GC
and reproduce by dropping `-A` until it fires.  Or simply: **at
the point of the first major GC, the renamer's `Bag` of bindings
is intact; after the first major GC, it isn't.**

## ghc dump-flag combination matters for diagnostics

When triaging stage2-style bugs, run with **multiple combinations
of `-ddump-rn`, `-ddump-tc`, `-ddump-parsed`, `-fforce-recomp`,
`-O0`, `-dverbose-core2core`**.  Different flags exercise
different evaluation orders and force different thunks early; if
results vary across the matrix, you've got either non-determinism
or memory corruption.

## install.sh and the bindist don't (yet) ship the stage2 wrapper

The bindist tarball still ships only stage1 + cross-scripts.
Stage2 is a separate, optional follow-up step:
`scripts/deploy-stage2.sh <tiger-ssh-host>`.  Users who want a
native ghc on their PowerMac clone the repo, run that one script,
done.  If we ever bundle stage2 into the main bindist, we should
also bundle `ghc-stage2-wrapper.sh` next to the binary.

## The lesson for next time

When a bug looks like "passes drop data structures", **check
whether GC is in the picture before assuming it's a pass-level
miscompile**.  Run with `+RTS -A1G -RTS` early.  If it goes away,
it's the RTS, not the compiler proper.

Probably-the-second-time-this-trick-works: an unfixed PPC RTS
issue is exactly the kind of thing 9.2.x inherits from the era
when PPC was unsupported.  GHC 8.6.5's RTS likely has the right
memory fence; diffing that against 9.2.8 is a productive next
step.
