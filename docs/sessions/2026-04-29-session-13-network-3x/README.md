# Session 13 — vendor network-3.x for Tiger (v0.8.1)

**Date:** 2026-04-29.
**Starting state:** v0.8.0 shipped (TH end-to-end working).  The
remaining easy F-track items: network 3.x, profiling (deferred),
TLS / HTTPS.
**Goal:** vendor network-3.x with the right `#ifdef` guards so it
builds against the 10.4u SDK; verify a real socket round-trip on
Tiger.
**Ending state:** v0.8.1 released.  `vendor/network/` ships
network-3.2.8.0 with two-line `#ifdef` guards on `IP_RECVTOS` and
`IPV6_TCLASS`; smoke-tested via `tests/cabal-examples/network-echo-three/`
which opens a localhost TCP echo server, connects a client, exchanges
bytes, prints the echo.

## What we found

The session 7 README claimed network 3.x was blocked on
`SOCK_CLOEXEC` in `Cbits.hsc`.  That turned out to be **stale**:
upstream already gates `SOCK_CLOEXEC` behind `HAVE_ADVANCED_SOCKET_FLAGS`,
which is gated on `HAVE_ACCEPT4`, and our `scripts/tiger-config.site`
correctly tells autoconf "no accept4" for Tiger.  So that path is
clean.

The *actual* gap was in `Network/Socket/Posix/Cmsg.hsc`:
- `IP_RECVTOS` (line 62) — referenced unconditionally on darwin/freebsd.
- `IPV6_TCLASS` (line 69) — referenced unconditionally everywhere.

Both were added to macOS in 10.7.  Tiger's 10.4u SDK has neither.

## The fix

[`vendor/network/Network/Socket/Posix/Cmsg.hsc`](../../../vendor/network/Network/Socket/Posix/Cmsg.hsc):
add `#if defined(...)` guards plus a `(-1) (-1)` sentinel fallback,
mirroring the existing pattern used for `IP_PKTINFO` a few lines down.
4-line change, no semantic effect on platforms that have these
constants.

See [`vendor/network/TIGER-PATCHES.md`](../../../vendor/network/TIGER-PATCHES.md)
for the full diff.

## Verified

```
$ tests/cabal-examples/run-one.sh network-echo-three
== Building network-echo-three ==
Resolving dependencies...
Up to date

== Running …/network-echo-three on pmacg5 ==
server listening on port 54255
echo: hello tiger
```

This exercises (on real Tiger hardware):
- `getAddrInfo` IPv4 binding
- `socket` + `bind` + `listen` + `accept`
- `connect` from the same process via forkIO
- `Network.Socket.ByteString.{send,recv}All`
- ephemeral port allocation
- `close`

## Side fix to run-one.sh

When a vendored package ships its own `configure`, cabal will
generate a `config.status` shell script in `dist/build/<pkg>/build/`
that's also marked executable.  The old `find ... -perm -u+x` picked
*it* before the actual PPC binary.  Filter via `file ... Mach-O.*ppc`.

## What's left in the network space

- `network` 3.x ✅ now works (this session, v0.8.1).
- TLS / HTTPS — needs Tiger-compatible `openssl`.  Not yet attempted;
  `tiger.sh` ships modern openssl, so the path is "build hsopenssl /
  tls against /opt/tiger.sh's openssl".  Future session.
