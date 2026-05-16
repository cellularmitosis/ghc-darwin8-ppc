# Session 59 commits

| SHA | Subject |
|---|---|
| `e95ee29` | v0.14.1: literate Haskell (unlit) packaging fix. |
| `f3161df` | Session 59 commits.md: backfill the v0.14.1 SHA. |
| `(this commit)` | Session 59 commits.md + docs: backfill the GitHub release URLs (replaces "deferred to user" language). |

`v0.14.1` annotated tag pointing at `e95ee29` — pushed to origin.

## Releases (live)

- **[v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0)** — retroactively pushed and released this session.  Tag had been local-only since 2026-05-15.  No bindist asset — v0.14.0's stage1 cross-build is byte-identical to v0.13.0's (the v0.14.0 change is entirely in `scripts/deploy-stage2.sh`'s manual `ghc/Main.hs` build line that enables `-DHAVE_INTERNAL_INTERPRETER`).  The release notes point users to v0.14.1 for the corrected bindist.
- **[v0.14.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1)** — committed + tagged + pushed + released this session.  Bindist tarball asset: `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz` (~211 MB), re-rolled with the corrected `unlit` (47 KB ppc Mach-O at `lib/bin/`, `bin/`, and `bin/*-ghc-9.2.8`).

## Release ritual recorded for future sessions

This is the standard end-to-end recipe — saved as feedback memory
"Handle release push and GitHub upload, don't defer" so future
sessions follow it without prompting:

```
git commit -m "vX.Y.Z: <one-line subject>." …
git tag -a vX.Y.Z -F <commit-message>
git push origin main
git push origin vX.Y.Z
gh release create vX.Y.Z \
  external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz \
  --title "vX.Y.Z — <emoji headline>" \
  --notes-file <release-notes>
```

## Stage2 native bindist (not shipped this release)

`ghc-9.2.8-stage2-native-ppc-darwin8.tar.xz` (which v0.13.0 shipped
as a secondary asset) was not regenerated for v0.14.1.  The deployed
stage2 on pmacg5 at `/opt/ghc-stage2/` reflects the v0.14.1
state and can be re-tarred from there if needed.
