# Decompilation notes

How the project was decompiled and how its tooling works: matching C functions, the assembly units, the patterns Microsoft QuickC produces, data, the room scripts, and the object conventions. See the [README](../README.md) for setup and building.

## Decompiling a function

1. Look at the code: `tools/disasm.py _sub_10018` (by name or address) prints the function with symbol names.
2. Write the C into `src/<unit>.c` (create the file if needed, then re-run `configure.py`).
3. `ninja`, then either open the unit in the objdiff GUI or run `tools/fdiff.py <unit> <symbol>` for a terminal side-by-side diff.
4. When the whole unit matches, add `complete` to its line in `config/units.txt`.

`src/seg004.c` is a worked example: three EMS wrapper functions that match 100%.

Flags can be overridden per unit in `UNIT_CFLAGS` in `configure.py`.

If an operand needs a reference that IDA didn't record, or IDA picked the wrong symbol (one past the end of an array is a common case), add a line to `config/relocs.txt`. The address is the instruction's; the entry relocates the operand that holds that value, and any other operand of the instruction is still relocated as usual (`none` suppresses all of them; `SYMBOL only` relocates that operand and nothing else, for `mov [tab+4], 2D0h` where the immediate also looks like an address). `tools/split.py` also relocates, without help, immediates and `[reg+disp]` operands that are the address of a variable you have named in `symbols.txt` (not a dummy name; C units only, and not `mov dx, imm` below 400h, which is usually an I/O port), and words in a unit's `.data` that point at the start of a symbol in its own `.rodata` (tables of strings). When an immediate only happens to equal a variable's address (`push 2CAh`, a number), add `ADDR none` to `relocs.txt`. The reverse also happens: IDA sometimes marked struct offsets such as `[bx+124h]` as data offsets, which shows up as a target relocation (to some `_word_45B74`) that the base doesn't have; add `none` for those. These heuristics ignore DGROUP offsets below `LOW_DGROUP` (240h, the end of seg001's `.data`): small numbers there are as often structure offsets (`[bx+1C8h]`) or constants (`enter 56h, 0`) as addresses, so variables in that range can have hand names, but their unmarked references need `relocs.txt` entries. Functions IDA left undefined only need a `func` entry in `symbols.txt` (`tools/split.py` disassembles them). For a pointer stored in initialized data (`Sprite **list = array;`), give the address of the data word itself.

### Assembly units

MASM 5.0 (`tools/MASM50`) assembles `src/<unit>.asm` (`/Ml`, case-sensitive names). For hand-written assembly modules, generate the source rather than typing it:

```sh
.venv/bin/python tools/asmgen.py seg028        # writes src/seg028.asm
```

`asmgen.py` builds the source from the unit's target object, so references come out as symbols (`OFFSET DGROUP:sym`, `SEG sym`, `call FAR PTR sym`, `cs:[bx+label]`). It then assembles the result and compares it with the EXE. An instruction MASM encodes differently first has its operands swapped (`test`/`xchg`, where the order picks the encoding); if that doesn't help, it's emitted as `DB` bytes. This repeats until the object matches. Labels that fall inside another instruction (self-modifying code) become `label EQU $-n`. Names come from `config/symbols.txt`, so rename there and regenerate. Re-running overwrites the file, so regenerate before hand-editing.

### Quick-compile (`/qc`) code patterns

`/qc` does almost no optimisation, so the code shape follows the source closely. Patterns found so far (`src/seg004.c` has examples of each):

