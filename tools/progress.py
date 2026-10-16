#!/usr/bin/env python3
"""Summarise an objdiff report (build/report.json) as a progress table."""

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


def main() -> None:
    path = sys.argv[1] if len(sys.argv) > 1 else "build/report.json"
    rep = json.load(open(path))
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
