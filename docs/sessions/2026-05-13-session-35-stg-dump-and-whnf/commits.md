# Session 35 commits

(SHA to be backfilled after commit lands.)

- `<sha>`  Session 35: `s71L` source-line pinned, plus the
  revelation that probe33/probe35 have been reading wrapping-thunk
  memory.  `-ddump-stg-final` on `AArch64/CodeGen.hs` shows `s71L`
  is the `ncgPlatform config1` thunk in `getRegister` (line 406
  of CodeGen.hs), inlined into `getRegister'`'s `MO_XX_Conv` case
  (line 652).  Built probe35-v1 (4-word closure dump + `seq v`
  WHNF-verifier), captured 6 REFINE samples in 3 distinct zones
  (env-lens {650,700}, {850,900}, {1650,1700}; all missing
  typeclass-dictionary variables: `$dNum_a1kb`, `$dNum_a1ko`,
  `$dOrd_a1k0`).  BEFORE/AFTER info-pointers consistently
  `_s7iu_info` / `_s7iW_info`, 16 bytes apart in `__DATA,__const`,
  both from `Simplify/Env.o`.  Follow-up `-ddump-stg-final` on
  `Env.hs` (with probe35 applied) revealed why: GHC compiles
  `aToWordzh (unsafeCoerce v :: Any)` such that `aToWordzh` is
  called on the wrapping thunk that holds `unsafeCoerce v`, not on
  v itself.  All info-pointers captured throughout sessions 33-35
  have been wrapping-thunk info-tables, not v's actual closure
  header.  Session 34's "AArch64.CodeGen ncgPlatform-config thunk"
  finding is dissolved.  Session ended CLEAN: probes reverted,
  stage1 rebuilt, stage2 redeployed to pmacg5, smoke-test PASS.
  Next-session priority: redesign probe using `GHC.Exts.unpackClosure#`
  (or a Cmm shim that bypasses `unsafeCoerce`) to read v's actual
  heap header.
