# Star Trek: Judgment Rites (CD, DOS) decompilation

A matching decompilation of `TREKJR.EXE`, the DOS executable of the Judgment Rites CD release (dated 7 Oct 1995). The goal is C source that the original compiler turns back into the original machine code. Progress is measured function by function with [objdiff](https://github.com/encounter/objdiff). The whole program can also be relinked with the original linker and compared with the shipped EXE.

## Status

| Category | Code | Functions | Data |
|---|---|---|---|
| Game code | 126,381 / 144,425 bytes (87.5%) | 825 / 854 | 31,940 / 31,940 (100%) |
| C runtime | 22,971 / 22,971 (100%) | 368 / 368 | 2,444 / 2,444 (100%) |
| Uninitialized (communals, stack) | | | reproduced by `src/BSS.ASM` |

The fuzzy match over all code is 99.68%. Every function is decompiled, and every function that doesn't match yet is within a few instructions of the original (see [Differences from the original](#differences-from-the-original)).

"Code" counts the bytes of functions that match exactly. The 86 bytes of "Game data" are runtime data between library modules (`data/d3F225`, `data/d3F290`, `data/d3F4D9`) that no module has been found for; the link places them correctly anyway.

## The original build

| | |
|---|---|
| Compiler | Microsoft C/C++ 7.00 (`tools/C700`), runtime "Copyright (c) 1992" |
| Memory model | Medium (`/AM`): far code, near data |
| Game code flags | `/AM /G2 /Ox /FPa /Zp1`, the same for every file |
| Assembler | MASM 5.0 (`mvelib`, `seg027`, `seg028`, `asm/t2D688`) |
| Runtime | `MLIBCA.LIB` (medium model, alternate math) and `OLDNAMES.LIB`. C 7.00's setup only builds `MLIBCA.LIB` when alternate math is chosen |
| Link | `/NOI /NOD /EXEPACK /PACKCODE /FARCALLTRANSLATION /STACK:0x12E8` |

The flags were confirmed by testing alternatives on files that already match:
- `/Ox` is right. Turning off any of its `/O` letters breaks functions that match today, or changes nothing.
- C 6.00 matches far fewer functions.
- The older C 7.00 (prior to any post-release patches) has identical compiler passes.
- `/FPa` makes floating point call the runtime's `__aF*` helpers, as the original does. Its code is the same as `/FPc`'s; what tells them apart is the library.

What the tooling has to deal with:

- **Packed code.** LINK `/PACKCODE` merged every file's code segment into three segments (0000h, 0BD6h and 1B98h, whose tail is the C runtime's `_TEXT`). Nothing in the EXE marks where one file ends. Units were carved out by hand, from the order of functions and the data each file uses.
- **Far call translation.** LINK turned far calls inside a packed segment into `nop; push cs; call near` (`90 0E E8`). `project.load_exe()` turns them back into `call far` with a segment fixup, so every tool sees an image that compares with compiled objects. A 4-byte `push cs; call near` without the `nop` is the compiler's own call to a function in the same file.
- **No IDA database.** `tools/analyze.py` disassembles the EXE by recursive descent from every far call, near call and far code pointer. It writes `build/analysis.txt` in the format of an IDA export, so an export from `tools/ida/export.idc` can replace it.
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
- `orig/CD/`: the CD's files. `orig/CD/TREKJR.EXE` must match `config/orig.sha1`.
- `tools/C700/`: Microsoft C/C++ 7.00 (`BIN`, `INCLUDE`, `LIB`), with the alternate math libraries installed (`LIB/MLIBCA.LIB`).
- `tools/MASM50/`: Microsoft Assembler 5.0, for the assembly units.

### Running the compiler

C 7.00's compiler passes are 32-bit DOS-extended programs (DOSX32 + `MS32KRNL.DLL`, a cut-down Win32 kernel) that need a DPMI host. Microsoft supported only a Windows 3.x DOS box or Qualitas 386-MAX. emu2 has no DPMI. In DOSBox, both HDPMI32 and CWSDPMI start it, but MS32KRNL then faults during its own start-up.

**dosemu2** works. `tools/cc.py` runs each compile in it (`dosemu -dumb -K <project> -E <batch>`) with the project root as the current drive, so paths must be 8.3 and inside the project. A compile takes about 0.7 s, and each one gets its own `TMP` directory so ninja can run them in parallel.

dosemu2's default shell, comcom64, needs the dj64 runtime, which Fedora's packages don't install. So `cc.py` sets `DOSEMU2_COMCOM_DIR=/usr/share/comcom32`; override it with that variable. `$DOSEMU` selects the dosemu binary.

## Layout

```
config/symbols.txt   every function/data symbol: address, kind, size, name
config/units.txt     units (translation units) and their address ranges
config/relocs.txt    explicit references the analysis can't tell from numbers
config/aliases.txt   library names sharing an address (generated)
src/<unit>.c         decompiled source, one file per unit (.asm for assembly)
src/BSS.ASM          communal layout for the relink (generated, tools/genbss.py)
include/             shared headers
TREKJR.MAK           NMAKE makefile for a full rebuild under DOS
build/analysis.txt   generated disassembly structure (tools/analyze.py)
build/target/        target objects split from the EXE (generated)
build/base/          objects compiled from src/ or taken from the C library
build/dos/           the relinked TREKJR.EXE (tools/dosbuild.py)
```

