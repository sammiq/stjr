#!/usr/bin/env python3
"""Room scripts: the .RDF files as MASM 5.0 source.

    tools/rdf.py gen ROOM... | --all [--force]   write src/rdf/<room>.asm from the original
    tools/rdf.py check ROOM... | --all            assemble and compare with the original
    tools/rdf.py progress                         scripts named, per room
    tools/rdf.py patch ROOM [-o DIR]              assemble into DIR/<room>.rdf, a patch file

Each away-mission room's .RDF (in DATA.001) is a header, the room's
scripts and their data, all in one segment; the scripts are hand-written
16-bit code (see include/rdf.inc). `gen` disassembles a room into source
that assembles back to the original bytes: it follows the code from every
script, finds the helper subroutines, works out which immediates are
pointers into the file (ScriptService arguments, conversation tables,
strings), and emits those as labels so that the source can be edited and
reassembled. It then assembles the result and replaces any instruction
MASM encodes differently with DB bytes, until the file matches.

`gen` writes a starting point; the source is then cleaned up by hand
(scripts and variables named, comments). Don't regenerate a room that has
been edited: `gen` refuses to overwrite without --force.

Progress: a script counts as named once its entry label is no longer the
generated E_XXXX. Rooms listed with `complete` in config/rdf.txt are done.
"""

from __future__ import annotations

import argparse
import os
import re
import struct
import subprocess
import sys
from pathlib import Path

import iced_x86 as ix

sys.path.insert(0, str(Path(__file__).parent))
import omf  # noqa: E402
from resource import Archive  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src/rdf"
BUILD = ROOT / "build/rdf"
CONFIG = ROOT / "config/rdf.txt"
MASM = ROOT / "tools/MASM50"
EMU2 = os.environ.get("EMU2", "emu2")
MAX_ROUNDS = 100

HDR_END = 0xCA          # sizeof(Rdf)
ROOM_SIZE = 0x129       # sizeof(RoomState)

# ScriptService commands: name, and which arguments (1-based) are pointers
# into the file
SERVICE = {
    0: ("Anim0", (2,)), 1: ("StopAnim", ()), 2: ("Anim", (2,)), 3: ("Talk", (1,)),
    4: ("GiveItem", ()), 5: ("Levers", ()), 6: ("GotoRoom", ()), 7: ("TakeItem", ()),
    8: ("Walk", ()), 9: ("LoadMap", (1,)), 10: ("FlashBitmap", (1,)), 11: ("HaveItem", ()),
    12: ("ItemCase", ()), 13: ("ActorPos", ()), 14: ("Random", ()), 15: ("BridgeSfx", ()),
    16: ("Music", ()), 17: ("BeamUp", ()), 18: ("GameOver", ()), 19: ("InputCode", (1,)),
    20: ("Turbolift", ()), 21: ("Sfx", (1,)), 22: ("Bad", ()), 23: ("DigiOff", ()),
}
RC_NAMES = ["RC_ANIM0", "RC_STOPANIM", "RC_ANIM2", "RC_TALK", "RC_GIVEITEM", "RC_LEVERS",
            "RC_GOTOROOM", "RC_TAKEITEM", "RC_WALK", "RC_LOADMAP", "RC_FLASHBMP", "RC_HAVEITEM",
            "RC_ITEMCASE", "RC_ACTORPOS", "RC_RANDOM", "RC_BRIDGESFX", "RC_MUSIC", "RC_BEAMUP",
            "RC_GAMEOVER", "RC_INPUTCODE", "RC_TURBOLIFT", "RC_SFX", "RC_BAD", "RC_DIGIOFF"]
ITEM_ARG = {4, 7, 11}
AX8_OPS = {ix.Mnemonic.ADD, ix.Mnemonic.OR, ix.Mnemonic.AND, ix.Mnemonic.SUB, ix.Mnemonic.XOR,
           ix.Mnemonic.CMP}   # commands whose first argument is an item
MSG_NAMES = {0: "MSG_TICK", 1: "MSG_WALK", 2: "MSG_USE", 3: "MSG_GET", 4: "MSG_LOOK",
             5: "MSG_TALK", 6: "MSG_EXIT", 7: "MSG_REGION", 8: "MSG_TIMER",
             10: "MSG_ANIM_DONE", 12: "MSG_WALK_DONE", 0xFF: "ANY"}
OBJ_NAMES = {0: "OBJ_KIRK", 1: "OBJ_SPOCK", 2: "OBJ_MCCOY", 3: "OBJ_REDSHIRT",
             0x1F: "OBJ_INVENTORY", 0xFF: "ANY"}
# message types whose first argument is an object (and second, for MSG_USE)
OBJ_MSGS = {1: 1, 2: 2, 3: 1, 4: 1, 5: 1}

ROOM_FIELDS = [(0x00, "RS_TIMERS"), (0x10, "RS_SAVED_X"), (0x12, "RS_SAVED_Y"),
               (0x14, "RS_STUN"), (0x1C, "RS_NO_WALK"), (0x1D, "RS_BUSY"),
               (0x1E, "RS_REDSHIRT_DEAD"), (0x1F, "RS_ACTION"), (0x20, "RS_TARGET"),
               (0x21, "RS_TARGET2"), (0x22, "RS_UNK22"), (0x23, "RS_MORE"),
               (0x24, "RS_FLAGS"), (0x25, "RS_FALL"), (0x29, "RS_VARS")]

# The header (include/room.h): offset, label, words, comment
HEADER = [
    (0x00, "rdf_service", 2, "ScriptService, set by LoadRoom"),
    (0x04, "rdf_state", 1, "&room, set by LoadRoom"),
    (0x06, "rdf_y_max", 1, "depth scaling: y range"),
    (0x08, "rdf_y_min", 1, None),
    (0x0A, "rdf_scale_min", 1, "and scale range"),
    (0x0C, "rdf_scale_max", 1, None),
    (0x0E, "rdf_sections", 10, "scripts, objects, exits, regions, bans: start, end"),
    (0x22, "rdf_exit_room", 4, "room for each exit"),
    (0x2A, "rdf_walk_in", 64, "per entrance, for each crew member: from, to"),
    (0xAA, "rdf_beam_pos", 8, "beaming in"),
    (0xBA, "rdf_stand_pos", 8, None),
]
SECTIONS = ["rdf_scripts", "rdf_scripts_end", "rdf_objects", "rdf_objects_end",
            "rdf_exits", "rdf_exits_end", "rdf_regions", "rdf_regions_end",
            "rdf_bans", "rdf_bans_end"]

ROOM = "room"          # a register value: &room
TRACKED = (ix.Register.AX, ix.Register.BX, ix.Register.SI, ix.Register.DI)

FLOW_END = (ix.FlowControl.RETURN, ix.FlowControl.UNCONDITIONAL_BRANCH,
            ix.FlowControl.INDIRECT_BRANCH, ix.FlowControl.EXCEPTION)


def w16(d: bytes, a: int) -> int:
    return struct.unpack_from("<H", d, a)[0]


def single(vals: frozenset) -> int | None:
    """The one constant value in a register/push state, if that's what it is."""
    if len(vals) == 1:
        v = next(iter(vals))
        if v is not ROOM and v[0] != "var":
            return v[1]
    return None


def consts(vals: frozenset):
    """The (source, value) constants in a value set."""
    return [v for v in vals if v is not ROOM and v[0] != "var"]


def hexnum(v: int) -> str:
    """MASM hex: 0FCh, 9, 99h."""
    if v < 10:
        return str(v)
    s = f"{v:X}h"
    return "0" + s if s[0] in "ABCDEF" else s


def printable(b: int) -> bool:
    return 0x20 <= b < 0x7F


