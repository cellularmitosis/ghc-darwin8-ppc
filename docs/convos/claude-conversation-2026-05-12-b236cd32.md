# Claude Conversation Log

Session ID: b236cd32-a7d4-4e1e-9375-8cf3ac5ce131
Date: 2026-05-12 03:11:44

---

## 👤 User

please read docs/sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md and proceed

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md"
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
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-26-bs-allocator-hunt/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-26-bs-allocator-hunt/findings.md"
}


---

## 🤖 Claude

I've read the handoff. Session 26 ruled out the BS-pinning-invariant hypothesis via direct observation, and the "5/5 SIGSEGV at `_blk_c7te+112`" pattern from sessions 23–25 turned out to be a probe artefact — without instrumentation the bug surfaces as panics (4/5 on M5.hs at session-26 end). The handoff queues "re-establish a non-perturbing deterministic repro" as top priority.

Let me start the session-27 checklist: roadmap, baseline tests, session-dir creation.

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
  "command": "bash tests/run-tests.sh 2>&1 | tail -40",
  "description": "Run baseline tests"
}


---

## 🤖 Claude

I'll create the session 27 dir while tests run.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-26-bs-allocator-hunt/",
  "description": "List session 26 dir contents"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-26-bs-allocator-hunt/scripts/ && echo \"---\" && cat /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-26-bs-allocator-hunt/scripts/run-probe26.sh",
  "description": "Look at probe26 harness"
}


---

## 🤖 Claude


🔧 Using tool: ToolSearch
Input: {
  "query": "select:TodoWrite,Monitor",
  "max_results": 2
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Run baseline tests/run-tests.sh",
      "activeForm": "Running baseline tests",
      "status": "in_progress"
    },
    {
      "content": "Create session-27 directory with skeleton notes",
      "activeForm": "Creating session-27 directory",
      "status": "pending"
    },
    {
      "content": "Re-confirm clean-stage2 panic baseline on M5.hs +RTS -A1m",
      "activeForm": "Re-confirming clean-stage2 panic baseline",
      "status": "pending"
    },
    {
      "content": "Pick and execute a session-27 investigation thread (non-perturbing repro, allocatePinned audit, or upstream RTS audit)",
      "activeForm": "Investigating",
      "status": "pending"
    },
    {
      "content": "End-of-session ritual: writeup + commits + HANDOFF for session 28",
      "activeForm": "Writing session-27 wrapup",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -60 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/b0o61qpu2.output 2>/dev/null; echo \"---\"; if ps -p $(cat /tmp/test-run.pid 2>/dev/null) >/dev/null 2>&1; then echo \"still running\"; else echo \"done\"; fi",
  "description": "Check baseline test progress"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/b0o61qpu2.output | tail -80",
  "description": "Read test output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/ 2>/dev/null",
  "description": "List task output dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash tests/run-tests.sh 2>&1 | tail -80",
  "description": "Run baseline tests in foreground",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -40 tests/run-tests.sh",
  "description": "Inspect test runner"
}


---

## 🤖 Claude


🔧 Using tool: Monitor
Input: {
  "command": "until ! ps -p $(pgrep -f 'tests/run-tests.sh' | head -1) > /dev/null 2>&1; do sleep 5; done; echo \"tests-finished\"",
  "description": "Wait for tests to finish",
  "persistent": false,
  "timeout_ms": 900000
}


---

## 🤖 Claude

While tests run, let me create the session 27 skeleton.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "mkdir -p /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts /Users/cell/claude/ghc-darwin8-ppc/log/session27 && ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/",
  "description": "Create session-27 directory structure"
}


---

## 🤖 Claude


🔧 Using tool: mcp__ccd_session__mark_chapter
Input: {
  "title": "Session 27 setup",
  "summary": "Read handoff, run baseline tests, create session-27 dir"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/README.md",
  "content": "# Session 27 \u2014 stage2 GC bug, round 9 (re-establish non-perturbing repro; pivot upstream of FastString)\n\n**Dates:** 2026-05-12 (continuation of session 26 same day).\n\n**Status on arrival:** v0.12.0 ships unchanged.  Stage2 ghc on\npmacg5 uses the `+RTS -A1G` workaround.  Session 26 ruled out\nhypothesis (a) \"BS reaches `mkFastStringByteString` with non-pinned\nMBA\" via direct observation (PROBE26 saw 150/150 PlainPtr-pinned, 0\nUNPINNED).  PROBE26 also perturbed the M5.hs SIGSEGV away entirely\n(0/3 vs. session 23's 5/5).  Sessions 23\u201325's PROBE22POISON crash\nsignature `_blk_c7te+112 / 0xdeadbeef` is now reread as a probe\nartefact composite: the underlying bug is the panics that session 17\nfirst cataloged (`depSortStgBinds`, `refineFromInScope`, \"variable\nnot found\"), not the SIGSEGV at a specific spilled-Addr#.  At\nsession-26 end, clean stage2 was re-confirmed on M5.hs `+RTS -A1m`\nas 4/5 panic.\n\n**Status on exit:** _(filled at end of session)._\n\n## What we're trying to do this session\n\nPer session-26 HANDOFF's \"what to try next\" list:\n\n1. **Top:** re-establish a deterministic, non-perturbing repro that\n   crashes WITHOUT any Haskell- or RTS-side instrumentation in\n   `mkFastStringByteString`.  The clean-stage2 4/5 panic on M5.hs\n   `-A1m` is the new baseline, but it's not 100%.  Want either:\n   (a) a workload that crashes 5/5, OR (b) confidence that \"4-out-\n   of-5 panic\" is the reliable signal we'll iterate on.\n2. **Pivot upstream of FastString.**  Session-26's PROBE26 ruled out\n   the BS-pinning theory; sessions 19\u201325 ruled out LayoutStack /\n   mkLivenessBits / stackMapToLiveness / StackRep.  The likely\n   suspects now are higher up the RTS \u2014 CAFs/SRTs, info-table\n   payloads, the PPC32 pinned-block sub-allocator (`allocatePinned`\n   in `rts/sm/Storage.c`), or generation-ordering quirks.\n\nThe session-26 HANDOFF lists option B (\"find a workload that crashes\n100% under any probe\") as the cleanest unblock \u2014 `cabal install\nrandom`, stage2 ghc compiling something larger, or `runghc-tiger`\ntest suite.  Going to try (in order):\n\n  - Larger Haskell input \u2014 Big.hs / M5plus.hs / something with more\n    imports / SCC structure \u2014 on clean stage2 to see if a larger\n    input gives a deterministic panic rate.\n  - If yes: lock that workload in as the session-27 baseline.\n  - If no: try cabal install random or stage2 compiling a module of\n    itself (e.g., `Data.List`).\n\nThen proceed to upstream investigation per the HANDOFF's \"fourth\"\noption.\n\n## What we did, in order\n\n_(filled in as session proceeds)._\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-26-bs-allocator-hunt/commits.md 2>/dev/null | head -40",
  "description": "See what commits.md looks like"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/findings.md",
  "content": "# Session 27 findings\n\n_(filled as session proceeds.)_\n\n## TL;DR\n\n_(filled at end of session.)_\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/commits.md",
  "content": "# Session 27 commits\n\n_(filled at session end.)_\n"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Run baseline tests/run-tests.sh",
      "activeForm": "Running baseline tests",
      "status": "in_progress"
    },
    {
      "content": "Create session-27 directory with skeleton notes",
      "activeForm": "Creating session-27 directory",
      "status": "completed"
    },
    {
      "content": "Re-confirm clean-stage2 panic baseline on M5.hs +RTS -A1m",
      "activeForm": "Re-confirming clean-stage2 panic baseline",
      "status": "pending"
    },
    {
      "content": "Pick and execute a session-27 investigation thread (non-perturbing repro, allocatePinned audit, or upstream RTS audit)",
      "activeForm": "Investigating",
      "status": "pending"
    },
    {
      "content": "End-of-session ritual: writeup + commits + HANDOFF for session 28",
      "activeForm": "Writing session-27 wrapup",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude

While tests run, let me think about the investigation plan and prepare a measurement harness.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -q pmacg5 'ls -la /opt/ghc-stage2/bin/ghc /opt/ghc-stage2/bin/ghc-real 2>&1; echo \"---\"; ls -la /tmp/M5.hs 2>&1' ",
  "description": "Check stage2 binary state on pmacg5"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -q pmacg5 'cat /tmp/M5.hs'",
  "description": "Show current M5.hs on pmacg5"
}


---

## 🤖 Claude

Stage2 is deployed clean as of session-26 end. Let me write the panic-rate harness in advance.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/measure-panic-rate.sh",
  "content": "#!/bin/bash\n# Measure the panic rate of stage2 ghc compiling a small input under\n# various RTS flag combos.  Goal: lock down a reliable, non-perturbing\n# repro for the session-17 GC corruption bug after session 26 ruled\n# out the BS-pinning-invariant theory.\n#\n# Default: 20 iterations of M5.hs, multiple +RTS profiles.\n#\n# Usage:  ./measure-panic-rate.sh [SSH_HOST] [N_ITERS] [INPUT]\n# Default SSH_HOST=pmacg5, N_ITERS=20, INPUT=M5\n\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nN_ITERS=\"${2:-20}\"\nINPUT=\"${3:-M5}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session27\"\nmkdir -p \"$LOGDIR\"\n\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\n\n# Make sure the input exists on pmacg5 (only really needed for M5 / a\n# few standards \u2014 caller may pre-place other inputs).\ncase \"$INPUT\" in\n  M5)\n    ssh -q \"$PPC_HOST\" 'cat > /tmp/M5.hs' <<'EOF'\nmodule M5 where\nfive = (5::Int)\nsix = (6::Int)\nEOF\n    ;;\n  Hello)\n    ssh -q \"$PPC_HOST\" 'cat > /tmp/Hello.hs' <<'EOF'\nmodule Main where\nmain :: IO ()\nmain = putStrLn \"Hello, World!\"\nEOF\n    ;;\n  M5plus)\n    ssh -q \"$PPC_HOST\" 'cat > /tmp/M5plus.hs' <<'EOF'\nmodule M5plus where\nimport Data.List (sort)\nimport qualified Data.Map.Strict as M\nfive :: Int\nfive = 5\nsix :: Int\nsix = 6\nsortedKeys :: M.Map Int String -> [Int]\nsortedKeys m = sort (M.keys m)\nsampleMap :: M.Map Int String\nsampleMap = M.fromList [(1,\"a\"),(2,\"b\"),(3,\"c\"),(4,\"d\"),(5,\"e\")]\nEOF\n    ;;\nesac\n\nrun_profile () {\n    local label=\"$1\"\n    local rts_flags=\"$2\"\n    local logbase=\"$LOGDIR/${INPUT}-${label}\"\n    echo \"=== $INPUT iters=$N_ITERS flags='$rts_flags' ===\"\n    local pass=0 fail=0\n    : > \"$logbase.summary\"\n    for i in $(seq 1 \"$N_ITERS\"); do\n        local log=\"$logbase.iter${i}.log\"\n        ssh -q \"$PPC_HOST\" \"\n            cd /tmp\n            rm -f ${INPUT}.hi ${INPUT}.o\n            $DYLD $GHC_REAL -c ${INPUT}.hs $rts_flags 2>&1\n            echo \\\"GHC_EXIT=\\$?\\\"\n        \" > \"$log\" 2>&1\n        local rc\n        rc=$(grep -m1 '^GHC_EXIT=' \"$log\" | sed 's/GHC_EXIT=//' || echo '?')\n        local sig=\"\"\n        if [ \"$rc\" = \"0\" ]; then\n            pass=$((pass+1))\n            sig=\"OK\"\n        else\n            fail=$((fail+1))\n            # Extract first panic / error line for symptom classification\n            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found)' \"$log\" 2>/dev/null \\\n                  | head -c 100)\n            if [ -z \"$sig\" ]; then sig=\"UNKNOWN_FAIL_rc=$rc\"; fi\n        fi\n        printf 'iter%02d rc=%s : %s\\n' \"$i\" \"$rc\" \"$sig\" | tee -a \"$logbase.summary\"\n    done\n    echo\n    echo \"  SUMMARY: pass=$pass fail=$fail of $N_ITERS\"\n    echo \"  Symptom histogram:\"\n    awk -F': ' '/^iter/ {print $2}' \"$logbase.summary\" | sort | uniq -c | sort -rn\n    echo\n}\n\n# A1G control \u2014 should never crash.\nrun_profile a1g  \"+RTS -A1G -RTS\"\n\n# A1m \u2014 the load-bearing repro.\nrun_profile a1m  \"+RTS -A1m -RTS\"\n\n# A1m -G1 \u2014 single-generation; rules out gen0\u2192gen1 promote-ordering quirks.\nrun_profile a1m-g1  \"+RTS -A1m -G1 -RTS\"\n\n# A512k \u2014 smaller area, more frequent GC, should crash at least as often.\nrun_profile a512k  \"+RTS -A512k -RTS\"\n\n# A4m \u2014 larger area, fewer GCs.  See where the threshold is.\nrun_profile a4m  \"+RTS -A4m -RTS\"\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/measure-panic-rate.sh",
  "description": "Make harness executable"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bin9w0hin.output 2>&1 && wc -l /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bin9w0hin.output",
  "description": "Check test log size"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "pgrep -f 'tests/run-tests.sh' ; pgrep -fl 'ghc' | head -10",
  "description": "Check for running test processes"
}


