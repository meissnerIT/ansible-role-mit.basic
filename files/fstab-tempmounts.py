#!/usr/bin/env python3
"""
Rewrite /etc/fstab: Use existing /tmp volume for /var/tmp, then use tmpfs for /tmp.

Copyright © 2024 Ralph Seichter
"""
__author__ = 'Ralph Seichter'

import argparse
import re
import sys
from typing import Optional


def say(*msg):
    if args.verbose:
        print(*msg)


def err(*msg):
    print(*msg, file=sys.stderr)


def fstab_status(fstab: str) -> int:
    """Return status of a given fstab file.

    :arg fstab: file to check
    :returns 0 if file is up-to-date, 1 otherwise.
    """
    rex = re.compile(r'^tmpfs\s+/tmp\s')
    with open(fstab, 'rt') as f:
        for line in f:
            if rex.search(line):
                say(f'{fstab} is up-to-date')
                return 0
    say(f'{fstab} needs updates')
    return 1


def extract_tmp_volume(fstab: str) -> Optional[str]:
    """Extract the volume mounted to /tmp.

    :arg fstab: file to check
    :returns volume/device if parsing succeeds, None otherwise.
    """
    rex = re.compile(r'^(/\S+)\s+/tmp\s')
    with open(fstab, 'rt') as f:
        for line in f:
            match = rex.search(line)
            if match is not None:
                return match.group(1)
    say('Found no /volume mounted to /tmp')


def write_fstab_entries(fout, tmpsize: str, vartmp: str = ''):
    """Write fstab entries to given output file.

    :arg fout: output file handle
    :arg tmpsize: size of /tmp
    :arg vartmp: volume for /var/tmp, optional.
    """
    say('/tmp on tmpfs')
    print(f'tmpfs /tmp tmpfs mode=1777,uid=0,gid=0,size={tmpsize}', file=fout)
    if vartmp:
        print(f'{vartmp} /var/tmp ext4 defaults 0 2', file=fout)
    else:
        say('/var/tmp unspecified')


def rewrite_fstab(fstab: str, outfile: str, tmpsize: str, vartmp: Optional[str]):
    """Update contents of the given fstab file and write result to outfile.

    :arg fstab: file to update.
    :arg outfile: file to write, or '-' for stdout.
    :arg tmpsize: size of tmpfs volume to mount on /tmp.
    :arg vartmp: volume to mount on /var/tmp, or None.
    """
    rex = re.compile(r'^/\S+\s+/tmp\s')
    if outfile == '-':
        fout = sys.stdout
    else:
        fout = open(outfile, 'wt')
    with open(fstab, 'rt') as f:
        for line in f:
            match = rex.search(line)
            if match is None:
                print(line.rstrip(), file=fout)
            else:
                write_fstab_entries(fout, tmpsize, vartmp)
    if vartmp is None:
        write_fstab_entries(fout, tmpsize)
    if outfile != '-':
        fout.close()


def main() -> int:
    if fstab_status(args.fstab) != 0:
        volume = extract_tmp_volume(args.fstab)
        rewrite_fstab(args.fstab, args.outfile, args.tmpsize, volume)
    return 0


if __name__ == '__main__':
    default_tmpsize = '512M'
    ap = argparse.ArgumentParser()
    ap.add_argument('fstab', help='fstab file (typically /etc/fstab)')
    ap.add_argument('outfile', help='optional output file', nargs='?', default='-')
    ap.add_argument('-c', '--check', action='store_true',
                    help="check if fstab is up-to-date, but don't change anything")
    ap.add_argument('-t', '--tmpsize', default=default_tmpsize, metavar='SIZE',
                    help=f'size of /tmp (default: {default_tmpsize})')
    ap.add_argument('-v', '--verbose', action='store_true', help='print verbose messages')
    args = ap.parse_args()
    if args.check:
        rc = fstab_status(args.fstab)
    else:
        rc = main()
    sys.exit(rc)
