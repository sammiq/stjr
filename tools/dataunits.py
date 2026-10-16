#!/usr/bin/env python3
"""Give each game code unit its piece of the game's _DATA in config/units.txt.

C 7.00 puts a file's string literals (and its initialised variables) in
that file's own _DATA, and LINK lays the files' _DATA out in the same order
as their code. A unit's _DATA starts:

  * where its compiled object says: a public variable of the object's _DATA
    that has its name in config/symbols.txt too sits at its offset from the
    start (the most common such start wins)
  * failing that, after the previous unit's last string literal: the
    literals a unit's code references (and no other unit does) are its own

and runs to the next unit's start. A unit's .data range lets a compiled
function's reference to a literal match the original's (objdiff compares
the text the two references point at).

    tools/dataunits.py [--dry-run]

Re-run after moving code between units. Units without literals of their
own get no .data; the region before the first one stays a data/ unit.
"""

from __future__ import annotations

import argparse
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from project import ROOT, UNITS, SymbolTable, Unit, load_ida, load_units, save_units  # noqa: E402

GAME_DATA = (0x3B8B2, 0x3EB68)     # after the runtime's NULL segment, up to the library's _DATA


def is_literal(s) -> bool:
    return s is not None and s.name.startswith("a") and s.name[1:2].isupper()


def content_votes(m, image: bytes, lo: int, hi: int) -> list[int]:
    """Starts of the object's _DATA in the original, one per public variable
    whose initial bytes (relocated words aside) occur exactly once there."""
    import re
    seg = next((sg for sg in m.segments if sg.name == "_DATA"), None)
    if seg is None or not seg.length:
        return []
    data = bytes(seg.data[:seg.length])
    fixed = bytearray(b"\1" * seg.length)
    for f in seg.fixups:
        for k in range(f.size):
            if f.offset + k < seg.length:
                fixed[f.offset + k] = 0
    pubs = sorted(p.offset for p in m.publics if p.seg == seg.index)
    votes = []
    for k, off in enumerate(pubs):
        end = pubs[k + 1] if k + 1 < len(pubs) else seg.length
        chunk = data[off:end]
        known = sum(fixed[off:end])
        if known < 8 or not any(chunk[i] for i in range(len(chunk)) if fixed[off + i]):
            continue                        # too short, or only zeros: anything matches
        pat = re.compile(b"".join(re.escape(bytes([b])) if fixed[off + i] else b"." for i, b in enumerate(chunk)), re.S)
        hits = [h.start() for h in pat.finditer(image)]
        if len(hits) == 1:
            votes.append(lo + hits[0] - off)
    return votes


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    ida = load_ida()
    syms = SymbolTable.load()
    units = load_units(UNITS)
    lo, hi = GAME_DATA
    code = sorted((u for u in units if ".text" in u.ranges and not u.lib and not u.name.startswith("asm/")),
                  key=lambda u: u.ranges[".text"][0])
    users: dict[int, set[str]] = defaultdict(set)
    lits: dict[str, list[int]] = defaultdict(list)
    for u in code:
        a, b = u.ranges[".text"]
        for ea, targets in ida.drefs.items():
            if a <= ea < b:
                for t in targets:
                    if lo <= t < hi and is_literal(syms.get(t)):
                        users[t].add(u.name)
    for t, us in users.items():
        if len(us) == 1:
            lits[next(iter(us))].append(t)

    # starts from the compiled objects' public variables: by name, and by
    # finding their initial contents in the original
    import omf
    from project import load_exe
    image = load_exe().bytes(lo, hi)
    from collections import Counter
    by_name = {sy.name: sy.addr for sy in syms.by_addr.values()}
    anchored: dict[str, int] = {}
    for u in code:
        obj = ROOT / "build/obj" / f"{u.name}.obj"
        if not obj.exists():
            continue
        m = omf.parse_obj(obj.read_bytes())
        starts = Counter(by_name[p.name] - p.offset for p in m.publics
                         if p.seg and m.seg(p.seg).name == "_DATA" and p.name in by_name
                         and lo <= by_name[p.name] < hi)
        starts.update(content_votes(m, image, lo, hi))
        if starts:
            anchored[u.name] = starts.most_common(1)[0][0]

    # anchors must follow code order: keep the largest increasing set
    seq = [(u.name, anchored[u.name]) for u in code if u.name in anchored]
    best: list[list] = []
    for i, (n, st) in enumerate(seq):
        prev = max((best[j] for j in range(i) if seq[j][1] < st), key=len, default=[])
        best.append(prev + [i])
    keep = max(best, key=len, default=[])
    for i, (n, st) in enumerate(seq):
        if i not in keep:
            print(f"{n:<8} anchor {st:05X} is out of code order: ignored")
            del anchored[n]

    # literals: each unit's own, outliers dropped (kept increasing)
    lit_end: dict[str, list[int]] = {}
    cursor = lo
    for u in code:
        ts = sorted(t for t in lits.get(u.name, []) if t >= cursor)
        if ts:
            cursor = ts[0]
            lit_end[u.name] = ts
    order = []          # (unit, start)
    prev_end = lo
    for k, u in enumerate(code):
        # the next unit's start: its anchor, or its first literal; a literal of
        # this unit past that is an outlier
        later = [anchored[v.name] if v.name in anchored else lit_end[v.name][0]
                 for v in code[k + 1:] if v.name in anchored or v.name in lit_end]
        nxt = min(later[:1] or [hi])
        if u.name in anchored:
            start = anchored[u.name]
        elif u.name in lit_end:
            start = prev_end
            if start >= nxt or (order and start <= order[-1][1]):
                continue                # no room before the next anchored unit
        else:
            continue
        order.append((u, start))
        mine = [t for t in lit_end.get(u.name, []) if t < nxt]
        if mine:
            end = max(mine) + max(syms.get(max(mine)).size, 1)
            prev_end = max(prev_end, end + (end & 1))
        else:
            prev_end = max(prev_end, start + 2)
    bounds = []
    for k, (u, start) in enumerate(order):
        end = order[k + 1][1] if k + 1 < len(order) else hi
        u.ranges[".data"] = (start, end)
        bounds.append((u, end))
    for u in code:
        if u not in [b[0] for b in bounds]:
            u.ranges.pop(".data", None)
    first = order[0][1] if order else hi
    # the data/ units that covered the game's _DATA keep only what's left
    out = []
    for u in units:
        r = u.ranges.get(".data")
        if u.name.startswith("data/") and r and r[0] < hi and lo < r[1]:
            if r[0] < lo:
                out.append(Unit(u.name, {".data": (r[0], lo)}, set(u.flags)))
            if lo < first:
                out.append(Unit(f"data/d{lo:05X}", {".data": (lo, first)}))
            if hi < r[1]:
                out.append(Unit(f"data/d{hi:05X}", {".data": (hi, r[1])}, set(u.flags)))
            continue
        out.append(u)
    out.sort(key=lambda u: min(r[0] for r in u.ranges.values()))
    for u, _ in bounds:
        a, b = u.ranges[".data"]
        how = "variables" if u.name in anchored else "literals"
        print(f"{u.name:<8} .data {a:05X}-{b:05X}  (from {how}; {len(lits[u.name])} literals)")
    if not args.dry_run:
        save_units(out, UNITS)


if __name__ == "__main__":
    main()
