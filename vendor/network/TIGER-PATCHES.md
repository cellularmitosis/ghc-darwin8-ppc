# vendor/network — Tiger-friendly fork of `network-3.2.8.0`

Upstream `network-3.x` references two socket constants that don't
exist in the 10.4u SDK:

- `IP_RECVTOS` (added in macOS 10.7).
- `IPV6_TCLASS` (added in macOS 10.7).

These are referenced unconditionally inside
[`Network/Socket/Posix/Cmsg.hsc`](Network/Socket/Posix/Cmsg.hsc),
so even with autoconf saying "we don't have these features" the
preprocessor failed before any C code ran.

The fix is two `#if defined(...)` guards plus a sentinel fallback
identical to the one upstream already uses for `IP_PKTINFO`.

## Diff

```diff
 -- | The identifier for 'IPv4TOS'.
 pattern CmsgIdIPv4TOS :: CmsgId
-#if defined(darwin_HOST_OS) || defined(freebsd_HOST_OS)
+#if (defined(darwin_HOST_OS) || defined(freebsd_HOST_OS)) && defined(IP_RECVTOS)
 pattern CmsgIdIPv4TOS = CmsgId (#const IPPROTO_IP) (#const IP_RECVTOS)
-#else
+#elif defined(IP_TOS)
 pattern CmsgIdIPv4TOS = CmsgId (#const IPPROTO_IP) (#const IP_TOS)
+#else
+pattern CmsgIdIPv4TOS = CmsgId (-1) (-1)
 #endif

 -- | The identifier for 'IPv6TClass'.
 pattern CmsgIdIPv6TClass :: CmsgId
+#if defined(IPV6_TCLASS)
 pattern CmsgIdIPv6TClass = CmsgId (#const IPPROTO_IPV6) (#const IPV6_TCLASS)
+#else
+pattern CmsgIdIPv6TClass = CmsgId (-1) (-1)
+#endif
```

`SOCK_CLOEXEC` itself was a *non-issue* — upstream already gates it
behind `HAVE_ADVANCED_SOCKET_FLAGS`, which is itself gated by
`HAVE_ACCEPT4`, which our `scripts/tiger-config.site` correctly sets
to "no" for Tiger (accept4 is Linux-only since 2.6.28).  Cmsg.hsc
just got missed in upstream's portability sweep.

## Using this vendor copy

In your project's `cabal.project`:

```
packages:
  .
  /path/to/ghc-darwin8-ppc/vendor/splitmix/    -- if you also need random
  /path/to/ghc-darwin8-ppc/vendor/network/
```

Then `network-3.2.8.0` resolves to the vendored copy.  Cabal-cross
recipe in `docs/cabal-cross.md`.

## Verified

- Builds end-to-end via cabal cross-compile against our stage1 cross-ghc.
- A localhost TCP echo client/server (open + bind + listen + accept +
  send + recv + close) round-trips a "hello tiger" message on a real
  PowerMac G5 running Tiger 10.4.11.

## Functions affected by the sentinel

- `CmsgIdIPv4TOS` and `CmsgIdIPv6TClass` patterns now match
  `CmsgId (-1) (-1)` on Tiger.  Code that pattern-matches on these
  to receive TOS/TClass cmsgs will simply never fire — those features
  aren't supported on Tiger anyway.  Standard `socket`, `bind`, `listen`,
  `accept`, `connect`, `send`, `recv`, `close` all work normally.
