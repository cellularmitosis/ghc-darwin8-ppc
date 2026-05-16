# Session 60 findings

## TL;DR

Extended session 58's `run-ghci-tnum.sh` to thread upstream's
`extra_run_opts(...)` annotation through the GHC invocation.  Three
new tests added — **T12091 + T17500 PASS, T9878b FAILS** and the
failure is a real, new, upstream-shaped PPC/Tiger bug in the runtime
Mach-O loader's `__dso_handle` handling.  Filed as
[proposals/rts-dso-handle-mach-o.md](../../proposals/rts-dso-handle-mach-o.md).

## 1. The runner extension is two-and-a-half lines of bash

A `run_opts_for() { case "$1" in ...; esac; }` function near the
top of the runner, plus `opts=$(run_opts_for "$name")` inside the
per-test command-builder loop, plus `$opts` slotted into the two
GHC-invocation lines (one for `combined=0`, one for `combined=1`).

The HC_FLAGS string in the runner is plain word-token concatenation
when interpolated into a remote shell, so multi-word per-test opts
like `-ddump-to-file -ddump-bcos` tokenise correctly when shipped
over ssh.  No quoting headache.

## 2. The `extra_run_opts` annotation in upstream is 4 hits, not 4 runnable

`grep extra_run_opts tests/ghci/scripts/all.T` finds 6 entries, but
of those:
- `ghci017` also has `reqlib('haskell98')` — skip (`reqlib` deferred
  to a future session).
- `ghci056` also has `pre_cmd($MAKE)` — skip (`pre_cmd` deferred).
- `T17669` also has `expect_broken(17669)` — upstream itself doesn't
  run this; skip.

That leaves three runnable: **T9878b, T12091, T17500**.  Session 58
HANDOFF's "4 more tests" count counted T17669 too.  Minor stale.

## 3. The T9878b failure surfaces a real upstream-shaped bug

T9878b is a static-pointer test:

```haskell
{-# LANGUAGE StaticPointers #-}
module T9878b where
import GHC.StaticPtr
f = deRefStaticPtr (static True)
```

`extra_run_opts('-fobject-code')` makes GHCi compile-and-load `.o`
files instead of using bytecode.  With native object code, the
`StaticPointers` SPT init machinery emits a call to `__cxa_atexit`
(to deregister entries on shutdown) — and `__cxa_atexit`'s third
argument is `__dso_handle`.  The object's symbol table therefore
carries an undefined external for `___dso_handle` (Mach-O underscore
prefix preserved).

When the runtime Mach-O loader (`rts/linker/MachO.c::resolveImports`)
tries to resolve `___dso_handle`, it calls `lookupDependentSymbol`
in `rts/Linker.c`.  That function has a special case:

```c
if (strcmp(lbl, "__dso_handle") == 0) {
    if (dependent) return dependent->image;
    else           return &lookupDependentSymbol;
}
```

— but the strcmp wants `"__dso_handle"` (no prefix, ELF-style) while
the Mach-O loader passes `"___dso_handle"` (Mach-O prefix kept,
matches `symbol->name` as populated from the object's string table
in `rts/linker/MachO.c:137-138`).  Three underscores vs two.  The
special case never fires for Mach-O object loads.

dlsym fallback also fails: on Tiger, `___dso_handle` is provided by
the link-time `dylib1.o`/`crt1.o` and not exported through the
runtime dyld namespace.

End-to-end: `lookupSymbol` returns NULL → `resolveImports` errors →
`:l T9878b.hs` fails → `f` is not in scope → stdout never prints
`True`.

The fix is two lines in `rts/Linker.c` — see
[proposals/rts-dso-handle-mach-o.md](../../proposals/rts-dso-handle-mach-o.md)
for the full release sketch.

## 4. The other two tests pass for principled reasons

**T12091** (`extra_run_opts('-fobject-code')`):

```
x = 5
x
```

No `:l` directive.  REPL bindings stay in bytecode/in-process
interpreter scope regardless of `-fobject-code` — the flag affects
module compilation, not interactive line evaluation.  So
`-fobject-code` is effectively a no-op for this test, and it passes
trivially through the same path as bytecode tests.

**T17500** (`extra_run_opts('-ddump-to-file -ddump-bcos')`):

The script loads `T17500.hs` and tests that `T17500.dump-BCOs`,
`Ghci1.dump-BCOs`, `Ghci2.dump-BCOs` exist + contain the title
line `== Proto-BCOs ==`.  This exercises the dump-file machinery
under `-ddump-to-file`, not the Mach-O loader (the module is loaded
as bytecode because the script does NOT pass `-fobject-code`).
Confirms that:
- our stage2 ghc honours `-ddump-bcos` at the BCO-generation phase,
- BCOs are generated for both the loaded module (`T17500.dump-BCOs`)
  and each REPL group of bindings (`Ghci1`, `Ghci2`),
- the file-naming convention (`Ghci<N>.dump-BCOs`) is intact.

That's three light verifications of the in-process interpreter's
BCO pipeline.  Nice-to-have signal.

## 5. T8042 was lucky this run

The runner's run 1 in session 58 had T8042 FAIL on the HFS+
mtime race; this session's run shows T8042 PASS, T17549 still FAIL.
Both failures are the same shape (two writeFiles inside one HFS+
second confuse `:reload`'s mtime check) — the race surfaces
non-deterministically depending on filesystem latency on pmacg5 at
test time.

Not a new finding — session 58's findings §3 already covered this.
Noted here only because the headline number (164/166 vs 161/163
last session) is partly luck.

## 6. The runner's auto-discovery glob already covers all 3 new tests

All three new test files (`T9878b.hs`, `T17500.hs`) are picked up
by the existing `$SCRIPTS_DIR/$name.*` glob in the staging loop —
no explicit `extras` slot needed in the TESTS list.  T12091 has
no `.hs` file at all (script is pure REPL bindings).
