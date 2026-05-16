# Session 58 findings

## TL;DR

161/163 of the T-prefix `tests/ghci/scripts/` testsuite (the
subset that doesn't need special harness) PASS on PPC/Tiger via
the deployed v0.14.0 stage2 ghc — once a packaging bug in the
bindist is repaired in-place.  The remaining two failures are
HFS+ filesystem mtime granularity races in the test scripts
themselves (not PPC runtime bugs).  No GHC source-tree changes
this session.

## 1. The 163-test selection (reproducer)

```python
# Run from external/ghc-modern/ghc-9.2.8/.
import re
all_t = open('testsuite/tests/ghci/scripts/all.T').read()
EXCLUDE = ['extra_hc_opts', 'extra_run_opts', 'reqlib', 'req_interp',
           'req_th', 'expect_broken', 'pre_cmd', 'skip',
           'makefile_test', 'cmd_prefix', 'fragile',
           'filter_stdout_lines', 'ignore_stdout', 'ignore_stderr',
           'normalise_slashes', 'normalise_version', 'extra_ways',
           'when(', 'unless(', 'expect_fail']
P = re.compile(
    r"test\('([^']+)'\s*,\s*(.+?)\s*,\s*ghci_script\s*,\s*\['([^']+)\.script'\]\s*\)",
    re.DOTALL)
for m in P.finditer(all_t):
    name, body = m.group(1), m.group(2).strip()
    if name.startswith('ghci'):        continue   # session 56 covered these
    if any(k in body for k in EXCLUDE): continue
    ef = re.search(r"extra_files\(\[(.*?)\]\)", body)
    if ef and any('/' in f or f.startswith('..')
                  for f in re.findall(r"'([^']+)'", ef.group(1))):
        continue   # extras outside scripts/ — too painful to stage
    print(name)
```

163 names emerge.  6 of them exercise TemplateHaskell — T4127,
T4127a, T5566, T8831, T10466, T11098 — directly addressing the
session-57-HANDOFF priority #1 concern (test TH driven via the
REPL).  No PPC failures across any of those once unlit is fixed
(see §2).

## 2. The unlit packaging bug

### Symptom

`T10989` (literate Haskell `:l dummy.lhs` reload test) failed in
run 1 with stderr:

```
/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit:
/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit: cannot execute binary file

dummy.lhs:1:1:
    `powerpc-apple-darwin8-unlit' failed in phase
    `Literate pre-processor'. (Exit code: 126)
```

Exit code 126 = "command found but not executable", which on
Mach-O means wrong arch (kernel's `execve` can't find a matching
slice).

### Diagnosis

```
$ ssh pmacg5 'file /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit'
Mach-O 64-bit executable

$ ssh pmacg5 'otool -hv /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit'
      magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
MH_MAGIC_64 16777228          0  0x00     EXECUTE    18       1208   ...
```

`cputype 16777228 = 0x100000C = CPU_TYPE_ARM` with the `CPU_ARCH_ABI64`
bit set — that's **arm64**, the build host's arch.  The binary is
the uranium-side host `unlit` copied verbatim into the bindist with
a `powerpc-apple-darwin8-` filename prefix.

### Root cause

`hadrian/src/Rules/Program.hs` (lines 99–114, GHC 9.2.8):

```haskell
case (cross, stage) of
    (True, s) | s > Stage0 && package /= iserv -> do
        srcDir <- buildRoot <&> (-/- (stageString Stage0 -/- "bin"))
        copyFile (srcDir -/- takeFileName bin) bin
    (False, s) | s > Stage0 && (package `elem` [touchy, unlit]) -> do
        srcDir <- stageLibPath Stage0 <&> (-/- "bin")
        copyFile (srcDir -/- takeFileName bin) bin
    _ -> buildBinary rs bin ctx
```

