# Tiger patches to splitmix-0.1.3.2

Changes from upstream:

1. `cbits-apple/init.c` — rewritten to read `/dev/urandom` via
   stdio.  The upstream version uses `SecRandomCopyBytes` from
   `Security/SecRandom.h`, which requires the Security framework
   (added in macOS 10.5).  Tiger's 10.4u SDK doesn't have it.

2. `splitmix.cabal` — stripped `frameworks: Security` from the
   `elif (os(osx) || os(ios))` branch.  The new init.c doesn't
   need it.

Diff is small enough that upgrading to future splitmix versions
should be straightforward: keep the same two files in sync.
