#!/usr/bin/env python3
"""Generate config/symbols.txt and config/units.txt from the analysis.

Run once to bootstrap the project. Re-running it (e.g. after a fresh IDA
export) keeps every existing symbol and name in symbols.txt, only replacing
IDA placeholder names, and adds newly identified library modules to an
existing units.txt. --force regenerates units.txt from scratch.

  * functions and data labels come from build/analysis.txt (tools/analyze.py)
  * C library modules are located in the EXE (tools/libmatch.py); their
    code and data become lib units with the real library names
  * the game code of each packed code segment (everything before the C
    runtime) becomes one unit, to be split into its .C files as they are
    identified (LINK /PACKCODE merged them; nothing marks the boundaries)
  * leftover parts of the runtime's _TEXT, the far data segments and DGROUP
    become gap units that can be split further by hand
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import libmatch  # noqa: E402
from omf2elf import module_basename  # noqa: E402
from project import (ALIASES, DUMMY_NAME, SYMBOLS, UNITS, IdaExport, Sym, SymbolTable,  # noqa: E402
                     Unit, load_exe, load_ida, load_units, save_units)

DGROUP_SEG = "dseg"
STACK_SEG = "stack"
FAR_SEG_LIMIT = "seg003"  # code segments come before the first far data segment
PAD_MAX = 16              # gaps up to this size made of 00/90 bytes are alignment padding


LITERAL_NAME = re.compile(r"^_?a[A-Z0-9]|^_?asc(_\d+)?$")


def generated(name: str) -> bool:
    """A placeholder or literal name the analysis made up: replaced on every run."""
    return bool(DUMMY_NAME.match(name) or LITERAL_NAME.match(name))


def linker_name(name: str) -> str:
    """C linker name for an IDA name.

    IDA (FLIRT style) names drop the C underscore, so add it back. Dummy names
    get one too (sub_18A64 -> _sub_18A64) so C code can use them unchanged.
    IDA's auto-named string literals (aSomeText) have no linker name.
    """
    if name.startswith("a") and name[1:2].isupper() or name[:1].isdigit():
        return name
    return "_" + name


def build_symbols(ida: IdaExport, rec: libmatch.Recovered, old: SymbolTable | None) -> SymbolTable:
    syms = SymbolTable()
    func_ranges = sorted((s, e) for s, (e, _, _) in ida.funcs.items())

    def in_func(ea: int) -> bool:
        import bisect
        i = bisect.bisect_right(func_ranges, (ea, 1 << 32)) - 1
        return i >= 0 and func_ranges[i][0] < ea < func_ranges[i][1]

    for start, (end, flags, name) in ida.funcs.items():
        f = set()
        if flags & 1:
            f.add("noreturn")
        if not flags & 2:
            f.add("near")
        syms.add(Sym(start, "func", end - start, linker_name(name), f))

    for ea, (name, _user) in ida.names.items():
        if ea in ida.funcs or name.startswith(("loc_", "locret_")):
            continue
        kind = ida.heads.get(ea, (0, "U"))[1]
        if kind == "C":
            if in_func(ea):
                continue
            syms.add(Sym(ea, "label", 0, linker_name(name)))
        elif not in_func(ea):
            syms.add(Sym(ea, "data", 0, linker_name(name)))

    for ea, (name, kind) in rec.names.items():
        s = syms.get(ea)
        if s is not None:
            s.name = name
            s.flags.add("lib")
        else:
            syms.add(Sym(ea, kind, 0, name, {"lib"}))

    if old is not None:
        for s in syms.by_addr.values():
            o = old.get(s.addr)
            if o is not None and not generated(o.name):
                if "lib" not in s.flags or "lib" in o.flags:
                    s.name = o.name
                s.flags |= o.flags
        # symbols added by hand
        for o in old.by_addr.values():
            if syms.get(o.addr) is None and not generated(o.name):
                syms.add(o)

    # A named variable keeps the size it was given: drop the analysis's
    # placeholder pieces of it (an access to its second word)
    named_sizes = {}
    if old is not None:
        for o in old.by_addr.values():
            if o.kind == "data" and o.size and not generated(o.name):
                named_sizes[o.addr] = o.size
                for inner in syms.in_range(o.addr + 1, o.addr + o.size):
                    if DUMMY_NAME.match(inner.name):
                        del syms.by_addr[inner.addr]
        syms._sorted = None

    # Data sizes run to the next symbol in the same segment
    addrs = syms.sorted_addrs()
    for i, a in enumerate(addrs):
        s = syms.by_addr[a]
        if s.kind == "func":
            continue
        seg = ida.seg_at(a)
        nxt = addrs[i + 1] if i + 1 < len(addrs) else seg.end
        s.size = max(0, min(nxt, seg.end) - a)
        if a in named_sizes:
            s.size = min(s.size, named_sizes[a])
    return syms


def lib_unit(p: libmatch.Placement, taken: set[str]) -> Unit:
    name = f"lib/{p.modname}"
    if name in taken:
        name = f"lib/{p.lib.split('.')[0].lower()}_{p.modname}"
    u = Unit(name, flags={f"lib={p.lib}:{module_basename(p.module.name)}"})
    u.ranges[".text"] = (p.addr, p.end)
    return u


def update_lib_units(exe, ida: IdaExport, units: list[Unit], placed: list[libmatch.Placement]) -> list[Unit]:
    """Add library modules found since units.txt was written, carving them
    out of the asm/ units that covered their code."""
    have = {u.ranges[".text"][0] for u in units if u.lib and ".text" in u.ranges}
    for p in placed:
        if p.addr in have:
            continue
        host = next((u for u in units if ".text" in u.ranges
                     and u.ranges[".text"][0] <= p.addr < u.ranges[".text"][1]), None)
        if host is not None and not host.name.startswith("asm/"):
            print(f"  skipping {p.modname} at {p.addr:05X}: inside {host.name}")
            continue
        units.append(lib_unit(p, {x.name for x in units}))
        print(f"  added {units[-1].name} {p.addr:05X}-{p.end:05X}")
        if host is None:
            continue
        units.remove(host)
        lo, hi = host.ranges[".text"]
        for a, b in ((lo, p.addr), (p.end, hi)):
            a, b = item_extent(exe, ida, a, b)
            if b > a and not is_padding(exe, a, b):
                units.append(Unit(f"asm/t{a:05X}", {".text": (a, b)}))
    units.sort(key=lambda u: min(r[0] for r in u.ranges.values()))
    return units


def item_extent(exe, ida: IdaExport, start: int, end: int) -> tuple[int, int]:
    """First and last+1 address of real items in [start, end), ignoring pad bytes."""
    eas = sorted(ea for ea in ida.heads if start <= ea < end)

    def pad(ea: int) -> bool:
        return (ida.heads[ea][0] == 1 and ea not in ida.funcs
                and exe.bytes(ea, ea + 1)[0] in (0, 0x90))

    while eas and pad(eas[0]):
        eas.pop(0)
    while eas and pad(eas[-1]):
        eas.pop()
    if not eas:
        return start, start
    return eas[0], eas[-1] + ida.heads[eas[-1]][0]


def is_padding(exe, start: int, end: int) -> bool:
    return end - start <= PAD_MAX and all(b in (0, 0x90) for b in exe.bytes(start, end))


def build_units(exe, ida: IdaExport, placed: list[libmatch.Placement],
                rec: libmatch.Recovered, syms: SymbolTable) -> list[Unit]:
    units: list[Unit] = []
    claimed: list[tuple[int, int]] = []

    # Library units: code, plus the module's DGROUP pieces when known
    for p in placed:
        u = lib_unit(p, {x.name for x in units})
        u.ranges[".text"] = (p.addr, p.end)
        claimed.append((p.addr, p.end))
        for segname, sec in (("_DATA", ".data"), ("CONST", ".rodata"), ("_BSS", ".bss")):
            base = rec.data_bases.get((p.modname, segname))
            seg = p.module.seg_by_name(segname)
            if base is not None and seg is not None and seg.length:
                u.ranges[sec] = (base, base + seg.length)
                claimed.append((base, base + seg.length))
        units.append(u)

    def gaps(start: int, end: int) -> list[tuple[int, int]]:
        out = []
        cur = start
        for s, e in sorted(c for c in claimed if c[1] > start and c[0] < end):
            if s > cur:
                out.append((cur, s))
            cur = max(cur, e)
        if cur < end:
            out.append((cur, end))
        return out

    dgroup = ida.seg_by_name(DGROUP_SEG)
    first_code_data = ida.seg_by_name(FAR_SEG_LIMIT).start
    runtime = min((p.addr for p in placed), default=first_code_data)
    for seg in ida.segs:
        if seg.start >= dgroup.start:
            break
        if seg.start >= first_code_data:
            units.append(Unit(f"far/{seg.name}", {".data": (seg.start, seg.end)}))
            continue
        for gs, ge in gaps(seg.start, seg.end):
            if gs < runtime:
                # the segment's game code, up to the C runtime
                ge = min(ge, runtime)
                lo, hi = item_extent(exe, ida, gs, ge)
                if hi > lo:
                    units.append(Unit(seg.name, {".text": (lo, hi)}))
                gs = max(gs, runtime)
                if gs >= ge:
                    continue
            lo, hi = item_extent(exe, ida, gs, ge)
            if hi <= lo or is_padding(exe, gs, ge):
                continue
            units.append(Unit(f"asm/t{lo:05X}", {".text": (lo, hi)}))

    # DGROUP: everything not owned by a library module, split by class
    edata = next((s.addr for s in syms.by_addr.values() if s.name in ("_edata", "__edata")), None)
    end = next((s.addr for s in syms.by_addr.values() if s.name in ("_end", "__end")), dgroup.end)
    # Class DATA (game _DATA, then library _DATA) precedes class CONST, which
    # starts with the game's CONST (string literals under /qc)
    lib_data_ends = [u.ranges[".data"][1] for u in units if u.lib and ".data" in u.ranges]
    const_start = max(lib_data_ends) if lib_data_ends else edata
    for gs, ge in gaps(dgroup.start, dgroup.end):
        if is_padding(exe, gs, ge) and ge - gs <= 3:
            continue
        pieces = []
        for bound in (const_start, edata, end):
            if bound is not None and gs < bound < ge:
                pieces.append(bound)
        cur = gs
        for b in pieces + [ge]:
            if b - cur > 0:
                if edata is not None and cur >= edata:
                    sec = ".bss"
                elif const_start is not None and cur >= const_start:
                    sec = ".rodata"
                else:
                    sec = ".data"
                if cur >= end:
                    sec = ".bss"
                units.append(Unit(f"data/d{cur:05X}", {sec: (cur, b)}))
            cur = b
    stack = ida.seg_by_name(STACK_SEG)
    units.append(Unit("data/stack", {".bss": (stack.start, stack.end)}))

    units.sort(key=lambda u: min(r[0] for r in u.ranges.values()))
    return units


def write_aliases(placed: list[libmatch.Placement], rec: libmatch.Recovered,
                  syms: SymbolTable, path: Path = ALIASES) -> None:
    """config/aliases.txt: library publics sharing an address -> the name in symbols.txt.

    The compiler may reference either name; tools/omf2elf.py renames external
    references so they agree with the target objects.
    """
    by_name = {s.name for s in syms.by_addr.values()}
    lines = ["# alias  canonical   (generated by tools/init_config.py)"]
    for p in placed:
        m = p.module
        groups: dict[tuple[int, int], list[str]] = {}
        for pub in m.publics:
            if pub.seg:
                groups.setdefault((pub.seg, pub.offset), []).append(pub.name)
        for names in groups.values():
            if len(names) < 2:
                continue
            canon = next((n for n in names if n in by_name), None)
            if canon is None:
                continue
            lines += [f"{n}  {canon}" for n in names if n != canon]
    path.write_text("\n".join(lines) + "\n")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("--force", action="store_true", help="overwrite existing units.txt")
    args = ap.parse_args()

    exe = load_exe()
    ida = load_ida(exe, verbose=True)
    dgroup = ida.seg_by_name(DGROUP_SEG).start
    code = [(s.start, s.end) for s in ida.segs if s.start < ida.seg_by_name(FAR_SEG_LIMIT).start]

    print("matching library modules...")
    placed = libmatch.find_modules(exe, ida, code)

    def seg_base(a: int) -> int:
        return ida.seg_at(a).start & ~0xF

    rec = libmatch.recover(exe, placed, dgroup, seg_base)
    print(f"  {len(placed)} modules, {len(rec.names)} names recovered")

    old = SymbolTable.load(SYMBOLS) if SYMBOLS.exists() else None
    syms = build_symbols(ida, rec, old)
    syms.save(SYMBOLS)
    print(f"wrote {SYMBOLS} ({len(syms.by_addr)} symbols)")
    write_aliases(placed, rec, syms)

    if UNITS.exists() and not args.force:
        print(f"updating library units in {UNITS} (use --force to regenerate)")
        save_units(update_lib_units(exe, ida, load_units(UNITS), placed), UNITS)
        return
    units = build_units(exe, ida, placed, rec, syms)
    save_units(units, UNITS)
    print(f"wrote {UNITS} ({len(units)} units)")


if __name__ == "__main__":
    main()