---

## 🤖 Claude

Tests still running. Let me read `allocatePinned` in the RTS to prep for the upstream investigation thread.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find external/ghc-modern/ghc-9.2.8/rts/sm -name 'Storage.c' 2>/dev/null | head -3",
  "description": "Locate Storage.c"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'allocatePinned\\b' external/ghc-modern/ghc-9.2.8/rts/sm/Storage.c | head -20",
  "description": "Find allocatePinned definition"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Storage.c",
  "offset": 1237,
  "limit": 160
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'PROBE21\\|PROBE20' external/ghc-modern/ghc-9.2.8/rts/ 2>/dev/null | head -20",
  "description": "Find prior PROBE21/20 RTS patches"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/ docs/sessions/2026-05-10-session-21-stage2-bitmap-bug/ 2>/dev/null",
  "description": "List sessions 20/21 dirs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'PROBE21\\|PROBE20\\|^@@\\|^---\\|^+++' docs/sessions/2026-05-10-session-20-stage2-gc-bug-round2/probe20-21-stack-walk.patch | head -40",
  "description": "Skim probe20-21 patch structure"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat docs/sessions/2026-05-10-session-22-stage2-bitmap-bug/HANDOFF.md | head -100",
  "description": "See session 22 handoff for context on PROBE21 false positives"
}


---

## 🤖 Claude

Tests are using pmacg5. Let me wait for them to finish before running pmacg5-bound experiments.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "pgrep -fl 'tests/run-tests.sh|stage1/bin/powerpc' | head",
  "description": "Check tests still running"
}


---

## 🤖 Claude

Two duplicate test runs are competing on pmacg5. Let me kill the older one and let the second one finish cleanly.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "kill 86887 86923 2>/dev/null; sleep 1; pgrep -fl 'tests/run-tests.sh' | head",
  "description": "Kill duplicate test run"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -30 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bin9w0hin.output 2>&1 ; echo \"---\" ; wc -l /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bin9w0hin.output",
  "description": "Check second test run output"
}


---

## 🤖 Claude

While tests finish (output buffered by `tail`), let me look up the panic call sites in GHC source.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'depSortStgBinds\\|refineFromInScope' external/ghc-modern/ghc-9.2.8/compiler/ 2>/dev/null | head -20",
  "description": "Find panic call sites"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/compiler/GHC/Stg/DepAnal.hs",
  "offset": 130,
  "limit": 30
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/compiler/GHC/Core/Opt/Simplify/Env.hs",
  "offset": 685,
  "limit": 35
}


---

## 🤖 Claude

Tests are still running on pmacg5. Let me look at the panic-related counts and prep the analysis docs while waiting.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -3 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bin9w0hin.output 2>&1 ; wc -l /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bin9w0hin.output; echo \"---\"; pgrep -fl 'tests/run-tests.sh' | head -3",
  "description": "Check on tests"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'scavenge_thunk\\|scavenge_thunk_srt\\|scavenge_one\\b' external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c 2>/dev/null | head -10",
  "description": "Find scavenger entry points"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 10,
  "limit": 100
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 370,
  "limit": 160
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la tests/actual/ 2>/dev/null | head -50; echo \"---\"; ls tests/programs/ 2>/dev/null | wc -l",
  "description": "Check test progress via actual/ dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "pgrep -fl 'tests/run-tests.sh' | head; echo \"---\"; pgrep -fl 'powerpc-apple-darwin8-ghc.*programs' | head",
  "description": "Check test progress"
}


---

## 🤖 Claude


🔧 Using tool: ScheduleWakeup
Input: {
  "delaySeconds": 240,
  "reason": "Waiting for the baseline test suite to finish on pmacg5 before launching pmacg5-bound experiments.",
  "prompt": "Continue session 27 of the GHC darwin8 PPC project. Tests should be done \u2014 check status and proceed with the M5.hs panic-rate baseline on the clean stage2, then move on to upstream investigation per docs/sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md."
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "pgrep -fl 'tests/run-tests.sh|powerpc-apple-darwin8-ghc.*programs' 2>/dev/null | head -5; echo \"---\"; tail -3 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bin9w0hin.output 2>/dev/null",
  "description": "Re-check test status"
}


---

## 🤖 Claude


🔧 Using tool: Monitor
Input: {
  "command": "while pgrep -f 'tests/run-tests.sh' > /dev/null 2>&1; do sleep 10; done; echo \"tests-finished\"",
  "description": "Tests/run-tests.sh exit watcher",
  "persistent": false,
  "timeout_ms": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "wc -l external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c external/ghc-modern/ghc-9.2.8/rts/sm/GC.c external/ghc-modern/ghc-9.2.8/rts/sm/Storage.c",
  "description": "Source sizes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'WORDS_PER_LONG\\|SIZEOF_VOID_P\\|WORD_SIZE_IN_BITS' external/ghc-modern/ghc-9.2.8/rts/sm/*.c external/ghc-modern/ghc-9.2.8/rts/sm/*.h 2>/dev/null | head -20",
  "description": "Look for 32-vs-64-bit guards in GC"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/MBlock.c",
  "offset": 340,
  "limit": 120
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn '\\\\bevacuate\\\\b' external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c | head -5; echo \"---\"; grep -n '^evacuate' external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c | head",
  "description": "Find evacuate entry point"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Evac.c",
  "offset": 681,
  "limit": 120
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls docs/sessions/2026-05-11-session-25-pin-aware-poison/ 2>/dev/null",
  "description": "List session 25 dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "wc -l docs/sessions/2026-05-11-session-25-pin-aware-poison/probe23-poison-stack.patch; echo \"---\"; head -50 docs/sessions/2026-05-11-session-25-pin-aware-poison/probe23-poison-stack.patch",
  "description": "Check session 25 patch shape"
}


---

## 🤖 Claude

While waiting, let me prep the M5plus.hs and Big.hs inputs for the harness.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find /Users/cell/claude/ghc-darwin8-ppc/log/session26 -type f 2>/dev/null | head -20",
  "description": "Look for session 26 input files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -E \"module Big|module M5plus\" docs/sessions/2026-05-12-session-26-bs-allocator-hunt/README.md docs/sessions/2026-05-12-session-26-bs-allocator-hunt/findings.md docs/sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md 2>/dev/null; echo \"---\"; head -50 log/session26/probe26-big-x10.log 2>/dev/null",
  "description": "See Big.hs/M5plus content references"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -10 log/session26/clean-rebuild-validation2.log 2>/dev/null; echo \"---\"; head -30 log/session26/probe26-big-x10.log 2>/dev/null",
  "description": "Look at session 26 logs"
}


---

## 🤖 Claude

Tests finished — let me check results.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -50 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bin9w0hin.output",
  "description": "Read test results"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat tests/expected/12_show_read.out 2>/dev/null | head -10; echo \"---ACTUAL---\"; cat tests/actual/12_show_read.out 2>/dev/null | head -10; echo \"---\"; cat /tmp/12_show_read.host-run.err 2>/dev/null | head -10; echo \"---\"; ls tests/expected/12_show_read.out tests/actual/12_show_read.out 2>&1",
  "description": "Check 12_show_read failure"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat tests/programs/12_show_read.hs 2>/dev/null | head -30; echo \"---\"; ls tests/bin/12_show_read* 2>/dev/null; echo \"---\"; ssh -q pmacg5 'ls /tmp/ghc-test-bin 2>&1; echo XX'",
  "description": "Check test 12 program and binaries"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "scp tests/bin/12_show_read-ppc pmacg5:/tmp/test-12 && ssh -q pmacg5 'DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /tmp/test-12; echo \"RC=$?\"'",
  "description": "Re-run test 12 on pmacg5 manually"
}


---

## 🤖 Claude

The 12_show_read failure was test-runner interference from two parallel runs. The binary runs cleanly when invoked directly. Baseline is effectively 30 PASS / 4 design-diffs as expected. Let me run a single test to re-confirm.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Run baseline tests/run-tests.sh",
      "activeForm": "Running baseline tests",
      "status": "completed"
    },
    {
      "content": "Create session-27 directory with skeleton notes",
      "activeForm": "Creating session-27 directory",
      "status": "completed"
    },
    {
      "content": "Measure clean-stage2 panic baseline on M5.hs +RTS -A1m and variants",
      "activeForm": "Measuring clean-stage2 panic baseline",
      "status": "in_progress"
    },
    {
      "content": "Try RTS-flag jiggling experiments (-G1, -A512k, -A4m) for repro signal",
      "activeForm": "Trying RTS-flag jiggling",
      "status": "pending"
    },
    {
      "content": "Pick upstream investigation direction (SRT/CAF integrity, info-table audit, allocatePinned, etc.)",
      "activeForm": "Picking upstream investigation direction",
      "status": "pending"
    },
    {
      "content": "End-of-session ritual: writeup + commits + HANDOFF for session 28",
      "activeForm": "Writing session-27 wrapup",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude

Now let me kick off the panic-rate measurement.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/measure-panic-rate.sh pmacg5 10 M5 2>&1 | tee log/session27/measure-A.log",
  "description": "Measure M5.hs panic rate, 10 iters per profile",
  "timeout": 600000,
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: Monitor
Input: {
  "command": "tail -F /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bvyy719yo.output 2>/dev/null | grep --line-buffered -E \"^(=== |  SUMMARY|iter[0-9]+ rc=[^0]|Symptom|UNKNOWN)\"",
  "description": "M5.hs panic-rate harness summary lines",
  "persistent": false,
  "timeout_ms": 2400000
}


---

## 🤖 Claude

While the M5 measurement runs (~10-15 min for 50 iterations), let me read the cap structure / RTS init to check for any PPC32-specific hazards we haven't yet considered.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'PPC32\\|powerpc\\|__PPC__\\|__ppc__\\|__POWERPC__' external/ghc-modern/ghc-9.2.8/rts/sm/*.c external/ghc-modern/ghc-9.2.8/rts/sm/*.h 2>/dev/null | head -20",
  "description": "Search for PPC-specific RTS GC code"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -40 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bvyy719yo.output 2>/dev/null",
  "description": "Check current harness progress"
}


---

## 🤖 Claude

Massive signal: **10/10 PANIC at -A1m default (-G2)** but the first 3 -A1m -G1 iters are PASSING. If -G1 suppresses it, the bug involves multi-generation interaction. Let me wait for more.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -60 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bvyy719yo.output 2>/dev/null",
  "description": "Read latest measurement output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "for i in 1 2 3 4 5 6 7 8 9 10; do echo \"--- iter$i ---\"; head -5 log/session27/M5-a1m.iter${i}.log 2>/dev/null | grep -E 'panic|Found|refineFromInScope|EXC|BAD|0x[0-9a-f]+' | head -3; done",
  "description": "Inspect M5 a1m panic signatures"
}


---

## 🤖 Claude

