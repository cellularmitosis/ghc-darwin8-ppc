# Session 23 — stage2 GC bug, round 5 (PROBE22POISON: real bug confirmed)

**Dates:** 2026-05-10.
**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on Tiger
uses the `+RTS -A1G` workaround.  Session 22 ruled out the bitmap-content
hypothesis for Catch.hs's PNP/PN frames: per-block audit showed all 15
True-marked slots are written-then-popped or never accessed, so PROBE21's
"is_ptr=0" BAD events for the 4 dominant Catch.hs info tables are most
likely false positives — heap-shaped values legitimately stranded in
genuinely-dead slots.  The actual GC crash is real (deterministic under
`-DS` since session 19) but somewhere else.  Session 22's HANDOFF
proposed a **poison-on-stale-slot RTS patch** as the decisive next test.

**Status on exit:** **bug confirmed real, location pinned to
`GHC.Data.FastString` Cmm.**  The PROBE22POISON RTS patch landed,
rebuilt, and got deployed to pmacg5.  Stage2 ghc compiling M5.hs
under `+RTS -A1m -RTS` then crashed deterministically (5/5
iterations) with `EXC_BAD_ACCESS at 0xdeadbeef` in `_blk_c7te + 112`,
which calls `__memcpy(dst, src=0xdeadbeef, len=16)`.  The src came
from `MEM[Sp+12]` = slot 6 in PROBE22 coordinates from the most
recent gc, whose pre-poison value `0x0bf5f38a` was a tagged heap
pointer in a non-evacuated nursery block.  `_blk_c7te` lives between
`_s77C_entry` and `_ghc_GHCziDataziFastString_mkFastStringByteString_entry`
in stage2's text section, so the misclassifying frame is in some
local closure / continuation block within `GHC.Data.FastString`.
Session 22's "Catch frames are correct" stands; the bug is in a
different module's bitmap.  v0.12.0 unchanged; stage2 was reverted
to unmodified RTS at session end so the production binary on pmacg5
matches what the bindist ships.  HANDOFF for session 24: identify
the precise StackRep, dump the relevant FastString Cmm, and trace
back to the StgToCmm/LayoutStack code that emits the wrong bitmap.

## What we did, in order

### Step 1 — confirm baseline still green

`tests/run-tests.sh`: 30 PASS / 4 expected design-diffs (Int size,
getProgName, getpid, numeric boundaries).  Same as v0.12.0 baseline.

(The test run started with the unpatched RTS but its later iterations
linked against the post-patch RTS — no regressions.)

### Step 2 — write & apply PROBE22POISON to `rts/sm/GC.c`

Inserted right before `resize_nursery();` in `GarbageCollect()`,
mirroring PROBE20/21's location from session 20.  Walks every word of
the running TSO's stack from `sp` to `stack + stack_size`.  For each
`HEAP_ALLOCED((void*)w)` whose `Bdescr(...)->flags & BF_EVACUATED` is
zero, prints a `PROBE22POISON gc_no=N slot=K old=0x...` line and
overwrites the word with `0xDEADBEEF`.  Per-GC summary line
`PROBE22 gc_no=N N=g major=0/1 ... words=W heap_ptr=H poisoned=P`.

Patch: [`probe22-poison-stack.patch`](probe22-poison-stack.patch).

### Step 3 — RTS-only rebuild

```
$ ./hadrian/build --flavour=quick-cross -j8 \
      _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
```

3.4s reported by hadrian; just GC.o + libHSrts*.a re-link.  All 12
RTS ways batched.

### Step 4 — re-link + deploy stage2 ghc

`bash scripts/deploy-stage2.sh pmacg5`.  Cross-link picks up the
patched `libHSrts-1.0.2.a`, scp's to `/opt/ghc-stage2/bin/ghc-real`.
Smoke test (Hello.hs under -A1G via the wrapper) passes — small
programs with a giant nursery never trigger the bug.

### Step 5 — run M5.hs through `ghc-real` under `-A1m`

