# Session 36 — probe redesigned to use `anyToAddr#` (reads v's REAL closure header)

**Dates:** 2026-05-13 (continuation of session 35; autonomous-loop mode).

**Status on arrival:** Source tree CLEAN per session-35 exit.
`pmacg5:/opt/ghc-stage2/bin/ghc-real` is the clean v0.12.0+ rebuild
(no probes).  v0.12.0 release unchanged.

**Status on exit:** CLEAN.  Probe reverted, stage1 rebuilt clean,
stage2 redeployed to pmacg5 + smoke-test PASS.  **Major finding:
v's heap closure at the panic site is `_stg_BLACKHOLE_info` with a
populated indirectee — i.e., the thunk was evaluated but its
header was never updated from `BLACKHOLE` to `IND`.**  This is the
PPC unreg bug, isolated to the BLACKHOLE→IND update path.

## Plan

Session 35 ended with the discovery that the past three sessions'
probes were reading the wrapping thunk that GHC builds for
`unsafeCoerce v :: Any`, not v's actual heap closure.  Session 35's
HANDOFF recommended `unpackClosure#` or a custom Cmm shim.

I picked a cleaner third option: **`anyToAddr#`** (`a -> State#
RealWorld -> (# State# RealWorld, Addr# #)`) — polymorphic over
any lifted type, compiles in Cmm to a register-to-register move
(see `compiler/GHC/StgToCmm/Prim.hs` `AnyToAddrOp`).  The argument
is passed through with no copying, no allocation, no wrapping
thunk.

Plan:
1. **Stand-alone verifier** — confirm `anyToAddr#` produces a clean
   STG (no `sat_sNNN` wrapping thunk) and returns the actual closure
   address on both uranium host-ghc and PPC unreg on pmacg5.
2. **Integrate into `refineFromInScope`** — mirror probe35's
   BEFORE/seq/AFTER design, but with the new primop.
3. **Rebuild stage1 + deploy + smoke-test.**
4. **Sweep env-len 600..2000 with the same Big2.hs trigger.**
5. **Decide:** is v's actual closure a THUNK at the panic site
   (theory 1: PPC unreg's pattern-match doesn't force), or a Var/Id
   constructor (theory: bug is in `lookupInScope` / `InScopeSet`
   tracking)?

## What happened

(Filled in as work progresses; see [`log.md`](log.md) for the
real-time trace and [`findings.md`](findings.md) for the distilled
outcome.)

### Phase 1 — stand-alone verifier (`anyToAddr#` is the right primop)

Verified on both uranium-host and PPC-unreg that `anyToAddr#`:

* Produces clean STG: `anyToAddr# [x void#]` — argument `x` passed
  directly, **no wrapping thunk**.
* Returns the actual tagged closure pointer.
* Distinguishes THUNK from WHNF cleanly: a thunk's word[0] is its
  THUNK info-table; after `seq` the same heap address has a
  different word[0] (indirection or constructor info-table).
* Behaves identically under `-O0` and `-O`.

See [`log.md`](log.md) for STG-dump evidence and runtime captures.

### Phase 2 — integrate into `refineFromInScope`

Patched `compiler/GHC/Core/Opt/Simplify/Env.hs` to add a
`probe36WhnfDump` helper using `anyToAddr#`, then re-wired the
existing `pprPanic` to include its output.  Patch saved as
[`probe36-anyToAddr.patch`](probe36-anyToAddr.patch).

### Phase 3 — deploy + sweep

Built stage1 (after fixing an early import-path issue: `int2Word#`
is in `GHC.Exts`, not `GHC.Prim` which is hidden from compiler code).
Cross-built stage2, rsync'd lib + binary to pmacg5, smoke-test PASS
(`stage2 native ghc on Tiger: ok`).

Swept env-len 600..2000 step 50 with the `Big2.hs` trigger.  Got
4 panic captures across 2 distinct env-len zones (the third zone
from session 35 didn't fire here — heap layout shifted with the
probe36 binary).  All 4 captures show:

* `BEFORE` address = `AFTER` address — `seq` did not relocate v.
* `BEFORE` 4-word header = `AFTER` 4-word header — `seq` did not
  update v's closure header.
* **`word[0]` is exactly `_stg_BLACKHOLE_info` (`0x092592a4`)** in
  every capture, resolved via `nm`.
* **`word[1]` has tag bits `0b011`** in every capture — a tagged
  pointer to the 3rd constructor of `Var`, which is `Id`.  So
  word[1] is the indirectee pointing at the evaluated Id closure.

See [`findings.md`](findings.md) for full analysis and the four
possible mechanisms (a)-(d), of which **(d) is favored: the
update path writes the indirectee to word[1] but fails to swap
word[0] from BLACKHOLE_info to IND_info**.

### Phase 4 — revert + clean rebuild + redeploy

* `git checkout -- compiler/GHC/Core/Opt/Simplify/Env.hs` —
  probe reverted.
* Rebuild stage1: `logs/build3-clean.log`.
* Redeploy stage2 to pmacg5: `logs/deploy2-clean.log`.
* Smoke-test PASS.

## Files added this session

* `README.md` (this), [`log.md`](log.md), [`findings.md`](findings.md),
  [`HANDOFF.md`](HANDOFF.md) (if needed), [`commits.md`](commits.md).
* [`probe36_verify.hs`](probe36_verify.hs) — stand-alone verifier.
* [`probe36-anyToAddr.patch`](probe36-anyToAddr.patch) — the probe
  applied to `Simplify/Env.hs`.
* [`scripts/sweep.sh`](scripts/sweep.sh) — sweep helper (env-len
  600..2000 step 50).
* [`scripts/identify-symbols.sh`](scripts/identify-symbols.sh) —
  post-sweep symbol identification (resolves captured info-pointers
  to symbol names via `nm`).
* `logs/` — every build / verify / sweep / deploy output.

## Status on exit

* Source tree: clean per `git status --short`.
* pmacg5 `/opt/ghc-stage2/bin/ghc-real`: clean v0.12.0+ rebuild
  (no probes).
* v0.12.0 release unchanged.
* Logs at `logs/`: build1-probe36 (failed import-path), build2-probe36
  (succeeded), build3-clean, deploy1-probe36, deploy2-clean, plus
  three verifier logs and the sweep capture.

## Top finding to carry into session 37

**v's closure header at the panic site is `_stg_BLACKHOLE_info`,
with the indirectee correctly populated at word[1].**  The
evaluation result is there — only the BLACKHOLE→IND swap is missing.

Session 37 should investigate the PPC unreg backend's emission of
`UPD_IND` / `stg_update_thunk_info` and the lazy-blackholing
interaction.  See [`findings.md`](findings.md) §F5 for concrete
next-session experiments and [`HANDOFF.md`](HANDOFF.md) for the
pickup primer.
