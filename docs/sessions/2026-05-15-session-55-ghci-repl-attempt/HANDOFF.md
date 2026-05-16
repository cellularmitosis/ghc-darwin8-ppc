# Handoff from session 55 → session 56

**For:** the next claude session.
**From:** session 55 — shipped v0.14.0 (GHCi REPL on PPC/Tiger).
The REPL turned out to need exactly one CPP flag plus two extra
build args; no new patches; every load-bearing piece had been in
place since v0.8.0 (TH plumbing) and v0.13.0 (STUArray Bool fix
unblocked stage2).
**Recommended pickup:** there's no single obvious next-must-do.
The roadmap's biggest open items have all closed.  Pick one of the
follow-ups below based on appetite.

## ✅ SESSION EXIT STATE

* No GHC source-tree changes.  No new patches.
* `scripts/deploy-stage2.sh` modified (3-line addition + comment) to
  enable the internal interpreter when building stage2 native ghc.
* Stage2 ghc-real on pmacg5 redeployed (~199 MB, was ~193 MB);
  smoke-tested; baseline tests 30 PASS / 4 FAIL_OUTPUT (unchanged
  — baseline is cross-compile, doesn't touch stage2).
* `demos/v0.14.0-ghci-repl.sh` + `demos/README.md` row added.
* `README.md` updated: Latest-release paragraph rewritten, GHCi REPL
  status row flipped ❌ → ✅, Releases table row added.
* `docs/roadmap.md` §C heading + GHCi REPL subsection updated.
* `docs/state.md` top-of-file summary bumped to session 55.
* All session 55 docs (`README.md`, `findings.md`, `commits.md`,
  this file, logs) committed in this dir.

The tree is clean and v0.14.0 is tagged.

## TL;DR — the session-55 finding

The "not built for interactive use" message comes from
`ghc/Main.hs`'s CPP gate `#if !defined(HAVE_INTERNAL_INTERPRETER)`.
Hadrian sets that gate via `ghc-bin.cabal`'s `internal-interpreter`
flag (default False, manual; hadrian flips it on for stage1+).
**Our stage2 native ghc isn't built by hadrian or cabal** — it's
built by `scripts/deploy-stage2.sh` invoking the cross-stage1
manually on `ghc/Main.hs`.  That manual build had been bypassing
the cabal flag entirely.

Three additions to the manual build line in `deploy-stage2.sh`:

1. `-DHAVE_INTERNAL_INTERPRETER` — the CPP gate.
2. `-i$GHC_SRC/ghc` — so `--make` discovers `GHCi.UI` et al.
3. `-package exceptions -package time` — the new deps.

That's the whole change.  Stage2 binary grew ~5 MB (193 → 199 MB)
for the GHCi.UI / GHCi.Leak / haskeline-driven REPL machinery.

Verified end-to-end: `ghc -e`, `ghc --interactive`, `:t`, `:load`,
multi-line `:{ :}`, imports, `Data.Map.Strict`, `factorial 20`
(bignum), recursion, lambdas — all working.  Zero failures on
first try.  See [`findings.md`](findings.md).

## What to try next, in priority order

There is no clear single next-must-do.  Roadmap A ✅, B ✅, C ✅,
D ✅, E on hold, G ✅, H ✅.  The remaining items are smaller or
exploratory.

### Top: run upstream's GHCi testsuite

The REPL works for the dozen or so smoke tests we tried, but the
full GHCi testsuite has hundreds of tests covering `:break`,
`:step`, `:trace`, `:print`, `:show`, `:edit`, `:script`,
`-fdebug` interactions, `Foreign.Ptr` from the REPL, etc.  Run it
and see what falls out.  The testsuite lives under
`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/`.  Note: we'd
need to drive it with the deployed stage2 ghc on pmacg5, not with
our cross-stage1 — which means either porting the testsuite driver
to ssh-bridge (heavy) or hand-running a curated subset (lighter).
Recommend the lighter path first: pick ~20 tests covering a range
of features, ssh them to pmacg5, run, capture output, diff against
expected.

### Second: stage2 native-compile sweep

Carried forward from session 54's HANDOFF.  The cabal-examples
sweep this far is *cross-compile* (stage1 on uranium → run on
pmacg5).  A *native-compile* sweep would ssh to pmacg5 and run
`ghc --make` on each example *there*, then run the binary.  That
exercises the post-v0.13.0 stage2 in a way the cross-compile sweep
doesn't.  Modest interest — v0.13.0's Big2.hs demo + v0.14.0's
GHCi `:load` of `RepoDemo.hs` already cover the bottom-line
question — but a wider sweep would catch surprises.

### Third: refactor patch 0016 to upstream's smaller form

Carried forward from session 54.  Replace the "add `bOOL_WORD_SCALE`,
change call sites" approach with "modify `bOOL_SCALE` to round up"
— same fix upstream took (`9cc80b5` "Round up unboxed Bool arrays
to whole-word sizes").  Diff size halves; behaviour identical.
Catch: needs a stage1 rebuild + stage2 redeploy to validate
(~17 min stage1 + few min stage2).  Defer unless we're touching
the patch for another reason.

### Fourth: audit other unboxed-bit-packed instances in third-party libs

Carried forward from sessions 53/54.  `vector`'s `Bit` storage,
`bytestring`'s internal bit handling, `data-array-byte`'s boolean
bit-packing — any code using `setByteArray# nbytes` plus
`readWordArray#` / `writeWordArray#` could carry the same
anti-pattern.  The Bool bug hid for ~20 years on the only platform
it fired on silently; could be more out there.

Method: grep upstream repos for the pattern `newByteArray#`
followed shortly by `setByteArray#` followed shortly by
`readWordArray#`.  Audit each hit for byte/word granularity
mismatch.  Low-priority for our project (we don't use those libs
in the bindist) but valuable upstream contribution.

### Fifth: try GHCi over a real ssh tty

Our session-55 smoke tests used piped stdin (`echo ... | ghc
--interactive`).  Real interactive use over `ssh pmacg5` with a
tty would exercise haskeline's terminal handling on Tiger.  Should
"just work" — haskeline is already built into the binary — but
hasn't been verified.

### Sixth: speed up the cross-build by adding more parallelism / caching

Pre-existing wishlist item.  Our stage1 build is ~17 min on an M-
series Mac.  Some of that is hadrian's serial sections.  Modest
interest.

## What NOT to redo

* **Don't try to land the GHCi REPL "feature" upstream.**  It's not
  a feature; the gate already exists, hadrian already sets it,
  upstream's Linux/Darwin/Windows builds all have it on by default.
  Our project's stage2 was unique in bypassing cabal entirely.
* **Don't add a patch for v0.14.0.**  None needed.
* **Don't claim v0.14.0 was hard.**  It wasn't.  v0.14.0 is the
  payoff for sessions 6/9/12/12e/12f/17–52 doing the heavy lifting.

## Hosts (unchanged)

* **uranium**: cross-build, source edits, bindist build, release prep.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real` is
  now the v0.14.0 stage2 (GHCi REPL enabled, ~199 MB).
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 55 of the ghc-darwin8-ppc project shipped v0.14.0,
which enables the GHCi REPL on PPC/Tiger.  No new patches; every
load-bearing piece had been in place since v0.8.0 (TH) and v0.13.0
(STUArray Bool fix unblocked stage2).  v0.14.0 is a 3-line addition
to scripts/deploy-stage2.sh: -DHAVE_INTERNAL_INTERPRETER, -i$GHC_SRC/ghc,
-package exceptions -package time.  That's it.

Stage2 ghc-real on pmacg5 is now the GHCi-enabled binary
(/opt/ghc-stage2/bin/ghc-real, ~199 MB).  Verified end-to-end:
ghc -e, ghc --interactive, :t, :load, :{ :}, imports, Data.Map.Strict,
recursion (factorial 20, fib 12, collatz).  Zero failures.

There's no clear single next-must-do.  Roadmap items A/B/C/D/G/H all
closed.  Pick from the session 55 HANDOFF's priority list:
1. Run a curated subset of upstream's GHCi testsuite on pmacg5.
2. Stage2 native-compile sweep over the cabal-examples set.
3. Refactor patch 0016 to upstream's smaller form (cosmetic).
4. Audit vector/bytestring/data-array-byte for the same
   setByteArray#-vs-readWordArray# granularity-mismatch
   anti-pattern that the Bool bug exemplified.
5. Try GHCi over a real ssh tty (vs piped stdin).
6. Speed up the cross-build.

Read in order:
1. docs/sessions/2026-05-15-session-55-ghci-repl-attempt/HANDOFF.md
2. docs/sessions/2026-05-15-session-55-ghci-repl-attempt/README.md
3. docs/sessions/2026-05-15-session-55-ghci-repl-attempt/findings.md
4. docs/roadmap.md (priorities + open items)

Hosts: uranium for builds, pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 56 ends, write the next handoff at:
`docs/sessions/<DATE>-session-56-<slug>/HANDOFF.md`.
