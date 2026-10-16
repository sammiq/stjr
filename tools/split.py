#!/usr/bin/env python3
"""Split the original EXE into per-unit ELF "target" objects for objdiff.

For each unit in config/units.txt the bytes of its ranges are copied into
.text/.data/.rodata/.bss sections, symbols come from config/symbols.txt and
relocations are reconstructed:

  * segment fixups from the MZ relocation table  -> R_386_SEG16 / R_386_FAR16
  * near offsets IDA identified as references    -> R_386_16
  * near calls/jumps into another unit            -> R_386_PC16

Near jumps and calls that stay inside a unit's own code get no relocation,
matching what tools/omf2elf.py does for compiled objects.
"""

from __future__ import annotations

import argparse
import bisect
import sys
from pathlib import Path

import iced_x86 as ix

sys.path.insert(0, str(Path(__file__).parent))
import libmatch  # noqa: E402
import omf  # noqa: E402
from elf16 import (R_386_16, R_386_FAR16, R_386_PC16, R_386_SEG16,  # noqa: E402
                   ElfWriter, literal_name, number_duplicates)
from omf2elf import ABSOLUTE_SYMBOLS, ALIASES, module_basename  # noqa: E402
from project import (ROOT, Exe, IdaExport, SymbolTable, Unit,  # noqa: E402
                     DUMMY_NAME, lin, load_exe, load_ida, load_units)

DGROUP_SEG = "dseg"
STACK_SEG = "stack"


