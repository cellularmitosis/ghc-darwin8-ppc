# Handoff from session 54 → session 55

**For:** the next claude session.
**From:** session 54 — discovered the `STUArray Bool` bug is already
fixed upstream (May 2023, commit `9cc80b5` / `array-0.5.6.0` /
[ghc#23132](https://gitlab.haskell.org/ghc/ghc/-/issues/23132)).
Session 53's "live upstream issue" framing was wrong: the *instance*
code is byte-identical upstream, but `bOOL_SCALE` itself was the
part that was patched, and the instance picks the fix up for free
via that helper.  Patch 0016 stays in our tree as the equivalent
backport into `array-0.5.4.0` (which is what GHC 9.2.8 ships).
**Recommended pickup:** the GHCi REPL (roadmap §C — all the
plumbing was done in v0.8.0 / session 12f for TemplateHaskell;
the REPL itself has been blocked on stage2 being usable, which it
now is post-v0.13.0).

## ✅ SESSION EXIT STATE

* No GHC source-tree changes.
* No patch *body* changes.  Patch 0016 prologue (the commentary
  block at the top of the .patch file) now cross-references the
  upstream commit and explains this patch is a backport.
* Docs reframed away from "we discovered an upstream bug" to "we
  independently rediscovered an already-fixed-upstream bug via the
  silent-miscompile-on-BE path":
  * top-level `README.md` (Latest-release paragraph + Releases row).
  * `docs/state.md` (top-of-file summary bumped to session 54).
  * `docs/roadmap.md` §H closed ✅.
  * Session 53 README amended with a correction paragraph.
* Cabal-examples sweep: 6/9 PASS, 3/9 test-harness or host-toolchain
  gaps, zero regressions.  See
  [`sweep-notes.md`](sweep-notes.md).
* Baseline tests: 30 PASS / 4 FAIL_OUTPUT (the four pre-existing
  design issues: Int width, getpid, getProgName).

The tree-as-shipped is byte-identical to v0.13.0 except for doc
text and the patch-file prologue.  No need to rebuild stage1, no
need to redeploy stage2, no need for a new release.

## TL;DR — the session-54 finding

`git log --all -- Data/Array/Base.hs` in the upstream
`gitlab.haskell.org/ghc/packages/array` repo shows commit
`9cc80b51cf98c13a140b00effb38329e7210d03c` by Matthew Craven on
2023-05-04, subject "Round up unboxed Bool arrays to whole-word
sizes".  It modifies `bOOL_SCALE` (around line 1557) to return a
whole-word-aligned byte count.  The `MArray (STUArray s) Bool (ST s)`
instance code (around line 1235), which session 53 checked, is
byte-identical to ours — but it calls `bOOL_SCALE n#`, so it picks
up the fix transparently.

Cross-version mapping:

| array version | bOOL_SCALE returns | Status |
|---|---|---|
| 0.5.4.0 (GHC 9.2.x) | ceil(n/8) | **buggy** |
| 0.5.5.0 (GHC 9.4.x, 9.6.0/9.6.1) | ceil(n/8) | **buggy** |
| 0.5.6.0+ (GHC 9.8.x+, 9.6.2+ rebump) | whole-word bytes | fixed |

The fix shipped in `array-0.5.6.0` (July 2023).  Cite-able citation
trail: the commit message says "to avoid ghc#23132", the changelog
entry says "Unboxed Bool arrays no longer cause spurious alarms
when used with `-fcheck-prim-bounds`" — both pin the same fix to
the same issue.  We couldn't fetch `gitlab.haskell.org/ghc/ghc/-/issues/23132`
itself (Anubis bot wall blocks WebFetch + curl), but the commit +
changelog + diff are unambiguous.

See [`findings.md`](findings.md) for the full discovery.

## What to try next, in priority order

### Top: GHCi REPL on PPC/Tiger

With stage2 native ghc now usable (v0.13.0), the GHCi REPL is the
biggest unimplemented feature.  The plumbing has been there since
v0.8.0 / session 12f (TemplateHaskell): the runtime Mach-O loader
(`patches/0007-rtslinker-tiger-machopowerpc.patch`), `iserv`, and
`scripts/pgmi-shim.sh`.  See [roadmap §C](../../roadmap.md).

What's likely needed:

1. Try `ghci` on pmacg5 with the v0.13.0 stage2 deploy.  Note any
   errors / panics.
2. If GHCi initialises and prompts but `:t` / loading modules fails,
   the issue is probably in the runtime linker's symbol resolution
   for stage2's own libraries.  Sister project
   [`llvm-7-darwin-ppc`](../../../../llvm-7-darwin-ppc) has detailed
   notes on this from the iserv side.
3. If GHCi panics at startup, the bug is probably in our patch tree
   that disabled GHCi paths during cross-build.  Audit `patches/`
   for `ghci`-related disables.

### Second: refactor patch 0016 to match upstream form

Cosmetic but reduces the patch from ~70 lines to ~12.  Replace the
"add `bOOL_WORD_SCALE`, change call sites" approach with
"modify `bOOL_SCALE` to round up" — same fix upstream took.  The
catch: we'd then want to rebuild stage1 + stage2 to verify the
shorter patch still produces the v0.13.0 demo's 46340-byte .o file,
and that's an ~17 min stage1 build + redeploy.  Defer unless we're
touching it for another reason.

### Third: audit other unboxed-bit-packed instances in third-party libs

Session 53 HANDOFF flagged this as "Fourth"; still open.  `vector`'s
`Bit` storage, `bytestring`'s internal bit handling, `data-array-byte`'s
boolean bit-packing — any code using `setByteArray# nbytes` plus
`readWordArray#`/`writeWordArray#` could carry the same anti-pattern.
The Bool bug hid for ~20 years on the only platform it fired on
silently; could be more out there.

Method: grep upstream repos for the pattern `newByteArray#` followed
shortly by `setByteArray#` followed shortly by `readWordArray#`.
Audit each hit for byte/word granularity mismatch.

### Fourth: stage2 native-compile sweep (not cross-compile)

The cabal-examples sweep this session was a cross-compile sweep
(stage1 on uranium → run on pmacg5).  That doesn't exercise the
bool-bug code path because the bool bug fires when stage2 *itself*
is compiling a complex program (renamer dep-analysis uses
`Data.Graph.scc` which uses `STUArray Bool`).

A native-compile sweep would ssh to pmacg5 and run `ghc --make` on
each example *there*, then run the binary.  That's the only way to
get a "what newly compiles?" answer.  Modest interest; the v0.13.0
demo (Big2.hs stage2-compile) already covers the bottom-line
question.

## What NOT to redo

* **Don't try to submit anything to upstream for the bool bug.**
  It's already there.
* **Don't claim "this is a live upstream issue" anywhere.**  It
  isn't.
* **Don't build a "portable repro" of the bool bug.**  Moot; fix
  is upstream.
* **Don't undo patch 0016.**  It's still load-bearing for 9.2.8.

## Hosts (unchanged)

* **uranium**: cross-build, source edits, bindist build, release prep.
* **pmacg5**: runs ppc binaries.  `/opt/ghc-stage2/bin/ghc-real` is
  the patched v0.13.0 stage2 (session 52 deploy).
* **indium**: medium-tolerance VM, not used this session.

## Paste-into-fresh-session prompt

```
Context: session 54 of the ghc-darwin8-ppc project discovered that
the STUArray Bool bug we fixed in v0.13.0 was already fixed upstream
in May 2023 (commit 9cc80b5 in gitlab.haskell.org/ghc/packages/array,
"Round up unboxed Bool arrays to whole-word sizes" by Matthew Craven,
motivated by ghc#23132; shipped in array-0.5.6.0).  GHC 9.2.8 ships
array-0.5.4.0 which predates the fix, so patch 0016 is the
equivalent backport into our tree.  No upstream MR work to do.

Top priority for session 55: tackle GHCi REPL on PPC/Tiger.  All the
plumbing has been in place since v0.8.0 / session 12f
(TemplateHaskell): runtime Mach-O loader, iserv, pgmi-shim.sh.  The
REPL itself has been blocked on stage2 being usable, which it now
is.  See docs/roadmap.md §C.

Second priority: refactor patch 0016 to match upstream's smaller form
(modify bOOL_SCALE itself rather than adding bOOL_WORD_SCALE).
Cosmetic; same behaviour; needs a stage1 rebuild + stage2 redeploy
to validate.  Probably skip unless we're already in the area.

Third: audit third-party libraries (vector, bytestring, data-array-byte)
for the same setByteArray# nbytes + readWordArray# granularity-mismatch
anti-pattern.

Read in order:
1. docs/sessions/2026-05-15-session-54-upstream-mr-prep/HANDOFF.md
2. docs/sessions/2026-05-15-session-54-upstream-mr-prep/README.md
3. docs/sessions/2026-05-15-session-54-upstream-mr-prep/findings.md
4. docs/roadmap.md §C (GHCi REPL scope)

Hosts: uranium for builds, pmacg5 for runs.

Unsupervised mode is project default.
```

## Memory aide

When session 55 ends, write the next handoff at:
`docs/sessions/<DATE>-session-55-<slug>/HANDOFF.md`.