| Source | Generated code |
|---|---|
| `if (c) return;` | `jcc_true short L; jmp body; L: jmp epilogue` |
| `if (c) { … }` (body runs on to the end) | `jcc_true short body; jmp past_if` |
| `if (!f()) return;` vs `if (f()) { … }` | the two shapes above. Pick whichever matches; nested `if` blocks are more common than `continue` |
| `for (b = arr; b != arr + N; b++)` | increment and test at the top of the loop |
| `for (b = arr; b != &arr[N]; b++)` | test at the bottom of the loop. Use whichever form matches; both occur |
| `i++` as a statement or in a `for` | loads the old value into `ax` first. Use `++i` when there's no load |
| `if ((n = f()) == 0)` | `mov [n], ax; cmp ax, 0` (testing `n` separately gives `cmp word ptr [n], 0`) |
| argument type differs from the parameter (`unsigned` → `int`, `long` → `unsigned long`) | loaded into registers before the `push`. A direct `push word ptr [..]` means the types agree |
| `return a == b;` | `mov ax, 1 / jmp / mov ax, 0` then `jmp epilogue` |
| a function containing `_asm` | the usual `push si / push di` and `enter` frame |
| locals | stack slots in declaration order from `[bp-2]` down, word aligned (a `char` still takes 2 bytes); unused locals still take space |
| `register` local | lives in `si`/`di` but **also** gets a stack slot. A `register` parameter (`f(register char *p)`) is loaded into `si` and has no slot |
| `register` local declared in an inner block | `si`/`di` is only saved around block moves (`push si / rep movsw / pop si`) while the variable is in scope. An extra `push si` around a struct copy after the block means the `register` variable was declared too far out |
| a unit whose last function is followed by a pad byte | end the unit's `.text` range before the pad (the next segment starts on a paragraph) |
| an `int` passed to a `char` parameter | with a prototype QC pushes the `int` unchanged. `mov ax, [x] / cbw / push ax` is an explicit `(char)x` cast in the call |
| a `switch` case whose `if` jumps to the end of the switch rather than to a `jmp` after it | the `break` is inside the `if` (`default: if (c) { ...; break; }`) |
| `max(a, b)` from `<stdlib.h>` | `mov ax, a / cmp ax, b / jg / mov ax, a / jmp / mov ax, b` |
| locals in nested `{ }` blocks | sibling blocks reuse the same stack slots |
| compiler temporaries | spill into the frame below the locals live at that point, so the frame can be larger than the declared locals. Sometimes an "extra" local is really a temporary for a subexpression: write the expression inline rather than adding a variable |
| type conversions | a mismatch (`int` ↔ `unsigned`, `long` ↔ `unsigned long`) shows up as an operand loaded into registers, or copied to a temporary, instead of being used straight from memory. Check which side is converted and fix the declared types |
| `for` loops | test at the bottom when the condition is a simple comparison (`i < n`, `x == 0`); test at the top when the condition does arithmetic, has side effects or uses `&&`/`\|\|` (`i < a + b`, `count--`, `i != n && *p`). `while` behaves the same way |
| returning a struct | copies it into the runtime's `__mbac` buffer and returns its address. The caller copies it out with `rep movsw` |
| a function ending in an expression statement with no `return` | the expression's value is left in `ax`, and the function "returns" it. QC loads values of assignments, so e.g. `*out = r;` leaves `out` in `ax`. Several `Matrix *` functions rely on this |
| explicit `return;` at the very end | `jmp` to the epilogue (the next instruction) |
| `switch` | `jmp` to a compare chain after the cases: `cmp ax, n / jne / jmp case_n`. Case values are sorted in the chain whatever the source order; the bodies stay in source order |
| `switch` with a jump table (`cmp ax, max / jbe / jmp cs:[bx+table]`) | QC only builds the table when the cases are dense. Table slots pointing at the default body are case labels in the source: list them (`case 3: case 4: case 5: default:`), or QC falls back to a compare chain |
| `void _interrupt _far f(void)` | `pusha / push ds / push es / mov bp, sp / sub sp, n / mov ax, DGROUP / mov ds, ax / cld`, ending in `iret`. Calling an interrupt function pointer is `pushf / call far` |
| `i++, j++` vs `++i, ++j` in a `for` increment | the postfix form loads the old value of the first operand (`mov ax, [i] / add [i], 1`); the prefix form doesn't |
| `long` arithmetic with one `unsigned long` and one `long` operand | the converted operand is loaded first (`a + b` loads `b` first if `b` is the one converted). Check the operand types before swapping operands |
| a chained assignment ending in an immediate store (`mov [a], 0`), then `mov ax, 0 / mov dx, 0` and register stores | the immediate store is the innermost target: `o->x = o->y = o->z = o->speed = 0;` stores `speed` first |
| `mov ax, [t] / ... / mov [tmp], ax` before a call, then the comparison against the call's result from `tmp` | the left operand is converted, e.g. `while ((unsigned long)t == GetTicks())` with a `long t` |
| `x++; if (x == 1)` vs `if (++x == 1)` | the first compares memory (`add [x], 1 / cmp [x], 1`), the second loads `x` |
| a `long` compared with a converted operand (`cnt > (unsigned long)p->len` where `len` is `long`) | the converted side is loaded into registers before the `cmp`. Plain operands are compared from memory |
| `far` arrays (`int far tab[N]`) | `mov es, ds:[w]`, where `w` is a segment word QC puts in `CONST` (relocated by the loader), then `es:[bx+offset]` |
| floating point | emulator calls (`INT 34h`–`3Dh`, shown decoded by `tools/disasm.py`). `double` constants go into `CONST` in order of first use, and constant expressions like `PI / 512` are folded at compile time. An `int` operand is converted at run time with `cwd` + `fild` from a temporary, even a constant: `f = 50;` (float `f`) is `mov ax, 32h / cwd / fild`, and `if (k > 10)` converts the `10` the same way. For `x * 512` the `int` is loaded first and the operands swapped with `fxch`; `512 * x` uses `fmul` from memory instead. A `cwd` before the `fild` of a call's result means the function returns `int` there (`(int)FixMul2(...)`) |
| `fwait` after every FP store at the end of a line, even when the next line starts with an FP instruction | the unit was compiled with debug information (`/Zd` or `/Zi`). Without it QC drops the `fwait` unless the next instruction is a CPU one or a jump target. seg006 is built with `/Zi` (`UNIT_CFLAGS`): only CodeView objects reference `__aDBused`, which is what pulled the runtime's `dbscrswp` module into the original EXE |
| a `struct` argument copied onto the stack (`sub sp, 8 / mov si, offset var / mov di, sp / movsw`...) | the struct is passed by value, e.g. `SpriteAddRect(&s, h, clip_rect)`. If the shared header declares the function differently, hide that declaration (`#define SpriteAddRect SpriteAddRect_` around the `#include`) and declare the form this file uses (see `src/seg017.c`) |
| `mov cx, [bp-n] / add ax, cx` where `[bp-n]` holds an earlier call's result | no variable: the right operand of `f() + g()` is evaluated first and spilled to a temporary (`strlen(label) + strlen(desc) + 1`) |
| a loop test `jcc L / jmp body / L: jmp exit` in the middle of a `for` | the test is in the body as `if (...) break;`, not part of the loop condition |
| `if (a) ... else if (b) { ...; return; } else if (c)` vs separate `if`s | after a `return` QC still emits the `jmp` over the `else`. If the original has no such `jmp`, the statements are separate `if`s (inside one `else` block) |
| a struct passed by value with `push word ptr` six times instead of `sub sp / rep movsw` | the callee takes the members, e.g. three `long`s (`sub_3A35E(d.x, d.y, d.z)`) |
| a function returning `double` | `return a / b;` stores into the runtime's `__fac` and returns its address in `ax`; the caller does `mov si, ax / fld qword ptr [si]` |
| `imul` then `idiv` with no `cwd` between (a 32-bit intermediate) | no C expression gives this, so it is inline assembly: `_asm { mov ax, a / imul b / idiv c / mov r, ax }` |
| temporaries between two block locals | temporaries go below the locals declared so far. FP conversion temporaries take 8-byte slots, `int` ones 2 bytes. If a temporary used while computing one local sits where the next local lives, that next local is declared in an inner block (`{ double w; w = ...; { double h; ... } }`) |
| `lea bx, [bp-n] / mov cx, ss / mov es, cx / ... es:[bx+2]` | `FP_SEG(p)` on a local far pointer, with the `<dos.h>` style macro `(*((unsigned _far *)&(p) + 1))` (`FP_OFF` without the `+ 1`) |
| `long` `x += y` vs `x = x + y` | `+=` adds into memory (`add [x], ax / adc [x+2], dx`); `x = x + y` loads `x`, adds and stores. The source uses both |
| `tolower`, `toupper`, `isdigit`… | `<ctype.h>` defines macros that expand inline. A `call _tolower` means the original declared the function itself and didn't include `<ctype.h>` |
| `if (a && !(b && c) && …)` | a negated group jumps straight to the false branch on `c`: `cmp c, 0 / je next_term / jmp false`. A chain of `if (b && c) continue;` looks different |
| a block of `jmp` with an empty "then" | `if (x) ; else { … }`. It really occurs (`LoadSpriteBitmap`) |
| `a + b`, `a \| b`, `a * b` with both sides non-trivial | usually the **right** operand is evaluated first (spilled to a temporary if needed), then the left (`dy * w + dx` evaluates `dx` first), but not always: two array lookups of the same shape go left first. If the diff shows the halves swapped, swap them in the source |
| `add [p], n` followed by a dead `mov ax, [p]` | a comma expression as a statement, whose value QC loads anyway: `#define READ(d, n) (MemCpy(d, p, n), p += (n))` (`LoadWalkGraph` in `src/seg000.c`) |
| a `for` tested at the top although the condition looks simple (`i != count`) | a cast in the condition is enough to move the test: `i != (int)walk.count` |
| `mov bx, offset sym+N / add bx, ax / push [bx]` instead of `push [bx+sym]` | the array is a member at offset `N` of a global struct (`walk.nodes[i].x`). Merge the symbols into one struct; IDA usually leaves these offsets unmarked, so add `sym+N` entries to `config/relocs.txt` |
| an `int` argument pushed straight from memory to a library function taking `size_t` (`qsort`) | the function had no prototype: the original didn't include `<stdlib.h>`. Declare it K&R style (`void qsort();`) |
| a `switch` whose last case has no `jmp` to the end | that case has no `break;` |
| `p[f()]` with `p` an expression | the pointer is computed first and spilled to a temporary across the call. A far pointer temporary in the frame may be this rather than a local |
| a function that passes its own arguments on as fixed words (`push [bp+6] … push [bp+0Eh]` into `printf`) while callers pass varying types | a K&R definition, `void Fatal(fmt, a, b, c, d) char *fmt; int a, b, c, d; {…}`, declared `void Fatal();` so calls aren't checked (`Fatal`, `FarPrintf` in `src/seg012.c`) |
| `mov ax, [n] / mov cx, 34h / imul cx` vs `imul ax, [n], 34h` | `n * sizeof(Sprite)` (an `unsigned` multiply) vs `n * 52`. Array indexing always uses the three-operand form |
| `shr ax, 8` vs `sar ax, 8` on an `int` field | `(unsigned)ev.key >> 8`: the original cast before shifting |
| `jmp` into the middle of another `case` | `goto` to a label inside it, even inside a nested `switch` or an `if` body. The `goto` replaces the `break`, so no second `jmp` follows it |
| `call f / mov cx, [t] / mov bx, [t+2] / cmp ax, cx` (a `long` compared from registers after the call) | the variable is the converted side: `GetTicks() == (unsigned long)t` with `long t` |
| a `.rodata` slice whose last byte is a lone `00` after the final string's terminator | alignment padding: end the unit's `.rodata` range before it |
| a table's strings in `CONST` between the strings of other functions | string literals go into `CONST` as they are parsed, so a table of string pointers is defined at that point in the source, between those functions. `.data` is laid out in definition order too, so the variables around it follow the same order (`ship_names` after `StartCrew` in `src/seg001.c`) |
| a table's strings between the literals of a single function | a `static` table declared inside it, at the start of the block that uses it (`case 7: { static struct {...} repair_names[] = {...}; ...}` in `BridgeMsg`) |
| `call / mov ax, [x] / cmp ax, 0` after `xor word ptr [x], 1` | the assignment operator in the condition: `if (target_analysis ^= 1)` |
| a `case` whose `if` jumps to the next case's code and whose `else` is `jmp end` | `if (c) f(); else break;` with the case falling through into the next one |
| two temporaries in the frame where one statement each would reuse one | the two statements are one comma expression: `mouse_x = max(...), mouse_y = max(...);` |
| a `long` loaded into `ax` and `dx`, then `and ax, 0FFh` with no `and dx` | the `long` was cast to `int` first: `(int)ticks & 0xFF` |
| a 6-byte `rep movsw` of a matrix row | a row assigned through a cast: `*(Vec *)m.e[0] = a;` |
| `a = 0, b = 7;` (comma expression) | both stores, then the value of the last one loaded into `al`/`ax`. Two separate statements don't load it |
| `x = y` storing a parameter into a struct field | `mov bx, s` then `mov ax, y` normally; when `y` is converted (an `unsigned` parameter into an `int` field) the value is loaded first |
| `_asm` | self-modifying code works: `mov word ptr cs:l_patch+3, ax` patches the displacement of the instruction at `l_patch`. Plain `jmp` is always near (`E9`). Conditional jumps aren't lengthened: an out-of-range `jne l` must be written `je skip / jmp l` (the original shows the pair). A local subroutine reached with `call l` needs a near return, written `_emit 0C3h`. Use `mov bx, offset var` for an address as an immediate. `xlat ss:[bx]` loses its segment prefix: write `_emit 36h` and `xlat [bx]`. Locals reached through `ds:` after changing `ss` are written `push ds:w`. `jmp short l` gives an `EB` jump. C struct members work as operands (`cmp ax, clip_rect.x1`), as do the halves of a far pointer local (`mov ds, word ptr p+2`). A local named like a register (`dx`) can't be used in `_asm`; rename it |
| `long` multiply | `__aFulmul` with both operands pushed, right one first. `__aFlmul` is the same routine (see `config/aliases.txt`) |
| a temporary that overlaps locals used before and after it | those locals belong to blocks that don't enclose the expression. Move them into the `if`/loop blocks that use them, or wrap the tail in a bare `{ MemHandle h; ... }` block (`LoadRoom`, `TextBox` in `src/seg008.c`). Each block's locals start right below the enclosing scope's |
| `mov ax, N / mov bx, [p] / mov cx, [p+2] / add bx, ax / mov [tmp], bx` for a member array of a far struct | `n = rdf->exit_room[i]`: QC spills the array's address to a far temporary. Assigning the address to a variable (`e = rdf->exit_room`) uses `cx:dx` instead |
| a chain of `jne +3 / jmp L` all going to the same `else` code | one `&&` condition with that code as its `else` (negated groups as `!(a && (b \|\| c))`). `if (c) goto L;` gives `je T / jmp F / T: jmp L` instead |
| `inc [i] / test [p] / jne +3 / jmp exit / jmp top` | an empty `while` body with a comma condition: `while (i++, *p++) ;` |
| `switch` on `ax` straight after `mov [k], ax` | the assignment is in the `switch`: `switch (k = (ev.key >> 8) & 0xFF)` |
| a function that only copies its argument (`mov [m], ax / mov [m+2], dx`) and then `jmp` to its epilogue | an empty `switch (m) { }`, left over from debug code compiled out (`TraceMsg`) |
| `jmp epilogue` then a second `jmp` to the end of the `switch` inside a case | `return;` followed by a `break;` that can't be reached (`TugDisabled` in `src/seg030.c`) |
| a `switch` whose case bodies are single `jmp`s to code after the compare chain | each case is a `goto` to a label after the `switch` (`case 0: goto a;`), and the code falling out of the `switch` is the default (`ElasiTalk` in `src/seg030.c`) |
| a call that pushes one argument more than the function takes (`add sp, 0Eh` for six words) | a bug in the original, e.g. a stray string in `MsgBox`'s `x` slot. Declare the function without a prototype (`void MsgBox();`) in that file so the call compiles (`TrialKallarax` in `src/seg034.c`) |
| a loop whose last test is `jne +3 / jmp exit / jmp top` | not `do … while`, which ends `je exit / jmp top`: a label with `if (...) goto` (`play: if ((r = f()) == 0 && MusicPlaying()) goto play;` in `Credits`, `src/seg036.c`) |
| a `switch` whose compare chain is a single `jmp` | the `switch` has only a `default:` (`DemonHail` in `src/seg029.c`) |
| an empty string literal pushed as a bare number | IDA didn't mark it as an offset. Add `aEmpty_N` symbols for each `""` in `symbols.txt`, shrink the string before it, and add `config/relocs.txt` entries for the pushes |

