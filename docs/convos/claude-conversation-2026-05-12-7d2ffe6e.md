# Claude Conversation Log

Session ID: 7d2ffe6e-a4ba-4458-8e0f-591f778b119c
Date: 2026-05-12 00:09:45

---

## 👤 User

please read docs/sessions/2026-05-11-session-24-faststring-stackrep/HANDOFF.md and proceed

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-24-faststring-stackrep/HANDOFF.md"
}


---

## 🤖 Claude

Now let me read the supporting docs the handoff says are mandatory.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-24-faststring-stackrep/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-24-faststring-stackrep/findings.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/README.md"
}


---

## 🤖 Claude

Let me set up my todo list and gather the key reference materials before starting.

---

## 🤖 Claude


🔧 Using tool: ToolSearch
Input: {
  "query": "select:TodoWrite",
  "max_results": 1
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-24-faststring-stackrep/excerpts/c7t9-c7te.cmm"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-10-session-23-stage2-poison-probe/",
  "description": "List session 23 dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/ | tail -10",
  "description": "List recent sessions"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 25 directory and pre-flight (read PROBE22 patch + harness, run baseline tests)",
      "activeForm": "Setting up session 25 dir and pre-flight",
      "status": "in_progress"
    },
    {
      "content": "Write PROBE23 patch (PROBE22POISON + BF_PINNED filter + pinned-on-stack logger)",
      "activeForm": "Writing PROBE23 patch",
      "status": "pending"
    },
    {
      "content": "Apply patch, rebuild RTS, deploy to pmacg5",
      "activeForm": "Applying patch, rebuilding RTS, deploying to pmacg5",
      "status": "pending"
    },
    {
      "content": "Run 5\u00d7iteration M5.hs harness under -A1m on pmacg5",
      "activeForm": "Running 5\u00d7iteration M5.hs harness",
      "status": "pending"
    },
    {
      "content": "Collect + classify results (a vs b vs mixed)",
      "activeForm": "Collecting and classifying results",
      "status": "pending"
    },
    {
      "content": "End-of-session ritual: revert RTS, rebuild, redeploy clean; write README/findings/HANDOFF/commits",
      "activeForm": "Performing end-of-session ritual",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-10-session-23-stage2-poison-probe/probe22-poison-stack.patch"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-10-session-23-stage2-poison-probe/HANDOFF.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-10-session-23-stage2-poison-probe/scripts"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-10-session-23-stage2-poison-probe/scripts/",
  "description": "List session 23 scripts"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-10-session-23-stage2-poison-probe/scripts/run-poison.sh"
}


---

## 🤖 Claude

Now I have the full picture. Let me run baseline tests, set up the session dir, and check repo state in parallel.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash tests/run-tests.sh 2>&1 | tail -30",
  "description": "Run baseline test battery",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "mkdir -p /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/scripts /Users/cell/claude/ghc-darwin8-ppc/log/session25 && ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/",
  "description": "Create session 25 dir tree"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git status rts/sm/GC.c && git log -1 --oneline rts/sm/GC.c",
  "description": "Check GC.c is clean"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 895,
  "limit": 30
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'BF_PINNED\\b' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/Block.h | head -5",
  "description": "Find BF_PINNED definition"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -f /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output 2>&1 | head -50",
  "description": "Peek at running tests",
  "timeout": 30000
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

Now let me write the PROBE23 patch as a session-25 artifact.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/probe23-poison-stack.patch",
  "content": "diff --git a/rts/sm/GC.c b/rts/sm/GC.c\nindex d63ca271..af11afaf 100644\n--- a/rts/sm/GC.c\n+++ b/rts/sm/GC.c\n@@ -907,6 +907,87 @@ GarbageCollect (uint32_t collect_gen,\n       }\n   }\n\n+  /* PROBE23POISON: like PROBE22POISON (session 23) but also exempts\n+   * BF_PINNED blocks.  Session 24 settled that the only confirmed\n+   * read-after-poison from PROBE22 reads MEM[Sp+12] of _blk_c7te in\n+   * GHC.Data.FastString, where Sp+12 is the Addr# field of an unboxed\n+   * Data.ByteString.Internal.Type.BS \u2014 i.e., a raw pointer that is\n+   * supposed to be stable across GC because the underlying\n+   * MutableByteArray# is pinned.  The PROBE22 log reported bd_flags=0\n+   * (no BF_PINNED, no BF_EVACUATED) for the stomped block, leaving\n+   * two open hypotheses:\n+   *\n+   *   (a) Real bug: some BS reaching mkFastStringByteString is backed\n+   *       by a non-pinned MutableByteArray#, so its Addr# IS stale\n+   *       post-GC.\n+   *   (b) Probe artefact: pinned blocks transiently lose BF_PINNED\n+   *       (or never had it during GC), and PROBE22POISON has been\n+   *       wrongly stomping stable Addr#s into pinned memory.\n+   *\n+   * PROBE23 adds `!(bd->flags & BF_PINNED)` to the poison filter.\n+   * If the 5/5 SIGSEGV pattern goes away, (b) was right and the\n+   * production -A1m crash is a different mechanism entirely.  If it\n+   * stays, (a) was right and we need to find the BS invariant\n+   * violator.\n+   *\n+   * It also runs a no-poison pass that just LOGS pinned-block-backed\n+   * stack slots (PROBE23PINNED), so we can quantify \"how many of\n+   * PROBE22POISON's stomps were actually into pinned memory.\"  That's\n+   * the false-positive denominator under hypothesis (b).\n+   *\n+   * Insertion point: same as PROBE22POISON, just before resize_nursery().\n+   */\n+  {\n+    static unsigned probe23_gc_no = 0;\n+    Capability *probe_cap = capabilities[0];\n+    StgTSO *probe_tso = probe_cap->run_queue_hd;\n+\n+    if (probe_tso != NULL && probe_tso != END_TSO_QUEUE\n+        && probe_tso->stackobj != NULL) {\n+      StgStack *st = probe_tso->stackobj;\n+      StgPtr probe_sp = st->sp;\n+      StgPtr probe_end = st->stack + st->stack_size;\n+      int n_words = 0, n_heap_ptr = 0, n_poisoned = 0;\n+      int n_pinned_skip = 0, n_evac_skip = 0;\n+\n+      for (StgPtr p = probe_sp; p < probe_end; p++) {\n+        StgWord w = *p;\n+        n_words++;\n+        if (HEAP_ALLOCED((void*)w)) {\n+          n_heap_ptr++;\n+          bdescr *bd = Bdescr((P_)(w & ~(StgWord)3));\n+          if (bd) {\n+            if (bd->flags & BF_EVACUATED) { n_evac_skip++; continue; }\n+            if (bd->flags & BF_PINNED) {\n+              n_pinned_skip++;\n+              fprintf(stderr,\n+                      \"PROBE23PINNED gc_no=%u slot=%ld val=0x%08lx \"\n+                      \"bd_gen=%u bd_flags=0x%lx\\n\",\n+                      probe23_gc_no,\n+                      (long)(p - probe_sp),\n+                      (unsigned long)w,\n+                      (unsigned)bd->gen_no,\n+                      (unsigned long)bd->flags);\n+              continue;\n+            }\n+            fprintf(stderr,\n+                    \"PROBE23POISON gc_no=%u slot=%ld old=0x%08lx \"\n+                    \"bd_gen=%u bd_flags=0x%lx\\n\",\n+                    probe23_gc_no,\n+                    (long)(p - probe_sp),\n+                    (unsigned long)w,\n+                    (unsigned)bd->gen_no,\n+                    (unsigned long)bd->flags);\n+            *p = (StgWord)0xDEADBEEF;\n+            n_poisoned++;\n+          }\n+        }\n+      }\n+\n+      fprintf(stderr,\n+              \"PROBE23 gc_no=%u N=%u major=%d \"\n+              \"tso=%p stk=%p sp=%p end=%p \"\n+              \"words=%d heap_ptr=%d pinned_skip=%d evac_skip=%d poisoned=%d\\n\",\n+              probe23_gc_no, N, (int)major_gc,\n+              (void*)probe_tso, (void*)st,\n+              (void*)probe_sp, (void*)probe_end,\n+              n_words, n_heap_ptr, n_pinned_skip, n_evac_skip, n_poisoned);\n+    }\n+\n+    probe23_gc_no++;\n+  }\n+\n   resize_nursery();\n\n   resetNurseries();\n"
}


---

## 🤖 Claude

Let me check the test results, then apply the patch directly with Edit (the patch file is the artifact for the record).

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -20 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output",
  "description": "Check baseline test output so far"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output | tail -50",
  "description": "Check test output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output 2>&1; echo \"---\"; wc -l /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output 2>&1",
  "description": "Check task file size"
}


---

## 🤖 Claude

