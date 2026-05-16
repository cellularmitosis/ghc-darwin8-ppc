# Session 61 — Release v0.14.2: `__dso_handle` Mach-O underscore fix shipped

**Date:** 2026-05-17 (continuation of session 60).

**Status on arrival:** Session 60 extended the ghci-tnum runner with
`extra_run_opts(...)` support and surfaced a real PPC/Tiger bug
through T9878b: `rts/Linker.c::lookupDependentSymbol`'s
`__dso_handle` special case strcmp'd against the ELF spelling
(`"__dso_handle"`) but the Mach-O loader passes the underscore-
prefixed form (`"___dso_handle"`) straight from the object's
string table.  Miss → returns NULL → resolveImports fails →
`-fobject-code` `:l Foo.hs` with any `static` pointer aborts with
`unknown symbol \`___dso_handle'`.  Session 60 filed
[`docs/proposals/rts-dso-handle-mach-o.md`](../../proposals/rts-dso-handle-mach-o.md)
with a v0.14.2 release sketch.  Session 60 HANDOFF's #1
recommendation: execute that sketch.  164/166 PASS on the v0.14.1
bindist.

**Status on exit:** **v0.14.2 released**.  Tag pushed; bindist
tarball (~211 MB) uploaded to the [v0.14.2 GitHub
release](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2).
Demo committed at
[`demos/v0.14.2-static-pointers.{hs,sh}`](../../../demos/).  README
"Latest release" line bumped, GHCi REPL row's "pending v0.14.2"
note converted to ✅ in-bindist, new row in the Releases table.
[`docs/state.md`](../../state.md) and [`docs/roadmap.md`](../../roadmap.md)
updated.  Session-60 runner re-ran clean against the new bindist:
**165/166 PASS** (T9878b ✅; only T17549 remains — the HFS+ 1-second
mtime-granularity race in upstream's `:reload` script, not a PPC
bug).

## What was done

### 1. Source edit + patch 0017

[`rts/Linker.c::lookupDependentSymbol`](../../../external/ghc-modern/ghc-9.2.8/rts/Linker.c)
amended so the `__dso_handle` special case matches both the ELF and
Mach-O spellings:

```c
/* See Note [Resolving __dso_handle] */
-   if (strcmp(lbl, "__dso_handle") == 0) {
+   if (strcmp(lbl, "__dso_handle") == 0 ||
+       strcmp(lbl, "___dso_handle") == 0) { /* Mach-O underscore prefix */
        if (dependent) {
            return dependent->image;
        } else {
            return &lookupDependentSymbol;
        }
    }
```

Plus a four-line update to `Note [Resolving __dso_handle]` documenting
why both spellings are matched.  Six-line patch total
([patches/0017-rts-dso-handle-mach-o-underscore.patch](../../../patches/0017-rts-dso-handle-mach-o-underscore.patch)).

The proposal's "Equivalent (slightly cleaner): teach
`lookupDependentSymbol` to look past one leading underscore on
`OBJFORMAT_MACHO` before the strcmp" form was considered.  Went
with the OR variant because (a) it's unconditional / no `#if`
needed, (b) it matches the existing file style of multiple
`strcmp(..., "_FOO") == 0 ||` checks, (c) it works for any future
Mach-O variant that ever drops the underscore prefix.  Both forms
are one-hunk equivalents.

### 2. Stage1 rebuild

```bash
source scripts/cross-env.sh
GHC=$HOME/.local/ghc-9.2.8/bin/ghc \
  ./hadrian/build --flavour=quick-cross --docs=none -j8 \
  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a
```

Total: **3.44 sec** (`Linker.c` recompiled, all 10 RTS ways
re-ar'd / re-ranlib'd, package re-registered).  Verified the new
`Linker.o` contains both spellings:

```
$ strings _build/stage1/rts/build/c/Linker.o | grep dso_handle
__dso_handle
___dso_handle
```

Full log at [`logs/01-stage1-rebuild.log`](logs/01-stage1-rebuild.log).

