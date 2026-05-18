# Claude Conversation Log

Session ID: 47f64964-884a-43a6-aef6-d2e843931444
Date: 2026-05-16 03:17:05

---

## 👤 User

read docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/HANDOFF.md and proceed

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/HANDOFF.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/findings.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "limit": 120
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/",
  "description": "List session 56 scripts"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/run-ghci-subset.sh"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n \"req_th\\b\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T",
  "description": "Find req_th tests in upstream all.T"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n \"req_th\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T",
  "description": "Find req_th tests in upstream all.T"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -l \"req_th\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/*.T 2>/dev/null; ls /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/ | head",
  "description": "Confirm scripts dir exists"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/ 2>&1 | head -20; echo \"---\"; ls /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/ 2>&1",
  "description": "Inspect ghci test directory layout"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n \"req_th\\|TemplateHaskell\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T | head -60",
  "description": "Find req_th and TH references in all.T"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -c \"test(\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T; head -50 /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T",
  "description": "Inspect all.T format"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "wc -l /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T",
  "description": "Line count of all.T"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn \"req_th\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/ 2>/dev/null | head -20",
  "description": "Look for req_th in ghci tests"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn \"req_th\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ 2>/dev/null | head -30",
  "description": "Look for req_th in entire testsuite"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n \"req_th\\|TemplateHaskell\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci.debugger/scripts/all.T 2>/dev/null",
  "description": "Look for req_th in debugger tests"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn \"req_th\\b\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci.debugger/ 2>/dev/null | head; echo \"---\"; ls /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci.debugger/",
  "description": "Inspect debugger dir layout"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -E \"req_th\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T; echo \"exit=$?\"",
  "description": "Confirm absence of req_th"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -l \"TemplateHaskell\\|splice\\|\\\\$(\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/*.script | head -20",
  "description": "Find scripts that exercise TH"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -l 'TemplateHaskell' /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/*.script /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/*.hs 2>/dev/null | head -30",
  "description": "Find TH-using scripts and hs files"
}


---

## 🤖 Claude

I'll start by setting up the session 58 directory. Then take stock of what's actually next.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/README.md"
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

The HANDOFF's priority #1 has a stale premise — there are no `req_th`-annotated tests in `tests/ghci/scripts/all.T`. I'll grep-confirmed: zero matches. But there are ~100+ `T<num>.script` tests in that same directory that session 56 didn't cover, including the TH-using ones (T4127, T4127a, T5566, T8831, T10466, T11098) — that's the actual spirit of priority #1. I'll extend session 56's runner to cover them.

---

## 🤖 Claude


🔧 Using tool: ToolSearch
Input: {
  "query": "select:TodoWrite",
  "max_results": 1
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Verify baseline (run tests/run-tests.sh)",
      "status": "in_progress",
      "activeForm": "Verifying baseline tests are green"
    },
    {
      "content": "Set up session 58 dir + scaffolding",
      "status": "pending",
      "activeForm": "Setting up session 58 dir"
    },
    {
      "content": "Parse all.T for T-prefix .script tests with normal/combined_output",
      "status": "pending",
      "activeForm": "Parsing all.T for T-prefix tests"
    },
    {
      "content": "Write run-ghci-tnum.sh runner (or extend session 56's)",
      "status": "pending",
      "activeForm": "Writing T-num runner"
    },
    {
      "content": "Run on pmacg5 and iterate on failures",
      "status": "pending",
      "activeForm": "Running on pmacg5"
    },
    {
      "content": "Write README, findings, commits, HANDOFF",
      "status": "pending",
      "activeForm": "Writing session notes"
    },
    {
      "content": "Update top-level README + state.md + roadmap.md",
      "status": "pending",
      "activeForm": "Updating top-level docs"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash tests/run-tests.sh 2>&1 | tail -20",
  "description": "Run baseline tests",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "mkdir -p /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/{scripts,logs}; ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/",
  "description": "Create session 58 dir"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "python3 <<'EOF'\n# Quick parser: extract T-prefix .script tests from upstream all.T\n# that have `normal` / `combined_output` / plain `extra_files(...)` annotations\n# and no excluded annotations.\nimport re, sys\nall_t = open('external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/all.T').read()\n\nEXCLUDE = ['extra_hc_opts', 'extra_run_opts', 'reqlib', 'req_interp', 'req_th',\n           'expect_broken', 'pre_cmd', 'skip', 'makefile_test', 'cmd_prefix',\n           'fragile', 'filter_stdout_lines', 'ignore_stdout', 'ignore_stderr',\n           'normalise_slashes', 'normalise_version', 'extra_ways', 'when(',\n           'unless(', 'expect_fail']\n\n# Match: test('NAME', <body>, ghci_script, ['NAME.script'])\n# Body may span lines and include brackets.  Use a permissive regex.\npattern = re.compile(r\"test\\('([^']+)'\\s*,\\s*(.+?)\\s*,\\s*ghci_script\\s*,\\s*\\['([^']+)\\.script'\\]\\s*\\)\", re.DOTALL)\n\npassing = []\nskipped = []\nfor m in pattern.finditer(all_t):\n    name = m.group(1)\n    body = m.group(2).strip()\n    script = m.group(3)\n    # consider only T-prefix or capitalised names not starting with 'ghci'\n    if name.startswith('ghci'):\n        continue\n    reasons = [k for k in EXCLUDE if k in body]\n    # combined_output passes through; normal passes through; extra_files OK if no other reasons\n    if reasons:\n        skipped.append((name, body[:80], reasons))\n        continue\n    # check extra_files refers only to local files (not '../...')\n    extra_files = re.search(r\"extra_files\\(\\[(.*?)\\]\\)\", body)\n    extras = []\n    if extra_files:\n        for f in re.findall(r\"'([^']+)'\", extra_files.group(1)):\n            if '/' in f or f.startswith('..'):\n                skipped.append((name, body[:80], ['extra_files outside dir: '+f]))\n                break\n            extras.append(f)\n        else:\n            # all extras OK\n            pass\n    if reasons:\n        continue\n    if 'combined_output' in body:\n        combined = '1'\n    else:\n        combined = '0'\n    passing.append((name, combined, extras))\n\n# Filter out those that skipped via inner break (extras outside dir)\nskipped_names = {s[0] for s in skipped}\npassing = [p for p in passing if p[0] not in skipped_names]\n\nprint(f\"# {len(passing)} passing T-prefix tests:\")\nfor name, combined, extras in passing:\n    ex = ' ' + ' '.join(extras) if extras else ''\n    print(f\"  \\\"{name} {combined}{ex}\\\"\")\nprint()\nprint(f\"# {len(skipped)} skipped:\")\nfor name, body, reasons in skipped:\n    print(f\"  # {name}: {reasons}\")\nEOF\n",
  "description": "Parse all.T for eligible T-prefix tests"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts && ls T1914.* T2766.* T7388.* 2>&1",
  "description": "Check companion files for a few tests"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -20 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/47f64964-884a-43a6-aef6-d2e843931444/tasks/bu19jg4s3.output",
  "description": "Check baseline test progress"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/47f64964-884a-43a6-aef6-d2e843931444/tasks/bu19jg4s3.output 2>&1 | head -50; echo ---; ls /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/47f64964-884a-43a6-aef6-d2e843931444/tasks/ 2>&1",
  "description": "Inspect baseline test output"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/47f64964-884a-43a6-aef6-d2e843931444/tasks/bu19jg4s3.output",
  "description": "Inspect output file"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -30 /Users/cell/claude/ghc-darwin8-ppc/tests/run-tests.sh",
  "description": "Inspect run-tests.sh"
}


---

## 🤖 Claude


🔧 Using tool: ToolSearch
Input: {
  "query": "select:TaskStop,TaskOutput",
  "max_results": 2
}


---

## 🤖 Claude


🔧 Using tool: TaskStop
Input: {
  "task_id": "bu19jg4s3"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Verify baseline (skip \u2014 stage2 unchanged from session 57)",
      "status": "completed",
      "activeForm": "Skipping baseline (stage2 unchanged)"
    },
    {
      "content": "Set up session 58 dir + scaffolding",
      "status": "completed",
      "activeForm": "Setting up session 58 dir"
    },
    {
      "content": "Parse all.T for T-prefix .script tests with normal/combined_output",
      "status": "completed",
      "activeForm": "Parsing all.T for T-prefix tests"
    },
    {
      "content": "Write run-ghci-tnum.sh runner",
      "status": "in_progress",
      "activeForm": "Writing T-num runner"
    },
    {
      "content": "Run on pmacg5 and iterate on failures",
      "status": "pending",
      "activeForm": "Running on pmacg5"
    },
    {
      "content": "Write README, findings, commits, HANDOFF",
      "status": "pending",
      "activeForm": "Writing session notes"
    },
    {
      "content": "Update top-level README + state.md + roadmap.md",
      "status": "pending",
      "activeForm": "Updating top-level docs"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "for t in T2766 T4127 T4127a T5566 T8831 T10466 T11098 T7388 T8042 T8042recomp T7873 T10576a T19667Ghci T11051a T11051b; do\n  echo \"=== $t ===\"\n  ls $t.* ${t}_* 2>/dev/null\ndone",
  "description": "Sample companion file patterns"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "for t in T7872 T11456 T13407 T16030 T18828 T19158 T15259 GhciKinds GhciCurDir StaticPtr TypeAppData T5557 T8353 T16804; do\n  echo \"=== $t ===\"\n  ls $t.* ${t}_* 2>/dev/null\ndone",
  "description": "More companion file inspection"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "\\\nfor t in T2766 T1914 T2182ghci T2976 T2816 T789 T3263 T4051 T4087 T4015 T4127 T4127a T4316 T4832 T5045 T5130 T5417 T5545 T5557 T5566 GhciKinds T5564 T5820 T5836 T6027ghci T6007 T6091 T6105 T7117 T7587 T7688 T7627 T7627b T7586 T4175 T6018ghci T6018ghcifail T6018ghcirnfail T7730 T7872 T7873 T7939 T7894 T8042 T8042recomp T8116 T8113 T8215 T8305 T8353 T8357 T8383 T8469 T8485 T8535 T8639 T8640 T8579 T8649 T8674 T8696 T8776 T8831 T8917 T8931 T8959 T8959b T9181 T9086b T9140 T9658 T9881 T9878 T10018 T10059 T10122 T10321 T10110 T10322 T10439 T10453 T10466 T10501 T10508 T10520 T10663 T10989 T11098 T11252 T10576a T10576b T11051a T11051b T11456 TypeAppData T11728 T11376 T12007 T11975 T10963 T11721 T12005 T12523 T12024 T12158 T12447 T10249 T12550 StaticPtr T13202 T13202a T13420 T13466 GhciCurDir T13699 T13988 T13407 T13795 T13963 T14796 T14969 T15259 T15341 T15568 T15325 T15591 T15743b T15827 T15872 T15898 T15941 T16030 T11606 T16089 T14828 T16376 T16527 T16569 T16767 T16575 T16509 T16804 T15546 T16876 T17345 T17384 T17403 T17431 T17549 T18501 T18644 T18755 T18828 T19197 T19158 T19279 T19310 T19667Ghci T19688 T20019 T20101 T20974 T7388; do\n  # find files starting with the test name that aren't .script/.stdout/.stderr,\n  # and have no underscore separator nor dot match.  i.e. ${name}<Cap>.hs etc.\n  for f in ${t}[A-Z]* 2>/dev/null; do\n    [ -f \"$f\" ] && echo \"$t needs: $f\"\n  done\ndone 2>/dev/null",
  "description": "Find camelcase-suffixed companion files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "python3 <<'EOF'\nimport os\nnames = \"\"\"T2766 T1914 T2182ghci T2976 T2816 T789 T3263 T4051 T4087 T4015 T4127 T4127a T4316 T4832 T5045 T5130 T5417 T5545 T5557 T5566 GhciKinds T5564 T5820 T5836 T6027ghci T6007 T6091 T6105 T7117 T7587 T7688 T7627 T7627b T7586 T4175 T6018ghci T6018ghcifail T6018ghcirnfail T7730 T7872 T7873 T7939 T7894 T8042 T8042recomp T8116 T8113 T8215 T8305 T8353 T8357 T8383 T8469 T8485 T8535 T8639 T8640 T8579 T8649 T8674 T8696 T8776 T8831 T8917 T8931 T8959 T8959b T9181 T9086b T9140 T9658 T9881 T9878 T10018 T10059 T10122 T10321 T10110 T10322 T10439 T10453 T10466 T10501 T10508 T10520 T10663 T10989 T11098 T11252 T10576a T10576b T11051a T11051b T11456 TypeAppData T11728 T11376 T12007 T11975 T10963 T11721 T12005 T12523 T12024 T12158 T12447 T10249 T12550 StaticPtr T13202 T13202a T13420 T13466 GhciCurDir T13699 T13988 T13407 T13795 T13963 T14796 T14969 T15259 T15341 T15568 T15325 T15591 T15743b T15827 T15872 T15898 T15941 T16030 T11606 T16089 T14828 T16376 T16527 T16569 T16767 T16575 T16509 T16804 T15546 T16876 T17345 T17384 T17403 T17431 T17549 T18501 T18644 T18755 T18828 T19197 T19158 T19279 T19310 T19667Ghci T19688 T20019 T20101 T20974 T7388\"\"\".split()\n\n# We want to find companion files like T9658X.hs (capital after the name) that\n# session 56's globs (<name>.* and <name>_*) won't pick up.\nall_files = set(os.listdir('.'))\nfor name in names:\n    extras = []\n    for f in sorted(all_files):\n        if not f.startswith(name):\n            continue\n        if f == name or f.startswith(name + '.') or f.startswith(name + '_'):\n            continue\n        # something like T9658X.hs\n        extras.append(f)\n    if extras:\n        print(f\"{name}: {extras}\")\nEOF\n",
  "description": "Find tests needing manual extras"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "for t in T5417 T8469 T8696 T10110 T10322 T16876; do\n  echo \"=== $t.script ===\"\n  cat $t.script\ndone",
  "description": "Inspect scripts that reference camelcase companions"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls T5417*; head -5 T5417a.hs; echo ---; ls T8469*; head -5 T8469a.hs",
  "description": "Inspect T5417 and T8469 companions"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -E \"^:l|^:load|^:add\" T*.script 2>/dev/null | grep -v \"_\\|^:l T[0-9]*\\.\\|^:load T[0-9]*\\.\\|^:load T[0-9]*$\" | head -50",
  "description": "Scan for unusual :load patterns"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls T1914*; echo ---; ls T10989*; echo ---; ls T13420*; echo ---; ls T15827*; echo ---; ls T15872*; echo ---; ls T15743b*",
  "description": "Inspect more companions"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat T1914.script; echo \"=== stdout ===\"; cat T1914.stdout; echo \"=== stderr ===\"; cat T1914.stderr",
  "description": "Inspect T1914 expected output"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/normalise.py"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh",
  "content": "#!/bin/bash\n# Run the bug-numbered T<NUM>.script subset of upstream's GHCi\n# testsuite (tests/ghci/scripts/all.T) against the deployed stage2\n# ghc on a PPC Tiger host.\n#\n# Why this exists: sessions 56 / 57 covered the `ghciNNN` and\n# `ghci.debugger` scripts but left the ~160 bug-numbered T<NUM>\n# regression scripts in tests/ghci/scripts/ untouched.  Several\n# (T4127, T4127a, T5566, T8831, T10466, T11098) exercise\n# TemplateHaskell through the REPL in ways session 56's ghci018\n# didn't.  Same runner shape as session 56; just a different TESTS\n# list.\n#\n# Usage:\n#   ./run-ghci-tnum.sh                 # runs against pmacg5\n#   ./run-ghci-tnum.sh imacg4          # explicit host\n#\n# Output: per-test PASS/FAIL line on stdout; full actual outputs\n# captured under $LOGDIR/<test>/actual.{stdout,stderr,combined}.\n\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nGHC_SRC=\"${GHC_SRC:-/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8}\"\nSCRIPTS_DIR=\"$GHC_SRC/testsuite/tests/ghci/scripts\"\nSESSION_DIR=\"$(cd \"$(dirname \"$0\")/..\" && pwd)\"\nLOGDIR=\"$SESSION_DIR/logs/ghci-tnum\"\nREMOTE_BASE=\"/tmp/ghci-tnum-$$\"\n\n# Test list.  Format: \"name combined_output(0|1) extra_files...\"\n# Filter applied: all upstream tests/ghci/scripts/all.T tests\n# whose name is NOT ghciNNN-shaped (i.e. T<NUM>* and miscellaneous\n# capitalised ones), with annotation in {normal, combined_output,\n# extra_files(...)}, and no extra_hc_opts / extra_run_opts / reqlib /\n# req_th / req_interp / expect_broken / pre_cmd / skip / fragile /\n# cmd_prefix / makefile_test / filter_stdout_lines.  extra_files\n# outside the scripts/ dir (`../...`) skipped (T14676, Defer02).\n#\n# Explicit extras added below come from two sources:\n#  - all.T's `extra_files([...])` (T8353, T10576a, T10576b, T16804,\n#    T19667Ghci)\n#  - lowercase / capital-suffix companion .hs files not caught by\n#    session 56's `<name>.*` / `<name>_*` auto-discovery globs\n#    (T5417a, T8469a, T8696A/B, T10110A/B/C, T10322A/B/C, T16876A/B).\nTESTS=(\n  \"T2766 0\"\n  \"T1914 0\"\n  \"T2182ghci 0\"\n  \"T2976 0\"\n  \"T2816 0\"\n  \"T789 0\"\n  \"T3263 0\"\n  \"T4051 0\"\n  \"T4087 0\"\n  \"T4015 0\"\n  \"T4127 0\"\n  \"T4127a 0\"\n  \"T4316 0\"\n  \"T4832 0\"\n  \"T5045 0\"\n  \"T5130 0\"\n  \"T5417 0 T5417a.hs\"\n  \"T5545 0\"\n  \"T5557 1\"\n  \"T5566 0\"\n  \"GhciKinds 0\"\n  \"T5564 0\"\n  \"T5820 0\"\n  \"T5836 0\"\n  \"T6027ghci 0\"\n  \"T6007 0\"\n  \"T6091 0\"\n  \"T6105 0\"\n  \"T7117 0\"\n  \"T7587 0\"\n  \"T7688 0\"\n  \"T7627 0\"\n  \"T7627b 0\"\n  \"T7586 0\"\n  \"T4175 0\"\n  \"T6018ghci 0\"\n  \"T6018ghcifail 0\"\n  \"T6018ghcirnfail 0\"\n  \"T7730 1\"\n  \"T7872 0\"\n  \"T7873 0\"\n  \"T7939 0\"\n  \"T7894 0\"\n  \"T8042 0\"\n  \"T8042recomp 0\"\n  \"T8116 0\"\n  \"T8113 0\"\n  \"T8215 0\"\n  \"T8305 0\"\n  \"T8353 0 Defer03.hs\"\n  \"T8357 0\"\n  \"T8383 0\"\n  \"T8469 0 T8469a.hs\"\n  \"T8485 0\"\n  \"T8535 0\"\n  \"T8639 0\"\n  \"T8640 0\"\n  \"T8579 0\"\n  \"T8649 0\"\n  \"T8674 0\"\n  \"T8696 0 T8696A.hs T8696B.hs\"\n  \"T8776 0\"\n  \"T8831 0\"\n  \"T8917 0\"\n  \"T8931 0\"\n  \"T8959 0\"\n  \"T8959b 0\"\n  \"T9181 0\"\n  \"T9086b 0\"\n  \"T9140 1\"\n  \"T9658 0\"\n  \"T9881 0\"\n  \"T9878 0\"\n  \"T10018 0\"\n  \"T10059 0\"\n  \"T10122 0\"\n  \"T10321 0\"\n  \"T10110 0 T10110A.hs T10110B.hs T10110C.hs\"\n  \"T10322 0 T10322A.hs T10322B.hs T10322C.hs\"\n  \"T10439 0\"\n  \"T10453 0\"\n  \"T10466 0\"\n  \"T10501 0\"\n  \"T10508 0\"\n  \"T10520 0\"\n  \"T10663 0\"\n  \"T10989 0\"\n  \"T11098 0\"\n  \"T11252 0\"\n  \"T10576a 0 T10576.hs\"\n  \"T10576b 0 T10576.hs\"\n  \"T11051a 0\"\n  \"T11051b 0\"\n  \"T11456 0\"\n  \"TypeAppData 0\"\n  \"T11728 0\"\n  \"T11376 0\"\n  \"T12007 0\"\n  \"T11975 0\"\n  \"T10963 0\"\n  \"T11721 0\"\n  \"T12005 0\"\n  \"T12523 0\"\n  \"T12024 0\"\n  \"T12158 0\"\n  \"T12447 0\"\n  \"T10249 0\"\n  \"T12550 0\"\n  \"StaticPtr 0\"\n  \"T13202 0\"\n  \"T13202a 0\"\n  \"T13420 0\"\n  \"T13466 0\"\n  \"GhciCurDir 0\"\n  \"T13699 0\"\n  \"T13988 0\"\n  \"T13407 0\"\n  \"T13795 0\"\n  \"T13963 0\"\n  \"T14796 0\"\n  \"T14969 0\"\n  \"T15259 0\"\n  \"T15341 0\"\n  \"T15568 0\"\n  \"T15325 0\"\n  \"T15591 0\"\n  \"T15743b 0\"\n  \"T15827 0\"\n  \"T15872 0\"\n  \"T15898 0\"\n  \"T15941 0\"\n  \"T16030 0\"\n  \"T11606 0\"\n  \"T16089 0\"\n  \"T14828 0\"\n  \"T16376 0\"\n  \"T16527 0\"\n  \"T16569 0\"\n  \"T16767 0\"\n  \"T16575 0\"\n  \"T16509 0\"\n  \"T16804 0 T16804a.hs T16804b.hs T16804c.hs\"\n  \"T15546 0\"\n  \"T16876 0 T16876A.hs T16876B.hs\"\n  \"T17345 0\"\n  \"T17384 0\"\n  \"T17403 0\"\n  \"T17431 0\"\n  \"T17549 0\"\n  \"T18501 0\"\n  \"T18644 0\"\n  \"T18755 0\"\n  \"T18828 0\"\n  \"T19197 0\"\n  \"T19158 0\"\n  \"T19279 0\"\n  \"T19310 0\"\n  \"T19667Ghci 0 T19667Ghci.hs\"\n  \"T19688 0\"\n  \"T20019 0\"\n  \"T20101 0\"\n  \"T20974 0\"\n  \"T7388 0\"\n)\n\nDYLD_ENV='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'\nGHC=/opt/ghc-stage2/bin/ghc-real\nHC_FLAGS=\"--interactive -v0 -ignore-dot-ghci -fno-ghci-history \\\n-fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never\"\n\nmkdir -p \"$LOGDIR\"\nrm -rf \"$LOGDIR\"/* 2>/dev/null\n\n# Stage all test files into a single tarball, scp once.\nSTAGE=$(mktemp -d)\ntrap 'rm -rf \"$STAGE\"' EXIT\n\nfor entry in \"${TESTS[@]}\"; do\n  read -r name combined extras <<< \"$entry\"\n  dest=\"$STAGE/$name\"\n  mkdir -p \"$dest\"\n  cp \"$SCRIPTS_DIR/$name.script\" \"$dest/\"\n  [ -f \"$SCRIPTS_DIR/$name.stdout\" ] && cp \"$SCRIPTS_DIR/$name.stdout\" \"$dest/expected.stdout\"\n  [ -f \"$SCRIPTS_DIR/$name.stderr\" ] && cp \"$SCRIPTS_DIR/$name.stderr\" \"$dest/expected.stderr\"\n  # Auto-include any other companion files matching $name.* or $name_*.*\n  # (e.g. T11456.hs, T7388.hs).  Skip files belonging to a sibling test\n  # whose stem starts with $name but has more chars before the dot\n  # (T789 vs T7894, T7627 vs T7627b, etc).\n  for f in \"$SCRIPTS_DIR/$name.\"* \"$SCRIPTS_DIR/${name}_\"*; do\n    [ -f \"$f\" ] || continue\n    case \"$f\" in\n      *.script|*.stdout|*.stderr) ;;\n      *) cp \"$f\" \"$dest/\" ;;\n    esac\n  done\n  if [ -n \"${extras:-}\" ]; then\n    for x in $extras; do\n      cp \"$SCRIPTS_DIR/$x\" \"$dest/\"\n    done\n  fi\ndone\n\n# Ship tarball + run script.\nssh -e none \"$PPC_HOST\" \"mkdir -p $REMOTE_BASE\"\n(cd \"$STAGE\" && tar cf - .) | ssh -e none \"$PPC_HOST\" \"cd $REMOTE_BASE && tar xf -\"\n\n# Build a remote runner.  For each test:\n#  - cd into its dir\n#  - run ghc --interactive < script   capturing stdout/stderr separately\n#  - print one TEST-LINE per test with status\nremote_script=$(cat <<EOF\nset -u\ncd \"$REMOTE_BASE\"\nexport $DYLD_ENV\nexport LANG=en_US.UTF-8\nEOF\n)\n\nfor entry in \"${TESTS[@]}\"; do\n  read -r name combined extras <<< \"$entry\"\n  if [ \"$combined\" = \"1\" ]; then\n    remote_script+=$'\\n'\"(\n  cd '$REMOTE_BASE/$name'\n  $GHC $HC_FLAGS < '$name.script' > actual.combined 2>&1\n  rc=\\$?\n  echo \\\"TEST $name rc=\\$rc\\\"\n)\"\n  else\n    remote_script+=$'\\n'\"(\n  cd '$REMOTE_BASE/$name'\n  $GHC $HC_FLAGS < '$name.script' > actual.stdout 2> actual.stderr\n  rc=\\$?\n  echo \\\"TEST $name rc=\\$rc\\\"\n)\"\n  fi\ndone\n\nssh -e none \"$PPC_HOST\" \"$remote_script\" > \"$LOGDIR/remote-run.log\" 2>&1\n\n# Fetch all artifacts back.\nssh -e none \"$PPC_HOST\" \"cd $REMOTE_BASE && tar cf - .\" | (cd \"$LOGDIR\" && tar xf -)\n\n# Cleanup remote.\nssh -e none \"$PPC_HOST\" \"rm -rf $REMOTE_BASE\"\n\nNORMALISE=\"$SESSION_DIR/scripts/normalise.py\"\n\nnorm() {\n  local f=$1; shift\n  [ -f \"$f\" ] || return 0\n  python3 \"$NORMALISE\" \"$@\" < \"$f\" > \"$f.norm\"\n  mv \"$f.norm\" \"$f\"\n}\n\n# Per-test extra normaliser args.  Mirrors annotations in upstream all.T.\n# (Most T<num> tests use plain `normal` so no per-test args.)\nnorm_args_for() {\n  case \"$1\" in\n    *) echo \"\" ;;\n  esac\n}\n\n# Diff each test and emit summary.\necho\necho \"=== GHCi T<num> subset results (host=$PPC_HOST, ghc=$GHC) ===\"\npass=0; fail=0\ndeclare -a FAILED\nfor entry in \"${TESTS[@]}\"; do\n  read -r name combined extras <<< \"$entry\"\n  dir=\"$LOGDIR/$name\"\n  fail_reasons=()\n\n  rc=$(grep \"^TEST $name rc=\" \"$LOGDIR/remote-run.log\" | tail -1 | sed 's/.*rc=//')\n  if [ \"$rc\" = 127 ] || [ \"$rc\" = 137 ] || [ \"$rc\" = 134 ]; then\n    fail_reasons+=(\"ghc rc=$rc\")\n  fi\n\n  nargs=$(norm_args_for \"$name\")\n  if [ \"$combined\" = 1 ]; then\n    norm \"$dir/expected.stdout\" $nargs\n    norm \"$dir/actual.combined\" $nargs\n    if [ ! -f \"$dir/expected.stdout\" ]; then\n      [ -s \"$dir/actual.combined\" ] && fail_reasons+=(\"combined output non-empty but no expected.stdout\")\n    elif ! diff -qw \"$dir/expected.stdout\" \"$dir/actual.combined\" > /dev/null 2>&1; then\n      fail_reasons+=(\"combined output mismatch\")\n    fi\n  else\n    norm \"$dir/expected.stdout\" $nargs\n    norm \"$dir/expected.stderr\" $nargs\n    norm \"$dir/actual.stdout\" $nargs\n    norm \"$dir/actual.stderr\" $nargs\n    if [ -f \"$dir/expected.stdout\" ]; then\n      if ! diff -qw \"$dir/expected.stdout\" \"$dir/actual.stdout\" > /dev/null 2>&1; then\n        fail_reasons+=(\"stdout mismatch\")\n      fi\n    else\n      [ -s \"$dir/actual.stdout\" ] && fail_reasons+=(\"stdout non-empty but no expected.stdout\")\n    fi\n    if [ -f \"$dir/expected.stderr\" ]; then\n      if ! diff -qw \"$dir/expected.stderr\" \"$dir/actual.stderr\" > /dev/null 2>&1; then\n        fail_reasons+=(\"stderr mismatch\")\n      fi\n    else\n      [ -s \"$dir/actual.stderr\" ] && fail_reasons+=(\"stderr non-empty but no expected.stderr\")\n    fi\n  fi\n\n  if [ ${#fail_reasons[@]} -eq 0 ]; then\n    pass=$((pass+1))\n    printf \"  PASS  %-15s  (rc=%s)\\n\" \"$name\" \"$rc\"\n  else\n    fail=$((fail+1))\n    FAILED+=(\"$name\")\n    printf \"  FAIL  %-15s  (rc=%s)  %s\\n\" \"$name\" \"$rc\" \"$(IFS='; '; echo \"${fail_reasons[*]}\")\"\n  fi\ndone\n\necho\necho \"=== Summary: $pass PASS / $fail FAIL out of ${#TESTS[@]} tests ===\"\nif [ ${#FAILED[@]} -gt 0 ]; then\n  echo \"Failed: ${FAILED[*]}\"\n  echo \"Diffs in $LOGDIR/<test>/{actual,expected}.* \"\nfi\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts && ln -sf ../../2026-05-15-session-56-ghci-testsuite/scripts/normalise.py normalise.py && ls -la",
  "description": "Symlink normalise.py from session 56"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh\n# quick syntax check\nbash -n /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh && echo \"syntax ok\"",
  "description": "Syntax check the runner"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat T789.script; echo ---; cat T789.stdout",
  "description": "Inspect T789"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts && cat T789.script; echo ---; cat T789.stdout 2>&1; echo ---; ls T789*",
  "description": "Inspect T789 again"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls T6018* T13202* T8959* T8042* T9878*",
  "description": "Check for sibling-test overlap"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat T6018ghci.script; echo \"=== T6018ghci.stdout ===\"; cat T6018ghci.stdout 2>&1; echo \"=== T6018ghci.stderr ===\"; cat T6018ghci.stderr 2>&1",
  "description": "Inspect T6018ghci"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat StaticPtr.hs; echo; echo \"=== StaticPtr.script ===\"; cat StaticPtr.script",
  "description": "Inspect StaticPtr test"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/T2766.script 2>&1; ssh -e none pmacg5 \"ls /opt/ghc-stage2/bin/ghc-real\" 2>&1",
  "description": "Verify paths exist"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && bash docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh 2>&1 | tee docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/logs/run-1-initial.log | tail -180",
  "description": "Run the T-num subset on pmacg5 (initial)",
  "timeout": 1500000
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Verify baseline (skip \u2014 stage2 unchanged from session 57)",
      "status": "completed",
      "activeForm": "Skipping baseline (stage2 unchanged)"
    },
    {
      "content": "Set up session 58 dir + scaffolding",
      "status": "completed",
      "activeForm": "Setting up session 58 dir"
    },
    {
      "content": "Parse all.T for T-prefix .script tests with normal/combined_output",
      "status": "completed",
      "activeForm": "Parsing all.T for T-prefix tests"
    },
    {
      "content": "Write run-ghci-tnum.sh runner",
      "status": "completed",
      "activeForm": "Writing T-num runner"
    },
    {
      "content": "Run on pmacg5 and iterate on failures",
      "status": "in_progress",
      "activeForm": "Running on pmacg5"
    },
    {
      "content": "Write README, findings, commits, HANDOFF",
      "status": "pending",
      "activeForm": "Writing session notes"
    },
    {
      "content": "Update top-level README + state.md + roadmap.md",
      "status": "pending",
      "activeForm": "Updating top-level docs"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: ScheduleWakeup
Input: {
  "delaySeconds": 270,
  "reason": "checking T-num run progress; first cache window before fetch back",
  "prompt": "Continue session 58 work. Background task b4eic34pf runs the 163-test GHCi T-num subset on pmacg5; check its progress and if done, parse PASS/FAIL counts and decide next steps."
}


---

## 🤖 Claude


🔧 Using tool: TaskOutput
Input: {
  "task_id": "b4eic34pf",
  "block": false,
  "timeout": 5000
}


---

## 🤖 Claude


🔧 Using tool: TaskOutput
Input: {
  "task_id": "b4eic34pf",
  "block": true,
  "timeout": 600000
}


---

## 🤖 Claude

Excellent — 161/163 PASS on run 1, just T10989 and T17549 failing. Let me inspect both.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/logs/ghci-tnum/T10989\necho \"=== T10989.script ===\"\ncat T10989.script\necho \"=== expected.stdout ===\"\ncat expected.stdout\necho \"=== actual.stdout ===\"\ncat actual.stdout\necho \"=== expected.stderr ===\"\ncat expected.stderr\necho \"=== actual.stderr ===\"\ncat actual.stderr",
  "description": "Inspect T10989 failure"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -e none pmacg5 'file /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit; ls -la /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit'",
  "description": "Inspect unlit binary on pmacg5"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -e none pmacg5 'file -b /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit; otool -hv /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit 2>&1 | head'",
  "description": "Inspect unlit Mach-O header"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -e none pmacg5 'ls /opt/ghc-stage2/lib/bin/; echo ---; for f in /opt/ghc-stage2/lib/bin/*; do printf \"%-60s \" \"$f\"; file -b \"$f\" | head -c 100; echo; done'",
  "description": "Inspect all helper binaries"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -e none pmacg5 'for f in /opt/ghc-stage2/lib/bin/*; do printf \"%-60s \" \"$f\"; file -b \"$f\"; done'",
  "description": "List bin file types"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn \"unlit\" /Users/cell/claude/ghc-darwin8-ppc/scripts/ /Users/cell/claude/ghc-darwin8-ppc/install.sh 2>/dev/null | head -20",
  "description": "Find unlit references in scripts"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn \"unlit\" /Users/cell/claude/ghc-darwin8-ppc/patches/ /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-15-session-55-ghci-repl-attempt/ 2>/dev/null | head -20",
  "description": "Search for unlit-related patches/notes"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/patches/0010-hadrian-cross-iserv.patch"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n -A 20 \"buildProgram bin ctx\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/hadrian/src/Rules/Program.hs | head -60",
  "description": "Inspect current Program.hs source"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/hadrian/src/Rules/Program.hs",
  "offset": 100,
  "limit": 40
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/utils/unlit -type f 2>/dev/null; echo ---; find /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 -name 'unlit.c' 2>/dev/null",
  "description": "Find unlit source"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/utils/unlit/unlit.cabal; echo ---; ls -la /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/utils/unlit/unlit.c",
  "description": "Inspect unlit cabal/source"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/logs/ghci-tnum/T17549\necho \"=== T17549.script ===\"\ncat T17549.script\necho \"=== expected.stderr ===\"\ncat expected.stderr\necho \"=== actual.stderr ===\"\ncat actual.stderr\necho \"=== diff -w ===\"\ndiff -w expected.stderr actual.stderr",
  "description": "Inspect T17549 failure"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/logs/ghci-tnum/T17549\necho \"=== expected.stdout ===\"\ncat expected.stdout 2>/dev/null\necho \"=== actual.stdout ===\"\ncat actual.stdout\necho \"=== combined ===\"\nls -la",
  "description": "Inspect T17549 stdout"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -e none pmacg5 'cd /tmp && touch x && ls -la --full-time x 2>/dev/null || stat -f %Sm x; rm -f x; mount | head -5; df /tmp'",
  "description": "Check /tmp filesystem on pmacg5"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -e none pmacg5 'cd /tmp && rm -rf T17549-test && mkdir T17549-test && cd T17549-test && cat > T17549.script << EOF\nwriteFile \"T17549.hs\" \"\"\n:load T17549.hs\nwriteFile \"T17549.hs\" \"import\"\n:! ls -la T17549.hs\n:! sleep 2\n:! ls -la T17549.hs\n:! touch T17549.hs\n:! ls -la T17549.hs\n:reload\n1\nEOF\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real --interactive -v0 -ignore-dot-ghci -fno-ghci-history -fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never < T17549.script' 2>&1",
  "description": "Probe T17549 mtime behavior"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -e none pmacg5 'cd /tmp && rm -rf T17549-test2 && mkdir T17549-test2 && cd T17549-test2 && cat > T17549.script << \"EOF\"\nwriteFile \"T17549.hs\" \"\"\n:load T17549.hs\nwriteFile \"T17549.hs\" \"import\"\n:reload\n1\nEOF\nDYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib /opt/ghc-stage2/bin/ghc-real --interactive -v0 -ignore-dot-ghci -fno-ghci-history -fshow-warning-groups -fno-diagnostics-show-caret -fdiagnostics-color=never < T17549.script\necho --- exitcode=$? ---\nls -la T17549.hs' 2>&1",
  "description": "Reproduce T17549 failure"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && source scripts/cross-env.sh 2>&1 | head -10; echo \"---\"; which $CC 2>/dev/null; echo \"PPC_CC=$PPC_CC\"; echo \"CC=$CC\"",
  "description": "Check cross-env"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source scripts/cross-env.sh && echo \"TARGET_CC=$TARGET_CC\"; type ppc-cc 2>&1; ls /Users/cell/.local/ghc-ppc-xtools/bin-wrap/",
  "description": "Check cross-cc"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && echo \"PATH includes bin-wrap?\" && which ppc-cc && echo \"ok\" && ppc-cc --version 2>&1 | head -3",
  "description": "Sanity-check ppc-cc"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source scripts/cross-env.sh 2>/dev/null && cd /tmp && mkdir -p unlit-build && cd unlit-build && cp /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/utils/unlit/{unlit.c,fs.c,fs.h} . && $CROSS_CC -O2 -o powerpc-apple-darwin8-unlit unlit.c fs.c 2>&1 | head -20 && echo \"=== file ===\" && file powerpc-apple-darwin8-unlit 2>&1",
  "description": "Cross-compile unlit"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "scp -q /tmp/unlit-build/powerpc-apple-darwin8-unlit pmacg5:/tmp/unlit-correct && ssh -e none pmacg5 'file /tmp/unlit-correct && /tmp/unlit-correct --help 2>&1 | head -3; echo ---; echo \"> t = putStrLn \\\"Test\\\"\" > /tmp/test.lhs && /tmp/unlit-correct /tmp/test.lhs /tmp/test.hs && cat /tmp/test.hs'",
  "description": "Deploy and test unlit on pmacg5"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "otool -hv /tmp/unlit-build/powerpc-apple-darwin8-unlit 2>&1; echo ---; ssh -e none pmacg5 'otool -hv /tmp/unlit-correct 2>&1'",
  "description": "Inspect Mach-O headers"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la /tmp/unlit-build/; ssh -e none pmacg5 'ls -la /tmp/unlit-correct'",
  "description": "Check file sizes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/.local/ghc-ppc-xtools/bin-wrap/ppc-cc | head -30",
  "description": "Inspect ppc-cc wrapper"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/.local/ghc-ppc-xtools/bin-wrap/ppc-cc",
  "offset": 30
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && cd /tmp/unlit-build && rm -f *.o powerpc-apple-darwin8-unlit && $CROSS_CC -O2 -c unlit.c && $CROSS_CC -O2 -c fs.c && ls -la *.o && file *.o",
  "description": "Compile unlit object files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && cd /tmp/unlit-build && $CROSS_CC -o powerpc-apple-darwin8-unlit unlit.o fs.o 2>&1 && ls -la powerpc-apple-darwin8-unlit && file powerpc-apple-darwin8-unlit",
  "description": "Link unlit via tiger_link"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "scp -q /tmp/unlit-build/powerpc-apple-darwin8-unlit pmacg5:/tmp/unlit-correct && ssh -e none pmacg5 'file /tmp/unlit-correct && /tmp/unlit-correct --help 2>&1 | head -3; echo \"---\"; echo \"> t = putStrLn \\\"Test\\\"\" > /tmp/test.lhs && /tmp/unlit-correct /tmp/test.lhs /tmp/test.hs && echo \"exit=$?\" && cat /tmp/test.hs'",
  "description": "Deploy and test new unlit"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ssh -e none pmacg5 '\nset -e\ncd /opt/ghc-stage2/lib/bin\nls -la powerpc-apple-darwin8-unlit\n# Back up the broken arm64 binary\nsudo cp -p powerpc-apple-darwin8-unlit powerpc-apple-darwin8-unlit.arm64.broken 2>/dev/null || cp -p powerpc-apple-darwin8-unlit powerpc-apple-darwin8-unlit.arm64.broken\n# Install corrected ppc binary\nsudo cp /tmp/unlit-correct powerpc-apple-darwin8-unlit 2>/dev/null || cp /tmp/unlit-correct powerpc-apple-darwin8-unlit\nls -la powerpc-apple-darwin8-unlit powerpc-apple-darwin8-unlit.arm64.broken\necho \"=== file ===\"\nfile powerpc-apple-darwin8-unlit powerpc-apple-darwin8-unlit.arm64.broken\n'",
  "description": "Deploy corrected unlit, back up broken one"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh 2>&1 | tee docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/logs/run-2-after-unlit-fix.log | tail -20",
  "description": "Re-run tests with corrected unlit (background)",
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: TaskOutput
Input: {
  "task_id": "bu2zkm3ia",
  "block": true,
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: TaskOutput
Input: {
  "task_id": "bu2zkm3ia",
  "block": true,
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep \"FAIL\" docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/logs/run-2-after-unlit-fix.log",
  "description": "Find FAILs in run 2 log"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/logs/ghci-tnum/T8042\necho \"=== T8042.script ===\"\ncat T8042.script\necho \"=== expected.stdout ===\"\ncat expected.stdout\necho \"=== actual.stdout ===\"\ncat actual.stdout\necho \"=== diff -w ===\"\ndiff -w expected.stdout actual.stdout",
  "description": "Inspect T8042 (new fail in run 2)"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Verify baseline (skip \u2014 stage2 unchanged from session 57)",
      "status": "completed",
      "activeForm": "Skipping baseline (stage2 unchanged)"
    },
    {
      "content": "Set up session 58 dir + scaffolding",
      "status": "completed",
      "activeForm": "Setting up session 58 dir"
    },
    {
      "content": "Parse all.T for T-prefix .script tests with normal/combined_output",
      "status": "completed",
      "activeForm": "Parsing all.T for T-prefix tests"
    },
    {
      "content": "Write run-ghci-tnum.sh runner",
      "status": "completed",
      "activeForm": "Writing T-num runner"
    },
    {
      "content": "Run 1 on pmacg5: 161/163 PASS (T10989 & T17549 fail)",
      "status": "completed",
      "activeForm": "Run 1 complete"
    },
    {
      "content": "Diagnose T10989: unlit binary on /opt is arm64 (packaging bug)",
      "status": "completed",
      "activeForm": "Diagnosed unlit packaging bug"
    },
    {
      "content": "Cross-compile + deploy fixed ppc unlit",
      "status": "completed",
      "activeForm": "Deployed fixed unlit"
    },
    {
      "content": "Run 2: 161/163 (T10989 fixed, T8042 newly flaky)",
      "status": "completed",
      "activeForm": "Run 2 complete; T8042 flakes"
    },
    {
      "content": "Run 3 to confirm T8042/T17549 flake pattern",
      "status": "in_progress",
      "activeForm": "Running run 3 for flake characterisation"
    },
    {
      "content": "Write README, findings, commits, HANDOFF",
      "status": "pending",
      "activeForm": "Writing session notes"
    },
    {
      "content": "Update top-level README + state.md + roadmap.md",
      "status": "pending",
      "activeForm": "Updating top-level docs"
    },
    {
      "content": "Decide on unlit fix release path (v0.14.1 vs HANDOFF item)",
      "status": "pending",
      "activeForm": "Deciding unlit fix path"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "bash docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh 2>&1 | tee docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/logs/run-3-flake-check.log | grep -E \"(FAIL|Summary)\"",
  "description": "Run 3 (background) for flake check",
  "run_in_background": true
}


---

## 🤖 Claude


🔧 Using tool: TaskOutput
Input: {
  "task_id": "b2zm45wke",
  "block": true,
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: TaskOutput
Input: {
  "task_id": "b2zm45wke",
  "block": true,
  "timeout": 600000
}


---

## 🤖 Claude

Three runs done. T10989 fixed by unlit replacement. T8042 and T17549 are HFS+ mtime-granularity flakes. Now writing it all up.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Verify baseline (skip \u2014 stage2 unchanged from session 57)",
      "status": "completed",
      "activeForm": "Skipping baseline (stage2 unchanged)"
    },
    {
      "content": "Set up session 58 dir + scaffolding",
      "status": "completed",
      "activeForm": "Setting up session 58 dir"
    },
    {
      "content": "Parse all.T for T-prefix .script tests with normal/combined_output",
      "status": "completed",
      "activeForm": "Parsing all.T for T-prefix tests"
    },
    {
      "content": "Write run-ghci-tnum.sh runner",
      "status": "completed",
      "activeForm": "Writing T-num runner"
    },
    {
      "content": "Run 1 on pmacg5: 161/163 PASS (T10989 & T17549 fail)",
      "status": "completed",
      "activeForm": "Run 1 complete"
    },
    {
      "content": "Diagnose T10989: unlit binary on /opt is arm64 (packaging bug)",
      "status": "completed",
      "activeForm": "Diagnosed unlit packaging bug"
    },
    {
      "content": "Cross-compile + deploy fixed ppc unlit",
      "status": "completed",
      "activeForm": "Deployed fixed unlit"
    },
    {
      "content": "Run 2: T10989 fixed, T8042 newly flaking, T17549 still fail",
      "status": "completed",
      "activeForm": "Run 2 complete"
    },
    {
      "content": "Run 3: confirm T8042+T17549 are HFS+ mtime-granularity flakes",
      "status": "completed",
      "activeForm": "Run 3 done; flake confirmed"
    },
    {
      "content": "Write README.md",
      "status": "in_progress",
      "activeForm": "Writing README"
    },
    {
      "content": "Write findings.md, commits.md, HANDOFF.md",
      "status": "pending",
      "activeForm": "Writing findings/commits/handoff"
    },
    {
      "content": "Update top-level README + state.md + roadmap.md",
      "status": "pending",
      "activeForm": "Updating top-level docs"
    },
    {
      "content": "Save the cross-built unlit + a build script under scripts/",
      "status": "pending",
      "activeForm": "Saving unlit fix artifacts"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cp /tmp/unlit-build/powerpc-apple-darwin8-unlit /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/powerpc-apple-darwin8-unlit.ppc\nls -la /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/powerpc-apple-darwin8-unlit.ppc\nfile /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/powerpc-apple-darwin8-unlit.ppc",
  "description": "Stash the corrected unlit binary in session dir"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/build-unlit-ppc.sh",
  "content": "#!/bin/bash\n# Cross-build the upstream `unlit` utility for PPC/Tiger.\n#\n# Why: the v0.14.0 bindist ships an *arm64* unlit at\n# /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit, because\n# Hadrian's cross-build path in `hadrian/src/Rules/Program.hs`\n# copies stage0 (host) helper binaries to stage1 for every package\n# except `iserv`.  patch 0010 carved out iserv but missed unlit.\n# Result: literate Haskell support (`.lhs`, the `:l foo.lhs` path\n# in GHCi, etc.) is broken on the deployed stage2 because the unlit\n# pre-processor can't actually execute.\n#\n# This script cross-builds a real PPC `unlit` from the GHC 9.2.8\n# source tree using our cross-cc.  Output is dropped next to this\n# script as `powerpc-apple-darwin8-unlit.ppc`.  To install:\n#\n#     scp powerpc-apple-darwin8-unlit.ppc pmacg5:/tmp/unlit\n#     ssh pmacg5 'mv /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit \\\n#                     /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.broken-host && \\\n#                  mv /tmp/unlit /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit && \\\n#                  chmod +x /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit'\n#\n# This is a *stopgap* \u2014 the real fix is a Hadrian patch that adds\n# `unlit` (and `touchy`, for completeness) to patch 0010's\n# \"don't copy stage0 binary in cross mode\" exclusion list, then a\n# stage1 rebuild + stage2 re-cross-build + new bindist.  That's a\n# v0.14.1 release-grade fix, scoped in session 58 HANDOFF.\n\nset -euo pipefail\n\nREPO_ROOT=\"$(cd \"$(dirname \"$0\")/../../../..\" && pwd)\"\nGHC_SRC=\"${GHC_SRC:-$REPO_ROOT/external/ghc-modern/ghc-9.2.8}\"\nUNLIT_SRC=\"$GHC_SRC/utils/unlit\"\nSCRIPT_DIR=\"$(cd \"$(dirname \"$0\")\" && pwd)\"\nOUT=\"$SCRIPT_DIR/powerpc-apple-darwin8-unlit.ppc\"\n\n# shellcheck source=../../../../scripts/cross-env.sh\nsource \"$REPO_ROOT/scripts/cross-env.sh\" >/dev/null\n\nWORK=$(mktemp -d)\ntrap 'rm -rf \"$WORK\"' EXIT\n\ncp \"$UNLIT_SRC/unlit.c\" \"$UNLIT_SRC/fs.c\" \"$UNLIT_SRC/fs.h\" \"$WORK/\"\ncd \"$WORK\"\n\n# Compile each .c separately (the ppc-cc wrapper routes compile-only\n# invocations to clang directly; compile+link from .c goes through the\n# fake-linker path and produces a 16-byte stub).\n\"$CROSS_CC\" -O2 -c unlit.c\n\"$CROSS_CC\" -O2 -c fs.c\n# Link via tiger_link (pure-link path: no source files in args).\n\"$CROSS_CC\" -o powerpc-apple-darwin8-unlit unlit.o fs.o\n\n# Sanity-check.\nfile powerpc-apple-darwin8-unlit | grep -q 'Mach-O executable ppc' \\\n  || { echo \"ERROR: built binary is not Mach-O ppc\"; exit 1; }\n\ninstall -m 0755 powerpc-apple-darwin8-unlit \"$OUT\"\necho \"Built: $OUT\"\nfile \"$OUT\"\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/build-unlit-ppc.sh\n# Verify the script reproduces the binary cleanly.\nrm -f /tmp/unlit-build-verify/powerpc-apple-darwin8-unlit.ppc 2>/dev/null\nbash /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/build-unlit-ppc.sh 2>&1 | tail -10",
  "description": "Run the unlit build script to confirm it works"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/README.md",
  "content": "# Session 58 \u2014 GHCi T<num> script subset + unlit packaging fix\n\n**Date:** 2026-05-17 (continuation of sessions 56 / 57).\n\n**Status on arrival:** Session 56 verified the v0.14.0 REPL against\n51/51 `ghciNNN`-style scripts; session 57 verified 83/83 of the\n`ghci.debugger/scripts/` family.  Both runs filtered to the\nghciNNN / debugger naming conventions, leaving the ~160 bug-numbered\n`T<NUM>.script` regression tests in `testsuite/tests/ghci/scripts/`\nuntouched.  Session 57 HANDOFF priority #1 said to \"drop the\n`req_th` filter\" and pick up TH-using ghci scripts \u2014 but on\ninspection `req_th` annotations don't actually appear in\n`tests/ghci/scripts/all.T` at all (`grep \"req_th\" all.T` is empty).\nThe real next move was always to extend the TESTS list to the\nT-prefix scripts, which incidentally subsumes the TH-from-REPL\ncases the HANDOFF was concerned about (T4127, T4127a, T5566, T8831,\nT10466, T11098).\n\n**Status on exit:** **161/163 PASS** on the curated subset of\nT-prefix tests from `tests/ghci/scripts/all.T` \u2014 every test with\nannotation in `{normal, combined_output, extra_files(...)}` that\ndoesn't need special harness.  One run-1 failure surfaced a real\n**packaging bug** \u2014 the v0.14.0 bindist's `unlit` helper at\n`/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` is an\n**arm64 Mach-O**, not PPC.  Hadrian's cross-build copies stage0\n(host) helpers into stage1 for everything except `iserv` (patch\n0010 carved iserv out and missed `unlit`).  Fixed in-place on\npmacg5 by cross-building a real PPC unlit and dropping it in; the\nbroken host binary is preserved alongside as\n`powerpc-apple-darwin8-unlit.arm64.broken`.  After the fix\nT10989 (the literate Haskell `:l dummy.lhs` test) passes.  The\nremaining two failures \u2014 T8042 and T17549 \u2014 are HFS+ filesystem\nmtime granularity races in the test scripts themselves, not PPC\nbugs (see [findings.md](findings.md) \u00a73).  **No GHC source-tree\nchanges, no new patches, no release tag this session** \u2014 the\nHadrian patch update is queued for a v0.14.1 bindist re-roll\n(HANDOFF priority #1).\n\n## Why this matters\n\nSessions 56 / 57 exercised the REPL command processor and the\nbytecode debugger respectively.  The T-prefix subset in\n`tests/ghci/scripts/` covers what amounts to \"every GHCi user\nissue ever filed and turned into a regression test\" \u2014 a dense,\nground-truthy corpus that targets specific behaviours that other\nnon-TH-using ghci script test categories don't.  Bugs covered (in\ndescending interestingness for PPC):\n\n- **TH from the REPL** \u2014 T4127, T4127a (typed splice round-trip);\n  T5566 (template-haskell quotation); T8831 (TH-introduced names\n  visible to `:type`); T10466 (`-XTemplateHaskell` carry-over on\n  `:reload`); T11098 (`$$x` typed-splice).  These were\n  session-57-HANDOFF priority #1's actual concern.\n- **Module loading edge cases** \u2014 T1914 (file rewrite triggering\n  reload); T8042 (object-code vs interpreted module switching);\n  T8696 / T10110 / T10322 (multi-module `:load` with `-fobject-code`);\n  T16804 / T16876 (multi-module loading variants).\n- **Type system surface tested via REPL** \u2014 T6018ghci/fail/rnfail\n  (type-family injectivity warnings); T13202 / T13202a (kinded\n  type-family decls); T5417, T8469 (associated type families);\n  TypeAppData (visible type application on data constructors);\n  T13407, T15259, T15341 (kind polymorphism); T17345 (impredicative\n  types in `:type`).\n- **Static pointers** \u2014 `StaticPtr.script` exercises the static\n  pointer table from REPL.  Walks `staticPtrKeys`,\n  `unsafeLookupStaticPtr`, `deRefStaticPtr` \u2014 all of which touch\n  the RTS's per-module static pointer table.  Passes.\n- **Literate Haskell** \u2014 T10989 (`:l dummy.lhs`).  Drives the\n  `unlit` pre-processor.  This is the test that surfaced the\n  packaging bug.\n\nIf anything in the REPL command processor's interaction with the\ntypechecker, kind inference, BCO codegen for TH splices, or the\nstatic-pointer table on PPC32 was broken, these 163 tests would\nmostly fail.  They don't \u2014 modulo the wrong-arch unlit binary\n(a packaging bug, not a runtime bug) and two HFS+-mtime races in\nthe test scripts themselves.\n\n## What was run\n\n[`docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/run-ghci-tnum.sh`](scripts/run-ghci-tnum.sh)\nparses the upstream `tests/ghci/scripts/all.T` for T-prefix /\nnon-ghciNNN script tests and runs the same staging-and-diff\nharness session 56 introduced.  Selection criteria:\n\n- annotation is `normal` / `combined_output` / plain\n  `extra_files(...)` (skip everything with `extra_hc_opts`,\n  `extra_run_opts`, `reqlib`, `req_th`, `req_interp`,\n  `expect_broken`, `pre_cmd`, `skip`, `fragile`, `cmd_prefix`,\n  `makefile_test`, `filter_stdout_lines`, `normalise_*`,\n  `ignore_*`, `when(...)` non-trivial predicates);\n- `extra_files` outside the scripts/ dir (`../...`) skipped \u2014\n  T14676 (needs `../prog002`), Defer02 (needs\n  `../../typecheck/should_run/Defer01.hs`).\n\nThat yields 163 candidates (the parser script is reproduced inline\nin `findings.md` \u00a71).  Explicit extras added below the parser\noutput cover companions the auto-discovery globs miss\n(lowercase / capital suffix `.hs` files):\nT5417a, T8469a, T8696A/B, T10110A/B/C, T10322A/B/C, T16876A/B,\nplus the all.T-declared T8353/Defer03, T10576a/b/T10576,\nT16804/T16804a-c, T19667Ghci.\n\nRunner reuse: identical pipeline to session 56 (stage tarball \u2192\nscp once \u2192 run each ghci over piped stdin \u2192 tar back \u2192 normalise\nexpected and actual through `scripts/normalise.py` \u2192 `diff -qw`).\nThe normaliser is symlinked from session 56's (session 57 added\ntwo upstream rules; nothing new added this session).\n\n## What happened\n\n**Run 1 (163 tests):** 161 PASS / 2 FAIL.\n- `T10989` failed: stderr showed\n  `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit: cannot\n   execute binary file`.  Investigation:\n   `file powerpc-apple-darwin8-unlit` says **Mach-O 64-bit\n   executable** (cputype 0x100000C \u2014 arm64).  This is the host\n   binary, copied verbatim by Hadrian into stage1 during the cross\n   build.  Real root cause in\n   `hadrian/src/Rules/Program.hs` ([finding \u00a72](findings.md)).\n- `T17549` failed: empty stderr where the test expected a parse\n  error.  Reproduced manually; cause is HFS+'s 1-second mtime\n  granularity ([finding \u00a73](findings.md)) \u2014 the script's second\n  `writeFile` lands in the same second as the initial `:load`,\n  so `:reload` sees mtime unchanged and skips, so the parse error\n  it expects never fires.\n\n**unlit fix:** session 58's\n[`scripts/build-unlit-ppc.sh`](scripts/build-unlit-ppc.sh)\ncross-builds a real PPC `unlit` from\n`external/ghc-modern/ghc-9.2.8/utils/unlit/` using `$CROSS_CC`,\ncompile-then-link in two steps (the ppc-cc wrapper routes\ncompile-only invocations to real clang and pure-link invocations\nto the real Tiger linker via `ppc-ld-tiger`; compile+link from a\n.c file goes through `ppc-ld-fake` and produces a 16-byte stub).\nThe resulting 14-KB Mach-O ppc binary is stashed at\n[`scripts/powerpc-apple-darwin8-unlit.ppc`](scripts/) and was\ninstalled on pmacg5:\n\n```\n/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit              (now ppc)\n/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.arm64.broken (backup)\n```\n\n**Run 2 (after unlit fix):** 161 PASS / 2 FAIL.\n- T10989 \u2705 now passes (cross-built unlit accepts `dummy.lhs`).\n- T8042 FAIL \u2014 diff shows the line\n  `[3 of 3] Compiling T8042A ( T8042A.hs, T8042A.o )` is missing.\n  Same shape as T17549: writeFile A \u2192 :load \u2192 writeFile A \u2192 :reload,\n  where the second writeFile lands in the same second as :load and\n  :reload skips.  T8042 happened to PASS in run 1 (timing variance);\n  fails reproducibly in runs 2 and 3.\n\n**Run 3 (sanity check):** 161 PASS / 2 FAIL \u2014 T8042 + T17549,\nidentical to run 2.\n\n## What this proves about the v0.14.0 REPL (after unlit fix)\n\n| Area | Tests | Status |\n|---|---|---|\n| TemplateHaskell from REPL (typed splices, quotation, reload) | T4127, T4127a, T5566, T8831, T10466, T11098 | \u2705 (6 tests) |\n| `:reload` / `:load` / module dependency tracking | T1914, T8042, T8042recomp, T8696, T10110, T10322, T11051a, T11051b, T16030, T16527, T17549, T20019 | \u2705 (10/12; T8042+T17549 flaky on HFS+, harness-side) |\n| Type families + kind polymorphism in REPL | T5417, T6018ghci/fail/rnfail, T8469, T13202, T13202a, T13407, T15259, T15341, T15568, T17345 | \u2705 (11 tests) |\n| `:type` / `:info` / `:kind` printing | T2766, T2976, T2816, T3263, T4316, T5045, T6027ghci, T7117, T7587, T7688, T8113, T8579, T15827, T15872, T17384, T17431, T17549, T18828, T19158 | \u2705 (most; T17549 flaky) |\n| Bidirectional `:browse` / `:show modules` | T11252, T11456, T11606, T11975, T12005, T12158 | \u2705 (6 tests) |\n| Dynamic file rewrite via `writeFile` + reload | T1914, T8042, T10989, T17549 | \u2705 (2/4; the other two are HFS+ mtime races, not PPC bugs) |\n| Literate Haskell pre-processor (`unlit`) | T10989 | \u2705 (after replacing wrong-arch unlit binary) |\n| `StaticPointers` via REPL \u2014 `staticPtrKeys`, `unsafeLookupStaticPtr`, `deRefStaticPtr` | StaticPtr | \u2705 |\n| Type-application syntax in REPL (`-XTypeApplications`) | TypeAppData, T13202, T13420 | \u2705 (3 tests) |\n| GADTs / pattern synonyms in REPL | T11098, T11376, T11728, T13988 | \u2705 (4 tests) |\n| `:break` / `:list` in non-debugger scripts | T7873, T13407 | \u2705 |\n| `:set -XCPP` / `:set -XHaskell2010` etc. (extension toggles mid-session) | T2182ghci, T5045, T6027ghci, T7388, T16089, T16767 | \u2705 |\n| `:show` / `:set` introspection | T6105, T11051a, T11051b, T16527 | \u2705 |\n| Regression Ts for specific bug IDs | T<bug-num> across the table | \u2705 |\n\nZero PPC- or endian-specific failures in run 2.  Every failure is\nattributable to a packaging error (the arm64 unlit, now fixed) or\na known testsuite-design race against HFS+'s 1-second mtime\ngranularity.\n\n## What this session did NOT do\n\n* Did not change any GHC source-tree files.\n* Did not regenerate patch 0010 to also exclude `unlit` (and\n  `touchy`) from the cross-build host-copy path.  That, plus a\n  stage1 rebuild + stage2 re-cross-build + new bindist tarball,\n  is the proper v0.14.1 release-grade fix.  Scoped in HANDOFF\n  priority #1.\n* Did not produce a new bindist or release tag.\n* Did not skip the two flaky tests from the TESTS list \u2014 they\n  stay in for honesty, and the runner reports them as FAIL each\n  run.  See HANDOFF priority #2 for the option to skip and claim\n  161/161.\n\n## Files added this session\n\n- `docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/`\n  - `README.md` (this)\n  - `findings.md`\n  - `commits.md`\n  - `HANDOFF.md`\n  - `scripts/run-ghci-tnum.sh` \u2014 the runner (163-test TESTS list).\n  - `scripts/normalise.py` \u2192 symlink to session 56's normaliser\n    (no changes this session).\n  - `scripts/build-unlit-ppc.sh` \u2014 cross-builds the corrected PPC\n    unlit from the GHC source tree.  Self-contained; reproduces\n    the `powerpc-apple-darwin8-unlit.ppc` artifact next to it.\n  - `scripts/powerpc-apple-darwin8-unlit.ppc` \u2014 the 14-KB built\n    PPC unlit binary.  Installed on pmacg5 at\n    `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` this\n    session.\n  - `logs/run-1-initial.log` \u2014 first run, 161/163, T10989 +\n    T17549 failed.\n  - `logs/run-2-after-unlit-fix.log` \u2014 after unlit replacement,\n    161/163, T8042 + T17549 failed.\n  - `logs/run-3-flake-check.log` \u2014 third run, 161/163, same as\n    run 2.\n  - `logs/ghci-tnum/` \u2014 per-test working dirs.\n- `README.md` \u2014 Implementation-status table updated.\n- `docs/state.md` \u2014 top-of-file bumped to session 58.\n- `docs/roadmap.md` \u2014 \u00a7C note added re: 161/163 T-num subset\n  passing + unlit packaging bug.\n\n## On pmacg5\n\nModified in-place:\n\n- `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` \u2014 replaced\n  with the session-58-cross-built PPC binary.  Was 84 KB arm64;\n  now 14 KB ppc.\n- `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.arm64.broken`\n  \u2014 backup of the original wrong-arch binary, kept for forensics\n  / to confirm the root cause is what we think it is.\n\nThe rest of the stage2 install is unchanged from v0.14.0.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/findings.md",
  "content": "# Session 58 findings\n\n## TL;DR\n\n161/163 of the T-prefix `tests/ghci/scripts/` testsuite (the\nsubset that doesn't need special harness) PASS on PPC/Tiger via\nthe deployed v0.14.0 stage2 ghc \u2014 once a packaging bug in the\nbindist is repaired in-place.  The remaining two failures are\nHFS+ filesystem mtime granularity races in the test scripts\nthemselves (not PPC runtime bugs).  No GHC source-tree changes\nthis session.\n\n## 1. The 163-test selection (reproducer)\n\n```python\n# Run from external/ghc-modern/ghc-9.2.8/.\nimport re\nall_t = open('testsuite/tests/ghci/scripts/all.T').read()\nEXCLUDE = ['extra_hc_opts', 'extra_run_opts', 'reqlib', 'req_interp',\n           'req_th', 'expect_broken', 'pre_cmd', 'skip',\n           'makefile_test', 'cmd_prefix', 'fragile',\n           'filter_stdout_lines', 'ignore_stdout', 'ignore_stderr',\n           'normalise_slashes', 'normalise_version', 'extra_ways',\n           'when(', 'unless(', 'expect_fail']\nP = re.compile(\n    r\"test\\('([^']+)'\\s*,\\s*(.+?)\\s*,\\s*ghci_script\\s*,\\s*\\['([^']+)\\.script'\\]\\s*\\)\",\n    re.DOTALL)\nfor m in P.finditer(all_t):\n    name, body = m.group(1), m.group(2).strip()\n    if name.startswith('ghci'):        continue   # session 56 covered these\n    if any(k in body for k in EXCLUDE): continue\n    ef = re.search(r\"extra_files\\(\\[(.*?)\\]\\)\", body)\n    if ef and any('/' in f or f.startswith('..')\n                  for f in re.findall(r\"'([^']+)'\", ef.group(1))):\n        continue   # extras outside scripts/ \u2014 too painful to stage\n    print(name)\n```\n\n163 names emerge.  6 of them exercise TemplateHaskell \u2014 T4127,\nT4127a, T5566, T8831, T10466, T11098 \u2014 directly addressing the\nsession-57-HANDOFF priority #1 concern (test TH driven via the\nREPL).  No PPC failures across any of those once unlit is fixed\n(see \u00a72).\n\n## 2. The unlit packaging bug\n\n### Symptom\n\n`T10989` (literate Haskell `:l dummy.lhs` reload test) failed in\nrun 1 with stderr:\n\n```\n/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit:\n/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit: cannot execute binary file\n\ndummy.lhs:1:1:\n    `powerpc-apple-darwin8-unlit' failed in phase\n    `Literate pre-processor'. (Exit code: 126)\n```\n\nExit code 126 = \"command found but not executable\", which on\nMach-O means wrong arch (kernel's `execve` can't find a matching\nslice).\n\n### Diagnosis\n\n```\n$ ssh pmacg5 'file /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit'\nMach-O 64-bit executable\n\n$ ssh pmacg5 'otool -hv /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit'\n      magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags\nMH_MAGIC_64 16777228          0  0x00     EXECUTE    18       1208   ...\n```\n\n`cputype 16777228 = 0x100000C = CPU_TYPE_ARM` with the `CPU_ARCH_ABI64`\nbit set \u2014 that's **arm64**, the build host's arch.  The binary is\nthe uranium-side host `unlit` copied verbatim into the bindist with\na `powerpc-apple-darwin8-` filename prefix.\n\n### Root cause\n\n`hadrian/src/Rules/Program.hs` (lines 99\u2013114, GHC 9.2.8):\n\n```haskell\ncase (cross, stage) of\n    (True, s) | s > Stage0 && package /= iserv -> do\n        srcDir <- buildRoot <&> (-/- (stageString Stage0 -/- \"bin\"))\n        copyFile (srcDir -/- takeFileName bin) bin\n    (False, s) | s > Stage0 && (package `elem` [touchy, unlit]) -> do\n        srcDir <- stageLibPath Stage0 <&> (-/- \"bin\")\n        copyFile (srcDir -/- takeFileName bin) bin\n    _ -> buildBinary rs bin ctx\n```\n\nIn **cross** mode (first arm), every package above Stage0 gets its\nstage0 (host) binary copied into stage1 except `iserv`.  Patch\n0010 carved out `iserv` (so it cross-builds a real ppc binary for\nTemplateHaskell) but missed `unlit`.  Result: stage1 ships the\nhost's arm64 `unlit` with a `powerpc-apple-darwin8-` prefix, and\nthat's what gets dropped into the bindist tarball.\n\nThe fix is a one-liner \u2014 change `package /= iserv` to\n`package `notElem` [iserv, unlit]`, which is the same shape as\nthe non-cross arm already uses for `[touchy, unlit]`.  In cross\nmode `unlit` will then fall through to `buildBinary`, which the\ncross-ghc handles fine (unlit is a pure-C utility \u2014 no Haskell\ndeps, no RTS).  We've already validated that the cross-cc can\nbuild it via the script in `scripts/build-unlit-ppc.sh`.\n\n### Why this wasn't caught earlier\n\nunlit only fires on `.lhs` (literate Haskell) inputs.  Nothing in\nthe project's test battery or in sessions 55\u201357 touches `.lhs`\nfiles.  The cross-build's stage1 testsuite would have caught it,\nbut we don't run hadrian's full testsuite (we use our own\nend-to-end battery).  The bug has been latent since v0.7.0 (which\nlanded iserv via patch 0010) \u2014 for over a year nobody hit `.lhs`\nin REPL.\n\n### Forensics\n\nBoth binaries are kept on pmacg5 for inspection:\n\n```\n$ ssh pmacg5 'ls -la /opt/ghc-stage2/lib/bin/'\npowerpc-apple-darwin8-ghc-iserv               29.7 MB   ppc Mach-O   (correct)\npowerpc-apple-darwin8-unlit                   14   KB   ppc Mach-O   (session 58 fix)\npowerpc-apple-darwin8-unlit.arm64.broken      84   KB   arm64 Mach-O (was)\n```\n\n`scripts/powerpc-apple-darwin8-unlit.ppc` in this session dir is\nbyte-identical to what's on pmacg5; `build-unlit-ppc.sh`\nreproduces it from the GHC source tree.\n\n## 3. The HFS+ mtime-granularity race\n\n### Symptom\n\n`T17549` fails 100% of the time on PPC/Tiger; `T8042` fails ~2 of 3\ntimes in our runs (passed run 1, failed runs 2 + 3).  Both share\nthe same shape:\n\n```\nwriteFile \"X.hs\" \"<some content>\"\n:load X.hs\nwriteFile \"X.hs\" \"<different content>\"\n:reload\n```\n\nExpected behaviour: `:reload` recompiles X.hs.\n\nActual on PPC/Tiger: `:reload` sees X.hs mtime unchanged and\nskips (the empty stdout/stderr in actual.* confirms it never\nreached the compile phase).\n\n### Diagnosis\n\nHFS+ on Tiger stores mtimes with 1-second granularity (POSIX\n`utimes()` precision, no `utimensat` / `mtim_nsec` on 10.4).\nGHCi's recompilation logic (in `GHC.Iface.Recomp`,\n`checkMod hsc_env hpt mod`) checks the source file's mtime\nagainst the cached value from the last load.  If the file is\nrewritten in the same second as it was first read, mtime is\nunchanged and the recomp logic concludes \"no work needed\".\n\nManual reproduction with explicit `touch -t`:\n\n```bash\nssh pmacg5 'cat > /tmp/repro.script <<EOF\nwriteFile \"X.hs\" \"\"\n:load X.hs\nwriteFile \"X.hs\" \"import\"\n:! touch X.hs\n:reload\n1\nEOF\nghc-real --interactive < /tmp/repro.script'\n```\n\nWith the touch, the parse error fires as expected.  Without it,\nnothing \u2014 exactly matches the T17549/T8042 failure mode.\n\n### Why T1914 succeeds where T8042/T17549 fail\n\nT1914 has the same `writeFile + :load + writeFile + :reload`\nshape **but** it explicitly bumps mtimes:\n\n```\nSystem.IO.writeFile \"T1914A.hs\" \"module T1914A where { import T1914B; }\"\n:! touch -t 01010000 T1914A.hs\n...\nSystem.IO.writeFile \"T1914A.hs\" \"...oops\"\n:! touch -t 01010001 T1914A.hs\n:reload\n```\n\nThe `touch -t` calls set explicit, distinct mtimes \u2014 bypassing\nthe filesystem's granularity entirely.  T8042 and T17549 were\nauthored later and forgot to do the same.  On Linux ext4\n(nanosecond mtimes) the race doesn't surface; on Tiger HFS+ it\ndoes.\n\n### Why T8042 sometimes passes\n\nT8042 has three writeFiles + :load + a fourth writeFile.  The\ncombined latency of those four IO ops *plus* the three-module\n:load is on the edge of a 1-second tick.  Run 1 happened to span\ntwo seconds; runs 2 and 3 happened to fit in one.  Pure timing\nvariance.\n\n### What to do\n\nFor an unbiased PASS count, leave both in the TESTS list and\nreport the run-stable failures honestly:\n\n- T17549: 0% PASS on PPC/Tiger.\n- T8042: ~30% PASS on PPC/Tiger (1/3 in our runs).\n\nFor a clean \"X / X PASS\" headline, the runner could exclude these\ntwo with a comment pointing to this section.  We chose honesty.\nThe upstream fix would be to add explicit `touch -t` calls to\nboth .script files \u2014 uncontroversial, would be a small upstream\nMR.\n\n## 4. The two-step cross-build pattern for utils/\n\nThe `unlit` build script taught me how to coax the ppc-cc wrapper\ninto producing a real binary.  Notable:\n\n- `$CROSS_CC -O2 -o foo bar.c baz.c` \u2014 produces a 16-byte stub\n  (ppc-cc routes compile+link with source through `ppc-ld-fake`,\n  which writes a Mach-O magic + empty header for configure\n  CC-works checks).\n- `$CROSS_CC -O2 -c bar.c && $CROSS_CC -O2 -c baz.c && $CROSS_CC\n  -o foo bar.o baz.o` \u2014 produces a real binary.  The compile-only\n  calls go to real clang; the pure-link call (no source files in\n  args) routes through `ppc-ld-tiger`, which is the real Tiger\n  linker via cctools-port.\n\nWorth documenting because the same pattern works for any of\nghc's C-only utilities (touchy, hp2ps, ...): they're not stuck\nneeding the full Hadrian build infrastructure.  If we ever need\nto retrofit other helper binaries that Hadrian's host-copy path\nmis-routes, the same `compile -c`-then-`link` recipe applies.\n\n## 5. Things still untested by this sweep\n\nEligible for a future T-num extension:\n\n- `extra_run_opts` tests: T9878b, T12091, T17500, T17669.\n  Easy follow-up if the runner threads RTS flags through.\n- `extra_hc_opts` tests: T2452, T2182ghci2, T5975b, T9293,\n  T13385, T14342, T16563.  Easy: thread compiler flags through.\n- `pre_cmd` tests: T5975a, T5975b, T6106, T9762, T19650.  Each\n  has a small Makefile or shell prelude.  Cherry-pick.\n- `reqlib` tests: T5979 (reqlib transformers).  Transformers is\n  a boot library; should just work.\n- The `Defer02` test needs files from `../../typecheck/`; needs a\n  cross-tree extras facility.\n\nThe T-prefix subdirectory tests (`tests/ghci/T11827/`, etc.) \u2014\neach a Makefile-driven mini-project \u2014 remain priority #2 from\nsession 57's HANDOFF.  Still uncovered.\n\n## 6. What was NOT a real bug\n\nFor future-self pre-emption:\n\n- `cannot execute binary file` from unlit on dummy.lhs \u2014 wrong-\n  arch binary in /opt/ghc-stage2/lib/bin/.  Fixed.  Real\n  packaging-side issue; Hadrian patch 0010 needs to also exclude\n  `unlit` from the cross-mode host-copy.\n- T8042 missing `[3 of 3] ... T8042A.o` line \u2014 HFS+ 1s mtime,\n  not a recomp bug.\n- T17549 empty stderr where parse error was expected \u2014 same.\n- T8042 having T8042recomp as a sibling test name was NOT a\n  staging problem; the auto-discovery glob `T8042.*` uses a\n  literal dot and correctly leaves T8042recomp.* alone.\n- T2182ghci / T2182ghci2, T7627 / T7627b, T13202 / T13202a,\n  T8959 / T8959b, T9878 / T9878b, T6018ghci / T6018ghcifail /\n  T6018ghcirnfail \u2014 sibling test names share a stem prefix.\n  Bash's `<name>.*` glob requires a literal dot before the suffix,\n  so sibling-test files aren't accidentally pulled into each\n  other's staging dir.  No code change needed; just worth\n  remembering when adding new tests to the list.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md",
  "content": "# Session 58 commits\n\nTo be backfilled with the actual commit SHA after `git commit`.\n\n- _SHA_: Session 58: 161/163 PASS on curated T<num> GHCi script subset; surface unlit packaging bug; deploy cross-built ppc unlit on pmacg5.\n"
}


---

## 🤖 Claude

Now the HANDOFF and top-level docs. Let me first peek at the README + state.md + roadmap.md so I know how to update them.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -150 /Users/cell/claude/ghc-darwin8-ppc/README.md",
  "description": "Inspect top-level README"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n \"session 56\\|session 57\\|session 58\\|161/163\\|run-ghci-subset\\|run-ghci-debugger\\|run-ghci-tnum\" /Users/cell/claude/ghc-darwin8-ppc/README.md | head -10",
  "description": "Find session refs in README"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/README.md",
  "old_string": "| GHCi REPL | \u2705 Working | [v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0).  `ghc -e`, `ghc --interactive`, `:t`, `:load`, `let`/lambdas, `:{ :}` blocks, imports, `Data.Map.Strict` lookups \u2014 all running in-process on a real PowerMac G5 under Mac OS X 10.4.  No new patches; the load-bearing pieces (runtime Mach-O loader, BCO byte-swap, `__eprintf` stub) have been in place since v0.8.0; v0.13.0's `STUArray Bool` fix unblocked the last gating dep.  Build change: `scripts/deploy-stage2.sh` compiles `ghc/Main.hs` with `-DHAVE_INTERNAL_INTERPRETER` + `-i$GHC_SRC/ghc -package exceptions -package time` (the cabal `internal-interpreter` flag's effective contents).  **Testsuite verification ([session 56](docs/sessions/2026-05-15-session-56-ghci-testsuite/)):** 51/51 PASS on a curated subset of upstream's `testsuite/tests/ghci/scripts/` \u2014 every `normal`/`combined_output` script test that doesn't need extra harness (reqlib, req_th, etc.).  Covers `:type` / `:info` / `:load` / `:reload` / `:browse` / `:instances` / `:m` / `:set prompt` / multi-line `:{ :}` / `:main` / `:def` / TH-splice-from-REPL / static-pointers / `:doc` / record-wildcards / type families. Reusable harness in [`scripts/run-ghci-subset.sh`](docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/run-ghci-subset.sh). |",
  "new_string": "| GHCi REPL | \u2705 Working | [v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0).  `ghc -e`, `ghc --interactive`, `:t`, `:load`, `let`/lambdas, `:{ :}` blocks, imports, `Data.Map.Strict` lookups \u2014 all running in-process on a real PowerMac G5 under Mac OS X 10.4.  No new patches; the load-bearing pieces (runtime Mach-O loader, BCO byte-swap, `__eprintf` stub) have been in place since v0.8.0; v0.13.0's `STUArray Bool` fix unblocked the last gating dep.  Build change: `scripts/deploy-stage2.sh` compiles `ghc/Main.hs` with `-DHAVE_INTERNAL_INTERPRETER` + `-i$GHC_SRC/ghc -package exceptions -package time` (the cabal `internal-interpreter` flag's effective contents).  **Testsuite verification ([session 56](docs/sessions/2026-05-15-session-56-ghci-testsuite/)):** 51/51 PASS on a curated subset of upstream's `testsuite/tests/ghci/scripts/` \u2014 every `normal`/`combined_output` script test that doesn't need extra harness (reqlib, req_th, etc.).  Covers `:type` / `:info` / `:load` / `:reload` / `:browse` / `:instances` / `:m` / `:set prompt` / multi-line `:{ :}` / `:main` / `:def` / TH-splice-from-REPL / static-pointers / `:doc` / record-wildcards / type families. Reusable harness in [`scripts/run-ghci-subset.sh`](docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/run-ghci-subset.sh).  **Extended verification ([session 58](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/)):** 161/163 PASS on the bug-numbered `T<NUM>.script` subset of the same dir (every `normal` / `combined_output` / `extra_files` test that doesn't need special harness).  Covers 6 TemplateHaskell-from-REPL regressions (T4127, T4127a, T5566, T8831, T10466, T11098), the `:reload` / `:load` / module-dependency family, type families + kind polymorphism, `StaticPtr`, type-applications, GADTs, and `T<NNN>` regressions across the issue tracker.  The two remaining failures are HFS+ mtime-granularity races in the upstream test scripts (T8042, T17549) \u2014 not PPC bugs.  Session 58 also surfaced and patched-in-place a real **packaging bug** in the v0.14.0 bindist: `lib/bin/powerpc-apple-darwin8-unlit` was a host (arm64) binary, not PPC; Hadrian's cross-build host-copy carve-out in [patch 0010](patches/0010-hadrian-cross-iserv.patch) only excluded `iserv` but should also have excluded `unlit`.  Pending a v0.14.1 release with the corrected Hadrian patch + rebuilt bindist; in the meantime [`scripts/build-unlit-ppc.sh`](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/build-unlit-ppc.sh) cross-builds a real PPC unlit. |"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/README.md",
  "offset": 130,
  "limit": 15
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/README.md",
  "old_string": "| GHCi REPL | \u2705 Working | [v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0).  `ghc -e`, `ghc --interactive`, `:t`, `:load`, `let`/lambdas, `:{ :}` blocks, imports, `Data.Map.Strict` lookups \u2014 all running in-process on a real PowerMac G5 under Mac OS X 10.4.  No new patches; the load-bearing pieces (runtime Mach-O loader, BCO byte-swap, `__eprintf` stub) have been in place since v0.8.0; v0.13.0's `STUArray Bool` fix unblocked the last gating dep.  Build change: `scripts/deploy-stage2.sh` compiles `ghc/Main.hs` with `-DHAVE_INTERNAL_INTERPRETER` + `-i$GHC_SRC/ghc -package exceptions -package time` (the cabal `internal-interpreter` flag's effective contents).  **Testsuite verification ([session 56](docs/sessions/2026-05-15-session-56-ghci-testsuite/)):** 51/51 PASS on a curated subset of upstream's `testsuite/tests/ghci/scripts/` \u2014 every `normal`/`combined_output` script test that doesn't need extra harness (reqlib, req_th, etc.).  Covers `:type` / `:info` / `:load` / `:reload` / `:browse` / `:instances` / `:m` / `:set prompt` / multi-line `:{ :}` / `:main` / `:def` / TH-splice-from-REPL / static-pointers / `:doc` / record-wildcards / type families. Reusable harness in [`scripts/run-ghci-subset.sh`](docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/run-ghci-subset.sh). |",
  "new_string": "| GHCi REPL | \u2705 Working | [v0.14.0](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.0).  `ghc -e`, `ghc --interactive`, `:t`, `:load`, `let`/lambdas, `:{ :}` blocks, imports, `Data.Map.Strict` lookups \u2014 all running in-process on a real PowerMac G5 under Mac OS X 10.4.  No new patches; the load-bearing pieces (runtime Mach-O loader, BCO byte-swap, `__eprintf` stub) have been in place since v0.8.0; v0.13.0's `STUArray Bool` fix unblocked the last gating dep.  Build change: `scripts/deploy-stage2.sh` compiles `ghc/Main.hs` with `-DHAVE_INTERNAL_INTERPRETER` + `-i$GHC_SRC/ghc -package exceptions -package time` (the cabal `internal-interpreter` flag's effective contents).  **Testsuite verification ([session 56](docs/sessions/2026-05-15-session-56-ghci-testsuite/)):** 51/51 PASS on a curated subset of upstream's `testsuite/tests/ghci/scripts/` \u2014 every `normal`/`combined_output` script test that doesn't need extra harness (reqlib, req_th, etc.).  Covers `:type` / `:info` / `:load` / `:reload` / `:browse` / `:instances` / `:m` / `:set prompt` / multi-line `:{ :}` / `:main` / `:def` / TH-splice-from-REPL / static-pointers / `:doc` / record-wildcards / type families. Reusable harness in [`scripts/run-ghci-subset.sh`](docs/sessions/2026-05-15-session-56-ghci-testsuite/scripts/run-ghci-subset.sh).  **Extended verification ([session 58](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/)):** 161/163 PASS on the bug-numbered `T<NUM>.script` subset of the same dir (every `normal` / `combined_output` / `extra_files` test that doesn't need special harness).  Covers six TemplateHaskell-from-REPL regressions (T4127, T4127a, T5566, T8831, T10466, T11098), the `:reload` / `:load` / module-dependency family, type families + kind polymorphism, `StaticPtr`, type-applications, GADTs, and a long tail of `T<NNN>` issue-tracker regressions.  The two remaining failures (T8042, T17549) are HFS+ mtime-granularity races in the upstream scripts themselves \u2014 not PPC bugs.  Session 58 also surfaced and patched-in-place a real **packaging bug** in the v0.14.0 bindist: `lib/bin/powerpc-apple-darwin8-unlit` was a host (arm64) binary, not PPC; Hadrian's cross-build host-copy carve-out in [patch 0010](patches/0010-hadrian-cross-iserv.patch) only excluded `iserv` but should also have excluded `unlit`.  Pending a v0.14.1 release with the corrected Hadrian patch + rebuilt bindist; in the meantime [`scripts/build-unlit-ppc.sh`](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/build-unlit-ppc.sh) cross-builds a real PPC unlit. |"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n \"Known issues\\|Latest release\" /Users/cell/claude/ghc-darwin8-ppc/README.md | head -5",
  "description": "Check for known-issues section"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -10 /Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "description": "Inspect state.md head"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "# state.md \u2014 where are we right now\n\n*Updated: 2026-05-16 session 57 (**GHCi debugger passes 83/83 of a curated subset of upstream's testsuite/tests/ghci.debugger/scripts/**).",
  "new_string": "# state.md \u2014 where are we right now\n\n*Updated: 2026-05-17 session 58 (**GHCi REPL passes 161/163 of a curated subset of upstream's tests/ghci/scripts/ T<NUM>.script regressions, AND surfaced + repaired-in-place a packaging bug in the v0.14.0 bindist**).  Extended sessions 56's `ghciNNN` and 57's `ghci.debugger` runs by parsing the same `tests/ghci/scripts/all.T` for T-prefix script tests with `normal` / `combined_output` / plain `extra_files` annotations (skipping `extra_hc_opts` / `extra_run_opts` / `reqlib` / `req_th` (none in scripts/) / `expect_broken` / `pre_cmd` / `makefile_test` / cross-dir extras).  163 candidates emerged; runner = identical to session 56's modulo TESTS list.  Run 1: **161/163** \u2014 two failures.  T10989 (literate Haskell `:l dummy.lhs`) failed with `cannot execute binary file` from `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit`; `file` revealed the helper is **Mach-O 64-bit arm64**, not ppc.  Root cause: Hadrian's `Rules/Program.hs` cross-mode copies stage0 (host) helpers into stage1 for every package except `iserv` (patch 0010's carve-out); `unlit` got the host binary verbatim with a ppc filename prefix.  Cross-built a real ppc `unlit` via the two-step compile-then-link pattern through `$CROSS_CC` (compile-only goes to clang; pure-link goes to `ppc-ld-tiger`), 14-KB Mach-O ppc, installed on pmacg5 at `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` with the arm64 binary preserved as `*.arm64.broken`.  Run 2 (after unlit fix): 161/163 \u2014 T10989 \u2705, T8042 newly FAIL, T17549 still FAIL.  Run 3: same as run 2 (T8042 confirmed flaky, not run-1's PASS).  Both remaining failures are HFS+ 1-second mtime granularity races in the upstream test scripts \u2014 `writeFile X \u2192 :load X \u2192 writeFile X \u2192 :reload` skips the reload when both writeFiles land in the same second, so the parse error / recompile-with-`-fobject-code` event the test expects never fires.  T1914 has the same shape but explicitly bumps mtimes with `:! touch -t 01010001`; T8042 / T17549 were authored later and forgot to.  Reproduced manually on pmacg5 with explicit `touch` \u2014 adds the expected stderr and stdout lines.  Surface covered by the 161 passes: 6 TH-from-REPL regressions (T4127, T4127a, T5566, T8831, T10466, T11098 \u2014 session-57-HANDOFF priority #1's actual concern), `:reload`/`:load` family, type families + kind polymorphism, `StaticPtr`, type applications, GADTs, regression `T<NNN>`s.  **STATE NEARLY CLEAN** \u2014 no GHC source changes, no new patches in `patches/`, no release tag.  pmacg5's `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` is replaced in-place (was arm64, now ppc); `*.arm64.broken` backup kept alongside.  Reusable harness in `docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/{run-ghci-tnum.sh,build-unlit-ppc.sh}`; `scripts/powerpc-apple-darwin8-unlit.ppc` is the binary that's now live on pmacg5.  v0.14.1 release path scoped in session 58 HANDOFF: extend patch 0010 to also exclude `unlit` from cross-mode host-copy, rebuild stage1 + stage2 + re-roll the bindist.*\n\n_(Prior summary, session 57:)_ **GHCi debugger passes 83/83 of a curated subset of upstream's testsuite/tests/ghci.debugger/scripts/**."
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "offset": 1,
  "limit": 5
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "*Updated: 2026-05-16 session 57 (**GHCi debugger passes 83/83 of a curated subset of upstream's testsuite/tests/ghci.debugger/scripts/**).  Verification-only session: no GHC source changes, no new patches, no release.  Picked every `normal` / `combined_output` / plain `extra_files` test that doesn't need special harness (no `reqlib` / `req_th` / `expect_broken` applicable to ppc32 / `extra_hc_opts` / `extra_run_opts`), ran them against the v0.14.0 stage2 ghc on pmacg5, normalised expected + actual through session 56's normaliser (now extended with two more upstream `testlib.py` rules \u2014 `...plus N instances` count erasure and `ghc-bignum-<VERSION>` masking).  First run: **79/83**.  Two failure shapes, both harness-side: (a) print019/break006 stderr off-by-one in the \"...plus N instances involving out-of-scope types\" footer \u2014 base-version drift, matched by upstream `testlib.py:2261`; (b) T2950/T3000 companion files named `<test><CapitalSuffix>.hs` (T2950M.hs, T3000S.hs) not auto-discovered, listed explicitly.  Run 2: **83/83 PASS** (~7 min CPU on pmacg5).  Surface covered: `:break NAME` / `:break NUM` / `:break MOD.NAME` / `:step` / `:steplocal` / `:stepmodule` / `:trace` / `:hist` / `:back` / `:forward` / `:print` / `:sprint` / `:force` / `:list` / `:show breaks` / `:show context` / `:show bindings` / dynamic break enable/disable/delete / `_result` rebinding / polymorphic types in breakpoint / unboxed tuples in `:print` / GADTs in `:print` / function types in `:print` / 15 bug-numbered `T<NNN>` regressions including `T13825-debugger` (`expect_broken(14455)` for ppc64 \u2014 passes here on ppc32).  This was the session-56-HANDOFF-predicted \"most likely place for an actual PPC bug\" target \u2014 zero PPC bugs surfaced.  Reusable harness in `docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/scripts/run-ghci-debugger.sh`.  **STATE CLEAN** \u2014 no GHC source changes, baseline tests unchanged (cross-compile path untouched), stage2 unchanged.*\n\n_(Prior summary, session 56:)_",
  "new_string": "*Updated: 2026-05-17 session 58 (**GHCi REPL passes 161/163 on the T-prefix subset of upstream's tests/ghci/scripts/ AND a packaging bug in v0.14.0 was repaired in-place on pmacg5**).  Extended sessions 56 + 57 by parsing the same `tests/ghci/scripts/all.T` for `T<NUM>.script` (and assorted capitalised: `GhciKinds`, `GhciCurDir`, `StaticPtr`, `TypeAppData`, `T19667Ghci`) regression tests with annotations in `{normal, combined_output, extra_files(...)}` \u2014 skipping `extra_hc_opts` / `extra_run_opts` / `reqlib` / `req_th` (which doesn't actually appear in scripts/all.T \u2014 session 57 HANDOFF's premise was stale) / `expect_broken` / `pre_cmd` / `makefile_test` / cross-dir extras.  163 candidates emerged.  Reusable runner = identical pipeline to session 56 modulo TESTS list; normaliser symlinked from session 56's, no new rules.  Run 1: **161/163**.  Two failures: T10989 (literate Haskell `:l dummy.lhs`) and T17549 (writeFile + :reload).  T10989's stderr surfaced `cannot execute binary file` from `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit`; `file` revealed the helper is **Mach-O 64-bit arm64**, not ppc \u2014 the host binary, copied verbatim into the bindist with a `powerpc-apple-darwin8-` filename prefix.  Root cause in `hadrian/src/Rules/Program.hs` lines 100\u2013114: cross-mode copies stage0 (host) helpers to stage1 for every package except `iserv` (patch 0010's carve-out), and `unlit` was missed.  Cross-built a real ppc `unlit` via the two-step compile-then-link pattern through `$CROSS_CC` (compile-only routes to clang; pure-link with `.o` args routes to `ppc-ld-tiger`; compile+link from `.c` routes to `ppc-ld-fake` which produces a 16-byte stub, hence the two-step recipe).  14-KB Mach-O ppc binary, installed on pmacg5 at the canonical path with the arm64 binary preserved as `*.arm64.broken`.  Run 2 (after unlit fix): T10989 \u2705, T8042 newly FAIL, T17549 still FAIL.  Run 3 (sanity): same as run 2.  Both remaining failures are HFS+ 1-second mtime granularity races in the upstream test scripts \u2014 `writeFile X \u2192 :load X \u2192 writeFile X \u2192 :reload` skips the reload when both writeFiles land in the same second.  T1914 has the same shape but explicitly bumps mtimes with `:! touch -t 01010001`; T8042 / T17549 were authored later and omitted the touch.  Reproduced manually with explicit `touch X.hs` between writeFile and :reload \u2014 the parse error / recompile event fires as expected.  Not a PPC bug; harness-side / upstream test-design.  Surface covered by the 161 passes: 6 TH-from-REPL regressions (T4127, T4127a, T5566, T8831, T10466, T11098 \u2014 session-57-HANDOFF priority #1's actual concern), `:reload`/`:load`/module-dependency family (T1914, T8696, T10110, T10322, T16030, T16527), type families + kind polymorphism (T5417, T6018ghci/fail/rnfail, T8469, T13202, T13202a, T13407, T15259, T15341, T15568, T17345), `StaticPtr` (the static-pointer table walk via REPL \u2014 `staticPtrKeys`, `unsafeLookupStaticPtr`, `deRefStaticPtr` all work), type applications (TypeAppData, T13202, T13420), GADTs + pattern synonyms (T11098, T11376, T11728, T13988), a long tail of `T<NNN>` issue-tracker regressions including T20974, T7388, T19279, T19310.  **STATE NEARLY CLEAN** \u2014 no GHC source changes, no new patches in `patches/`, no release tag.  pmacg5's `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` is replaced in-place (was arm64, now ppc, 14 KB); `*.arm64.broken` backup kept alongside.  Reusable harness in `docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/{run-ghci-tnum.sh,build-unlit-ppc.sh}`; `scripts/powerpc-apple-darwin8-unlit.ppc` is byte-identical to what's now live on pmacg5.  v0.14.1 release path scoped in session 58 HANDOFF: change patch 0010's `package /= iserv` to ``package `notElem` [iserv, unlit]``, rebuild stage1 + stage2 + re-roll the bindist.*\n\n_(Prior summary, session 57:)_ **GHCi debugger passes 83/83 of a curated subset of upstream's testsuite/tests/ghci.debugger/scripts/**.  Verification-only session: no GHC source changes, no new patches, no release.  Picked every `normal` / `combined_output` / plain `extra_files` test that doesn't need special harness (no `reqlib` / `req_th` / `expect_broken` applicable to ppc32 / `extra_hc_opts` / `extra_run_opts`), ran them against the v0.14.0 stage2 ghc on pmacg5, normalised expected + actual through session 56's normaliser (now extended with two more upstream `testlib.py` rules \u2014 `...plus N instances` count erasure and `ghc-bignum-<VERSION>` masking).  First run: **79/83**.  Two failure shapes, both harness-side: (a) print019/break006 stderr off-by-one in the \"...plus N instances involving out-of-scope types\" footer \u2014 base-version drift, matched by upstream `testlib.py:2261`; (b) T2950/T3000 companion files named `<test><CapitalSuffix>.hs` (T2950M.hs, T3000S.hs) not auto-discovered, listed explicitly.  Run 2: **83/83 PASS** (~7 min CPU on pmacg5).  Surface covered: `:break NAME` / `:break NUM` / `:break MOD.NAME` / `:step` / `:steplocal` / `:stepmodule` / `:trace` / `:hist` / `:back` / `:forward` / `:print` / `:sprint` / `:force` / `:list` / `:show breaks` / `:show context` / `:show bindings` / dynamic break enable/disable/delete / `_result` rebinding / polymorphic types in breakpoint / unboxed tuples in `:print` / GADTs in `:print` / function types in `:print` / 15 bug-numbered `T<NNN>` regressions including `T13825-debugger` (`expect_broken(14455)` for ppc64 \u2014 passes here on ppc32).  This was the session-56-HANDOFF-predicted \"most likely place for an actual PPC bug\" target \u2014 zero PPC bugs surfaced.  Reusable harness in `docs/sessions/2026-05-16-session-57-ghci-debugger-testsuite/scripts/run-ghci-debugger.sh`.  **STATE CLEAN** \u2014 no GHC source changes, baseline tests unchanged (cross-compile path untouched), stage2 unchanged.*\n\n_(Prior summary, session 56:)_"
}


---

## 🤖 Claude

Now roadmap.md — let me find the right spot.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n \"session 5[678]\\|## C\\|GHCi\\|161/163\\|83/83\\|51/51\" /Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md | head -20",
  "description": "Inspect roadmap.md sections"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "offset": 155,
  "limit": 35
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "old_string": "Last reviewed: 2026-05-16 session 57.",
  "new_string": "Last reviewed: 2026-05-17 session 58."
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "old_string": "No new patches, no source changes, no release.\nSee [session 57](sessions/2026-05-16-session-57-ghci-debugger-testsuite/).\n\n### ~~B. Stage2 native `ghc`~~ \u2705 done (v0.13.0)",
  "new_string": "No new patches, no source changes, no release.\nSee [session 57](sessions/2026-05-16-session-57-ghci-debugger-testsuite/).\n\n\u2705 **Session 58 (verification + packaging fix):** 161/163 PASS on\nthe **T-prefix subset** of upstream's `testsuite/tests/ghci/scripts/`\n\u2014 every `T<NUM>.script` / `GhciKinds` / `StaticPtr` / `TypeAppData` /\n`GhciCurDir` / `T19667Ghci` test with annotation in\n`{normal, combined_output, extra_files(...)}` that doesn't need\nspecial harness.  Run 1's first failure surfaced a real packaging\nbug in the v0.14.0 bindist: `/opt/ghc-stage2/lib/bin/powerpc-apple-\ndarwin8-unlit` is the *host* (arm64) binary, copied verbatim by\nHadrian's cross-build path; patch 0010's\n``case (cross, stage) of (True, s) | s > Stage0 && package /= iserv``\ncarve-out should also exclude `unlit`.  Cross-built a real ppc\n`unlit` from the GHC source tree via two-step compile-then-link\nthrough `$CROSS_CC`, deployed to pmacg5; T10989 then passes.  The\ntwo remaining failures (T8042, T17549) are HFS+ 1-second mtime\ngranularity races in the upstream scripts \u2014 `writeFile X \u2192 :load X\n\u2192 writeFile X \u2192 :reload` skips the reload when both writeFiles land\nin the same second; T1914 has the same shape but explicitly bumps\nmtimes with `:! touch -t`, T8042 / T17549 omit it.  Not PPC bugs.\nReusable runner + `build-unlit-ppc.sh` + built artifact in\n[`docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/`](sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/).\n**No GHC source changes, no new patches landed, no release tag.**\nThe Hadrian patch update + stage1-rebuild + new bindist + v0.14.1\nrelease is scoped in session 58's HANDOFF priority #1.\nNotable PASSes: 6 TH-from-REPL regressions (T4127, T4127a, T5566,\nT8831, T10466, T11098 \u2014 session-57-HANDOFF priority #1's actual\nconcern), `StaticPtr` (static-pointer table walk via REPL).\nSee [session 58](sessions/2026-05-17-session-58-ghci-tnum-scripts/).\n\n### ~~B. Stage2 native `ghc`~~ \u2705 done (v0.13.0)"
}


---

## 🤖 Claude

Now the HANDOFF.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/HANDOFF.md",
  "content": "# Handoff from session 58 \u2192 session 59\n\n**For:** the next claude session.\n**From:** session 58 \u2014 extended verification milestone + packaging\nbug repair.  161/163 PASS on the curated T-prefix subset of\nupstream's `testsuite/tests/ghci/scripts/all.T`.  Real packaging\nbug surfaced (Hadrian copies the host's `unlit` binary into the\ncross-mode bindist with a `powerpc-apple-darwin8-` prefix);\nrepaired in-place on pmacg5 via a cross-built ppc `unlit`.\nNo new patches, no source changes, no release tag.\n\n**Recommended pickup:** **v0.14.1 release** \u2014 properly fix the\nunlit packaging bug in the Hadrian build, rebuild stage1 + stage2,\nre-roll the bindist, ship.  This is the highest-priority follow-up\nbecause it's a real bug in v0.14.0's binary, and we've already\ndone all the diagnosis + prototyped the fix.\n\n## \u2705 SESSION EXIT STATE\n\n* No GHC source-tree changes (no edits under `external/`,\n  `patches/`).\n* No new release tag.  v0.14.0 still the latest.\n* Stage2 ghc-real on pmacg5 unchanged (still the v0.14.0 binary,\n  ~199 MB).\n* `/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit` REPLACED\n  on pmacg5 with the session-58-cross-built ppc binary (14 KB).\n  Original arm64 helper preserved as\n  `powerpc-apple-darwin8-unlit.arm64.broken` for forensics.\n* New `docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/`\n  dir with the run harness + unlit cross-build script + the\n  built ppc binary + per-test logs.\n* README + state.md + roadmap.md updated.\n\n## TL;DR \u2014 what session 58 found\n\n1. **The v0.14.0 REPL passes the T-prefix subset of ghci script\n   tests, including all six TH-from-REPL regressions.**\n   `T4127`, `T4127a`, `T5566`, `T8831`, `T10466`, `T11098` \u2014 every\n   TemplateHaskell-driven-through-the-REPL regression in\n   upstream's testsuite \u2014 PASS on PPC/Tiger.  This was the\n   *actual* concern behind session 57 HANDOFF's priority #1\n   (which talked about `req_th` annotations that don't exist in\n   the ghci/scripts subdir).\n\n2. **The v0.14.0 bindist ships an arm64 `unlit` helper.**\n   Hadrian's `Rules/Program.hs` cross-mode copies stage0 (host)\n   binaries to stage1 for every package except `iserv`\n   (patch 0010 carved iserv out but missed `unlit`).  The\n   resulting binary at `/opt/ghc-stage2/lib/bin/powerpc-apple-\n   darwin8-unlit` is the build-host's arm64 unlit with a ppc\n   filename prefix \u2014 it can't execute on Tiger.  Literate\n   Haskell support (`.lhs` files, the `:l foo.lhs` path in\n   GHCi) is broken in v0.14.0.  This has been latent since\n   v0.7.0 (when patch 0010 landed).\n\n3. **T17549 and T8042 fail due to HFS+'s 1-second mtime\n   granularity.**  Both are `writeFile X \u2192 :load X \u2192 writeFile X\n   \u2192 :reload` patterns where the second writeFile lands in the\n   same second as the initial :load, so :reload skips.  T1914\n   has the same shape but explicitly bumps mtimes with `:! touch\n   -t` \u2014 T8042 / T17549 omit it.  Not PPC bugs; upstream\n   test-design issues.\n\n## What to try next, in priority order\n\n### Top: v0.14.1 release \u2014 bindist re-roll with corrected unlit\n\nThe work is small but ritualistic.  Specifically:\n\n1. **Patch 0010 update.**  Change the cross-mode arm of\n   `hadrian/src/Rules/Program.hs:108` from\n   ```haskell\n   (True, s) | s > Stage0 && package /= iserv -> ...\n   ```\n   to\n   ```haskell\n   (True, s) | s > Stage0 && package `notElem` [iserv, unlit] -> ...\n   ```\n   (`unlit` is imported in the existing pattern below \u2014 no new\n   imports needed).  Either edit patch 0010 in place to reflect\n   this, or add a new patch 0017 if we want a clean lineage.\n   Patches in this project are typically rebased rather than\n   stacked, so edit-in-place is fine.\n\n2. **Stage1 rebuild.**  `hadrian -j build` against the corrected\n   patch.  ~16 minutes on uranium.\n\n3. **Stage2 re-cross-build.**  `scripts/deploy-stage2.sh` \u2014\n   re-cross-compiles the stage2 ghc-real with the corrected\n   stage1, packages, and deploys.  Verify the unlit in the new\n   bindist is `Mach-O executable ppc`.\n\n4. **Bindist tarball + install verification.**  Re-roll\n   `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`, run\n   `install.sh` on a clean Tiger box, verify\n   `cat /opt/ghc-darwin8/lib/bin/powerpc-apple-darwin8-unlit | file`\n   says ppc.\n\n5. **Demo + README + release tag.**  Per project workflow\n   (`CLAUDE.md` \u2192 \"Release workflow\"):\n   - Demo: `demos/v0.14.1-literate-haskell.{hs,sh}` \u2014 write a\n     short program that round-trips through `unlit`\n     (e.g. compile a `.lhs` with the bird-track style, run on\n     Tiger, observe expected output).  The point is to show\n     v0.14.1 unblocks something v0.14.0 couldn't.\n   - README: bump \"Latest release\" to v0.14.1, add a Releases\n     row.\n   - Tag: `git tag v0.14.1` with release notes mentioning\n     T10989 + the Hadrian patch fix.\n\n6. **Re-run session 58's runner** to confirm 162/163 (T10989 \u2705\n   without the manual unlit deploy; T8042 + T17549 still\n   harness-side flakes).\n\n### Second: skip T8042 / T17549 from the runner (cosmetic)\n\nIf we want a clean \"X / X PASS\" headline in future runs, exclude\nT8042 and T17549 from the TESTS list in\n`scripts/run-ghci-tnum.sh` with a comment pointing to\n[findings.md \u00a73](findings.md).  Session 58 chose honesty over\nclean numbers; that's a defensible reversal.\n\n### Third: extend the runner to handle more tests/ghci/scripts/ annotations\n\nUntouched groups, in order of likely-value:\n\n- `extra_run_opts` tests (T9878b, T12091, T17500, T17669) \u2014 thread\n  RTS flags through.  ~4 more tests.\n- `extra_hc_opts` tests (T2452, T2182ghci2, T9293, T13385, T14342,\n  T16563) \u2014 thread compiler flags through.  ~6 more tests.\n- `reqlib` tests (T5979 \u2014 needs `transformers`).  ~1 more test.\n- `pre_cmd` tests (T5975a/b, T6106, T19650) \u2014 needs a Makefile or\n  shell prelude.  ~4 more tests.\n- `req_interp` / `makefile_test` family \u2014 different harness shape;\n  not script-driven.\n\nIf all of these were unlocked, we'd cover ~175-180 of the ~209\nghci scripts.  The rest are makefile-driven (`req_interp`) or\ngenuinely broken upstream (`expect_broken`).\n\n### Fourth: bug-numbered T<num>/ subdirs (session 57 HANDOFF\npriority #2)\n\n`external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/T11827/`,\n`T13786/`, `T16670/`, `T18060/`, `T18071/`, `T18262/`, etc.  Each\nhas its own Makefile driving a small scenario.  Less uniform\nthan `scripts/`; each one may need bespoke setup.  Cherry-pick\nthe ones whose Makefiles are short.\n\n### Fifth: prog001..prog019 multi-module `:load` tests\n\n(Session 57 HANDOFF priority #3.)  Multi-module `:load` exercise.\nEach is a directory with several `.hs` files and a `.script`.\nTests `:load`'s multi-module dependency tracking + reload\ninvalidation.  Probably all pass, but worth running.\n\n### Sixth: GHCi over a real ssh tty\n\n(Session 57 HANDOFF priority #4.)  All script-based runs use\npiped stdin.  A real `ssh pmacg5` + `/opt/ghc-stage2/bin/ghc-real\n--interactive` exercises haskeline's terminal handling on Tiger.\nShould \"just work\" \u2014 haskeline is statically baked in \u2014 but\nhasn't been verified.  Low effort: ssh in, try arrow keys,\nhistory, ctrl-r, multi-line editing, tab completion.\n\n### Seventh: extend the debugger runner to handle extra_run_opts /\nsubdir extras (session 57 HANDOFF #5, #6)\n\nTrivial.  Unlocks hist001, hist002, T1620.\n\n### Eighth: stage2 native-compile sweep (carry-forward from S54)\n\nCabal-examples sweep, but native (ssh in, compile + run on\npmacg5) rather than cross-compile.  Modest interest.\n\n### Ninth: refactor patch 0016 to upstream's smaller form\n\nStill on the list from session 54.  Cosmetic.  Needs a stage1\nrebuild + stage2 redeploy to validate \u2014 which v0.14.1's bindist\nre-roll would naturally do anyway, so consider rolling into the\nsame session.\n\n### Tenth: audit third-party libs for the setByteArray# /\nreadWordArray# granularity-mismatch\n\nStill on the list from session 53/54.  Upstream contribution.\n\n## What NOT to redo\n\n* **Don't re-run session 56 / 57 / 58 test subsets** unless the\n  stage2 binary changes.  v0.14.1's bindist re-roll WILL change\n  it, so DO re-run all three to confirm the new bindist passes\n  everything plus T10989.\n* **Don't manually re-deploy the unlit fix** on pmacg5 \u2014 it's\n  already there in-place.  If you wipe `/opt/ghc-stage2`, you'd\n  need to reinstall v0.14.0 and then redo the manual fix (or\n  install v0.14.1 once that ships).\n* **Don't reimplement the runner** \u2014 `run-ghci-tnum.sh` works.\n  Extending its TESTS list and adding flags-pass-through is\n  cheaper than rewriting.\n* **Don't believe HANDOFF text that says `req_th` annotations\n  exist in `tests/ghci/scripts/all.T`** \u2014 they don't.  Session 57\n  HANDOFF's priority #1 was based on that stale claim.  The real\n  TH-from-REPL coverage came from running T4127 etc., not from\n  any `req_th` filter.\n\n## Hosts (unchanged from session 56/57)\n\n* **uranium**: source edits, harness scripts, sweeps from here;\n  cross-build of unlit happened here too (using existing cross-cc).\n* **pmacg5**: runs the ppc stage2 ghc binary.\n  `/opt/ghc-stage2/bin/ghc-real` is the v0.14.0 GHCi-enabled\n  binary (~199 MB).  `/opt/ghc-stage2/lib/bin/powerpc-apple-\n  darwin8-unlit` is now the session-58-cross-built 14-KB ppc\n  binary; the original arm64 is preserved alongside.\n* **indium**: medium-tolerance VM, not used this session.\n\n## Paste-into-fresh-session prompt\n\n```\nContext: session 58 of the ghc-darwin8-ppc project added a third\nverification milestone for the v0.14.0 GHCi REPL \u2014 161/163 PASS\non a curated subset of upstream's testsuite/tests/ghci/scripts/\nT<NUM>.script regressions (every test with `normal` /\n`combined_output` / `extra_files(...)` annotation that doesn't\nneed special harness).  Surface: 6 TH-from-REPL regressions\n(T4127, T4127a, T5566, T8831, T10466, T11098), the\n:reload/:load/module-dependency family, type families + kind\npolymorphism, StaticPtr, type apps, GADTs.  The two remaining\nfailures (T8042, T17549) are HFS+ 1s mtime races in the upstream\ntest scripts (not PPC bugs).  Reusable runner at\ndocs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/.\n\nAlso: surfaced and repaired-in-place a packaging bug \u2014 the v0.14.0\nbindist ships an arm64 `unlit` helper at\n/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit.  Hadrian's\ncross-mode host-copy in Rules/Program.hs only excluded `iserv`\n(patch 0010) and missed `unlit`.  Cross-built a real ppc unlit\nvia a two-step compile-then-link recipe through $CROSS_CC,\ndeployed to pmacg5 in-place (original kept as\npowerpc-apple-darwin8-unlit.arm64.broken).  T10989 now PASSes.\n\nNo new patches, no source changes, no release.  v0.14.0\nunchanged; pmacg5's /opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-\nunlit is the only thing modified.\n\nTop next move: v0.14.1 release.  Change patch 0010's\n``case (cross, stage) of (True, s) | s > Stage0 && package /= iserv``\nto ``package `notElem` [iserv, unlit]``, rebuild stage1, re-cross-\ncompile stage2, re-roll bindist, demo + release tag.  See\nsession 58 HANDOFF for the full priority list.\n\nRead in order:\n1. docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/HANDOFF.md\n2. docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/README.md\n3. docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/findings.md\n4. docs/roadmap.md (priorities)\n\nHosts: uranium for source edits + cross-builds; pmacg5 for runs.\nThe unlit fix on pmacg5 is in-place; if /opt/ghc-stage2 is wiped,\nreinstall v0.14.0 then re-deploy the patched unlit from\ndocs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/\npowerpc-apple-darwin8-unlit.ppc \u2014 or, better, ship v0.14.1 first.\n\nUnsupervised mode is project default.\n```\n\n## Memory aide\n\nWhen session 59 ends, write the next handoff at:\n`docs/sessions/<DATE>-session-59-<slug>/HANDOFF.md`.\n"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Verify baseline (skip \u2014 stage2 unchanged from session 57)",
      "status": "completed",
      "activeForm": "Skipping baseline (stage2 unchanged)"
    },
    {
      "content": "Set up session 58 dir + scaffolding",
      "status": "completed",
      "activeForm": "Setting up session 58 dir"
    },
    {
      "content": "Parse all.T for T-prefix .script tests with normal/combined_output",
      "status": "completed",
      "activeForm": "Parsing all.T for T-prefix tests"
    },
    {
      "content": "Write run-ghci-tnum.sh runner",
      "status": "completed",
      "activeForm": "Writing T-num runner"
    },
    {
      "content": "Run 1 on pmacg5: 161/163 PASS (T10989 & T17549 fail)",
      "status": "completed",
      "activeForm": "Run 1 complete"
    },
    {
      "content": "Diagnose T10989: unlit binary on /opt is arm64 (packaging bug)",
      "status": "completed",
      "activeForm": "Diagnosed unlit packaging bug"
    },
    {
      "content": "Cross-compile + deploy fixed ppc unlit",
      "status": "completed",
      "activeForm": "Deployed fixed unlit"
    },
    {
      "content": "Run 2: T10989 fixed, T8042 newly flaking, T17549 still fail",
      "status": "completed",
      "activeForm": "Run 2 complete"
    },
    {
      "content": "Run 3: confirm T8042+T17549 are HFS+ mtime-granularity flakes",
      "status": "completed",
      "activeForm": "Run 3 done; flake confirmed"
    },
    {
      "content": "Write README.md",
      "status": "completed",
      "activeForm": "Wrote README"
    },
    {
      "content": "Write findings.md, commits.md, HANDOFF.md",
      "status": "completed",
      "activeForm": "Wrote findings/commits/handoff"
    },
    {
      "content": "Update top-level README + state.md + roadmap.md",
      "status": "completed",
      "activeForm": "Updated top-level docs"
    },
    {
      "content": "Save the cross-built unlit + a build script under scripts/",
      "status": "completed",
      "activeForm": "Saved unlit fix artifacts"
    },
    {
      "content": "Commit session work",
      "status": "in_progress",
      "activeForm": "Committing session"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git status",
  "description": "Check git status"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log --oneline -5",
  "description": "Recent commit style"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git diff --stat README.md docs/state.md docs/roadmap.md",
  "description": "Diff stat of my doc changes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add README.md docs/state.md docs/roadmap.md docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/\ngit status",
  "description": "Stage session 58 files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git status -s 2>&1 | wc -l; git status -s 2>&1 | grep \"^[?M]\" | head -10",
  "description": "Confirm only session 58 staged"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git status -s | grep \"^[?]\" | head -3; echo \"---\"; git diff --cached --stat docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/",
  "description": "Verify untracked files left out"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git commit -m \"$(cat <<'EOF'\nSession 58: 161/163 PASS on curated T<num> GHCi script subset; unlit packaging bug repaired in-place on pmacg5.\n\nExtended sessions 56 (ghciNNN scripts) and 57 (ghci.debugger\nscripts) by parsing tests/ghci/scripts/all.T for the T-prefix\nscript regression tests with normal / combined_output /\nextra_files(...) annotations.  163 candidates emerged.  Surface\ncovered: 6 TH-from-REPL regressions (T4127, T4127a, T5566,\nT8831, T10466, T11098 \u2014 session-57-HANDOFF priority #1's actual\nconcern; the `req_th` filter premise turned out stale, those\nannotations don't exist in scripts/all.T), the :reload/:load\nfamily, type families + kind polymorphism, StaticPtr, type\napplications, GADTs, and a long tail of T<NNN> issue-tracker\nregressions.\n\nRun 1 surfaced a real **packaging bug** in v0.14.0:\n/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit is the host\n(arm64) binary, copied verbatim by Hadrian into the bindist with\na powerpc-apple-darwin8- filename prefix.  Root cause:\nhadrian/src/Rules/Program.hs cross-mode copies stage0 helpers to\nstage1 for every package except `iserv` (patch 0010's carve-out\nmissed `unlit`).  Cross-built a real ppc unlit via two-step\ncompile-then-link through $CROSS_CC, installed on pmacg5\nin-place; original kept as *.arm64.broken.\n\nAfter the unlit fix: 161/163, with T8042 + T17549 the remaining\nfailures.  Both are HFS+ 1-second mtime granularity races in the\nupstream scripts themselves \u2014 writeFile X \u2192 :load X \u2192 writeFile X\n\u2192 :reload skips the reload when both writeFiles land in the same\nsecond; T1914 has the same shape but explicitly bumps mtimes\nwith :! touch -t, T8042 / T17549 omit it.  Not PPC bugs;\nupstream test-design.\n\nNo GHC source changes, no new patches landed, no release tag.\nv0.14.1 release path (extend patch 0010, rebuild stage1+stage2,\nre-roll bindist) scoped in session 58 HANDOFF priority #1.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\"",
  "description": "Commit session 58"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/tmp/session-58-commit-msg.txt",
  "content": "Session 58: 161/163 PASS on curated T<num> GHCi script subset; unlit packaging bug repaired in-place on pmacg5.\n\nExtended sessions 56 (ghciNNN scripts) and 57 (ghci.debugger scripts)\nby parsing tests/ghci/scripts/all.T for the T-prefix script regression\ntests with normal / combined_output / extra_files(...) annotations.\n163 candidates emerged.  Surface covered: 6 TH-from-REPL regressions\n(T4127, T4127a, T5566, T8831, T10466, T11098 \u2014 session-57-HANDOFF\npriority #1 actual concern; the req_th filter premise turned out\nstale, those annotations don't exist in scripts/all.T), the\n:reload/:load family, type families + kind polymorphism, StaticPtr,\ntype applications, GADTs, and a long tail of T<NNN> issue-tracker\nregressions.\n\nRun 1 surfaced a real packaging bug in v0.14.0:\n/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit is the host\n(arm64) binary, copied verbatim by Hadrian into the bindist with a\npowerpc-apple-darwin8- filename prefix.  Root cause:\nhadrian/src/Rules/Program.hs cross-mode copies stage0 helpers to\nstage1 for every package except iserv (patch 0010 carve-out missed\nunlit).  Cross-built a real ppc unlit via two-step compile-then-link\nthrough $CROSS_CC, installed on pmacg5 in-place; original kept as\n*.arm64.broken.\n\nAfter the unlit fix: 161/163, with T8042 + T17549 the remaining\nfailures.  Both are HFS+ 1-second mtime granularity races in the\nupstream scripts themselves \u2014 writeFile X then :load X then writeFile\nX then :reload skips the reload when both writeFiles land in the same\nsecond; T1914 has the same shape but explicitly bumps mtimes with\n:! touch -t, T8042 / T17549 omit it.  Not PPC bugs; upstream\ntest-design.\n\nNo GHC source changes, no new patches landed, no release tag.\nv0.14.1 release path (extend patch 0010, rebuild stage1+stage2,\nre-roll bindist) scoped in session 58 HANDOFF priority #1.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git commit -F /tmp/session-58-commit-msg.txt",
  "description": "Commit session 58 from file"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log --oneline -3",
  "description": "Confirm commit landed"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SHA=12c662b\nsed -i.bak \"s|_SHA_|$SHA|\" /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md\nrm /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md.bak\ncat /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md",
  "description": "Backfill SHA in commits.md"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md",
  "old_string": "# Session 58 commits\n\nTo be backfilled with the actual commit SHA after `git commit`.\n\n- 12c662b: Session 58: 161/163 PASS on curated T<num> GHCi script subset; surface unlit packaging bug; deploy cross-built ppc unlit on pmacg5.",
  "new_string": "# Session 58 commits\n\n- [12c662b](../../../../../commit/12c662b): Session 58: 161/163 PASS on curated T<num> GHCi script subset; surface unlit packaging bug; deploy cross-built ppc unlit on pmacg5."
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md\ngit commit -m \"Session 58 commits.md: backfill the SHA.\"",
  "description": "Commit commits.md SHA backfill"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Verify baseline (skip \u2014 stage2 unchanged from session 57)",
      "status": "completed",
      "activeForm": "Skipping baseline (stage2 unchanged)"
    },
    {
      "content": "Set up session 58 dir + scaffolding",
      "status": "completed",
      "activeForm": "Setting up session 58 dir"
    },
    {
      "content": "Parse all.T for T-prefix .script tests with normal/combined_output",
      "status": "completed",
      "activeForm": "Parsing all.T for T-prefix tests"
    },
    {
      "content": "Write run-ghci-tnum.sh runner",
      "status": "completed",
      "activeForm": "Writing T-num runner"
    },
    {
      "content": "Run 1 on pmacg5: 161/163 PASS (T10989 & T17549 fail)",
      "status": "completed",
      "activeForm": "Run 1 complete"
    },
    {
      "content": "Diagnose T10989: unlit binary on /opt is arm64 (packaging bug)",
      "status": "completed",
      "activeForm": "Diagnosed unlit packaging bug"
    },
    {
      "content": "Cross-compile + deploy fixed ppc unlit",
      "status": "completed",
      "activeForm": "Deployed fixed unlit"
    },
    {
      "content": "Run 2: T10989 fixed, T8042 newly flaking, T17549 still fail",
      "status": "completed",
      "activeForm": "Run 2 complete"
    },
    {
      "content": "Run 3: confirm T8042+T17549 are HFS+ mtime-granularity flakes",
      "status": "completed",
      "activeForm": "Run 3 done; flake confirmed"
    },
    {
      "content": "Write README.md",
      "status": "completed",
      "activeForm": "Wrote README"
    },
    {
      "content": "Write findings.md, commits.md, HANDOFF.md",
      "status": "completed",
      "activeForm": "Wrote findings/commits/handoff"
    },
    {
      "content": "Update top-level README + state.md + roadmap.md",
      "status": "completed",
      "activeForm": "Updated top-level docs"
    },
    {
      "content": "Save the cross-built unlit + a build script under scripts/",
      "status": "completed",
      "activeForm": "Saved unlit fix artifacts"
    },
    {
      "content": "Commit session work + SHA backfill",
      "status": "completed",
      "activeForm": "Committed"
    }
  ]
}


---

## 🤖 Claude

Session 58 done. Net: **161/163 PASS** on the T-prefix subset of `tests/ghci/scripts/`, and a real packaging bug in the v0.14.0 bindist was uncovered and patched in-place on pmacg5.

Key outcomes:
- **6 TH-from-REPL regressions** (T4127, T4127a, T5566, T8831, T10466, T11098) all PASS — that was the actual spirit of session 57 HANDOFF's priority #1. (Its literal `req_th`-filter premise turned out stale — no `req_th` annotations exist in `tests/ghci/scripts/all.T`.)
- **Real packaging bug:** [/opt/ghc-stage2/lib/bin/powerpc-apple-darwin8-unlit](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/findings.md#2-the-unlit-packaging-bug) was the *host* (arm64) binary in v0.14.0. Hadrian's cross-mode in `hadrian/src/Rules/Program.hs` copies stage0 helpers for every package except `iserv`; [patch 0010](patches/0010-hadrian-cross-iserv.patch) missed `unlit`. Cross-built a real ppc unlit ([scripts/build-unlit-ppc.sh](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/scripts/build-unlit-ppc.sh)), deployed on pmacg5 (arm64 binary kept as `*.arm64.broken`). T10989 then passes.
- **T8042 + T17549**: HFS+ 1-second mtime granularity races in upstream scripts — `writeFile X → :load → writeFile X → :reload` skips when both writeFiles land in the same second. T1914 has the same shape but explicitly uses `:! touch -t`; T8042 / T17549 don't. Not PPC bugs.

Files of interest:
- [HANDOFF.md](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/HANDOFF.md) — priority #1 is the v0.14.1 release (extend patch 0010 to also exclude `unlit`, rebuild stage1+stage2, re-roll bindist).
- [README.md](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/README.md)
- [findings.md](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/findings.md)
- Commits [12c662b](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md) + [4e91cec](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md).

Next session's HANDOFF lives at: [docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/HANDOFF.md](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/HANDOFF.md).

---

## 👤 User

Continue session 58 work. Background task b4eic34pf runs the 163-test GHCi T-num subset on pmacg5; check its progress and if done, parse PASS/FAIL counts and decide next steps.

---

## 🤖 Claude

That scheduled wakeup was unnecessary — the task completed and the full session 58 workflow finished while we were still in the same turn. Recap:

- **Task `b4eic34pf`**: completed long ago, 161/163 PASS. The 2 failures were T10989 (unlit packaging bug, fixed in-place) and T17549 (HFS+ mtime race).
- **Two additional runs**: confirmed T10989 fixed and characterised T8042/T17549 as harness-side HFS+ flakes.
- **Session 58 written up + committed** as [12c662b](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md) and [4e91cec](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/commits.md).

Nothing left to do here — the session is closed. The next session's pickup doc is at [docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/HANDOFF.md](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/HANDOFF.md), priority #1 being the v0.14.1 bindist re-roll with the corrected Hadrian patch.

---

