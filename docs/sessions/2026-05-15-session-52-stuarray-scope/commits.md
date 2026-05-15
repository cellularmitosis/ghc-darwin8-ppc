# Session 52 commits

- `e7380f7` — Session 52: **ROOT CAUSE
  IDENTIFIED, FIXED, AND DEPLOYED**.  The 32-session-old "compiler
  produces empty .o files" bug is a single upstream library bug in
  `libraries/array/Data/Array/Base.hs`'s
  `MArray (STUArray s) Bool (ST s)` instance, fired only on
  big-endian targets.  `newArray` zeroes `bOOL_SCALE n = ceil(n/8)`
  bytes via `setByteArray#` but `unsafeRead` / `unsafeWrite` access
  the array via `readWordArray#` / `writeWordArray#` (a full machine
  word).  For any size that doesn't align to a word, the trailing
  partial-word bytes are uninitialised; on big-endian the bit for
  element 0 lives in the *last* memory byte of the word but
  `setByteArray#` zeroes the *first*, so every read of an
  `STUArray Bool` of size < SIZEOF\_HSWORD\*8 returns garbage.  Fix:
  introduce `bOOL_WORD_SCALE` that rounds up to a full machine word,
  use it for both `newByteArray#` allocation and `setByteArray#`
  zeroing in Bool's `newArray` and `unsafeNewArray_`.  Patch:
  `patches/0016-array-stuarray-bool-word-aligned-init.patch`.
  Validation: pre-fix confirm\_test 1998/2000 bad → 0/2000 bad
  post-fix.  Session-51 minimal repro 8655/10001 bad → 0/10001 bad.
  Big2.hs (sessions 42-51 root reproducer) 152-byte empty `.o` →
  46340-byte fully-populated `.o` under both default RTS and
  `-A1m -G1`.  Baseline tests unchanged at 30 PASS / 4
  FAIL\_OUTPUT.  No regressions.  Stage1 rebuilt; stage2 redeployed
  to pmacg5.

Files in this commit:

- `external/ghc-modern/ghc-9.2.8/libraries/array/Data/Array/Base.hs`
  — the actual fix (live in build tree).
- `patches/0016-array-stuarray-bool-word-aligned-init.patch` —
  formatted patch for the source tree.
- `docs/sessions/2026-05-15-session-52-stuarray-scope/` — full
  session record:
  - `README.md`, `findings.md`, `HANDOFF.md`, `commits.md` (this).
  - `types_test.hs`, `nogc_test.hs`, `size_test.hs`,
    `confirm_test.hs` — four standalone test programs that
    bisected the bug and confirmed the fix.
  - `logs/` — pre-fix and post-fix run outputs, build log,
    deploy log, baseline-tests log.
