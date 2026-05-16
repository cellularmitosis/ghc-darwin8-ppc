# Proposal: teach `lookupDependentSymbol` about Mach-O's `___dso_handle`

**Discovered:** session 60 (2026-05-17), via T9878b in the extended
ghci-tnum runner (`-fobject-code` + `:l T9878b.hs` exercises `static
True` → runtime Mach-O loader load of the resulting `.o`).

**Symptom:**

```
ghc-real:
lookupSymbol failed in resolveImports
/tmp/.../T9878b.o: unknown symbol `___dso_handle'
ghc-real: Could not load Object Code /tmp/.../T9878b.o.
```

**Root cause** (upstream-shaped, not Tiger-specific):

`rts/Linker.c::lookupDependentSymbol` has a special case for
`__dso_handle` that returns the dependent object's image as the handle
(see `Note [Resolving __dso_handle]` in that file, upstream commit
ref'd as `#20493`):

```c
if (strcmp(lbl, "__dso_handle") == 0) {
    if (dependent) {
        return dependent->image;
    } else {
        return &lookupDependentSymbol;
    }
}
```

This `strcmp` was written for the ELF case, where the linker presents
`__dso_handle` with no underscore prefix.  Mach-O symbol names always
carry an extra leading underscore (the `_main` / `_printf`
convention).  Our PPC Mach-O loader populates `macho_symbols[i].name`
directly from the object's string table (`rts/linker/MachO.c:137-138`),
so what arrives at `lookupDependentSymbol` is `"___dso_handle"` —
three underscores — and the special-case never fires.

Compilers running under non-Mach-O object formats (ELF / PEi386) hit
this code path with the two-underscore form and resolve cleanly.  On
Mach-O it just fails.  Nobody noticed because Mach-O builds normally
fall through to `dlsym(lbl + 1)` for unresolved externals
(`rts/Linker.c:881-892`), which on a running process picks up
`___dso_handle` from `dyld`.  But for a `.o` loaded into a *cross-*
or *headless* GHCi (no `dyld` to fall back on for project-internal
symbols), `dlsym` returns NULL and we error.

On our PPC/Tiger stage2 ghc this path is the regular one: `:l T9878b.hs`
in `-fobject-code` mode produces a `.o` that has an `___dso_handle`
relocation (from `static`-pointer SPT init code calling
`__cxa_atexit(..., __dso_handle)`).  The runtime loader sees a
Mach-O-prefixed name, asks `lookupDependentSymbol`, the strcmp
misses, the `dlsym` fallback returns NULL (because `___dso_handle`
on Tiger is provided by the link-time `dylib1.o` / `crt1.o`, not
exported into the dyld namespace), and we get the error above.

**Fix shape** (~2 lines of C in `rts/Linker.c`):

```c
/* See Note [Resolving __dso_handle] */
if (strcmp(lbl, "__dso_handle") == 0 ||
    strcmp(lbl, "___dso_handle") == 0) {           /* Mach-O prefix */
    ...
}
```

Equivalent (slightly cleaner): teach `lookupDependentSymbol` to look
past one leading underscore on `OBJFORMAT_MACHO` before the strcmp.
Either form is a one-hunk patch.

**Why a one-line strcmp extension is the right fix:**

The Note's `__dso_handle` story is the same on ELF and Mach-O — the
loader hands the dependent object's image address back as a synthetic
handle.  The only thing that differs is the *spelling* of the symbol
at lookup time.  Adding the Mach-O-prefixed spelling preserves
upstream's semantics exactly and matches the existing comment.

**Release sketch (v0.14.2):**

- New patch `patches/0017-rts-dso-handle-mach-o-underscore.patch`.
- Stage1 rebuild — only `rts/Linker.c` changes, hadrian re-link is
  fast.
- Stage2 re-cross-build + deploy via `scripts/deploy-stage2.sh
  pmacg5` (same shape as v0.14.1 session 59).
- Bindist re-roll.
- Re-run session 60's runner to verify T9878b flips to PASS (target:
  165/166 with only the HFS+ mtime race remaining).
- Demo: pick a `static`-pointer / `-fobject-code` REPL one-liner.
- README + state.md + roadmap.md updates.

**Effort:** roughly the same shape as session 59 (v0.14.1).  Maybe
half — no testsuite re-debugging, no new harness work; just the
patch, the rebuild, and the re-roll.

**Priority:** medium.  Unlocks `-fobject-code` mode through GHCi
(which is a documented user-facing mode and a real surface for
`StaticPointers`), and would let us close out the last "true failure"
in the T-prefix subset (T17549 is the HFS+ mtime race, not a PPC
bug).  But it's not blocking any current user.

**Upstream contribution opportunity:**

The strcmp limitation also affects any Mach-O cross-GHC on a host
without a live dyld for the relevant symbol.  Worth proposing
upstream once the local patch is validated.  Same pattern as patch
0016 (the `STUArray Bool` granularity mismatch) — found locally,
applicable upstream.