Addresses are linear, with the load module at paragraph 1000h: `seg001:6056` is `1BD60 + 6056 = 21DB6`.

### Units

- **`segNNN`, `space`, `demo`, `acmp`, `cfg`, `iff`**: the game's C files, one run of code each, in the original's link order. Unit names must be 8.3, because the compiler runs under DOS.
- **`mvelib`, `seg027`, `seg028`, `asm/t2D688`**: assembly modules (the movie player library, and hand-written routines such as `PlayDelta`).
- **`lib/<module>`**: C runtime modules (`tools/libmatch.py`), built straight from `MLIBCA.LIB` or `MLIBCE.LIB` (the two share the non-floating-point modules). Their target relocations come from the library's own fixups. When a library has two modules of one name (the near and far `chkstk.asm`), `lib=LIB:name@N` picks one. Data-only modules (`_file.c`, `ctype.asm`, `cmiscdat.asm`, `huge.asm`) are units of their own, placed by hand.
- **`far/segNNN`, `data/dXXXXX`, `data/stack`**: far data and DGROUP pieces that belong to no file: the communals, the stack, and the few runtime bytes above.

Each file's statics are declared `static` in their source, in the original's address order, so its `_BSS` matches per unit. C 7.00 also puts its buffers for functions that return structs there.

## Workflow

1. Name things: `tools/rename.py _sub_21DB6 _ListInit` updates symbols.txt, relocs.txt and the sources.
2. Edit `src/<unit>.c`, then run `ninja progress`, or open `objdiff.json` in `tools/bin/objdiff`.
3. Use `tools/fdiff.py UNIT SYMBOL` for a side-by-side view, and `tools/disasm.py ADDR [END]` for the original.
   `tools/relcheck.py [UNIT...]` lists functions whose instructions reference different symbols from the original's. objdiff can score these 100%: a call to the wrong one of two near-identical functions, statics laid out in the wrong order, stores to two fields in the opposite order.
