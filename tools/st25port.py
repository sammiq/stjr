#!/usr/bin/env python3
"""Carry ST25 source over to the sequel, using tools/st25match.py's results.

    tools/st25port.py units            carve a unit per ST25 file out of the packed segments
    tools/st25port.py names            rename matched functions (and the variables they use)
    tools/st25port.py relocs           add config/relocs.txt entries for the matching functions'
                                       references to named variables (operands the analysis
                                       took for numbers, or for the wrong symbol)
    tools/st25port.py src FILE...      write src/FILE.c from ref/st25/src/FILE.c, keeping
                                       only the functions that match (--force to overwrite)
    tools/st25port.py add UNIT NAME@ADDR...  copy ST25's NAME into src/UNIT.c in address order,
                                       naming the function at ADDR (a sub_ placeholder) NAME
    tools/st25port.py prunedata FILE...  remove from src/FILE.c the variables none of its
                                       functions use (they went with ST25's functions
                                       that weren't carried over)

The sequel links ST25's files in nearly the same order, and each file's
matching functions form one run of addresses. `units` gives each ST25 file
segNNN the range from its first to its last matching function (so the
names line up with ref/st25/src/segNNN.c); the code between two files'
runs becomes a c<addr> unit: new code, or a file's changed functions,
to be assigned as it is identified.

Only "exact" and "small" matches from build/st25match.txt are used.
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from project import (DUMMY_NAME, ROOT, UNITS, SymbolTable, Unit, load_units,  # noqa: E402
                     save_units)

MATCHES = ROOT / "build/st25match.txt"


def load_matches() -> list[tuple[str, str, int, str, int]]:
    out = []
    for line in MATCHES.read_text().splitlines():
        if line.startswith("#"):
            continue
        unit, name, size, tag, addr, _ratio, _k = line.split()
        if tag in ("exact", "small"):
            out.append((unit, name, int(size), tag, int(addr, 16)))
    return out


# ---------------------------------------------------------------------- units

def cmd_units() -> None:
    syms = SymbolTable.load()
    units = load_units(UNITS)
    runs: dict[str, list[int]] = defaultdict(list)
    for unit, _name, _size, _tag, addr in load_matches():
        runs[unit].append(addr)
    game = [u for u in units if ".text" in u.ranges and not u.lib and not u.name.startswith("asm/")
            and len(u.ranges) == 1]
    new: list[Unit] = []
    taken = {u.name for u in units}
    for host in game:
        lo, hi = host.ranges[".text"]
        files = sorted((min(a), max(a), f) for f, a in runs.items()
                       if all(lo <= x < hi for x in a) and f not in taken)
        # files whose runs overlap another's are left alone
        ok = [r for i, r in enumerate(files)
              if not any(o[0] <= r[1] and r[0] <= o[1] for j, o in enumerate(files) if j != i)]
        if not ok:
            continue
        pieces = []
        cur = lo
        for first, last, f in ok:
            end = next_symbol(syms, last, hi)
            if first > cur:
                pieces.append((cur, first, None))
            pieces.append((first, end, f))
            cur = end
        if cur < hi:
            pieces.append((cur, hi, None))
        units.remove(host)
        for a, b, f in pieces:
            name = f or (host.name if a == lo and not host.name.startswith("seg") else f"c{a:05X}")
            new.append(Unit(name, {".text": (a, b)}, set(host.flags) if not f else set()))
            print(f"{name:<8} {a:05X}-{b:05X}" + (f"  ({len(runs[f])} matching)" if f else ""))
    units += new
    units.sort(key=lambda u: min(r[0] for r in u.ranges.values()))
    save_units(units, UNITS)


def next_symbol(syms: SymbolTable, addr: int, hi: int) -> int:
    nxt = [a for a in syms.sorted_addrs() if addr < a < hi and syms.get(a).kind == "func"]
    return min(nxt) if nxt else hi


# ---------------------------------------------------------------------- names

def cmd_names() -> None:
    syms = SymbolTable.load()
    have = {s.name for s in syms.by_addr.values()}
    renames: dict[int, str] = {}
    for _unit, name, _size, _tag, addr in load_matches():
        s = syms.get(addr)
        if s is not None and DUMMY_NAME.match(s.name) and name not in have:
            renames[addr] = name
            have.add(name)
    sizes: dict[str, int] = {}
    sized = {}
    for addr, (name, size) in referenced(sizes).items():
        s = syms.get(addr)
        if s is not None and DUMMY_NAME.match(s.name) and name not in have and addr not in renames:
            renames[addr] = name
            have.add(name)
        if s is not None and s.kind == "data" and s.name in (name, renames.get(addr)):
            sized[addr] = name
    dropped = 0
    for addr, name in renames.items():
        syms.get(addr).name = name
    for addr, name in sized.items():
        s = syms.get(addr)
        if sizes.get(name):
            # the analysis cut a variable up by access size: drop the pieces inside it
            for inner in syms.in_range(addr + 1, addr + sizes[name]):
                if DUMMY_NAME.match(inner.name):
                    del syms.by_addr[inner.addr]
                    dropped += 1
            syms._sorted = None
            s.size = sizes[name]
    syms._sorted = None
    syms.save()
    print(f"renamed {len(renames)} symbols, dropped {dropped} pieces of variables")


def referenced(sizes: dict[str, int]) -> dict[int, tuple[str, int]]:
    """What the matching functions' fixups name, at the sequel's addresses:
    externals (variables through DGROUP offsets, functions through far
    pointers) and the variables the ST25 file itself defines. Fills sizes
    with each variable's size in the ST25 objects."""
    import omf
    from project import DGROUP_PARA, lin, load_exe
    exe = load_exe()
    matches = {name: addr for _u, name, _s, _t, addr in load_matches()}
    seen: dict[str, set[int]] = defaultdict(set)
    reach: dict[str, int] = {}      # how far into a file's own variable the code reaches
    objs = [omf.parse_obj(o.read_bytes()) for o in sorted((ROOT / "build/st25").glob("*.obj"))]
    for m in objs:
        for e in m.externs:
            if e.communal and getattr(e, "size", 0):
                sizes.setdefault(e.name, e.size)
        for seg in m.segments:
            if seg.cls in ("DATA", "BSS", "CONST"):
                pubs = sorted((p.offset, p.name) for p in m.publics if p.seg == seg.index)
                for k, (off, name) in enumerate(pubs):
                    sizes.setdefault(name, (pubs[k + 1][0] if k + 1 < len(pubs) else seg.length) - off)
    for m in objs:
        for seg in m.segments:
            if not seg.cls.endswith("CODE"):
                continue
            pubs = sorted((p.offset, p.name) for p in m.publics if p.seg == seg.index)
            for k, (off, name) in enumerate(pubs):
                if name not in matches:
                    continue
                end = pubs[k + 1][0] if k + 1 < len(pubs) else seg.length
                for f in seg.fixups:
                    if not (off <= f.offset < end):
                        continue
                    at = matches[name] + f.offset - off
                    value = int.from_bytes(seg.data[f.offset:f.offset + 2], "little") + f.disp
                    if f.loc == omf.LOC_POINTER and f.target_method == omf.T_EXTDEF:
                        seen[m.ext(f.target_index).name].add(lin(exe.word(at + 2), exe.word(at)))
                        continue
                    if f.loc not in (omf.LOC_OFFSET, omf.LOC_OFFSET_LOADER) or not f.seg_relative:
                        continue
                    if f.target_method == omf.T_EXTDEF:
                        if value == 0:
                            seen[m.ext(f.target_index).name].add(lin(DGROUP_PARA, exe.word(at)))
                    elif f.target_method == omf.T_SEGDEF:
                        tseg = m.seg(f.target_index)
                        if tseg.cls not in ("DATA", "BSS"):
                            continue
                        own = [(o, n) for o, n in ((p.offset, p.name) for p in m.publics
                                                   if p.seg == tseg.index) if o <= value]
                        if own:
                            o, n = max(own)
                            if value - o < sizes.get(n, 1):
                                seen[n].add(lin(DGROUP_PARA, exe.word(at)) - (value - o))
                                reach[n] = max(reach.get(n, 2), value - o + 2)
    # an object's public runs to the next public, past any statics, so only
    # trust the part of a file's own variable that the code is seen to use
    for n in list(sizes):
        if n in reach:
            sizes[n] = min(sizes[n], reach[n])
        elif n not in {e.name for m in objs for e in m.externs if e.communal}:
            sizes[n] = 0
    out = {}
    for name, addrs in seen.items():
        if len(addrs) == 1:
            out[addrs.pop()] = (name, sizes.get(name, 0))
    return out