String literals go into `CONST` (`.rodata`), in source order, except that a call's arguments are evaluated right to left: `f("a", "b")` stores `"b"` first. A unit's strings form a contiguous range of the game's `CONST` area, so assign that range to the unit as `.rodata` in `units.txt`. Each module's `CONST` starts on an even address. If a module's strings have an odd total length, the `00` byte after them is LINK padding, not part of the module, so end the range before it.

The `seg004` code calls functions without prototypes in places, e.g. `MemSet(near_ptr, …)` where other files pass a far pointer. Leave such calls unprototyped in that file to keep the original argument sizes.

MSC 6 accepts anonymous structs and unions inside a struct. `Obj3D` (`include/obj3d.h`) uses them for the planet and shot fields that share offsets.

### Data

A compiled object references its own string literals and statics as `_DATA+offset`. These only match once the target unit owns the same slice of DGROUP. To give a unit its data, add `.data` / `.rodata` / `.bss` ranges to the unit in `config/units.txt`, and shrink the `data/dXXXXX` unit that held them. Ranges must not overlap. Until then, either switch objdiff's *Function relocation diffs* option to *None* or accept those mismatches.

`_far` initialized data (`char _far msg[] = "...";`) doesn't go into DGROUP. MSC puts it in a segment of its own, `<FILE>_DATA` (class `FAR_DATA`), which the build names `.data.<FILE>_DATA`. To match it, give the unit a section with that exact name over the `far/segNNN` unit's range and delete the `far/` unit. seg012's memory messages are an example: `seg012 .data.SEG012_DATA 44510 44720` replaced `far/seg038`. Each variable in the segment starts on an even address, as in DGROUP. The same works for library modules: the 8087 emulator's `EMULATOR_DATA` is `lib/emulator .data.EMULATOR_DATA`. Paragraph padding after a segment (the next one starts on a 16-byte boundary) stays outside the range.

