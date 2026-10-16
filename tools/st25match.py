#!/usr/bin/env python3
"""Find which ST25 functions still compile to the sequel's code.

Compiles every ref/st25/src/*.c with C 7.00 and the project's flags (the
objects go to build/st25/), then looks each compiled function up among
TREKJR.EXE's functions:

  exact  same bytes, with the fields the object relocates masked (and the
         displacement of a compiler `push cs; call near`, which depends on
         where the callee sits in its file)
  close  not exact, but the best candidate is at least --close similar

    tools/st25match.py [--no-compile] [--close 0.85] [-v]

Writes build/st25match.txt (one line per ST25 function) and prints a
summary per ST25 file. Small functions (under 12 bytes) can match several
places; they're reported but marked ambiguous.
"""

from __future__ import annotations

import argparse
import bisect
import difflib
import subprocess
import sys
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import omf  # noqa: E402
from project import ROOT, SymbolTable, load_exe  # noqa: E402

REF = ROOT / "ref/st25/src"
OUT = ROOT / "build/st25"
FLAGS = ["/AM", "/G2", "/Ox", "/Zp1", "/I\\REF\\ST25\\INCLUDE"]
MIN_UNIQUE = 12


def compile_all() -> None:
    OUT.mkdir(parents=True, exist_ok=True)

    def one(src: Path) -> tuple[str, bool]:
        r = subprocess.run([sys.executable, str(ROOT / "tools/cc.py"), str(src),
                            str(OUT / f"{src.stem}.o"), "--", *FLAGS],
                           capture_output=True, text=True, cwd=ROOT)
        return src.stem, r.returncode == 0

    with ThreadPoolExecutor(8) as pool:
        for name, ok in pool.map(one, sorted(REF.glob("*.c"))):
            if not ok:
                print(f"st25match: {name}.c does not compile", file=sys.stderr)


def compiled_functions(path: Path) -> list[tuple[str, bytes, bytes, list]]:
    """(name, code, mask, refs) per function; mask 0 = don't compare; refs
    are (offset in function, kind, external name) for the far pointer
    ("far") and DGROUP offset ("near") fixups to externals."""
    m = omf.parse_obj(path.read_bytes())
    out = []
    for seg in m.segments:
        if not seg.cls.endswith("CODE") or not seg.length:
            continue
        data = bytes(seg.data[:seg.length])
        mask = bytearray(b"\1" * seg.length)
        for f in seg.fixups:
            for k in range(f.size):
                if f.offset + k < seg.length:
                    mask[f.offset + k] = 0
        for i in range(seg.length - 3):
            if data[i] == 0x0E and data[i + 1] == 0xE8 and mask[i + 2]:
                mask[i + 2] = mask[i + 3] = 0
        pubs = sorted((p.offset, p.name) for p in m.publics if p.seg == seg.index)
        for k, (off, name) in enumerate(pubs):
            end = pubs[k + 1][0] if k + 1 < len(pubs) else seg.length
            code = data[off:end]
            n = len(code)
            while n and code[n - 1] == 0x90:
                n -= 1
            refs = []
            for f in seg.fixups:
                if off <= f.offset < off + n and f.target_method == omf.T_EXTDEF:
                    ext = m.ext(f.target_index)
                    if f.loc == omf.LOC_POINTER:
                        refs.append((f.offset - off, "far", ext.name))
                    elif f.loc in (omf.LOC_OFFSET, omf.LOC_OFFSET_LOADER) and f.seg_relative \
                            and f.disp + int.from_bytes(seg.data[f.offset:f.offset + 2], "little") == 0:
                        refs.append((f.offset - off, "near", ext.name))
            out.append((name, code[:n], bytes(mask[off:off + n]), refs))
    return out


