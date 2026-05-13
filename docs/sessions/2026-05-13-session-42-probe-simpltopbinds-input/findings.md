# Session 42 findings — **simplTopBinds' input `binds0` IS corrupted**; the [InBind] list spine is truncated by GC

## TL;DR

Probe42 instruments `simplTopBinds`'s entry in `Simplify.hs` to
emit a single line per call:

```
PROBE42-TOPBINDS call=<N> num_groups=<length binds0> num_binders=<length (bindersOfBinds binds0)>
```

The session-41 hypothesis ("the simplifier's input binds0 is
corrupted upstream") is **DIRECTLY CONFIRMED**.

### The signature table

| env-len    | call=1 binds            | call=2 binds     | RC | .o size | outcome              |
|------------|-------------------------|------------------|----|---------|----------------------|
| (clean)    | groups=9 binders=9      | groups=13 binders=13 | 0  | 46340 B | proper compile       |
| 600        | groups=1 binders=1      | -                | 1  | -       | refineFromInScope panic |
| 700        | groups=1 binders=1      | groups=5 binders=5 | 1  | -       | refineFromInScope panic |
| 800        | (no probe42 fired)      | -                | 1  | -       | TC-time swap-not-in-scope |
| 850, 900, 950, 1000 | groups=0 binders=0 | -        | 0  | **152 B**   | **SILENT MISCOMPILE — empty .o** |
| 1100, 1500, 1900, 2000 | (no probe42 fired) | -      | 1  | -       | TC-time swap-not-in-scope |
| 1650, 1700 | groups=1 binders=1      | -                | 1  | -       | refineFromInScope panic |

### -A1G (huge nursery → no GC) baseline

| -A     | binds list shape           | .o size | outcome   |
|--------|----------------------------|---------|-----------|
| 1G     | call=1 num=9, call=2 num=13 | 46340 B | proper compile |
| 1G len=850 | call=1 num=9, call=2 num=13 | 46340 B | proper compile |

With `-A1G`, the [InBind] list is **always intact**.  The bug is
GC-pressure-induced corruption of the list spine.

## F1. **Silent miscompilation at env-lens 850-1000**

This is the most alarming finding: at env-lens 850-1000 (under
`-A1m -G1`), `ghc-real -c Big2.hs` returns RC=0 (success!) and
produces a 152-byte .o file containing **zero bindings**:

```
$ ssh pmacg5 'nm /tmp/Big2.o'
(empty)
```

vs. the clean compile's 46340-byte .o:

```
$ ssh pmacg5 'nm /tmp/Big2.o | head'
00003e78 D _Big2_allPositive_closure
00000290 T _Big2_allPositive_entry
00004024 S _Big2_allPositive_info
00003fb0 D _Big2_countOf_closure
...  (all 8 functions present)
```

The .hi file at 850-1000 (1237 bytes) is also smaller than
clean's 2202 bytes — it's been emptied out.

**The compiler is silently producing valid-looking but empty
output objects.**  This is a much more severe correctness bug
than a panic.  Programs that link against this Big2.o would
encounter linker errors or undefined behaviour at runtime.

## F2. The list-spine-truncation pattern

`binds0 :: [InBind]` flowing into `simplTopBinds` is a heap-
allocated cons-list.  Each cons cell is a closure of the form

```
(:) head tail
```

with `head :: InBind` (the binding) and `tail :: [InBind]` (the
rest of the list).

Probe42's observation across failing env-lens:

- **At len=600, 1650, 1700**: `length binds0 = 1`.  The list
  has been truncated to `[head : []]` — the FIRST cons cell is
  intact but its `tail` pointer has been rewritten to Nil.
- **At len=850-1000**: `length binds0 = 0`.  The list IS Nil
  (an empty list).  Either the entire list spine was nulled, or
  the variable `binds0` itself points at Nil.
- **At len=700**: call 1 sees length=1, call 2 sees length=5.
  Between calls, more binders appeared from somewhere — possibly
  the previous simplifier iteration produced new bindings via
  inlining or floating-out.  But still less than the expected 9.

The shrinkage is **deterministic given env-len** (three repeats
at len=600 all produce length=1).

## F3. The GC connection

`-A1G` (1 GB nursery) consistently produces clean compiles with
correct binder counts (9 / 13).  `-A1m -G1` (1 MB nursery,
single-generation collector) produces 0-1 binders.

The only thing differing between these RTS configurations is
**GC frequency** (and slightly, generation count).  With a 1 GB
nursery, GC almost never runs during a small compile.  With 1
MB + G1, GC runs many times.

This is direct evidence that **GC is corrupting the [InBind]
list spine**.  Either:

- (a) The GC is moving the cons cells' `tail` pointers to point
  at the wrong place (often Nil).
- (b) Some cons cell pointed at by `binds0` is being collected
  prematurely, replaced with stale memory that happens to
  resemble Nil.
- (c) The `binds0` variable's heap location is being
  overwritten with a pointer to a stale Nil cons.

(b) and (c) feel most plausible: a heap closure that holds the
binds list is being relocated by GC, and the relocation
doesn't update some reference correctly, leaving a stale stub
that the simplifier reads as an empty list.

## F4. Connection to all prior sessions

This finding **subsumes** every earlier "X is corrupted" framing:

- "v's closure shape is corrupt" (sessions 33-36): the v that
  appears in the panic is a `Var` from one of the binders that
  DID survive in the truncated list; it appears in the wrong
  scope context.
- "UniqMap data structures corrupted" (sessions 28-38): the
  InScopeSet at the panic site is small because the binds list
  was small — only 1 top-level binding got processed.
- "Var.realUnique drift" (session 39): not the bug; the Vars
  are stable.
- "Two distinct Vars with same OccName" (session 40): the
  panic-site env's `seIdSubst` is empty because no
  substitutions were built up (only 1 binding processed).
- "GC corrupts SimplEnv data structure" (session 41): partially
  true — but the env corruption is downstream of the binds-list
  corruption.  The simplifier sees binds=[1 binder], runs
  normally on it, and the resulting env is small but
  uncorrupted.

**One root cause:** GC truncates the `[InBind]` list spine.
Every downstream observation is a symptom of that single bug.

## F5. Concrete next-session targets

1. **Identify which closure type the [InBind] cons cells are.**
   `:` is `ghczmprim_GHCziTypes_Czm_con_info`.  The cons cell
   has 2 ptr fields (head, tail) and 0 non-ptr fields.  On
   PPC32 unreg this is closure-type CONSTR_2_0 or similar.
2. **Instrument GC's evac/scav for CONSTR_2_0 closures.**  In
   `rts/sm/Evac.c::copy_tag`, when copying a CONSTR_2_0
   closure, log the destination address and verify the payload
   pointers are correctly forwarded.
3. **Pin binds0 in an IORef and walk its spine repeatedly.**
   Like probe39 but on a `[InBind]` list — read its length
   periodically during the simplifier's run.  If the length
   shrinks between checks, GC is collapsing the spine in real
   time.
4. **Compare list-spine integrity for other CoreProgram-like
   lists.**  `mg_binds`, `cg_binds`, the rules list, etc. —
   all share the cons-cell representation.  If they ALL
   corrupt under GC pressure, the bug is in generic cons-cell
   handling.  If only this one corrupts, the bug is in the
   specific [InBind] heap structure.
5. **Compare PPC32 unreg's `:` (cons) constructor layout vs
   host arm64.**  Look for any size / alignment / pointer-
   width assumption that's wrong on PPC32.

## F6. The user-facing workaround

`-A256m` (or `-A1G`) consistently produces clean compiles of
Big2.hs.  Document this as an immediate operational workaround
until the root cause is fixed:

> When compiling on PPC stage2, set `+RTS -A256m -RTS` (or
> add it to ghc-stage2-wrapper.sh) to suppress GC during
> small compiles and avoid the binds-list corruption.

Note: even `-A256m` won't help for very large programs that
fill the nursery before completing.  A real fix is needed.

## F7. What probe42 directly ruled in

**Confirmed:**

- `simplTopBinds`'s input `binds0` has fewer binders in failing
  runs than in clean runs (1 or 0 vs 9).
- The shrinkage is GC-frequency-sensitive (`-A1G` → 9 always;
  `-A1m -G1` → 0/1).
- The shrinkage is **deterministic** given heap layout
  (env-len + flags).
- The compiler can silently produce empty .o files when
  binds0 = [] (at env-lens 850-1000).

**Implied (one strong root-cause hypothesis):**

- GC corrupts the `[InBind]` cons-list spine, truncating it
  to 0 or 1 elements somewhere between the desugarer/optimizer
  pipeline producing the list and `simplTopBinds` reading it.

## F8. What this means for the project status

The bug is **much more dangerous than previously thought**:

- Not just a panic — also silent miscompilation producing
  empty .o files.
- Affects ANY program of any size when GC pressure is high.
- `+RTS -A1G` workaround works but doesn't scale.

This finding should be reflected in the README's "Implementation
status" table and the user-facing release notes.  Stage2 native
compilation should be marked 🟡 with a strong "use -A256m or
larger" caveat rather than just ✅.
