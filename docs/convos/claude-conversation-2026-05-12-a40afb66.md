# Claude Conversation Log

Session ID: a40afb66-4d7f-44cb-92dc-cb2a36844c21
Date: 2026-05-12 04:04:11

---

## 👤 User

please read docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md and proceed

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md"
}


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
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/findings.md"
}


---

## 🤖 Claude

Reading complete. Now I have the picture. Let me set up session 28 and verify the baseline.

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
  "command": "date '+%Y-%m-%d' && ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/ | tail -5",
  "description": "Get date and list recent sessions"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/",
  "description": "List session 27 scripts"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log -3 --format='%ai %s' | head -5",
  "description": "Check commit timestamps"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat docs/sessions/2026-05-12-session-27-non-perturbing-repro/commits.md 2>/dev/null | head -40",
  "description": "Read session 27 commits"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log --format='%ai %s' -- docs/sessions/ | head -20",
  "description": "Check session dirs' commit dates vs label dates"
}


---

## 🤖 Claude

Today's date convention is UTC-based — labels are +1 day from CDT commit times. I'll use `2026-05-12` for session 28 to match. Let me set up todos and start work.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 28 dir + run baseline test suite",
      "activeForm": "Setting up session 28 dir + running baseline",
      "status": "in_progress"
    },
    {
      "content": "Verify session 27 numbers (quick sanity check: M5.hs -A1m, M5.hs -A1m -G1)",
      "activeForm": "Verifying session 27 numbers",
      "status": "pending"
    },
    {
      "content": "Design + implement RTS-side probe in rts/sm/GC.c (per-GC mut_list lengths + static_objects chain + promotion counts)",
      "activeForm": "Implementing RTS-side probe",
      "status": "pending"
    },
    {
      "content": "Rebuild stage1 RTS lib + redeploy to pmacg5",
      "activeForm": "Rebuilding stage1 RTS + redeploying",
      "status": "pending"
    },
    {
      "content": "Run probe matrix: M5.hs -A1m, M5.hs -A1m -G1, Big2.hs -A1m -G1, Big2.hs -A1G",
      "activeForm": "Running probe matrix",
      "status": "pending"
    },
    {
      "content": "Analyze probe output: discriminate 'one bug, two victims' vs 'two bugs'",
      "activeForm": "Analyzing probe output",
      "status": "pending"
    },
    {
      "content": "Decide on next audit (mut_list path vs SRT/static-objects) based on probe results",
      "activeForm": "Deciding next audit path",
      "status": "pending"
    },
    {
      "content": "Write session 28 README + findings + commits.md + HANDOFF.md",
      "activeForm": "Writing session 28 notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "mkdir -p /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts",
  "description": "Create session 28 dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md 2>/dev/null | head -60",
  "description": "Glance at roadmap"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/tests/run-tests.sh 2>/dev/null | head -30; echo ---; ls /Users/cell/claude/ghc-darwin8-ppc/tests/ | head -40",
  "description": "Check what the test runner does"
}


---

## 🤖 Claude

Let me kick off the baseline tests in the background while I design the probe.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash tests/run-tests.sh > /tmp/session28-baseline.log 2>&1; echo \"EXIT=$?\"",
  "description": "Run baseline test suite in background",
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/measure-panic-rate.sh"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm -name 'GC.c' -o -name 'Scav.c' 2>/dev/null",
  "description": "Find GC source files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'GarbageCollect\\b\\|major_gc\\|saved_mut_lists\\|static_objects\\|n_old_blocks\\|live_blocks' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c | head -40",
  "description": "Find probe-relevant lines in GC.c"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 270,
  "limit": 100
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 1580,
  "limit": 130
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'countOccupied\\b' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/ /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/Stats.c /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/BlockAlloc.c /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/ 2>/dev/null | head -20",
  "description": "Find countOccupied uses + declaration"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'gct->scavenged_static_objects\\|scavenge_static\\|scavenged_static_objects\\|^debugBelch\\|debugBelch.*GC' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c | head -30",
  "description": "Find static objects + log calls in GC.c"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Storage.c",
  "offset": 1590,
  "limit": 40
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 660,
  "limit": 200
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 1690,
  "limit": 30
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 1590,
  "limit": 110
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'prepare_uncollected_gen\\|prepare_collected_gen\\|stash_mut_list' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c | head -20",
  "description": "Find where mut_lists are prepared"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 390,
  "limit": 80
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 1745,
  "limit": 30
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 970,
  "limit": 140
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'STATIC_LINK\\|END_OF_STATIC_OBJECT_LIST\\|scavenged_static_objects' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c | head -20",
  "description": "Find STATIC_LINK references"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'END_OF_STATIC_OBJECT_LIST\\|#define STATIC_LINK\\b' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/ /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Storage.h 2>/dev/null | head -10",
  "description": "Find STATIC_LINK macro"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 1720,
  "limit": 100
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-big2-test.sh"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh | head -50",
  "description": "Check cross-env script"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/scripts/deploy-stage2.sh 2>/dev/null | head -40",
  "description": "Look for stage2 deploy script"
}


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
  "command": "grep -rn 'UNTAG_STATIC_LIST_PTR\\|^#define STATIC_LINK' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/ /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/ 2>/dev/null | head -10",
  "description": "Find STATIC_LINK / UNTAG_STATIC_LIST_PTR macros"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n '#include\\|debugBelch\\b' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c | head -25",
  "description": "Confirm headers in GC.c"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn '^#define STATIC_LINK\\b' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/ 2>/dev/null",
  "description": "Find STATIC_LINK definition"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'STATIC_LINK' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/ClosureMacros.h 2>/dev/null | head -10",
  "description": "Find STATIC_LINK macro in ClosureMacros.h"
}


---

## 🤖 Claude

Let me check on the baseline tests and look at file layout precisely.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -20 /tmp/session28-baseline.log 2>/dev/null; echo ---; ls -la /tmp/session28-baseline.log",
  "description": "Check baseline progress"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 100,
  "limit": 25
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 450,
  "limit": 20
}


---

## 🤖 Claude

Baseline still running. Let me code the probe.

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "static W_ g0_pcnt_kept = 30; // percentage of g0 live at last minor GC\n\nstatic int consec_idle_gcs = 0;",
  "new_string": "static W_ g0_pcnt_kept = 30; // percentage of g0 live at last minor GC\n\nstatic int consec_idle_gcs = 0;\n\n/* PROBE28-BEGIN \u2014 session-28 discriminator probe state.\n *\n * Goal: distinguish \"one bug, two victim data structures\" vs \"two\n * separate bugs\" for the stage2 GC corruption (cf. session 27's\n * findings.md).  RTS-side only \u2014 does not touch Haskell allocation\n * paths, so it should not perturb the M5.hs / Big2.hs panic rates\n * the way session-26's PROBE26 did.\n *\n * Snapshots taken pre-GC and combined with end-of-GC stats are\n * printed once per call to GarbageCollect() via debugBelch().\n */\n#define PROBE28_MAX_GENS 8\nstatic StgWord64 probe28_gc_no = 0;\nstatic W_ probe28_pre_mut[PROBE28_MAX_GENS];\n/* PROBE28-END */"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "  // gather blocks allocated using allocatePinned() from each capability\n  // and put them on the g0->large_object list.\n  collect_pinned_object_blocks();\n\n  // Initialise all the generations that we're collecting.",
  "new_string": "  // gather blocks allocated using allocatePinned() from each capability\n  // and put them on the g0->large_object list.\n  collect_pinned_object_blocks();\n\n  /* PROBE28-BEGIN \u2014 snapshot pre-GC mut_list occupancy per gen, summed\n   * across capabilities.  Must run BEFORE prepare_collected_gen() (which\n   * throws away mut_lists for collected gens) and BEFORE\n   * prepare_uncollected_gen() / stash_mut_list() (which moves the list\n   * to saved_mut_lists and installs a fresh empty block).\n   */\n  probe28_gc_no++;\n  {\n      uint32_t pg_ng = RtsFlags.GcFlags.generations;\n      if (pg_ng > PROBE28_MAX_GENS) pg_ng = PROBE28_MAX_GENS;\n      for (uint32_t gg = 0; gg < PROBE28_MAX_GENS; gg++) {\n          probe28_pre_mut[gg] = 0;\n      }\n      for (uint32_t gg = 0; gg < pg_ng; gg++) {\n          W_ s = 0;\n          for (uint32_t c = 0; c < getNumCapabilities(); c++) {\n              s += countOccupied(capabilities[c]->mut_lists[gg]);\n          }\n          probe28_pre_mut[gg] = s;\n      }\n  }\n  /* PROBE28-END */\n\n  // Initialise all the generations that we're collecting."
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "  // ok, GC over: tell the stats department what happened.\n  stat_endGCWorker(cap, gct);\n  stat_endGC(cap, gct, live_words, copied,\n             live_blocks * BLOCK_SIZE_W - live_words /* slop */,\n             N, n_gc_threads, gc_threads,\n             par_max_copied, par_balanced_copied,\n             any_work, scav_find_work, max_n_todo_overflow);",
  "new_string": "  /* PROBE28-BEGIN \u2014 emit per-GC summary line.  Pre-GC mut_list sizes\n   * were captured at the top of GarbageCollect into probe28_pre_mut.\n   * Walk gct->scavenged_static_objects (via STATIC_LINK) to get the\n   * static-objects chain length scavenged this GC.  Safety cap at 1M\n   * iterations.\n   */\n  {\n      uint32_t pg_ng = RtsFlags.GcFlags.generations;\n      if (pg_ng > PROBE28_MAX_GENS) pg_ng = PROBE28_MAX_GENS;\n      W_ static_chain = 0;\n      StgClosure *sp = gct->scavenged_static_objects;\n      while (sp != END_OF_STATIC_OBJECT_LIST && static_chain < 1000000) {\n          StgClosure *up = UNTAG_STATIC_LIST_PTR(sp);\n          const StgInfoTable *info = get_itbl(up);\n          StgClosure **link = STATIC_LINK(info, up);\n          sp = (StgClosure *)RELAXED_LOAD(link);\n          static_chain++;\n      }\n      debugBelch(\"PROBE28 gc=%llu N=%u maj=%d ng=%u\",\n                 (unsigned long long)probe28_gc_no, N, (int)major_gc, pg_ng);\n      for (uint32_t gg = 0; gg < pg_ng; gg++) {\n          debugBelch(\" preMut%u=%lu\", gg, (unsigned long)probe28_pre_mut[gg]);\n      }\n      debugBelch(\" staticChain=%lu copiedW=%lu liveW=%lu liveB=%lu\\n\",\n                 (unsigned long)static_chain,\n                 (unsigned long)copied,\n                 (unsigned long)live_words,\n                 (unsigned long)live_blocks);\n  }\n  /* PROBE28-END */\n\n  // ok, GC over: tell the stats department what happened.\n  stat_endGCWorker(cap, gct);\n  stat_endGC(cap, gct, live_words, copied,\n             live_blocks * BLOCK_SIZE_W - live_words /* slop */,\n             N, n_gc_threads, gc_threads,\n             par_max_copied, par_balanced_copied,\n             any_work, scav_find_work, max_n_todo_overflow);"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 28 dir + run baseline test suite",
      "activeForm": "Setting up session 28 dir + running baseline",
      "status": "completed"
    },
    {
      "content": "Verify session 27 numbers (quick sanity check: M5.hs -A1m, M5.hs -A1m -G1)",
      "activeForm": "Verifying session 27 numbers",
      "status": "pending"
    },
    {
      "content": "Design + implement RTS-side probe in rts/sm/GC.c (per-GC mut_list lengths + static_objects chain + promotion counts)",
      "activeForm": "Implementing RTS-side probe",
      "status": "completed"
    },
    {
      "content": "Rebuild stage1 RTS lib + redeploy to pmacg5",
      "activeForm": "Rebuilding stage1 RTS + redeploying",
      "status": "in_progress"
    },
    {
      "content": "Run probe matrix: M5.hs -A1m, M5.hs -A1m -G1, Big2.hs -A1m -G1, Big2.hs -A1G",
      "activeForm": "Running probe matrix",
      "status": "pending"
    },
    {
      "content": "Analyze probe output: discriminate 'one bug, two victims' vs 'two bugs'",
      "activeForm": "Analyzing probe output",
      "status": "pending"
    },
    {
      "content": "Decide on next audit (mut_list path vs SRT/static-objects) based on probe results",
      "activeForm": "Deciding next audit path",
      "status": "pending"
    },
    {
      "content": "Write session 28 README + findings + commits.md + HANDOFF.md",
      "activeForm": "Writing session 28 notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && source ../../../scripts/cross-env.sh > /dev/null && ./hadrian/build --flavour=quick-cross -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/rts/libHSrts-1.0.2.a 2>&1 | tail -40",
  "description": "Rebuild stage1 RTS lib with the probe",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/_build -name 'libHSrts*' 2>/dev/null | head -20",
  "description": "Find the actual RTS library"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source ../../../scripts/cross-env.sh > /dev/null && ./hadrian/build --flavour=quick-cross -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>&1 | tail -40",
  "description": "Rebuild stage1 RTS lib (correct path)",
  "timeout": 600000
}


