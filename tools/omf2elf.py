#!/usr/bin/env python3
"""Convert a Microsoft C OMF object (or one module of a LIB) to an ELF object for objdiff.

Section mapping:   class CODE -> .text, CONST -> .rodata, class BSS -> .bss,
                   _DATA/other data -> .data, debug segments are dropped.
Relocations follow the same conventions as tools/split.py:
  * near jumps/calls within the same (ungrouped) code segment are resolved in place
  * R_386_16 near offset, R_386_PC16 self-relative, R_386_SEG16 segment base,
    R_386_FAR16 seg:off pair. Group frames (DGROUP) are named by the group.
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import omf  # noqa: E402
from elf16 import (R_386_16, R_386_8, R_386_FAR16, R_386_PC16, R_386_SEG16,  # noqa: E402
                   ElfWriter, literal_name, number_duplicates)

DEBUG_CLASSES = {"DEBSYM", "DEBTYP"}

# Absolute publics defined by the MSC 6.00 libraries. LINK adds their values
# in place: the FI?RQQ/FJ?RQQ fixups turn 8087 instructions into INT 34h-3Dh
# emulator calls. These are applied directly instead of becoming relocations.
ABSOLUTE_SYMBOLS = {
    "FIARQQ": 0xFE32, "FJARQQ": 0x4000, "FICRQQ": 0x0E32, "FJCRQQ": 0xC000,
    "FIDRQQ": 0x5C32, "FIERQQ": 0x1632, "FISRQQ": 0x0632, "FJSRQQ": 0x8000,
    "FIWRQQ": 0xA23D,
    "__aDBdoswp": 0xD6D6, "__aDBused": 0xD6D6, "__acrtused": 0x9876, "__acrtmsg": 0x9876,
    "__execmsg": 0x9876, "__fltused": 0x9876, "__AHINCR": 0x1000, "__AHSHIFT": 0x000C,
}


def section_name(seg: omf.Segment, code_count: dict[str, int]) -> str | None:
    if seg.cls in DEBUG_CLASSES:
        return None
    if seg.cls.endswith("CODE"):
        code_count.setdefault("n", 0)
        code_count["n"] += 1
        return ".text" if code_count["n"] == 1 else f".text.{seg.name}"
    if seg.name == "CONST":
        return ".rodata"
    if seg.cls.endswith("BSS") or seg.name in ("_BSS", "c_common"):
        return ".bss" if seg.name == "_BSS" else f".bss.{seg.name}"
    if seg.name == "_DATA":
        return ".data"
    return f".data.{seg.name}"


def load_aliases(path: Path = Path(__file__).resolve().parent.parent / "config/aliases.txt") -> dict[str, str]:
    """Library publics with several names at one address -> the name the target objects use."""
    out = {}
    if path.exists():
        for line in path.read_text().splitlines():
            f = line.split("#", 1)[0].split()
            if len(f) == 2:
                out[f[0]] = f[1]
    return out


ALIASES = load_aliases()


def literal_offsets(unit: str) -> set[int] | None:
    """Offsets in unit's .data where config/symbols.txt has a string
    literal (a generated name): where the target side names a literal."""
    import re
    from project import UNITS, SymbolTable, load_units
    try:
        u = next(x for x in load_units(UNITS) if x.name == unit)
    except StopIteration:
        return None
    if ".data" not in u.ranges:
        return None
    lo, hi = u.ranges[".data"]
    gen = re.compile(r"^_?a[A-Z0-9]|^_?asc(_\d+)?$")
    return {s.addr - lo for s in SymbolTable.load().in_range(lo, hi) if gen.match(s.name)}


def convert(mod: omf.Module, unit: str | None = None) -> ElfWriter:
    w = ElfWriter()
    counter: dict[str, int] = {}
    secname: dict[int, str] = {}
    for seg in mod.segments:
        name = section_name(seg, counter)
        if name is None or seg.length == 0:
            continue
        secname[seg.index] = name
        bss = name.startswith(".bss") or not any(seg.initialized)
        if bss and not name.startswith(".bss"):
            name = f".bss.{seg.name}"
        if not name.startswith(".text"):
            # LEDATA may run past a short segment; keep exactly seg.length bytes
            seg.data = seg.data[:seg.length]
        secname[seg.index] = name
        align = {1: 1, 2: 2, 3: 16, 4: 256, 5: 4}.get(seg.align, 1)
        w.add_section(name, None if bss else bytes(seg.data), seg.length, align)

    # Public symbols, sized by the next public in the same segment
    by_seg: dict[int, list[omf.Public]] = {}
    for p in mod.publics:
        if p.seg in secname:
            by_seg.setdefault(p.seg, []).append(p)
    public_loc: dict[str, tuple[int, int]] = {}
    for segi, pubs in by_seg.items():
        seg = mod.seg(segi)
        pubs.sort(key=lambda p: p.offset)
        sec = secname[segi]
        kind = "func" if sec.startswith(".text") else "object"
        for i, p in enumerate(pubs):
            end = pubs[i + 1].offset if i + 1 < len(pubs) else seg.length
            if kind == "func" and end - p.offset > 1 and seg.data[end - 1] == 0x90:
                end -= 1        # the nop that word-aligns the next function (tools/split.py too)
            w.add_symbol(p.name, sec, p.offset, end - p.offset, kind, local=p.local)
            public_loc[p.name] = (segi, p.offset)

    for seg in mod.segments:
        if seg.index not in secname:
            continue
        sec = secname[seg.index]
        own_group = mod.group_of(seg.index)
        for f in seg.fixups:
            _apply_fixup(w, mod, seg, sec, own_group, f, secname, public_loc)
    lits = literal_offsets(unit) if unit else None
    unit = module_basename(mod.name).rsplit(".", 1)[0]
    _name_data_targets(w, unit, lits)
    return w


def _long_literal(data, off: int) -> bool:
    """A string literal starts at off, and isn't a single character (more
    likely a field of a struct, like an int under 0x100)."""
    if not data or not literal_name(data, off):
        return False
    end = bytes(data).find(b"\0", off)
    return end - off != 1


def _name_data_targets(w: ElfWriter, unit: str = "", lits: set[int] | None = None) -> None:
    """Give unnamed data (string literals, statics) local symbols.

    References to them are section relative. Each referenced offset gets a
    symbol ($rodata_00AC, and $bss_<unit>_0014 so the target can name a
    static by the unit it belongs to) so relocations compare by address like the target's
    named symbols, and offset 0 always gets one: objdiff only compares data
    up to the end of the last symbol in a section.
    """
    data_secs = [n for n, s in w.sections.items() if not n.startswith(".text")]
    targets: dict[str, set[int]] = {n: {0} for n in data_secs}
    # A reference into a named variable (&tab[2], the segment half of a far
    # pointer) is written symbol+offset, as the target side names it
    named = [s for s in w.symbols.values() if s.section in targets and not s.local and s.size]
    for sec in w.sections.values():
        for i, (off, rtype, sym, addend) in enumerate(sec.relocs):
            if sym in targets and rtype != R_386_PC16:
                # (but not a string literal that the variable's size runs over:
                # a public's size goes to the next public, past any literals)
                inside = [s for s in named if s.section == sym and s.value <= addend < s.value + s.size
                          and not (s.value < addend and ((addend in lits) if lits and sym == ".data"
                                                         else _long_literal(w.sections[sym].data, addend)))]
                if inside:
                    sec.relocs[i] = (off, rtype, inside[0].name, addend - inside[0].value)
    for sec in w.sections.values():
        for off, rtype, sym, addend in sec.relocs:
            if sym in targets and rtype != R_386_PC16:
                targets[sym].add(addend)
    labels: dict[tuple[str, int], str] = {}
    for name, offs in targets.items():
        size = w.sections[name].size
        data = w.sections[name].data
        taken = {s.value for s in w.symbols.values() if s.section == name}
        offs = sorted(o for o in offs if 0 <= o < size and o not in taken)
        # string literals are named by their text (elf16.literal_name), the rest by offset
        names = number_duplicates([(literal_name(data, o) if data else None) or (f"${name[1:]}_{unit}_{o:04X}" if name.startswith(".bss") and unit
                                       else f"${name[1:]}_{o:04X}")
                                   for o in offs])
        allofs = sorted(set(offs) | taken)
        for off, local in zip(offs, names):
            later = [o for o in allofs if o > off]
            end = later[0] if later else size
            w.add_symbol(local, name, off, end - off, "object", local=True)
            labels[(name, off)] = local
    for sec in w.sections.values():
        for i, (off, rtype, sym, addend) in enumerate(sec.relocs):
            if (sym, addend) in labels:
                sec.relocs[i] = (off, rtype, labels[(sym, addend)], 0)


def _apply_fixup(w: ElfWriter, mod: omf.Module, seg: omf.Segment, sec: str,
                 own_group: omf.Group | None, f: omf.Fixup, secname: dict[int, str],
                 public_loc: dict[str, tuple[int, int]]) -> None:
    data = w.sections[sec].data
    # Microsoft LINK adds the existing field contents to the fixup value
    existing = struct.unpack_from("<h", data, f.offset)[0] if f.size >= 2 else data[f.offset]
    disp = f.disp + existing

    # Resolve the target to (symbol, addend) and its segment index if local
    tseg = None
    toff = 0
    if f.target_method == omf.T_EXTDEF and mod.ext(f.target_index).name in ABSOLUTE_SYMBOLS:
        value = ABSOLUTE_SYMBOLS[mod.ext(f.target_index).name] + f.disp
        if f.size >= 2:
            struct.pack_into("<H", data, f.offset, (struct.unpack_from("<H", data, f.offset)[0] + value) & 0xFFFF)
        else:
            data[f.offset] = (data[f.offset] + (value >> 8 if f.loc == omf.LOC_HIBYTE else value)) & 0xFF
        return
    if f.target_method == omf.T_EXTDEF:
        sym = ALIASES.get(mod.ext(f.target_index).name, mod.ext(f.target_index).name)
        if sym in public_loc:
            tseg, toff = public_loc[sym]
            toff += disp
        addend = disp
    elif f.target_method == omf.T_SEGDEF:
        tseg = f.target_index
        toff = disp
        sym = secname.get(tseg, mod.seg(tseg).name)
        addend = disp
    elif f.target_method == omf.T_GRPDEF:
        sym = mod.group(f.target_index).name
        addend = disp
    else:
        raise omf.OmfError(f"unsupported target method {f.target_method}")

    # Frame group, if any (offsets are then relative to the group)
    frame_group = None
    if f.frame_method == omf.F_GRPDEF:
        frame_group = mod.group(f.frame_index)
    elif f.frame_method == omf.F_TARGET and tseg is not None:
        frame_group = mod.group_of(tseg)

    same_seg = tseg == seg.index and own_group is None and frame_group is None

    if f.loc in (omf.LOC_OFFSET, omf.LOC_OFFSET_LOADER):
        if same_seg and not f.seg_relative:
            # near jump/call within the segment: position independent
            struct.pack_into("<H", data, f.offset, (toff - (f.offset + 2)) & 0xFFFF)
            return
        # absolute offsets into the own segment stay relocations: in the EXE
        # they are relative to the frame, which may start before the module
        if f.seg_relative:
            w.add_reloc(sec, f.offset, R_386_16, sym, addend)
        else:
            w.add_reloc(sec, f.offset, R_386_PC16, sym, addend - 2)
    elif f.loc == omf.LOC_BASE:
        if frame_group is not None:
            sym = frame_group.name
        w.add_reloc(sec, f.offset, R_386_SEG16, sym, 0)
    elif f.loc == omf.LOC_POINTER:
        w.add_reloc(sec, f.offset, R_386_FAR16, sym, addend)
    elif f.loc in (omf.LOC_LOBYTE, omf.LOC_HIBYTE):
        if same_seg and not f.seg_relative:
            data[f.offset] = (toff - (f.offset + 1)) & 0xFF
            return
        w.add_reloc(sec, f.offset, R_386_8, sym, addend)
    else:
        raise omf.OmfError(f"unsupported fixup location {f.loc}")


def module_basename(name: str) -> str:
    """Library module name without directory, lower case (e.g. dos\\nmsghdr.asm -> nmsghdr.asm)."""
    return name.replace("\\", "/").rsplit("/", 1)[-1].lower()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("input", help="OMF .OBJ or .LIB")
    ap.add_argument("output", help="output ELF .o")
    ap.add_argument("--module", help="module name to extract from a LIB")
    args = ap.parse_args()
    mods = omf.load(args.input)
    if args.module:
        want = args.module.lower()
        mods = [m for m in mods if want in (m.name.lower(), module_basename(m.name))]
        if not mods:
            sys.exit(f"omf2elf: module {args.module} not found in {args.input}")
    convert(mods[0]).write(args.output)


if __name__ == "__main__":
    main()
