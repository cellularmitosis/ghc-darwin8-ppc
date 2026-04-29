# Session 16 — profiling enabled (v0.10.0) 📊

**Date:** 2026-04-29.
**Goal:** flip `libraryWays = [vanilla, profiling]` in `QuickCross`
once LLVM-7 r4 lands the BUG-003 fix, and ship a working `-prof`
binary that produces `.prof` cost-centre and `.hp` heap profiles
on Tiger.
**Outcome:** ✅ done.

```
$ tests/profiling/run.sh
[1/3] cross-compile with -prof + cost centres...
[2/3] ship to pmacg5...
[3/3] run with +RTS -p (time profiling) and -h (heap profiling)...
--- mandel.prof (first 30 lines) ---
        Wed Apr 29 15:21 2026 Time and Allocation Profiling Report  (Final)
        mandel +RTS -p -h -RTS

        total time  =        0.19 secs   (194 ticks @ 1000 us, 1 processor)
        total alloc =   4,980,432 bytes  (excludes profiling overheads)

COST CENTRE   MODULE                SRC                       %time %alloc
mandelIter.go Main                  Mandel.hs:(11,5)-(14,51)   96.4   95.1
CAF           GHC.IO.Encoding.Iconv <entire-module>             3.1    0.0
renderRow     Main                  Mandel.hs:(27,1)-(31,5)     0.0    3.5
…
```

A Mandelbrot-set printer compiled with `-O -prof -fprof-auto`,
running natively on a PowerMac G5 / Tiger 10.4.11, produces a
real cost-centre report and a real heap-profile file.

## What had to happen

Three things, in order:

### 1. Pull the LLVM-7 r4 cross-clang

