# Claude Conversation Log

Session ID: 7ffe9ca6-c20e-44d7-ac10-3e8234ba33a0
Date: 2026-05-16 06:33:21

---

## 👤 User

read docs/sessions/2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md and proceed

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md"
}


---

## 🤖 Claude

I'll read the session's full context and the proposal before starting the v0.14.2 work.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-60-extra-run-opts-runner/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/proposals/rts-dso-handle-mach-o.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-60-extra-run-opts-runner/findings.md"
}


---

## 🤖 Claude

Now let me look at the existing patches structure and previous v0.14.1 release flow.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/patches/ | head -50",
  "description": "List existing patches"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/scripts/ | head -50",
  "description": "List scripts"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/ | tail -20",
  "description": "List recent sessions"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/",
  "description": "List files in v0.14.1 release session"
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
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/commits.md"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/scripts/deploy-stage2.sh"
}


---

## 🤖 Claude

I have the context. Now let me load TodoWrite and inspect the rts/Linker.c source to craft the patch.

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
  "command": "grep -n \"dso_handle\\|__dso_handle\\|Resolving __dso_handle\" /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/Linker.c | head -30",
  "description": "Find dso_handle references in Linker.c"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Read rts/Linker.c context around dso_handle and craft patch 0017",
      "activeForm": "Reading rts/Linker.c and crafting patch 0017",
      "status": "in_progress"
    },
    {
      "content": "Create session 61 directory and scaffolding",
      "activeForm": "Creating session 61 directory",
      "status": "pending"
    },
    {
      "content": "Apply source edit, rebuild stage1",
      "activeForm": "Applying source edit and rebuilding stage1",
      "status": "pending"
    },
    {
      "content": "Generate patches/0017-...patch from source diff",
      "activeForm": "Generating patches/0017 from source diff",
      "status": "pending"
    },
    {
      "content": "Run deploy-stage2.sh pmacg5 to redeploy stage2",
      "activeForm": "Running deploy-stage2.sh pmacg5",
      "status": "pending"
    },
    {
      "content": "Re-run session 60 runner \u2014 verify T9878b PASSes (165/166 target)",
      "activeForm": "Re-running session 60 runner",
      "status": "pending"
    },
    {
      "content": "Re-roll bindist tarball",
      "activeForm": "Rolling new bindist tarball",
      "status": "pending"
    },
    {
      "content": "Pick / write a static-pointer / -fobject-code demo for v0.14.2",
      "activeForm": "Writing v0.14.2 demo",
      "status": "pending"
    },
    {
      "content": "Update README, docs/state.md, docs/roadmap.md, demos/README.md",
      "activeForm": "Updating top-level docs",
      "status": "pending"
    },
    {
      "content": "Commit, tag v0.14.2, push, gh release create with bindist asset",
      "activeForm": "Committing, tagging, pushing, releasing v0.14.2",
      "status": "pending"
    },
    {
      "content": "Write session 61 README, findings, commits, HANDOFF",
      "activeForm": "Writing session 61 docs",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/Linker.c",
  "offset": 840,
  "limit": 100
}


---

## 🤖 Claude

Now let me check the patches directory structure and the layout under external/.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "head -20 patches/0010-hadrian-cross-iserv.patch",
  "description": "Inspect patch 0010 format"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git status 2>&1 | head -15",
  "description": "Check if ghc-9.2.8 tree is git-managed"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && head -5 patches/0015-rts-rtsutils-tiger-strnlen-shim.patch && echo \"---\" && head -5 patches/0016-array-stuarray-bool-word-aligned-init.patch",
  "description": "Inspect patch 0015/0016 format"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git status --short 2>&1 | head -40",
  "description": "Short git status"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git diff rts/Linker.c 2>&1 | head -20 && echo \"---ENDS---\" && cd /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8 && git log --oneline rts/Linker.c | head -5",
  "description": "Check Linker.c diff state"
}


---

## 🤖 Claude

Now let me set up the session 61 directory and apply the source change.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "mkdir -p /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/{logs,scripts} && ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/",
  "description": "Create session 61 directory"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -n \"OBJFORMAT_MACHO\\|OBJFORMAT_ELF\" rts/Linker.c | head -20",
  "description": "Survey object format guards in Linker.c"
}


---

## 🤖 Claude

Now applying the source edit to rts/Linker.c.

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/Linker.c",
  "old_string": "    /* See Note [Resolving __dso_handle] */\n    if (strcmp(lbl, \"__dso_handle\") == 0) {\n        if (dependent) {\n            return dependent->image;\n        } else {\n            // In the case that we don't know which object the reference lives\n            // in we return a random symbol from the executable image.\n            return &lookupDependentSymbol;\n        }\n    }",
  "new_string": "    /* See Note [Resolving __dso_handle] */\n    if (strcmp(lbl, \"__dso_handle\") == 0 ||\n        strcmp(lbl, \"___dso_handle\") == 0) { /* Mach-O underscore prefix */\n        if (dependent) {\n            return dependent->image;\n        } else {\n            // In the case that we don't know which object the reference lives\n            // in we return a random symbol from the executable image.\n            return &lookupDependentSymbol;\n        }\n    }"
}


---

## 🤖 Claude

Also extend the Note to document the Mach-O case.

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/rts/Linker.c",
  "old_string": "/* Note [Resolving __dso_handle]\n * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n * This symbol, which is defined by the C++ ABI, would typically be defined by\n * the system's dynamic linker to act as a \"handle\", identifying a particular\n * loaded dynamic object to the C++ standard library for the purpose of running\n * destructors on unload. Here we behave the same way that the dynamic linker\n * would, using some address (here the start address) of the loaded object as\n * its handle.\n *\n * Note that references to __dso_handle may be relocated using\n * relocations of bounded displacement and therefore __dso_handle must not be\n * too far from the loaded object's code (hence using its start address).\n *\n * See #20493.\n */",
  "new_string": "/* Note [Resolving __dso_handle]\n * ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n * This symbol, which is defined by the C++ ABI, would typically be defined by\n * the system's dynamic linker to act as a \"handle\", identifying a particular\n * loaded dynamic object to the C++ standard library for the purpose of running\n * destructors on unload. Here we behave the same way that the dynamic linker\n * would, using some address (here the start address) of the loaded object as\n * its handle.\n *\n * Note that references to __dso_handle may be relocated using\n * relocations of bounded displacement and therefore __dso_handle must not be\n * too far from the loaded object's code (hence using its start address).\n *\n * On Mach-O the symbol table preserves the leading underscore prefix\n * convention, so the symbol arrives at lookupDependentSymbol() as\n * \"___dso_handle\" (three underscores) rather than the ELF spelling\n * \"__dso_handle\" (two).  We match both forms above.\n *\n * See #20493.\n */"
}


---

## 🤖 Claude

Now generate the patch file and rebuild stage1.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git diff rts/Linker.c",
  "description": "Diff Linker.c"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "pwd",
  "description": "Print working directory"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git diff rts/Linker.c > /Users/cell/claude/ghc-darwin8-ppc/patches/0017-rts-dso-handle-mach-o-underscore.patch && head -20 /Users/cell/claude/ghc-darwin8-ppc/patches/0017-rts-dso-handle-mach-o-underscore.patch",
  "description": "Generate patch 0017"
}


---

## 🤖 Claude

Let me add a header to the patch file in the style of patch 0016.

---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/patches/0016-array-stuarray-bool-word-aligned-init.patch",
  "limit": 25
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/patches/0017-rts-dso-handle-mach-o-underscore.patch",
  "content": "From: ghc-darwin8-ppc project\nSubject: [PATCH] rts/Linker.c: match Mach-O underscore-prefixed ___dso_handle\n\nghc-darwin8-ppc: `rts/Linker.c::lookupDependentSymbol` has a special\ncase for `__dso_handle` (see `Note [Resolving __dso_handle]`, upstream\n#20493) that hands the dependent object's image address back as a\nsynthetic handle.  The strcmp was written for ELF, where the symbol\narrives with two leading underscores.\n\nMach-O preserves the platform's leading-underscore symbol-name prefix.\nOur PPC Mach-O loader populates `macho_symbols[i].name` directly from\nthe object's string table (`rts/linker/MachO.c:137-138`), so the\nsymbol arrives at `lookupDependentSymbol` as `\"___dso_handle\"` (three\nunderscores).  The strcmp misses, the special case never fires, and\nresolution falls through to `dlsym(lbl + 1)`.  On Tiger this also\nfails \u2014 `___dso_handle` is provided at link time by `dylib1.o`/`crt1.o`\nand is not exported into the runtime dyld namespace.  The .o load\ntherefore aborts with:\n\n    lookupSymbol failed in resolveImports\n    /tmp/.../T9878b.o: unknown symbol `___dso_handle'\n\nThe fix is to match both spellings.  Same semantics on ELF and Mach-O\n(the loader hands the dependent object's image back either way); only\nthe spelling at lookup time differs.\n\nSurfaced by session 60's extended ghci-tnum runner on T9878b\n(`-fobject-code` + `:l T9878b.hs` with `import GHC.StaticPtr; static\nTrue` \u2014 SPT init emits a call to `__cxa_atexit(..., __dso_handle)`).\nReleased as v0.14.2.\n\ndiff --git a/rts/Linker.c b/rts/Linker.c\nindex 19545fd3..4c06a477 100644\n--- a/rts/Linker.c\n+++ b/rts/Linker.c\n@@ -851,7 +851,8 @@ SymbolAddr* lookupDependentSymbol (SymbolName* lbl, ObjectCode *dependent)\n     RtsSymbolInfo *pinfo;\n\n     /* See Note [Resolving __dso_handle] */\n-    if (strcmp(lbl, \"__dso_handle\") == 0) {\n+    if (strcmp(lbl, \"__dso_handle\") == 0 ||\n+        strcmp(lbl, \"___dso_handle\") == 0) { /* Mach-O underscore prefix */\n         if (dependent) {\n             return dependent->image;\n         } else {\n@@ -925,6 +926,11 @@ SymbolAddr* lookupDependentSymbol (SymbolName* lbl, ObjectCode *dependent)\n  * relocations of bounded displacement and therefore __dso_handle must not be\n  * too far from the loaded object's code (hence using its start address).\n  *\n+ * On Mach-O the symbol table preserves the leading underscore prefix\n+ * convention, so the symbol arrives at lookupDependentSymbol() as\n+ * \"___dso_handle\" (three underscores) rather than the ELF spelling\n+ * \"__dso_handle\" (two).  We match both forms above.\n+ *\n  * See #20493.\n  */\n\n"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/patches/0017-rts-dso-handle-mach-o-underscore.patch",
  "limit": 5
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/patches/0017-rts-dso-handle-mach-o-underscore.patch",
  "content": "From: ghc-darwin8-ppc project\nSubject: [PATCH] rts/Linker.c: match Mach-O underscore-prefixed ___dso_handle\n\nghc-darwin8-ppc: `rts/Linker.c::lookupDependentSymbol` has a special\ncase for `__dso_handle` (see `Note [Resolving __dso_handle]`, upstream\n#20493) that hands the dependent object's image address back as a\nsynthetic handle.  The strcmp was written for ELF, where the symbol\narrives with two leading underscores.\n\nMach-O preserves the platform's leading-underscore symbol-name prefix.\nOur PPC Mach-O loader populates `macho_symbols[i].name` directly from\nthe object's string table (`rts/linker/MachO.c:137-138`), so the\nsymbol arrives at `lookupDependentSymbol` as `\"___dso_handle\"` (three\nunderscores).  The strcmp misses, the special case never fires, and\nresolution falls through to `dlsym(lbl + 1)`.  On Tiger this also\nfails -- `___dso_handle` is provided at link time by `dylib1.o`/`crt1.o`\nand is not exported into the runtime dyld namespace.  The .o load\ntherefore aborts with:\n\n    lookupSymbol failed in resolveImports\n    /tmp/.../T9878b.o: unknown symbol `___dso_handle'\n\nThe fix is to match both spellings.  Same semantics on ELF and Mach-O\n(the loader hands the dependent object's image back either way); only\nthe spelling at lookup time differs.\n\nSurfaced by session 60's extended ghci-tnum runner on T9878b\n(`-fobject-code` + `:l T9878b.hs` with `import GHC.StaticPtr; static\nTrue` -- SPT init emits a call to `__cxa_atexit(..., __dso_handle)`).\nReleased as v0.14.2.\n\ndiff --git a/rts/Linker.c b/rts/Linker.c\nindex 19545fd3..4c06a477 100644\n--- a/rts/Linker.c\n+++ b/rts/Linker.c\n@@ -851,7 +851,8 @@ SymbolAddr* lookupDependentSymbol (SymbolName* lbl, ObjectCode *dependent)\n     RtsSymbolInfo *pinfo;\n\n     /* See Note [Resolving __dso_handle] */\n-    if (strcmp(lbl, \"__dso_handle\") == 0) {\n+    if (strcmp(lbl, \"__dso_handle\") == 0 ||\n+        strcmp(lbl, \"___dso_handle\") == 0) { /* Mach-O underscore prefix */\n         if (dependent) {\n             return dependent->image;\n         } else {\n@@ -925,6 +926,11 @@ SymbolAddr* lookupDependentSymbol (SymbolName* lbl, ObjectCode *dependent)\n  * relocations of bounded displacement and therefore __dso_handle must not be\n  * too far from the loaded object's code (hence using its start address).\n  *\n+ * On Mach-O the symbol table preserves the leading underscore prefix\n+ * convention, so the symbol arrives at lookupDependentSymbol() as\n+ * \"___dso_handle\" (three underscores) rather than the ELF spelling\n+ * \"__dso_handle\" (two).  We match both forms above.\n+ *\n  * See #20493.\n  */\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn \"patches/0\" --include=\"*.sh\" --include=\"*.md\" /Users/cell/claude/ghc-darwin8-ppc/scripts/ /Users/cell/claude/ghc-darwin8-ppc/docs/plan.md 2>/dev/null | head -10",
  "description": "Find how patches are applied"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -rn \"patches/\" --include=\"*.sh\" /Users/cell/claude/ghc-darwin8-ppc/scripts/ 2>/dev/null | head -10 && echo \"---\" && grep -rn \"0017\\|git apply\\|patch -p\" /Users/cell/claude/ghc-darwin8-ppc/scripts/install.sh /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null | head",
  "description": "Find patch-apply automation"
}