[`scripts/run-poison.sh`](scripts/run-poison.sh) does 5 × M5.hs under
`-A1m` plus a `-A1m -DS` and `-A1G` control.  Bypasses the wrapper's
forced `-A1G` by calling `/opt/ghc-stage2/bin/ghc-real` directly.

| iter         | exit | n_GCs | n_poisoned |
|--------------|-----:|------:|-----------:|
| iter1-A1m    |  139 |     3 |          9 |
| iter2-A1m    |  139 |     3 |          9 |
| iter3-A1m    |  139 |     3 |          9 |
| iter4-A1m    |  139 |     3 |          9 |
| iter5-A1m    |  139 |     3 |          9 |
| iter1-A1m-DS |    1 |     0 |          0 |
| iter1-A1G    |    0 |     0 |          0 |

5/5 deterministic SIGSEGV.

### Step 6 — read the OS X crash report on pmacg5

`~/Library/Logs/CrashReporter/ghc-real.crash.log` had 5 matching
`EXC_BAD_ACCESS at 0xdeadbeef` reports between 03:54:45 and 03:55:21,
one per iter1..5.  Pulled to
[`logs/ghc-real.crash.log`](logs/ghc-real.crash.log).

Backtrace (identical for all 5):

```
Exception:  EXC_BAD_ACCESS (0x0001)
Codes:      KERN_INVALID_ADDRESS (0x0001) at 0xdeadbeef
0   <<00000000>>  0xffff87f0 __memcpy + 80 (cpu_capabilities.h:189)
1   ghc-real      0x01fa4820 _blk_c7te + 112
2   ghc-real      0x07f00bd0 StgRun + 32
3   ghc-real      0x07efc550 scheduleWaitThread + 944
4   ghc-real      0x07ef6248 rts_evalLazyIO + 168
5   ghc-real      0x07ef8b8c hs_main + 172
```

Crash registers (excerpt):

```
r2: 0x0bfe8bf0   ← Sp at crash (iter2-5; iter1 had 0x0bfe8c08)
r3: 0x0bdbc43c   ← memcpy dst
r4: 0xdeadbeef   ← memcpy src (POISONED)
r5: 0x10         ← memcpy len = 16 bytes
r27: 0xbf8a19c   ← TSO ptr (matches gc_no=2 PROBE22 line)
```

### Step 7 — disassembly of `_blk_c7te` confirms the read site

`otool -tV` on `/opt/ghc-stage2/bin/ghc-real`, slice at the crash:

```
01fa4810  addi r3, r29, 0x8          ; r3 = memcpy dst
01fa4814  lwz  r4, 0xc(r2)           ; r4 = MEM[Sp + 12] = memcpy src ← READ
01fa4818  lwz  r5, 0x8(r2)           ; r5 = MEM[Sp +  8] = memcpy len
01fa481c  bl   _memcpy$stub$island$3
01fa4820  …                          ; ← LR / crash PC
```

So the slot read is `MEM[Sp + 12]`.

### Step 8 — slot correlation: PROBE22POISON ↔ crash

Crash `Sp` (iter2–5) = `0x0bfe8bf0`.  Read site = `MEM[0x0bfe8bfc]`.

GC-time `Sp` = `0xbfe8be4` (per `PROBE22 gc_no=2 ...`).  So
`crash_Sp − GC_Sp = 0xc` = 12 bytes (3 words) — Sp went UP between GC
and crash, meaning 3 frames were popped post-GC.  Equivalently,
`MEM[Sp+12]` at crash time = `MEM[GC_Sp + 24]` = **slot 6** in
PROBE22 coordinates.

The PROBE22POISON line for iter2–5, gc_no=2:

```
PROBE22POISON gc_no=2 slot=6 old=0x0bf5f38a bd_gen=0 bd_flags=0x0
```

`slot=6` got stomped from `0x0bf5f38a` → `0xdeadbeef`.  At crash
time, that exact word was read as a pointer, fed to memcpy, deref'd,
SIGSEGV.

