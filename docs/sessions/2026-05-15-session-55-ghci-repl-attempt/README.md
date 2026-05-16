# Session 55 — GHCi REPL on PPC/Tiger (v0.14.0)

**Date:** 2026-05-15 (continuation of session 54).

**Status on arrival:** v0.13.0 shipped, stage2 native ghc on pmacg5
patched and verified.  Session 54 proved no upstream MR work to do
for the `STUArray Bool` bug (already fixed upstream in May 2023,
[`9cc80b5`](https://gitlab.haskell.org/ghc/packages/array/-/commit/9cc80b51cf98c13a140b00effb38329e7210d03c)).
Baseline 30 PASS / 4 FAIL_OUTPUT.  Session 54 HANDOFF flagged GHCi
REPL as the top priority — all the plumbing has been in place since
v0.8.0 (TemplateHaskell): runtime Mach-O loader, `iserv`,
`pgmi-shim.sh`.  The REPL itself was blocked on stage2 being usable,
which it now is post-v0.13.0.  See [roadmap §C](../../roadmap.md).

**Status on exit:** **GHCi REPL works on PPC/Tiger.**  Cut as
**v0.14.0**.  Build change is one-line-ish: `scripts/deploy-stage2.sh`
now compiles `ghc/Main.hs` with `-DHAVE_INTERNAL_INTERPRETER` (and
the `-i$GHC_SRC/ghc -package exceptions -package time` extras the
cabal flag would otherwise wire in).  No new patches — every other
load-bearing piece (runtime Mach-O loader 0009/0012, BCO byte-swap
0014, `__eprintf` stub 0011) was already there since v0.8.0.  Stage2
ghc-real binary grew ~5 MB (193 → 199 MB) for the additional GHCi.UI
/ GHCi.Leak / haskeline-driven REPL machinery.  Verified end-to-end
on pmacg5 four ways via `demos/v0.14.0-ghci-repl.sh`: `ghc -e`
one-shot expressions; `ghc --interactive` with stdin; `:load` of a
real Haskell module followed by calls to its functions; multi-line
`:{ :}` block defining `collatz` and evaluating it.  Roadmap §C
closes ✅.  **STATE CLEAN** — stage2 redeployed to pmacg5, smoke-test
PASS, baseline tests 30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (unchanged
— baseline is cross-compile, doesn't touch stage2).

## Plan (per session 54 HANDOFF)

1. Probe: `ghc --interactive` and `ghc -e "1+1"` on the existing
   v0.13.0 stage2 deploy, capture failure mode.
2. Read the build path that produces our stage2 native ghc
   (`scripts/deploy-stage2.sh`) and figure out what changes to enable
   the internal interpreter.
3. Rebuild stage2 with the internal interpreter enabled and try
   GHCi end-to-end.
4. If it works: deploy as the canonical stage2, write a demo, update
   docs, tag v0.14.0.

## What happened

### Step 1: probe on v0.13.0 stage2

```
$ ssh pmacg5 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \
              /opt/ghc-stage2/bin/ghc -e "1+1"'
<command line>: not built for interactive use
```

Canonical message from [`ghc/Main.hs:278`](../../../external/ghc-modern/ghc-9.2.8/ghc/Main.hs):

```haskell
ghciUI :: [(FilePath, Maybe Phase)] -> Maybe [String] -> Ghc ()
#if !defined(HAVE_INTERNAL_INTERPRETER)
ghciUI _ _ =
  throwGhcException (CmdLineError "not built for interactive use")
#else
ghciUI srcs maybe_expr = interactiveUI defaultGhciSettings srcs maybe_expr
#endif
```

So the gate is the CPP symbol `HAVE_INTERNAL_INTERPRETER`.

### Step 2: where the gate is set

Searching the source tree, the symbol is defined by ghc-bin.cabal's
`internal-interpreter` flag (default False, manually controlled):

```
Flag internal-interpreter
    Description: Build with internal interpreter support.
    Default: False
    Manual: True

Executable ghc
    ...
    if flag(internal-interpreter)
        Build-depends:
            deepseq        == 1.4.*,
            ghc-prim       >= 0.5.0 && < 0.9,
            ghci           == 9.2.8,
            haskeline      == 0.8.*,
            exceptions     == 0.10.*,
            time           >= 1.8 && < 1.12
        CPP-Options: -DHAVE_INTERNAL_INTERPRETER
        Other-Modules:
            GHCi.Leak
            GHCi.UI
            GHCi.UI.Info
            GHCi.UI.Monad
            GHCi.UI.Tags
            GHCi.Util
```

Hadrian sets it for stage1+ unconditionally
([`hadrian/src/Settings/Packages.hs:84`](../../../external/ghc-modern/ghc-9.2.8/hadrian/src/Settings/Packages.hs)):

```haskell
, package ghc ? mconcat
  [ ...
  , builder (Cabal Flags) ? mconcat
    [ andM [expr ghcWithInterpreter, notStage0] `cabalFlag` "internal-interpreter"
    , ...
```

**But our stage2 native ghc isn't built by hadrian.**  It's built by
`scripts/deploy-stage2.sh`, which manually invokes the cross-stage1
ghc to compile `ghc/Main.hs` plus `hschooks.c` into a single PPC
Mach-O binary.  That manual build bypasses the cabal flag entirely.

### Step 3: the build change

Pre-existing call:

```bash
"$STAGE1" \
  -package ghc -package ghci -package haskeline \
  -outputdir /tmp/stage2-build \
  -no-hs-main \
  -optc-DNON_POSIX_SOURCE \
  "$GHC_SRC/ghc/Main.hs" \
  "$GHC_SRC/ghc/hschooks.c" \
  -o /tmp/stage2-build/ghc-stage2
```

Three changes:

1. Add `-DHAVE_INTERNAL_INTERPRETER` (the CPP gate Main.hs checks).
2. Add `-i$GHC_SRC/ghc` so `--make` discovers the `GHCi.UI`
   et al modules under `ghc/GHCi/`.
3. Add `-package exceptions -package time` for the new deps
   (`deepseq`, `ghc-prim`, `ghci`, `haskeline` were already pulled in
   transitively via `-package ghc -package ghci -package haskeline`).

That's it.  The existing build command builds 1 module (Main); the
new one builds 7 (Main + the six GHCi.UI modules under `ghc/GHCi/`).

### Step 4: verification

First experimental build dropped a 198,755,052-byte ppc_7400 binary
(vs. v0.13.0's 193 MB stage2).  Deployed alongside the original as
`ghc-real-ghci`, smoke-tested:

```
=== ghc -e "1+1" ===
2
rc=0
```

Then four broader sanity tests, all PASS:
- `ghc -e "show (sum [1..100])"` → `"5050"`
- `ghc -e "Data.List.sort [3,1,4,1,5,9,2,6]"` → `[1,1,2,3,4,5,6,9]`
- `ghc -e "putStrLn ..."` → text on stdout
- `ghc -e "import qualified Data.Map.Strict as M" -e "M.toList ..."`
  → working multi-statement -e

Then `--interactive` with stdin (`echo ":t reverse" | ghc --interactive`):

```
GHCi, version 9.2.8: https://www.haskell.org/ghc/  :? for help
ghci> reverse :: [a] -> [a]
ghci> Leaving GHCi.
```

Then `:load` of a real module:

```
ghci> :load /tmp/Hello.hs
[1 of 1] Compiling Hello            ( /tmp/Hello.hs, interpreted )
Ok, one module loaded.
ghci> greet "tiger"
"hello, tiger!"
ghci> factorial 10
3628800
ghci> :t factorial
factorial :: Int -> Int
ghci> :q
Leaving GHCi.
```

Then `let`/lambdas/`map`, `:{ :}` multi-line definitions, imports,
`Data.Char.toUpper`, `pi :: Double`, `exp 1 :: Double` — all working
faithfully.  No panics, no wrong answers, no endian corruption, no
GC drama.  See [`logs/ghci-load-module.log`](logs/ghci-load-module.log)
and [`logs/ghc-e-tests.log`](logs/ghc-e-tests.log).

### Step 5: make it the canonical stage2

Rolled the experimental flags into `scripts/deploy-stage2.sh`,
re-ran the deploy script, smoke-tested again — all PASS.  The
deployed `ghc-real` is now the GHCi-enabled binary.

### Step 6: demo + docs

Wrote [`demos/v0.14.0-ghci-repl.sh`](../../../demos/v0.14.0-ghci-repl.sh):
exercises the REPL four ways (one-shot `ghc -e`; `--interactive`
with stdin including types + arithmetic + let + lambdas + imports;
`:load` a real module + call its functions; multi-line `:{ :}`
block defining `collatz`).  Demo output captured in
[`logs/v0.14.0-demo-run.log`](logs/v0.14.0-demo-run.log).

Updated:
- Top-level `README.md` — Latest-release paragraph + GHCi REPL row in
  the TemplateHaskell / external interpreter table (❌ → ✅) +
  Releases table row.
- `demos/README.md` — added v0.14.0 row, bumped header to v0.14.0.
- `docs/roadmap.md` §C — flipped the "🟡 GHCi REPL" subsection to
  "✅ Session 55 (v0.14.0)" with a description.  Heading expanded to
  note REPL done.
- `docs/state.md` — top-of-file Updated bumped to session 55 with
  the v0.14.0 summary; session 54 demoted.

## Why this was so easy

In hindsight: every load-bearing piece of the internal interpreter
on PPC/Tiger was wrestled into shape over sessions 6, 9, 12, 12e,
12f, 17–52.  v0.13.0 closed the last gating dep (stage2 compiling
real programs).  All session 55 had to do was flip a CPP flag.

The reason it was even worth trying right away was the session 54
HANDOFF's framing: "all the plumbing was done in v0.8.0 / session
12f for TemplateHaskell; the REPL itself has been blocked on stage2
being usable, which it now is post-v0.13.0."  Worth the half-hour.

## What this session did NOT do

* No new patches.  No GHC source-tree changes.
* No stage1 rebuild (only the manual stage2 build was rerun).
* No cabal-examples sweep.
* Nothing about session 54's "second priority" (refactor patch 0016
  to match upstream's smaller form) — moot for now.
* Nothing about session 54's "third priority" (audit other
  bit-packed instances in third-party libs) — still open.

## Files added / changed this session

* `README.md` (this), `findings.md`, `commits.md`, `HANDOFF.md`,
  `logs/`.
* `scripts/deploy-stage2.sh` — three-line addition to enable
  internal interpreter.
* `demos/v0.14.0-ghci-repl.sh` (new).
* `demos/README.md` — header bump + v0.14.0 row.
* `docs/roadmap.md` — §C heading + GHCi REPL subsection updated.
* `docs/state.md` — top-of-file new summary, session 54 demoted.
* `README.md` — Latest release paragraph + GHCi REPL status row +
  Releases table row.
