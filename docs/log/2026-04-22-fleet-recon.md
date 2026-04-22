# 2026-04-22 — fleet recon raw output

Raw output from the fleet reachability sweep at the start of the
session. Filed for the record; summary lives in
[`notes/fleet-recon.md`](../notes/fleet-recon.md).

## SSH reachability

```
imacg3   : OK 10.4.11 Power Macintosh powerpc
imacg52  : OK 10.4.11 Power Macintosh powerpc
pmacg5   : OK 10.4.11 Power Macintosh powerpc
ibookg37 : OK 10.4.11 Power Macintosh powerpc
emac     : OK 10.4.11 Power Macintosh powerpc
pmacg3   : ssh: connect to host pmacg3 port 22: Operation timed out
mdd      : OK 10.5.8  Power Macintosh powerpc
ibookg3  : OK 10.4.11 Power Macintosh powerpc
pbookg42 : OK 10.5.8  Power Macintosh powerpc
```

## pmacg5 detailed

```
$ sw_vers
ProductName:    Mac OS X
ProductVersion: 10.4.11
BuildVersion:   8S165

$ sysctl hw.model hw.ncpu hw.memsize
hw.model: PowerMac11,2
hw.ncpu: 2
hw.memsize: 2147483648

$ df -h /
Filesystem     Size   Used  Avail Capacity  Mounted on
/dev/disk0s5    58G   6.9G    51G    12%    /

$ tiger.sh --cpu
g5
$ tiger.sh -mcpu
-mcpu=970
$ tiger.sh -j
-j2
$ tiger.sh -O
-O2

$ ls /opt | wc -l
66
```

Relevant /opt packages:
```
/opt/gcc-10.3.0
/opt/gcc-4.9.4
/opt/gcc-libs-4.9.4
/opt/gmp-4.3.2
/opt/gmp-6.2.1
/opt/libffi-3.4.2
/opt/libiconv-1.16
/opt/libiconv-bootstrap-1.16
/opt/ncurses-6.3
/opt/python-3.11.2
/opt/cctools-667.3
/opt/ld64-97.17-tigerbrew
/opt/autoconf-2.13
/opt/macports-legacy-support-20221029
/opt/openssl-1.1.1t
/opt/tigersh-deps-0.1
```

`/usr/bin/gcc-4.0` present (Apple GCC 4.0.1 build 5370).
`/Developer/SDKs/MacOSX10.4u.sdk` and `MacOSX10.3.9.sdk` present.
No GHC anywhere before this session. No `/opt/ghc-*`.

## imacg52 detailed

Same /opt stack, similar shape. Key difference:
```
hw.model: PowerMac8,2   (single-core G5 2.0 GHz)
hw.ncpu: 1
hw.memsize: 2147483648

$ df -h /
/dev/disk0s9   20G   12G   7.8G   61%  /
```

7.8 GB free — tight for a GHC self-build (a typical GHC build can
easily produce 5–10 GB of intermediate objects). Usable for
validation / second-opinion builds but not the primary host.

## /Users/macuser/tmp on pmacg5

Clutter from prior sibling projects (TigerTube, ionpower-node,
LLVM-7-darwin-ppc, chicken-scheme bootstrap). Will not touch any
of it. Our scratch will go under `/Users/macuser/tmp/ghc/`.

## Decision

Primary build host for this project: **pmacg5**.

Plan said `imacg52` tentatively; updated in state.md.