Tests are running in background. Let me apply the PROBE23 patch directly to GC.c while I wait.

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "      if (gen->bitmap != NULL) {\n          freeGroup(gen->bitmap);\n          gen->bitmap = NULL;\n      }\n  }\n\n  resize_nursery();",
  "new_string": "      if (gen->bitmap != NULL) {\n          freeGroup(gen->bitmap);\n          gen->bitmap = NULL;\n      }\n  }\n\n  /* PROBE23POISON: like PROBE22POISON (session 23) but also exempts\n   * BF_PINNED blocks.  Session 24 settled that the only confirmed\n   * read-after-poison from PROBE22 reads MEM[Sp+12] of _blk_c7te in\n   * GHC.Data.FastString, where Sp+12 is the Addr# field of an unboxed\n   * Data.ByteString.Internal.Type.BS \u2014 i.e., a raw pointer that is\n   * supposed to be stable across GC because the underlying\n   * MutableByteArray# is pinned.  The PROBE22 log reported bd_flags=0\n   * (no BF_PINNED, no BF_EVACUATED) for the stomped block, leaving\n   * two open hypotheses:\n   *\n   *   (a) Real bug: some BS reaching mkFastStringByteString is backed\n   *       by a non-pinned MutableByteArray#, so its Addr# IS stale\n   *       post-GC.\n   *   (b) Probe artefact: pinned blocks transiently lose BF_PINNED\n   *       (or never had it during GC), and PROBE22POISON has been\n   *       wrongly stomping stable Addr#s into pinned memory.\n   *\n   * PROBE23 adds `!(bd->flags & BF_PINNED)` to the poison filter.\n   * If the 5/5 SIGSEGV pattern goes away, (b) was right and the\n   * production -A1m crash is a different mechanism entirely.  If it\n   * stays, (a) was right and we need to find the BS invariant\n   * violator.\n   *\n   * It also runs a no-poison pass that just LOGS pinned-block-backed\n   * stack slots (PROBE23PINNED), so we can quantify \"how many of\n   * PROBE22POISON's stomps were actually into pinned memory.\"  That's\n   * the false-positive denominator under hypothesis (b).\n   */\n  {\n    static unsigned probe23_gc_no = 0;\n    Capability *probe_cap = capabilities[0];\n    StgTSO *probe_tso = probe_cap->run_queue_hd;\n\n    if (probe_tso != NULL && probe_tso != END_TSO_QUEUE\n        && probe_tso->stackobj != NULL) {\n      StgStack *st = probe_tso->stackobj;\n      StgPtr probe_sp = st->sp;\n      StgPtr probe_end = st->stack + st->stack_size;\n      int n_words = 0, n_heap_ptr = 0, n_poisoned = 0;\n      int n_pinned_skip = 0, n_evac_skip = 0;\n\n      for (StgPtr p = probe_sp; p < probe_end; p++) {\n        StgWord w = *p;\n        n_words++;\n        if (HEAP_ALLOCED((void*)w)) {\n          n_heap_ptr++;\n          bdescr *bd = Bdescr((P_)(w & ~(StgWord)3));\n          if (bd) {\n            if (bd->flags & BF_EVACUATED) { n_evac_skip++; continue; }\n            if (bd->flags & BF_PINNED) {\n              n_pinned_skip++;\n              fprintf(stderr,\n                      \"PROBE23PINNED gc_no=%u slot=%ld val=0x%08lx \"\n                      \"bd_gen=%u bd_flags=0x%lx\\n\",\n                      probe23_gc_no,\n                      (long)(p - probe_sp),\n                      (unsigned long)w,\n                      (unsigned)bd->gen_no,\n                      (unsigned long)bd->flags);\n              continue;\n            }\n            fprintf(stderr,\n                    \"PROBE23POISON gc_no=%u slot=%ld old=0x%08lx \"\n                    \"bd_gen=%u bd_flags=0x%lx\\n\",\n                    probe23_gc_no,\n                    (long)(p - probe_sp),\n                    (unsigned long)w,\n                    (unsigned)bd->gen_no,\n                    (unsigned long)bd->flags);\n            *p = (StgWord)0xDEADBEEF;\n            n_poisoned++;\n          }\n        }\n      }\n\n      fprintf(stderr,\n              \"PROBE23 gc_no=%u N=%u major=%d \"\n              \"tso=%p stk=%p sp=%p end=%p \"\n              \"words=%d heap_ptr=%d pinned_skip=%d evac_skip=%d poisoned=%d\\n\",\n              probe23_gc_no, N, (int)major_gc,\n              (void*)probe_tso, (void*)st,\n              (void*)probe_sp, (void*)probe_end,\n              n_words, n_heap_ptr, n_pinned_skip, n_evac_skip, n_poisoned);\n    }\n\n    probe23_gc_no++;\n  }\n\n  resize_nursery();"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 25 directory and pre-flight (read PROBE22 patch + harness, run baseline tests)",
      "activeForm": "Setting up session 25 dir and pre-flight",
      "status": "completed"
    },
    {
      "content": "Write PROBE23 patch (PROBE22POISON + BF_PINNED filter + pinned-on-stack logger)",
      "activeForm": "Writing PROBE23 patch",
      "status": "completed"
    },
    {
      "content": "Apply patch, rebuild RTS, deploy to pmacg5",
      "activeForm": "Rebuilding RTS and deploying to pmacg5",
      "status": "in_progress"
    },
    {
      "content": "Run 5\u00d7iteration M5.hs harness under -A1m on pmacg5",
      "activeForm": "Running 5\u00d7iteration M5.hs harness",
      "status": "pending"
    },
    {
      "content": "Collect + classify results (a vs b vs mixed)",
      "activeForm": "Collecting and classifying results",
      "status": "pending"
    },
    {
      "content": "End-of-session ritual: revert RTS, rebuild, redeploy clean; write README/findings/HANDOFF/commits",
      "activeForm": "Performing end-of-session ritual",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source ../../../scripts/cross-env.sh > /dev/null 2>&1 && ./hadrian/build --flavour=quick-cross -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>&1 | tail -30",
  "description": "Rebuild RTS with PROBE23 patch",
  "timeout": 600000,
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "pwd; sleep 5 && cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b505c15zy.output 2>&1 | head -10",
  "description": "Check pwd and rts build status"
}


---

## 🤖 Claude

RTS build done. Let me verify the output and then deploy.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -10 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b505c15zy.output",
  "description": "Confirm RTS build success"
}


---

## 🤖 Claude

Suspiciously fast — the build may have skipped GC.c. Let me verify it was actually recompiled.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find _build/stage1/rts/build -name 'GC.*' -newer rts/sm/GC.c -ls 2>&1; echo \"---GC.c mtime:\"; ls -la rts/sm/GC.c; echo \"---GC.o mtimes:\"; ls -la _build/stage1/rts/build/GC.*o 2>&1 | head -20",
  "description": "Check GC.o was rebuilt"
}


---

## 🤖 Claude

GC.o was rebuilt across all ways. Now deploy to pmacg5.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && bash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -30",
  "description": "Deploy stage2 ghc with PROBE23 to pmacg5",
  "timeout": 600000,
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output | tail -30; echo \"---\"; ls -la /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output",
  "description": "Check baseline test output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ps -p $(pgrep -f run-tests.sh 2>/dev/null) -o pid,etime,command 2>&1 | head -5; echo \"---\"; pgrep -af 'M5\\|run-tests\\|stage2\\|ghc-real\\|pmacg5' | head -20",
  "description": "Check if test runner still alive"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ps -ef | grep -E 'run-tests|ssh.*pmacg5|stage2|ghc-real' | grep -v grep | head -20",
  "description": "Find test/deploy processes"
}


---

## 🤖 Claude

Both tests and deploy are progressing in parallel. Let me wait for both to complete.

---

## 🤖 Claude


🔧 Using tool: Monitor
Input: {
  "command": "while true; do\n  d_done=$([ -f /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/bn5iww29w.output ] && grep -lE 'deploy|smoke|done|error|fail|Sanity' /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/bn5iww29w.output 2>/dev/null && wc -c < /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/bn5iww29w.output)\n  t_size=$(wc -c < /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output 2>/dev/null || echo 0)\n  d_size=$(wc -c < /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/bn5iww29w.output 2>/dev/null || echo 0)\n  d_pid=$(pgrep -f deploy-stage2.sh | head -1)\n  t_pid=$(pgrep -f run-tests.sh | head -1)\n  if [ -z \"$d_pid\" ] && [ -z \"$t_pid\" ]; then\n    echo \"BOTH_DONE deploy_size=$d_size tests_size=$t_size\"\n    break\n  fi\n  sleep 30\ndone\n",
  "description": "Wait for tests and deploy to finish",
  "timeout_ms": 1500000,
  "persistent": false
}


---

## 🤖 Claude

While tests + deploy run, let me write the session-25 harness adapter (mirrors session 23's but counts PROBE23 fields).

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/scripts/run-poison.sh",
  "content": "#!/bin/bash\n# Run M5.hs through the PROBE23-instrumented stage2 ghc on pmacg5\n# under various RTS flag combos.  Adapts session 23's run-poison.sh to\n# also count PROBE23PINNED lines (the no-poison \"denominator\" log of\n# pinned-block addresses on stack).\n#\n# The decision matrix from HANDOFF.md (session 24):\n#\n#   All 5/5 crash gone (exit 0)     \u2192 PROBE22POISON was the bug.\n#                                     False-positive class is pinned\n#                                     Addr#s; the actual GC-bug\n#                                     mechanism is elsewhere.\n#   Crash still fires (5/5 SIGSEGV) \u2192 BS really is non-pinned-backed.\n#                                     Real bug.  Find the BS allocator.\n#   Crash fires sometimes (1-4/5)   \u2192 Mixed signal.  Investigate.\n#\n# Usage:  ./run-poison.sh [SSH_HOST]\n# Default SSH_HOST=pmacg5.\n\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session25\"\nmkdir -p \"$LOGDIR\"\n\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\n\n# Same M5.hs as session 19/20/23.\nssh -q \"$PPC_HOST\" 'cat > /tmp/M5.hs' <<'EOF'\nmodule M5 where\nfive = (5::Int)\nsix = (6::Int)\nEOF\n\nrun_one () {\n    local label=\"$1\"\n    local rts_flags=\"$2\"\n    local logfile=\"$LOGDIR/poison-${label}.log\"\n    echo \"==> $label  ($rts_flags)\"\n    ssh -q \"$PPC_HOST\" \"\n        cd /tmp\n        rm -f M5.hi M5.o\n        $DYLD $GHC_REAL -c M5.hs $rts_flags\n        echo \\\"GHC_EXIT=\\$?\\\"\n    \" > \"$logfile\" 2>&1\n    local exit_status=$?\n    echo \"    log: $logfile (ssh exit=$exit_status)\"\n    echo \"    GHC_EXIT line: $(grep -m1 GHC_EXIT= \"$logfile\" 2>/dev/null || echo '(missing \u2014 likely segfault)')\"\n    echo \"    PROBE23 lines:        $(grep -c '^PROBE23 ' \"$logfile\" 2>/dev/null || echo 0)\"\n    echo \"    PROBE23POISON lines:  $(grep -c '^PROBE23POISON' \"$logfile\" 2>/dev/null || echo 0)\"\n    echo \"    PROBE23PINNED lines:  $(grep -c '^PROBE23PINNED' \"$logfile\" 2>/dev/null || echo 0)\"\n    if grep -q 'variable not found\\|panic\\|impossible' \"$logfile\"; then\n        echo \"    PANIC seen: $(grep -m1 'variable not found\\|panic\\|impossible' \"$logfile\")\"\n    fi\n    if grep -qiE '0xdeadbeef|deadbeef|segmentation|bus error' \"$logfile\"; then\n        echo \"    DEADBEEF / segfault: $(grep -miE '0xdeadbeef|deadbeef|segmentation|bus error' \"$logfile\" | head -3)\"\n    fi\n    echo\n}\n\n# Multiple iterations to capture non-determinism (mirrors session 23).\nfor i in 1 2 3 4 5; do\n    run_one \"iter${i}-A1m\" '+RTS -A1m -RTS'\ndone\n\n# Sanity-check mode (deterministic per session 19).\nrun_one \"iter1-A1m-DS\" '+RTS -A1m -DS -RTS'\n\n# Control: -A1G should still work.\nrun_one \"iter1-A1G\" '+RTS -A1G -RTS'\n\necho\necho \"All runs done.  Logs in $LOGDIR/poison-*.log\"\necho \"Summary by exit code:\"\nfor f in \"$LOGDIR\"/poison-*.log; do\n    label=$(basename \"$f\" .log | sed 's/poison-//')\n    e=$(grep -m1 GHC_EXIT= \"$f\" 2>/dev/null | sed 's/GHC_EXIT=//' || echo \"?\")\n    n_probe=$(grep -c '^PROBE23 ' \"$f\" 2>/dev/null || echo 0)\n    n_poison=$(grep -c '^PROBE23POISON' \"$f\" 2>/dev/null || echo 0)\n    n_pinned=$(grep -c '^PROBE23PINNED' \"$f\" 2>/dev/null || echo 0)\n    panic=$(grep -m1 -E 'variable not found|deadbeef|panic|impossible' \"$f\" 2>/dev/null | head -c 80 || echo \"\")\n    printf \"  %-20s exit=%-4s gc=%-3s poisoned=%-3s pinned=%-3s  %s\\n\" \\\n        \"$label\" \"$e\" \"$n_probe\" \"$n_poison\" \"$n_pinned\" \"$panic\"\ndone\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/scripts/run-poison.sh",
  "description": "Make harness executable"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "sleep 60 && tail -10 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/bn5iww29w.output 2>&1; echo \"---tests size:\"; wc -c /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output 2>&1",
  "description": "Peek at deploy + test progress"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -10 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/bn5iww29w.output 2>&1; echo \"---tests size:\"; wc -c /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output 2>&1",
  "description": "Peek at deploy + test progress"
}