4. `tools/splitunit.py START END name` carves a new unit out of an address range.
5. After changing how the EXE is analysed, `tools/init_config.py` regenerates symbols.txt (keeping every name you've given) and adds newly found library modules to units.txt. `--force` rebuilds units.txt from scratch and loses your splits.

Notes on getting C 7.00 to produce a given instruction sequence (loop forms, copy variables, register choice) are kept with the sources' comments and in commit messages.

## Full rebuild

`tools/dosbuild.py` links `build/dos/TREKJR.EXE` from the objects ninja builds (`build/obj/`). It runs C 7.00's LINK under dosemu2 with the original's options and libraries, in the units' code order. It then compares the result with `TREKJR.EXE`, both packed and unpacked. Run ninja first.

`TREKJR.MAK` does the whole build the old way, with NMAKE under DOS: compile, assemble, link. Its result is the same EXE. Before running it, `SET PATH=\TOOLS\C700\BIN` and `SET INCLUDE=\TOOLS\C700\INCLUDE`.

- **`_BSS`**: each file's statics come out in link order, as in the original.
- **`c_common`** and the far communals (`FAR_BSS`): LINK lays these out in an order of its own that depends on the lost variable names. `src/BSS.ASM` is generated by `tools/genbss.py` from `symbols.txt` and linked last. It defines each communal at its original address. It's a reproduction aid, not recovered source; regenerate it after renaming or resizing a symbol there.
- **Layout**: every segment comes out in the original's order and alignment (code, far data, DGROUP, BSS, stack), with the original stack size. The only cause of differences left is the code of the functions that don't match yet.

## Differences from the original

The relinked EXE is 64 bytes shorter than the original, both packed (184,826 vs 184,890) and unpacked (202,448 vs 202,512). The header's `SS` and `CS` are 4 paragraphs lower, and `minalloc` 1. All of this comes from 15 functions whose compiled size differs from the original's. Each one moves every address after it, so far more bytes differ than the functions themselves account for: far calls and data references all change. Only 15.5% of the packed file, or 24.0% unpacked, is equal byte for byte. Once those 15 sizes are right, the rest of the image should line up.

### Functions of the wrong size

| Unit | Function | Size difference (bytes) | What differs |
|---|---|---|---|
| seg008 | `InputBox` | −22 | a local stored as a word in the original stays in a register; key cases branch differently |
| seg008 | `ScriptService` | +12 | a pointer kept in `si` in the original is reloaded from the stack; branch layout in the switch |
| space | `Evaluate` | −8 | `pct` lives on the stack in the original, so its dead store `pct = 1` survives; register choice in the clamp |
| seg008 | `Converse` | −6 | the original points `DS` at a far record; ours uses `ES:` overrides and one more local |
| seg014 | `MenuLoop` | −4 | a 32-bit sum evaluated in a different order (as in `MenuWait`) |
| demo | `PlayDpAnim` | −4 | ours has a 2-byte larger frame, so every local's slot moves |
| cfg | `CfgOpen` | −4 | a dead store (`mov [bp-2],dx`) the original keeps |
| seg015 | `StreamInit` | +4 | a far pointer argument (`&s->field`) built differently |
| demo | `PlayMovie` | +4 | the original loads `heap0` with `les bx` instead of keeping it in `si` |
| seg003 | `FindFile` | −2 | a field store and an index multiply (×7 by shifts) in a different order |
| seg005 | `ReadPointer` | −2 | the original multiplies in `cx`, then reloads `mouse_x` from memory; ours multiplies in `si` |
| seg008 | `EnterRoom` | −2 | a comparison done in a register instead of on the stack |
| seg008 | `CrewSay` | −2 | a local in `di` vs on the stack, and slot order |
| seg015 | `PlayMusicSeq` | −2 | an extra `mov ax,cx` before the push |
| acmp | `AcmpOpen` | −1 | `di` vs `si`, and the original has one more local |

By file, the code segments differ by:

| Segment | Original | Rebuilt | Difference |
|---|---|---|---|
| SEG003 | 105Eh | 105Ch | −2 |
| SEG005 | 994h | 992h | −2 |
| SEG008 | 4FE0h | 4FCCh | −20 |
| SEG014 | 13A0h | 139Ch | −4 |
| SEG015 | 25CCh | 25CEh | +2 |
| DEMO | CD9h | CDAh | +1 (alignment) |
| SPACE | 1BA8h | 1BA0h | −8 |
| CFG | 386h | 382h | −4 |

ACMP's −1 disappears in word alignment.

### Right size, different code

These 14 functions don't change any address. They differ only inside themselves:

| Unit | Function | Match | What differs |
|---|---|---|---|
| seg009 | `PickItem` | 99.99% | one register (`si,dx` vs `si,di`) |
| seg014 | `MenuMove` | 99.98% | stack-slot order of locals |
| seg015 | `SoundInit` | 99.97% | register choice |
| seg012 | `Turbolift` | 99.97% | stack-slot order |
| seg008 | `CheckRegions` | 99.97% | one register |
| seg007 | `BuildRemap` | 99.95% | stack-slot order |
| seg001 | `Intercept` | 99.91% | stack-slot order |
| seg000 | `StartTalk` | 99.91% | stack-slot order |
| seg023 | `DrawStars` | 99.85% | a far pointer copied through a second local |
| seg008 | `PickObject` | 99.01% | call and argument order |
| acmp | `AcmpRead` | 98.87% | comparison operand order (`cmp ax,[x]; jbe` vs `cmp [x],ax; jae`) |
| seg014 | `MenuWait` | 97.12% | a 32-bit sum evaluated in a different order (`ticks` loaded first); operand order, casts, `volatile` and split assignments don't change it |
| space | `EncounterTick` | 95.11% | shared vs duplicated return epilogues |
| seg015 | `PlayDigi` | 92.41% | the original has a 2-byte frame (`enter 2,0`), ours has none |

### Hidden differences

`tools/relcheck.py` finds one function that objdiff scores 100% but whose code isn't the original's: `AcmpUnary` (acmp) loads `rbyte` and `rlast` in the opposite order for `(cur.rbyte ^ cur.rlast) & 1`. Neither operand order, casts nor field types change C 7.00's choice.

Two kinds of mistake it caught are worth checking for when a file is done:
- **Static layout.** C 7.00 lays out a file's statics in the order they were *first declared*, and an `extern` in a header counts. `include/menu.h` declared `menu_sel` before `menu_count`, which swapped the two in seg014's `_BSS`.
- **Library modules with the same code.** `ctran.asm` (pow, log, log10, exp) and `csqrt.asm` + `ctrig.asm` (sqrt, sin, cos, tan) differ only in fixed-up bytes. `tools/libmatch.py` now also checks a module's `_DATA` (here the function names) against the EXE.

### What's been tried

- **Other compilers and flags:** see [The original build](#the-original-build). Nothing beats C 7.00 `/Ox`, and no single flag fixes these functions.
- **Source constructs:** these do change register and slot choices, and fixed several functions. Examples: index loops vs pointer loops, a copy variable, `return -2` vs `return n`, merged conditions, block-local declarations, and `unsigned` vs `int`. Pulling an assignment out of an expression into its own statement (`x = e; f(x)` vs `f(x = e)`) fixed `CanWalk` and `BridgeKey`. A search that tried every such hoist, the reverse fold, swapping adjacent independent assignments and splitting chained ones in all the remaining functions found nothing more: the variants that fix a size do it by making the function less like the original.

Most of the remaining differences look like C 7.00's register allocator making a different choice for an expression the source doesn't pin down. The dead stores in `Evaluate` and `CfgOpen` are part of this: they survive in the original because the variable lives on the stack there, not in a register.
