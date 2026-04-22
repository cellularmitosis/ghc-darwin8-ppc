# 001 — Does the prebuilt GHC 7.0.4 .pkg run on Tiger?

## Hypothesis

The krabby `GHC-7.0.4-powerpc.pkg` from
<https://downloads.haskell.org/~ghc/7.0-latest/krabby/> (2011) will
install and run on Tiger 10.4.11 / PPC G5 after working around the
known libiconv ABI mismatch
([`notes/iconv-abi-mismatch.md`](../notes/iconv-abi-mismatch.md))
by setting `DYLD_LIBRARY_PATH=/opt/libiconv-1.16/lib`.

If yes, Path A phase 1 is trivially unblocked.

## Method

1. `pkgutil --expand` the .pkg on the main Mac (arm64 macOS 15).
2. `gunzip -c ghc.pkg/Payload | cpio -id` to extract the
   `GHC.framework/` directory tree.
3. `tar -cf /tmp/ghc-7.0.4-framework.tar GHC.framework` — 736 MB.
4. `tiger-rsync.sh` the tar to `pmacg5:/tmp/`.
5. On `pmacg5`: `sudo tar -C /Library/Frameworks -xf /tmp/ghc-7.0.4-framework.tar`
   — the target layout of the .pkg postinstall.
6. Write `/usr/local/bin/ghc-7.0.4` (and ghci, ghc-pkg, …) as a
   wrapper script that sets `DYLD_LIBRARY_PATH=/opt/libiconv-1.16/lib`
   before exec'ing the real binary.
7. Run `ghc-7.0.4 --version`.

Full automation script:
[`scripts/install-ghc-704-on-tiger.sh`](../../scripts/install-ghc-704-on-tiger.sh).

## Result

**Failure.** Two distinct problems encountered.

### Problem 1: `DYLD_FALLBACK_LIBRARY_PATH` does not work

First pass used `DYLD_FALLBACK_LIBRARY_PATH`. dyld emitted:

```
dyld: Library not loaded: /usr/lib/libiconv.2.dylib
  Referenced from: .../ghc-7.0.4-powerpc/usr/lib/ghc-7.0.4/ghc
  Reason: Incompatible library version: ghc requires version 7.0.0
          or later, but libiconv.2.dylib provides version 5.0.0
```

**Diagnosis:** `DYLD_FALLBACK_LIBRARY_PATH` is consulted only when
the install-name path **does not exist**. Tiger does have
`/usr/lib/libiconv.2.dylib` — it's just the wrong ABI version
(compat 5.0.0 vs the required 7.0.0). dyld errors out before
FALLBACK kicks in.

**Fix:** switch the wrapper to `DYLD_LIBRARY_PATH`, which is
consulted **before** the install name. Confirmed loading now
picks up `/opt/libiconv-1.16/lib/libiconv.2.dylib` via
`DYLD_PRINT_LIBRARIES=1`:

```
dyld: loaded: /Library/Frameworks/GHC.framework/Versions/7.0.4-powerpc/usr/lib/ghc-7.0.4/ghc
dyld: loaded: /usr/lib/libncurses.5.4.dylib
dyld: loaded: /usr/lib/libSystem.B.dylib
dyld: loaded: /opt/libiconv-1.16/lib/libiconv.2.dylib   ← correct
dyld: loaded: /usr/lib/libgcc_s.1.dylib
dyld: loaded: /usr/lib/system/libmathCommon.A.dylib
```

Update: wrapper script in [`scripts/install-ghc-704-on-tiger.sh`](../../scripts/install-ghc-704-on-tiger.sh).

### Problem 2: `ghc` bus-errors in `_malloc_initialize` at startup

After the dyld fix, the binary loads all its libraries successfully
but crashes with `EXC_BAD_ACCESS / KERN_PROTECTION_FAILURE at 0x0`
during program init. Full stack trace from
`/Users/macuser/Library/Logs/CrashReporter/ghc.crash.log`:

```
Exception:  EXC_BAD_ACCESS (0x0001)
Codes:      KERN_PROTECTION_FAILURE (0x0002) at 0x00000000

Thread 0 Crashed:
0   libSystem.B.dylib  _malloc_initialize + 1016
1   libSystem.B.dylib  calloc + 52
2   ghc                stgCallocBytes + 32
3   ghc                setFullProgArgv + 56
4   ghc                hs_init + 112
5   ghc                startupHaskell + 40
6   ghc                real_main + 64
7   ghc                hs_main + 96
8   ghc                start + 68
```

The crash is inside `libSystem.B.dylib`'s `_malloc_initialize` —
so early in Haskell runtime init that we haven't even finished
parsing argv. The null-pointer deref is happening inside the
malloc-zone bring-up path of libSystem.

`otool -l` on the binary shows no `LC_VERSION_MIN_MACOSX` load
command — the binary doesn't advertise a minimum macOS version.
But the gdb warnings reveal build-tree paths under
`/Users/patriciajohnson/byron/ghc/7.0.4/` — so this is a build by
Patricia Johnson (haskell.org release manager circa 2011), and
the libiconv compat-7.0.0 dependency tells us it was built on
Snow Leopard or later. **This binary targets ≥ 10.5.**

