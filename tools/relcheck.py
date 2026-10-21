#!/usr/bin/env python3
"""Compare what each function's relocations point at, target vs base.

    tools/relcheck.py [UNIT...]

objdiff can score a function 100% when an instruction references a
different symbol than the original's: a call to CacheLoad instead of
CacheLoadEMS, a static at the wrong offset of the file's _BSS, two stores
to adjacent fields in the opposite order. This lists every function whose
relocations, taken in order, name different targets.

Not differences: names for one address (config/aliases.txt, OLDNAMES'
lseek/_lseek, the medium model's malloc/_nmalloc), jump tables named
relative to .text in base and to the function in target, and string
literals (named by content and not comparable by name).
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# the near heap functions medium model code calls by their ANSI names
SAME = {("__nmalloc", "_malloc"), ("__nfree", "_free")}


def aliases() -> dict[str, str]:
    out = {}
    for line in (ROOT / "config/aliases.txt").read_text().splitlines():
        f = line.split()
        if len(f) >= 2 and not line.startswith("#"):
            out[f[0]] = f[1]
    return out


def functions(obj: Path) -> dict[str, int]:
    out = subprocess.run(["readelf", "-sW", str(obj)], capture_output=True, text=True).stdout
    return {f[7]: int(f[1], 16) for f in (ln.split() for ln in out.splitlines())
            if len(f) >= 8 and f[3] == "FUNC"}


def relocs(obj: Path) -> dict[str, list[str]]:
    """Each function's relocation targets, in address order, as sym+off."""
    funcs = sorted(functions(obj).items(), key=lambda kv: kv[1])
    out = subprocess.run(["objdump", "-dr", str(obj)], capture_output=True, text=True).stdout
    res: dict[str, list[str]] = {}
    fn = None
    for line in out.splitlines():
        m = re.match(r"^[0-9a-f]+ <(\S+)>:", line)
        if m:
            fn = m.group(1)
            res[fn] = []
            continue
        m = re.search(r"R_386_\w+\s+(\S+)", line)
        if not (m and fn):
            continue
        sym = re.sub(r"~\d+$", "", m.group(1))
        t = re.match(r"^\.text\+0x([0-9a-f]+)$", sym)
        if t:   # section relative: name it from the function containing it
            a = int(t.group(1), 16)
            owner = max(((n, s) for n, s in funcs if s <= a), key=lambda kv: kv[1], default=None)
            if owner:
                sym = f"{owner[0]}+{a - owner[1]:#x}" if a != owner[1] else owner[0]
        res[fn].append(sym)
    return res


def same(a: str, b: str, al: dict[str, str]) -> bool:
    if a == b or a.startswith("$") or b.startswith("$"):
        return True
    ca, cb = al.get(a, a), al.get(b, b)
    if ca == cb or (a, b) in SAME or (b, a) in SAME:
        return True
    return "_" + a == b or "_" + b == a          # OLDNAMES: lseek -> _lseek


def main() -> None:
    al = aliases()
    units = sys.argv[1:]
    objs = sorted((ROOT / "build/base").rglob("*.o"))
    found = 0
    for b in objs:
        unit = str(b.relative_to(ROOT / "build/base"))[:-2]
        if unit.startswith("lib/") or (units and unit not in units):
            continue
        t = ROOT / "build/target" / f"{unit}.o"
        if not t.exists():
            continue
        rb, rt = relocs(b), relocs(t)
        for fn, lb in rb.items():
            lt = rt.get(fn)
            if lt is None or len(lt) != len(lb):
                continue        # a different instruction count: objdiff shows it
            diff = [(x, y) for x, y in zip(lt, lb) if not same(x, y, al)]
            if diff:
                found += 1
                pairs = ", ".join(f"{x} (base {y})" for x, y in diff[:4])
                print(f"{unit:8} {fn:20} {pairs}{' ...' if len(diff) > 4 else ''}")
    print(f"{found} functions reference different symbols")


if __name__ == "__main__":
    main()
