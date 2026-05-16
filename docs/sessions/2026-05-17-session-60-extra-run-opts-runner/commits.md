# Session 60 commits

One commit, harness-only.  No GHC source-tree edits, no patches/,
no release tag.

| SHA | Message |
| --- | --- |
| [aa02c20](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/aa02c20) | Session 60: extend ghci-tnum runner with `extra_run_opts(...)` support; 164/166 PASS; T9878b surfaces __dso_handle Mach-O bug. |

## Files in this commit

- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/README.md`
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/findings.md`
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md`
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/commits.md` (this file)
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/run-ghci-tnum.sh`
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/normalise.py`
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/00-runner-diff.log`
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/01-run1.log`
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/02-T9878b-stderr.log`
- `docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/ghci-tnum/...`
  (per-test captured outputs, ~166 small dirs)
- `docs/proposals/rts-dso-handle-mach-o.md`
- `docs/state.md` — top entry bumped to session 60.
- `docs/roadmap.md` — §C session 60 entry added.
- `README.md` — Implementation-status note about T9878b finding.