10/10 panic at -A1m (default -G2), mostly "Found cyclic SCC" — a strong, deterministic, **non-perturbing** repro. Let me check iter8.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -20 log/session27/M5-a1m.iter8.log 2>/dev/null",
  "description": "Check iter8 signature"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'major_gc\\s*=\\|major_gc;\\|^major_gc\\|RtsFlags\\.GcFlags\\.generations' external/ghc-modern/ghc-9.2.8/rts/sm/GC.c external/ghc-modern/ghc-9.2.8/rts/sm/GC.h 2>/dev/null | head -20",
  "description": "Find major_gc semantics"
}


---

## 🤖 Claude

Big result: **`-A1m -G1` is 10/10 PASS** — the bug requires multi-generational GC. `major_gc = (N == generations-1)`, so with -G1 every GC is "major" but there's no promotion. Bug is in the promotion/mut_list path, not major-gc-gated paths.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -40 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bvyy719yo.output 2>/dev/null",
  "description": "Read latest harness output"
}


---

## 🤖 Claude

Excellent baseline data:

| Profile | Pass/Fail | Note |
|---|---|---|
| -A1G | 10/0 | control |
| **-A1m** | **0/10** | **non-perturbing deterministic repro** |
| **-A1m -G1** | **10/0** | **-G1 suppresses the bug** |
| -A512k | 9/1 | rare hit |
| -A4m | 10/0 | too large for the trigger |

Crucial finding: `-G1` (single generation) suppresses the bug. Let me confirm with larger inputs.

---

## 🤖 Claude


🔧 Using tool: mcp__ccd_session__mark_chapter
Input: {
  "title": "Repro nailed; -G1 suppresses",
  "summary": "A1m \u2192 10/10 panic; A1m -G1 \u2192 10/10 pass. Bug requires generational interaction."
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -5 log/session27/M5-a512k.iter4.log 2>/dev/null",
  "description": "Check A512k 1-panic signature"
}


---

## 🤖 Claude

Same family of panic. Now let me confirm `-G1` holds on larger inputs.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-suppression-test.sh",
  "content": "#!/bin/bash\n# Test whether +RTS -A1m -G1 suppresses the stage2 GC bug across\n# multiple workload sizes.  Session 27 already confirmed:\n#   M5.hs +RTS -A1m       \u2192 10/10 panic   (deterministic non-perturbing repro)\n#   M5.hs +RTS -A1m -G1   \u2192 10/10 PASS    (bug suppressed!)\n#\n# Question: does -G1 hold on slightly larger inputs that exercise\n# more of the typechecker / simplifier?\n#\n# Usage:  ./g1-suppression-test.sh [SSH_HOST] [N_ITERS]\n# Default: pmacg5, 5 iters each (we mainly want pass/fail signal).\n\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nN_ITERS=\"${2:-5}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session27\"\nmkdir -p \"$LOGDIR\"\n\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\n\n# Place inputs on pmacg5.\nssh -q \"$PPC_HOST\" 'cat > /tmp/M5plus.hs' <<'EOF'\nmodule M5plus where\nimport Data.List (sort)\nimport qualified Data.Map.Strict as M\nfive :: Int\nfive = 5\nsix :: Int\nsix = 6\nsortedKeys :: M.Map Int String -> [Int]\nsortedKeys m = sort (M.keys m)\nsampleMap :: M.Map Int String\nsampleMap = M.fromList [(1,\"a\"),(2,\"b\"),(3,\"c\"),(4,\"d\"),(5,\"e\")]\nEOF\n\nssh -q \"$PPC_HOST\" 'cat > /tmp/Big.hs' <<'EOF'\nmodule Big where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ntopK :: Ord a => Int -> [a] -> [(a, Int)]\ntopK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs\n  where swap (a, b) = (b, a)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n\nrun_profile () {\n    local input=\"$1\"\n    local label=\"$2\"\n    local rts_flags=\"$3\"\n    local logbase=\"$LOGDIR/${input}-${label}\"\n    echo \"=== $input.hs iters=$N_ITERS flags='$rts_flags' ===\"\n    local pass=0 fail=0\n    : > \"$logbase.summary\"\n    for i in $(seq 1 \"$N_ITERS\"); do\n        local log=\"$logbase.iter${i}.log\"\n        ssh -q \"$PPC_HOST\" \"\n            cd /tmp\n            rm -f ${input}.hi ${input}.o\n            $DYLD $GHC_REAL -c ${input}.hs $rts_flags 2>&1\n            echo \\\"GHC_EXIT=\\$?\\\"\n        \" > \"$log\" 2>&1\n        local rc\n        rc=$(grep -m1 '^GHC_EXIT=' \"$log\" | sed 's/GHC_EXIT=//' || echo '?')\n        local sig=\"\"\n        if [ \"$rc\" = \"0\" ]; then\n            pass=$((pass+1)); sig=\"OK\"\n        else\n            fail=$((fail+1))\n            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found)' \"$log\" 2>/dev/null | head -c 100)\n            [ -z \"$sig\" ] && sig=\"UNKNOWN_FAIL_rc=$rc\"\n        fi\n        printf 'iter%02d rc=%s : %s\\n' \"$i\" \"$rc\" \"$sig\" | tee -a \"$logbase.summary\"\n    done\n    echo \"  SUMMARY: pass=$pass fail=$fail of $N_ITERS\"\n    echo\n}\n\n# M5plus\nrun_profile M5plus  a1m     \"+RTS -A1m -RTS\"\nrun_profile M5plus  a1m-g1  \"+RTS -A1m -G1 -RTS\"\n\n# Big\nrun_profile Big     a1m     \"+RTS -A1m -RTS\"\nrun_profile Big     a1m-g1  \"+RTS -A1m -G1 -RTS\"\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-suppression-test.sh && bash docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-suppression-test.sh pmacg5 5 2>&1 | tee log/session27/g1-suppression.log",
  "description": "Test -G1 suppression on M5plus and Big",
  "timeout": 600000,
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: Monitor
Input: {
  "command": "tail -F /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bef8ve2jl.output 2>/dev/null | grep --line-buffered -E \"^(=== |  SUMMARY|iter[0-9]+ rc=)\"",
  "description": "g1-suppression iter events",
  "persistent": false,
  "timeout_ms": 1200000
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Run baseline tests/run-tests.sh",
      "activeForm": "Running baseline tests",
      "status": "completed"
    },
    {
      "content": "Create session-27 directory with skeleton notes",
      "activeForm": "Creating session-27 directory",
      "status": "completed"
    },
    {
      "content": "Measure clean-stage2 panic baseline on M5.hs +RTS -A1m and variants",
      "activeForm": "Measuring clean-stage2 panic baseline",
      "status": "completed"
    },
    {
      "content": "Confirm -G1 suppression on M5plus.hs and Big.hs",
      "activeForm": "Confirming -G1 suppression on larger inputs",
      "status": "in_progress"
    },
    {
      "content": "Pick upstream investigation direction informed by -G1 suppression (mut_list / promote path / older-gen scavenge)",
      "activeForm": "Picking upstream investigation direction",
      "status": "pending"
    },
    {
      "content": "End-of-session ritual: writeup + commits + HANDOFF for session 28",
      "activeForm": "Writing session-27 wrapup",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -30 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bef8ve2jl.output",
  "description": "Check g1 suppression progress"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'mut_list\\|recordMutable\\|dirty_MUT_VAR\\|dirty_TVAR' external/ghc-modern/ghc-9.2.8/rts/sm/Storage.c external/ghc-modern/ghc-9.2.8/rts/sm/GC.c 2>/dev/null | head -30",
  "description": "Find mut_list write-barrier code"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -20 log/session27/Big-a1m.iter1.log 2>/dev/null",
  "description": "Check Big.hs iter1 unknown fail"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -30 log/session27/Big-a1m.iter3.log 2>/dev/null ; echo \"---\"; head -30 log/session27/Big-a1m.iter2.log 2>/dev/null ; echo \"---\"; head -30 log/session27/Big-a1m.iter4.log 2>/dev/null",
  "description": "Compare Big.hs iter3 (OK) vs iter2 (panic) vs iter4 (unknown)"
}


---

## 🤖 Claude

Big.hs has a (genuine) type error that interacts with the corruption signature — making it a noisy repro. Let me let this run finish and then write a clean Big.hs.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -20 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/bef8ve2jl.output 2>/dev/null",
  "description": "Check g1 test progress"
}


---

## 🤖 Claude

Let me check what host ghc says about my buggy Big.hs to disambiguate.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat > /tmp/Big-test.hs <<'EOF'\nmodule Big where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ntopK :: Ord a => Int -> [a] -> [(a, Int)]\ntopK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs\n  where swap (a, b) = (b, a)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n$HOME/.local/ghc-9.2.8/bin/ghc -c /tmp/Big-test.hs -o /tmp/Big-test.o 2>&1 | head -25",
  "description": "Compile Big.hs with host ghc to see expected error"
}


---

## 🤖 Claude

`-G1` doesn't fully suppress on Big.hs — it changes the corruption signature. Let me fix the type error in Big.hs and re-test with a clean program.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat > /tmp/Big2.hs <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ntopK :: Ord a => Int -> [a] -> [(Int, a)]\ntopK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs\n  where swap (a, b) = (b, a)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n$HOME/.local/ghc-9.2.8/bin/ghc -c /tmp/Big2.hs -o /tmp/Big2.o 2>&1 | head -5; echo \"host RC=$?\"; rm -f /tmp/Big2.o /tmp/Big2.hi",
  "description": "Verify clean Big2.hs compiles on host"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-big2-test.sh",
  "content": "#!/bin/bash\n# Re-test -G1 suppression with a CORRECT Big.hs (no type errors).\n# Session 27's first Big.hs had a real type error that masked the\n# corruption signal; this script uses Big2.hs which compiles cleanly\n# on host ghc.\n#\n# Usage:  ./g1-big2-test.sh [SSH_HOST] [N_ITERS]\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nN_ITERS=\"${2:-10}\"\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../../\" && pwd)\"\nLOGDIR=\"$REPO_ROOT/log/session27\"\nmkdir -p \"$LOGDIR\"\n\nGHC_REAL=\"/opt/ghc-stage2/bin/ghc-real\"\nDYLD=\"DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib\"\n\nssh -q \"$PPC_HOST\" 'cat > /tmp/Big2.hs' <<'EOF'\nmodule Big2 where\nimport Data.List (sort, group)\nimport qualified Data.Map.Strict as M\nimport Data.Maybe (fromMaybe)\n\nfreqMap :: Ord a => [a] -> M.Map a Int\nfreqMap xs = M.fromListWith (+) [(x, 1) | x <- xs]\n\ntopK :: Ord a => Int -> [a] -> [(Int, a)]\ntopK k xs = take k . reverse . sort . map swap . M.toList $ freqMap xs\n  where swap (a, b) = (b, a)\n\ndedup :: Ord a => [a] -> [a]\ndedup = map head . group . sort\n\ncountOf :: Ord a => a -> M.Map a Int -> Int\ncountOf k m = fromMaybe 0 (M.lookup k m)\n\nshift :: Int -> [Int] -> [Int]\nshift n = map (+ n)\n\nscaleAndShift :: Int -> Int -> [Int] -> [Int]\nscaleAndShift s n = map (\\x -> x * s + n)\n\nallPositive :: [Int] -> Bool\nallPositive = all (> 0)\n\ncumsum :: Num a => [a] -> [a]\ncumsum = scanl1 (+)\nEOF\n\nrun_profile () {\n    local label=\"$1\"\n    local rts_flags=\"$2\"\n    local logbase=\"$LOGDIR/Big2-${label}\"\n    echo \"=== Big2.hs iters=$N_ITERS flags='$rts_flags' ===\"\n    local pass=0 fail=0\n    for i in $(seq 1 \"$N_ITERS\"); do\n        local log=\"$logbase.iter${i}.log\"\n        ssh -q \"$PPC_HOST\" \"\n            cd /tmp\n            rm -f Big2.hi Big2.o\n            $DYLD $GHC_REAL -c Big2.hs $rts_flags 2>&1\n            echo \\\"GHC_EXIT=\\$?\\\"\n        \" > \"$log\" 2>&1\n        local rc\n        rc=$(grep -m1 '^GHC_EXIT=' \"$log\" | sed 's/GHC_EXIT=//' || echo '?')\n        local sig\n        if [ \"$rc\" = \"0\" ]; then\n            pass=$((pass+1)); sig=\"OK\"\n        else\n            fail=$((fail+1))\n            sig=$(grep -m1 -E '(panic|Bus error|Segmentation|EXC_BAD_ACCESS|<<loop>>|internal error|refineFromInScope|depSortStgBinds|variable not found|not in scope)' \"$log\" 2>/dev/null | head -c 120)\n            [ -z \"$sig\" ] && sig=\"UNKNOWN_FAIL_rc=$rc\"\n        fi\n        printf 'iter%02d rc=%s : %s\\n' \"$i\" \"$rc\" \"$sig\"\n    done\n    echo \"  SUMMARY: pass=$pass fail=$fail of $N_ITERS\"\n    echo\n}\n\nrun_profile a1g     \"+RTS -A1G -RTS\"\nrun_profile a1m     \"+RTS -A1m -RTS\"\nrun_profile a1m-g1  \"+RTS -A1m -G1 -RTS\"\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-big2-test.sh && bash docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-big2-test.sh pmacg5 10 2>&1 | tee log/session27/g1-big2.log",
  "description": "Test -G1 suppression with clean Big2.hs",
  "timeout": 900000,
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: Monitor
Input: {
  "command": "tail -F /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/barquq4m8.output 2>/dev/null | grep --line-buffered -E \"^(=== |  SUMMARY|iter[0-9]+ rc=[^0])\"",
  "description": "Big2 test progress (only print failures + section headers)",
  "persistent": false,
  "timeout_ms": 1200000
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/GC.c",
  "offset": 450,
  "limit": 120
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'scavenge_capability_mut_lists\\b' external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c | head; echo \"---\"; sed -n '/^scavenge_capability_mut_lists\\b/,/^}/p' external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c | head -40",
  "description": "Read scavenge_capability_mut_lists"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 1680,
  "limit": 90
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n '^scavenge_mutable_list\\|^scavenge_mutable_list1' external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c | head",
  "description": "Find scavenge_mutable_list defn"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/sm/Scav.c",
  "offset": 1592,
  "limit": 100
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -20 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/barquq4m8.output 2>/dev/null",
  "description": "Big2 progress"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -25 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/barquq4m8.output 2>/dev/null",
  "description": "Big2 final results"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -15 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/barquq4m8.output 2>/dev/null",
  "description": "Big2 g1 progress"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -5 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/barquq4m8.output 2>/dev/null; echo \"---\"; ps -p $(pgrep -f g1-big2-test.sh | head -1) 2>/dev/null | head",
  "description": "Big2 final status"
}