Note on `GHC=...`: the bare `./hadrian/build` invocation defaults
`$GHC` to whatever `ghc` resolves to in `cabal --with-compiler`'s
resolution, which on this machine picks up homebrew's ghc-9.14 and
fails to resolve hadrian's deps against base-4.22.  Setting `GHC`
to the full 9.2.8 path is the load-bearing detail.  Recorded as a
session 61 finding.

### 3. Stage2 re-cross-build + deploy

`scripts/deploy-stage2.sh pmacg5` — cross-compiles `ghc/Main.hs`
via the patched stage1, rsyncs the updated `_build/stage1/lib/` to
`/opt/ghc-stage2/lib/`, smoke-tests.  Log at
[`logs/02-deploy-stage2.log`](logs/02-deploy-stage2.log).

```
==> [5/5] smoke-test on pmacg5
The Glorious Glasgow Haskell Compilation System, version 9.2.8
stage2 native ghc on Tiger: ok
```

Verified the deployed `ghc-real` has both spellings in its
compiled-in Linker.c text segment:

```
$ ssh pmacg5 'strings /opt/ghc-stage2/bin/ghc-real | grep dso_handle'
___dso_handle
__dso_handle
```

### 4. Verification — session 60 runner

Copied session 60's `run-ghci-tnum.sh` + `normalise.py` into
`scripts/` and re-ran against the new stage2:

```
=== Summary: 165 PASS / 1 FAIL out of 166 tests ===
Failed: T17549
```

T9878b flipped to PASS ✅ (the deterministic failure from session
60).  T17549 is the same HFS+ 1-second mtime-granularity race
diagnosed in [session 58
findings](../2026-05-17-session-58-ghci-tnum-scripts/findings.md)
— not a PPC bug.  Full log at
[`logs/03-ghci-tnum-rerun.log`](logs/03-ghci-tnum-rerun.log).

### 5. Demo

[`demos/v0.14.2-static-pointers.hs`](../../../demos/v0.14.2-static-pointers.hs)
— a module that imports `GHC.StaticPtr` and defines four `static`
pointers of different shapes:

```haskell
staticTrue     :: StaticPtr Bool                  -- value
staticGreeting :: StaticPtr String                -- value
staticDouble   :: StaticPtr (Int -> Int)          -- closure
staticSum      :: StaticPtr ([Int] -> Int)        -- closure
```

`main` calls `deRefStaticPtr` on each and prints the result.

[`demos/v0.14.2-static-pointers.sh`](../../../demos/v0.14.2-static-pointers.sh)
is the driver.  Four steps:

0. Greps the deployed `ghc-real` for both spellings of `dso_handle`
   — proves the fix is compiled in.
1. scps the `.hs` to pmacg5.
2. Native compile + run on Tiger — prints all four `deRefStaticPtr`
   results.  (This path works on any release that ships
   StaticPointers, but is included for completeness.)
3. `:load`s the module into `ghc --interactive -fobject-code` — the
   load path that was broken pre-v0.14.2 — and exercises
   `deRefStaticPtr` on each pointer via `:m + GHC.StaticPtr` for
   REPL scope.

Log at [`logs/04-demo-run.log`](logs/04-demo-run.log).  Demo runs
end-to-end cleanly.

### 6. Bindist re-roll

`./hadrian/build --flavour=quick-cross --docs=none -j8 binary-dist-dir`
(log at [`logs/05-hadrian-bindist.log`](logs/05-hadrian-bindist.log))
— rebuilt the bindist tree from scratch in **3m09s**.  Most of the
time was profiling-way rebuilds of Cabal and its transitive
dependents (same shape as the v0.14.1 re-roll in [session 59
README](../2026-05-17-session-59-v0.14.1-unlit-release/README.md)).

Pre-tar sanity check:

```
$ ar x bindist/lib/.../libHSrts-1.0.2.a Linker.o && strings Linker.o | grep dso_handle
__dso_handle
___dso_handle
```