class Splitter:
    def __init__(self, exe: Exe, ida: IdaExport, syms: SymbolTable, units: list[Unit],
                 overrides: dict[int, tuple[str, int] | None] | None = None):
        self.overrides = overrides or {}
        self.exe = exe
        self.ida = ida
        self.syms = syms
        self.units = units
        dseg = ida.seg_by_name(DGROUP_SEG)
        self.dgroup = dseg.start
        self.dgroup_para = (dseg.start >> 4) - 0x1000
        self.dgroup_end = ida.seg_by_name(STACK_SEG).end
        # (start, end, unit, section) sorted for address lookup
        self.ranges = sorted((r[0], r[1], u, sec) for u in units for sec, r in u.ranges.items())
        self.range_starts = [r[0] for r in self.ranges]
        self._decode_missed_functions()
        self.code_heads = sorted(ea for ea, (_, k) in ida.heads.items() if k == "C")
        self.data_heads = sorted(ea for ea, (_, k) in ida.heads.items() if k != "C")
        self.relocs_sorted = sorted(exe.relocs)
        self.by_name = {s.name: s for s in syms.by_addr.values()}
        # DGROUP segment word -> first far address reached through it (QC far data)
        self.segword_users: dict[int, int] = {}

    # ------------------------------------------------------------------ lookup helpers

    def owner(self, addr: int) -> tuple[Unit, str, int] | None:
        i = bisect.bisect_right(self.range_starts, addr) - 1
        if i >= 0:
            start, end, unit, sec = self.ranges[i]
            if start <= addr < end:
                return unit, sec, start
        return None

    def frame_of(self, addr: int) -> int:
        """Linear base of the frame (segment) that addresses addr."""
        if self.dgroup <= addr < self.dgroup_end:
            return self.dgroup
        seg = self.ida.seg_at(addr)
        return (seg.start & ~0xF) if seg else addr & ~0xFFFF

    def symbol_for(self, unit: Unit, target: int) -> tuple[str, int]:
        """(symbol name, addend) for a reference to target from unit."""
        own = self.owner(target)
        if own is not None:
            ounit, sec, sec_start = own
            lo, hi = ounit.ranges[sec]
            s = self.syms.containing(target, lo, hi, self.visible_in(ounit))
            if s is not None:
                return s.name, target - s.addr
            if ounit is unit:
                return sec, target - sec_start
            return f"{ounit.name.replace('/', '_')}{sec}", target - sec_start
        s = self.syms.containing(target, self.frame_of(target))
        if s is not None:
            return s.name, target - s.addr
        return f"unk_{target:05X}", 0

    @staticmethod
    def visible_in(unit: Unit):
        """Library objects only define their publics; hide IDA's internal labels there."""
        if unit.lib:
            return lambda s: "lib" in s.flags
        return None

    def heads_in(self, heads: list[int], start: int, end: int) -> list[int]:
        return heads[bisect.bisect_left(heads, start):bisect.bisect_left(heads, end)]

    def mz_relocs_in(self, start: int, end: int) -> list[int]:
        r = self.relocs_sorted
        return r[bisect.bisect_left(r, start):bisect.bisect_left(r, end)]

    # ------------------------------------------------------------------ split

    def split(self, unit: Unit) -> ElfWriter:
        w = ElfWriter()
        for sec, (start, end) in unit.ranges.items():
            if sec == ".bss":
                w.add_section(sec, None, end - start)
            else:
                data = self.exe.bytes(start, end)
                data = data + bytes(end - start - len(data))   # past the end of the image
                w.add_section(sec, data)
            visible = self.visible_in(unit) or (lambda s: True)
            in_sec = [s for s in self.syms.in_range(start, end) if s.kind != "label" and visible(s)]
            for i, s in enumerate(in_sec):
                nxt = in_sec[i + 1].addr if i + 1 < len(in_sec) else end
                # Functions run to the next symbol, like publics in a compiled
                # object (this absorbs alignment padding IDA leaves outside)
                size = nxt - s.addr if s.kind == "func" else min(s.size, end - s.addr)
                if s.kind == "func" and size > 1 and self.exe.bytes(s.addr + size - 1, s.addr + size) == b"\x90":
                    size -= 1   # word alignment: C 7.00 pads each function to an even address
                kind = "func" if s.kind == "func" else "object"
                w.add_symbol(s.name, sec, s.addr - start, size, kind, local="static" in s.flags)

        for sec, (start, end) in unit.ranges.items():
            if sec == ".bss":
                continue
            covered: set[int] = set()
            pending_seg: list[tuple[int, int, int]] = []
            if sec == ".text" and unit.lib:
                self._lib_relocs(w, unit, sec, start, end, covered)
            if sec == ".text":
                self._code_relocs(w, unit, sec, start, end, covered, pending_seg)
            self._data_relocs(w, unit, sec, start, end, covered, pending_seg)
            self._resolve_segs(w, unit, sec, start, pending_seg)
        if not unit.lib and ".data" in w.sections:
            self._name_literals(w)
        return w

    @staticmethod
    def _name_literals(w: ElfWriter) -> None:
        """References to string literals in the unit's own .data use names made
        from the text (elf16.literal_name), as tools/omf2elf.py names the
        compiler's anonymous labels, so the two sides match by name."""
        data = w.sections[".data"].data
        own = {s.name: s for s in w.symbols.values() if s.section == ".data"}
        refs = []
        for secname, sec in w.sections.items():
            for i, (off, rtype, sym, addend) in enumerate(sec.relocs):
                s = own.get(sym)
                if s is None or rtype == R_386_PC16:
                    continue
                if not (DUMMY_NAME.match(sym) or sym.startswith("a")):
                    continue                    # a named variable keeps its name
                o = s.value + addend
                if literal_name(data, o):
                    refs.append((secname, i, o))
        offs = sorted({o for _, _, o in refs})
        names = dict(zip(offs, number_duplicates([literal_name(data, o) for o in offs])))
        for o, name in names.items():
            end = data.find(b"\0", o) + 1
            w.add_symbol(name, ".data", o, end - o, "object", local=True)
        for secname, i, o in refs:
            off, rtype, _sym, _add = w.sections[secname].relocs[i]
            w.sections[secname].relocs[i] = (off, rtype, names[o], 0)

    _lib_cache: dict[str, list] = {}

    def _lib_relocs(self, w: ElfWriter, unit: Unit, sec: str, start: int, end: int,
                    covered: set[int]) -> None:
        """A library module's references, from its own fixups.

        Every other byte of the code is then marked covered, so the guesses
        in _code_relocs only add the segment fixups (MZ relocations)."""
        libfile, modname = unit.lib.split(":", 1)
        if libfile not in self._lib_cache:
            self._lib_cache[libfile] = omf.load(str(libmatch.LIB_DIR / libfile))
        mod = next((m for m in self._lib_cache[libfile] if module_basename(m.name) == modname), None)
        if mod is None:
            return
        seg = next((sg for sg in mod.segments if sg.cls == "CODE" and sg.length == end - start), None)
        if seg is None:
            return
        segwords = {r for r in self.mz_relocs_in(start, end)}
        for f, at, target, disp in libmatch.iter_fixups(self.exe, mod, seg, start, self.dgroup,
                                                        self.frame_of):
            if not f.seg_relative and f.loc != omf.LOC_POINTER and start <= target < end:
                continue                    # resolved in place, as in the library object
            if f.target_method == omf.T_EXTDEF:
                name = mod.ext(f.target_index).name
                if name in ABSOLUTE_SYMBOLS:
                    continue
                sym, add = ALIASES.get(name, name), disp
            else:
                sym, add = self.symbol_for(unit, target)
            if f.loc == omf.LOC_POINTER:
                self._add(w, sec, start, at, R_386_FAR16, sym, add, covered)
            elif f.seg_relative:
                self._add(w, sec, start, at, R_386_16, sym, add, covered)
            else:
                self._add(w, sec, start, at, R_386_PC16, sym, add - 2, covered)
        covered.update(a for a in range(start, end) if a not in segwords and a - 1 not in segwords)

    def _named_var(self, s) -> bool:
        return (s is not None and s.kind == "data" and not DUMMY_NAME.match(s.name)
                and not s.name.startswith("a") and self.dgroup <= s.addr < self.dgroup_end)

    def _decode_missed_functions(self) -> None:
        """Make code heads for functions added in symbols.txt that IDA left undefined."""
        ida = self.ida
        for s in self.syms.by_addr.values():
            if s.kind != "func" or ida.heads.get(s.addr, (0, ""))[1] == "C":
                continue
            ea, end = s.addr, s.addr + s.size
            for a in [a for a in ida.heads if ea <= a < end]:
                del ida.heads[a]
            dec = ix.Decoder(16, self.exe.bytes(ea, end), ip=ea - self.frame_of(ea))
            for ins in dec:
                ida.heads[ea] = (ins.len, "C")
                ea += ins.len

    def _add(self, w: ElfWriter, sec: str, sec_start: int, at: int, rtype: int, sym: str,
             addend: int, covered: set[int]) -> None:
        n = 4 if rtype == R_386_FAR16 else 2
        if any(at + k in covered for k in range(n)):
            return
        covered.update(range(at, at + n))
        w.add_reloc(sec, at - sec_start, rtype, sym, addend)

    def _code_relocs(self, w: ElfWriter, unit: Unit, sec: str, start: int, end: int,
                     covered: set[int], pending_seg: list) -> None:
        exe, ida = self.exe, self.ida
        es_frame: tuple[int, int] | None = None    # (segment word, far frame) loaded into ES
        for ea in self.heads_in(self.code_heads, start, end):
            if ea in ida.funcs:
                es_frame = None
            size = ida.heads[ea][0]
            code = exe.bytes(ea, ea + size)
            dec = ix.Decoder(16, code, ip=ea - self.frame_of(ea))
            ins = dec.decode()
            if ins.code == ix.Code.INVALID:
                continue
            co = dec.get_constant_offsets(ins)

            # An override names one operand; any other operand is still
            # relocated below ("none" suppresses them all)
            if ea in self.overrides:
                if self.overrides[ea] is None:
                    continue
                self._override(w, sec, start, ea, ins, co, code, covered)
                if ea in OVERRIDE_ONLY:
                    continue

            # Segment fixups from the MZ table
            for r in self.mz_relocs_in(ea, ea + size):
                segv = exe.relocs[r]
                if ins.op0_kind == ix.OpKind.FAR_BRANCH16 and r == ea + co.immediate_offset2:
                    target = lin(segv, ins.far_branch16)
                    sym, add = self.symbol_for(unit, target)
                    self._add(w, sec, start, ea + co.immediate_offset, R_386_FAR16, sym, add, covered)
                else:
                    pending_seg.append((r, segv, ea))

            # Near branches leaving the unit (rel16 call/jmp only)
            if ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
                target = self.frame_of(ea) + ins.near_branch16
                if not (start <= target < end) and code[0] in (0xE8, 0xE9):
                    sym, add = self.symbol_for(unit, target)
                    self._add(w, sec, start, ea + 1, R_386_PC16, sym, add - 2, covered)
                continue

            # 8087 emulator calls: the x87 ModRM and displacement follow the INT
            if ins.mnemonic == ix.Mnemonic.INT and 0x34 <= ins.immediate8 <= 0x3C:
                self._emu_operand(w, unit, sec, start, end, ea, ins.immediate8, covered)
                continue

            # QC far data: mov es, ds:[segword] (a relocated segment value in
            # DGROUP), then es:[bx+offset] operands address that far segment
            if ins.op0_kind == ix.OpKind.REGISTER and ins.op0_register == ix.Register.ES:
                es_frame = None
                if (ins.mnemonic == ix.Mnemonic.MOV and ins.op1_kind == ix.OpKind.MEMORY
                        and ins.memory_base == ix.Register.NONE and ins.memory_index == ix.Register.NONE):
                    word = self.dgroup + (ins.memory_displacement & 0xFFFF)
                    if word in exe.relocs:
                        es_frame = (word, lin(exe.relocs[word], 0))
            elif ins.mnemonic == ix.Mnemonic.LES:
                es_frame = None
            if (es_frame is not None and co.displacement_size == 2
                    and ins.memory_segment == ix.Register.ES):
                t = es_frame[1] + (ins.memory_displacement & 0xFFFF)
                self.segword_users.setdefault(es_frame[0], t)
                sym, add = self.symbol_for(unit, t)
                self._add(w, sec, start, ea + co.displacement_offset, R_386_16, sym, add, covered)

            # Near offsets / memory references (ES: operands are far data, not DGROUP)
            fields = []
            if co.displacement_size == 2 and ins.memory_segment != ix.Register.ES:
                fields.append((ea + co.displacement_offset, ins.memory_displacement & 0xFFFF, True))
            if co.immediate_size == 2:
                fields.append((ea + co.immediate_offset, _word(code, co.immediate_offset), False))
            if not fields:
                continue
            targets = list(ida.drefs.get(ea, []))
            cs_override = ins.segment_prefix == ix.Register.CS
            for op in ida.ops.get(ea, []):
                if op.isoff or op.optype == 2:
                    base = self.frame_of(ea) if cs_override else self.dgroup
                    # Prefer an explicit xref that agrees with the operand value
                    if not any((t - self.frame_of(t)) & 0xFFFF == op.value & 0xFFFF for t in targets):
                        targets.append(base + (op.value & 0xFFFF))
            # cs:[bx+disp16] into the unit's own code: tables kept in the code
            # segment (assembly modules); the 16-bit encoding marks a symbol
            if co.displacement_size == 2 and ins.segment_prefix == ix.Register.CS:
                t = self.frame_of(ea) + (ins.memory_displacement & 0xFFFF)
                if start <= t < end:
                    targets.append(t)
            # [bx/si/di+disp16] array accesses IDA left as plain numbers: accept
            # the displacement when it is exactly the start of a DGROUP symbol
            if co.displacement_size == 2 and ins.memory_base not in (ix.Register.BP, ix.Register.NONE) \
                    and ins.memory_segment == ix.Register.DS:
                t = self.dgroup + (ins.memory_displacement & 0xFFFF)
                s0 = self.syms.get(t)
                if s0 is not None and s0.kind == "data" and (ins.memory_displacement & 0xFFFF) >= LOW_DGROUP:
                    targets.append(t)
            # Addresses of named DGROUP variables IDA left as plain numbers
            # (push offset music_name, mov cx, offset tab; [bx+tab+2]). Only
            # hand-named symbols count: a dummy name proves nothing
            # (C units only: assembly sources were generated without them).
            # Below 400h, mov dx, imm is as likely an I/O port
            if not unit.lib and not (ROOT / "src" / f"{unit.name}.asm").exists():
                if co.immediate_size == 2:
                    v = _word(code, co.immediate_offset)
                    s0 = self.syms.get(self.dgroup + v)
                    port = ins.mnemonic == ix.Mnemonic.MOV and ins.op0_kind == ix.OpKind.REGISTER \
                        and ins.op0_register == ix.Register.DX
                    if (v >= 0x400 or not port) and v >= LOW_DGROUP and self._named_var(s0):
                        targets.append(self.dgroup + v)
                if co.displacement_size == 2 and ins.memory_base != ix.Register.BP \
                        and ins.memory_base != ix.Register.NONE and ins.memory_segment == ix.Register.DS:
                    t = self.dgroup + (ins.memory_displacement & 0xFFFF)
                    s0 = self.syms.containing(t, self.dgroup, self.dgroup_end)
                    if (ins.memory_displacement & 0xFFFF) >= LOW_DGROUP and self._named_var(s0) \
                            and t < s0.addr + max(s0.size, 1):
                        targets.append(t)
            # Immediates IDA left as numbers (push 3507h): accept them when they
            # are exactly the start of a symbol in the unit's own CONST (strings)
            if co.immediate_size == 2 and ".rodata" in unit.ranges and not unit.lib:
                v = _word(code, co.immediate_offset)
                t = self.dgroup + v
                lo, hi = unit.ranges[".rodata"]
                if lo <= t < hi and self.syms.get(t) is not None and t not in targets:
                    targets.append(t)
            for at, value, _is_mem in fields:
                hit = None
                for t in targets:
                    if (t - self.frame_of(t)) & 0xFFFF == value:
                        hit = t
                        break
                if hit is None:
                    continue
                sym, add = self.symbol_for(unit, hit)
                self._add(w, sec, start, at, R_386_16, sym, add, covered)

    def _override(self, w: ElfWriter, sec: str, start: int, ea: int, ins: ix.Instruction,
                  co: ix.ConstantOffsets, code: bytes, covered: set[int]) -> None:
        """Apply a config/relocs.txt entry: the reference is given explicitly (or suppressed)."""
        ov = self.overrides[ea]
        if ov is None:
            return
        name, addend = ov
        s = self.by_name.get(name)
        if s is None:
            sys.exit(f"relocs.txt: unknown symbol {name} at {ea:05X}")
        value = (s.addr + addend - self.frame_of(s.addr)) & 0xFFFF
        fields = []
        if co.displacement_size == 2:
            fields.append(co.displacement_offset)
        if co.immediate_size == 2:
            fields.append(co.immediate_offset)
        for off in fields:
            if _word(code, off) == value:
                self._add(w, sec, start, ea + off, R_386_16, name, addend, covered)
                return
        sys.exit(f"relocs.txt: no operand of the instruction at {ea:05X} equals {name}+{addend:#x}")

    def _emu_operand(self, w: ElfWriter, unit: Unit, sec: str, start: int, end: int, ea: int,
                     vector: int, covered: set[int]) -> None:
        """Relocate the memory operand of an emulated x87 instruction.

        INT 34h-3Bh: ESC D8-DF, followed by ModRM [disp]
        INT 3Ch:     segment override form, followed by an opcode byte, ModRM [disp]
        """
        pos = ea + 2 + (1 if vector == 0x3C else 0)
        segment = "ds"
        if vector == 0x3C:
            seg_bits = self.exe.bytes(ea + 2, ea + 3)[0] >> 6
            # the FIxRQQ/FJxRQQ fixups leave the segment in the top two bits
            segment = {0: "ds", 1: "ss", 2: "cs", 3: "es"}[seg_bits]
        if pos + 3 > end:
            return
        modrm = self.exe.bytes(pos, pos + 1)[0]
        mod, rm = modrm >> 6, modrm & 7
        if not ((mod == 0 and rm == 6) or mod == 2):
            return
        at = pos + 1
        value = self.exe.word(at)
        if segment == "es" or (mod == 2 and rm in (2, 3, 6)):      # ES:, or BP-based (stack)
            return
        if segment == "cs":
            t = self.frame_of(ea) + value
        else:
            t = self.dgroup + value
        if mod == 2:
            s0 = self.syms.get(t)
            if s0 is None or s0.kind != "data":
                return
        sym, add = self.symbol_for(unit, t)
        self._add(w, sec, start, at, R_386_16, sym, add, covered)

    def _data_relocs(self, w: ElfWriter, unit: Unit, sec: str, start: int, end: int,
                     covered: set[int], pending_seg: list) -> None:
        exe, ida = self.exe, self.ida
        # Far pointers / segment words in data
        for r in self.mz_relocs_in(start, end):
            if r in covered:
                continue
            if ida.heads.get(r, (0, ""))[1] == "C" or self.owner_head_kind(r) == "C":
                continue
            segv = exe.relocs[r]
            if ida.heads.get(r, (0, ""))[0] == 2:
                # a lone segment word (QC far data): name it after what is
                # reached through it
                used = self.segword_users.get(r)
                if used is not None:
                    sym, _ = self.symbol_for(unit, used)
                    self._add(w, sec, start, r, R_386_SEG16, sym, 0, covered)
                    continue
            off_at = r - 2
            if off_at >= start and off_at not in covered:
                target = lin(segv, exe.word(off_at))
                if segv != self.dgroup_para or self.dgroup <= target < self.dgroup_end:
                    sym, add = self.symbol_for(unit, target)
                    self._add(w, sec, start, off_at, R_386_FAR16, sym, add, covered)
                    continue
            pending_seg.append((r, segv, r))
        # Near pointers given in config/relocs.txt (the address is the word itself)
        for at in sorted(a for a in self.overrides if start <= a < end):
            if self.owner_head_kind(at) == "C":
                continue
            ov = self.overrides[at]
            if ov is None or at in covered:
                covered.update((at, at + 1))
                continue
            name, addend = ov
            s = self.by_name.get(name)
            if s is None:
                sys.exit(f"relocs.txt: unknown symbol {name} at {at:05X}")
            if exe.word(at) != (s.addr + addend - self.frame_of(s.addr)) & 0xFFFF:
                sys.exit(f"relocs.txt: the word at {at:05X} is not {name}+{addend:#x}")
            self._add(w, sec, start, at, R_386_16, name, addend, covered)
        # Pointers to the unit's own strings (char *names[] = {"a", ...}):
        # IDA rarely records these. Accept words that are exactly the start
        # of a symbol in the unit's .rodata
        if ".rodata" in unit.ranges and not unit.lib and sec.startswith(".data"):
            lo, hi = unit.ranges[".rodata"]
            for at in range(start, end - 1, 2):
                if at in covered or at + 1 in covered:
                    continue
                t = self.dgroup + exe.word(at)
                if lo <= t < hi and self.syms.get(t) is not None:
                    sym, add = self.symbol_for(unit, t)
                    self._add(w, sec, start, at, R_386_16, sym, add, covered)
        # Near pointers in data items, from IDA data xrefs
        for ea in self.heads_in(self.data_heads, start, end):
            targets = ida.drefs.get(ea)
            if not targets:
                continue
            size = ida.heads[ea][0]
            for at in range(ea, min(ea + size, end) - 1):
                if at in covered:
                    continue
                v = exe.word(at)
                for t in targets:
                    if (t - self.frame_of(t)) & 0xFFFF == v:
                        sym, add = self.symbol_for(unit, t)
                        self._add(w, sec, start, at, R_386_16, sym, add, covered)
                        break

    def owner_head_kind(self, addr: int) -> str:
        i = bisect.bisect_right(self.code_heads, addr) - 1
        if i >= 0:
            ea = self.code_heads[i]
            if ea <= addr < ea + self.ida.heads[ea][0]:
                return "C"
        return "D"

    def _resolve_segs(self, w: ElfWriter, unit: Unit, sec: str, start: int, pending: list) -> None:
        """Name segment-only fixups: DGROUP, or a nearby offset reference into that segment."""
        if not pending:
            return
        rel = w.sections[sec].relocs
        for at, segv, ea in pending:
            if segv == self.dgroup_para:
                sym = "DGROUP"
            else:
                base = lin(segv, 0)
                sym = None
                # A neighbouring R_386_16 whose target lives in the same frame
                best = None
                for off, rtype, name, add in rel:
                    if rtype != R_386_16:
                        continue
                    s = self.by_name.get(name)
                    if s is None or not (base <= s.addr < base + 0x10000):
                        continue
                    d = abs((start + off) - at)
                    if d <= 16 and (best is None or d < best[0]):
                        best = (d, name)
                if best:
                    sym = best[1]
                elif ".text" in unit.ranges and self.frame_of(unit.ranges[".text"][0]) == base:
                    sym = ".text"       # the unit's own code segment
                else:
                    seg = self.ida.seg_at(base + 0x10) or self.ida.seg_at(base)
                    own = self.owner(seg.start) if seg else None
                    if own and own[1].startswith(".data."):
                        sym = own[1][len(".data."):]   # a far segment: named like the compiler's SEGDEF
                    else:
                        sym = f"SEG_{seg.name}" if seg else f"SEG_{segv:04X}"
            self._add(w, sec, start, at, R_386_SEG16, sym, 0, set())