---

## 🤖 Claude

Critical finding: **Big2.hs `-A1m -G1` is 10/10 fail** — worse than without `-G1`. The bug has at least two distinct corruption modes:
1. STG-stage panic family (suppressed by -G1, e.g. M5.hs)
2. Typecheck-stage corruption (NOT suppressed by -G1, e.g. Big2.hs)

Let me confirm Big2.hs at -A1G is clean.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -E '^=== Big2|SUMMARY|iter[0-9]+ rc=' /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/barquq4m8.output | head -20",
  "description": "Confirm Big2 -A1G result"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -40 log/session27/Big2-a1m-g1.iter1.log 2>/dev/null",
  "description": "Read full Big2 -G1 panic trace"
}


---

## 🤖 Claude

Now I have an excellent data set. Let me write up the findings and update the session docs.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Run baseline tests/run-tests.sh",
      "activeForm": "Running baseline tests",
      "status": "completed"
    },
    {
      "content": "Create session-27 directory with skeleton notes",
      "activeForm": "Creating session-27 directory",
      "status": "completed"
    },
    {
      "content": "Measure clean-stage2 panic baseline on M5.hs +RTS -A1m and variants",
      "activeForm": "Measuring clean-stage2 panic baseline",
      "status": "completed"
    },
    {
      "content": "Confirm -G1 suppression on M5plus.hs and Big.hs",
      "activeForm": "Confirming -G1 suppression on larger inputs",
      "status": "completed"
    },
    {
      "content": "Read mut_list / write-barrier code paths in RTS for upstream investigation",
      "activeForm": "Reading mut_list / write-barrier code paths",
      "status": "in_progress"
    },
    {
      "content": "Write up session-27 findings + README + HANDOFF for session 28",
      "activeForm": "Writing up session-27",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn 'TcLclEnv\\b' external/ghc-modern/ghc-9.2.8/compiler/GHC/Tc/Types.hs 2>/dev/null | head -10; echo \"---\"; grep -rn 'tcl_env\\b' external/ghc-modern/ghc-9.2.8/compiler/GHC/Tc/Types.hs 2>/dev/null | head -10",
  "description": "Find TcLclEnv data type"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/compiler/GHC/Tc/Types.hs",
  "offset": 730,
  "limit": 50
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/findings.md",
  "content": "# Session 27 findings \u2014 non-perturbing repro nailed; two distinct corruption modes; `-G1` partial workaround\n\n## TL;DR\n\n- **The clean-stage2 production bug is a deterministic non-perturbing\n  repro:** `M5.hs +RTS -A1m -RTS` panics 10/10 times.  Confirmed on\n  the clean rebuild + redeploy at session-26 end.\n- **`+RTS -A1m -G1` (single-generation) fully suppresses the bug on\n  small inputs** (M5.hs 10/10 OK, M5plus.hs 5/5 OK).  This is a new,\n  cheaper-than-`-A1G` workaround for the M5.hs-sized panic family.\n- **`-G1` does NOT suppress on slightly larger inputs.**  Big2.hs\n  (a clean Haskell module ~30 LOC with Data.Map.Strict + small\n  functions) compiles 10/10 OK at `-A1G`, but fails 9/10 at `-A1m`\n  AND fails 10/10 at `-A1m -G1`.  -G1 changes the corruption\n  signature, doesn't eliminate it.\n- **The bug has at least two distinct manifestations** \u2014 the\n  M5.hs-style STG-time panic family (depSortStgBinds /\n  refineFromInScope / \"variable not found\") and the Big2.hs-style\n  **typecheck-time corruption** (`* GHC internal error: 'swap' is\n  not in scope during type checking, but it passed the renamer`).\n  The TC-time variant is a genuinely new signature first observed\n  this session \u2014 sessions 17\u201326 catalogued only the STG-time family.\n- **Top hypothesis revised:** the STG-time variant is consistent\n  with a missed-`mut_list`-entry / promotion-path bug (because\n  `-G1` disables the whole older-gen mut_list scavenge code path\n  via `scavenge_capability_mut_lists`'s `for (g = generations-1;\n  g > N; g--)` loop being empty).  But the TC-time variant runs\n  fine under `-G1` so EITHER (a) the bug has two mechanisms, OR\n  (b) one mechanism but two victim data structures and the TC-env\n  IntMap doesn't go through the gen-1 mut_list at all (it lives\n  in gen-0 long enough to be fully corrupted by a different code\n  path).  Need a single-cause vs two-cause discriminator.\n- v0.12.0 ships unchanged.\n\n## Data \u2014 clean-stage2 panic rates\n\nAll on pmacg5 (PowerMac G5 / Tiger 10.4.11) against `/opt/ghc-stage2/bin/ghc-real`,\nwhich was rebuilt+redeployed clean at session-26 end (no PROBE patches,\nmatches v0.12.0).\n\n### M5.hs (3 lines, no imports)\n\n```haskell\nmodule M5 where\nfive = (5::Int)\nsix = (6::Int)\n```\n\n| RTS flags             | iters | pass | fail | dominant symptom                          |\n|-----------------------|------:|-----:|-----:|-------------------------------------------|\n| `+RTS -A1G -RTS`      |   10  |  10  |   0  | control                                    |\n| **`+RTS -A1m -RTS`**  |   10  |   0  |  10  | **depSortStgBinds cyclic SCC (9/10), 1\u00d7 refineFromInScope** |\n| **`+RTS -A1m -G1 -RTS`** |  10  |  10  |   0  | **bug suppressed**                         |\n| `+RTS -A512k -RTS`    |   10  |   9  |   1  | 1\u00d7 \"variable not found\"                    |\n| `+RTS -A4m -RTS`      |   10  |  10  |   0  | suppressed (larger nursery)                |\n\n### M5plus.hs (Data.List + Data.Map.Strict imports, 5 small bindings)\n\n| RTS flags             | iters | pass | fail | symptom        |\n|-----------------------|------:|-----:|-----:|----------------|\n| `+RTS -A1m -RTS`      |    5  |   4  |   1  | 1\u00d7 panic       |\n| `+RTS -A1m -G1 -RTS`  |    5  |   5  |   0  | suppressed     |\n\n### Big2.hs (same imports + 9 small typed functions; compiles fine on host)\n\n| RTS flags             | iters | pass | fail | dominant symptom                                                   |\n|-----------------------|------:|-----:|-----:|--------------------------------------------------------------------|\n| `+RTS -A1G -RTS`      |   10  |  10  |   0  | control                                                             |\n| **`+RTS -A1m -RTS`**  |   10  |   1  |   9  | **\"`swap` not in scope during type checking, but it passed the renamer\" (8\u00d7), 1\u00d7 depSortStgBinds panic** |\n| **`+RTS -A1m -G1 -RTS`** |  10  |   0  |  10  | **same \"`swap` not in scope\" (10\u00d7) \u2014 `-G1` does NOT suppress this variant** |\n\nThe \"`swap`-not-in-scope\" message includes the full `tcl_env`\n(TcTypeEnv) at the moment of lookup, which lists 9 entries (4 outer\ntype-variable / argument bindings + 5 top-level identifiers, including\n`topK` and `freqMap`).  `swap` is the `where`-bound local that should\nbe the 10th entry; it's missing.  See\n[`../../../log/session27/Big2-a1m-g1.iter1.log`](../../../log/session27/Big2-a1m-g1.iter1.log)\nfor a full dump.\n\n### Big.hs (Big2.hs with a deliberate type-error variant) \u2014 discarded\n\nFirst attempt at a larger input had a real type error in `topK`\n(returned `[(a, Int)]` instead of `[(Int, a)]`).  Cross stage2 at\n`-A1m`: mix of real-type-error (good!), refineFromInScope panic,\nand false-success.  At `-A1m -G1`: 5/5 \"swap not in scope\" \u2014 the\nGC corruption overrode the real type error in the report.  Useful\ndata point that the corruption can mask or replace legitimate error\nmessages, but the noisy signal led us to rewrite as Big2.hs (which\ncompiles cleanly on host).\n\n## The two corruption signatures\n\n### STG-time family (sessions 17\u201326 catalogue)\n\n- `depSortStgBinds Found cyclic SCC` \u2014 fires in `GHC.Stg.DepAnal`\n  when SCC analysis of top-level STG bindings finds a cyclic SCC.\n  Implies the FV set of a binding contains a name that's either a\n  self-reference or a sibling in the same group, which shouldn't\n  happen for top-level bindings.\n- `refineFromInScope` \u2014 fires in\n  `GHC.Core.Opt.Simplify.Env::refineFromInScope` when a local Var\n  isn't found in the simplifier's InScopeSet.  Implies VarEnv /\n  IntMap corruption.\n- `GHC.StgToCmm.Env: variable not found` \u2014 `pprPanic` at line 153 of\n  `compiler/GHC/StgToCmm/Env.hs`.  Same family \u2014 VarEnv lookup fails.\n\nAll three suppressed by `-G1` on M5.hs.\n\n### TC-time family (newly observed this session)\n\n- `GHC internal error: 'swap' is not in scope during type checking,\n  but it passed the renamer` \u2014 fires in `GHC.Tc.Utils.Env` (or\n  similar) when the renamer's OccName\u2192Name map (`LocalRdrEnv`) and\n  the typechecker's Name\u2192TcTyThing map (`TcTypeEnv` / `tcl_env`)\n  disagree.\n\nNOT suppressed by `-G1`.  Big2.hs hits this 10/10 under\n`+RTS -A1m -G1`.\n\n## Why `-G1` suppresses one family but not the other\n\n`scavenge_capability_mut_lists` at `rts/sm/Scav.c:1714`:\n```c\nfor (uint32_t g = RtsFlags.GcFlags.generations-1; g > N; g--) {\n    scavenge_mutable_list(cap->saved_mut_lists[g], &generations[g]);\n    freeChain_sync(cap->saved_mut_lists[g]);\n    cap->saved_mut_lists[g] = NULL;\n}\n```\n\nWith `generations=1` (`-G1`), the loop bound is `g > N` starting from\n`g = 0`, so the loop body executes 0 times.  **The entire older-gen\nmut_list scavenging code path is dead under `-G1`.**\n\nIf the bug were *only* \"mut_list missing some entries \u2192 minor GCs\nmiss roots from older gens \u2192 stale gen-0 pointers in promoted gen-1\ndata,\" `-G1` would fix all cases.  The fact that Big2.hs's TC-time\ncorruption persists under `-G1` means there's a second mechanism\nthat doesn't depend on the older-gen mut_list.\n\nTwo plausible readings:\n\n1. **Two bugs.**  A: missing mut_list entry on PPC32 (write-barrier\n   bug, mutator-side, in Updates.cmm or similar).  B: a separate\n   corruption that hits even with single-gen GC.  Both produce\n   similar-looking IntMap / VarEnv damage, surfacing as different\n   panic messages depending on which compilation phase is unlucky.\n\n2. **One bug, two manifestations.**  A single GC bug \u2014 e.g.,\n   `scavenge_one` mis-scavenging some closure type on PPC32 \u2014\n   corrupts heap state.  With `-G2`, gen-0 churn is fast and the\n   STG/Simplifier data structures get caught.  With `-G1`,\n   different objects survive different lengths and the\n   typecheck-time IntMap gets caught instead.  Same heap-level\n   damage; different victims.\n\nThe (1) reading predicts that fixing the mut_list path eliminates\nthe M5.hs panic family but leaves the Big2.hs TC-time error.  The\n(2) reading predicts that fixing the (one) bug eliminates both.\n\n## Upstream code surface relevant to the mut_list hypothesis\n\n- `rts/sm/Scav.c::scavenge_capability_mut_lists` (line 1697): the\n  loop that re-scavenges older-gen mut_lists.  Already inspected;\n  no obvious PPC32-specific issue, but the work it does is iterate\n  blocks (`bd`), walk slot pointers (`q = bd->start..bd->free`),\n  and call `scavenge_one(*q)`.  If `bd->free` is wrong on PPC32\n  for a freshly-stashed block, entries would be skipped.\n- `rts/sm/Storage.c::dirty_MUT_VAR` (line 1402): the C-level write\n  barrier.  Adds the closure to `mut_lists[g]` via\n  `recordClosureMutated`.\n- `rts/Updates.cmm` (not yet read): Cmm-level write barriers for\n  IND_OLDGEN, BLACKHOLE updates, thunk \u2192 IND transitions.\n- `rts/PrimOps.cmm::stg_writeMutVarzh` and friends: mutator-side\n  mut_var update + dirty-flag.\n- `compiler/GHC/StgToCmm/Bind.hs::emitBlackHoleCode`: where\n  blackholing happens in Cmm.  If the BH write barrier on PPC32\n  is wrong, gen-1 \u2192 gen-0 IND pointers might be missed.\n\n## Open hypotheses for the TC-time corruption\n\nSessions 17\u201326 implicitly assumed all symptoms shared a cause.  The\nnew TC-time signature makes that less certain.  Some candidates that\ndon't require the mut_list path:\n\n- **Static-closure / SRT scavenging.**  `scavenge_thunk_srt`,\n  `scavenge_fun_srt`, `scavenge_static`.  These run on EVERY GC under\n  `-G1` (since major_gc is always true with single gen) AND on major\n  GCs under `-G2`.  If they have a PPC32-specific bug, both regimes\n  would surface it.\n- **Info-table contents.**  The static_link / static_objects chain\n  uses STATIC_LINK macros that decode pointer fields from info\n  tables.  PPC32 alignment / endian could subtly break the chain.\n- **PAP / AP scavenging.**  `scavenge_PAP_payload` walks function-\n  argument lists using `GET_FUN_LARGE_BITMAP` and friends.  If any\n  bitmap decoding is wrong on PPC32, PAP/AP arguments could be\n  mis-scavenged.  (Sessions 21\u201322 ruled out stack-frame bitmaps;\n  PAP/AP bitmaps are a separate codepath.)\n- **`scavenge_AP_stack`** for STACK-typed thunks.  Stacks-as-thunks\n  use stack-frame bitmaps for their body \u2014 same machinery as session\n  21 \u2014 but the *interaction* between the AP_STACK header and the\n  bitmap-tagged stack inside might be wrong.\n\n## What's next\n\nSession 28 should pick from the following, in priority order:\n\n1. **Distinguish \"one bug, two victims\" vs \"two bugs.\"**  Cheapest\n   test: re-introduce a slim RTS-side probe (e.g. count mut_list\n   entries per GC, print at exit) that doesn't touch Haskell code\n   at all.  Run on M5.hs `-A1m` and Big2.hs `-A1m`.  If the mut_list\n   bookkeeping looks identical (same lengths, same per-gen counts)\n   when one crashes and the other doesn't, the mut_list-missing\n   hypothesis becomes harder to defend.\n2. **Audit `rts/Updates.cmm` and `rts/PrimOps.cmm`'s\n   `dirty_MUT_VAR_GC` / `recordClosureMutated` machinery for PPC32-\n   isms.**  Especially: pointer arithmetic when growing the mut_list,\n   info-pointer reads/writes in the write-barrier hot path.\n3. **Read `scavenge_thunk_srt` / `scavenge_fun_srt` plus\n   `scavenge_static`** with PPC32 eyes \u2014 alignment, endian,\n   `STATIC_LINK` macro expansion.  If a bug there fires on every\n   major GC (including `-G1`), it would explain why Big2.hs fails\n   regardless of `-G`.\n4. **Try `+RTS -A1m -G1 -F0.5`** (lower the promotion-survival\n   factor) on Big2.hs to see if reducing object lifetime fixes\n   the TC-time variant.\n\n## Files added this session\n\n- [`README.md`](README.md), `findings.md`, `HANDOFF.md`, `commits.md`\n  \u2014 writeup.\n- [`scripts/measure-panic-rate.sh`](scripts/measure-panic-rate.sh) \u2014\n  per-profile harness (M5.hs across `-A1G`, `-A1m`, `-A1m -G1`,\n  `-A512k`, `-A4m`).\n- [`scripts/g1-suppression-test.sh`](scripts/g1-suppression-test.sh)\n  \u2014 M5plus.hs and Big.hs `-G1` suppression tests (Big.hs version\n  had a real type error; results kept for context but Big.hs\n  itself was discarded).\n- [`scripts/g1-big2-test.sh`](scripts/g1-big2-test.sh) \u2014 Big2.hs\n  (corrected) `-A1G`, `-A1m`, `-A1m -G1` suite.\n- Run logs at [`../../../log/session27/`](../../../log/session27/)\n  (gitignored).\n"
}


