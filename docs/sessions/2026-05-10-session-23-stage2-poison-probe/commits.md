# Session 23 commits

- [`6c39edb`](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/6c39edb) — Session 23: stage2 GC bug investigation, round 5 (PROBE22POISON RTS patch confirms the bug is real; crash at `0xdeadbeef` in `_blk_c7te + 112` of `GHC.Data.FastString` proves at least one stack slot the bitmap classifies as non-pointer is actually a live GC root).
- [`88b08d6`](https://github.com/cellularmitosis/ghc-darwin8-ppc/commit/88b08d6) — Session 23: state.md + roadmap.md reflect bug-confirmed-real-and-localised.

This session applied a temporary RTS patch (`probe22-poison-stack.patch`)
to instrument GC, ran the experiment, then reverted the patch and
redeployed the clean stage2 ghc to pmacg5.  No persistent changes to
`external/ghc-modern/` or to live binaries on pmacg5.  Deliverables in
`docs/sessions/2026-05-10-session-23-stage2-poison-probe/`:

- `README.md` — narrative + status on entry/exit.
- `findings.md` — measurements + slot-correlation arithmetic.
- `HANDOFF.md` — pickup doc for session 24.
- `probe22-poison-stack.patch` — the RTS diff against unmodified GC.c
  (re-applicable in 2 minutes).
- `scripts/run-poison.sh` — harness for the 5×iteration M5.hs repro.

Plus log artifacts under `logs/`:

- `poison-iter*.log` — per-iteration PROBE22 / PROBE22POISON output
  + GHC exit code.
- `ghc-real.crash.log` — Mac OS X CrashReporter file copied from
  pmacg5 (5 deadbeef events from this session, plus earlier
  unrelated entries).
- `blk_c7te.disasm` — 54-line disassembly of the crashing block,
  for cross-reference with PROBE22POISON slot offsets.
