#!/usr/bin/env python3
# Apply the subset of upstream testsuite normalisations relevant to
# our GHCi subset runs.  Mirrors functions in
# external/ghc-modern/ghc-9.2.8/testsuite/driver/testlib.py:
#   normalise_errmsg, normalise_callstacks, normalise_version, plus
#   the " error:" / bullet strip that's applied unconditionally.
#
# Usage: normalise.py [--version base,...] < in.txt > out.txt

import argparse
import re
import sys


CALLSITE_RE = re.compile(r', called at (.+):[\d]+:[\d]+ in [\w\-\.]+:')
ERROR_KEYWORD_RE = re.compile(r' error:')
WARNING_KEYWORD_RE = re.compile(r' Warning:')
BULLET = '•'


def normalise_callstacks(s):
    s = CALLSITE_RE.sub(lambda m: ', called at {0}:<line>:<column> in <package-id>:'.format(m.group(1)), s)
    s = s.replace('from ImplicitParams', 'from HasCallStack')
    s = re.sub(r'CallStack \(from -prof\):(\n  .*)*\n?', '', s)
    return s


def normalise_version_strs(s, pkgs):
    if not pkgs:
        return s
    return re.sub('(' + '|'.join(map(re.escape, pkgs)) + ')-[0-9.]+', r'\1-<VERSION>', s)


def normalise(s, versions=()):
    # " error:" → "" (upstream's modify_lines hack from #10021)
    s = '\n'.join(ERROR_KEYWORD_RE.sub('', l) for l in s.split('\n'))
    # " Warning:" → " warning:"
    s = '\n'.join(WARNING_KEYWORD_RE.sub(' warning:', l) for l in s.split('\n'))
    s = normalise_callstacks(s)
    s = s.replace(BULLET, '')
    s = normalise_version_strs(s, versions)
    return s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--version', action='append', default=[],
                    help='package name whose version digits should be replaced with <VERSION>')
    args = ap.parse_args()
    versions = []
    for v in args.version:
        versions.extend(v.split(','))
    sys.stdout.write(normalise(sys.stdin.read(), versions))


if __name__ == '__main__':
    main()
