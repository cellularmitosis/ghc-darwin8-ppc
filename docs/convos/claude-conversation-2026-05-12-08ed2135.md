# Claude Conversation Log

Session ID: 08ed2135-5c50-4992-8128-cf14932545fa
Date: 2026-05-12 04:35:25

---

## 👤 User

please read docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md and proceed

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md"
}


---

## 🤖 Claude

I have the handoff. Let me read the session workflow conventions and the session 28 narrative + findings to get fully oriented before starting work.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/findings.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch"
}


---

## 🤖 Claude

Got it. Let me check current date + state of things, then plan and start the session.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "date '+%Y-%m-%d %H:%M:%S %Z' && git -C /Users/cell/claude/ghc-darwin8-ppc log --format='%H %ad %s' --date=short -5",
  "description": "Check current date and recent commits"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git -C /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 status --short && echo \"---\" && git -C /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 log --format='%h %s' -3",
  "description": "Check GHC source tree state"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/ | tail -10",
  "description": "List recent session directories"
}


---

## 🤖 Claude


🔧 Using tool: ToolSearch
Input: {
  "query": "select:TodoWrite",
  "max_results": 1
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c 2>&1",
  "description": "Verify GC source files exist"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 'ls -la /opt/ghc-stage2/bin/ghc-real /opt/ghc-stage2/bin/ghc 2>&1 | head -5' 2>&1 | head -10",
  "description": "Confirm stage2 still deployed on pmacg5"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session-29 dir with plan + log scaffolding",
      "activeForm": "Setting up session-29 dir",
      "status": "in_progress"
    },
    {
      "content": "Read rts/sm/Scav.c::scavenge_block to understand insertion points",
      "activeForm": "Reading scavenge_block",
      "status": "pending"
    },
    {
      "content": "Design + implement PROBE29 (PROBE28 + per-closure-type histogram)",
      "activeForm": "Implementing PROBE29 histogram",
      "status": "pending"
    },
    {
      "content": "Rebuild RTS lib and redeploy stage2 to pmacg5",
      "activeForm": "Rebuilding RTS + deploying",
      "status": "pending"
    },
    {
      "content": "Run probe matrix (M5 -A1m -G1 PASS vs Big2 -A1m -G1 FAIL, 5 iters each)",
      "activeForm": "Running probe matrix",
      "status": "pending"
    },
    {
      "content": "Analyze histograms; identify suspect closure type",
      "activeForm": "Analyzing histogram diffs",
      "status": "pending"
    },
    {
      "content": "Audit Evac.c / Scav.c paths for the suspect closure type with PPC32 eyes",
      "activeForm": "Auditing GC paths for suspect type",
      "status": "pending"
    },
    {
      "content": "Revert probe + rebuild + redeploy clean stage2 at session end",
      "activeForm": "Cleaning up probe",
      "status": "pending"
    },
    {
      "content": "Write session-29 README/findings/HANDOFF/commits.md",
      "activeForm": "Writing session notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "mkdir -p /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts && mkdir -p /Users/cell/claude/ghc-darwin8-ppc/log/session29 && ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/",
  "description": "Create session-29 directory tree"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/log.md",
  "content": "# Session 29 \u2014 running log\n\nReal-time scratch log.  Decisions, dead ends, judgment calls \u2014 write\nliberally per CLAUDE.md \"Document everything\".  README.md /\nfindings.md / HANDOFF.md condense this at session end.\n\n## Starting state\n\n- Arrived: 2026-05-11 23:35 CDT (= 2026-05-12 UTC, matching the\n  session-26..28 slug convention).\n- v0.12.0 ships unchanged.  Stage2 on pmacg5 is the clean rebuild\n  from end of session 28 (`/opt/ghc-stage2/bin/ghc-real` mtime\n  2026-05-11 23:28, ~7 min before session start).\n- GHC source tree under `external/ghc-modern/ghc-9.2.8/` clean for\n  `rts/sm/GC.c`.  (The other M files in `git status` are the long-\n  standing project patches that have been in place since the build\n  was wired up.)\n- Per session-28 HANDOFF, plan is:\n  1. Re-apply PROBE28 patch.\n  2. Extend with per-closure-type histogram in `scavenge_block`.\n  3. Run matrix \u2192 diff PASS (M5 -A1m -G1) vs FAIL (Big2 -A1m -G1)\n     closure-type distributions.\n  4. Identify suspect type; audit `Evac.c` / `Scav.c` paths for it.\n- Skipping the optional `tests/run-tests.sh` baseline run \u2014 session\n  27 certified it green earlier today and session 28 ended with a\n  clean rebuild + redeploy.  Nothing has touched the tree since.\n\n## Plan for this session\n"
}


---

## 🤖 Claude

Now read the scavenge_block code to design the histogram insertion point precisely.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'scavenge_block\\|info->type\\|scavenge_one\\|scavenge_block_no_evac\\|^scavenge\\|case [A-Z_]*:' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c | head -80",
  "description": "Index scavenge_block in Scav.c"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'N_CLOSURE_TYPES\\|CONSTR\\|FUN\\|THUNK\\|enum.*type' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/ClosureTypes.h 2>/dev/null | head -80",
  "description": "Find closure-type enum"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 420,
  "limit": 75
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n '^scavenge_one\\|info->type\\|scavenge_one (' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c | sed -n '40,90p'",
  "description": "Find scavenge_one signature/dispatch"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n '^evacuate\\|^evacuate1\\|^copy_tag\\|^copy(\\|IS_FORWARDING_PTR\\|^static\\|info->type' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c | head -40",
  "description": "Find evacuate hook points"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'scavenge_one' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c | head -10",
  "description": "scavenge_one locations"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 681,
  "limit": 90
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 770,
  "limit": 85
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session-29 dir with plan + log scaffolding",
      "activeForm": "Setting up session-29 dir",
      "status": "completed"
    },
    {
      "content": "Read rts/sm/Scav.c::scavenge_block to understand insertion points",
      "activeForm": "Reading scavenge_block",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE29 (PROBE28 + per-closure-type histogram + fwd-ptr hits)",
      "activeForm": "Implementing PROBE29 histogram",
      "status": "in_progress"
    },
    {
      "content": "Rebuild RTS lib and redeploy stage2 to pmacg5",
      "activeForm": "Rebuilding RTS + deploying",
      "status": "pending"
    },
    {
      "content": "Run probe matrix (M5 -A1m -G1 PASS vs Big2 -A1m -G1 FAIL, 5 iters each)",
      "activeForm": "Running probe matrix",
      "status": "pending"
    },
    {
      "content": "Analyze histograms; identify suspect closure type",
      "activeForm": "Analyzing histogram diffs",
      "status": "pending"
    },
    {
      "content": "Audit Evac.c / Scav.c paths for the suspect closure type with PPC32 eyes",
      "activeForm": "Auditing GC paths for suspect type",
      "status": "pending"
    },
    {
      "content": "Revert probe + rebuild + redeploy clean stage2 at session end",
      "activeForm": "Cleaning up probe",
      "status": "pending"
    },
    {
      "content": "Write session-29 README/findings/HANDOFF/commits.md",
      "activeForm": "Writing session notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git apply ../../../docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch && git diff --stat rts/sm/GC.c",
  "description": "Apply PROBE28 patch to GC.c"
}


---

## 🤖 Claude

Now extend it with the closure-type histogram (in GC.c declare; in Scav.c bump; print in summary).

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 122,
  "limit": 25
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "#define PROBE28_MAX_GENS 8\nstatic StgWord64 probe28_gc_no = 0;\nstatic W_ probe28_pre_mut[PROBE28_MAX_GENS];\n/* PROBE28-END */",
  "new_string": "#define PROBE28_MAX_GENS 8\nstatic StgWord64 probe28_gc_no = 0;\nstatic W_ probe28_pre_mut[PROBE28_MAX_GENS];\n/* PROBE28-END */\n\n/* PROBE29-BEGIN \u2014 session-29 per-closure-type histogram.\n *\n * The probe28 data showed mut_list / static_objects scavenge paths\n * are not at fault \u2014 same load both ways, only Big2 crashes.\n * Remaining suspect: scavenge_block / evacuate dispatch by closure\n * type.  This histogram bumps a counter per closure scavenged in\n * rts/sm/Scav.c::scavenge_block, plus per-closure-type fresh-\n * evacuate and forwarding-pointer-hit counters from rts/sm/Evac.c.\n *\n * Counters are reset at the start of each GarbageCollect() call and\n * emitted as part of the post-GC summary debugBelch line.\n *\n * Indexed by info->type (which is 0..N_CLOSURE_TYPES-1 == 0..63).\n * Non-static so Scav.c and Evac.c can see them via `extern`.\n */\nW_ probe29_type_hist[64];\nW_ probe29_evac_fresh[64];\nW_ probe29_evac_fwd_hits;\n/* PROBE29-END */"
}


---

## 🤖 Claude

Now add the reset in pre-GC and the print in post-GC sections.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 485,
  "limit": 35
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "      for (uint32_t gg = 0; gg < pg_ng; gg++) {\n          W_ s = 0;\n          for (uint32_t c = 0; c < getNumCapabilities(); c++) {\n              s += countOccupied(capabilities[c]->mut_lists[gg]);\n          }\n          probe28_pre_mut[gg] = s;\n      }\n  }\n  /* PROBE28-END */",
  "new_string": "      for (uint32_t gg = 0; gg < pg_ng; gg++) {\n          W_ s = 0;\n          for (uint32_t c = 0; c < getNumCapabilities(); c++) {\n              s += countOccupied(capabilities[c]->mut_lists[gg]);\n          }\n          probe28_pre_mut[gg] = s;\n      }\n  }\n  /* PROBE28-END */\n\n  /* PROBE29-BEGIN \u2014 reset the per-closure-type histograms at the\n   * start of every GC so each emitted summary line reflects this\n   * GC only.\n   */\n  for (uint32_t tt = 0; tt < 64; tt++) {\n      probe29_type_hist[tt] = 0;\n      probe29_evac_fresh[tt] = 0;\n  }\n  probe29_evac_fwd_hits = 0;\n  /* PROBE29-END */"
}


---

## 🤖 Claude

Now the post-GC summary — extend it to print the histogram + fwd hits + fresh evac counts.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 1140,
  "limit": 45
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "      debugBelch(\" staticChain=%lu copiedW=%lu liveW=%lu liveB=%lu\\n\",\n                 (unsigned long)static_chain,\n                 (unsigned long)copied,\n                 (unsigned long)live_words,\n                 (unsigned long)live_blocks);\n  }\n  /* PROBE28-END */",
  "new_string": "      debugBelch(\" staticChain=%lu copiedW=%lu liveW=%lu liveB=%lu\\n\",\n                 (unsigned long)static_chain,\n                 (unsigned long)copied,\n                 (unsigned long)live_words,\n                 (unsigned long)live_blocks);\n  }\n  /* PROBE28-END */\n\n  /* PROBE29-BEGIN \u2014 emit per-closure-type histograms.  One line each\n   * for the scavenge_block dispatch histogram and the evacuate\n   * fresh-copy histogram, plus the forwarding-pointer hit count.\n   * Both lines are tagged with the same gc=<n> so they can be\n   * grouped post-hoc.  Skip zero buckets to keep the line short.\n   */\n  {\n      debugBelch(\"PROBE29 gc=%llu scav fwdHits=%lu\",\n                 (unsigned long long)probe28_gc_no,\n                 (unsigned long)probe29_evac_fwd_hits);\n      for (uint32_t tt = 0; tt < 64; tt++) {\n          if (probe29_type_hist[tt] != 0) {\n              debugBelch(\" t%u=%lu\",\n                         tt, (unsigned long)probe29_type_hist[tt]);\n          }\n      }\n      debugBelch(\"\\n\");\n      debugBelch(\"PROBE29 gc=%llu evac\",\n                 (unsigned long long)probe28_gc_no);\n      for (uint32_t tt = 0; tt < 64; tt++) {\n          if (probe29_evac_fresh[tt] != 0) {\n              debugBelch(\" e%u=%lu\",\n                         tt, (unsigned long)probe29_evac_fresh[tt]);\n          }\n      }\n      debugBelch(\"\\n\");\n  }\n  /* PROBE29-END */"
}


---

## 🤖 Claude

Now the Scav.c bump — and the Evac.c bumps.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 1,
  "limit": 50
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 50,
  "limit": 30
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "old_string": "#include <string.h> /* for memset */\n\nstatic void scavenge_large_bitmap (StgPtr p,\n                                   StgLargeBitmap *large_bitmap,\n                                   StgWord size );",
  "new_string": "#include <string.h> /* for memset */\n\n/* PROBE29-BEGIN \u2014 see rts/sm/GC.c for the definition.  Bumped per\n * closure scavenged in scavenge_block to identify which closure\n * type appears in Big2's failing GC but not in M5 -G1's passing GCs.\n */\nextern W_ probe29_type_hist[64];\n/* PROBE29-END */\n\nstatic void scavenge_large_bitmap (StgPtr p,\n                                   StgLargeBitmap *large_bitmap,\n                                   StgWord size );"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "old_string": "    ASSERT(bd->link == NULL);\n    ASSERT(LOOKS_LIKE_CLOSURE_PTR(p));\n    info = get_itbl((StgClosure *)p);\n\n    ASSERT(gct->thunk_selector_depth == 0);\n\n    q = p;\n    switch (info->type) {",
  "new_string": "    ASSERT(bd->link == NULL);\n    ASSERT(LOOKS_LIKE_CLOSURE_PTR(p));\n    info = get_itbl((StgClosure *)p);\n\n    /* PROBE29 \u2014 bump histogram per closure scavenged */\n    if ((uint32_t)info->type < 64) probe29_type_hist[info->type]++;\n\n    ASSERT(gct->thunk_selector_depth == 0);\n\n    q = p;\n    switch (info->type) {"
}


---

## 🤖 Claude

Now the Evac.c hooks — bump fwd_hits on forwarding-ptr branch, and fresh evac counter on the per-type dispatch.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 1,
  "limit": 40
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "old_string": "#include \"CheckUnload.h\" // n_unloaded_objects and markObjectCode\n\n#if defined(THREADED_RTS) && !defined(PARALLEL_GC)",
  "new_string": "#include \"CheckUnload.h\" // n_unloaded_objects and markObjectCode\n\n/* PROBE29-BEGIN \u2014 see rts/sm/GC.c for the definitions.\n *   probe29_evac_fresh[type]: closures freshly copied to to-space\n *     this GC, indexed by source-closure type.\n *   probe29_evac_fwd_hits: count of evacuate() calls that short-\n *     circuited on a forwarding pointer (already evacuated).\n */\nextern W_ probe29_evac_fresh[64];\nextern W_ probe29_evac_fwd_hits;\n/* PROBE29-END */\n\n#if defined(THREADED_RTS) && !defined(PARALLEL_GC)"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "old_string": "  info = ACQUIRE_LOAD(&q->header.info);\n  if (IS_FORWARDING_PTR(info))\n  {\n    /* Already evacuated, just return the forwarding address.",
  "new_string": "  info = ACQUIRE_LOAD(&q->header.info);\n  if (IS_FORWARDING_PTR(info))\n  {\n    probe29_evac_fwd_hits++;  /* PROBE29 */\n    /* Already evacuated, just return the forwarding address."
}


---

## 🤖 Claude

Now the fresh-evacuate dispatch — bump per-type counter at the top of the switch.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 850,
  "limit": 30
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "old_string": "  switch (INFO_PTR_TO_STRUCT(info)->type) {\n\n  case WHITEHOLE:\n      goto loop;",
  "new_string": "  /* PROBE29 \u2014 bump per-source-type counter for fresh-evacuate dispatch.\n   * Placed before the switch so it sees every type, including paths\n   * that goto loop (WHITEHOLE) \u2014 those will retry and re-bump, but\n   * that's a rare path and the over-count is bounded.\n   */\n  {\n      uint32_t pt = (uint32_t)INFO_PTR_TO_STRUCT(info)->type;\n      if (pt < 64) probe29_evac_fresh[pt]++;\n  }\n\n  switch (INFO_PTR_TO_STRUCT(info)->type) {\n\n  case WHITEHOLE:\n      goto loop;"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source ../../../scripts/cross-env.sh > /dev/null && ./hadrian/build --flavour=quick-cross -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>&1 | tail -50",
  "description": "Rebuild RTS lib with PROBE29"
}


