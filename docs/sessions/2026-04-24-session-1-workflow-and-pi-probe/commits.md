# Session 1 commits

| SHA | Description |
|-----|-------------|
| 474c2d7 | Session 1: workflow migration + pi-Double codegen fix. |

Tags cut: `v0.2.0` ([release on GitHub](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.2.0), bindist SHA-256 `2abdd179bca1f36af5a20416c6068ae5459876fd6db16a8ec888bd4d4e98170f`).

The single commit bundles two logically-independent changes.  Pragmatic
choice — the workflow migration churns a lot of files (renames +
deletes) and splitting it off from the pi fix would have produced two
commits both with ~20 file changes each and a messy chronology.
Future sessions should try harder to land atomic commits.
