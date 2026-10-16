#!/usr/bin/env python3
"""Compile a C file with Microsoft C/C++ 7.00 (or assemble a .asm file with
MASM 5.0) under dosemu2 and convert the result to ELF.

    cc.py SRC OUT.o [--omf OUT.obj] -- [CL flags...]

C 7.00's compiler passes are 32-bit DOS-extended programs that need a DPMI
host; dosemu2 provides one (emu2 has none, and HDPMI32/CWSDPMI under DOSBox
crash in MS32KRNL.DLL). The project root is the current drive in DOS, so
every path the compiler sees must be inside the project and use 8.3 names.
Tools are reached as \\TOOLS\\C700 and \\TOOLS\\MASM50 on that drive.

dosemu2's default shell (comcom64) needs the dj64 runtime; comcom32 is used
instead ($DOSEMU2_COMCOM_DIR, default /usr/share/comcom32).
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import omf  # noqa: E402
import omf2elf  # noqa: E402
from project import ROOT  # noqa: E402

DOSEMU = os.environ.get("DOSEMU", "dosemu")
COMCOM = os.environ.get("DOSEMU2_COMCOM_DIR", "/usr/share/comcom32")
MSC = "\\TOOLS\\C700"
MASM = "\\TOOLS\\MASM50"


def dos_path(p: Path) -> str:
    rel = p.resolve().relative_to(ROOT)
    for part in rel.parts:
        stem, _, ext = part.partition(".")
        if len(stem) > 8 or len(ext) > 3:
            sys.exit(f"cc: '{rel}' is not a DOS 8.3 path")
    return "\\" + "\\".join(rel.parts).upper()


def run_dos(lines: list[str], tag: str) -> str:
    """Run batch lines in dosemu2 with the project root as the current drive;
    returns what the commands wrote to the log."""
    work = ROOT / "build/cc"
    work.mkdir(parents=True, exist_ok=True)
    bat = work / f"{tag}.BAT"
    log = work / f"{tag}.LOG"
    for p in (bat, log, work / f"{tag.lower()}.log"):
        if p.exists():
            p.unlink()
    logp = dos_path(log)
    body = ["@echo off"] + [f"{ln} >> {logp}" if ln.split()[0].upper() not in ("SET", "@ECHO") else ln
                            for ln in lines]
    bat.write_text("\r\n".join(body) + "\r\n")
    env = dict(os.environ, DOSEMU2_COMCOM_DIR=COMCOM)
    subprocess.run([DOSEMU, "-dumb", "-K", str(ROOT), "-E", dos_path(bat)], env=env,
                   stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                   timeout=600)
    found = next((p for p in work.iterdir() if p.name.lower() == log.name.lower()), None)
    out = found.read_text(errors="replace") if found else ""
    bat.unlink()
    if found:
        found.unlink()
    return out


def main() -> None:
    argv = sys.argv[1:]
    flags: list[str] = []
    if "--" in argv:
        i = argv.index("--")
        argv, flags = argv[:i], argv[i + 1:]
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--omf", help="where to keep the OMF object (default: OUT with .obj)")
    args = ap.parse_args(argv)

    src = Path(args.src)
    out = Path(args.out)
    obj = Path(args.omf) if args.omf else out.with_suffix(".obj")
    obj.parent.mkdir(parents=True, exist_ok=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    # DOS file names are case-insensitive: replace any old object of any case
    if obj.parent.exists():
        for old in obj.parent.iterdir():
            if old.name.lower() == obj.name.lower():
                old.unlink()
    tag = "C" + format(abs(hash(str(obj.resolve()))) % 10**7, "07d")
    tmp = ROOT / "build/cc" / tag     # CL's intermediate files, one directory per compile
    tmp.mkdir(parents=True, exist_ok=True)

    if src.suffix.lower() == ".asm":
        # /Ml: case sensitive names, /t: quiet unless there are errors
        lines = ["SET INCLUDE=" + MASM + "\\INC",
                 f"{MASM}\\BIN\\MASM.EXE /Ml /t {' '.join(flags)} {dos_path(src)},{dos_path(obj)};"]
    else:
        lines = ["SET PATH=" + MSC + "\\BIN", "SET INCLUDE=" + MSC + "\\INCLUDE", "SET TMP=" + dos_path(tmp),
                 f"{MSC}\\BIN\\CL.EXE /c /nologo {' '.join(flags)} /Fo{dos_path(obj)} {dos_path(src)}"]
    log = run_dos(lines, tag)
    for leftover in tmp.iterdir():
        leftover.unlink()
    tmp.rmdir()
    # CL echoes the source file name; only show real diagnostics
    msgs = [ln for ln in log.splitlines()
            if ln.strip() and ln.strip().lower() not in (src.name.lower(), dos_path(src).lower())]
    produced = next((p for p in obj.parent.iterdir() if p.name.lower() == obj.name.lower()), None)
    if msgs:
        print("\n".join(msgs), file=sys.stderr)
    if produced is None or any(" error " in m.lower() for m in msgs):
        sys.exit(1)
    if produced != obj:
        produced.rename(obj)

    mod = omf.parse_obj(obj.read_bytes())
    omf2elf.convert(mod).write(str(out))


if __name__ == "__main__":
    main()
