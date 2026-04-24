# Experiment 006: PPC-native GHC binary on Tiger — stage2 bootstrap

Date: 2026-04-24.

## Outcome

**PPC-native `ghc` binary built, runs on Tiger, identifies itself:**

```
$ ssh pmacg5 '/tmp/ghc-tiger-install/bin/ghc --version'
The Glorious Glasgow Haskell Compilation System, version 9.2.8
```

Binary: 128 MB Mach-O `ppc_7400` executable, linked by gcc14's ld on pmacg5.

**But it cannot currently *compile* user code successfully** — hits a GHC panic in `StgToCmm.Env` when generating code:

```
$ /tmp/ghc-tiger-install/bin/ghc -c /tmp/NoMain.hs
ghc: panic! (the 'impossible' happened)
  GHC version 9.2.8: GHC.StgToCmm.Env: variable not found
  $trModule3_rwD
```

And for executables, a type-checker inconsistency:

```
GHC internal error: `main' is not in scope during type checking,
                     but it passed the renamer
```

So stage2 native ghc is a **runs-but-not-useful** milestone.  The practical Tiger-Haskell path remains the uranium cross-build (experiment 005).

## What we built

Manual cross-bootstrap of the `ghc-bin` executable:

```
powerpc-apple-darwin8-ghc \
  -package ghc -package ghci -package haskeline \
  -Ighc -ighc/stage1 \
  -no-hs-main \
  -optc-DNON_POSIX_SOURCE \
  ghc/Main.hs ghc/hschooks.c \
  -o /tmp/ghc-stage2-ppc
```

Hadrian's `binary-dist-dir` for a cross-compile just copies the Stage0 host GHC binary into Stage1/bin as a placeholder — it does not cross-compile the compiler itself to the target.  So we invoked the cross-compiler on `ghc/Main.hs` ourselves.

`-no-hs-main` is needed because `ghc/hschooks.c` provides its own `int main` that calls `hs_main(argc, argv, &ZCMain_main_closure, conf)`.

## Fixes made along the way

* **`_lutimes` undefined** — Tiger's libSystem lacks lutimes (added in Leopard).  Our config had `ac_cv_func_lutimes=yes` wrongly.  Fix: set to `no`, then force-regenerate unix's hsc-derived `.hs` files (deleting only `.o`/`.hi` isn't enough since hsc2hs outputs are cached).

* **`_relocateSection` undefined** — the runtime Mach-O loader in `rts/linker/MachO.c` only defines `relocateSection` for `x86_64_HOST_ARCH`.  For PPC we stub it out to fail at runtime rather than at link time.  Static compile doesn't touch this.  Restoring the pre-2018 PPC Mach-O runtime loader is future work.

* **`_ZCMain_main_closure` undefined at executable link** — `hschooks.c` has its own `main`; we pass `-no-hs-main`.

* **Tiger native install settings patches** — GHC's `lib/settings` ships absolute paths from uranium (`/Users/cell/.local/...`).  Rewritten to point at `/opt/gcc14/bin/gcc`, `/opt/gcc14/bin/ld`, etc., for Tiger.  Also strip `--target=powerpc-apple-darwin` (native gcc doesn't need it), flip `cross compiling` to `NO`, add `-L/opt/gmp-6.2.1/lib -liconv` to C compiler link flags.

* **`-lmingwex`** — `rts/package.conf.in` has `extra-libraries: m dl mingwex`; the `mingwex` is Windows-only.  Stripped from the runtime package config.

## The remaining panic

`StgToCmm.Env: variable not found $trModule3_rwD` is GHC's internal panic when StgToCmm tries to look up a binding in the local environment but it's not there.  The `$tr` prefix indicates a Typeable-generated binding.

Plausible root causes (none verified):
1. Stage mismatch — our `ghc-bin` executable is ghc/Main.hs compiled by the STAGE=1 cross-ghc (which targets unregisterised PPC), but the GHC library internals `libHSghc-9.2.8.a` may expect STAGE=2 invariants somewhere.
2. Unregisterised ABI hiccup — the MINIINTERPRETER mode of unregisterised GHC has a different calling convention than the NCG/LLVM path; internal Typeable references may get emitted differently.
3. Actual GHC bug specific to PPC/Darwin that was last fixed before 2018 and lost with the port removal.

Investigating would mean either:
* Running stage2 ghc under gdb on pmacg5 and tracing where `$trModule3_rwD` goes missing.
* Comparing the Stage2 libs compiled by stage1 (this run) vs Stage2 libs compiled by a *Stage2* ghc (which requires a working Stage2 ghc — chicken and egg).
* Bisecting GHC history to find where PPC lost its Typeable code path.

Deferred.  The cross-build from uranium is fully functional, so users have a path to running Haskell on Tiger today.

## Follow-up investigation (same day)

Ran `ghc -dno-typeable-binds -c foo.hs` on the native stage2 ghc — **this bypass works**.  Typeable-free code compiles: `NoMain.hs` (a module with no main, just `addOne :: Int -> Int`) produced a 152-byte .o file successfully.

But for Main modules:
- `-c hello.hs` still fails: **"GHC internal error: 'main' is not in scope during type checking"** in `tcLookupId main_name` inside `generateMainBinding`.
- `--make hello.hs` suppresses the error (gets printed once) but produces an empty `hello.o` that doesn't contain `_Main_main_closure`.
- Link then fails on `_ZCMain_main_closure` because the `:Main` synthesis module is never written.

So the defect narrows:
1. Typeable binding codegen is broken on stage2 (workaround: `-dno-typeable-binds`).
2. `:Main.main = runMainIO Main.main` synthesis is also broken — `tcLookupId` returns empty tcl_env for the main Name.

Both point at the typechecker's local environment being empty when it shouldn't be.  Theory: stage2's internal state machinery (something the `ghc` library sets up in `runGhc`/`initDynFlags`/`loadInterfaceEnv`) isn't wiring up properly when the library was cross-compiled to PPC.

Leaving the deep dive for a future session.