def cmd_relocs() -> None:
    import bisect
    import omf
    from project import DGROUP_PARA, lin, load_exe, load_ida
    exe = load_exe()
    ida = load_ida()
    code_heads = sorted(ea for ea, (_, k) in ida.heads.items() if k == "C")
    syms = SymbolTable.load()
    by_name = {s.name: s for s in syms.by_addr.values()}
    matches = {name: addr for _u, name, _s, _t, addr in load_matches()}
    path = ROOT / "config/relocs.txt"
    lines = path.read_text().splitlines()
    have = {int(ln.split()[0], 16) for ln in lines if ln.strip() and not ln.startswith("#")}
    added = []
    for obj in sorted((ROOT / "build/st25").glob("*.obj")):
        m = omf.parse_obj(obj.read_bytes())
        for seg in m.segments:
            if not seg.cls.endswith("CODE"):
                continue
            pubs = sorted((p.offset, p.name) for p in m.publics if p.seg == seg.index)
            for k, (off, name) in enumerate(pubs):
                if name not in matches:
                    continue
                end = pubs[k + 1][0] if k + 1 < len(pubs) else seg.length
                for f in seg.fixups:
                    if not (off <= f.offset < end) or f.loc not in (omf.LOC_OFFSET, omf.LOC_OFFSET_LOADER) \
                            or not f.seg_relative:
                        continue
                    at = matches[name] + f.offset - off
                    target = lin(DGROUP_PARA, exe.word(at))
                    s = syms.containing(target, lin(DGROUP_PARA, 0))
                    if s is None or s.kind != "data" or DUMMY_NAME.match(s.name) or s.name.startswith("a"):
                        continue
                    if f.target_method == omf.T_EXTDEF and m.ext(f.target_index).name != s.name:
                        continue
                    if target - s.addr >= max(s.size, 1) and target != s.addr:
                        continue
                    i = bisect.bisect_right(code_heads, at) - 1
                    insn = code_heads[i] if i >= 0 else None
                    if insn is None or insn in have or not (insn <= at < insn + ida.heads[insn][0]):
                        continue
                    # plain [addr] operands are already references (tools/split.py)
                    if any(op.optype == 2 and op.value & 0xFFFF == exe.word(at) for op in ida.ops.get(insn, [])):
                        continue
                    add = target - s.addr
                    added.append(f"{insn:05X}  {s.name}" + (f"+0x{add:X}" if add else "") + f"   # {name}")
                    have.add(insn)
    if added:
        path.write_text("\n".join(lines + ["", "# From ST25 functions that compile to the sequel's code (tools/st25port.py relocs)"]
                                   + added) + "\n")
    print(f"added {len(added)} entries to {path.relative_to(ROOT)}")