---

## 🤖 Claude

Patches are a documentation record, not auto-applied. The source-tree change is what drives the build. Now let me rebuild stage1.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Read rts/Linker.c context around dso_handle and craft patch 0017",
      "activeForm": "Reading rts/Linker.c and crafting patch 0017",
      "status": "completed"
    },
    {
      "content": "Create session 61 directory and scaffolding",
      "activeForm": "Creating session 61 directory",
      "status": "completed"
    },
    {
      "content": "Apply source edit, rebuild stage1",
      "activeForm": "Applying source edit and rebuilding stage1",
      "status": "in_progress"
    },
    {
      "content": "Generate patches/0017-...patch from source diff",
      "activeForm": "Generating patches/0017 from source diff",
      "status": "completed"
    },
    {
      "content": "Run deploy-stage2.sh pmacg5 to redeploy stage2",
      "activeForm": "Running deploy-stage2.sh pmacg5",
      "status": "pending"
    },
    {
      "content": "Re-run session 60 runner \u2014 verify T9878b PASSes (165/166 target)",
      "activeForm": "Re-running session 60 runner",
      "status": "pending"
    },
    {
      "content": "Re-roll bindist tarball",
      "activeForm": "Rolling new bindist tarball",
      "status": "pending"
    },
    {
      "content": "Pick / write a static-pointer / -fobject-code demo for v0.14.2",
      "activeForm": "Writing v0.14.2 demo",
      "status": "pending"
    },
    {
      "content": "Update README, docs/state.md, docs/roadmap.md, demos/README.md",
      "activeForm": "Updating top-level docs",
      "status": "pending"
    },
    {
      "content": "Commit, tag v0.14.2, push, gh release create with bindist asset",
      "activeForm": "Committing, tagging, pushing, releasing v0.14.2",
      "status": "pending"
    },
    {
      "content": "Write session 61 README, findings, commits, HANDOFF",
      "activeForm": "Writing session 61 docs",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh && ls _build/stage1/bin/ 2>&1 | head -5 && echo \"---\" && file _build/stage1/bin/powerpc-apple-darwin8-ghc 2>&1 | head -3",
  "description": "Confirm stage1 build state"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find _build/stage1 -name 'Linker.o' 2>/dev/null | head",
  "description": "Find rts Linker.o build outputs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la _build/stage1/rts/build/c/Linker.o _build/stage1/lib/powerpc-apple-darwin8-ghc-9.2.8/rts-1.0.2/libHSrts*.a 2>&1 | head -10",
  "description": "Inspect rts build outputs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find _build/stage1/lib -name 'libHSrts*' 2>/dev/null | head -10 && echo \"---\" && find _build/stage1/rts -name '*.a' 2>/dev/null | head -10",
  "description": "Find rts archives"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "touch rts/Linker.c && ./hadrian/build --flavour=quick-cross --docs=none -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>&1 | tail -30",
  "description": "Rebuild rts vanilla archive",
  "timeout": 600000
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
  "command": "which ghc && ghc --numeric-version && echo \"---\" && which cabal && cabal --numeric-version 2>&1 | tail -3",
  "description": "Check ghc/cabal in PATH"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && which ghc && ghc --numeric-version && which cabal && cabal --numeric-version 2>&1 | tail -3",
  "description": "Confirm cross-env reaches ghc 9.2.8"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat hadrian/build | head -40",
  "description": "Inspect hadrian/build wrapper"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat hadrian/build-cabal | head -40",
  "description": "Inspect hadrian/build-cabal"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && echo \"GHC will be: $(which ghc)\" && echo \"cabal will be: $(which cabal)\" && ls _build/hadrian/ 2>&1 | head",
  "description": "Check hadrian build outputs"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "find . -maxdepth 3 -name 'dist-newstyle' 2>/dev/null | head -3 && echo \"---\" && find _build -maxdepth 4 -name 'hadrian' -type d 2>/dev/null | head -5",
  "description": "Find hadrian dist tree"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls _build/hadrian/ && echo \"---\" && find _build/hadrian -name 'hadrian' -type f 2>/dev/null | head && echo \"---\" && ls hadrian/dist-newstyle/ | head -5",
  "description": "Inspect hadrian build artifacts"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls hadrian/dist-newstyle/build/ 2>&1 | head -5 && echo \"---\" && ls hadrian/dist-newstyle/build/*/*/ 2>&1 | head -10",
  "description": "Inspect hadrian dist-newstyle structure"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls hadrian/dist-newstyle/build/aarch64-osx/",
  "description": "Check ghc version used for hadrian"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && export GHC=$HOME/.local/ghc-9.2.8/bin/ghc && export CABAL=cabal && echo \"GHC=$GHC\" && echo \"CABAL=$CABAL\" && $GHC --info | grep -i SMP",
  "description": "Confirm GHC env vars"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && export GHC=$HOME/.local/ghc-9.2.8/bin/ghc && ./hadrian/build --flavour=quick-cross --docs=none -j8 _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>&1 | tail -40",
  "description": "Rebuild rts vanilla archive with explicit GHC env",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/*.a 2>&1 | head -15 && echo \"---\" && date",
  "description": "Check rts archive mtimes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la _build/stage1/rts/build/c/Linker.o && echo \"---\" && powerpc-apple-darwin8-strings _build/stage1/rts/build/c/Linker.o 2>/dev/null | grep -E '_dso_handle|dso' | head",
  "description": "Inspect rebuilt Linker.o"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "strings _build/stage1/rts/build/c/Linker.o 2>/dev/null | grep -E 'dso_handle' | head",
  "description": "Check for dso_handle strings in Linker.o"
}


---

## 🤖 Claude

The rebuilt Linker.o contains both `__dso_handle` and `___dso_handle` strings — the patch is in. Capture the build log and move to stage2 deploy.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && (echo \"Build run at: $(date)\"; echo; echo \"=== git diff rts/Linker.c ===\"; git diff rts/Linker.c; echo; echo \"=== strings _build/stage1/rts/build/c/Linker.o | grep dso_handle ===\"; strings _build/stage1/rts/build/c/Linker.o 2>/dev/null | grep dso_handle) > $SESSION/logs/01-stage1-rebuild.log && head -40 $SESSION/logs/01-stage1-rebuild.log",
  "description": "Save stage1 rebuild log"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Read rts/Linker.c context around dso_handle and craft patch 0017",
      "activeForm": "Reading rts/Linker.c and crafting patch 0017",
      "status": "completed"
    },
    {
      "content": "Create session 61 directory and scaffolding",
      "activeForm": "Creating session 61 directory",
      "status": "completed"
    },
    {
      "content": "Apply source edit, rebuild stage1",
      "activeForm": "Applying source edit and rebuilding stage1",
      "status": "completed"
    },
    {
      "content": "Generate patches/0017-...patch from source diff",
      "activeForm": "Generating patches/0017 from source diff",
      "status": "completed"
    },
    {
      "content": "Run deploy-stage2.sh pmacg5 to redeploy stage2",
      "activeForm": "Running deploy-stage2.sh pmacg5",
      "status": "in_progress"
    },
    {
      "content": "Re-run session 60 runner \u2014 verify T9878b PASSes (165/166 target)",
      "activeForm": "Re-running session 60 runner",
      "status": "pending"
    },
    {
      "content": "Re-roll bindist tarball",
      "activeForm": "Rolling new bindist tarball",
      "status": "pending"
    },
    {
      "content": "Pick / write a static-pointer / -fobject-code demo for v0.14.2",
      "activeForm": "Writing v0.14.2 demo",
      "status": "pending"
    },
    {
      "content": "Update README, docs/state.md, docs/roadmap.md, demos/README.md",
      "activeForm": "Updating top-level docs",
      "status": "pending"
    },
    {
      "content": "Commit, tag v0.14.2, push, gh release create with bindist asset",
      "activeForm": "Committing, tagging, pushing, releasing v0.14.2",
      "status": "pending"
    },
    {
      "content": "Write session 61 README, findings, commits, HANDOFF",
      "activeForm": "Writing session 61 docs",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && export GHC=$HOME/.local/ghc-9.2.8/bin/ghc && /Users/cell/claude/ghc-darwin8-ppc/scripts/deploy-stage2.sh pmacg5 2>&1 | tee $SESSION/logs/02-deploy-stage2.log | tail -40",
  "description": "Deploy stage2 to pmacg5",
  "timeout": 600000
}


---

## 🤖 Claude

Stage2 deployed successfully and the smoke test passed. Now re-run the session-60 ghci-tnum runner to verify T9878b flips to PASS.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/",
  "description": "Inspect session 60 runner scripts"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && cp /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/run-ghci-tnum.sh $SESSION/scripts/ && cp /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/normalise.py $SESSION/scripts/ && ls -la $SESSION/scripts/",
  "description": "Copy session 60 runner to session 61"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && bash $SESSION/scripts/run-ghci-tnum.sh pmacg5 2>&1 | tee $SESSION/logs/03-ghci-tnum-rerun.log | tail -30",
  "description": "Re-run session 60 runner against v0.14.2 stage2",
  "timeout": 600000
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

The runner is going in the background. While it runs, let me look at what kind of demo would best showcase the `__dso_handle` / StaticPointers / `-fobject-code` fix.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls /Users/cell/claude/ghc-darwin8-ppc/demos/",
  "description": "List existing demos"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/demos/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/T9878b.hs 2>&1 && echo \"---SCRIPT---\" && cat /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/T9878b.script 2>&1 && echo \"---STDOUT---\" && cat /Users/cell/claude/ghc-darwin8-ppc/external/ghc-modern/ghc-9.2.8/testsuite/tests/ghci/scripts/T9878b.stdout 2>&1",
  "description": "Inspect T9878b test artifacts"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -20 /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7ffe9ca6-c20e-44d7-ac10-3e8234ba33a0/tasks/b1c7j45ab.output 2>&1",
  "description": "Check runner progress"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && wc -l $SESSION/logs/03-ghci-tnum-rerun.log 2>&1 && tail -10 $SESSION/logs/03-ghci-tnum-rerun.log 2>&1",
  "description": "Check runner log tail"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ls -la /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7ffe9ca6-c20e-44d7-ac10-3e8234ba33a0/tasks/ 2>&1 | head && echo \"---\" && wc -l /private/tmp/claude-501/-Users-cell-claude-ghc-darwin8-ppc/7ffe9ca6-c20e-44d7-ac10-3e8234ba33a0/tasks/b1c7j45ab.output 2>&1",
  "description": "Check runner background output"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/demos/v0.14.1-literate-haskell.sh"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "tail -20 /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/logs/03-ghci-tnum-rerun.log 2>&1",
  "description": "Re-check runner log"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "ps -ef | grep -E 'run-ghci-tnum|ssh.*pmacg5' | grep -v grep | head",
  "description": "Check if runner processes are alive"
}


---

## 🤖 Claude

While the runner continues, let me draft the demo.

---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/demos/v0.14.2-static-pointers.hs",
  "content": "{-# LANGUAGE StaticPointers #-}\n-- v0.14.2 demo: StaticPointers (and -fobject-code GHCi) on PPC/Tiger.\n--\n-- The compiler emits SPT-init code that registers each `static`\n-- pointer with the GHC runtime so it can be deRef'd later.  That init\n-- code calls `__cxa_atexit(handler, env, __dso_handle)` so the SPT\n-- entries are unregistered at shutdown.  On Mach-O, `__dso_handle`\n-- is spelled `___dso_handle` in the object's symbol table (three\n-- leading underscores -- the platform underscore-prefix convention).\n--\n-- Pre-v0.14.2 the runtime Mach-O loader's `lookupDependentSymbol`\n-- special case for `__dso_handle` strcmp'd against the ELF\n-- spelling, missed the Mach-O form, and dropped through to dlsym --\n-- which on Tiger doesn't expose `___dso_handle` (provided at link\n-- time by dylib1.o / crt1.o, not in the dyld namespace).  Result:\n-- `:l Foo.hs` in GHCi `-fobject-code` mode aborted with\n--   unknown symbol `___dso_handle'\n-- whenever the module had any `static` reference.\n--\n-- v0.14.2's two-line patch to `rts/Linker.c` matches both spellings.\nmodule Main where\n\nimport GHC.StaticPtr\n\n-- A handful of `static` pointers of different shapes, to make the\n-- demo more than a single yes/no.\n\nstaticTrue :: StaticPtr Bool\nstaticTrue = static True\n\nstaticGreeting :: StaticPtr String\nstaticGreeting = static \"v0.14.2 static-pointer demo on PPC/Tiger\"\n\nstaticDouble :: StaticPtr (Int -> Int)\nstaticDouble = static (\\x -> x + x)\n\nstaticSum :: StaticPtr ([Int] -> Int)\nstaticSum = static sum\n\nmain :: IO ()\nmain = do\n    putStrLn \"deRefStaticPtr round-trip:\"\n    putStrLn $ \"  static True               = \" ++ show (deRefStaticPtr staticTrue)\n    putStrLn $ \"  static \\\"v0.14.2 ...\\\"      = \" ++ deRefStaticPtr staticGreeting\n    putStrLn $ \"  static (\\\\x -> x+x) $ 21   = \" ++ show (deRefStaticPtr staticDouble 21)\n    putStrLn $ \"  static sum $ [1..10]      = \" ++ show (deRefStaticPtr staticSum [1..10])\n    putStrLn \"\"\n    putStrLn \"StaticPointers work on PPC/Tiger.\"\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/demos/v0.14.2-static-pointers.sh",
  "content": "#!/bin/bash\n# v0.14.2 demo: StaticPointers + GHCi -fobject-code on PPC/Tiger.\n#\n# What this demonstrates: the v0.14.2 bindist can load Mach-O `.o`\n# files that reference `___dso_handle` from their SPT init code.\n# This is what happens in practice whenever GHCi-`-fobject-code`\n# mode compiles a module containing a `static` pointer:\n#\n#   StaticPointers SPT init\n#     -> __cxa_atexit(_handler, _env, _ _ _dso_handle)\n#         -> the .o has an undefined `___dso_handle` external\n#             -> rts/Linker.c::lookupDependentSymbol must\n#                resolve it as a synthetic handle for the loaded object\n#\n# Pre-v0.14.2 that strcmp matched only the ELF spelling\n# `__dso_handle` (two underscores), so the Mach-O form\n# `___dso_handle` (three underscores) missed the special case, fell\n# through to dlsym, and dlsym on Tiger doesn't find the symbol\n# (it's a link-time-only artifact of dylib1.o / crt1.o).  The .o\n# load aborted with `unknown symbol \\`___dso_handle'`.\n# v0.14.2 fixes it (patch 0017).\n#\n# This script:\n#   1. Confirms the deployed v0.14.2 ghc-real has both spellings\n#      of `dso_handle` in its compiled-in Linker.c text segment.\n#   2. scp's the v0.14.2 .hs demo to Tiger.\n#   3. Compiles + runs natively (the simpler path -- works on\n#      any release that ships StaticPointers in the SPT machinery,\n#      but bundling the demo lets the v0.14.2 release tag have a\n#      runnable copy on disk).\n#   4. Loads the same module into GHCi `-fobject-code` mode (the\n#      load path that was broken pre-v0.14.2) and exercises\n#      `deRefStaticPtr` on each of the four `static` pointers --\n#      this is the new capability v0.14.2 unblocks.\n#\n# Session: docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/\n#\n# Prereqs: v0.14.2 stage2 deployed to $PPC_HOST via deploy-stage2.sh\n# (or v0.14.2 bindist installed via install.sh).\n\nset -uo pipefail\n\nPPC_HOST=\"${1:-pmacg5}\"\nDYLD='DYLD_LIBRARY_PATH=/opt/gmp-6.2.1/lib:/opt/gcc14/lib'\nGHC=/opt/ghc-stage2/bin/ghc-real\nHS=\"$(cd \"$(dirname \"$0\")\" && pwd)/v0.14.2-static-pointers.hs\"\n\necho \"==> 0. confirm v0.14.2 ghc-real has both __dso_handle spellings\"\nssh -e none -T -q \"$PPC_HOST\" \"strings $GHC | grep -F dso_handle | sort -u\"\n\necho\necho \"==> 1. ship the .hs to Tiger\"\nscp -q \"$HS\" \"$PPC_HOST:/tmp/static-pointers.hs\"\n\necho\necho \"==> 2. compile + run natively\"\nssh -e none -T -q \"$PPC_HOST\" \"\n  set -e\n  cd /tmp\n  rm -f static-pointers static-pointers.o static-pointers.hi\n  $DYLD $GHC -O0 static-pointers.hs -o static-pointers 2>&1 | tail -10\n  echo\n  $DYLD /tmp/static-pointers\n\"\n\necho\necho \"==> 3. :load the module into GHCi -fobject-code (the v0.14.2 path)\"\nssh -e none -T -q \"$PPC_HOST\" \"$DYLD $GHC --interactive -ignore-dot-ghci -fobject-code 2>&1\" <<'EOF'\n:l /tmp/static-pointers.hs\ndeRefStaticPtr staticTrue\ndeRefStaticPtr staticGreeting\ndeRefStaticPtr staticDouble 21\ndeRefStaticPtr staticSum [1..10]\nmain\n:q\nEOF\n\necho\necho \"v0.14.2 demo done.  StaticPointers + GHCi -fobject-code work on PPC/Tiger.\"\n"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "chmod +x /Users/cell/claude/ghc-darwin8-ppc/demos/v0.14.2-static-pointers.sh && SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && tail -30 $SESSION/logs/03-ghci-tnum-rerun.log",
  "description": "Check ghci-tnum rerun results"
}


---

## 🤖 Claude

**165/166 PASS** — exactly the target. T9878b flipped to PASS, only the HFS+ mtime race (T17549) remains. The patch is verified.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "grep -E \"T9878b|T12091|T17500|T17549\" /Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/logs/03-ghci-tnum-rerun.log",
  "description": "Confirm T9878b PASS and others"
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Read rts/Linker.c context around dso_handle and craft patch 0017",
      "activeForm": "Reading rts/Linker.c and crafting patch 0017",
      "status": "completed"
    },
    {
      "content": "Create session 61 directory and scaffolding",
      "activeForm": "Creating session 61 directory",
      "status": "completed"
    },
    {
      "content": "Apply source edit, rebuild stage1",
      "activeForm": "Applying source edit and rebuilding stage1",
      "status": "completed"
    },
    {
      "content": "Generate patches/0017-...patch from source diff",
      "activeForm": "Generating patches/0017 from source diff",
      "status": "completed"
    },
    {
      "content": "Run deploy-stage2.sh pmacg5 to redeploy stage2",
      "activeForm": "Running deploy-stage2.sh pmacg5",
      "status": "completed"
    },
    {
      "content": "Re-run session 60 runner \u2014 verify T9878b PASSes (165/166 target)",
      "activeForm": "Re-running session 60 runner",
      "status": "completed"
    },
    {
      "content": "Test the v0.14.2 demo on pmacg5",
      "activeForm": "Testing v0.14.2 demo on pmacg5",
      "status": "in_progress"
    },
    {
      "content": "Re-roll bindist tarball",
      "activeForm": "Rolling new bindist tarball",
      "status": "pending"
    },
    {
      "content": "Update README, docs/state.md, docs/roadmap.md, demos/README.md",
      "activeForm": "Updating top-level docs",
      "status": "pending"
    },
    {
      "content": "Commit, tag v0.14.2, push, gh release create with bindist asset",
      "activeForm": "Committing, tagging, pushing, releasing v0.14.2",
      "status": "pending"
    },
    {
      "content": "Write session 61 README, findings, commits, HANDOFF",
      "activeForm": "Writing session 61 docs",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && bash /Users/cell/claude/ghc-darwin8-ppc/demos/v0.14.2-static-pointers.sh pmacg5 2>&1 | tee $SESSION/logs/04-demo-run.log",
  "description": "Run v0.14.2 demo",
  "timeout": 300000
}


---

## 🤖 Claude

The demo works end-to-end — but the REPL doesn't have `GHC.StaticPtr` in scope so the individual calls fail; `main` works fine and prints all four results. Let me fix the demo to `:m + GHC.StaticPtr` first.

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/demos/v0.14.2-static-pointers.sh",
  "old_string": "ssh -e none -T -q \"$PPC_HOST\" \"$DYLD $GHC --interactive -ignore-dot-ghci -fobject-code 2>&1\" <<'EOF'\n:l /tmp/static-pointers.hs\ndeRefStaticPtr staticTrue\ndeRefStaticPtr staticGreeting\ndeRefStaticPtr staticDouble 21\ndeRefStaticPtr staticSum [1..10]\nmain\n:q\nEOF",
  "new_string": "ssh -e none -T -q \"$PPC_HOST\" \"$DYLD $GHC --interactive -ignore-dot-ghci -fobject-code 2>&1\" <<'EOF'\n:l /tmp/static-pointers.hs\n:m + GHC.StaticPtr\ndeRefStaticPtr staticTrue\ndeRefStaticPtr staticGreeting\ndeRefStaticPtr staticDouble 21\ndeRefStaticPtr staticSum [1..10]\nmain\n:q\nEOF"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && bash /Users/cell/claude/ghc-darwin8-ppc/demos/v0.14.2-static-pointers.sh pmacg5 2>&1 | tee $SESSION/logs/04-demo-run.log | tail -40",
  "description": "Re-run v0.14.2 demo",
  "timeout": 300000
}


---

## 🤖 Claude

Demo runs end-to-end cleanly. Now re-roll the bindist.

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Read rts/Linker.c context around dso_handle and craft patch 0017",
      "activeForm": "Reading rts/Linker.c and crafting patch 0017",
      "status": "completed"
    },
    {
      "content": "Create session 61 directory and scaffolding",
      "activeForm": "Creating session 61 directory",
      "status": "completed"
    },
    {
      "content": "Apply source edit, rebuild stage1",
      "activeForm": "Applying source edit and rebuilding stage1",
      "status": "completed"
    },
    {
      "content": "Generate patches/0017-...patch from source diff",
      "activeForm": "Generating patches/0017 from source diff",
      "status": "completed"
    },
    {
      "content": "Run deploy-stage2.sh pmacg5 to redeploy stage2",
      "activeForm": "Running deploy-stage2.sh pmacg5",
      "status": "completed"
    },
    {
      "content": "Re-run session 60 runner \u2014 verify T9878b PASSes (165/166 target)",
      "activeForm": "Re-running session 60 runner",
      "status": "completed"
    },
    {
      "content": "Test the v0.14.2 demo on pmacg5",
      "activeForm": "Testing v0.14.2 demo on pmacg5",
      "status": "completed"
    },
    {
      "content": "Re-roll bindist tarball",
      "activeForm": "Rolling new bindist tarball",
      "status": "in_progress"
    },
    {
      "content": "Update README, docs/state.md, docs/roadmap.md, demos/README.md",
      "activeForm": "Updating top-level docs",
      "status": "pending"
    },
    {
      "content": "Commit, tag v0.14.2, push, gh release create with bindist asset",
      "activeForm": "Committing, tagging, pushing, releasing v0.14.2",
      "status": "pending"
    },
    {
      "content": "Write session 61 README, findings, commits, HANDOFF",
      "activeForm": "Writing session 61 docs",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && source /Users/cell/claude/ghc-darwin8-ppc/scripts/cross-env.sh 2>/dev/null && export GHC=$HOME/.local/ghc-9.2.8/bin/ghc && ./hadrian/build --flavour=quick-cross --docs=none -j8 binary-dist-dir 2>&1 | tee $SESSION/logs/05-hadrian-bindist.log | tail -30",
  "description": "Re-roll bindist tarball",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && BINDIST=_build/bindist/ghc-9.2.8-powerpc-apple-darwin8 && find $BINDIST -name 'libHSrts-1.0.2.a' && echo \"---\" && find $BINDIST -name 'libHSrts-1.0.2.a' -exec sh -c 'ar t \"$1\" 2>/dev/null | grep -i linker' _ {} \\; | head && echo \"---\" && ls -la $BINDIST/bin/powerpc-apple-darwin8-unlit* $BINDIST/lib/bin/powerpc-apple-darwin8-unlit* 2>&1 | head -6 && echo \"---\" && file $BINDIST/bin/powerpc-apple-darwin8-unlit-ghc-9.2.8 2>&1",
  "description": "Inspect bindist structure"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && BINDIST=_build/bindist/ghc-9.2.8-powerpc-apple-darwin8 && ar t $BINDIST/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a 2>/dev/null | grep -i linker | head && echo \"---\" && ar x $BINDIST/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a Linker.o 2>&1 && strings Linker.o 2>/dev/null | grep dso_handle && rm -f Linker.o && echo \"---\" && ls -la $BINDIST/bin/ $BINDIST/lib/bin/ 2>&1 | grep -E 'unlit|iserv' | head",
  "description": "Verify Linker.o in bindist + unlit/iserv arch"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && BINDIST=_build/bindist/ghc-9.2.8-powerpc-apple-darwin8 && file $BINDIST/bin/powerpc-apple-darwin8-unlit-ghc-9.2.8 $BINDIST/lib/bin/powerpc-apple-darwin8-unlit 2>&1",
  "description": "Verify unlit binaries are ppc"
}


---

## 🤖 Claude

Bindist looks clean: Linker.o has both spellings, unlit is ppc. Now tar it.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "SESSION=/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle && cd _build/bindist && rm -f ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz && XZ_OPT=\"-T0 -6\" tar -cJf ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz ghc-9.2.8-powerpc-apple-darwin8 2>&1 | tee -a $SESSION/logs/05-hadrian-bindist.log && ls -lh ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz",
  "description": "Tar the bindist",
  "timeout": 600000
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/README.md"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/README.md",
  "old_string": "Latest release:\n[**v0.14.1**](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1)\n\u2014 **Literate Haskell (`unlit`) packaging fix** \ud83d\udcdc.  The v0.14.0\nbindist shipped a host (arm64) `unlit` pre-processor at\n`lib/bin/powerpc-apple-darwin8-unlit` \u2014 Hadrian's cross-mode\nhelper-binary-copy in `hadrian/src/Rules/Program.hs` excluded\n`iserv` (patch 0010's carve-out) but missed `unlit`.  Any `.lhs`\ninput produced exit code 126 (\"cannot execute binary file\").\nLatent since v0.7.0 (when patch 0010 landed); surfaced in\n[session 58](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/)\nby T10989 (the only `.lhs` test in upstream's GHCi script suite).\nv0.14.1 amends [patch 0010](patches/0010-hadrian-cross-iserv.patch)\nto add `unlit` alongside `iserv` in the exclusion list, so the\ncross-build's `buildBinary` path produces a real PPC Mach-O\n`unlit` (47 KB).  Session 58's runner now reports 161/163 PASS\nagainst the new bindist (T10989 \u2705; only T8042 and T17549 remain,\nboth HFS+ 1-second mtime-granularity races in the upstream\nscripts).  See [session 59](docs/sessions/2026-05-17-session-59-v0.14.1-unlit-release/)\nand [`demos/v0.14.1-literate-haskell.sh`](demos/v0.14.1-literate-haskell.sh).\nPlus all of v0.14.0's GHCi REPL, v0.13.0's `STUArray Bool` fix,\nv0.12.0's LLVM-8 swap, v0.11.0's stage2 native ghc, v0.10.0's\nprofiling, v0.9.0's HTTPS, etc.",
  "new_string": "Latest release:\n[**v0.14.2**](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2)\n\u2014 **StaticPointers + GHCi `-fobject-code` packaging fix** \ud83e\ude84.\n[Patch 0017](patches/0017-rts-dso-handle-mach-o-underscore.patch)\nteaches the runtime Mach-O loader's `__dso_handle` special case\nabout the platform underscore prefix.  Upstream's\n`rts/Linker.c::lookupDependentSymbol` strcmps against the ELF\nspelling `\"__dso_handle\"`, but on Mach-O the symbol arrives as\n`\"___dso_handle\"` (three underscores).  Pre-fix, `:l Foo.hs` in\nGHCi `-fobject-code` mode aborted with `unknown symbol\n\\`___dso_handle'` whenever the module had any `static` pointer \u2014\nthe SPT init code calls `__cxa_atexit(_, _, __dso_handle)` which\nemits an undefined external for the symbol.  Surfaced by [session\n60](docs/sessions/2026-05-17-session-60-extra-run-opts-runner/)'s\nextended ghci-tnum runner via T9878b.  Two-line patch matches both\nspellings; T9878b flips to PASS, session-60 runner reports\n**165/166** against the new bindist (only T17549's HFS+ mtime\nrace remains).  See [session 61](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/)\nand [`demos/v0.14.2-static-pointers.sh`](demos/v0.14.2-static-pointers.sh).\nPlus all of v0.14.1's literate Haskell, v0.14.0's GHCi REPL,\nv0.13.0's `STUArray Bool` fix, v0.12.0's LLVM-8 swap, v0.11.0's\nstage2 native ghc, v0.10.0's profiling, v0.9.0's HTTPS, etc."
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/README.md",
  "old_string": "**Runner extension ([session 60](docs/sessions/2026-05-17-session-60-extra-run-opts-runner/)):** added `extra_run_opts(...)` support to `run-ghci-tnum.sh` and three new tests (T9878b, T12091, T17500).  T12091 + T17500 PASS clean (164/166).  T9878b surfaces a real PPC/Tiger bug \u2014 `rts/Linker.c::lookupDependentSymbol`'s `__dso_handle` special case strcmps against the ELF spelling but the Mach-O loader passes the underscore-prefixed `___dso_handle`, so static-pointer SPT-init's `__cxa_atexit` reference goes unresolved.  Filed as [`docs/proposals/rts-dso-handle-mach-o.md`](docs/proposals/rts-dso-handle-mach-o.md) with a two-line-fix v0.14.2 release sketch. |",
  "new_string": "**Runner extension ([session 60](docs/sessions/2026-05-17-session-60-extra-run-opts-runner/)):** added `extra_run_opts(...)` support to `run-ghci-tnum.sh` and three new tests (T9878b, T12091, T17500).  T12091 + T17500 PASS clean (164/166).  T9878b surfaced a real PPC/Tiger bug \u2014 `rts/Linker.c::lookupDependentSymbol`'s `__dso_handle` special case strcmps against the ELF spelling but the Mach-O loader passes the underscore-prefixed `___dso_handle`, so static-pointer SPT-init's `__cxa_atexit` reference goes unresolved.  **Fixed in [v0.14.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2)** ([session 61](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/)) \u2014 [patch 0017](patches/0017-rts-dso-handle-mach-o-underscore.patch) matches both spellings; T9878b flips to PASS, taking the session-60 runner to **165/166** PASS against the new bindist (only T17549's HFS+ mtime race remains). |"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/README.md",
  "old_string": "- [`patches/`](patches/) \u2014 16 patches to GHC 9.2.8 source\n  re-enabling PPC/Darwin bits, including [patch 0016](patches/0016-array-stuarray-bool-word-aligned-init.patch)\n  for the big-endian `STUArray Bool` bug.",
  "new_string": "- [`patches/`](patches/) \u2014 17 patches to GHC 9.2.8 source\n  re-enabling PPC/Darwin bits, including [patch 0016](patches/0016-array-stuarray-bool-word-aligned-init.patch)\n  for the big-endian `STUArray Bool` bug and [patch 0017](patches/0017-rts-dso-handle-mach-o-underscore.patch)\n  for the Mach-O `___dso_handle` strcmp."
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/README.md",
  "old_string": "| [v0.14.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1) | 2026-05-17 | **Literate Haskell (`.lhs`) works on Tiger** \ud83d\udcdc \u2014 Hadrian patch 0010 amended to add `unlit` alongside `iserv` in the cross-mode helper-binary-copy carve-out.  Pre-fix the v0.14.0 bindist shipped the host arm64 `unlit` with a `powerpc-apple-darwin8-` prefix (latent since v0.7.0 when patch 0010 landed; surfaced by [session 58](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/) via T10989).  Post-fix `unlit` cross-builds as a real 47 KB PPC Mach-O binary through hadrian's normal `buildBinary` path; session-58 runner re-runs at 161/163 PASS.  No other changes. |",
  "new_string": "| [v0.14.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1) | 2026-05-17 | **Literate Haskell (`.lhs`) works on Tiger** \ud83d\udcdc \u2014 Hadrian patch 0010 amended to add `unlit` alongside `iserv` in the cross-mode helper-binary-copy carve-out.  Pre-fix the v0.14.0 bindist shipped the host arm64 `unlit` with a `powerpc-apple-darwin8-` prefix (latent since v0.7.0 when patch 0010 landed; surfaced by [session 58](docs/sessions/2026-05-17-session-58-ghci-tnum-scripts/) via T10989).  Post-fix `unlit` cross-builds as a real 47 KB PPC Mach-O binary through hadrian's normal `buildBinary` path; session-58 runner re-runs at 161/163 PASS.  No other changes. |\n| [v0.14.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2) | 2026-05-17 | **StaticPointers + GHCi `-fobject-code` work on Tiger** \ud83e\ude84 \u2014 Two-line [patch 0017](patches/0017-rts-dso-handle-mach-o-underscore.patch) teaches `rts/Linker.c::lookupDependentSymbol`'s `__dso_handle` special case about Mach-O's leading-underscore prefix.  Pre-fix, the strcmp matched only the ELF spelling, so `:l Foo.hs` in GHCi `-fobject-code` mode failed with `unknown symbol \\`___dso_handle'` whenever the module had a `static` pointer (SPT-init code references `__dso_handle` via `__cxa_atexit`).  Surfaced by [session 60](docs/sessions/2026-05-17-session-60-extra-run-opts-runner/) via T9878b; fixed in [session 61](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/).  Session-60 runner now reports 165/166 PASS (only T17549's HFS+ mtime race remains).  Upstream-shaped \u2014 same fix would help any Mach-O cross-GHC. |"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "limit": 60
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/state.md",
  "old_string": "# state.md \u2014 where are we right now\n\n*Updated: 2026-05-17 session 60 (**ghci-tnum runner extended with `extra_run_opts(...)` support; 164/166 PASS on the now-166-test T-prefix subset**).",
  "new_string": "# state.md \u2014 where are we right now\n\n*Updated: 2026-05-17 session 61 (**v0.14.2 released \u2014 two-line `__dso_handle` Mach-O underscore fix; session-60 runner now reports 165/166 PASS**).  Session 60 had filed [`docs/proposals/rts-dso-handle-mach-o.md`](proposals/rts-dso-handle-mach-o.md) with the full v0.14.2 release sketch; this session executed it.  Two-line change to `rts/Linker.c::lookupDependentSymbol` \u2014 the `__dso_handle` strcmp now matches both the ELF spelling (`\"__dso_handle\"`) and the Mach-O underscore-prefixed form (`\"___dso_handle\"`) \u2014 landed as [patch 0017](../patches/0017-rts-dso-handle-mach-o-underscore.patch).  Stage1 rebuilt (hadrian re-ranlib'd all 10 RTS ways in ~3.4 sec since only one C file changed).  Stage2 re-cross-built + deployed to pmacg5 via `scripts/deploy-stage2.sh`; the deployed `ghc-real` now contains both spellings of the dso_handle symbol in its compiled-in Linker.c text segment.  Session-60 runner re-ran against the new bindist: **165/166 PASS** (T9878b \u2705; only T17549's HFS+ mtime race remains).  Bindist re-rolled in ~3m09s via hadrian `binary-dist-dir`; verified `Linker.o` extracted from the bindist's `libHSrts-1.0.2.a` contains both `__dso_handle` and `___dso_handle` strings.  Tarball: `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz` (211 MB).  Demo: [`demos/v0.14.2-static-pointers.{hs,sh}`](../demos/v0.14.2-static-pointers.sh) \u2014 module with four `static` pointers (Bool, String, Int->Int closure, [Int]->Int closure) compiles + runs natively, then loads cleanly into `ghc --interactive -fobject-code` (the load path that was broken pre-v0.14.2) and exercises `deRefStaticPtr` on each.  README \"Latest release\" + GHCi REPL row + Releases-table row + Layout 16\u219217 patches all updated.  **STATE CLEAN** \u2014 v0.14.2 released end-to-end: tag pushed to origin; bindist tarball (~211 MB) uploaded to the [v0.14.2 GitHub release](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2).  Patch 0017 added in `patches/`; rts/Linker.c source change matches the patch.*\n\n_(Prior summary, session 60:)_ **ghci-tnum runner extended with `extra_run_opts(...)` support; 164/166 PASS on the now-166-test T-prefix subset**)."
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
  "command": "grep -n \"session 60\\|## \u00a7C\\|session 59\\|^## \" /Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md | head -30",
  "description": "Find \u00a7C in roadmap"
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "offset": 1,
  "limit": 30
}


---

## 🤖 Claude


🔧 Using tool: Read
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "offset": 220,
  "limit": 40
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "old_string": "Last reviewed: 2026-05-17 session 59.",
  "new_string": "Last reviewed: 2026-05-17 session 61."
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/roadmap.md",
  "old_string": "\ud83d\udfe1 **Session 60 (verification + new bug):** Extended session 58's\n`run-ghci-tnum.sh` with `extra_run_opts(...)` support; **164/166\nPASS** on the now-166-test T-prefix subset.  Two of the three new\ntests (T12091, T17500) pass clean; **T9878b surfaces a real\nPPC/Tiger bug**: the runtime Mach-O loader can't resolve\n`___dso_handle` because `rts/Linker.c::lookupDependentSymbol`'s\nspecial case strcmps against the ELF spelling `\"__dso_handle\"`\nwhile the Mach-O loader passes the underscore-prefixed\n`\"___dso_handle\"` straight from the object's string table.  Filed\nas [`docs/proposals/rts-dso-handle-mach-o.md`](proposals/rts-dso-handle-mach-o.md)\nwith a v0.14.2 release sketch (two-line fix in `lookupDependentSymbol`).\nVerification only; no GHC source changes, no patches, no release.\nReusable runner extension at\n[`docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/`](sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/);\nfuture `extra_hc_opts` / `reqlib` / `pre_cmd` extensions can use\nthe same `run_opts_for()` shape.\nSee [session 60](sessions/2026-05-17-session-60-extra-run-opts-runner/).",
  "new_string": "\ud83d\udfe1 **Session 60 (verification + new bug):** Extended session 58's\n`run-ghci-tnum.sh` with `extra_run_opts(...)` support; **164/166\nPASS** on the now-166-test T-prefix subset.  Two of the three new\ntests (T12091, T17500) pass clean; **T9878b surfaces a real\nPPC/Tiger bug**: the runtime Mach-O loader can't resolve\n`___dso_handle` because `rts/Linker.c::lookupDependentSymbol`'s\nspecial case strcmps against the ELF spelling `\"__dso_handle\"`\nwhile the Mach-O loader passes the underscore-prefixed\n`\"___dso_handle\"` straight from the object's string table.  Filed\nas [`docs/proposals/rts-dso-handle-mach-o.md`](proposals/rts-dso-handle-mach-o.md)\nwith a v0.14.2 release sketch (two-line fix in `lookupDependentSymbol`).\nVerification only; no GHC source changes, no patches, no release.\nReusable runner extension at\n[`docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/`](sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/);\nfuture `extra_hc_opts` / `reqlib` / `pre_cmd` extensions can use\nthe same `run_opts_for()` shape.\nSee [session 60](sessions/2026-05-17-session-60-extra-run-opts-runner/).\n\n\u2705 **Session 61 (v0.14.2 release):** Executed session 60's proposal.\nTwo-line change to `rts/Linker.c::lookupDependentSymbol` matches\nboth `\"__dso_handle\"` and `\"___dso_handle\"` ([patch 0017](../patches/0017-rts-dso-handle-mach-o-underscore.patch)).\nStage1 rebuilt; stage2 re-cross-built + deployed to pmacg5;\nsession-60 runner re-runs at **165/166 PASS** (T9878b \u2705; only\nT17549's HFS+ mtime race remains).  Bindist re-rolled; tarball\nshipped as the [v0.14.2 GitHub release](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2).\nDemo: [`demos/v0.14.2-static-pointers.{hs,sh}`](../demos/v0.14.2-static-pointers.sh)\n\u2014 exercises four `static` pointers (Bool, String, Int\u2192Int closure,\n[Int]\u2192Int closure) under both native compile and the GHCi\n`-fobject-code` load path (the path that was broken pre-v0.14.2).\nUpstream-shaped fix; would help any Mach-O cross-GHC.\nSee [session 61](sessions/2026-05-17-session-61-v0.14.2-dso-handle/)."
}


---

## 🤖 Claude

Now the demos/README.md update.

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/demos/README.md",
  "old_string": "## What's here (v0.14.1)",
  "new_string": "## What's here (v0.14.2)"
}


---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/demos/README.md",
  "old_string": "| [`v0.14.1-literate-haskell.{lhs,sh}`](v0.14.1-literate-haskell.sh) | **Literate Haskell (`.lhs`) end-to-end on Tiger.**  A bird-track `.lhs` source (factorial / sort / toUpper / collatz) is `scp`'d to pmacg5, compiled by stage2 native ghc (whose `.lhs` pre-processing step invokes the bindist's `unlit` helper), the resulting binary runs, then the same `.lhs` is `:load`ed into the GHCi REPL \u2014 exercising both the file-on-disk and REPL paths through `unlit`.  Pre-v0.14.1 every step would have failed with `cannot execute binary file` (exit 126) because Hadrian shipped the host arm64 `unlit` with a `powerpc-apple-darwin8-` prefix.  v0.14.1's amended [patch 0010](../patches/0010-hadrian-cross-iserv.patch) makes hadrian cross-build a real PPC `unlit` (47 KB Mach-O) into the bindist. | [v0.14.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1) |",
  "new_string": "| [`v0.14.1-literate-haskell.{lhs,sh}`](v0.14.1-literate-haskell.sh) | **Literate Haskell (`.lhs`) end-to-end on Tiger.**  A bird-track `.lhs` source (factorial / sort / toUpper / collatz) is `scp`'d to pmacg5, compiled by stage2 native ghc (whose `.lhs` pre-processing step invokes the bindist's `unlit` helper), the resulting binary runs, then the same `.lhs` is `:load`ed into the GHCi REPL \u2014 exercising both the file-on-disk and REPL paths through `unlit`.  Pre-v0.14.1 every step would have failed with `cannot execute binary file` (exit 126) because Hadrian shipped the host arm64 `unlit` with a `powerpc-apple-darwin8-` prefix.  v0.14.1's amended [patch 0010](../patches/0010-hadrian-cross-iserv.patch) makes hadrian cross-build a real PPC `unlit` (47 KB Mach-O) into the bindist. | [v0.14.1](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.1) |\n| [`v0.14.2-static-pointers.{hs,sh}`](v0.14.2-static-pointers.sh) | **StaticPointers + GHCi `-fobject-code` work on PPC/Tiger.**  A module with four `static` pointers of different shapes (Bool, String, `Int -> Int` closure, `[Int] -> Int` closure) is `scp`'d to pmacg5 and exercised three ways: (1) native compile + run prints `True`, the string, `42`, `55` from `deRefStaticPtr` calls; (2) `ghc --interactive -fobject-code` loads the module's `.o` (the path that was broken pre-v0.14.2) and `:m + GHC.StaticPtr` makes `deRefStaticPtr` available in the REPL; (3) `main` is invoked from inside the REPL.  Pre-v0.14.2 step 2 aborted with `unknown symbol \\`___dso_handle'` because `rts/Linker.c::lookupDependentSymbol`'s `__dso_handle` special case only matched the ELF spelling; the Mach-O symbol is underscore-prefixed (`___dso_handle`).  Two-line fix in [patch 0017](../patches/0017-rts-dso-handle-mach-o-underscore.patch) matches both spellings.  Step 0 of the demo greps the deployed `ghc-real` for both strings to confirm the fix is in. | [v0.14.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2) |"
}


---

## 🤖 Claude

Now write the session 61 README, findings, and HANDOFF. (commits.md will be backfilled with the SHA after the commit lands.)

---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Read rts/Linker.c context around dso_handle and craft patch 0017",
      "activeForm": "Reading rts/Linker.c and crafting patch 0017",
      "status": "completed"
    },
    {
      "content": "Create session 61 directory and scaffolding",
      "activeForm": "Creating session 61 directory",
      "status": "completed"
    },
    {
      "content": "Apply source edit, rebuild stage1",
      "activeForm": "Applying source edit and rebuilding stage1",
      "status": "completed"
    },
    {
      "content": "Generate patches/0017-...patch from source diff",
      "activeForm": "Generating patches/0017 from source diff",
      "status": "completed"
    },
    {
      "content": "Run deploy-stage2.sh pmacg5 to redeploy stage2",
      "activeForm": "Running deploy-stage2.sh pmacg5",
      "status": "completed"
    },
    {
      "content": "Re-run session 60 runner \u2014 verify T9878b PASSes (165/166 target)",
      "activeForm": "Re-running session 60 runner",
      "status": "completed"
    },
    {
      "content": "Test the v0.14.2 demo on pmacg5",
      "activeForm": "Testing v0.14.2 demo on pmacg5",
      "status": "completed"
    },
    {
      "content": "Re-roll bindist tarball",
      "activeForm": "Rolling new bindist tarball",
      "status": "completed"
    },
    {
      "content": "Update README, docs/state.md, docs/roadmap.md, demos/README.md",
      "activeForm": "Updating top-level docs",
      "status": "completed"
    },
    {
      "content": "Write session 61 README, findings, commits scaffold, HANDOFF",
      "activeForm": "Writing session 61 docs",
      "status": "in_progress"
    },
    {
      "content": "Commit, tag v0.14.2, push, gh release create with bindist asset",
      "activeForm": "Committing, tagging, pushing, releasing v0.14.2",
      "status": "pending"
    },
    {
      "content": "Backfill commits.md with the v0.14.2 SHA",
      "activeForm": "Backfilling commits.md with the v0.14.2 SHA",
      "status": "pending"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/README.md",
  "content": "# Session 61 \u2014 Release v0.14.2: `__dso_handle` Mach-O underscore fix shipped\n\n**Date:** 2026-05-17 (continuation of session 60).\n\n**Status on arrival:** Session 60 extended the ghci-tnum runner with\n`extra_run_opts(...)` support and surfaced a real PPC/Tiger bug\nthrough T9878b: `rts/Linker.c::lookupDependentSymbol`'s\n`__dso_handle` special case strcmp'd against the ELF spelling\n(`\"__dso_handle\"`) but the Mach-O loader passes the underscore-\nprefixed form (`\"___dso_handle\"`) straight from the object's\nstring table.  Miss \u2192 returns NULL \u2192 resolveImports fails \u2192\n`-fobject-code` `:l Foo.hs` with any `static` pointer aborts with\n`unknown symbol \\`___dso_handle'`.  Session 60 filed\n[`docs/proposals/rts-dso-handle-mach-o.md`](../../proposals/rts-dso-handle-mach-o.md)\nwith a v0.14.2 release sketch.  Session 60 HANDOFF's #1\nrecommendation: execute that sketch.  164/166 PASS on the v0.14.1\nbindist.\n\n**Status on exit:** **v0.14.2 released**.  Tag pushed; bindist\ntarball (~211 MB) uploaded to the [v0.14.2 GitHub\nrelease](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2).\nDemo committed at\n[`demos/v0.14.2-static-pointers.{hs,sh}`](../../../demos/).  README\n\"Latest release\" line bumped, GHCi REPL row's \"pending v0.14.2\"\nnote converted to \u2705 in-bindist, new row in the Releases table.\n[`docs/state.md`](../../state.md) and [`docs/roadmap.md`](../../roadmap.md)\nupdated.  Session-60 runner re-ran clean against the new bindist:\n**165/166 PASS** (T9878b \u2705; only T17549 remains \u2014 the HFS+ 1-second\nmtime-granularity race in upstream's `:reload` script, not a PPC\nbug).\n\n## What was done\n\n### 1. Source edit + patch 0017\n\n[`rts/Linker.c::lookupDependentSymbol`](../../../external/ghc-modern/ghc-9.2.8/rts/Linker.c)\namended so the `__dso_handle` special case matches both the ELF and\nMach-O spellings:\n\n```c\n/* See Note [Resolving __dso_handle] */\n-   if (strcmp(lbl, \"__dso_handle\") == 0) {\n+   if (strcmp(lbl, \"__dso_handle\") == 0 ||\n+       strcmp(lbl, \"___dso_handle\") == 0) { /* Mach-O underscore prefix */\n        if (dependent) {\n            return dependent->image;\n        } else {\n            return &lookupDependentSymbol;\n        }\n    }\n```\n\nPlus a four-line update to `Note [Resolving __dso_handle]` documenting\nwhy both spellings are matched.  Six-line patch total\n([patches/0017-rts-dso-handle-mach-o-underscore.patch](../../../patches/0017-rts-dso-handle-mach-o-underscore.patch)).\n\nThe proposal's \"Equivalent (slightly cleaner): teach\n`lookupDependentSymbol` to look past one leading underscore on\n`OBJFORMAT_MACHO` before the strcmp\" form was considered.  Went\nwith the OR variant because (a) it's unconditional / no `#if`\nneeded, (b) it matches the existing file style of multiple\n`strcmp(..., \"_FOO\") == 0 ||` checks, (c) it works for any future\nMach-O variant that ever drops the underscore prefix.  Both forms\nare one-hunk equivalents.\n\n### 2. Stage1 rebuild\n\n```bash\nsource scripts/cross-env.sh\nGHC=$HOME/.local/ghc-9.2.8/bin/ghc \\\n  ./hadrian/build --flavour=quick-cross --docs=none -j8 \\\n  _build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a\n```\n\nTotal: **3.44 sec** (`Linker.c` recompiled, all 10 RTS ways\nre-ar'd / re-ranlib'd, package re-registered).  Verified the new\n`Linker.o` contains both spellings:\n\n```\n$ strings _build/stage1/rts/build/c/Linker.o | grep dso_handle\n__dso_handle\n___dso_handle\n```\n\nFull log at [`logs/01-stage1-rebuild.log`](logs/01-stage1-rebuild.log).\n\nNote on `GHC=...`: the bare `./hadrian/build` invocation defaults\n`$GHC` to whatever `ghc` resolves to in `cabal --with-compiler`'s\nresolution, which on this machine picks up homebrew's ghc-9.14 and\nfails to resolve hadrian's deps against base-4.22.  Setting `GHC`\nto the full 9.2.8 path is the load-bearing detail.  Recorded as a\nsession 61 finding.\n\n### 3. Stage2 re-cross-build + deploy\n\n`scripts/deploy-stage2.sh pmacg5` \u2014 cross-compiles `ghc/Main.hs`\nvia the patched stage1, rsyncs the updated `_build/stage1/lib/` to\n`/opt/ghc-stage2/lib/`, smoke-tests.  Log at\n[`logs/02-deploy-stage2.log`](logs/02-deploy-stage2.log).\n\n```\n==> [5/5] smoke-test on pmacg5\nThe Glorious Glasgow Haskell Compilation System, version 9.2.8\nstage2 native ghc on Tiger: ok\n```\n\nVerified the deployed `ghc-real` has both spellings in its\ncompiled-in Linker.c text segment:\n\n```\n$ ssh pmacg5 'strings /opt/ghc-stage2/bin/ghc-real | grep dso_handle'\n___dso_handle\n__dso_handle\n```\n\n### 4. Verification \u2014 session 60 runner\n\nCopied session 60's `run-ghci-tnum.sh` + `normalise.py` into\n`scripts/` and re-ran against the new stage2:\n\n```\n=== Summary: 165 PASS / 1 FAIL out of 166 tests ===\nFailed: T17549\n```\n\nT9878b flipped to PASS \u2705 (the deterministic failure from session\n60).  T17549 is the same HFS+ 1-second mtime-granularity race\ndiagnosed in [session 58\nfindings](../2026-05-17-session-58-ghci-tnum-scripts/findings.md)\n\u2014 not a PPC bug.  Full log at\n[`logs/03-ghci-tnum-rerun.log`](logs/03-ghci-tnum-rerun.log).\n\n### 5. Demo\n\n[`demos/v0.14.2-static-pointers.hs`](../../../demos/v0.14.2-static-pointers.hs)\n\u2014 a module that imports `GHC.StaticPtr` and defines four `static`\npointers of different shapes:\n\n```haskell\nstaticTrue     :: StaticPtr Bool                  -- value\nstaticGreeting :: StaticPtr String                -- value\nstaticDouble   :: StaticPtr (Int -> Int)          -- closure\nstaticSum      :: StaticPtr ([Int] -> Int)        -- closure\n```\n\n`main` calls `deRefStaticPtr` on each and prints the result.\n\n[`demos/v0.14.2-static-pointers.sh`](../../../demos/v0.14.2-static-pointers.sh)\nis the driver.  Four steps:\n\n0. Greps the deployed `ghc-real` for both spellings of `dso_handle`\n   \u2014 proves the fix is compiled in.\n1. scps the `.hs` to pmacg5.\n2. Native compile + run on Tiger \u2014 prints all four `deRefStaticPtr`\n   results.  (This path works on any release that ships\n   StaticPointers, but is included for completeness.)\n3. `:load`s the module into `ghc --interactive -fobject-code` \u2014 the\n   load path that was broken pre-v0.14.2 \u2014 and exercises\n   `deRefStaticPtr` on each pointer via `:m + GHC.StaticPtr` for\n   REPL scope.\n\nLog at [`logs/04-demo-run.log`](logs/04-demo-run.log).  Demo runs\nend-to-end cleanly.\n\n### 6. Bindist re-roll\n\n`./hadrian/build --flavour=quick-cross --docs=none -j8 binary-dist-dir`\n(log at [`logs/05-hadrian-bindist.log`](logs/05-hadrian-bindist.log))\n\u2014 rebuilt the bindist tree from scratch in **3m09s**.  Most of the\ntime was profiling-way rebuilds of Cabal and its transitive\ndependents (same shape as the v0.14.1 re-roll in [session 59\nREADME](../2026-05-17-session-59-v0.14.1-unlit-release/README.md)).\n\nPre-tar sanity check:\n\n```\n$ ar x bindist/lib/.../libHSrts-1.0.2.a Linker.o && strings Linker.o | grep dso_handle\n__dso_handle\n___dso_handle\n```\n\nThe shipped `libHSrts-1.0.2.a`'s `Linker.o` contains both spellings.\n\nTarred with `XZ_OPT=\"-T0 -6\" tar -cJf \u2026`:\n\n```\n_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz  211 MB\n```\n\n(Same size as v0.14.1's tarball; the change is a single object file.)\n\n### 7. README, state.md, roadmap.md, demos/README.md\n\n- **README:** Latest-release paragraph rewritten (v0.14.1 \u2192 v0.14.2);\n  GHCi REPL status row's \"pending v0.14.2 release sketch\" note\n  converted to \u2705-in-bindist; new row in the Releases table; Layout\n  bullet updated 16 \u2192 17 patches.\n- **`docs/state.md`:** top entry bumped to session 61.\n- **`docs/roadmap.md`:** \u00a7C session 61 entry added; last-reviewed\n  date bumped.\n- **`demos/README.md`:** \"What's here\" header bumped to v0.14.2; new\n  row in the per-release table.\n\n### 8. Commit + tag + push + release\n\n(See [`commits.md`](commits.md) for the SHA and the exact commands\nused.)\n\n```\ngit tag -a v0.14.2 -F <commit-message>\ngit push origin main\ngit push origin v0.14.2\ngh release create v0.14.2 \\\n  external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz \\\n  --title \"v0.14.2 \u2014 StaticPointers + GHCi -fobject-code work on Tiger \ud83e\ude84\" \\\n  --notes-file <release-notes>\n```\n\n## What this means\n\nv0.14.2 closes the last deterministic failure in session 60's\n166-test T-prefix subset.  The fix is upstream-shaped: any Mach-O\ncross-GHC where the host doesn't have a live `dyld` exporting\n`___dso_handle` (which is the normal Mach-O state \u2014 the symbol is\nprovided at link time by `dylib1.o`/`crt1.o`, not at run time)\nwould have hit the same bug.  It's been latent in `lookupDependentSymbol`\nsince upstream commit `#20493` added the special case for ELF.\n\nWorth proposing upstream once the local patch settles.  Same\npattern as patch 0016 \u2014 found locally on PPC/Darwin, applicable to\nany platform with Mach-O symbol-name conventions.\n\n## Files added this session\n\n* `README.md` (this), `findings.md`, `HANDOFF.md`, `commits.md`.\n* `scripts/run-ghci-tnum.sh`, `scripts/normalise.py` \u2014 byte-identical\n  copies of session 60's runner artefacts.  Unchanged this session\n  (the runner was the verification harness, not the change-under-test).\n* `logs/01-stage1-rebuild.log` \u2014 git diff of `rts/Linker.c` + the\n  rebuilt `Linker.o`'s `strings` output showing both spellings.\n* `logs/02-deploy-stage2.log` \u2014 `deploy-stage2.sh pmacg5` output.\n* `logs/03-ghci-tnum-rerun.log` \u2014 full PASS/FAIL log (165/166).\n* `logs/04-demo-run.log` \u2014 the v0.14.2 demo running end-to-end on pmacg5.\n* `logs/05-hadrian-bindist.log` \u2014 bindist re-roll output.\n* `patches/0017-rts-dso-handle-mach-o-underscore.patch` \u2014 the patch.\n* `external/ghc-modern/ghc-9.2.8/rts/Linker.c` \u2014 the corresponding\n  live-source change.\n* `demos/v0.14.2-static-pointers.hs` \u2014 the `static`-pointer module.\n* `demos/v0.14.2-static-pointers.sh` \u2014 the driver.\n* `README.md` \u2014 Latest-release paragraph + GHCi REPL row + Releases\n  table + Layout patches-count all updated.\n* `docs/state.md` \u2014 top-of-file summary bumped to session 61.\n* `docs/roadmap.md` \u2014 \u00a7C session 61 / v0.14.2 row added.\n* `demos/README.md` \u2014 v0.14.2 row added; \"What's here\" header bumped.\n\n## On pmacg5\n\nAfter `deploy-stage2.sh pmacg5`:\n\n- `/opt/ghc-stage2/bin/ghc-real` \u2014 rebuilt; same ~199 MB size as\n  v0.14.1.  Its compiled-in `rts/Linker.c` text segment now contains\n  both `__dso_handle` and `___dso_handle` strings.\n- `/opt/ghc-stage2/lib/` \u2014 rsynced with `--delete`; new `Linker.o`\n  baked into all 10 RTS-way archives in `lib/ppc-osx-ghc-9.2.8/rts-1.0.2/`.\n\n## What's next\n\nSee `HANDOFF.md`.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/findings.md",
  "content": "# Session 61 findings\n\n## TL;DR\n\nExecuted session 60's [`docs/proposals/rts-dso-handle-mach-o.md`](../../proposals/rts-dso-handle-mach-o.md)\nrelease sketch.  Six-line patch to `rts/Linker.c` ships as\n[patch 0017](../../../patches/0017-rts-dso-handle-mach-o-underscore.patch);\nv0.14.2 released end-to-end.  Session-60 runner re-runs at **165/166\nPASS** (T9878b \u2705; T17549 remains as the HFS+ mtime race).\n\n## 1. The actual change is ~3 lines plus a comment\n\n```c\n-   if (strcmp(lbl, \"__dso_handle\") == 0) {\n+   if (strcmp(lbl, \"__dso_handle\") == 0 ||\n+       strcmp(lbl, \"___dso_handle\") == 0) { /* Mach-O underscore prefix */\n```\n\nPlus a four-line update to `Note [Resolving __dso_handle]` explaining\nwhy both spellings are matched.  The proposal predicted \"two lines\";\nthe actual count is \"two if you count code only, six with the note\nupdate.\"  Trivially small.\n\n## 2. The OR variant beats the `#ifdef OBJFORMAT_MACHO` variant\n\nTwo equivalent fix shapes:\n\n(a) OR both spellings unconditionally:\n```c\nif (strcmp(lbl, \"__dso_handle\") == 0 ||\n    strcmp(lbl, \"___dso_handle\") == 0) { ... }\n```\n\n(b) Strip one leading underscore under `OBJFORMAT_MACHO` before strcmp:\n```c\nconst char *probe = lbl;\n#if defined(OBJFORMAT_MACHO)\n    if (probe[0] == '_') probe++;\n#endif\nif (strcmp(probe, \"_dso_handle\") == 0) { ... }\n```\n\nWent with (a) because (i) it's unconditional (no `#if` adds a\npreprocessor branch that platform-specific testing forgets to\ncover), (ii) it matches the existing `Linker.c` style of `strcmp(lbl,\n\"_FOO\") == 0 ||` chains, (iii) it would still work if a future\nMach-O variant ever drops the underscore prefix (vanishingly\nunlikely but harmless to handle), (iv) the cost is one extra strcmp\ncall per `lookupDependentSymbol` invocation, which is unmeasurable\nnext to the work that happens after the special case fires.\n\n## 3. Stage1 rebuild is fast \u2014 3.44 sec end-to-end\n\nOnly `rts/Linker.c` changed.  Hadrian's `Want\n_build/stage1/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`\nrecompiles `Linker.c` once, then re-archives + re-ranlibs all 10 RTS\nway archives (vanilla, thr, thr_p, thr_l, thr_debug, thr_debug_p,\ndebug, debug_p, l, p), then re-runs `cabal-copy` +\n`cabal-register`.  Total wall time 3.44 sec on a recent M-series\nMac.  A nice contrast with the 3m09s `binary-dist-dir` re-roll\nlater (which has to rebuild all the cabal profiling-way artefacts).\n\n## 4. Setting `$GHC` to the full path is load-bearing\n\nSourcing `scripts/cross-env.sh` is not sufficient \u2014 hadrian's\n`hadrian/build-cabal` wrapper invokes `cabal --with-compiler=$GHC`\nwith `GHC` defaulting to `ghc` (just the name).  On uranium, cabal\nis homebrew's 3.16 and looks for `ghc` via its own resolution path,\nwhich finds homebrew's ghc 9.14, which causes a hadrian-dep\nresolution failure (base-4.22 vs hashable's `base < 4.17`).\n\nSetting `GHC=$HOME/.local/ghc-9.2.8/bin/ghc` explicitly fixes it.\nThis wasn't documented in `cross-env.sh` or `deploy-stage2.sh` \u2014 the\nscript `deploy-stage2.sh` happens to work because its uses of `STAGE1`\nare full paths, not `ghc`-via-PATH lookups.  Recommended follow-up:\nadd `export GHC=$HOME/.local/ghc-9.2.8/bin/ghc` to\n`scripts/cross-env.sh` so it's set automatically when sourced.\n\n## 5. The \"verify the bindist's Linker.o has both spellings\" step is a useful sanity check\n\n```\n$ ar x bindist/lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a Linker.o\n$ strings Linker.o | grep dso_handle\n__dso_handle\n___dso_handle\n```\n\nA one-liner pre-tar sanity check that the bindist actually contains\nthe fix and didn't accidentally pick up a stale archive.  Worth\nrepeating on any future RTS-affecting patch.  The on-device follow-up\n(`ssh pmacg5 'strings /opt/ghc-stage2/bin/ghc-real | grep dso_handle'`)\nis the same check at the binary level.\n\n## 6. The \"165/166 PASS\" headline is exactly what the proposal predicted\n\nThe proposal said: \"target: 165/166 with only the HFS+ mtime race\nremaining.\"  Got exactly that.  No surprises, no further bugs\nsurfaced, no other tests flipped one way or the other.  T8042 (same\nHFS+ race shape as T17549) was the lucky-passes coin-flip this\nrun \u2014 session 60's run had it pass too; session 58/59 had it fail\nin different runs.  T17549 was the unlucky coin-flip; the inverse\nsometimes happens.\n\n## 7. The demo exercise revealed a small lesson about REPL scope\n\nWhen the demo's first iteration sent these commands directly:\n\n```\n:l /tmp/static-pointers.hs\ndeRefStaticPtr staticTrue\n```\n\n\u2026the `:l` succeeded (the v0.14.2 fix at work \u2014 pre-fix this would\nhave failed at `:l` time with the `___dso_handle` error) but\n`deRefStaticPtr` failed with \"Variable not in scope\".  GHCi `:l`\nbrings the loaded module's top-level bindings into scope but does\nnot import names from modules the loaded module imports\n(`GHC.StaticPtr` in this case).  `:m + GHC.StaticPtr` brings\n`deRefStaticPtr` into scope.\n\nThis is GHCi behaviour, not a v0.14.2 bug \u2014 same shape as needing\n`:m + Data.Map.Strict` after `:l` of a module that uses\n`Map.fromList`.  Mentioned only because the second-iteration demo\nadds the `:m + GHC.StaticPtr` line and explains why.\n\n## 8. v0.14.2 effort matched session 59's \"half a session\" estimate\n\nSession 60 HANDOFF predicted \"roughly half a session-59\" because no\ntestsuite re-debugging was needed.  Actual session-61 work breakdown:\n\n- Patch + source edit: ~10 min (read the existing code, decide\n  between OR vs `#ifdef`, write the patch).\n- Stage1 rebuild: 3.44 sec (after one false start with wrong GHC env var).\n- Stage2 deploy: ~30 sec.\n- Verification runner: ~7 min wall-clock (most of it on pmacg5).\n- Demo authoring + iteration: ~10 min.\n- Bindist re-roll: 3m09s.\n- Tar + sanity checks: ~1 min.\n- README/state/roadmap/demos-README updates: ~5 min.\n- Session docs (README/findings/HANDOFF/commits): ~10 min.\n- Commit + tag + push + gh release create: ~2 min.\n\nTotal: ~35 min for the load-bearing work plus ~15 min for documentation.\nSquarely \"half a session-59\" as predicted.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/HANDOFF.md",
  "content": "# Handoff from session 61 \u2192 session 62\n\n**For:** the next claude session.\n**From:** session 61 \u2014 **v0.14.2 released** end-to-end.  Two-line\n`__dso_handle` Mach-O underscore fix (patch 0017); stage1 rebuilt;\nstage2 redeployed; session-60 runner re-runs at **165/166 PASS**;\nbindist re-rolled; demo committed; release tag pushed + bindist\nuploaded.\n\n**Recommended pickup:** **harness work**.  v0.14.2 closes the last\ndeterministic failure in the 166-test T-prefix subset.  The\nremaining failure (T17549) is the HFS+ mtime-granularity race in\nupstream's `:reload` script \u2014 fixing it would require touching\nupstream's test script, not GHC, and is not a PPC bug.  Forward\npriorities live in [session 60 HANDOFF's \"second\" section](../2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md#second-extend-the-runner-to-handle-more-annotations) (extending the runner\nto handle more annotations) or session 59 HANDOFF's priorities\n2-onwards (the open exploratory work).\n\n## \u2705 SESSION EXIT STATE\n\n* `external/ghc-modern/ghc-9.2.8/rts/Linker.c` \u2014 two strcmps in the\n  `__dso_handle` special case, plus a four-line Note update.\n* `patches/0017-rts-dso-handle-mach-o-underscore.patch` \u2014 the patch.\n* `demos/v0.14.2-static-pointers.hs` \u2014 `StaticPtr` demo module.\n* `demos/v0.14.2-static-pointers.sh` \u2014 driver.\n* `demos/README.md` \u2014 header bumped to v0.14.2; new row in the\n  per-release table.\n* `README.md` \u2014 Latest-release paragraph, GHCi REPL row, Releases\n  table row, Layout patches-count all updated.\n* `docs/state.md` \u2014 top entry bumped to session 61.\n* `docs/roadmap.md` \u2014 \u00a7C session 61 entry added; last-reviewed date\n  bumped.\n* `docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/{README,findings,HANDOFF,commits}.md`\n  \u2014 session notes.\n* `docs/sessions/.../scripts/{run-ghci-tnum.sh,normalise.py}` \u2014\n  byte-identical copies of session 60's runner artefacts\n  (unchanged; the runner was verification, not change-under-test).\n* `docs/sessions/.../logs/` \u2014 five logs covering rebuild, deploy,\n  test re-run, demo run, bindist re-roll.\n\nOn pmacg5: `/opt/ghc-stage2/` is the v0.14.2 stage2.  Its\n`ghc-real` contains both `__dso_handle` and `___dso_handle` strings\nin its compiled-in Linker.c text segment.  Verified end-to-end via\nthe v0.14.2 demo.\n\nOn origin: `v0.14.2` annotated tag pushed; bindist tarball uploaded\nto the [v0.14.2 GitHub release](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2).\n\n## TL;DR \u2014 the session-61 work\n\nThree-line C code change (plus a four-line comment), one tiny\npatch file, one stage1 rebuild (~3.4 sec), one stage2 deploy\n(~30 sec), one runner re-run (165/166 PASS), one demo\nauthored + tested, one bindist re-roll (~3m09s), one tag push +\ngh release upload, one round of README / state / roadmap / demos\nupdates.  No surprises, no new bugs surfaced \u2014 the proposal's\n\"two-line fix \u2192 165/166\" prediction landed exactly.\n\n## What to try next, in priority order\n\n### Top: extend the runner to handle more annotations\n\nSession 60 HANDOFF's \"second\" priority is still the cleanest\nforward direction.  In order of likely-value:\n\n- `extra_hc_opts` tests (T2452, T2182ghci2, T9293, T13385, T14342,\n  T16563) \u2014 thread compiler flags through.  Same harness shape as\n  session 60's `extra_run_opts` extension but `$opts` is appended\n  to the *compilation* line.  In practice, since we use `ghc\n  --interactive` (compile and run in one invocation), the wiring\n  is identical to session 60's: just add cases to `run_opts_for`.\n  ~6 more tests.\n- `reqlib` tests (T5979 \u2014 needs `transformers`).  ~1 more test, but\n  requires `cabal-cross` to first verify the lib is in the stage2\n  ghc-pkg's package.conf.d.\n- `pre_cmd` tests (T5975a/b, T6106, T19650) \u2014 needs a Makefile or\n  shell prelude.  ~4 more tests.  Harder than the others; each\n  pre_cmd is bespoke.\n\n### Second + onwards\n\nThe session 59 HANDOFF's optional/exploratory list still applies:\nbug-numbered T<num>/ subdirs, prog001..prog019, GHCi over a real\nssh tty, extend debugger runner, stage2 native-compile sweep,\npatch 0016 refactor, third-party lib audit.\n\n### Possibly: propose patch 0017 upstream\n\nThe fix is upstream-shaped \u2014 any Mach-O cross-GHC where the host\ndoesn't have a live dyld exporting `___dso_handle` (which is the\nnormal Mach-O state \u2014 the symbol is provided at link time by\n`dylib1.o`/`crt1.o`, not at run time) would hit the same bug.\nWorth a GHC GitLab MR once we want to do upstream work.  Same\npattern as patch 0016 (`STUArray Bool` \u2014 found locally, applicable\nupstream).\n\n## What NOT to redo\n\n* **Don't re-run session-60's runner against v0.14.2 expecting\n  different numbers.**  T17549 is non-deterministic (HFS+ mtime\n  race); T8042 same family but lucky this run (and session 60's).\n  The 165/166 with T17549 as the FAIL is the steady state.\n* **Don't try the `#ifdef OBJFORMAT_MACHO` variant** of the patch\n  thinking it's \"cleaner\".  The OR variant is what shipped; both\n  are functionally equivalent and the unconditional OR matches the\n  rest of `lookupDependentSymbol`'s style.\n* **Don't forget `export GHC=...`** when re-running hadrian.\n  Source `cross-env.sh` AND `export GHC=$HOME/.local/ghc-9.2.8/bin/ghc`,\n  or hadrian's cabal dispatch will pick up homebrew's ghc-9.14 and\n  fail dep resolution.  (Recommended follow-up: bake this into\n  `cross-env.sh`.)\n\n## Hosts (unchanged from session 60)\n\n* **uranium**: source edits, harness scripts, hadrian builds,\n  bindist re-roll, cross-builds.\n* **pmacg5**: runs the ppc stage2 ghc binary.\n  `/opt/ghc-stage2/bin/ghc-real` is now the v0.14.2 binary (~199 MB).\n* **indium**: medium-tolerance VM, not used this session.\n\n## Paste-into-fresh-session prompt\n\n```\nContext: session 61 of the ghc-darwin8-ppc project executed session\n60's v0.14.2 release sketch.  Two-line C change in\n`rts/Linker.c::lookupDependentSymbol` matches both the ELF spelling\n`__dso_handle` and the Mach-O spelling `___dso_handle` for the\nsynthetic-handle special case.  Patch 0017 added; stage1 rebuilt\nin 3.4 sec; stage2 re-cross-built + deployed to pmacg5; bindist\nre-rolled in 3m09s; tarball + tag pushed to the v0.14.2 GitHub\nrelease.  Session-60 runner re-runs at 165/166 PASS (T9878b \u2705;\nonly T17549's HFS+ mtime race remains).  Demo at\n`demos/v0.14.2-static-pointers.{hs,sh}`.  No other source changes.\n\nTop next move: pick from session 60 HANDOFF's \"second\" list\n(extend the runner to handle more annotations: `extra_hc_opts` is\nthe easiest next group).  Or shift to one of session 59 HANDOFF's\nexploratory items.\n\nRead in order:\n1. docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/HANDOFF.md\n2. docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/README.md\n3. docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/findings.md\n4. docs/sessions/2026-05-17-session-60-extra-run-opts-runner/HANDOFF.md (for the priority list)\n5. docs/roadmap.md (for the broader priority list)\n\nHosts: uranium for source edits + cross-builds; pmacg5 for runs.\n\nUnsupervised mode is project default.\n```\n\n## Memory aide\n\nWhen session 62 ends, write the next handoff at:\n`docs/sessions/<DATE>-session-62-<slug>/HANDOFF.md`.\n"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/commits.md",
  "content": "# Session 61 commits\n\n| SHA | Subject |\n|---|---|\n| `(this commit)` | v0.14.2: rts/Linker.c match Mach-O ___dso_handle spelling. |\n\n`v0.14.2` annotated tag pointing at the session-61 commit \u2014 pushed\nto origin.\n\n## Releases (live)\n\n- **[v0.14.2](https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2)**\n  \u2014 committed + tagged + pushed + released this session.  Bindist\n  tarball asset: `ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz`\n  (~211 MB), re-rolled from the patched stage1.  The shipped\n  `lib/ppc-osx-ghc-9.2.8/rts-1.0.2/libHSrts-1.0.2.a`'s `Linker.o`\n  contains both `__dso_handle` and `___dso_handle` strings.\n\n## Release recipe (recorded in session 59 for reference)\n\n```\ngit commit -m \"vX.Y.Z: <one-line subject>.\" \u2026\ngit tag -a vX.Y.Z -F <commit-message>\ngit push origin main\ngit push origin vX.Y.Z\ngh release create vX.Y.Z \\\n  external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz \\\n  --title \"vX.Y.Z \u2014 <emoji headline>\" \\\n  --notes-file <release-notes>\n```\n\n## Stage2 native bindist (not shipped this release)\n\n`ghc-9.2.8-stage2-native-ppc-darwin8.tar.xz` (which v0.13.0 shipped\nas a secondary asset) was not regenerated for v0.14.2.  The\ndeployed stage2 on pmacg5 at `/opt/ghc-stage2/` reflects the\nv0.14.2 state and can be re-tarred from there if needed.\n"
}


---

## 🤖 Claude

Now write the release notes, then commit + tag + push + release.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cd /Users/cell/claude/ghc-darwin8-ppc && git status -s 2>&1 | head -40",
  "description": "Confirm full set of changed files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git check-ignore external/ghc-modern/ghc-9.2.8/rts/Linker.c && echo \"ignored\" || echo \"tracked\"",
  "description": "Verify ghc source tree is gitignored"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "gh release view v0.14.1 --json body --jq .body 2>&1 | head -40",
  "description": "Inspect v0.14.1 release notes for format"
}


---

## 🤖 Claude


🔧 Using tool: Write
Input: {
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/release-notes.md",
  "content": "# v0.14.2 \u2014 StaticPointers + GHCi `-fobject-code` work on PPC/Tiger \ud83e\ude84\n\nThe v0.14.1 (and every prior) bindist's runtime Mach-O loader failed to resolve `___dso_handle` whenever GHCi loaded a `.o` containing a `static` pointer.  `:l Foo.hs` in `ghc --interactive -fobject-code` mode aborted with:\n\n```\nlookupSymbol failed in resolveImports\n/tmp/.../Foo.o: unknown symbol `___dso_handle'\n```\n\n[Session 60](https://github.com/cellularmitosis/ghc-darwin8-ppc/tree/main/docs/sessions/2026-05-17-session-60-extra-run-opts-runner) surfaced this via T9878b in the extended ghci-tnum runner.  The fix is two lines.\n\n## Root cause\n\n`rts/Linker.c::lookupDependentSymbol` has a special case for `__dso_handle` (see `Note [Resolving __dso_handle]`, upstream #20493) that hands the dependent object's image address back as a synthetic handle.  The strcmp was written for ELF, where the symbol arrives with two leading underscores:\n\n```c\nif (strcmp(lbl, \"__dso_handle\") == 0) {\n    if (dependent) return dependent->image;\n    else           return &lookupDependentSymbol;\n}\n```\n\nMach-O preserves the platform's leading-underscore symbol-name convention.  Our PPC Mach-O loader populates `macho_symbols[i].name` directly from the object's string table (`rts/linker/MachO.c:137-138`), so what arrives at `lookupDependentSymbol` is `\"___dso_handle\"` \u2014 three underscores \u2014 and the strcmp misses.  Resolution falls through to `dlsym(lbl + 1)`, which on Tiger also fails because `___dso_handle` is provided at link time by `dylib1.o`/`crt1.o` and isn't exported into the runtime dyld namespace.\n\nThe bug only fires when GHCi compiles + loads a `.o` containing `static` pointers \u2014 the StaticPointers SPT init machinery emits a call to `__cxa_atexit(_, _, __dso_handle)` so SPT entries can be unregistered on shutdown, and the resulting `.o` has an undefined external for `___dso_handle`.\n\n## What changed\n\n[`patches/0017-rts-dso-handle-mach-o-underscore.patch`](https://github.com/cellularmitosis/ghc-darwin8-ppc/blob/v0.14.2/patches/0017-rts-dso-handle-mach-o-underscore.patch) \u2014 match both spellings:\n\n```c\n/* See Note [Resolving __dso_handle] */\n-if (strcmp(lbl, \"__dso_handle\") == 0) {\n+if (strcmp(lbl, \"__dso_handle\") == 0 ||\n+    strcmp(lbl, \"___dso_handle\") == 0) { /* Mach-O underscore prefix */\n     if (dependent) return dependent->image;\n     else           return &lookupDependentSymbol;\n}\n```\n\nPlus a four-line update to `Note [Resolving __dso_handle]` documenting why both spellings are matched.  Same semantics on ELF and Mach-O \u2014 the loader hands the dependent object's image back either way; only the spelling at lookup time differs.\n\n## Verification\n\nAfter re-rolling the bindist with the patched stage1, [session 60's runner](https://github.com/cellularmitosis/ghc-darwin8-ppc/blob/v0.14.2/docs/sessions/2026-05-17-session-60-extra-run-opts-runner/scripts/run-ghci-tnum.sh) re-ran against the new bindist:\n\n```\nPASS  T9878b           (rc=0)\nPASS  T12091           (rc=0)\nPASS  T17500           (rc=0)\nFAIL  T17549           (rc=0)  stderr mismatch\n=== Summary: 165 PASS / 1 FAIL out of 166 tests ===\n```\n\n**T9878b flipped to PASS** \u2705 \u2014 the load path that surfaced the bug in session 60 now works.  T17549 remains as the HFS+ 1-second mtime-granularity race in upstream's `:reload` test script (writeFile X \u2192 :load X \u2192 writeFile X \u2192 :reload skips the reload when both writeFiles land in the same second; T1914 has the same shape but explicitly bumps mtimes with `:! touch -t`; T17549 was authored later and omitted that touch).  Not a PPC bug.\n\nThe deployed `ghc-real` and its compiled-in Linker.c text segment now contain both spellings:\n\n```\n$ ssh pmacg5 'strings /opt/ghc-stage2/bin/ghc-real | grep -F dso_handle | sort -u'\n___dso_handle\n__dso_handle\n```\n\n## Demo\n\n[`demos/v0.14.2-static-pointers.{hs,sh}`](https://github.com/cellularmitosis/ghc-darwin8-ppc/blob/v0.14.2/demos/v0.14.2-static-pointers.sh) \u2014 a module with four `static` pointers of different shapes (Bool value, String value, `Int -> Int` closure, `[Int] -> Int` closure).  The driver:\n\n0. `strings /opt/ghc-stage2/bin/ghc-real | grep -F dso_handle` \u2014 confirms the deployed binary contains both spellings.\n1. `scp`s the `.hs` to pmacg5.\n2. Native compile + run \u2014 prints all four `deRefStaticPtr` results.\n3. `:load`s the module into `ghc --interactive -fobject-code` (the path that was broken pre-v0.14.2), brings `GHC.StaticPtr` into REPL scope with `:m +`, exercises `deRefStaticPtr` on each pointer, then runs `main`.\n\n```\n==> 0. confirm v0.14.2 ghc-real has both __dso_handle spellings\n___dso_handle\n__dso_handle\n\n==> 2. compile + run natively\ndeRefStaticPtr round-trip:\n  static True               = True\n  static \"v0.14.2 ...\"      = v0.14.2 static-pointer demo on PPC/Tiger\n  static (\\x -> x+x) $ 21   = 42\n  static sum $ [1..10]      = 55\n\n==> 3. :load the module into GHCi -fobject-code (the v0.14.2 path)\nGHCi, version 9.2.8: https://www.haskell.org/ghc/  :? for help\nghci> Ok, one module loaded.\nghci> ghci> True\nghci> \"v0.14.2 static-pointer demo on PPC/Tiger\"\nghci> 42\nghci> 55\nghci> deRefStaticPtr round-trip:\n  static True               = True\n  static \"v0.14.2 ...\"      = v0.14.2 static-pointer demo on PPC/Tiger\n  static (\\x -> x+x) $ 21   = 42\n  static sum $ [1..10]      = 55\nStaticPointers work on PPC/Tiger.\n```\n\n## Upstream contribution opportunity\n\nThe strcmp limitation affects any Mach-O cross-GHC where the host doesn't have a live `dyld` exporting `___dso_handle` (which is the normal Mach-O state \u2014 the symbol is provided at link time by `dylib1.o`/`crt1.o`, not at run time).  Patch 0017 is upstream-shaped: applying it to current GHC's `rts/Linker.c` would help any future Mach-O cross-build.\n\n## Install\n\n```\n$ tar xJf ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz\n$ cd ghc-9.2.8-powerpc-apple-darwin8/\n$ ./install.sh --prefix=$HOME/.local/ghc-darwin8-ppc \\\n               --ppc-host=<your-tiger-ssh-alias>\n```\n\n## Session\n\n[`docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/`](https://github.com/cellularmitosis/ghc-darwin8-ppc/tree/main/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle).\n\n\ud83e\udd16 Generated with [Claude Code](https://claude.com/claude-code).\n"
}


---

## 🤖 Claude

Now to commit, tag, push, and create the GitHub release. I'll add the specific paths.

---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add README.md demos/README.md demos/v0.14.2-static-pointers.hs demos/v0.14.2-static-pointers.sh docs/roadmap.md docs/state.md docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/ patches/0017-rts-dso-handle-mach-o-underscore.patch && git status -s 2>&1 | head -25",
  "description": "Stage v0.14.2 commit files"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "du -sh docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/logs/ghci-tnum 2>&1 && find docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/logs/ghci-tnum -type f 2>&1 | wc -l && echo \"---\" && ls docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/ 2>&1 | head",
  "description": "Sanity check log size vs session 60's footprint"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "du -sh docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/ghci-tnum 2>&1 && find docs/sessions/2026-05-17-session-60-extra-run-opts-runner/logs/ghci-tnum -type f 2>&1 | wc -l",
  "description": "Compare with session 60's logs footprint"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git diff --staged --shortstat 2>&1 | head -3",
  "description": "Shortstat of staged changes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "cat > /tmp/v0.14.2-commit-msg <<'EOF'\nv0.14.2: rts/Linker.c match Mach-O ___dso_handle spelling.\n\nTwo-line C fix to the runtime Mach-O loader's __dso_handle special\ncase.  Pre-fix, rts/Linker.c::lookupDependentSymbol strcmp'd against\nthe ELF spelling \"__dso_handle\"; the Mach-O loader passes the\nunderscore-prefixed \"___dso_handle\" straight from the object's\nstring table, so the special case missed.  Fallthrough to dlsym\nalso fails on Tiger (___dso_handle is provided at link time by\ndylib1.o / crt1.o, not exported into the runtime dyld namespace).\nSurfaced by session 60's extended ghci-tnum runner on T9878b\n(GHCi -fobject-code + StaticPointers).\n\nReleased as v0.14.2.  Session 60 runner re-runs at 165/166 PASS\n(T9878b \u2705; only T17549's HFS+ mtime race remains).  Patch 0017\nadded; stage1 rebuilt (3.4 sec); stage2 redeployed to pmacg5;\nbindist re-rolled (~211 MB).  Demo at\ndemos/v0.14.2-static-pointers.{hs,sh}.\n\nSee docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\ngit commit -F /tmp/v0.14.2-commit-msg 2>&1 | tail -10",
  "description": "Commit v0.14.2 changes"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git log --oneline -1 && SHA=$(git rev-parse HEAD) && echo \"SHA=$SHA\" && git tag -a v0.14.2 -F /tmp/v0.14.2-commit-msg $SHA && git tag -l v0.14.2 -n3",
  "description": "Tag v0.14.2 at the commit"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git push origin main 2>&1 | tail -5 && echo \"---\" && git push origin v0.14.2 2>&1 | tail -5",
  "description": "Push main + tag to origin",
  "timeout": 120000
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "gh release create v0.14.2 \\\n  external/ghc-modern/ghc-9.2.8/_build/bindist/ghc-9.2.8-stage1-cross-to-ppc-darwin8.tar.xz \\\n  --title \"v0.14.2 \u2014 StaticPointers + GHCi -fobject-code work on Tiger \ud83e\ude84\" \\\n  --notes-file docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/release-notes.md 2>&1 | tail -5",
  "description": "Create v0.14.2 GitHub release with bindist asset",
  "timeout": 600000
}


