# Star Trek: Judgment Rites (CD, DOS) decompilation

Matching decompilation of `TREKJR.EXE`, the DOS executable of the Judgment Rites CD release (dated 7 Oct 1995). The aim is C source that compiles to the original machine code with the original compiler, measured function by function with [objdiff](https://github.com/encounter/objdiff).

Judgment Rites is the sequel to Star Trek: 25th Anniversary, whose finished decompilation lives in `ref/st25/` (its sources, headers, config, notes and ST25-only tools). Much of the sequel's engine is the same C source recompiled: ST25's `seg010` (vectors), `seg011` (lists) and `seg013` (memory) compile byte for byte to the sequel's code with the flags below. Start a function by finding its ST25 counterpart.

## The original build

| | |
|---|---|
| Compiler | Microsoft C/C++ 7.00 (`tools/C700`), runtime "Copyright (c) 1992" |
| Memory model | Medium (`/AM`): far code, near data |
| Game code flags | `/AM /G2 /Ox /Zp1` (`/Zp1` is carried over from ST25, not yet confirmed) |
| Runtime | `MLIBCE.LIB` (medium model, 8087 emulator) |
| Link | `/EXEPACK /PACKCODE /FARCALLTRANSLATION` |

Differences from ST25 (C 6.00A `/qc`) that the tooling deals with:

- **Packed code.** LINK `/PACKCODE` merged every `.C` file's code segment into three segments (0000h, 0BD6h and 1B98h, whose tail is the C runtime's `_TEXT`). Nothing in the EXE marks where one file ends. The files are found from the ST25 functions that still compile to the sequel's code (`tools/st25match.py`): the sequel links ST25's files in almost the same order, each as one run of addresses.
- **Far call translation.** LINK turned far calls inside a packed segment into `nop; push cs; call near` (`90 0E E8`). `project.load_exe()` turns them back into `call far` with a segment fixup, so the image every tool sees compares with compiled objects. A 4-byte `push cs; call near` without the `nop` is the compiler's own call to a function in the same file.
- **No IDA database.** `tools/analyze.py` disassembles the EXE (recursive descent from every far call, near call and far code pointer) and writes `build/analysis.txt` in the IDA-export format the ST25 tools read. An IDA export from `tools/ida/export.idc` can replace it.
- **DGROUP** is 2B87h (linear 3B870h). The far data segments are 290Eh, 2B0Eh and 2B3Eh. String literals are in the game's `_DATA`, not `CONST`.

## Setup

You need Python 3.11+, ninja, **dosemu2** and a Rust toolchain (for objdiff and exepack).

```sh
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
tools/objdiff/build.sh             # patched objdiff + objdiff-cli -> tools/bin
tools/exepack/build.sh             # exepack -> tools/bin
.venv/bin/python configure.py      # writes build.ninja and objdiff.json
ninja                              # unpack, analyse, split targets, build base objects
ninja progress                     # progress summary (tools/progress.py build/report.json -v per unit)
```

These inputs are not in git, so supply your own copies:
- `orig/CD/` - the CD's files; `orig/CD/TREKJR.EXE` must match `config/orig.sha1`
- `tools/C700/` - Microsoft C/C++ 7.00 (`BIN`, `INCLUDE`, `LIB`)
- `tools/MASM50/` - Microsoft Assembler 5.0, for assembly units

### Running the compiler

C 7.00's compiler passes are 32-bit DOS-extended programs (DOSX32 + `MS32KRNL.DLL`, a cut-down Win32 kernel) that need a DPMI host. Microsoft supported only a Windows 3.x DOS box or Qualitas 386-MAX. emu2 has no DPMI; in DOSBox, both HDPMI32 and CWSDPMI start it, but MS32KRNL then faults during its own start-up. **dosemu2** works, and `tools/cc.py` runs each compile in it: `dosemu -dumb -K <project> -E <batch>`, with the project root as the current drive, so paths must be 8.3 and inside the project. A compile takes about 0.7 s, and each compile gets its own `TMP` directory so ninja can run them in parallel.

dosemu2's default shell, comcom64, needs the dj64 runtime, which Fedora's packages don't install, so `cc.py` sets `DOSEMU2_COMCOM_DIR=/usr/share/comcom32` (override with that variable). `$DOSEMU` selects the dosemu binary.

## Layout

