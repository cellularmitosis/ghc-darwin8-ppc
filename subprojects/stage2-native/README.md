# stage2-native

Status: ⏸ deferred (2026-04-24).  128 MB ppc-native `ghc` binary
built and runs `--version` on Tiger; compile pipeline has runtime bug.

Full investigation: [docs/experiments/006-stage2-native-ghc.md](../../docs/experiments/006-stage2-native-ghc.md).

The short version: our ppc-native `ghc` binary's typechecker's
`tcl_env` is empty when it tries to look up `main`.  `-dno-typeable-binds`
works around the Typeable-codegen panic, but the `:Main.main` synthesis
breaks separately on the same underlying issue.

Bug class smells like "stage2 mutable-state wiring is broken" — likely
something in `HscEnv` / `DynFlags` ref cells that didn't cross the
cross-build correctly.  Next step is gdb on pmacg5 or a careful
comparison with a known-good stage2, neither of which is cheap.

Deferred in favour of [bug-pi-double-literal](../bug-pi-double-literal/)
and [bindist-installer](../bindist-installer/) for now.
