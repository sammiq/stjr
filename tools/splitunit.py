#!/usr/bin/env python3
"""Carve a source file's code out of a packed segment's unit in config/units.txt.

LINK /PACKCODE merged the game's .C files into three code segments, so
init_config.py starts with one unit per segment. Once a file's extent is
known, split it off:

    tools/splitunit.py START END NAME     e.g. tools/splitunit.py 21DB6 21E66 list

START/END are linear addresses (end exclusive) inside one .text unit. NAME
gets [START, END); what was before keeps the old unit's name and what was
after becomes c<END> (rename it once its file is known). Then re-run
configure.py (ninja does it by itself when units.txt changes).
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from project import UNITS, Unit, load_units, save_units  # noqa: E402


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    start, end, name = int(sys.argv[1], 16), int(sys.argv[2], 16), sys.argv[3]
    units = load_units(UNITS)
    if any(u.name == name for u in units):
        sys.exit(f"splitunit: unit {name} already exists")
    host = next((u for u in units if ".text" in u.ranges
                 and u.ranges[".text"][0] <= start and end <= u.ranges[".text"][1]), None)
    if host is None or host.lib or len(host.ranges) != 1:
        sys.exit(f"splitunit: {start:05X}-{end:05X} is not inside one game code unit")
    lo, hi = host.ranges[".text"]
    out = [u for u in units if u is not host]
    if lo < start:
        out.append(Unit(host.name, {".text": (lo, start)}, set(host.flags)))
        rest = f"c{end:05X}"
    else:
        rest = host.name if host.name != name else f"c{end:05X}"
    out.append(Unit(name, {".text": (start, end)}))
    if end < hi:
        out.append(Unit(rest, {".text": (end, hi)}))
    out.sort(key=lambda u: min(r[0] for r in u.ranges.values()))
    save_units(out, UNITS)
    for u in out:
        if u.ranges.get(".text", (0, 0))[0] in (lo, start, end):
            print(f"{u.name:<10} {u.ranges['.text'][0]:05X}-{u.ranges['.text'][1]:05X}")


if __name__ == "__main__":
    main()