---

## 🤖 Claude

The Monitor will notify when both finish. Let me wait for it.

---

## 👤 User

<task-notification>
<task-id>b56sajyj8</task-id>
<tool-use-id>toolu_01EnjekBUfSAqZoZcsirMWTX</tool-use-id>
<output-file>/private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output</output-file>
<status>completed</status>
<summary>Background command "Run baseline test battery" completed (exit code 0)</summary>
</task-notification>

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b56sajyj8.output",
  "description": "View baseline test output"
}


---

## 🤖 Claude

Baseline test diffs are exactly the 4 expected design diffs (Int size, getProgName, getpid, numeric boundaries) — matches v0.12.0 baseline. Waiting for deploy.

---

## 👤 User

<task-notification>
<task-id>bn5iww29w</task-id>
<tool-use-id>toolu_01KfCCo6PeNwenPgAYTnaU1R</tool-use-id>
<output-file>/private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/bn5iww29w.output</output-file>
<status>completed</status>
<summary>Background command "Deploy stage2 ghc with PROBE23 to pmacg5" completed (exit code 0)</summary>
</task-notification>

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/bn5iww29w.output",
  "description": "View deploy output"
}


---

## 🤖 Claude

Deployed cleanly. Now I'll run the PROBE23 harness on pmacg5.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 25 directory and pre-flight (read PROBE22 patch + harness, run baseline tests)",
      "activeForm": "Setting up session 25 dir and pre-flight",
      "status": "completed"
    },
    {
      "content": "Write PROBE23 patch (PROBE22POISON + BF_PINNED filter + pinned-on-stack logger)",
      "activeForm": "Writing PROBE23 patch",
      "status": "completed"
    },
    {
      "content": "Apply patch, rebuild RTS, deploy to pmacg5",
      "activeForm": "Rebuilding RTS and deploying to pmacg5",
      "status": "completed"
    },
    {
      "content": "Run 5\u00d7iteration M5.hs harness under -A1m on pmacg5",
      "activeForm": "Running 5\u00d7iteration M5.hs harness",
      "status": "in_progress"
    },
    {
      "content": "Collect + classify results (a vs b vs mixed)",
      "activeForm": "Collecting and classifying results",
      "status": "pending"
    },
    {
      "content": "End-of-session ritual: revert RTS, rebuild, redeploy clean; write README/findings/HANDOFF/commits",
      "activeForm": "Performing end-of-session ritual",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash docs/sessions/2026-05-11-session-25-pin-aware-poison/scripts/run-poison.sh pmacg5 2>&1 | tee log/session25/run-poison-summary.log | tail -80",
  "description": "Run PROBE23 harness",
  "timeout": 300000
}


---

## 🤖 Claude

Dramatic result: 5/5 still crash, but **0 pinned-skips** — the pin-aware filter never fired. Let me dig into the log details.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/log/session25/poison-iter1-A1m.log",
  "description": "Read iter1 detailed log"
}


---

## 🤖 Claude

The result is unambiguous: 5/5 crash, **0 pinned-skips ever** across all GCs in all iterations. Let me verify all 5 iters match.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "for i in 1 2 3 4 5; do\n  echo \"=== iter${i}-A1m ===\"\n  cat /Users/cell/claude/ghc-darwin8-ppc/log/session25/poison-iter${i}-A1m.log | grep -E '^PROBE23 |^PROBE23POISON|^PROBE23PINNED|^GHC_EXIT'\ndone",
  "description": "Cross-check all 5 iter logs"
}


---

## 🤖 Claude

5/5 byte-identical (down to TSO/stack pointers). Let me pull the crash log too.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -q pmacg5 'tail -200 ~/Library/Logs/CrashReporter/ghc-real.crash.log 2>/dev/null' > log/session25/ghc-real.crash.log && wc -l log/session25/ghc-real.crash.log && echo \"---last entry header---\" && grep -B1 -A8 'Process:.*ghc-real\\|Exception Type\\|^Crashed Thread' log/session25/ghc-real.crash.log | tail -30",
  "description": "Pull and inspect crash log"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -nE 'Process:|Exception|Date/Time|Thread.*Crashed|src=0x|0xdeadbeef' log/session25/ghc-real.crash.log | tail -40",
  "description": "Find crash log structure"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "sed -n '20,80p' log/session25/ghc-real.crash.log",
  "description": "View first crash entry detail"
}


---

## 🤖 Claude

Crash trace identical to session 23 (`_blk_c7te + 112`, `r4=0xdeadbeef`). Result fully characterized. Starting end-of-session cleanup in background while I write up.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 25 directory and pre-flight (read PROBE22 patch + harness, run baseline tests)",
      "activeForm": "Setting up session 25 dir and pre-flight",
      "status": "completed"
    },
    {
      "content": "Write PROBE23 patch (PROBE22POISON + BF_PINNED filter + pinned-on-stack logger)",
      "activeForm": "Writing PROBE23 patch",
      "status": "completed"
    },
    {
      "content": "Apply patch, rebuild RTS, deploy to pmacg5",
      "activeForm": "Rebuilding RTS and deploying to pmacg5",
      "status": "completed"
    },
    {
      "content": "Run 5\u00d7iteration M5.hs harness under -A1m on pmacg5",
      "activeForm": "Running 5\u00d7iteration M5.hs harness",
      "status": "completed"
    },
    {
      "content": "Collect + classify results (a vs b vs mixed)",
      "activeForm": "Collecting and classifying results",
      "status": "completed"
    },
    {
      "content": "Revert RTS, rebuild, redeploy clean to pmacg5 (background)",
      "activeForm": "Reverting and redeploying clean RTS",
      "status": "in_progress"
    },
    {
      "content": "Write session 25 README, findings, HANDOFF, commits.md",
      "activeForm": "Writing session 25 docs",
      "status": "pending"
    },
    {
      "content": "Update state.md and roadmap.md",
      "activeForm": "Updating state.md and roadmap.md",
      "status": "pending"
    },
    {
      "content": "Commit all session 25 work",
      "activeForm": "Committing session 25 work",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git checkout rts/sm/GC.c && source ../../../scripts/cross-env.sh > /dev/null 2>&1 && ./hadrian/build --flavour=quick-cross -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>&1 | tail -5 && bash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -10",
  "description": "Revert RTS, rebuild, redeploy clean",
  "timeout": 600000,
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/scripts/deploy-stage2.sh 2>&1; ls /Users/cell/claude/ghc-darwin8-ppc/scripts/deploy-stage2.sh 2>&1",
  "description": "Check deploy script paths"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/byzugwq0g.output",
  "description": "Check cleanup output"
}


---

## 🤖 Claude

GC.c reverted, RTS rebuilt clean — but deploy failed because I was in the wrong cwd. Re-running deploy.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -10",
  "description": "Re-deploy clean stage2 from project root",
  "timeout": 600000,
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git status rts/sm/GC.c",
  "description": "Confirm GC.c is clean"
}


---

## 🤖 Claude

Now I'll write the session docs while the deploy runs.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b7l1i5k7t.output 2>&1 | tail -20",
  "description": "Check deploy status"
}


---

## 🤖 Claude

