# Session 37 commits

- 751a01a Session 37: probe37
  dissolves session 36's "BLACKHOLE→IND swap missing" framing —
  `rts/Updates.h:48-67`'s `updateWithIndirection` macro sets
  `word[0] = stg_BLACKHOLE_info` *by design* and writes the tagged
  result at `word[1]`; `stg_IND_info` doesn't appear in this path.
  Probe37 (probe36 + dereference of `word[1] & ~3` as a 4-word read
  via `anyToAddr#`) was applied to `compiler/GHC/Core/Opt/Simplify/Env.hs`,
  built clean, deployed stage2 to pmacg5 + smoke-test PASS.  Sweep
  across env-len 600..2000 step 50 captured 2 panics at len=1650/1700
  (1650-1700 zone from session 36), both showing `_stg_BLACKHOLE_info`
  at v's `word[0]` and **`_ghc_GHCziTypesziVar_Id_con_info` (EXACT)
  at the indirectee's `word[0]`** — the thunk WAS evaluated, the
  result IS a fully-formed Id constructor closure with sensible
  Name/Unique/Type fields.  The panic body itself reveals the real
  bug: `InScope {wild_00 v_B1 allPositive}` — only 3 entries in a
  context that should have many more, missing the `$dOrd_a1k0`
  typeclass dictionary the simplifier is trying to look up.  At
  len=850 the panic shifts to `depSortStgBinds` "Found cyclic SCC"
  on `$trModule3_r1lT` and `$trModule4_r1lU` whose printed FVs
  (`{}` and `{$trModule3_r1lT}` respectively) do NOT form a cycle —
  a different victim of the same underlying corruption.  This is
  consistent with session 28's "one bug, multiple victim data
  structures, all UniqMap-backed" framing and dissolves the closure-
  shape probe trail of sessions 33-36 as a wild goose chase; the
  bug is GC-of-UniqMap-data-structures, not thunk-update on PPC
  unreg.  v0.12.0 ships unchanged; probe applied for measurement
  and reverted at session end; stage2 on pmacg5 rebuilt+redeployed
  clean.
