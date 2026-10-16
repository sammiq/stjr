"""Parser for Intel/Microsoft OMF-86 object files and LIB archives.

Covers the subset of records emitted by Microsoft C 6.00 and its libraries.
"""

from __future__ import annotations

import struct
import sys
from dataclasses import dataclass, field

# Fixup location types
LOC_LOBYTE = 0
LOC_OFFSET = 1
LOC_BASE = 2
LOC_POINTER = 3
LOC_HIBYTE = 4
LOC_OFFSET_LOADER = 5

# Frame / target methods
F_SEGDEF, F_GRPDEF, F_EXTDEF, F_FRAMENUM, F_LOCATION, F_TARGET = 0, 1, 2, 3, 4, 5
T_SEGDEF, T_GRPDEF, T_EXTDEF, T_FRAMENUM = 0, 1, 2, 3


@dataclass
class Fixup:
    offset: int          # offset of the fixed-up field within the segment
    loc: int             # LOC_* location type
    seg_relative: bool   # M bit: True = segment relative, False = self relative
    frame_method: int
    frame_index: int
    target_method: int   # T_* (method & 3)
    target_index: int
    disp: int

    @property
    def size(self) -> int:
        return {LOC_LOBYTE: 1, LOC_HIBYTE: 1, LOC_POINTER: 4}.get(self.loc, 2)


@dataclass
class Segment:
    index: int
    name: str
    cls: str
    overlay: str
    align: int
    combine: int
    length: int
    data: bytearray = field(default_factory=bytearray)
    initialized: bytearray = field(default_factory=bytearray)  # 1 per byte written
    fixups: list[Fixup] = field(default_factory=list)


@dataclass
class Group:
    index: int
    name: str
    segments: list[int]   # segment indices


@dataclass
class Public:
    name: str
    seg: int              # segment index (0 = absolute)
    group: int
    offset: int
    local: bool = False


@dataclass
class Extern:
    index: int            # 1-based external index
    name: str
    local: bool = False
    communal: bool = False
    far: bool = False
    size: int = 0         # communal size in bytes


@dataclass
class Module:
    name: str = ""
    segments: list[Segment] = field(default_factory=list)   # index-1
    groups: list[Group] = field(default_factory=list)
    publics: list[Public] = field(default_factory=list)
    externs: list[Extern] = field(default_factory=list)     # index-1
    comments: list[tuple[int, bytes]] = field(default_factory=list)

    def seg(self, idx: int) -> Segment:
        return self.segments[idx - 1]

    def group(self, idx: int) -> Group:
        return self.groups[idx - 1]

    def ext(self, idx: int) -> Extern:
        return self.externs[idx - 1]

    def seg_by_name(self, name: str) -> Segment | None:
        for s in self.segments:
            if s.name == name:
                return s
        return None

    def group_of(self, seg_idx: int) -> Group | None:
        for g in self.groups:
            if seg_idx in g.segments:
                return g
        return None


class OmfError(Exception):
    pass


class _Reader:
    def __init__(self, data: bytes, rectype: int):
        self.d = data
        self.p = 0
        self.wide = rectype & 1   # 32-bit variant of the record

    def eof(self) -> bool:
        return self.p >= len(self.d)

    def u8(self) -> int:
        v = self.d[self.p]
        self.p += 1
        return v

    def u16(self) -> int:
        v = struct.unpack_from("<H", self.d, self.p)[0]
        self.p += 2
        return v

    def u32(self) -> int:
        v = struct.unpack_from("<I", self.d, self.p)[0]
        self.p += 4
        return v

    def off(self) -> int:
        return self.u32() if self.wide else self.u16()

    def index(self) -> int:
        b = self.u8()
        if b & 0x80:
            return ((b & 0x7F) << 8) | self.u8()
        return b

    def name(self) -> str:
        n = self.u8()
        s = self.d[self.p:self.p + n]
        self.p += n
        return s.decode("latin-1")

    def comlen(self) -> int:
        b = self.u8()
        if b <= 0x80:
            return b
        n = {0x81: 2, 0x84: 3, 0x88: 4}[b]
        v = int.from_bytes(self.d[self.p:self.p + n], "little")
        self.p += n
        return v

    def rest(self) -> bytes:
        r = self.d[self.p:]
        self.p = len(self.d)
        return r