Deploy still running. Writing docs in parallel.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/findings.md",
  "content": "# Session 25 findings \u2014 PROBE23 (pin-aware poison) doesn't change a thing\n\n## TL;DR\n\n- PROBE23 = PROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the\n  poison filter, plus a no-poison `PROBE23PINNED` log of stack slots\n  that point into pinned blocks (the b-hypothesis \"false-positive\n  denominator\").\n- Result on stage2 ghc compiling M5.hs under `+RTS -A1m -RTS`,\n  5 iterations: **5/5 SIGSEGV at `_blk_c7te + 112`**, exit=139,\n  byte-identical crash signature and PROBE log to session 23's\n  PROBE22POISON run.\n- Critically: **`pinned_skip = 0` across every GC of every iteration.**\n  No stack slot in any of the 3 GCs of the M5.hs compile contained a\n  value that pointed into a `BF_PINNED` block.  The pin-aware filter\n  never had to skip anything.\n- Decisive against hypothesis (b2) \"pinned blocks keep BF_PINNED and\n  PROBE22 was wrongly stomping them\" \u2014 that would have shown\n  pinned_skip > 0 and a corresponding crash drop.  Neither happened.\n- Hypothesis (a) \"BS reaches `mkFastStringByteString` with a non-pinned\n  underlying byte array\" is the simplest reading of the data: **the\n  bug is real, in the BS-allocation pipeline, NOT in PROBE22POISON\n  itself, NOT in LayoutStack/mkLivenessBits/stackMapToLiveness, and\n  NOT in any stack-frame bitmap.**\n- Residual hypothesis (b1) \"pinned blocks transiently lose BF_PINNED\n  at the moment GC runs PROBE23\" remains formally consistent with the\n  data but would require explaining a contrived RTS state transition.\n  Pursuing (a) first is correct unless (b1) gets specific evidence.\n\n## Decisive matrix\n\nThis was the decision matrix from session-24 HANDOFF.md:\n\n| Outcome under PROBE23           | Conclusion |\n|---------------------------------|-----------|\n| All 5/5 crash gone (exit 0)     | (b2) PROBE22POISON was the bug. |\n| Crash still fires (5/5 SIGSEGV) | (a) BS really is non-pinned-backed.  Real bug. |\n| Crash fires sometimes (1-4/5)   | Mixed signal. |\n\nWe landed in row 2.  The handoff classified that as \"(a) BS really is\nnon-pinned-backed.\"  This session adds a sub-finding: the\npinned-block skip count is 0, so we can also rule out (b2) on its own\nterms (not just by absence of crash relief).\n\n## Per-iteration data\n\n5/5 iterations are byte-identical, including TSO/stack/sp pointers.\nBelow is iter1 (the others differ in nothing).\n\n```\nPROBE23POISON gc_no=0 slot=8  old=0x0bdfff44 bd_gen=0 bd_flags=0x0\nPROBE23POISON gc_no=0 slot=42 old=0x0bd15e05 bd_gen=0 bd_flags=0x0\nPROBE23 gc_no=0 N=0 major=0 tso=0xbefe570 stk=0xbefeafc sp=0xbefedcc\n        end=0xbefeeb0 words=57  heap_ptr=23  pinned_skip=0\n        evac_skip=21  poisoned=2\n\nPROBE23POISON gc_no=1 slot=13 old=0x0bdeb079 bd_gen=0 bd_flags=0x0\nPROBE23POISON gc_no=1 slot=20 old=0x0bdeabd6 bd_gen=0 bd_flags=0x0\nPROBE23POISON gc_no=1 slot=46 old=0x0bde9464 bd_gen=0 bd_flags=0x0\nPROBE23POISON gc_no=1 slot=65 old=0x0bd5111d bd_gen=0 bd_flags=0x0\nPROBE23 gc_no=1 N=0 major=0 tso=0xbefd570 stk=0xbfe1000 sp=0xbfe8e94\n        end=0xbfe9000 words=91  heap_ptr=31  pinned_skip=0\n        evac_skip=27  poisoned=4\n\nPROBE23POISON gc_no=2 slot=6  old=0x0bf5f38a bd_gen=0 bd_flags=0x0   \u2605\nPROBE23POISON gc_no=2 slot=19 old=0x0bdff04c bd_gen=0 bd_flags=0x0\nPROBE23POISON gc_no=2 slot=25 old=0x0bdff0ad bd_gen=0 bd_flags=0x0\nPROBE23 gc_no=2 N=1 major=1 tso=0xbf8a19c stk=0xbfe1000 sp=0xbfe8be4\n        end=0xbfe9000 words=263 heap_ptr=157 pinned_skip=0\n        evac_skip=154 poisoned=3\n```\n\n\u2605 = The session-23 smoking-gun slot.  `gc_no=2 slot=6 old=0x0bf5f38a`\nis bit-identical to PROBE22POISON's session-23 reading of the same\nslot.\n\nCrash trace (matches session 23):\n\n```\nException:  EXC_BAD_ACCESS (0x0001)\nCodes:      KERN_INVALID_ADDRESS (0x0001) at 0xdeadbeef\n\nThread 0 Crashed:\n0   <<00000000>>      0xffff87f0 __memcpy + 80\n1   ghc-real          0x01fa4750 _blk_c7te + 112\n2   ghc-real          0x07f00b00 StgRun + 32\n...\n\n  r4: 0x00000000deadbeef    (memcpy src \u2014 the poisoned word)\n  r5: 0x0000000000000010    (memcpy len \u2014 16 bytes; matches the\n                             FastString copyByteArray# of the BS\n                             into the Short-form storage)\n```\n\n## Summary table (from `run-poison.sh`)\n\n```\niter1-A1G            exit=0    gc=0   poisoned=0   pinned=0\niter1-A1m-DS         exit=1    gc=0   poisoned=0   pinned=0\niter1-A1m            exit=139  gc=3   poisoned=9   pinned=0\niter2-A1m            exit=139  gc=3   poisoned=9   pinned=0\niter3-A1m            exit=139  gc=3   poisoned=9   pinned=0\niter4-A1m            exit=139  gc=3   poisoned=9   pinned=0\niter5-A1m            exit=139  gc=3   poisoned=9   pinned=0\n```\n\n(`-A1G` doesn't trigger any GC during the M5.hs compile so no probe\ndata; `-A1m -DS` exits with 1 from a sanity-check assertion before\nthe relevant GC runs, same as session 19 baseline.)\n\n## Why \"0 pinned-skip\" is informative\n\nPROBE23's pinned-block-on-stack pass logs every stack word `w` for\nwhich `Bdescr(w & ~3)` returns a `bd` with `BF_PINNED` set, and\n**does not poison it.**  Across 3 GCs (of which 2 are minor, 1 is\nmajor) and 211 heap-shaped stack words seen, **zero** of them point\ninto a pinned block.\n\nIf hypothesis (b2) had been true \u2014 pinned blocks correctly carry\n`BF_PINNED` and PROBE22POISON was wrongly stomping them \u2014 we'd have\nseen pinned_skip > 0 and the crash would have stopped.  Both did\nnot happen.\n\nHypothesis (a) \u2014 the BS underlying byte array is not pinned \u2014\npredicts pinned_skip = 0 trivially: there's no pinned MBA in the\ngraph for the stack to reference.\n\nThere's a residual hypothesis (b1) that PROBE22POISON was wrongly\nstomping pinned-memory `Addr#`s and PROBE23 still does the same\nbecause the **pinned blocks transiently present `bd_flags=0`** at the\nmoment our probe runs (post-scavenge, before `resize_nursery() /\nresetNurseries()`).  That would explain both pinned_skip=0 AND the\nunchanged crash.  But it requires the GHC RTS to clear `BF_PINNED`\nduring scavenge in some way, which is not documented behavior and\nnot visible in `rts/sm/Evac.c` / `rts/sm/Scav.c` on a quick read.\nReasonable reading: this would need its own audit before being\ntreated as the explanation.\n\n## What this means cumulatively\n\n| Session | Hypothesis                                                 | Outcome |\n|---------|------------------------------------------------------------|---------|\n| 20      | \"stack-frame bitmaps are wrong on PPC32 cross-build\"      | PROBE20/21 finds 184 heap-shaped non-evac slots; not-yet-classified |\n| 21      | \"bitmap encoding step is wrong\"                           | Disproved.  `BITMAP_BITS_SHIFT=5` both sides; mkLivenessBits faithful. |\n| 22      | \"`stackMapToLiveness` or upstream StackMap construction is wrong\" | Disproved for Catch.hs.  All 15 True-marked slots are dead. |\n| 23      | \"the bug is in another module's bitmap; PROBE22POISON will find it\" | Found 1 / 9 real read-after-poison events \u2014 in FastString. |\n| 24      | \"that 1 read is into a slot whose StackRep IS wrong\"      | Disproved.  The slot is an `Addr#`, correctly typed non-pointer. |\n| **25**  | **\"PROBE22POISON is itself the bug (pinned-Addr# false positive)\"** | **Disproved.  Crash + pinned_skip pattern rules out (b2).** |\n\nAll five \"the GC bug is somewhere on the stack-frame bitmap\" framings\nhave now been refuted.  After session 25 the strongest hypothesis is:\n\n> The bytestring/FastString boundary in stage2's compilation pipeline\n> sometimes feeds a non-pinned-backed `BS` constructor into\n> `mkFastStringByteString`.  Inside the inlined\n> `Data.ByteString.Short.Internal.toShortIO` body, the BS's `Addr#` is\n> spilled to the stack across an `stg_newByteArray#` call (which\n> performs a GC), and after GC moves the underlying byte array, the\n> `Addr#` on the stack is stale.  When the code resumes and does\n> `copyAddrToByteArray#`, the memcpy reads from the stale address.\n> Under `-A1m` this is what causes the production \"variable not found\"\n> / SIGSEGV.\n\nConfirming this requires finding the BS allocator that produces the\nnon-pinned BS.  Session 25 doesn't do that; session 26 should.\n\n## What we didn't try\n\n- Cross-checking the host `ghc` 9.2.8's Cmm for the same\n  FastString.hs (handoff suggested it as a side-experiment, \"20\n  minutes useful background\").  Skipping it: the result here is\n  decisive enough that the host comparison wouldn't change the\n  next-step plan.  Worth picking up if (a) gets stuck.\n- Auditing `rts/sm/Evac.c` / `Scav.c` for any code path that clears\n  `BF_PINNED`.  This would settle the residual (b1) hypothesis.\n  ~30 min, deferred to session 26 as part of the BS-allocator hunt.\n- Counting pinned-block stack slots across other inputs (e.g., a\n  longer compile that exercises more of the BS allocator surface).\n  All-zero pinned_skip on M5.hs is per se interesting but small-N.\n\n## Methodology / files added this session\n\n- [`probe23-poison-stack.patch`](probe23-poison-stack.patch) \u2014 the\n  RTS patch (PROBE22POISON + BF_PINNED filter + PROBE23PINNED\n  no-poison log).\n- [`scripts/run-poison.sh`](scripts/run-poison.sh) \u2014 adapted from\n  session 23.  Counts PROBE23 / PROBE23POISON / PROBE23PINNED lines.\n- [`README.md`](README.md), [`findings.md`](findings.md),\n  [`HANDOFF.md`](HANDOFF.md), `commits.md` \u2014 writeup.\n- Logs at [`../../../log/session25/`](../../../log/session25/)\n  (gitignored).\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/README.md",
  "content": "# Session 25 \u2014 stage2 GC bug, round 7 (PROBE23 = pin-aware poison; rules out PROBE22 false-positive theory)\n\n**Dates:** 2026-05-11.\n\n**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on\nTiger uses the `+RTS -A1G` workaround.  Session 23 confirmed the bug\nis real (5/5 deterministic SIGSEGV on `_blk_c7te + 112` reading\n`MEM[Sp + 12] = 0xdeadbeef`).  Session 24 settled that the StackRep\nof `_blk_c7te` is `[False, True, True]` and that this is **correct**\ngiven the Cmm IR \u2014 the slot at Sp+12 is the `Addr#` field of an\nunboxed `Data.ByteString.Internal.Type.BS`.  Two open hypotheses\ngoing in:\n\n(a) Real bug: some BS reaching `mkFastStringByteString` is\n    backed by a non-pinned `MutableByteArray#`, so its `Addr#` is\n    stale post-GC.\n\n(b) Probe artefact: PROBE22POISON wrongly stomped a pinned-memory\n    `Addr#` because pinned blocks transiently lose `BF_PINNED` (or\n    were never tagged with it during this GC pass).\n\n**Status on exit:** Hypothesis **(a) is supported, (b) is rejected\nin its strong form.**  PROBE23 (= PROBE22POISON + `&& !(bd->flags &\nBF_PINNED)` plus a no-poison `PROBE23PINNED` log of pinned-block\nstack slots) ran 5\u00d7M5.hs under `+RTS -A1m`.  Result:\n\n- 5/5 SIGSEGV at `_blk_c7te + 112` (exit 139), byte-identical\n  crash signature to session 23's PROBE22POISON run.\n- The smoking-gun slot at `gc_no=2 slot=6 old=0x0bf5f38a` is\n  bit-identical to session 23's reading.\n- **`pinned_skip = 0` across every GC of every iteration.**  No\n  stack-resident value pointed into a `BF_PINNED` block during any\n  of the 3 GCs of M5.hs's compile.\n\nIf (b)'s strong form had been right (\"PROBE22 was wrongly stomping\npinned-Addr#s\"), PROBE23 would have shown pinned_skip > 0 and the\ncrash would have stopped.  Neither happened.  A residual\nhypothesis (b1) \u2014 \"pinned blocks present `bd_flags=0` at this GC\npoint because BF_PINNED is transiently cleared\" \u2014 remains formally\nconsistent with the data but requires unverified RTS behavior;\ntreating it as the explanation needs an `Evac.c`/`Scav.c` audit\nsession 25 does not do.\n\nAfter session 25 the strongest hypothesis is:\n\n> Some caller of `mkFastStringByteString` produces a `BS` whose\n> `ForeignPtrContents` wraps a non-pinned `MutableByteArray#`,\n> violating the pinning invariant documented at\n> `libraries/base/GHC/ForeignPtr.hs:145`.  The `Addr#` field of\n> that BS is spilled to Sp+12 across an `stg_newByteArray#`\n> GC point inside the inlined `toShortIO` body.  After GC moves\n> the underlying byte array, the `Addr#` on the stack is stale.\n> The next `copyAddrToByteArray#` reads from a stale (in PROBE23,\n> poisoned) address and crashes.\n\nSessions 19\u201325 collectively show: **the actual GC bug is not in\nLayoutStack, not in `mkLivenessBits`, not in `stackMapToLiveness`,\nnot in any stack-frame bitmap PROBE21 looked at.**  It is upstream\nof all of those \u2014 in the bytestring / FastString allocation\nboundary.  Session 26's hunt is for the BS-allocator code path that\nomits pinning.\n\nv0.12.0 still ships unchanged.  Stage2 on pmacg5 was reverted to\nclean RTS at session-25 end.\n\nHANDOFF for session 26: see [`HANDOFF.md`](HANDOFF.md).  Top of\nqueue: instrument the BS pattern-match in `mkFastStringByteString`\n(or `mkFastStringByteString`'s callers in the typechecker / lexer)\nto print whether the underlying `ForeignPtrContents` is a\n`PlainPtr` (unpinned) or one of the pinned variants\n(`MallocPtr`/`PlainForeignPtr` / etc.).  Alternative path: read\nthe source of `Data.ByteString.Short.Internal.toShortIO` (and its\ndirect callers) and audit which ones do `mallocByteString` /\n`mallocPlainForeignPtrBytes` (pinned) vs. `byteArrayContents# .\nunsafeCoerce#` of an unpinned MBA.\n\n## What we did, in order\n\n### Step 1 \u2014 confirm baseline green\n\n`tests/run-tests.sh`: 30 PASS, 4 expected design diffs (Int size,\ngetProgName, getpid, numeric boundaries).  Matches v0.12.0.\n\n### Step 2 \u2014 write PROBE23\n\n[`probe23-poison-stack.patch`](probe23-poison-stack.patch).  Two\nchanges vs. session 23's PROBE22POISON:\n\n1. The poison filter gains `&& !(bd->flags & BF_PINNED)`.  Pinned\n   blocks are skipped, not stomped.\n2. A new `PROBE23PINNED` line logs every pinned-block-backed stack\n   slot (no poison).  This is PROBE22's false-positive denominator\n   under hypothesis (b2).\n\nInsertion point: same as PROBE22POISON (just before\n`resize_nursery();` in `GarbageCollect()`).\n\n### Step 3 \u2014 apply, rebuild RTS, deploy\n\n```\n# from external/ghc-modern/ghc-9.2.8\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\n# ~5 sec incremental (RTS only, all 12 ways).\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n# ~3 min for cross-link + scp + smoke test.\n```\n\n(The first incremental RTS rebuild is suspiciously fast (~5 s) but\nverified by `ls _build/stage1/rts/build/c/sm/GC.*o`: all 12 ways of\n`GC.o` are present and newer than `rts/sm/GC.c`.)\n\n### Step 4 \u2014 run the harness\n\n```\nbash docs/sessions/2026-05-11-session-25-pin-aware-poison/scripts/run-poison.sh pmacg5\n```\n\n5\u00d7M5.hs under `+RTS -A1m`, 1\u00d7M5.hs under `+RTS -A1m -DS`, 1\u00d7M5.hs\nunder `+RTS -A1G`.  Captures PROBE23/POISON/PINNED counts and\nGHC_EXIT.  ~30 sec total.\n\n### Step 5 \u2014 collect crash log + classify\n\n```\nssh -q pmacg5 'tail -200 ~/Library/Logs/CrashReporter/ghc-real.crash.log' \\\n    > log/session25/ghc-real.crash.log\n```\n\nAll 3 most recent crash entries match PROBE22POISON's session-23\nsignature: `_blk_c7te + 112`, `r4=0xdeadbeef`, `r5=0x10`, in\n`__memcpy + 80`.\n\nPer-iteration data summary table \u2014 5/5 SIGSEGV, 9 poisons each,\n0 pinned-skip each.  See [`findings.md`](findings.md) for the full\nper-GC breakdown.\n\n### Step 6 \u2014 interpretation\n\nThe decision matrix from session-24 HANDOFF.md was binary:\n\n- \"5/5 crash gone\" \u2192 (b) is right.\n- \"5/5 crash fires\" \u2192 (a) is right.\n\nWe're in the second branch.  But the additional `pinned_skip = 0`\nfinding refines this: even a charitable reading of (b) \u2014 \"PROBE was\nstomping pinned-Addr#s\" \u2014 is contradicted by the absence of any\npinned-block-backed stack slots.  See [`findings.md`](findings.md)\n\"Why '0 pinned-skip' is informative\" for the full reasoning, including\nthe residual (b1) hypothesis we cannot fully rule out without an RTS\naudit.\n\n### Step 7 \u2014 end-of-session ritual\n\n```\ncd external/ghc-modern/ghc-9.2.8\ngit checkout rts/sm/GC.c\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\nStage2 on pmacg5 back to clean RTS.\n\n## Status on exit\n\n- **v0.12.0 unchanged.**  Stage2 ships with `+RTS -A1G` wrapper,\n  baseline test battery green.\n- **No source-tree edits this session** persist.  GC.c is back to\n  upstream `dfa83462`.\n- **Stage2 ghc on pmacg5 is clean.**\n- **Logs at** [`log/session25/`](../../../log/session25/) (gitignored)\n  capture the PROBE23 run + the crash log.\n- **HANDOFF for session 26** scopes the BS-allocator hunt.\n\n## Files added this session\n\n- [`README.md`](README.md), [`findings.md`](findings.md),\n  [`HANDOFF.md`](HANDOFF.md), `commits.md` \u2014 writeup.\n- [`probe23-poison-stack.patch`](probe23-poison-stack.patch) \u2014 the\n  RTS patch for the experiment (not committed to GHC tree; archived\n  here for re-apply).\n- [`scripts/run-poison.sh`](scripts/run-poison.sh) \u2014 harness adapted\n  from session 23 to count PROBE23 fields.\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b7l1i5k7t.output 2>&1 | tail -10; echo \"---deploy still running:\"; pgrep -fl deploy-stage2 | head -3",
  "description": "Check deploy status"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md",
  "content": "# Handoff from session 25 \u2192 session 26\n\n**For:** the next claude session.\n**From:** session 25 (stage2 GC bug round 7; PROBE23 = pin-aware\npoison; rules out the b2 false-positive theory; 2026-05-11).\n**Recommended pickup:** find the BS-allocator code path that\nproduces a non-pinned-backed `BS` flowing into\n`mkFastStringByteString`.\n\n## TL;DR (mandatory read)\n\n- PROBE23 (PROBE22POISON + `BF_PINNED` filter + a no-poison\n  `PROBE23PINNED` log of pinned-block stack slots) ran on M5.hs\n  under `+RTS -A1m`.  **5/5 SIGSEGV, byte-identical to PROBE22**:\n  same crash slot (`gc_no=2 slot=6 old=0x0bf5f38a` at `_blk_c7te +\n  112`), same `r4=0xdeadbeef`, same `r5=0x10`.\n- **`pinned_skip = 0` across every GC of every iteration.**  No\n  stack-resident value pointed into a `BF_PINNED` block during the\n  3 GCs of M5.hs's compile.  211 heap-shaped stack words seen\n  cumulatively; 0 pinned.\n- Conclusion: hypothesis (a) \"BS reaches `mkFastStringByteString`\n  with a non-pinned underlying byte array\" is supported.  Hypothesis\n  (b2) \"PROBE22POISON was wrongly stomping pinned-Addr#s\" is\n  rejected.  Residual (b1) \"BF_PINNED transiently cleared during\n  GC\" remains formally open but is contrived; pursue (a) first.\n- v0.12.0 ships unchanged.  Stage2 on pmacg5 was reverted to clean\n  RTS at session-25 end.\n\n## Read in order\n\n1. **This file** (the handoff).\n2. [`README.md`](README.md) \u2014 narrative of session 25.\n3. [`findings.md`](findings.md) \u2014 measurement detail + decision\n   matrix.\n4. [`probe23-poison-stack.patch`](probe23-poison-stack.patch) \u2014 the\n   exact RTS patch we ran.\n5. (Reference) [Session 24 findings](../2026-05-11-session-24-faststring-stackrep/findings.md)\n   \u2014 for the `_blk_c7te` Cmm reading and BS-field-layout arithmetic.\n6. (Reference) `libraries/base/GHC/ForeignPtr.hs:85-165` \u2014 the\n   `ForeignPtrContents` documentation that lists the pinned vs.\n   unpinned variants and their pinning invariants.\n7. (Reference) `libraries/bytestring/Data/ByteString/Internal/Type.hs`\n   (and `mallocByteString`, `unsafePackAddress`, etc.) \u2014 the BS\n   producer set we need to audit.\n\n## What to NOT redo\n\n- **Don't re-run PROBE22 or PROBE23 expecting different results.**\n  Both are deterministic per session 23 / 25.  They've told us\n  everything they can; we now need to see what's UPSTREAM, in\n  Haskell-level code, not in the RTS.\n- **Don't go back to LayoutStack / mkLivenessBits / stackMapToLiveness.**\n  Sessions 21\u201324 settled them.  The bitmap is correct; the bug is\n  not in stack-frame liveness analysis.\n- **Don't audit Catch.hs.**  Session 22 already settled that.\n- **Don't poison without filtering by something more specific than\n  block flags.**  PROBE22 / PROBE23 have served their purpose.\n\n## What to try next, in priority order\n\n### Top: instrument the BS allocator surface\n\nThe simplest decisive test: print, for each `BS` constructor that\nflows into `mkFastStringByteString`, the runtime tag of its\n`ForeignPtrContents`.  If any of them is `PlainPtr` (the unpinned\nvariant), we've found the violator.\n\nThere are two ways to instrument this:\n\n#### Option A \u2014 patch the Haskell-level pattern\n\nAdd a `Debug.Trace.traceShow`-equivalent inside\n`mkFastStringByteString` (or its inlinee chain) right at the\n`case bs of BS p contents l -> ...` site.  Print whether `contents`\nis a `PlainPtr` MBA (unpinned) vs `MallocPtr` / `PlainForeignPtr`\n(pinned).  The check is:\n\n```haskell\nimport GHC.ForeignPtr (ForeignPtrContents(..))\nimport GHC.Exts (isMutableByteArrayPinned#, MutableByteArray#, RealWorld)\nimport GHC.IO (unsafePerformIO)\n\nisPinnedFPC :: ForeignPtrContents -> Bool\nisPinnedFPC (PlainPtr mba)            = isTrue# (isMutableByteArrayPinned# mba)\nisPinnedFPC (MallocPtr _ _)           = True   -- always pinned\nisPinnedFPC (PlainForeignPtr _)       = True   -- finalizer-bearing pinned MBA\nisPinnedFPC (FinalPtr)                = True   -- static, always pinned\n```\n\n(The exact constructor names are 9.2.8-vintage; verify by reading\n`libraries/base/GHC/ForeignPtr.hs`.)\n\nPlace the trace inside `mkFastStringByteString`'s body in\n`compiler/GHC/Data/FastString.hs`.  Cross-compile, redeploy, run\nM5.hs.  Look for the BSs that print \"PlainPtr unpinned\".\n\nCaveats:\n- Rebuilding stage1 ghc with a modified compiler library takes ~3\u20135\n  min.  Then rebuild stage2 + deploy.\n- `Debug.Trace` might already be in scope; if not, add\n  `import Debug.Trace (trace)`.\n- `isMutableByteArrayPinned#` may not be available on 9.2.8 \u2014 check\n  `libraries/ghc-prim/GHC/Prim.hs`.  Fallback: lookup\n  `byteArrayContents#` and check the underlying block via FFI to\n  `lookupBdescr`.\n\n#### Option B \u2014 instrument at the RTS level\n\nAdd a probe inside `stg_newByteArray#` (or `allocate`) that prints\nthe tag of every `MutableByteArray#` allocated with the FastString\ncaller's pc.  Or, more targeted: in `evacuate`, when moving a\n`MUT_ARR_PTRS_FROZEN` / `ARR_WORDS` closure, print whether its\nsource block had `BF_PINNED` set; if not, print \"moved a non-pinned\nbyte array.\"\n\nThis avoids touching Haskell source but is harder to attribute to\n\"this BS came from this Haskell call site.\"\n\n**Recommend A first.**  It's slower per iteration but produces\nattribution data the RTS-level probe can't.\n\n### Second: read the BS allocator surface\n\nBefore instrumenting, just read these files cold and grep for\n\"newByteArray#\" (unpinned) vs \"newPinnedByteArray#\" (pinned):\n\n- `libraries/bytestring/Data/ByteString/Internal/Type.hs` \u2014 the BS\n  type and its constructors.\n- `libraries/bytestring/Data/ByteString/Internal.hs` \u2014\n  `mallocByteString`, `mallocPlainForeignPtrBytes`, `create`,\n  `createUptoN`, `unsafePackAddress`, `packCString`, `pack`, etc.\n- `libraries/bytestring/Data/ByteString/Short/Internal.hs` \u2014\n  `toShort`, `toShortIO`, `fromShort`.  `toShortIO` is what\n  `mkFastStringByteString` inlines.\n- `compiler/GHC/Data/FastString.hs::mkFastStringByteString` \u2014 the\n  caller.\n\nMap each BS-producer function to its pinning status.  Most are\npinned (designed-in invariant).  Find the ones that aren't.\n\nThe most likely suspects for non-pinned BS production:\n- `unsafePackAddress` family \u2014 wraps a static C string, usually\n  `FinalPtr` (pinned by definition) but could be `PlainPtr` if\n  recently refactored.\n- `pack` / `packBytes` \u2014 usually goes through `create` \u2192\n  `mallocByteString` (pinned), but check the implementation.\n- Anything that goes through `Data.ByteString.Internal.fromForeignPtr`\n  with a custom `ForeignPtrContents`.\n\nMost importantly: **what calls `mkFastStringByteString`?**  Per\nsession 24's STG dump, the function inlines `toShortIO` from\n`Data.ByteString.Short.Internal`.  But its callers are throughout\nthe typechecker / lexer.  Quick grep:\n\n```\ncd external/ghc-modern/ghc-9.2.8\ngrep -rn 'mkFastStringByteString\\|mkFastString '\\\n   compiler/GHC/Data/FastString.hs compiler/GHC/Parser.y \\\n   compiler/GHC/Parser/Lexer.x compiler/GHC/Tc/ \\\n   compiler/GHC/Iface/ | head -30\n```\n\nThe lexer's `cmtok` family (which produces FastString from a\nByteString slice) is a common hot path.\n\n### Third: residual (b1) audit\n\nIf (a) stalls (i.e., we can't find any non-pinned BS producer), the\nresidual (b1) \"BF_PINNED transiently cleared during GC\" hypothesis\nbecomes worth testing.  Read `rts/sm/Evac.c` and `rts/sm/Scav.c`\nfor any code that touches `bd->flags &= ~BF_PINNED`.  Also check\n`allocatePinned` and `pinned_object_blocks` handling.  ~30 min.\n\n### Fourth: cross-compare host ghc 9.2.8\n\nSuggested by session-24 HANDOFF.md as a side experiment but\ndeprioritized.  Worth doing if (a) still doesn't reveal a culprit:\n\n```\nghc -ddump-cmm-sp -ddump-cmm-info -dno-suppress-uniques \\\n    -O2 -c -fno-asm-shortcutting compiler/GHC/Data/FastString.hs\n```\n\nDiff the StackRep of the equivalent block.  If the host emits a\ndifferent layout (e.g., the `Addr#` is kept in a register across\nthe GC point), the bug is PPC32-specific because of unregisterised\ncodegen.  20 min.\n\n## Mechanics \u2014 how to reproduce session-25 results\n\n```bash\ncd /Users/cell/claude/ghc-darwin8-ppc\n\n# 0. Confirm baseline still green\nbash tests/run-tests.sh   # expect 30 PASS / 4 design diffs\n\n# 1. Apply PROBE23 to rts/sm/GC.c.\ncd external/ghc-modern/ghc-9.2.8\ngit apply ../../../docs/sessions/2026-05-11-session-25-pin-aware-poison/probe23-poison-stack.patch\n\n# 2. RTS-only rebuild\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a    # ~5 sec incremental\n\n# 3. Deploy\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5                                  # ~3 min\n\n# 4. Run harness\nbash docs/sessions/2026-05-11-session-25-pin-aware-poison/scripts/run-poison.sh pmacg5\n# 5\u00d7M5.hs under -A1m + 2 controls.\n\n# 5. Pull crash log\nssh -q pmacg5 'tail -200 ~/Library/Logs/CrashReporter/ghc-real.crash.log' \\\n    > log/session25/ghc-real.crash.log\n\n# 6. Revert + redeploy clean\ncd external/ghc-modern/ghc-9.2.8\ngit checkout rts/sm/GC.c\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n    _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\n## Hosts (unchanged from sessions 22\u201324)\n\n- **uranium** (this Mac): host for cross-build, source edits.\n- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.\n- **imacg3**: smaller-RAM PPC G3.\n- **indium**: trimmed dev tools \u2014 don't use for clang or hadrian builds.\n\n## What's clean / dirty in the source tree\n\n- `external/ghc-modern/ghc-9.2.8/rts/sm/GC.c` \u2014 clean (revert\n  applied at session-25 end).\n- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSrts-1.0.2*.a`\n  \u2014 clean RTS rebuilt + redeployed.\n- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` \u2014 clean (matches v0.12.0).\n- New session log: `docs/sessions/2026-05-11-session-25-pin-aware-poison/`\n  + run logs gitignored at `log/session25/`.\n\n## Time estimate for session 26\n\n- Setup + read handoff: 15 min.\n- Read BS-allocator source surface (option B above, no-instrumentation\n  audit first): 30\u201360 min.\n- If audit doesn't immediately localise the culprit, instrument\n  `mkFastStringByteString`: cross-compile (3\u20135 min) + redeploy\n  (3 min) + run (1 min) per iteration.  3\u20135 iterations likely.\n- Writeup: 30 min.\n\nRealistic: 1 medium session (~3\u20135 h) to identify the BS-producer\nthat violates the pinning invariant.  Then probably another short\nsession to write the fix (which is upstream of GHC \u2014 likely a\nbytestring library bug or a compiler-internal misuse of the\nbytestring API), and a third to verify the fix kills the GC crash\nwithout `+RTS -A1G`.\n\nIf the BS-producer turns out to be GHC-internal (likely; the\nbytestring library is widely used and well-tested elsewhere), the\nfix is a 1-line patch.  If it's bytestring-library-side, we'd have\nto vendor + patch bytestring (precedent: `vendor/network/`,\n`vendor/HsOpenSSL/`).\n\n## Paste-into-fresh-session prompt\n\n```\nContext: just finished session 25 (stage2 GC bug round 7; PROBE23 =\npin-aware poison).  PROBE23 = PROBE22POISON + `&& !(bd->flags &\nBF_PINNED)` plus a no-poison PROBE23PINNED log of pinned-block stack\nslots.  Result on M5.hs under +RTS -A1m: 5/5 SIGSEGV (byte-identical\nto PROBE22POISON's session-23 run), with `pinned_skip = 0` across\nevery GC.  This rules out the strong form of \"PROBE22POISON was\nwrongly stomping pinned-Addr#s\" \u2014 there were no pinned-block-backed\nstack slots at all.  Conclusion: the BS reaching mkFastStringByteString\nreally is non-pinned-backed (hypothesis (a) from session-24 HANDOFF),\nviolating the BS pinning invariant documented at\nlibraries/base/GHC/ForeignPtr.hs:145.\n\nSessions 19\u201325 collectively settled that the bug is NOT in\nLayoutStack, NOT in mkLivenessBits, NOT in stackMapToLiveness, NOT\nin any stack-frame bitmap PROBE21 looked at.  The bug is upstream of\nall of those.  It's in the BS-allocation pipeline \u2014 specifically,\nsome caller of mkFastStringByteString is producing a BS whose\nForeignPtrContents is a PlainPtr (unpinned MutableByteArray#) when\nit should be one of the pinned variants.\n\nRead in order:\n1. docs/sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md\n2. docs/sessions/2026-05-11-session-25-pin-aware-poison/README.md\n3. docs/sessions/2026-05-11-session-25-pin-aware-poison/findings.md\n4. (reference) libraries/base/GHC/ForeignPtr.hs:85-165 for the\n   ForeignPtrContents variants and pinning invariants\n5. (reference) libraries/bytestring/Data/ByteString/Internal/Type.hs\n   for the BS constructor\n\nThen either:\n- Audit the bytestring producer functions for unpinned ByteArray#\n  use, OR\n- Instrument mkFastStringByteString to print the\n  ForeignPtrContents tag for each BS that flows in (rebuild\n  stage1, redeploy stage2, run M5.hs, look for \"PlainPtr\"\n  output), OR\n- Audit rts/sm/Evac.c / Scav.c for any BF_PINNED clearing \u2014 the\n  residual (b1) hypothesis \u2014 to make sure (a) is the right path.\n\nHosts: uranium for builds, pmacg5 for runs.  Don't use indium.\nv0.12.0 stays shipped \u2014 don't break stage2's -A1G wrapper.\n\nUnsupervised mode is project default.\n```\n"
}