---

## 🤖 Claude

Build succeeded. Now deploy to pmacg5.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && bash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -20",
  "description": "Deploy stage2 with PROBE29 to pmacg5"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "while [ ! -f /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.exit ] && [ $((SECONDS)) -lt 180 ]; do sleep 5; done; cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.output | tail -30; echo \"---exit---\"; cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.exit 2>/dev/null",
  "description": "Wait for deploy to finish and show output"
}


---

## 🤖 Claude


🔧 Using tool: ToolSearch
Input: {
  "query": "select:Monitor",
  "max_results": 1
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "wc -l /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.output && head -200 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.output",
  "description": "Inspect deploy output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.* 2>&1 ; ps -p $(cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.pid 2>/dev/null) 2>/dev/null | head",
  "description": "Check if deploy is still running"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 'ls -la /opt/ghc-stage2/bin/ghc-real' 2>&1; echo \"---\"; date '+%H:%M:%S'",
  "description": "Check stage2 timestamp on pmacg5"
}


---

## 🤖 Claude

The deploy didn't actually push — stage2 mtime is still 23:28. Let me look at the deploy script to understand what it does.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/scripts/deploy-stage2.sh"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && bash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -30",
  "description": "Deploy stage2 with PROBE29 (10min timeout)",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: ToolSearch
Input: {
  "query": "select:TaskStop",
  "max_results": 1
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -50 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/08ed2135-5c50-4992-8128-cf14932545fa/tasks/bh7ea75wl.output && echo \"---\" && ssh pmacg5 'ls -la /opt/ghc-stage2/bin/ghc-real'",
  "description": "Check first deploy output + binary timestamp"
}


---

## 🤖 Claude

PROBE29 is producing data. Let me stop the redundant second deploy and verify state.

---

## 🤖 Claude


🔧 Using tool: TaskStop
Input: {
  "task_id": "b95pjafpx"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/ClosureTypes.h"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/run-probe-matrix.sh"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/run-probe-matrix.sh",
  "content": "#!/bin/bash\n# Run the session-29 PROBE29 matrix.\n#\n# PROBE29 extends PROBE28 with per-closure-type histograms emitted\n# from rts/sm/Scav.c::scavenge_block and rts/sm/Evac.c::evacuate,\n# plus a forwarding-pointer hit count.  Output:\n#   PROBE28 gc=<n> N=<gen> maj=<0|1> ng=<gens> preMutN=... staticChain=... copiedW=... liveW=... liveB=...\n#   PROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...\n#   PROBE29 gc=<n> evac e<type>=<count> ...\n#\n# Matrix (focused on the cleanest discriminator):\n#   M5.hs    +RTS -A1m -G1 -RTS  \u2014 PASS baseline (session 28: 5/5 OK)\n#   Big2.hs  +RTS -A1m -G1 -RTS  \u2014 FAIL baseline (session 28: 5/5 panic)\n#\n# Goal: identify the closure type whose count diverges between the\n# passing M5 GCs and the failing Big2 GC.\n#\n# Usage:  ./run-probe-matrix.sh [SSH_HOST] [N_ITERS]\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nN_ITERS=\"${2:-5}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session29\"\nmkdir -p \"$LOGDIR\"\n\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\n\n# Stage inputs on pmacg5 (same as session 28).\nssh -q \"$PPC_HOST\" 'cat > /tmp/M5.hs' <<'EOF'\nmodule M5 where\nfive = (5::Int)\nsix = (6::Int)\nEOF\n\nssh -q \"$PPC_HOST\" 'cat > /tmp/Big2.hs' <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ntopK :: Ord a => Int -> [a] -> [(Int, a)]\ntopK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs\n  where swap (a, b) = (b, a)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n\nrun_cell () {\n    local input=\"$1\"\n    local label=\"$2\"\n    local rts=\"$3\"\n    local logbase=\"$LOGDIR/${input}-${label}\"\n    echo \"=== ${input}.hs iters=${N_ITERS} flags='${rts}' ===\"\n    local pass=0 fail=0\n    for i in $(seq 1 \"$N_ITERS\"); do\n        local log=\"${logbase}.iter${i}.log\"\n        ssh -q \"$PPC_HOST\" \"\n            cd /tmp\n            rm -f ${input}.hi ${input}.o\n            $DYLD $GHC_REAL -c ${input}.hs $rts 2>&1\n            echo \\\"GHC_EXIT=\\$?\\\"\n        \" > \"$log\" 2>&1\n        local rc\n        rc=$(grep -m1 '^GHC_EXIT=' \"$log\" | sed 's/GHC_EXIT=//' || echo '?')\n        local sig\n        if [ \"$rc\" = \"0\" ]; then\n            pass=$((pass+1)); sig=\"OK\"\n        else\n            fail=$((fail+1))\n            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found|not in scope)' \"$log\" 2>/dev/null | head -c 120)\n            [ -z \"$sig\" ] && sig=\"UNKNOWN_FAIL_rc=$rc\"\n        fi\n        local gcs\n        gcs=$(grep -c '^PROBE28 ' \"$log\" 2>/dev/null || echo 0)\n        printf '  iter%02d rc=%s gcs=%s : %s\\n' \"$i\" \"$rc\" \"$gcs\" \"$sig\"\n    done\n    echo \"  SUMMARY: pass=${pass} fail=${fail} of ${N_ITERS}\"\n    echo\n}\n\nrun_cell M5     a1m-g1  \"+RTS -A1m -G1 -RTS\"\nrun_cell Big2   a1m-g1  \"+RTS -A1m -G1 -RTS\"\n"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session-29 dir with plan + log scaffolding",
      "activeForm": "Setting up session-29 dir",
      "status": "completed"
    },
    {
      "content": "Read rts/sm/Scav.c::scavenge_block to understand insertion points",
      "activeForm": "Reading scavenge_block",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE29 (PROBE28 + per-closure-type histogram + fwd-ptr hits)",
      "activeForm": "Implementing PROBE29 histogram",
      "status": "completed"
    },
    {
      "content": "Rebuild RTS lib and redeploy stage2 to pmacg5",
      "activeForm": "Rebuilding RTS + deploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix (M5 -A1m -G1 PASS vs Big2 -A1m -G1 FAIL, 5 iters each)",
      "activeForm": "Running probe matrix",
      "status": "in_progress"
    },
    {
      "content": "Analyze histograms; identify suspect closure type",
      "activeForm": "Analyzing histogram diffs",
      "status": "pending"
    },
    {
      "content": "Audit Evac.c / Scav.c paths for the suspect closure type with PPC32 eyes",
      "activeForm": "Auditing GC paths for suspect type",
      "status": "pending"
    },
    {
      "content": "Revert probe + rebuild + redeploy clean stage2 at session end",
      "activeForm": "Cleaning up probe",
      "status": "pending"
    },
    {
      "content": "Write session-29 README/findings/HANDOFF/commits.md",
      "activeForm": "Writing session notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/run-probe-matrix.sh && bash /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/run-probe-matrix.sh pmacg5 5 2>&1",
  "description": "Run the PROBE29 matrix on pmacg5",
  "timeout": 600000
}


---

## 🤖 Claude

Matrix reproduces session 28 results cleanly. Now extract and compare PROBE29 histograms.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/log/session29/",
  "description": "List run logs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session29 && echo \"=== M5 iter1 PROBE28 lines ===\" && grep '^PROBE28 ' M5-a1m-g1.iter1.log && echo && echo \"=== Big2 iter1 PROBE28 lines ===\" && grep '^PROBE28 ' Big2-a1m-g1.iter1.log",
  "description": "Quick look at PROBE28 lines for both"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session29 && grep '^PROBE28 ' Big2-a1m-g1.iter1.log && echo \"---tail---\" && tail -50 Big2-a1m-g1.iter1.log",
  "description": "Big2 PROBE28 lines + tail"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session29 && echo \"=== M5 GC 13 (last, big-drop) ===\" && grep '^PROBE29 gc=13 ' M5-a1m-g1.iter1.log && echo && echo \"=== Big2 GC 17 (failing) ===\" && grep '^PROBE29 gc=17 ' Big2-a1m-g1.iter1.log",
  "description": "Compare histograms for M5 GC 13 vs Big2 GC 17"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session29 && grep -E '^(PROBE28|PROBE29) gc=17 ' Big2-a1m-g1.iter1.log; echo \"---\"; grep -E '^(PROBE28|PROBE29) gc=16 ' Big2-a1m-g1.iter1.log",
  "description": "Check if GC 17 emitted PROBE29 entries"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session29 && echo \"=== M5 GC 8 (similar copiedW\u2248468k) ===\" && grep '^PROBE29 gc=8 ' M5-a1m-g1.iter1.log",
  "description": "M5 GC 8 \u2014 similar live-set size to Big2 failing GC"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session29 && echo \"=== Big2 GCs 14-17, scav lines ===\" && grep -E '^PROBE29 gc=(14|15|16|17) scav' Big2-a1m-g1.iter1.log",
  "description": "Trace closure-type evolution across Big2's last GCs"
}


---

## 🤖 Claude

Let me write a quick differential analysis script and look at the suspect scavenge/evac paths.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/diff-histograms.sh",
  "content": "#!/bin/bash\n# Compute per-closure-type differential between a PASS GC and a FAIL GC.\n# Usage:  ./diff-histograms.sh PASS_LOG PASS_GC FAIL_LOG FAIL_GC\nset -euo pipefail\n\nPASS_LOG=\"$1\"\nPASS_GC=\"$2\"\nFAIL_LOG=\"$3\"\nFAIL_GC=\"$4\"\n\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nCTH=\"$REPO_ROOT/external/ghc-modern/ghc-9.2.8/includes/rts/storage/ClosureTypes.h\"\n\n# Map t<n> \u2192 name.\ntypename () {\n    local n=\"$1\"\n    awk -v n=\"$n\" '\n      /^#define +[A-Z_]+ +[0-9]+$/ {\n        if ($3 == n) { print $2; exit }\n      }' \"$CTH\"\n}\n\nparse_line () {\n    local log=\"$1\" gc=\"$2\" prefix=\"$3\"\n    grep \"^PROBE29 gc=${gc} ${prefix}\" \"$log\" | head -1 |\n        tr ' ' '\\n' | grep -oE \"^[te][0-9]+=[0-9]+$\" || true\n}\n\necho \"PASS log : $PASS_LOG (gc=$PASS_GC)\"\necho \"FAIL log : $FAIL_LOG (gc=$FAIL_GC)\"\necho\necho \"scavenge_block dispatch (per closure scavenged):\"\nprintf \"  %-30s %10s %10s %10s\\n\" \"TYPE\" \"PASS\" \"FAIL\" \"FAIL/PASS\"\n\npass_scav=$(parse_line \"$PASS_LOG\" \"$PASS_GC\" \"scav\")\nfail_scav=$(parse_line \"$FAIL_LOG\" \"$FAIL_GC\" \"scav\")\n\n# union of indices\nindices=$(printf '%s\\n%s\\n' \"$pass_scav\" \"$fail_scav\" | sed 's/^t//' | cut -d= -f1 | sort -un)\n\nfor t in $indices; do\n    p=$(echo \"$pass_scav\" | grep \"^t${t}=\" | cut -d= -f2 || true); p=${p:-0}\n    f=$(echo \"$fail_scav\" | grep \"^t${t}=\" | cut -d= -f2 || true); f=${f:-0}\n    ratio=$(awk -v p=\"$p\" -v f=\"$f\" 'BEGIN{ if(p+0==0){print(f+0==0?\"-\":\"NEW\")} else {printf \"%.2fx\", f/p} }')\n    name=$(typename \"$t\")\n    printf \"  %-30s %10d %10d %10s\\n\" \"$name($t)\" \"$p\" \"$f\" \"$ratio\"\ndone\n\necho\necho \"evacuate() dispatch (per closure freshly evacuated):\"\nprintf \"  %-30s %10s %10s %10s\\n\" \"TYPE\" \"PASS\" \"FAIL\" \"FAIL/PASS\"\n\npass_evac=$(parse_line \"$PASS_LOG\" \"$PASS_GC\" \"evac\")\nfail_evac=$(parse_line \"$FAIL_LOG\" \"$FAIL_GC\" \"evac\")\n\nindices=$(printf '%s\\n%s\\n' \"$pass_evac\" \"$fail_evac\" | sed 's/^e//' | cut -d= -f1 | sort -un)\n\nfor t in $indices; do\n    p=$(echo \"$pass_evac\" | grep \"^e${t}=\" | cut -d= -f2 || true); p=${p:-0}\n    f=$(echo \"$fail_evac\" | grep \"^e${t}=\" | cut -d= -f2 || true); f=${f:-0}\n    ratio=$(awk -v p=\"$p\" -v f=\"$f\" 'BEGIN{ if(p+0==0){print(f+0==0?\"-\":\"NEW\")} else {printf \"%.2fx\", f/p} }')\n    name=$(typename \"$t\")\n    printf \"  %-30s %10d %10d %10s\\n\" \"$name($t)\" \"$p\" \"$f\" \"$ratio\"\ndone\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/diff-histograms.sh && bash /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/diff-histograms.sh /Users/cell/claude/ghc-darwin8-ppc/log/session29/M5-a1m-g1.iter1.log 13 /Users/cell/claude/ghc-darwin8-ppc/log/session29/Big2-a1m-g1.iter1.log 17 2>&1",
  "description": "Diff M5 GC 13 vs Big2 GC 17 histograms"
}


---

## 🤖 Claude

Let me check histogram consistency across iters before doing the deep audit, and also fix the typename script.

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/diff-histograms.sh",
  "old_string": "    awk -v n=\"$n\" '\n      /^#define +[A-Z_]+ +[0-9]+$/ {\n        if ($3 == n) { print $2; exit }\n      }' \"$CTH\"",
  "new_string": "    awk -v n=\"$n\" '\n      /^#define +[A-Z_0-9]+ +[0-9]+$/ {\n        if ($3 == n) { print $2; exit }\n      }' \"$CTH\""
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session29 && for i in 1 2 3 4 5; do\n  echo \"=== Big2 iter $i GC 17 scav ===\" \n  grep '^PROBE29 gc=17 scav' Big2-a1m-g1.iter${i}.log\ndone",
  "description": "Compare Big2 GC 17 histograms across iters"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session29 && for i in 1 2 3 4 5; do\n  echo \"--- Big2 iter $i ---\"\n  echo -n \"PROBE28 last gc: \"; grep '^PROBE28 ' Big2-a1m-g1.iter${i}.log | tail -1 | grep -oE 'gc=[0-9]+ N=[0-9]+ maj=[0-9]+ ng=[0-9]+ preMut0=[0-9]+ staticChain=[0-9]+ copiedW=[0-9]+'\n  echo -n \"PROBE29 last scav gc: \"; grep '^PROBE29 .* scav' Big2-a1m-g1.iter${i}.log | tail -1 | sed 's/.*\\(gc=[0-9]\\+\\).*/\\1/'\ndone",
  "description": "Verify all 5 Big2 iters end at GC 17 with PROBE29 emitted"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'INFO_PTR_TO_STRUCT\\|TABLES_NEXT_TO_CODE' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/ClosureMacros.h | head -30",
  "description": "Find INFO_PTR_TO_STRUCT macro"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/ClosureMacros.h",
  "offset": 220,
  "limit": 120
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'RELAXED_LOAD\\|ACQUIRE_LOAD' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/stg/SMP.h | head -20",
  "description": "Find RELAXED_LOAD / ACQUIRE_LOAD definitions"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/stg/SMP.h",
  "offset": 455,
  "limit": 60
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'memcpy_words\\|memcpy_words(' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.h 2>&1 | head -10",
  "description": "Find memcpy_words"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'memcpy_words' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/ /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/ 2>/dev/null | head -10",
  "description": "Find memcpy_words across rts"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'copy_tag\\|memcpy' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c | head -20",
  "description": "Find copy_tag uses"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 125,
  "limit": 170
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'sizeofW\\b\\|StgHeader\\|^typedef struct StgClosure\\|^typedef struct .*Header' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/Closures.h | head -30",
  "description": "Find Closure/Header definitions"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn '^#define sizeofW\\|sizeofW(' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/stg/Types.h | head -10",
  "description": "Find sizeofW macro"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'define sizeofW' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/ 2>/dev/null | head -5",
  "description": "Find sizeofW macro definition"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/Rts.h",
  "offset": 105,
  "limit": 15
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 295,
  "limit": 110
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "awk '/^  switch \\(INFO_PTR_TO_STRUCT/,/^  barf/' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c | grep -E '^  case|copy_tag\\(|copy\\(|copyPart\\(|evacuate_BLACKHOLE|barf' | head -80",
  "description": "Map evacuate switch cases to copy variants"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 855,
  "limit": 130
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 580,
  "limit": 80
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'alloc_in_moving_heap\\|alloc_in_nonmoving_heap\\b' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/ | head -10",
  "description": "Find alloc_in_moving_heap"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 105,
  "limit": 30
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn '^todo_block_full\\|todo_block_full *(' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.h 2>/dev/null | head -5",
  "description": "Find todo_block_full"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c",
  "offset": 230,
  "limit": 90
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c",
  "offset": 320,
  "limit": 40
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'BLOCK_SIZE_W\\|BLOCK_ROUND_UP\\|#define BLOCK_SIZE\\b\\|#define MBLOCK_SIZE\\b' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/Block.h | head -20",
  "description": "Find BLOCK_SIZE definitions"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/Block.h",
  "offset": 17,
  "limit": 60
}


