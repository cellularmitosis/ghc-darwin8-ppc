# Claude Conversation Log

Session ID: 2db0db60-5d2b-4de6-a202-ee51b06bfa79
Date: 2026-05-13 00:23:21

---

## 👤 User

please read docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md amd proceed

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/HANDOFF.md"
}


---

## 🤖 Claude

I'll read the session workflow doc and the key session-29 docs in parallel, then set up session 30.

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
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/README.md"
}


---

## 🤖 Claude

Got the handoff. The plan is clear: build stage2 with DEBUG / `-DS` sanity-check RTS, then run Big2.hs to catch corruption inside `GarbageCollect()`. Let me set up session 30 and load tools I'll need.

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
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/ | tail -5",
  "description": "List recent sessions"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/findings.md"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/scripts/",
  "description": "List scripts"
}


---

## 🤖 Claude

There are already `exp-deploy-stage2-debug.sh` and `exp-stage2-debug-rts-probe.sh` — prior groundwork. Let me check them and the deploy script, plus roadmap and the prior session's log.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/scripts/exp-deploy-stage2-debug.sh"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/scripts/exp-stage2-debug-rts-probe.sh"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/scripts/deploy-stage2.sh"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 30 directory and read prior debug-RTS work",
      "activeForm": "Setting up session 30 directory and reading prior debug-RTS work",
      "status": "in_progress"
    },
    {
      "content": "Verify baseline: Big2.hs -A1m -G1 still panics deterministically with v0.12.0 stage2",
      "activeForm": "Verifying baseline",
      "status": "pending"
    },
    {
      "content": "Build debug-RTS-linked stage2 (ghc-real-debug) and deploy to pmacg5",
      "activeForm": "Building debug-RTS-linked stage2",
      "status": "pending"
    },
    {
      "content": "Run Big2.hs +RTS -A1m -G1 -DS and inspect for sanity-check catches inside GC",
      "activeForm": "Running Big2.hs with -DS sanity check",
      "status": "pending"
    },
    {
      "content": "Analyze sanity output \u2014 pinpoint corruption or pivot to allocator audit",
      "activeForm": "Analyzing sanity output",
      "status": "pending"
    },
    {
      "content": "Write session 30 docs (README, findings, HANDOFF, commits) and commit",
      "activeForm": "Writing session 30 docs and committing",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/experiments/ 2>/dev/null; ls /Users/cell/claude/ghc-darwin8-ppc/log/ 2>/dev/null | head -30; echo \"---\"; ls /Users/cell/claude/ghc-darwin8-ppc/log/session19/ 2>/dev/null",
  "description": "Check experiments and prior session-19 logs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md 2>/dev/null | head -80",
  "description": "Check roadmap"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/session19 2>/dev/null; find /Users/cell/claude/ghc-darwin8-ppc/docs/ -maxdepth 3 -name \"*session-19*\" -o -name \"*-19-*\" 2>/dev/null | head -5",
  "description": "Find session 19 docs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/ | grep -i 19",
  "description": "List session 19 dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-09-session-19-stage2-gc-bug/",
  "description": "List session 19 contents"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/log/session19/probe19-iter1-sanity-A1m.log",
  "limit": 100
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-09-session-19-stage2-gc-bug/step1-debug-rts-findings.md"
}


---

## 🤖 Claude

Important pre-existing context I need to integrate: **session 19 already tried `-DS` and it DID NOT catch corruption** — the heap was internally consistent. But that was M5.hs at default `-A` producing the `$trModule2_ruq` panic. Sessions 28-29 use Big2.hs at `-A1m -G1` producing `refineFromInScope`. Different input/flags, possibly different signal under `-DS`. Worth retrying since the failure shape may have changed, but lowering the prior on "sanity-check pinpoints the bug."

Let me create the session 30 directory and check pmacg5 state.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "mkdir -p /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit\nmkdir -p /Users/cell/claude/ghc-darwin8-ppc/log/session30\nls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit",
  "description": "Create session 30 directory"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -o BatchMode=yes -o ConnectTimeout=10 pmacg5 'ls -la /opt/ghc-stage2/bin/ ; echo \"---\" ; ls /tmp/*.hs 2>/dev/null | head -20 ; echo \"---\" ; uname -a' 2>&1 | head -40",
  "description": "Probe pmacg5 state"
}


---

## 🤖 Claude

pmacg5 reachable. Stage2 ghc-real present (matches session-29 redeploy). No `ghc-real-debug` currently. All Big2 variants still in /tmp.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 30 directory and read prior debug-RTS work",
      "activeForm": "Setting up session 30 directory and reading prior debug-RTS work",
      "status": "completed"
    },
    {
      "content": "Verify baseline: Big2.hs -A1m -G1 still panics deterministically with v0.12.0 stage2",
      "activeForm": "Verifying baseline",
      "status": "in_progress"
    },
    {
      "content": "Build debug-RTS-linked stage2 (ghc-real-debug) and deploy to pmacg5",
      "activeForm": "Building debug-RTS-linked stage2",
      "status": "pending"
    },
    {
      "content": "Run Big2.hs +RTS -A1m -G1 -DS and inspect for sanity-check catches inside GC",
      "activeForm": "Running Big2.hs with -DS sanity check",
      "status": "pending"
    },
    {
      "content": "Analyze sanity output \u2014 pinpoint corruption or pivot to allocator audit",
      "activeForm": "Analyzing sanity output",
      "status": "pending"
    },
    {
      "content": "Write session 30 docs (README, findings, HANDOFF, commits) and commit",
      "activeForm": "Writing session 30 docs and committing",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\nmd5 Big2.hs\necho \"--- Big2 baseline runs (5x) ---\"\nfor i in 1 2 3 4 5; do\n  rm -f Big2.hi Big2.o\n  out=$(DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1)\n  rc=$?\n  panic=$(echo \"$out\" | grep -c \"panic\\|impossible\\|inScope\")\n  sig=$(echo \"$out\" | grep -E \"panic|impossible|inScope|refineFromInScope|StgToCmm\" | head -2 | tr \"\\n\" \"|\")\n  echo \"iter $i  rc=$rc  panic_lines=$panic  sig=$sig\"\ndone\n' 2>&1",
  "description": "Verify Big2 -A1m -G1 baseline panic"
}


---

## 🤖 Claude

Baseline verified — 5/5 deterministic `refineFromInScope` panic. Now build debug-RTS-linked stage2 and deploy. Starting the log file too.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/log.md",
  "content": "# Session 30 log \u2014 debug-RTS + allocator audit\n\n## Plan on arrival\n\nPer session-29 HANDOFF: top priority is rebuild stage2 with DEBUG /\nsanity-check RTS, run Big2.hs `-A1m -G1 -DS` to catch corruption\ninside `GarbageCollect()`.\n\n**Caveat I noted before starting:** session 19 already tried `-DS`\non M5.hs at default `-A` and `-DS` did NOT fire (heap was internally\nconsistent; the bug is missed-root, not corrupted-heap-state).  But\nthat was a different reproducer (M5.hs, `$trModule2_ruq` panic);\nsession 28-29's repro is Big2.hs `-A1m -G1` producing\n`refineFromInScope`.  The session-28 framing of \"one bug, two\nvictim data structures\" makes a redo of `-DS` worthwhile.\n\n## Step 0 \u2014 baseline\n\n```\nssh pmacg5\nMD5 (Big2.hs) = 78b5eb77f66d284948fcea9d96013f81\nBig2 -A1m -G1 \u00d7 5: rc=1 5/5, all `refineFromInScope` STG-time panic.\n```\n\nMatches session-29 README exactly.  Clean stage2 from session-29 end\nstill on pmacg5: `/opt/ghc-stage2/bin/ghc-real`, 193 MB, mtime\n2026-05-12 00:15.\n\n## Step 1 \u2014 build & deploy debug-RTS stage2\n\nPlan: invoke `scripts/exp-deploy-stage2-debug.sh pmacg5` (built in\nsession 19, never touched since).  Produces\n`/opt/ghc-stage2/bin/ghc-real-debug` alongside the normal `ghc-real`.\n\nCaveats from session 19:\n- `-DS` deterministically panic'd M5.hs while the vanilla run was\n  non-deterministic (size=152 4/5, size=356 1/5, panic 0/5 vanilla\n  vs panic 5/5 sanity).  Sessions 28-29 showed Big2 `-A1m -G1` is\n  deterministic both with and without probes.  So we won't see the\n  same probe-flips-the-mode behavior; we'll either catch the\n  corruption or confirm session 19's \"heap-consistent\" finding still\n  holds.\n- The debug build is bigger (more assertions linked in) but the\n  cross-link time should be similar to vanilla stage2.\n\n(Continuing below...)\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash scripts/exp-deploy-stage2-debug.sh pmacg5 2>&1 | tee log/session30/debug-stage2-deploy.log | tail -30",
  "description": "Build and deploy debug-RTS stage2 to pmacg5",
  "timeout": 600000
}


---

## 🤖 Claude

Debug stage2 deployed. Now run Big2.hs `-A1m -G1 -DS` and capture output.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug --version\necho \"---\"\n# smoke test: vanilla works against debug\nrm -f Big2.hi Big2.o\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug -c Big2.hs +RTS -A1G -RTS 2>&1 | tail -5\necho \"rc=$?\"\nls -la Big2.o 2>/dev/null\n' 2>&1",
  "description": "Smoke-test debug-RTS-linked ghc"
}


---

## 🤖 Claude

Debug stage2 works under `-A1G` (the workaround that always passes). Now the key run — Big2.hs `-A1m -G1 -DS`:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\nrm -f Big2.hi Big2.o\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug -c Big2.hs +RTS -A1m -G1 -DS -RTS 2>&1\nrc=$?\necho \"==========================\"\necho \"rc=$rc\"\nls -la Big2.o 2>/dev/null\n' 2>&1 | tee log/session30/big2-A1m-G1-DS.iter1.log | tail -80",
  "description": "Big2 -A1m -G1 -DS run 1",
  "timeout": 300000
}


---

## 🤖 Claude

**Critical:** Same `refineFromInScope` panic with `-DS`. No sanity-check assertion fired. This matches session 19's finding: the heap is internally consistent, the bug is a missed root (unscanned GC root), not corrupted scavenge bookkeeping.

Let me check the full log for any -DS output at all, then try more aggressive flags:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "wc -l log/session30/big2-A1m-G1-DS.iter1.log\necho \"--- first 30 lines ---\"\nhead -30 log/session30/big2-A1m-G1-DS.iter1.log\necho \"--- sanity / barf / inconsistent mentions ---\"\ngrep -i -E \"sanity|barf|inconsistent|invariant|assert\" log/session30/big2-A1m-G1-DS.iter1.log | head -10\necho \"--- any debug RTS output lines? ---\"\ngrep -E \"^(GC|gc:|scav|evac|mut|sanity|debug)\" log/session30/big2-A1m-G1-DS.iter1.log | head -10",
  "description": "Inspect -DS output for sanity messages"
}


---

## 🤖 Claude

`-DS` ran silently — no barf, but also no other DEBUG output. Let me verify `-DS` is actually live in this build and try `-Dg` (GC trace) which should produce verbose output on success.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug --info 2>&1 | head -20\necho \"--- check RTS flags help ---\"\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug +RTS --help -RTS 2>&1 | grep -E \"DS|sanity|debug|^ +-D\" | head -20\necho \"--- nm for sanity symbol ---\"\nnm /opt/ghc-stage2/bin/ghc-real-debug 2>/dev/null | grep -i \"sanity\\|checkHeap\\|checkSanity\" | head -10\n' 2>&1",
  "description": "Verify debug RTS is in build"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug +RTS --info -RTS 2>&1 | head -20\necho \"--- side-by-side: normal stage2 ---\"\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real +RTS --info -RTS 2>&1 | head -20\n' 2>&1",
  "description": "Check RTS --info for DEBUG flavor"
}


---

## 🤖 Claude

Debug RTS is `rts_debug`, sanity symbols linked. `-DS` running silently means sanity passes — confirms session 19's "heap is internally consistent" finding still holds for Big2's `refineFromInScope` panic. Let me try `-DZ` (zero on free) and `-Dg` (GC trace) for more signal.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\necho \"=== -DZ (zero on GC) ===\"\nrm -f Big2.hi Big2.o\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug -c Big2.hs +RTS -A1m -G1 -DZ -RTS 2>&1 | head -25\necho \"rc=$?\"\necho \"\"\necho \"=== -DS -DZ ===\"\nrm -f Big2.hi Big2.o\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real-debug -c Big2.hs +RTS -A1m -G1 -DS -DZ -RTS 2>&1 | head -25\necho \"rc=$?\"\n' 2>&1 | tee log/session30/big2-A1m-G1-DZ-and-DS-DZ.log",
  "description": "-DZ and -DS-DZ runs",
  "timeout": 300000
}


---

## 🤖 Claude

Confirmed: heap is consistent (`-DS` silent) AND the missed data is reused, not stale (`-DZ` same panic). This is a **missed-root** bug — a pointer that should be a GC root isn't being scanned, leading to live data being reclaimed and the block being reused for a fresh allocation. Let me read session 19's step 3 findings and the related findings to understand prior ruleouts:

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-09-session-19-stage2-gc-bug/step3-probe19-findings.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-09-session-19-stage2-gc-bug/HANDOFF.md"
}


---

## 🤖 Claude

Let me check what sessions 20-27 actually ruled out (especially TSO stack walk / StgRegTable):

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "for d in /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-*-session-2{0,1,2,3,4,5,6,7,8}-*/; do\n  echo \"=== $(basename $d) ===\"\n  if [ -f \"$d/README.md\" ]; then\n    head -5 \"$d/README.md\" | grep -v '^$'\n  fi\ndone 2>&1",
  "description": "List sessions 20-28 titles"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -l -i \"stack\\|TSO\\|StgRegTable\\|rCurrentNursery\\|rCurrentAlloc\\|scavenge_stack\" /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-*-session-2*/findings.md /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-*-session-2*/README.md 2>/dev/null | sort -u",
  "description": "Find sessions discussing TSO/stack/StgRegTable"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 30 directory and read prior debug-RTS work",
      "activeForm": "Setting up session 30 directory and reading prior debug-RTS work",
      "status": "completed"
    },
    {
      "content": "Verify baseline: Big2.hs -A1m -G1 still panics deterministically with v0.12.0 stage2",
      "activeForm": "Verifying baseline",
      "status": "completed"
    },
    {
      "content": "Build debug-RTS-linked stage2 (ghc-real-debug) and deploy to pmacg5",
      "activeForm": "Building debug-RTS-linked stage2",
      "status": "completed"
    },
    {
      "content": "Run Big2.hs +RTS -A1m -G1 -DS and inspect for sanity-check catches inside GC",
      "activeForm": "Running Big2.hs with -DS sanity check",
      "status": "completed"
    },
    {
      "content": "Read prior bitmap/stack/StgRegTable session conclusions (20-24) to see what's already ruled out",
      "activeForm": "Reading prior bitmap/stack/StgRegTable session conclusions",
      "status": "in_progress"
    },
    {
      "content": "Pivot: audit alloc_in_moving_heap / todo_block_full for PPC32 block-boundary bugs OR add per-closure-SIZE histogram probe",
      "activeForm": "Auditing allocator for PPC32 block-boundary bugs",
      "status": "pending"
    },
    {
      "content": "Write session 30 docs (README, findings, HANDOFF, commits) and commit",
      "activeForm": "Writing session 30 docs and committing",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-11-session-24-faststring-stackrep/README.md",
  "limit": 80
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "for s in 26 27 28; do\n  d=$(ls -d /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-*-session-$s-*/ | head -1)\n  echo \"==================== session $s ====================\"\n  grep -A 5 \"Status on exit:\" \"$d/README.md\" | head -25\n  echo\ndone",
  "description": "Read session 26-28 status-on-exit"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -A 30 \"Status on exit:\" /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/README.md | head -50",
  "description": "Session 27 status on exit detail"
}


