#!/usr/bin/env python3
"""Disassemble a function (or address range) of the original EXE with symbol names.

    tools/disasm.py _sub_10018          by symbol name
    tools/disasm.py 10018               by IDA linear address
    tools/disasm.py 10018 100C2         a range
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import iced_x86 as ix

sys.path.insert(0, str(Path(__file__).parent))
from project import SymbolTable, lin, load_exe, load_ida  # noqa: E402


SEG_PREFIX = {0: 0x3E, 1: 0x36, 2: 0x2E, 3: 0x26}   # DS, SS, CS, ES


def decode(exe, start: int, end: int, frame: int):
    """Decode instructions, turning 8087 emulator calls back into x87 ones.

    INT 34h-3Bh: ESC D8-DF + ModRM; INT 3Ch: segment override form (top two
    bits of the next byte select the segment); INT 3Dh: FWAIT.
    """
    pos = start
    while pos < end:
        code = exe.bytes(pos, min(end, pos + 16))
        ins = ix.Decoder(16, code, ip=pos - frame).decode()
        if ins.mnemonic == ix.Mnemonic.INT and 0x34 <= ins.immediate8 <= 0x3D:
            v = ins.immediate8
            if v == 0x3D:
                raw, extra = bytes([0x9B]), 1
            elif v == 0x3C:
                b = code[2]
                raw, extra = bytes([SEG_PREFIX[b >> 6], (b & 0x3F) | 0xC0]) + code[3:], 1
            else:
                raw, extra = bytes([0xD8 + v - 0x34]) + code[2:], 1
            emu = ix.Decoder(16, raw, ip=pos - frame).decode()
            if emu.code != ix.Code.INVALID:
                emu.len = emu.len + extra
                yield emu, pos
                pos += emu.len
                continue
        yield ins, pos
        pos += ins.len


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("start", help="symbol name or hex address")
    ap.add_argument("end", nargs="?", help="hex end address (default: end of the function)")
    args = ap.parse_args()

    exe = load_exe()
    ida = load_ida(exe)
    syms = SymbolTable.load()
    by_name = {s.name: s for s in syms.by_addr.values()}

    if args.start in by_name:
        start = by_name[args.start].addr
    else:
        start = int(args.start, 16)
    if args.end:
        end = int(args.end, 16)
    elif start in ida.funcs:
        end = ida.funcs[start][0]
    else:
        nxt = [a for a in syms.sorted_addrs() if a > start]
        end = nxt[0] if nxt else start + 0x40

    seg = ida.seg_at(start)
    frame = seg.start & ~0xF

    def name_of(t: int) -> str:
        s = syms.containing(t)
        if s is None:
            return f"{t:05X}"
        return s.name if s.addr == t else f"{s.name}+{t - s.addr:X}"

    fmt = ix.Formatter(ix.FormatterSyntax.MASM)
    fmt.hex_prefix = ""
    fmt.hex_suffix = "h"
    s0 = syms.get(start)
    print(f"; {s0.name if s0 else hex(start)}  {seg.name}:{start - frame:04X}  ({end - start} bytes)")
    for ins, a in decode(exe, start, end, frame):
        if a != start and syms.get(a) is not None:
            print(f"{syms.get(a).name}:")
        refs = []
        for t in ida.drefs.get(a, []) + ida.crefs.get(a, []):
            refs.append(name_of(t))
        if ins.op0_kind == ix.OpKind.FAR_BRANCH16:
            refs = [name_of(lin(ins.far_branch_selector, ins.far_branch16))]
        cmt = ida.comments.get(a, "")
        text = fmt.format(ins)
        extra = "  ; " + ", ".join(dict.fromkeys(refs)) if refs else ""
        if cmt:
            extra += f"  ; {cmt}"
        print(f"  {ins.ip:04X}  {exe.bytes(a, a + ins.len).hex():<14} {text:<36}{extra}")


if __name__ == "__main__":
    main()