# ---------------------------------------------------------------------- src

def skip_literal(text: str, i: int) -> int:
    """Index after the string or character literal at i. An apostrophe that
    doesn't close within a few characters (a ; comment in an _asm block,
    "don't") is just a character."""
    q = text[i]
    j = i + 1
    while j < len(text) and text[j] != q and text[j] != "\n":
        j += 2 if text[j] == "\\" else 1
    if q == "'" and (j - i > 6 or j >= len(text) or text[j] != q):
        return i + 1
    return j + 1


def top_level_functions(text: str) -> list[tuple[str, int, int]]:
    """(name, start, end) of each function definition, start including the
    comment directly above it, end after the closing brace's line."""
    out = []
    i, n, depth = 0, len(text), 0
    stmt_start = 0
    while i < n:
        c = text[i]
        if text.startswith("/*", i):
            i = text.index("*/", i) + 2
            continue
        if text.startswith("//", i) or (c == "#" and (i == 0 or text[i - 1] == "\n")):
            j = i
            while True:                       # preprocessor lines may continue with backslash
                j = text.find("\n", j)
                if j < 0 or text[j - 1] != "\\":
                    break
                j += 1
            i = n if j < 0 else j + 1
            if depth == 0:
                stmt_start = i
            continue
        if c in "\"'":
            i = skip_literal(text, i)
            continue
        if c == "{":
            if depth == 0:
                header = re.sub(r"/\*.*?\*/|//[^\n]*", " ", text[stmt_start:i], flags=re.S)
                m = re.search(r"(\w+)\s*\([^;{}]*\)\s*(?:[^;{}()]*;\s*)*$", header, re.S)
                if m and "=" not in header:
                    open_at = i
                    d, j = 0, i
                    while True:
                        if text.startswith("/*", j):
                            j = text.index("*/", j) + 2
                            continue
                        if text[j] in "\"'":
                            j = skip_literal(text, j)
                            continue
                        if text[j] == "{":
                            d += 1
                        elif text[j] == "}":
                            d -= 1
                            if d == 0:
                                break
                        j += 1
                    end = text.find("\n", j)
                    end = n if end < 0 else end + 1
                    start = comment_start(text, stmt_start, open_at)
                    out.append((m.group(1), start, end))
                    i = end
                    stmt_start = end
                    continue
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                stmt_start = i + 1
        elif c == ";" and depth == 0:
            stmt_start = i + 1
        i += 1
    return out