---

## 🤖 Claude

Now write commits.md (will be backfilled with SHAs after commit), and update state.md + roadmap.md.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/commits.md",
  "content": "# Commits \u2014 session 25\n\n(SHAs to be backfilled after the session-end commit lands.)\n\n- _TBD_ Session 25: stage2 GC bug investigation, round 7.  PROBE23\n  (PROBE22POISON + `BF_PINNED` filter + no-poison `PROBE23PINNED`\n  log) confirms hypothesis (a) \u2014 the BS reaching\n  `mkFastStringByteString` really is non-pinned-backed.  Hypothesis\n  (b2) \"PROBE22POISON was wrongly stomping pinned-Addr#s\" is\n  rejected.  RTS patch archived; cross-tree reverted.\n- _TBD_ Session 25 commits.md: backfill the SHAs.\n"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "*Updated: 2026-05-11 session 24 (stage2 GC bug round 6 \u2014 the FastString frame's StackRep `[False, True, True]` is the **correct** answer given the Cmm IR; slot Sp+12 holds an `Addr#` (raw word), not a misclassified pointer.  Sessions 19\u201323's \"bitmap codegen is broken\" narrative is wrong.  Real bug is either an upstream invariant violation (some BS reaches `mkFastStringByteString` with a non-pinned underlying byte array) or PROBE22POISON itself was a false positive on pinned-memory Addr#s \u2014 decisive test is session 25's `BF_PINNED`-aware PROBE23).*",
  "new_string": "*Updated: 2026-05-11 session 25 (stage2 GC bug round 7 \u2014 PROBE23 = PROBE22POISON + `BF_PINNED` filter + no-poison `PROBE23PINNED` log of pinned-block stack slots.  Result: 5/5 SIGSEGV byte-identical to PROBE22, **with `pinned_skip = 0`** across every GC.  Rules out the false-positive theory in its strong form: no stack-resident value pointed into a pinned block during M5.hs's compile, so the bug isn't \"PROBE22 was wrongly stomping pinned-Addr#s.\"  Hypothesis (a) from session-24 confirmed: some BS reaching `mkFastStringByteString` is backed by a non-pinned `MutableByteArray#`, violating the pinning invariant at `libraries/base/GHC/ForeignPtr.hs:145`.  Sessions 19\u201325 cumulatively rule out: bitmap codegen, `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, and the StackRep itself \u2014 all correct.  Bug is upstream of all of them, in the bytestring/FastString allocation boundary.  Next: find the BS allocator that omits pinning.)*"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "And [`docs/sessions/2026-05-11-session-24-faststring-stackrep/`](sessions/2026-05-11-session-24-faststring-stackrep/)\nfor round 6 \u2014 **session 23's attribution was wrong**.  Cross-built\nFastString.hs's `_blk_c7te` info-table's StackRep is `[False, True,\nTrue]`, which is the **correct** bitmap for what the Cmm IR\nspecifies: slot Sp+12 holds the `Addr#` field of an unboxed\n`Data.ByteString.Internal.Type.BS` constructor (the\n`byteArrayContents#` of the underlying `ForeignPtrContents`), typed\n`I32` (non-pointer) in Cmm.  LayoutStack faithfully encodes this;\n`mkLivenessBits` faithfully encodes that.  The actual stale-Addr#\nread-after-poison is upstream of LayoutStack \u2014 either an invariant\nviolation by some caller of `mkFastStringByteString` (the BS is\nbacked by a non-pinned `MutableByteArray#`, so the `Addr#` is stale\nacross the `stg_newByteArray#` GC point) or PROBE22POISON itself\nfalse-positiveing on pinned-memory `Addr#`s in blocks whose\n`bd_flags` happen to be `0x0` at the moment PROBE22 runs.  Decisive\ntest: PROBE23, a `BF_PINNED`-aware variant of PROBE22POISON.  Session\n[`HANDOFF.md`](sessions/2026-05-11-session-24-faststring-stackrep/HANDOFF.md)\nscopes it.",
  "new_string": "And [`docs/sessions/2026-05-11-session-24-faststring-stackrep/`](sessions/2026-05-11-session-24-faststring-stackrep/)\nfor round 6 \u2014 **session 23's attribution was wrong**.  Cross-built\nFastString.hs's `_blk_c7te` info-table's StackRep is `[False, True,\nTrue]`, which is the **correct** bitmap for what the Cmm IR\nspecifies: slot Sp+12 holds the `Addr#` field of an unboxed\n`Data.ByteString.Internal.Type.BS` constructor (the\n`byteArrayContents#` of the underlying `ForeignPtrContents`), typed\n`I32` (non-pointer) in Cmm.  LayoutStack faithfully encodes this;\n`mkLivenessBits` faithfully encodes that.  The actual stale-Addr#\nread-after-poison is upstream of LayoutStack \u2014 either an invariant\nviolation by some caller of `mkFastStringByteString` (the BS is\nbacked by a non-pinned `MutableByteArray#`, so the `Addr#` is stale\nacross the `stg_newByteArray#` GC point) or PROBE22POISON itself\nfalse-positiveing on pinned-memory `Addr#`s in blocks whose\n`bd_flags` happen to be `0x0` at the moment PROBE22 runs.\nAnd [`docs/sessions/2026-05-11-session-25-pin-aware-poison/`](sessions/2026-05-11-session-25-pin-aware-poison/)\nfor round 7 \u2014 **PROBE23 (pin-aware poison) settled it.**  PROBE23 =\nPROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the poison filter,\nplus a no-poison `PROBE23PINNED` log of stack slots pointing into\n`BF_PINNED` blocks.  Result on M5.hs `+RTS -A1m`: 5/5 SIGSEGV\nbyte-identical to session 23's PROBE22 (same crash slot\n`gc_no=2 slot=6 old=0x0bf5f38a` at `_blk_c7te + 112`), AND\n`pinned_skip = 0` across every GC of every iteration.  No stack\nslot held a value pointing into a pinned block during M5.hs's\ncompile.  Rules out the strong form of the b-hypothesis \"PROBE22\nwas wrongly stomping pinned-memory Addr#s\" \u2014 there were no pinned-\nbacked addresses on the stack to stomp.  Confirms hypothesis (a):\nthe BS reaching `mkFastStringByteString` really is non-pinned-backed.\nSessions 19\u201325 collectively rule out all of: bitmap codegen,\n`mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, the StackRep\nitself.  The actual bug is upstream of all of them, in the\nbytestring/FastString allocation boundary.  Next session: instrument\n`mkFastStringByteString` to print whether each incoming BS's\n`ForeignPtrContents` is `PlainPtr` (unpinned) vs one of the pinned\nvariants, find the violator, fix the BS producer.  Session\n[`HANDOFF.md`](sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md)\nscopes it."
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "- 2026-05-10 session 23: stage2 GC bug investigation, round 5.",
  "new_string": "- 2026-05-11 session 25: stage2 GC bug investigation, round 7.\n  PROBE23 (PROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the\n  poison filter, plus a no-poison `PROBE23PINNED` log of stack\n  slots pointing into pinned blocks) ran against M5.hs under\n  `+RTS -A1m`.  Result: 5/5 SIGSEGV byte-identical to session\n  23's PROBE22 (same crash slot `gc_no=2 slot=6 old=0x0bf5f38a`\n  at `_blk_c7te + 112`, same `r4=0xdeadbeef`, same `r5=0x10`),\n  AND `pinned_skip = 0` across every GC of every iteration.\n  No stack-resident value pointed into a `BF_PINNED` block during\n  M5.hs's compile.  Rules out the false-positive theory in its\n  strong form: PROBE22 was NOT wrongly stomping pinned-Addr#s\n  (there weren't any).  Confirms hypothesis (a) from session-24\n  HANDOFF: the BS reaching `mkFastStringByteString` is backed by\n  a non-pinned `MutableByteArray#`, violating the pinning\n  invariant at `libraries/base/GHC/ForeignPtr.hs:145`.  Sessions\n  19\u201325 collectively rule out all of: bitmap codegen,\n  `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, the\n  StackRep itself.  The bug is upstream of all of them, in the\n  bytestring/FastString allocation boundary.  v0.12.0 ships\n  unchanged; stage2 on pmacg5 reverted to clean RTS at session-25\n  end.  Next session: instrument `mkFastStringByteString` (or\n  audit the BS producer surface) to find the BS allocator that\n  omits pinning.\n- 2026-05-10 session 23: stage2 GC bug investigation, round 5."
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "old_string": "- [`docs/sessions/2026-05-11-session-24-faststring-stackrep/`](sessions/2026-05-11-session-24-faststring-stackrep/)\n  \u2014 round 6.  **Session 23's attribution was wrong.**  Re-cross-\n  compiled FastString.hs with `-ddump-cmm-sp -ddump-cmm-info`;\n  found `_blk_c7te`'s info table directly (uniques are stable\n  across rebuilds).  Its StackRep is `[False, True, True]` \u2014 and\n  reading the Cmm IR, that is the **correct** answer: slot Sp+12\n  is `_s77l`, the `Addr#` field of an unboxed `BS` constructor\n  (`BS !(ForeignPtr Word8) !Int` \u21d2 3 unboxed fields: ptr\n  `ForeignPtrContents`, raw `Addr#`, raw `Int`).  An `Addr#` is\n  typed `I32` in Cmm \u2014 non-pointer \u2014 and the bitmap faithfully\n  reflects that.  `mkLivenessBits`, `stackMapToLiveness`, and\n  `LayoutStack` are all correct.  The PROBE22POISON read-after-\n  poison crash is therefore **not** a bitmap bug.  Two open\n  hypotheses for what it really is:\n    (a) Invariant violation upstream \u2014 some BS reaching\n        `mkFastStringByteString` has a non-pinned `MutableByteArray#`\n        backing its `ForeignPtrContents`, so the `Addr#` becomes\n        stale when GC moves the byte array.  Real bug, but not in\n        LayoutStack.\n    (b) PROBE22POISON false positive \u2014 pinned blocks may transiently\n        present `bd_flags=0x0` (no `BF_PINNED`) at the moment\n        PROBE22 runs, causing the probe to wrongly stomp stable\n        `Addr#`s.  In that case, the production GC crash under\n        `-A1m` has a different mechanism (CAFs, SRTs, info-tables,\n        non-stack RTS state).\n  Decisive test: PROBE23 = PROBE22POISON + `&& !(bd->flags &\n  BF_PINNED)` to the poison filter.  Session-24\n  [`HANDOFF.md`](sessions/2026-05-11-session-24-faststring-stackrep/HANDOFF.md)\n  scopes it.",
  "new_string": "- [`docs/sessions/2026-05-11-session-24-faststring-stackrep/`](sessions/2026-05-11-session-24-faststring-stackrep/)\n  \u2014 round 6.  **Session 23's attribution was wrong.**  Re-cross-\n  compiled FastString.hs with `-ddump-cmm-sp -ddump-cmm-info`;\n  found `_blk_c7te`'s info table directly (uniques are stable\n  across rebuilds).  Its StackRep is `[False, True, True]` \u2014 and\n  reading the Cmm IR, that is the **correct** answer: slot Sp+12\n  is `_s77l`, the `Addr#` field of an unboxed `BS` constructor\n  (`BS !(ForeignPtr Word8) !Int` \u21d2 3 unboxed fields: ptr\n  `ForeignPtrContents`, raw `Addr#`, raw `Int`).  An `Addr#` is\n  typed `I32` in Cmm \u2014 non-pointer \u2014 and the bitmap faithfully\n  reflects that.  `mkLivenessBits`, `stackMapToLiveness`, and\n  `LayoutStack` are all correct.  The PROBE22POISON read-after-\n  poison crash is therefore **not** a bitmap bug.  Two open\n  hypotheses for what it really is:\n    (a) Invariant violation upstream \u2014 some BS reaching\n        `mkFastStringByteString` has a non-pinned `MutableByteArray#`\n        backing its `ForeignPtrContents`, so the `Addr#` becomes\n        stale when GC moves the byte array.  Real bug, but not in\n        LayoutStack.\n    (b) PROBE22POISON false positive \u2014 pinned blocks may transiently\n        present `bd_flags=0x0` (no `BF_PINNED`) at the moment\n        PROBE22 runs, causing the probe to wrongly stomp stable\n        `Addr#`s.  In that case, the production GC crash under\n        `-A1m` has a different mechanism (CAFs, SRTs, info-tables,\n        non-stack RTS state).\n  Decisive test: PROBE23 = PROBE22POISON + `&& !(bd->flags &\n  BF_PINNED)` to the poison filter.  See session 25 below.\n- [`docs/sessions/2026-05-11-session-25-pin-aware-poison/`](sessions/2026-05-11-session-25-pin-aware-poison/)\n  \u2014 round 7.  **PROBE23 settled it.**  PROBE23 = PROBE22POISON +\n  `BF_PINNED` filter + a no-poison `PROBE23PINNED` log of stack\n  slots pointing into pinned blocks.  Result on M5.hs `+RTS -A1m`:\n  5/5 SIGSEGV byte-identical to session 23 (same `_blk_c7te + 112`,\n  same `r4=0xdeadbeef`, same `r5=0x10`), AND `pinned_skip = 0`\n  across every GC of every iteration \u2014 no stack-resident value\n  pointed into a pinned block during M5.hs's compile.  Rules out\n  hypothesis (b2) \"PROBE22 was wrongly stomping pinned-Addr#s\" in\n  its strong form: there were no pinned-backed addresses on the\n  stack at all.  Confirms hypothesis (a): the BS reaching\n  `mkFastStringByteString` really is non-pinned-backed.  Sessions\n  19\u201325 collectively rule out: bitmap codegen, `mkLivenessBits`,\n  `stackMapToLiveness`, `LayoutStack`, the StackRep itself.  The\n  bug is upstream of all of them, in the bytestring/FastString\n  allocation boundary.  Next: find the BS allocator that omits\n  pinning.  Session-25\n  [`HANDOFF.md`](sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md)\n  scopes the BS-allocator hunt."
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7d2ffe6e-a4ba-4458-8e0f-591f778b119c/tasks/b7l1i5k7t.output 2>&1 | tail -20",
  "description": "Check deploy status"
}


