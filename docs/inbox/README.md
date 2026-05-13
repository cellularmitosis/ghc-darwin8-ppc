# inbox/

Drop point for **incoming notes from the sister
[llvm-darwin8-ppc](https://github.com/cellularmitosis/llvm-darwin8-ppc)
project** (and any future sister projects).

The llvm-darwin8-ppc project is this project's toolchain dependency:
its clang/LLVM is what cross-compiles the GHC RTS for
`powerpc-apple-darwin8`. When the LLVM-side ships a clang bug fix
that unblocks GHC work, lands a new toolchain release, or changes
something that affects how this project should build, the finding
gets dropped here as `<topic>.md` for this project to pick up.

## Convention

- **Sister project writes:** drops a self-contained note here with
  the change description, what's already done on their side, what
  this project needs to do to validate/integrate, any blockers
  hit during their investigation, and pointers back to their bug
  reports / patches / sessions. Filename hints at the topic
  (e.g. `bug-010-fixed-llvm-side.md`).
- **This project picks up:** in a new session, convert the inbox
  note into the canonical workflow:
  1. New session dir at
     `docs/sessions/YYYY-MM-DD-session-<N+1>-<slug>/` with the
     usual README + HANDOFF (per [`docs/sessions/README.md`](../sessions/README.md)).
     Highest session number so far: 21.
  2. If the note documents a bug or design proposal that needs
     ongoing tracking, file an entry under
     [`docs/proposals/`](../proposals/) (e.g. `bug-<slug>.md`,
     matching the existing `bug-pi-double-literal.md` style).
  3. Move the inbox file to [`attic/`](attic/) once its content
     has been integrated (or determined to need no integration).
     Don't delete — the attic preserves the original wording for
     future reference and lets the sister project see what's been
     processed without spelunking git history. **Keep this
     README** — the directory itself is the persistent channel.
  4. Optional but courteous: drop a "validated" / "integrated"
     note back in `llvm-darwin8-ppc/docs/inbox/` so the LLVM
     project can flip its bug status accordingly.

## Why a directory, not GitHub Issues

This is a sole-developer setup; cross-project communication is
fastest when both ends just write Markdown files. A GitHub Issue
on ghc-darwin8-ppc filed by llvm-darwin8-ppc, also by Jason, also
to be triaged by Jason, adds ceremony with no benefit. Files in
`docs/inbox/` work fine.

(The sister llvm-darwin8-ppc project uses the symmetric
[`docs/inbox/`](https://github.com/cellularmitosis/llvm-darwin8-ppc/tree/main/docs/inbox)
for incoming-from-here notes; same convention.)

## Examples (historical)

- `bug-010-fixed-llvm-side.md` (2026-05-09) — first inbox note,
  briefing this project that
  [BUG-010](https://github.com/cellularmitosis/llvm-darwin8-ppc/blob/main/docs/bug-reports/bug-010-clang8-ghc-rts-storage-miscompile.md)
  (the clang-8 → GHC RTS struct-layout SIGBUS that blocked session
  18's LLVM-7 → LLVM-8 toolchain swap) is fixed via patch 0013 in
  the LLVM project, with the patched cross-clang already installed
  at `~/.local/ghc-ppc-xtools/clang-8`.  Validated end-to-end in
  session 18 attempt 3, shipped as v0.12.0.  (This note pre-dates
  the attic convention — only the [`bug-010-validated-shipped.md`](attic/bug-010-validated-shipped.md)
  reply we sent back, if any, would live in attic now.)
- [`attic/v8.0.1-r8-shipped.md`](attic/v8.0.1-r8-shipped.md)
  (2026-05-10) — courtesy follow-up from llvm-darwin8-ppc session
  037 noting that the BUG-010 fix is now also baked into the PPC
  self-host clang-8 binary (v8.0.1-r8 release).  No integration
  needed on this side — our cross-build path already had the fix
  via the arm64 cross-clang.  First note processed under the
  attic convention; reviewed in session 21.