---

## 🤖 Claude

Release is up. Now backfill the SHA into commits.md.

---

## 🤖 Claude


🔧 Using tool: Edit
Input: {
  "replace_all": false,
  "file_path": "/Users/cell/claude/ghc-darwin8-ppc/docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/commits.md",
  "old_string": "| SHA | Subject |\n|---|---|\n| `(this commit)` | v0.14.2: rts/Linker.c match Mach-O ___dso_handle spelling. |",
  "new_string": "| SHA | Subject |\n|---|---|\n| `d09c4ba` | v0.14.2: rts/Linker.c match Mach-O ___dso_handle spelling. |\n| `(this commit)` | Session 61 commits.md: backfill the v0.14.2 SHA. |"
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "git add docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/commits.md && git commit -m \"$(cat <<'EOF'\nSession 61 commits.md: backfill the v0.14.2 SHA.\n\nCo-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>\nEOF\n)\" 2>&1 | tail -3 && git push origin main 2>&1 | tail -3",
  "description": "Backfill commits.md and push",
  "timeout": 120000
}


---

## 🤖 Claude


🔧 Using tool: TodoWrite
Input: {
  "todos": [
    {
      "content": "Read rts/Linker.c context around dso_handle and craft patch 0017",
      "activeForm": "Reading rts/Linker.c and crafting patch 0017",
      "status": "completed"
    },
    {
      "content": "Create session 61 directory and scaffolding",
      "activeForm": "Creating session 61 directory",
      "status": "completed"
    },
    {
      "content": "Apply source edit, rebuild stage1",
      "activeForm": "Applying source edit and rebuilding stage1",
      "status": "completed"
    },
    {
      "content": "Generate patches/0017-...patch from source diff",
      "activeForm": "Generating patches/0017 from source diff",
      "status": "completed"
    },
    {
      "content": "Run deploy-stage2.sh pmacg5 to redeploy stage2",
      "activeForm": "Running deploy-stage2.sh pmacg5",
      "status": "completed"
    },
    {
      "content": "Re-run session 60 runner \u2014 verify T9878b PASSes (165/166 target)",
      "activeForm": "Re-running session 60 runner",
      "status": "completed"
    },
    {
      "content": "Test the v0.14.2 demo on pmacg5",
      "activeForm": "Testing v0.14.2 demo on pmacg5",
      "status": "completed"
    },
    {
      "content": "Re-roll bindist tarball",
      "activeForm": "Rolling new bindist tarball",
      "status": "completed"
    },
    {
      "content": "Update README, docs/state.md, docs/roadmap.md, demos/README.md",
      "activeForm": "Updating top-level docs",
      "status": "completed"
    },
    {
      "content": "Write session 61 README, findings, commits scaffold, HANDOFF",
      "activeForm": "Writing session 61 docs",
      "status": "completed"
    },
    {
      "content": "Commit, tag v0.14.2, push, gh release create with bindist asset",
      "activeForm": "Committing, tagging, pushing, releasing v0.14.2",
      "status": "completed"
    },
    {
      "content": "Backfill commits.md with the v0.14.2 SHA",
      "activeForm": "Backfilling commits.md with the v0.14.2 SHA",
      "status": "completed"
    }
  ]
}


