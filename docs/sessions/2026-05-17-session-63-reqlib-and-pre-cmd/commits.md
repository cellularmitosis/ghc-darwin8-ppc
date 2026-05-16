# Session 63 commits

| SHA | Subject |
|-----|---------|
| [`29c2251`](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/29c2251b9023883dc96e1a0ff91883f49cd0ad3a) | Session 63: extend ghci-tnum runner with reqlib + simple pre_cmd; 173/175 PASS. |

## Commit message

```
Session 63: extend ghci-tnum runner with reqlib + simple pre_cmd; 173/175 PASS.

Adds `reqlib(...)` and simple `pre_cmd(...)` support to
`run-ghci-tnum.sh`.  Three new components:

  - New `pre_cmd_for()` lookup function returning a shell snippet
    that runs (in the per-test directory) before the GHC invocation.
    Handles T5975a (`touch föøbàr1.hs`) and T5975b (`touch
    föøbàr2.hs`).
  - One new arm in `run_opts_for()` for T5975b's
    extra_hc_opts('föøbàr2.hs') — positional UTF-8 filename
    appended to the GHC command line (same dispatch as session
    60/62's other extra_hc_opts cases).
  - One new arm in `norm_args_for()` for T5979's
    normalise_version("transformers") — uses normalise.py's existing
    `--version pkg` flag (added in session 58) to reduce
    `transformers-X.Y.Z` to `transformers-<VERSION>`.

TESTS list grows by three (172 → 175): T5975a, T5975b, T5979.

All three new tests pass clean on the first run.  Result: 173/175
PASS.  The two failures are both T8042 *and* T17549 — the HFS+
1-second mtime-granularity race in upstream's `:reload` script.
Sessions 60/61/62 each had exactly one of {T8042, T17549} failing
per run, leading session 62 to claim they "alternate as the unlucky
coin-flip"; sessions 58 and 63 show both can fail in the same run
(two independent coin-flips).  No deterministic failures remain in
this 175-test subset.

T6106 ($MAKE preproc compile + ../shell.hs), T19650 ($MAKE needs
ghc-pkg on pmacg5), and ghci056 ($MAKE) need richer plumbing and
remain deferred.

No GHC source changes, no patches, no release.
```