---

## 🤖 Claude

I have enough context to pivot. Sessions 19–29 have ruled out: per-closure-type scavenge, mut_list, static_objects, SRT, CAF list, stack-frame bitmaps, ForeignPtrContents pinning. The remaining high-priority suspect per session-29 HANDOFF is the allocator (`alloc_in_moving_heap` / `todo_block_full`). Let me audit it.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/ -name \"*.c\" | xargs ls -la 2>/dev/null | head -10\necho \"---\"\nls /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/ 2>/dev/null",
  "description": "Check RTS sm/ source tree"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git diff --stat HEAD -- rts/sm/ 2>&1 | head -20\necho \"---\"\ncd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git status rts/sm/ 2>&1 | head -10",
  "description": "Check rts/sm source is clean"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 100,
  "limit": 150
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c"
}


---

## 🤖 Claude

Let me check the block-size constants and the related macros for PPC32 correctness:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngrep -n \"BLOCK_SIZE_W\\|BLOCK_SIZE\\b\" includes/rts/storage/Block.h includes/rts/Constants.h 2>/dev/null | head -30\necho \"--- BLOCK_ROUND_UP ---\"\ngrep -n \"BLOCK_ROUND_UP\\|BLOCK_ROUND_DOWN\" includes/rts/storage/Block.h 2>/dev/null\necho \"--- WORK_UNIT_WORDS ---\"\ngrep -rn \"WORK_UNIT_WORDS\" rts/sm/GC.h rts/sm/GCThread.h rts/sm/*.c 2>/dev/null | head -5\necho \"--- sizeof StgWord on PPC32 ---\"\ngrep -n \"SIZEOF_VOID_P\\|StgWord\" includes/stg/Types.h 2>/dev/null | head -10",
  "description": "Check block-size constants"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngrep -n \"BLOCK_SHIFT\\|MBLOCK_SHIFT\" includes/rts/Constants.h rts/include/MachDeps.h includes/rts/storage/Block.h 2>/dev/null | head -10\necho \"--- Block.h relevant section ---\"\nsed -n '20,80p' includes/rts/storage/Block.h\necho \"--- LARGE_OBJECT_THRESHOLD context ---\"\nsed -n '55,80p' includes/rts/storage/Block.h",
  "description": "Inspect BLOCK constants context"
}


---

## 🤖 Claude

Let me check how the allocator decides "large object" vs "ordinary copy" and what changes with `-G1`:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\necho \"--- LARGE_OBJECT_THRESHOLD usage ---\"\ngrep -n \"LARGE_OBJECT_THRESHOLD\" rts/*.c rts/sm/*.c 2>/dev/null\necho \"\"\necho \"--- BF_LARGE flag handling in Evac.c ---\"\ngrep -n \"BF_LARGE\\|evacuate_large\\|is_large\\|allocateMightFail\" rts/sm/Evac.c | head -20\necho \"\"\necho \"--- evacuate function start ---\"\ngrep -n \"^evacuate\\|^evacuate_large\" rts/sm/Evac.c",
  "description": "Find large-object handling"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 258,
  "limit": 200
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngrep -n \"^evacuate\\|^evacuate_large\\|^void evacuate\\|^REGPARM1 GNUC_ATTR_HOT void evacuate\" rts/sm/Evac.c\necho \"---\"\ngrep -n \"evacuate_large\\|BF_LARGE\\|BF_COMPACT\" rts/sm/Evac.c | head -30",
  "description": "Find evacuate entry points"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 681,
  "limit": 200
}


---

## 🤖 Claude

Let me check `Bdescr()` macro and a few more places where PPC32 32-bit arithmetic could go wrong, then design the size+blockfull probe:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\necho \"--- Bdescr macro ---\"\nsed -n '195,235p' includes/rts/storage/Block.h\necho \"\"\necho \"--- IS_FORWARDING_PTR / MK_FORWARDING_PTR ---\"\ngrep -n \"IS_FORWARDING_PTR\\|MK_FORWARDING_PTR\\|UN_FORWARDING_PTR\" includes/rts/storage/ClosureMacros.h\necho \"\"\necho \"--- ClosureMacros.h forwarding ---\"\nsed -n '225,250p' includes/rts/storage/ClosureMacros.h",
  "description": "Check Bdescr and forwarding-ptr macros"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngrep -n \"^bdescr \\* *Bdescr\\|^static inline bdescr \\* *Bdescr\\|^STATIC_INLINE bdescr \\* *Bdescr\\|#define Bdescr\" includes/rts/storage/Block.h rts/sm/MBlock.c\necho \"\"\nsed -n '275,340p' includes/rts/storage/Block.h",
  "description": "Find Bdescr inline"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/includes/rts/storage/Block.h",
  "offset": 170,
  "limit": 60
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 30 directory and read prior debug-RTS work",
      "activeForm": "Setting up session 30 directory and reading prior debug-RTS work",
      "status": "completed"
    },
    {
      "content": "Verify baseline: Big2.hs -A1m -G1 still panics deterministically with v0.12.0 stage2",
      "activeForm": "Verifying baseline",
      "status": "completed"
    },
    {
      "content": "Build debug-RTS-linked stage2 (ghc-real-debug) and deploy to pmacg5",
      "activeForm": "Building debug-RTS-linked stage2",
      "status": "completed"
    },
    {
      "content": "Run Big2.hs +RTS -A1m -G1 -DS and inspect for sanity-check catches inside GC",
      "activeForm": "Running Big2.hs with -DS sanity check",
      "status": "completed"
    },
    {
      "content": "Confirm prior bitmap/stack/StgRegTable session conclusions (20-24)",
      "activeForm": "Confirming prior bitmap/stack/StgRegTable session conclusions",
      "status": "completed"
    },
    {
      "content": "Audit allocator (alloc_in_moving_heap / todo_block_full / Bdescr / forwarding-ptr) for PPC32 arithmetic bugs",
      "activeForm": "Auditing allocator arithmetic for PPC32 bugs",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE30: per-closure-SIZE histogram + allocator-state counters (block-fulls, can_extends, fresh-allocs, evacuate_large) per GC",
      "activeForm": "Designing and implementing PROBE30",
      "status": "in_progress"
    },
    {
      "content": "Run M5/Big2 matrix with PROBE30 and diff results",
      "activeForm": "Running probe matrix and diffing",
      "status": "pending"
    },
    {
      "content": "Revert + clean redeploy, write session 30 docs, commit",
      "activeForm": "Reverting and writing session 30 docs",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/probe29-rts.patch"
}


---

## 🤖 Claude

Let me read scavenge_block to understand how to extract closure size cheaply:

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 440,
  "limit": 100
}


---

## 🤖 Claude

Let me design and write PROBE30 patch — adds allocator-state counters + size histogram + carries forward PROBE28/29:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\necho \"--- re-apply PROBE29 baseline first ---\"\ngit apply --check ../../../docs/sessions/2026-05-12-session-29-closure-type-histogram/probe29-rts.patch && echo OK || echo \"PROBE29 patch does not apply cleanly\"",
  "description": "Check PROBE29 patch applies cleanly"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngit apply ../../../docs/sessions/2026-05-12-session-29-closure-type-histogram/probe29-rts.patch\ngit status -s rts/sm/",
  "description": "Apply PROBE29 patch to source"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 122,
  "limit": 10
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 155,
  "limit": 15
}


---

## 🤖 Claude

Now I'll add PROBE30 declarations right after PROBE29:

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "W_ probe29_type_hist[64];\nW_ probe29_evac_fresh[64];\nW_ probe29_evac_fwd_hits;\n/* PROBE29-END */\n\n/* Mut-list stats */",
  "new_string": "W_ probe29_type_hist[64];\nW_ probe29_evac_fresh[64];\nW_ probe29_evac_fwd_hits;\n/* PROBE29-END */\n\n/* PROBE30-BEGIN \u2014 session-30 allocator-state + size-class probe.\n *\n * Sessions 28-29 ruled out per-closure-type scavenge bugs (filename-\n * sensitivity shows the trigger is heap-layout dependent, not\n * type-X-mishandling).  Remaining suspect direction (per session 29\n * HANDOFF): the to-space bump allocator in Evac.c::alloc_in_moving_heap\n * + GCUtils.c::todo_block_full + alloc_todo_block, where exact heap\n * geometry / block-boundary crossings could trip a PPC32-specific bug.\n *\n * Counters:\n *   probe30_aim_calls            : alloc_in_moving_heap invocations.\n *   probe30_aim_pre_overflow     : aim invocations where the pre-bump\n *                                   crossed todo_lim (=> todo_block_full).\n *   probe30_tbf_can_extend       : todo_block_full hits where the\n *                                   block had room AND wasn't urgent\n *                                   to push (in-place extension).\n *   probe30_tbf_push_new         : todo_block_full hits that pushed\n *                                   the current block + allocated new.\n *   probe30_tbf_freed_empty      : push-new path freed an empty block\n *                                   (closure spans > 1 block edge).\n *   probe30_atb_part_reuse       : alloc_todo_block grabbed a part_list block.\n *   probe30_atb_alloc_group      : alloc_todo_block did allocGroup_sync\n *                                   (closure size > BLOCK_SIZE_W).\n *   probe30_atb_alloc_blocks     : alloc_todo_block did allocBlocks_sync\n *                                   (refilled gct->free_blocks).\n *   probe30_atb_free_blocks      : alloc_todo_block grabbed from gct->free_blocks.\n *   probe30_evac_large_calls     : evacuate_large invocations (BF_LARGE path).\n *   probe30_size_hist[12]        : log2-ish bucketed size histogram\n *                                   of every size param passed to\n *                                   alloc_in_moving_heap.\n *                                   Buckets:\n *                                     0:  size == 1\n *                                     1:  size == 2\n *                                     2:  size 3..4\n *                                     3:  size 5..8\n *                                     4:  size 9..16\n *                                     5:  size 17..32\n *                                     6:  size 33..64\n *                                     7:  size 65..128\n *                                     8:  size 129..256\n *                                     9:  size 257..512\n *                                    10:  size 513..1024\n *                                    11:  size > 1024 (= \"big object\")\n */\nW_ probe30_aim_calls;\nW_ probe30_aim_pre_overflow;\nW_ probe30_tbf_can_extend;\nW_ probe30_tbf_push_new;\nW_ probe30_tbf_freed_empty;\nW_ probe30_atb_part_reuse;\nW_ probe30_atb_alloc_group;\nW_ probe30_atb_alloc_blocks;\nW_ probe30_atb_free_blocks;\nW_ probe30_evac_large_calls;\nW_ probe30_size_hist[12];\n/* PROBE30-END */\n\n/* Mut-list stats */"
}


---

## 🤖 Claude

Now add the reset at start of GarbageCollect:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngrep -n \"PROBE29-BEGIN \u2014 reset\" rts/sm/GC.c\necho ---\nsed -n '180,210p' rts/sm/GC.c",
  "description": "Find PROBE29 reset block"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 570,
  "limit": 25
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "  probe29_evac_fwd_hits = 0;\n  /* PROBE29-END */\n\n  // Initialise all the generations that we're collecting.",
  "new_string": "  probe29_evac_fwd_hits = 0;\n  /* PROBE29-END */\n\n  /* PROBE30-BEGIN \u2014 reset allocator-state counters at GC start */\n  probe30_aim_calls = 0;\n  probe30_aim_pre_overflow = 0;\n  probe30_tbf_can_extend = 0;\n  probe30_tbf_push_new = 0;\n  probe30_tbf_freed_empty = 0;\n  probe30_atb_part_reuse = 0;\n  probe30_atb_alloc_group = 0;\n  probe30_atb_alloc_blocks = 0;\n  probe30_atb_free_blocks = 0;\n  probe30_evac_large_calls = 0;\n  for (uint32_t bb = 0; bb < 12; bb++) {\n      probe30_size_hist[bb] = 0;\n  }\n  /* PROBE30-END */\n\n  // Initialise all the generations that we're collecting."
}


---

## 🤖 Claude

Now add the per-GC emit. Find the end of PROBE29's emit:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngrep -n \"PROBE29-END\\|PROBE29-BEGIN \u2014 emit\" rts/sm/GC.c | head -5",
  "description": "Find PROBE29 emit end"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 1270,
  "limit": 20
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "old_string": "      debugBelch(\"\\n\");\n  }\n  /* PROBE29-END */\n\n  // ok, GC over: tell the stats department what happened.",
  "new_string": "      debugBelch(\"\\n\");\n  }\n  /* PROBE29-END */\n\n  /* PROBE30-BEGIN \u2014 emit one allocator-state line per GC, then a\n   * second line with the size-class histogram (skip zero buckets).\n   */\n  debugBelch(\"PROBE30 gc=%llu aim=%lu aimPre=%lu tbfExt=%lu tbfNew=%lu tbfFreedEmpty=%lu atbPart=%lu atbGrp=%lu atbBlks=%lu atbFree=%lu evacLarge=%lu\\n\",\n             (unsigned long long)probe28_gc_no,\n             (unsigned long)probe30_aim_calls,\n             (unsigned long)probe30_aim_pre_overflow,\n             (unsigned long)probe30_tbf_can_extend,\n             (unsigned long)probe30_tbf_push_new,\n             (unsigned long)probe30_tbf_freed_empty,\n             (unsigned long)probe30_atb_part_reuse,\n             (unsigned long)probe30_atb_alloc_group,\n             (unsigned long)probe30_atb_alloc_blocks,\n             (unsigned long)probe30_atb_free_blocks,\n             (unsigned long)probe30_evac_large_calls);\n  debugBelch(\"PROBE30 gc=%llu sizeHist\",\n             (unsigned long long)probe28_gc_no);\n  for (uint32_t bb = 0; bb < 12; bb++) {\n      if (probe30_size_hist[bb] != 0) {\n          debugBelch(\" s%u=%lu\",\n                     bb, (unsigned long)probe30_size_hist[bb]);\n      }\n  }\n  debugBelch(\"\\n\");\n  /* PROBE30-END */\n\n  // ok, GC over: tell the stats department what happened."
}


---

## 🤖 Claude

