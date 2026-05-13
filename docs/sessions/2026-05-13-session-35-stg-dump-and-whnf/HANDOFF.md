# Handoff from session 35 → session 36

**For:** the next claude session.
**From:** session 35 (STG dump + probe35 + the probe-was-the-artifact
revelation; CLEAN exit).
**Recommended pickup:** redesign the probe to read v's actual
closure header (not the wrapping-thunk's), then rerun the WHNF
verification.

## ✅ SESSION CLEAN EXIT

Source tree clean (probe35 reverted; the OPTIONS_GHC dump-stg
pragmas on AArch64/CodeGen.hs and Simplify/Env.hs both reverted).
Stage1 + stage2 rebuilt clean and redeployed to pmacg5.  v0.12.0
release unchanged.

## TL;DR — the major finding to carry forward

**Sessions 33, 34, and 35 have all been reading the wrong memory.**
The probe pattern `aToWordzh (unsafeCoerce v :: Any)` does NOT
return v's heap address.  Instead, GHC compiles `unsafeCoerce v
:: Any` as a let-bound THUNK that captures v, and `aToWordzh` is
called on that THUNK.  The returned address is the wrapping thunk's
heap address, whose info-pointer is a `_sNNN_info` THUNK_1_0 symbol
from whatever module the probe code lives in (Simplify/Env.o in
sessions 33 and 35; coincidentally collided with an AArch64.CodeGen
`_s71L_info` symbol in session 33's binary due to static-info-table
layout in `__DATA,__const`).

Concretely, session 35's STG dump on Env.hs (with probe35 applied)
shows:

```
sat_s7iu{v} :: Any Type
[LclId] =
    CCCS {(v{v s7ip} :: Var)} \u []
        unsafeCoerce (v{v s7ip})

case __primcall ghc aToWordzh [(sat_s7iu{v} ...)] of ...
```

`aToWordzh` is called on `sat_s7iu` (the wrapping thunk), not v.

**Session 34's "v's heap address contains AArch64.CodeGen's
ncgPlatform-config thunk" finding is dissolved.**  We never saw
v's real closure type.  The "deepening puzzle" of how an AArch64
codegen thunk shows up under PPC compilation is also dissolved —
it didn't.

### What we DID learn from sessions 33-35

1.  **The bug consistently fires at three discrete env-len zones**
    (around 600-700, 850-900, 1650-1700 in the probe35 binary).
2.  **Each REFINE-panic captures a missing TYPECLASS DICTIONARY
    variable** (`$dNum_a1kb`, `$dNum_a1ko`, `$dOrd_a1k0`).  This
    narrows the bug: it's about typeclass-dictionary Ids being
    "lost" between binding-site and use-site in the simplifier's
    substitution/in-scope machinery.
3.  **`s71L` (session 33's captured wrapping-thunk info pointer)**
    happens to be **`compiler/GHC/CmmToAsm/AArch64/CodeGen.hs:406`'s
    `ncgPlatform config1` thunk** in the v2 binary — but this is
    irrelevant to the actual bug.

## Read in order

1. **This file.**
2. [`README.md`](README.md) — session plan + arrival/exit state +
   table of capture results.
3. [`findings.md`](findings.md) — the wrapping-thunk reveal in
   detail; the four theories revised.
4. [`log.md`](log.md) — real-time work log.
5. (Reference) Session 34 [`HANDOFF.md`](../2026-05-13-session-34-s71L-identification/HANDOFF.md)
   — what session 35 picked up.  **Note:** session 34's
   "AArch64.CodeGen ncgPlatform-config thunk" identification is
   superseded by session 35's wrapping-thunk reveal.
6. (Reference) Session 33 [`HANDOFF.md`](../2026-05-13-session-33-closure-shape-probe/HANDOFF.md)
   — original probe design.  **Note:** same artifact issue applies.

## What to try next, in priority order

### Top: redesign the probe to read v's actual closure header

The wrapping-thunk artifact comes from `aToWordzh (unsafeCoerce v
:: Any)`.  Avoiding it requires one of:

**Option A — Inline `aToWordzh` at the call site via Cmm shim.**
Write a small `.cmm` file in `compiler/GHC/Utils/Probe.cmm` (or
inline in `HeapPrim.cmm`) that defines:

```
probeReadClosureHeaderzh ( P_ clos )
{
    W_ result;
    result = clos;
    return (result);
}
```

Then `foreign import prim "probeReadClosureHeaderzh"
probe :: Var -> Word#`.  The argument type `Var` (not `Any`) might
mean GHC doesn't need to allocate a wrapping `unsafeCoerce` thunk
— the caller has v as Var already.  Test in a tiny stand-alone
GHC program first.

**Option B — Use `GHC.Exts.unpackClosure#` directly.**  GHC has a
primop `unpackClosure# :: a -> (# Addr#, ByteArray#, Array# b #)`
that returns the info-table address as an `Addr#`.  See
`libraries/ghc-heap/GHC/Exts/Heap.hs`.  This avoids `unsafeCoerce`
entirely.  In the probe, do:

```haskell
import GHC.Exts (unpackClosure#)
import GHC.Word (Word(..))
probeHeader :: a -> Word
probeHeader x = case unpackClosure# x of
                  (# info_addr#, _, _ #) -> W# (int2Word# (addr2Int# info_addr#))
```

This should give the info-table address WITHOUT going through a
wrapping thunk.  (Caveat: `unpackClosure#` might itself force x to
WHNF.  Read `unpackClosure#` semantics in
`compiler/GHC/Builtin/primops.txt.pp` to be sure.)

**Option C — Inline the probe via `{-# INLINE #-}` and explicit
`addrToAny#` machinery.**  Could work, but fragile across simplifier
versions.

**Option D — Use a CallStack or HasCallStack inspection of v at the
moment it enters `refineFromInScope`, captured via
`Debug.Trace.traceShow`.**  Requires v to have a `Show` instance, or
something Show-like.  Var has a `Outputable` instance (`ppr`).
`pprPanic` already shows v's `ppr` output — see the panic message
for the missing variable name.  This gives us v's user-level
identity but not its heap-level closure shape.

### Second: re-run the WHNF question once the probe is reliable

With a reliable probe, re-run the sweep and check:
- Is v's actual info-pointer a THUNK or an Id constructor?
- If THUNK: does `seq v` change it to an indirection?
- If indirection after seq: theory 1 — `isLocalId v` doesn't force.
- If still THUNK after seq: deeper PPC unreg eval bug.
- If Id constructor before seq: v IS in WHNF; bug is in
  in_scope/lookupInScope tracking, not WHNF.

### Third: investigate `lookupInScope` directly

If v IS in WHNF at the panic site (no thunk issue), then the bug
is in `lookupInScope`/`InScopeSet`.  All 3 missing variables are
typeclass dictionaries.  Possible mechanisms:
- Dictionaries get floated out of let-bindings but the in-scope
  set isn't updated.
- The simplifier's `extendInScope` for dictionaries has a bug
  specific to PPC's calling convention.
- Specialiser passes generate Ids that aren't added to the
  in-scope set.

Use a different probe: at the call site of `extendInScope` for
dictionary Ids, log the binding-site Var + Unique.  Compare with
the missing Var at the panic site.

### Fourth: investigate the dictionary lifecycle

The missing variables share a structural pattern: `$dNum`,
`$dOrd` — these are GHC's compiler-generated dictionary Ids for
typeclass instance lookup.  Check:
- Where are these dictionaries first introduced (binding site)?
- Where are they normally looked up (use site)?
- What does the simplifier do between binding and lookup that might
  drop them from the in-scope set?

This is a Core-level investigation; doesn't need PPC runtime.

## Mechanics — picking up where session 35 left off

```bash
cd /Users/cell/claude/ghc-darwin8-ppc

# Source tree is clean.  Stage2 on pmacg5 is the clean v0.12.0+
# rebuild from end of session 35.

# Option A — build a stand-alone test of unpackClosure# to verify it
# returns the right address before integrating into the panic probe:
cat > /tmp/probe_test.hs <<'EOF'
{-# LANGUAGE MagicHash, UnboxedTuples #-}
module Main where
import GHC.Exts (unpackClosure#)
import GHC.Word (Word(..))
import GHC.Int  (Int(..))
import GHC.Prim (addr2Int#)

data Foo = Foo !Int
{-# NOINLINE foo #-}
foo :: Foo
foo = Foo 42

main :: IO ()
main = do
  let !x = foo
  case unpackClosure# x of
    (# info_addr#, _, _ #) -> do
      let !i = I# (addr2Int# info_addr#)
      putStrLn $ "x info-ptr = 0x" ++ showHex (fromIntegral i :: Word) ""
  where showHex w s = if w == 0 then s else showHex (w `div` 16) (digit (w `mod` 16) : s)
        digit n = "0123456789abcdef" !! fromIntegral n
EOF
# Compile on uranium with host GHC, then with cross-stage1, then run
# on pmacg5.  Compare the captured info-ptr against `nm` lookup of
# the expected symbol.  If unpackClosure# returns the right thing,
# proceed to integrate into the refineFromInScope probe.

# Option B — write a Cmm shim (more invasive, requires hadrian
# rebuild of base/ghc-prim).

# Once probe is reliable, re-do the sweep:
cd external/ghc-modern/ghc-9.2.8
# Apply the redesigned probe to compiler/GHC/Core/Opt/Simplify/Env.hs.
source ../../../scripts/cross-env.sh > /dev/null
./hadrian/build --flavour=quick-cross -j8 \
    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/libHSghc-9.2.8.a
cd ../../..
bash scripts/deploy-stage2.sh pmacg5
# Sweep env-len 600..2000 with the same Big2.hs trigger as session 35.
```

## What NOT to redo

- **Don't trust `aToWordzh (unsafeCoerce v :: Any)`** as a probe
  for v's heap address.  It returns the wrapping thunk's address.
- **Don't redo the env-var bisect / address probe** — sessions 32
  + 33 ruled those framings out.
- **Don't redo the cross-run address diff** — session 31 ruled out.
- **Don't redo the AArch64.CodeGen STG-dump identification** —
  session 35 confirmed s71L = AArch64/CodeGen.hs:406, but this is
  moot now (the wrapping-thunk reveal makes it irrelevant to the
  actual bug).
- **Don't conclude theory 3 (GC walker bug) without first ruling
  out the wrapping-thunk artifact** — sessions 33-35's evidence
  for theory 3 was based on misreads.

## Hosts (unchanged)

- **uranium** (this Mac): cross-build, source edits.
- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.
  - `/opt/ghc-stage2/bin/ghc-real` — **clean v0.12.0+ rebuild**
    (session-end-35 rebuild).
  - `/opt/ghc-stage2/bin/ghc-real-debug` — debug-RTS-linked,
    kept from session 30.  Unchanged.
- **imacg3**: not used.
- **indium**: don't use for clang/hadrian builds.

## Time estimate for session 36

- Setup + read handoff: 10-20 min.
- Stand-alone test of `unpackClosure#` to verify reliability: ~30 min
  (one host-ghc compile + one cross-ghc compile + one pmacg5 run).
- Integrate redesigned probe into Env.hs + build + deploy + sweep:
  ~30 min build + 5-10 min sweep + analysis.
- If probe reveals v is in WHNF at panic site: pivot to investigating
  lookupInScope and the typeclass-dictionary lifecycle.  Estimate:
  another 2-4 hours.
- If probe reveals v is a thunk: investigate PPC unreg's pattern-
  match codegen.  Estimate: 4-8 hours.

Total realistic: 1 medium session (4-6 h) to definitively pin
down whether the bug is in WHNF forcing vs in-scope tracking.

## Paste-into-fresh-session prompt

```
Context: session 35 of the GHC darwin8-ppc project rebuilt
AArch64/CodeGen.hs with -ddump-stg-final to identify s71L's source
line, then built a new probe (probe35) to verify WHNF status at
refineFromInScope's panic site.  The probe captured 6 REFINE
samples in 3 distinct zones — but a follow-up -ddump-stg-final on
Env.hs (with probe applied) revealed:

**The probe has been reading the wrong memory the entire time
(sessions 33, 34, AND 35).**  `aToWordzh (unsafeCoerce v :: Any)`
is compiled such that `aToWordzh` is called on the wrapping THUNK
that holds `unsafeCoerce v`, not on v itself.  All info-pointers
captured by probes 33-v1, 33-v2, and 35 have been the info-tables
of the wrapping thunks, not v's actual closure header.  Session 34's
"AArch64.CodeGen ncgPlatform-config thunk" identification was a
structural coincidence — both `_s71L_info` (session 33's binary)
and `_s7iu_info`/`_s7iW_info` (session 35's binary) are THUNK_1_0
symbols in __DATA,__const that the linker happens to place near
each other.

What WAS learned: the bug fires at 3 discrete env-len zones, each
missing a TYPECLASS DICTIONARY variable ($dNum_a1kb, $dNum_a1ko,
$dOrd_a1k0).  Two of these are Num dicts, one is an Ord dict.

Session 35 ended CLEAN: probes reverted, stage1 rebuilt, stage2
redeployed to pmacg5 + smoke-test PASS.

Read in order:
1. docs/sessions/2026-05-13-session-35-stg-dump-and-whnf/HANDOFF.md
2. docs/sessions/2026-05-13-session-35-stg-dump-and-whnf/README.md
3. docs/sessions/2026-05-13-session-35-stg-dump-and-whnf/findings.md
4. docs/sessions/2026-05-13-session-35-stg-dump-and-whnf/log.md
5. (reference, NOW PARTIALLY SUPERSEDED) docs/sessions/2026-05-13-session-34-s71L-identification/HANDOFF.md
6. (reference, NOW PARTIALLY SUPERSEDED) docs/sessions/2026-05-13-session-33-closure-shape-probe/HANDOFF.md

Top priority: redesign the probe to read v's ACTUAL closure header.
Best option: use GHC.Exts.unpackClosure# directly (no unsafeCoerce
wrapping), verify in a stand-alone test program first, then
integrate into refineFromInScope.

Second priority: once probe is reliable, re-run the sweep and
determine: is v a thunk at the panic site (theory 1 — pattern-match
doesn't force), or in WHNF (bug is in lookupInScope/InScope
tracking)?

Third priority: investigate the typeclass-dictionary lifecycle —
$dNum and $dOrd dicts are consistently the missing variables.

Don't trust the aToWordzh/unsafeCoerce probe.  Don't redo the
session-32 env-var bisect or session-31 cross-run address diff.

Hosts: uranium for builds, pmacg5 for runs.  Don't use indium.
v0.12.0 stays shipped.

Unsupervised mode is project default.
```

## Memory aide for the next-you: session-end HANDOFF path

This handoff lives at:
[`docs/sessions/2026-05-13-session-35-stg-dump-and-whnf/HANDOFF.md`](docs/sessions/2026-05-13-session-35-stg-dump-and-whnf/HANDOFF.md).

When session 36 ends, write the next handoff at:
`docs/sessions/<DATE>-session-36-<slug>/HANDOFF.md`.
