"""Shared helpers: the original EXE, the code analysis and the config files.

The original, orig/CD/TREKJR.EXE, is EXEPACK-compressed (it was linked with
/EXEPACK). The tools work on its unpacked image, which load_exe() keeps in
build/exe/TREKJR.EXE, made with `exepack -d`.

It was also linked with /PACKCODE /FARCALLTRANSLATION: LINK packed the code
segments into three and turned every far call that stays inside its packed
segment into `nop; push cs; call near`. load_exe() turns those back into the
`call far` the compiler emitted (see untranslate_far_calls), so the image
the tools see compares with compiled objects.

The analysis (build/analysis.txt, tools/analyze.py) has the format of the
IDA export tools/ida/export.idc writes, so the same loader
reads either.

Addresses everywhere are IDA linear addresses: the load module is based at
paragraph 0x1000, so image offset = address - 0x10000 and an EXE segment
value S maps to linear (S + 0x1000) * 16.
"""

from __future__ import annotations

import bisect
import os
import re
import shutil
import struct
import subprocess
import sys
from dataclasses import dataclass, field
from typing import Callable
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ORIG_EXE = ROOT / "orig/CD/TREKJR.EXE"              # the shipped, packed EXE
EXE_PATH = ROOT / "build/exe/TREKJR.EXE"            # its unpacked image
IDA_EXPORT = ROOT / "build/analysis.txt"            # tools/analyze.py (or an IDA export)

# Segments of the load module, as EXE paragraph values. LINK packed the code
# into three segments; the C runtime's _TEXT is the end of the third.
CODE_SEGS = [0x0000, 0x0BD6, 0x1B98]
FAR_DATA_SEGS = [0x290E, 0x2B0E, 0x2B3E]
DGROUP_PARA = 0x2B87
SEG_NAMES = {0x0000: "seg000", 0x0BD6: "seg001", 0x1B98: "seg002",
             0x290E: "seg003", 0x2B0E: "seg004", 0x2B3E: "seg005", DGROUP_PARA: "dseg"}
STACK_SEG_NAME = "stack"
SYMBOLS = ROOT / "config/symbols.txt"
UNITS = ROOT / "config/units.txt"
ALIASES = ROOT / "config/aliases.txt"

LOAD_SEG = 0x1000
LOAD_BASE = LOAD_SEG * 16

DUMMY_NAME = re.compile(
    r"^_?(sub|loc|locret|byte|word|dword|qword|unk|off|seg|asc|stru|algn|nullsub|j|flt|dbl|tbyte)_[0-9A-F]+$")


def lin(seg: int, off: int) -> int:
    """EXE-relative segment:offset to linear address."""
    return ((seg + LOAD_SEG) << 4) + off


# --------------------------------------------------------------------------- EXE

@dataclass
class Exe:
    data: bytes
    image: bytes
    header_size: int
    relocs: dict[int, int]        # linear address of segment word -> segment value
    cs: int
    ip: int
    ss: int
    sp: int

    def word(self, addr: int) -> int:
        return struct.unpack_from("<H", self.image, addr - LOAD_BASE)[0]

    def bytes(self, start: int, end: int) -> bytes:
        return self.image[start - LOAD_BASE:end - LOAD_BASE]


def exepack_tool() -> str:
    """$EXEPACK, else tools/bin/exepack (tools/exepack/build.sh), else exepack on PATH."""
    if os.environ.get("EXEPACK"):
        return os.environ["EXEPACK"]
    local = ROOT / "tools/bin/exepack"
    return str(local) if local.exists() else (shutil.which("exepack") or "exepack")


def unpack_original() -> Path:
    """Unpack the original EXE into EXE_PATH if it's missing or older."""
    if not EXE_PATH.exists() or EXE_PATH.stat().st_mtime < ORIG_EXE.stat().st_mtime:
        EXE_PATH.parent.mkdir(parents=True, exist_ok=True)
        try:
            subprocess.run([exepack_tool(), "-d", str(ORIG_EXE), str(EXE_PATH)],
                           check=True, capture_output=True)
        except (OSError, subprocess.CalledProcessError) as e:
            sys.exit(f"can't unpack {ORIG_EXE.relative_to(ROOT)} with exepack ({e}); "
                     "build it with tools/exepack/build.sh or set $EXEPACK")
    return EXE_PATH