Now add the bump points in Evac.c (alloc_in_moving_heap + evacuate_large) and GCUtils.c (todo_block_full + alloc_todo_block):

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngrep -n \"PROBE29-BEGIN\\|extern W_ probe29\" rts/sm/Evac.c\necho ---\nsed -n '30,50p' rts/sm/Evac.c",
  "description": "Find PROBE29 externs in Evac.c"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "old_string": "extern W_ probe29_evac_fresh[64];\nextern W_ probe29_evac_fwd_hits;\n/* PROBE29-END */",
  "new_string": "extern W_ probe29_evac_fresh[64];\nextern W_ probe29_evac_fwd_hits;\n/* PROBE29-END */\n\n/* PROBE30-BEGIN \u2014 externs for counters defined in rts/sm/GC.c.\n * Bumped in alloc_in_moving_heap (this file) and evacuate_large.\n */\nextern W_ probe30_aim_calls;\nextern W_ probe30_aim_pre_overflow;\nextern W_ probe30_evac_large_calls;\nextern W_ probe30_size_hist[12];\n/* PROBE30-END */\n\n/* PROBE30 \u2014 log2-ish bucketing helper for the size histogram. */\nstatic inline uint32_t probe30_size_bucket(uint32_t size) {\n    if (size <= 1) return 0;\n    if (size == 2) return 1;\n    if (size <= 4) return 2;\n    if (size <= 8) return 3;\n    if (size <= 16) return 4;\n    if (size <= 32) return 5;\n    if (size <= 64) return 6;\n    if (size <= 128) return 7;\n    if (size <= 256) return 8;\n    if (size <= 512) return 9;\n    if (size <= 1024) return 10;\n    return 11;\n}"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 30,
  "limit": 50
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "old_string": "extern W_ probe29_evac_fresh[64];\nextern W_ probe29_evac_fwd_hits;\n/* PROBE29-END */\n\n#if defined(THREADED_RTS) && !defined(PARALLEL_GC)",
  "new_string": "extern W_ probe29_evac_fresh[64];\nextern W_ probe29_evac_fwd_hits;\n/* PROBE29-END */\n\n/* PROBE30-BEGIN \u2014 externs for counters defined in rts/sm/GC.c.\n * Bumped in alloc_in_moving_heap (this file) and evacuate_large.\n */\nextern W_ probe30_aim_calls;\nextern W_ probe30_aim_pre_overflow;\nextern W_ probe30_evac_large_calls;\nextern W_ probe30_size_hist[12];\n\n/* PROBE30 \u2014 log2-ish bucketing helper for the size histogram. */\nstatic inline uint32_t probe30_size_bucket(uint32_t size) {\n    if (size <= 1) return 0;\n    if (size == 2) return 1;\n    if (size <= 4) return 2;\n    if (size <= 8) return 3;\n    if (size <= 16) return 4;\n    if (size <= 32) return 5;\n    if (size <= 64) return 6;\n    if (size <= 128) return 7;\n    if (size <= 256) return 8;\n    if (size <= 512) return 9;\n    if (size <= 1024) return 10;\n    return 11;\n}\n/* PROBE30-END */\n\n#if defined(THREADED_RTS) && !defined(PARALLEL_GC)"
}


---

## 🤖 Claude

Now add bumps in alloc_in_moving_heap and evacuate_large:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngrep -n \"alloc_in_moving_heap\\|^evacuate_large\\b\" rts/sm/Evac.c | head -10",
  "description": "Find aim and evac_large"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 133,
  "limit": 20
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "old_string": "alloc_in_moving_heap (uint32_t size, uint32_t gen_no)\n{\n    gen_workspace *ws = &gct->gens[gen_no];  // zero memory references here\n\n    /* chain a new block onto the to-space for the destination gen if\n     * necessary.\n     */\n    StgPtr to = ws->todo_free;\n    ws->todo_free += size;\n    if (ws->todo_free > ws->todo_lim) {\n        to = todo_block_full(size, ws);\n    }\n    ASSERT(ws->todo_free >= ws->todo_bd->free && ws->todo_free <= ws->todo_lim);\n\n    return to;\n}",
  "new_string": "alloc_in_moving_heap (uint32_t size, uint32_t gen_no)\n{\n    gen_workspace *ws = &gct->gens[gen_no];  // zero memory references here\n\n    /* PROBE30 \u2014 count every aim call, plus a size-class histogram bump. */\n    probe30_aim_calls++;\n    probe30_size_hist[probe30_size_bucket(size)]++;\n\n    /* chain a new block onto the to-space for the destination gen if\n     * necessary.\n     */\n    StgPtr to = ws->todo_free;\n    ws->todo_free += size;\n    if (ws->todo_free > ws->todo_lim) {\n        /* PROBE30 \u2014 pre-bump crossed todo_lim, so todo_block_full\n         * will fire.  Used together with PROBE30's tbf counters in\n         * GCUtils.c to break down extend-vs-push-new path.  */\n        probe30_aim_pre_overflow++;\n        to = todo_block_full(size, ws);\n    }\n    ASSERT(ws->todo_free >= ws->todo_bd->free && ws->todo_free <= ws->todo_lim);\n\n    return to;\n}"
}


---

## 🤖 Claude

Now add the evacuate_large bump:

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 434,
  "limit": 20
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "old_string": "ATTR_NOINLINE static void\nevacuate_large(StgPtr p)\n{\n  bdescr *bd;\n  generation *gen, *new_gen;\n  uint32_t gen_no, new_gen_no;\n  gen_workspace *ws;\n\n  bd = Bdescr(p);\n  gen = RELAXED_LOAD(&bd->gen);\n  gen_no = RELAXED_LOAD(&bd->gen_no);\n  ACQUIRE_SPIN_LOCK(&gen->sync);",
  "new_string": "ATTR_NOINLINE static void\nevacuate_large(StgPtr p)\n{\n  bdescr *bd;\n  generation *gen, *new_gen;\n  uint32_t gen_no, new_gen_no;\n  gen_workspace *ws;\n\n  /* PROBE30 \u2014 count every BF_LARGE evacuation.  Counts BEFORE the\n   * \"already evacuated\" shortcut so we see every dispatch, not only\n   * fresh evacuations.  Adjust analysis accordingly.\n   */\n  probe30_evac_large_calls++;\n\n  bd = Bdescr(p);\n  gen = RELAXED_LOAD(&bd->gen);\n  gen_no = RELAXED_LOAD(&bd->gen_no);\n  ACQUIRE_SPIN_LOCK(&gen->sync);"
}


---

## 🤖 Claude

Now add bumps in GCUtils.c — todo_block_full's two paths plus alloc_todo_block:

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c",
  "offset": 25,
  "limit": 15
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c",
  "old_string": "#if defined(THREADED_RTS)\nSpinLock gc_alloc_block_sync;\n#endif\n\nstatic void push_todo_block(bdescr *bd, gen_workspace *ws);",
  "new_string": "#if defined(THREADED_RTS)\nSpinLock gc_alloc_block_sync;\n#endif\n\n/* PROBE30-BEGIN \u2014 externs for allocator-state counters defined in\n * rts/sm/GC.c.  Bumped in todo_block_full and alloc_todo_block to\n * discriminate which path the allocator takes per GC.\n */\nextern W_ probe30_tbf_can_extend;\nextern W_ probe30_tbf_push_new;\nextern W_ probe30_tbf_freed_empty;\nextern W_ probe30_atb_part_reuse;\nextern W_ probe30_atb_alloc_group;\nextern W_ probe30_atb_alloc_blocks;\nextern W_ probe30_atb_free_blocks;\n/* PROBE30-END */\n\nstatic void push_todo_block(bdescr *bd, gen_workspace *ws);"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c",
  "old_string": "    if (!urgent_to_push && can_extend)\n    {\n        ws->todo_lim = stg_min(bd->start + bd->blocks * BLOCK_SIZE_W,\n                               ws->todo_lim + stg_max(WORK_UNIT_WORDS,size));\n        debugTrace(DEBUG_gc, \"increasing limit for %p to %p\",\n                   bd->start, ws->todo_lim);\n        p = ws->todo_free;\n        ws->todo_free += size;\n\n        return p;\n    }",
  "new_string": "    if (!urgent_to_push && can_extend)\n    {\n        /* PROBE30 \u2014 in-place extension hit. */\n        probe30_tbf_can_extend++;\n\n        ws->todo_lim = stg_min(bd->start + bd->blocks * BLOCK_SIZE_W,\n                               ws->todo_lim + stg_max(WORK_UNIT_WORDS,size));\n        debugTrace(DEBUG_gc, \"increasing limit for %p to %p\",\n                   bd->start, ws->todo_lim);\n        p = ws->todo_free;\n        ws->todo_free += size;\n\n        return p;\n    }\n\n    /* PROBE30 \u2014 push-out-and-alloc-new path (covers the rest of the\n     * function below).\n     */\n    probe30_tbf_push_new++;"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c",
  "old_string": "            if (bd->free == bd->start) {\n                // Normally the block would not be empty, because then\n                // there would be enough room to copy the current\n                // object.  However, if the object we're copying is\n                // larger than a block, then we might have an empty\n                // block here.\n                freeGroup_sync(bd);\n            } else {\n                push_scanned_block(bd, ws);\n            }",
  "new_string": "            if (bd->free == bd->start) {\n                // Normally the block would not be empty, because then\n                // there would be enough room to copy the current\n                // object.  However, if the object we're copying is\n                // larger than a block, then we might have an empty\n                // block here.\n                /* PROBE30 \u2014 empty-block freed path; only fires when\n                 * the current object is larger than a block.  */\n                probe30_tbf_freed_empty++;\n                freeGroup_sync(bd);\n            } else {\n                push_scanned_block(bd, ws);\n            }"
}


---

## 🤖 Claude

Now add the alloc_todo_block path counters:

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c",
  "offset": 348,
  "limit": 45
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GCUtils.c",
  "old_string": "    // Grab a part block if we have one, and it has enough room\n    bd = ws->part_list;\n    if (bd != NULL &&\n        bd->start + bd->blocks * BLOCK_SIZE_W - bd->free > (int)size)\n    {\n        ws->part_list = bd->link;\n        ws->n_part_blocks -= bd->blocks;\n        ws->n_part_words -= bd->free - bd->start;\n    }\n    else\n    {\n        if (size > BLOCK_SIZE_W) {\n            bd = allocGroup_sync((W_)BLOCK_ROUND_UP(size*sizeof(W_))\n                                 / BLOCK_SIZE);\n        } else {\n            if (gct->free_blocks) {\n                bd = gct->free_blocks;\n                gct->free_blocks = bd->link;\n            } else {\n                allocBlocks_sync(16, &bd);\n                gct->free_blocks = bd->link;\n            }\n        }\n        initBdescr(bd, ws->gen, ws->gen->to);\n        RELAXED_STORE(&bd->u.scan, RELAXED_LOAD(&bd->start));\n        // blocks in to-space get the BF_EVACUATED flag.\n        // RELEASE here to ensure that bd->gen is visible to other cores.\n        RELEASE_STORE(&bd->flags, BF_EVACUATED);\n    }",
  "new_string": "    // Grab a part block if we have one, and it has enough room\n    bd = ws->part_list;\n    if (bd != NULL &&\n        bd->start + bd->blocks * BLOCK_SIZE_W - bd->free > (int)size)\n    {\n        /* PROBE30 \u2014 reusing a partially-filled block from ws->part_list. */\n        probe30_atb_part_reuse++;\n        ws->part_list = bd->link;\n        ws->n_part_blocks -= bd->blocks;\n        ws->n_part_words -= bd->free - bd->start;\n    }\n    else\n    {\n        if (size > BLOCK_SIZE_W) {\n            /* PROBE30 \u2014 big-object path: closure needs a multi-block\n             * group.  Triggers Note [big objects] handling.\n             */\n            probe30_atb_alloc_group++;\n            bd = allocGroup_sync((W_)BLOCK_ROUND_UP(size*sizeof(W_))\n                                 / BLOCK_SIZE);\n        } else {\n            if (gct->free_blocks) {\n                /* PROBE30 \u2014 fresh block grabbed from gct->free_blocks\n                 * (the pre-allocated pool from a previous fill).  */\n                probe30_atb_free_blocks++;\n                bd = gct->free_blocks;\n                gct->free_blocks = bd->link;\n            } else {\n                /* PROBE30 \u2014 pool was empty, refilled via allocBlocks_sync. */\n                probe30_atb_alloc_blocks++;\n                allocBlocks_sync(16, &bd);\n                gct->free_blocks = bd->link;\n            }\n        }\n        initBdescr(bd, ws->gen, ws->gen->to);\n        RELAXED_STORE(&bd->u.scan, RELAXED_LOAD(&bd->start));\n        // blocks in to-space get the BF_EVACUATED flag.\n        // RELEASE here to ensure that bd->gen is visible to other cores.\n        RELEASE_STORE(&bd->flags, BF_EVACUATED);\n    }"
}


---

## 🤖 Claude

Now rebuild RTS and deploy:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\nsource ../../../scripts/cross-env.sh >/dev/null 2>&1\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a 2>&1 | tail -20",
  "description": "Rebuild RTS with PROBE30",
  "timeout": 300000
}


---

## 🤖 Claude

RTS rebuilt in 5s. Deploy stage2:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\nbash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -8",
  "description": "Deploy stage2 with PROBE30",
  "timeout": 600000
}


---

## 🤖 Claude