Tiger's `_malloc_initialize` has a different internal layout than
Leopard's. A Snow-Leopard-built binary's static init code trips
over something that isn't there on Tiger. Not fixable without
rebuilding the binary.

### Sanity check: other binaries in the framework

Tried the smaller helpers:
- `ghc-pkg list` — **exit 0**. Output shows the shipped boot
  packages (base-4.3.1.0, containers-0.4.0.0, etc.). Works fine.
- `ghc --version`, `ghc --help`, `ghc --info` — exit 0 with no
  output (probably driver-level early-exit paths that don't run
  the Haskell runtime).
- `ghc --numeric-version`, `ghc -B<topdir> --version` — bus error
  (both trigger full `hs_init`).

So the RTS init is the failure surface, not dyld or the GHC
driver code paths that exit before RTS init.

### Cross-check: 6.10.4 bin-dist

The maeder `ghc-6.10.4-powerpc-apple-darwin.tar.bz2` is a standard
GHC binary-distribution tarball (with `configure`, `Makefile`,
etc.) — not a .pkg. On Tiger:

```
$ ./configure --prefix=/opt/ghc-6.10.4
checking build system type... powerpc-apple-darwin8.11.0
checking host system type... powerpc-apple-darwin8.11.0
...
checking for path to top of build tree... configure: error:
    cannot determine current directory
```

`configure` invokes `ghc-pwd` (a small pre-built helper in the
bin-dist) to print the cwd in a portable way, and `ghc-pwd`
fails. Inspecting the bin-dist: `otool -L ghc/dist-stage2/build/ghc/ghc`
shows the same `libiconv.2.dylib (compat 7.0.0)` dependency —
**6.10.4 is also a Leopard+ build.** Same class of problem as
7.0.4.

## Conclusion

**No prebuilt PPC/Darwin GHC binary on haskell.org runs on Tiger.**
All of them (6.10.4 maeder, 7.0.1 maeder, 7.0.4 krabby) appear to
have been built on Leopard-or-later hosts, and none of them have
a `LC_VERSION_MIN_MACOSX` tag but they do have libSystem init
code that doesn't match Tiger's layout. The libiconv ABI mismatch
was the visible red flag; the `_malloc_initialize` null-deref is
the same underlying problem one level deeper.

This **invalidates the original Path A Phase 1 plan** — we cannot
just install a prebuilt .pkg and move on. The two options from here:

### Option A' — use a Leopard host as the Path A launchpad

Install 7.0.4 on `mdd` or `pbookg42` (both Leopard 10.5.8), where
it should Just Work (libSystem matches, libiconv compat 7 is
system-supplied). Use that to build 7.6.3 there, where
barracuda156 confirmed it works. Then cross-compile a Tiger-native
GHC from Leopard (Leopard preserves the 10.4 userland, so binaries
built with `-mmacosx-version-min=10.4` should run on Tiger).

This is ~2 days of work if things go well, ~1 week if they don't.
The output is still a GHC 7.6.3 dead end (old `base`, no TH).

### Option B' — skip Path A, go directly to Path B

Cross-compile a modern GHC (9.2.x) for `powerpc-apple-darwin8`
from the main Mac (arm64 macOS 15) or a Linux host, starting
unregisterised per Trommler's recipe. This is what the plan
originally called Path B Phase 3, with no Path A intermediate.
Harder per-session, but the output is a useful modern Haskell
compiler, not a museum piece.

**Recommendation:** pursue **Option B'** (skip Path A). Path A's
intermediate value was "validate the build pipeline end-to-end
on Tiger in a week." That value is gone now — Path A as planned
is several weeks of Leopard-detour work, and the resulting 7.6.3
compiler is unusable for almost anything modern. Path B's
cross-toolchain work is what Trommler himself recommended up front;
we lost a day validating that the shortcut doesn't exist, but
we're back on the canonical path.

Plan and state.md updated to reflect the pivot. Original Path A
material stays in the docs as reference for anyone who wants to
try the Leopard detour later.

## Artefacts

- `external/ghc-7.0.4-powerpc-darwin.pkg` — source .pkg (164 MB, gitignored)
- `external/ghc-7.0.4-pkg-expanded/` — `pkgutil --expand` output (gitignored)
- `/tmp/ghc-7.0.4-framework.tar` — extracted framework tar (gitignored)
- `scripts/install-ghc-704-on-tiger.sh` — install script, kept as reference
  for the Leopard route and for anyone revisiting

## See also

- [`notes/iconv-abi-mismatch.md`](../notes/iconv-abi-mismatch.md)
- [`notes/ghc-704-pkg-anatomy.md`](../notes/ghc-704-pkg-anatomy.md)
- [`notes/bootstrap-chain.md`](../notes/bootstrap-chain.md)