In **cross** mode (first arm), every package above Stage0 gets its
stage0 (host) binary copied into stage1 except `iserv`.  Patch
0010 carved out `iserv` (so it cross-builds a real ppc binary for
TemplateHaskell) but missed `unlit`.  Result: stage1 ships the
host's arm64 `unlit` with a `powerpc-apple-darwin8-` prefix, and
that's what gets dropped into the bindist tarball.

The fix is a one-liner — change `package /= iserv` to
`package `notElem` [iserv, unlit]`, which is the same shape as
the non-cross arm already uses for `[touchy, unlit]`.  In cross
mode `unlit` will then fall through to `buildBinary`, which the
cross-ghc handles fine (unlit is a pure-C utility — no Haskell
deps, no RTS).  We've already validated that the cross-cc can
build it via the script in `scripts/build-unlit-ppc.sh`.

### Why this wasn't caught earlier

unlit only fires on `.lhs` (literate Haskell) inputs.  Nothing in
the project's test battery or in sessions 55–57 touches `.lhs`
files.  The cross-build's stage1 testsuite would have caught it,
but we don't run hadrian's full testsuite (we use our own
end-to-end battery).  The bug has been latent since v0.7.0 (which
landed iserv via patch 0010) — for over a year nobody hit `.lhs`
in REPL.

### Forensics

Both binaries are kept on pmacg5 for inspection:

```
$ ssh pmacg5 'ls -la /opt/ghc-stage2/lib/bin/'
powerpc-apple-darwin8-ghc-iserv               29.7 MB   ppc Mach-O   (correct)
powerpc-apple-darwin8-unlit                   14   KB   ppc Mach-O   (session 58 fix)
powerpc-apple-darwin8-unlit.arm64.broken      84   KB   arm64 Mach-O (was)
```

`scripts/powerpc-apple-darwin8-unlit.ppc` in this session dir is
byte-identical to what's on pmacg5; `build-unlit-ppc.sh`
reproduces it from the GHC source tree.

## 3. The HFS+ mtime-granularity race

### Symptom

`T17549` fails 100% of the time on PPC/Tiger; `T8042` fails ~2 of 3
times in our runs (passed run 1, failed runs 2 + 3).  Both share
the same shape:

```
writeFile "X.hs" "<some content>"
:load X.hs
writeFile "X.hs" "<different content>"
:reload
```

Expected behaviour: `:reload` recompiles X.hs.

Actual on PPC/Tiger: `:reload` sees X.hs mtime unchanged and
skips (the empty stdout/stderr in actual.* confirms it never
reached the compile phase).

### Diagnosis

HFS+ on Tiger stores mtimes with 1-second granularity (POSIX
`utimes()` precision, no `utimensat` / `mtim_nsec` on 10.4).
GHCi's recompilation logic (in `GHC.Iface.Recomp`,
`checkMod hsc_env hpt mod`) checks the source file's mtime
against the cached value from the last load.  If the file is
rewritten in the same second as it was first read, mtime is
unchanged and the recomp logic concludes "no work needed".

Manual reproduction with explicit `touch -t`:

```bash
ssh pmacg5 'cat > /tmp/repro.script <<EOF
writeFile "X.hs" ""
:load X.hs
writeFile "X.hs" "import"
:! touch X.hs
:reload
1
EOF
ghc-real --interactive < /tmp/repro.script'
```

With the touch, the parse error fires as expected.  Without it,
nothing — exactly matches the T17549/T8042 failure mode.

### Why T1914 succeeds where T8042/T17549 fail

T1914 has the same `writeFile + :load + writeFile + :reload`
shape **but** it explicitly bumps mtimes:

```
System.IO.writeFile "T1914A.hs" "module T1914A where { import T1914B; }"
:! touch -t 01010000 T1914A.hs
...
System.IO.writeFile "T1914A.hs" "...oops"
:! touch -t 01010001 T1914A.hs
:reload
```

The `touch -t` calls set explicit, distinct mtimes — bypassing
the filesystem's granularity entirely.  T8042 and T17549 were
authored later and forgot to do the same.  On Linux ext4
(nanosecond mtimes) the race doesn't surface; on Tiger HFS+ it
does.