---

## 🤖 Claude

Let me save the PROBE29 patch now, then try the Big2.hs bisect (cheap experiment — strip imports one by one to find the trigger).

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git diff rts/sm/GC.c rts/sm/Scav.c rts/sm/Evac.c > /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/probe29-rts.patch && wc -l /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/probe29-rts.patch",
  "description": "Save PROBE29 patch"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session-29 dir with plan + log scaffolding",
      "activeForm": "Setting up session-29 dir",
      "status": "completed"
    },
    {
      "content": "Read rts/sm/Scav.c::scavenge_block to understand insertion points",
      "activeForm": "Reading scavenge_block",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE29 (PROBE28 + per-closure-type histogram + fwd-ptr hits)",
      "activeForm": "Implementing PROBE29 histogram",
      "status": "completed"
    },
    {
      "content": "Rebuild RTS lib and redeploy stage2 to pmacg5",
      "activeForm": "Rebuilding RTS + deploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix (M5 -A1m -G1 PASS vs Big2 -A1m -G1 FAIL, 5 iters each)",
      "activeForm": "Running probe matrix",
      "status": "completed"
    },
    {
      "content": "Analyze histograms; identify suspect closure type",
      "activeForm": "Analyzing histogram diffs",
      "status": "completed"
    },
    {
      "content": "Bisect Big2.hs \u2014 strip imports to identify trigger",
      "activeForm": "Bisecting Big2.hs imports",
      "status": "in_progress"
    },
    {
      "content": "Audit Evac.c / Scav.c paths for the suspect closure type with PPC32 eyes (initial pass done; deeper audit deferred)",
      "activeForm": "Auditing GC paths",
      "status": "in_progress"
    },
    {
      "content": "Revert probe + rebuild + redeploy clean stage2 at session end",
      "activeForm": "Cleaning up probe",
      "status": "pending"
    },
    {
      "content": "Write session-29 README/findings/HANDOFF/commits.md",
      "activeForm": "Writing session notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/big2-bisect.sh",
  "content": "#!/bin/bash\n# Bisect Big2.hs progressively to find which import/declaration triggers\n# the stage2 GC bug (deterministic panic at GC 17 under -A1m -G1).\n#\n# Each variant is run 3 iters (deterministic \u2014 but redundant runs catch\n# any flakes).  We expect EXACTLY the trigger removal to flip pass=0\n# fail=3 \u2192 pass=3 fail=0.\n#\n# Usage:  ./big2-bisect.sh [SSH_HOST] [N_ITERS]\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nN_ITERS=\"${2:-3}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session29\"\nmkdir -p \"$LOGDIR\"\n\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\nRTS_FLAGS=\"+RTS -A1m -G1 -RTS\"\n\n# Variants:\n#   B0 \u2014 the original Big2.hs (control: should fail 3/3)\n#   B1 \u2014 drop topK + its where-bound swap\n#   B2 \u2014 also drop Data.Map.Strict import\n#   B3 \u2014 also drop scaleAndShift + cumsum\n#   B4 \u2014 bare module with no imports (essentially M5)\n\ncat > /tmp/B0.hs <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ntopK :: Ord a => Int -> [a] -> [(Int, a)]\ntopK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs\n  where swap (a, b) = (b, a)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n\n# B1: drop topK + its where-bound swap\ncat > /tmp/B1.hs <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n\n# B2: also drop Data.Map.Strict import (+ freqMap, countOf)\ncat > /tmp/B2.hs <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\nimport Data.Maybe (fromMaybe)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n\n# B3: also drop scaleAndShift + cumsum, keep dedup/shift/allPositive\ncat > /tmp/B3.hs <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\nEOF\n\n# B4: bare module\ncat > /tmp/B4.hs <<'EOF'\nmodule Big2 where\nfoo :: Int -> Int\nfoo x = x + 1\nEOF\n\nfor v in B0 B1 B2 B3 B4; do\n  scp -q /tmp/${v}.hs \"$PPC_HOST:/tmp/${v}.hs\"\ndone\n\nrun_v () {\n    local v=\"$1\"\n    echo \"=== ${v}.hs iters=${N_ITERS} ===\"\n    local pass=0 fail=0\n    for i in $(seq 1 \"$N_ITERS\"); do\n        local log=\"$LOGDIR/bisect-${v}.iter${i}.log\"\n        ssh -q \"$PPC_HOST\" \"\n            cd /tmp\n            rm -f ${v}.hi ${v}.o\n            $DYLD $GHC_REAL -c ${v}.hs $RTS_FLAGS 2>&1\n            echo \\\"GHC_EXIT=\\$?\\\"\n        \" > \"$log\" 2>&1\n        local rc\n        rc=$(grep -m1 '^GHC_EXIT=' \"$log\" | sed 's/GHC_EXIT=//')\n        if [ \"$rc\" = \"0\" ]; then\n            pass=$((pass+1)); sig=\"OK\"\n        else\n            fail=$((fail+1))\n            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|<<loop>>|internal error|refineFromInScope|depSortStgBinds|not in scope)' \"$log\" 2>/dev/null | head -c 100)\n            [ -z \"$sig\" ] && sig=\"UNKNOWN_FAIL_rc=$rc\"\n        fi\n        local gcs\n        gcs=$(grep -c '^PROBE28 ' \"$log\" 2>/dev/null || echo 0)\n        printf '  iter%02d rc=%s gcs=%s : %s\\n' \"$i\" \"$rc\" \"$gcs\" \"$sig\"\n    done\n    echo \"  SUMMARY: pass=${pass} fail=${fail} of ${N_ITERS}\"\n    echo\n}\n\nfor v in B0 B1 B2 B3 B4; do run_v \"$v\"; done\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/big2-bisect.sh && bash /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/big2-bisect.sh pmacg5 3 2>&1",
  "description": "Run Big2.hs bisect",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 'diff /tmp/Big2.hs /tmp/B0.hs; echo \"Big2 md5:\"; md5 -q /tmp/Big2.hs 2>/dev/null || md5sum /tmp/Big2.hs; echo \"B0 md5:\"; md5 -q /tmp/B0.hs 2>/dev/null || md5sum /tmp/B0.hs'",
  "description": "Compare Big2.hs vs B0.hs contents"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\nrm -f Big2.hi Big2.o\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1 | grep -E \"panic|PROBE28 gc=17\" | head -5\necho \"rc=$?\"\necho \"---\"\necho \"Now compile as B0.hs at /tmp/B0.hs (identical content):\"\nrm -f Big2.hi Big2.o B0.hi B0.o\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c B0.hs +RTS -A1m -G1 -RTS 2>&1 | grep -E \"panic|PROBE28 gc=1[5-9]\" | head -10\necho \"rc=$?\"\n'",
  "description": "Compare Big2.hs vs B0.hs runtime behavior"
}


---

## 🤖 Claude

Filename-sensitive! Byte-identical source, but `Big2.hs` panics at GC 17 while `B0.hs` succeeds. The bug is heap-layout dependent, not source-content dependent.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\nfor name in Big2 B0 BB BigTwo X Big22 Big2a aBig2 ABCDEF; do\n  cp Big2.hs /tmp/${name}.hs\n  rm -f Big2.hi Big2.o ${name}.hi ${name}.o\n  out=$(DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c ${name}.hs +RTS -A1m -G1 -RTS 2>&1)\n  rc=$?\n  gcs=$(echo \"$out\" | grep -c \"^PROBE28 gc=\")\n  panic=$(echo \"$out\" | grep -c \"panic\")\n  printf \"  %-10s rc=%d gcs=%2d panic=%d\\n\" \"$name.hs\" \"$rc\" \"$gcs\" \"$panic\"\ndone\n'",
  "description": "Test filename sensitivity"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\nfor name in A AA AAA AAAA AAAAA AAAAAA B BB BBB BBBB BBBBB; do\n  cp Big2.hs /tmp/${name}.hs\n  rm -f Big2.hi Big2.o ${name}.hi ${name}.o\n  out=$(DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c ${name}.hs +RTS -A1m -G1 -RTS 2>&1)\n  rc=$?\n  gcs=$(echo \"$out\" | grep -c \"^PROBE28 gc=\")\n  panic=$(echo \"$out\" | grep -c \"panic\\|Bus error\\|Segmentation\\|impossible\")\n  sig=$(echo \"$out\" | grep -m1 -E \"panic|error|impossible|Bus|Segmentation|not in scope\" | head -c 60)\n  printf \"  %-10s rc=%d gcs=%2d panic=%d %s\\n\" \"$name.hs\" \"$rc\" \"$gcs\" \"$panic\" \"$sig\"\ndone\n'",
  "description": "Probe filename-length sensitivity"
}


---

## 🤖 Claude

The filename sensitivity is a major finding. Let me capture this data and one more confirmation, then revert the probe and write session notes.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\n# Check default -G2 too \u2014 does filename also affect it?\nfor name in Big2 BB BBB X AAA; do\n  rm -f Big2.hi Big2.o ${name}.hi ${name}.o\n  out=$(DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c ${name}.hs +RTS -A1m -RTS 2>&1)\n  rc=$?\n  gcs=$(echo \"$out\" | grep -c \"^PROBE28 gc=\")\n  fail=$(echo \"$out\" | grep -cE \"panic|impossible|Bus error|Segmentation|not in scope\")\n  printf \"  -A1m  %-10s rc=%d gcs=%2d fail=%d\\n\" \"$name.hs\" \"$rc\" \"$gcs\" \"$fail\"\ndone\necho\nfor name in Big2 BB BBB X AAA; do\n  rm -f Big2.hi Big2.o ${name}.hi ${name}.o\n  out=$(DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c ${name}.hs +RTS -A2m -G1 -RTS 2>&1)\n  rc=$?\n  gcs=$(echo \"$out\" | grep -c \"^PROBE28 gc=\")\n  fail=$(echo \"$out\" | grep -cE \"panic|impossible|Bus error|Segmentation|not in scope\")\n  printf \"  -A2m -G1  %-10s rc=%d gcs=%2d fail=%d\\n\" \"$name.hs\" \"$rc\" \"$gcs\" \"$fail\"\ndone\n'",
  "description": "Confirm filename effect on -A1m default and -A2m -G1"
}


---

## 🤖 Claude

Now let me revert the source, rebuild clean, redeploy, and write the session notes.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session-29 dir with plan + log scaffolding",
      "activeForm": "Setting up session-29 dir",
      "status": "completed"
    },
    {
      "content": "Read rts/sm/Scav.c::scavenge_block to understand insertion points",
      "activeForm": "Reading scavenge_block",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE29 (PROBE28 + per-closure-type histogram + fwd-ptr hits)",
      "activeForm": "Implementing PROBE29 histogram",
      "status": "completed"
    },
    {
      "content": "Rebuild RTS lib and redeploy stage2 to pmacg5",
      "activeForm": "Rebuilding RTS + deploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix (M5 -A1m -G1 PASS vs Big2 -A1m -G1 FAIL, 5 iters each)",
      "activeForm": "Running probe matrix",
      "status": "completed"
    },
    {
      "content": "Analyze histograms; identify suspect closure type",
      "activeForm": "Analyzing histogram diffs",
      "status": "completed"
    },
    {
      "content": "Bisect Big2.hs \u2014 strip imports to identify trigger (uncovered filename sensitivity instead)",
      "activeForm": "Bisecting Big2.hs",
      "status": "completed"
    },
    {
      "content": "Audit Evac.c / Scav.c paths for the suspect closure type with PPC32 eyes (partial)",
      "activeForm": "Auditing GC paths",
      "status": "completed"
    },
    {
      "content": "Revert probe + rebuild + redeploy clean stage2 at session end",
      "activeForm": "Cleaning up probe",
      "status": "in_progress"
    },
    {
      "content": "Write session-29 README/findings/HANDOFF/commits.md",
      "activeForm": "Writing session notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git checkout rts/sm/GC.c rts/sm/Scav.c rts/sm/Evac.c && git status --short rts/sm/",
  "description": "Revert probe sources"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source ../../../scripts/cross-env.sh > /dev/null && ./hadrian/build --flavour=quick-cross -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>&1 | tail -10",
  "description": "Rebuild RTS clean",
  "timeout": 120000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && bash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -15",
  "description": "Deploy clean stage2",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\nrm -f Big2.hi Big2.o\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1 | tail -5\necho \"rc=$?\"\n'",
  "description": "Verify clean stage2 reproduces bug and no PROBE noise"
}


---

## 🤖 Claude

Source clean, stage2 redeployed, bug still reproduces. Now write up the session notes.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git status --short rts/sm/",
  "description": "Confirm rts/sm clean"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la /Users/cell/claude/ghc-darwin8-ppc/log/session29/ | head -20",
  "description": "List run logs"
}


---

## 🤖 Claude