def _parse_module(data: bytes, pos: int) -> tuple[Module, int]:
    """Parse one module starting at pos; returns (module, position after MODEND)."""
    m = Module()
    lnames: list[str] = []
    threads_t: dict[int, tuple[int, int]] = {}
    threads_f: dict[int, tuple[int, int]] = {}
    last_data: tuple[Segment, int] | None = None   # (segment, base offset) of last LEDATA

    while pos < len(data):
        rectype = data[pos]
        reclen = struct.unpack_from("<H", data, pos + 1)[0]
        body = data[pos + 3:pos + 3 + reclen - 1]
        pos += 3 + reclen
        r = _Reader(body, rectype)
        t = rectype & 0xFE

        if t == 0x80 or t == 0x82:          # THEADR / LHEADR
            m.name = r.name()
        elif t == 0x88:                      # COMENT
            r.u8()
            cls = r.u8()
            m.comments.append((cls, r.rest()))
        elif t == 0x96 or t == 0xCA:         # LNAMES / LLNAMES
            while not r.eof():
                lnames.append(r.name())
        elif t == 0x98:                      # SEGDEF
            acbp = r.u8()
            align = acbp >> 5
            if align == 0:
                r.u16()
                r.u8()
            length = r.off()
            if acbp & 2:
                length = 0x10000 if not r.wide else 0x100000000
            name = lnames[r.index() - 1]
            cls = lnames[r.index() - 1]
            ovl_i = r.index()
            ovl = lnames[ovl_i - 1] if ovl_i else ""
            m.segments.append(Segment(len(m.segments) + 1, name, cls, ovl, align,
                                      (acbp >> 2) & 7, length,
                                      bytearray(length), bytearray(length)))
        elif t == 0x9A:                      # GRPDEF
            name = lnames[r.index() - 1]
            segs = []
            while not r.eof():
                r.u8()  # 0xFF
                segs.append(r.index())
            m.groups.append(Group(len(m.groups) + 1, name, segs))
        elif t in (0x8C, 0xB4):              # EXTDEF / LEXTDEF
            while not r.eof():
                name = r.name()
                r.index()
                m.externs.append(Extern(len(m.externs) + 1, name, local=(t == 0xB4)))
        elif t in (0xB0, 0xB8):              # COMDEF / LCOMDEF
            while not r.eof():
                name = r.name()
                r.index()
                kind = r.u8()
                if kind == 0x61:
                    n = r.comlen()
                    sz = r.comlen()
                    size, far = n * sz, True
                else:
                    size, far = r.comlen(), False
                m.externs.append(Extern(len(m.externs) + 1, name, local=(t == 0xB8),
                                        communal=True, far=far, size=size))
        elif t in (0x90, 0xB6):              # PUBDEF / LPUBDEF
            grp = r.index()
            seg = r.index()
            if seg == 0:
                r.u16()
            while not r.eof():
                name = r.name()
                off = r.off()
                r.index()
                m.publics.append(Public(name, seg, grp, off, local=(t == 0xB6)))
        elif t == 0xA0:                      # LEDATA
            seg = m.seg(r.index())
            off = r.off()
            chunk = r.rest()
            _store(seg, off, chunk)
            last_data = (seg, off)
        elif t == 0xA2:                      # LIDATA
            seg = m.seg(r.index())
            off = r.off()
            out = bytearray()
            while not r.eof():
                out += _lidata_block(r)
            _store(seg, off, bytes(out))
            last_data = (seg, off)
        elif t == 0x9C:                      # FIXUPP
            while not r.eof():
                b = r.u8()
                if not b & 0x80:             # THREAD
                    method = (b >> 2) & 7
                    num = b & 3
                    if b & 0x40:     # frame thread: F0-F2 index, F3 frame number
                        idx = r.index() if method < 3 else (r.u16() if method == 3 else 0)
                        threads_f[num] = (method, idx)
                    else:            # target thread: always followed by an index
                        threads_t[num] = (method & 3, r.index())
                    continue
                if last_data is None:
                    raise OmfError("FIXUPP without preceding data record")
                locat = (b << 8) | r.u8()
                seg_rel = bool(locat & 0x4000)
                loc = (locat >> 10) & 0xF
                rec_off = locat & 0x3FF
                fd = r.u8()
                if fd & 0x80:
                    fmethod, fidx = threads_f[(fd >> 4) & 7]
                else:
                    fmethod = (fd >> 4) & 7
                    fidx = r.index() if fmethod < 3 else (r.u16() if fmethod == 3 else 0)
                if fd & 0x08:
                    tmethod, tidx = threads_t[fd & 3]
                    tmethod &= 3
                else:
                    tmethod = fd & 3
                    tidx = r.index()
                disp = 0 if fd & 0x04 else r.off()
                seg, base = last_data
                seg.fixups.append(Fixup(base + rec_off, loc, seg_rel, fmethod, fidx,
                                        tmethod, tidx, disp))
        elif t == 0x8A:                      # MODEND
            return m, pos
        elif t == 0xB2:                      # BAKPAT: add values to earlier data
            seg = m.seg(r.index())
            kind = r.u8()
            size = {0: 1, 1: 2, 2: 4}[kind]
            while not r.eof():
                off = r.off()
                val = r.off()
                cur = int.from_bytes(seg.data[off:off + size], "little")
                seg.data[off:off + size] = ((cur + val) & ((1 << (8 * size)) - 1)).to_bytes(size, "little")
        elif t in (0x94, 0x8E, 0xC4, 0xC6):
            # LINNUM, TYPDEF, LINSYM, ALIAS - not needed
            pass
        elif t in (0xBC, 0xC2) and m.name.lower().endswith(".cxx"):
            # CEXTDEF, COMDAT: only C 7.00's iostream (C++) library modules
            pass
        else:
            print(f"omf: warning: unhandled record {rectype:02X} in {m.name}", file=sys.stderr)
    raise OmfError("missing MODEND")