---

## 🤖 Claude

Now the README narrative.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/README.md",
  "content": "# Session 27 \u2014 stage2 GC bug, round 9 (non-perturbing repro nailed; `-G1` is a partial workaround; bug has two distinct corruption modes)\n\n**Dates:** 2026-05-12 (same-day continuation of session 26).\n\n**Status on arrival:** v0.12.0 ships unchanged.  Stage2 ghc on\npmacg5 uses the `+RTS -A1G` workaround.  Session 26 ruled out\nhypothesis (a) \"BS reaches `mkFastStringByteString` with non-pinned\nMBA\" via direct observation (PROBE26 saw 150/150 PlainPtr-pinned, 0\nUNPINNED).  PROBE26 also perturbed the M5.hs SIGSEGV away entirely\n(0/3 vs. session 23's 5/5).  Sessions 23\u201325's PROBE22POISON crash\nsignature `_blk_c7te+112 / 0xdeadbeef` was reread as a probe artefact\ncomposite: the underlying bug is the panics that session 17 first\ncataloged.  At session-26 end, clean stage2 was re-confirmed on M5.hs\n`+RTS -A1m` as 4/5 panic.  Session-26 HANDOFF queued \"re-establish a\nnon-perturbing deterministic repro\" as top priority for session 27.\n\n**Status on exit:**\n\n- **Deterministic non-perturbing repro nailed:** `M5.hs +RTS -A1m`\n  on clean stage2 panics **10/10**.  No instrumentation needed.\n- **`+RTS -A1m -G1` (single-generation) fully suppresses the M5.hs\n  panic family** (10/10 OK).  It does NOT suppress all variants of\n  the bug \u2014 Big2.hs `+RTS -A1m -G1` fails 10/10 with a typecheck-\n  time corruption signature.\n- **A second, previously-undocumented corruption signature was\n  discovered:** `* GHC internal error: 'swap' is not in scope\n  during type checking, but it passed the renamer`.  Fires\n  deterministically on a small clean module that uses\n  Data.Map.Strict + a `where`-bound local function.  Sessions\n  17\u201326 catalogued only the STG-time family\n  (depSortStgBinds / refineFromInScope / \"variable not found\");\n  this typecheck-time variant is new.\n- **Hypothesis revised:** the STG-time variant is consistent with\n  a missed `mut_list` entry on older-gen objects (because `-G1`\n  disables the older-gen mut_list scavenge path entirely).  The\n  TC-time variant suppressed neither by `-G1` nor by the same\n  treatment, so EITHER (a) it's a second bug with a different\n  mechanism, OR (b) one bug with two distinct victim data\n  structures \u2014 needs more probing to discriminate.\n- v0.12.0 unchanged.  Stage2 source tree clean.  No commits to the\n  GHC tree this session; only session notes + harness scripts.\n\nHANDOFF for session 28: see [`HANDOFF.md`](HANDOFF.md).  Top of\nqueue: design a slim RTS-side probe (no Haskell-side perturbation)\nthat counts mut_list entries / scavenge events, to discriminate\n\"one bug\" vs \"two bugs.\"\n\n## What we did, in order\n\n### Step 1 \u2014 confirm baseline green\n\n`tests/run-tests.sh`: 29 PASS / 4 design diffs.  (One run earlier\nhad a 12_show_read transient failure caused by accidentally launching\ntwo parallel copies of the test runner; re-running 12_show_read\nmanually succeeded.  Baseline is effectively v0.12.0 unchanged.)\n\n### Step 2 \u2014 write the panic-rate harness\n\n[`scripts/measure-panic-rate.sh`](scripts/measure-panic-rate.sh)\nloops `ghc-real -c M5.hs $RTS_FLAGS` N times against pmacg5 via ssh,\ncaptures stdout/stderr per iter, and classifies each run as PASS or\na fail-symptom-bucket.  Tested 5 RTS-flag profiles:\n`-A1G` (control), `-A1m` (load-bearing), `-A1m -G1` (single-gen),\n`-A512k` (smaller area), `-A4m` (larger area).\n\n### Step 3 \u2014 measure M5.hs panic rate\n\nResult on clean stage2 (no PROBE instrumentation):\n\n```\n=== M5 iters=10 flags='+RTS -A1G  -RTS' === pass=10 fail=0\n=== M5 iters=10 flags='+RTS -A1m  -RTS' === pass= 0 fail=10  (9\u00d7 depSortStgBinds, 1\u00d7 refineFromInScope)\n=== M5 iters=10 flags='+RTS -A1m -G1' === pass=10 fail= 0\n=== M5 iters=10 flags='+RTS -A512k -RTS'=== pass= 9 fail= 1\n=== M5 iters=10 flags='+RTS -A4m   -RTS'=== pass=10 fail= 0\n```\n\n**Key observation: `-A1m` is the Goldilocks zone \u2014 `-A1G` and `-A4m`\nare too large (no GC fires); `-A512k` is too small or has different\nallocation behaviour; `-A1m` triggers the bug 10/10.  And `-G1`\n(single-generation) suppresses the bug entirely.**\n\n`-A1G` baseline confirmation matches v0.11.0's ship workaround.\n\n### Step 4 \u2014 confirm `-G1` suppression on slightly larger inputs\n\n[`scripts/g1-suppression-test.sh`](scripts/g1-suppression-test.sh)\nruns M5plus.hs (Data.List + Data.Map.Strict imports, 5 small bindings)\nand Big.hs through the same matrix.\n\nM5plus.hs at `-A1m`: 4 OK / 1 panic (the panic surfaced even at lower\ninput size).  At `-A1m -G1`: 5 OK / 0 fail \u2014 **`-G1` suppression\nholds**.\n\nBig.hs (first version) had a deliberate **real type error** in\n`topK`'s return-type signature, intended to give a deterministic\nnon-GC failure to compare against.  Result: at `-A1m`, mix of real\ntype error / panic / false-success.  At `-A1m -G1`: 5/5 reports a\nDIFFERENT error \u2014 `swap' is not in scope during type checking, but\nit passed the renamer`.  That's a **GC-corruption signature** masking\nthe real type error.\n\n### Step 5 \u2014 repeat with a syntactically clean Big2.hs\n\nRewrote `Big.hs` \u2192 `Big2.hs` so it compiles cleanly on host ghc\n(verified: `host RC=0`).  Same matrix:\n\n```\n=== Big2.hs iters=10 flags='+RTS -A1G   -RTS' === pass=10 fail=0  (control)\n=== Big2.hs iters=10 flags='+RTS -A1m   -RTS' === pass= 1 fail=9  (1\u00d7 panic, 8\u00d7 \"swap not in scope\")\n=== Big2.hs iters=10 flags='+RTS -A1m -G1 -RTS' === pass= 0 fail=10 (10\u00d7 \"swap not in scope\")\n```\n\n**`-G1` does NOT suppress the Big2.hs corruption.**  It changes the\nsignature: under `-A1m -G2` we get a mix of compile-success and the\nTC-time error; under `-A1m -G1` we get the TC-time error 10/10.\n\n### Step 6 \u2014 interpretation\n\nCombined data:\n\n| Input    | `-A1G`  | `-A1m`               | `-A1m -G1`              |\n|----------|---------|----------------------|-------------------------|\n| M5.hs    | 10/0    | 0/10 STG-panic       | 10/0 \u2713                  |\n| M5plus.hs| \u2014       | 4/1 STG-panic        | 5/0 \u2713                   |\n| Big2.hs  | 10/0    | 1/9 TC-corruption    | 0/10 TC-corruption      |\n\nTwo distinct corruption modes:\n\n- **STG-time family** (depSortStgBinds, refineFromInScope, \"variable\n  not found\").  Suppressed by `-G1`.\n- **TC-time family** (`swap` not in scope during type checking).\n  NOT suppressed by `-G1`.\n\nThe TC-time error includes the full `tcl_env` (TcTypeEnv) at the\npanic site, which lists 9 entries \u2014 4 outer + 5 top-level\nidentifiers \u2014 but missing the `where`-bound `swap`.  The renamer\nDID add `swap` to its scope; the typechecker DID look at the\ncorrect environment; the entry just isn't there.  Classic GC-eaten-\nIntMap-node.\n\nThe fact that `-G1` disables `scavenge_capability_mut_lists`'s\nolder-gen scavenge loop (`for (g = generations-1; g > N; g--)` \u2014\nempty when generations=1) is consistent with the STG-time bug\nbeing in the older-gen mut_list path.  The TC-time bug must\ninvolve a different mechanism (or hit a different victim data\nstructure).\n\nSee [`findings.md`](findings.md) for the full analysis.\n\n### Step 7 \u2014 no GHC-tree edits this session\n\nSource tree clean throughout.  We only added session notes and\nharness scripts.  No rebuild, no redeploy.\n\n## Status on exit\n\n- **v0.12.0 unchanged.**  Stage2 ships with `+RTS -A1G` wrapper.\n- **No GHC-tree source edits this session.**\n- **Stage2 ghc on pmacg5 is the clean rebuild from session-26 end**\n  (unchanged).\n- **Logs at** [`../../../log/session27/`](../../../log/session27/)\n  (gitignored).\n- **HANDOFF for session 28** queues mut_list / write-barrier audit\n  and a single-cause-vs-two-causes probe design.\n\n## Files added this session\n\n- [`README.md`](README.md), [`findings.md`](findings.md),\n  [`HANDOFF.md`](HANDOFF.md), `commits.md` \u2014 writeup.\n- [`scripts/measure-panic-rate.sh`](scripts/measure-panic-rate.sh)\n  \u2014 M5.hs panic-rate harness across 5 RTS profiles.\n- [`scripts/g1-suppression-test.sh`](scripts/g1-suppression-test.sh)\n  \u2014 M5plus.hs + Big.hs (initial buggy version) `-G1` suppression test.\n- [`scripts/g1-big2-test.sh`](scripts/g1-big2-test.sh) \u2014 Big2.hs\n  (syntactically clean) `-A1G / -A1m / -A1m -G1` matrix.\n"
}