Now write the session notes — log, README, findings, HANDOFF, commits.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/log.md",
  "content": "# Session 29 \u2014 running log\n\nReal-time scratch log.  Decisions, dead ends, judgment calls \u2014 write\nliberally per CLAUDE.md \"Document everything\".  README.md /\nfindings.md / HANDOFF.md condense this at session end.\n\n## Starting state\n\n- Arrived: 2026-05-11 23:35 CDT (= 2026-05-12 UTC, matching the\n  session-26..28 slug convention).\n- v0.12.0 ships unchanged.  Stage2 on pmacg5 is the clean rebuild\n  from end of session 28 (`/opt/ghc-stage2/bin/ghc-real` mtime\n  2026-05-11 23:28, ~7 min before session start).\n- GHC source tree under `external/ghc-modern/ghc-9.2.8/` clean for\n  `rts/sm/GC.c`.  (The other M files in `git status` are the long-\n  standing project patches that have been in place since the build\n  was wired up.)\n- Per session-28 HANDOFF, plan is:\n  1. Re-apply PROBE28 patch.\n  2. Extend with per-closure-type histogram in `scavenge_block`.\n  3. Run matrix \u2192 diff PASS (M5 -A1m -G1) vs FAIL (Big2 -A1m -G1)\n     closure-type distributions.\n  4. Identify suspect type; audit `Evac.c` / `Scav.c` paths for it.\n- Skipping the optional `tests/run-tests.sh` baseline run \u2014 session\n  27 certified it green earlier today and session 28 ended with a\n  clean rebuild + redeploy.  Nothing has touched the tree since.\n\n## Plan for this session\n\n1. Apply PROBE28 patch (session 28's RTS-side per-GC probe).\n2. Extend with PROBE29: per-closure-type counters bumped in\n   `rts/sm/Scav.c::scavenge_block` (per closure scavenged) and\n   `rts/sm/Evac.c::evacuate` (per fresh-evacuated closure), plus a\n   forwarding-pointer-hit counter.  Counters indexed by `info->type`\n   (0..63 \u2014 N_CLOSURE_TYPES = 64).  Reset at start of every\n   `GarbageCollect()` and printed in two new `debugBelch` lines as\n   part of the per-GC summary.\n3. Rebuild RTS lib only (~5 s), redeploy stage2 to pmacg5 via\n   `deploy-stage2.sh` (~3 min \u2014 cross-link of the 193 MB stage2 ghc\n   binary).\n4. Run matrix on the cleanest discriminator pair: M5 `-A1m -G1`\n   (PASS, 5 iters) and Big2 `-A1m -G1` (FAIL, 5 iters).\n5. Diff histograms PASS vs FAIL.\n\n## Step-by-step\n\n### Step 1 \u2014 apply PROBE28, extend to PROBE29\n\nMechanics:\n\n```bash\ncd external/ghc-modern/ghc-9.2.8\ngit apply ../../docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch\n# Then hand-edited rts/sm/GC.c to add PROBE29 declarations + reset + print;\n# rts/sm/Scav.c with the bump in scavenge_block (after info = get_itbl());\n# rts/sm/Evac.c with the fwd-ptr hit bump (line ~810) and the per-type\n# fresh-evac bump (line ~852, just before the switch).\n```\n\nPROBE29 design notes:\n\n- `W_ probe29_type_hist[64]` \u2014 bumped per closure scavenged in\n  `scavenge_block`.\n- `W_ probe29_evac_fresh[64]` \u2014 bumped per closure freshly evacuated\n  (i.e. not short-circuiting on a forwarding pointer) in `evacuate`.\n- `W_ probe29_evac_fwd_hits` \u2014 bumped on every forwarding-pointer\n  hit in `evacuate`.\n- All declared non-static in `GC.c`; `extern` in `Scav.c` / `Evac.c`.\n- Output lines:\n  ```\n  PROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...\n  PROBE29 gc=<n> evac e<type>=<count> ...\n  ```\n- Zero buckets are skipped to keep the lines compact.\n\n### Step 2 \u2014 RTS rebuild + deploy\n\nRTS rebuild: 4.25 s (correct Hadrian target per session-28's HANDOFF\ncorrection).  Deploy via `deploy-stage2.sh pmacg5`: ~3 min (the\ndeploy includes the full stage2 ghc cross-link).\n\nNOTE-1: my Bash tool kept invoking `deploy-stage2.sh` in background\nmode unexpectedly.  First invocation completed cleanly (exit 0) but\nthe completion notification arrived after I had checked the\nbinary's mtime once and noticed it was still the session-28\nartifact \u2014 so I impatiently kicked off a second deploy concurrently,\nthen stopped it via TaskStop once the first one's completion event\nlanded.  No harm: the two deploys produce identical bits and rsync's\nlast-writer-wins semantics keep the result consistent.  Lesson: be\npatient about background-task completion events instead of\ndouble-fired commands.\n\nSmoke test confirmed the probe is emitting.  Three GCs visible\n(one for `ghc --version`, two for the compile-and-run test).  Mix of\nclosure types in the histograms looked sane: high counts of CONSTR\nvariants (1, 2, 4), THUNK variants (15, 16, 18), and `e38`\n(BLACKHOLE) which appears only in evacuate (BLACKHOLE has its own\nshort-circuit path in `evacuate` and never reaches `scavenge_block`'s\nmain loop).\n\n### Step 3 \u2014 run probe matrix\n\n[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) runs\neach cell 5\u00d7, captures all stderr per iter to `log/session29/`.\n\nResults:\n\n```\n=== M5.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===\n  iter01..05 rc=0 gcs=13 : OK   \u2192  pass=5 fail=0\n\n=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===\n  iter01..05 rc=1 gcs=17 : panic at GC 17  \u2192  pass=0 fail=5\n```\n\nReproduces session 28 exactly.  All 5 Big2 iters panic at GC 17\nwith the STG-time `refineFromInScope` signature.\n\n### Step 4 \u2014 histograms across iters\n\nSampled the PROBE29 line for GC 17 across all 5 Big2 iters.\n**Byte-for-byte identical** \u2014 every closure-type count, every fwd-\nhit, every metric matches.  Confirms full determinism of the bug:\nsame input \u2192 same GC behavior \u2192 same crash.\n\n### Step 5 \u2014 histogram diff M5 GC 13 (PASS) vs Big2 GC 17 (FAIL)\n\nWrote [`scripts/diff-histograms.sh`](scripts/diff-histograms.sh)\nto normalize and pretty-print the diff.  Initial run found bug in\nthe typename lookup (regex excluded digits in symbol names like\nCONSTR_1_0); fixed.\n\nKey data (M5 GC 13 vs Big2 GC 17 scav histogram):\n\n| Type                 | M5    | Big2  | Ratio  |\n|----------------------|------:|------:|-------:|\n| CONSTR(1)            | 18361 | 22713 |  1.24x |\n| CONSTR_1_0(2)        | 12150 | 15929 |  1.31x |\n| CONSTR_2_0(4)        | 23677 | 27928 |  1.18x |\n| THUNK(15)            |  2732 |  3259 |  1.19x |\n| THUNK_1_0(16)        |  7698 | 10182 |  1.32x |\n| THUNK_2_0(18)        |  9767 | 13858 |  1.42x |\n| **ARR_WORDS(42)**    |  4853 |  8047 |**1.66x**|\n| MUT_ARR_PTRS_DIRTY(44)|    1 |    13 | 13.00x |\n| MUT_VAR_DIRTY(48)    |    60 |     3 |  0.05x |\n| BLACKHOLE (evac only)|   130 |   625 |  4.81x |\n\nBig2's copiedW at GC 17 is 464982; M5's at GC 13 is 366812 \u2014 Big2\nis doing ~27% more copying.  A uniform 1.27x scaling would mean\n\"workload differs but no closure type is over-represented.\"\nAnything above 1.27x is anomalous.\n\n**ARR_WORDS at 1.66x is the biggest workload-relative anomaly.**\nBut \u2014 critically \u2014 every closure type that appears in Big2 GC 17\nalso appears in Big2's earlier GCs (and in M5's GCs).  No type is\nunique to the failing case.\n\nNOTE-2: the histograms make the trigger LESS clean than I expected.\nIf the bug were \"scavenge of type X is buggy on PPC32\", we'd see X\nappearing only on failing runs, or only at the failing GC index.\nInstead we see WORKLOAD scaling \u2014 Big2 is just doing more of\neverything.  The trigger must be something else: heap layout, block\nboundary, or alignment.  See \"Step 6 \u2014 the filename experiment\"\nbelow.\n\n### Step 6 \u2014 bisect Big2.hs to identify the trigger\n\nStarted writing [`scripts/big2-bisect.sh`](scripts/big2-bisect.sh)\nthat progressively strips Big2.hs:\n\n- B0: identical to Big2.hs (control)\n- B1: drop `topK` + its `where`-bound `swap`\n- B2: also drop `Data.Map.Strict` import\n- B3: also drop `scaleAndShift` + `cumsum`\n- B4: bare module with one trivial declaration\n\nPlot twist: **B0 (byte-identical to Big2.hs) PASSED 3/3** \u2014 running\nto GC 18 successfully.  Big2.hs at the same input was panicking\n5/5 at GC 17 minutes earlier.\n\n`md5` confirmed the file contents are bit-identical.  The only\ndifference is the FILENAME on the command line: `Big2.hs` vs\n`B0.hs`.\n\nFollowup matrix (single iter each, same RTS flags):\n\n```\n  Big2.hs    rc=1 gcs=17 panic=1   (FAIL)\n  B0.hs      rc=0 gcs=18 panic=0   (PASS)\n  BB.hs      rc=0 gcs=18 panic=0\n  BigTwo.hs  rc=1 gcs=17 panic=0\n  X.hs       rc=0 gcs=18 panic=0\n  Big22.hs   rc=1 gcs=17 panic=0\n  Big2a.hs   rc=1 gcs=17 panic=0\n  aBig2.hs   rc=1 gcs=17 panic=0\n  ABCDEF.hs  rc=1 gcs=17 panic=0\n```\n\nThen length sweep:\n\n```\n  A.hs       rc=0 gcs=18 panic=0   (1 char)\n  AA.hs      rc=1 gcs=17 panic=1   (2 chars) FAIL\n  AAA..AAAAAA.hs   all FAIL (gcs=17)\n  B.hs       rc=0 gcs=18 panic=0\n  BB.hs      rc=0 gcs=18 panic=0\n  BBB..BBBBB.hs    all FAIL (gcs=17)\n```\n\nSo `A.hs` PASSES at 1 char, `AA.hs` FAILS at 2 chars.  But `B.hs`\nand `BB.hs` PASS; `BBB.hs` FAILS at 3 chars.  The threshold depends\non the specific filename text, not just length.  This proves the\nbug is sensitive to *exact heap state* \u2014 every byte allocated for\nfilename storage / FastString / module-summary path shifts the\nheap layout enough to flip the trigger.\n\nNOTE-3: this kills the per-closure-type-bug hypothesis stone dead.\nA bug in `scavenge_block`'s dispatch on type X would fire whenever\nX is scavenged \u2014 and X is scavenged on every GC of every input.\nInstead, the bug fires only when the heap state at GC 17 reaches a\n*specific configuration*.  The trigger is **heap-layout-dependent**,\nnot source-dependent.\n\nAdditional cross-flag sweep (same filenames, different RTS):\n\n```\n-A1m default (=-G2):\n  Big2.hs PASS, BB.hs FAIL, BBB.hs FAIL, X.hs FAIL, AAA.hs FAIL\n\n-A2m -G1:\n  Big2.hs FAIL, BB.hs PASS, BBB.hs PASS, X.hs FAIL, AAA.hs PASS\n```\n\nDifferent allocation areas redistribute which inputs hit the\ntrigger.  Pattern is not length-monotonic \u2014 it's a complex function\nof (filename, RTS flags) \u2192 heap state at the critical GC \u2192 trigger\nyes/no.\n\n### Step 7 \u2014 wrap up\n\n- Saved [`probe29-rts.patch`](probe29-rts.patch) (229 lines, all\n  three files: GC.c, Scav.c, Evac.c).\n- `git checkout` reverted rts/sm/{GC,Scav,Evac}.c.\n- Rebuilt RTS clean (4.67 s), redeployed stage2.  Smoke test passes\n  with no PROBE noise; Big2.hs -A1m -G1 still panics deterministically\n  with the refineFromInScope (STG-time) signature.  Stage2 now\n  matches v0.12.0 again.\n\n## Open at session end\n\n- The closure-type histogram diff identified ARR_WORDS as the most\n  workload-disproportionate type \u2014 but the filename experiment\n  shows the trigger isn't actually per-type.  Audit direction for\n  session 30 should pivot to heap-geometry / alignment / block-\n  boundary concerns rather than continuing the type-based hunt.\n- The audit of `Evac.c::evacuate` / `copy_tag` / `Scav.c::scavenge_block`\n  that the session 28 HANDOFF queued was started but cut short\n  once the filename finding redirected priorities.  Notes in\n  findings.md.\n- Did not try `+RTS -DS` sanity-check rebuild \u2014 that needs DEBUG\n  RTS and possibly a stage2 link against `_debug.a`.  Good queue\n  item for session 30.\n\n## Time\n\n- Session start: 23:35 CDT.\n- Session end: ~00:30 CDT (next day in UTC, 2026-05-12).\n- Total: ~2 h.  (HANDOFF estimate was 5\u20137 h; the filename\n  discovery short-circuited the planned audit phase and is a much\n  more important data point to capture than a slower-paced audit.)\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/README.md",
  "content": "# Session 29 \u2014 stage2 GC bug, round 11 (PROBE29 per-closure-type histogram; the filename-sensitivity plot twist)\n\n**Dates:** 2026-05-12 (continuing the stage2 GC bug hunt).\n\n**Status on arrival:** v0.12.0 ships unchanged.  Session 28 nailed\nthe \"one bug, two victim data structures\" framing (PROBE28 timing\nperturbation flipped Big2 `-A1m -G1` from session-27's TC-time\n\"swap not in scope\" signature to STG-time `refineFromInScope`,\nproving they're the same root corruption with different downstream\nvictims).  Session 28 also ruled out `mut_list scavenge` and\n`static_objects scavenge` paths.  Remaining suspects per session\n28's HANDOFF: `rts/sm/Evac.c::evacuate / copy_tag / copy`,\n`rts/sm/Scav.c::scavenge_block dispatch`, forwarding-pointer\nmachinery, info-table reads on PPC32.  Top queued item: extend\nPROBE28 with a per-closure-type histogram to identify which type\nfires the bug.\n\n**Status on exit:**\n\n- **PROBE29 implemented** as additions to `rts/sm/GC.c`\n  (declarations + reset + per-GC print), `rts/sm/Scav.c::scavenge_block`\n  (bump per closure scavenged), `rts/sm/Evac.c::evacuate`\n  (forwarding-pointer hit count + bump per fresh evacuation).\n  Patch saved at [`probe29-rts.patch`](probe29-rts.patch); reverted\n  before session end, clean stage2 redeployed to pmacg5.\n- **Probe rebuilt + redeployed**, matrix run (M5 `-A1m -G1` 5/5\n  PASS, Big2 `-A1m -G1` 5/5 FAIL at GC 17 \u2014 reproduces session 28\n  exactly).  Source reverted, clean stage2 redeployed.  v0.12.0\n  ships unchanged.\n- **Histograms across all 5 Big2 failing-GC iters are BYTE-IDENTICAL.**\n  fwdHits=51890, every t<n> count identical.  Full determinism\n  confirmed.\n- **Histogram diff (M5 GC 13 PASS vs Big2 GC 17 FAIL):** largest\n  workload-relative anomaly is **ARR_WORDS at 1.66x** (4853 vs\n  8047).  THUNK_2_0 at 1.42x, CONSTR_1_0 at 1.31x, THUNK_1_0 at\n  1.32x.  In evac only: **BLACKHOLE at 4.81x** (130 vs 625).\n  But \u2014 **no closure type is unique to Big2's failing GC**; every\n  type present in GC 17 also appeared in earlier GCs.  See\n  [findings.md](findings.md) for the full diff.\n- **\ud83d\udfe5 Major finding \u2014 the bug is filename-sensitive.**  Compiling\n  the byte-identical Big2.hs source under the filename `Big2.hs`\n  panics 5/5 at GC 17.  Compiling the SAME bytes under filename\n  `B0.hs` (or `BB.hs`, or `X.hs`) **passes** through GC 18.  The\n  trigger depends on cumulative heap state, not source content.\n  Length sweeps show `A.hs` (1 char) passes but `AA.hs` (2 chars)\n  fails; `B.hs` and `BB.hs` pass but `BBB.hs` fails.  Different RTS\n  flags shift which filenames trigger the bug.  **This rules out a\n  per-closure-type scavenge bug** \u2014 such a bug would fire whenever\n  type X is scavenged, not at specific (filename, flags) tuples.\n  See [findings.md](findings.md) for the full data + interpretation.\n- **Implication for next-session audit direction:** the bug is in\n  heap geometry, block-boundary / alignment, or info-table-read\n  paths that depend on EXACT memory layout.  Per-closure-type audit\n  of `scavenge_block`'s switch dispatch is unlikely to find it.\n  Better directions: (a) rebuild RTS with `DEBUG` / `-DS` sanity\n  checks to catch corruption inside GC, (b) audit block/MBLOCK\n  boundary handling on PPC32 with 4 KB blocks, (c) audit forwarding-\n  pointer + info-pointer 32-bit alignment paths, (d) per-closure-\n  SIZE histogram (rather than per-type) to see whether large/odd-\n  sized closures correlate with the trigger.\n- v0.12.0 unchanged.  Source tree clean at session end.  Stage2 on\n  pmacg5 rebuilt+redeployed to match v0.12.0.  No commits to the\n  GHC tree this session.\n\nHANDOFF for session 30: see [`HANDOFF.md`](HANDOFF.md).  Top of\nqueue: rebuild stage2 with debug sanity checks, then audit block-\nboundary / alignment paths in `rts/sm/Evac.c` and `rts/sm/GCUtils.c`.\nHeap-layout sensitivity is the new framing.\n\n## What we did, in order\n\n### Step 1 \u2014 design + implement PROBE29\n\nPROBE29 = PROBE28 + per-closure-type histograms:\n\n1. **`rts/sm/GC.c`** \u2014 declare `W_ probe29_type_hist[64]`,\n   `W_ probe29_evac_fresh[64]`, `W_ probe29_evac_fwd_hits` as non-\n   static (so Scav.c / Evac.c can extern them).  Reset all to 0 at\n   the start of every `GarbageCollect()` (right after PROBE28's\n   pre-GC mut_list snapshot).  Print two new lines as part of the\n   post-GC summary, skipping zero buckets:\n   ```\n   PROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...\n   PROBE29 gc=<n> evac e<type>=<count> ...\n   ```\n2. **`rts/sm/Scav.c`** \u2014 add `extern` for `probe29_type_hist`.\n   Bump it once per closure scavenged, right after\n   `info = get_itbl((StgClosure *)p);` in `scavenge_block`'s main\n   loop (line ~458 in the unpatched source).\n3. **`rts/sm/Evac.c`** \u2014 add `extern` for `probe29_evac_fresh` and\n   `probe29_evac_fwd_hits`.  Bump `fwd_hits` in the\n   `if (IS_FORWARDING_PTR(info))` branch of `evacuate` (line ~810).\n   Bump per-source-type counter just before the\n   `switch (INFO_PTR_TO_STRUCT(info)->type)` (line ~852).\n\nThe bump operations are one ALU op per closure scavenged / evacuated\n\u2014 millions per GC, but no I/O, so far less perturbing than\nPROBE28's debugBelch-per-GC.\n\n### Step 2 \u2014 rebuild + deploy\n\nRebuilt RTS lib in 4.25 s via:\n\n```bash\ncd external/ghc-modern/ghc-9.2.8\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\nStage2 smoke-test confirmed PROBE29 lines visible in stderr and the\nhistogram numbers were sane (high CONSTR / THUNK counts; BLACKHOLE\nappears only in evac as expected; e3 [CONSTR_0_1] and e38 [BLACKHOLE]\ncorrectly absent from scav since they short-circuit in evacuate).\n\n### Step 3 \u2014 probe matrix\n\n[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) runs\nthe two cells that cleanest discriminator pair from session 28:\n\n```\n=== M5.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===\n  iter01..05 rc=0 gcs=13 : OK      pass=5 fail=0\n\n=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===\n  iter01..05 rc=1 gcs=17 : panic   pass=0 fail=5\n```\n\nMatches session 28.\n\n### Step 4 \u2014 histogram diff\n\nWrote [`scripts/diff-histograms.sh`](scripts/diff-histograms.sh)\nthat parses the PROBE29 t<n>= / e<n>= tokens and prints a side-by-\nside comparison with closure-type names.\n\nDiffed M5 GC 13 (the last, \"big-drop\" major GC of a PASSING run)\nagainst Big2 GC 17 (the failing GC of a FAILING run).  Big2's\ncopiedW = 464982 vs M5's 366812 \u2014 Big2 is doing ~27% more copying,\nso a uniform 1.27x scaling means \"workload differs but no closure\ntype is over-represented per-unit-work.\"\n\nAnomalies (above the 1.27x workload baseline):\n\n- **ARR_WORDS (42): 1.66x** \u2014 3194 more closures in Big2.\n- **THUNK_2_0 (18): 1.42x** \u2014 4091 more.\n- **CONSTR_1_0 (2): 1.31x** \u2014 3779 more.\n- **THUNK_1_0 (16): 1.32x** \u2014 2484 more.\n- **BLACKHOLE (38, evac only): 4.81x** \u2014 495 more.\n- **MUT_ARR_PTRS_DIRTY (44): 13x** (but 1 \u2192 13 absolute \u2014 tiny).\n\nCrucially, **no closure type is unique to Big2's failing GC** \u2014\nevery type at GC 17 also appears in Big2's earlier GCs (which\nfinish successfully) and in M5's GCs.  The trigger isn't \"type X\nappearing for the first time.\"\n\n### Step 5 \u2014 Big2.hs bisect \u2192 filename plot twist\n\nWrote [`scripts/big2-bisect.sh`](scripts/big2-bisect.sh) to strip\nBig2.hs progressively (drop `topK`, drop `Data.Map.Strict`, etc.)\nand find which removal flipped fail\u2192pass.\n\nPlot twist: variant **B0 (byte-identical to Big2.hs)** PASSED 3/3\nunder the same `-A1m -G1` flags that crashed Big2.hs 5/5 minutes\nearlier.  `md5` confirmed the file contents are identical.\n\nThe only difference: the filename on the command line (`B0.hs`\nvs `Big2.hs`).\n\nFollowup sweep at fixed source content:\n\n```\n  Big2.hs    rc=1 gcs=17 panic   FAIL\n  B0.hs      rc=0 gcs=18         PASS\n  BB.hs      rc=0 gcs=18         PASS\n  BigTwo.hs  rc=1 gcs=17         FAIL\n  X.hs       rc=0 gcs=18         PASS\n  Big22.hs   rc=1 gcs=17         FAIL\n  Big2a.hs   rc=1 gcs=17         FAIL\n  aBig2.hs   rc=1 gcs=17         FAIL\n  ABCDEF.hs  rc=1 gcs=17         FAIL\n```\n\nLength sweep:\n\n```\n  A.hs       PASS    AA.hs      FAIL    AAA..AAAAAA.hs  FAIL\n  B.hs       PASS    BB.hs      PASS    BBB..BBBBB.hs   FAIL\n```\n\nSo the pass/fail boundary isn't simply length \u2014 it's specific to\nthe cumulative heap state induced by the filename bytes flowing\nthrough GHC's internal data structures.\n\nCross-flag check (same filenames, different RTS):\n\n```\n-A1m default (=-G2):\n  Big2.hs PASS, BB.hs FAIL, BBB.hs FAIL, X.hs FAIL, AAA.hs FAIL\n\n-A2m -G1:\n  Big2.hs FAIL, BB.hs PASS, BBB.hs PASS, X.hs FAIL, AAA.hs PASS\n```\n\nDifferent `-A` and `-G` flags shift which filenames trigger the\nbug \u2014 confirming the trigger is some specific *heap configuration*\nthat varies with allocation patterns.\n\n### Step 6 \u2014 revert + clean redeploy\n\n```bash\ncd external/ghc-modern/ghc-9.2.8\ngit checkout -- rts/sm/GC.c rts/sm/Scav.c rts/sm/Evac.c\n# Rebuild RTS (4.67 s)\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\nSmoke-test passes with no PROBE noise.  Big2.hs under `-A1m -G1`\nstill panics deterministically with the `refineFromInScope` (STG-\ntime) signature \u2014 clean v0.12.0-equivalent stage2 confirmed.\n\n## Status on exit\n\n- **v0.12.0 unchanged.**  Stage2 ships with the `+RTS -A1G` wrapper.\n- **No GHC-tree source edits committed this session.**  Probe lives\n  only as the patch in this session dir.\n- **Stage2 ghc on pmacg5 is the clean rebuild after probe revert.**\n- **Logs at** [`../../../log/session29/`](../../../log/session29/)\n  (gitignored).\n- **HANDOFF for session 30** queues debug-RTS rebuild + heap-\n  geometry / alignment audit (sees [`HANDOFF.md`](HANDOFF.md)).\n\n## Files added this session\n\n- [`README.md`](README.md), this; [`findings.md`](findings.md);\n  [`HANDOFF.md`](HANDOFF.md); [`log.md`](log.md);\n  [`commits.md`](commits.md) \u2014 writeup.\n- [`probe29-rts.patch`](probe29-rts.patch) \u2014 the PROBE29 patch as a\n  git-format diff over the unmodified `rts/sm/{GC,Scav,Evac}.c`.\n  Re-apply with `git apply` from inside `external/ghc-modern/ghc-9.2.8`.\n- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) \u2014\n  M5 / Big2 \u00d7 `-A1m -G1` (5 iters each).\n- [`scripts/diff-histograms.sh`](scripts/diff-histograms.sh) \u2014 pretty\n  diff of two PROBE29 GCs side-by-side, with closure type names.\n- [`scripts/big2-bisect.sh`](scripts/big2-bisect.sh) \u2014 the Big2.hs\n  variant matrix that uncovered the filename effect.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/findings.md",
  "content": "# Session 29 findings \u2014 PROBE29 histograms + the filename-sensitivity discovery\n\n## TL;DR\n\n- **PROBE29** (PROBE28 + per-closure-type histograms in\n  `scavenge_block` and `evacuate`, plus a forwarding-pointer-hit\n  counter) shows that under M5 `-A1m -G1` (PASS) and Big2 `-A1m -G1`\n  (FAIL), Big2's failing GC 17 has **no closure type that's absent\n  from M5's GCs**.  Every type in Big2 GC 17 also appears in M5 GC\n  1\u201313.\n- **Workload differs but no per-type smoking gun.**  Big2 GC 17 is\n  ~27% larger than M5 GC 13 in copiedW; nearly every closure type\n  scales by 1.1\u00d7\u20131.4\u00d7 \u2014 a uniform-workload increase.  Most\n  workload-disproportionate types are ARR_WORDS (1.66\u00d7 scav),\n  BLACKHOLE evacuate (4.81\u00d7), THUNK_2_0 (1.42\u00d7), but **none is the\n  trigger** (see filename experiment below).\n- **All 5 failing Big2 iters produce BYTE-IDENTICAL histograms at\n  GC 17** \u2014 fwdHits=51890, every `t<n>=` and `e<n>=` count\n  matching to the digit.  Bug is fully deterministic on input.\n- **\ud83d\udfe5 The bug is filename-sensitive.**  Byte-identical Big2.hs\n  source compiled under filename `Big2.hs` panics 5/5 at GC 17;\n  under filename `B0.hs` (or `BB.hs`, `X.hs`, `A.hs`) it PASSES at\n  GC 18.  `md5` confirms identical bytes.  The pass/fail boundary\n  isn't monotone in filename length \u2014 `A.hs` passes, `AA.hs` fails;\n  `BB.hs` passes, `BBB.hs` fails.  Different RTS flags shift which\n  filenames trigger.\n- **This rules out a per-closure-type scavenge / evacuate bug as\n  the root cause.**  Such a bug would fire whenever that type is\n  processed.  The bug instead requires a specific *heap state* \u2014\n  identical source bytes can produce wildly different heap layouts\n  depending on filename-derived allocations, and only some of those\n  layouts trigger it.\n- **New audit direction:** heap-block geometry, alignment, block-\n  boundary crossings, allocator state, info-table reads at specific\n  addresses \u2014 anything where exact memory layout matters on PPC32\n  (32-bit, big-endian, 4 KB blocks).  Per-closure-type audit of\n  `scavenge_block`'s switch is unlikely to find it.\n- v0.12.0 ships unchanged.  Probe reverted at session end; clean\n  stage2 redeployed.\n\n## The probe\n\n3 source files touched.  See [`probe29-rts.patch`](probe29-rts.patch)\nfor the diff.\n\n### Declarations + reset + print (`rts/sm/GC.c`)\n\n```c\n/* near consec_idle_gcs, after PROBE28's declarations */\nW_ probe29_type_hist[64];\nW_ probe29_evac_fresh[64];\nW_ probe29_evac_fwd_hits;\n\n/* at the start of each GarbageCollect(), after PROBE28's pre-GC mut snapshot */\nfor (uint32_t tt = 0; tt < 64; tt++) {\n    probe29_type_hist[tt] = 0;\n    probe29_evac_fresh[tt] = 0;\n}\nprobe29_evac_fwd_hits = 0;\n\n/* at end of GarbageCollect(), after PROBE28's summary line */\ndebugBelch(\"PROBE29 gc=%llu scav fwdHits=%lu\", ...);\nfor (tt < 64) if (probe29_type_hist[tt] != 0) debugBelch(\" t%u=%lu\", ...);\ndebugBelch(\"\\nPROBE29 gc=%llu evac\", ...);\nfor (tt < 64) if (probe29_evac_fresh[tt] != 0) debugBelch(\" e%u=%lu\", ...);\n```\n\n### Bumps (`rts/sm/Scav.c` and `rts/sm/Evac.c`)\n\nScav.c \u2014 bump in `scavenge_block`'s main loop:\n\n```c\ninfo = get_itbl((StgClosure *)p);\nif ((uint32_t)info->type < 64) probe29_type_hist[info->type]++;   /* PROBE29 */\n```\n\nEvac.c \u2014 bump on forwarding-pointer hit:\n\n```c\nif (IS_FORWARDING_PTR(info))\n{\n    probe29_evac_fwd_hits++;  /* PROBE29 */\n    /* existing code: shortcut to the forwarded address */\n}\n```\n\nEvac.c \u2014 bump per source-type on fresh evacuation, just before the\n`switch`:\n\n```c\n{\n    uint32_t pt = (uint32_t)INFO_PTR_TO_STRUCT(info)->type;\n    if (pt < 64) probe29_evac_fresh[pt]++;\n}\nswitch (INFO_PTR_TO_STRUCT(info)->type) { ... }\n```\n\nThe bumps are single ALU ops per closure \u2014 millions per GC but no\nI/O.  Far less perturbing than PROBE28's per-GC debugBelch.\n\n## Per-GC summary line format\n\nAfter PROBE28's `PROBE28 gc=\u2026` line, two new lines per GC:\n\n```\nPROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...\nPROBE29 gc=<n> evac e<type>=<count> ...\n```\n\nIndexed by `info->type` (0..63).  Zero buckets skipped for brevity.\n\n## Data \u2014 matrix under PROBE29\n\n```\n=== M5.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===\n  iter01..05 rc=0 gcs=13 OK            pass=5 fail=0\n\n=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===\n  iter01..05 rc=1 gcs=17 panic         pass=0 fail=5\n```\n\nReproduces session 28 exactly.\n\n## Determinism check\n\nAll 5 Big2 GC 17 PROBE29 lines are byte-identical:\n\n```\nPROBE29 gc=17 scav fwdHits=51890 t1=22713 t2=15929 t3=5424 t4=27928\n  t5=3947 t6=34 t7=12 t8=38 t9=1371 t10=930 t11=682 t15=3259\n  t16=10182 t17=516 t18=13858 t22=4018 t25=401 t39=244 t40=16\n  t42=8047 t43=244 t44=13 t46=8 t47=276 t48=3 t49=4 t52=1\n```\n\n`PROBE28` line for the same GC is also byte-identical across iters:\n\n```\nPROBE28 gc=17 N=0 maj=1 ng=1 preMut0=0 staticChain=174027\n  copiedW=464982 liveW=485763 liveB=483\n```\n\nThis confirms the bug is fully deterministic on its input.\n\n## Histogram diff \u2014 M5 GC 13 (PASS) vs Big2 GC 17 (FAIL)\n\nBig2's failing GC has copiedW = 464982 vs M5's last GC's 366812 \u2014\n~27% more work.  A uniform 1.27\u00d7 scaling is the workload baseline.\n\n| Type                       | Code | M5 GC 13 (PASS) | Big2 GC 17 (FAIL) | Big2/M5 |\n|----------------------------|-----:|----------------:|------------------:|--------:|\n| CONSTR                     |   1  |          18 361 |            22 713 |   1.24\u00d7 |\n| CONSTR_1_0                 |   2  |          12 150 |            15 929 |   1.31\u00d7 |\n| CONSTR_0_1                 |   3  |           5 029 |             5 424 |   1.08\u00d7 |\n| CONSTR_2_0                 |   4  |          23 677 |            27 928 |   1.18\u00d7 |\n| CONSTR_1_1                 |   5  |           3 827 |             3 947 |   1.03\u00d7 |\n| CONSTR_0_2                 |   6  |              35 |                34 |   0.97\u00d7 |\n| CONSTR_NOCAF               |   7  |              12 |                12 |   1.00\u00d7 |\n| FUN                        |   8  |              49 |                38 |   0.78\u00d7 |\n| FUN_1_0                    |   9  |           1 462 |             1 371 |   0.94\u00d7 |\n| FUN_0_1                    |  10  |             918 |               930 |   1.01\u00d7 |\n| FUN_2_0                    |  11  |             626 |               682 |   1.09\u00d7 |\n| THUNK                      |  15  |           2 732 |             3 259 |   1.19\u00d7 |\n| THUNK_1_0                  |  16  |           7 698 |            10 182 |   1.32\u00d7 |\n| THUNK_0_1                  |  17  |             519 |               516 |   0.99\u00d7 |\n| THUNK_2_0                  |  18  |           9 767 |            13 858 |   **1.42\u00d7** |\n| THUNK_SELECTOR             |  22  |           4 036 |             4 018 |   1.00\u00d7 |\n| PAP                        |  25  |             327 |               401 |   1.23\u00d7 |\n| MVAR_CLEAN                 |  39  |             256 |               244 |   0.95\u00d7 |\n| MVAR_DIRTY                 |  40  |              17 |                16 |   0.94\u00d7 |\n| **ARR_WORDS**              |  42  |           4 853 |             8 047 | **1.66\u00d7** |\n| MUT_ARR_PTRS_CLEAN         |  43  |             256 |               244 |   0.95\u00d7 |\n| MUT_ARR_PTRS_DIRTY         |  44  |               1 |                13 |  13.00\u00d7 |\n| MUT_ARR_PTRS_FROZEN_CLEAN  |  46  |               7 |                 8 |   1.14\u00d7 |\n| MUT_VAR_CLEAN              |  47  |             277 |               276 |   1.00\u00d7 |\n| MUT_VAR_DIRTY              |  48  |              60 |                 3 |   0.05\u00d7 |\n| WEAK                       |  49  |              16 |                 4 |   0.25\u00d7 |\n| TSO                        |  52  |               0 |                 1 |     new |\n\nIn `evac` (fresh-evacuate dispatch), additional rows:\n\n| Type                       | Code | M5 GC 13 | Big2 GC 17 | ratio |\n|----------------------------|-----:|---------:|-----------:|------:|\n| BLACKHOLE                  |  38  |      130 |        625 | **4.81\u00d7** |\n\nAnomalies relative to 1.27\u00d7 workload baseline:\n\n- **ARR_WORDS (42): 1.66\u00d7**, +3194 closures.\n- **THUNK_2_0 (18): 1.42\u00d7**, +4091 closures.\n- **CONSTR_1_0 (2): 1.31\u00d7**, +3779 closures.\n- **THUNK_1_0 (16): 1.32\u00d7**, +2484 closures.\n- **BLACKHOLE evac: 4.81\u00d7**, +495 fresh evacuations.\n\n`MUT_VAR_DIRTY (48)` and `WEAK (49)` are *under*-represented in\nBig2 (1/20 and 1/4 of M5's count) \u2014 interesting but on tiny absolute\ncounts.\n\n**Crucially: no closure type appears in Big2 GC 17 that wasn't\nalready present in earlier GCs (Big2 GCs 1\u201316 and M5 GCs 1\u201313).**\nThe bug doesn't fire the first time type X is processed; it fires\nspecifically at GC 17 of Big2.\n\n## Why \"ARR_WORDS is the bug\" doesn't work\n\nARR_WORDS is workload-disproportionate (1.66\u00d7).  Hypothesis: a bug\nin evacuating ARR_WORDS on PPC32 \u2014 e.g. miscomputing `arr_words_sizeW`\non PPC32's 4-byte words.\n\nBut:\n\n1. **M5 has 4853 ARR_WORDS in GC 13 and PASSES.**  Big2 has 8047\n   in GC 17 and fails.  If ARR_WORDS were buggy, M5 should\n   sometimes crash too.  It never does.\n2. **Big2 GCs 1\u201316 also process thousands of ARR_WORDS, all\n   successfully.**  GC 14 had 7708 ARR_WORDS, GC 15 had 7873, GC\n   16 had 8353, GC 17 had 8047 \u2014 and only GC 17 fires the bug.\n3. **The filename experiment (below) is dispositive**: the same\n   source bytes (so the same ARR_WORDS workload) pass under one\n   filename and fail under another.  The trigger can't be the\n   number of ARR_WORDS scavenged.\n\nSame logic kills the THUNK_2_0 / BLACKHOLE / CONSTR_1_0 hypotheses.\n\n## The filename experiment\n\nThe original session-28 HANDOFF queued a \"Big2 variant bisect\" \u2014\nstrip imports / functions progressively to find which removal flips\nfail \u2192 pass.  When we did this with file variants `B0.hs` through\n`B4.hs`:\n\n```\n  B0.hs (= byte-identical to Big2.hs)   pass=3 fail=0 of 3, gcs=18\n  B1.hs (drop topK + swap)               pass=3 fail=0 of 3, gcs=17\n  B2.hs (also drop Data.Map.Strict)      pass=0 fail=3 of 3, gcs=15\n  B3.hs (also drop scaleAndShift,\n         cumsum)                         pass=0 fail=3 of 3, gcs=15\n  B4.hs (bare module)                    pass=0 fail=3 of 3, gcs=12\n```\n\nBut B0.hs has the **same bytes** as Big2.hs!  `md5` confirmed.  The\nonly difference is the filename.\n\nFollowup single-iter sweep on byte-identical content with varying\nfilenames:\n\n```\n  Big2.hs    rc=1 gcs=17 panic     (FAIL)\n  B0.hs      rc=0 gcs=18           (PASS)\n  BB.hs      rc=0 gcs=18           (PASS)\n  BigTwo.hs  rc=1 gcs=17           (FAIL)\n  X.hs       rc=0 gcs=18           (PASS)\n  Big22.hs   rc=1 gcs=17           (FAIL)\n  Big2a.hs   rc=1 gcs=17           (FAIL)\n  aBig2.hs   rc=1 gcs=17           (FAIL)\n  ABCDEF.hs  rc=1 gcs=17           (FAIL)\n```\n\nLength sweep:\n\n```\n  A.hs       PASS (gcs=18)    AA.hs    FAIL (gcs=17)\n  AAA..AAAAAA.hs               all FAIL (gcs=17)\n  B.hs       PASS (gcs=18)    BB.hs    PASS (gcs=18)\n  BBB..BBBBB.hs                all FAIL (gcs=17)\n```\n\nBoundary is name-specific, not length-monotonic.  `A.hs` flips at\n2 chars; `B.hs` flips at 3 chars.\n\nCross-flag check:\n\n```\n-A1m default (=-G2):\n  Big2.hs PASS, BB.hs FAIL, BBB.hs FAIL, X.hs FAIL, AAA.hs FAIL\n\n-A2m -G1:\n  Big2.hs FAIL, BB.hs PASS, BBB.hs PASS, X.hs FAIL, AAA.hs PASS\n```\n\nDifferent RTS allocation parameters redistribute which (filename,\nflags) tuples hit the bug.\n\n### What this means\n\nThe filename string flows through GHC's internal data structures \u2014\nModSummary, source-span attributions, FastString interning of the\npath, intermediate file naming for `.hi` / `.o` outputs.  Each\nadditional byte changes the cumulative allocation pattern.  By the\ntime GC 17 runs, the heap layout differs depending on filename.\n\nSo **the trigger is a specific heap layout**.  Not a specific\nclosure type appearing.  Not a specific volume of any type.  The\nexact memory layout \u2014 which closures live where, which to-space\nblocks are contiguous, which alignment boundaries get crossed.\n\nHypotheses consistent with the filename data:\n\n- A **block-boundary crossing bug** in `alloc_in_moving_heap` or\n  `todo_block_full` \u2014 when a closure crosses a block edge under a\n  specific alignment, the scavenge reads garbage.\n- An **info-pointer / forwarding-pointer alignment bug** on PPC32\n  \u2014 the IS_FORWARDING_PTR test uses bit 0.  On PPC32 with 4-byte\n  pointers, all valid closure pointers have bit 0 = 0.  But if a\n  closure ends up at an odd address (somehow), the test\n  misclassifies it.\n- A **`ROUNDUP_BYTES_TO_WDS` rounding bug** on PPC32 \u2014 an ARR_WORDS\n  with a `bytes` value not aligned to W_ would round up to the\n  next word, but if the rounding is off by one in either direction\n  the next closure's header gets read as a pointer.\n- A **memory-overlap / aliasing bug** in to-space allocation \u2014 two\n  closures end up overlapping if the bump allocator returns the\n  same pointer twice due to an extension-vs-block-full race-free\n  bug on PPC32.\n\nHypotheses NOT consistent with the filename data:\n\n- \"scavenge_block dispatch on type X is buggy\" \u2014 type X would be\n  processed in many GCs of many inputs, but the bug fires only\n  on specific (filename, flags) tuples.\n- \"evacuate of closure type X copies the wrong number of words\" \u2014\n  same logic.\n- \"static_objects walking is buggy\" \u2014 already ruled out by\n  session 28.\n- \"mut_list scavenge is buggy\" \u2014 already ruled out by session 28.\n\n## Open questions / next-step priorities for session 30\n\n### Top: rebuild with DEBUG / sanity checks\n\nThe RTS supports `+RTS -DS` for sanity-checking heap invariants\nafter every GC.  This needs a DEBUG-flavored rebuild and a stage2\nlinked against `libHSrts-1.0.2_debug.a` (Hadrian produces this\nartifact already during a `quick-cross` build).\n\nIf sanity check catches the corruption inside `GarbageCollect()`\nrather than letting it leak to the next mutator phase, we'll get a\nmuch more precise failure point.\n\nCost: 1 RTS rebuild + 1 deploy + a few runs.  ~30 min.\n\n### Second: audit `alloc_in_moving_heap` / `todo_block_full`\n\nThese are the to-space bump allocator.  Suspect lines in\n`rts/sm/Evac.c` and `rts/sm/GCUtils.c`:\n\n- `alloc_in_moving_heap` (Evac.c:111) \u2014 pre-increments `ws->todo_free`\n  before the limit check, expecting `todo_block_full` to compensate.\n  Check: does the compensation hold up at block-boundary crossings?\n- `todo_block_full` (GCUtils.c:235) \u2014 `ws->todo_free -= size` is the\n  expected pre-decrement on entry.  Then it decides \"extend\" or\n  \"push out the block.\"  Is the `can_extend` predicate (line 270)\n  correct on PPC32 with 4 KB blocks?\n- `alloc_todo_block` (GCUtils.c:330) \u2014 `bd->start + bd->blocks * BLOCK_SIZE_W - bd->free > (int)size`\n  uses `int` on the LHS-cast \u2014 on PPC32 `int` is 32-bit; if the\n  arithmetic overflows for large blocks it'd return a wrong answer.\n\nPPC32 alignment concerns:\n\n- `BLOCK_SIZE_W = 1024` words on PPC32 (vs 512 on amd64).  Block\n  bounds calculations should still be correct but check arithmetic.\n- `bd->start` is aligned to `BLOCK_SIZE` (4 KB) per `BLOCK_ROUND_DOWN`.\n  Check that `bd->blocks * BLOCK_SIZE_W` doesn't overflow on PPC32.\n\n### Third: audit forwarding-pointer / info-pointer 32-bit paths\n\nIn `rts/sm/Evac.c`:\n\n- `IS_FORWARDING_PTR` / `MK_FORWARDING_PTR` / `UN_FORWARDING_PTR`\n  in `ClosureMacros.h:229-231` \u2014 these manipulate bit 0.  PPC32\n  closure pointers are 4-byte aligned (bit 0 and bit 1 both 0).\n- `evacuate()` line ~809: `info = ACQUIRE_LOAD(&q->header.info)`\n  \u2014 non-threaded RTS expands ACQUIRE_LOAD to `*ptr`.  PPC32 32-bit\n  aligned load.\n- `INFO_PTR_TO_STRUCT(info)->type` \u2014 with `TABLES_NEXT_TO_CODE = NO`\n  (per stage2's lib/settings), `INFO_PTR_TO_STRUCT(info) = info`\n  (Identity).  So reading `info->type` is just a load from the\n  info-table struct.\n\n### Fourth: per-closure-SIZE histogram (alternative to per-type)\n\nAdd a histogram bucketed by `closure_sizeW(p)` in `scavenge_block`.\nBig2's failing GC may have a specific size class that M5's GCs lack.\nIf we see a unique large-size closure in Big2, that's evidence for\nan alignment-padding bug on variable-size closures (ARR_WORDS,\nMUT_ARR_PTRS, PAP, AP_STACK, etc.).\n\n### Fifth: dump pre-fail heap state\n\nAdd a probe that, just before the panic-causing mutator code path\nreads from the corrupted closure, dumps the closure's address +\ncontents.  This requires identifying the corruption site in\nSimplifier `refineFromInScope` and instrumenting around it.  More\ninvasive but would identify the EXACT corrupted closure.\n\n## Process notes\n\n- **PROBE29 perturbation** is small (single ALU op per closure,\n  no I/O beyond PROBE28's existing per-GC printf).  Confirmed not\n  bug-suppressing: same outcomes as PROBE28-only (Big2 -A1m -G1\n  panics 5/5 with `refineFromInScope` signature).\n- **The deploy step is slow** (~3 min) because stage2 is a 193 MB\n  cross-link.  An RTS-only rebuild is 5 s but the deploy has to\n  re-cross-link the whole stage2 binary.  Could potentially be\n  optimized by linking only the RTS lib into a wrapper, but the\n  current deploy script is fine for low-rate iteration.\n- **Mind the background-task harness** \u2014 `Bash` tool sometimes\n  defers long commands to background mode.  Wait for the completion\n  event rather than re-issuing the command, or you end up with\n  duplicate work.\n\n## Files added this session\n\n- [`README.md`](README.md), this `findings.md`,\n  [`HANDOFF.md`](HANDOFF.md), [`log.md`](log.md),\n  `commits.md` \u2014 writeup.\n- [`probe29-rts.patch`](probe29-rts.patch) \u2014 the PROBE29 patch\n  (re-applicable via `git apply` inside\n  `external/ghc-modern/ghc-9.2.8`).\n- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) \u2014\n  the M5 / Big2 \u00d7 `-A1m -G1` matrix.\n- [`scripts/diff-histograms.sh`](scripts/diff-histograms.sh) \u2014\n  diff two PROBE29 GCs side-by-side.\n- [`scripts/big2-bisect.sh`](scripts/big2-bisect.sh) \u2014 the Big2.hs\n  variant bisect (that uncovered the filename effect).\n- Run logs at [`../../../log/session29/`](../../../log/session29/)\n  (gitignored).\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md",
  "content": "# Handoff from session 29 \u2192 session 30\n\n**For:** the next claude session.\n**From:** session 29 (PROBE29 per-closure-type histogram; **bug\nproved heap-layout-dependent \u2014 filename-sensitive on byte-identical\nsource**; 2026-05-12).\n**Recommended pickup:** rebuild stage2 with DEBUG / sanity-check\nRTS to catch corruption inside `GarbageCollect()`, then audit\n`rts/sm/Evac.c::alloc_in_moving_heap` + `rts/sm/GCUtils.c::todo_block_full`\n+ forwarding-pointer arithmetic for PPC32 block-boundary /\nalignment bugs.\n\n## TL;DR (mandatory read)\n\n- **PROBE29 (per-closure-type histogram in `scavenge_block` and\n  `evacuate`)** ran cleanly.  All 5 Big2 `-A1m -G1` failing GCs\n  produce byte-identical histograms \u2014 bug is fully deterministic.\n- **Histogram diff (M5 GC 13 PASS vs Big2 GC 17 FAIL)** shows\n  ARR_WORDS at 1.66\u00d7 workload-relative, THUNK_2_0 at 1.42\u00d7,\n  BLACKHOLE evac at 4.81\u00d7.  But **no closure type is unique to the\n  failing GC** \u2014 every type at Big2 GC 17 also appears in Big2 GCs\n  1\u201316 and in M5's passing GCs.\n- **\ud83d\udfe5 The bug is filename-sensitive.**  Byte-identical Big2.hs\n  source compiled under filename `Big2.hs` panics 5/5 at GC 17;\n  under filename `B0.hs` (or `BB.hs`, `X.hs`, `A.hs`) it PASSES at\n  GC 18.  `md5` confirms identical bytes.  Length sweep: `A.hs`\n  passes, `AA.hs` fails; `BB.hs` passes, `BBB.hs` fails.  Different\n  RTS flags shift which (filename, flags) tuples trigger the bug.\n- **This rules out a per-closure-type scavenge / evacuate bug.**\n  Type-X-mishandling would fire on every input containing type X.\n  Instead the bug fires only when the heap at GC 17 reaches a\n  specific *layout* \u2014 which depends on filename-derived allocations.\n- **New audit framing:** heap geometry, block-boundary crossings,\n  allocator state, info-pointer alignment, ROUNDUP / sizeofW\n  arithmetic at variable-size closures on PPC32 (32-bit big-endian,\n  4 KB blocks = 1024 words).\n- v0.12.0 ships unchanged.  Source tree clean at session end.\n  Stage2 on pmacg5 is the clean redeploy after probe revert.\n  Probe saved as a patch under this session dir.\n\n## Read in order\n\n1. **This file.**\n2. [`README.md`](README.md) \u2014 narrative of session 29.\n3. [`findings.md`](findings.md) \u2014 full PROBE29 data + filename\n   experiment + analysis.\n4. [`log.md`](log.md) \u2014 real-time work log with all the dead ends.\n5. [`probe29-rts.patch`](probe29-rts.patch) \u2014 the probe diff, ready\n   to re-apply.\n6. (Reference) Session 28 [`HANDOFF.md`](../2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)\n   \u2014 for the audit-target ruleouts that still hold.\n\n## What to NOT redo\n\n- **Don't audit `scavenge_block`'s per-type dispatch as if the bug\n  is type-X-specific.**  The filename experiment proves the trigger\n  is heap-layout-dependent, not closure-type-dependent.  Anything\n  framed \"find the buggy `case` in `scavenge_block`'s switch\" is\n  unlikely to find it.\n- **Don't redo the ARR_WORDS / THUNK_2_0 / BLACKHOLE evacuate\n  audit.**  Those were the workload-disproportionate types in the\n  histogram diff, but they appear in many GCs of many inputs\n  without firing the bug.  Same logic kills the MUT_ARR_PTRS_DIRTY\n  hypothesis.\n- **Don't redo `scavenge_capability_mut_lists` / `scavenge_static`\n  / SRT-scavenge audits** \u2014 session 28 ruled them out.\n- **Don't write more Haskell-side instrumentation** \u2014 PROBE28's\n  per-GC printf already perturbs timing enough to flip failure\n  signatures.  PROBE29's per-closure bumps are fine (ALU-only) but\n  any Haskell-side allocation perturbation is strictly worse.\n- **Don't rebuild the world** for an RTS-only change.  ~5 s with\n  the correct Hadrian target:\n  `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`.\n\n## What to try next, in priority order\n\n### Top: rebuild with DEBUG / sanity-check RTS\n\nThe non-threaded RTS supports `+RTS -DS` (sanity check) and\n`+RTS -DG` (GC debug trace) IF the runtime is built with DEBUG.\nHadrian already produces `libHSrts-1.0.2_debug.a` during a normal\n`quick-cross` build; the question is whether stage2 links against\nthe debug or non-debug variant.\n\nSteps:\n\n1. Confirm what stage2 currently links against:\n   `nm /opt/ghc-stage2/bin/ghc-real | grep -i sanity` \u2014 if it\n   has sanity-check symbols, stage2 is already DEBUG-flavored.\n   If not, rebuild stage2 with the debug RTS linked.\n2. Run Big2.hs `-A1m -G1 -DS` and see if the corruption is caught\n   inside `GarbageCollect()` rather than leaking to the next\n   mutator phase.\n3. If `-DS` catches a corrupted closure, the panic message will\n   include a specific address.  Read the surrounding heap state\n   to identify the corrupted closure's type, size, and contents.\n\nCost: 1 RTS rebuild (5 s) + 1 deploy (3 min) + a few runs.  ~30 min.\n\nThis is the single most informative experiment available.  Sanity\ncheck inside GC can pinpoint the bug to a specific iteration of a\nspecific GC's scavenge loop.\n\n### Second: audit `alloc_in_moving_heap` / `todo_block_full`\n\n`rts/sm/Evac.c:111` \u2014 `alloc_in_moving_heap` pre-bumps `ws->todo_free`\n*before* the limit check, expecting `todo_block_full` to compensate.\nLook at the interaction carefully:\n\n```c\nStgPtr to = ws->todo_free;\nws->todo_free += size;\nif (ws->todo_free > ws->todo_lim) {\n    to = todo_block_full(size, ws);\n}\n```\n\n`todo_block_full` (rts/sm/GCUtils.c:235):\n\n```c\nws->todo_free -= size;  // undo the pre-bump\n// ... decide extend vs push-out ...\nif (!urgent_to_push && can_extend) {\n    ws->todo_lim = stg_min(...);\n    p = ws->todo_free;\n    ws->todo_free += size;\n    return p;\n}\n// push out + alloc new block\nws->todo_bd = NULL;\nws->todo_free = NULL;\nws->todo_lim = NULL;\nalloc_todo_block(ws, size);\np = ws->todo_free;\nws->todo_free += size;\nreturn p;\n```\n\nPPC32 concerns:\n\n- `bd->start + bd->blocks * BLOCK_SIZE_W` arithmetic with\n  `BLOCK_SIZE_W = 1024` and 32-bit pointers.  Check for overflow\n  in `(int)size` casts (line 337 of GCUtils.c: `bd->start + bd->blocks * BLOCK_SIZE_W - bd->free > (int)size`).\n- `can_extend` (line 270): `ws->todo_free + size <= bd->start + bd->blocks * BLOCK_SIZE_W && ws->todo_free < ws->todo_bd->start + BLOCK_SIZE_W`.\n  On PPC32, ws->todo_free is `StgPtr` (= `W_ *`).  `+ size` on a\n  `W_ *` advances by `size * sizeof(W_) = size * 4` bytes.  Correct.\n- The `&&` predicate has two conjuncts.  The second\n  (`< bd->start + BLOCK_SIZE_W`) restricts extension to *within\n  the first block* of a large block group.  Why?  See \"Note [big\n  objects]\".  Suspect: this restriction interacts with multi-block\n  large-object handling in a way that's correct on amd64 but wrong\n  on PPC32.\n\n### Third: audit forwarding-pointer / sizing arithmetic for variable-size closures\n\nARR_WORDS, MUT_ARR_PTRS, PAP, AP, AP_STACK are variable-size.\nTheir sizing macros:\n\n- `arr_words_sizeW(x) = sizeofW(StgArrBytes) + ROUNDUP_BYTES_TO_WDS(x->bytes)`\n- `mut_arr_ptrs_sizeW(x) = sizeofW(StgMutArrPtrs) + x->size`\n- `pap_sizeW(n_args) = sizeofW(StgPAP) + n_args`\n\n`ROUNDUP_BYTES_TO_WDS(n) = ((n) + sizeof(W_) - 1) / sizeof(W_)`.\nOn PPC32 sizeof(W_) = 4, so a `bytes` of e.g. 9 rounds to 3 words.\nLooks right.\n\nPPC32 concerns:\n\n- `bytes` field on ARR_WORDS \u2014 written by the mutator.  Is it a\n  full word on PPC32?  `StgArrBytes { StgHeader header; StgWord bytes; StgWord payload[]; }`\n  \u2014 yes, `StgWord` is 4 bytes on PPC32.  Should be 32-bit aligned.\n- `x->size` on MUT_ARR_PTRS \u2014 same.\n- `n_args` on PAP \u2014 16-bit field maybe?  Check struct layout.\n\nFor PAP/AP, the calling-convention info comes from `StgFunInfoTable`\n(an extension of `StgInfoTable` for FUN closures).  PPC32-specific\nABI assumptions could break this.\n\n### Fourth: per-closure-SIZE histogram (extension to PROBE29)\n\nIf the bug is alignment-dependent on variable-size closures, a\nper-size histogram (bucketed by `closure_sizeW(p)` in scavenge_block)\nwould show Big2 GC 17 with a specific size class that M5 GCs lack.\n\nCost: small extension to PROBE29.  ~1 hour.\n\n### Fifth: bisect filename more aggressively\n\nWe have a discriminator: Big2.hs FAIL, B0.hs PASS, byte-identical\ncontent.  Can we find a 1-byte filename change that flips the\nresult?\n\nCompare:\n\n- `B0.hs` PASS, `BB.hs` PASS, `Big.hs` ?, `Big2.hs` FAIL.\n- `A.hs` PASS, `AA.hs` FAIL.\n- Try: `B.hs`, `Big1.hs`, `Big3.hs`, `Big2.hs`.  Does `Big.hs`\n  pass while `Big2.hs` fails?\n\nIf we can isolate a 1-char (or 1-bit) flip that toggles the bug,\nthat's an extreme bisection that pinpoints the exact heap shift.\n\n## Mechanics \u2014 reproducing session 29 results\n\n```bash\ncd /Users/cell/claude/ghc-darwin8-ppc\n\n# 0. Optional: baseline still green?\nbash tests/run-tests.sh    # ~10 min; expect 30 PASS / 4 design diffs\n\n# 1. Re-apply the probe\ncd external/ghc-modern/ghc-9.2.8\ngit apply ../../docs/sessions/2026-05-12-session-29-closure-type-histogram/probe29-rts.patch\n\n# 2. Rebuild + deploy\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n\n# 3. Run the matrix (logs at log/session29/)\nbash docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/run-probe-matrix.sh \\\n    pmacg5 5\n\n# 4. Histogram diff (PASS GC vs FAIL GC)\nbash docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/diff-histograms.sh \\\n    log/session29/M5-a1m-g1.iter1.log 13 \\\n    log/session29/Big2-a1m-g1.iter1.log 17\n\n# 5. Filename-sensitivity quick check\nssh pmacg5 '\ncd /tmp\nfor name in Big2 B0 BB X AAA; do\n  cp Big2.hs ${name}.hs\n  rm -f Big2.hi Big2.o ${name}.hi ${name}.o\n  DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \\\n    /opt/ghc-stage2/bin/ghc-real -c ${name}.hs +RTS -A1m -G1 -RTS 2>&1 \\\n    | grep -c \"panic\"\ndone'\n\n# 6. When done \u2014 REVERT before any user-facing run\ncd external/ghc-modern/ghc-9.2.8\ngit checkout -- rts/sm/GC.c rts/sm/Scav.c rts/sm/Evac.c\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\n**Expected:** with probe, M5 `-A1m -G1` passes 5/5 (13 GCs each),\nBig2 `-A1m -G1` panics 5/5 at GC 17 with `refineFromInScope`.\nHistograms across all 5 Big2 iters are byte-identical.  Filename\nsweep shows `Big2.hs` panics but `B0.hs` (and `BB.hs`, `X.hs`)\npass.\n\n## Hosts (unchanged)\n\n- **uranium** (this Mac): host for cross-build, source edits.\n- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.\n- **imacg3**: smaller-RAM PPC G3.\n- **indium**: don't use for clang or hadrian builds.\n\n## What's clean / dirty in the source tree\n\n- `external/ghc-modern/ghc-9.2.8/` \u2014 clean for `rts/sm/`.  Other\n  paths under it have long-standing project patches.\n- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` \u2014 clean rebuild+\n  redeploy at session-29 end, matches v0.12.0.\n- New session dir: `docs/sessions/2026-05-12-session-29-closure-type-histogram/`\n  + run logs gitignored at `log/session29/`.\n\n## Time estimate for session 30\n\n- Setup + read handoff + verify session-29 numbers (re-apply\n  probe + rebuild + 5\u00d72 = 10 runs): 30\u201345 min.\n- Rebuild stage2 with DEBUG/sanity-check RTS + run Big2 -DS: 1\u20132 h.\n- If -DS catches the corruption: analyze + identify corrupted\n  closure: 1\u20132 h.  Then audit the specific path that produces it.\n- If -DS doesn't catch it: pivot to allocator audit\n  (`alloc_in_moving_heap` + `todo_block_full`) and per-closure-SIZE\n  histogram: 2\u20134 h.\n\nRealistic: 1 medium-to-long session (~4\u20136 h) for sanity-check\nrebuild + corruption pinpoint, then 1 short session for the fix.\n\n## Paste-into-fresh-session prompt\n\n```\nContext: session 29 of the GHC darwin8-ppc project just wrapped up.\nSession 29 implemented PROBE29 \u2014 extended PROBE28 with per-closure-\ntype histograms in rts/sm/Scav.c::scavenge_block and rts/sm/Evac.c::\nevacuate, plus a forwarding-pointer hit count.  Goal was to identify\nthe closure type that fires the stage2 GC bug at Big2.hs +RTS -A1m\n-G1 GC 17.\n\nResult: ALL 5 Big2 GC 17 histograms are byte-identical (full\ndeterminism confirmed), but NO closure type is unique to Big2's\nfailing GC.  ARR_WORDS is workload-disproportionate (1.66x) but\nthat doesn't trigger the bug \u2014 M5 GCs scavenge thousands of\nARR_WORDS successfully.\n\nThen a Big2.hs bisect uncovered the BIG finding: compiling byte-\nidentical source under filename Big2.hs panics 5/5 at GC 17, but\nunder filename B0.hs (or BB.hs, X.hs) it PASSES.  md5 confirms\nidentical bytes.  The bug is HEAP-LAYOUT-DEPENDENT \u2014 every byte\nof filename text shifts the cumulative allocation pattern, and\nonly specific heap layouts at GC 17 hit the trigger.\n\nThis rules out a per-closure-type scavenge bug.  The audit\ndirection pivots to: heap-block geometry, allocator state, block-\nboundary crossings, info-pointer / forwarding-pointer alignment,\nROUNDUP / sizeofW arithmetic at variable-size closures on PPC32\n(32-bit big-endian, 4KB blocks).\n\nRead in order:\n1. docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md\n2. docs/sessions/2026-05-12-session-29-closure-type-histogram/README.md\n3. docs/sessions/2026-05-12-session-29-closure-type-histogram/findings.md\n4. docs/sessions/2026-05-12-session-29-closure-type-histogram/log.md\n5. (reference) docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md\n\nTop priority: rebuild stage2 with DEBUG / sanity-check RTS (run\nwith +RTS -A1m -G1 -DS).  If sanity check catches the corruption\ninside GarbageCollect() rather than the next mutator phase, we'll\nget a precise pinpoint of the corrupted closure.  Then audit the\nspecific scavenge / evacuate path that produced it \u2014 likely in\nrts/sm/Evac.c::alloc_in_moving_heap, rts/sm/GCUtils.c::todo_block_full,\nor the forwarding-pointer / info-table machinery.\n\nDon't redo per-closure-type audit (proved dead by filename\nexperiment).  Don't redo static_objects / mut_list / SRT audits\n(killed by session 28).\n\nHosts: uranium for builds, pmacg5 for runs.  Don't use indium.\nv0.12.0 stays shipped \u2014 don't break stage2's -A1G wrapper.  ALWAYS\nrevert the probe + rebuild + redeploy clean stage2 at session end.\n\nUnsupervised mode is project default.\n```\n\n## Memory aide for the next-you: session-end HANDOFF path\n\nThis handoff lives at:\n[`docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md`](docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md).\n\nWhen session 30 ends, write the next handoff at:\n`docs/sessions/<DATE>-session-30-<slug>/HANDOFF.md`.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/commits.md",
  "content": "# Session 29 commits\n\nNo commits to the GHC source tree (`external/ghc-modern/ghc-9.2.8/`)\nthis session \u2014 the PROBE29 patch was applied, used, and reverted.\nThe patch itself is preserved at\n[`probe29-rts.patch`](probe29-rts.patch) in this session dir.\n\n## Repository commits\n\n(SHA backfilled after the commit lands; the commit itself comes\nafter the session-end ritual completes.)\n\n- `(SHA TBD)` \u2014 Session 29: stage2 GC bug investigation, round 11\n  (PROBE29 per-closure-type histogram in scavenge_block + evacuate;\n  histogram diff identifies workload-disproportionate types but\n  bisect-by-filename reveals the bug is HEAP-LAYOUT-DEPENDENT \u2014\n  byte-identical source compiled under different filenames produces\n  different outcomes; per-closure-type scavenge-bug hypothesis ruled\n  out; audit direction pivots to allocator / block-boundary /\n  alignment).\n"
}