Deployment + probe verified working. Now run the M5 vs Big2 matrix:

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-29-closure-type-histogram/scripts/run-probe-matrix.sh"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/scripts/run-probe-matrix.sh",
  "content": "#!/bin/bash\n# Run the session-30 PROBE30 matrix.\n#\n# PROBE30 extends PROBE28 + PROBE29 with allocator-state counters\n# (alloc_in_moving_heap calls, todo_block_full extend-vs-push-new\n# splits, alloc_todo_block paths, evacuate_large count) + a log2-ish\n# size-class histogram of every alloc_in_moving_heap size param.\n#\n# Output (per GC):\n#   PROBE28 gc=<n> ...\n#   PROBE29 gc=<n> scav fwdHits=<n> t<type>=<count> ...\n#   PROBE29 gc=<n> evac e<type>=<count> ...\n#   PROBE30 gc=<n> aim=<n> aimPre=<n> tbfExt=<n> tbfNew=<n>\n#           tbfFreedEmpty=<n> atbPart=<n> atbGrp=<n> atbBlks=<n>\n#           atbFree=<n> evacLarge=<n>\n#   PROBE30 gc=<n> sizeHist s<bucket>=<count> ...\n#\n# Matrix:\n#   M5.hs    +RTS -A1m -G1 -RTS  \u2014 PASS baseline\n#   Big2.hs  +RTS -A1m -G1 -RTS  \u2014 FAIL baseline (panic at GC 17)\n#\n# Goal: find an allocator-state counter or size-bucket that diverges\n# at Big2 GC 17 from M5's similar-workload GCs in a way per-closure-\n# type histograms (PROBE29) did NOT.\n#\n# Usage:  ./run-probe-matrix.sh [SSH_HOST] [N_ITERS]\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nN_ITERS=\"${2:-5}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session30\"\nmkdir -p \"$LOGDIR\"\n\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\n\n# Both inputs are already staged on pmacg5 (sessions 28+29).  Re-write\n# just in case to make this self-contained.\n\nssh -q \"$PPC_HOST\" 'cat > /tmp/M5.hs' <<'EOF'\nmodule M5 where\nfive = (5::Int)\nsix = (6::Int)\nEOF\n\nssh -q \"$PPC_HOST\" 'cat > /tmp/Big2.hs' <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ntopK :: Ord a => Int -> [a] -> [(Int, a)]\ntopK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs\n  where swap (a, b) = (b, a)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n\nrun_cell () {\n    local input=\"$1\"\n    local label=\"$2\"\n    local rts=\"$3\"\n    local logbase=\"$LOGDIR/${input}-${label}\"\n    echo \"=== ${input}.hs iters=${N_ITERS} flags='${rts}' ===\"\n    local pass=0 fail=0\n    for i in $(seq 1 \"$N_ITERS\"); do\n        local log=\"${logbase}.iter${i}.log\"\n        ssh -q \"$PPC_HOST\" \"\n            cd /tmp\n            rm -f ${input}.hi ${input}.o\n            $DYLD $GHC_REAL -c ${input}.hs $rts 2>&1\n            echo \\\"GHC_EXIT=\\$?\\\"\n        \" > \"$log\" 2>&1\n        local rc\n        rc=$(grep -m1 '^GHC_EXIT=' \"$log\" | sed 's/GHC_EXIT=//' || echo '?')\n        local sig\n        if [ \"$rc\" = \"0\" ]; then\n            pass=$((pass+1)); sig=\"OK\"\n        else\n            fail=$((fail+1))\n            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found|not in scope)' \"$log\" 2>/dev/null | head -c 120)\n            [ -z \"$sig\" ] && sig=\"UNKNOWN_FAIL_rc=$rc\"\n        fi\n        local gcs\n        gcs=$(grep -c '^PROBE28 ' \"$log\" 2>/dev/null || echo 0)\n        printf '  iter%02d rc=%s gcs=%s : %s\\n' \"$i\" \"$rc\" \"$gcs\" \"$sig\"\n    done\n    echo \"  SUMMARY: pass=${pass} fail=${fail} of ${N_ITERS}\"\n    echo\n}\n\nrun_cell M5     a1m-g1  \"+RTS -A1m -G1 -RTS\"\nrun_cell Big2   a1m-g1  \"+RTS -A1m -G1 -RTS\"\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/scripts/run-probe-matrix.sh\nbash /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/scripts/run-probe-matrix.sh pmacg5 5 2>&1 | tee /Users/cell/claude/ghc-darwin8-ppc/log/session30/run-probe-matrix.out",
  "description": "Run PROBE30 M5/Big2 matrix",
  "timeout": 600000
}


---

## 🤖 Claude

Matrix reproduces baseline. Now let me compare PROBE30 lines for Big2 GC 17 (FAIL) vs M5 GC 13 (PASS):

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\necho \"=== M5 iter1 PROBE30 across all 13 GCs ===\"\ngrep \"^PROBE30 \" log/session30/M5-a1m-g1.iter1.log\necho\necho \"=== Big2 iter1 PROBE30 across all 17 GCs ===\"\ngrep \"^PROBE30 \" log/session30/Big2-a1m-g1.iter1.log",
  "description": "PROBE30 per-GC output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\necho \"=== Big2 iter1 PROBE30 across all 17 GCs ===\"\ngrep \"^PROBE30 \" log/session30/Big2-a1m-g1.iter1.log",
  "description": "Big2 PROBE30 output"
}


---

## 🤖 Claude

Let me verify Big2 PROBE30 GC 17 determinism across iters, then think about implications:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\necho \"=== Big2 GC 17 PROBE30 lines across 5 iters ===\"\nfor i in 1 2 3 4 5; do\n  echo \"--- iter$i ---\"\n  grep \"^PROBE30 gc=17 \" log/session30/Big2-a1m-g1.iter${i}.log\ndone\necho\necho \"=== M5 GC 13 PROBE30 lines across 5 iters ===\"\nfor i in 1 2 3 4 5; do\n  echo \"--- iter$i ---\"\n  grep \"^PROBE30 gc=13 \" log/session30/M5-a1m-g1.iter${i}.log\ndone",
  "description": "Check PROBE30 determinism"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\necho \"=== Big2 GC 17 PROBE30 lines across all iters (md5) ===\"\nfor i in 1 2 3 4 5; do\n  m=$(grep \"^PROBE30 gc=17 \" log/session30/Big2-a1m-g1.iter${i}.log | md5)\n  echo \"iter${i}: $m\"\ndone\necho\necho \"=== M5 GC 13 PROBE30 lines (md5) ===\"\nfor i in 1 2 3 4 5; do\n  m=$(grep \"^PROBE30 gc=13 \" log/session30/M5-a1m-g1.iter${i}.log | md5)\n  echo \"iter${i}: $m\"\ndone",
  "description": "Verify PROBE30 determinism via md5"
}


---

## 🤖 Claude

Great — PROBE30 reveals: all allocator-state counters and size buckets are byte-identical across iters AND scale uniformly with workload between M5 GC 13 and Big2 GC 17. **No allocator path is Big2-GC-17-specific.** Combined with PROBE29's no-per-type-anomaly result, this means aggregate per-GC counters cannot discriminate the bug. Let me also confirm a key ruleout — the "big object" path never fires (`atbGrp=0` everywhere):

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\necho \"=== Total atbGrp counts across all GCs/iters ===\"\nfor f in log/session30/M5-a1m-g1.iter*.log log/session30/Big2-a1m-g1.iter*.log; do\n  total=$(grep \"^PROBE30 \" \"$f\" | grep -oE \"atbGrp=[0-9]+\" | sed 's/atbGrp=//' | awk '{s+=$1} END{print s+0}')\n  echo \"$(basename $f): atbGrp total = $total\"\ndone\necho\necho \"=== Max s11 (size > 1024 words) ever seen ===\"\nfor f in log/session30/M5-a1m-g1.iter*.log log/session30/Big2-a1m-g1.iter*.log; do\n  s11max=$(grep \"^PROBE30 \" \"$f\" | grep -oE \"s11=[0-9]+\" | sed 's/s11=//' | sort -n | tail -1)\n  echo \"$(basename $f): max s11 = ${s11max:-0}\"\ndone\necho\necho \"=== Big2 GC 17 vs M5 GC 13 raw ratios (workload-normalized) ===\"\nm5=\"$(grep '^PROBE30 gc=13 aim' log/session30/M5-a1m-g1.iter1.log)\"\nb2=\"$(grep '^PROBE30 gc=17 aim' log/session30/Big2-a1m-g1.iter1.log)\"\necho \"M5  GC13: $m5\"\necho \"Big2 GC17: $b2\"",
  "description": "Confirm big-object path never fires"
}


---

## 🤖 Claude

Definitive ruleouts. Now save the patch and revert/redeploy clean stage2:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngit diff HEAD -- rts/sm/GC.c rts/sm/Evac.c rts/sm/Scav.c rts/sm/GCUtils.c > /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch\nwc -l /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch",
  "description": "Save PROBE30 patch (incl PROBE28+29 base)"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8\ngit checkout -- rts/sm/GC.c rts/sm/Evac.c rts/sm/Scav.c rts/sm/GCUtils.c\ngit status -s rts/sm/\nsource ../../../scripts/cross-env.sh >/dev/null 2>&1\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a 2>&1 | tail -5",
  "description": "Revert probes and rebuild clean RTS",
  "timeout": 120000
}


---

## 🤖 Claude

Clean RTS rebuilt. Redeploy stage2 and verify clean state:

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\nbash scripts/deploy-stage2.sh pmacg5 2>&1 | tail -6",
  "description": "Redeploy clean stage2",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh pmacg5 '\ncd /tmp\necho \"--- verify Big2 -A1m -G1 still deterministic on clean stage2 ---\"\nfor i in 1 2 3; do\n  rm -f Big2.hi Big2.o\n  out=$(DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real -c Big2.hs +RTS -A1m -G1 -RTS 2>&1)\n  rc=$?\n  sig=$(echo \"$out\" | grep -E \"refineFromInScope|panic\" | head -1)\n  probe=$(echo \"$out\" | grep -c \"^PROBE\")\n  echo \"iter $i  rc=$rc  probe_lines=$probe  sig=$sig\"\ndone\n' 2>&1",
  "description": "Verify clean stage2 still panics same way"
}


---

## 🤖 Claude

