#!/usr/bin/env python3
"""Side-by-side diff of one function (target vs base) in the terminal.

    tools/fdiff.py UNIT SYMBOL [-a]      (-a: show all rows, not just context)

Uses objdiff-cli one-shot mode with the project's objdiff.json.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CLI = ROOT / "tools/bin/objdiff-cli"


def rows(side: dict, symbol: str) -> tuple[list[dict], float | None]:
    for s in side.get("symbols", []):
        if s.get("name") == symbol:
            return s.get("instructions", []), s.get("match_percent")
    return [], None


def fmt(row: dict) -> str:
    ins = row.get("instruction")
    if not ins:
        return ""
    addr = int(ins.get("address", "0"))
    text = ins.get("formatted", "").strip()
    rel = ins.get("relocation")
    if rel:
        text += f"   <{rel.get('type_name', rel.get('type'))}>"
    return f"{addr:04X}  {text}"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("unit")
    ap.add_argument("symbol")
    ap.add_argument("-a", "--all", action="store_true", help="show every row")
    ap.add_argument("-w", "--width", type=int, default=60)
    args = ap.parse_args()

    res = subprocess.run([str(CLI), "diff", "-p", str(ROOT), "-u", args.unit, "-o", "-",
                          "--format", "json", args.symbol], capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit(res.stderr.strip() or res.stdout.strip())
    d = json.loads(res.stdout)
    left, lp = rows(d.get("left", {}), args.symbol)
    right, rp = rows(d.get("right", {}), args.symbol)
    if lp is None and rp is None:
        sys.exit(f"symbol {args.symbol} not found in unit {args.unit}")
    print(f"{args.unit} {args.symbol}: match {lp if lp is not None else 0:.2f}%")
    print(f"{'target':<{args.width}} | base")
    w = args.width
    n = max(len(left), len(right))
    show = set(range(n)) if args.all else set()
    for i in range(n):
        lk = left[i].get("diff_kind") if i < len(left) else "DIFF_NONE"
        rk = right[i].get("diff_kind") if i < len(right) else "DIFF_NONE"
        if (lk or rk) and not args.all:
            show.update(range(max(0, i - 3), min(n, i + 4)))
    prev = -1
    for i in sorted(show):
        if prev != -1 and i != prev + 1:
            print(f"{'...':<{w}} | ...")
        prev = i
        lrow = left[i] if i < len(left) else {}
        rrow = right[i] if i < len(right) else {}
        mark = " " if not (lrow.get("diff_kind") or rrow.get("diff_kind")) else "*"
        kind = (lrow.get("diff_kind") or rrow.get("diff_kind") or "").replace("DIFF_", "").lower()
        print(f"{fmt(lrow)[:w]:<{w}} |{mark}{fmt(rrow)[:w]:<{w}} {kind}")


if __name__ == "__main__":
    main()