---

## 🤖 Claude

Now update state.md and roadmap.md to reflect the new framing.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'session.28\\|session.29\\|GC bug\\|stage2\\|filename' /Users/cell/claude/ghc-darwin8-ppc/docs/state.md | head -20",
  "description": "See current state.md references"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "offset": 1,
  "limit": 15
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "*Updated: 2026-05-12 session 28 (stage2 GC bug round 10 \u2014 RTS-side discriminator probe; session-27's \"two distinct corruption modes\" downgraded to **one bug, two victim data structures**).  PROBE28 (slim RTS-side per-GC printf in `rts/sm/GC.c`) shows Big2.hs `-A1m -G1` switches from session 27's TC-time \"swap not in scope\" signature to the STG-time `refineFromInScope` signature 5/5 \u2014 the probe's tiny timing perturbation shifts which downstream IntMap-backed VarEnv catches the corruption.  Same root corruption, different downstream victim.  PROBE28 also ruled out two of session 27's audit targets: (i) `scavenge_capability_mut_lists` / mut_list write-barrier path (under `-G1` the mut_list is empty, yet Big2 `-G1` still panics 5/5); (ii) `scavenge_static` / `scavenge_thunk_srt` / `scavenge_fun_srt` (under `-G1` every GC walks the same ~175k-entry static_objects chain in both M5 (PASS) and Big2 (FAIL)).  Remaining suspects: `rts/sm/Evac.c` (evacuate / copy_tag / copy), `rts/sm/Scav.c::scavenge_block` dispatch by closure type, forwarding-pointer / info-table machinery on PPC32 (32-bit big-endian).  v0.12.0 ships unchanged; source tree clean; probe applied for measurement and reverted before session end; stage2 on pmacg5 rebuilt+redeployed clean.  Next session: extend PROBE28 with a per-closure-type histogram, then audit Evac.c / Scav.c.*",
  "new_string": "*Updated: 2026-05-12 session 29 (stage2 GC bug round 11 \u2014 PROBE29 per-closure-type histogram in `rts/sm/Scav.c::scavenge_block` + `rts/sm/Evac.c::evacuate`).  Histograms across all 5 Big2 `-A1m -G1` failing GCs are **byte-identical** (full determinism confirmed).  Diff of M5 GC 13 (PASS) vs Big2 GC 17 (FAIL): largest workload-relative anomalies are **ARR_WORDS (1.66\u00d7)**, THUNK_2_0 (1.42\u00d7), BLACKHOLE evac (4.81\u00d7) \u2014 but **no closure type is unique to Big2's failing GC** (every type at GC 17 also appears in earlier Big2 GCs and in M5's GCs).  Then a Big2.hs bisect uncovered the headline finding: **the bug is filename-sensitive**.  Byte-identical source compiled under filename `Big2.hs` panics 5/5 at GC 17; under `B0.hs` (or `BB.hs`, `X.hs`, `A.hs`) it PASSES at GC 18.  `md5` confirms identical bytes.  Length sweep: `A.hs` passes, `AA.hs` fails; `BB.hs` passes, `BBB.hs` fails.  Different RTS flags shift which filenames trigger.  **This rules out a per-closure-type scavenge / evacuate bug**: such a bug would fire whenever type X is processed.  The trigger is **heap-layout-dependent** \u2014 every byte of filename text changes cumulative allocation pattern, and only specific layouts at GC 17 hit it.  Audit direction pivots to: heap-block geometry, allocator state (`alloc_in_moving_heap` / `todo_block_full`), block-boundary crossings, info-pointer / forwarding-pointer alignment, ROUNDUP / sizeofW arithmetic at variable-size closures on PPC32 (32-bit big-endian, 4 KB blocks = 1024 words).  v0.12.0 ships unchanged; source tree clean; probe applied + reverted; stage2 on pmacg5 rebuilt+redeployed clean.  Next session: rebuild stage2 with DEBUG / sanity-check RTS (`+RTS -DS`) to catch corruption inside `GarbageCollect()`, then audit allocator / block-boundary paths.*"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'session.28\\|session.29\\|stage2.GC.bug\\|PROBE28\\|PROBE29' /Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md | head -20",
  "description": "Check roadmap.md references"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "offset": 300,
  "limit": 50
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "old_string": "- [`docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/)\n  \u2014 round 10.  Wrote **PROBE28** \u2014 a slim RTS-side per-GC printf in\n  `rts/sm/GC.c` (file-static counter + pre-GC mut_list snapshot via\n  `countOccupied` + post-GC summary line walking\n  `gct->scavenged_static_objects` via `STATIC_LINK`).  With the\n  probe enabled, **Big2.hs `-A1m -G1` flips from session 27's\n  TC-time \"swap not in scope\" signature (10/10) to the STG-time\n  `refineFromInScope` signature 5/5** \u2014 the probe's tiny per-GC\n  timing delay shifts which downstream IntMap-backed VarEnv catches\n  the corruption.  Strong evidence for **one bug, two victim data\n  structures**.  PROBE28 also rules out two of session 27's audit\n  targets: (i) `scavenge_capability_mut_lists` / mut_list write-\n  barrier path (Big2 `-G1` fails 5/5 with zero mut_list activity \u2014\n  under `-G1` mut_lists are empty); (ii) `scavenge_static` /\n  `scavenge_thunk_srt` / `scavenge_fun_srt` (under `-G1` every GC\n  walks the same ~175k-entry static_objects chain in both M5 (PASS)\n  and Big2 (FAIL)).  Remaining suspects: `rts/sm/Evac.c`\n  (`evacuate`, `copy_tag`, `copy`), `rts/sm/Scav.c::scavenge_block`\n  dispatch by closure type, forwarding-pointer / info-table\n  machinery on PPC32 (32-bit big-endian).  v0.12.0 ships unchanged;\n  probe applied for measurement and reverted at session end; stage2\n  on pmacg5 rebuilt+redeployed clean.  Session-28\n  [`HANDOFF.md`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)\n  scopes a per-closure-type histogram extension to PROBE28, then a\n  PPC32-eyes audit of Evac.c / Scav.c.",
  "new_string": "- [`docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/)\n  \u2014 round 10.  Wrote **PROBE28** \u2014 a slim RTS-side per-GC printf in\n  `rts/sm/GC.c` (file-static counter + pre-GC mut_list snapshot via\n  `countOccupied` + post-GC summary line walking\n  `gct->scavenged_static_objects` via `STATIC_LINK`).  With the\n  probe enabled, **Big2.hs `-A1m -G1` flips from session 27's\n  TC-time \"swap not in scope\" signature (10/10) to the STG-time\n  `refineFromInScope` signature 5/5** \u2014 the probe's tiny per-GC\n  timing delay shifts which downstream IntMap-backed VarEnv catches\n  the corruption.  Strong evidence for **one bug, two victim data\n  structures**.  PROBE28 also rules out two of session 27's audit\n  targets: (i) `scavenge_capability_mut_lists` / mut_list write-\n  barrier path (Big2 `-G1` fails 5/5 with zero mut_list activity \u2014\n  under `-G1` mut_lists are empty); (ii) `scavenge_static` /\n  `scavenge_thunk_srt` / `scavenge_fun_srt` (under `-G1` every GC\n  walks the same ~175k-entry static_objects chain in both M5 (PASS)\n  and Big2 (FAIL)).  Remaining suspects: `rts/sm/Evac.c`\n  (`evacuate`, `copy_tag`, `copy`), `rts/sm/Scav.c::scavenge_block`\n  dispatch by closure type, forwarding-pointer / info-table\n  machinery on PPC32 (32-bit big-endian).  v0.12.0 ships unchanged;\n  probe applied for measurement and reverted at session end; stage2\n  on pmacg5 rebuilt+redeployed clean.  Session-28\n  [`HANDOFF.md`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)\n  scopes a per-closure-type histogram extension to PROBE28, then a\n  PPC32-eyes audit of Evac.c / Scav.c.\n- [`docs/sessions/2026-05-12-session-29-closure-type-histogram/`](sessions/2026-05-12-session-29-closure-type-histogram/)\n  \u2014 round 11.  Extended PROBE28 to **PROBE29** \u2014 per-closure-type\n  histogram in `rts/sm/Scav.c::scavenge_block` and\n  `rts/sm/Evac.c::evacuate`, plus a forwarding-pointer hit count.\n  **All 5 Big2 `-A1m -G1` failing GCs produce byte-identical\n  histograms** (full determinism confirmed).  Diff M5 GC 13 (PASS)\n  vs Big2 GC 17 (FAIL): largest workload-relative anomalies are\n  **ARR_WORDS at 1.66\u00d7 scav**, THUNK_2_0 at 1.42\u00d7, BLACKHOLE evac\n  at 4.81\u00d7 \u2014 but **no closure type is unique to Big2's failing GC**\n  (every type at GC 17 also appears in earlier Big2 GCs and in\n  M5's GCs).  Then a Big2.hs bisect produced the headline finding:\n  **the bug is filename-sensitive**.  Byte-identical Big2.hs source\n  compiled under filename `Big2.hs` panics 5/5 at GC 17; under\n  `B0.hs` (or `BB.hs`, `X.hs`, `A.hs`) it PASSES at GC 18.  `md5`\n  confirmed identical bytes.  Length sweep: `A.hs` passes, `AA.hs`\n  fails; `BB.hs` passes, `BBB.hs` fails.  Different RTS flags\n  shift which filenames trigger.  **This rules out a per-closure-\n  type scavenge / evacuate bug**: such a bug would fire whenever\n  type X is processed.  The trigger is **heap-layout-dependent**.\n  Audit direction pivots to: heap-block geometry, allocator state\n  (`alloc_in_moving_heap` / `todo_block_full`), block-boundary\n  crossings, info-pointer / forwarding-pointer alignment, ROUNDUP /\n  sizeofW arithmetic at variable-size closures on PPC32.  v0.12.0\n  ships unchanged; probe applied for measurement and reverted at\n  session end; stage2 on pmacg5 rebuilt+redeployed clean.  Session-29\n  [`HANDOFF.md`](sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md)\n  scopes a DEBUG/sanity-check RTS rebuild (`+RTS -DS`) to catch\n  corruption inside `GarbageCollect()`, then an allocator + block-\n  boundary audit."
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session-29 dir with plan + log scaffolding",
      "activeForm": "Setting up session-29 dir",
      "status": "completed"
    },
    {
      "content": "Read rts/sm/Scav.c::scavenge_block to understand insertion points",
      "activeForm": "Reading scavenge_block",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE29 (PROBE28 + per-closure-type histogram + fwd-ptr hits)",
      "activeForm": "Implementing PROBE29 histogram",
      "status": "completed"
    },
    {
      "content": "Rebuild RTS lib and redeploy stage2 to pmacg5",
      "activeForm": "Rebuilding RTS + deploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix (M5 -A1m -G1 PASS vs Big2 -A1m -G1 FAIL, 5 iters each)",
      "activeForm": "Running probe matrix",
      "status": "completed"
    },
    {
      "content": "Analyze histograms; identify suspect closure type",
      "activeForm": "Analyzing histogram diffs",
      "status": "completed"
    },
    {
      "content": "Bisect Big2.hs \u2014 uncovered filename sensitivity instead",
      "activeForm": "Bisecting Big2.hs",
      "status": "completed"
    },
    {
      "content": "Audit Evac.c / Scav.c paths (partial; pivoted to heap-layout after filename finding)",
      "activeForm": "Auditing GC paths",
      "status": "completed"
    },
    {
      "content": "Revert probe + rebuild + redeploy clean stage2 at session end",
      "activeForm": "Cleaning up probe",
      "status": "completed"
    },
    {
      "content": "Write session-29 README/findings/HANDOFF/log/commits.md + update state/roadmap",
      "activeForm": "Writing session notes",
      "status": "completed"
    },
    {
      "content": "Commit session 29 to git",
      "activeForm": "Committing session 29",
      "status": "in_progress"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && git status --short docs/ 2>&1 | head -30 && echo \"---\" && git status --short . 2>&1 | head -10",
  "description": "Check what's staged for commit"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/state.md docs/roadmap.md docs/sessions/2026-05-12-session-29-closure-type-histogram/ && git status --short",
  "description": "Stage session 29 files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git commit -m \"$(cat <<'EOF'\nSession 29: stage2 GC bug investigation, round 11 (PROBE29 per-closure-type histogram in scavenge_block + evacuate; histogram diff identifies workload-disproportionate types but bisect-by-filename reveals the bug is HEAP-LAYOUT-DEPENDENT \u2014 byte-identical source compiled under different filenames produces different outcomes; per-closure-type scavenge-bug hypothesis ruled out; audit direction pivots to allocator / block-boundary / alignment).\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\" 2>&1 | tail -20",
  "description": "Commit session 29"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git rev-parse HEAD",
  "description": "Get commit SHA"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/commits.md",
  "old_string": "- `(SHA TBD)` \u2014 Session 29: stage2 GC bug investigation, round 11",
  "new_string": "- `bf58a63` \u2014 Session 29: stage2 GC bug investigation, round 11"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-12-session-29-closure-type-histogram/commits.md && git commit -m \"$(cat <<'EOF'\nSession 29 commits.md: backfill the SHA.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\" 2>&1 | tail -5",
  "description": "Backfill SHA in commits.md"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session-29 dir with plan + log scaffolding",
      "activeForm": "Setting up session-29 dir",
      "status": "completed"
    },
    {
      "content": "Read rts/sm/Scav.c::scavenge_block to understand insertion points",
      "activeForm": "Reading scavenge_block",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE29 (PROBE28 + per-closure-type histogram + fwd-ptr hits)",
      "activeForm": "Implementing PROBE29 histogram",
      "status": "completed"
    },
    {
      "content": "Rebuild RTS lib and redeploy stage2 to pmacg5",
      "activeForm": "Rebuilding RTS + deploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix (M5 -A1m -G1 PASS vs Big2 -A1m -G1 FAIL, 5 iters each)",
      "activeForm": "Running probe matrix",
      "status": "completed"
    },
    {
      "content": "Analyze histograms; identify suspect closure type",
      "activeForm": "Analyzing histogram diffs",
      "status": "completed"
    },
    {
      "content": "Bisect Big2.hs \u2014 uncovered filename sensitivity instead",
      "activeForm": "Bisecting Big2.hs",
      "status": "completed"
    },
    {
      "content": "Audit Evac.c / Scav.c paths (partial; pivoted after filename finding)",
      "activeForm": "Auditing GC paths",
      "status": "completed"
    },
    {
      "content": "Revert probe + rebuild + redeploy clean stage2 at session end",
      "activeForm": "Cleaning up probe",
      "status": "completed"
    },
    {
      "content": "Write session-29 README/findings/HANDOFF/log/commits.md + update state/roadmap",
      "activeForm": "Writing session notes",
      "status": "completed"
    },
    {
      "content": "Commit session 29 to git (incl. SHA backfill)",
      "activeForm": "Committing session 29",
      "status": "completed"
    }
  ]
}


