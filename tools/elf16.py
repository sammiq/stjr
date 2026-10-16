"""Minimal ELF32 relocatable object writer for 16-bit x86 code.

Objects are EM_386 with e_flags = EF_386_I8086, which the patched objdiff
(tools/objdiff/x86-16bit.patch) uses to decode the code as 16-bit.
Relocations are always RELA with the relocated field zeroed.
"""

from __future__ import annotations

import struct
from dataclasses import dataclass, field

EM_386 = 3
EF_386_I8086 = 0x8086

R_386_8 = 22
R_386_16 = 20
R_386_PC16 = 21
R_386_PC8 = 23
R_386_SEG16 = 45
R_386_FAR16 = 250

RELOC_SIZE = {R_386_8: 1, R_386_PC8: 1, R_386_16: 2, R_386_PC16: 2, R_386_SEG16: 2, R_386_FAR16: 4}
RELOC_NAMES = {R_386_8: "R_386_8", R_386_PC8: "R_386_PC8", R_386_16: "R_386_16",
               R_386_PC16: "R_386_PC16", R_386_SEG16: "R_386_SEG16", R_386_FAR16: "R_386_FAR16"}

SHT_PROGBITS, SHT_SYMTAB, SHT_STRTAB, SHT_RELA, SHT_NOBITS = 1, 2, 3, 4, 8
SHF_WRITE, SHF_ALLOC, SHF_EXECINSTR = 1, 2, 4
STB_LOCAL, STB_GLOBAL = 0, 1
STT_NOTYPE, STT_OBJECT, STT_FUNC, STT_SECTION = 0, 1, 2, 3
SHN_UNDEF = 0

SYM_TYPES = {"notype": STT_NOTYPE, "object": STT_OBJECT, "func": STT_FUNC}

# Standard section attributes by name prefix
SECTION_KINDS = {
    ".text": (SHT_PROGBITS, SHF_ALLOC | SHF_EXECINSTR),
    ".data": (SHT_PROGBITS, SHF_ALLOC | SHF_WRITE),
    ".rodata": (SHT_PROGBITS, SHF_ALLOC),
    ".bss": (SHT_NOBITS, SHF_ALLOC | SHF_WRITE),
}


@dataclass
class Section:
    name: str
    data: bytearray
    size: int
    sh_type: int
    flags: int
    align: int
    relocs: list[tuple[int, int, str, int]] = field(default_factory=list)  # off, type, sym, addend


@dataclass
class Symbol:
    name: str
    section: str | None   # None = undefined
    value: int
    size: int
    kind: str              # notype/object/func
    local: bool