```
config/symbols.txt   every function/data symbol: address, kind, size, name
config/units.txt     units (translation units) and their address ranges
config/relocs.txt    explicit references the analysis can't tell from numbers
config/aliases.txt   library names sharing an address (generated)
src/<unit>.c         decompiled source, one file per unit
include/             shared headers
ref/st25/            the 25th Anniversary decompilation, for reference
build/analysis.txt   generated disassembly structure (tools/analyze.py)
build/target/        target objects split from the EXE (generated)
build/base/          objects compiled from src/ or taken from the C library
```

Addresses are linear, with the load module at paragraph 1000h: `seg001:6056` is `1BD60 + 6056 = 21DB6`.

### Units

- **`segNNN`**: the sequel's version of ST25's `ref/st25/src/segNNN.c`, from its first to its last function that still matches (`tools/st25port.py units`). `src/segNNN.c` started as the ST25 file with the non-matching functions taken out (`tools/st25port.py src`).
- **`c<addr>`**: game code between two files' runs: new code, or the changed functions of a neighbouring file. Move code from these into a file's unit by editing `config/units.txt` (or carve out a new file with `tools/splitunit.py`) as it's identified. Unit names must be 8.3, as the compiler runs under DOS.
- **`lib/<module>`**: C runtime modules (`tools/libmatch.py`), built straight from `MLIBCE.LIB`. Their target relocations come from the library's own fixups, so they match 100%.
- **`asm/tXXXXX`**: code in the runtime's `_TEXT` that isn't from the library: about 9 KB of hand-written assembly (interrupt handlers, sound).
- **`far/segNNN`, `data/dXXXXX`, `data/stack`**: far data segments and the DGROUP pieces not yet given to a unit.

## Carrying ST25 code over

`tools/st25match.py` compiles every ST25 file with C 7.00 and the game flags (into `build/st25/`) and looks each function up in the sequel: byte for byte with relocated fields masked, then checked so that every external a function references lands on the same address everywhere. It writes `build/st25match.txt` (`exact`, `small`, `ambiguous`, `close` with a similarity, or `none`, plus the sequel address). `close` and `none` functions are the ones that changed: start from the ST25 source.

`tools/st25port.py` then applies the results:
- `units`: carve a unit per ST25 file
- `names`: rename matched functions, and the functions and variables they reference, to their ST25 names. It also trims the analysis's pieces of a variable once its size is known.
- `relocs`: add `config/relocs.txt` entries for operands that the matched code shows are addresses
- `src FILE...`: write `src/FILE.c` from the ST25 file, keeping only matching functions

## Workflow

1. Find the sequel function's ST25 counterpart: `build/st25match.txt`, or matching strings, constants and callees, then look in `ref/st25/src`.
2. If its file isn't a unit yet, carve it out: `tools/splitunit.py START END name`.
3. Name things: `tools/rename.py _sub_21DB6 _ListInit` (updates symbols.txt, relocs.txt and sources).
4. Write `src/<unit>.c` (copy what still matches from ST25, headers into `include/`), then `ninja progress`, or open `objdiff.json` in `tools/bin/objdiff`. Use `tools/fdiff.py UNIT SYMBOL` for a side-by-side view and `tools/disasm.py ADDR [END]` for the original.
5. After changing how the EXE is analysed, `tools/init_config.py` regenerates symbols.txt (keeping every name you've given) and adds newly found library modules to units.txt. `--force` rebuilds units.txt from scratch and loses your splits.

## Status

- The C runtime matches: 147/147 functions, 100% of its code. Its `.data` is at 50%: data relocations aren't yet taken from the library fixups.
- Game code: 150 of 1,085 functions (8.5%) match, all carried over unchanged from ST25 into 22 `src/segNNN.c` files. Of ST25's 602 C functions, 154 compile byte for byte to the sequel's code and 19 are close.
- String literals: the game's `_DATA` isn't divided into units yet, so a function that references a string literal can't match (LoadBan is the one case so far). The target object points the literal at a symbol in a `data/` unit, and the compiled object at its own `.data`.
- Not ported from ST25 yet: the full NMAKE/LINK rebuild (`ref/st25/tools/dosbuild.py`, `genbss.py`), and the room script (`.RDF`) tooling (`ref/st25/tools/rdf.py`). The sequel's RDFs are still x86 code, but with a shorter header.
