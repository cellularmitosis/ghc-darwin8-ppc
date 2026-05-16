# Session 62 commits

| SHA | Subject |
|-----|---------|
| [`f9570d1`](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/f9570d11f152abadbe875df0239cbc4a613c9a01) | Session 62: extend ghci-tnum runner with extra_hc_opts; 171/172 PASS. |

## Commit message

```
Session 62: extend ghci-tnum runner with extra_hc_opts; 171/172 PASS.

Adds `extra_hc_opts(...)` support to `run-ghci-tnum.sh` — six new
cases in `run_opts_for()` plus six new TESTS entries (T2452,
T2182ghci2, T9293, T13385, T14342, T16563).  Same dispatch arm as
session 60's `extra_run_opts` extension, because ghci_script
tests compile and run in one `ghc --interactive` invocation.

`normalise.py` gains a trailing-blank-line trim
(`s.rstrip('\n') + '\n' if s else ''`) to absorb upstream's stray
expected-file newlines.  Required for T16563 — its expected
`.stdout` has `hello world\n\n` but GHCi emits `hello world\n`,
reproduced on the host's bare ghc-9.2.8 (so test-data issue, not
PPC).  Mirrors upstream `testlib.py::normalise_whitespace` but
applied conservatively to trailing-only — internal blank lines
between error messages are preserved.

Result: 171/172 PASS on the now-172-test T-prefix subset.  Lone
failure is T8042 — the HFS+ 1-second mtime-granularity race in
upstream's `:reload` script; alternates with T17549 as the unlucky
coin-flip per run.

No GHC source changes, no patches, no release.
```