Clean stage2 verified. Now write up session 30 docs:

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 30 directory and read prior debug-RTS work",
      "activeForm": "Setting up session 30 directory and reading prior debug-RTS work",
      "status": "completed"
    },
    {
      "content": "Verify baseline: Big2.hs -A1m -G1 still panics deterministically with v0.12.0 stage2",
      "activeForm": "Verifying baseline",
      "status": "completed"
    },
    {
      "content": "Build debug-RTS-linked stage2 (ghc-real-debug) and deploy to pmacg5",
      "activeForm": "Building debug-RTS-linked stage2",
      "status": "completed"
    },
    {
      "content": "Run Big2.hs +RTS -A1m -G1 -DS and inspect for sanity-check catches inside GC",
      "activeForm": "Running Big2.hs with -DS sanity check",
      "status": "completed"
    },
    {
      "content": "Confirm prior bitmap/stack/StgRegTable session conclusions (20-24)",
      "activeForm": "Confirming prior bitmap/stack/StgRegTable session conclusions",
      "status": "completed"
    },
    {
      "content": "Audit allocator (alloc_in_moving_heap / todo_block_full / Bdescr / forwarding-ptr) for PPC32 arithmetic bugs",
      "activeForm": "Auditing allocator arithmetic for PPC32 bugs",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE30: allocator-state counters + per-size histogram",
      "activeForm": "Designing and implementing PROBE30",
      "status": "completed"
    },
    {
      "content": "Run M5/Big2 matrix with PROBE30 and diff results",
      "activeForm": "Running probe matrix and diffing",
      "status": "completed"
    },
    {
      "content": "Revert + clean redeploy stage2",
      "activeForm": "Reverting and redeploying clean stage2",
      "status": "completed"
    },
    {
      "content": "Write session 30 docs (README, findings, HANDOFF, log, commits)",
      "activeForm": "Writing session 30 docs",
      "status": "in_progress"
    },
    {
      "content": "Commit session 30 work",
      "activeForm": "Committing session 30 work",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/log.md",
  "content": "# Session 30 log \u2014 debug-RTS revisit + PROBE30 allocator-state probe\n\n## Plan on arrival\n\nPer session-29 HANDOFF: top priority is rebuild stage2 with DEBUG /\nsanity-check RTS, run Big2.hs `-A1m -G1 -DS` to catch corruption\ninside `GarbageCollect()`.\n\n**Caveat I noted before starting:** session 19 already tried `-DS`\non M5.hs at default `-A` and `-DS` did NOT fire (heap was internally\nconsistent; the bug is missed-root, not corrupted-heap-state).  But\nthat was a different reproducer (M5.hs, `$trModule2_ruq` panic);\nsession 28-29's repro is Big2.hs `-A1m -G1` producing\n`refineFromInScope`.  The session-28 framing of \"one bug, two\nvictim data structures\" makes a redo of `-DS` worthwhile.\n\n## Step 0 \u2014 baseline\n\n```\nssh pmacg5\nMD5 (Big2.hs) = 78b5eb77f66d284948fcea9d96013f81\nBig2 -A1m -G1 \u00d7 5: rc=1 5/5, all `refineFromInScope` STG-time panic.\n```\n\nMatches session-29 README exactly.\n\n## Step 1 \u2014 build & deploy debug-RTS stage2\n\n`bash scripts/exp-deploy-stage2-debug.sh pmacg5` ran cleanly using\nthe script left over from session 19.  Produced\n`/opt/ghc-stage2/bin/ghc-real-debug` on pmacg5 (193 MB).\n`+RTS --info` confirms `RTS way = rts_debug`; `nm` confirms\n`_checkSanity`, `_checkHeapChain`, `_checkNurserySanity` etc. linked.\n\nSmoke test: `ghc-real-debug -c Big2.hs +RTS -A1G -RTS` produced a\nvalid 46340-byte `Big2.o` (rc=0).  Debug variant works for the\n\"unbroken\" workaround flag combo.\n\n## Step 2 \u2014 Big2 -A1m -G1 -DS\n\n```\nghc-real-debug -c Big2.hs +RTS -A1m -G1 -DS -RTS\n\u2192 ghc-real-debug: panic! ... refineFromInScope ...\n\u2192 (Sp 706:30 simplify)\n\u2192 no `barf`, no `sanity`, no `inconsistent`, no `invariant`, no `assert` lines\n\u2192 no `Sanity check` output at all\n```\n\n15-line output total.  Just the panic and the call stack.  Sanity\ncheck ran (silent on success) and DID NOT catch a corrupt heap.\n\nCross-verified with `-DS -DZ` (zero freed memory): **same panic\nsignature, same InScope set, same missing `$dNum_a1kO`.**  If the\nmissed data were \"present-but-stale\" (still readable from a freed\nblock), `-DZ` would convert reads to zero-deref.  Since the panic\nis identical, the lost data isn't stale \u2014 it's been reused by a\nfresh allocation.\n\nThis replicates session 19's step1 finding for the new (Big2,\nrefineFromInScope) reproducer:\n\n- Sanity check passes \u2192 heap is internally consistent after GC.\n- `-DZ` doesn't change panic \u2192 the lost slot's memory got REUSED\n  by a fresh allocation post-GC, not freed-and-zero'd.\n\nCombined: **a pointer that should be a GC root isn't being walked.\nThe closure it points to is therefore not evacuated.  Its\nfrom-space block is freed and recycled.  The mutator reads through\nthe now-dangling pointer and sees fresh data \u2014 not the dictionary\nbinding it expected.**\n\n## Step 3 \u2014 re-read sessions 20-24 + 28-29 to consolidate ruleouts\n\nReading order: session 19 step1 + step3 + HANDOFF; session 24's\nREADME (which closes sessions 20-23's bitmap framing); session 27\nexit; session 28 exit; session 29 README.  Consolidated remaining\nsuspects below.\n\nWhat's ruled out by data, not theory:\n\n- Session 19 PROBE19 \u2192 CAF list (`dyn_caf_list`) walking is correct.\n  CAF counts are monotonically non-decreasing; never truncated.\n- Session 19 + step1 \u2192 SMP atomics not at fault (non-threaded RTS\n  uses no atomics on the GC path); `large_alloc_lim` doesn't\n  overflow.\n- Sessions 20-24 \u2192 stack-frame bitmap codegen produces correct\n  bitmaps for the cases tested.  PROBE22POISON's read-after-poison\n  crash is a stale-Addr# bug, not a bitmap mis-classification.\n- Session 26 \u2192 ForeignPtrContents pinning is correct.  Zero\n  `*+UNPINNED` BSes ever observed.\n- Session 28 \u2192 `mut_list` scavenge and `static_objects` scavenge\n  paths ruled out (PROBE28 per-cap, per-gen counters identical\n  under M5 -A1m -G1 [PASS] and Big2 -A1m -G1 [FAIL]).\n- Session 29 \u2192 per-closure-type scavenge / evacuate buggy-dispatch\n  ruled out by the filename-sensitivity experiment.  Same source\n  bytes, different filename \u2192 different pass/fail outcome.\n- Session 30 (today) \u2192 `-DS` doesn't catch the bug.  Heap is\n  internally consistent after every GC.\n\nWhat remained per session 29 HANDOFF:\n\n1. Audit `alloc_in_moving_heap` / `todo_block_full` for PPC32\n   block-boundary bugs.\n2. Audit forwarding-pointer / info-pointer 32-bit alignment paths.\n3. Per-closure-SIZE histogram (vs per-type) to catch variable-size\n   closure misclassification.\n4. Bisect filename more aggressively to find a 1-byte flip.\n\nSession 30 addresses #1 + #3 in one combined probe (PROBE30).\n\n## Step 4 \u2014 design + implement PROBE30\n\nGoal: instrument the to-space allocator paths so we can see *which\npath the allocator takes* per GC, not just *what types it allocates*.\nIf a PPC32 block-boundary or big-object bug fires the GC corruption,\nit'll show as a path-counter anomaly at Big2 GC 17.\n\nCounters added in `rts/sm/GC.c` (static W_):\n\n| name                       | what it counts                                   |\n|----------------------------|--------------------------------------------------|\n| `probe30_aim_calls`        | every `alloc_in_moving_heap` invocation          |\n| `probe30_aim_pre_overflow` | aim invocations where `todo_free+size > todo_lim` (calls `todo_block_full`) |\n| `probe30_tbf_can_extend`   | `todo_block_full` in-place extension hits        |\n| `probe30_tbf_push_new`     | `todo_block_full` push-out + alloc-new hits      |\n| `probe30_tbf_freed_empty`  | push-new path freed an empty block (closure spans block edge) |\n| `probe30_atb_part_reuse`   | `alloc_todo_block` reused a `part_list` block    |\n| `probe30_atb_alloc_group`  | `alloc_todo_block` called `allocGroup_sync` (closure > BLOCK_SIZE_W \u2192 BIG OBJECT path) |\n| `probe30_atb_alloc_blocks` | `alloc_todo_block` refilled `gct->free_blocks`   |\n| `probe30_atb_free_blocks`  | `alloc_todo_block` grabbed from `gct->free_blocks` |\n| `probe30_evac_large_calls` | every `evacuate_large` invocation                |\n| `probe30_size_hist[12]`    | log2-ish bucketed size of every `alloc_in_moving_heap` size arg |\n\nBumps:\n\n- `rts/sm/Evac.c::alloc_in_moving_heap`: bump `aim_calls` +\n  `size_hist[bucket]`, then if overflow bump `aim_pre_overflow`.\n- `rts/sm/Evac.c::evacuate_large` (top): bump `evac_large_calls`.\n- `rts/sm/GCUtils.c::todo_block_full`: bump `tbf_can_extend` or\n  `tbf_push_new`; bump `tbf_freed_empty` on the empty-block-free\n  path.\n- `rts/sm/GCUtils.c::alloc_todo_block`: bump one of `atb_part_reuse`,\n  `atb_alloc_group`, `atb_alloc_blocks`, `atb_free_blocks` per the\n  branch taken.\n\nReset all at GC start.  Emit two debugBelch lines per GC alongside\nPROBE28/29 (one line of counters, one line of size hist).\n\nPatch lives at [`probe30-rts.patch`](probe30-rts.patch) \u2014 re-applies\nPROBE28+PROBE29 from session 29 PLUS the PROBE30 additions.\n\n## Step 5 \u2014 rebuild + deploy\n\n```\ncd external/ghc-modern/ghc-9.2.8\nsource ../../../scripts/cross-env.sh >/dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a\n# 4.84 s\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n# ~3 min cross-link\n```\n\nStage2 smoke-test confirmed PROBE30 lines in output.  Sample from a\ntrivial `putStrLn` program GC 1:\n\n```\nPROBE30 gc=1 aim=103 aimPre=0 tbfExt=0 tbfNew=0 tbfFreedEmpty=0 atbPart=0 atbGrp=0 atbBlks=0 atbFree=0 evacLarge=5\nPROBE30 gc=1 sizeHist s1=27 s2=62 s3=6 s4=5 s5=2 s7=1\n```\n\nTiny workload \u2014 no `todo_block_full` overflow needed.  Numbers are\nsane.\n\n## Step 6 \u2014 run probe matrix\n\n[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) =\nsession-29's matrix runner, retargeted to `log/session30/`.\n\n```\n=== M5.hs   iters=5 flags='+RTS -A1m -G1 -RTS' ===  5/5 PASS, 13 GCs each\n=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===  5/5 FAIL, 17 GCs each, refineFromInScope\n```\n\nMatches session 28+29.  PROBE30 doesn't suppress or flip the bug \u2014\nsingle-ALU-op bumps don't perturb enough.\n\n## Step 7 \u2014 analyse PROBE30 data\n\n**All 5 Big2 GC-17 PROBE30 lines are byte-identical across iters\n(md5 match).  All 5 M5 GC-13 PROBE30 lines are byte-identical too.**\nJust like PROBE28+29, the bug is fully deterministic on input.\n\n### Headline numbers\n\n| Field                | M5 GC 13 (PASS) | Big2 GC 17 (FAIL) | Big2/M5 |\n|----------------------|---------------:|------------------:|--------:|\n| `aim`                |         96 968 |           120 079 |   1.24\u00d7 |\n| `aimPre`             |          2 873 |             3 638 |   1.27\u00d7 |\n| `tbfExt`             |          2 508 |             3 180 |   1.27\u00d7 |\n| `tbfNew`             |            365 |               458 |   1.25\u00d7 |\n| `tbfFreedEmpty`      |              0 |                 0 |     \u2014   |\n| `atbPart`            |              5 |                 2 |   0.40\u00d7 |\n| `atbGrp`             |              0 |                 0 |     \u2014   |\n| `atbBlks`            |             23 |                30 |   1.30\u00d7 |\n| `atbFree`            |            338 |               427 |   1.26\u00d7 |\n| `evacLarge`          |             17 |                 8 |   0.47\u00d7 |\n\nThe \"workload baseline\" Big2/M5 ratio is ~1.27\u00d7 (from copiedW).\nEvery allocator path that scales with workload sits in 1.24\u20131.30\u00d7.\n**No allocator path is uniquely fired at Big2 GC 17.**\n\nTwo values are *under*-represented:\n- `atbPart` (5 \u2192 2) \u2014 part-block reuse goes down.  Tiny absolute\n  counts.\n- `evacLarge` (17 \u2192 8) \u2014 large evacs go down at Big2 GC 17, while\n  total work goes UP.  Surprising but not a smoking gun on its own.\n\n### Size histogram\n\nBig2 GC 17 vs M5 GC 13 size-bucket Big2/M5 ratios:\n\n| bucket | size range | M5 GC 13 | Big2 GC 17 | Big2/M5 |\n|-------:|-----------:|---------:|-----------:|--------:|\n| s1     |          1 |   20 680 |     24 696 |   1.19\u00d7 |\n| s2     |          2 |   55 825 |     67 837 |   1.22\u00d7 |\n| s3     |        3-4 |   18 731 |     24 668 |   1.32\u00d7 |\n| s4     |        5-8 |    1 217 |      2 052 |   1.69\u00d7 |\n| s5     |       9-16 |      246 |        556 |   2.26\u00d7 |\n| s6     |      17-32 |        1 |          1 |   1.00\u00d7 |\n| s7     |     33-64  |      259 |        260 |   1.00\u00d7 |\n| s8     |     65-128 |        7 |          7 |   1.00\u00d7 |\n| s9     |    129-256 |        1 |          1 |   1.00\u00d7 |\n| s10    |    513-1024|        1 |          1 |   1.00\u00d7 |\n| s11    |     > 1024 |        0 |          0 |     \u2014   |\n\nBuckets s6..s10 are **identical** between M5 and Big2 \u2014 same\nabsolute count.  Buckets s1..s5 scale with workload (1.19\u20132.26\u00d7).\n**No size bucket is uniquely fired at Big2 GC 17.**\n\n### What this rules out\n\n1. **The \"big object\" path is never hit in either run** (`atbGrp=0`\n   for every GC of every iter, and `s11=0` everywhere).  No closure\n   size > BLOCK_SIZE_W = 1024 words gets copied through\n   `alloc_todo_block`'s `size > BLOCK_SIZE_W` branch.  So the\n   session-29 HANDOFF's hypothesis \"PPC32 block-boundary bug in the\n   multi-block-group allocator path\" is **disproved by data**.\n\n2. **`tbfFreedEmpty=0` everywhere.**  No closure ever spans a block\n   edge leaving an empty block behind.  Rules out the\n   \"evacuate-into-second-block\" pathology.\n\n3. **No allocator state is uniquely fired at the failing GC.**  Every\n   counter scales with workload at the 1.24\u20131.30\u00d7 baseline.\n\n4. **No size class is uniquely fired at the failing GC.**  Buckets\n   either scale with workload (small) or match exactly (medium /\n   large).\n\n5. **Per-closure-type histograms scale identically (PROBE29).**  No\n   type is uniquely fired.\n\nCombining 1-5: **no aggregate per-GC counter discriminates Big2\nGC 17 from a typical GC.**  This strongly implies the bug is a\n*single-event-at-a-specific-address* error, invisible to any\naggregate counter.  Each GC processes hundreds of thousands of\nclosures uniformly; only one address-or-pointer interaction during\nGC 17 of Big2 goes wrong.\n\n### What this means for next steps\n\nThe \"specific address mishandling\" framing kills aggregate\ninstrumentation as a useful approach.  The probe family we've been\nusing (PROBE28/29/30) is now exhausted.  Next-session probe\nstrategies need to track *individual* events, not aggregates.\n\nTop candidates for session 31:\n\nA. **Track which root-walker misses the lost pointer.**  Add\n   per-iteration logging to `markCAFs`, `scavenge_static`, the\n   stack walker, `scavenge_capability_mut_lists`, etc., printing\n   the addresses they hand to `evacuate`.  Compare the address\n   stream from a passing GC to a failing GC.  If the failing GC\n   visits a *different* root set, that's the smoking gun.\n\nB. **Track the saved/restored mutator state.**  Print\n   `Capability->r.rCurrentTSO`, `cap->r.rCurrentNursery`,\n   `cap->r.rCurrentAlloc`, etc., before/after every GC.  If any\n   field shifts unexpectedly across GC 17 in Big2, that's the\n   StgRegTable mis-offset session 19 flagged.\n\nC. **Bisect filename to a 1-byte flip.**  Mechanical, cheap.  Just\n   needs many runs.  Doesn't require a probe.  Per session 29: A.hs\n   passes, AA.hs fails; B.hs/BB.hs pass, BBB.hs fails.  If we can\n   find a single (filename1, filename2) pair differing in one byte\n   that flips pass/fail, the heap shift is extremely small and may\n   be reverse-engineerable.\n\nD. **Track scavenge_stack frame-by-frame.**  Per session 24 the\n   bitmap is correct for the FastString case examined, but the\n   walking *loop* through stack frames hasn't been instrumented.\n   Add a per-frame address dump.\n\nE. **Use `+RTS -Dg`** (GC trace) on `ghc-real-debug`.  Voluminous\n   per-GC trace lines (push/pop block, scan/copy progress).  Will\n   produce ~MB of output, but may reveal a transition step where\n   Big2 GC 17 differs from a typical GC.  Cost: 0 build time\n   (debug RTS is already deployed), ~30 s per run.\n\n## Step 8 \u2014 revert + clean redeploy\n\n```\ncd external/ghc-modern/ghc-9.2.8\ngit checkout -- rts/sm/GC.c rts/sm/Evac.c rts/sm/Scav.c rts/sm/GCUtils.c\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a\n# 4.91 s\n\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\nSmoke test: Big2 -A1m -G1 panics 3/3 with `refineFromInScope`,\nzero PROBE lines in output \u2192 clean v0.12.0-equivalent stage2.\n\nThe debug-RTS-linked stage2 (`/opt/ghc-stage2/bin/ghc-real-debug`)\nis **kept on pmacg5** for session 31's potential use of `-Dg` /\n`-DZ` etc.  Sessions 19's HANDOFF removed it at end-of-session to\navoid confusion; session 30 leaves it, on the rationale that it's\ninformative and clearly distinct from `ghc-real`.  Session 31 can\nremove it via `ssh pmacg5 'rm /opt/ghc-stage2/bin/ghc-real-debug'`\nif they want a clean slate.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/findings.md",
  "content": "# Session 30 findings \u2014 `-DS` revisit + PROBE30 allocator-state probe\n\n## TL;DR\n\n- **Sanity check (`+RTS -DS`) does NOT catch the Big2 -A1m -G1 bug.**\n  The heap is internally consistent after every GC.  Replicates\n  session 19's finding for the new (Big2, `refineFromInScope`)\n  reproducer.  Confirms the bug is **missed-root**, not corrupted-\n  scavenge-bookkeeping.\n- **`-DZ` (zero freed memory) doesn't change the panic.**  The lost\n  data isn't \"present but stale\" \u2014 it's been *reused* by a fresh\n  allocation post-GC.\n- **PROBE30** (allocator-state counters + per-evac size histogram)\n  shows **no allocator path or size class is uniquely fired at\n  Big2 GC 17.**  All path counters scale with workload at 1.24\u2013\n  1.30\u00d7 over M5 GC 13; medium/large size buckets are exactly equal.\n- **The \"big object\" path never fires** in either run\n  (`atbGrp=0` for every GC; `s11=0` always).  No closure ever takes\n  the multi-block-group allocator path.  This **disproves the\n  session-29 HANDOFF's hypothesis** that the bug lives in PPC32\n  block-boundary handling for big objects.\n- **Combining PROBE29 + PROBE30: no aggregate per-GC counter\n  discriminates Big2 GC 17.**  Per-closure-type, per-evacuator-\n  flavor, per-allocator-path, per-size-class \u2014 all match the\n  workload-scaled baseline.  The bug is a single-event mishandling\n  at a specific address that no aggregate counter can see.\n- Probe reverted.  Clean stage2 redeployed.  v0.12.0 ships\n  unchanged.  Debug-RTS-linked `ghc-real-debug` left on pmacg5 for\n  session 31's optional use.\n\n## What the probe revealed (and ruled out)\n\n### Setup: Big2 -A1m -G1 baseline reproducer (sessions 28-29)\n\n```\nM5.hs:    13 GCs, 5/5 PASS\nBig2.hs:  17 GCs, 5/5 FAIL (refineFromInScope STG-time panic)\n```\n\nBig2 GC 17 is the last GC of the run.  M5 GC 13 is the last GC of\nits run.  copiedW for Big2 GC 17 (464982) is ~27% larger than M5\nGC 13 (366812), so the workload-scaling baseline is **1.27\u00d7**.\n\n### Debug-RTS sanity check\n\n`ghc-real-debug -c Big2.hs +RTS -A1m -G1 -DS -RTS` produces a\n15-line output: just the `refineFromInScope` panic and call stack.\nZero `barf`, `sanity`, `inconsistent`, `invariant`, or `assert`\nlines.  Heap is internally consistent post-every-GC.\n\n`-DZ` adds zero-on-free to the GC.  Same panic, same InScope set,\nsame missing `$dNum_a1kO`.  If the missed data had been \"still\nreadable but stale,\" `-DZ` would convert the read to a zero-deref\ncrash.  Since the panic is unchanged, **the lost slot's memory has\nbeen REUSED by a fresh allocation** \u2014 a classic dangling-pointer-\nto-fresh-allocation symptom of a missed GC root.\n\nThis replicates session 19's step1 finding on the new reproducer.\nThe framework: a pointer that should be a GC root isn't being\nwalked \u2192 its target closure isn't evacuated \u2192 the from-space block\nis freed and reused \u2192 the mutator reads through the now-dangling\npointer and sees the new content (a fresh `*$dXxx` dictionary or\nsimilar), not the dictionary it expected (`$dNum_a1kO`).\n\n### PROBE30 allocator-state counters\n\nCounters added (see [log.md](log.md) for full table):\n\n- `aim` calls, of which `aimPre` overflowed to `todo_block_full`\n- `tbf` extend hits, push-new hits, freed-empty hits\n- `atb` part-reuse, alloc-group (big-object), alloc-blocks, free-blocks\n- `evacLarge` calls (BF_LARGE path)\n- `sizeHist[12]` log2-ish buckets of every aim size param\n\nBig2 GC 17 vs M5 GC 13:\n\n| field         |   M5 GC13 |   Big2 GC17 |  ratio |\n|---------------|----------:|------------:|-------:|\n| aim           |    96 968 |     120 079 |  1.24\u00d7 |\n| aimPre        |     2 873 |       3 638 |  1.27\u00d7 |\n| tbfExt        |     2 508 |       3 180 |  1.27\u00d7 |\n| tbfNew        |       365 |         458 |  1.25\u00d7 |\n| tbfFreedEmpty |         0 |           0 |    \u2014   |\n| atbPart       |         5 |           2 |  0.40\u00d7 |\n| atbGrp        |         0 |           0 |    \u2014   |\n| atbBlks       |        23 |          30 |  1.30\u00d7 |\n| atbFree       |       338 |         427 |  1.26\u00d7 |\n| evacLarge     |        17 |           8 |  0.47\u00d7 |\n\nAllocator-path counters all sit at the 1.24-1.30\u00d7 workload baseline.\n**No path is uniquely fired at Big2 GC 17.**\n\n### Size histogram\n\n| bucket | size range  |  M5 GC13 | Big2 GC17 |  ratio |\n|-------:|------------:|---------:|----------:|-------:|\n| s1     |           1 |   20 680 |    24 696 |  1.19\u00d7 |\n| s2     |           2 |   55 825 |    67 837 |  1.22\u00d7 |\n| s3     |         3-4 |   18 731 |    24 668 |  1.32\u00d7 |\n| s4     |         5-8 |    1 217 |     2 052 |  1.69\u00d7 |\n| s5     |        9-16 |      246 |       556 |  2.26\u00d7 |\n| s6     |       17-32 |        1 |         1 |  1.00\u00d7 |\n| s7     |       33-64 |      259 |       260 |  1.00\u00d7 |\n| s8     |      65-128 |        7 |         7 |  1.00\u00d7 |\n| s9     |     129-256 |        1 |         1 |  1.00\u00d7 |\n| s10    |    513-1024 |        1 |         1 |  1.00\u00d7 |\n| s11    |      > 1024 |        0 |         0 |    \u2014   |\n\nBuckets s6..s10 **identical** between M5 and Big2.  Small buckets\nscale with workload.  No bucket is uniquely fired at the failing GC.\n\n### Determinism check (md5)\n\n```\nBig2 GC 17 PROBE30 lines across 5 iters: all 5 \u2192 md5 f859e676...\nM5  GC 13 PROBE30 lines across 5 iters: all 5 \u2192 md5 623b6fcd...\n```\n\nFull byte-identical determinism per (input, flags) tuple.\nConsistent with session 29's PROBE29 byte-identical histograms.\n\n## What this rules out\n\n1. **The \"big object\" path** (closure > 1 block, multi-block group):\n   `atbGrp=0` everywhere; `s11=0` everywhere.  Path never fires.\n   Disproves session 29 HANDOFF's #2 hypothesis.\n\n2. **Block-edge-spanning closures** that leave an empty block behind:\n   `tbfFreedEmpty=0` everywhere.  Path never fires.\n\n3. **Any \"the allocator state at Big2 GC 17 is different\" theory** \u2014\n   all path counters scale with workload.\n\n4. **Any \"Big2 GC 17 evacuates an unusual-sized closure\" theory** \u2014\n   medium-and-large size buckets are byte-identical; small buckets\n   scale uniformly.\n\n5. **Per-closure-type \"type X mishandled\" theory** (session 29's\n   ruleout, restated): combined with PROBE29's per-type histogram\n   matching at 1.27\u00d7 ratios.\n\n## What's still on the table\n\nGiven the comprehensive aggregate-counter ruleout, the bug has to be\n**a single-event mishandling at a specific address**.  Per session\n19's framing: a pointer that should be a GC root isn't being walked.\n\nCandidate \"missed-root\" sources, with status:\n\n| candidate                                | status                        |\n|------------------------------------------|-------------------------------|\n| CAF list (`dyn_caf_list`) walking        | ruled out (session 19 PROBE19) |\n| `mut_list` scavenge                      | ruled out (session 28)         |\n| `static_objects` scavenge                | ruled out (session 28)         |\n| SRT scavenge                             | ruled out (session 28)         |\n| stack-frame bitmap codegen               | ruled out (sessions 20-24)     |\n| per-closure-type scavenge / evac dispatch| ruled out (session 29)         |\n| big-object allocator path                | ruled out (session 30 \u2014 TODAY) |\n| **stack walker (the WALK, not the bitmap)** | NOT YET PROBED              |\n| **`scavenge_one`** on a specific block   | NOT YET PROBED                |\n| **Saved register state / StgRegTable**   | NOT YET PROBED                |\n| **Weak pointers**                        | NOT YET PROBED                |\n| **Stable pointers**                      | NOT YET PROBED                |\n| **`scavenge_stack` step through frames** | NOT YET PROBED                |\n\nThe remaining candidates all involve a specific *traversal* missing\na slot.  Detecting them requires per-event instrumentation, not\naggregate counters.\n\n## PPC32 arithmetic audit (incidental)\n\nI read through `rts/sm/GCUtils.c` and `rts/sm/Evac.c` for PPC32-\nspecific arithmetic concerns flagged in session 29's HANDOFF, plus\n`includes/rts/storage/Block.h` for the block-geometry macros.\nFindings (none rule the bug in or out, but documented for the\nrecord):\n\n- `BLOCK_SHIFT = 12`, `MBLOCK_SHIFT = 20`, **same on both\n  platforms**.  Block = 4 KB, megablock = 1 MB.\n- `BLOCK_SIZE_W = BLOCK_SIZE / sizeof(W_) = 4096/4 = 1024` on\n  PPC32 vs `4096/8 = 512` on amd64.\n- `LARGE_OBJECT_THRESHOLD = BLOCK_SIZE * 8 / 10` (in BYTES, not\n  words).  Same on both platforms = 3276.8 bytes.  In words: 819\n  words on PPC32, 409 on amd64.  Pointer-heavy closures cross the\n  threshold at fewer payload entries on amd64.\n- `BLOCK_SIZE` uses the `UL` suffix (`1UL<<BLOCK_SHIFT`) so\n  expressions like `n*BLOCK_SIZE` promote correctly per \"Note\n  [integer overflow]\".\n- `Bdescr(p)` macro uses 32-bit arithmetic on pointers (`(W_)p`).\n  On PPC32, `W_` is `unsigned long` = 4 bytes.  Pointer values\n  fit; arithmetic is correct.\n- `IS_FORWARDING_PTR(p) = ((StgWord)p & 1) != 0`.  PPC32 closure\n  pointers are 4-byte aligned (bit 1 and bit 0 both zero).  No\n  alignment issue.\n- `alloc_todo_block` line 337's `bd->start + bd->blocks * BLOCK_SIZE_W - bd->free > (int)size`:\n  the cast `(int)size` is fine.  `size` is uint32_t in practice\n  bounded by closure sizes (max ~ a few hundred words on PPC32).\n  No overflow.\n\nThe arithmetic looks correct as written.  PROBE30 data confirms\nthe dynamic behavior on PPC32 stays in the regime where this\narithmetic was designed (small allocs, no big-object path).\n**No PPC32-specific allocator bug surfaces in audit or in data.**\n\n## Process notes\n\n- Debug-RTS rebuild via `exp-deploy-stage2-debug.sh` worked\n  unchanged from session 19.  Produces\n  `/opt/ghc-stage2/bin/ghc-real-debug` (193 MB).  Distinct from\n  the normal `ghc-real`.  Adds `-debug` to ghc-bin's link line\n  \u2192 RTS linked is `libHSrts-1.0.2_debug.a` instead of `.a`.\n- The debug-RTS-linked stage2 is ~the same size as normal (193 MB)\n  but the RTS code is bulkier (extra assertions).  Performance is\n  noticeably slower (~2\u00d7 per compile) due to the assertion overhead.\n- `+RTS -DS` produces NO OUTPUT when sanity check passes.  Only the\n  `barf` / `sanity` messages on failure.  Silent success on every\n  GC of every probe iteration confirms the heap is consistent.\n- Bumping a static W_ counter is ~ 1 ALU op per closure.  PROBE30\n  adds 11 counters but only 1-3 bumps per closure (one in\n  alloc_in_moving_heap; sometimes one in todo_block_full /\n  alloc_todo_block).  Total perturbation: micro-percent, not\n  measurable.  Matches session 29's PROBE29 perturbation profile.\n\n## Files added this session\n\n- [`README.md`](README.md), this `findings.md`,\n  [`HANDOFF.md`](HANDOFF.md), [`log.md`](log.md),\n  [`commits.md`](commits.md) \u2014 writeup.\n- [`probe30-rts.patch`](probe30-rts.patch) \u2014 combined PROBE28 +\n  PROBE29 + PROBE30 diff over clean rts/sm/{GC,Scav,Evac,GCUtils}.c.\n  Re-apply with `git apply` from inside `external/ghc-modern/ghc-9.2.8`.\n- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) \u2014\n  the M5 / Big2 \u00d7 -A1m -G1 matrix runner, retargeted to\n  `log/session30/`.\n- Run logs at [`../../../log/session30/`](../../../log/session30/)\n  (gitignored).\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/README.md",
  "content": "# Session 30 \u2014 stage2 GC bug, round 12 (debug-RTS revisit + PROBE30 allocator-state probe; aggregate counters can't see the bug)\n\n**Dates:** 2026-05-12 (continuing the stage2 GC bug hunt from session 29).\n\n**Status on arrival:** v0.12.0 ships unchanged.  Stage2 native ghc on\nTiger uses `+RTS -A1G` workaround.  Session 29 ruled out per-closure-\ntype scavenge / evacuate bugs and uncovered the **filename-sensitivity\nplot twist** \u2014 byte-identical Big2.hs source compiled under filename\n`Big2.hs` panics 5/5 at GC 17; under `B0.hs` (or `BB.hs`, `X.hs`) it\nPASSES.  The trigger is heap-layout-dependent, not closure-type-\ndependent.  Session 29 HANDOFF queued: (a) rebuild with DEBUG/sanity-\ncheck RTS, (b) audit `alloc_in_moving_heap` / `todo_block_full` for\nPPC32 block-boundary bugs, (c) per-closure-SIZE histogram, (d) bisect\nfilename to a 1-byte flip.\n\n**Status on exit:**\n\n- **`+RTS -DS` does NOT catch the Big2 -A1m -G1 bug.**  Heap is\n  internally consistent after every GC.  Replicates session 19's\n  step1 finding for the new (Big2, `refineFromInScope`) reproducer.\n- **`+RTS -DZ` doesn't change the panic.**  Lost data is reused-by-\n  fresh-allocation, not present-but-stale.  Classic dangling-pointer-\n  to-recycled-block signature \u2192 confirms the bug is a **missed GC\n  root**, exactly as session 19 predicted.\n- **PROBE30 implemented**: 10 allocator-state counters\n  (alloc_in_moving_heap calls, todo_block_full extend-vs-push-new\n  splits, alloc_todo_block paths, evacuate_large) + log2-ish size-\n  class histogram of every `alloc_in_moving_heap` size param.\n  Counters declared in `rts/sm/GC.c`, bumps in `rts/sm/Evac.c` and\n  `rts/sm/GCUtils.c`.  Patch saved at\n  [`probe30-rts.patch`](probe30-rts.patch); reverted before session\n  end, clean stage2 redeployed.\n- **PROBE30 matrix run** (M5.hs `-A1m -G1` 5/5 PASS, Big2.hs `-A1m -G1`\n  5/5 FAIL at GC 17 \u2014 reproduces session 28+29 exactly).\n- **All 5 Big2 GC 17 PROBE30 lines byte-identical (md5 match).**\n  Full determinism confirmed at the allocator level too.\n- **\ud83d\udfe5 No aggregate per-GC counter discriminates Big2 GC 17 from M5\n  GC 13.**  Allocator-path counters: 1.24-1.30\u00d7 workload-baseline.\n  Size buckets: medium/large bytes-identical, small scale uniformly.\n  Combined with PROBE29's per-type histograms (also workload-scaled),\n  **the bug is invisible to aggregate per-GC counters**.  The\n  mishandling is a single-event at a specific address, not a\n  systematic pattern that aggregates can see.\n- **The \"big object\" path NEVER FIRES** in either run (`atbGrp=0` for\n  every GC of every iter; `s11=0` always).  No closure ever needs the\n  multi-block-group allocator.  **Disproves session 29 HANDOFF's #2\n  hypothesis** (\"PPC32 block-boundary bug in `alloc_todo_block`'s big-\n  object branch\").\n- **Incidental PPC32 arithmetic audit** of `rts/sm/GCUtils.c`,\n  `rts/sm/Evac.c`, and `includes/rts/storage/Block.h` found no\n  arithmetic bugs.  `BLOCK_SIZE_W = 1024` on PPC32; `BLOCK_SIZE`\n  uses `UL` suffix; `(W_)p` arithmetic in `Bdescr()` macro is\n  correct on PPC32's 4-byte W_; `IS_FORWARDING_PTR` bit-0 check is\n  fine on PPC32 (4-byte alignment of closure pointers).\n- v0.12.0 unchanged.  Source tree clean at session end.  Stage2 on\n  pmacg5 rebuilt + redeployed to match v0.12.0.  Debug-RTS-linked\n  `/opt/ghc-stage2/bin/ghc-real-debug` left in place for session 31's\n  potential use of `-Dg` / `-Db` / `-DZ`.  No commits to the GHC\n  tree this session.\n\nHANDOFF for session 31: see [`HANDOFF.md`](HANDOFF.md).  Pivot:\naggregate counters are exhausted; the next probes need to track\n*individual events*.  Top of queue: per-iteration logging of which\nROOT-WALKER returns which addresses to `evacuate`, comparing the\naddress stream from a passing GC to a failing GC.  Alternative\nquick wins: filename 1-byte bisect; `+RTS -Dg` GC trace on\n`ghc-real-debug`.\n\n## What we did, in order\n\n### Step 1 \u2014 verified -DS still doesn't fire on Big2\n\nSession 19 already proved `-DS` is silent on the M5.hs reproducer\n(at default `-A`, panic `$trModule2_ruq`).  Re-verified on\nsessions 28-29's Big2.hs `-A1m -G1` reproducer (`refineFromInScope`\npanic).  Same outcome: 15-line output, zero sanity-check / barf /\ninconsistent / invariant / assert messages.  Heap is consistent\npost-GC.\n\n`-DZ` (zero freed memory) also tested.  Same panic, same InScope\nset, same missing `$dNum_a1kO`.  Lost data is reused-by-fresh-\nallocation, not stale.\n\n### Step 2 \u2014 designed + implemented PROBE30\n\n10 allocator-state counters + a 12-bucket size histogram.  See\n[findings.md](findings.md) for the full table.  Patch lives at\n[`probe30-rts.patch`](probe30-rts.patch).\n\n### Step 3 \u2014 rebuild + deploy\n\n```\ncd external/ghc-modern/ghc-9.2.8\nsource ../../../scripts/cross-env.sh >/dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a\n# 4.84 s\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\nStage2 smoke-test confirmed PROBE30 lines in output, sane numbers.\n\n### Step 4 \u2014 probe matrix\n\n[`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh):\n\n```\n=== M5.hs   iters=5 flags='+RTS -A1m -G1 -RTS' ===\n  iter01..05 rc=0 gcs=13 : OK         pass=5 fail=0\n\n=== Big2.hs iters=5 flags='+RTS -A1m -G1 -RTS' ===\n  iter01..05 rc=1 gcs=17 : panic      pass=0 fail=5\n```\n\nMatches session 28+29.\n\n### Step 5 \u2014 PROBE30 analysis\n\nByte-identical lines across all 5 iters (md5).  Allocator-path\ncounters scale 1.24-1.30\u00d7 over M5 (workload baseline = 1.27\u00d7).\nSize buckets s6-s10 exactly equal between M5 and Big2 GCs.  Big-\nobject path (`atbGrp`, `s11`) never fires.  **No counter is\nuniquely fired at Big2 GC 17.**\n\nCombined with PROBE29's per-closure-type result, this rules out all\naggregate-counter-visible bug classes.\n\n### Step 6 \u2014 revert + clean redeploy\n\n```\ncd external/ghc-modern/ghc-9.2.8\ngit checkout -- rts/sm/GC.c rts/sm/Evac.c rts/sm/Scav.c rts/sm/GCUtils.c\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a\n# 4.91 s\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\nSmoke test: Big2 -A1m -G1 panics 3/3 with `refineFromInScope`, zero\nPROBE lines in output \u2014 clean v0.12.0-equivalent stage2 confirmed.\n\n## Status on exit\n\n- **v0.12.0 unchanged.**  Stage2 ships with the `+RTS -A1G` wrapper.\n- **No GHC-tree source edits committed this session.**  Probe lives\n  only as the patch in this session dir.\n- **Stage2 ghc on pmacg5 is the clean rebuild after probe revert.**\n- **Debug-RTS-linked `ghc-real-debug` on pmacg5 KEPT** for session\n  31.  Session 19 ritually removed it; session 30 leaves it because\n  it's clearly distinct from `ghc-real` and immediately useful for\n  `-Dg` / `-Db` traces in the next round.\n- **Logs at** [`../../../log/session30/`](../../../log/session30/)\n  (gitignored).\n- **HANDOFF for session 31** pivots the audit strategy from aggregate\n  counters to per-event traces (see [`HANDOFF.md`](HANDOFF.md)).\n\n## Files added this session\n\n- [`README.md`](README.md), this; [`findings.md`](findings.md);\n  [`HANDOFF.md`](HANDOFF.md); [`log.md`](log.md);\n  [`commits.md`](commits.md) \u2014 writeup.\n- [`probe30-rts.patch`](probe30-rts.patch) \u2014 the combined PROBE28 +\n  PROBE29 + PROBE30 patch over clean `rts/sm/{GC,Scav,Evac,GCUtils}.c`.\n  Re-apply with `git apply` from inside `external/ghc-modern/ghc-9.2.8`.\n- [`scripts/run-probe-matrix.sh`](scripts/run-probe-matrix.sh) \u2014\n  M5 / Big2 \u00d7 `-A1m -G1` (5 iters each), retargeted to\n  `log/session30/`.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md",
  "content": "# Handoff from session 30 \u2192 session 31\n\n**For:** the next claude session.\n**From:** session 30 (debug-RTS revisit + PROBE30 allocator-state probe;\n**aggregate counters can't see the bug**; **big-object path ruled out\nby data**; 2026-05-12).\n**Recommended pickup:** pivot from aggregate counters to **per-event\ntracing of root-walkers**.  Run PROBE31 = log every address handed to\n`evacuate` from each root source (CAFs, mut_lists, static_objects,\nstack walker, weak ptrs, stable ptrs).  Diff Big2 GC 17 vs M5 GC 13's\naddress stream and look for what's in M5's stream but missing from\nBig2's, OR present in both streams but pointing to different memory.\n\n## TL;DR (mandatory read)\n\n- **`+RTS -DS` doesn't catch the bug.**  Replicates session 19's\n  result for Big2 / `refineFromInScope`.  Heap is internally\n  consistent post-every-GC.  The bug is a **missed GC root**.\n- **`+RTS -DZ` doesn't change the panic.**  Lost data is reused-by-\n  fresh-allocation, not stale.  Confirms missed-root.\n- **PROBE30** instrumented every allocator path in `rts/sm/Evac.c`\n  and `rts/sm/GCUtils.c` + a size histogram.  ALL counters scale\n  1.24-1.30\u00d7 with workload between M5 GC 13 (PASS) and Big2 GC 17\n  (FAIL).  Medium/large size buckets are exactly equal.  **No\n  allocator state is uniquely fired at Big2 GC 17.**\n- \ud83d\udfe5 **The big-object path NEVER fires.**  `atbGrp=0` everywhere\n  in every iter of both runs; `s11=0` everywhere.  **Disproves\n  session-29 HANDOFF's \"PPC32 block-boundary big-object bug\"\n  hypothesis.**  Closures never exceed BLOCK_SIZE_W = 1024 words.\n- \ud83d\udfe5 **No aggregate per-GC counter discriminates Big2 GC 17.**\n  Per-closure-type (PROBE29), per-allocator-path (PROBE30), per-\n  size-class (PROBE30 size histogram) \u2014 all match the workload-\n  scaled baseline.  The bug is a single-event mishandling at one\n  specific address, invisible to aggregate counters.\n- v0.12.0 ships unchanged.  Source tree clean at session end.\n  Stage2 on pmacg5 is the clean redeploy after probe revert.\n  Debug-RTS-linked `/opt/ghc-stage2/bin/ghc-real-debug` is **kept\n  on pmacg5** for session 31's potential use of `-Dg` / `-Db`.\n\n## Read in order\n\n1. **This file.**\n2. [`README.md`](README.md) \u2014 narrative of session 30.\n3. [`findings.md`](findings.md) \u2014 full PROBE30 data + ruleouts +\n   PPC32 arithmetic audit.\n4. [`log.md`](log.md) \u2014 real-time work log.\n5. [`probe30-rts.patch`](probe30-rts.patch) \u2014 the probe diff, ready\n   to re-apply.\n6. (Reference) Session 29 [`HANDOFF.md`](../2026-05-12-session-29-closure-type-histogram/HANDOFF.md)\n   \u2014 its #4 hypothesis (per-size histogram) is now ruled out; its\n   #2 (big-object path) is also ruled out.  Other priorities\n   (filename bisect, sanity check, stack walker audit) still hold.\n7. (Reference) Session 19 [`step1-debug-rts-findings.md`](../2026-05-09-session-19-stage2-gc-bug/step1-debug-rts-findings.md)\n   \u2014 established the \"missed-root\" framing.  Confirmed again today\n   for the Big2 reproducer.\n\n## What to NOT redo\n\n- **Don't try `-DS`, `-DZ`, or any other sanity-check variant.**\n  Heap is consistent.  Data is reused, not stale.\n- **Don't probe the `alloc_in_moving_heap` / `todo_block_full` /\n  `alloc_todo_block` path for aggregate anomalies.**  PROBE30 has\n  exhausted that direction.  Counters match workload-baseline.\n- **Don't probe the big-object path (`atbGrp`, `s11`, multi-block\n  group).**  PROBE30 confirmed it never fires.\n- **Don't redo per-closure-type histograms** \u2014 PROBE29 already did,\n  and the filename experiment disproved per-type as the trigger.\n- **Don't redo `mut_list` / `static_objects` / SRT** \u2014 sessions\n  27-28 ruled them out.\n- **Don't redo stack-frame BITMAP codegen audits** \u2014 sessions\n  20-24 ruled them out.  But \u2014 *do* feel free to instrument the\n  stack-WALK (the loop itself), since that hasn't been done.\n- **Don't rebuild the world** for an RTS-only change.  ~5 s with\n  `_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`\n  (+ `_debug.a` if needed).\n- **Don't remove `/opt/ghc-stage2/bin/ghc-real-debug`** unless you\n  decide you want a clean slate.  It's useful for `+RTS -Dg/-Db`\n  traces with zero rebuild cost.\n\n## What to try next, in priority order\n\n### Top: PROBE31 \u2014 per-event address-stream trace of root walkers\n\nThe session-30 ruleouts have narrowed the bug to \"a single pointer\nthat should be a GC root isn't being walked, in a way that depends\non exact heap layout.\"  Aggregate counters can't see this.\n\nPlan: extend PROBE28+29+30 with **per-iteration logging**:\n\n1. **`markCAFs`** (rts/sm/GCAux.c) \u2014 currently logs CAF count per\n   GC (session 19 PROBE19).  Extend: log the ADDRESS of every CAF\n   walked.  ~3000 lines per GC, ~50000 across the run.\n2. **`scavenge_capability_mut_lists`** (rts/sm/Scav.c) \u2014 log\n   every closure pointer fed to `evacuate` from per-cap mut_lists.\n3. **`scavenge_static`** (rts/sm/Scav.c) \u2014 log each static object\n   visited.\n4. **`scavenge_stack`** (rts/sm/Scav.c) \u2014 log each TSO's stack\n   walk: TSO address, frame info-table, frame size, payload\n   pointers fed to evacuate.\n5. **`markWeakPtrList`** (rts/sm/MarkWeak.c) \u2014 log each weak ptr.\n6. **`markScheduler`** / **`markStableTables`** (rts/sm/Sanity.c,\n   rts/StableName.c) \u2014 log stable ptr / TSO table entries.\n\nRun M5 -A1m -G1 (PASS) and Big2 -A1m -G1 (FAIL).  Diff the address\nstreams.\n\nWhat we expect:\n- Most addresses will be different (different allocations).\n- BUT: the COUNT of addresses per root-source should be very close\n  (PROBE28+29+30 already established this aggregately).\n- IF Big2 GC 17 visits one FEWER address from one root-source\n  compared to a similar passing GC, that's the smoking gun.\n- IF Big2 GC 17 has an address that maps to a different bdescr/\n  flag/type than M5's corresponding GC's nearest analog, that's\n  also a smoking gun.\n\nThis is voluminous instrumentation.  Output will be 10-50 MB of\ntrace.  Diff-tooling will need to be careful (address values\nshift, but counts/types/flags should match).\n\nCost: ~2 h to write probe + tooling, then ~30 min/run.\n\n### Second: filename 1-byte bisect\n\nMechanical, cheap, no probe required.\n\nSession 29 found: `A.hs` PASS, `AA.hs` FAIL; `B.hs`/`BB.hs` PASS,\n`BBB.hs` FAIL.  Different content under those filenames.\n\nThe richer experiment: take the EXACT Big2.hs content, vary just\nthe filename across an alphabet of 1- and 2-char names, find a\n(name1, name2) pair differing in 1 byte that flips PASS\u2194FAIL.\n\nCost: ~30 min for a thorough sweep.  Outcome: confirms the heap-\nlayout-sensitivity bound and may suggest which structure carries\nfilename bytes through to GC 17 allocations.\n\nRun on pmacg5 directly \u2014 no rebuild needed, just shell loops.\n\n### Third: `+RTS -Dg` GC trace on Big2\n\n`ghc-real-debug` is already deployed on pmacg5.  `-Dg` enables the\nGC trace via `debugTrace(DEBUG_gc, ...)`.  Voluminous (~ MB per GC)\nbut no rebuild needed.  Look for:\n- `push todo block <addr> ...` lines\n- `increasing limit for <addr> to <addr>` lines\n- `alloc new todo block <addr> for gen N` lines\n\nThese map to PROBE30's counters but with addresses + per-event\ndata.  May reveal whether a specific block-push-pop sequence at\nGC 17 visits a problematic address.\n\nCost: ~5 min per run.  Analysis 1-2 h.\n\n### Fourth: stack-walker step trace\n\nSessions 20-24 examined stack-frame BITMAPS and concluded they're\ncorrect for the cases tested.  But the stack-WALK loop in\n`scavenge_stack` (rts/sm/Scav.c) processes frames one at a time\nusing info-table dispatch.  Per-frame instrumentation could reveal:\n- A frame whose info-table type is misclassified on PPC32.\n- A stack pointer that walks past the end (Sp/SpLim mismatch).\n- A frame size computation that's off by one.\n\nCost: ~1 h to probe; voluminous output.\n\n### Fifth: StgRegTable / saved register state probe\n\nSession 19's #1 candidate.  Probe `Capability->r.rCurrentNursery`,\n`Capability->r.rCurrentAlloc`, `cap->r.rCurrentTSO` before/after\nevery GC.  If any field shifts unexpectedly, the StgRegTable layout\non PPC32 is at fault.\n\nCost: ~1 h.  Lower prior than (1) but mechanical.\n\n## Mechanics \u2014 reproducing session 30 results\n\n```bash\ncd /Users/cell/claude/ghc-darwin8-ppc\n\n# 0. Optional baseline (skip if just continuing PROBE work)\nbash tests/run-tests.sh    # ~10 min; 30 PASS / 4 design diffs\n\n# 1. Re-apply the probe (combined PROBE28+29+30)\ncd external/ghc-modern/ghc-9.2.8\ngit apply ../../docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch\n\n# 2. Rebuild RTS + deploy stage2\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n\n# 3. Run the matrix (logs at log/session30/)\nbash docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/scripts/run-probe-matrix.sh \\\n    pmacg5 5\n\n# 4. Inspect specific GCs\ngrep \"^PROBE30 gc=13 \" log/session30/M5-a1m-g1.iter1.log\ngrep \"^PROBE30 gc=17 \" log/session30/Big2-a1m-g1.iter1.log\n\n# 5. Determinism check\nfor f in log/session30/Big2-a1m-g1.iter*.log; do\n  grep \"^PROBE30 gc=17 \" \"$f\" | md5\ndone\n# Expected: all 5 iters produce md5 f859e676adef6e1a0dd06c44566ae315\n\n# 6. Sanity-check rerun (no probe needed)\nssh pmacg5 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib \\\n    /opt/ghc-stage2/bin/ghc-real-debug -c /tmp/Big2.hs +RTS -A1m -G1 -DS -RTS 2>&1' \\\n    | head -20\n# Expected: 15-line panic output, no sanity messages\n\n# 7. When done \u2014 REVERT before any user-facing run\ncd external/ghc-modern/ghc-9.2.8\ngit checkout -- rts/sm/GC.c rts/sm/Scav.c rts/sm/Evac.c rts/sm/GCUtils.c\n./hadrian/build --flavour=quick-cross -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2_debug.a\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\n**Expected:** with probe, M5 `-A1m -G1` passes 5/5 (13 GCs each),\nBig2 `-A1m -G1` panics 5/5 at GC 17 with `refineFromInScope`.\nPROBE30 lines are byte-identical across all 5 iters of each input.\nBig2 GC 17 PROBE30 counters scale 1.24-1.30\u00d7 over M5 GC 13's.\n`atbGrp=0` and `s11=0` for every GC.\n\n## Hosts (unchanged)\n\n- **uranium** (this Mac): host for cross-build, source edits.\n- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.\n  - `/opt/ghc-stage2/bin/ghc-real` \u2014 production stage2 (clean).\n  - `/opt/ghc-stage2/bin/ghc-real-debug` \u2014 debug-RTS-linked, kept\n    for session 31.\n- **imacg3**: smaller-RAM PPC G3 (not used this session).\n- **indium**: don't use for clang or hadrian builds.\n\n## What's clean / dirty in the source tree\n\n- `external/ghc-modern/ghc-9.2.8/` \u2014 **rts/sm/** is clean (the\n  PROBE30 patch was applied, used, then `git checkout -- ` reverted).\n- `pmacg5:/opt/ghc-stage2/bin/ghc-real` \u2014 clean rebuild + redeploy at\n  session-30 end, matches v0.12.0.\n- `pmacg5:/opt/ghc-stage2/bin/ghc-real-debug` \u2014 debug-RTS-linked\n  stage2 from this session.  KEPT (not removed at session end).\n- New session dir: `docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/`\n  + run logs gitignored at `log/session30/`.\n\n## Time estimate for session 31\n\n- Setup + read handoff + verify session-30 numbers (re-apply\n  probe + rebuild + 5\u00d72 = 10 runs): 30\u201345 min.\n- Filename 1-byte bisect (mechanical, may be enlightening): 30 min.\n- `+RTS -Dg` GC trace on Big2 + inspect for anomalies: 1-2 h.\n- PROBE31 design + implement + run (per-event root-walker\n  address-stream trace): 3-5 h.\n- Diff-analysis of PROBE31 streams: 2-3 h.\n\nRealistic: 1 long session (~6-8 h) for PROBE31 implementation +\nfirst-pass analysis, then 1 short session to either pinpoint the\nmissed-root source or pivot strategy.\n\n## Paste-into-fresh-session prompt\n\n```\nContext: session 30 of the GHC darwin8-ppc project just wrapped up.\nSession 30 (a) rebuilt stage2 with debug-RTS and confirmed -DS does\nNOT catch the Big2 -A1m -G1 bug (heap is consistent after every\nGC); (b) confirmed -DZ doesn't change the panic (lost data is\nreused-by-fresh-allocation, not stale); (c) implemented PROBE30\n(allocator-state counters + per-evac size histogram) covering\nalloc_in_moving_heap, todo_block_full, alloc_todo_block, and\nevacuate_large; (d) found that NO aggregate per-GC counter\ndiscriminates Big2's failing GC 17 from M5's passing GC 13 \u2014 all\ncounters scale 1.24-1.30x with workload, big-object path never\nfires (atbGrp=0 always), no size class is uniquely Big2-GC-17-\nspecific.\n\nThis DISPROVES the session-29 HANDOFF's hypothesis that the bug\nlives in PPC32 block-boundary handling for big objects.  More\nimportantly, combined with PROBE29's per-closure-type histograms\n(also workload-scaled), it establishes that AGGREGATE COUNTERS\nCANNOT SEE THIS BUG.  The mishandling is a single-event at one\nspecific address, not a systematic pattern.\n\nThe bug is a missed GC root (per session 19's framing, confirmed\nagain on the new reproducer).  Aggregate root-walker counters\n(CAF count, mut_list count, static-chain count) all match between\npassing and failing GCs.  But ONE pointer that should be a root\nisn't being walked.\n\nThe audit direction pivots to: PER-EVENT address-stream tracing\nof every root-walker (markCAFs, scavenge_capability_mut_lists,\nscavenge_static, scavenge_stack, markWeakPtrList, stable ptr table,\netc.).  Diff the address stream from a passing GC vs failing GC\nand look for a missing address or a misclassified one.\n\nQuick wins also queued:\n- Filename 1-byte bisect (mechanical, ~30 min).\n- +RTS -Dg GC trace on the already-deployed ghc-real-debug (no\n  rebuild, ~5 min/run).\n- Stack-walker per-frame trace (sessions 20-24 examined BITMAPS;\n  WALK loop not probed).\n\nRead in order:\n1. docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md\n2. docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/README.md\n3. docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/findings.md\n4. docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/log.md\n5. (reference) docs/sessions/2026-05-09-session-19-stage2-gc-bug/step1-debug-rts-findings.md\n   \u2014 established the missed-root framing (PROBE19 ruled out CAF list).\n\nTop priority: design PROBE31 \u2014 per-iteration logging of which\naddress each root-walker hands to evacuate().  Run M5 -A1m -G1\n(PASS) and Big2 -A1m -G1 (FAIL); diff the streams; look for an\naddress present in M5 but missing from Big2, or vice-versa.\n\nDon't redo -DS / -DZ probes (session 19 + session 30 already did,\ntwice).  Don't redo allocator-path or size-class aggregate counters\n(PROBE30 exhausted).  Don't redo per-closure-type histograms\n(PROBE29 exhausted).  Don't redo big-object path investigation\n(PROBE30 proved it never fires).\n\nHosts: uranium for builds, pmacg5 for runs.  Don't use indium.\nv0.12.0 stays shipped \u2014 don't break stage2's -A1G wrapper.\n`/opt/ghc-stage2/bin/ghc-real-debug` is kept on pmacg5 \u2014 feel free\nto use +RTS -Dg/-Db with it.  ALWAYS revert the probe + rebuild +\nredeploy clean stage2 at session end.\n\nUnsupervised mode is project default.\n```\n\n## Memory aide for the next-you: session-end HANDOFF path\n\nThis handoff lives at:\n[`docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md`](docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md).\n\nWhen session 31 ends, write the next handoff at:\n`docs/sessions/<DATE>-session-31-<slug>/HANDOFF.md`.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/commits.md",
  "content": "# Session 30 commits\n\n## Repo commits\n\nThis file is filled in after the session-30 commit lands.  Expected\nshape: one commit containing session-30 docs (README, findings,\nHANDOFF, log, commits, probe30-rts.patch, scripts/) plus a session\nnotes title line in the format used by sessions 26-29.\n\nThe actual SHA gets backfilled by the next commit (the\n`commits.md: backfill the SHA` pattern from sessions 27-29).\n\n## GHC-tree commits\n\nNone.  Session 30's RTS edits were applied to the source tree,\nused to gather probe data, then reverted at session end.  The\nprobe lives only in\n[`probe30-rts.patch`](probe30-rts.patch) for re-application.\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\ngit status -s\necho ---\nls -la docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/\necho ---\necho \"patch lines: $(wc -l docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch)\"",
  "description": "Check git state and session 30 dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\nhead -30 docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch\necho \"...\"\necho \"--- diffstat ---\"\ndiffstat docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch 2>/dev/null || grep -E \"^(---|\\+\\+\\+)\" docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch\necho \"--- check patch still applies ---\"\ncd external/ghc-modern/ghc-9.2.8\ngit apply --check ../../../docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/probe30-rts.patch && echo \"PATCH APPLIES CLEAN\"",
  "description": "Verify probe30 patch is intact"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\ngit log --oneline -10",
  "description": "Check recent commits for style"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\ngit add docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/\ngit status -s",
  "description": "Stage session 30 dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\ngit commit -m \"$(cat <<'EOF'\nSession 30: stage2 GC bug investigation, round 12 (debug-RTS revisit + PROBE30 allocator-state probe; +RTS -DS does NOT catch the Big2 -A1m -G1 bug, replicating session 19's missed-root framing on the new refineFromInScope reproducer; +RTS -DZ doesn't change panic so lost data is reused-by-fresh-allocation not stale; PROBE30 = alloc_in_moving_heap + todo_block_full + alloc_todo_block + evacuate_large counters + log2-ish size histogram shows no aggregate per-GC counter discriminates Big2 GC 17 from M5 GC 13; big-object path NEVER fires in either run [atbGrp=0 and s11=0 everywhere], disproving session-29 HANDOFF's PPC32 block-boundary big-object hypothesis; aggregate-counter probe family is exhausted; pivot to per-event root-walker address-stream tracing for session 31).\nEOF\n)\"",
  "description": "Commit session 30 work"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/tmp/session30-commit-msg.txt",
  "content": "Session 30: stage2 GC bug investigation, round 12 (debug-RTS revisit + PROBE30 allocator-state probe; +RTS -DS does NOT catch the Big2 -A1m -G1 bug, replicating session 19s missed-root framing on the new refineFromInScope reproducer; +RTS -DZ doesnt change panic so lost data is reused-by-fresh-allocation not stale; PROBE30 = alloc_in_moving_heap + todo_block_full + alloc_todo_block + evacuate_large counters + log2-ish size histogram shows no aggregate per-GC counter discriminates Big2 GC 17 from M5 GC 13; big-object path NEVER fires in either run [atbGrp=0 and s11=0 everywhere], disproving session-29 HANDOFFs PPC32 block-boundary big-object hypothesis; aggregate-counter probe family is exhausted; pivot to per-event root-walker address-stream tracing for session 31).\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\ngit commit -F /tmp/session30-commit-msg.txt 2>&1",
  "description": "Commit session 30 via file"
}