---

## 🤖 Claude

Now the HANDOFF for session 28.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md",
  "content": "# Handoff from session 27 \u2192 session 28\n\n**For:** the next claude session.\n**From:** session 27 (non-perturbing repro nailed; `-G1` partial\nworkaround; bug has two distinct corruption modes; 2026-05-12).\n**Recommended pickup:** decide between \"one bug, two victims\" vs\n\"two bugs\" with a slim RTS-side probe.  Then audit the mut_list /\nwrite-barrier path for the STG-time variant.\n\n## TL;DR (mandatory read)\n\n- **Non-perturbing deterministic repro nailed:** `M5.hs +RTS -A1m`\n  on clean stage2 panics **10/10** with the STG-time panic family\n  (depSortStgBinds, refineFromInScope, \"variable not found\").\n- **`+RTS -A1m -G1` (single generation) fully suppresses M5.hs**\n  (10/10 OK) and M5plus.hs (5/5 OK).\n- **`-G1` does NOT suppress Big2.hs** (a clean ~30-LOC module that\n  imports Data.Map.Strict and has a `where`-bound local function):\n  10/10 fail with a **new corruption signature** \u2014 `* GHC internal\n  error: 'swap' is not in scope during type checking, but it\n  passed the renamer`.\n- **The bug has at least two distinct corruption modes.**  Sessions\n  17\u201326 catalogued only the STG-time family; the TC-time variant is\n  new in session 27.  Either: (a) two separate bugs, OR (b) one bug\n  with two victim data structures.  Need a discriminator.\n- v0.12.0 ships unchanged.  Source tree clean.  No commits to\n  external/ghc-modern this session.\n\n## Read in order\n\n1. **This file.**\n2. [`README.md`](README.md) \u2014 narrative of session 27.\n3. [`findings.md`](findings.md) \u2014 full data tables and analysis.\n4. (Reference) Session 26 [`HANDOFF.md`](../2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md)\n   for the context this session built on.\n5. (Reference) Session 17 [`GC-BUG-FOUND.md`](../2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md)\n   for the original panic catalogue.\n\n## What to NOT redo\n\n- **Don't bother with PROBE26-style Haskell-side BS classifiers.**\n  Session 26 ruled out BS-pinning-invariant theory and showed that\n  Haskell-side instrumentation in `mkFastStringByteString` perturbs\n  the bug away on M5.hs.\n- **Don't re-prove the BS-pinning theory is dead.**  150/150\n  PlainPtr-pinned, hypothesis (a) rejected.\n- **Don't audit Catch.hs StackRep, mkLivenessBits, stackMapToLiveness,\n  LayoutStack, or any stack-frame bitmap path.**  Sessions 21\u201324\n  settled them.\n- **Don't poison the stack (PROBE22 / PROBE23 family).**  Both have\n  served their purpose and add probe artefacts that confuse the\n  picture.\n- **Don't re-measure the panic rate on M5.hs.**  We have 10/10 from\n  this session; treat it as deterministic.\n\n## What to try next, in priority order\n\n### Top: discriminate \"one bug, two victims\" vs \"two bugs\"\n\nThe cleanest single experiment: write a **slim RTS-side probe** that\nprints, at every GC, a small fixed-size summary:\n\n- `gc_no`, `N` (gen being collected), `major_gc`\n- Per-gen: `mut_list` length in entries (`countOccupied(saved_mut_lists[g])`)\n- Per-gen: blocks promoted in / out\n- Total `static_objects` chain length scavenged this GC\n\nRun on:\n- M5.hs `+RTS -A1m` (10/10 panic \u2014 STG-time)\n- M5.hs `+RTS -A1m -G1` (10/10 OK \u2014 bug suppressed)\n- Big2.hs `+RTS -A1m -G1` (10/10 fail \u2014 TC-time)\n- Big2.hs `+RTS -A1G` (10/10 OK \u2014 bug suppressed by no-GC)\n\nCompare the per-GC summaries.  If the mut_list bookkeeping looks\n*identical* between M5.hs (`-G1` clean) and Big2.hs (`-G1` broken),\nthen the mut_list path isn't the cause of the TC-time variant; the\nTC-time variant has a different mechanism.\n\nThis probe is **fully RTS-side** so it doesn't perturb Cmm codegen\non the Haskell side \u2014 important after session 26's PROBE26 lesson.\nCost: ~1 RTS rebuild (~3 min for `rts/sm/GC.c` alone via Hadrian)\n+ N runs.  Cheap.\n\n### Second: audit `rts/Updates.cmm` and write-barrier code\n\nIf `-G1` suppression on M5.hs is real, the bug is somewhere in the\nolder-gen mut_list machinery \u2014 either:\n- The mutator-side write barrier in `Updates.cmm` /\n  `PrimOps.cmm::stg_writeMutVarzh` etc. is failing to add some\n  closures to the mut_list on PPC32.\n- The RTS-side `recordClosureMutated` / `dirty_MUT_VAR_GC` is\n  buggy.\n- `scavenge_mutable_list` / `scavenge_one` for some mut_list entry\n  type miscalculates pointer payload on PPC32.\n\nConcrete file list to audit, PPC32-eyes:\n\n- `rts/Updates.cmm` \u2014 `stg_BLACKHOLE_info`, `stg_upd_frame_*`\n- `rts/PrimOps.cmm` \u2014 `stg_writeMutVarzh`, `stg_writeMutVar*`,\n  `stg_writeArray*`\n- `rts/sm/Storage.c::dirty_MUT_VAR` (line 1402),\n  `dirty_TVAR` (line 1425).\n- `rts/sm/Scav.c::scavenge_mutable_list` (line 1592),\n  `scavenge_capability_mut_lists` (line 1697),\n  `scavenge_one` (search for `scavenge_one`).\n\nLook especially for:\n- Cmm code that uses `bdescr->free` arithmetic \u2014 endian / pointer-\n  size issues.\n- C code that reads/writes `bd->flags` \u2014 should be uint16_t; PPC32\n  is big-endian so word-order matters in struct layout.\n- The \"clean \u2192 dirty\" info-table swap \u2014 uses `RELAXED_STORE`; on\n  non-threaded PPC32 this is just a regular store, but the info\n  pointer value loaded for comparison may be cached.\n\n### Third: address the TC-time variant separately\n\nIf the mut_list audit explains the STG-time variant (M5.hs), but the\nTC-time variant (Big2.hs) survives, the next-priority audit is:\n\n- `scavenge_thunk_srt` / `scavenge_fun_srt` (Scav.c:384, 397).\n  Both gated by `if (!major_gc) return;`.  With `-G1`, every GC is\n  major, so these run a LOT.  If they have a PPC32 SRT-encoding\n  bug, Big2.hs `-A1m -G1` would still fail.\n- `scavenge_static` (Scav.c:1729).  Walks the `static_objects`\n  linked list using `STATIC_LINK(info, p)` macros.  PPC32 alignment\n  of static info-table fields could be wrong.\n- Info-table layout: read `includes/rts/storage/InfoTables.h` with\n  PPC32 alignment eyes.  The `StgFunInfoTable` / `StgThunkInfoTable`\n  inheritance via `i.layout` union \u2014 does the SRT offset\n  arithmetic come out right with `__alignof__(StgFunPtr) == 4`?\n\n### Fourth: bisect\n\n`+RTS -A1m -G1 -F0.5` lowers the survival factor on Big2.hs; does\nit help?  Conversely, `+RTS -A1m -G3` (three generations) might\nexpose yet another variant.  Cheap to try.\n\n## Mechanics \u2014 reproducing session-27 results\n\n```bash\ncd /Users/cell/claude/ghc-darwin8-ppc\n\n# 1. Baseline\nbash tests/run-tests.sh   # expect 30 PASS / 4 design diffs (one test\n                          # may transient-fail if you run two test\n                          # runners concurrently; serialize)\n\n# 2. M5.hs panic-rate matrix\nbash docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/measure-panic-rate.sh \\\n    pmacg5 10 M5\n# ~10 min.  Expected: -A1m 0/10, -A1m -G1 10/10, -A1G 10/0.\n\n# 3. Big2.hs matrix\nbash docs/sessions/2026-05-12-session-27-non-perturbing-repro/scripts/g1-big2-test.sh \\\n    pmacg5 10\n# ~12 min.  Expected: -A1G 10/0, -A1m 1/9, -A1m -G1 0/10.\n\n# 4. (If implementing the priority-1 probe) edit rts/sm/GC.c, rebuild\n#    stage1 ghc lib, redeploy:\ncd external/ghc-modern/ghc-9.2.8\nsource ../../../scripts/cross-env.sh > /dev/null\n./hadrian/build --flavour=quick-cross -j8 \\\n    _build/stage1/lib/ppc-osx-ghc-9.2.8/ghc-9.2.8/rts/libHSrts-1.0.2.a\n# (only RTS rebuild needed \u2014 ~3 min if only GC.c changes)\ncd ../../..\nbash scripts/deploy-stage2.sh pmacg5\n```\n\n## Hosts (unchanged)\n\n- **uranium** (this Mac): host for cross-build, source edits.\n- **pmacg5** (PowerMac G5, Tiger 10.4.11): runs ppc binaries.\n- **imacg3**: smaller-RAM PPC G3.\n- **indium**: trimmed dev tools \u2014 don't use for clang or hadrian builds.\n\n## What's clean / dirty in the source tree\n\n- `external/ghc-modern/ghc-9.2.8/` \u2014 clean (no source edits this\n  session).\n- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` \u2014 unchanged from\n  session-26 end (v0.12.0-equivalent).\n- New session log: `docs/sessions/2026-05-12-session-27-non-perturbing-repro/`\n  + run logs gitignored at `log/session27/`.\n\n## Time estimate for session 28\n\n- Setup + read handoff + verify session-27 numbers: 30 min.\n- Implement the priority-1 RTS-side probe (per-GC mut_list /\n  static-object counter): 1\u20132 h (one focused C edit + RTS rebuild\n  + redeploy + 4 short runs).\n- Analyse the probe output and pick mut_list audit vs SRT/static\n  audit: 30\u201360 min.\n- Audit + first hypothesis test: 2\u20133 h.\n\nRealistic: 1 medium session (~4\u20136 h) to either nail the STG-time\nvariant's mechanism or pivot.  Then 1\u20132 more medium sessions to\naddress the TC-time variant and ship a fix.\n\n## Paste-into-fresh-session prompt\n\n```\nContext: session 27 of the GHC darwin8-ppc project just wrapped up.\nSession 27 nailed a deterministic non-perturbing repro for the\nstage2 GC bug \u2014 `M5.hs +RTS -A1m` panics 10/10 on clean stage2.\n`+RTS -A1m -G1` (single-generation) fully suppresses M5.hs's panic\nfamily (10/10 OK) AND M5plus.hs (5/5 OK), but does NOT suppress\nBig2.hs (a clean ~30-LOC module that imports Data.Map.Strict and\nuses a `where`-bound local function): Big2.hs `+RTS -A1m -G1` fails\n10/10 with a new, previously-undocumented signature: `* GHC internal\nerror: 'swap' is not in scope during type checking, but it passed\nthe renamer`.  So the bug has at least two distinct corruption\nmodes \u2014 STG-time (suppressed by -G1) and typecheck-time (not\nsuppressed).\n\nThis session resets the playing field after sessions 19\u201326's various\ndead-end hypotheses (BS-pinning invariant, mkLivenessBits, StackRep,\npoison-on-stale-slot).  v0.12.0 ships unchanged; no source-tree edits\nthis session.\n\nRead in order:\n1. docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md\n2. docs/sessions/2026-05-12-session-27-non-perturbing-repro/README.md\n3. docs/sessions/2026-05-12-session-27-non-perturbing-repro/findings.md\n4. (reference) docs/sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md\n5. (reference) docs/sessions/2026-04-29-session-17-stage2-O0-experiment/GC-BUG-FOUND.md\n\nTop priority: write a slim RTS-side probe (no Haskell-side\ninstrumentation, just a printf at start/end of `GarbageCollect()`\nreporting per-gen mut_list lengths + static-object chain length +\npromotion counts) and run on M5.hs `-A1m`, M5.hs `-A1m -G1`,\nBig2.hs `-A1m -G1`, Big2.hs `-A1G`.  Goal: discriminate \"one bug,\ntwo victim data structures\" from \"two distinct bugs.\"\n\nHosts: uranium for builds, pmacg5 for runs.  Don't use indium.\nv0.12.0 stays shipped \u2014 don't break stage2's -A1G wrapper.\n\nUnsupervised mode is project default.\n```\n\n## Memory aide for the next-you: session-end HANDOFF path\n\nThis handoff lives at:\n[`docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md`](docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md).\n\nWhen session 28 ends, write the next handoff at:\n`docs/sessions/<DATE>-session-28-<slug>/HANDOFF.md`.\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n -A 2 'Session 26\\|session-26\\|Session 25\\|round 8' docs/state.md | head -30",
  "description": "Find existing session-26 entries in state.md"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n 'session-2[3-6]\\|round [4-9]\\|allocator-hunt\\|GC bug' docs/state.md 2>/dev/null | head -20; echo \"---\"; wc -l docs/state.md",
  "description": "Check state.md current contents"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "offset": 1,
  "limit": 160
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "offset": 300,
  "limit": 100
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "*Updated: 2026-05-11 session 25 (stage2 GC bug round 7 \u2014 PROBE23 = PROBE22POISON + `BF_PINNED` filter + no-poison `PROBE23PINNED` log of pinned-block stack slots.  Result: 5/5 SIGSEGV byte-identical to PROBE22, **with `pinned_skip = 0`** across every GC.  Rules out the false-positive theory in its strong form: no stack-resident value pointed into a pinned block during M5.hs's compile, so the bug isn't \"PROBE22 was wrongly stomping pinned-Addr#s.\"  Hypothesis (a) from session-24 confirmed: some BS reaching `mkFastStringByteString` is backed by a non-pinned `MutableByteArray#`, violating the pinning invariant at `libraries/base/GHC/ForeignPtr.hs:145`.  Sessions 19\u201325 cumulatively rule out: bitmap codegen, `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, and the StackRep itself \u2014 all correct.  Bug is upstream of all of them, in the bytestring/FastString allocation boundary.  Next: find the BS allocator that omits pinning.)*",
  "new_string": "*Updated: 2026-05-12 session 27 (stage2 GC bug round 9 \u2014 non-perturbing deterministic repro nailed; bug has two distinct corruption modes; `-G1` is a partial workaround).  **`M5.hs +RTS -A1m -RTS` panics 10/10** on clean stage2 with the STG-time panic family (depSortStgBinds, refineFromInScope, \"variable not found\").  **`+RTS -A1m -G1` (single-generation) fully suppresses the M5.hs panic family** (10/10 OK) and M5plus.hs (5/5 OK).  But **`-G1` does NOT suppress all variants** \u2014 Big2.hs (~30-LOC clean module using Data.Map.Strict + `where`-bound local) fails 10/10 at `-A1m -G1` with a **new corruption signature first observed this session: `* GHC internal error: 'swap' is not in scope during type checking, but it passed the renamer`**.  So sessions 17\u201326's catalogue (STG-time panics) was incomplete: there's also a typecheck-time corruption that escapes the gen-2 mut_list path entirely.  Sessions 19\u201326 dead-end theories (BS-pinning invariant, mkLivenessBits, StackRep, poison-on-stale-slot) all stand as ruled out.  v0.12.0 ships unchanged; source tree clean.  Next session: write a slim RTS-side probe (per-GC mut_list / static-object counter, no Haskell-side perturbation) to discriminate \"one bug, two victim data structures\" vs \"two distinct bugs.\")*"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "- 2026-05-11 session 25: stage2 GC bug investigation, round 7.",
  "new_string": "- 2026-05-12 session 27: stage2 GC bug investigation, round 9.\n  Re-established a **deterministic non-perturbing repro** after\n  session 26 showed PROBE26 was hiding the M5.hs SIGSEGV: clean\n  stage2 + `M5.hs +RTS -A1m -RTS` panics **10/10** with the\n  STG-time panic family (depSortStgBinds, refineFromInScope, etc.).\n  Tried a matrix of RTS flag profiles on M5.hs: `-A1G` 10/0,\n  `-A1m` 0/10, `-A1m -G1` **10/0** (single-generation fully\n  suppresses!), `-A512k` 9/1, `-A4m` 10/0.  `-G1` empties the\n  older-gen mut_list scavenge loop in `scavenge_capability_mut_lists`,\n  so the bug looked consistent with a missed-mut_list-entry / write-\n  barrier bug.  Then on slightly larger inputs the picture broke:\n  M5plus.hs `-A1m -G1` 5/0 (still suppressed), but a syntactically\n  clean Big2.hs `-A1m -G1` fails **10/10** with a previously-\n  undocumented signature \u2014 `* GHC internal error: 'swap' is not in\n  scope during type checking, but it passed the renamer`.  So the\n  bug has at least two distinct corruption modes: STG-time\n  (suppressed by `-G1`) and typecheck-time (not suppressed).  Either\n  two separate bugs or one bug with two victim data structures.\n  v0.12.0 ships unchanged; source tree clean; no commits to\n  external/ghc-modern this session.  Session\n  [`HANDOFF.md`](sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md)\n  scopes a slim RTS-side probe to discriminate one-bug vs two-bug.\n- 2026-05-12 session 26: stage2 GC bug investigation, round 8.\n  PROBE26 = Haskell-side ForeignPtrContents classifier in\n  `mkFastStringByteString`.  Result on M5.hs `+RTS -A1m`: 150\n  visible BSes across 3 runs, all **`PlainPtr+pinned`, zero\n  UNPINNED**.  Hypothesis (a) from session 25 (\"BS reaches\n  `mkFastStringByteString` with non-pinned MBA\") is **rejected\n  by direct observation**.  Additionally, PROBE26 prevents the\n  SIGSEGV on M5.hs entirely (0/3 vs. session 23's 5/5) \u2014 the\n  instrumentation perturbs `mkFastStringByteString`'s Cmm enough\n  to hide the bug.  Stress-test on M5plus.hs and Big.hs: bug\n  rate dramatically reduced but not zero (1/16 panic on a cold\n  M5plus.hs first run).  Sessions 23\u201325's `_blk_c7te + 112 /\n  0xdeadbeef` signature was a PROBE22POISON / PROBE23 probe\n  artefact \u2014 without any probe, the bug surfaces as the panics\n  that session 17 first cataloged.  Sessions 19\u201326 collectively\n  rule out: bitmap codegen, mkLivenessBits, stackMapToLiveness,\n  LayoutStack, StackRep, AND the BS-pinning-invariant theory.\n  v0.12.0 ships unchanged; stage2 on pmacg5 redeployed clean.\n  See [`HANDOFF.md`](sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md).\n- 2026-05-11 session 25: stage2 GC bug investigation, round 7."
}