def comment_start(text: str, stmt_start: int, open_at: int) -> int:
    """Start of the definition, including the comment lines right above it
    (each starting its own line, no blank line between, after stmt_start)."""
    head = text[stmt_start:open_at]
    start = stmt_start + len(head) - len(head.lstrip())
    while True:
        m = re.search(r"(?:^|\n)([ \t]*/\*(?:(?!\*/).)*\*/[ \t]*\n)$", text[stmt_start:start], re.S)
        if not m:
            return start
        start = stmt_start + m.start(1)


KEYWORDS = {"int", "char", "unsigned", "signed", "long", "short", "void", "far", "_far", "near",
            "_near", "huge", "const", "static", "register", "volatile", "struct", "union", "enum",
            "float", "double"}


def top_level_statements(text: str) -> list[tuple[int, int]]:
    """(start, end) of each top-level statement ending in ';' outside functions,
    preprocessor lines and comments (start includes a comment directly above)."""
    funcs = [(a, b) for _n, a, b in top_level_functions(text)]
    out = []
    i, n = 0, len(text)
    start = 0
    depth = 0
    while i < n:
        f = next(((a, b) for a, b in funcs if a <= i < b), None)
        if f:
            i = start = f[1]
            continue
        c = text[i]
        if text.startswith("/*", i):
            i = text.index("*/", i) + 2
            continue
        if c == "#" and (i == 0 or text[i - 1] == "\n") and depth == 0:
            j = i
            while True:                 # continued with backslashes
                j = text.find("\n", j)
                if j < 0 or text[j - 1] != "\\":
                    break
                j += 1
            i = start = n if j < 0 else j + 1
            continue
        if c in "\"'":
            i = skip_literal(text, i)
            continue
        if c in "{(":
            depth += 1
        elif c in "})":
            depth -= 1
        elif c == ";" and depth == 0:
            end = text.find("\n", i)
            end = n if end < 0 else end + 1
            # K&R parameter declarations run up to the function's '{'
            if not re.match(r"(?:[^;{}()]*;)*\s*\{", text[i + 1:i + 600]):
                out.append((comment_start(text, start, i), end))
            i = start = end
            continue
        i += 1
    return out


