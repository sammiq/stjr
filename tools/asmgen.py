#!/usr/bin/env python3
"""Generate MASM 5.0 source for a unit that matches the original bytes.

    tools/asmgen.py UNIT [-o FILE]

The source is built from the unit's target object (tools/split.py), so
references come out as symbols: OFFSET DGROUP:sym, SEG sym, FAR PTR sym,
[bx+sym]. It is then assembled; any instruction MASM encodes differently
from the original is replaced by DB bytes, and this repeats until the
object matches. The result is a starting point for a hand-cleaned module.
"""

from __future__ import annotations

import argparse
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

import iced_x86 as ix

sys.path.insert(0, str(Path(__file__).parent))
import omf  # noqa: E402
from elf16 import R_386_16, R_386_8, R_386_FAR16, R_386_PC16, R_386_SEG16  # noqa: E402
from project import ROOT, SymbolTable, load_exe, load_ida, load_units  # noqa: E402
from split import Splitter, load_overrides  # noqa: E402

MAX_ROUNDS = 200


class Gen:
    def __init__(self, unit_name: str):
        self.exe = load_exe()
        self.ida = load_ida(self.exe)
        self.syms = SymbolTable.load()
        self.units = load_units()
        self.unit = next(u for u in self.units if u.name == unit_name)
        self.sp = Splitter(self.exe, self.ida, self.syms, self.units, load_overrides())
        self.w = self.sp.split(self.unit)
        self.raw: set[int] = set()          # instruction addresses emitted as DB
        self.swap: set[int] = set()         # test/xchg with the register operands swapped
        self.fmt = ix.Formatter(ix.FormatterSyntax.MASM)
        self.fmt.hex_suffix = "h"
        self.fmt.hex_prefix = ""
        self.fmt.uppercase_hex = True
        self.fmt.space_after_operand_separator = True

    # ------------------------------------------------------------------ helpers

    def relocs(self, sec: str) -> dict[int, tuple[int, str, int]]:
        start = self.unit.ranges[sec][0]
        return {start + off: (t, sym, add) for off, t, sym, add in self.w.sections[sec].relocs}

    def defined(self) -> dict[int, str]:
        out = {}
        for s in self.w.symbols.values():
            if s.section is not None and not s.name.startswith("$"):
                out[self.unit.ranges[s.section][0] + s.value] = s.name
        return out

    def is_data_symbol(self, name: str) -> bool:
        s = self.sp.by_name.get(name)
        return s is not None and self.sp.dgroup <= s.addr < self.sp.dgroup_end

    def seg_expr(self, sym: str) -> str:
        if sym == "DGROUP":
            return "DGROUP"
        if sym.startswith("."):
            return "SEG L_TEXT" if sym == ".text" else "SEG L_DATA"
        return f"SEG {sym}"

    @staticmethod
    def expr(sym: str, add: int) -> str:
        if sym.startswith("."):
            sym = {".text": "L_TEXT", ".data": "L_DATA", ".rodata": "L_CONST"}.get(sym, sym)
        return sym if add == 0 else f"{sym}+{add}" if add > 0 else f"{sym}-{-add}"

    # ------------------------------------------------------------------ code

    def code_lines(self, labels: dict[int, str]) -> list[str]:
        start, end = self.unit.ranges[".text"]
        rel = self.relocs(".text")
        frame = self.sp.frame_of(start)
        heads = {ea for ea, (sz, k) in self.ida.heads.items() if start <= ea < end and k == "C"}
        out = []
        pos = start
        while pos < end:
            if pos in labels:
                out.append(f"{labels[pos]}:")
            code = self.exe.bytes(pos, min(end, pos + 16))
            ins = ix.Decoder(16, code, ip=pos - frame).decode() if pos in heads else None
            if ins is None or ins.code == ix.Code.INVALID or pos + ins.len > end:
                n = 1
                while pos + n < end and pos + n not in heads and pos + n not in labels:
                    n += 1
                out += self.db_lines(pos, n, rel)
                pos += n
                continue
            inner = [a for a in labels if pos < a < pos + ins.len]
            if pos in self.raw:
                out += self.db_lines(pos, ins.len, rel)
            else:
                text = self.format(ins, pos, rel, labels, frame)
                if pos in self.swap:
                    mn, _, ops = text.partition(" ")
                    a, b = ops.split(", ")
                    text = f"{mn} {b}, {a}"
                out.append("\t" + text)
            # labels inside the instruction (overlapping/self-modifying code)
            for a in sorted(inner):
                out.append(f"{labels[a]}\tEQU\t$-{pos + ins.len - a}")
            pos += ins.len
        return out

    def db_lines(self, pos: int, n: int, rel) -> list[str]:
        """Bytes, with relocated fields as DW/DD expressions."""
        out = []
        i = 0
        chunk: list[str] = []

        def flush():
            if chunk:
                out.append("\tDB\t" + ", ".join(chunk))
                chunk.clear()
        while i < n:
            a = pos + i
            if a in rel:
                flush()
                t, sym, add = rel[a]
                if t == R_386_FAR16:
                    out.append(f"\tDD\t{self.expr(sym, add)}")
                    i += 4
                elif t == R_386_SEG16:
                    out.append(f"\tDW\t{self.seg_expr(sym)}")
                    i += 2
                elif t == R_386_PC16:
                    out.append(f"\tDW\t{self.expr(sym, add + 2)}-($+2)")
                    i += 2
                else:
                    pre = "DGROUP:" if self.is_data_symbol(sym) else ""
                    out.append(f"\tDW\tOFFSET {pre}{self.expr(sym, add)}")
                    i += 2
                continue
            chunk.append(f"0{self.exe.bytes(a, a + 1)[0]:02X}h")
            if len(chunk) == 12:
                flush()
            i += 1
        flush()
        return out

    def format(self, ins: ix.Instruction, pos: int, rel, labels, frame: int) -> str:
        dec = ix.Decoder(16, self.exe.bytes(pos, pos + ins.len), ip=pos - frame)
        ins = dec.decode()
        co = dec.get_constant_offsets(ins)
        text = self.fmt.format(ins)
        m = ins.mnemonic

        # near branches to labels
        if ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
            target = frame + ins.near_branch16
            r = rel.get(pos + 1)
            if r is not None and r[0] == R_386_PC16:
                return f"{text.split()[0]} {self.expr(r[1], r[2] + 2)}"
            name = labels[target]
            mn = text.split()[0]
            if m == ix.Mnemonic.JMP:
                kind = "SHORT " if ins.len == 2 else ""
                return f"jmp {kind}{name}"
            return f"{mn} {name}"
        # far call/jmp
        if ins.op0_kind == ix.OpKind.FAR_BRANCH16:
            r = rel.get(pos + co.immediate_offset)
            mn = "call" if m == ix.Mnemonic.CALL else "jmp"
            return f"{mn} FAR PTR {self.expr(r[1], r[2])}" if r else text

        # relocated displacement / immediate
        disp_at = pos + co.displacement_offset if co.displacement_size == 2 else None
        imm_at = pos + co.immediate_offset if co.immediate_size == 2 else None
        for at in (disp_at, imm_at):
            if at is None or at not in rel:
                continue
            t, sym, add = rel[at]
            if at == disp_at:
                text = self.sub_disp(ins, text, sym, add)
            elif t == R_386_SEG16:
                text = self.sub_last_number(text, self.seg_expr(sym))
            else:
                pre = "DGROUP:" if self.is_data_symbol(sym) else ""
                text = self.sub_last_number(text, f"OFFSET {pre}{self.expr(sym, add)}")
        return text

    def sub_disp(self, ins: ix.Instruction, text: str, sym: str, add: int) -> str:
        """Rewrite the memory operand with a symbolic displacement."""
        regs = []
        if ins.memory_base != ix.Register.NONE:
            regs.append(_reg(ins.memory_base))
        if ins.memory_index != ix.Register.NONE:
            regs.append(_reg(ins.memory_index))
        inner = "+".join(regs + [self.expr(sym, add)])
        seg = ""
        if ins.segment_prefix != ix.Register.NONE:
            seg = _reg(ins.segment_prefix) + ":"
        lb = text.index("[")
        rb = text.index("]", lb)
        # drop an existing "ds:" and size before the bracket, then add the size
        pre = text[:lb]
        for s in ("es:", "cs:", "ss:", "ds:"):
            if pre.endswith(s):
                pre = pre[: -len(s)]
        import re
        pre = re.sub(r"(byte|word|dword|qword) ptr $", "", pre)
        return f"{pre}{_ptr(ins)}{seg}[{inner}]{text[rb + 1:]}"

    @staticmethod
    def sub_last_number(text: str, val: str) -> str:
        import re
        ms = list(re.finditer(r"\b[0-9][0-9A-F]*h?\b", text))
        if not ms:
            return text
        mt = ms[-1]
        return text[:mt.start()] + val + text[mt.end():]

    # ------------------------------------------------------------------ data

    def data_lines(self, sec: str, labels: dict[int, str]) -> list[str]:
        start, end = self.unit.ranges[sec]
        rel = self.relocs(sec)
        if sec == ".bss":
            out = []
            points = sorted(a for a in labels if start <= a < end) + [end]
            if not points or points[0] != start:
                points.insert(0, start)
            for a, b in zip(points, points[1:]):
                if a in labels:
                    out.append(f"{labels[a]}\tLABEL\tBYTE")
                if b > a:
                    out.append(f"\tDB\t{b - a} DUP(?)")
            return out
        out = []
        pos = start
        cuts = sorted({a for a in labels if start < a < end} | {end})
        for nxt in cuts:
            if pos in labels:
                out.append(f"{labels[pos]}\tLABEL\tBYTE")
            out += self.db_lines(pos, nxt - pos, rel)
            pos = nxt
        return out

    # ------------------------------------------------------------------ whole file

    def source(self) -> str:
        defined = self.defined()
        labels = dict(defined)
        start, end = self.unit.ranges[".text"]
        frame = self.sp.frame_of(start)
        for ea, (sz, k) in self.ida.heads.items():
            if start <= ea < end and k == "C":
                ins = ix.Decoder(16, self.exe.bytes(ea, ea + sz), ip=ea - frame).decode()
                if ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
                    t = frame + ins.near_branch16
                    if start <= t < end and t not in labels:
                        labels[t] = f"L{t:05X}"
        externs = {}
        for s in self.w.symbols.values():
            if s.section is None:
                externs[s.name] = s
        lines = [f"; {self.unit.name}: generated by tools/asmgen.py", "",
                 "\t.MODEL\tMEDIUM", "\t.286", ""]
        near = {sym for sec in self.unit.ranges for _, t, sym, _ in self.w.sections[sec].relocs
                if t == R_386_PC16}
        code_ext = [n for n in externs if not self.is_data_symbol(n) and n != "DGROUP"
                    and not n.startswith(".")]
        data_ext = [n for n in externs if self.is_data_symbol(n)]
        for n in sorted(code_ext):
            lines.append(f"\tEXTRN\t{n}:{'NEAR' if n in near else 'FAR'}")
        pubs = sorted(n for n in defined.values() if not n.startswith("."))
        for n in pubs:
            lines.append(f"\tPUBLIC\t{n}")
        lines.append("")
        if data_ext or ".data" in self.unit.ranges:
            lines.append("\t.DATA")
            for n in sorted(data_ext):
                lines.append(f"\tEXTRN\t{n}:BYTE")
            if ".data" in self.unit.ranges:
                lines += ["L_DATA\tLABEL\tBYTE"] + self.data_lines(".data", labels)
            lines.append("")
        if ".rodata" in self.unit.ranges:
            lines += ["\t.CONST"] + self.data_lines(".rodata", labels) + [""]
        if ".bss" in self.unit.ranges:
            lines += ["\t.DATA?"] + self.data_lines(".bss", labels) + [""]
        lines += ["\t.CODE", "L_TEXT\tLABEL\tBYTE"] + self.code_lines(labels) + ["", "\tEND", ""]
        return "\n".join(lines)

    # ------------------------------------------------------------------ verification

    def assemble(self, text: str) -> omf.Module | str:
        tmp = ROOT / "build/asmgen"
        tmp.mkdir(parents=True, exist_ok=True)
        (tmp / "gen.asm").write_text(text.replace("\n", "\r\n"))
        res = subprocess.run([sys.executable, str(ROOT / "tools/cc.py"), str(tmp / "gen.asm"),
                              str(tmp / "gen.o"), "--omf", str(tmp / "gen.obj")],
                             capture_output=True, text=True)
        if res.returncode != 0:
            return res.stdout + res.stderr
        return omf.parse_obj((tmp / "gen.obj").read_bytes())

    def first_mismatch(self, mod: omf.Module) -> int | None:
        start, end = self.unit.ranges[".text"]
        seg = next(s for s in mod.segments if s.cls.endswith("CODE"))
        mask = bytearray(len(seg.data))
        for f in seg.fixups:
            for k in range(f.size):
                if f.offset + k < len(mask):
                    mask[f.offset + k] = 1
        want = self.exe.bytes(start, end)
        rel = self.relocs(".text")
        for a in rel:
            n = 4 if rel[a][0] == R_386_FAR16 else 2
            for k in range(n):
                i = a - start + k
                if i < len(mask):
                    mask[i] = 1
        n = max(len(want), len(seg.data))
        for i in range(n):
            if i >= len(want) or i >= len(seg.data):
                return start + min(i, len(want) - 1)
            if not mask[i] and seg.data[i] != want[i]:
                return start + i
        return None

    def swappable(self, ea: int) -> bool:
        """test/xchg reg, reg: the operand order picks the encoding."""
        sz = self.ida.heads[ea][0]
        ins = ix.Decoder(16, self.exe.bytes(ea, ea + sz)).decode()
        return (ins.mnemonic in (ix.Mnemonic.TEST, ix.Mnemonic.XCHG) and ins.op_count == 2
                and ins.op0_kind == ix.OpKind.REGISTER and ins.op1_kind == ix.OpKind.REGISTER)

    def instruction_at(self, addr: int) -> int:
        heads = sorted(ea for ea, (sz, k) in self.ida.heads.items() if ea <= addr and k == "C")
        return heads[-1] if heads else addr


