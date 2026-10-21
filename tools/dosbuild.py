#!/usr/bin/env python3
"""Link build/dos/TREKJR.EXE from the project's objects with the original
tools (Microsoft C/C++ 7.00's LINK, MASM 5.0) under dosemu2, then compare it
with the original EXE.

    tools/dosbuild.py

The objects are the per-unit ones ninja already builds (build/obj/*.obj, from
tools/cc.py), so run ninja first. src/BSS.ASM (tools/genbss.py) is
assembled here and linked last. The link order is the units' code order
(config/units.txt); the C runtime comes from MLIBCA.LIB, the medium model
alternate math library (/FPa).

The original was linked with /EXEPACK, so the build is compared with the
packed TREKJR.EXE, and both are unpacked with exepack and compared again:
there a difference stays at the address it affects.
"""

from __future__ import annotations

import struct
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from cc import MASM, MSC, dos_path, run_dos  # noqa: E402
from project import ORIG_EXE, ROOT, exepack_tool, load_units, unpack_original  # noqa: E402

OUT = ROOT / "build/dos"
EXE = OUT / "TREKJR.EXE"
HEADER = ["sig", "cblp", "cp", "crlc", "cparhdr", "minalloc", "maxalloc", "ss", "sp",
          "csum", "ip", "cs", "lfarlc", "ovno"]
# /NOI: names are case sensitive. /NOD: the runtime is named explicitly.
# /STACK: SS:SP is 3836:12E8 in the original.
LINK_OPTS = "/NOLOGO /NOI /NOD /EXEPACK /PACKCODE /FARCALLTRANSLATION /MAP /STACK:0x12E8"
LIBS = [f"{MSC}\\LIB\\MLIBCA.LIB", f"{MSC}\\LIB\\OLDNAMES.LIB"]


def find(path: Path) -> Path | None:
    """A file DOS wrote, whatever the case of its name."""
    return next((p for p in path.parent.iterdir() if p.name.lower() == path.name.lower()), None)


def remove(path: Path) -> None:
    found = find(path)
    if found is not None:
        found.unlink()


def objects() -> list[Path]:
    """The game's objects in link order: the units with source, by address."""
    units = [u for u in load_units() if ".text" in u.ranges and not u.lib
             and (ROOT / "src" / f"{u.name}.c").exists() or (ROOT / "src" / f"{u.name}.asm").exists()]
    units = [u for u in units if ".text" in u.ranges and not u.lib]
    units.sort(key=lambda u: u.ranges[".text"][0])
    out = []
    for u in units:
        obj = ROOT / "build/obj" / f"{u.name}.obj"
        if not obj.exists():
            sys.exit(f"dosbuild: {obj.relative_to(ROOT)} is missing (run ninja)")
        out.append(obj)
    return out


def assemble_bss() -> Path:
    obj = OUT / "BSS.OBJ"
    remove(obj)
    log = run_dos(["SET INCLUDE=" + MASM + "\\INC",
                   f"{MASM}\\BIN\\MASM.EXE /Ml /t {dos_path(ROOT / 'src/BSS.ASM')},{dos_path(obj)};"], "DBBSS")
    found = find(obj)
    if found is None:
        sys.exit("dosbuild: BSS.ASM did not assemble\n" + log)
    return found


def link(objs: list[Path]) -> str:
    rsp = OUT / "TREKJR.LNK"
    lines = [dos_path(o) + ("+" if i < len(objs) - 1 else "") for i, o in enumerate(objs)]
    lines += [dos_path(EXE), dos_path(OUT / "TREKJR.MAP"), "+".join(LIBS) + ";"]
    rsp.write_text("\r\n".join(lines) + "\r\n")
    for p in (EXE, OUT / "TREKJR.MAP"):
        remove(p)
    return run_dos(["SET PATH=" + MSC + "\\BIN", "SET TMP=" + dos_path(OUT),
                    f"{MSC}\\BIN\\LINK.EXE {LINK_OPTS} @{dos_path(rsp)}"], "DBLINK")


def compare(exe: Path, orig: Path) -> None:
    a, b = orig.read_bytes(), exe.read_bytes()
    ha, hb = struct.unpack_from("<14H", a), struct.unpack_from("<14H", b)
    diff = [f"{n} {x:04X}/{y:04X}" for n, x, y in zip(HEADER, ha, hb) if x != y]
    same = sum(x == y for x, y in zip(a, b))
    print(f"{exe.relative_to(ROOT)}: {len(b)} bytes ({orig.relative_to(ROOT)}: {len(a)}); "
          f"{same}/{len(a)} bytes equal ({100 * same / len(a):.2f}%)")
    print("  header differences (original/rebuilt): " + (", ".join(diff) if diff else "none"))
    if a == b:
        print(f"  identical to {orig.relative_to(ROOT)}")


def unpack(exe: Path) -> Path | None:
    out = OUT / "TREKJR.UNP"
    try:
        subprocess.run([exepack_tool(), "-d", str(exe), str(out)], check=True, capture_output=True)
    except (OSError, subprocess.CalledProcessError):
        return None
    return out


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    objs = objects() + [assemble_bss()]
    log = link(objs)
    msgs = [ln for ln in log.splitlines() if ln.strip()]
    if msgs:
        print("\n".join(msgs))
    exe = find(EXE)
    if exe is None:
        sys.exit("dosbuild: no TREKJR.EXE was linked")
    compare(exe, ORIG_EXE)
    unpacked = unpack(exe)
    if unpacked is not None:
        compare(unpacked, unpack_original())
    else:
        print("(no exepack: skipping the unpacked comparison)")


if __name__ == "__main__":
    main()
