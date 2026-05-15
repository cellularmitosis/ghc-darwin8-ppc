# Session 53 findings — v0.13.0 release

## F1. The upstream GHC bug is still live in HEAD

Fetched current `libraries/array/Data/Array/Base.hs` from
`gitlab.haskell.org/ghc/packages/array` master branch.  The `MArray
(STUArray s) Bool (ST s)` instance (lines 1235-1250) is **byte-identical**
to the buggy code session 52 patched.  Specifically:

```haskell
newArray (l,u) initialValue = ST $ \s1# ->
    case safeRangeSize (l,u)                   of { n@(I# n#) ->
    case bOOL_SCALE n#                         of { nbytes# ->     -- ceil(n/8) BYTES
    case newByteArray# nbytes# s1#             of { (# s2#, marr# #) ->
    case setByteArray# marr# 0# nbytes# e# s2# of { s3# ->          -- zeroes nbytes BYTES
    (# s3#, STUArray l u n marr# #) }}}}
...
unsafeRead (STUArray _ _ _ marr#) (I# i#) = ST $ \s1# ->
    case readWordArray# marr# (bOOL_INDEX i#) s1# of { (# s2#, e# #) ->  -- reads SIZEOF_HSWORD BYTES
    ...
```

This is an active upstream issue.  Patch 0016 is appropriate for
submission to GHC HEAD; see roadmap §H.

## F2. The bash 3.2 empty-array issue in `tests/cabal-examples/run-one.sh`

macOS still ships bash 3.2 as `/bin/bash`.  Under `set -u`, expanding
an empty array via `"${arr[@]}"` triggers `unbound variable`:

```
$ /bin/bash -c 'set -euo pipefail; A=(); echo "${A[@]}"'
bash: A[@]: unbound variable
```

The workaround is `${arr[@]+"${arr[@]}"}` — expands to nothing when
the array is unset/empty, expands to the array contents otherwise.
Applied to `run-one.sh`; verified the failing path now works.

This is also why our own scripts (`tests/run-tests.sh`,
`scripts/deploy-stage2.sh`) use `set -uo pipefail` *without* `-e` —
some of them want to keep going past array expansions and other
ergonomic bash bits that 3.2 trips over.

## F3. Hadrian's `binary-dist-dir` rebuild touches downstream libraries

After session 52's `array-0.5.4.0/libHSarray-0.5.4.0.a` rebuild,
running `./hadrian/build --flavour=quick-cross --docs=none
binary-dist-dir` did NOT just package up the existing artifacts —
it rebuilt the profiling-way (`.p_o`) files of array's downstream
dependents (text, parsec, etc.).  Even though those packages don't
import `Data.Array.Base` directly, hadrian's dependency tracking
flags them because *some* path in the dependency graph touched a
file that changed.

Total bindist rebuild time on uranium: ~TODO min (vs 3-5 min for
just packaging — the rebuild cost is the extra .p_o files).

## F4. Cabal-examples sanity check

Sanity-checked `tests/cabal-examples/random` end-to-end via the
patched `run-one.sh`:

```
== Building random ==
Preprocessing executable 'random-example' for random-example-0.1...
Building executable 'random-example' for random-example-0.1...
Linking ./dist/build/.../random-example ...
== Running .../random-example on pmacg5 ==
random int 1..100 with seed 42: 49
```

The full cabal-examples sweep is deferred to session 54 — only
`random` was sanity-checked.  Most cabal-examples don't exercise
`STUArray Bool` so they're unaffected by the patch; the question
re-running them would answer is whether the EXTRA_FLAGS fix is
sufficient (looks like yes), and whether anything in the patch
inadvertently broke a previously-working build (none observed for
`random`).

## F5. Demo choice rationale

The v0.13.0 demo program is `Big2.hs` — the 30-LOC reproducer that
session 27 first found produced the deterministic "swap not in
scope" panic and 152-byte empty `.o` files, and that has been the
reference test case for sessions 27 through 52.  It:

- Uses `Data.Map.Strict`, `Data.List`, `Data.Maybe` — exercises real
  library code.
- Has 8 top-level definitions of varying complexity (point-free
  composition, where-bound helpers, lambdas).
- Compiles cleanly on host GHC (no type errors).
- Pre-fix: stage2 produces a 152-byte empty `.o` 100% of the time
  with default RTS and `-A1m -G1`.
- Post-fix: stage2 produces a 46340-byte fully-populated `.o`
  100% of the time with default RTS and `-A1m -G1`.

The demo script (`demos/v0.13.0-bool-bug-fix.sh`) writes Big2.hs to
Tiger, runs `ghc -c` 5× to show deterministic success, then
`--make`s an executable that calls Big2's functions and prints
their results — verifying that what comes out of stage2 is not just
non-empty but *functionally correct*.
