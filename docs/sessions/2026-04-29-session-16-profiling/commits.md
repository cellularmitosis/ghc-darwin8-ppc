# Session 16 commits

| SHA | Description |
|-----|-------------|
| d5ad7b8 | Session 16: profiling builds work on Tiger (v0.10.0). |

Picks up LLVM-7 r4 from the sister project, re-enables
`libraryWays = [vanilla, profiling]` in QuickCross, and adds two
Tiger compatibility shims (`__MAC_OS_X_VERSION_MIN_REQUIRED` macro
definition, `tiger_strnlen` inline) for symbols the profiling RTS
references that don't exist on 10.4u.
