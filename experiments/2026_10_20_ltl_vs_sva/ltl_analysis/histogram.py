#!/usr/bin/env python3
import spot
import sys
import os
import textwrap
from collections import defaultdict

PROGNAME = os.path.basename(sys.argv[0])


def usage() -> None:
    print(textwrap.dedent(f"""\
    usage: {PROGNAME} FILE [FILE2 ...]
     FILE\tltl files to use"""))
    return


def main() -> None:
    if len(sys.argv) < 2:
        usage()
        sys.exit(os.EX_USAGE)

    hist = defaultdict(list)

    simp = spot.tl_simplifier()

    for ltl_file in sys.argv[1:]:
        with open(ltl_file) as f:
            formulas = [spot.formula(line.strip()) for line in f]
        for f in formulas:
            hist[simp.simplify(f)].append(ltl_file)

    for k, v in hist.items():
        print(f'"{k}", {len(v)}')

    sys.exit(os.EX_OK)


if __name__ == "__main__":
    main()
