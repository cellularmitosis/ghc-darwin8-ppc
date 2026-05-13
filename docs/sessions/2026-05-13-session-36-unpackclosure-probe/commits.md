# Session 36 commits

(To be filled in by `git log --oneline` after final commits land.)

- `<SHA>` Session 36: `anyToAddr#` probe reveals v is `_stg_BLACKHOLE_info` at refineFromInScope panic; BLACKHOLE→IND swap missing on PPC unreg (probe36 verified clean on host + PPC, applied to Env.hs, swept env-len 600..2000, captured 4 panics in 2 zones, all word[0] = exactly `_stg_BLACKHOLE_info` (0x092592a4), word[1] tag=3 indirectee to evaluated Id, BEFORE == AFTER in every capture; session ended CLEAN with probe reverted + stage1 rebuilt + stage2 redeployed to pmacg5 + smoke-test OK).
- `<SHA>` Session 36 commits.md: backfill the SHA.
