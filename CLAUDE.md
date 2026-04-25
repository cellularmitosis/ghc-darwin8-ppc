# ghc-darwin8-ppc

Bring GHC (Haskell) back to Mac OS X 10.4 Tiger on PowerPC.  PPC/Darwin
support was removed from GHC in commit 374e44704b (Dec 2018, first
absent in 8.8.1).  Goal: a working cross-build today that compiles
Haskell to ppc Mach-O, running on real Tiger hardware.

Project brief: [docs/plan.md](docs/plan.md).
Current status: [docs/state.md](docs/state.md).
Roadmap: [docs/roadmap.md](docs/roadmap.md).

## Repo layout

```
docs/
  plan.md               — original project brief.
  state.md              — all-time status snapshot.
  roadmap.md            — prioritized forward work.
  ghc-version-choice.md — why 9.2.8 vs 9.4 / 9.6 / newer.
  experiments/          — historical phase write-ups (001–006).  These
                          document work done before the sessions
                          workflow existed.
  sessions/             — one dir per session, dated.  See sessions/README.md.
    YYYY-MM-DD-session-N-<slug>/
      README.md         — narrative: arrival state, what was done, exit state.
      findings.md       — "things learned that will matter later."
      commits.md        — commits landed, one-liner each.
  proposals/            — forward-looking plans for pieces of work
                          that are scheduled but not yet started.
                          Graduate to sessions as they get picked up.
  notes/                — reference material (cross-toolchain strategy,
                          fleet recon, file mapping, etc.).  Stable
                          knowledge that outlasts any one session.
  ref/                  — short factual refs (package anatomy, etc.).
  log/                  — ad-hoc diagnostic logs.
patches/                — git-format patches applied to the GHC source tree.
scripts/                — cross-env, wrappers, linker shims, site cache.
tests/                  — test battery + runner.  See tests/RESULTS.md.
demos/                  — one runnable Haskell program per release,
                          showcasing what that release unlocked.  See
                          demos/README.md.
external/               — gitignored.  Where the GHC source tree is unpacked.
```

## Release workflow

Every GitHub release ships **two** things in addition to the bindist
tarball:

1. A **demo** under `demos/vX.Y.Z-<slug>.{hs,sh}` (or a subdir for
   cabal projects), showcasing what the release unlocked.  Add a row
   to `demos/README.md`'s table.  Pick a tiny program that compiles
   and runs end-to-end on a real Tiger box; the goal is "someone
   landing on the release tag can paste a one-liner and see it work."
2. A **README update** so the front-page status reflects what just
   shipped.  Specifically:
   - The "Latest release" line at the top of the Status section.
   - The relevant rows in the "Implementation status" tables — flip
     ❌ → 🟡 / ✅ where appropriate, link to the new patch / session /
     release tag.
   - A new row in the "Releases" table at the bottom.

The release isn't done until both have landed.  Patch + session
notes + bindist tarball + demo + README + tag, in roughly that order,
all in the commit/release that bears the version number.

## README format

The "Implementation status" section uses tables, one per area
(compiler & cross-build, language & libraries, cabal, runtime
linker, TemplateHaskell, tooling).  Status column uses three
emojis in this priority order:

- ✅ Working — lands a green test or a verified end-to-end run.
- 🟡 Partial / Stub / Pinned / Deferred — works for the common case
  but has known gaps; or works only with a workaround; or works for
  one variant only.  Always followed by a one-line "what's missing"
  in the Notes column.
- ❌ Missing — known not to work, with a pointer to the proposal or
  session that scopes the fix.

Each row's "Notes" column is one or two sentences.  Anything longer
goes in the linked session findings or proposal — keep the table
scannable.

This format is borrowed from the sister project
[`ionpower-node`](https://github.com/cellularmitosis/ionpower-node);
see its README's "Node API implementation status" section for the
full original.

## Sessions workflow

Substantive work lives in [`docs/sessions/`](docs/sessions/).  Each
session is its own dated dir; see
[`docs/sessions/README.md`](docs/sessions/README.md) for the checklist
and end-of-session ritual.

Forward-looking work that's scheduled but not yet started lives as
individual files under [`docs/proposals/`](docs/proposals/).  When a
proposal gets picked up for real, the active session's `README.md`
references it; when the work lands, the proposal can be archived or
rolled into that session's notes.

### How this evolved

Before the sessions workflow we briefly tried a `subprojects/` layout
(chunks by theme: `stage1-cross/`, `bug-pi-double-literal/`, etc.).
That was heavier than needed — each chunk wanted its own README +
plan + log + post-mortem, which created lots of thin files.  Sessions
(chunks by date) turned out to match the actual shape of the work
better: one session touches whatever needs touching, and the log
captures the decisions in order.

The even-earlier `docs/experiments/001..006.md` format is kept as-is
for the bootstrap phase — those files are the historical record and
are referenced from [`docs/state.md`](docs/state.md).

## The ghc-9.2.8 pin

We target GHC 9.2.8 specifically.  See
[docs/ghc-version-choice.md](docs/ghc-version-choice.md) for the full
reasoning; short version:

- 9.2.8 is the last LTS release of the 9.2 line.  Stable, wide
  ecosystem support, minor-rev cycle is done.
- 9.4+ did a lot of internal refactoring (hadrian-only, Cmm/NCG
  changes).  Would be strictly more work to reintroduce PPC support
  there.
- 9.6+ is actively trying to deprecate unregisterised mode, which is
  the exact path our PPC build relies on.

Switching to a newer series is a future project, not this one.

## Unsupervised mode

When the user says "work unsupervised" (or similar wording), they're
unreachable — at work, asleep — and cannot answer questions.  Under
this mode:

- **Don't stop to ask.**  Unblock yourself: make assumptions, run
  experiments, search the web for the problem or prior art, read
  related source, try the obvious fixes.
- **Long runtimes are fine.**  Eight or more hours of iteration is not
  too long if the task warrants it.
- **Only block for genuinely unreasonable actions.**  E.g. "delete the
  user's games to free disk space" is unreasonable.  A workaround is
  almost always available.
- **Log every judgment call** in the active subproject's `log.md` —
  assumptions made, experiments tried, dead-ends rolled back.  That
  log is what the user reviews on return.

### Risk tolerance by host

The line between reasonable and unreasonable is host-dependent:

- **uranium (this main Mac)** — low risk tolerance; this machine
  matters.
  - OK: `brew install`, downloading source tarballs, building from
    source, standard package installs.
  - Not OK: installing random hobbyist binaries off the internet (e.g.
    a stranger's ffmpeg build).
- **PowerPC fleet (pmacg5, imacg4, etc.)** — high risk tolerance;
  these are test machines and we can reinstall them.
  - OK: downloading and trying hobbyist Tiger/Leopard PowerPC builds
    found via web search (a random blog's GHC Haskell build is fair
    game), pulling patches from MacPorts/Fink/Debian/Gentoo as
    inspiration or direct drop-in, copying utilities between fleet
    hosts, experimental kernel installs, `tiger.sh` / `leopard.sh`
    package installs, building from source in-place.
  - The bar is "will this probably teach us something?" not "is this
    provably safe?"
- **indium (build VM)** — medium tolerance; reinstallable but we share
  it with other projects.  Default to building in a scratch directory,
  clean up on failure.
