# Session 55 findings

## TL;DR

The GHCi REPL on PPC/Tiger needed exactly one CPP flag and two
extra cabal-equivalent build args.  No new patches, no source
changes, no debugging.  Every load-bearing piece had been built
across sessions 6/9/12/12f/17–52 already; session 55 just turned
the key.

## Where the gate lives

`ghc/Main.hs` line 276:

```haskell
ghciUI :: [(FilePath, Maybe Phase)] -> Maybe [String] -> Ghc ()
#if !defined(HAVE_INTERNAL_INTERPRETER)
ghciUI _ _ =
  throwGhcException (CmdLineError "not built for interactive use")
#else
ghciUI srcs maybe_expr = interactiveUI defaultGhciSettings srcs maybe_expr
#endif
```

So a stage2 ghc that prints "not built for interactive use" simply
hasn't been compiled with `-DHAVE_INTERNAL_INTERPRETER`.

## How upstream wires this

`ghc/ghc-bin.cabal`:

```
Flag internal-interpreter
    Description: Build with internal interpreter support.
    Default: False
    Manual: True

Executable ghc
    if flag(internal-interpreter)
        Build-depends:
            deepseq, ghc-prim, ghci, haskeline, exceptions, time
        CPP-Options: -DHAVE_INTERNAL_INTERPRETER
        Other-Modules:
            GHCi.Leak, GHCi.UI, GHCi.UI.Info,
            GHCi.UI.Monad, GHCi.UI.Tags, GHCi.Util
```

Hadrian flips this on for stage1+ unconditionally
(`hadrian/src/Settings/Packages.hs:84`):

```haskell
[ andM [expr ghcWithInterpreter, notStage0] `cabalFlag` "internal-interpreter"
, ... ]
```

## Why our stage2 didn't have it

The cross-built stage2 native ghc doesn't go through hadrian (or
cabal).  `scripts/deploy-stage2.sh` invokes the cross-stage1
manually:

```
$STAGE1 -package ghc -package ghci -package haskeline \
        -outputdir /tmp/stage2-build \
        -no-hs-main \
        -optc-DNON_POSIX_SOURCE \
        $GHC_SRC/ghc/Main.hs $GHC_SRC/ghc/hschooks.c \
        -o /tmp/stage2-build/ghc-stage2
```

That bypasses ghc-bin.cabal entirely — the `internal-interpreter`
flag is never consulted.

## The fix

Three additions:

1. `-DHAVE_INTERNAL_INTERPRETER` — define the CPP gate that Main.hs
   checks.
2. `-i$GHC_SRC/ghc` — extend the module search path so `--make` can
   discover `ghc/GHCi/UI.hs` et al.  Without this, `import GHCi.UI`
   in Main.hs would fail to resolve.
3. `-package exceptions -package time` — the new deps the
   `internal-interpreter` cabal block adds.  `ghc-prim`, `ghci`,
   `haskeline`, `deepseq` were already pulled in transitively via
   the existing `-package ghc -package ghci -package haskeline`.

Build cost: stage2 binary grew from 193,188,704 → 198,755,052 bytes
(~5.5 MB, +2.9%).  Compile-time grew from 1 module → 7 modules.
Negligible.

## What the REPL exercises that wasn't already exercised

GHCi's internal interpreter sits on top of:

| Mechanism | Already verified by | Still gating |
|---|---|---|
| Runtime Mach-O loader (`loadObj`/`resolveObjs`/`lookupSymbol`) | v0.6.0 + v0.6.1 + v0.7.2 (loads `base.o`) | — |
| BCO bytecode interpretation, byte-swap on host/target endian mismatch | v0.8.0 (TH splice) | — |
| `-pgmi=` external-interpreter pipe protocol | v0.8.0 (TH splice via iserv) | _(not used by REPL — REPL uses internal interpreter)_ |
| `__eprintf` symbol resolution for ghc-bignum | v0.7.1 | — |
| BR24 jump-island placement for multi-MB `.o`s | v0.7.2 | — |
| Stage2 compiles real programs without `-A1G` | v0.13.0 | — |
| Internal interpreter's `interactiveUI` driver, prompt parsing, `:t`/`:load`/etc dispatch | _none — REPL was never enabled_ | this session |
| haskeline-driven line editing on Tiger | _none_ | implicitly verified by `--interactive` accepting stdin |