def _word(code: bytes, off: int) -> int:
    return code[off] | (code[off + 1] << 8)


# DGROUP offsets below this (the C runtime's and seg001's _DATA) are as
# likely structure offsets or small constants (o->expl is [bx+1C8h]) as
# variable addresses, so unmarked operands there are never taken as
# references; use config/relocs.txt for the real ones
LOW_DGROUP = 0x240

# Instructions whose override is their only reference ("SYMBOL only")
OVERRIDE_ONLY: set[int] = set()


def load_overrides(path: Path = ROOT / "config/relocs.txt") -> dict[int, tuple[str, int] | None]:
    """config/relocs.txt:  INSN_ADDR  SYMBOL[+ADDEND] [only] | none"""
    out: dict[int, tuple[str, int] | None] = {}
    if not path.exists():
        return out
    for line in path.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        parts = line.split()
        addr, ref = parts[:2]
        if parts[2:3] == ["only"]:
            OVERRIDE_ONLY.add(int(addr, 16))
        if ref == "none":
            out[int(addr, 16)] = None
            continue
        name, sign, add = ref.partition("+") if "+" in ref else ref.partition("-")
        addend = int(add, 0) if add else 0
        out[int(addr, 16)] = (name, -addend if sign == "-" else addend)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("-o", "--out", default=str(ROOT / "build/target"), help="output directory")
    ap.add_argument("units", nargs="*", help="only split these units")
    args = ap.parse_args()

    exe = load_exe()
    ida = load_ida(exe)
    syms = SymbolTable.load()
    units = load_units()
    sp = Splitter(exe, ida, syms, units, load_overrides())
    out = Path(args.out)
    for u in units:
        if args.units and u.name not in args.units:
            continue
        path = out / f"{u.name}.o"
        path.parent.mkdir(parents=True, exist_ok=True)
        data = sp.split(u).to_bytes()
        if not path.exists() or path.read_bytes() != data:
            path.write_bytes(data)


if __name__ == "__main__":
    main()
