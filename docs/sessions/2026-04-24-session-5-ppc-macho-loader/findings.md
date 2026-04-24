# Session 5 findings

## 1. Our current state is carefully scaffolded

Patch 0004 already restores `ocAllocateExtras_MachO` for PPC —
the pre-2018 "count unique UNDEF externals, reserve one jump-island
slot per symbol" policy.  This is the FRAMEWORK that
`relocateSection_PPC` would plug into via `makeSymbolExtra`.

So when we implement the loader, we don't need to touch extras-
allocation; just the dispatch.

## 2. Our stub is clean

`ocResolve_MachO`'s PPC arm prints an error and returns 0 on entry.
No side effects.  We can replace the stub with real code without
worrying about undo.

## 3. Estimated work (for the next implementor)

Measured in days, not hours, even assuming the old code extracts cleanly:

- 0.5 day: git archaeology, extract `relocateSection_PPC` + helpers
  from pre-374e44704b source.
- 0.5 day: adapt to current `ObjectCode` / `Section` / `MachOSection`
  structs and macros.
- 0.5 day: build + fix compilation errors.
- 1 day: write C driver, test loading a trivial .o on pmacg5.
- 1 day: debug reloc-by-reloc when the first non-trivial .o breaks.
- Bonus days: bigger .o files, `.a` archives, cross-section refs,
  jump-island invocation.

So realistically 1–2 weeks of focused work to get GHCi usable.

## 4. Prereq dependency

The GHCi use case also needs a working ppc-native `ghc` executable
(stage2), which is currently blocked by the `tcl_env` empty bug
(roadmap B).  So even after restoring the runtime loader, TH splices
won't run until stage2 also works.

Workaround path: test the loader in isolation with a C driver,
confirm it loads .o's correctly, and defer the GHCi integration
until stage2 is fixed.

## 5. No code changed this session

Pure scoping.  Battery stays at 30/34 PASS.