The shipped `libHSrts-1.0.2.a`'s `Linker.o` contains both spellings.

Tarred with `XZ_OPT="-T0 -6" tar -cJf …`:

```
_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz  211 MB
```

(Same size as v0.14.1's tarball; the change is a single object file.)

### 7. README, state.md, roadmap.md, demos/README.md

- **README:** Latest-release paragraph rewritten (v0.14.1 → v0.14.2);
  GHCi REPL status row's "pending v0.14.2 release sketch" note
  converted to ✅-in-bindist; new row in the Releases table; Layout
  bullet updated 16 → 17 patches.
- **`docs/state.md`:** top entry bumped to session 61.
- **`docs/roadmap.md`:** §C session 61 entry added; last-reviewed
  date bumped.
- **`demos/README.md`:** "What's here" header bumped to v0.14.2; new
  row in the per-release table.

### 8. Commit + tag + push + release

(See [`commits.md`](commits.md) for the SHA and the exact commands
used.)

```
git tag -a v0.14.2 -F <commit-message>
git push origin main
git push origin v0.14.2
gh release create v0.14.2 \
  external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz \
  --title "v0.14.2 — StaticPointers + GHCi -fobject-code work on Tiger 🪄" \
  --notes-file <release-notes>
```

## What this means

v0.14.2 closes the last deterministic failure in session 60's
166-test T-prefix subset.  The fix is upstream-shaped: any Mach-O
cross-GHC where the host doesn't have a live `dyld` exporting
`___dso_handle` (which is the normal Mach-O state — the symbol is
provided at link time by `dylib1.o`/`crt1.o`, not at run time)
would have hit the same bug.  It's been latent in `lookupDependentSymbol`
since upstream commit `#20493` added the special case for ELF.

Worth proposing upstream once the local patch settles.  Same
pattern as patch 0016 — found locally on PPC/Darwin, applicable to
any platform with Mach-O symbol-name conventions.

## Files added this session

* `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.
* `scripts/run-ghci-tnum.sh`, `scripts/normalise.py` — byte-identical
  copies of session 60's runner artefacts.  Unchanged this session
  (the runner was the verification harness, not the change-under-test).
* `logs/01-stage1-rebuild.log` — git diff of `rts/Linker.c` + the
  rebuilt `Linker.o`'s `strings` output showing both spellings.
* `logs/02-deploy-stage2.log` — `deploy-stage2.sh pmacg5` output.
* `logs/03-ghci-tnum-rerun.log` — full PASS/FAIL log (165/166).
* `logs/04-demo-run.log` — the v0.14.2 demo running end-to-end on pmacg5.
* `logs/05-hadrian-bindist.log` — bindist re-roll output.
* `patches/0017-rts-dso-handle-mach-o-underscore.patch` — the patch.
* `external/ghc-modern/ghc-9.2.8/rts/Linker.c` — the corresponding
  live-source change.
* `demos/v0.14.2-static-pointers.hs` — the `static`-pointer module.
* `demos/v0.14.2-static-pointers.sh` — the driver.
* `README.md` — Latest-release paragraph + GHCi REPL row + Releases
  table + Layout patches-count all updated.
* `docs/state.md` — top-of-file summary bumped to session 61.
* `docs/roadmap.md` — §C session 61 / v0.14.2 row added.
* `demos/README.md` — v0.14.2 row added; "What's here" header bumped.

## On pmacg5

After `deploy-stage2.sh pmacg5`:

- `/opt/ghc-stage2/bin/ghc-real` — rebuilt; same ~199 MB size as
  v0.14.1.  Its compiled-in `rts/Linker.c` text segment now contains
  both `__dso_handle` and `___dso_handle` strings.
- `/opt/ghc-stage2/lib/` — rsynced with `--delete`; new `Linker.o`
  baked into all 10 RTS-way archives in `lib/ppc-osx-ghc-9.2.8/rts-1.0.2/`.

## What's next

See `HANDOFF.md`.