So the REPL test is mostly an integration check that all these
pieces compose end-to-end.  No surprises in the composition.

## What worked first try

Every test landed first attempt:

- `ghc -e "1+1"` → `2`
- `ghc -e "show (sum [1..100])"` → `"5050"`
- `ghc -e "Data.List.sort [3,1,4,1,5,9,2,6]"` → `[1,1,2,3,4,5,6,9]`
- `ghc -e "putStrLn \"...\""` → text on stdout
- Multi-`-e`: `import Data.Map.Strict; M.toList ...` → working
- `--interactive` welcome banner + prompt
- `:t reverse` → `reverse :: [a] -> [a]`
- `:load Hello.hs` → `Compiling Hello (interpreted) / Ok, one module loaded.`
- `greet "tiger"` (defined in Hello.hs) → `"hello, tiger!"`
- `factorial 10` → `3628800`
- `factorial 20` → `2432902008176640000` (Integer, exercises bignum)
- `:t factorial`, `:t fib` — type queries on user-defined symbols
- `let f = \x -> x*x + 1; map f [1..5]` → `[2,5,10,17,26]`
- `take 12 (iterate (*2) 1)` → `[1,2,...,2048]`
- `import Data.Char; map toUpper "tiger"` → `"TIGER"`
- `pi :: Double` → `3.141592653589793`
- `exp 1 :: Double` → `2.718281828459045`
- `(2 ** 32) :: Double` → `4.294967296e9`
- `:{ ... :}` multi-line block defining `fib` recursively → maps over `[0..10]`
- `:{ ... :}` defining `collatz` (lazy `[Int]` building) → `length`,
  `maximum`, `take 10` all evaluated correctly

Zero failures.  No GC drama on stage2 (the v0.13.0 Bool-bug fix
is doing its job).

## Why TH never required this same flip

TH uses the **external** interpreter (a separately-spawned
`ghc-iserv` process talking to host-ghc over pipes via
`pgmi-shim.sh`).  External interpreter doesn't go through
`ghciUI` / `interactiveUI` at all — it goes through
`GHC.Tc.Gen.Splice`'s pipe-message protocol.  Different code path,
different gate (`Opt_ExternalInterpreter`), no
`HAVE_INTERNAL_INTERPRETER` required.

The internal interpreter is what powers `ghc -e` and
`ghc --interactive` (i.e. the REPL prompt).  Different code path
from TH, but reuses the same runtime linker + BCO machinery
underneath.

## Open follow-ups (not done this session)

1. **Run actual GHCi tests from upstream's testsuite.**  Unblocked
   now; could expose corner cases (especially anything bytecode-only
   that doesn't go via the runtime linker).
2. **Refactor patch 0016 to upstream's smaller form** — still on the
   session 54 HANDOFF list; cosmetic, defer.
3. **Audit `vector` / `bytestring` / `data-array-byte` for the
   `setByteArray# nbytes` + `readWordArray#` granularity-mismatch
   anti-pattern** — also on session 54 HANDOFF list; still open.
4. **Stage2 native-compile sweep.**  The cabal-examples sweep
   exercises stage1 cross-compile.  A stage2 native sweep would
   cross-stress the in-process linker / interpreter further.
   Modest interest.
5. **Try `ghci` *interactively* over a real ssh tty** (vs piped
   stdin like our smoke tests).  Would exercise haskeline's terminal
   handling on Tiger.  Should "just work"; defer until someone has
   a reason to need it.
