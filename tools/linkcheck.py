#!/usr/bin/env python3
"""List the externals no object defines, as LINK would.

    tools/linkcheck.py

Reads every compiled or assembled object in build/obj and the C libraries in
tools/C700/LIB. A name is defined by a public or a communal (an uninitialized
global, which LINK allocates). Anything referenced but not defined would stop
a link of the rebuilt EXE. Run `ninja` first so build/obj is current.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import omf  # noqa: E402
from omf2elf import ABSOLUTE_SYMBOLS  # noqa: E402
from project import ROOT  # noqa: E402


def main() -> None:
    defined: set[str] = set(ABSOLUTE_SYMBOLS)
    needed: dict[str, set[str]] = {}
    for f in sorted((ROOT / "build/obj").rglob("*.obj")):
        unit = str(f.relative_to(ROOT / "build/obj").with_suffix(""))
        for m in omf.load(str(f)):
            defined.update(p.name for p in m.publics if not p.local)
            for x in m.externs:
                if x.communal:
                    defined.add(x.name)
                elif not x.local:
                    needed.setdefault(x.name, set()).add(unit)
    for lib in sorted((ROOT / "tools/C700/LIB").glob("*.LIB")):
        for m in omf.load(str(lib)):
            defined.update(p.name for p in m.publics)
            defined.update(x.name for x in m.externs if x.communal)
    missing = {n: u for n, u in needed.items() if n not in defined}
    for name in sorted(missing):
        print(f"{name:<28} used by {', '.join(sorted(missing[name]))}")
    print(f"{len(missing)} unresolved")
    sys.exit(1 if missing else 0)


if __name__ == "__main__":
    main()
