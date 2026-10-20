#!/usr/bin/env python3
"""Locate Microsoft C library modules inside the original EXE.

Each library module's code segment is turned into a byte pattern with its
fixup fields wildcarded and searched for in the EXE's code segments. The
fixups of placed modules are then read back from the EXE to recover the
addresses of the externals and data they reference.
"""

from __future__ import annotations

import re
import struct
import sys
from dataclasses import dataclass
from typing import Callable
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import omf  # noqa: E402
from omf2elf import ABSOLUTE_SYMBOLS  # noqa: E402
from project import LOAD_BASE, ROOT, Exe, IdaExport, lin  # noqa: E402

# Search order matters: a module name is only placed once, from the first library.
# MLIBCE is C 7.00's combined medium model library with the 8087 emulator; the game
# was built with /FPa, so the alternate math modules come from MLIBCA.
LIBS = ["MLIBCE.LIB", "MLIBCA.LIB", "GRAPHICS.LIB", "PGCHART.LIB"]
LIB_DIR = ROOT / "tools/C700/LIB"
MIN_FIXED = 12       # minimum non-wildcard bytes for a standalone match


@dataclass
class Placement:
    lib: str
    module: omf.Module
    seg: omf.Segment        # the module's code segment
    addr: int               # linear address in the EXE

    @property
    def end(self) -> int:
        return self.addr + self.seg.length

    @property
    def modname(self) -> str:
        n = self.module.name.replace("\\", "/").rsplit("/", 1)[-1]
        return n.rsplit(".", 1)[0].lower()


def _pattern(seg: omf.Segment) -> tuple[re.Pattern[bytes], int]:
    mask = bytearray(b"\x01" * seg.length)
    for f in seg.fixups:
        for k in range(f.size):
            if f.offset + k < seg.length:
                mask[f.offset + k] = 0
    parts = []
    for b, m in zip(seg.data[:seg.length], mask):
        parts.append(re.escape(bytes([b])) if m else b".")
    return re.compile(b"".join(parts), re.S), sum(mask)


def _module_key(m: omf.Module) -> tuple:
    return (m.name.lower(), tuple(sorted(p.name for p in m.publics)))


def find_modules(exe: Exe, ida: IdaExport, code_segs: list[tuple[int, int]]) -> list[Placement]:
    candidates: list[tuple[str, omf.Module, omf.Segment, list[int], int]] = []
    for lib in LIBS:
        path = LIB_DIR / lib
        if not path.exists():
            continue
        for m in omf.load(str(path)):
            for s in m.segments:
                if s.cls != "CODE" or s.length == 0:
                    continue
                pat, fixed = _pattern(s)
                hits = []
                for start, end in code_segs:
                    blob = exe.bytes(start, end)
                    p = 0
                    while True:
                        mt = pat.search(blob, p)
                        if not mt:
                            break
                        hits.append(start + mt.start())
                        p = mt.start() + 1
                candidates.append((lib, m, s, hits, fixed))

    placed: list[Placement] = []
    taken: list[tuple[int, int]] = []

    def free(a: int, n: int) -> bool:
        return all(a + n <= s or a >= e for s, e in taken)

    def place(lib, m, s, a):
        placed.append(Placement(lib, m, s, a))
        taken.append((a, a + s.length))

    # Pass 1: unique, sufficiently specific hits. The same module may appear in
    # several libraries (the first library wins), but modules that merely share
    # a name (LIBH's far strchr.asm vs MLIBCR's near one) are told apart by
    # their publics.
    seen_names: set[str] = set()
    pending = []
    for lib, m, s, hits, fixed in candidates:
        key = _module_key(m)
        if len(hits) == 1 and fixed >= MIN_FIXED and key not in seen_names and free(hits[0], s.length):
            place(lib, m, s, hits[0])
            seen_names.add(key)
        else:
            pending.append((lib, m, s, hits, fixed))

    # Pass 2: ambiguous/short modules that sit directly next to a placed module
    changed = True
    while changed:
        changed = False
        ends = {p.end for p in placed} | {p.end + 1 for p in placed}
        starts = {p.addr for p in placed}
        rest = []
        for lib, m, s, hits, fixed in pending:
            key = _module_key(m)
            ok = [a for a in hits if key not in seen_names and free(a, s.length)
                  and (a in ends or a + s.length in starts or a + s.length + 1 in starts)]
            if len(ok) == 1:
                place(lib, m, s, ok[0])
                seen_names.add(key)
                changed = True
            else:
                rest.append((lib, m, s, hits, fixed))
        pending = rest

    placed.sort(key=lambda p: p.addr)
    return placed


