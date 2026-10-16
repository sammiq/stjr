#!/usr/bin/env python3
"""Name a unit's string literals and relocate the pushes IDA left as numbers.

    tools/strrel.py seg030 [--dry-run]

Every string in the unit's .rodata range (from config/units.txt) gets a
symbol in config/symbols.txt. A symbol that already starts at a string keeps
its name. A symbol that only covers strings (an IDA "aFoo" running over
several literals) is split: the part before the range keeps its name with a
shorter size, and the part after the range keeps its name too. New names are
made from the text ("aTug0Flyby", "aEmpty" for "").

Then every `push NNNNh` in the unit's .text whose operand is the DGROUP
offset of one of those strings, and which the disassembly shows without a
symbol, gets an entry in config/relocs.txt (skipping addresses already there).
Other operand forms (`mov ax, NNNNh`) still need entries by hand.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from project import ROOT, SYMBOLS, load_exe, load_units  # noqa: E402

DGROUP = 0x45A50
RELOCS = ROOT / "config/relocs.txt"
SYM_LINE = re.compile(r"^([0-9A-F]{5})\s+(\w+)\s+([0-9A-F]+)\s+(\S+)")
PUSH = re.compile(r"^\s+([0-9A-F]{4})\s+\S+\s+push ([0-9A-F]+)h\s*$")
FIRST = re.compile(r"^\s+([0-9A-F]{4})\s")


def split_strings(data: bytes, lo: int) -> list[tuple[int, int, str]]:
    """(address, size with terminator, text) for each string in data."""
    out = []
    i = 0
    while i < len(data):
        j = data.find(b"\0", i)
        if j < 0:
            j = len(data) - 1
        out.append((lo + i, j - i + 1, data[i:j].decode("latin1")))
        i = j + 1
    return out


def make_name(text: str, taken: set[str]) -> str:
    words = re.findall(r"[A-Za-z0-9]+", text)
    base = ("a" + "".join(w.capitalize() for w in words)[:20]) if words else "aEmpty"
    name, k = base, 0
    while name in taken:
        name = f"{base}_{k}"
        k += 1
    taken.add(name)
    return name


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("unit")
    ap.add_argument("--dry-run", action="store_true", help="print the changes without writing them")
    args = ap.parse_args()

    unit = next((u for u in load_units() if u.name == args.unit), None)
    if unit is None or ".text" not in unit.ranges or ".rodata" not in unit.ranges:
        sys.exit(f"{args.unit}: needs .text and .rodata ranges in config/units.txt")
    tlo, thi = unit.ranges[".text"]
    lo, hi = unit.ranges[".rodata"]

    strings = split_strings(load_exe().bytes(lo, hi), lo)

    lines = SYMBOLS.read_text().rstrip("\n").split("\n")
    taken = {m.group(4) for l in lines if (m := SYM_LINE.match(l))}

    # Symbols starting inside the range: keep their names; one running past
    # the end leaves a symbol at `hi` for the rest.
    keep: dict[int, tuple[str, int]] = {}
    tail: tuple[int, int, str] | None = None
    out_lines = []
    for l in lines:
        m = SYM_LINE.match(l)
        if m and m.group(2) == "data":
            a, n, name = int(m.group(1), 16), int(m.group(3), 16), m.group(4)
            if lo <= a < hi:
                keep[a] = (name, n)
                if a + n > hi:
                    tail = (hi, a + n - hi, name)
                continue
            if a < lo < a + n:          # covers the start of the range
                l = f"{a:05X}  data   {lo - a:06X}  {name}"
                if a + n > hi:              # the head keeps the name
                    tail = (hi, a + n - hi, make_name("", taken))
        out_lines.append(l)

    new: dict[int, tuple[int, str]] = {}
    for a, n, text in strings:
        # Keep a name only where it named just this string; a symbol that
        # ran on over others (a leftover blob) keeps its name for the tail.
        old = keep.get(a)
        if old and old[1] <= n and not (tail and tail[2] == old[0]):
            new[a] = (n, old[0])
        else:
            new[a] = (n, make_name(text, taken))
    if tail:
        new[tail[0]] = (tail[1], tail[2])

    # Merge the new symbols in address order.
    pending = sorted(new.items())
    merged = []
    for l in out_lines:
        m = SYM_LINE.match(l)
        while pending and m and int(m.group(1), 16) > pending[0][0]:
            a, (n, name) = pending.pop(0)
            merged.append(f"{a:05X}  data   {n:06X}  {name}")
        merged.append(l)
    merged += [f"{a:05X}  data   {n:06X}  {name}" for a, (n, name) in pending]

    # Pushes of those strings without a symbol in the disassembly.
    dis = subprocess.run([sys.executable, str(ROOT / "tools/disasm.py"), f"{tlo:X}", f"{thi:X}"],
                         check=True, capture_output=True, text=True).stdout.splitlines()
    base = None
    have = {int(l.split()[0], 16) for l in RELOCS.read_text().splitlines()
            if re.match(r"^[0-9A-F]{5}\s", l)}
    relocs = []
    for line in dis:
        if base is None and (m := FIRST.match(line)):
            base = tlo - int(m.group(1), 16)    # the display offset of the unit's first byte
        m = PUSH.match(line)
        if not m:
            continue
        target = int(m.group(2), 16) + DGROUP
        addr = base + int(m.group(1), 16)
        if target in new and lo <= target < hi and addr not in have:
            relocs.append((addr, new[target][1]))

    for a, (n, name) in sorted(new.items()):
        print(f"symbol {a:05X} {n:3X} {name}")
    for a, name in relocs:
        print(f"reloc  {a:05X} {name}")
    if args.dry_run:
        return
    SYMBOLS.write_text("\n".join(merged) + "\n")
    if relocs:
        text = RELOCS.read_text().rstrip("\n")
        text += f"\n\n# {args.unit}: strings pushed as bare immediates\n"
        text += "".join(f"{a:05X}  {name}\n" for a, name in relocs)
        RELOCS.write_text(text)
    print(f"{len(new)} symbols, {len(relocs)} relocs")


if __name__ == "__main__":
    main()