def declared_names(stmt: str) -> list[str]:
    """The variables a top-level definition defines ([] for prototypes,
    typedefs, externs and bare struct declarations)."""
    code = re.sub(r"/\*.*?\*/", " ", stmt, flags=re.S).strip()
    code = re.sub(r'"(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\'', '""', code)    # no commas from strings
    if re.match(r"(typedef|extern)\b", code):
        return []
    # cut initialisers (top level '=' up to the next top-level ',' or ';')
    decls, depth, cur, skip = [], 0, "", False
    for ch in code.rstrip(";"):
        if ch in "({[":
            depth += 1
        elif ch in ")}]":
            depth -= 1
        if depth == 0 and ch == "=":
            skip = True
            continue
        if depth == 0 and ch == ",":
            decls.append(cur)
            cur, skip = "", False
            continue
        if not skip:
            cur += ch
    decls.append(cur)
    if "{" in decls[0]:
        return []                       # struct/union/enum body
    # a function declarator (name followed by a parameter list) is a prototype
    for m in re.finditer(r"([A-Za-z_]\w*)\s*\(", decls[0]):
        if m.group(1) not in KEYWORDS:
            return []
    names = []
    for d in decls:
        d = re.sub(r"(?<=\))\s*\([^()]*\)", "", d)     # (*fp)(args): drop the args
        d = re.sub(r"\[[^\]]*\]", "", d)                  # and array sizes
        ids = [t for t in re.findall(r"[A-Za-z_]\w*", d) if t not in KEYWORDS]
        if ids:
            names.append(ids[-1])
    return names


def cmd_prunedata(files: list[str]) -> None:
    for f in files:
        path = ROOT / "src" / f"{f}.c"
        text = path.read_text()
        stmts = [(a, b, declared_names(text[a:b])) for a, b in top_level_statements(text)]
        data = [(a, b, names) for a, b, names in stmts if names]
        # everything but the definitions: functions, macros, prototypes
        rest, cur = "", 0
        for a, b, _names in data:
            rest += text[cur:a]
            cur = b
        rest += text[cur:]
        keep = set()
        changed = True
        while changed:                  # data used by kept data (tables of pointers) stays too
            changed = False
            pool = rest + "".join(text[a:b] for a, b, names in data if any(n in keep for n in names))
            for a, b, names in data:
                if not set(names) & keep and any(re.search(rf"\b{re.escape(n)}\b", pool) for n in names):
                    keep.update(names)
                    changed = True
        drop = [(a, b, names) for a, b, names in data if not set(names) & keep]
        for a, b, _names in sorted(drop, reverse=True):
            text = text[:a] + text[b:]
        text = re.sub(r"\n{3,}", "\n\n", text)
        path.write_text(text)
        print(f"{path.relative_to(ROOT)}: dropped {', '.join(n for _a, _b, ns in drop for n in ns) or 'nothing'}")


