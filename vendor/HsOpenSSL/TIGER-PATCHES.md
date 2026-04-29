# vendor/HsOpenSSL — Tiger-friendly fork of `HsOpenSSL-0.11.7.10`

Upstream `HsOpenSSL` uses `runInBoundThread` in three places to
ensure OpenSSL sees the same OS thread for the duration of an
operation.  On PPC32-darwin8, the threaded RTS won't link
(gcc14's libgcc lacks the `__atomic_*_8` intrinsics that GHC's
threaded RTS needs), so `runInBoundThread` is hard-wired to error
out via `failNonThreaded`.

The fix is a 1-line wrapper:

```haskell
-- | Soft 'runInBoundThread' that falls back to running the action
-- in the current thread when the RTS doesn't support bound threads.
-- Safe for our use case: HsOpenSSL uses bound threads to ensure
-- OpenSSL sees the same OS thread; on a single-OS-thread RTS that
-- invariant is trivially satisfied.
runInBoundThreadOrJustHere :: IO a -> IO a
runInBoundThreadOrJustHere action
  | rtsSupportsBoundThreads = runInBoundThread action
  | otherwise               = action
```

Plus three replacements of `runInBoundThread $ …` →
`runInBoundThreadOrJustHere $ …` (in `sslTryHandshake`,
`sslIOInner`, `tryShutdown`).

Plus the import of `rtsSupportsBoundThreads` from
`Control.Concurrent`.

## Diff

```diff
--- HsOpenSSL-0.11.7.10/OpenSSL/Session.hsc
+++ vendor/HsOpenSSL/OpenSSL/Session.hsc
@@ -89 +89 @@
-import Control.Concurrent (threadWaitWrite, threadWaitRead, runInBoundThread)
+import Control.Concurrent (threadWaitWrite, threadWaitRead, runInBoundThread, rtsSupportsBoundThreads)
@@ -598 +598 @@ sslTryHandshake loc action ssl
-    = runInBoundThread $
+    = runInBoundThreadOrJustHere $
@@ -610,0 +611,16 @@
+
+-- ghc-darwin8-ppc: a softer 'runInBoundThread' that falls back to
+-- the current thread when the RTS does not support bound threads.
+runInBoundThreadOrJustHere :: IO a -> IO a
+runInBoundThreadOrJustHere action
+  | rtsSupportsBoundThreads = runInBoundThread action
+  | otherwise               = action
@@ -660 +660 @@
-    = runInBoundThread $
+    = runInBoundThreadOrJustHere $
@@ -780 +780 @@
-tryShutdown ssl ty = runInBoundThread $ withSSL ssl loop
+tryShutdown ssl ty = runInBoundThreadOrJustHere $ withSSL ssl loop
```

## Using this vendor copy

```
packages:
  .
  /path/to/ghc-darwin8-ppc/vendor/network/
  /path/to/ghc-darwin8-ppc/vendor/HsOpenSSL/
```

Then `cabal build` with:
```
--extra-include-dirs=/opt/openssl-1.1.1t/include
--extra-lib-dirs=/opt/openssl-1.1.1t/lib
```

(or via `tests/cabal-examples/run-one.sh`'s `OPENSSL_PREFIX` env var).

## Verified

A live HTTPS GET to example.com:443 from a Tiger PowerMac, returning
Cloudflare's `HTTP/1.1 200 OK` and the `<title>Example Domain</title>`
HTML body.  See `tests/cabal-examples/https-get/`.

## Tiger runtime requirements

- `/opt/openssl-1.1.1t/lib/libssl.1.1.dylib` and `libcrypto.1.1.dylib`.
  Both ship via the `tiger.sh` package helper:
  `tiger.sh openssl-1.1.1t install`.
- `/opt/gmp-6.2.1/lib/libgmp.dylib` (already required for
  ghc-darwin8-ppc).
- Standard Tiger libSystem / dyld.

`DYLD_LIBRARY_PATH` should include `/opt/openssl-1.1.1t/lib`.