The
[sister project](https://github.com/cellularmitosis/llvm-darwin8-ppc)
shipped `v7.1.1-r4` after we filed the bug.  The actual LLVM source
fix matches *both* `PPC::R0` and `PPC::ZERO` and emits `r0`
literally — see
[`docs/bug-reports/ppc-displacement-form-rA0-asmprinter.md`](https://github.com/cellularmitosis/llvm-darwin8-ppc/blob/main/docs/bug-reports/ppc-displacement-form-rA0-asmprinter.md)
for why ZERO-not-R0 was the actual operand.

```
rsync -av indium:tmp/claude/llvm-7-darwin-ppc/build-phase0/bin/clang-7 \
    ~/.local/ghc-ppc-xtools/clang-7
```

(`clang` and `clang++` symlinks already point at `clang-7`.)

Verify:
```
$ cat > /tmp/repro.c <<EOF
extern int read_abs(void);
int read_abs(void) { return *(volatile int *)0x40; }
EOF
$ ~/.local/ghc-ppc-xtools/clang -target powerpc-apple-darwin8 -isysroot $SDK -O2 -S /tmp/repro.c -o /tmp/r.s
$ grep lwz /tmp/r.s
        lwz r3, 64(r0)        ← was `lwz r3, 64(0)` pre-r4
$ ~/.local/ghc-ppc-xtools/clang -target powerpc-apple-darwin8 -isysroot $SDK -c /tmp/r.s -o /tmp/r.o
$ echo $?
0                              ← round-trip succeeds
```

### 2. Re-enable profiling in QuickCross

[`patches/0006-quickcross-static-only.patch`](../../../patches/0006-quickcross-static-only.patch)
(file kept the historical name even though "static-only" is no
longer literally what it does):

```haskell
, libraryWays = pure [vanilla, profiling]
, rtsWays     = pure
                [ vanilla, threaded, logging, debug
                , threadedDebug, threadedLogging
                , profiling, threadedProfiling
                , debugProfiling, threadedDebugProfiling ] }
```

Hadrian's shake DB had cached the previous flavour decision; the
first re-build only produced `.p_o` for the RTS.  Wiping
`_build/hadrian/.shake.database` forced a clean reconfigure that
properly built the profiling way for every library.  Took 54 min
on uranium for the from-scratch profiling rebuild.

### 3. Two Tiger compatibility shims for the profiling RTS

Once profiling-RTS C compiled cleanly, link of a `-prof` Haskell
program failed on two missing libSystem symbols:

- `_pthread_threadid_np` — added in macOS 10.6 (Snow Leopard).
  Used by `rts/posix/OSThreads.c`'s `kernelThreadId` for per-OS-
  thread identification in eventlog / cost-centre records.

- `_strnlen` — added to POSIX in 2008 (macOS 10.7).  Used by
  `rts/RtsUtils.c`'s `stgStrndup` (called by IPE / cost-centre
  string handling).

The first one was already gated by a `__MAC_OS_X_VERSION_MIN_REQUIRED < 1060`
check.  The catch: Tiger's 10.4u SDK uses
`MAC_OS_X_VERSION_MIN_REQUIRED` (no leading underscores) — the
modern `__MAC_OS_X_VERSION_MIN_REQUIRED` macro doesn't exist
there.  GHC's check evaluated the macro as undefined → the
"call pthread_threadid_np" branch was taken.

Fix in
[`scripts/ppc-cc.sh`](../../../scripts/ppc-cc.sh) (and the
deployed wrapper at
`~/.local/ghc-ppc-xtools/bin-wrap/ppc-cc`):

```
-D__MAC_OS_X_VERSION_MIN_REQUIRED=1040
-DMAC_OS_X_VERSION_MIN_REQUIRED=1040
```

For `strnlen`, no version gate existed at all — the call was
unconditional.  Added a 7-line shim in
[`patches/0015-rts-rtsutils-tiger-strnlen-shim.patch`](../../../patches/0015-rts-rtsutils-tiger-strnlen-shim.patch):

```c
#if defined(darwin_HOST_OS) && \
    defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && \
    __MAC_OS_X_VERSION_MIN_REQUIRED < 1070
static size_t tiger_strnlen(const char *s, size_t n)
{ const char *p = s; while (n-- > 0 && *p) p++; return p - s; }
#define strnlen tiger_strnlen
#endif
```

## Verified end-to-end

A
[`tests/profiling/run.sh`](../../../tests/profiling/run.sh)
regression script:

1. Cross-compiles `Mandel.hs` (Mandelbrot printer) with
   `-O -prof -fprof-auto`.
2. Ships to pmacg5.
3. Runs `+RTS -p -h -RTS`.
4. Prints `mandel.prof` (cost-centre + per-CC entries + module
   tree) and the head of `mandel.hp` (heap-profile sample data).

Result: 194 ticks (= 0.19 s wallclock), 4.98 MB allocated,
`mandelIter.go` claims 96.4% time / 95.1% alloc, 28998 entries —
all consistent.

## What the bindist now ships

In addition to v0.9.0's contents:
- `lib/ppc-osx-ghc-9.2.8/*/libHS*_p.a` — profiling-way archives
  for every library (35 of them).
- `lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_p.a` and
  `_thr_p.a`, `_debug_p.a`, `_thr_debug_p.a` — profiling-way
  RTS variants.

Bindist size grew from 124 → 196 MB.  All profiling artifacts.

## What's still TBD

- `+RTS -hc`/`-hd`/`-hr` heap-profile post-processing via `hp2ps`.
  Should work — `hp2ps` is a host-side tool, the `.hp` file from
  Tiger is portable.  Smoke-test belongs in a future session.
- Profiling + threaded RTS — built (`libHSrts-1.0.2_thr_p.a`
  exists), not exercised end-to-end yet (TLS-style
  `rtsSupportsBoundThreads=False` limitation may apply to some
  programs).
- LLVM-8 cross-clang.  Sister project shipped v8.0.1-r4 with the
  same fix; we could move to LLVM-8 for better diagnostics and
  slightly better codegen.  Not urgent now that LLVM-7 r4 works.