---

## 🤖 Claude

Now let me update roadmap.md to capture the session 27 finding.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "offset": 259,
  "limit": 40
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "old_string": "  Sessions 19\u201326 collectively rule out: bitmap codegen,\n  `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, StackRep,\n  AND the BS-pinning-invariant theory.  We do not currently have a\n  confirmed proximate cause.  Session-26\n  [`HANDOFF.md`](sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md)\n  scopes re-establishing a non-perturbing repro (currently 4/5 panic\n  on clean stage2 + M5.hs `-A1m`) and pivoting investigation upstream.\n\nEarlier \"missing PPC memory fences\" hypothesis is **dead** under\nour build configuration \u2014 non-threaded RTS uses no fences.\n\nFixing the actual GC bug is still likely multi-session work.",
  "new_string": "  Sessions 19\u201326 collectively rule out: bitmap codegen,\n  `mkLivenessBits`, `stackMapToLiveness`, `LayoutStack`, StackRep,\n  AND the BS-pinning-invariant theory.  We do not currently have a\n  confirmed proximate cause.  Session-26\n  [`HANDOFF.md`](sessions/2026-05-12-session-26-bs-allocator-hunt/HANDOFF.md)\n  scopes re-establishing a non-perturbing repro (currently 4/5 panic\n  on clean stage2 + M5.hs `-A1m`) and pivoting investigation upstream.\n- [`docs/sessions/2026-05-12-session-27-non-perturbing-repro/`](sessions/2026-05-12-session-27-non-perturbing-repro/)\n  \u2014 round 9.  **Deterministic non-perturbing repro nailed.**\n  `M5.hs +RTS -A1m -RTS` on clean stage2 panics **10/10** with the\n  STG-time panic family (depSortStgBinds, refineFromInScope, \"variable\n  not found\").  **`+RTS -A1m -G1` (single-generation) fully\n  suppresses the M5.hs panic family** (10/10 OK), and likewise on\n  M5plus.hs (5/5 OK).  Goldilocks: `-A1G`, `-A4m`, and even `-A512k`\n  are too large/small to reproduce M5.hs's failure.  But on a\n  larger clean input \u2014 Big2.hs, ~30-LOC, uses Data.Map.Strict and\n  a `where`-bound local function \u2014 `-A1m -G1` fails 10/10 with a\n  **new, previously-undocumented signature**: `* GHC internal\n  error: 'swap' is not in scope during type checking, but it\n  passed the renamer`.  So the bug has at least two distinct\n  corruption modes: STG-time (suppressed by `-G1`) and typecheck-\n  time (not suppressed).  Either two separate bugs or one bug with\n  two victim data structures.  v0.12.0 ships unchanged; source\n  tree clean; no commits to external/ghc-modern this session.\n  Session-27\n  [`HANDOFF.md`](sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md)\n  scopes a slim RTS-side probe (per-GC mut_list / static-object\n  counter, no Haskell-side perturbation) to discriminate one-bug\n  vs two-bug.\n\nEarlier \"missing PPC memory fences\" hypothesis is **dead** under\nour build configuration \u2014 non-threaded RTS uses no fences.\n\nFixing the actual GC bug is still likely multi-session work."
}