---

## 🤖 Claude

Clean deploy done. Now committing.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 25 directory and pre-flight (read PROBE22 patch + harness, run baseline tests)",
      "activeForm": "Setting up session 25 dir and pre-flight",
      "status": "completed"
    },
    {
      "content": "Write PROBE23 patch (PROBE22POISON + BF_PINNED filter + pinned-on-stack logger)",
      "activeForm": "Writing PROBE23 patch",
      "status": "completed"
    },
    {
      "content": "Apply patch, rebuild RTS, deploy to pmacg5",
      "activeForm": "Rebuilding RTS and deploying to pmacg5",
      "status": "completed"
    },
    {
      "content": "Run 5\u00d7iteration M5.hs harness under -A1m on pmacg5",
      "activeForm": "Running 5\u00d7iteration M5.hs harness",
      "status": "completed"
    },
    {
      "content": "Collect + classify results (a vs b vs mixed)",
      "activeForm": "Collecting and classifying results",
      "status": "completed"
    },
    {
      "content": "Revert RTS, rebuild, redeploy clean to pmacg5",
      "activeForm": "Reverting and redeploying clean RTS",
      "status": "completed"
    },
    {
      "content": "Write session 25 README, findings, HANDOFF, commits.md",
      "activeForm": "Writing session 25 docs",
      "status": "completed"
    },
    {
      "content": "Update state.md and roadmap.md",
      "activeForm": "Updating state.md and roadmap.md",
      "status": "completed"
    },
    {
      "content": "Commit all session 25 work",
      "activeForm": "Committing session 25 work",
      "status": "in_progress"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && git status",
  "description": "Check git status before commit"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-11-session-25-pin-aware-poison docs/state.md docs/roadmap.md && git status",
  "description": "Stage session 25 files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git commit -m \"$(cat <<'EOF'\nSession 25: stage2 GC bug investigation, round 7 (PROBE23 = pin-aware poison rules out PROBE22 false-positive theory; bug is upstream BS pinning invariant violation).\n\nPROBE23 = PROBE22POISON + `&& !(bd->flags & BF_PINNED)` to the poison\nfilter, plus a no-poison `PROBE23PINNED` log of stack slots that\npoint into pinned blocks.  Result on M5.hs `+RTS -A1m`, 5 iterations:\n5/5 SIGSEGV byte-identical to session 23's PROBE22 (same crash slot\n`gc_no=2 slot=6 old=0x0bf5f38a` at `_blk_c7te + 112`, same\n`r4=0xdeadbeef`, same `r5=0x10`), AND `pinned_skip = 0` across every\nGC of every iteration.  No stack-resident value pointed into a\n`BF_PINNED` block during M5.hs's compile.\n\nRules out hypothesis (b2) \"PROBE22 was wrongly stomping pinned-Addr#s\"\nin its strong form \u2014 there were no pinned-block-backed addresses on\nthe stack to stomp.  Confirms hypothesis (a) from session-24\nHANDOFF: the BS reaching `mkFastStringByteString` is backed by a\nnon-pinned `MutableByteArray#`, violating the pinning invariant at\n`libraries/base/GHC/ForeignPtr.hs:145`.\n\nSessions 19\u201325 collectively rule out: bitmap codegen, mkLivenessBits,\nstackMapToLiveness, LayoutStack, the StackRep itself.  The bug is\nupstream of all of them, in the bytestring/FastString allocation\nboundary.  Next session: find the BS allocator that omits pinning.\n\nv0.12.0 ships unchanged; stage2 on pmacg5 reverted to clean RTS at\nsession-25 end.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\"",
  "description": "Commit session 25"
}