class ElfWriter:
    def __init__(self) -> None:
        self.sections: dict[str, Section] = {}
        self.symbols: dict[str, Symbol] = {}

    def add_section(self, name: str, data: bytes | None, size: int | None = None,
                    align: int = 2) -> Section:
        prefix = "." + name.split(".")[1] if name.startswith(".") else name
        sh_type, flags = SECTION_KINDS.get(prefix, (SHT_PROGBITS, SHF_ALLOC | SHF_WRITE))
        if data is None:
            sh_type = SHT_NOBITS
        if size is None:
            size = len(data or b"")
        sec = Section(name, bytearray(data or b""), size, sh_type, flags, align)
        self.sections[name] = sec
        return sec

    def add_symbol(self, name: str, section: str | None, value: int, size: int = 0,
                   kind: str = "notype", local: bool = False) -> None:
        old = self.symbols.get(name)
        if old is not None and old.section is not None:
            return  # first definition wins
        self.symbols[name] = Symbol(name, section, value, size, kind, local)

    def add_reloc(self, section: str, offset: int, rtype: int, symbol: str, addend: int = 0,
                  zero: bool = True) -> None:
        sec = self.sections[section]
        if zero and sec.sh_type != SHT_NOBITS:
            n = RELOC_SIZE[rtype]
            sec.data[offset:offset + n] = bytes(n)
        if symbol not in self.symbols and symbol not in self.sections:
            self.symbols[symbol] = Symbol(symbol, None, 0, 0, "notype", False)
        sec.relocs.append((offset, rtype, symbol, addend))

    def write(self, path: str) -> None:
        open(path, "wb").write(self.to_bytes())

    def to_bytes(self) -> bytes:
        shstr = _StrTab()
        strtab = _StrTab()
        secs = list(self.sections.values())
        sec_index = {s.name: i + 1 for i, s in enumerate(secs)}

        # Symbol table: null, section symbols, locals, globals
        syms = [struct.pack("<IIIBBH", 0, 0, 0, 0, 0, 0)]
        sym_index: dict[str, int] = {}
        for s in secs:
            sym_index["\0sec:" + s.name] = len(syms)
            syms.append(struct.pack("<IIIBBH", 0, 0, 0, (STB_LOCAL << 4) | STT_SECTION, 0,
                                    sec_index[s.name]))
        ordered = sorted(self.symbols.values(), key=lambda s: (not s.local,))
        n_local = len(syms) + sum(1 for s in ordered if s.local)
        for s in ordered:
            sym_index[s.name] = len(syms)
            bind = STB_LOCAL if s.local else STB_GLOBAL
            shndx = sec_index[s.section] if s.section else SHN_UNDEF
            syms.append(struct.pack("<IIIBBH", strtab.add(s.name), s.value, s.size,
                                    (bind << 4) | SYM_TYPES[s.kind], 0, shndx))

        # Layout: header, section contents, rela, symtab, strtab, shstrtab, section headers
        blobs: list[tuple[str, int, int, int, int, int, int, bytes]] = []
        # (name, type, flags, link, info, align, entsize, data)
        for s in secs:
            blobs.append((s.name, s.sh_type, s.flags, 0, 0, s.align, 0,
                          b"" if s.sh_type == SHT_NOBITS else bytes(s.data)))
        symtab_idx = len(secs) + 1 + sum(1 for s in secs if s.relocs)
        for s in secs:
            if not s.relocs:
                continue
            rela = bytearray()
            for off, rtype, sym, addend in sorted(s.relocs):
                idx = sym_index.get(sym)
                if idx is None:
                    idx = sym_index["\0sec:" + sym]
                rela += struct.pack("<IIi", off, (idx << 8) | rtype, addend)
            blobs.append((".rela" + s.name, SHT_RELA, 0, symtab_idx, sec_index[s.name], 4, 12,
                          bytes(rela)))
        blobs.append((".symtab", SHT_SYMTAB, 0, symtab_idx + 1, n_local, 4, 16, b"".join(syms)))
        blobs.append((".strtab", SHT_STRTAB, 0, 0, 0, 1, 0, strtab.data()))
        shstr_idx = len(blobs) + 1
        names = [shstr.add(b[0]) for b in blobs]
        shstrtab_name = shstr.add(".shstrtab")
        blobs.append((".shstrtab", SHT_STRTAB, 0, 0, 0, 1, 0, shstr.data()))
        names.append(shstrtab_name)

        out = bytearray(52)
        headers = [bytes(40)]
        for (name, typ, flags, link, info, align, entsize, data), nm in zip(blobs, names):
            while len(out) % max(align, 1):
                out.append(0)
            off = len(out)
            size = len(data)
            if typ == SHT_NOBITS:
                size = self.sections[name].size
            else:
                out += data
            headers.append(struct.pack("<IIIIIIIIII", nm, typ, flags, 0, off, size, link, info,
                                       align, entsize))
        while len(out) % 4:
            out.append(0)
        shoff = len(out)
        out += b"".join(headers)
        ident = b"\x7fELF" + bytes([1, 1, 1, 0]) + bytes(8)
        out[0:52] = ident + struct.pack("<HHIIIIIHHHHHH", 1, EM_386, 1, 0, 0, shoff,
                                        EF_386_I8086, 52, 0, 0, 40, len(headers), shstr_idx)
        return bytes(out)


class _StrTab:
    def __init__(self) -> None:
        self.buf = bytearray(b"\0")
        self.cache: dict[str, int] = {}

    def add(self, s: str) -> int:
        if s not in self.cache:
            self.cache[s] = len(self.buf)
            self.buf += s.encode("latin-1") + b"\0"
        return self.cache[s]

    def data(self) -> bytes:
        return bytes(self.buf)
