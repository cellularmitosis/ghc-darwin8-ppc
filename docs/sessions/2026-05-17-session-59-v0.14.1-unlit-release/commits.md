# Session 59 commits

| SHA | Subject |
|---|---|
| `e95ee29` | v0.14.1: literate Haskell (unlit) packaging fix. |

`v0.14.1` annotated tag pointing at `e95ee29` (local-only, not
pushed).

## Release artifacts (ready locally, not yet uploaded)

- Tag: `v0.14.1` (on the above commit, **local-only**).
- Bindist: `external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`
  — re-rolled stage1 cross-build with the corrected `unlit` (47 KB
  ppc Mach-O at `lib/bin/powerpc-apple-darwin8-unlit`).  Verified
  via `tar tvJf ... | grep unlit` + extract + `file` (expected:
  `Mach-O executable ppc`).
- Stage2 native bindist: `ghc-9.2.8-stage2-native-ppc-darwin8.tar.xz`
  — same artifacts as `/opt/ghc-stage2/` on pmacg5 after session 59's
  `scripts/deploy-stage2.sh`.  Not regenerated as a tarball this
  session; matches the v0.13.0/v0.14.0 stage2 layout 1:1 except for
  the new ppc `unlit` under `lib/bin/`.

## GitHub release path (user-owned)

Both v0.14.0 and v0.14.1 are local-only tags at session-59 exit.
The latest GitHub release on the repo is v0.13.0.  When the user
is ready to ship:

```
git push origin v0.14.0 v0.14.1      # push both tags
gh release create v0.14.0 \
  external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz \
  --title "v0.14.0 — GHCi REPL on PPC/Tiger 🎉" \
  --notes-file <release-notes>
gh release create v0.14.1 \
  external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz \
  --title "v0.14.1 — Literate Haskell (unlit) packaging fix 📜" \
  --notes-file <release-notes>
```

(Both releases would point at the same bindist tarball, since
v0.14.0's bindist is the broken one — v0.14.1's bindist is the
fixed-and-superseding artifact.  Alternative: ship only v0.14.1
on GitHub, since v0.14.0's bindist had the packaging bug and
v0.14.1 supersedes it; the v0.14.0 tag stays in git history for
provenance.)
