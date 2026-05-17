# T16525a SIGSEGV bisection

Bisecting the T16525a SIGSEGV (rc=139) on pmacg5 with stage2
ghc-real (v0.15.0).  Test produces the correct expected output
(`["a;lskdfa;lszkfsd;alkfjas"]`) then crashes during `performGC`.

Setup on remote: `/tmp/T16525a-experiment/` with `A.hs`, `B.hs`
from upstream + custom `.script` per variant.  Runner:

```
DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
/opt/ghc-stage2/bin/ghc-real --interactive -v0 \
-ignore-dot-ghci -fno-ghci-history < <script>
```

## Variants tried

| # | Variant | Script body (after `:set -fobject-code` + `:load A` + `import Control.Concurrent`) | rc |
|---|---------|------|----|
| 1 | Upstream T16525a (verbatim) | `forkIO (delay 500ms >> print)` → `:l []` → `performGC` ×3 with 500ms delays | **139** |
| 2 | + explicit `:quit` at end | same as #1 + `:quit` | **139** |
| 3 | No `performGC` | `forkIO (delay 500ms >> print)` → `:l []` → `delay 1000ms` | 0 |
| 4 | `performGC` BEFORE thread fires | `forkIO (delay 500ms >> print)` → `:l []` → `performGC` (immediately, no wait) | 0 |
| 5 | Thread completes BEFORE `:l []` | `forkIO (delay 200ms >> print)` → `delay 500ms` → `:l []` → `performGC` | 0 |

## Conclusion

The crash needs all three:

1. `:l []` unloads object code.
2. A thread that ran (and printed) AFTER the unload, holding closures
   that reference symbols in the just-unloaded modules.
3. A `performGC` afterward, walking the heap and following the stale
   refs.

Variant #4 (performGC fires before the thread wakes) is clean — the
GC happens while the thread is still parked in `threadDelay`, so its
closure isn't yet executing the print that captures stale refs.
Variant #5 (thread completes before unload) is clean — the thread's
captured closures are GC-able normally, no dangling Cmm calls into
unloaded code.

This is a real PPC-port issue in the runtime linker's code-unload
path, not a test-driver artifact.  Specifically: GHC's `unload`
machinery (`rts/Linker.c` / `rts/LinkerInternals.h`) marks object
files as "unloaded" but the GC has to walk the heap and find any
closures still referring to that code, and remap or destroy them.
On x86_64 with a working RTS linker this either succeeds or the
threads are kept alive enough to keep refs live; on our PPC port,
the GC follows a pointer into freed/unmapped object code and dies.

## Why T16525b is clean despite the harder shape

T16525b (`replicateM_ 3 (b () >>= print >> delay 500ms)`) has a
thread that keeps calling INTO unloaded code while GCs happen.  We
observe **rc=0** there, contradicting the hypothesis that "live ref
to unloaded code" is what crashes.  Hypotheses for why T16525b
escapes:

- The continuously-executing thread holds the relevant closures in
  evac regs / stack slots, keeping them from being seen as orphan-but-
  scannable by `performGC`.
- T16525a's `_ <- forkIO ...` discards the ThreadId, while T16525b's
  same pattern produces a thread whose stack remains live longer.
- Coincidental scheduling on a single-CPU PPC G5 — T16525b's thread
  is mid-call when each `performGC` runs, T16525a's thread has just
  returned and its print buffer flush is what the GC trips on.

Worth more investigation, but the central observation is solid: the
runtime-linker unload + GC interaction is buggy on the v0.15.0 PPC
stage2 in at least one repeatable shape.

## Not blocking

Not a regression from any session; never previously exercised.
T16525a is one test; in upstream it's also flagged as historically
fragile (issue #16525 was filed BECAUSE this codepath had platform-
specific quirks on x86 too).  No release work needed; this is now a
documented PPC-port test failure to chase in a future session
focused on the runtime linker's unload path.
