# Session 55 commits

| SHA | Subject |
|---|---|
| `2fb956a` | v0.14.0: GHCi REPL on PPC/Tiger. |

## Files changed

No GHC source-tree changes.  No new patches.  Build-script + docs +
demo additions only.

### Build script

* [`scripts/deploy-stage2.sh`](../../../scripts/deploy-stage2.sh) —
  three additions to the `$STAGE1` invocation that compiles the
  stage2 native ghc:
  * `-DHAVE_INTERNAL_INTERPRETER` — the CPP gate `ghc/Main.hs`
    checks before pulling in `interactiveUI`.
  * `-i$GHC_SRC/ghc` — extends the module search path so `--make`
    discovers `GHCi.UI` / `GHCi.Leak` / etc. under `ghc/GHCi/`.
  * `-package exceptions -package time` — the new deps the
    `internal-interpreter` cabal block adds.  (`ghc-prim`, `ghci`,
    `haskeline`, `deepseq` were already pulled in transitively.)
  Plus a comment explaining what the change is mirroring from
  `ghc/ghc-bin.cabal`'s `if flag(internal-interpreter)` block.

### Demo

* [`demos/v0.14.0-ghci-repl.sh`](../../../demos/v0.14.0-ghci-repl.sh)
  — new file.  Exercises the REPL four ways: one-shot `ghc -e`;
  `ghc --interactive` with stdin (types, arithmetic, let, lambdas,
  imports, `Data.Map.Strict`); `:load` of a real Haskell module
  followed by calls to its functions; multi-line `:{ :}` block
  defining `collatz` and evaluating it.
* [`demos/README.md`](../../../demos/README.md) — header bumped to
  v0.14.0; new row for `v0.14.0-ghci-repl.sh`.

### Top-level README

* [`README.md`](../../../README.md):
  * Latest-release paragraph rewritten for v0.14.0 (GHCi REPL).
  * "GHCi REPL" row in the TemplateHaskell / external interpreter
    table flipped from ❌ Missing to ✅ Working with description.
  * New row in the Releases table for v0.14.0.

### Roadmap + state

* [`docs/roadmap.md`](../../roadmap.md) — §C heading expanded to
  note REPL done in session 55 / v0.14.0.  The "❌ GHCi REPL still
  blocked on stage2" paragraph reframed as historical, pointing at
  the new ✅ entry.  The "🟡 GHCi REPL — stage2 works as of v0.11.0,
  so an in-process REPL is now reachable" paragraph replaced with
  the v0.14.0 ✅ entry that describes the build change, what was
  verified, and links to the demo + this session.
* [`docs/state.md`](../../state.md) — new session-55 summary at the
  top of file (`Updated:` bumped from session 54 to session 55).
  Session-54 summary demoted to a `(Prior summary, session 54:)`
  block.

### Session-55 record (this dir)

* `docs/sessions/2026-05-15-session-55-ghci-repl-attempt/`
  * `README.md` — narrative + exit state.
  * `findings.md` — discovery write-up, cabal-flag explanation,
    why this took only one CPP flag.
  * `commits.md` — this file.
  * `HANDOFF.md` — primer for session 56.
  * `logs/`:
    * `stage2-build-attempt1.log` — first experimental
      cross-build with HAVE_INTERNAL_INTERPRETER.
    * `ghc-e-tests.log` — `ghc -e` smoke tests.
    * `ghci-load-module.log` — `--interactive` + `:load` smoke
      tests.
    * `deploy-stage2-with-ghci.log` — full re-deploy run.
    * `v0.14.0-demo-run.log` — full demo output.

## Notes

* Session 55 produced no GHC source changes and no new patches.
  Every load-bearing piece of the internal interpreter on PPC/Tiger
  was already in place (sessions 6, 9, 12, 12e, 12f for the runtime
  loader + iserv + BCO byte-swap; v0.13.0 / session 52 for the
  STUArray Bool fix that unblocked stage2 native compiles).  Session
  55 just flipped the CPP gate.
* Tagged as v0.14.0.