@dataclass
class Recovered:
    names: dict[int, tuple[str, str]]          # addr -> (name, kind func/data)
    data_bases: dict[tuple[str, str], int]     # (module, segment) -> linear address


def iter_fixups(exe: Exe, m: omf.Module, seg: omf.Segment, addr: int, dgroup: int,
                seg_base: Callable[[int], int]):
    """(fixup, address, target, displacement) for the offset and pointer
    fixups of a library module's segment placed at addr in the EXE."""
    for f in seg.fixups:
        at = addr + f.offset
        if f.loc not in (omf.LOC_OFFSET, omf.LOC_OFFSET_LOADER, omf.LOC_POINTER):
            continue
        word = struct.unpack_from("<H", exe.image, at - LOAD_BASE)[0]
        existing = struct.unpack_from("<H", seg.data, f.offset)[0]
        if f.loc == omf.LOC_POINTER:
            segv = exe.relocs.get(at + 2)
            if segv is None:
                continue
            target = lin(segv, word)
        elif not f.seg_relative:
            rel = word if word < 0x8000 else word - 0x10000
            target = at + 2 + rel
        else:
            # segment relative: data in DGROUP or code in the same segment
            frame_is_group = f.frame_method == omf.F_GRPDEF or (
                f.frame_method == omf.F_TARGET and f.target_method != omf.T_EXTDEF
                and m.group_of(f.target_index) is not None)
            if f.target_method == omf.T_EXTDEF or frame_is_group:
                target = dgroup + word
            else:
                target = seg_base(at) + word
        yield f, at, target, f.disp + existing


def recover(exe: Exe, placed: list[Placement], dgroup: int,
            seg_base: Callable[[int], int]) -> Recovered:
    """seg_base(addr) gives the linear start of the code segment containing addr."""
    names: dict[int, tuple[str, str]] = {}
    bases: dict[tuple[str, str], int] = {}
    for p in placed:
        for pub in p.module.publics:
            if pub.seg == p.seg.index:
                names[p.addr + pub.offset] = (pub.name, "func")
    code_publics = {n for n, _ in names.values()}
    for p in placed:
        m = p.module
        for f, at, target, disp in iter_fixups(exe, m, p.seg, p.addr, dgroup, seg_base):
            if f.target_method == omf.T_EXTDEF:
                ext = m.ext(f.target_index)
                if ext.communal or ext.name in ABSOLUTE_SYMBOLS or ext.name in code_publics:
                    continue
                kind = "func" if f.loc == omf.LOC_POINTER or not f.seg_relative else "data"
                if disp == 0:
                    names.setdefault(target, (ext.name, kind))
            elif f.target_method == omf.T_SEGDEF:
                tseg = m.seg(f.target_index)
                if tseg.cls in ("DATA", "CONST", "BSS") and f.seg_relative:
                    bases.setdefault((p.modname, tseg.name), target - disp)
    # Publics in each module's data segments
    by_mod = {p.modname: p for p in placed}
    for (modname, segname), base in bases.items():
        m = by_mod[modname].module
        for pub in m.publics:
            if pub.seg and m.seg(pub.seg).name == segname:
                names.setdefault(base + pub.offset, (pub.name, "data"))
    return Recovered(names, bases)


def main() -> None:
    from project import load_exe, load_ida
    exe = load_exe()
    ida = load_ida()
    code = [(s.start, s.end) for s in ida.segs if s.start < ida.seg_by_name("seg003").start]
    placed = find_modules(exe, ida, code)
    for p in placed:
        print(f"{p.addr:05X}-{p.end:05X}  {p.lib:<12} {p.modname}")
    print(f"{len(placed)} modules, {sum(p.seg.length for p in placed)} bytes")


if __name__ == "__main__":
    main()
