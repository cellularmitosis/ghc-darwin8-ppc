# Session 42 commits

- _TBD: backfill SHA after `git commit`._  Session 42:
  **SMOKING-GUN finding** for the stage2 GC bug.  Probe42
  instruments `simplTopBinds`'s entry in `Simplify.hs` to log
  `(length binds0, length (bindersOfBinds binds0))` via a
  helper exported from `Simplify/Env.hs`.

  **Findings:**
  - Clean compile (-A256m or -A1G, no padding): binds0 has 9
    binders (matching Big2.hs's ~10 top-level functions +
    dictionaries); call 2 sees 13 (post-inlining).
  - Failing -A1m -G1 at len=600, 1650, 1700: binds0 has 1
    binder → refineFromInScope panic.
  - Failing -A1m -G1 at len=700: 1 then 5 binders → panic.
  - Failing -A1m -G1 at len=850-1000: **0 binders** →
    ghc-real exits RC=0 producing a **152-byte empty .o file**
    with no function definitions (SILENT MISCOMPILE,
    confirmed via `nm /tmp/Big2.o` returning empty output).
  - Failing -A1m -G1 at len=800, 1100-1600, 1750-2000: TC-time
    `swap-not-in-scope` (probe42 doesn't fire — [InBind] not
    yet read at TC time).
  - **-A1G eliminates the bug entirely** (always sees 9
    binders).
  - Three repeats at len=600 produce identical numbers
    (deterministic given env-len + RTS flags).

  Root cause: **GC corrupts the [InBind] cons-list spine
  flowing into simplTopBinds**, truncating it to 0 or 1
  elements.  The list is heap-allocated CONSTR_2_0 closures
  (cons cells with 2 pointer fields: head, tail); GC's
  evac/scav handling appears to corrupt these on PPC32 unreg
  under GC pressure.

  This finding **subsumes every prior session's framing** —
  v's-closure-shape (S33-36), UniqMap-corruption (S28-38),
  Var.realUnique-drift (S38), two-distinct-Vars (S39),
  SimplEnv-field-corruption (S40-41) — all are downstream
  symptoms of the same root cause: GC truncates the [InBind]
  list, leaving the simplifier with 0-1 binders instead of 9.

  v0.12.0 ships unchanged; probe applied for measurement only
  and reverted at session end; stage2 on pmacg5
  rebuilt+redeployed clean + smoke-test PASS + baseline tests
  30 PASS / 0 FAIL_RUN / 4 FAIL_OUTPUT (same long-standing
  test-design divergences as sessions 37-41).

  **Severity update:** the bug is worse than previously
  thought — not just panics but also silent miscompiles
  producing empty .o files.  README's "Implementation status"
  should reflect this; user-facing workaround is
  `+RTS -A1G -RTS` (or `-A256m` for moderate compiles).

  Session 42 HANDOFF.md scopes probe43: identify the specific
  GC pass corrupting CONSTR_2_0 closures.  Likely candidate:
  `rts/sm/Evac.c::copy_tag` on PPC32 unreg.