Uninitialized far arrays (`int far sin_table[0x101];`) are different: MSC emits them as communal definitions (`COMDEF`) with no data, and LINK lays them all out in one `FAR_BSS` segment, in an order no object controls. That segment (`far/seg041`: `sin_table`, `file_buf`, `tan_table`, `ems_files`, `cos_table`) is marked `.bss` in `units.txt`, and each array only needs a definition in the source that owns it (seg010, seg003, seg016).

The near `.bss` (`data/d49E78`) works the same way. Every uninitialized global needs a definition (`int game_mode;`, `Obj3D ships[4];`) in the file that owns it, usually the one that uses it most. A plain `extern` everywhere still matches unit by unit, but leaves the program unlinkable. `tools/linkcheck.py` lists anything left undefined.

## Room scripts (.RDF)

Each away-mission room has a `.RDF` file in `DATA.001` (53 rooms: `DEMON0`–`VENG8`). Besides the room's header (`Rdf` in `include/room.h`: depth scaling, exits, entry positions), polygons and strings, it holds the room's scripts, which are 16-bit x86 code. `LoadRoom` loads the file whole and `CallScript` calls into it with `SI` = `&room` (the `RoomState`), and the scripts call back through the far pointer at offset 0 (`ScriptService` in `src/seg008.c`). The scripts were written in assembly, not C: strings sit inline with `jmp` over them, arguments are pushed in two different styles, the helpers take arguments in registers, and some bodies run into the next script's header.