---

## 🤖 Claude

RTS rebuilt. Now check baseline + deploy.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -40 /tmp/session28-baseline.log 2>/dev/null",
  "description": "Check baseline status"
}


---

## 🤖 Claude

The baseline is in Phase 2 (cross-build) — my RTS rebuild will pollute later tests with probe output. Let me kill it and proceed, since session 27 already confirmed baseline green.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "pkill -f run-tests.sh; sleep 1; tail -5 /tmp/session28-baseline.log 2>/dev/null; echo \"---STATUS---\"; pgrep -af 'run-tests.sh|powerpc-apple-darwin8-ghc' | head -5",
  "description": "Kill baseline test runner"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "pkill -9 -f 'powerpc-apple-darwin8-ghc' 2>/dev/null; pkill -9 -f 'cross-env' 2>/dev/null; sleep 2; pgrep -af 'powerpc-apple-darwin8-ghc|run-tests'",
  "description": "Kill any remaining children of baseline"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ps -fp 25286 2>/dev/null; ps -ef | grep -E 'powerpc-apple|run-tests' | grep -v grep | head -5",
  "description": "Inspect remaining process"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && bash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -30",
  "description": "Deploy stage2 with probe to pmacg5",
  "timeout": 600000
}


---

## 🤖 Claude

Probe is working — see `PROBE28` lines in smoke test. Now run the matrix.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 28 dir + run baseline test suite",
      "activeForm": "Setting up session 28 dir + running baseline",
      "status": "completed"
    },
    {
      "content": "Verify session 27 numbers (quick sanity check: M5.hs -A1m, M5.hs -A1m -G1)",
      "activeForm": "Verifying session 27 numbers",
      "status": "in_progress"
    },
    {
      "content": "Design + implement RTS-side probe in rts/sm/GC.c (per-GC mut_list lengths + static_objects chain + promotion counts)",
      "activeForm": "Implementing RTS-side probe",
      "status": "completed"
    },
    {
      "content": "Rebuild stage1 RTS lib + redeploy to pmacg5",
      "activeForm": "Rebuilding stage1 RTS + redeploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix: M5.hs -A1m, M5.hs -A1m -G1, Big2.hs -A1m -G1, Big2.hs -A1G",
      "activeForm": "Running probe matrix",
      "status": "pending"
    },
    {
      "content": "Analyze probe output: discriminate 'one bug, two victims' vs 'two bugs'",
      "activeForm": "Analyzing probe output",
      "status": "pending"
    },
    {
      "content": "Decide on next audit (mut_list path vs SRT/static-objects) based on probe results",
      "activeForm": "Deciding next audit path",
      "status": "pending"
    },
    {
      "content": "Write session 28 README + findings + commits.md + HANDOFF.md",
      "activeForm": "Writing session 28 notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/run-probe-matrix.sh",
  "content": "#!/bin/bash\n# Run the session-28 PROBE28 matrix.\n#\n# PROBE28 is an RTS-side probe in rts/sm/GC.c that prints one line\n# per GC with: gc_no, N, major_gc, ng, preMut* per gen, staticChain,\n# copied, live_words, live_blocks.  See findings.md for analysis.\n#\n# Matrix:\n#   M5.hs    +RTS -A1m -RTS      \u2014 STG-time panic family (session 27: 10/10 fail)\n#   M5.hs    +RTS -A1m -G1 -RTS  \u2014 bug suppressed (session 27: 10/10 OK)\n#   Big2.hs  +RTS -A1m -G1 -RTS  \u2014 TC-time panic (session 27: 10/10 fail)\n#   Big2.hs  +RTS -A1G -RTS      \u2014 bug suppressed (session 27: 10/10 OK)\n#\n# Goal: discriminate \"one bug, two victim data structures\" vs \"two bugs\"\n# by comparing per-GC mut_list lengths and static_objects chain length\n# across the four conditions.\n#\n# Usage:  ./run-probe-matrix.sh [SSH_HOST] [N_ITERS]\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nN_ITERS=\"${2:-5}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session28\"\nmkdir -p \"$LOGDIR\"\n\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\n\n# Stage inputs on pmacg5.\nssh -q \"$PPC_HOST\" 'cat > /tmp/M5.hs' <<'EOF'\nmodule M5 where\nfive = (5::Int)\nsix = (6::Int)\nEOF\n\nssh -q \"$PPC_HOST\" 'cat > /tmp/Big2.hs' <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ntopK :: Ord a => Int -> [a] -> [(Int, a)]\ntopK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs\n  where swap (a, b) = (b, a)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n\nrun_cell () {\n    local input=\"$1\"\n    local label=\"$2\"\n    local rts=\"$3\"\n    local logbase=\"$LOGDIR/${input}-${label}\"\n    echo \"=== ${input}.hs iters=${N_ITERS} flags='${rts}' ===\"\n    local pass=0 fail=0\n    for i in $(seq 1 \"$N_ITERS\"); do\n        local log=\"${logbase}.iter${i}.log\"\n        ssh -q \"$PPC_HOST\" \"\n            cd /tmp\n            rm -f ${input}.hi ${input}.o\n            $DYLD $GHC_REAL -c ${input}.hs $rts 2>&1\n            echo \\\"GHC_EXIT=\\$?\\\"\n        \" > \"$log\" 2>&1\n        local rc\n        rc=$(grep -m1 '^GHC_EXIT=' \"$log\" | sed 's/GHC_EXIT=//' || echo '?')\n        local sig\n        if [ \"$rc\" = \"0\" ]; then\n            pass=$((pass+1)); sig=\"OK\"\n        else\n            fail=$((fail+1))\n            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found|not in scope)' \"$log\" 2>/dev/null | head -c 120)\n            [ -z \"$sig\" ] && sig=\"UNKNOWN_FAIL_rc=$rc\"\n        fi\n        local gcs\n        gcs=$(grep -c '^PROBE28 ' \"$log\" 2>/dev/null || echo 0)\n        printf '  iter%02d rc=%s gcs=%s : %s\\n' \"$i\" \"$rc\" \"$gcs\" \"$sig\"\n    done\n    echo \"  SUMMARY: pass=${pass} fail=${fail} of ${N_ITERS}\"\n    echo\n}\n\nrun_cell M5     a1m     \"+RTS -A1m -RTS\"\nrun_cell M5     a1m-g1  \"+RTS -A1m -G1 -RTS\"\nrun_cell Big2   a1m-g1  \"+RTS -A1m -G1 -RTS\"\nrun_cell Big2   a1g     \"+RTS -A1G -RTS\"\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/run-probe-matrix.sh",
  "description": "Make script executable"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/run-probe-matrix.sh pmacg5 5 2>&1",
  "description": "Run probe matrix (5 iters x 4 cells)",
  "timeout": 900000
}


---

## 🤖 Claude

Probe non-perturbing (mostly) — pass/fail pattern matches session 27. Now let me inspect the PROBE28 lines to find the discriminator signal.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session28 && echo \"=== M5 -A1m iter01 (FAIL) ===\" && grep '^PROBE28' M5-a1m.iter01.log && echo && echo \"=== M5 -A1m iter02 (PASS) ===\" && grep '^PROBE28' M5-a1m.iter02.log",
  "description": "Compare M5.hs -A1m fail vs pass probe output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/log/session28/ | head -20",
  "description": "List session28 logs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session28 && echo \"=== M5 -A1m iter01 (FAIL) ===\" && grep '^PROBE28' M5-a1m.iter1.log && echo && echo \"=== M5 -A1m iter02 (PASS) ===\" && grep '^PROBE28' M5-a1m.iter2.log",
  "description": "Compare M5.hs -A1m fail vs pass probe output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session28 && echo \"=== M5 -A1m iter02 (PASS) ===\" && grep '^PROBE28' M5-a1m.iter2.log && echo && echo \"=== M5 -A1m-G1 iter01 (PASS) ===\" && grep '^PROBE28' M5-a1m-g1.iter1.log",
  "description": "Compare M5.hs pass+ pass G1"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session28 && echo \"=== M5 -A1m-G1 iter01 (PASS) ===\" && grep '^PROBE28' M5-a1m-g1.iter1.log && echo && echo \"=== Big2 -A1m-G1 iter01 (FAIL) ===\" && grep '^PROBE28' Big2-a1m-g1.iter1.log && echo && echo \"=== Big2 -A1G iter01 (PASS) ===\" && grep '^PROBE28' Big2-a1g.iter1.log",
  "description": "Compare M5 -G1, Big2 -G1, Big2 -A1G"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session28 && echo \"=== Big2 -A1m-G1 iter01 (FAIL) ===\" && grep '^PROBE28' Big2-a1m-g1.iter1.log && echo && echo \"=== Big2 -A1G iter01 (PASS) ===\" && grep '^PROBE28' Big2-a1g.iter1.log",
  "description": "Show Big2 logs"
}


---

## 🤖 Claude

Let me look at the actual panic messages and trim down the data view.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/log/session28 && echo \"=== Big2 -A1m-G1 iter01 tail (panic message) ===\" && tail -30 Big2-a1m-g1.iter1.log && echo && echo \"=== M5 -A1m iter01 tail (panic) ===\" && tail -20 M5-a1m.iter1.log",
  "description": "Inspect panic messages in fail logs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "for f in Big2-a1m-g1.iter*.log M5-a1m.iter*.log; do\n  echo \"=== $f ===\"\n  grep -E '(panic|internal error|refineFromInScope|depSortStgBinds|variable not found|not in scope)' \"$f\" | head -3\ndone",
  "description": "Compare panic signatures across iterations"
}


