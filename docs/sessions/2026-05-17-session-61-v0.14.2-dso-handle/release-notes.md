# v0.14.2 — StaticPointers + GHCi `-fobject-code` work on PPC/Tiger 🪄

The v0.14.1 (and every prior) bindist's runtime Mach-O loader failed to resolve `___dso_handle` whenever GHCi loaded a `.o` containing a `static` pointer.  `:l Foo.hs` in `ghc --interactive -fobject-code` mode aborted with:

```
lookupSymbol failed in resolveImports
/tmp/.../Foo.o: unknown symbol `___dso_handle'
```

[Session 60](https://github.com/cellularmitosis/ghc-darwin8-ppc/tree/main/docs/sessions/2026-05-17-session-60-extra-run-opts-runner) surfaced this via T9878b in the extended ghci-tnum runner.  The fix is two lines.

## Root cause

`rts/Linker.c::lookupDependentSymbol` has a special case for `__dso_handle` (see `Note [Resolving __dso_handle]`, upstream #20493) that hands the dependent object's image address back as a synthetic handle.  The strcmp was written for ELF, where the symbol arrives with two leading underscores:

```c
if (strcmp(lbl, "__dso_handle") == 0) {
    if (dependent) return dependent->image;
    else           return &lookupDependentSymbol;
}
```

Mach-O preserves the platform's leading-underscore symbol-name convention.  Our PPC Mach-O loader populates `macho_symbols[i].name` directly from the object's string table (`rts/linker/MachO.c:137-138`), so what arrives at `lookupDependentSymbol` is `"___dso_handle"` — three underscores — and the strcmp misses.  Resolution falls through to `dlsym(lbl + 1)`, which on Tiger also fails because `___dso_handle` is provided at link time by `dylib1.o`/`crt1.o` and isn't exported into the runtime dyld namespace.

The bug only fires when GHCi compiles + loads a `.o` containing `static` pointers — the StaticPointers SPT init machinery emits a call to `__cxa_atexit(_, _, __dso_handle)` so SPT entries can be unregistered on shutdown, and the resulting `.o` has an undefined external for `___dso_handle`.

## What changed

[`patches/0017-rts-dso-handle-mach-o-underscore.patch`](https://github.com/cellularmitosis/ghc-darwin8-ppc/blob/v0.14.2/patches/0017-rts-dso-handle-mach-o-underscore.patch) — match both spellings:

```c
/* See Note [Resolving __dso_handle] */
-if (strcmp(lbl, "__dso_handle") == 0) {
+if (strcmp(lbl, "__dso_handle") == 0 ||
+    strcmp(lbl, "___dso_handle") == 0) { /* Mach-O underscore prefix */
     if (dependent) return dependent->image;
     else           return &lookupDependentSymbol;
}
```

Plus a four-line update to `Note [Resolving __dso_handle]` documenting why both spellings are matched.  Same semantics on ELF and Mach-O — the loader hands the dependent object's image back either way; only the spelling at lookup time differs.

## Verification

After re-rolling the bindist with the patched stage1, [session 60's runner](https://github.com/cellularmitosis/ghc-darwin8-ppc/blob/v0.14.2/docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/run-ghci-tnum.sh) re-ran against the new bindist:

```
PASS  T9878b           (rc=0)
PASS  T12091           (rc=0)
PASS  T17500           (rc=0)
FAIL  T17549           (rc=0)  stderr mismatch
=== Summary: 165 PASS / 1 FAIL out of 166 tests ===
```

**T9878b flipped to PASS** ✅ — the load path that surfaced the bug in session 60 now works.  T17549 remains as the HFS+ 1-second mtime-granularity race in upstream's `:reload` test script (writeFile X → :load X → writeFile X → :reload skips the reload when both writeFiles land in the same second; T1914 has the same shape but explicitly bumps mtimes with `:! touch -t`; T17549 was authored later and omitted that touch).  Not a PPC bug.

The deployed `ghc-real` and its compiled-in Linker.c text segment now contain both spellings:

```
$ ssh pmacg5 'strings /opt/ghc-stage2/bin/ghc-real | grep -F dso_handle | sort -u'
___dso_handle
__dso_handle
```

## Demo

[`demos/v0.14.2-static-pointers.{hs,sh}`](https://github.com/cellularmitosis/ghc-darwin8-ppc/blob/v0.14.2/demos/v0.14.2-static-pointers.sh) — a module with four `static` pointers of different shapes (Bool value, String value, `Int -> Int` closure, `[Int] -> Int` closure).  The driver:

0. `strings /opt/ghc-stage2/bin/ghc-real | grep -F dso_handle` — confirms the deployed binary contains both spellings.
1. `scp`s the `.hs` to pmacg5.
2. Native compile + run — prints all four `deRefStaticPtr` results.
3. `:load`s the module into `ghc --interactive -fobject-code` (the path that was broken pre-v0.14.2), brings `GHC.StaticPtr` into REPL scope with `:m +`, exercises `deRefStaticPtr` on each pointer, then runs `main`.

```
==> 0. confirm v0.14.2 ghc-real has both __dso_handle spellings
___dso_handle
__dso_handle

==> 2. compile + run natively
deRefStaticPtr round-trip:
  static True               = True
  static "v0.14.2 ..."      = v0.14.2 static-pointer demo on PPC/Tiger
  static (\x -> x+x) $ 21   = 42
  static sum $ [1..10]      = 55

==> 3. :load the module into GHCi -fobject-code (the v0.14.2 path)
GHCi, version 9.2.8: https://www.haskell.org/ghc/  :? for help
ghci> Ok, one module loaded.
ghci> ghci> True
ghci> "v0.14.2 static-pointer demo on PPC/Tiger"
ghci> 42
ghci> 55
ghci> deRefStaticPtr round-trip:
  static True               = True
  static "v0.14.2 ..."      = v0.14.2 static-pointer demo on PPC/Tiger
  static (\x -> x+x) $ 21   = 42
  static sum $ [1..10]      = 55
StaticPointers work on PPC/Tiger.
```

## Upstream contribution opportunity

The strcmp limitation affects any Mach-O cross-GHC where the host doesn't have a live `dyld` exporting `___dso_handle` (which is the normal Mach-O state — the symbol is provided at link time by `dylib1.o`/`crt1.o`, not at run time).  Patch 0017 is upstream-shaped: applying it to current GHC's `rts/Linker.c` would help any future Mach-O cross-build.

## Install

```
$ tar xJf ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz
$ cd ghc-9.2.8-powerpc-apple-darwin8/
$ ./install.sh --prefix=$HOME/.local/ghc-darwin8-ppc \
               --ppc-host=<your-tiger-ssh-alias>
```

## Session

[`docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/`](https://github.com/cellularmitosis/ghc-darwin8-ppc/tree/main/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle).

🤖 Generated with [Claude Code](https://claude.com/claude-code).