The [README](../README.md#room-scripts-rdf) lists the quirks of the original scripts.

### The file

Everything in a room file is addressed from its start: the code, its strings and its variables.

| Offset | Contents |
|---|---|
| `00` | `rdf_service`: far pointer to `ScriptService`, filled in by `LoadRoom` |
| `04` | `rdf_state`: near pointer to `room` (the `RoomState`), filled in by `LoadRoom` |
| `06` | depth scaling: `y_max`, `y_min`, `scale_min`, `scale_max` |
| `0E` | start and end of the scripts, objects, exits, regions and `.ban` names |
| `22` | the room each of the four exits leads to |
| `2A` | where each crew member walks from and to, for each of the four entrances |
| `AA`, `BA` | where the crew stand when beamed in, and standing |
| `CA` | the room's data and code, in no fixed order. Some rooms start their data inside the header |

A script is a key of four bytes, the offset of the next script, then its code, which ends with `retf`. The engine searches the chain from `scripts` while it stays below `scripts_end`. For each room message it runs the scripts whose key matches (`RunScripts`); `RunWildScripts` lets an `FFh` in a key match anything. A script that sets `RS_MORE` lets the search go on to the next match, and in the end to the engine's default action. The first byte of the key is the message type:

| Type | Message | Key bytes 2–4 |
|---|---|---|
| 0 | `MSG_TICK` | room tick count, low and high byte |
| 1 | `MSG_WALK` | object clicked with the walk cursor |
| 2 | `MSG_USE` | object used, object it is used on |
| 3, 4, 5 | `MSG_GET`, `MSG_LOOK`, `MSG_TALK` | object |
| 6 | `MSG_EXIT` | exit polygon Kirk walked into |
| 7 | `MSG_REGION` | region polygon Kirk walked into |
| 8 | `MSG_TIMER` | room timer 0–7 (`RS_TIMERS`) that ran out |
| 10, 12 | `MSG_ANIM_DONE`, `MSG_WALK_DONE` | the number given when the animation or walk was started |

Objects are 0–3 for the crew (Kirk, Spock, McCoy, the security officer), 8–1Fh for the room's other actors, 20h–3Fh for its polygons and 40h–88h for items (`IT_` in `include/rdf.inc`, from `items[]` in `src/seg008.c`).

Scripts call `ScriptService(cmd, ...)` with the C calling convention. The result comes back in `DX:AX`.

| Cmd | | Arguments |
|---|---|---|
| 0, 2 | `RC_ANIM0`, `RC_ANIM2` | actor, `.anm` name, x, y, message when done. Actors 0–7 are scaled for depth; x or y -1 means "where the actor is" |
| 1 | `RC_STOPANIM` | actor |
| 3 | `RC_TALK` | conversation: speaker, choices, 0. Returns the choice |
| 4, 7, 11 | `RC_GIVEITEM`, `RC_TAKEITEM`, `RC_HAVEITEM` | item |
| 5 | `RC_LEVERS` | the lever puzzle |
| 6 | `RC_GOTOROOM` | room, entrance. Doesn't return |
| 8 | `RC_WALK` | crew member, x, y, message when there |
| 9, 10, 21 | `RC_LOADMAP`, `RC_FLASHBMP`, `RC_SFX` | name |
| 12 | `RC_ITEMCASE` | mask |
| 13 | `RC_ACTORPOS` | actor. Returns x, and y in `DX` |
| 14 | `RC_RANDOM` | lowest, highest |
| 15, 16 | `RC_BRIDGESFX`, `RC_MUSIC` | sound number; music |
| 17 | `RC_BEAMUP` | score, maximum score, outcome: ends the mission. The outcome picks the bridge's ending (0 the usual one) |
| 18 | `RC_GAMEOVER` | (then runs on into 19) |
| 19 | `RC_INPUTCODE` | the accepted codes, separated by NULs. Returns the number of the one typed, or 0 |
| 20 | `RC_TURBOLIFT` | unused, deck |
| 23 | `RC_DIGIOFF` | shuts digital sound down |

Nearly every room has the same two helpers, which the scripts `call` with arguments in registers. `Talk` runs the conversation at `AX`. `Say` writes one line into `talk_buf` (`AX` the speaker, 0 for none; `BX` the line) and runs that. Spoken lines start with their speech file, `#DEM0\DEM0_016#`, and the sources name each line after it (`T_DEM0_016`).

`room.vars` (`vNN` in the sources) is the scripts' memory. It is cleared when an away mission starts (`StartAway`), shared by the mission's rooms, and saved with the game. Variables inside the room file (`D_XXXX`) start again each time the room loads, and a saved game keeps them as a list of the bytes that differ from the original file.

### The source

`src/rdf/<room>.asm` is each room as MASM 5.0 source, one segment assembled at offset 0. `include/rdf.inc` names the service commands (`RC_`), message types (`MSG_`), objects and items (`OBJ_`, `IT_`), the `RoomState` fields (`RS_`), and has the macros: `SCRIPT type, a, b, c, next` (a script's key and link), `SERVICE` (the call through offset 0), `JMPN` (a 16-bit `jmp`, which MASM 5.0 would otherwise shorten) and `AX8` (`op ax, imm8` in the `83h` form, which MASM 5.0 doesn't choose).

```sh
ninja rdf                           # assemble every room and compare it with the original
ninja rdf-progress                  # script bodies named, per room
.venv/bin/python tools/rdf.py check DEMON0
.venv/bin/python tools/resource.py extract build/res -e rdf   # the original files
```

`ninja` checks the rooms too, so it needs `orig/CD/TREKCD/DATA.DIR`, `DATA.RUN` and `DATA.001` (from the CD). The rooms aren't put back into `DATA.001`. Instead, `tools/rdf.py patch ROOM` assembles a room into `build/rdf/patches/<room>.rdf` in the game's patch format (the unpacked size, then LZSS). Copied to a `patches` directory next to the game, it replaces the room in `DATA.001` (`ScanPatches` and `LoadPatchPacked` in `src/seg003.c`). A game saved before a room changed warns "Code for current room patched after game saved" when loaded in that room.

### Decompiling a room

`tools/rdf.py gen ROOM` wrote the sources. It follows the code from every script (and through the run-time jump tables of the TRIAL rooms' conversations), recognises the `Talk`/`Say` helpers and the loops some rooms use to make several service calls from arguments pushed in advance, and tracks values through registers, pushes and variables so that each pointer into the file becomes a label (`OFFSET T_DEM0_016`, `DW OFFSET N_Capt_Kirk, ...`). The source therefore still assembles correctly after an edit moves things. It notes the quirks it finds at the top of the file. `gen` won't overwrite a source without `--force`, so don't regenerate a room that has been worked on.

The rest is by hand:

1. Rename each script's entry label (`E_XXXX`) after what it does, and the room's variables: `vNN` (`RoomState.vars`, shared by the rooms of a mission and cleared when it starts) and `D_XXXX` (variables in the room file, which start again each time the room loads). Rename conversations (`C_XXXX`) and branch labels where it helps.
2. Comment the room (what its actors and objects are) and each script.
3. Run `ninja rdf` after each change; the room must still match.
4. When everything in the room is named, add `complete` to its line in `config/rdf.txt`.

Every room has been done this way. The DEMON rooms (`src/rdf/demon0.asm` to `demon6.asm`) make good examples. `ninja rdf-progress` counts the script bodies whose entry label has been renamed (a script that only jumps to another one's body has no label of its own). Unreachable code isn't found by following the scripts; give its address as `code=ADDR` in `config/rdf.txt` so that `gen` disassembles it (TRIAL2 and SINS1 have some).

## How it works

| Tool | Purpose |
|---|---|
| `tools/ida/export.idc` | IDC script for IDA 5 that dumps segments, functions, items, names, xrefs and operand info |
| `tools/init_config.py` | builds `symbols.txt` / `units.txt` from the export and the library matches |
| `tools/libmatch.py` | finds C library modules in the EXE (code with fixups masked) and recovers names |
| `tools/split.py` | cuts each unit out of the EXE into an ELF target object, rebuilding relocations |
| `tools/cc.py` | runs `CL.EXE` under emu2 (project root = `D:`, `tools/C600` = `C:`) and converts the result |
| `tools/omf.py`, `tools/omf2elf.py` | OMF object/library reader and OMF → ELF converter |
| `tools/elf16.py` | ELF writer shared by both sides |
| `tools/fdiff.py`, `tools/disasm.py`, `tools/progress.py` | command-line diff, disassembly, progress summary |
| `tools/rename.py` | renames symbols in `symbols.txt`, `relocs.txt` and every source and header (`tools/rename.py _sub_3AEFF _AIL_startup …`) |
| `tools/linkcheck.py` | lists externals that no object or C library defines, as LINK would report them; exits non-zero if any (run `ninja` first) |
| `tools/resource.py` | reads `DATA.DIR`/`DATA.RUN`/`DATA.001` (or the Amiga's `data000.*`): lists and unpacks the game's files |
| `tools/amiga_music.py` | converts the Amiga version's music to ProTracker `.mod` (and `.wav`); not used by the build |
| `tools/rdf.py` | room scripts: generates, checks, patches and counts `src/rdf/<room>.asm` |
| `tools/strrel.py` | gives each string in a unit's `.rodata` a symbol and adds `relocs.txt` entries for `push` operands IDA left as numbers (`tools/strrel.py seg030 [--dry-run]`) |

### Object conventions

objdiff doesn't read OMF or 16-bit code, so both sides are converted to ELF32 (`EM_386`) with `e_flags = 0x8086`. The patched objdiff ([tools/objdiff/x86-16bit.patch](../tools/objdiff/x86-16bit.patch), against v3.8.2) decodes those objects as 16-bit code. Relocations:

| Type | Meaning |
|---|---|
| `R_386_16` (20) | 16-bit offset of a symbol (DGROUP data, or code in another unit) |
| `R_386_PC16` (21) | near call/jump into another unit |
| `R_386_SEG16` (45) | segment (paragraph) of a symbol; `DGROUP` for the data group |
| `R_386_FAR16` (250) | `seg:off` far pointer or far call, shown as one operand |

Near jumps and calls inside a unit's own code get no relocation on either side. Absolute offsets into it (`offset label`, `switch` jump tables) do, because in the EXE they're relative to the segment's frame, which can start before the module.

On the compiled side, the 8087 emulator fixups (`FIDRQQ` and friends) and other absolute library symbols are applied in place, just as LINK does. QuickC-style `BAKPAT` records are applied as well. On the target side, the operands of emulated x87 instructions (`INT 34h`–`3Ch`) are decoded so that their memory references can be relocated.

## Known limitations

- **`static` functions** aren't in an OMF object's public symbols, so a compiled static function merges into the public function before it. While matching, leave helpers non-static (MSC generates the same code either way).
- **Unmarked offsets:** a target relocation exists only where IDA knows an operand is an address. If a diff shows a number on the target side and a symbol on the base side, mark the operand as an offset in IDA (`O`) and re-export. `[bx+disp16]` accesses that hit a DGROUP symbol exactly are picked up automatically.
- **One relocation per instruction:** objdiff shows only one, so in `mov word ptr [x], offset y` only `x` is compared.
- **One name per address:** `symbols.txt` holds a single name per address, so aliased library publics (`__chkstk` / `__aFchkstk`) can mismatch.
- **Segment-only fixups** (`mov ax, seg func`) on the target side are named after a nearby offset reference, if there is one.
- **The runtime isn't quite 100%:** a few library functions stay just short (e.g. the emulator, which mixes code and data). Those units are still marked complete.