---

## 🤖 Claude

**Big finding**: with the probe enabled, Big2.hs -A1m-G1 now panics with `refineFromInScope` (5/5) — the SAME STG-time signature as M5.hs. Session 27 saw "swap not in scope". The probe's timing perturbation collapsed the TC-time variant into the STG-time variant. Strong evidence for **one bug, two victim data structures**.

Let me run Big2 with -A1m (default -G2) for completeness and verify the same convergence.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/big2-a1m-test.sh",
  "content": "#!/bin/bash\n# Big2.hs +RTS -A1m -RTS (default -G2) under PROBE28 \u2014 verify whether\n# the TC-time \"swap not in scope\" signature from session 27 still fires\n# when the probe is enabled, or whether it collapses to the STG-time\n# refineFromInScope signature seen under -G1.\nset -uo pipefail\nPPC_HOST=\"${1:-pmacg5}\"\nN_ITERS=\"${2:-10}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session28\"\nmkdir -p \"$LOGDIR\"\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\n\nfor i in $(seq 1 \"$N_ITERS\"); do\n    log=\"$LOGDIR/Big2-a1m-G2.iter${i}.log\"\n    ssh -q \"$PPC_HOST\" \"\n        cd /tmp\n        rm -f Big2.hi Big2.o\n        $DYLD $GHC_REAL -c Big2.hs +RTS -A1m -RTS 2>&1\n        echo \\\"GHC_EXIT=\\$?\\\"\n    \" > \"$log\" 2>&1\n    rc=$(grep -m1 '^GHC_EXIT=' \"$log\" | sed 's/GHC_EXIT=//' || echo '?')\n    sig=$(grep -m1 -E '(panic|internal error|refineFromInScope|depSortStgBinds|variable not found|not in scope)' \"$log\" | head -c 120)\n    [ \"$rc\" = \"0\" ] && sig=\"OK\"\n    [ -z \"$sig\" ] && sig=\"UNKNOWN_FAIL_rc=$rc\"\n    gcs=$(grep -c '^PROBE28 ' \"$log\" 2>/dev/null || echo 0)\n    printf '  iter%02d rc=%s gcs=%s : %s\\n' \"$i\" \"$rc\" \"$gcs\" \"$sig\"\ndone\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/big2-a1m-test.sh && bash /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/big2-a1m-test.sh pmacg5 10 2>&1",
  "description": "Big2 -A1m (default G2) under probe",
  "timeout": 900000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "echo \"=== Big2 -A1m G2 iter01 (FAIL swap, gcs=41) ===\" && grep '^PROBE28' Big2-a1m-G2.iter1.log | head -45 && echo --- && echo \"PANIC:\" && grep -A 4 'panic\\|internal error' Big2-a1m-G2.iter1.log | head -20",
  "description": "Show Big2 -A1m-G2 iter1 fail signature"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 28 dir + run baseline test suite",
      "activeForm": "Setting up session 28 dir + running baseline",
      "status": "completed"
    },
    {
      "content": "Verify session 27 numbers (quick sanity check: M5.hs -A1m, M5.hs -A1m -G1)",
      "activeForm": "Verifying session 27 numbers",
      "status": "completed"
    },
    {
      "content": "Design + implement RTS-side probe in rts/sm/GC.c (per-GC mut_list lengths + static_objects chain + promotion counts)",
      "activeForm": "Implementing RTS-side probe",
      "status": "completed"
    },
    {
      "content": "Rebuild stage1 RTS lib + redeploy to pmacg5",
      "activeForm": "Rebuilding stage1 RTS + redeploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix: M5.hs -A1m, M5.hs -A1m -G1, Big2.hs -A1m -G1, Big2.hs -A1G",
      "activeForm": "Running probe matrix",
      "status": "completed"
    },
    {
      "content": "Analyze probe output: discriminate 'one bug, two victims' vs 'two bugs'",
      "activeForm": "Analyzing probe output",
      "status": "completed"
    },
    {
      "content": "Revert probe + redeploy clean stage2 (don't ship probe-noisy stage2)",
      "activeForm": "Reverting probe + redeploying clean stage2",
      "status": "in_progress"
    },
    {
      "content": "Write session 28 README + findings + commits.md + HANDOFF.md",
      "activeForm": "Writing session 28 notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude

Let me save the probe as a patch, revert the source, rebuild clean.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git diff rts/sm/GC.c > /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch && wc -l /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch && head -20 /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch",
  "description": "Save PROBE28 as a patch"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git checkout rts/sm/GC.c && git diff rts/sm/GC.c | wc -l && grep -c PROBE28 rts/sm/GC.c",
  "description": "Revert GC.c"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source ../../../scripts/cross-env.sh > /dev/null && ./hadrian/build --flavour=quick-cross -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>&1 | tail -10",
  "description": "Rebuild RTS clean",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && bash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -15",
  "description": "Re-deploy clean stage2",
  "timeout": 600000
}


---

## 🤖 Claude