def load_exe(path: Path | None = None) -> Exe:
    d = (path or unpack_original()).read_bytes()
    (_, cblp, cp, crlc, cparhdr, _, _, ss, sp, _, ip, cs, lfarlc, _) = struct.unpack_from("<14H", d)
    size = (cp - 1) * 512 + cblp if cblp else cp * 512
    image = d[cparhdr * 16:size]
    relocs = {}
    for i in range(crlc):
        off, seg = struct.unpack_from("<HH", d, lfarlc + 4 * i)
        a = lin(seg, off)
        relocs[a] = struct.unpack_from("<H", image, a - LOAD_BASE)[0]
    image = untranslate_far_calls(image, relocs)
    return Exe(d, image, cparhdr * 16, relocs, cs, ip, ss, sp)


def untranslate_far_calls(image: bytes, relocs: dict[int, int]) -> bytes:
    """Undo LINK's /FARCALLTRANSLATION.

    LINK rewrote `call far seg:off` (9A off seg, with a segment fixup) into
    `nop; push cs; call near off` (90 0E E8 rel16) when the target is in
    the same packed segment. Put the far call back, and a segment fixup for
    it into relocs, as if the program had been linked without translation.
    """
    img = bytearray(image)
    bounds = CODE_SEGS + [FAR_DATA_SEGS[0]]
    for seg, nxt in zip(bounds, bounds[1:]):
        lo, hi = seg * 16, nxt * 16
        i = img.find(b"\x90\x0e\xe8", lo, hi)
        while i >= 0:
            rel = struct.unpack_from("<h", img, i + 3)[0]
            target = (i + 5 - lo + rel) & 0xFFFF
            img[i:i + 5] = b"\x9a" + struct.pack("<HH", target, seg)
            relocs[LOAD_BASE + i + 3] = seg
            i = img.find(b"\x90\x0e\xe8", i + 5, hi)
    return bytes(img)


# --------------------------------------------------------------------------- IDA export

@dataclass
class IdaSeg:
    start: int
    end: int
    name: str

    @property
    def para(self) -> int:
        return (self.start >> 4) - LOAD_SEG


@dataclass
class IdaOp:
    n: int
    optype: int
    value: int
    isoff: bool
    text: str


@dataclass
class IdaExport:
    entry: int = 0
    segs: list[IdaSeg] = field(default_factory=list)
    funcs: dict[int, tuple[int, int, str]] = field(default_factory=dict)  # start -> (end, flags, name)
    heads: dict[int, tuple[int, str]] = field(default_factory=dict)       # ea -> (size, kind)
    names: dict[int, tuple[str, bool]] = field(default_factory=dict)      # ea -> (name, user)
    crefs: dict[int, list[int]] = field(default_factory=dict)
    drefs: dict[int, list[int]] = field(default_factory=dict)
    ops: dict[int, list[IdaOp]] = field(default_factory=dict)
    comments: dict[int, str] = field(default_factory=dict)

    def seg_at(self, ea: int) -> IdaSeg | None:
        for s in self.segs:
            if s.start <= ea < s.end:
                return s
        return None

    def seg_by_name(self, name: str) -> IdaSeg:
        for s in self.segs:
            if s.name == name:
                return s
        raise KeyError(name)


