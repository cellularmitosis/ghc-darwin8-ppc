# Session 57 commits

One commit landed this session.

## [376147e](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/376147e) — Session 57: 83/83 PASS on curated GHCi debugger testsuite subset

Verification-only.  No GHC source-tree changes, no new patches, no
release tag.  Stage2 ghc-real on pmacg5 unchanged (still the v0.14.0
binary from session 55).

Changes:
- `docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/`
  — new session dir containing README.md, findings.md, HANDOFF.md,
  commits.md (this file), `scripts/run-ghci-debugger.sh`, symlinked
  `scripts/normalise.py`, and `logs/` (run-1 + run-2 + per-test
  artifacts).
- `docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/normalise.py`
  — added two upstream `testlib.py:normalise_errmsg` rules:
  `...plus N instances involving out-of-scope types` count erasure
  (line 2261), and `ghc-bignum-X.Y.Z` → `ghc-bignum-<VERSION>`
  (line 2256).  Pure additions; session 56's run-2 51/51 PASS is
  preserved (neither rule applies to session-56-era expected files).
- `README.md` — added GHCi-debugger row to the "GHCi /
  TemplateHaskell" implementation-status table.
- `docs/state.md` — top-of-file paragraph for session 57; prior
  session-56 paragraph demoted.
- `docs/roadmap.md` — last-reviewed date bumped; §C gained a "Session
  57 (verification)" subsection.