def _store(seg: Segment, off: int, chunk: bytes) -> None:
    end = off + len(chunk)
    if end > len(seg.data):
        seg.data.extend(bytes(end - len(seg.data)))
        seg.initialized.extend(bytes(end - len(seg.initialized)))
    seg.data[off:end] = chunk
    seg.initialized[off:end] = b"\x01" * len(chunk)


def _lidata_block(r: _Reader) -> bytes:
    repeat = r.off()
    blocks = r.u16()
    if blocks == 0:
        n = r.u8()
        content = r.d[r.p:r.p + n]
        r.p += n
        return content * repeat
    inner = bytearray()
    for _ in range(blocks):
        inner += _lidata_block(r)
    return bytes(inner) * repeat


def parse_obj(data: bytes) -> Module:
    m, _ = _parse_module(data, 0)
    return m


def parse_lib(data: bytes) -> list[Module]:
    if data[0] != 0xF0:
        raise OmfError("not an OMF library")
    page = struct.unpack_from("<H", data, 1)[0] + 3
    pos = page
    mods = []
    while pos < len(data) and data[pos] != 0xF1:
        m, end = _parse_module(data, pos)
        mods.append(m)
        pos = (end + page - 1) // page * page
    return mods


def load(path: str) -> list[Module]:
    data = open(path, "rb").read()
    if data[0] == 0xF0:
        return parse_lib(data)
    return [parse_obj(data)]


def describe(m: Module) -> str:
    out = [f"module {m.name}"]
    for g in m.groups:
        out.append(f"  group {g.name}: " + ", ".join(m.seg(s).name for s in g.segments))
    for s in m.segments:
        out.append(f"  seg {s.index} {s.name} class={s.cls} len={s.length:#x} align={s.align} "
                   f"combine={s.combine} fixups={len(s.fixups)}")
    for e in m.externs:
        out.append(f"  ext {e.index} {e.name}" + (f" communal size={e.size}" if e.communal else ""))
    for p in m.publics:
        out.append(f"  pub {p.name} {m.seg(p.seg).name if p.seg else 'ABS'}:{p.offset:04X}"
                   + (" local" if p.local else ""))
    for s in m.segments:
        for f in s.fixups:
            out.append(f"  fix {s.name}+{f.offset:04X} loc={f.loc} {'seg' if f.seg_relative else 'self'} "
                       f"F{f.frame_method}:{f.frame_index} T{f.target_method}:{f.target_index} +{f.disp:#x}")
    return "\n".join(out)


if __name__ == "__main__":
    for path in sys.argv[1:]:
        for mod in load(path):
            print(describe(mod))