def room_names() -> list[str]:
    names = []
    for line in CONFIG.read_text().splitlines():
        line = line.split("#", 1)[0].split()
        if line:
            names.append(line[0])
    return names


def room_flags() -> dict[str, set[str]]:
    out = {}
    for line in CONFIG.read_text().splitlines():
        line = line.split("#", 1)[0].split()
        if line:
            out[line[0]] = set(line[1:])
    return out


def load_room(name: str, arc: Archive | None = None) -> bytes:
    arc = arc or Archive()
    return arc.read(f"{name.upper()}.RDF")


# ====================================================================== analysis

class Room:
    def __init__(self, name: str, data: bytes, dead: list[int] | None = None):
        self.name = name.upper()
        self.dead = dead or []                            # unreachable code, from config/rdf.txt
        self.d = data
        self.n = len(data)
        self.sections = [w16(data, 0x0E + 2 * i) for i in range(10)]
        self.hdr_end = min([HDR_END, *(s for s in self.sections if s)])
        self.code: dict[int, ix.Instruction] = {}
        self.headers: list[tuple[int, bytes, int]] = []   # (addr, key, next)
        self.hdr_bytes: set[int] = set()
        self.entries: set[int] = set()
        self.calls: set[int] = set()
        self.targets: set[int] = set()                    # branch targets
        self.notes: dict[int, list[str]] = {}             # addr -> comments after it
        self.notes_before: dict[int, list[str]] = {}      # addr -> comments before it
        self.quirks: list[str] = []
        self.helpers: dict[int, str] = {}                 # addr -> kind
        self.say_buf: int | None = None
        self.ptr_imm: dict[int, int] = {}                 # instruction -> target
        self.ptr_data: dict[int, int] = {}                # data word -> target
        self.svc: dict[int, list] = {}                    # SERVICE call -> args
        self.convs: dict[int, int] = {}                   # conversation table -> words
        self.strings: set[int] = set()                    # pointer targets used as strings
        self.data_ptrs: set[int] = set()                  # other pointer targets
        self.ptr_vars: dict = {}                          # variables holding pointers
        self.dropped: dict[int, list] = {}                # add sp dropping a call's pushes
        self.jump_table: dict[int, int] = {}              # table -> the jmp using it
        self.code_ptrs: dict[int, int] = {}               # mov storing a code address
        self.loop_calls: dict[int, list] = {}             # SERVICE in a loop -> each call's args
        self.mem_refs: set[int] = set()                   # cs: displacements
        self.room_disp: set[int] = set()                  # [si+d] room fields
        self.labels: dict[int, list[str]] = {}
        self.analyse()

    # ------------------------------------------------------------ structure

    def analyse(self) -> None:
        d = self.d
        scripts, scripts_end = self.sections[0], self.sections[1]
        p = scripts
        chain = []
        while p < scripts_end:
            nxt = w16(d, p + 4)
            chain.append((p, d[p:p + 4], nxt))
            if nxt <= p:
                break
            p = nxt
        # The last real script's next can point at the helper subroutines,
        # whose first bytes then read as a script with a far-off next.
        while chain and not (chain[-1][0] < chain[-1][2] <= scripts_end):
            a, key, nxt = chain.pop()
            self.quirks.append(
                f"The script chain runs on into code at {a:04X}: the engine reads its bytes "
                f"as key {key.hex(' ').upper()} and next {nxt:04X}"
                + (" (beyond rdf_scripts_end, so the search stops)." if nxt >= scripts_end else
                   ", which is before rdf_scripts_end, so the search carries on from there"
                   + self.wild_chain(nxt, scripts_end) + "."))
        self.headers = chain
        for a, _, _ in chain:
            self.hdr_bytes.update(range(a, a + 6))
            self.entries.add(a + 6)
        for e in sorted(self.entries):
            if e in self.hdr_bytes:
                self.quirks.append(f"The script at {e - 6:04X} has no body: its entry is the next "
                                   "script's header, whose six bytes run as code.")
            self.decode(e)
        for e in self.dead:
            self.decode(e)
            self.notes_before.setdefault(e, []).append(f"NOTE: unreachable (code={e:04X} in config/rdf.txt)")
        self.jump_tables()
        self.ptr_imm.update(self.code_ptrs)
        self.find_helpers()
        self.track()
        for t in list(self.convs):
            if self.cs_stores(t, 16):
                # built at run time: the stores are its words
                for a in self.cs_stores(t, 16):
                    self.mark(frozenset([(a, self.code[a].immediate16)]), "str")
                self.quirks.append(f"The conversation at {t:04X} is built at run time.")
            else:
                self.parse_conv(t)

    def cs_stores(self, lo: int, size: int) -> list[int]:
        """mov word ptr cs:[d], imm with lo <= d < lo + size."""
        return [a for a, i in self.code.items()
                if i.mnemonic == ix.Mnemonic.MOV and i.op0_kind == ix.OpKind.MEMORY
                and i.segment_prefix == ix.Register.CS and i.memory_base == ix.Register.NONE
                and i.op1_kind == ix.OpKind.IMMEDIATE16 and lo <= i.memory_displacement < lo + size]

    def jump_tables(self) -> None:
        """jmp cs:[reg+table]: the scripts fill the table at run time, so its
        targets are the constants they store in it."""
        done = set()
        while True:
            new = []
            for a, ins in list(self.code.items()):
                if ins.flow_control != ix.FlowControl.INDIRECT_BRANCH or a in done \
                        or ins.segment_prefix != ix.Register.CS:
                    continue
                done.add(a)
                table = ins.memory_displacement
                self.jump_table[table] = a
                for st in self.cs_stores(table, 32):
                    t = self.code[st].immediate16
                    if self.valid_ptr(t):
                        self.code_ptrs[st] = t
                        self.targets.add(t)
                        new.append(t)
            if not new:
                break
            for t in new:
                self.decode(t)

    def wild_chain(self, p: int, end: int) -> str:
        seen = set()
        out = []
        while p < end and p not in seen and p + 6 <= self.n:
            seen.add(p)
            out.append(f"{p:04X} (key {self.d[p:p + 4].hex(' ').upper()})")
            p = w16(self.d, p + 4)
        return ": " + ", ".join(out) + f", then next {p:04X} ends it"

    def note(self, a: int, text: str) -> None:
        self.notes.setdefault(a, []).append(text)

    def decode(self, entry: int) -> None:
        todo = [entry]
        while todo:
            a = todo.pop()
            prev = None
            while a not in self.code:
                if a in self.hdr_bytes:
                    if prev is not None:
                        self.note(prev, "NOTE: runs on into the next script's header, "
                                        "executing its six bytes as code")
                        self.quirks.append(f"Code at {prev:04X} runs on into the script header at {a:04X}.")
                    break
                if a >= self.n:
                    break
                ins = ix.Decoder(16, self.d[a:a + 16], ip=a).decode()
                if ins.code == ix.Code.INVALID or a + ins.len > self.n \
                        or any(b in self.hdr_bytes for b in range(a, a + ins.len)):
                    self.quirks.append(f"Undecodable code at {a:04X}.")
                    break
                inside = [c for c in self.code if c < a < c + self.code[c].len]
                if inside:
                    self.quirks.append(f"Code at {a:04X} is inside the instruction at {inside[0]:04X}.")
                    break
                self.code[a] = ins
                if ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
                    t = ins.near_branch16
                    if t in self.hdr_bytes:
                        self.note(a, "NOTE: jumps to a script header, executing its six bytes as code")
                        self.quirks.append(f"The jump at {a:04X} goes to the script header at {t:04X}.")
                        t = max(h for h, _, _ in self.headers if h <= t) + 6
                    self.targets.add(t)
                    todo.append(t)
                    if ins.mnemonic == ix.Mnemonic.CALL:
                        self.calls.add(t)
                if ins.flow_control in FLOW_END:
                    break
                prev = a
                a += ins.len

    def seq(self, a: int, n: int) -> list[ix.Instruction]:
        """Up to n instructions from a, stopping after a return."""
        out = []
        for _ in range(n):
            ins = self.code.get(a)
            if ins is None:
                break
            out.append(ins)
            a += ins.len
            if ins.flow_control == ix.FlowControl.RETURN:
                break
        return out

    @staticmethod
    def is_service(ins: ix.Instruction) -> bool:
        return (ins.mnemonic == ix.Mnemonic.CALL and ins.op0_kind == ix.OpKind.MEMORY
                and ins.memory_size == ix.MemorySize.SEG_PTR16
                and ins.memory_base == ix.Register.NONE and ins.memory_displacement == 0)

    def find_helpers(self) -> None:
        """Talk: service(RC_TALK, ax). Say: a conversation of one line, ax
        the speaker and bx the line, in a buffer in the file."""
        fmt = ix.Formatter(ix.FormatterSyntax.MASM)
        talk = None
        for c in sorted(self.calls):
            t = [fmt.format(i) for i in self.seq(c, 6)]
            if t in (["push ax", "mov ax,3", "push ax", "call dword ptr cs:[0]", "add sp,4", "ret"],
                     ["push ax", "push 3", "call dword ptr cs:[0]", "add sp,4", "ret"]):
                self.helpers[c] = "talk"
                talk = c
        for c in sorted(self.calls):
            s = self.seq(c, 6)
            if len(s) < 5 or not all(i.mnemonic == ix.Mnemonic.MOV for i in s[:-2]):
                continue
            stores = s[:-3]
            buf = stores[0].memory_displacement
            if not (stores[0].segment_prefix == ix.Register.CS and stores[0].op1_register == ix.Register.AX
                    and stores[1].segment_prefix == ix.Register.CS and stores[1].op1_register == ix.Register.BX
                    and stores[1].memory_displacement == buf + 2
                    and all(i.segment_prefix == ix.Register.CS and i.memory_displacement == buf + 4
                            and i.op1_kind == ix.OpKind.IMMEDIATE16 and i.immediate16 == 0
                            for i in stores[2:])
                    and s[-3].op0_register == ix.Register.AX and s[-3].op1_kind == ix.OpKind.IMMEDIATE16
                    and s[-3].immediate16 == buf
                    and s[-2].mnemonic == ix.Mnemonic.CALL and s[-2].near_branch16 == talk
                    and s[-1].mnemonic == ix.Mnemonic.RET):
                continue
            self.helpers[c] = "say"
            if self.say_buf not in (None, buf):
                self.quirks.append(f"Two talk buffers: {self.say_buf:04X} and {buf:04X}.")
            self.say_buf = buf
            self.ptr_imm[s[-3].ip] = buf
            self.convs[buf] = 0

    # ------------------------------------------------------------ data flow

    def valid_ptr(self, v: int) -> bool:
        return self.hdr_end <= v < self.n

    # Values: a frozenset of (source instruction, value) for a constant
    # loaded by mov/push/sub/xor (source None if there's nothing to name),
    # ("var", key) for a word loaded from a variable (operand_key), or ROOM
    # for &room (cs:rdf_state, and SI on entry). An empty set is unknown.
    # A state is the registers (missing: unknown) and the stack of pushed
    # values (None: unknown).
    def flow(self) -> None:
        """Forward dataflow of AX, BX, SI, DI and the pushes."""
        self.info = ix.InstructionInfoFactory()
        self.state_in: dict[int, tuple[dict[int, frozenset], tuple | None]] = {}
        work = []
        for e in sorted(self.entries | self.calls | set(self.dead)):
            if e in self.code:
                self.state_in[e] = ({ix.Register.SI: frozenset([ROOM])}, ())
                work.append(e)
        for e in sorted(set(self.code_ptrs.values())):
            if e in self.code and e not in self.state_in:
                self.state_in[e] = ({}, ())
                work.append(e)
        while work:
            a = work.pop()
            regs, stack = self.state_in[a]
            regs, stack = self.transfer(a, dict(regs), stack)
            ins = self.code[a]
            succ = []
            if ins.op0_kind == ix.OpKind.NEAR_BRANCH16 and ins.mnemonic != ix.Mnemonic.CALL:
                succ.append(ins.near_branch16)
            if ins.flow_control not in FLOW_END:
                succ.append(a + ins.len)
            for t in succ:
                if t not in self.code:
                    continue
                old = self.state_in.get(t)
                if old is None:
                    new = (regs, stack)
                else:
                    oregs, ostack = old
                    nregs = {r: oregs[r] | regs[r] for r in oregs if r in regs}
                    nstack = None
                    if ostack is not None and stack is not None:
                        # paths of different depth: keep what they agree on at the top
                        k = min(len(ostack), len(stack))
                        nstack = tuple(x | y for x, y in zip(ostack[len(ostack) - k:], stack[len(stack) - k:]))
                    new = (nregs, nstack)
                if old != new:
                    self.state_in[t] = new
                    work.append(t)

    def transfer(self, a: int, regs: dict, stack: tuple | None):
        ins = self.code[a]
        m = ins.mnemonic
        r0 = ins.op0_register if ins.op0_kind == ix.OpKind.REGISTER else None
        if m == ix.Mnemonic.PUSH:
            if ins.op0_kind in (ix.OpKind.IMMEDIATE16, ix.OpKind.IMMEDIATE8TO16):
                v = ins.immediate16 if ins.op0_kind == ix.OpKind.IMMEDIATE16 else ins.immediate8to16 & 0xFFFF
                item = frozenset([(a, v)])
            elif r0 is not None:
                item = regs.get(r0, frozenset())
            else:
                key = self.operand_key(a, regs)
                item = frozenset([("var", key)]) if key else frozenset()
            return regs, None if stack is None else stack + (item,)
        if m == ix.Mnemonic.POP:
            top = stack[-1] if stack else frozenset()
            if r0 is not None:
                regs[r0] = top
            return regs, None if stack is None else stack[:-1]
        if m == ix.Mnemonic.ADD and r0 == ix.Register.SP \
                and ins.op1_kind in (ix.OpKind.IMMEDIATE8TO16, ix.OpKind.IMMEDIATE16):
            n = (ins.immediate8to16 if ins.op1_kind == ix.OpKind.IMMEDIATE8TO16 else ins.immediate16) // 2
            return regs, None if stack is None else stack[:max(0, len(stack) - n)]
        if m == ix.Mnemonic.CALL:
            for r in (ix.Register.AX, ix.Register.BX):
                regs.pop(r, None)
            return regs, stack
        if m == ix.Mnemonic.MOV and r0 in TRACKED:
            if ins.op1_kind == ix.OpKind.IMMEDIATE16:
                regs[r0] = frozenset([(a, ins.immediate16)])
                return regs, stack
            if ins.op1_kind == ix.OpKind.MEMORY:
                key = self.operand_key(a, regs)
                if key == ("cs", 4):
                    regs[r0] = frozenset([ROOM])
                elif key:
                    regs[r0] = frozenset([("var", key)])
                else:
                    regs.pop(r0, None)
                return regs, stack
        if m in (ix.Mnemonic.SUB, ix.Mnemonic.XOR) and r0 in TRACKED \
                and ins.op1_kind == ix.OpKind.REGISTER and ins.op1_register == r0:
            regs[r0] = frozenset([(None, 0)])
            return regs, stack
        for r in self.info.info(ins).used_registers():
            if r.access in (ix.OpAccess.WRITE, ix.OpAccess.READ_WRITE, ix.OpAccess.COND_WRITE,
                            ix.OpAccess.READ_COND_WRITE):
                full = ix.RegisterExt.full_register(r.register)
                if full == ix.Register.ESP:
                    stack = None
                for k in TRACKED:
                    if ix.RegisterExt.full_register(k) == full:
                        regs.pop(k, None)
        return regs, stack

    def reg(self, a: int, r: int) -> frozenset:
        return self.state_in.get(a, ({}, None))[0].get(r, frozenset())

    def is_room(self, a: int, r: int) -> bool:
        return self.reg(a, r) == frozenset([ROOM])

    def operand_key(self, a: int, regs: dict | None = None):
        """The memory word an instruction uses, as ("cs", d) or
        ("room", d), or None."""
        ins = self.code[a]
        if not any(ins.op_kind(k) == ix.OpKind.MEMORY for k in range(ins.op_count)) \
                or ins.memory_index != ix.Register.NONE:
            return None
        if ins.segment_prefix == ix.Register.CS and ins.memory_base == ix.Register.NONE:
            return ("cs", ins.memory_displacement)
        if regs is None:
            regs = self.state_in.get(a, ({}, None))[0]
        if ins.segment_prefix == ix.Register.NONE and ins.memory_base in (ix.Register.SI, ix.Register.BX) \
                and regs.get(ins.memory_base) == frozenset([ROOM]):
            return ("room", ins.memory_displacement)
        return None

    def track(self) -> None:
        """Find the ScriptService arguments and the helpers' register
        arguments, and mark the pointers among them."""
        self.flow()
        for a in sorted(self.code):
            if a not in self.state_in:
                continue
            ins = self.code[a]
            m = ins.mnemonic
            regs, stack = self.state_in[a]
            if self.is_service(ins):
                n = len(stack or ())
                after = self.code.get(a + ins.len)
                if after is not None and after.mnemonic == ix.Mnemonic.ADD \
                        and after.op0_register == ix.Register.SP \
                        and after.op1_kind == ix.OpKind.IMMEDIATE8TO16:
                    n = after.immediate8to16 // 2
                self.svc[a] = self.service_args(stack, n)
            elif m == ix.Mnemonic.ADD and ins.op0_register == ix.Register.SP and stack \
                    and ins.op1_kind == ix.OpKind.IMMEDIATE8TO16:
                prev = max((p for p in self.code if p < a), default=None)
                if prev is not None and prev + self.code[prev].len == a \
                        and self.code[prev].mnemonic == ix.Mnemonic.PUSH:
                    # pushed and dropped: a call that was taken out
                    self.dropped[a] = self.service_args(stack, ins.immediate8to16 // 2)
            elif m == ix.Mnemonic.CALL and ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
                kind = self.helpers.get(ins.near_branch16)
                if kind == "talk":
                    self.mark(self.reg(a, ix.Register.AX), "conv")
                elif kind == "say":
                    self.mark(self.reg(a, ix.Register.AX), "str")
                    self.mark(self.reg(a, ix.Register.BX), "str")
            if ins.segment_prefix == ix.Register.CS and ins.memory_base in TRACKED \
                    and not self.is_room(a, ins.memory_base):
                self.mark(self.reg(a, ins.memory_base), "data")
        self.table_bases()
        self.service_loops()
        # variables that hold pointers: every constant stored in them is one
        for _ in range(3):
            for a, ins in self.code.items():
                if ins.mnemonic != ix.Mnemonic.MOV or ins.op0_kind != ix.OpKind.MEMORY:
                    continue
                kind = self.ptr_vars.get(self.operand_key(a))
                if not kind:
                    continue
                if ins.op1_kind == ix.OpKind.IMMEDIATE16:
                    self.mark(frozenset([(a, ins.immediate16)]), kind)
                elif ins.op1_kind == ix.OpKind.REGISTER:
                    self.mark(self.reg(a, ins.op1_register), kind)

    def service_loops(self) -> None:
        """mov di, N then a loop [push cmd] SERVICE / add sp, 4 / dec di /
        jne: N calls, each taking its arguments from what was pushed before
        the loop (MUDD rooms)."""
        for a, ins in self.code.items():
            if not (ins.mnemonic == ix.Mnemonic.MOV and ins.op0_kind == ix.OpKind.REGISTER
                    and ins.op0_register == ix.Register.DI and ins.op1_kind == ix.OpKind.IMMEDIATE16):
                continue
            body = self.seq(a + ins.len, 5)
            cmd_push = None
            if body and body[0].mnemonic == ix.Mnemonic.PUSH and body[0].op0_kind != ix.OpKind.REGISTER:
                cmd_push = body[0]
                body = body[1:]
            if len(body) < 4 or not self.is_service(body[0]) or body[2].mnemonic != ix.Mnemonic.DEC \
                    or body[3].mnemonic != ix.Mnemonic.JNE:
                continue
            stack = list(self.state_in.get(a, ({}, None))[1] or ())
            calls = []
            for _ in range(ins.immediate16):
                if cmd_push is not None:
                    v = cmd_push.immediate8to16 & 0xFFFF if cmd_push.op0_kind == ix.OpKind.IMMEDIATE8TO16 \
                        else cmd_push.immediate16
                    args = [frozenset([(cmd_push.ip, v)])] + ([stack.pop()] if stack else [])
                else:
                    args = [stack.pop() if stack else frozenset() for _ in range(2)]
                calls.append(self.service_args(tuple(reversed(args)), 2))
            self.loop_calls[body[0].ip] = calls

    def service_args(self, stack: tuple | None, n: int) -> list:
        """A ScriptService call's arguments from the stack, command first,
        as (kind, None, values); marks the pointers among them."""
        if stack is None:
            return []
        args = [("arg", None, v) for v in reversed(stack[max(0, len(stack) - n):])]
        cmd = single(args[0][2]) if args else None
        for k in SERVICE.get(cmd, ("", ()))[1]:
            if k < len(args):
                self.mark(args[k][2], "conv" if cmd == 3 else "str")
        return args

    def table_bases(self) -> None:
        """mov bx/si/di, imm followed (before the register changes or the
        code leaves the block) by a cs:[reg] access: a table in the file."""
        addrs = sorted(self.code)
        for i, a in enumerate(addrs):
            ins = self.code[a]
            if not (ins.mnemonic == ix.Mnemonic.MOV and ins.op0_kind == ix.OpKind.REGISTER
                    and ins.op0_register in (ix.Register.BX, ix.Register.SI, ix.Register.DI)
                    and ins.op1_kind == ix.OpKind.IMMEDIATE16 and self.valid_ptr(ins.immediate16)):
                continue
            reg = ins.op0_register
            for b in addrs[i + 1:i + 16]:
                nxt = self.code[b]
                if nxt.segment_prefix == ix.Register.CS and nxt.memory_base == reg:
                    self.mark(frozenset([(a, ins.immediate16)]), "data")
                    break
                if nxt.flow_control in (ix.FlowControl.RETURN, ix.FlowControl.UNCONDITIONAL_BRANCH) \
                        or nxt.mnemonic == ix.Mnemonic.MOV and nxt.op0_kind == ix.OpKind.REGISTER \
                        and nxt.op0_register == reg:
                    break

    def mark(self, vals: frozenset, kind: str) -> None:
        """These values are pointers: to a conversation ("conv"), a string
        ("str") or other data ("data")."""
        for v in vals:
            if v is ROOM:
                continue
            if v[0] == "var":
                self.ptr_vars.setdefault(v[1], kind)
                continue
            src, val = v
            if src is None or not self.valid_ptr(val):
                continue
            self.ptr_imm[src] = val
            if kind == "conv":
                self.convs.setdefault(val, 0)
            elif kind == "data":
                self.data_ptrs.add(val)
            else:
                self.strings.add(val)

    def parse_conv(self, t: int) -> None:
        """A conversation: speaker (or 0), then the choices, then 0."""
        if t == self.say_buf:
            self.convs[t] = 3
            return
        n = 0
        while t + 2 * n + 2 <= self.n:
            v = w16(self.d, t + 2 * n)
            n += 1
            if v == 0 and n > 1:
                break
            if v and not self.valid_ptr(v):
                self.quirks.append(f"Conversation {t:04X}: word {n - 1} isn't a pointer.")
                self.convs[t] = 0
                return
        self.convs[t] = n
        for k in range(n):
            v = w16(self.d, t + 2 * k)
            if v:
                self.ptr_data[t + 2 * k] = v
                self.strings.add(v)


# ====================================================================== source

class Writer:
    def __init__(self, room: Room):
        self.r = room
        self.d = room.d
        self.raw: set[int] = set()      # instructions emitted as DB
        self.fmt = ix.Formatter(ix.FormatterSyntax.MASM)
        self.fmt.hex_suffix = "h"
        self.fmt.hex_prefix = ""
        self.fmt.uppercase_hex = True
        self.fmt.space_after_operand_separator = True
        self.fmt.signed_immediate_operands = True
        self.fmt.show_branch_size = False
        self.names: dict[int, list[str]] = {}
        self.used: set[str] = set()
        self.make_labels()

    # ------------------------------------------------------------ labels

    def add(self, a: int, name: str, unique: bool = True) -> str:
        base = re.sub(r"[^A-Za-z0-9_]", "_", name)[:28]
        name = base
        k = 2
        while unique and name.lower() in self.used:
            name = f"{base}_{k}"
            k += 1
        self.used.add(name.lower())
        self.names.setdefault(a, []).append(name)
        return name

    def name(self, a: int) -> str:
        """The label to use for a: a section label only if there's no other."""
        return next((n for n in self.names[a] if n not in SECTIONS), self.names[a][0])

    def unnamed(self, a: int) -> bool:
        return all(n in SECTIONS for n in self.names.get(a, []))

    def string_name(self, a: int) -> str:
        d = self.d
        end = d.find(b"\0", a)
        s = d[a:end if end >= 0 else a + 40].decode("latin-1")
        m = re.match(r"#\w+\\(\w+)#", s)
        if m:
            return "T_" + m.group(1)
        if 0 < len(s) <= 20 and re.fullmatch(r"[A-Za-z0-9_ .']+", s):
            return "N_" + re.sub(r"[ .']+", "_", s).strip("_")
        return f"S_{a:04X}"

    def make_labels(self) -> None:
        r = self.r
        for off, name, words, _ in HEADER:
            self.add(off, name)
        for i, s in enumerate(r.sections):
            self.add(s, SECTIONS[i])
        for a, _, _ in r.headers:
            self.add(a, f"H_{a:04X}")
        for e in sorted(r.entries):
            ins = r.code.get(e)
            if ins is not None and ins.mnemonic == ix.Mnemonic.JMP and e not in r.targets \
                    and ins.near_branch16 in r.entries:
                continue        # shares another script's body
            self.add(e, f"E_{e:04X}")
        for c, kind in r.helpers.items():
            self.add(c, {"talk": "Talk", "say": "Say"}[kind])
        # arrays: their words are named as offsets from the start
        self.arrays: dict[int, tuple[str, int]] = {}
        if r.say_buf is not None:
            self.arrays[r.say_buf] = (self.add(r.say_buf, "talk_buf"), 16)
        for k, t in enumerate(sorted(r.jump_table)):
            self.arrays[t] = (self.add(t, "choice_jumps" + (str(k + 1) if len(r.jump_table) > 1 else "")), 32)
        for c in sorted(r.calls - set(r.helpers)):
            self.add(c, f"F_{c:04X}")
        for t in sorted(r.targets | set(r.dead)):
            if t not in self.names:
                self.add(t, f"L{t:04X}")
        for t in sorted(r.convs):
            if self.unnamed(t):
                self.add(t, f"C_{t:04X}")
        for t in sorted(r.data_ptrs):
            if self.unnamed(t):
                self.add(t, f"D_{t:04X}")
        for t in sorted(set(r.ptr_imm.values()) | set(r.ptr_data.values()) | r.strings - r.data_ptrs):
            if self.unnamed(t):
                self.add(t, self.string_name(t))
        for a in sorted(r.code):
            ins = r.code[a]
            if ins.op_count and any(ins.op_kind(k) == ix.OpKind.MEMORY for k in range(ins.op_count)) \
                    and ins.segment_prefix == ix.Register.CS and not r.is_service(ins):
                disp = ins.memory_displacement
                if ins.memory_base != ix.Register.NONE and ins.memory_displ_size == 0:
                    continue
                r.mem_refs.add(disp)
                if disp >= r.hdr_end and self.unnamed(disp) and self.in_array(disp) is None:
                    self.add(disp, f"D_{disp:04X}")
            elif self.room_operand(a):
                r.room_disp.add(ins.memory_displacement)

    def room_operand(self, a: int) -> bool:
        """[si+d] or [bx+d] with the register at &room."""
        r = self.r
        ins = r.code[a]
        return (any(ins.op_kind(k) == ix.OpKind.MEMORY for k in range(ins.op_count))
                and ins.segment_prefix == ix.Register.NONE and ins.memory_index == ix.Register.NONE
                and ins.memory_base in (ix.Register.SI, ix.Register.BX)
                and r.is_room(a, ins.memory_base) and ins.memory_displacement < ROOM_SIZE)

    def in_array(self, v: int) -> tuple[str, int] | None:
        """(array, offset) for an address inside an array; an array ends at
        the next label."""
        for start, (name, size) in self.arrays.items():
            if start <= v < start + size and not any(start < x <= v for x in self.names):
                return name, v - start
        return None

    def sym(self, v: int) -> str:
        """An address in the file as label[+n]."""
        arr = self.in_array(v)
        if arr and arr[1]:
            return f"{arr[0]}+{arr[1]}"
        if v in self.names:
            return self.name(v)
        if v < self.r.hdr_end:
            off, name = max((o, n) for o, n, _, _ in HEADER if o <= v)
            return f"{name}+{v - off}"
        return f"{hexnum(v)}"

    @staticmethod
    def room_sym(disp: int) -> str:
        if disp >= 0x29:
            return f"v{disp - 0x29:02X}"
        off, name = max(f for f in ROOM_FIELDS if f[0] <= disp)
        return name if disp == off else f"{name}+{disp - off}"

    # ------------------------------------------------------------ code

    def ins_text(self, a: int) -> str:
        r = self.r
        ins = r.code[a]
        if r.is_service(ins):
            return "SERVICE"
        text = self.fmt.format(ins)
        m = ins.mnemonic
        if self.d[a] == 0x83 and ins.op0_kind == ix.OpKind.REGISTER and ins.op0_register == ix.Register.AX \
                and m in AX8_OPS:
            return f"AX8\t{text.split()[0]}, {hexnum(ins.immediate8to16 & 0xFF)}"
        if ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
            t = ins.near_branch16
            name = self.name(t)
            if m == ix.Mnemonic.JMP:
                return f"jmp\tSHORT {name}" if ins.len == 2 else f"JMPN\t{name}"
            return f"{text.split()[0]}\t{name}"
        mem = any(ins.op_kind(k) == ix.OpKind.MEMORY for k in range(ins.op_count))
        if mem:
            text = self.sub_mem(ins, text)
        if a in r.ptr_imm:
            text = sub_last_number(text, f"OFFSET {self.sym(r.ptr_imm[a])}")
        elif self.is_cmd_push(a):
            v = r.svc_cmd_at[a]
            if v < len(RC_NAMES):
                text = sub_last_number(text, RC_NAMES[v])
        elif a in r.item_imm:
            text = sub_last_number(text, r.item_imm[a])
        mn, _, ops = text.partition(" ")
        return f"{mn}\t{ops}" if ops else mn

    def is_cmd_push(self, a: int) -> bool:
        return a in self.r.svc_cmd_at

    def sub_mem(self, ins: ix.Instruction, text: str) -> str:
        r = self.r
        regs = []
        if ins.memory_base != ix.Register.NONE:
            regs.append(_reg(ins.memory_base))
        if ins.memory_index != ix.Register.NONE:
            regs.append(_reg(ins.memory_index))
        disp = ins.memory_displacement
        seg = ""
        if ins.segment_prefix != ix.Register.NONE:
            seg = _reg(ins.segment_prefix) + ":"
        if ins.segment_prefix == ix.Register.CS:
            if regs and ins.memory_displ_size == 0:
                inner = "[" + "+".join(regs) + "]"
            else:
                inner = self.sym(disp)
                if regs:
                    inner = "[" + "+".join(regs + [inner]) + "]"
        elif self.room_operand(ins.ip):
            inner = f"[{regs[0]}+{self.room_sym(disp)}]"
        else:
            return text
        lb = text.index("[")
        rb = text.index("]", lb)
        pre = text[:lb]
        for s in ("es:", "cs:", "ss:", "ds:"):
            if pre.endswith(s):
                pre = pre[:-len(s)]
        pre = re.sub(r"(byte|word|dword|qword) ptr $", "", pre)
        return f"{pre}{_ptr(ins)}{seg}{inner}{text[rb + 1:]}"

    def raw_lines(self, a: int, n: int, comment: str = "") -> list[str]:
        """Bytes, keeping pointer immediates, cs: displacements and branch
        displacements symbolic."""
        r = self.r
        fields: dict[int, tuple[int, str]] = {}
        ins = r.code.get(a)
        if ins is not None and n == ins.len:
            co = ix.Decoder(16, self.d[a:a + n], ip=a)
            i2 = co.decode()
            off = co.get_constant_offsets(i2)
            if a in r.ptr_imm and off.immediate_size == 2:
                fields[a + off.immediate_offset] = (2, f"DW\tOFFSET {self.sym(r.ptr_imm[a])}")
            if ins.segment_prefix == ix.Register.CS and off.displacement_size == 2:
                fields[a + off.displacement_offset] = (2, f"DW\tOFFSET {self.sym(ins.memory_displacement)}")
            if ins.op0_kind == ix.OpKind.NEAR_BRANCH16:
                t = self.name(ins.near_branch16)
                if self.d[a] in (0xE8, 0xE9):
                    fields[a + 1] = (2, f"DW\t{t}-($+2)")
                elif ins.len == 2:
                    fields[a + 1] = (1, f"DB\t{t}-($+1)")
        out = []
        chunk: list[str] = []

        def flush():
            if chunk:
                out.append("\tDB\t" + ", ".join(chunk))
                chunk.clear()
        i = 0
        while i < n:
            if a + i in fields:
                flush()
                size, text = fields[a + i]
                out.append("\t" + text)
                i += size
                continue
            chunk.append(hexnum(self.d[a + i]))
            i += 1
        flush()
        if comment and out:
            out[0] += "\t; " + comment
        return out

    def svc_comment(self, args: list | None) -> str:
        cmd = single(args[0][2]) if args else None
        if cmd is None:
            return ""
        name = SERVICE.get(cmd, (f"cmd{cmd}", ()))[0]
        out = []
        for k, (kind, _, vals) in enumerate(args[1:], 1):
            v = single(vals)
            if v is None:
                out.append("?")
            elif any(src in self.r.ptr_imm for src, _ in consts(vals)):
                out.append(self.quote(v))
            elif cmd in ITEM_ARG and k == 1 and v in self.r.items:
                out.append(self.r.items[v])
            else:
                out.append(str(v - 0x10000 if v >= 0x8000 else v))
        return f"{name}({', '.join(out)})"

    def quote(self, v: int) -> str:
        d = self.d
        end = d.find(b"\0", v)
        s = d[v:end].decode("latin-1") if end >= 0 else ""
        if v in self.r.convs or not s or len(s) > 24 or not all(printable(ord(c)) for c in s):
            return self.sym(v)
        return '"' + s + '"'

    # ------------------------------------------------------------ data

    def data_lines(self, a: int, b: int) -> list[str]:
        """Bytes [a, b) that aren't code or headers."""
        r = self.r
        out = []
        cuts = sorted({x for x in self.names if a < x < b}
                      | {x for x in r.convs if a < x < b} | {b})
        pos = a
        for nxt in cuts:
            out += self.label_lines(pos, data=True)
            out += self.chunk_lines(pos, nxt)
            pos = nxt
        return out

    def chunk_lines(self, a: int, b: int) -> list[str]:
        r = self.r
        d = self.d
        out = []
        if a in r.convs and r.convs[a] and a + 2 * r.convs[a] <= b:
            n = r.convs[a]
            words = [f"OFFSET {self.sym(w16(d, a + 2 * k))}" if a + 2 * k in r.ptr_data
                     else hexnum(w16(d, a + 2 * k)) for k in range(n)]
            what = "speaker, line, 0" if a == r.say_buf else "speaker, choices, 0"
            out.append(f"\tDW\t{', '.join(words)}\t; {what}")
            a += 2 * n
        pos = a
        while pos < b:
            # a string: printable bytes and a NUL
            e = pos
            while e < b and printable(d[e]):
                e += 1
            if e < b and d[e] == 0 and (e - pos >= 3 or (e > pos and pos in self.names)):
                out += string_lines(d[pos:e])
                pos = e + 1
                continue
            # bytes up to the next string start
            e = pos + 1
            while e < b:
                f = e
                while f < b and printable(d[f]):
                    f += 1
                if f < b and d[f] == 0 and f - e >= 3:
                    break
                e = f + 1 if f > e else e + 1
            e = min(e, b)
            for k in range(pos, e, 12):
                out.append("\tDB\t" + ", ".join(hexnum(x) for x in d[k:min(k + 12, e)]))
            pos = e
        return out

    def poly_lines(self, a: int, b: int, objects: bool) -> list[str] | None:
        d = self.d
        out = []
        p = a
        while p < b:
            if objects and w16(d, p) & 0x8000:
                out.append(f"\tDW\t{hexnum(w16(d, p))}, {w16(d, p + 2)}, {w16(d, p + 4)}"
                           "\t; actions (bit 15 set), walk to (x, y)")
                p += 6
            if p + 4 > b:
                return None
            n = w16(d, p + 2)
            if n == 0 or n > 64 or p + 4 + 4 * n > b:
                return None
            out.append(f"\tDW\t{hexnum(w16(d, p))}, {n}\t; id, points")
            pts = [f"{w16(d, p + 4 + 4 * k)},{w16(d, p + 6 + 4 * k)}" for k in range(n)]
            for k in range(0, n, 6):
                out.append("\tDW\t" + ", ".join(pts[k:k + 6]))
            p += 4 + 4 * n
        return out

    def header_lines(self) -> list[str]:
        r = self.r
        d = self.d
        out = []
        for off, name, words, comment in HEADER:
            if off >= r.hdr_end:
                break
            words = min(words, (r.hdr_end - off) // 2)
            out += self.label_lines(off, data=True)
            first = len(out)
            vals = [w16(d, off + 2 * k) for k in range(words)]
            if name == "rdf_service":
                out.append(f"\tDD\t{hexnum(vals[0] | vals[1] << 16)}")
            elif name == "rdf_sections":
                for k in range(0, 10, 2):
                    out.append(f"\tDW\tOFFSET {SECTIONS[k]}, OFFSET {SECTIONS[k + 1]}")
            elif name == "rdf_walk_in":
                out.append(f"\t\t\t\t; {comment}")
                comment = None
                for k in range(0, words - 3, 4):
                    q = vals[k:k + 4]
                    out.append(f"\tDW\t{q[0]},{q[1]}, {q[2]},{q[3]}\t; entrance {k // 16}, crew {k // 4 % 4}")
            elif name in ("rdf_beam_pos", "rdf_stand_pos"):
                out.append("\tDW\t" + ", ".join(f"{vals[k]},{vals[k + 1]}" for k in range(0, words - 1, 2)))
            elif name == "rdf_exit_room":
                out.append("\tDW\t" + ", ".join("-1" if v == 0xFFFF else str(v) for v in vals))
            else:
                out.append("\tDW\t" + ", ".join(hexnum(v) for v in vals))
            if comment and len(out) > first:
                out[first] += f"\t; {comment}"
        # header fields cut short by data that starts inside the header
        if r.hdr_end < HDR_END:
            out.append(f"; (the header is cut short at {r.hdr_end:04X}, where the room's data starts)")
        return out

    def label_lines(self, a: int, data: bool = False) -> list[str]:
        return [f"{n}\tLABEL\tBYTE" if data else f"{n}:" for n in self.names.get(a, [])]

    def script_line(self, a: int, key: bytes, nxt: int) -> str:
        t, b1, b2, b3 = key
        args = [MSG_NAMES.get(t, hexnum(t))]
        objs = OBJ_MSGS.get(t, 0)
        for k, v in enumerate((b1, b2, b3)):
            if k < objs:
                args.append(OBJ_NAMES.get(v) or self.r.items.get(v) or hexnum(v))
            else:
                args.append("ANY" if v == 0xFF else hexnum(v))
        return f"\tSCRIPT\t{', '.join(args)}, {self.name(nxt) if nxt in self.names else hexnum(nxt)}"

    # ------------------------------------------------------------ file

    def source(self) -> str:
        r = self.r
        d = self.d
        body: list[str] = []
        hdrs = {a: (key, nxt) for a, key, nxt in r.headers}
        polys = {}
        for k, objects in ((2, True), (4, False), (6, False)):
            s, e = r.sections[k], r.sections[k + 1]
            if s < e:
                polys[s] = (e, objects)
        pos = 0
        body += self.header_lines()
        pos = r.hdr_end
        while pos < r.n:
            if pos in hdrs:
                key, nxt = hdrs[pos]
                body.append("")
                body += self.label_lines(pos)
                body.append(self.script_line(pos, key, nxt))
                pos += 6
                continue
            if pos in r.code:
                body += ["\t\t\t\t; " + n for n in r.notes_before.get(pos, [])]
                body += self.label_lines(pos)
                ins = r.code[pos]
                if pos in self.raw:
                    body += self.raw_lines(pos, ins.len, self.fmt.format(ins))
                else:
                    line = "\t" + self.ins_text(pos)
                    c = self.svc_comment(r.svc.get(pos)) if r.is_service(ins) else ""
                    if pos in r.loop_calls:
                        c = "; ".join(self.svc_comment(x) for x in r.loop_calls[pos])
                    if pos in r.dropped:
                        c = f"NOTE: drops the arguments of {self.svc_comment(r.dropped[pos])}: " \
                            "the call was taken out"
                    if c:
                        line += "\t\t; " + c
                    body.append(line)
                for n in r.notes.get(pos, []):
                    body.append("\t\t\t\t; " + n)
                pos += ins.len
                if ins.flow_control in FLOW_END and pos not in hdrs:
                    body.append("")
                continue
            if pos in polys:
                e, objects = polys[pos]
                lines = self.poly_lines(pos, e, objects)
                if lines is not None and not any(pos < x < e for x in r.code) \
                        and not any(pos < x < e for x in hdrs):
                    body += self.label_lines(pos, data=True)
                    body += lines
                    pos = e
                    continue
            e = pos
            while e < r.n and e not in r.code and e not in hdrs and (e == pos or e not in polys):
                e += 1
            body += self.data_lines(pos, e)
            pos = e
        body += self.label_lines(r.n, data=True)

        vars_ = sorted(x for x in r.room_disp if x >= 0x29)
        head = [f"; {r.name}.RDF - room scripts (generated by tools/rdf.py; edit freely)",
                ";",
                "; Labels: H_ script headers, E_ script entries, L branch targets,",
                "; F_ subroutines, C_ conversations, T_/N_/S_ strings, D_ data;",
                "; talk_buf: the conversation buffer of Say; choice_jumps: where to go",
                "; for each choice of a conversation built at run time.",
                "; vNN: RoomState.vars bytes, reached through SI (or BX)."]
        if r.quirks:
            head += [";", "; Quirks of the original:"]
            for q in r.quirks:
                head += wrap("; - ", q)
        head += ["", "\tINCLUDE\trdf.inc", ""]
        for v in vars_:
            head.append(f"v{v - 0x29:02X}\tEQU\tRS_VARS+{hexnum(v - 0x29)}")
        if vars_:
            head.append("")
        head += ["RDF\tSEGMENT BYTE PUBLIC 'RDF'",
                 "\tASSUME\tCS:RDF, DS:NOTHING, ES:NOTHING, SS:NOTHING", ""]
        tail = ["", "RDF\tENDS", "\tEND", ""]
        return "\n".join(head + body + tail)


def sub_last_number(text: str, val: str) -> str:
    ms = list(re.finditer(r"-?\b[0-9][0-9A-F]*h?\b", text))
    if not ms:
        return text
    mt = ms[-1]
    return text[:mt.start()] + val + text[mt.end():]


def string_lines(s: bytes) -> list[str]:
    text = s.decode("latin-1")
    parts = [text[k:k + 64] for k in range(0, len(text), 64)] or [""]
    out = []
    for k, p in enumerate(parts):
        q = "'" + p.replace("'", "''") + "'"
        out.append(f"\tDB\t{q}" + (",0" if k == len(parts) - 1 else ""))
    return out


def wrap(prefix: str, text: str, width: int = 76) -> list[str]:
    out = []
    line = prefix
    for word in text.split():
        if len(line) + len(word) + 1 > width and line.strip(" ;-"):
            out.append(line.rstrip())
            line = ";   "
        line += word + " "
    out.append(line.rstrip())
    return out


_REG_NAMES = {getattr(ix.Register, n): n.lower() for n in dir(ix.Register) if n.isupper()}


def _reg(r: int) -> str:
    return _REG_NAMES[r]


def _ptr(ins: ix.Instruction) -> str:
    size = ix.MemorySizeInfo(ins.memory_size).size
    return {1: "byte ptr ", 2: "word ptr ", 4: "dword ptr "}.get(size, "")


# ====================================================================== assembling

def dos_path(p: Path) -> str:
    return "D:\\" + "\\".join(p.resolve().relative_to(ROOT).parts).upper()


def assemble(src: Path, obj: Path) -> bytes | str:
    """MASM the source; the segment's bytes with fixups applied, or errors."""
    obj.parent.mkdir(parents=True, exist_ok=True)
    produced = obj.parent / obj.name.lower()
    for old in obj.parent.iterdir():
        if old.name.lower() == produced.name:
            old.unlink()
    env = dict(os.environ, EMU2_DRIVE_C=str(MASM), EMU2_DRIVE_D=str(ROOT))
    cmd = [EMU2, str(MASM / "BIN/MASM.EXE"), "/Ml", "/t", "/ID:\\INCLUDE",
           f"{dos_path(src)},{dos_path(obj)};", "--", "INCLUDE=C:\\INC"]
    res = subprocess.run(cmd, env=env, capture_output=True, text=True, errors="replace")
    if res.returncode != 0 or not produced.exists():
        return (res.stdout + res.stderr).strip() or f"MASM failed ({res.returncode})"
    mod = omf.parse_obj(produced.read_bytes())
    seg = mod.seg_by_name("RDF")
    if seg is None:
        return "no RDF segment"
    data = bytearray(seg.data)
    for f in seg.fixups:
        if f.loc != 1:          # 16-bit offsets only
            return f"unexpected fixup {f}"
        old = struct.unpack_from("<H", data, f.offset)[0]
        v = old + f.disp if f.seg_relative else old + f.disp - (f.offset + 2)
        struct.pack_into("<H", data, f.offset, v & 0xFFFF)
    return bytes(data)


def first_diff(a: bytes, b: bytes) -> int | None:
    for i in range(min(len(a), len(b))):
        if a[i] != b[i]:
            return i
    return None if len(a) == len(b) else min(len(a), len(b))


def generate(name: str, arc: Archive, force: bool) -> bool:
    out = SRC / f"{name.lower()}.asm"
    if out.exists() and not force:
        print(f"{out.relative_to(ROOT)} exists (edited by hand?); use --force to overwrite")
        return False
    data = load_room(name, arc)
    dead = [int(f[5:], 16) for f in room_flags().get(name, set()) if f.startswith("code=")]
    room = Room(name, data, dead)
    room.items = load_items()
    resolve_semantics(room)
    w = Writer(room)
    tmp = BUILD / "gen"
    tmp.mkdir(parents=True, exist_ok=True)
    src = tmp / f"{name.lower()}.asm"
    for _ in range(MAX_ROUNDS):
        text = w.source()
        src.write_text(text.replace("\n", "\r\n"))
        got = assemble(src, tmp / f"{name.lower()}.obj")
        if isinstance(got, str):
            print(got)
            print(f"rdf: {name}: assembly failed (see {src.relative_to(ROOT)})")
            return False
        bad = first_diff(got, data)
        if bad is None:
            break
        ins = max((a for a in room.code if a <= bad), default=None)
        if ins is None or bad >= ins + room.code[ins].len or ins in w.raw:
            print(f"rdf: {name}: can't match at {bad:04X} (see {src.relative_to(ROOT)})")
            return False
        w.raw.add(ins)
    else:
        print(f"rdf: {name}: too many rounds")
        return False
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text)
    print(f"{out.relative_to(ROOT)}: {len(room.headers)} scripts, "
          f"{sum(i.len for i in room.code.values())} code bytes, {len(w.raw)} instructions as DB, "
          f"{len(room.quirks)} quirks")
    return True


def load_items() -> dict[int, str]:
    inc = (ROOT / "include/rdf.inc").read_text()
    return {int(v.rstrip("h"), 16): n for n, v in re.findall(r"^(IT_\w+)\s+EQU\s+(\w+)", inc, re.M)}


def resolve_semantics(room: Room) -> None:
    """Command pushes and item arguments, for naming."""
    room.svc_cmd_at = {}
    room.item_imm = {}
    for args in [*room.svc.values(), *(c for cs in room.loop_calls.values() for c in cs)]:
        cmd = single(args[0][2]) if args else None
        if cmd is None:
            continue
        for src, _ in consts(args[0][2]):
            if src is not None:
                room.svc_cmd_at[src] = cmd
        if cmd in ITEM_ARG and len(args) > 1:
            for src, v in consts(args[1][2]):
                if src is not None and v in room.items:
                    room.item_imm[src] = room.items[v]


def check(name: str) -> bool:
    src = SRC / f"{name.lower()}.asm"
    if not src.exists():
        print(f"{name}: no source")
        return False
    got = assemble(src, BUILD / f"{name.lower()}.obj")
    if isinstance(got, str):
        print(got)
        print(f"{name}: assembly failed")
        return False
    data = load_room(name)
    bad = first_diff(got, data)
    if bad is not None:
        print(f"{name}: differs from the original at {bad:04X} "
              f"(size {len(got):X}, original {len(data):X})")
        return False
    return True


def write_patch(name: str, out_dir: Path) -> bool:
    """A patches/<room>.rdf the game loads instead of DATA.001's
    (LoadPatchPacked): the unpacked size, then LZSS with every item a
    literal (flag byte FFh, eight bytes)."""
    src = SRC / f"{name.lower()}.asm"
    got = assemble(src, BUILD / f"{name.lower()}.obj")
    if isinstance(got, str):
        print(got)
        return False
    packed = bytearray(struct.pack("<H", len(got)))
    for k in range(0, len(got), 8):
        chunk = got[k:k + 8]
        packed.append(0xFF)
        packed += chunk
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"{name.lower()}.rdf"
    out.write_bytes(packed)
    print(f"{out}: {len(got)} bytes" + ("" if got == load_room(name) else " (differs from the original)"))
    return True


# ====================================================================== progress

def progress() -> None:
    """Scripts with a body of their own (not just a jmp to another's) and
    how many of those have had their E_XXXX entry label renamed."""
    flags = room_flags()
    tot_s = tot_b = tot_n = done = 0
    print(f"{'room':10} {'scripts':>8} {'bodies':>7} {'named':>6}")
    for name in room_names():
        src = SRC / f"{name.lower()}.asm"
        if not src.exists():
            print(f"{name:10} {'-':>8} {'-':>7} {'-':>6}  no source")
            continue
        lines = [ln.split(";")[0].strip() for ln in src.read_text().splitlines()]
        scripts = bodies = named = 0
        for i, line in enumerate(lines):
            if line.split()[:1] != ["SCRIPT"]:
                continue
            scripts += 1
            nxt = next((ln for ln in lines[i + 1:] if ln), "")    # comments are stripped
            if nxt.endswith(":"):
                bodies += 1
                if not re.fullmatch(r"E_[0-9A-F]{4}:", nxt):
                    named += 1
        complete = "complete" in flags.get(name, set())
        done += complete
        tot_s += scripts
        tot_b += bodies
        tot_n += named
        print(f"{name:10} {scripts:8} {bodies:7} {named:6}  {'complete' if complete else ''}")
    pct = 100 * tot_n / tot_b if tot_b else 0
    print(f"{'all':10} {tot_s:8} {tot_b:7} {tot_n:6}  {pct:.1f}% of script bodies named, "
          f"{done}/{len(room_names())} rooms complete")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    g = sub.add_parser("gen")
    g.add_argument("rooms", nargs="*")
    g.add_argument("--all", action="store_true")
    g.add_argument("--force", action="store_true")
    c = sub.add_parser("check")
    c.add_argument("rooms", nargs="*")
    c.add_argument("--all", action="store_true")
    c.add_argument("--stamp", help="touch this file if every room matches")
    sub.add_parser("progress")
    pa = sub.add_parser("patch")
    pa.add_argument("rooms", nargs="+")
    pa.add_argument("-o", "--out", default=str(BUILD / "patches"))
    args = ap.parse_args()

    if args.cmd == "progress":
        progress()
        return
    rooms = room_names() if getattr(args, "all", False) else [r.upper() for r in args.rooms]
    if not rooms:
        ap.error("no rooms given")
    ok = True
    if args.cmd == "patch":
        for name in rooms:
            ok &= write_patch(name, Path(args.out))
    elif args.cmd == "gen":
        arc = Archive()
        for name in rooms:
            ok &= generate(name, arc, args.force)
    else:
        for name in rooms:
            ok &= check(name)
        if ok and args.stamp:
            Path(args.stamp).parent.mkdir(parents=True, exist_ok=True)
            Path(args.stamp).touch()
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