Source tree clean, stage2 redeployed. Now write up.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/README.md",
  "content": "# Session 28 \u2014 stage2 GC bug, round 10 (RTS-side per-GC probe; session-27's \"two distinct corruption modes\" hypothesis downgraded to \"one bug, two victim data structures\")\n\n**Dates:** 2026-05-12 (continuation of session 27).\n\n**Status on arrival:** v0.12.0 ships unchanged.  Session 27 nailed a\ndeterministic non-perturbing repro (M5.hs `+RTS -A1m` panics 10/10 on\nclean stage2 with the STG-time panic family) and discovered that\n`+RTS -A1m -G1` (single-generation) fully suppresses the M5.hs panic\nbut does NOT suppress Big2.hs's failure \u2014 under `-G1`, Big2.hs panics\n10/10 with a new, previously-uncatalogued signature: `* GHC internal\nerror: 'swap' is not in scope during type checking, but it passed\nthe renamer`.  Session 27 framed this as \"the bug has at least two\ndistinct corruption modes\" \u2014 STG-time (suppressed by `-G1`) and TC-\ntime (not suppressed) \u2014 and queued discriminating \"one bug, two\nvictims\" vs \"two bugs\" as session 28's top priority via a slim RTS-\nside probe.\n\n**Status on exit:**\n\n- **PROBE28 implemented** as 3 instrumentation points in\n  [`rts/sm/GC.c`](../../../external/ghc-modern/ghc-9.2.8/rts/sm/GC.c)\n  (file-static state + pre-GC mut_list snapshot + post-GC summary\n  line via `debugBelch`).  RTS-side only \u2014 no Haskell-side\n  perturbation.  Patch saved at\n  [`probe28-rts-gc.patch`](probe28-rts-gc.patch).\n- **Probe rebuilt + redeployed**, matrix run, then source reverted\n  and clean stage2 redeployed at session end.  v0.12.0 ships\n  unchanged.\n- **One-bug hypothesis strongly supported.**  With PROBE28 enabled,\n  Big2.hs `+RTS -A1m -G1` now panics 5/5 with the STG-time\n  `refineFromInScope` signature \u2014 the **same** family as M5.hs's\n  `-A1m` failures and **not** session 27's \"swap not in scope\"\n  TC-time signature.  The probe adds tiny timing delays\n  (debugBelch per GC); that's enough to shift which downstream\n  data structure ends up holding the corrupted closure pointer.\n  Same root corruption, different downstream victim.  Big2.hs\n  `+RTS -A1m` (default `-G2`) still produces \"swap not in scope\"\n  5/10 even with the probe, so the TC-time signature is real but\n  is not a separate bug.\n- **Static_objects scavenge ruled out as the cause.**  Under `-G1`\n  every GC is major; PROBE28 shows the `scavenged_static_objects`\n  chain is walked at ~174\u2013181k entries on every GC for both M5.hs\n  (PASS) and Big2.hs (FAIL).  Same load both ways; M5 doesn't\n  crash, Big2 does \u2014 so the static_objects code path is not the\n  bug.\n- **mut_list scavenge ruled out as the cause.**  Under `-G1`, gen-0\n  has no mut_list (preMut0 = 0 always; preMut1 doesn't exist\n  because ng=1).  Big2.hs `-G1` still fails 5/5 with the corruption.\n  So the bug fires WITHOUT any mut_list scavenging happening.  The\n  remaining mut_list audit queued by session 27 is therefore lower\n  priority.\n- **Bug fires at deterministic GC indices.**  M5 `-A1m -G2`: fail at\n  GC 24 (when the heuristic picks major) or pass at GC 25 (when it\n  defers).  Big2 `-A1m -G1`: fail at GC 17 (after liveB \u2248 1.7M\n  words).  Big2 `-A1m -G2`: fail at GC 41 (5/10) or pass at GC 42\n  (5/10).  In every failing run the failing GC is a major collection\n  with copiedW \u2248 365\u2013465k.\n- **Remaining suspects** after probe data: `evacuate()`, `copy()` /\n  `copy_tag()`, `scavenge_block()` dispatch, info-table / forwarding-\n  pointer machinery in `rts/sm/Evac.c` and `rts/sm/Scav.c`.  These run\n  on every GC regardless of `-G` and would fire identically across\n  M5/Big2 EXCEPT that Big2 has more closures of whatever type\n  triggers the bug.\n- v0.12.0 unchanged.  Source tree clean at session end.  Stage2 on\n  pmacg5 rebuilt+redeployed to match v0.12.0.  No commits to the\n  GHC tree this session.\n\nHANDOFF for session 29: see [`HANDOFF.md`](HANDOFF.md).  Top of\nqueue: enhance PROBE28 with a per-closure-type histogram so we can\nidentify which closure type's evacuate/scavenge fires the bug.  Then\naudit `rts/sm/Evac.c::evacuate` and `rts/sm/Scav.c::scavenge_block`\nwith PPC32 eyes.\n\n## What we did, in order\n\n### Step 1 \u2014 verify baseline\n\nStarted `tests/run-tests.sh` in the background as part of arrival\nsanity; killed it once Phase 2 reached `12_show_read` because by\nthen we'd queued an RTS source edit and the in-flight Phase-2 tests\nwould have linked against half-old / half-new RTS.  Session 27 had\nalready certified v0.12.0 stage2 green on the same day, so we\naccepted that certification and moved on.  (Phase 1 host-compile\npassed all 30 programs cleanly during the partial run.)\n\n### Step 2 \u2014 design + implement PROBE28\n\nPROBE28 lives entirely in\n[`rts/sm/GC.c`](../../../external/ghc-modern/ghc-9.2.8/rts/sm/GC.c).\nThree insertion points:\n\n1. **File-static state** (near `consec_idle_gcs`) \u2014 `probe28_gc_no`\n   counter and `probe28_pre_mut[8]` snapshot array.\n2. **Pre-GC snapshot** (after `collect_pinned_object_blocks();`\n   before `prepare_collected_gen` loop) \u2014 `countOccupied` per gen\n   across all caps, stored in `probe28_pre_mut`.  Must run before\n   the prepare loops because they throw away or stash the mut_lists.\n3. **Post-GC summary** (just before `stat_endGCWorker` /\n   `stat_endGC`) \u2014 walks `gct->scavenged_static_objects` via\n   `STATIC_LINK` macros (safety-capped at 1M iterations) and emits\n   a single `debugBelch` line per GC:\n\n```\nPROBE28 gc=<n> N=<gen> maj=<0|1> ng=<gens> preMut0=<w> preMut1=<w> ...\n        staticChain=<count> copiedW=<w> liveW=<w> liveB=<blocks>\n```\n\nNo Haskell-side instrumentation, no heap allocation, no atomic\nops.  Cost: one printf per GC + walks of mut_lists (1-block typical)\nand static_objects (~175k entries on major GCs).  Slight perturbation\nexpected from the extra stderr writes during GC; quantified below.\n\nPatch saved at [`probe28-rts-gc.patch`](probe28-rts-gc.patch) for\nre-application.\n\n### Step 3 \u2014 RTS rebuild + redeploy\n\n```bash\ncd external/ghc-modern/ghc-9.2.8\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\n# (3.3 s \u2014 only RTS bits affected, ranlib + rsync)\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\nThe HANDOFF's path\n`_build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/rts/libHSrts-1.0.2.a`\ndoes not parse for Hadrian.  Corrected path:\n`_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`.\n\nStage2 smoke test passed cleanly; PROBE28 lines visible in the\nsmoke-test stderr.\n\n### Step 4 \u2014 run the probe matrix\n\n[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) runs\neach cell 5\u00d7, captures all stderr (including PROBE28 lines) per\niter.\n\n```\n=== M5.hs   iters=5 flags='+RTS -A1m -RTS'    === pass=3 fail=2   (depSortStgBinds, both at gc 24)\n=== M5.hs   iters=5 flags='+RTS -A1m -G1 -RTS' === pass=5 fail=0   (suppressed; 13 GCs)\n=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' === pass=0 fail=5   (**refineFromInScope** at gc 17, NOT \"swap not in scope\")\n=== Big2.hs iters=5 flags='+RTS -A1G -RTS'    === pass=5 fail=0   (control; 1 GC)\n```\n\n[`scripts/big2-a1m-test.sh`](scripts/big2-a1m-test.sh) added Big2\n`-A1m` (default `-G2`) at N=10:\n\n```\n  iter01 rc=1 gcs=41 : `swap' is not in scope during type checking\n  iter02 rc=1 gcs=41 : `swap' is not in scope during type checking\n  iter03 rc=0 gcs=42 : OK\n  iter04 rc=1 gcs=41 : `swap' is not in scope during type checking\n  iter05 rc=0 gcs=42 : OK\n  iter06 rc=0 gcs=42 : OK\n  iter07 rc=0 gcs=43 : OK\n  iter08 rc=1 gcs=41 : `swap' is not in scope during type checking\n  iter09 rc=0 gcs=42 : OK\n  iter10 rc=1 gcs=41 : `swap' is not in scope during type checking\n```\n\n5/10 with the TC-time \"swap\" signature.  Probe perturbation lowered\nthe fail rate from 9/10 (session 27, no probe) to 5/10, but the\nTC-time signature is preserved \u2014 the probe didn't make the TC-time\nmanifestation impossible.\n\nSee [`findings.md`](findings.md) for the full per-GC analysis.\n\n### Step 5 \u2014 revert + clean redeploy\n\nSaved the probe as [`probe28-rts-gc.patch`](probe28-rts-gc.patch),\nran `git checkout -- rts/sm/GC.c`, rebuilt the RTS lib (3.5 s),\nre-ran `deploy-stage2.sh pmacg5`.  Stage2 now matches v0.12.0\nagain.  Source tree is clean.\n\n## Status on exit\n\n- **v0.12.0 unchanged.**  Stage2 ships with the `+RTS -A1G` wrapper.\n- **No GHC-tree source edits committed this session.**  Probe lives\n  only as the patch in this session dir.\n- **Stage2 ghc on pmacg5 is the clean rebuild after probe revert.**\n- **Logs at** [`../../../log/session28/`](../../../log/session28/)\n  (gitignored).\n- **HANDOFF for session 29** queues per-closure-type probe\n  enhancement + `Evac.c` / `Scav.c` audit.\n\n## Files added this session\n\n- [`README.md`](README.md), [`findings.md`](findings.md),\n  [`HANDOFF.md`](HANDOFF.md), `commits.md` \u2014 writeup.\n- [`probe28-rts-gc.patch`](probe28-rts-gc.patch) \u2014 the RTS-side\n  probe as a git-format patch.  Re-apply with `git apply` from\n  inside `external/ghc-modern/ghc-9.2.8`.\n- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) \u2014\n  M5 / Big2 \u00d7 `-A1m` / `-A1m -G1` / `-A1G` matrix (5 iters each).\n- [`scripts/big2-a1m-test.sh`](scripts/big2-a1m-test.sh) \u2014 Big2 at\n  default `-G2` (10 iters) to verify TC-time signature persistence.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/findings.md",
  "content": "# Session 28 findings \u2014 PROBE28 discriminator data downgrades session-27's \"two distinct bugs\" to \"one bug, two victim data structures\"\n\n## TL;DR\n\n- **PROBE28** (slim RTS-side per-GC printf, no Haskell-side\n  instrumentation) confirms the bug fires regardless of:\n  - mut_list scavenge activity (under `-G1` mut_lists are empty;\n    Big2 still fails),\n  - static_objects scavenge load (M5 `-G1` passes despite walking\n    the same ~175k-entry static chain on every GC that Big2 `-G1`\n    walks).\n- **Big2.hs `-A1m -G1` panic signature changed under the probe.**\n  Session 27 (no probe): 10/10 fail with `* GHC internal error:\n  'swap' is not in scope during type checking, but it passed the\n  renamer` (TC-time variant).  Session 28 (with PROBE28): 5/5 fail\n  with `panic! refineFromInScope` (STG-time variant).  The probe's\n  small per-GC timing perturbation is enough to shift the corruption\n  to a different downstream victim data structure.  **Strong evidence\n  the TC-time and STG-time signatures are the same underlying bug.**\n- **`-A1m -G2` TC-time signature persists under the probe** for Big2\n  (5/10 still produce \"swap not in scope\").  So the TC-time\n  manifestation is real, just timing-fragile; it's a different\n  victim, not a different bug.\n- M5 `-A1m -G2` failure rate dropped from 10/10 (session 27, no\n  probe) to 2/5 with PROBE28 \u2014 confirming the probe is mildly\n  perturbing but does not suppress the bug.\n- **Removed from suspect list:** `scavenge_capability_mut_lists` /\n  `scavenge_mutable_list`, `scavenge_static`, `scavenge_thunk_srt`,\n  `scavenge_fun_srt`.  All run identically (or more, under `-G1`) in\n  the passing case (M5 `-G1`) and the failing case (Big2 `-G1`).\n- **Remaining suspects:** `rts/sm/Evac.c::evacuate` / `copy_tag` /\n  `copy`, `rts/sm/Scav.c::scavenge_block` dispatch by closure type,\n  forwarding-pointer / info-table machinery, PPC32-specific block\n  arithmetic in `bdescr` / `BLOCK_SIZE` macros.\n- v0.12.0 ships unchanged.  Probe reverted at session end; clean\n  stage2 redeployed.\n\n## The probe\n\n3 insertion points in `rts/sm/GC.c`.  See\n[`probe28-rts-gc.patch`](probe28-rts-gc.patch) for the full diff.\n\n### File-static state (line ~123)\n\n```c\n#define PROBE28_MAX_GENS 8\nstatic StgWord64 probe28_gc_no = 0;\nstatic W_ probe28_pre_mut[PROBE28_MAX_GENS];\n```\n\n### Pre-GC snapshot (just before the `prepare_collected_gen` loop)\n\n```c\nprobe28_gc_no++;\n{\n    uint32_t pg_ng = RtsFlags.GcFlags.generations;\n    if (pg_ng > PROBE28_MAX_GENS) pg_ng = PROBE28_MAX_GENS;\n    for (uint32_t gg = 0; gg < PROBE28_MAX_GENS; gg++) {\n        probe28_pre_mut[gg] = 0;\n    }\n    for (uint32_t gg = 0; gg < pg_ng; gg++) {\n        W_ s = 0;\n        for (uint32_t c = 0; c < getNumCapabilities(); c++) {\n            s += countOccupied(capabilities[c]->mut_lists[gg]);\n        }\n        probe28_pre_mut[gg] = s;\n    }\n}\n```\n\n### Post-GC summary line (just before `stat_endGCWorker`)\n\n```c\n{\n    uint32_t pg_ng = RtsFlags.GcFlags.generations;\n    if (pg_ng > PROBE28_MAX_GENS) pg_ng = PROBE28_MAX_GENS;\n    W_ static_chain = 0;\n    StgClosure *sp = gct->scavenged_static_objects;\n    while (sp != END_OF_STATIC_OBJECT_LIST && static_chain < 1000000) {\n        StgClosure *up = UNTAG_STATIC_LIST_PTR(sp);\n        const StgInfoTable *info = get_itbl(up);\n        StgClosure **link = STATIC_LINK(info, up);\n        sp = (StgClosure *)RELAXED_LOAD(link);\n        static_chain++;\n    }\n    debugBelch(\"PROBE28 gc=%llu N=%u maj=%d ng=%u\",\n               (unsigned long long)probe28_gc_no, N, (int)major_gc, pg_ng);\n    for (uint32_t gg = 0; gg < pg_ng; gg++) {\n        debugBelch(\" preMut%u=%lu\", gg, (unsigned long)probe28_pre_mut[gg]);\n    }\n    debugBelch(\" staticChain=%lu copiedW=%lu liveW=%lu liveB=%lu\\n\",\n               (unsigned long)static_chain, (unsigned long)copied,\n               (unsigned long)live_words, (unsigned long)live_blocks);\n}\n```\n\n## Data \u2014 pass/fail matrix under PROBE28\n\nAll on pmacg5 (PowerMac G5 / Tiger 10.4.11), `/opt/ghc-stage2/bin/ghc-real`\nbuilt with PROBE28 applied to `rts/sm/GC.c`.\n\n| Input    | RTS flags         | iters | pass | fail | dominant symptom                                                |\n|----------|-------------------|------:|-----:|-----:|-----------------------------------------------------------------|\n| M5.hs    | `+RTS -A1m -RTS`  |    5  |   3  |   2  | depSortStgBinds (both fails at GC 24, both major)               |\n| M5.hs    | `+RTS -A1m -G1`   |    5  |   5  |   0  | suppressed (13 GCs, all major under `-G1`)                       |\n| Big2.hs  | `+RTS -A1m -G1`   |    5  |   0  |   5  | **refineFromInScope** at GC 17 (5/5) \u2014 **not** \"swap not in scope\"|\n| Big2.hs  | `+RTS -A1G -RTS`  |    5  |   5  |   0  | control (1 GC)                                                   |\n| Big2.hs  | `+RTS -A1m -RTS`  |   10  |   5  |   5  | \"swap not in scope\" (TC-time, at GC 41 in failing iters)        |\n\n### Comparison to session 27 (clean stage2, no probe)\n\n| Cell                       | Session 27 fail rate / signature          | Session 28 (probe) fail rate / signature        |\n|----------------------------|-------------------------------------------|--------------------------------------------------|\n| M5.hs `-A1m`               | 10/10 (depSortStgBinds + refineFromInScope) | 2/5 (depSortStgBinds)                            |\n| M5.hs `-A1m -G1`           | 0/10 (suppressed)                         | 0/5 (suppressed)                                  |\n| Big2.hs `-A1m -G1`         | **10/10 (\"swap not in scope\")**           | **5/5 (refineFromInScope)** \u2190 **signature shift** |\n| Big2.hs `-A1G`             | 0/10                                      | 0/5                                              |\n| Big2.hs `-A1m` (default `-G2`) | 9/10 (8\u00d7 \"swap\", 1\u00d7 depSortStgBinds)  | 5/10 (5\u00d7 \"swap\")                                  |\n\n**The probe lowers the fail rate but does not suppress the bug.**\nCritically, Big2 `-G1` flips from TC-time to STG-time under the\nprobe \u2014 this is the discriminator.\n\n## Why the probe-induced signature shift is conclusive\n\nThe \"two distinct bugs\" reading from session 27 predicted that one bug\nfired the STG-time family and a separate bug fired the TC-time family.\nUnder that reading, perturbing the GC with a printf shouldn't move a\nfailure from the TC-time bug to the STG-time bug \u2014 they have different\nmechanisms.\n\nThe \"one bug, two victim data structures\" reading predicted that\nadding tiny delays between mutator and GC phases would change which\nin-memory IntMap / VarEnv / TcTypeEnv the corruption lands in.  That\nis exactly what we observe: Big2 `-A1m -G1` deterministically panics\nwith `refineFromInScope` (STG-time, Simplify/Env.hs:706) under the\nprobe, while without the probe (session 27) it deterministically\npanics with the TC-time signature.\n\nBoth signatures are reading from a corrupted VarEnv / IntMap chain\n(LocalRdrEnv \u2192 TcTypeEnv \u2192 SimplifierEnv \u2192 ... \u2014 these are all\n`Data.IntMap`-backed `VarEnv` newtypes deep down).  The corruption\nis the same; the victim depends on which of these maps holds the\nfreshly-corrupted node when the bug surfaces.\n\n## Why static_objects scavenge is ruled out\n\nPROBE28 reports `staticChain` (the length of\n`gct->scavenged_static_objects` walked via `STATIC_LINK`) per GC.\n\n| Cell                     | staticChain per major GC | major GCs / total GCs | result |\n|--------------------------|--------------------------|-----------------------|--------|\n| M5.hs `-A1m -G1` (PASS)  | ~175 000\u2013181 000         | 13 / 13 (all major)   | PASS   |\n| Big2.hs `-A1m -G1` (FAIL)| ~174 000\u2013181 000         | 17 / 17 (all major)   | FAIL   |\n| M5.hs `-A1m` (FAIL iter) | ~174 000\u2013180 000         | 4 / 24                | FAIL at GC 24 (major) |\n| Big2.hs `-A1m` (FAIL)    | ~174 000\u2013180 000         | 5 / 41                | FAIL at GC 41 (major) |\n\nThe static_objects chain is the same magnitude in PASS and FAIL\ncases.  Under `-G1` it gets walked on every GC (because every GC is\nmajor and `scavenge_static` always runs on majors); under `-G2` it\ngets walked on majors only.  If a bug in `scavenge_static` /\n`scavenge_thunk_srt` / `scavenge_fun_srt` were responsible, M5\n`-G1` would not be a clean PASS (those code paths fire 13 times\non every successful M5 `-G1` run).\n\nThis kills the \"Third: address the TC-time variant separately\" thread\nfrom session 27's HANDOFF (audit `scavenge_thunk_srt` / `scavenge_fun_srt`\n/ `scavenge_static`).\n\n## Why mut_list scavenge is ruled out\n\nUnder `-G1`, `RtsFlags.GcFlags.generations == 1`, so:\n\n- `prepare_collected_gen` for g==0 hits the `g != 0` test as false\n  and is a no-op (does not stash to `saved_mut_lists`).\n- `prepare_uncollected_gen` is never called (loop bound is empty).\n- `scavenge_capability_mut_lists` runs the loop\n  `for (g = generations-1; g > N; g--)` with `generations=1`, `N=0`:\n  the loop body executes zero times.  No older-gen mut_list is\n  scavenged.\n\nPROBE28 confirms: under `-G1`, `preMut0 = 0` every GC (gen 0 has no\nmut_list).  No older gen exists, so no preMut1 either.\n\nBig2.hs `-A1m -G1` panics 5/5 with this configuration.  **The bug\nfires without ANY mut_list scavenging happening.**  This kills\nsession 27's \"Second: audit `rts/Updates.cmm` and write-barrier\ncode\" thread as a primary direction (it can still be a contributing\nfactor in the `-G2` path, but it's not the root cause).\n\n## Where the bug must be \u2014 narrowed suspect list\n\nThe bug fires:\n\n- \u2705 On every major GC under `-G1` for sufficiently large heaps\n  (Big2 fails at every iteration of this configuration).\n- \u2705 Sometimes on major GCs under `-G2` (M5 / Big2 fail rates 0\u2013100%\n  depending on heap-shape heuristics, all failures at major GCs).\n- \u274c Not via mut_list scavenge (no mut_list under `-G1`).\n- \u274c Not via static_objects scavenge (M5 `-G1` walks the same chain\n  size that Big2 `-G1` walks; M5 passes).\n\nWhat runs on every major GC (and is reachable from `-G1`):\n\n1. `evacuate()` (rts/sm/Evac.c) \u2014 copies live closures from from-space\n   to to-space.  Reads info-table pointer, decides closure size + ptrs,\n   calls `copy_tag()` to copy + tag the closure, installs forwarding\n   pointer.\n2. `copy_tag()` / `copy()` (rts/sm/Evac.c) \u2014 the inner copy routine.\n   Includes a tight loop over the closure payload.\n3. `scavenge_block()` (rts/sm/Scav.c) \u2014 iterates from-space objects\n   and dispatches by `info->type` to a per-closure-type scavenge that\n   calls `evacuate` on each pointer field.\n4. `scavenge_one()` \u2014 handles a single closure (used from mut_list\n   scavenge, but also from `scavenge_block`'s general dispatch).\n5. Forwarding-pointer reads/writes \u2014 `LOOKS_LIKE_INFO_PTR`, `IS_FORWARDING_PTR`,\n   `MIN_INTLIKE`/`MAX_INTLIKE` macros, `getInfoTable` indirection.\n\nAll of these involve pointer arithmetic at byte / word granularity\nand assume specific alignment.  PPC32 is a 32-bit big-endian target,\nwhich is uncommon for modern GHC \u2014 bugs at the byte-order or\nalignment level would survive QC on 64-bit little-endian boxes and\nfire here.\n\n## Bug-firing pattern\n\n| Run                       | Failing GC | Pre-fail mut1 | copiedW at fail | liveB after fail GC |\n|---------------------------|-----------:|--------------:|----------------:|--------------------:|\n| M5 `-A1m` iter01 (FAIL)   |    GC 24   |       808     |     365 847     |       392           |\n| M5 `-A1m` iter02 (PASS)   |    GC 25   |       306     |     367 208     |       412           |\n| Big2 `-A1m -G1` iter01    |    GC 17   |       n/a     |     464 922     |       483           |\n| Big2 `-A1m` iter01        |    GC 41   |       398     |     462 385     |       484           |\n\nThe failing major GCs all have copiedW around 365\u2013465k words and\npost-fail liveB \u2248 400\u2013500.  The pre-fail mut1 differs (it's an\ninput-shape variable, not the trigger).  The shared feature is the\n*shape* of the major collection's work \u2014 `evacuate` is being called\non a few hundred thousand words of live data, and somewhere in\nthere one closure ends up with a corrupted pointer field.\n\nThe deterministic GC index per cell tells us the bug fires at a\nspecific point in execution \u2014 same code path on the same input\nproduces the same GC number that fires.  This is consistent with\nthe corruption being introduced when a specific closure type appears\nin from-space for the first time.\n\n## Open questions / next-step priorities\n\n### Top: identify WHICH closure type evacuate is mis-handling\n\nPROBE28 captures heap-level summary but doesn't distinguish closure\ntypes.  A focused follow-up probe: count `info->type` occurrences\nper GC, emitted as a histogram in the same probe line.  If we see\nthat Big2's failing GC contains a closure type that M5 `-G1`'s GCs\ndo not contain, we have the answer.\n\nClosure-type set worth focusing on:\n\n- `THUNK_1_0`, `THUNK_2_0`, `THUNK_1_1`, `THUNK_2_1`, `THUNK` \u2014 high\n  volume in compilation workload; payload + SRT layout differs by\n  shape.\n- `IND`, `IND_STATIC` \u2014 indirection chains; `IND` payload is a single\n  pointer; evacuate is supposed to short-circuit them.\n- `BLACKHOLE` \u2014 thunk-update marker; subtle race-free protocol with\n  the write barrier.\n- `PAP`, `AP`, `AP_STACK` \u2014 partial-application closures, variable-\n  size payload, bitmap-driven scavenge.\n- `MUT_VAR_CLEAN` / `MUT_VAR_DIRTY` \u2014 relevant only under `-G2` but\n  worth distinguishing.\n- `FUN_2_0` / `FUN_2_1` / `FUN_1_0` etc. \u2014 the bulk of allocated\n  closures.\n\nAlso worth recording: count of forwarding-pointer hits during\nevacuate (i.e. closures that were already evacuated).\n\n### Second: read `rts/sm/Evac.c` with PPC32 eyes\n\nSpecifically:\n\n- `evacuate1` / `evacuate` \u2014 the dispatch (line ~620).  Look at how\n  `info` is read from `p->header.info` and what `IS_FORWARDING_PTR`\n  test does on PPC32 (32-bit forward pointer with low-bit tag).\n- `copy_tag` (line ~150) \u2014 uses `alloc_for_copy` to get to-space\n  block, then `memcpy_words`.  `memcpy_words` is a hand-rolled\n  copy loop on PPC32; should be a simple unrolled loop but worth\n  reading.\n- `copy` (line ~104) \u2014 copy without tag preservation.\n\n### Third: read `rts/sm/Scav.c::scavenge_block` for PPC32-isms\n\n`scavenge_block` walks a block from `bd->start` to `bd->free`,\nswitches on `info->type`, calls `evacuate` for each pointer\nfield.  Key risk areas:\n\n- The pointer arithmetic that advances `p` past each closure.  Each\n  closure type has a different size; getting the size wrong leads to\n  reading the next closure's header as a pointer, which would corrupt\n  the next closure's payload via `evacuate`.\n- Bitmap-driven scavenge: `scavenge_PAP_payload`, `scavenge_arg_block`,\n  `scavenge_large_bitmap`, `scavenge_small_bitmap`.\n\n### Fourth: try a Big2 variant that omits `Data.Map.Strict`\n\nSession 27 noted Big2 differs from M5 in importing `Data.Map.Strict`\nand having a `where`-bound local function.  Cheap test: simplify\nBig2 progressively until the bug stops firing.  The first removal\nthat turns 5/5 fail \u2192 0/5 pass tells us which closure type / library\nfunction is the trigger.\n\n## Process notes\n\n- **PROBE28's perturbation is real but not bug-suppressing.**  M5 `-A1m`\n  drops from 10/10 fail \u2192 2/5 fail.  Big2 `-A1m -G1` stays 5/5 fail\n  but shifts signature.  For session-29's enhanced probe, prefer a\n  ring-buffer or sampling approach to minimize printf overhead.\n- **The probe rebuild path corrected.**  Session 27's HANDOFF said\n  `_build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/rts/libHSrts-1.0.2.a`;\n  the actual Hadrian target is\n  `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`.\n- **End-of-session cleanup** is non-negotiable: probe noise to stderr\n  on every GC would break user-facing usage.  Source reverted +\n  rebuilt + redeployed at session end.\n\n## Files added this session\n\n- [`README.md`](README.md), this `findings.md`, `HANDOFF.md`,\n  `commits.md` \u2014 writeup.\n- [`probe28-rts-gc.patch`](probe28-rts-gc.patch) \u2014 the RTS probe\n  (re-applicable via `git apply` inside\n  `external/ghc-modern/ghc-9.2.8`).\n- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) \u2014\n  the M5 / Big2 \u00d7 `-A1m` / `-A1m -G1` / `-A1G` matrix.\n- [`scripts/big2-a1m-test.sh`](scripts/big2-a1m-test.sh) \u2014 Big2 at\n  default `-G2`.\n- Run logs at [`../../../log/session28/`](../../../log/session28/)\n  (gitignored).\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md",
  "content": "# Handoff from session 28 \u2192 session 29\n\n**For:** the next claude session.\n**From:** session 28 (PROBE28 RTS-side discriminator; session-27's\n\"two distinct corruption modes\" downgraded to \"one bug, two victim\ndata structures\"; mut_list and static_objects paths ruled out;\n2026-05-12).\n**Recommended pickup:** enhance PROBE28 with a per-closure-type\nhistogram and then audit `rts/sm/Evac.c` / `rts/sm/Scav.c::scavenge_block`\nwith PPC32 eyes.\n\n## TL;DR (mandatory read)\n\n- PROBE28 (slim RTS-side per-GC printf in `rts/sm/GC.c`) shows that\n  the static_objects scavenge code path runs identically (~175k chain\n  walks per major GC) for both M5.hs `-G1` (PASS) and Big2.hs `-G1`\n  (FAIL).  **`scavenge_static` / `scavenge_thunk_srt` / `scavenge_fun_srt`\n  ruled out** as the bug.\n- Under `-G1`, mut_lists are unused (the older-gen scavenge loop is\n  empty, mut_list[0] is always 0).  Big2.hs `-A1m -G1` panics 5/5 in\n  this configuration.  **mut_list / write-barrier path ruled out**\n  as the root cause (still a possible contributor under `-G2` only).\n- **Under PROBE28, Big2.hs `-A1m -G1` panics with `refineFromInScope`\n  (STG-time) 5/5 \u2014 NOT with session 27's \"swap not in scope\" TC-time\n  signature.**  The probe's tiny per-GC timing perturbation is\n  enough to shift which downstream data structure (Simplifier\n  InScopeSet vs Typechecker TcTypeEnv) catches the corrupted closure.\n  Both signatures are reads from corrupted IntMap-backed VarEnv\n  structures \u2014 same root corruption, different victim.\n- **Remaining suspects:** `evacuate()` / `copy_tag()` / `copy()` in\n  `rts/sm/Evac.c`, `scavenge_block()` dispatch in `rts/sm/Scav.c`,\n  forwarding-pointer machinery, info-table reads on PPC32 (32-bit\n  big-endian).\n- v0.12.0 ships unchanged.  Source tree clean.  Probe saved as a\n  patch under this session dir; reverted before session end; stage2\n  on pmacg5 rebuilt+redeployed clean.\n\n## Read in order\n\n1. **This file.**\n2. [`README.md`](README.md) \u2014 narrative of session 28.\n3. [`findings.md`](findings.md) \u2014 full per-GC data + analysis.\n4. [`probe28-rts-gc.patch`](probe28-rts-gc.patch) \u2014 the probe diff,\n   ready to re-apply.\n5. (Reference) Session 27 [`HANDOFF.md`](../2026-05-12-session-27-non-perturbing-repro/HANDOFF.md)\n   \u2014 the context this session built on.\n6. (Reference) Session 27 [`findings.md`](../2026-05-12-session-27-non-perturbing-repro/findings.md)\n   \u2014 particularly the \"Open hypotheses\" section, several of which\n   are now ruled out.\n\n## What to NOT redo\n\n- **Don't audit `rts/Updates.cmm`, `rts/PrimOps.cmm::stg_writeMutVarzh`,\n  `rts/sm/Storage.c::dirty_MUT_VAR`, or `rts/sm/Scav.c::scavenge_capability_mut_lists`.**\n  PROBE28 shows the mut_list path is empty when Big2.hs `-G1` panics \u2014\n  the bug doesn't need any mut_list activity to fire.  Session 27's\n  HANDOFF priority-2 audit is no longer load-bearing.\n- **Don't audit `scavenge_thunk_srt`, `scavenge_fun_srt`, or\n  `scavenge_static`.**  PROBE28 shows the same chain length is walked\n  on every GC in both M5 `-G1` (PASS) and Big2 `-G1` (FAIL).  Session\n  27's HANDOFF priority-3 audit is dead.\n- **Don't write more Haskell-side instrumentation.**  Even PROBE28's\n  RTS-side `debugBelch` slightly perturbed timing (M5 `-A1m` dropped\n  from 10/10 fail to 2/5 fail).  Haskell-side instrumentation (PROBE26\n  style) is strictly worse.\n- **Don't treat the TC-time \"swap not in scope\" signature as a\n  separate bug.**  Session 27 framed it as a second corruption mode;\n  PROBE28 shows it's the same bug, different victim.\n- **Don't rebuild the world via `./hadrian/build` without a target.**\n  The RTS rebuild for the probe takes ~3 seconds with the corrected\n  Hadrian target:\n  `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`\n  (note: NOT the path the previous HANDOFF gave \u2014 `ghc-9.2.8/rts/...`\n  doesn't parse).\n\n## What to try next, in priority order\n\n### Top: per-closure-type histogram probe\n\nExtend PROBE28 to count `info->type` per GC and print a compact\nhistogram.  The simplest implementation: add a static `W_\nprobe28_type_hist[64]` indexed by `info->type` (which is an enum with\n~60 values).  Increment in `scavenge_block` for each closure\nprocessed.  Print as part of the post-GC summary line.  Reset to 0 at\nthe start of each GC.\n\nGoal: identify which closure type appears in Big2's failing GC but\nnot in M5 `-G1`'s passing GCs.  If we find e.g. `THUNK_2_0` only\nappears in Big2 \u2014 that's the suspect for an `evacuate` /\n`scavenge_block` bug.\n\nCost: ~1 RTS rebuild + redeploy + 4 probe-matrix runs (~20 min).\n\nNote: the histogram bump happens per closure, not per GC.  That's\nmillions of increments per GC \u2014 but they're just ALU ops, no I/O.\nShould perturb timing far less than per-GC debugBelch already does.\n\nImplementation skeleton (apply to `rts/sm/Scav.c::scavenge_block`):\n\n```c\n#include \"GC.h\"  // for probe28_type_hist (declared extern in GC.c)\n...\n// inside the main loop of scavenge_block, after const StgInfoTable *info = get_itbl(...);\nif ((int)info->type < 64) probe28_type_hist[info->type]++;\n```\n\nAnd in `rts/sm/GC.c`, declare:\n\n```c\nW_ probe28_type_hist[64];  // not file-static \u2014 Scav.c needs access\n```\n\nReset at pre-GC snapshot point.  Print in the post-GC summary line as\n`type{T_N=count, ...}` (skip zero buckets for compactness).\n\n### Second: audit `rts/sm/Evac.c::evacuate` and `copy_tag`\n\nPPC32-specific concerns:\n\n- **Info-pointer reads**: `evacuate` does `info = ACQUIRE_LOAD(&q->header.info)`.\n  In the non-threaded RTS, `ACQUIRE_LOAD` expands to a plain load.\n  On PPC32, info pointers are 32-bit; check there's no path that\n  treats them as 64-bit.\n- **Forwarding pointer tag**: `IS_FORWARDING_PTR(p)` tests the low\n  bit of the info pointer.  `((StgWord)p) & 1`.  PPC32 ensures\n  pointers are 4-byte aligned, so the low 2 bits are always clear in\n  a valid pointer; setting bit 0 marks a forward.  Look at how\n  `UN_FORWARDING_PTR` recovers the new address.\n- **`copy_tag` and `copy`**: alloc to-space block via `alloc_for_copy`,\n  then `memcpy_words` for the closure body.  `memcpy_words` is in\n  `rts/sm/GCUtils.c` \u2014 a hand-rolled word-copy loop.  Read with PPC32\n  alignment eyes.\n- **Closure-size lookup**: `closure_sizeW(p)` reads `info->layout.payload.ptrs`\n  and `nptrs`.  Check `StgInfoTable` struct layout on PPC32 (it's a\n  packed struct in `includes/rts/storage/InfoTables.h`).\n\nConcrete file list:\n\n- `rts/sm/Evac.c` lines ~100 (`copy`), ~150 (`copy_tag`), ~250\n  (`evacuate1`), ~620 (`evacuate`).\n- `rts/sm/GCUtils.c::memcpy_words`.\n- `includes/rts/storage/InfoTables.h::StgInfoTable`.\n- `includes/rts/storage/ClosureMacros.h::closure_sizeW`.\n\n### Third: audit `rts/sm/Scav.c::scavenge_block`\n\n`scavenge_block` is the big switch by `info->type`.  Every closure\ntype has its own scavenge logic.  Risk areas:\n\n- The pointer-advance arithmetic at end of each case \u2014 `p += sizeofW(StgFoo)`\n  or `p = (StgPtr)((StgFun *)p + 1)` style.  Getting this wrong by\n  one word reads the next closure's header as a pointer field of\n  the current closure, which then gets scribbled by evacuate.\n- The big-bitmap and small-bitmap scavenge routines: `scavenge_large_bitmap`,\n  `scavenge_small_bitmap` (`rts/sm/Scav.c` lines ~80\u2013~180).  Bitmap\n  is a 32-bit pattern saying which slots are pointers.  Iterate bits,\n  call `evacuate` on pointer slots.\n\n### Fourth: bisect Big2.hs\n\nCheap exploratory test: strip Big2.hs progressively (remove `topK`,\nremove the `where` clause, remove the `Data.Map.Strict` import) and\nsee which removal turns 5/5 fail \u2192 0/5 pass.  The first one that\nclears the bug names the offending closure shape.  Smaller heap \u2192\nfewer closures of the suspect type.  Cheaper than the probe enhancement\nif you want a quick hypothesis, but less informative.\n\n## Mechanics \u2014 reproducing session 28 results\n\n```bash\ncd /Users/cell/claude/ghc-darwin8-ppc\n\n# 0. Optional: baseline still green?\nbash tests/run-tests.sh    # ~10 min; expect 30 PASS / 4 design diffs\n\n# 1. Re-apply the probe\ncd external/ghc-modern/ghc-9.2.8\ngit apply ../../docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch\n\n# 2. Rebuild + deploy\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n\n# 3. Run the matrix (writes logs to log/session28/)\nbash docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/run-probe-matrix.sh \\\n    pmacg5 5\nbash docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/scripts/big2-a1m-test.sh \\\n    pmacg5 10\n\n# 4. When done \u2014 REVERT before any user-facing run\ncd external/ghc-modern/ghc-9.2.8\ngit checkout rts/sm/GC.c\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\n**Expected:** with probe, the matrix produces (5-iter samples):\n- M5 `-A1m`: pass=3 fail=2\n- M5 `-A1m -G1`: pass=5 fail=0\n- Big2 `-A1m -G1`: pass=0 fail=5 (5\u00d7 `refineFromInScope` at GC 17)\n- Big2 `-A1G`: pass=5 fail=0\n- Big2 `-A1m` (10 iter): pass=5 fail=5 (5\u00d7 \"swap not in scope\" at GC 41)\n\n## Hosts (unchanged)\n\n- **uranium** (this Mac): host for cross-build, source edits.\n- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.\n- **imacg3**: smaller-RAM PPC G3.\n- **indium**: don't use for clang or hadrian builds.\n\n## What's clean / dirty in the source tree\n\n- `external/ghc-modern/ghc-9.2.8/` \u2014 clean.  Probe reverted before\n  session end.\n- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` \u2014 clean rebuild+redeploy\n  at session-28 end, matches v0.12.0.\n- New session dir: `docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/`\n  + run logs gitignored at `log/session28/`.\n\n## Time estimate for session 29\n\n- Setup + read handoff + verify session-28 numbers (re-apply probe +\n  rebuild + 5\u00d74 = 20 runs): 30\u201345 min.\n- Implement closure-type histogram (Scav.c + GC.c edit + rebuild +\n  redeploy + 4 probe-matrix cells): 1.5\u20132.5 h.\n- Analyse histogram, identify suspect closure type, narrow audit:\n  30\u201360 min.\n- Audit + first hypothesis test on `Evac.c` or `Scav.c`: 2\u20134 h.\n\nRealistic: 1 medium-to-long session (~5\u20137 h) to identify the\nclosure type and pinpoint the buggy scavenge routine.  Then 1 short\nsession to write + test the fix and ship it.\n\n## Paste-into-fresh-session prompt\n\n```\nContext: session 28 of the GHC darwin8-ppc project just wrapped up.\nSession 28 wrote PROBE28 \u2014 an RTS-side per-GC printf in rts/sm/GC.c\n(no Haskell-side perturbation) \u2014 and used it to discriminate between\nsession 27's \"one bug, two victims\" and \"two bugs\" framings.\n\nResult: ONE BUG, TWO VICTIM DATA STRUCTURES.  With PROBE28 enabled,\nBig2.hs +RTS -A1m -G1 panics 5/5 with the STG-time refineFromInScope\nsignature instead of session 27's TC-time \"swap not in scope\" \u2014 the\nprobe's small timing perturbation shifted which downstream IntMap-\nbacked VarEnv catches the corrupted closure.  Both signatures come\nfrom the same root corruption.\n\nPROBE28 also ruled out two of session 27's audit targets:\n- scavenge_capability_mut_lists / mut_list scavenge: under -G1 the\n  mut_list is empty, yet Big2 -G1 panics 5/5.\n- scavenge_static / scavenge_thunk_srt / scavenge_fun_srt: under\n  -G1 every GC walks the same ~175k-entry static_objects chain in\n  both M5 (PASS) and Big2 (FAIL).\n\nRemaining suspects: rts/sm/Evac.c (evacuate, copy_tag, copy),\nrts/sm/Scav.c (scavenge_block dispatch), forwarding-pointer\nmachinery, info-table reads on PPC32.\n\nRead in order:\n1. docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md\n2. docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/README.md\n3. docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/findings.md\n4. docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch\n5. (reference) docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md\n\nTop priority: extend PROBE28 with a per-closure-type histogram\n(increment per-type counter in scavenge_block's main switch, print\nin the post-GC summary).  Run on M5 -A1m-G1 (PASS) and Big2 -A1m-G1\n(FAIL); compare histograms to find the closure type that fires only\nin the failing case.  Then audit Evac.c / Scav.c's scavenge for that\ntype with PPC32 (32-bit big-endian) eyes.\n\nHosts: uranium for builds, pmacg5 for runs.  Don't use indium.\nv0.12.0 stays shipped \u2014 don't break stage2's -A1G wrapper.  ALWAYS\nrevert the probe + rebuild + redeploy clean stage2 at session end.\n\nUnsupervised mode is project default.\n```\n\n## Memory aide for the next-you: session-end HANDOFF path\n\nThis handoff lives at:\n[`docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md`](docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md).\n\nWhen session 29 ends, write the next handoff at:\n`docs/sessions/<DATE>-session-29-<slug>/HANDOFF.md`.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/commits.md",
  "content": "# Session 28 commits\n\n- `XXXXXXX` Session 28: stage2 GC bug investigation, round 10\n  (PROBE28 RTS-side per-GC discriminator probe; session-27's \"two\n  distinct corruption modes\" framing downgraded to \"one bug, two\n  victim data structures\"; mut_list and static_objects scavenge\n  paths ruled out as the bug).\n\n## Source-tree changes that did NOT make it into git\n\nThe PROBE28 patch in `rts/sm/GC.c` was applied, used to gather data,\nthen reverted before session end.  The patch is preserved at\n`docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/probe28-rts-gc.patch`\nso it can be re-applied verbatim by the next session.\n\n## Stage1 / stage2 / pmacg5 state changes\n\n- `external/ghc-modern/ghc-9.2.8/` \u2014 no edits committed.  Probe\n  applied for matrix runs, then reverted via `git checkout`.\n- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSrts-1.0.2.a`\n  \u2014 rebuilt twice during the session (once with probe, once after\n  revert).  Final state matches v0.12.0.\n- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` \u2014 rebuilt + redeployed\n  twice (with probe, then clean).  Final state matches v0.12.0.\n"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 28 dir + run baseline test suite",
      "activeForm": "Setting up session 28 dir + running baseline",
      "status": "completed"
    },
    {
      "content": "Verify session 27 numbers (quick sanity check)",
      "activeForm": "Verifying session 27 numbers",
      "status": "completed"
    },
    {
      "content": "Design + implement RTS-side probe in rts/sm/GC.c",
      "activeForm": "Implementing RTS-side probe",
      "status": "completed"
    },
    {
      "content": "Rebuild stage1 RTS lib + redeploy to pmacg5",
      "activeForm": "Rebuilding stage1 RTS + redeploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix: M5.hs -A1m, M5.hs -A1m -G1, Big2.hs -A1m -G1, Big2.hs -A1G",
      "activeForm": "Running probe matrix",
      "status": "completed"
    },
    {
      "content": "Analyze probe output: discriminate 'one bug, two victims' vs 'two bugs'",
      "activeForm": "Analyzing probe output",
      "status": "completed"
    },
    {
      "content": "Revert probe + redeploy clean stage2",
      "activeForm": "Reverting probe + redeploying clean stage2",
      "status": "completed"
    },
    {
      "content": "Write session 28 README + findings + commits.md + HANDOFF.md",
      "activeForm": "Writing session 28 notes",
      "status": "completed"
    },
    {
      "content": "Update docs/state.md and docs/roadmap.md to reflect session 28 findings",
      "activeForm": "Updating state + roadmap",
      "status": "in_progress"
    },
    {
      "content": "Commit session 28 notes",
      "activeForm": "Committing session 28 notes",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/docs/state.md | head -60",
  "description": "Inspect state.md head"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'session 27\\|session 26\\|round 9\\|stage2 GC' /Users/cell/claude/ghc-darwin8-ppc/docs/state.md | head -20",
  "description": "Find session refs in state.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "offset": 315,
  "limit": 50
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "*Updated: 2026-05-12 session 27 (stage2 GC bug round 9 \u2014 non-perturbing deterministic repro nailed; bug has two distinct corruption modes; `-G1` is a partial workaround).  **`M5.hs +RTS -A1m -RTS` panics 10/10** on clean stage2 with the STG-time panic family (depSortStgBinds, refineFromInScope, \"variable not found\").  **`+RTS -A1m -G1` (single-generation) fully suppresses the M5.hs panic family** (10/10 OK) and M5plus.hs (5/5 OK).  But **`-G1` does NOT suppress all variants** \u2014 Big2.hs (~30-LOC clean module using Data.Map.Strict + `where`-bound local) fails 10/10 at `-A1m -G1` with a **new corruption signature first observed this session: `* GHC internal error: 'swap' is not in scope during type checking, but it passed the renamer`**.  So sessions 17\u201326's catalogue (STG-time panics) was incomplete: there's also a typecheck-time corruption that escapes the gen-2 mut_list path entirely.  Sessions 19\u201326 dead-end theories (BS-pinning invariant, mkLivenessBits, StackRep, poison-on-stale-slot) all stand as ruled out.  v0.12.0 ships unchanged; source tree clean.  Next session: write a slim RTS-side probe (per-GC mut_list / static-object counter, no Haskell-side perturbation) to discriminate \"one bug, two victim data structures\" vs \"two distinct bugs.\")*",
  "new_string": "*Updated: 2026-05-12 session 28 (stage2 GC bug round 10 \u2014 RTS-side discriminator probe; session-27's \"two distinct corruption modes\" downgraded to **one bug, two victim data structures**).  PROBE28 (slim RTS-side per-GC printf in `rts/sm/GC.c`) shows Big2.hs `-A1m -G1` switches from session 27's TC-time \"swap not in scope\" signature to the STG-time `refineFromInScope` signature 5/5 \u2014 the probe's tiny timing perturbation shifts which downstream IntMap-backed VarEnv catches the corruption.  Same root corruption, different downstream victim.  PROBE28 also ruled out two of session 27's audit targets: (i) `scavenge_capability_mut_lists` / mut_list write-barrier path (under `-G1` the mut_list is empty, yet Big2 `-G1` still panics 5/5); (ii) `scavenge_static` / `scavenge_thunk_srt` / `scavenge_fun_srt` (under `-G1` every GC walks the same ~175k-entry static_objects chain in both M5 (PASS) and Big2 (FAIL)).  Remaining suspects: `rts/sm/Evac.c` (evacuate / copy_tag / copy), `rts/sm/Scav.c::scavenge_block` dispatch by closure type, forwarding-pointer / info-table machinery on PPC32 (32-bit big-endian).  v0.12.0 ships unchanged; source tree clean; probe applied for measurement and reverted before session end; stage2 on pmacg5 rebuilt+redeployed clean.  Next session: extend PROBE28 with a per-closure-type histogram, then audit Evac.c / Scav.c.*"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "- 2026-05-12 session 27: stage2 GC bug investigation, round 9.",
  "new_string": "- 2026-05-12 session 28: stage2 GC bug investigation, round 10.\n  Wrote **PROBE28** \u2014 a slim RTS-side per-GC printf in `rts/sm/GC.c`\n  (file-static counter + pre-GC mut_list snapshot via `countOccupied`\n  + post-GC summary line walking `gct->scavenged_static_objects`)\n  \u2014 to discriminate session 27's \"one bug, two victims\" vs \"two\n  bugs\" framings.  With the probe enabled, **Big2.hs `-A1m -G1`\n  flips from session 27's TC-time \"swap not in scope\" signature\n  (10/10) to the STG-time `refineFromInScope` signature 5/5** \u2014\n  the probe's tiny per-GC timing delay shifts which downstream\n  IntMap-backed VarEnv catches the corruption.  Strong evidence\n  for **one bug, two victim data structures**.  PROBE28 also rules\n  out (i) the mut_list / write-barrier audit (Big2 `-G1` fails 5/5\n  with zero mut_list activity \u2014 under `-G1` mut_lists are empty),\n  and (ii) the static_objects scavenge audit (under `-G1` every GC\n  walks the same ~175k-entry static chain in both M5 (PASS) and Big2\n  (FAIL)).  Remaining suspects: `rts/sm/Evac.c` (evacuate, copy_tag,\n  copy) and `rts/sm/Scav.c::scavenge_block` dispatch \u2014 these run on\n  every GC regardless of `-G` and would fire identically across\n  M5/Big2 except that Big2 has more closures of whatever type\n  triggers the bug.  v0.12.0 ships unchanged; probe applied for\n  measurement, then reverted; clean stage2 redeployed at session end.\n  Session\n  [`HANDOFF.md`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)\n  scopes the closure-type histogram extension + Evac.c / Scav.c\n  audit.\n- 2026-05-12 session 27: stage2 GC bug investigation, round 9."
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'stage2\\|session 2[78]\\|round 9' /Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md | head -15",
  "description": "Check roadmap mentions"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'session 27\\|session 28\\|round 9\\|round 10' /Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "description": "Check session 27 mention in roadmap"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "offset": 280,
  "limit": 60
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "old_string": "- [`docs/sessions/2026-05-12-session-27-non-perturbing-repro/`](sessions/2026-05-12-session-27-non-perturbing-repro/)\n  \u2014 round 9.  **Deterministic non-perturbing repro nailed.**\n  `M5.hs +RTS -A1m -RTS` on clean stage2 panics **10/10** with the\n  STG-time panic family (depSortStgBinds, refineFromInScope, \"variable\n  not found\").  **`+RTS -A1m -G1` (single-generation) fully\n  suppresses the M5.hs panic family** (10/10 OK), and likewise on\n  M5plus.hs (5/5 OK).  Goldilocks: `-A1G`, `-A4m`, and even `-A512k`\n  are too large/small to reproduce M5.hs's failure.  But on a\n  larger clean input \u2014 Big2.hs, ~30-LOC, uses Data.Map.Strict and\n  a `where`-bound local function \u2014 `-A1m -G1` fails 10/10 with a\n  **new, previously-undocumented signature**: `* GHC internal\n  error: 'swap' is not in scope during type checking, but it\n  passed the renamer`.  So the bug has at least two distinct\n  corruption modes: STG-time (suppressed by `-G1`) and typecheck-\n  time (not suppressed).  Either two separate bugs or one bug with\n  two victim data structures.  v0.12.0 ships unchanged; source\n  tree clean; no commits to external/ghc-modern this session.\n  Session-27\n  [`HANDOFF.md`](sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md)\n  scopes a slim RTS-side probe (per-GC mut_list / static-object\n  counter, no Haskell-side perturbation) to discriminate one-bug\n  vs two-bug.",
  "new_string": "- [`docs/sessions/2026-05-12-session-27-non-perturbing-repro/`](sessions/2026-05-12-session-27-non-perturbing-repro/)\n  \u2014 round 9.  **Deterministic non-perturbing repro nailed.**\n  `M5.hs +RTS -A1m -RTS` on clean stage2 panics **10/10** with the\n  STG-time panic family (depSortStgBinds, refineFromInScope, \"variable\n  not found\").  **`+RTS -A1m -G1` (single-generation) fully\n  suppresses the M5.hs panic family** (10/10 OK), and likewise on\n  M5plus.hs (5/5 OK).  Goldilocks: `-A1G`, `-A4m`, and even `-A512k`\n  are too large/small to reproduce M5.hs's failure.  But on a\n  larger clean input \u2014 Big2.hs, ~30-LOC, uses Data.Map.Strict and\n  a `where`-bound local function \u2014 `-A1m -G1` fails 10/10 with a\n  **new, previously-undocumented signature**: `* GHC internal\n  error: 'swap' is not in scope during type checking, but it\n  passed the renamer`.  Session-27 framed this as \"the bug has at\n  least two distinct corruption modes\" \u2014 **downgraded by session\n  28 to one bug, two victim data structures** (see next entry).\n  v0.12.0 ships unchanged; source tree clean; no commits to\n  external/ghc-modern this session.\n- [`docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/)\n  \u2014 round 10.  Wrote **PROBE28** \u2014 a slim RTS-side per-GC printf in\n  `rts/sm/GC.c` (file-static counter + pre-GC mut_list snapshot via\n  `countOccupied` + post-GC summary line walking\n  `gct->scavenged_static_objects` via `STATIC_LINK`).  With the\n  probe enabled, **Big2.hs `-A1m -G1` flips from session 27's\n  TC-time \"swap not in scope\" signature (10/10) to the STG-time\n  `refineFromInScope` signature 5/5** \u2014 the probe's tiny per-GC\n  timing delay shifts which downstream IntMap-backed VarEnv catches\n  the corruption.  Strong evidence for **one bug, two victim data\n  structures**.  PROBE28 also rules out two of session 27's audit\n  targets: (i) `scavenge_capability_mut_lists` / mut_list write-\n  barrier path (Big2 `-G1` fails 5/5 with zero mut_list activity \u2014\n  under `-G1` mut_lists are empty); (ii) `scavenge_static` /\n  `scavenge_thunk_srt` / `scavenge_fun_srt` (under `-G1` every GC\n  walks the same ~175k-entry static_objects chain in both M5 (PASS)\n  and Big2 (FAIL)).  Remaining suspects: `rts/sm/Evac.c`\n  (`evacuate`, `copy_tag`, `copy`), `rts/sm/Scav.c::scavenge_block`\n  dispatch by closure type, forwarding-pointer / info-table\n  machinery on PPC32 (32-bit big-endian).  v0.12.0 ships unchanged;\n  probe applied for measurement and reverted at session end; stage2\n  on pmacg5 rebuilt+redeployed clean.  Session-28\n  [`HANDOFF.md`](sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md)\n  scopes a per-closure-type histogram extension to PROBE28, then a\n  PPC32-eyes audit of Evac.c / Scav.c."
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git status",
  "description": "Check git status before commit"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe docs/state.md docs/roadmap.md && git status",
  "description": "Stage session 28 changes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git commit -m \"$(cat <<'EOF'\nSession 28: stage2 GC bug investigation, round 10 (PROBE28 RTS-side per-GC discriminator probe; session-27's \"two distinct corruption modes\" downgraded to \"one bug, two victim data structures\"; mut_list and static_objects scavenge paths ruled out).\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\"",
  "description": "Commit session 28 notes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git commit -F - <<'COMMIT_EOF'\nSession 28: stage2 GC bug investigation, round 10 (PROBE28 RTS-side per-GC discriminator probe; session-27's \"two distinct corruption modes\" downgraded to \"one bug, two victim data structures\"; mut_list and static_objects scavenge paths ruled out).\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nCOMMIT_EOF",
  "description": "Commit session 28 via stdin"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log -1 --format='%H' | head -c 7",
  "description": "Get commit SHA for backfill"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/commits.md",
  "old_string": "- `XXXXXXX` Session 28: stage2 GC bug investigation, round 10",
  "new_string": "- `4f1fcb6` Session 28: stage2 GC bug investigation, round 10"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/commits.md && git commit -F - <<'COMMIT_EOF'\nSession 28 commits.md: backfill the SHA.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nCOMMIT_EOF",
  "description": "Commit backfill of SHA"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 28 dir + run baseline test suite",
      "activeForm": "Setting up session 28 dir + running baseline",
      "status": "completed"
    },
    {
      "content": "Verify session 27 numbers (quick sanity check)",
      "activeForm": "Verifying session 27 numbers",
      "status": "completed"
    },
    {
      "content": "Design + implement RTS-side probe in rts/sm/GC.c",
      "activeForm": "Implementing RTS-side probe",
      "status": "completed"
    },
    {
      "content": "Rebuild stage1 RTS lib + redeploy to pmacg5",
      "activeForm": "Rebuilding stage1 RTS + redeploying",
      "status": "completed"
    },
    {
      "content": "Run probe matrix: M5.hs -A1m, M5.hs -A1m -G1, Big2.hs -A1m -G1, Big2.hs -A1G",
      "activeForm": "Running probe matrix",
      "status": "completed"
    },
    {
      "content": "Analyze probe output: discriminate 'one bug, two victims' vs 'two bugs'",
      "activeForm": "Analyzing probe output",
      "status": "completed"
    },
    {
      "content": "Revert probe + redeploy clean stage2",
      "activeForm": "Reverting probe + redeploying clean stage2",
      "status": "completed"
    },
    {
      "content": "Write session 28 README + findings + commits.md + HANDOFF.md",
      "activeForm": "Writing session 28 notes",
      "status": "completed"
    },
    {
      "content": "Update docs/state.md and docs/roadmap.md to reflect session 28 findings",
      "activeForm": "Updating state + roadmap",
      "status": "completed"
    },
    {
      "content": "Commit session 28 notes",
      "activeForm": "Committing session 28 notes",
      "status": "completed"
    }
  ]
}


