# Stage2 GC bug — found and worked around

**Date:** 2026-04-30 evening
**Status:** ✅ workaround deployed; root cause not yet fixed.
**Headline:** the stage2 native ghc binding-loss bug is a **PPC-Darwin
RTS GC bug**.  Suppressing GC (`+RTS -A1G -RTS`) makes stage2 work
end-to-end.

## Bisection that found it

After ruling out:
- Optimiser passes (session 14's `simpleOptPgm` hypothesis).
- LLVM-7 PPC backend (this session — rebuilt without `-fllvm`, same bug).
- User-level Bag/UniqSupply/atomic primitives (probes all PASS).

I tried `+RTS -A256m -RTS` to suppress GC.  **Stage2 worked
correctly.**

## Threshold table

Compile `M5.hs` (`five = 5::Int; six = 6::Int`) with various `-A`
sizes, count user binding closures in the resulting `M5.o`:

| `+RTS -A…` | symbols in `M5.o`        | observation |
|-----------|--------------------------|-------------|
| default   | 0 (152-byte empty `.o`)  | broken      |
| `-A8m`    | 0                        | broken      |
| `-A16m`   | 0                        | broken (panic) |
| `-A32m`   | 0                        | broken      |
| `-A64m`   | 0                        | broken      |
| `-A128m`  | 3 (`five`, `six`, `$trModule`) | works for tiny modules |
| `-A256m`  | 3                        | works for tiny modules |
| `-A1G`    | 3                        | recommended default |

For larger inputs (e.g. `Plus.hs` importing `Data.List`,
`Data.Char`, `Data.Map.Strict`), `-A256m` is too small and the
bug returns.  `-A1G` is enough for the common cases tested
(simple `Hello.hs`, multi-module `--make`, `Data.Map`-using
programs).

## Stage2 with wrapper: working test cases

All run on pmacg5 (PowerMac G5, Tiger 10.4) via
`/opt/ghc-stage2/bin/ghc` (the wrapper, which appends
`+RTS -A1G -RTS`):

- `M5.hs` (2 bindings, no sigs): `M5.o` has both closures ✅
- `M8.hs` (10 bindings): all 10 closures ✅
- `Hello.hs` → `hello` binary, prints expected line ✅
- `Plus.hs` (imports `Data.List`, `Data.Char`,
  `Data.Map.Strict`): compiles + runs, prints word-count map ✅
- `--make A.hs B.hs Main.hs` (3-module compile + link): runs ✅

## Bug shape

The bug fires **after the first major GC**.  Stage2 ghc allocates
fast (~40 MB/s heap usage during a small compile); with the
default `-A1m` allocation area, GC fires within milliseconds, and
the renamer/typechecker's `Bag` of bindings comes back partially
empty.

Symptom catalogue — see
[`stage2-non-determinism-finding.md`](stage2-non-determinism-finding.md)
for the panic call-stacks (`refineFromInScope`,
`GHC.StgToCmm.Env: variable not found`,
`depSortStgBinds Found cyclic SCC`, `'main' is not in scope
during type checking, but it passed the renamer`).  All trace
back to the same root: data structures losing entries between
allocation and the next read.

## What this means for the project

- v0.11.0 ships **working stage2 native ghc** on Tiger.
- The wrapper (`scripts/ghc-stage2-wrapper.sh`) is the canonical
  launcher.  It's installed by `scripts/deploy-stage2.sh`.
- Users with PowerMacs that have less than ~2 GB free RAM may
  need to lower `-A` (e.g. `GHCRTS=-A256m`).
- The actual GC bug needs to be fixed in a future session.  At
  that point we can ship without the workaround.

## What to investigate when fixing the GC bug

1. Run stage2 with `+RTS -DC -RTS` (debug RTS, sanity-check GC)
   on a Tiger box.  See if it reports any inconsistencies during
   the failing compile.
2. Compare PPC-specific GC paths between 9.2.8's `rts/sm/` and
   8.6.5's (the last GHC version that officially supported PPC).
   8.6.5 had a working RTS for PPC; diff what changed and look
   for missed PPC-specific bits.
3. Check whether PPC's weak-memory-model write ordering needs
   barriers we're missing.  GHC 9.x added more atomics-aware
   code; PPC needs `lwsync`/`sync` in the right places.  The
   non-SMP build still uses some atomic ops via the C atomic
   builtins, and at least some of those compile to bare loads
   without barriers on PPC32.
4. Look for any CAF-table or `large_alloc_lim`-related
   recent change that might have a 32-bit overflow.

## Workaround code

`scripts/ghc-stage2-wrapper.sh`:

```bash
#!/bin/bash
GHC_REAL="$(dirname "$0")/ghc-real"
exec "$GHC_REAL" "$@" +RTS -A1G -RTS
```

That's it.  Two lines of bash buy us a working native ghc on
Tiger after a 5-month investigation.
