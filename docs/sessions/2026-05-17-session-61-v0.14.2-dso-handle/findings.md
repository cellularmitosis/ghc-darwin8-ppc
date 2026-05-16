# Session 61 findings

## TL;DR

Executed session 60's [`docs/proposals/rts-dso-handle-mach-o.md`](../../proposals/rts-dso-handle-mach-o.md)
release sketch.  Six-line patch to `rts/Linker.c` ships as
[patch 0017](../../../patches/0017-rts-dso-handle-mach-o-underscore.patch);
v0.14.2 released end-to-end.  Session-60 runner re-runs at **165/166
PASS** (T9878b ✅; T17549 remains as the HFS+ mtime race).

## 1. The actual change is ~3 lines plus a comment

```c
-   if (strcmp(lbl, "__dso_handle") == 0) {
+   if (strcmp(lbl, "__dso_handle") == 0 ||
+       strcmp(lbl, "___dso_handle") == 0) { /* Mach-O underscore prefix */
```

Plus a four-line update to `Note [Resolving __dso_handle]` explaining
why both spellings are matched.  The proposal predicted "two lines";
the actual count is "two if you count code only, six with the note
update."  Trivially small.

## 2. The OR variant beats the `#ifdef OBJFORMAT_MACHO` variant

Two equivalent fix shapes:

(a) OR both spellings unconditionally:
```c
if (strcmp(lbl, "__dso_handle") == 0 ||
    strcmp(lbl, "___dso_handle") == 0) { ... }
```

(b) Strip one leading underscore under `OBJFORMAT_MACHO` before strcmp:
```c
const char *probe = lbl;
#if defined(OBJFORMAT_MACHO)
    if (probe[0] == '_') probe++;
#endif
if (strcmp(probe, "_dso_handle") == 0) { ... }
```

Went with (a) because (i) it's unconditional (no `#if` adds a
preprocessor branch that platform-specific testing forgets to
cover), (ii) it matches the existing `Linker.c` style of `strcmp(lbl,
"_FOO") == 0 ||` chains, (iii) it would still work if a future
Mach-O variant ever drops the underscore prefix (vanishingly
unlikely but harmless to handle), (iv) the cost is one extra strcmp
call per `lookupDependentSymbol` invocation, which is unmeasurable
next to the work that happens after the special case fires.

## 3. Stage1 rebuild is fast — 3.44 sec end-to-end

Only `rts/Linker.c` changed.  Hadrian's `Want
_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`
recompiles `Linker.c` once, then re-archives + re-ranlibs all 10 RTS
way archives (vanilla, thr, thr_p, thr_l, thr_debug, thr_debug_p,
debug, debug_p, l, p), then re-runs `cabal-copy` +
`cabal-register`.  Total wall time 3.44 sec on a recent M-series
Mac.  A nice contrast with the 3m09s `binary-dist-dir` re-roll
later (which has to rebuild all the cabal profiling-way artefacts).

## 4. Setting `$GHC` to the full path is load-bearing

Sourcing `scripts/cross-env.sh` is not sufficient — hadrian's
`hadrian/build-cabal` wrapper invokes `cabal --with-compiler=$GHC`
with `GHC` defaulting to `ghc` (just the name).  On uranium, cabal
is homebrew's 3.16 and looks for `ghc` via its own resolution path,
which finds homebrew's ghc 9.14, which causes a hadrian-dep
resolution failure (base-4.22 vs hashable's `base < 4.17`).

Setting `GHC=$HOME/.local/ghc-9.2.8/bin/ghc` explicitly fixes it.
This wasn't documented in `cross-env.sh` or `deploy-stage2.sh` — the
script `deploy-stage2.sh` happens to work because its uses of `STAGE1`
are full paths, not `ghc`-via-PATH lookups.  Recommended follow-up:
add `export GHC=$HOME/.local/ghc-9.2.8/bin/ghc` to
`scripts/cross-env.sh` so it's set automatically when sourced.

## 5. The "verify the bindist's Linker.o has both spellings" step is a useful sanity check

```
$ ar x bindist/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a Linker.o
$ strings Linker.o | grep dso_handle
__dso_handle
___dso_handle
```

A one-liner pre-tar sanity check that the bindist actually contains
the fix and didn't accidentally pick up a stale archive.  Worth
repeating on any future RTS-affecting patch.  The on-device follow-up
(`ssh pmacg5 'strings /opt/ghc-stage2/bin/ghc-real | grep dso_handle'`)
is the same check at the binary level.

## 6. The "165/166 PASS" headline is exactly what the proposal predicted

The proposal said: "target: 165/166 with only the HFS+ mtime race
remaining."  Got exactly that.  No surprises, no further bugs
surfaced, no other tests flipped one way or the other.  T8042 (same
HFS+ race shape as T17549) was the lucky-passes coin-flip this
run — session 60's run had it pass too; session 58/59 had it fail
in different runs.  T17549 was the unlucky coin-flip; the inverse
sometimes happens.

## 7. The demo exercise revealed a small lesson about REPL scope

When the demo's first iteration sent these commands directly:

```
:l /tmp/static-pointers.hs
deRefStaticPtr staticTrue
```

…the `:l` succeeded (the v0.14.2 fix at work — pre-fix this would
have failed at `:l` time with the `___dso_handle` error) but
`deRefStaticPtr` failed with "Variable not in scope".  GHCi `:l`
brings the loaded module's top-level bindings into scope but does
not import names from modules the loaded module imports
(`GHC.StaticPtr` in this case).  `:m + GHC.StaticPtr` brings
`deRefStaticPtr` into scope.

This is GHCi behaviour, not a v0.14.2 bug — same shape as needing
`:m + Data.Map.Strict` after `:l` of a module that uses
`Map.fromList`.  Mentioned only because the second-iteration demo
adds the `:m + GHC.StaticPtr` line and explains why.

## 8. v0.14.2 effort matched session 59's "half a session" estimate

Session 60 HANDOFF predicted "roughly half a session-59" because no
testsuite re-debugging was needed.  Actual session-61 work breakdown:

- Patch + source edit: ~10 min (read the existing code, decide
  between OR vs `#ifdef`, write the patch).
- Stage1 rebuild: 3.44 sec (after one false start with wrong GHC env var).
- Stage2 deploy: ~30 sec.
- Verification runner: ~7 min wall-clock (most of it on pmacg5).
- Demo authoring + iteration: ~10 min.
- Bindist re-roll: 3m09s.
- Tar + sanity checks: ~1 min.
- README/state/roadmap/demos-README updates: ~5 min.
- Session docs (README/findings/HANDOFF/commits): ~10 min.
- Commit + tag + push + gh release create: ~2 min.

Total: ~35 min for the load-bearing work plus ~15 min for documentation.
Squarely "half a session-59" as predicted.
