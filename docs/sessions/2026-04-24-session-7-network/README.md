# Session 7 — network package for sockets

**Date:** 2026-04-24.
**Starting state:** v0.4.0 released.  6 Hackage pkgs verified.
Network documented as "needs patching" — blocked on SOCK_CLOEXEC
missing from Tiger SDK.
**Goal:** unblock sockets on Tiger by getting `Network.Socket` to work
via some combination of configure overrides, older version pin, or
vendoring.
**Ending state:** ✅ `network-2.5.0.0` works via
`constraints: network < 3.0` in cabal.project.  TCP echo server +
client (forkIO-separated, both in one binary) verified running on
pmacg5.

## What didn't work

### Attempt 1: `ac_cv_func_accept4=no` in tiger-config.site

Got past the first error (`SOCK_CLOEXEC`) by forcing
`HAVE_ADVANCED_SOCKET_FLAGS` to 0 via the accept4 check.  Network
built further but then hit:

```
Cmsg.hsc:63:32: error: use of undeclared identifier 'IP_RECVTOS'
Cmsg.hsc:70:32: error: use of undeclared identifier 'IPV6_TCLASS'
```

Both added in macOS 10.6–10.7.  Not trivially configure-controllable
— the hsc file reaches for them unconditionally inside a
`#if defined(darwin_HOST_OS)` branch.

### Attempt 2 (abandoned): vendor network with Tiger patches

Would have required patching:
1. `Cmsg.hsc` — replace `IP_RECVTOS` with `IP_TOS` fallback; skip
   `IPV6_TCLASS` entirely (define as `-1` sentinel).
2. `Cbits.hsc` — `#ifdef SOCK_CLOEXEC` guards.
3. `configure.ac` — add `ac_cv_func_accept4=no` respect via
   AC_CHECK_FUNCS.
4. Regenerate `configure` from `.ac` with autoreconf.

Substantial.  Deferred when I noticed:

## What worked: constrain to `network < 3.0`

Simple one-liner in cabal.project:

```
constraints:
  network < 3.0
```

cabal picks `network-2.5.0.0` (pre-Cmsg, no SOCK_CLOEXEC, no
IP_RECVTOS references).  Builds cleanly.

## The demo

TCP echo on Tiger (both halves in one binary, forkIO-separated
server/client over 127.0.0.1):

```
$ ssh pmacg5 /tmp/dummy-echo
server listening on 49310
got: re: hello tiger
```

## tiger-config.site additions (kept even though network 2.5 didn't need them)

```
ac_cv_func_accept4=no
ac_cv_func_gai_strerror=yes
ac_cv_func_gethostent=yes
ac_cv_func_ifNameToIndex=yes
```

These are useful for other packages that depend on `network`
transitively and probe these functions.

## Lessons

1. **Version pinning beats vendoring** when the upstream breakage is
   recent.  network went from Tiger-safe (≤2.8) to Tiger-hostile
   (3.x+) in a few breaking changes; dropping back a major version is
   cheaper than 4 patches + autoreconf.
2. **`cabal.project`'s `constraints:` is underappreciated.**  For
   Tiger users, a "known-good-pins" shared cabal.project template
   would smooth onboarding.
3. **Tiger SDK gaps are mostly unrelated constants.**  `SOCK_CLOEXEC`,
   `IP_RECVTOS`, `IPV6_TCLASS`, `HAVE_ACCEPT4` are all independent.
   Packages that reach for any of them without `#ifdef` guards will
   fail.  Each case needs its own workaround.

## Hand-off

Session 8 options:
- Vendor more commonly-broken packages (`time-compat`, `unix-compat`).
- Add cabal-based tests to the battery so regressions get caught.
- Build a real useful CLI tool (e.g. a small jq-alike with
  aeson+megaparsec).
