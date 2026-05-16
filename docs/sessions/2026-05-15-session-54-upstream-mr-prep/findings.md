# Session 54 findings — the bug is already fixed upstream

## TL;DR

The `STUArray Bool` word-aligned-init bug is **already fixed upstream**,
and has been since May 2023.  Session 53's claim that "the broken
code is byte-identical in current GHC HEAD" was technically true of
the `MArray (STUArray s) Bool (ST s)` instance itself, but missed
that `bOOL_SCALE` — which the instance calls — was itself patched
to round its return value up to a whole-word byte count.  No upstream
MR work to do.

Concretely:

* Upstream commit
  [`9cc80b5`](https://gitlab.haskell.org/ghc/packages/array/-/commit/9cc80b51cf98c13a140b00effb38329e7210d03c)
  "Round up unboxed Bool arrays to whole-word sizes" by Matthew Craven,
  2023-05-04.
* Motivated by [ghc#23132](https://gitlab.haskell.org/ghc/ghc/-/issues/23132)
  (page is behind an Anubis bot wall; can't quote contents directly, but
  the commit + changelog reference is unambiguous).
* Changelog framing in array's `changelog.md`: "Unboxed Bool arrays no
  longer cause spurious alarms when used with `-fcheck-prim-bounds`."
  The original report appears to have been a bounds-check false-alarm
  on LE (which would catch the `readWordArray#` over-read), not the
  silent BE miscompile we hit.  Same root cause; same fix.

## What the upstream fix looks like

11 lines, touching only `bOOL_SCALE`:

```diff
 bOOL_SCALE, wORD_SCALE, dOUBLE_SCALE, fLOAT_SCALE :: Int# -> Int#
 bOOL_SCALE n# =
-    -- + 7 to handle case where n is not divisible by 8
-    (n# +# 7#) `uncheckedIShiftRA#` 3#
+    -- Round the number of bits up to the next whole-word-aligned number
+    -- of bytes to avoid ghc#23132; the addition can signed-overflow but
+    -- that's OK because it will not unsigned-overflow and the logical
+    -- right-shift brings us back in-bounds
+#if SIZEOF_HSWORD == 4
+    ((n# +# 31#) `uncheckedIShiftRL#` 5#) `uncheckedIShiftL#` 2#
+#elif SIZEOF_HSWORD == 8
+    ((n# +# 63#) `uncheckedIShiftRL#` 6#) `uncheckedIShiftL#` 3#
+#endif
```

Functionally identical to our `bOOL_WORD_SCALE`.  More elegant —
they changed the helper itself instead of replacing every call site.

## Why we missed it in session 53

Session 53's check fetched `Data/Array/Base.hs` from upstream's
master branch and noted that the `MArray (STUArray s) Bool (ST s)`
*instance code* (lines 1235-1264) is byte-identical to what we
patched.  That's true.  What the check missed is that the instance
calls `bOOL_SCALE n#` — and `bOOL_SCALE`'s definition (~ line 1557
in upstream HEAD) was the part that changed.  In 9.2.8 (array-0.5.4.0)
`bOOL_SCALE` is the ceil(n/8) byte count that drives the bug; in
0.5.6.0+ it's the whole-word-rounded byte count that fixes it.

Lesson: when checking "is this still broken upstream?", check
*every helper the broken site calls*, not just the buggy site.

## Which versions are affected

| array version | bOOL_SCALE returns | Status |
|---|---|---|
| 0.5.4.0 (GHC 9.2.x) | ceil(n/8) bytes | **buggy** |
| 0.5.5.0 (GHC 9.4.x, 9.6.0/9.6.1) | ceil(n/8) bytes | **buggy** |
| 0.5.6.0 (~ GHC 9.8.x, 9.6.2+ rebump) | whole-word bytes | fixed |
| 0.5.7.0 | whole-word bytes | fixed |
| 0.5.8.0 | whole-word bytes | fixed |

(Exact GHC → array mapping wasn't pinned down this session; the
table above is best-effort.)

GHC 9.2.x (our target) is past EOL and the array library inside it
will not be updated.  Our patch 0016 carries the fix into our 9.2.8
tree, which is exactly what we need.

## What we add to upstream's understanding (even though the fix is in)

Upstream's framing of the bug is "spurious `-fcheck-prim-bounds` alarms."
Our work in sessions 51-52 fleshes out the *actual* user-visible
consequences:

1. The bug is a **silent miscompile** on big-endian.  Every read of
   elements 0..(SIZEOF\_HSWORD\*8 - 1) of a sub-word `STUArray Bool`
   returns garbage instead of the initialiser value.  Not a bounds-
   check warning — actually wrong data.
2. The bug **also affects little-endian** for sizes not aligned to
   a word.  On 32-bit LE, `n=33` leaves bytes 5..7 of the second
   word uninitialised, so reads of elements 33..63 return garbage.
   Masked in practice by nursery zero-fill, but real.
3. Concrete downstream symptom: GHC's `Data.Graph.scc` uses an
   `STUArray Bool` for its visited set, gets garbage initial values
   on BE, and computes wrong SCC results.  The Haskell renamer's
   dep-analysis (`rnValBindsRHS`) uses scc and truncates its output;
   GHC stage2 on BE then drops most top-level bindings during
   typecheck and emits "empty" .o files (header + tiny tail, no body).
   This is the "stage2 emits empty .o" symptom that masked the root
   cause from us for ~10 sessions (42-51).

If we ever do open something upstream, it'd be a follow-up note on
ghc#23132 (or its own issue) saying "for the record, this was a
silent-miscompile on BE, not just a bounds-check warning."

## Implication for the project

* No upstream MR to prepare.  Roadmap §H closes ✅ as "already fixed
  upstream in 9cc80b5 / array-0.5.6.0; our patch 0016 is the equivalent
  backport into 9.2.8."
* Our patch 0016 is the correct backport.  We could rewrite it to
  match upstream's form (modify `bOOL_SCALE` rather than add
  `bOOL_WORD_SCALE`) — diff size halves, behaviour identical.
  Cosmetic; deferred unless we end up touching it for another reason.
* Session 53's session README and roadmap §H need amending to remove
  the "live upstream issue" claim.
