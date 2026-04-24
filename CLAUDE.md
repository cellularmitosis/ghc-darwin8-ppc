# ghc-darwin8-ppc

Bring GHC (Haskell) back to Mac OS X 10.4 Tiger on PowerPC.  PPC/Darwin
support was removed from GHC in commit 374e44704b (Dec 2018, first
absent in 8.8.1).  Goal: a working cross-build today that compiles
Haskell to ppc Mach-O, running on real Tiger hardware.

Project brief: [docs/plan.md](docs/plan.md).
Current status: [docs/state.md](docs/state.md).
Roadmap: [docs/roadmap.md](docs/roadmap.md).

## Subprojects workflow

All discrete chunks of work — bug fixes, build-chain shakedowns,
investigations, tools — live under `subprojects/<slug>/`.  This is
where plans, logs, and post-mortems get written.  Anything that isn't
a reusable binary artifact but has a story worth capturing belongs in
a subproject directory.

### Naming

- Flat layout: `subprojects/<slug>/`, no nesting.
- Slug is hyphenated, lowercase.  Prefix by theme so related work sorts
  together: `stage1-cross`, `stage2-native`, `bug-pi-double-literal`,
  `test-battery`, `ghci-macho-loader`, `bindist-installer`.
- No numbering.  Ordering lives in `subprojects/README.md` and in each
  subproject's declared dependencies.

### Layout inside a subproject

- `README.md` — entry point.  Current status in the first paragraph,
  links to the rest.
- `plan.md` — intent and approach.  Evolves as understanding does.
- `log.md` — append-only chronological work log.  Dated entries.
- `post-mortem.md` — written at completion.  What worked, what didn't,
  what surprised.

Minimum viable subproject is `plan.md` + `log.md`.  Add the others when
they earn their keep.

### Lifecycle

Subprojects stay flat in `subprojects/` when done — don't move them into
`done/`.  Moving breaks links, and completion state is already captured
in the content.  Status at a glance lives in
[subprojects/README.md](subprojects/README.md).

### How this evolved

Before this workflow we had `docs/experiments/001..006.md` as a flat
chronological log.  That worked for a linear bootstrap sequence.  Going
forward, branches of work (bug fixes, investigations, packaging) are
concurrent and iterative — the subprojects layout fits better.  Keep
the old `experiments/` files in place (they're still referenced by
`docs/state.md`) but put new work in subprojects.

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
