# Session 7 findings

## 1. Tiger SDK has three independent socket/network gaps

Added in macOS 10.6–10.7, not in 10.4u SDK:
- `SOCK_CLOEXEC` / `SOCK_NONBLOCK` (socket creation flags)
- `IP_RECVTOS` / `IPV6_RECVHOPLIMIT` (IPv4/6 TOS / Traffic Class cmsg)
- `IPV6_TCLASS` (IPv6 traffic class)
- `accept4(2)` (Linux-only anyway)

Packages that use any of these without `#ifdef` guards fail in Tiger.

## 2. Pin + constrain < version-pattern works well

`cabal.project`'s `constraints:` field is a clean way to pick a
Tiger-compatible version.  `constraints: network < 3.0` makes cabal
solve to `network-2.5.0.0` which predates the problematic code.

General Tiger pattern: pin to the last major version released before
~2018 (when "assume macOS 10.7+" became default in the ecosystem).

## 3. CONFIG_SITE is picked up by Hackage packages' configure

Network's `./configure` (autoconf-generated) honored our
`ac_cv_func_accept4=no` override from `scripts/tiger-config.site`.
Confirmed by grepping the generated `HsNetworkConfig.h`: `accept4`
was undefined as requested.

This pattern works for any Hackage package with `build-type: Configure`
or a `Setup.hs` that runs `./configure`.

## 4. CONFIG_SITE doesn't propagate through cabal to hsc2hs preprocessing

hsc2hs runs during `Preprocessing library` phase, with the cross-cc.
It doesn't consult `CONFIG_SITE` — it just evaluates C expressions
against the SDK headers.  That's why the `IP_RECVTOS` issue isn't
fixable via tiger-config.site; it's hard-coded in Cmsg.hsc.

Takeaway: CONFIG_SITE handles *configure-script* probes, not
*hsc2hs* preprocessing.  For hsc2hs, you need either `#ifdef` guards
in the .hsc source or a version that doesn't have the reference.

## 5. TCP echo works end to end

forkIO-based server/client both in one binary (server listens on
127.0.0.1:0, announces port to client, sends "hello tiger", gets
"re: hello tiger" back).  Full socket lifecycle: `socket`, `bind`,
`listen`, `accept`, `connect`, `sendAll`, `recv`, `close`.

Demonstrates MVar synchronization across forkIO threads on
non-threaded RTS concurrently with network IO.  Clean.