### Why T8042 sometimes passes

T8042 has three writeFiles + :load + a fourth writeFile.  The
combined latency of those four IO ops *plus* the three-module
:load is on the edge of a 1-second tick.  Run 1 happened to span
two seconds; runs 2 and 3 happened to fit in one.  Pure timing
variance.

### What to do

For an unbiased PASS count, leave both in the TESTS list and
report the run-stable failures honestly:

- T17549: 0% PASS on PPC/Tiger.
- T8042: ~30% PASS on PPC/Tiger (1/3 in our runs).

For a clean "X / X PASS" headline, the runner could exclude these
two with a comment pointing to this section.  We chose honesty.
The upstream fix would be to add explicit `touch -t` calls to
both .script files — uncontroversial, would be a small upstream
MR.

## 4. The two-step cross-build pattern for utils/

The `unlit` build script taught me how to coax the ppc-cc wrapper
into producing a real binary.  Notable:

- `$CROSS_CC -O2 -o foo bar.c baz.c` — produces a 16-byte stub
  (ppc-cc routes compile+link with source through `ppc-ld-fake`,
  which writes a Mach-O magic + empty header for configure
  CC-works checks).
- `$CROSS_CC -O2 -c bar.c && $CROSS_CC -O2 -c baz.c && $CROSS_CC
  -o foo bar.o baz.o` — produces a real binary.  The compile-only
  calls go to real clang; the pure-link call (no source files in
  args) routes through `ppc-ld-tiger`, which is the real Tiger
  linker via cctools-port.

Worth documenting because the same pattern works for any of
ghc's C-only utilities (touchy, hp2ps, ...): they're not stuck
needing the full Hadrian build infrastructure.  If we ever need
to retrofit other helper binaries that Hadrian's host-copy path
mis-routes, the same `compile -c`-then-`link` recipe applies.

## 5. Things still untested by this sweep

Eligible for a future T-num extension:

- `extra_run_opts` tests: T9878b, T12091, T17500, T17669.
  Easy follow-up if the runner threads RTS flags through.
- `extra_hc_opts` tests: T2452, T2182ghci2, T5975b, T9293,
  T13385, T14342, T16563.  Easy: thread compiler flags through.
- `pre_cmd` tests: T5975a, T5975b, T6106, T9762, T19650.  Each
  has a small Makefile or shell prelude.  Cherry-pick.
- `reqlib` tests: T5979 (reqlib transformers).  Transformers is
  a boot library; should just work.
- The `Defer02` test needs files from `../../typecheck/`; needs a
  cross-tree extras facility.

The T-prefix subdirectory tests (`tests/ghci/T11827/`, etc.) —
each a Makefile-driven mini-project — remain priority #2 from
session 57's HANDOFF.  Still uncovered.

## 6. What was NOT a real bug

For future-self pre-emption:

- `cannot execute binary file` from unlit on dummy.lhs — wrong-
  arch binary in /opt/ghc-stage2/lib/bin/.  Fixed.  Real
  packaging-side issue; Hadrian patch 0010 needs to also exclude
  `unlit` from the cross-mode host-copy.
- T8042 missing `[3 of 3] ... T8042A.o` line — HFS+ 1s mtime,
  not a recomp bug.
- T17549 empty stderr where parse error was expected — same.
- T8042 having T8042recomp as a sibling test name was NOT a
  staging problem; the auto-discovery glob `T8042.*` uses a
  literal dot and correctly leaves T8042recomp.* alone.
- T2182ghci / T2182ghci2, T7627 / T7627b, T13202 / T13202a,
  T8959 / T8959b, T9878 / T9878b, T6018ghci / T6018ghcifail /
  T6018ghcirnfail — sibling test names share a stem prefix.
  Bash's `<name>.*` glob requires a literal dot before the suffix,
  so sibling-test files aren't accidentally pulled into each
  other's staging dir.  No code change needed; just worth
  remembering when adding new tests to the list.