---

## 🤖 Claude

Session 29 wrapped up.

**Summary of what landed:**

- **PROBE29** = PROBE28 + per-closure-type histograms in `rts/sm/Scav.c::scavenge_block` and `rts/sm/Evac.c::evacuate`, plus a forwarding-pointer hit count. Applied, measured, reverted; clean stage2 redeployed.
- Matrix reproduces session 28 exactly: M5 `-A1m -G1` 5/5 PASS, Big2 `-A1m -G1` 5/5 FAIL at GC 17.
- All 5 Big2 failing-GC histograms are **byte-identical** — full determinism confirmed.
- Histogram diff (M5 GC 13 vs Big2 GC 17): largest workload-relative anomalies are **ARR_WORDS at 1.66×**, THUNK_2_0 at 1.42×, BLACKHOLE evac at 4.81×. **But no closure type is unique to Big2's failing GC.**
- **🟥 Headline finding: the bug is filename-sensitive.** Byte-identical Big2.hs source compiled under filename `Big2.hs` panics 5/5 at GC 17; under `B0.hs` / `BB.hs` / `X.hs` / `A.hs` it PASSES at GC 18 (`md5` confirms identical bytes). Length sweep: `A.hs` passes, `AA.hs` fails; `BB.hs` passes, `BBB.hs` fails. Different RTS flags shift which filenames trigger.
- **This rules out a per-closure-type scavenge/evacuate bug.** The trigger is **heap-layout-dependent**. Audit direction pivots to: heap-block geometry, allocator state, block-boundary crossings, info-pointer / forwarding-pointer alignment, ROUNDUP / sizeofW arithmetic at variable-size closures on PPC32.
- 2 commits: `bf58a63` (the session) + `b2e5f3b` (SHA backfill). v0.12.0 ships unchanged.

**Next session's HANDOFF:** [docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md](docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md). Top priority: rebuild stage2 with DEBUG / sanity-check RTS (`+RTS -DS`) to catch corruption inside `GarbageCollect()`, then audit `alloc_in_moving_heap` / `todo_block_full` and forwarding-pointer alignment paths.

---

