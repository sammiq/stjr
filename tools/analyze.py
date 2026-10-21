#!/usr/bin/env python3
"""Analyse the original EXE into build/analysis.txt (IDA export format).

An IDA database export (tools/ida/export.idc) can stand in for it.
This does the part of IDA's job the other tools need, from the EXE alone:

  * segments: the three packed code segments, the far data segments, DGROUP
    and the stack (project.SEG_NAMES)
  * functions, by recursive descent from the entry point, every far call
    (segment fixups), every near call, far pointers to code in the data,
    and whatever code is left over in the gaps
  * code heads, jump tables (`jmp cs:[bx+table]`) as data heads
  * data heads and data xrefs for direct memory operands ([1234h]), x87
    emulator operands and offsets of string literals (push offset aText)
  * placeholder names in IDA's style (sub_10018, word_3C0A2, aUnableToLoad)

Names in config/symbols.txt always win; this only provides the structure.
A real IDA export (tools/ida/export.idc) can be dropped in its place.

    tools/analyze.py [-o build/analysis.txt]
"""

from __future__ import annotations

import argparse
import bisect
import re
import struct
import sys
from pathlib import Path

import iced_x86 as ix

sys.path.insert(0, str(Path(__file__).parent))
from project import (CODE_SEGS, DGROUP_PARA, FAR_DATA_SEGS, IDA_EXPORT, SEG_NAMES,  # noqa: E402
                     STACK_SEG_NAME, LOAD_BASE, Exe, lin, load_exe)

FAR_FUNC = 2          # IDA FUNC_FAR
STOP = {ix.FlowControl.RETURN, ix.FlowControl.INTERRUPT}   # INT handled separately