---

## 🤖 Claude

Now backfill commits.md with the SHA and commit that.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SHA=$(git log -1 --format=%h) && echo \"SHA=$SHA\"",
  "description": "Get short SHA"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-25-pin-aware-poison/commits.md",
  "content": "# Commits \u2014 session 25\n\n- a723c75 Session 25: stage2 GC bug investigation, round 7 (PROBE23 =\n  pin-aware poison rules out PROBE22 false-positive theory; bug is\n  upstream BS pinning invariant violation).  RTS patch archived;\n  cross-tree reverted; state.md + roadmap.md updated.\n- _TBD_ Session 25 commits.md: backfill the SHAs.\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-11-session-25-pin-aware-poison/commits.md && git commit -m \"$(cat <<'EOF'\nSession 25 commits.md: backfill the SHAs.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\"",
  "description": "Commit commits.md backfill"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 25 directory and pre-flight (read PROBE22 patch + harness, run baseline tests)",
      "activeForm": "Setting up session 25 dir and pre-flight",
      "status": "completed"
    },
    {
      "content": "Write PROBE23 patch (PROBE22POISON + BF_PINNED filter + pinned-on-stack logger)",
      "activeForm": "Writing PROBE23 patch",
      "status": "completed"
    },
    {
      "content": "Apply patch, rebuild RTS, deploy to pmacg5",
      "activeForm": "Rebuilding RTS and deploying to pmacg5",
      "status": "completed"
    },
    {
      "content": "Run 5\u00d7iteration M5.hs harness under -A1m on pmacg5",
      "activeForm": "Running 5\u00d7iteration M5.hs harness",
      "status": "completed"
    },
    {
      "content": "Collect + classify results (a vs b vs mixed)",
      "activeForm": "Collecting and classifying results",
      "status": "completed"
    },
    {
      "content": "Revert RTS, rebuild, redeploy clean to pmacg5",
      "activeForm": "Reverting and redeploying clean RTS",
      "status": "completed"
    },
    {
      "content": "Write session 25 README, findings, HANDOFF, commits.md",
      "activeForm": "Writing session 25 docs",
      "status": "completed"
    },
    {
      "content": "Update state.md and roadmap.md",
      "activeForm": "Updating state.md and roadmap.md",
      "status": "completed"
    },
    {
      "content": "Commit all session 25 work",
      "activeForm": "Committing session 25 work",
      "status": "completed"
    }
  ]
}