def resolve(exe, cands: dict, refs: dict) -> dict:
    """Pick each function's address so that the externals its fixups name
    agree everywhere. cands: name -> [addr]; returns name -> (addr, confirmed)."""
    from project import DGROUP_PARA, lin

    def ref_addr(a: int, off: int, kind: str) -> int:
        w = exe.word(a + off)
        return lin(exe.word(a + off + 2), w) if kind == "far" else lin(DGROUP_PARA, w)

    claims = defaultdict(set)
    for n, hs in cands.items():
        for h in hs:
            claims[h].add(n)
    known = {n: hs[0] for n, hs in cands.items() if len(hs) == 1 and len(claims[hs[0]]) == 1}
    chosen: dict[str, tuple[int, bool]] = {}
    for _ in range(6):
        # what the known functions say about the externals they reference
        for n, a in list(known.items()):
            if n not in cands:
                continue                    # a variable
            for off, kind, ext in refs.get(n, ()):
                if (kind == "far") == (ext in refs):    # far: functions, near: variables
                    known.setdefault(ext, ref_addr(a, off, kind))
        chosen = {}
        for n, hs in cands.items():
            scored = []
            for h in hs:
                bad = sum(1 for off, kind, ext in refs[n] if ext in known and known[ext] != ref_addr(h, off, kind))
                good = sum(1 for off, kind, ext in refs[n] if ext in known and known[ext] == ref_addr(h, off, kind))
                if n in known and known[n] != h:
                    bad += 1
                if not bad:
                    scored.append((good, h))
            if len(scored) == 1 or (scored and scored[0][0] > 0 and all(g == 0 for g, _ in scored[1:])):
                scored.sort(reverse=True)
                chosen[n] = (scored[0][1], scored[0][0] > 0)
            elif scored:
                scored.sort(reverse=True)
                if scored[0][0] > scored[1][0]:
                    chosen[n] = (scored[0][1], True)
        # an address claimed by several functions goes to the confirmed one
        by_addr = defaultdict(list)
        for n, (a, conf) in chosen.items():
            by_addr[a].append((conf, n))
        for a, ns in by_addr.items():
            confirmed = [n for c, n in ns if c]
            keep = confirmed if len(confirmed) == 1 else ([ns[0][1]] if len(ns) == 1 else [])
            for c, n in ns:
                if n not in keep:
                    del chosen[n]
                elif n not in known:
                    known[n] = a
    return chosen


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("--no-compile", action="store_true", help="reuse build/st25/*.obj")
    ap.add_argument("--close", type=float, default=0.85)
    ap.add_argument("-v", action="store_true", help="list every function")
    args = ap.parse_args()
    if not args.no_compile:
        compile_all()

    exe = load_exe()
    syms = SymbolTable.load()
    funcs = sorted(s.addr for s in syms.by_addr.values() if s.kind == "func" and "lib" not in s.flags)
    addrs = syms.sorted_addrs()

    def target(a: int) -> bytes:
        nxt = addrs[bisect.bisect_right(addrs, a)] if bisect.bisect_right(addrs, a) < len(addrs) else a + 0x1000
        return exe.bytes(a, nxt)

    tbytes = {a: target(a) for a in funcs}
    by_len = defaultdict(list)
    for a, b in tbytes.items():
        n = len(b)
        while n and b[n - 1] == 0x90:
            n -= 1
        by_len[n].append(a)

    lines = []
    summary = []
    objs = {obj.stem.lower(): compiled_functions(obj) for obj in sorted(OUT.glob("*.obj"))}
    cands, refs = {}, {}
    for unit, fs in objs.items():
        for name, code, mask, rf in fs:
            refs[name] = rf
            cands[name] = [a for a in by_len.get(len(code), [])
                           if all(not m or x == y for x, y, m in zip(code, tbytes[a], mask))]
    chosen = resolve(exe, {n: h for n, h in cands.items() if h}, refs)
    for unit, fs in objs.items():
        exact = close = 0
        for name, code, mask, _rf in fs:
            n = len(code)
            hits = cands[name]
            if hits:
                if name in chosen:
                    exact += 1
                    a, conf = chosen[name]
                    tag = "exact" if conf or n >= MIN_UNIQUE else "small"
                    lines.append((unit, name, n, tag, a, 1.0, len(hits)))
                else:
                    lines.append((unit, name, n, "ambiguous", hits[0], 1.0, len(hits)))
                continue
            best = (0.0, None)
            masked = bytes(x if m else 0 for x, m in zip(code, mask))
            for a, b in tbytes.items():
                if abs(len(b) - n) > max(8, n // 4):
                    continue
                sm = difflib.SequenceMatcher(None, masked, b[:len(b)], autojunk=False)
                if sm.real_quick_ratio() < max(args.close, best[0]) or sm.quick_ratio() < max(args.close, best[0]):
                    continue
                r = sm.ratio()
                if r > best[0]:
                    best = (r, a)
            if best[0] >= args.close:
                close += 1
                lines.append((unit, name, n, "close", best[1], best[0], 1))
            else:
                lines.append((unit, name, n, "none", best[1] or 0, best[0], 0))
        summary.append((unit, len(fs), exact, close))

    with open(ROOT / "build/st25match.txt", "w") as fh:
        fh.write("# st25 unit, function, size, match, sequel address, similarity, candidates\n")
        for unit, name, n, tag, a, r, k in lines:
            fh.write(f"{unit:<8} {name:<28} {n:5d}  {tag:<9} {a:05X}  {r:.2f}  {k}\n")
    print(f"{'unit':<8} {'funcs':>5} {'exact':>5} {'close':>5}")
    for unit, n, e, c in summary:
        print(f"{unit:<8} {n:5d} {e:5d} {c:5d}")
    tot = [sum(x[i] for x in summary) for i in (1, 2, 3)]
    print(f"{'all':<8} {tot[0]:5d} {tot[1]:5d} {tot[2]:5d}   -> build/st25match.txt")
    if args.v:
        for ln in lines:
            print(*ln)


if __name__ == "__main__":
    main()