def load_ida(exe: "Exe | None" = None, path: Path = IDA_EXPORT, verbose: bool = False) -> IdaExport:
    """Load the IDA export; with exe given, also repair split function tails."""
    x = IdaExport()
    with open(path, encoding="latin-1") as fh:
        for line in fh:
            f = line.rstrip("\n").split("\t")
            tag = f[0]
            if tag == "HEAD":
                x.heads[int(f[1], 16)] = (int(f[2], 16), f[3])
            elif tag == "OP":
                ea = int(f[1], 16)
                x.ops.setdefault(ea, []).append(
                    IdaOp(int(f[2]), int(f[3]), int(f[4], 16) & 0xFFFFFFFF, f[5] == "1",
                          f[6] if len(f) > 6 else ""))
            elif tag == "DREF":
                x.drefs.setdefault(int(f[1], 16), []).append(int(f[2], 16))
            elif tag == "CREF":
                x.crefs.setdefault(int(f[1], 16), []).append(int(f[2], 16))
            elif tag == "NAME":
                x.names[int(f[1], 16)] = (f[3], f[2] == "1")
            elif tag == "FUNC":
                x.funcs[int(f[1], 16)] = (int(f[2], 16), int(f[3], 16), f[4])
            elif tag == "SEG":
                x.segs.append(IdaSeg(int(f[1], 16), int(f[2], 16), f[3]))
            elif tag == "CMT":
                x.comments[int(f[1], 16)] = f[2] if len(f) > 2 else ""
            elif tag == "ENTRY":
                x.entry = int(f[1], 16)
    x.segs.sort(key=lambda s: s.start)
    if exe is not None:
        fix_segment_tails(exe, x, verbose)
    return x


def fix_segment_tails(exe, ida: IdaExport, verbose: bool = False) -> None:
    """Move code that IDA put at the start of a segment back into the previous function.

    LINK gives each code segment the frame of the paragraph containing its
    first byte, and IDA starts the segment at that paragraph, so the tail
    (e.g. `leave; retf`) of the previous segment's last function can land in
    the next segment.
    """
    import iced_x86

    enders = {iced_x86.Mnemonic.RETF, iced_x86.Mnemonic.RET, iced_x86.Mnemonic.JMP,
              iced_x86.Mnemonic.IRET}
    for prev_seg, seg in zip(ida.segs, ida.segs[1:]):
        prev = [(s, v) for s, v in ida.funcs.items() if v[0] == seg.start and s < seg.start]
        if not prev:
            continue
        start, (end, flags, name) = prev[0]
        last = None
        for ins in iced_x86.Decoder(16, exe.bytes(start, end), ip=start):
            last = ins
        if last is None or last.mnemonic in enders:
            continue
        tail_end = None
        for ins in iced_x86.Decoder(16, exe.bytes(seg.start, seg.start + 16), ip=seg.start):
            if ins.mnemonic in enders:
                tail_end = ins.next_ip
                break
        if tail_end is None:
            continue
        if verbose:
            print(f"  {name}: tail {seg.start:05X}-{tail_end:05X} moved back from {seg.name}")
        ida.funcs[start] = (tail_end, flags, name)
        for ea in [ea for ea in ida.heads if seg.start <= ea < tail_end]:
            ida.funcs.pop(ea, None)
            ida.names.pop(ea, None)
        prev_seg.end = tail_end
        seg.start = tail_end


# --------------------------------------------------------------------------- symbols.txt

@dataclass
class Sym:
    addr: int
    kind: str      # func / data / label
    size: int
    name: str
    flags: set[str] = field(default_factory=set)