---

## 🤖 Claude


🔧 Using tool: Bash
Input: {
  "command": "gh release view v0.14.2 --json url,assets --jq '.url, .assets[].name' 2>&1",
  "description": "Confirm GitHub release + asset"
}


---

## 🤖 Claude

v0.14.2 is shipped end-to-end:

- **Patch 0017** ([patches/0017-rts-dso-handle-mach-o-underscore.patch](patches/0017-rts-dso-handle-mach-o-underscore.patch)) — two-line C fix to `rts/Linker.c::lookupDependentSymbol` matching both `__dso_handle` and `___dso_handle`.
- **Stage1 rebuilt** (~3.4 sec), **stage2 redeployed** to pmacg5, **bindist re-rolled** (~3m09s, 211 MB tarball).
- **Verification**: session 60's runner re-ran at **165/166 PASS** — T9878b flipped to PASS ✅; only T17549's HFS+ mtime race remains (not a PPC bug). Logged at [docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/logs/03-ghci-tnum-rerun.log](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/logs/03-ghci-tnum-rerun.log).
- **Demo** at [demos/v0.14.2-static-pointers.{hs,sh}](demos/v0.14.2-static-pointers.sh) — exercises four `static` pointers under native compile and the GHCi `-fobject-code` load path that was broken pre-v0.14.2.
- **Release**: https://github.com/cellularmitosis/ghc-darwin8-ppc/releases/tag/v0.14.2 — tag pushed, bindist uploaded, notes from [release-notes.md](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/release-notes.md).
- **Docs**: README "Latest release", GHCi REPL row, Releases table, Layout 16→17 patches; [docs/state.md](docs/state.md), [docs/roadmap.md](docs/roadmap.md), [demos/README.md](demos/README.md) all updated. Session 61 narrative + findings + HANDOFF in [docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/).

Next session HANDOFF lives at [docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/HANDOFF.md](docs/sessions/2026-05-17-session-61-v0.14.2-dso-handle/HANDOFF.md) — recommended pickup is the `extra_hc_opts` runner extension (six more tests, same shape as session 60's `extra_run_opts` work).

---