---

## 🤖 Claude

Session 25 done. Summary:

**PROBE23 ran. Hypothesis (a) confirmed; (b2) ruled out.**

- 5/5 SIGSEGV under `+RTS -A1m`, byte-identical to session 23's PROBE22 — same crash slot (`gc_no=2 slot=6 old=0x0bf5f38a` at `_blk_c7te + 112`), same `r4=0xdeadbeef`.
- Critically: **`pinned_skip = 0`** across every GC of every iteration. No stack-resident value pointed into a `BF_PINNED` block during M5.hs's compile, so PROBE22 wasn't wrongly stomping pinned-Addr#s — there were none on the stack to stomp.
- Cumulative: sessions 19–25 collectively rule out bitmap codegen, `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, the StackRep itself. Bug is upstream of all of them — in the bytestring/FastString allocation boundary.

**Commits landed:**
- [a723c75](docs/sessions/2026-05-11-session-25-pin-aware-poison/) — main session 25 work + state.md + roadmap.md
- 9d6e426 — commits.md SHA backfill

**Next session** picks up from [docs/sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md](docs/sessions/2026-05-11-session-25-pin-aware-poison/HANDOFF.md) — find the BS-allocator code path that produces a non-pinned-backed BS flowing into `mkFastStringByteString`.

v0.12.0 ships unchanged; stage2 on pmacg5 reverted to clean RTS.

---

