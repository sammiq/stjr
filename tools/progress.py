#!/usr/bin/env python3
"""Summarise an objdiff report (build/report.json) as a progress table.

    tools/progress.py [build/report.json] [-v]     -v: every unit
    tools/progress.py -u UNIT [-u UNIT...]          a unit's functions and their match
"""

from __future__ import annotations

import json
import sys


def pct(m: dict, key: str) -> str:
    return f"{float(m.get(key, 0) or 0):6.2f}%"


def num(m: dict, key: str) -> int:
    return int(m.get(key, 0) or 0)


def line(name: str, m: dict) -> str:
    return (f"{name:<14} code {num(m, 'matched_code'):>7}/{num(m, 'total_code'):<7} {pct(m, 'matched_code_percent')}"
            f"   funcs {num(m, 'matched_functions'):>4}/{num(m, 'total_functions'):<4}"
            f"   data {num(m, 'matched_data'):>6}/{num(m, 'total_data'):<6} {pct(m, 'matched_data_percent')}"
            f"   fuzzy {pct(m, 'fuzzy_match_percent')}")


def functions(rep: dict, names: list[str]) -> None:
    for u in rep.get("units", []):
        if u["name"] not in names:
            continue
        print(line(u["name"][-14:], u.get("measures", {})))
        for f in sorted(u.get("functions", []), key=lambda f: int(f.get("address", 0) or 0)):
            mp = float(f.get("fuzzy_match_percent", 0) or 0)
            mark = "  " if mp == 100 else "* "
            print(f"  {mark}{f['name']:<28} {int(f.get('size', 0)):5d}  {mp:6.2f}%")


def main() -> None:
    args = [a for a in sys.argv[1:]]
    units = [args[i + 1] for i, a in enumerate(args) if a == "-u" and i + 1 < len(args)]
    paths = [a for i, a in enumerate(args) if not a.startswith("-") and (i == 0 or args[i - 1] != "-u")]
    path = paths[0] if paths else "build/report.json"
    rep = json.load(open(path))
    if units:
        functions(rep, units)
        return
    print(line("all", rep.get("measures", {})))
    for cat in rep.get("categories", []):
        print(line(cat.get("name", cat.get("id")), cat.get("measures", {})))
    if "-v" in sys.argv:
        print()
        for u in rep.get("units", []):
            m = u.get("measures", {})
            if num(m, "total_code") or num(m, "total_data"):
                print(line(u["name"][-14:], m))


if __name__ == "__main__":
    main()