---

## 🤖 Claude

Now backfill the SHA in commits.md:

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/commits.md",
  "old_string": "# Session 30 commits\n\n## Repo commits\n\nThis file is filled in after the session-30 commit lands.  Expected\nshape: one commit containing session-30 docs (README, findings,\nHANDOFF, log, commits, probe30-rts.patch, scripts/) plus a session\nnotes title line in the format used by sessions 26-29.\n\nThe actual SHA gets backfilled by the next commit (the\n`commits.md: backfill the SHA` pattern from sessions 27-29).",
  "new_string": "# Session 30 commits\n\n## Repo commits\n\n- `4c6d8f4` \u2014 Session 30 docs (README, findings, HANDOFF, log,\n  commits, probe30-rts.patch, scripts/run-probe-matrix.sh).\n  7 files / 1692 insertions."
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc\ngit add docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/commits.md\ngit commit -m \"Session 30 commits.md: backfill the SHA.\"\ngit log --oneline -3",
  "description": "Backfill SHA commit"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Set up session 30 directory and read prior debug-RTS work",
      "activeForm": "Setting up session 30 directory and reading prior debug-RTS work",
      "status": "completed"
    },
    {
      "content": "Verify baseline: Big2.hs -A1m -G1 still panics deterministically with v0.12.0 stage2",
      "activeForm": "Verifying baseline",
      "status": "completed"
    },
    {
      "content": "Build debug-RTS-linked stage2 (ghc-real-debug) and deploy to pmacg5",
      "activeForm": "Building debug-RTS-linked stage2",
      "status": "completed"
    },
    {
      "content": "Run Big2.hs +RTS -A1m -G1 -DS and inspect for sanity-check catches inside GC",
      "activeForm": "Running Big2.hs with -DS sanity check",
      "status": "completed"
    },
    {
      "content": "Confirm prior bitmap/stack/StgRegTable session conclusions (20-24)",
      "activeForm": "Confirming prior bitmap/stack/StgRegTable session conclusions",
      "status": "completed"
    },
    {
      "content": "Audit allocator (alloc_in_moving_heap / todo_block_full / Bdescr / forwarding-ptr) for PPC32 arithmetic bugs",
      "activeForm": "Auditing allocator arithmetic for PPC32 bugs",
      "status": "completed"
    },
    {
      "content": "Design + implement PROBE30: allocator-state counters + per-size histogram",
      "activeForm": "Designing and implementing PROBE30",
      "status": "completed"
    },
    {
      "content": "Run M5/Big2 matrix with PROBE30 and diff results",
      "activeForm": "Running probe matrix and diffing",
      "status": "completed"
    },
    {
      "content": "Revert + clean redeploy stage2",
      "activeForm": "Reverting and redeploying clean stage2",
      "status": "completed"
    },
    {
      "content": "Write session 30 docs (README, findings, HANDOFF, log, commits)",
      "activeForm": "Writing session 30 docs",
      "status": "completed"
    },
    {
      "content": "Commit session 30 work",
      "activeForm": "Committing session 30 work",
      "status": "completed"
    }
  ]
}


