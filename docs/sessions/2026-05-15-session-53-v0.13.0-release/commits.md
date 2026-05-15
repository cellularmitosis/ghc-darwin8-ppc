# Session 53 commits

| SHA | Subject |
|---|---|
| `cf1639f` | v0.13.0: ship the STUArray Bool big-endian fix. |

`v0.13.0` tagged at `cf1639f`.

GitHub release: https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.13.0

Assets:
- `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz` (~213 MB) — stage1 cross-build bindist, with patch 0016 applied to the bundled array library and to every library that hadrian rebuilt as a transitive dependency (array, binary, containers, deepseq, exceptions, ghc, ghc-boot, ghc-heap, ghci, hpc, stm, parsec, libiserv, text, haskeline).  Other libraries (Cabal, megaparsec, etc.) weren't touched by hadrian and ship byte-identical to v0.12.0.
- `ghc-9.2.8-stage2-native-ppc-darwin8.tar.xz` (~14.1 MB) — stage2 PPC-native ghc + wrapper, deployable to `/opt/ghc-stage2/`.  Wrapper no longer needs `+RTS -A1G -RTS`.

## Files changed

- `patches/0016-array-stuarray-bool-word-aligned-init.patch` — already
  landed in session 52, ships as part of v0.13.0.
- `README.md` — Latest release flipped to v0.13.0; Stage2 native ghc
  row 🟡 → ✅; new row added to the Releases table; patch count
  updated 12 → 16.
- `docs/state.md` — new session 52 summary at the top; "Stage2
  native ghc" section reframed from "works with workaround" to
  "fully working".
- `docs/roadmap.md` — Last reviewed bumped to session 53; §B
  (Stage2 native ghc) flipped from "🟡 working with workaround" to
  "✅ done"; new §H (Upstream MR for `STUArray Bool` fix) added.
- `demos/v0.13.0-bool-bug-fix.sh` (new) — the v0.13.0 demo.
- `demos/README.md` — new row for the v0.13.0 demo; "What's here"
  bumped to v0.13.0.
- `scripts/ghc-stage2-wrapper.sh` — removed `+RTS -A1G -RTS` (no
  longer needed); updated header comment to reflect history.
- `tests/cabal-examples/run-one.sh` — fixed bash 3.2 empty-array
  `unbound variable` under `set -u`.
- `docs/sessions/2026-05-15-session-53-v0.13.0-release/` — full
  session record (README, findings, commits, HANDOFF, logs/).

## Notes

- v0.13.0 is the **milestone release** that closes the 32-session
  "stage2 emits empty .o" investigation.
- The bindist tarball was assembled by extracting v0.12.0's
  bindist tarball, replacing the 15 library directories that
  session 52 rebuilt (or that hadrian's partial rebuild touched
  before being killed), and re-tarring with `xz -T0 -6` for
  parallel compression.  The full hadrian `binary-dist-dir`
  rebuild would have rebuilt all 1023 `.p_o` files from scratch
  (~30-90 minutes on uranium); the swap-and-retar approach
  produces an equivalent bindist in ~3-5 minutes because most
  rebuilt artifacts are byte-identical to v0.12.0's (only `array`
  has a substantive size delta of +648 bytes).
- No source-tree changes beyond what session 52 already landed.
  The patch tree is unchanged.
- `scripts/ghc-stage2-wrapper.sh` updated: no longer needs to add
  `+RTS -A1G -RTS`, because the bug it was working around is now
  fixed at source.  Backwards compatible with v0.11.0/v0.12.0
  installs (the wrapper is still at the same path; deploy-stage2.sh
  still expects it).
