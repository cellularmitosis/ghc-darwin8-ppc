# Session 61 commits

| SHA | Subject |
|---|---|
| `d09c4ba` | v0.14.2: rts/Linker.c match Mach-O ___dso_handle spelling. |
| `(this commit)` | Session 61 commits.md: backfill the v0.14.2 SHA. |

`v0.14.2` annotated tag pointing at the session-61 commit — pushed
to origin.

## Releases (live)

- **[v0.14.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2)**
  — committed + tagged + pushed + released this session.  Bindist
  tarball asset: `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`
  (~211 MB), re-rolled from the patched stage1.  The shipped
  `lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`'s `Linker.o`
  contains both `__dso_handle` and `___dso_handle` strings.

## Release recipe (recorded in session 59 for reference)

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
as a secondary asset) was not regenerated for v0.14.2.  The
deployed stage2 on pmacg5 at `/opt/ghc-stage2/` reflects the
v0.14.2 state and can be re-tarred from there if needed.