def cmd_add(unit: str, items: list[str], ref_file: str | None = None) -> None:
    import subprocess
    from project import load_units
    u = next(x for x in load_units(UNITS) if x.name == unit)
    lo, hi = u.ranges[".text"]
    ref = (ROOT / "ref/st25/src" / f"{ref_file or unit}.c").read_text()
    ref_funcs = {n: ref[a:b] for n, a, b in top_level_functions(ref)}
    path = ROOT / "src" / f"{unit}.c"
    syms = SymbolTable.load()
    renames = []
    wanted = []
    for item in items:
        name, _, addr = item.partition("@")
        a = int(addr, 16)
        s = syms.get(a)
        if s is None or s.kind != "func":
            sys.exit(f"add: no function at {addr}")
        if s.name != "_" + name:
            if not DUMMY_NAME.match(s.name):
                sys.exit(f"add: {addr} is {s.name}, not a placeholder")
            renames += [s.name, "_" + name]
        if name not in ref_funcs:
            sys.exit(f"add: no {name} in ref/st25/src/{ref_file or unit}.c")
        wanted.append((a, name))
    if renames:
        subprocess.run([sys.executable, str(ROOT / "tools/rename.py"), *renames], check=True,
                       stdout=subprocess.DEVNULL)
        syms = SymbolTable.load()
    order = {s.name[1:]: s.addr for s in syms.in_range(lo, hi) if s.kind == "func"}
    for a, name in sorted(wanted):
        text = path.read_text()
        have = {n: (x, y) for n, x, y in top_level_functions(text)}
        if name in have:
            print(f"{name}: already in {path.name}")
            continue
        later = sorted((order[n], n) for n in have if n in order and order[n] > a)
        at = have[later[0][1]][0] if later else len(text.rstrip("\n")) + 1
        block = ref_funcs[name].rstrip("\n") + "\n\n"
        if not later:
            block = "\n" + block.rstrip("\n") + "\n"
        path.write_text(text[:at] + block + text[at:])
        print(f"{name}: added at {a:05X}")
    restore_data(path, ref)


def restore_data(path: Path, ref: str) -> None:
    """Put back ST25 variables the file uses but no longer defines, each
    before the first function that followed it in ST25 and is in the file."""
    ref_stmts = [(a, b, declared_names(ref[a:b])) for a, b in top_level_statements(ref)]
    ref_funcs = [(a, n) for n, a, _b in top_level_functions(ref)]
    while True:
        text = path.read_text()
        defined = {n for a, b in top_level_statements(text) for n in declared_names(text[a:b])}
        rest = text
        missing = [(a, b, names) for a, b, names in ref_stmts if names and not set(names) & defined
                   and any(re.search(rf"\b{re.escape(n)}\b", rest) for n in names)]
        if not missing:
            return
        a, b, names = missing[0]
        have = {n: x for n, x, _y in top_level_functions(text)}
        nxt = next((have[n] for fa, n in ref_funcs if fa > a and n in have), None)
        at = nxt if nxt is not None else len(text)
        at = text.rfind("\n", 0, at) + 1 if at < len(text) and at and text[at - 1] != "\n" else at
        path.write_text(text[:at] + ref[a:b].rstrip("\n") + "\n\n" + text[at:])
        print(f"  restored {', '.join(names)}")


def cmd_src(files: list[str], force: bool) -> None:
    keep = defaultdict(set)
    for unit, name, _size, _tag, _addr in load_matches():
        keep[unit].add(name.lstrip("_"))
    for f in files:
        src = ROOT / "ref/st25/src" / f"{f}.c"
        out = ROOT / "src" / f"{f}.c"
        if out.exists() and not force:
            print(f"{out.relative_to(ROOT)} exists; skipped (--force to overwrite)")
            continue
        text = src.read_text()
        funcs = top_level_functions(text)
        dropped = [(n, a, b) for n, a, b in funcs if n not in keep[f]]
        for _n, a, b in sorted(dropped, key=lambda x: -x[1]):
            text = text[:a] + text[b:]
        text = re.sub(r"\n{3,}", "\n\n", text)
        out.write_text(text)
        print(f"{out.relative_to(ROOT)}: kept {len(funcs) - len(dropped)} of {len(funcs)} functions")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("cmd", choices=["units", "names", "relocs", "src", "prunedata", "add"])
    ap.add_argument("--ref", help="add: the ST25 file to copy from (default: the unit's name)")
    ap.add_argument("files", nargs="*")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()
    if args.cmd == "units":
        cmd_units()
    elif args.cmd == "names":
        cmd_names()
    elif args.cmd == "relocs":
        cmd_relocs()
    elif args.cmd == "prunedata":
        cmd_prunedata(args.files)
    elif args.cmd == "add":
        cmd_add(args.files[0], args.files[1:], args.ref)
    else:
        cmd_src(args.files, args.force)


if __name__ == "__main__":
    main()