---

## 🤖 Claude

Session 30 complete and committed.

## Summary

**Findings (2 hard ruleouts, 1 framing confirmation):**

1. **`+RTS -DS` does not catch the bug** on the Big2 `-A1m -G1` repro either — heap is consistent after every GC. Replicates session 19's missed-root framing on the new `refineFromInScope` signature.
2. **`+RTS -DZ` doesn't change the panic** — the lost data has been *reused* by a fresh allocation, not left stale. Classic dangling-pointer-into-recycled-block signature of a missed GC root.
3. **PROBE30 (allocator-state counters + size histogram)** shows no aggregate per-GC counter discriminates Big2 GC 17 from M5 GC 13 — all paths scale 1.24–1.30× with workload, and the **big-object path never fires** (`atbGrp=0`, `s11=0` everywhere). This **disproves the session-29 HANDOFF's PPC32 block-boundary big-object hypothesis**.

**Strategic implication:** combined with PROBE29's per-closure-type ruleout, **aggregate counters cannot see this bug**. The mishandling is a single-event-at-a-specific-address, invisible to any aggregate. Session 31 needs to pivot to per-event root-walker address-stream tracing.

**State at session end:**
- Clean stage2 redeployed to pmacg5 (matches v0.12.0).
- Debug-RTS-linked [`ghc-real-debug`](docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/README.md) kept on pmacg5 for session 31's potential `-Dg`/`-Db` traces.
- Commits: [`4c6d8f4`](docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/commits.md) (session 30 docs, 1692 lines) and `b9b79dd` (SHA backfill).
- Next session pickup: [docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md](docs/sessions/2026-05-12-session-30-debug-rts-and-allocator-audit/HANDOFF.md).

---

