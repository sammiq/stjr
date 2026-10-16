#!/usr/bin/env python3
"""Rebuild BUILD/DOS/STARTREK.EXE with the original tools (NMAKE, Microsoft
C 6.00A, MASM 5.0, LINK 5.10) running in DOSBox, then compare it with the
original EXE.

The original was linked with /EXEPACK, so the build is compared with the
original, packed STARTREK.EXE. Both are then unpacked with exepack (see
project.exepack_tool) and the images compared too: there a difference stays at
the address it affects.

    tools/dosbuild.py [NMAKE args...]     e.g. tools/dosbuild.py /A  (rebuild all)

Drives: C: tools/C600, D: the project root, E: tools/MASM50. NMAKE's output
goes to BUILD/DOS/NMAKE.LOG. DOSBox (dosbox-staging) runs headless with SDL's
offscreen video driver. emu2, which the per-unit build uses, can't run this
link: LINK 5.10 goes wrong under it with this many objects.
"""

from __future__ import annotations

import os
import struct
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from project import EXE_PATH, ORIG_EXE, ROOT, exepack_tool, unpack_original  # noqa: E402

DOSBOX = os.environ.get("DOSBOX", "dosbox")
OUT = ROOT / "build/dos"
HEADER = ["sig", "cblp", "cp", "crlc", "cparhdr", "minalloc", "maxalloc", "ss", "sp",
          "csum", "ip", "cs", "lfarlc", "ovno"]


def find(name: str) -> Path | None:
    return next((p for p in OUT.iterdir() if p.name.lower() == name.lower()), None)


def run_nmake(args: list[str]) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    log = find("NMAKE.LOG")
    if log:
        log.unlink()
    nmake = " ".join(["C:\\BIN\\NMAKE", "/NOLOGO", "/F", "STARTREK.MAK", *args])
    cmds = [f"mount c {ROOT / 'tools/C600'}", f"mount d {ROOT}", f"mount e {ROOT / 'tools/MASM50'}",
            "d:", "set PATH=C:\\BIN;C:\\BINB;E:\\BIN", "set INCLUDE=C:\\INCLUDE",
            "set LIB=C:\\LIB", "set TMP=D:\\BUILD\\DOS",
            f"{nmake} > BUILD\\DOS\\NMAKE.LOG"]
    env = dict(os.environ, SDL_VIDEODRIVER="offscreen", SDL_AUDIODRIVER="dummy")
    cmd = [DOSBOX, "--noprimaryconf", "--nolocalconf", "-set", "sdl output=texture",
           "-set", "cpu cycles=max", "-noconsole", "-exit"]
    for c in cmds:
        cmd += ["-c", c]
    try:
        subprocess.run(cmd, env=env, cwd=ROOT, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL, timeout=1800)
    except subprocess.TimeoutExpired:
        print("dosbuild: DOSBox did not exit within 30 minutes", file=sys.stderr)
    log = find("NMAKE.LOG")
    if log:
        lines = [ln for ln in log.read_text(errors="replace").splitlines()
                 if ln.strip() and not ln.startswith("Object Modules")]
        print("\n".join(lines))


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
    out = OUT / "STARTREK.UNP"
    try:
        subprocess.run([exepack_tool(), "-d", str(exe), str(out)], check=True, capture_output=True)
    except (OSError, subprocess.CalledProcessError):
        return None
    return out


def main() -> None:
    run_nmake(sys.argv[1:])
    exe = find("STARTREK.EXE")
    if exe is None:
        sys.exit("no STARTREK.EXE was built")
    compare(exe, ORIG_EXE)
    unpacked = unpack(exe)
    if unpacked is not None:
        compare(unpacked, unpack_original())
    else:
        print("(no exepack: skipping the unpacked comparison)")


if __name__ == "__main__":
    main()
