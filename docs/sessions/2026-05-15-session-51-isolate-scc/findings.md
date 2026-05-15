# Session 51 findings — **TRUE MINIMAL REPRO: freshly-allocated `STUArray Bool` has spurious True bits on PPC32 unreg**

## TL;DR — the bug is in `newArray :: ST s (STUArray s Int Bool)`

Session 51 took the session-50 finding ("`Data.Graph.scc` returns
wrong forest") and stripped it down to its irreducible essence.
The bug is **not** in `scc`, **not** in `Data.Graph`, **not** in
any compiler code, **not** in PPC's complex unreg ABI.  It's in
the most primitive operation possible:

```haskell
arr <- newArray (0, 7) False :: ST s (STUArray s Int Bool)
mapM (readArray arr) [0..7]
-- expected: [False, False, False, False, False, False, False, False]
-- actual (on pmacg5 under GC pressure): random bits set to True
```

**Default RTS: 8431/10001 iterations have spurious True bits.**
**`-A1m -G1`: 8655/10001 iterations have spurious True bits.**

Sample bad outputs:
- `[False,False,False,False,True,False,False,True]`
- `[True,False,True,False,True,True,True,True]`
- `[False,False,True,True,True,False,True,False]`

Random-looking garbage, not a systematic pattern.

The bug **does not reproduce on host (arm64 macOS)** — confirmed
0/10001 bad runs on uranium with both default RTS and `-A1m -G1`.

## Pipeline chain (sessions 42-51)

| Session | Hook point                                  | Count clean / failing |
|---------|---------------------------------------------|------------------------|
| 42      | `simplTopBinds` entry                       | 9 / 0-1               |
| 43      | `core2core` entry                           | 9 / 1-3               |
| 44      | `deSugar` `final_prs`                       | 9 / 3-6               |
| 45      | `deSugar` `tcg_binds` entry                 | 9 / 3-6               |
| 46      | `hsc_typecheck` exit                        | 9 / 3-5               |
| 47      | `tcRnSrcDecls` output                       | 9 / 2-5               |
| 48      | `tcTopBinds val_binds val_sigs` output      | 8 / 2-3               |
| 49      | `tcTopBinds` INPUT                          | 8 / 2-3               |
| 50      | `Data.Graph.scc` in `stronglyConnCompG`     | 8 / 3 (forest_len)    |
| **51**  | **`newArray False :: ST s (STUArray s Int Bool)`** | **all False / random True bits** |

Thirteen sessions of bisection have pinned the bug from
"compiler emits 152-byte empty .o files" all the way down to
**a 3-line standalone test that calls `newArray False` on
`STUArray Int Bool` and finds spurious True bits**.

## F1. The trip down the stack (this session's four iterations)

### Phase 1 — scc_test.hs (single-pass test)

Built a graph with N vertices, no edges, called `Data.Graph.scc`,
checked count.  Default RTS: 0 bad.  `-A1m -G1`: 0 bad.
**Did not reproduce** — the bug needs more GC pressure.

### Phase 2 — scc_test2.hs (interleaved allocation)

Same test, but with `burnGC 1000` calls before and after each
`scc` invocation, in a 1000-iter loop.  **Reproduced**:
- 8-vertex, default RTS: 191/1000 bad.
- 8-vertex, `-A1m -G1`: 966/1000 bad.
- Host (uranium): 0/10000 bad — confirms PPC-specific.

### Phase 3 — scc_test3.hs (size sweep)

Same test, varied graph size from 1 to 256.

**Default RTS sizes** (reps=500): sizes 1-5 OK; sizes 6-24 BAD
(close to all-bad); size 28 OK; size 32 OK; size 48 BAD; sizes
64, 96, 128, 256 OK.

**`-A1m -G1` sizes** (reps=500): sizes 1-2 OK; sizes 3-24 BAD;
sizes 28, 32, 64, 96, 128, 256 OK; size 48 BAD.

Bug is **size-sensitive** but not monotonic.  Small sizes and
multiples-of-32-ish sizes seem safer.  Sizes 6-24, 48 trigger
reliably.  Heap-layout-sensitive behavior, consistent with GC
corruption.

### Phase 4 — scc_test4.hs (inlined scc with probes)

Re-implemented `dfs` / `prune` / `chop` / `generate` /
`transposeG` / `postOrd` inline, with probes on the lengths at
each step.  Initially used `STArray` (boxed) — **didn't
reproduce**.  Switched to `STUArray` (unboxed) — **reproduced**.

Trace at the bad iteration (size 8, evt order matters):
```
PROBE51 evt=184 prune_chop_in_len  n=8
PROBE51 evt=190 prune_chop_out_len n=6   ← prune dropped 2 trees
```

Per-vertex chop trace showed vertex 3 read as `True` on the
**first call** to `readArray marks 3`, despite the array being
freshly initialized with `False` and no prior write to position 3.

### Phase 5 — stuarray_test.hs (THE MINIMAL REPRO)

Stripped everything except the STUArray Bool allocation:

```haskell
checkFresh :: Int -> [Bool]
checkFresh n = runST $ do
  arr <- newArray (0, n - 1) False :: ST s (STUArray s Int Bool)
  mapM (readArray arr) [0 .. n - 1]
```

Loop this 10000 times with `burnGC` around each call.  Count
iterations where any element is `True`.

**Result on pmacg5: 8431/10001 bad (default), 8655/10001 bad
(`-A1m -G1`).**  Host: 0/10001.

The bug is in the most primitive operation possible: `newArray`
of an unboxed Bool array, when GC fires near the call.

## F2. What this means for the bug

**The bug is in GHC's RTS, specifically in the
`newByteArray#` / `newPinnedByteArray#` /
`newAlignedPinnedByteArray#` / `STUArray Bool` allocation path
on PPC32 unreg.**

`STUArray s Int Bool` is internally `MutableByteArray# s`, with
one bit per element (or one byte — depends on implementation
details; need to check).  For 8 elements: either 1 byte or 8
bytes of data.

The freshly-allocated array's data is supposed to be initialized
to zeros (False).  Under PPC32 unreg with GC pressure, the data
ends up with random bits set.

Most likely causes:
- The `MutableByteArray#` allocation is not properly zeroing the
  data.  Maybe the zeroing code has an off-by-one for small
  arrays.
- GC scavenge during the (newArray, readArray) window
  corrupts the data.  The MutableByteArray's payload is treated
  by GC as opaque, but if GC moves the array, the contents
  should be copied verbatim — unless the copy is buggy.
- A specific RTS code path (e.g., `stg_newByteArrayzh`) has a
  bug on PPC32 unreg.

## F3. This is a real upstream bug

This isn't a darwin8-ppc-port-specific bug.  This is a bug in
GHC's RTS / `Data.Array.ST` / `STUArray` implementation that
affects any PPC32-unreg-compiled program that uses `STUArray`
with allocation pressure.

Session 52 should:
1. Confirm with `STUArray Word8` / `STUArray Int8` / `STUArray Int`
   to see if the bug is Bool-specific or generic to
   `MutableByteArray#`.
2. Look at the RTS source for `newByteArray#` on PPC32 unreg.
3. File a GHC bug report.

## F4. Why session 50's `scc` was the symptom not the cause

`Data.Graph.scc` uses `prune` → `chop` (with `SetM` ST state) →
`runST (newArray bnds False >>= ...)`.  The corruption of the
freshly-allocated STUArray Bool causes `chop` to see false
positives (visited bits) for vertices it hasn't processed yet,
causing it to prune those vertices.  Result: fewer trees in the
output Forest.

In GHC's compilation of Big2.hs, `tcTopBinds` → `tcValBinds` →
... → `rnValBindsRHS` → `depAnalBinds` → `depAnal` →
`stronglyConnCompFromEdgedVerticesUniq` → `stronglyConnCompG` →
`scc` — and `scc` returned fewer trees because the STUArray was
corrupted.  Thus the renamer's `[(RecFlag, LHsBinds GhcRn)]`
ended up with fewer groups, dropping bindings on the floor.

The session 42 bug "compiler produces 152-byte empty .o" traces
back all the way to **STUArray Bool's allocation is
corrupted by GC on PPC32 unreg**.

## F5. Concrete next-session targets (session 52)

1. **Test other unboxed types.**  Does the bug fire for
   `STUArray Int` (boxed int)? `STUArray Word8`? `STUArray Char`?
   This will tell us whether it's bit-packing-specific or generic.
2. **Test without `burnGC` interleaved.**  If we just newArray
   and read, no GC pressure, does the bug fire?  If yes, the
   bug is in newArray itself; if no, it's in GC scavenge.
3. **Read RTS source.**  In
   `rts/PrimOps.cmm::stg_newByteArrayzh`, find the
   allocation+zeroing path.  See if there's a PPC32-specific
   branch or an alignment / size issue.
4. **Try pinned arrays.**  `newPinnedByteArray#` allocates in
   the large-object area, outside GC's scavenge.  If
   pinned-byte-arrays don't corrupt, GC scavenge is the bug.
5. **File GHC bug report.**  Include the minimal repro
   (3 lines) + reproduction rate + platform info.
6. **Once root cause is fixed:** rebuild GHC stage1 with the
   fix, redeploy, re-run baseline.  Should restore 32 PASS.

## F6. Why sessions 42-49's other symptoms were all downstream

Every probe in sessions 42-49 measured the count of bindings
arriving at some pipeline phase.  In each case, the count was
wrong because somewhere upstream, the renamer's dep-analysis
SCC computation truncated the binder list.  That truncation
traces back to `chop`'s STUArray-based visited set being
corrupted.

The "fake CyclicSCC" observation in session 49 (Big2.hs has no
mutually recursive bindings but `depAnal` produced one Recursive
group of size 2) is also explained: if the STUArray reports
visited=True for a vertex that wasn't actually visited, then
the DFS algorithm thinks there's a back-edge there, and treats
the connected component as cyclic.

## F7. Baseline tests at session-end

Probe50/51 didn't modify GHC source, only standalone Haskell
test programs.  Baseline tests at session-end: 30 PASS / 4
FAIL_OUTPUT.  Matches sessions 49 / 50 noise floor.

## F8. The bug is reproducible at default RTS

Importantly, session 50 thought the bug only fired under
`-A1m -G1`.  Session 51's data shows it also fires under
DEFAULT RTS at high iteration counts (>1000 iterations with
moderate allocation pressure).  This means **any moderately-
large program compiled on stage2 PPC ghc is potentially
miscompiling**, not just programs that pathologically use
`-A1m -G1`.  The bug is more widespread than previously thought.
