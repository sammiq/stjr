#!/usr/bin/env python3
"""Rename symbols everywhere: config/symbols.txt, config/relocs.txt and the
C/assembly sources and headers.

tools/rename.py _sub_3AEFF _AIL_startup [_old2 _new2 ...]

Names are linker names (with the leading underscore). In C files the name
without the underscore is replaced too.
"""

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main() -> None:
    args = sys.argv[1:]
    if not args or len(args) % 2:
        sys.exit(__doc__)
    pairs = list(zip(args[::2], args[1::2]))
    files = [ROOT / "config/symbols.txt", ROOT / "config/relocs.txt"]
    files += sorted((ROOT / "src").rglob("*.c")) + sorted((ROOT / "src").rglob("*.asm"))
    files += sorted((ROOT / "include").glob("*.h"))
    for f in files:
        text = f.read_text(errors="surrogateescape")
        new = text
        for old, rep in pairs:
            new = re.sub(rf"(?<![\w$?@]){re.escape(old)}(?![\w$?@])", rep, new)
            if f.suffix in (".c", ".h") and old.startswith("_") and rep.startswith("_"):
                new = re.sub(rf"(?<![\w$?@]){re.escape(old[1:])}(?![\w$?@])", rep[1:], new)
        if new != text:
            f.write_text(new, errors="surrogateescape")
            print(f"updated {f.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