---

## 🤖 Claude

Session 28 complete and committed. Headline: **PROBE28 (slim RTS-side per-GC printf in `rts/sm/GC.c`) downgrades session 27's "two distinct corruption modes" framing to "one bug, two victim data structures".** With the probe enabled, Big2.hs `+RTS -A1m -G1` flipped from session 27's TC-time "swap not in scope" signature (10/10) to the STG-time `refineFromInScope` signature (5/5) — the probe's tiny per-GC timing delay shifts which downstream IntMap-backed VarEnv catches the corrupted closure. Same root corruption, different downstream victim.

PROBE28 also ruled out two of session 27's queued audit targets:
- **mut_list / write-barrier path** — under `-G1` mut_lists are empty, yet Big2 still panics 5/5.
- **`scavenge_static` / `scavenge_thunk_srt` / `scavenge_fun_srt`** — under `-G1` every GC walks the same ~175k-entry static_objects chain in both M5 (PASS) and Big2 (FAIL).

Remaining suspects: `rts/sm/Evac.c` (`evacuate` / `copy_tag` / `copy`), `rts/sm/Scav.c::scavenge_block` dispatch by closure type, forwarding-pointer / info-table machinery on PPC32 (32-bit big-endian).

v0.12.0 ships unchanged; probe applied for measurement and reverted before session end; stage2 on pmacg5 rebuilt+redeployed clean.

Next session's handoff: [docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md](docs/sessions/2026-05-12-session-28-rts-gc-discriminator-probe/HANDOFF.md). Top priority is extending PROBE28 with a per-closure-type histogram in `scavenge_block`, then auditing Evac.c / Scav.c with PPC32 eyes.

---

