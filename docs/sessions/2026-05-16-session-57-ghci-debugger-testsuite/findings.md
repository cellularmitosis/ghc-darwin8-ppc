# Session 57 findings

## TL;DR

83/83 of upstream's `ghci.debugger/scripts/` testsuite (the subset
that doesn't need extra harness — `normal` / `combined_output` /
plain `extra_files` annotations, no `reqlib` / `req_th` /
`expect_broken` / `extra_hc_opts` / `extra_run_opts`) PASS on
PPC/Tiger via the deployed v0.14.0 stage2 ghc.  No new patches, no
source changes, no PPC bugs surfaced.  Both run-1 failures were
testsuite-drift (instance-count footer) or harness omissions
(camelcase-suffixed companion files) — matched in upstream's
`testlib.py` line 2261 and explicit `extras=` entries respectively,
flipped all to PASS in run 2.

## What this proves that session 56 did not

Session 56's 51 tests exercised the **REPL command processor** —
`:type`, `:info`, `:load`, `:browse`, `:m`, `:set prompt`, etc. —
which mostly walks the typechecker and pretty-printer over GHCi's
in-memory state.  Session 57's 83 tests exercise the **bytecode
debugger** — `:break`, `:step`, `:trace`, `:print`, `:force`,
`:list`, `:hist`, `:back` — which actually mutates the BCO byte
stream at runtime, suspends thunks for `:print` introspection
without forcing them, walks the call stack of suspended BCOs, and
follows IND redirections through forced thunks.

Concretely:
- **Bytecode breakpoint insertion via `:break`** writes `BRK_FUN`
  opcodes into the in-memory BCO stream.  These opcodes are
  loaded under the BCO byte-swap path (patch 0014) but the
  modification happens after load — so it tests a different
  pathway: live mutation of the on-host BCO byte array vs the
  one-time load-time swap.
- **`:print` walks heap closures without forcing.**  The closure
  type dispatch in the runtime (`THUNK`, `THUNK_SELECTOR`,
  `BLACKHOLE`, `PAP`, `CONSTR_*_*`, `IND`) is layout-sensitive on
  32-bit big-endian — every closure header field, every payload
  pointer, every indirection traversal has to handle 4-byte
  pointers in MSB-first order.
- **`:force` drives a thunk to WHNF and rebinds `_result` to the
  forced value.**  Exercises the BCO interpreter's "update frame"
  machinery and the IND-following code in the bytecode dispatch
  loop.

If any of: BCO opcode layout, BCO byte-swap on patch, closure
header endian-handling, IND following, update-frame placement,
or per-line breakpoint-tick table access — had a PPC bug, these 83
tests would surface it.  None did.

## Important harness lessons (carrying forward to next sweep)

### 1. Camelcase-suffixed companions need explicit extras

The auto-discovery globs `<name>.*` and `<name>_*` (from session
56) catch `<name>.hs`, `<name>.ghci`, `<name>_1.hs`, etc., but
miss `<name><Letter>.hs` patterns like `T2950M.hs`, `T3000S.hs`.

Upstream's driver stages every file in the test dir
indiscriminately, which masks this divergence.  Our staging is
explicit-only, so:
- If `all.T` lists `extra_files([...])` — use those names.
- If `all.T` is silent BUT files like `<name>X.hs` exist — list
  them in the runner explicitly.

The T17989 case (companion files `T17989A.hs`..`T17989M.hs`) is
the same shape — already covered in run-1 because we caught it
during the test-list construction.

### 2. `...plus N instances involving out-of-scope types`

Upstream's `normalise_errmsg` masks this footer's count
(`testlib.py:2261`):
```python
s = re.sub('...plus ([a-z]+|[0-9]+) instances involving out-of-scope types',
             '...plus N instances involving out-of-scope types', s)
```
Backported into `normalise.py`.  Spurious depending on bignum backend
and base version.

### 3. `ghc-bignum-<VERSION>`

Same source (`testlib.py:2256`).  Backported as well — wasn't biting
session 57's tests but will bite a future sweep.

### 4. `T13825-debugger` `expect_broken(14455)` is for powerpc64

The `arch('powerpc64')` predicate in upstream's testsuite means
**64-bit PPC**.  We're **32-bit PPC** (`arch('powerpc')`, which is
`HostPlatform_powerpc` in upstream parlance).  So the
`expect_broken` doesn't apply and the test stays in.  It PASSes.

This is incidentally a nice data point: `T13825-debugger` tests
`:print` on a typed `_result` after a breakpoint hit; the bug
upstream marked it as broken on PPC64 (probably a calling-convention
issue on AIX / Linux PPC64) doesn't appear on PPC32 Mach-O.

## What this proves about the v0.14.0 REPL

Section "What this proves" in [`README.md`](README.md) has the full
table.  Headline: the GHCi debugger family — `:break` / `:step` /
`:trace` / `:print` / `:force` / `:list` / `:hist` / `:back` /
`:forward` — works end-to-end on PPC/Tiger.  This was the
session-56-HANDOFF-predicted "most likely place for an actual PPC
bug to surface" target, and it surfaces nothing.

## What this leaves untested

- `hist001`, `hist002` — `extra_run_opts('+RTS -I0')`.  Easy
  follow-up; wire `extra_run_opts` through.
- `T1620` — needs `T1620/` subdirectory staged.  Easy follow-up;
  extend extras to handle dirs.
- `tests/ghci/scripts/` `req_th` tests — session-56-HANDOFF
  priority #2.
- `tests/ghci/T<NUM>/` bug-numbered regressions —
  session-56-HANDOFF priority #3.
- `tests/ghci/prog001..prog019` multi-module — priority #4.
- Real-tty interactive REPL via ssh — priority #5.

## Reusable artifacts

`scripts/run-ghci-debugger.sh` is self-contained (modulo the
shared `normalise.py` symlinked from session 56).  To run again:

```bash
bash docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/scripts/run-ghci-debugger.sh
```

Override host: `bash run-ghci-debugger.sh imacg4`.  Logs land
under `docs/sessions/.../logs/ghci-debugger/<test>/`.

## What was NOT a real bug

Pre-emptive callouts for future sweeps:

- `...plus 14 instances involving out-of-scope types` (vs
  expected 13) — base library has gained one Show instance since
  the expected file was last regenerated.  Not a bug; the count
  is normalised.
- `T13825-debugger` PASSing — the `expect_broken` is for ppc64,
  not ppc32.  This is correct, not a regression.
- `T2950M.hs` "can't find file" in run 1 — pure harness omission
  (camelcase-suffixed companion).  Not a runtime bug.
