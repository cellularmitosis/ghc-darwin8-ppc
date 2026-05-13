# Commits — session 33

Session 33 was cut short for project reorganization.  No source
edits committed to GHC tree (probe33 remains in working tree as
an uncommitted modification, captured as
[`probe33-closure-dump.patch`](probe33-closure-dump.patch)).

- TBD — Session 33: stage2 GC bug investigation, round 15 (CUT SHORT; PROBE33-v1 closure-header dump captures 4 REFINE samples at 4 different heap addresses across 3 megablocks ALL sharing info ptr `_s71L_info` THUNK_1_0 at 0x08c62bac and the same w3 = `W#_con_info` at 0x092577e0; refines session 32's "no single virtual address" finding into "specific closure type" finding; PROBE33-v2 8-word dump deployed but sweep returned no REFINE samples in tested env-len range so v2 data not collected; source tree + stage2 DIRTY, must revert + rebuild + redeploy clean stage2 to return to v0.12.0).