(iter1 had `GC_Sp = 0xbfe8bfc` and `crash_Sp = 0xbfe8c08` — same
+12 delta, same slot 6 in GC coords, same `0x0bf5f38a` pre-poison
value.  The bug is fully deterministic; only absolute addresses
shift between iterations.)

### Step 9 — locate `_blk_c7te` in the source tree

`nm` on ghc-real (sorted), nearest neighbours:

```
01fa42e0 T _ghc_GHCziDataziFastString_zdwmkFastStringBytes_entry
01fa44f0 T _ghc_GHCziDataziFastString_isUnderscoreFS1_entry
01fa4690 t _s77B_entry                        ; local lifted closure
01fa46e0 t _s77C_entry                        ; local lifted closure
01fa47b0 t __blk_c7te ←                       ; ★ crash site ★
01fa4880 t __blk_c7tr
01fa4920 t __blk_c7tq
01fa4940 T _ghc_GHCziDataziFastString_mkFastStringByteString_entry
```

→ misclassifying frame is in **`GHC.Data.FastString`**'s compilation
unit (likely a continuation in the `mkFastStringBytes` /
`isUnderscoreFS1` / `mkFastStringByteString` chain).  16-byte memcpy
into a freshly-allocated heap block looks like
`copyByteArray#`-style FastString-bytes copy.

### Step 10 — restore stage2 to clean state

Reverted the GC.c PROBE22POISON edit, rebuilt RTS, redeployed clean
stage2 ghc to pmacg5.  Production stage2 on pmacg5 once again
matches v0.12.0.

## Net effect on the search space

Going into session 23 we had two competing hypotheses for the
93/106 BAD pay=1 events PROBE21 attributed to Catch.hs PNP frames:

> **H-real-bug:** at least one is a real missed root.
> **H-false-positive:** all are dead-but-stranded heap-shapes.

Session 22's per-block audit established that for **Catch.hs's
frames specifically**, H-false-positive is correct.  Session 23's
PROBE22POISON now establishes that, broadening the scope to **all**
non-evac heap-shaped slots on the running TSO's stack:

> **One slot is read** (the `Sp+12` source argument to a 16-byte
> `memcpy` in `_blk_c7te`, which is in `GHC.Data.FastString`'s text
> section).  **Eight other PROBE22POISON-stomped slots in the same
> run cause no observable effect** — they really are dead from the
> reading-code's perspective, just as session 22 said.

So PROBE21's signal-to-noise was ~1:8 in this run.  The good news is
that one needle was enough to localise the bug to a specific
compilation unit.  The next session can re-cross-compile FastString.hs
with `-ddump-cmm-final`, find the exact info table whose StackRep
mis-classifies slot `Sp+12` of the `_blk_c7te`-containing frame, and
walk back to the StgToCmm/LayoutStack code that produced it.

## Status on exit

- **v0.12.0 unchanged.**  Stage2 ships with `+RTS -A1G` wrapper,
  baseline test battery green.
- **Stage2 ghc on pmacg5 reverted** to unmodified-RTS build at
  session end.
- **PROBE22POISON patch + scripts saved** to
  [`probe22-poison-stack.patch`](probe22-poison-stack.patch) and
  [`scripts/run-poison.sh`](scripts/run-poison.sh) — re-applicable
  in 2 minutes.
- **Crash log + disassembly + per-iter PROBE logs** saved to
  [`logs/`](logs/).
- **HANDOFF.md** for session 24 frames the next experiment: dump
  cross-built FastString.hs Cmm, find the offending info table /
  block / StackRep, classify, and instrument LayoutStack /
  stackMapToLiveness for that frame to find why the slot got
  marked non-pointer.

## Files added this session

- [`probe22-poison-stack.patch`](probe22-poison-stack.patch) — RTS
  diff against unmodified GC.c.
- [`scripts/run-poison.sh`](scripts/run-poison.sh) — harness for
  the 5×iteration repro.
- [`README.md`](README.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md), `commits.md` — session writeup.
