#!/usr/bin/env python3
"""Read the game's resource files: DATA.DIR, DATA.RUN and DATA.001.

This is the Python side of FindFile / LoadFilePacked / Unpack in
src/seg003.c. The Amiga version's data000.dir, data000.run and data.000
(orig/AMIGA/StarTrek25thAnnivAGA/data/database) are read too: the same
layout with big-endian numbers, though the LZSS codes stay little-endian.

    tools/resource.py list [DIR]                  every file with its sizes
    tools/resource.py extract OUT [-e EXT]... [DIR]   unpack files into OUT

DIR defaults to orig/CD/TREKCD.
"""

import argparse
import os
import struct
import sys

DEFAULT_DIR = os.path.join(os.path.dirname(__file__), "..", "orig", "CD", "TREKCD")


def unpack(src, size):
    """LZSS as Unpack does it: a flag byte per eight items, a set bit a
    literal, a clear bit a 16-bit word (distance << 4 | length - 3).
    Distances below 2 repeat the previous byte."""
    out = bytearray()
    i = 0
    n = len(src)
    while i < n:
        flags = src[i]
        i += 1
        for bit in range(8):
            if i >= n:
                break
            if flags & (1 << bit):
                out.append(src[i])
                i += 1
            else:
                code = src[i] | src[i + 1] << 8
                i += 2
                count = (code & 0x0F) + 3
                dist = max(code >> 4, 1)
                start = len(out) - dist
                for k in range(count):
                    out.append(out[start + k])
    if len(out) != size:
        raise ValueError(f"unpacked {len(out)} bytes, expected {size}")
    return bytes(out)


class Archive:
    def __init__(self, path=DEFAULT_DIR):
        self.path = path
        self.amiga = os.path.exists(os.path.join(path, "data000.dir"))
        names = (("data000.dir", "data000.run", "data.000") if self.amiga
                 else ("DATA.DIR", "DATA.RUN", "DATA.001"))
        dirdata, run, self.data = (open(os.path.join(path, n), "rb").read()
                                   for n in names)
        self.endian = ">" if self.amiga else "<"
        # name.ext -> offset in DATA.001
        self.files = {}
        for e in range(len(dirdata) // 14):
            ent = dirdata[e * 14:e * 14 + 14]
            name = ent[:8].split(b"\0")[0].decode("ascii")
            ext = ent[8:11].split(b"\0")[0].decode("ascii")
            if self.amiga:
                hi, off = struct.unpack_from(">BH", ent, 11)
            else:
                off, hi = struct.unpack_from("<HB", ent, 11)
            if hi & 0x80:
                # numbered files: a 3-byte offset, then 16-bit steps
                count = hi & 0x7F
                if self.amiga:
                    pos = struct.unpack_from(">I", run, off)[0] >> 8 & 0x7FFFFE
                else:
                    pos = struct.unpack_from("<I", run, off)[0] & 0x7FFFFE
                q = off + 3
                for idx in range(count):
                    if idx:
                        pos += struct.unpack_from(self.endian + "H", run, q)[0] & 0xFFFE
                        q += 2
                    fname = name[:-1] + chr(ord(name[-1]) + idx)
                    self.files[f"{fname}.{ext}"] = pos
            else:
                self.files[f"{name}.{ext}"] = (hi << 16 | off) & 0x7FFFFE

    def names(self, ext=None):
        return sorted(n for n in self.files
                      if ext is None or n.rsplit(".", 1)[1] == ext.upper())

    def sizes(self, name):
        pos = self.files[name.upper()]
        return struct.unpack_from(self.endian + "HH", self.data, pos)

    def read(self, name):
        pos = self.files[name.upper()]
        size, packed = self.sizes(name)
        return unpack(self.data[pos + 4:pos + 4 + packed], size)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("list")
    p.add_argument("dir", nargs="?", default=DEFAULT_DIR)
    p = sub.add_parser("extract")
    p.add_argument("out")
    p.add_argument("-e", "--ext", action="append")
    p.add_argument("dir", nargs="?", default=DEFAULT_DIR)
    args = ap.parse_args()

    arc = Archive(args.dir)
    if args.cmd == "list":
        for n in arc.names():
            size, packed = arc.sizes(n)
            print(f"{n:16} {arc.files[n]:7X} {size:6} {packed:6}")
    else:
        exts = {e.upper() for e in args.ext} if args.ext else None
        os.makedirs(args.out, exist_ok=True)
        count = 0
        for n in arc.names():
            if exts and n.rsplit(".", 1)[1] not in exts:
                continue
            try:
                data = arc.read(n)
            except (ValueError, IndexError) as e:
                # S5ROOM3.BMP and Z_LIST.TXT don't unpack, nor the Amiga's
                # SND.BIN (the game loads the loose copy); nothing loads them
                print(f"{n}: {e}", file=sys.stderr)
                continue
            with open(os.path.join(args.out, n), "wb") as f:
                f.write(data)
            count += 1
        print(f"{count} files -> {args.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
