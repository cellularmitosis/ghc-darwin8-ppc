# Session 2 commits

| SHA | Description |
|-----|-------------|
| cc47613 | install.sh: support running from inside the bindist tree. |
| (pending) | Session 2: scripts/install.sh end-to-end installer. + ppc-ld-tiger.sh path handling. |

Tags cut: `v0.3.0` ([release on GitHub](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.3.0), bindist SHA-256 `6a51bc80d3150baf2e5aaf39cbd03e5080b4c9c80c84205115d4b6ab0d17dc8a`).

Note: the initial install.sh landed in a single commit with the
ppc-ld-tiger.sh fix; the later fix (support running from inside the
bindist) landed in a follow-up.  Cleaner separation than session 1.