class Analysis:
    def __init__(self, exe: Exe):
        self.exe = exe
        self.code_bounds = [lin(s, 0) for s in CODE_SEGS] + [lin(FAR_DATA_SEGS[0], 0)]
        self.code_start, self.code_end = self.code_bounds[0], self.code_bounds[-1]
        self.dgroup = lin(DGROUP_PARA, 0)
        self.stack = lin(exe.ss, 0)
        self.stack_end = self.stack + ((exe.sp + 15) & ~15)
        self.insns: dict[int, int] = {}          # ea -> length
        self.funcs: dict[int, list] = {}         # start -> [end, flags]
        self.far_called: set[int] = set()
        self.data: dict[int, tuple[int, str]] = {}    # ea -> (size, prefix)
        self.drefs: dict[int, set[int]] = {}
        self.ops: list[tuple[int, int, int, int, int]] = []   # ea, n, optype, value, isoff
        self.tables: dict[int, list[int]] = {}   # jump table ea -> targets
        self.strings: dict[int, str] = {}

    # ------------------------------------------------------------------ helpers

    def seg_base(self, ea: int) -> int:
        i = bisect.bisect_right(self.code_bounds, ea) - 1
        return self.code_bounds[max(0, min(i, len(self.code_bounds) - 2))]

    def in_code(self, ea: int) -> bool:
        return self.code_start <= ea < self.code_end

    def byte(self, ea: int) -> int:
        return self.exe.image[ea - LOAD_BASE]

    def word(self, ea: int) -> int:
        return struct.unpack_from("<H", self.exe.image, ea - LOAD_BASE)[0]

    def decode(self, ea: int) -> ix.Instruction:
        """One instruction, with the 8087 emulator's INT 34h-3Dh taken whole."""
        frame = self.seg_base(ea)
        code = self.exe.bytes(ea, min(ea + 16, self.code_end))
        ins = ix.Decoder(16, code, ip=ea - frame).decode()
        if ins.mnemonic == ix.Mnemonic.INT and 0x34 <= ins.immediate8 <= 0x3D and len(code) > 2:
            v = ins.immediate8
            if v == 0x3D:
                return ins
            if v == 0x3C:
                b = code[2]
                raw = bytes([(0x3E, 0x36, 0x2E, 0x26)[b >> 6], (b & 0x3F) | 0xC0]) + code[3:]
            else:
                raw = bytes([0xD8 + v - 0x34]) + code[2:]
            emu = ix.Decoder(16, raw, ip=ea - frame).decode()
            if emu.code != ix.Code.INVALID:
                emu.len = emu.len + 1
                self._emu_operand(ea, v, code)
                return emu
        return ins

    def _emu_operand(self, ea: int, v: int, code: bytes) -> None:
        pos = 3 if v == 0x3C else 2
        if v == 0x3C and code[2] >> 6 != 0:
            return                      # SS:/CS:/ES: forms
        modrm = code[pos]
        if modrm >> 6 == 0 and modrm & 7 == 6:
            t = self.dgroup + struct.unpack_from("<H", code, pos + 1)[0]
            size = {0: 4, 1: 4, 2: 8, 3: 2, 4: 8, 5: 8, 6: 2, 7: 8}.get((code[pos - 1] if v != 0x3C else 0) & 7, 4)
            self.add_data(t, size if v != 0x3C else 4)
            self.drefs.setdefault(ea, set()).add(t)

    def add_data(self, ea: int, size: int, prefix: str | None = None) -> None:
        if ea in self.data or ea in self.insns:
            return
        prefix = prefix or {1: "byte", 2: "word", 4: "dword", 8: "qword", 10: "tbyte"}.get(size, "unk")
        self.data[ea] = (size, prefix)

    def string_at(self, ea: int) -> str | None:
        """A C string literal starting exactly at ea (in DGROUP)."""
        off = ea - LOAD_BASE
        img = self.exe.image
        if not (self.dgroup <= ea < self.dgroup + 0x10000) or off >= len(img):
            return None
        # a string starts after a NUL or other non-text byte, never mid-text
        if 32 <= img[off - 1] < 127 or img[off - 1] in (9, 10, 13):
            return None
        end = img.find(b"\0", off, off + 512)
        if end <= off + 1:
            return None
        s = img[off:end]
        if all(32 <= c < 127 or c in (9, 10, 13) for c in s):
            return s.decode("latin-1")
        return None

    # ------------------------------------------------------------------ descent

    def seeds_from_relocs(self) -> set[int]:
        seeds = set()
        for at, segv in self.exe.relocs.items():
            if segv not in CODE_SEGS or at - 2 < LOAD_BASE:
                continue
            off = self.word(at - 2)
            target = lin(segv, off)
            if not self.in_code(target):
                continue
            if self.in_code(at):
                # in code only far calls; other fixups (mov ax, SEG x) have
                # no offset in front of them
                if self.byte(at - 3) != 0x9A:
                    continue
                self.far_called.add(target)
            seeds.add(target)
        return seeds

    def function(self, start: int, stops: set[int]) -> tuple[int, list[int]]:
        """Flow from start; returns (end, new call targets)."""
        work = [start]
        seen: set[int] = set()
        calls: list[int] = []
        end = start
        while work:
            ea = work.pop()
            while self.in_code(ea) and ea not in seen:
                if ea != start and ea in stops:
                    break
                ins = self.decode(ea)
                if ins.code == ix.Code.INVALID:
                    break
                seen.add(ea)
                self.insns[ea] = ins.len
                nxt = ea + ins.len
                end = max(end, nxt)
                frame = self.seg_base(ea)
                fc = ins.flow_control
                if ins.mnemonic == ix.Mnemonic.INT:
                    if ins.immediate8 == 0x20:
                        break
                    ea = nxt
                    continue
                if fc == ix.FlowControl.CALL:
                    if ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
                        calls.append(frame + ins.near_branch16)
                    elif ins.op0_kind == ix.OpKind.FAR_BRANCH16:
                        t = lin(ins.far_branch_selector, ins.far_branch16)
                        if self.in_code(t):
                            calls.append(t)
                            self.far_called.add(t)
                    ea = nxt
                    continue
                if fc == ix.FlowControl.CONDITIONAL_BRANCH:
                    work.append(frame + ins.near_branch16)
                    ea = nxt
                    continue
                if fc == ix.FlowControl.UNCONDITIONAL_BRANCH:
                    if ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
                        ea = frame + ins.near_branch16
                        continue
                    break
                if fc == ix.FlowControl.INDIRECT_BRANCH:
                    work.extend(self.jump_table(ea, ins, start))
                    break
                if fc == ix.FlowControl.RETURN:
                    break
                ea = nxt
        for t in self.tables:
            if start <= t < end + 0x400 and t >= end:
                end = max(end, t + 2 * len(self.tables[t]))
        return end, calls

    def jump_table(self, ea: int, ins: ix.Instruction, func: int) -> list[int]:
        """jmp cs:[bx+table] (or [bx+table] in DGROUP): the switch table's targets."""
        if ins.op0_kind != ix.OpKind.MEMORY or ins.memory_base == ix.Register.NONE \
                or ins.memory_displacement == 0:
            return []
        frame = self.seg_base(ea)
        if ins.memory_segment == ix.Register.CS:
            table = frame + ins.memory_displacement
        else:
            table = self.dgroup + ins.memory_displacement
        targets = []
        t = table
        limit = self.switch_bound(ea)
        while len(targets) < limit:
            if t in self.insns or (targets and t in self.tables) or t + 2 - LOAD_BASE > len(self.exe.image):
                break
            v = frame + self.word(t)
            if not (func <= v < frame + 0x10000) or v == t or abs(v - table) > 0x4000:
                break
            if table <= v < t + 2:
                break
            targets.append(v)
            t += 2
        if targets:
            self.tables[table] = targets
            self.drefs.setdefault(ea, set()).add(table)
        return targets

    def switch_bound(self, ea: int) -> int:
        """The entry count from the switch's range check just before the
        indirect jump (cmp reg, n; ja default / jbe in range; then shl,
        mov/xchg bx: n + 1 entries); 256 if there isn't one."""
        for back in range(4, 24):
            a = ea - back
            if a not in self.insns:
                continue
            ins = self.decode(a)
            if ins.mnemonic != ix.Mnemonic.CMP or ins.op1_kind not in (
                    ix.OpKind.IMMEDIATE16, ix.OpKind.IMMEDIATE8TO16, ix.OpKind.IMMEDIATE8):
                continue
            j = self.decode(a + ins.len)
            if j.mnemonic in (ix.Mnemonic.JA, ix.Mnemonic.JBE):
                return ins.immediate(1) + 1
        return 256

    def run(self) -> None:
        entry = lin(self.exe.cs, self.exe.ip)
        pending = {entry} | self.seeds_from_relocs()
        pending = {p for p in pending if self.in_code(p)}
        known: set[int] = set()
        for _ in range(8):
            known |= pending
            self.insns.clear()
            self.tables.clear()
            new: set[int] = set()
            for f in sorted(known):
                end, calls = self.function(f, known)
                self.funcs[f] = [end, 0]
                new.update(c for c in calls if self.in_code(c))
            new |= self.gap_seeds(known | new)
            pending = new - known
            if not pending:
                break
        for f in self.funcs:
            last = max((ea for ea in self.insns if f <= ea < self.funcs[f][0]), default=None)
            far = f in self.far_called or (last is not None and self.byte(last) in (0xCB, 0xCA))
            self.funcs[f][1] = FAR_FUNC if far else 0
        # functions run to the next function (MSC packs them, word aligned)
        starts = sorted(self.funcs)
        for a, b in zip(starts, starts[1:]):
            self.funcs[a][0] = min(max(self.funcs[a][0], a + 1), b)
        self.operands()

    def gap_seeds(self, known: set[int]) -> set[int]:
        """Code nothing reaches (functions only called through pointers):
        the first non-padding byte after each function's end."""
        out = set()
        covered = sorted(self.insns)
        ends = sorted({ea + self.insns[ea] for ea in covered})
        for e in ends:
            if e in self.insns or e in self.tables or e in known or not self.in_code(e):
                continue
            a = e
            while self.in_code(a) and self.byte(a) in (0x90, 0x00) and a not in self.insns:
                a += 1
            if not self.in_code(a) or a in self.insns or a in known or a in self.tables:
                continue
            if any(t <= a < t + 2 * len(v) for t, v in self.tables.items()):
                continue
            ins = self.decode(a)
            if ins.code != ix.Code.INVALID:
                out.add(a)
        return out

    # ------------------------------------------------------------------ operands

    def operands(self) -> None:
        for ea in sorted(self.insns):
            ins = self.decode(ea)
            if ins.code == ix.Code.INVALID:
                continue
            frame = self.seg_base(ea)
            for n in range(ins.op_count):
                kind = ins.op_kind(n)
                if kind == ix.OpKind.MEMORY and ins.memory_base == ix.Register.NONE \
                        and ins.memory_index == ix.Register.NONE:
                    seg = ins.memory_segment
                    if seg == ix.Register.ES:
                        continue
                    t = (frame if seg == ix.Register.CS else self.dgroup) + ins.memory_displacement
                    self.ops.append((ea, n, 2, ins.memory_displacement, 0))
                    self.drefs.setdefault(ea, set()).add(t)
                    if t not in self.tables:
                        self.add_data(t, max(1, ix.MemorySizeExt.size(ins.memory_size)))
                elif kind == ix.OpKind.IMMEDIATE16 and (
                        ins.mnemonic == ix.Mnemonic.PUSH
                        or (ins.mnemonic == ix.Mnemonic.MOV and ins.op0_kind == ix.OpKind.REGISTER
                            and ins.op0_register != ix.Register.CX)):     # cx: a count, not a pointer
                    # push offset aText / mov ax, offset aText; not mov [x], 450
                    t = self.dgroup + ins.immediate16
                    s = self.string_at(t)
                    if s is not None:
                        self.strings[t] = s
                        self.ops.append((ea, n, 5, ins.immediate16, 1))
                        self.drefs.setdefault(ea, set()).add(t)

    # ------------------------------------------------------------------ output

    def write(self, path: Path) -> None:
        exe = self.exe
        lines = [f"ENTRY\t{lin(exe.cs, exe.ip):X}"]
        bounds = sorted(SEG_NAMES)
        for i, para in enumerate(bounds):
            start = lin(para, 0)
            end = lin(bounds[i + 1], 0) if i + 1 < len(bounds) else self.stack
            lines.append(f"SEG\t{start:X}\t{end:X}\t{SEG_NAMES[para]}")
        lines.append(f"SEG\t{self.stack:X}\t{self.stack_end:X}\t{STACK_SEG_NAME}")
        for f, (end, flags) in sorted(self.funcs.items()):
            lines.append(f"FUNC\t{f:X}\t{end:X}\t{flags:X}\tsub_{f:X}")
        heads = {ea: (n, "C") for ea, n in self.insns.items()}
        names: dict[int, str] = {f: f"sub_{f:X}" for f in self.funcs}
        for t, targets in self.tables.items():
            for k, target in enumerate(targets):
                heads[t + 2 * k] = (2, "D")
                self.drefs.setdefault(t + 2 * k, set()).add(target)     # the entry points there
            names.setdefault(t, f"off_{t:X}")
        used: set[str] = set(names.values())
        for t, s in sorted(self.strings.items()):
            heads.setdefault(t, (len(s) + 1, "D"))
            names.setdefault(t, _unique(_ida_string_name(s), used))
        for t, (size, prefix) in sorted(self.data.items()):
            if t >= self.stack_end:
                continue
            heads.setdefault(t, (size, "D"))
            names.setdefault(t, f"{prefix}_{t:X}")
        for ea in sorted(heads):
            size, kind = heads[ea]
            lines.append(f"HEAD\t{ea:X}\t{size:X}\t{kind}\t0")
            if ea in names:
                lines.append(f"NAME\t{ea:X}\t0\t{names[ea]}")
        for ea in sorted(self.drefs):
            for t in sorted(self.drefs[ea]):
                lines.append(f"DREF\t{ea:X}\t{t:X}\t0")
        for ea, n, optype, value, isoff in self.ops:
            lines.append(f"OP\t{ea:X}\t{n}\t{optype}\t{value:X}\t{isoff}\t")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("\n".join(lines) + "\n", encoding="latin-1")


def _ida_string_name(s: str) -> str:
    """IDA's auto name for a string literal: 'a' + capitalised words, at most 15 chars."""
    words = re.findall(r"[A-Za-z0-9]+", s)
    name = "a" + "".join(w[:1].upper() + w[1:] for w in words)
    return name[:16] if len(name) > 1 else "asc"


def _unique(name: str, used: set[str]) -> str:
    out, k = name, 0
    while out in used:
        out = f"{name}_{k}"
        k += 1
    used.add(out)
    return out


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("-o", "--out", default=str(IDA_EXPORT))
    args = ap.parse_args()
    a = Analysis(load_exe())
    a.run()
    a.write(Path(args.out))
    print(f"{len(a.funcs)} functions, {len(a.insns)} instructions, {len(a.tables)} jump tables, "
          f"{len(a.data)} data items, {len(a.strings)} strings -> {args.out}")


if __name__ == "__main__":
    main()