_REG_NAMES = {getattr(ix.Register, n): n.lower() for n in dir(ix.Register) if n.isupper()}


def _reg(r: int) -> str:
    return _REG_NAMES[r]


def _ptr(ins: ix.Instruction) -> str:
    size = ix.MemorySizeInfo(ins.memory_size).size
    return {1: "byte ptr ", 2: "word ptr ", 4: "dword ptr ", 8: "qword ptr "}.get(size, "")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("unit")
    ap.add_argument("-o", "--out")
    args = ap.parse_args()

    g = Gen(args.unit)
    for rnd in range(MAX_ROUNDS):
        text = g.source()
        mod = g.assemble(text)
        if isinstance(mod, str):
            print(mod)
            sys.exit("asmgen: assembly failed (see build/asmgen/gen.asm)")
        bad = g.first_mismatch(mod)
        if bad is None:
            break
        ins = g.instruction_at(bad)
        if ins in g.raw:
            sys.exit(f"asmgen: cannot match at {bad:05X} (see build/asmgen/gen.asm)")
        if ins not in g.swap and g.swappable(ins):
            g.swap.add(ins)
        else:
            g.swap.discard(ins)
            g.raw.add(ins)
    else:
        sys.exit("asmgen: too many rounds")
    out = Path(args.out) if args.out else ROOT / "src" / f"{args.unit}.asm"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text)
    print(f"wrote {out} ({len(g.raw)} instructions emitted as DB, {len(g.swap)} with swapped operands)")


if __name__ == "__main__":
    main()
