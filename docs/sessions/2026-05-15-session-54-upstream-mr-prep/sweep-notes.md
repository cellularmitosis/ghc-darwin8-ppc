# Cabal-examples sweep — session 54

Driver: `/tmp/cabal-sweep-54.sh` (see commits.md for the snippet).
Each example was invoked via `bash tests/cabal-examples/run-one.sh
<example>`, which cross-builds with the patched stage1 and ssh-runs
the binary on `pmacg5`.  Logs at `logs/cabal-examples/<example>.log`.

| Example | Result | Notes |
|---|---|---|
| `random` | ✅ PASS | `random int 1..100 with seed 42: 49` |
| `async` | ✅ PASS | `concurrent: (42,"world")` |
| `vector` | ✅ PASS | 10-pair zipWith output |
| `optparse` | ⚠️ test-harness gap | Binary works, prints `--help` because `run-one.sh` doesn't pass `-n NAME`.  Same as v0.12.0 behaviour. |
| `megaparsec` | ✅ PASS | `("charlie",42)` |
| `aeson-generics` | ✅ PASS | JSON round-trip |
| `network-echo` | ✅ PASS | TCP echo round-trip |
| `full-stack-cli` | ⚠️ test-harness gap | Binary works, prints `--help` because `run-one.sh` doesn't pass `-i FILE`.  Same as v0.12.0 behaviour. |
| `https-get` | ⚠️ host toolchain gap | `HsOpenSSL-0.11.7.10` build fails (14 errors) because `OPENSSL_PREFIX` not set in env on uranium.  Session 15 set up `/tmp/ssl-mirror/openssl-1.1.1t` as the PPC-cross OpenSSL prefix; that scratch dir is gone.  Not a regression — same gap as v0.12.0. |

**Net:** zero regressions from patch 0016.  Six end-to-end PASS on
pmacg5; the three "FAIL"s are all environmental (two missing args,
one missing host-side dep), not codegen.

## What didn't get validated

The session 53 HANDOFF guessed "many will newly succeed under default
RTS via stage2-native compile" — but this sweep used stage1 cross-
compile, which has been working since v0.7.0 regardless of the bool
bug.  The bool bug fired in stage2's *own* compilation work (the
renamer's `Data.Graph.scc` building empty `.o` files), not in
arbitrary user programs that happen to use bit-packed Bool arrays.

A true "what newly succeeds with the patch?" sweep would need to
stage2-compile each example on pmacg5 (rather than cross-compile on
uranium and run on pmacg5).  None of these examples are very large,
so most would probably have stage2-compiled cleanly even pre-fix.
The cleanest "newly works" demo is the v0.13.0 demo itself:
Big2.hs stage2-compiled on pmacg5, which produced 152-byte empty
.o files pre-fix and 46340-byte real .o files post-fix.

Two follow-up sweeps that would be more informative if pursued:

1. **Stage2-compile sweep.**  Pick a Haskell program with moderate
   complexity, ssh to pmacg5, run `ghc --make` there under default
   RTS, check the binary works.  This is the only sweep that
   actually exercises the previously-broken code path.
2. **Audit other bit-packed unboxed arrays in popular libraries**
   (`vector`'s `Bit` storage, `bytestring`'s internal bit handling,
   etc.).  The Bool bug came from `setByteArray# nbytes` +
   `readWordArray#` mismatched granularity; same anti-pattern
   could exist in third-party packages without anyone noticing on
   LE.  Session-53 HANDOFF flagged this as "Fourth" priority.
