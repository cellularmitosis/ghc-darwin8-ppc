# Session 15 — TLS/HTTPS via tiger.sh's openssl (v0.9.0)

**Date:** 2026-04-29.
**Goal:** real HTTPS GET from a Haskell program running on Tiger.
**Outcome:** ✅ Done.  `https-get` cabal-example connects to
example.com:443, completes a TLS handshake against an OpenSSL
1.1.1t install (provided by `tiger.sh`), sends `GET /`, and
prints back Cloudflare's `HTTP/1.1 200 OK` response.

## What we built on

- `tiger.sh` ships `openssl-1.1.1t` to `/opt/openssl-1.1.1t/` on Tiger
  (libcrypto.dylib + libssl.dylib + headers).
- v0.8.1's vendored `network-3.x` provides modern socket bindings.

## What we vendored

`vendor/HsOpenSSL/` — Hackage's `HsOpenSSL-0.11.7.10`, with one
small patch:

- All three `runInBoundThread $ ...` sites in
  `OpenSSL/Session.hsc` (`sslTryHandshake`, the unnamed one in
  `sslIOInner`, and `tryShutdown`) replaced with
  `runInBoundThreadOrJustHere`, a local wrapper that falls back to
  running the action in the current thread when the RTS doesn't
  support bound threads.

  Why we need this: HsOpenSSL uses `runInBoundThread` to ensure
  OpenSSL sees the same OS thread for the entire handshake.  But on
  PPC32-darwin8 our threaded RTS won't link — gcc14's libgcc is
  missing the `__atomic_*_8` intrinsics that the threaded RTS uses
  for `tryWakeupThread` / `throwToMsg` / `STM` / etc.  Without the
  threaded RTS, `runInBoundThread` is hard-wired to error.
  On a single-OS-thread RTS, the same-thread invariant is trivially
  satisfied, so the fallback is safe.

See [`vendor/HsOpenSSL/TIGER-PATCHES.md`](../../../vendor/HsOpenSSL/TIGER-PATCHES.md).

## Cross-build glue

`tests/cabal-examples/run-one.sh`:
- New `OPENSSL_PREFIX` env var.  When set, passed as
  `--extra-include-dirs=$OPENSSL_PREFIX/include` and
  `--extra-lib-dirs=$OPENSSL_PREFIX/lib` to cabal.
- `DYLD_LIBRARY_PATH` on Tiger now includes
  `/opt/openssl-1.1.1t/lib` so `libssl.1.1.dylib`,
  `libcrypto.1.1.dylib` are found at runtime (in addition to
  `/opt/gmp-6.2.1/lib` and `/opt/gcc14/lib`).

For uranium-side cross-builds, before running cabal, mirror the
Tiger openssl install to the host so cabal can find headers/libs:

```
ssh pmacg5 'tar -czf /tmp/openssl-1.1.1t.tar.gz -C /opt openssl-1.1.1t'
scp pmacg5:/tmp/openssl-1.1.1t.tar.gz /tmp/
mkdir /tmp/ssl-mirror && tar -xzf /tmp/openssl-1.1.1t.tar.gz -C /tmp/ssl-mirror
export OPENSSL_PREFIX=/tmp/ssl-mirror/openssl-1.1.1t
```

Then `tests/cabal-examples/run-one.sh https-get` builds and runs.

## Verified

```
$ OPENSSL_PREFIX=/tmp/ssl-mirror/openssl-1.1.1t \
    tests/cabal-examples/run-one.sh https-get
== Running …/https-get on pmacg5 ==
TRACE: creating SSL context
TRACE: wrapping in SSL
TRACE: ssl connect (handshake)
TRACE: TLS handshake complete!
first 512 bytes:
HTTP/1.1 200 OK
Date: Wed, 29 Apr 2026 09:58:34 GMT
Content-Type: text/html
Connection: close
Server: cloudflare
…
<!doctype html><html lang="en"><head><title>Example Domain</title>…
```

This exercises (running natively on PowerMac G5):
- TCP socket → `getAddrInfo` IPv4 → `connect`
- OpenSSL context creation, SNI (`setTlsextHostName`), handshake
- TLS read + write
- Connection shutdown
- Cloudflare's TLS 1.x server validating us, sending real HTML back.

## Threaded RTS limitation (deferred)

The PPC32 threaded RTS won't link because gcc14's libgcc on Tiger
lacks `__atomic_load_8`, `__atomic_store_8`, etc.  Same family as
the `_hs_xchg64` issue we patched in 2026-04-22 (now patch 0007).

For most uses this is fine — the non-threaded RTS supports unbounded
forkIO concurrency, and HsOpenSSL works with the runInBoundThread
patch.  Programs that really need OS-thread parallelism (servers
with thread pools, etc.) would need either:

1. Soft-float-style helpers for 8-byte atomics in our RTS.
2. SMP rebuild of the threaded RTS using libatomic.
3. Tiger compatibility shim emulating `__atomic_*_8` via a global lock.

Not blocking; deferred.

## What's left in the network/TLS space

✅ Plain `network` 3.x (v0.8.1).
✅ TLS handshake / HTTPS GET via HsOpenSSL (this session, v0.9.0).
- `http-client` / `wreq` / `req` for higher-level HTTP API.  These
  layer on top of `connection` / `tls` / `HsOpenSSL`.  Should "just
  work" on top of what we have, modulo possibly more
  `runInBoundThread` issues.  Future session.
- TLS server (accept + handshake).  Same patch surface; not yet
  tested.