---

## 🤖 Claude

Now let me check git status and verify everything is in order.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git status --short 2>&1 | head -40; echo \"---\"; ls docs/sessions/2026-05-12-session-27-non-perturbing-repro/",
  "description": "Check git status"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git status --short docs/inbox/README.md AGENTS.md docs/convos/ docs/inbox/attic/ kimi-export-a0145e07-20260508-221232.md log/ 2>&1 | head; echo \"---\"; head -5 AGENTS.md 2>/dev/null; echo \"---\"; head -5 docs/inbox/README.md 2>/dev/null; git diff docs/inbox/README.md 2>&1 | head -30",
  "description": "Check pre-existing unrelated dirty files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -E '^log|^/log|session2' .gitignore 2>/dev/null | head; echo \"---\"; ls log/session27/ 2>/dev/null | head -5",
  "description": "Verify log/ gitignored"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat .gitignore 2>/dev/null",
  "description": "Inspect .gitignore"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/commits.md",
  "content": "# Session 27 commits\n\n- _(SHA pending)_ Session 27: stage2 GC bug investigation, round 9\n  (non-perturbing deterministic repro nailed; `-G1` is partial\n  workaround on small inputs; bug has two distinct corruption\n  modes \u2014 STG-time and typecheck-time \u2014 only the STG-time variant\n  is suppressed by `-G1`).\n\n## Source-tree changes that did NOT make it into git\n\nNone this session.  No patches to `external/ghc-modern/ghc-9.2.8/`.\n\n## Stage1 / stage2 / pmacg5 state changes\n\n- `external/ghc-modern/ghc-9.2.8/` \u2014 no edits.\n- `external/ghc-modern/ghc-9.2.8/_build/stage1/lib/.../libHSghc-9.2.8.a`\n  \u2014 unchanged from session-26 end (matches v0.12.0).\n- `pmacg5:/opt/ghc-stage2/bin/{ghc,ghc-real}` \u2014 unchanged from\n  session-26 end (matches v0.12.0).\n- No rebuild, no redeploy this session.  Pure measurement +\n  analysis + documentation.\n"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Run baseline tests/run-tests.sh",
      "activeForm": "Running baseline tests",
      "status": "completed"
    },
    {
      "content": "Create session-27 directory with skeleton notes",
      "activeForm": "Creating session-27 directory",
      "status": "completed"
    },
    {
      "content": "Measure clean-stage2 panic baseline on M5.hs +RTS -A1m and variants",
      "activeForm": "Measuring clean-stage2 panic baseline",
      "status": "completed"
    },
    {
      "content": "Confirm -G1 suppression on M5plus.hs and Big.hs",
      "activeForm": "Confirming -G1 suppression on larger inputs",
      "status": "completed"
    },
    {
      "content": "Write up session-27 findings + README + HANDOFF for session 28",
      "activeForm": "Writing up session-27",
      "status": "completed"
    },
    {
      "content": "Commit session-27 work",
      "activeForm": "Committing session-27",
      "status": "in_progress"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log --oneline | head -5",
  "description": "Inspect recent commit style"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-12-session-27-non-perturbing-repro/ docs/state.md docs/roadmap.md && git status --short | head -20",
  "description": "Stage session-27 changes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git commit -m \"$(cat <<'EOF'\nSession 27: stage2 GC bug investigation, round 9 (deterministic non-perturbing repro nailed; -G1 partial workaround; bug has two distinct corruption modes).\n\nM5.hs +RTS -A1m on clean stage2 panics 10/10 (STG-time panic family:\ndepSortStgBinds, refineFromInScope, \"variable not found\").  +RTS -A1m -G1\nfully suppresses M5.hs (10/10 OK) and M5plus.hs (5/5 OK).  But Big2.hs\n(clean ~30-LOC module using Data.Map.Strict + where-bound local) fails\n10/10 at -A1m -G1 with a new signature: \"* GHC internal error: 'swap'\nis not in scope during type checking, but it passed the renamer\".  So\nthe bug has at least two distinct corruption modes \u2014 STG-time\n(suppressed by -G1) and typecheck-time (not).  Either two separate bugs\nor one bug with two victim data structures.  Next session: slim\nRTS-side probe to discriminate.  v0.12.0 ships unchanged; source tree\nclean; no GHC-tree edits this session.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\"",
  "description": "Commit session 27 work"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log --oneline | head -3",
  "description": "Show new commit and backfill commit hash"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-12-session-27-non-perturbing-repro/commits.md",
  "old_string": "- _(SHA pending)_ Session 27: stage2 GC bug investigation, round 9",
  "new_string": "- `059bfd7` Session 27: stage2 GC bug investigation, round 9"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-12-session-27-non-perturbing-repro/commits.md && git commit -m \"$(cat <<'EOF'\nSession 27 commits.md: backfill the SHA.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\"",
  "description": "Backfill SHA in commits.md"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log --oneline | head -5",
  "description": "Final log check"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Run baseline tests/run-tests.sh",
      "activeForm": "Running baseline tests",
      "status": "completed"
    },
    {
      "content": "Create session-27 directory with skeleton notes",
      "activeForm": "Creating session-27 directory",
      "status": "completed"
    },
    {
      "content": "Measure clean-stage2 panic baseline on M5.hs +RTS -A1m and variants",
      "activeForm": "Measuring clean-stage2 panic baseline",
      "status": "completed"
    },
    {
      "content": "Confirm -G1 suppression on M5plus.hs and Big.hs",
      "activeForm": "Confirming -G1 suppression on larger inputs",
      "status": "completed"
    },
    {
      "content": "Write up session-27 findings + README + HANDOFF for session 28",
      "activeForm": "Writing up session-27",
      "status": "completed"
    },
    {
      "content": "Commit session-27 work",
      "activeForm": "Committing session-27",
      "status": "completed"
    }
  ]
}


---

## 🤖 Claude

Session 27 done. Summary:

**Key findings:**

| Input    | -A1G  | -A1m              | -A1m -G1          |
|----------|-------|-------------------|-------------------|
| M5.hs    | 10/0  | **0/10 panic**    | **10/0 (clean!)** |
| M5plus.hs| —     | 4/1               | 5/0 (clean)       |
| Big2.hs  | 10/0  | 1/9 mostly TC-err | **0/10 TC-err**   |

- **Deterministic non-perturbing repro:** `M5.hs +RTS -A1m -RTS` → 10/10 panic on clean stage2.
- **`-G1` (single-generation) fully suppresses** the M5.hs panic family — disables the older-gen `scavenge_capability_mut_lists` loop, consistent with a missed mut_list entry hypothesis.
- **Newly discovered second corruption signature** on Big2.hs (~30 LOC, clean program): `* GHC internal error: 'swap' is not in scope during type checking, but it passed the renamer`. **Not** suppressed by `-G1` — bug has two distinct modes (or one bug, two victims).

**Deliverables:**
- [README.md](docs/sessions/2026-05-12-session-27-non-perturbing-repro/README.md), [findings.md](docs/sessions/2026-05-12-session-27-non-perturbing-repro/findings.md), [HANDOFF.md](docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md), 3 harness scripts.
- 2 commits: [059bfd7](docs/sessions/2026-05-12-session-27-non-perturbing-repro/) + commits.md backfill 6cac711.
- v0.12.0 unchanged; source tree clean; no GHC rebuild needed this session.

Next-session HANDOFF lives at [docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md](docs/sessions/2026-05-12-session-27-non-perturbing-repro/HANDOFF.md). It scopes a slim RTS-side probe to discriminate "one bug, two victims" vs "two distinct bugs" before auditing the mut_list/write-barrier path.

---

## 👤 User

<task-notification>
<task-id>b5ywg2l9b</task-id>
<summary>Monitor event: "g1-suppression iter events"</summary>
<event>[Monitor timed out — re-arm if needed.]</event>
</task-notification>

---

## 🤖 Claude

That's a stale monitor from the earlier `g1-suppression-test.sh` run, which already completed cleanly. No action needed — session 27 is wrapped up and committed.

---

## 👤 User

<task-notification>
<task-id>b5ywg2l9b</task-id>
<summary>Monitor event: "g1-suppression iter events"</summary>
<event>SUMMARY</event>
</task-notification>

---

## 🤖 Claude

Stale monitor still firing tail-of-file events from the already-completed run log. The monitor's `tail -F` is picking up unrelated writes to a file path that no longer matters. Nothing to act on — session 27 is committed and done.

---

## 👤 User

<task-notification>
<task-id>bm1bu231f</task-id>
<summary>Monitor event: "Big2 test progress (only print failures + section headers)"</summary>
<event>[Monitor timed out — re-arm if needed.]</event>
</task-notification>

---

## 🤖 Claude

Another stale monitor from a completed run timing out. Ignoring — session 27 is committed and done. No further action.

---

## 👤 User

<task-notification>
<task-id>bm1bu231f</task-id>
<summary>Monitor event: "Big2 test progress (only print failures + section headers)"</summary>
<event>SUMMARY</event>
</task-notification>

---

## 🤖 Claude

Stale monitor noise from the completed Big2 test — nothing to act on. Session 27 remains committed and done.

---

## 👤 User

<task-notification>
<task-id>badiip72j</task-id>
<tool-use-id>toolu_01FDpCVCpN6iQdJRAZAtAkwx</tool-use-id>
<output-file>/private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/b236cd32-a7d4-4e1e-9375-8cf3ac5ce131/tasks/badiip72j.output</output-file>
<status>killed</status>
<summary>Monitor "M5.hs panic-rate harness summary lines" stopped</summary>
</task-notification>

---