class SymbolTable:
    """config/symbols.txt:  ADDR KIND SIZE NAME [flags...]   (hex addr/size)."""

    def __init__(self, syms: list[Sym] | None = None):
        self.by_addr: dict[int, Sym] = {}
        for s in syms or []:
            self.by_addr[s.addr] = s
        self._sorted: list[int] | None = None

    @classmethod
    def load(cls, path: Path = SYMBOLS) -> "SymbolTable":
        syms = []
        for line in path.read_text().splitlines():
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            f = line.split()
            syms.append(Sym(int(f[0], 16), f[1], int(f[2], 16), f[3], set(f[4:])))
        # Tools look symbols up by name (relocs.txt, rename.py, fdiff.py) and
        # by address, so both must be unique.
        dups = []
        for key, what in ((lambda s: s.name, "name"), (lambda s: s.addr, "address")):
            seen: dict = {}
            for s in syms:
                k = key(s)
                if k in seen:
                    dups.append(f"duplicate {what}: {seen[k].addr:05X} {seen[k].name} / {s.addr:05X} {s.name}")
                seen[k] = s
        if dups:
            sys.exit(f"{path}:\n  " + "\n  ".join(dups))
        return cls(syms)

    def save(self, path: Path = SYMBOLS) -> None:
        lines = ["# addr    kind   size     name  [flags]",
                 "# addr is the IDA linear address; names are linker names (C names get a",
                 "# leading underscore). Flags: lib, near, noreturn, unused (never referenced)",
                 ""]
        for s in sorted(self.by_addr.values(), key=lambda s: s.addr):
            flags = " ".join(sorted(s.flags))
            lines.append(f"{s.addr:05X}  {s.kind:<5}  {s.size:06X}  {s.name}" + (f"  {flags}" if flags else ""))
        path.write_text("\n".join(lines) + "\n")

    def add(self, s: Sym) -> None:
        self.by_addr[s.addr] = s
        self._sorted = None

    def get(self, addr: int) -> Sym | None:
        return self.by_addr.get(addr)

    def sorted_addrs(self) -> list[int]:
        if self._sorted is None:
            self._sorted = sorted(self.by_addr)
        return self._sorted

    def containing(self, addr: int, lo: int = 0, hi: int = 1 << 32,
                   want: "Callable[[Sym], bool] | None" = None) -> Sym | None:
        """Nearest symbol at or below addr, within [lo, hi), optionally filtered by want."""
        keys = self.sorted_addrs()
        i = bisect.bisect_right(keys, addr) - 1
        while i >= 0:
            s = self.by_addr[keys[i]]
            if s.addr < lo:
                return None
            if s.kind != "label" and s.addr < hi and (want is None or want(s)):
                return s
            i -= 1
        return None

    def in_range(self, start: int, end: int) -> list[Sym]:
        keys = self.sorted_addrs()
        i = bisect.bisect_left(keys, start)
        out = []
        while i < len(keys) and keys[i] < end:
            out.append(self.by_addr[keys[i]])
            i += 1
        return out


# --------------------------------------------------------------------------- units.txt

SECTION_ORDER = [".text", ".data", ".rodata", ".bss"]


@dataclass
class Unit:
    name: str
    ranges: dict[str, tuple[int, int]] = field(default_factory=dict)   # section -> [start, end)
    flags: set[str] = field(default_factory=set)

    @property
    def lib(self) -> str | None:
        for f in self.flags:
            if f.startswith("lib="):
                return f[4:]
        return None


def load_units(path: Path = UNITS) -> list[Unit]:
    """config/units.txt:  UNIT SECTION START END [flags...]   (hex, END exclusive)."""
    units: dict[str, Unit] = {}
    for line in path.read_text().splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        f = line.split()
        u = units.setdefault(f[0], Unit(f[0]))
        u.ranges[f[1]] = (int(f[2], 16), int(f[3], 16))
        u.flags.update(f[4:])
    return list(units.values())


def save_units(units: list[Unit], path: Path = UNITS, header: str = "") -> None:
    lines = ["# unit                     section  start  end    [flags]",
             "# Address ranges are IDA linear addresses, end exclusive. Units map to",
             "# src/<unit>.c (or .asm); lib=<LIB>:<module> units are built from the C library.",
             ""]
    if header:
        lines += ["# " + h for h in header.splitlines()] + [""]
    for u in units:
        for sec in sorted(u.ranges, key=lambda s: SECTION_ORDER.index(s) if s in SECTION_ORDER else 99):
            start, end = u.ranges[sec]
            flags = " ".join(sorted(u.flags))
            lines.append(f"{u.name:<26} {sec:<8} {start:05X}  {end:05X}" + (f"  {flags}" if flags else ""))
    path.write_text("\n".join(lines) + "\n")
