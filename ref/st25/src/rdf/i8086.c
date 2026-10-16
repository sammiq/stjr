/* i8086.c - the Amiga version's 8086 interpreter for the room scripts
 *
 * For reference only: this is not part of the DOS build. It is a hand
 * decompilation of the module "$Id: i8086.c,v 1.7 1993/08/24 20:56:39 Mark
 * Exp $" in the AGA executable (orig/AMIGA/.../data/StarTrek, a 68020 hunk
 * file with no symbols, dated 29 Nov 1993). All addresses are offsets into
 * its code hunk (hunk 0) or, for the globals, its data hunk (hunk 2).
 *
 * The Amiga port did not rewrite the room scripts: its .RDF files hold the
 * same x86 machine code as the DOS ones (see src/rdf/<room>.asm), with only the
 * Rdf header and the script chain's "next" words byte-swapped (and not even
 * the last one). CallScript (13A46) runs them with this interpreter:
 *
 *     base = LockMem(rdf_handle);
 *     i8086(base, (char *)entry - base, (unsigned char *)&room);
 *     UnlockMem(rdf_handle);
 *
 * It is a single function, 15912-19DCE, preceded in the code hunk by an
 * empty function (158B0, called before every error, presumably a debugging
 * hook compiled out) and its two strings; items.c follows at 19DD0.
 *
 * How it works:
 *  - The registers are globals, each a 4-byte Reg with the 16-bit value in
 *    the low half, so on the 68000 the low byte (AL etc.) is at +3. Only
 *    IP, SP and the general registers matter; DS/ES/SS can be pushed and
 *    popped but never take part in addressing.
 *  - Memory is three flat 64K windows: `code' (the RDF, x86 byte order),
 *    `data' (the RoomState, native 68000 byte order) and a 64-byte stack
 *    in this function's frame (native order, SP starts at 40h). A cs:/ss:/
 *    ds: prefix picks the window, ds: being the default; es: is illegal.
 *    Words read from or written to the code window are byte-swapped;
 *    nothing else is, so [si+field] reads RoomState words as they are.
 *  - Opcodes are dispatched twice. The first switch fetches the opcode,
 *    handles the simple instructions outright and, for ModRM ones, fills
 *    in up to three operand descriptors (kind << 4 | size). A common
 *    decoder then turns each descriptor into a pointer (ptr[]) and a cached
 *    value (val[]), and a second switch on the same opcode does the work.
 *  - Flags are computed lazily: an operation sets the result in `res' and
 *    marks which flags it affects (flags.upd_*); one of two tails (word or
 *    byte) then derives them. PF and AF are never computed.
 *  - "call far cs:[0]" (FF /3), the scripts' call to ScriptService, is not
 *    followed: up to 12 words are copied off the script stack and passed
 *    to the Amiga's ScriptService (13B32) as 12 longs; DX:AX gets the
 *    result. RETF (CB) at any depth ends the script.
 *  - Only what the DOS scripts use is implemented. Everything else - the
 *    string instructions, LEA/LES/LDS, segment moves, shifts by an
 *    immediate, IN/OUT, PUSHF/POPF, INT, ENTER/LEAVE, far jumps, the 0F
 *    two-byte opcodes (decoded but all rejected), and so on - ends in
 *    InternalError("Current script contains an illegal instruction..."),
 *    which ignores its message and shows "Internal Error: contact customer
 *    service --- from interpreter".
 *
 * Differences from a real 8086 (the scripts evidently never hit them):
 *  - Byte SUB r/m8,r8 and SUB r8,r/m8 (28, 2A) set the flags but write back
 *    the destination unchanged (the difference goes into val[1]).
 *  - SBB in its ModRM forms (18-1B, 80/3, 81/3, 83/3) adds the carry.
 *  - ADD, ADC, INC and DEC never set CF (the result is zero-extended before
 *    bit 8/16 is tested); NEG sets CF and then clears it the same way.
 *  - CMP r/m,r (38-3B), CMP r/m,imm (80/7, 81/7, 83/7) compare as signed
 *    numbers, so JB/JA after them are signed; CMP AL/AX,imm (3C, 3D) are
 *    unsigned. OF is "the result does not fit", not a true overflow.
 *  - An 8-bit ModRM displacement is not sign-extended ([bp-2] is bp+0FEh),
 *    while the A0-A3 moffs forms index with a signed 16-bit offset.
 *  - 83 /1, /4, /6 (OR/AND/XOR with imm8) zero-extend the immediate.
 *  - IMUL r16,r/m,imm8 (6B) uses whatever is in the high byte of val[2].
 *  - IMUL sets CF/OF when the product fits (69/6B), or when it is negative
 *    (F6/5, F7/5); CWD always clears DX; DIV/IDIV r/m16 divide AX only and
 *    word division by zero is silently skipped (byte division by zero is an
 *    error); POP SP sets SP to the popped word plus 2.
 *  - Shifts by CL do (CL - 1) & 31 then one more step for SHL/SHR, so CL=0
 *    shifts by 32; rotates/SAR by CL loop CL & 31 times and leave OF.
 *  - A descriptor kind the decoder does not handle (8, 9, C, E, F) leaves
 *    ptr[] stale, and the value cache still reads through it before the
 *    instruction is rejected.
 */

typedef union Reg {
    unsigned long d;                            /* also a 32-bit temporary */
    struct { unsigned short hi, x; } w;         /* the 16-bit register */
    struct { unsigned char b0, b1, h, l; } b;   /* its high and low bytes */
} Reg;

/* 7284-72C7. 7280 (CS?) is not referenced here. */
static Reg r_ds, r_es, r_ss;            /* 7284 7288 728C */
static Reg r_si, r_di;                  /* 7290 7294 */
static Reg r_ax, r_cx, r_dx, r_bx;      /* 7298 729C 72A0 72A4 */
static Reg r_bp, r_sp, r_ip;            /* 72A8 72AC 72B0 */
static Reg r_imm;                       /* 72B4 the last immediate fetched */
static Reg r_ea;                        /* 72B8 effective address; scratch */
static Reg val[3];                      /* 72BC the operands' values */

/* 727C: the 8086 FLAGS (SAS/C allocates bit fields from the top, so cf
 * is bit 31), then a mask in the same layout of the flags the current
 * instruction leaves to the flag tails to compute. */
static struct {
    unsigned cf:1, :1, pf:1, :1, af:1, :1, zf:1, sf:1,
             tf:1, ifl:1, df:1, of:1, :4;
    unsigned upd_cf:1, :5, upd_zf:1, upd_sf:1, :3, upd_of:1, :4;
} flags;
#define UPD_CLEAR()  (((unsigned short *)&flags)[1] = 0)

long ScriptService(long cmd, long a1, long a2, long a3, long a4, long a5,
                   long a6, long a7, long a8, long a9, long a10, long a11);
void InternalError(char *fmt, ...);                         /* 1C13A */

#define SWAP(w)     ((unsigned short)((unsigned short)(w) << 8 | (unsigned short)(w) >> 8))
#define CODE8()     (code[r_ip.w.x++])
#define CODE16()    (r_ip.w.x += 2, SWAP(*(unsigned short *)(code + r_ip.w.x - 2)))
#define IMM8()      (r_imm.b.l = CODE8())
#define IMM16()     (r_imm.w.x = CODE16())
#define W(p)        (*(unsigned short *)(p))
#define PUSH(v)     (r_sp.w.x -= 2, W(stack + r_sp.w.x) = (v))
#define POP()       (r_sp.w.x += 2, W(stack + r_sp.w.x - 2))
#define JUMP(cond)  do { signed char d = IMM8(); if (cond) r_ip.w.x += d; } while (0)

/* Operand descriptors: kind << 4 | size. */
#define D_RM    0x40    /* ModRM r/m */
#define D_REG   0x60    /* ModRM reg */
#define D_IMM   0x70    /* immediate */
#define D_MEM   0x90    /* memory only (LES/LDS/LSS, LEA): not decoded */
#define D_SREG  0xC0    /* ModRM reg as a segment register: not decoded */
#define D_SI    0xE0    /* string source: not decoded */
#define D_DI    0xF0    /* string destination: not decoded */
#define S_B     2       /* byte */
#define S_D     4       /* dword (far pointer): no value cached */
#define S_W     6       /* word */
#define S_WS    7       /* word, segment register */

/* 158B0: empty; called before each illegal-instruction error. */
static void Trace(void)
{
}

static unsigned char *Reg8(int n)       /* AL CL DL BL AH CH DH BH */
{
    static Reg *r[4] = { &r_ax, &r_cx, &r_dx, &r_bx };
    return n < 4 ? &r[n]->b.l : &r[n - 4]->b.h;
}

static unsigned char *Reg16(int n)      /* AX CX DX BX SP BP SI DI */
{
    static Reg *r[8] = { &r_ax, &r_cx, &r_dx, &r_bx, &r_sp, &r_bp, &r_si, &r_di };
    return (unsigned char *)&r[n]->w.x;
}

/* 15912 */
void i8086(unsigned char *code, unsigned short ip, unsigned char *data)
{
    unsigned char *mem;                 /* a3: the window [ea] addresses */
    unsigned char *seg;                 /* $B0: segment prefix, or 0 */
    unsigned char *default_seg;         /* $2C: always 0 */
    unsigned char rep;                  /* $AC: F0/F2/F3 prefix, unused */
    unsigned char op, op2, modrm;       /* $B4 $B5 $B6 */
    unsigned char desc[3];              /* $C0 */
    unsigned char *ptr[3];              /* $C4 */
    unsigned char incode[3];            /* $D0: ptr[i] is in the code */
    unsigned char stack[0x40];          /* $6C */
    unsigned short args[12];            /* $54 */
    long res;                           /* d7: the result, for the flags */
    long n, i;

    r_ip.w.x = ip;
    r_sp.w.x = 0x40;
    default_seg = 0;
    goto next;

prefix:                                                         /* 15938 */
    if (seg)
        mem = seg;
    op = CODE8();
    switch (op) {
    case 0x00: case 0x08: case 0x10: case 0x18:                 /* 15B6E */
    case 0x20: case 0x28: case 0x30: case 0x38:
    case 0x84: case 0x86: case 0x88:
        modrm = CODE8();
        desc[0] = D_RM | S_B;
        desc[1] = D_REG | S_B;
        goto decode;
    case 0x01: case 0x09: case 0x11: case 0x19:                 /* 15B92 */
    case 0x21: case 0x29: case 0x31: case 0x39:
    case 0x85: case 0x87: case 0x89:
        modrm = CODE8();
        desc[0] = D_RM | S_W;
        desc[1] = D_REG | S_W;
        goto decode;
    case 0x02: case 0x0A: case 0x12: case 0x1A:                 /* 15BB6 */
    case 0x22: case 0x2A: case 0x32: case 0x3A: case 0x8A:
        modrm = CODE8();
        desc[0] = D_REG | S_B;
        desc[1] = D_RM | S_B;
        goto decode;
    case 0x03: case 0x0B: case 0x13: case 0x1B:                 /* 15BDA */
    case 0x23: case 0x2B: case 0x33: case 0x3B: case 0x8B:
        modrm = CODE8();
        desc[0] = D_REG | S_W;
        desc[1] = D_RM | S_W;
        goto decode;

    /* ALU AL,imm8 */
    case 0x04:                                                  /* 15BFE */
        r_ax.b.l += IMM8();
        res = r_ax.b.l;
        flags.upd_cf = 1;
        flags.upd_of = 1;
        goto byte_flags;
    case 0x0C:                                                  /* 15C38 */
        r_ax.b.l |= IMM8();
        res = r_ax.b.l;
        flags.cf = 0;
        flags.of = 0;
        goto byte_flags;
    case 0x14:                                                  /* 15C72 */
        IMM8();
        r_ax.b.l = r_ax.b.l + flags.cf + r_imm.b.l;
        res = r_ax.b.l;
        flags.upd_cf = 1;
        flags.upd_of = 1;
        goto byte_flags;
    case 0x1C:                                                  /* 15CBA */
        IMM8();
        r_ax.b.l = r_ax.b.l - flags.cf - r_imm.b.l;
        res = r_ax.b.l;
        flags.upd_cf = 1;
        flags.upd_of = 1;
        goto byte_flags;
    case 0x24:                                                  /* 15D02 */
        r_ax.b.l &= IMM8();
        res = r_ax.b.l;
        flags.cf = 0;
        flags.of = 0;
        goto byte_flags;
    case 0x2C:                                                  /* 15D3C */
        r_ax.b.l -= IMM8();
        res = r_ax.b.l;
        flags.upd_cf = 1;
        flags.upd_of = 1;
        goto byte_flags;
    case 0x34:                                                  /* 15D76 */
        r_ax.b.l ^= IMM8();
        res = r_ax.b.l;
        flags.cf = 0;
        flags.of = 0;
        goto byte_flags;
    case 0x3C:                                                  /* 15DB0 */
        IMM8();
        res = (long)r_ax.b.l - (long)r_imm.b.l;         /* unsigned */
        flags.upd_cf = 1;
        flags.upd_of = 1;
        goto byte_flags;

    /* ALU AX,imm16 */
    case 0x05:                                                  /* 15DEC */
        r_ax.w.x += IMM16();
        res = r_ax.w.x;
        flags.upd_cf = flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
        goto word_flags;
    case 0x0D:                                                  /* 15E46 */
        r_ax.w.x |= IMM16();
        res = r_ax.w.x;
        flags.cf = 0;
        flags.of = 0;
        flags.upd_zf = flags.upd_sf = 1;
        goto word_flags;
    case 0x15:                                                  /* 15EA0 */
        IMM16();
        r_ax.w.x = (unsigned short)(r_ax.w.x + r_imm.w.x) + flags.cf;
        res = r_ax.w.x;
        flags.upd_cf = flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
        goto word_flags;
    case 0x1D:                                                  /* 15F0C */
        IMM16();
        r_ax.w.x = (unsigned short)(r_ax.w.x - r_imm.w.x) - flags.cf;
        res = r_ax.w.x;
        flags.upd_cf = flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
        goto word_flags;
    case 0x25:                                                  /* 15F78 */
        r_ax.w.x &= IMM16();
        res = r_ax.w.x;
        flags.cf = 0;
        flags.of = 0;
        flags.upd_zf = flags.upd_sf = 1;
        goto word_flags;
    case 0x2D:                                                  /* 15FD2 */
        r_ax.w.x -= IMM16();
        res = r_ax.w.x;
        flags.upd_cf = flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
        goto word_flags;
    case 0x35:                                                  /* 1602C */
        r_ax.w.x ^= IMM16();
        res = r_ax.w.x;
        flags.cf = 0;
        flags.of = 0;
        flags.upd_zf = flags.upd_sf = 1;
        goto word_flags;
    case 0x3D:                                                  /* 16086 */
        IMM16();
        res = (long)r_ax.w.x - (long)r_imm.w.x;         /* unsigned */
        flags.upd_cf = flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
        goto word_flags;

    /* 0F xx: 286/386 two-byte opcodes. Some set up operands (IMUL r,r/m;
     * LSS; BT/BTS/BTR/BTC; BSF/BSR), but the second switch rejects them
     * all (case 0x0F below). */
    case 0x0F:                                                  /* 160E2 */
        op2 = CODE8();
        switch (op2) {
        case 0x00: case 0x01: case 0x02: case 0x03:
        case 0x20: case 0x21: case 0x22: case 0x23: case 0x24: case 0x26:
        case 0x80: case 0x81: case 0x82: case 0x83: case 0x84: case 0x85:
        case 0x86: case 0x87: case 0x88: case 0x89: case 0x8A: case 0x8B:
        case 0x8C: case 0x8D: case 0x8E: case 0x8F:
        case 0x90: case 0x91: case 0x92: case 0x93: case 0x94: case 0x95:
        case 0x96: case 0x97: case 0x98: case 0x99: case 0x9A: case 0x9B:
        case 0x9C: case 0x9D: case 0x9E: case 0x9F: case 0xA0: case 0xA1:
        case 0xA3: case 0xA4: case 0xA5: case 0xA8: case 0xA9: case 0xAB:
        case 0xAC: case 0xAD: case 0xB3: case 0xB4: case 0xB5: case 0xB6:
        case 0xB7: case 0xBE: case 0xBF:
            Trace();
            goto illegal;
        case 0xAF:                                      /* IMUL r16,r/m16 */
            modrm = CODE8();
            desc[0] = D_REG | S_W;
            desc[1] = D_RM | S_W;
            break;
        case 0xB2:                                      /* LSS */
            modrm = CODE8();
            desc[0] = D_REG | S_W;
            desc[1] = D_MEM | 4;
            break;
        case 0xBA:                                      /* BT group, imm8 */
            modrm = CODE8();
            switch (modrm >> 3 & 7) {
            case 4: case 5: case 6: case 7:
                desc[0] = D_RM | S_W;
                desc[1] = D_IMM | S_B;
            }
            break;
        case 0xBB:                                      /* BTC */
            modrm = CODE8();
            desc[0] = D_RM | S_W;
            desc[1] = D_REG | S_W;
            break;
        case 0xBC: case 0xBD:                           /* BSF, BSR */
            modrm = CODE8();
            desc[0] = D_REG | S_W;
            desc[1] = D_RM | S_W;
            break;
        }
        goto decode;

    case 0x06: PUSH(r_es.w.x); goto next;                       /* 1637A */
    case 0x07: r_es.w.x = POP(); goto next;                     /* 16396 */
    case 0x16: PUSH(r_ss.w.x); goto next;                       /* 163B2 */
    case 0x17: r_ss.w.x = POP(); goto next;                     /* 163CE */
    case 0x1E: PUSH(r_ds.w.x); goto next;                       /* 163EA */
    case 0x1F: r_ds.w.x = POP(); goto next;                     /* 16406 */

    case 0x26:                                  /* es: */       /* 1688E */
    case 0x27: case 0x2F: case 0x37: case 0x3F: /* DAA DAS AAA AAS */
        Trace();
        goto illegal;
    case 0x2E: seg = code; goto prefix;         /* cs: */       /* 16896 */
    case 0x36: seg = stack; goto prefix;        /* ss: */       /* 1689E */
    case 0x3E: seg = data; goto prefix;         /* ds: */       /* 168AA */

    /* INC/DEC/PUSH/POP r16 (16422-16882) */
    case 0x40: case 0x41: case 0x42: case 0x43:
    case 0x44: case 0x45: case 0x46: case 0x47:
        res = ++W(Reg16(op & 7));
        flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
        goto word_flags;
    case 0x48: case 0x49: case 0x4A: case 0x4B:
    case 0x4C: case 0x4D: case 0x4E: case 0x4F:
        res = --W(Reg16(op & 7));
        flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
        goto word_flags;
    case 0x50: case 0x51: case 0x52: case 0x53:
    case 0x55: case 0x56: case 0x57:
        PUSH(W(Reg16(op & 7)));
        goto next;
    case 0x54:                                  /* PUSH SP */   /* 166AE */
        r_sp.w.x -= 2;
        W(stack + r_sp.w.x) = r_sp.w.x;
        goto next;
    case 0x58: case 0x59: case 0x5A: case 0x5B:
    case 0x5D: case 0x5E: case 0x5F:
        W(Reg16(op & 7)) = POP();
        goto next;
    case 0x5C:                                  /* POP SP */    /* 166C6 */
        r_sp.w.x = W(stack + r_sp.w.x) + 2;
        goto next;

    case 0x60: case 0x61: case 0x62: case 0x63:                 /* 16886 */
    case 0x64: case 0x65: case 0x66: case 0x67:                 /* 168B2 */
        Trace();
        goto illegal;
    case 0x68:                                  /* PUSH imm16 */ /* 168BA */
        PUSH(IMM16());
        goto next;
    case 0x69:                                  /* IMUL r,r/m,imm16 */
        modrm = CODE8();
        desc[0] = D_REG | S_W;
        desc[1] = D_RM | S_W;
        desc[2] = D_IMM | S_W;
        goto decode;
    case 0x6A:                                  /* PUSH imm8 */ /* 16922 */
        r_ea.b.l = CODE8();
        r_imm.w.x = (signed char)r_ea.b.l;
        PUSH(r_imm.w.x);
        goto next;
    case 0x6B:                                  /* IMUL r,r/m,imm8 */
        modrm = CODE8();
        desc[0] = D_REG | S_W;
        desc[1] = D_RM | S_W;
        desc[2] = D_IMM | S_B;
        goto decode;
    case 0x6C: case 0x6D: case 0x6E: case 0x6F:                 /* 16982 */
        Trace();
        goto illegal;

    /* Jcc rel8 (1698A-16D92) */
    case 0x70: JUMP(flags.of); goto next;
    case 0x71: JUMP(!flags.of); goto next;
    case 0x72: JUMP(flags.cf); goto next;
    case 0x73: JUMP(!flags.cf); goto next;
    case 0x74: JUMP(flags.zf); goto next;
    case 0x75: JUMP(!flags.zf); goto next;
    case 0x76: JUMP(flags.cf || flags.zf); goto next;
    case 0x77: JUMP(!flags.cf && !flags.zf); goto next;
    case 0x78: JUMP(flags.sf); goto next;
    case 0x79: JUMP(!flags.sf); goto next;
    case 0x7A: JUMP(flags.pf); goto next;               /* PF is never set */
    case 0x7B: JUMP(!flags.pf); goto next;
    case 0x7C: JUMP(flags.of != flags.sf); goto next;
    case 0x7D: JUMP(flags.of == flags.sf); goto next;
    case 0x7E: JUMP(flags.zf || flags.of != flags.sf); goto next;
    case 0x7F: JUMP(!flags.zf && flags.of == flags.sf); goto next;

    case 0x80:                                                  /* 16D96 */
        modrm = CODE8();
        desc[0] = D_RM | S_B;
        desc[1] = D_IMM | S_B;
        goto decode;
    case 0x81:                                                  /* 16DBA */
        modrm = CODE8();
        desc[0] = D_RM | S_W;
        desc[1] = D_IMM | S_W;
        goto decode;
    case 0x82:                                                  /* 16DDE */
        Trace();
        goto illegal;
    case 0x83:                                                  /* 16DE6 */
        modrm = CODE8();
        desc[0] = D_RM | S_W;
        desc[1] = D_IMM | S_B;
        goto decode;
    case 0x8C:                                  /* MOV r/m,sreg */
        modrm = CODE8();
        desc[0] = D_RM | S_WS;
        desc[1] = D_SREG | S_WS;
        goto decode;
    case 0x8D:                                  /* LEA */
        modrm = CODE8();
        desc[0] = D_REG | S_W;
        desc[1] = D_MEM | S_W;
        goto decode;
    case 0x8E:                                  /* MOV sreg,r/m */
        modrm = CODE8();
        desc[0] = D_SREG | S_WS;
        desc[1] = D_RM | S_WS;
        goto decode;
    case 0x8F:                                  /* POP r/m */
        modrm = CODE8();
        desc[0] = D_RM | S_W;
        goto decode;

    case 0x90:                                  /* NOP */
        goto next;
    case 0x91: case 0x92: case 0x93:            /* XCHG AX,r16 */
    case 0x94: case 0x95: case 0x96: case 0x97: /* 16E94-16F70 */
        r_ea.w.x = r_ax.w.x;
        r_ax.w.x = W(Reg16(op & 7));
        W(Reg16(op & 7)) = r_ea.w.x;
        goto next;
    case 0x98:                                  /* CBW */       /* 16F74 */
        r_ax.w.x = (signed char)r_ax.b.l;
        goto next;
    case 0x99:                                  /* CWD */       /* 16F86 */
        r_ea.d = r_ax.w.x;
        r_dx.w.x = 0;                   /* the high word of the above */
        goto next;
    case 0x9A: case 0x9B: case 0x9C: case 0x9D: case 0x9E: case 0x9F:
        Trace();
        goto illegal;

    /* MOV AL/AX <-> moffs16 (16FAA-1709E) */
    case 0xA0:
        n = (short)CODE16();
        r_ax.b.l = mem[n];
        goto next;
    case 0xA1:
        n = (short)CODE16();
        r_ax.w.x = W(mem + n);
        if (mem == code)
            r_ax.w.x = SWAP(r_ax.w.x);
        goto next;
    case 0xA2:
        n = (short)CODE16();
        mem[n] = r_ax.b.l;
        goto next;
    case 0xA3:
        n = (short)CODE16();
        r_ea.w.x = r_ax.w.x;
        if (mem == code)
            r_ea.w.x = SWAP(r_ea.w.x);
        W(mem + n) = r_ea.w.x;
        goto next;

    /* String instructions: rejected after decoding */
    case 0xA4: case 0xA6:                       /* MOVSB CMPSB */
        desc[0] = D_SI | S_B;
        desc[1] = D_DI | S_B;
        goto decode;
    case 0xA5: case 0xA7:                       /* MOVSW CMPSW */
        desc[0] = D_SI | S_W;
        desc[1] = D_DI | S_W;
        goto decode;
    case 0xAA: desc[0] = D_DI | S_B; goto decode;       /* STOSB */
    case 0xAB: desc[0] = D_DI | S_W; goto decode;       /* STOSW */
    case 0xAC: case 0xAE: desc[0] = D_SI | S_B; goto decode;
    case 0xAD: case 0xAF: desc[0] = D_SI | S_W; goto decode;

    case 0xA8:                                  /* TEST AL,imm8 */
        res = r_ax.b.l & IMM8();
        flags.cf = 0;
        flags.of = 0;
        goto byte_flags;
    case 0xA9:                                  /* TEST AX,imm16 */
        res = r_ax.w.x & IMM16();
        flags.cf = 0;
        flags.of = 0;
        flags.upd_zf = flags.upd_sf = 1;
        goto word_flags;

    /* MOV r,imm (171AE-173DA); these do not go through r_imm */
    case 0xB0: case 0xB1: case 0xB2: case 0xB3:
    case 0xB4: case 0xB5: case 0xB6: case 0xB7:
        *Reg8(op & 7) = CODE8();
        goto next;
    case 0xB8: case 0xB9: case 0xBA: case 0xBB:
    case 0xBC: case 0xBD: case 0xBE: case 0xBF:
        W(Reg16(op & 7)) = CODE16();
        goto next;

    case 0xC0:                                  /* shifts by imm8 */
        modrm = CODE8();
        desc[0] = D_RM | S_B;
        desc[1] = D_IMM | S_B;
        goto decode;
    case 0xC1:
        modrm = CODE8();
        desc[0] = D_RM | S_W;
        desc[1] = D_IMM | S_B;
        goto decode;
    case 0xC2:                                  /* RET imm16 */ /* 17426 */
        IMM16();
        r_ip.w.x = POP();
        r_sp.w.x += r_imm.w.x;
        goto next;
    case 0xC3:                                  /* RET */       /* 17470 */
        r_ip.w.x = POP();
        goto next;
    case 0xC4: case 0xC5:                       /* LES LDS */
        modrm = CODE8();
        desc[0] = D_REG | S_W;
        desc[1] = D_MEM | 4;
        goto decode;
    case 0xC6:                                  /* MOV r/m8,imm8 */
        modrm = CODE8();
        desc[0] = D_RM | S_B;
        desc[1] = D_IMM | S_B;
        goto decode;
    case 0xC7:                                  /* MOV r/m16,imm16 */
        modrm = CODE8();
        desc[0] = D_RM | S_W;
        desc[1] = D_IMM | S_W;
        goto decode;
    case 0xC8: case 0xC9: case 0xCA:
    case 0xCC: case 0xCD: case 0xCE: case 0xCF:
        Trace();
        goto illegal;
    case 0xCB:                                  /* RETF: the end */
        return;

    case 0xD0: case 0xD2:                                       /* 17508 */
        modrm = CODE8();
        desc[0] = D_RM | S_B;
        goto decode;
    case 0xD1: case 0xD3:                                       /* 17526 */
        modrm = CODE8();
        desc[0] = D_RM | S_W;
        goto decode;
    case 0xD4: case 0xD5: case 0xD6: case 0xD7:
    case 0xD8: case 0xD9: case 0xDA: case 0xDB:
    case 0xDC: case 0xDD: case 0xDE: case 0xDF:
        Trace();
        goto illegal;

    case 0xE0: case 0xE1: case 0xE2:            /* LOOPNZ LOOPZ LOOP */
        r_ea.b.l = --r_cx.w.x != 0;                             /* 1754C */
        IMM8();
        if (op != 0xE2)
            r_ea.b.l &= op == 0xE0 ? !flags.zf : flags.zf;
        if (r_ea.b.l)
            r_ip.w.x += (signed char)r_imm.b.l;
        goto next;
    case 0xE3:                                  /* JCXZ */      /* 175CA */
        JUMP(r_cx.w.x == 0);
        goto next;
    case 0xE4: case 0xE5: case 0xE6: case 0xE7:
        Trace();
        goto illegal;
    case 0xE8:                                  /* CALL rel16 */ /* 1760C */
        IMM16();
        PUSH(r_ip.w.x);
        r_ip.w.x += r_imm.w.x;
        goto next;
    case 0xE9:                                  /* JMP rel16 */ /* 17656 */
        IMM16();
        r_ip.w.x += r_imm.w.x;
        goto next;
    case 0xEA:
        Trace();
        goto illegal;
    case 0xEB:                                  /* JMP rel8 */  /* 17690 */
        JUMP(1);
        goto next;
    case 0xEC: case 0xED: case 0xEE: case 0xEF: case 0xF1: case 0xF4:
        Trace();
        goto illegal;
    case 0xF0: case 0xF2: case 0xF3:            /* LOCK REPNZ REP */
        rep = op;
        goto prefix;
    case 0xF5:                                  /* CMC */
        flags.cf ^= 1;
        goto next;
    case 0xF6:                                                  /* 176EC */
        modrm = CODE8();
        desc[0] = D_RM | S_B;
        switch (modrm >> 3 & 7) {
        case 0:
            desc[1] = D_IMM | S_B;
            break;
        case 1:
            Trace();
            goto illegal;
        }
        goto decode;
    case 0xF7:                                                  /* 17740 */
        modrm = CODE8();
        desc[0] = D_RM | S_W;
        switch (modrm >> 3 & 7) {
        case 0:
            desc[1] = D_IMM | S_W;
            break;
        case 1:
            Trace();
            goto illegal;
        }
        goto decode;
    case 0xF8: flags.cf = 0; goto next;         /* CLC */
    case 0xF9: flags.cf = 1; goto next;         /* STC */
    case 0xFA: case 0xFB:                       /* CLI STI */
        Trace();
        goto illegal;
    case 0xFC: flags.df = 0; goto next;         /* CLD */
    case 0xFD: flags.df = 1; goto next;         /* STD */
    case 0xFE:                                                  /* 177CC */
        modrm = CODE8();
        desc[0] = D_RM | S_B;
        goto decode;
    case 0xFF:                                                  /* 177E8 */
        modrm = CODE8();
        switch (modrm >> 3 & 7) {
        case 0: case 1: case 2: case 4: case 6:
            desc[0] = D_RM | S_W;
            break;
        case 3: case 5:                         /* far: CALL/JMP m16:16 */
            desc[0] = D_RM | S_D;
            break;
        case 7:
            Trace();
            goto illegal;
        }
        goto decode;
    default:                                    /* 0E (PUSH CS) */
        goto decode;
    }

    /* The operands (1783A). The first empty descriptor ends the list. */
decode:
    for (i = 0; i < 3; i++) {
        int size;

        if (desc[i] == 0)
            break;
        size = desc[i] & 15;
        switch (desc[i] >> 4) {
        case D_RM >> 4:
            switch (modrm >> 6) {
            case 0:
                switch (modrm & 7) {
                case 0: r_ea.w.x = r_bx.w.x + r_si.w.x; break;
                case 1: r_ea.w.x = r_bx.w.x + r_di.w.x; break;
                case 2: r_ea.w.x = r_bp.w.x + r_si.w.x; break;
                case 3: r_ea.w.x = r_bp.w.x + r_di.w.x; break;
                case 4: r_ea.w.x = r_si.w.x; break;
                case 5: r_ea.w.x = r_di.w.x; break;
                case 6: r_ea.w.x = CODE16(); break;
                case 7: r_ea.w.x = r_bx.w.x; break;
                }
                ptr[i] = mem + r_ea.w.x;
                if (mem == code)
                    incode[i] = 1;
                break;
            case 1:
            case 2:
                if ((modrm >> 6) == 1) {
                    r_ea.w.x = 0;
                    r_ea.b.l = CODE8();         /* not sign-extended */
                } else
                    r_ea.w.x = CODE16();
                switch (modrm & 7) {
                case 0: r_ea.w.x += r_bx.w.x + r_si.w.x; break;
                case 1: r_ea.w.x += r_bx.w.x + r_di.w.x; break;
                case 2: r_ea.w.x += r_bp.w.x + r_si.w.x; break;
                case 3: r_ea.w.x += r_bp.w.x + r_di.w.x; break;
                case 4: r_ea.w.x += r_si.w.x; break;
                case 5: r_ea.w.x += r_di.w.x; break;
                case 6: r_ea.w.x += r_bp.w.x; break;
                case 7: r_ea.w.x += r_bx.w.x; break;
                }
                ptr[i] = mem + r_ea.w.x;
                if (mem == code)
                    incode[i] = 1;
                break;
            case 3:
                ptr[i] = size == S_B ? Reg8(modrm & 7) : Reg16(modrm & 7);
                break;
            }
            break;
        case D_REG >> 4:
            n = modrm >> 3 & 7;
            ptr[i] = size == S_B ? Reg8(n) : Reg16(n);
            break;
        case D_IMM >> 4:
            if (size == S_B) {
                IMM8();
                ptr[i] = &r_imm.b.l;
            } else if (size == S_W || size == S_WS) {
                IMM16();
                ptr[i] = (unsigned char *)&r_imm.w.x;
            }
            break;
        }
        if (size == S_B)                                        /* 17E28 */
            val[i].b.l = *ptr[i];
        else if (size == S_W || size == S_WS) {
            val[i].w.x = W(ptr[i]);
            if (incode[i])
                val[i].w.x = SWAP(val[i].w.x);
        }
    }

    /* The operation (17E88). */
    switch (op) {
    case 0x00: case 0x02:                       /* ADD r/m8 */  /* 180A0 */
        val[0].b.l += val[1].b.l;
        res = val[0].b.l;
        *ptr[0] = val[0].b.l;
        flags.upd_cf = flags.upd_of = 1;
        goto byte_flags;
    case 0x01: case 0x03:                       /* ADD r/m16 */ /* 180D4 */
        val[0].w.x += val[1].w.x;
        res = val[0].w.x;
        goto store_word_all;
    case 0x08: case 0x0A:                       /* OR */        /* 18134 */
        val[0].b.l |= val[1].b.l;
        res = val[0].b.l;
        *ptr[0] = val[0].b.l;
        flags.cf = 0;
        flags.of = 0;
        goto byte_flags;
    case 0x09: case 0x0B:                                       /* 18166 */
        val[0].w.x |= val[1].w.x;
        res = val[0].w.x;
        flags.cf = 0;
        flags.of = 0;
        goto store_word_zs;
    case 0x0F:                                                  /* 181CA */
        /* checks for 0F 02, 03, A3, AB, AF, B2, B3, BA /4-7, BB-BF, and
         * rejects every one of them */
        goto bad_op;
    case 0x10: case 0x12:                       /* ADC */       /* 18242 */
        val[0].b.l = val[0].b.l + val[1].b.l + flags.cf;
        res = val[0].b.l;
        *ptr[0] = val[0].b.l;
        flags.upd_cf = flags.upd_of = 1;
        goto byte_flags;
    case 0x11: case 0x13:                                       /* 1827E */
        val[0].w.x = val[0].w.x + val[1].w.x + flags.cf;
        res = val[0].w.x;
        goto store_word_all;
    case 0x18: case 0x1A:                       /* SBB: + CF */ /* 182E6 */
        val[0].b.l = val[0].b.l - val[1].b.l + flags.cf;
        res = val[0].b.l;
        *ptr[0] = val[0].b.l;
        flags.upd_cf = flags.upd_of = 1;
        goto byte_flags;
    case 0x19: case 0x1B:                                       /* 18322 */
        val[0].w.x = val[0].w.x - val[1].w.x + flags.cf;
        res = val[0].w.x;
        goto store_word_all;
    case 0x20: case 0x22:                       /* AND */       /* 1838A */
        val[0].b.l &= val[1].b.l;
        res = val[0].b.l;
        *ptr[0] = val[0].b.l;
        flags.cf = 0;
        flags.of = 0;
        goto byte_flags;
    case 0x21: case 0x23:                                       /* 183BC */
        val[0].w.x &= val[1].w.x;
        res = val[0].w.x;
        flags.cf = 0;
        flags.of = 0;
        goto store_word_zs;
    case 0x28: case 0x2A:                       /* SUB */       /* 18420 */
        n = val[0].b.l;
        val[1].b.l = n - val[1].b.l;            /* sic */
        res = val[1].b.l;
        *ptr[0] = n;                            /* unchanged */
        flags.upd_cf = flags.upd_of = 1;
        goto byte_flags;
    case 0x29: case 0x2B:                                       /* 18454 */
        val[0].w.x -= val[1].w.x;
        res = val[0].w.x;
        goto store_word_all;
    case 0x30: case 0x32:                       /* XOR */       /* 184B4 */
        val[0].b.l ^= val[1].b.l;
        res = val[0].b.l;
        *ptr[0] = val[0].b.l;
        flags.cf = 0;
        flags.of = 0;
        goto byte_flags;
    case 0x31: case 0x33:                                       /* 184E6 */
        val[0].w.x ^= val[1].w.x;
        res = val[0].w.x;
        flags.cf = 0;
        flags.of = 0;
        goto store_word_zs;
    case 0x38: case 0x3A:                       /* CMP: signed */ /* 1854A */
        res = (long)(signed char)val[0].b.l - (signed char)val[1].b.l;
        flags.upd_cf = flags.upd_of = 1;
        goto byte_flags;
    case 0x39: case 0x3B:                                       /* 18576 */
        res = (long)(short)val[0].w.x - (short)val[1].w.x;
        flags.upd_cf = flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
        goto word_flags;

    case 0x69: case 0x6B:                       /* IMUL r,r/m,imm */
        /* 6B reads the whole word of val[2], of which only the low byte
         * was fetched */
        r_ea.d = (long)(short)val[2].w.x * (short)val[1].w.x;  /* 185AE */
        W(ptr[0]) = r_ea.w.x;
        flags.cf = flags.of = (long)r_ea.d == (long)r_ea.w.x;
        goto next;

    case 0x80:                                                  /* 185F6 */
        switch (modrm >> 3 & 7) {
        case 0: val[0].b.l += val[1].b.l; break;
        case 1: val[0].b.l |= val[1].b.l; break;
        case 2: val[0].b.l = val[0].b.l + val[1].b.l + flags.cf; break;
        case 3: val[0].b.l = val[0].b.l - val[1].b.l + flags.cf; break;
        case 4: val[0].b.l &= val[1].b.l; break;
        case 5: val[0].b.l -= val[1].b.l; break;
        case 6: val[0].b.l ^= val[1].b.l; break;
        case 7:
            res = (long)(signed char)val[0].b.l - (signed char)val[1].b.l;
            flags.upd_cf = flags.upd_of = 1;
            goto byte_flags;
        }
        res = val[0].b.l;
        *ptr[0] = val[0].b.l;                                   /* 18712 */
        flags.upd_cf = flags.upd_of = 1;
        goto byte_flags;
    case 0x81:                                                  /* 18730 */
        switch (modrm >> 3 & 7) {
        case 0: val[0].w.x += val[1].w.x; break;
        case 1: val[0].w.x |= val[1].w.x; break;
        case 2: val[0].w.x = val[0].w.x + val[1].w.x + flags.cf; break;
        case 3: val[0].w.x = val[0].w.x - val[1].w.x + flags.cf; break;
        case 4: val[0].w.x &= val[1].w.x; break;
        case 5: val[0].w.x -= val[1].w.x; break;
        case 6: val[0].w.x ^= val[1].w.x; break;
        case 7:
            res = (long)(short)val[0].w.x - (short)val[1].w.x;
            flags.upd_cf = flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
            goto word_flags;
        }
        res = val[0].w.x;
        goto store_word_all;                                    /* 1885A */
    case 0x83:                                                  /* 188AA */
        switch (modrm >> 3 & 7) {
        case 0: val[0].w.x = (short)val[0].w.x + (signed char)val[1].b.l; break;
        case 1: val[0].w.x |= val[1].b.l; break;
        case 2: val[0].w.x = (short)val[0].w.x + (signed char)val[1].b.l + flags.cf; break;
        case 3: val[0].w.x = (short)val[0].w.x - (signed char)val[1].b.l + flags.cf; break;
        case 4: val[0].w.x &= val[1].b.l; break;
        case 5: val[0].w.x = (short)val[0].w.x - (signed char)val[1].b.l; break;
        case 6: val[0].w.x ^= val[1].b.l; break;
        case 7:
            res = (long)(short)val[0].w.x - (signed char)val[1].b.l;
            flags.upd_cf = flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
            goto word_flags;
        }
        res = val[0].w.x;
        goto store_word_all;                                    /* 18A06 */

    case 0x84:                                  /* TEST */      /* 18A56 */
        res = val[0].b.l & val[1].b.l;
        flags.cf = 0;
        flags.of = 0;
        goto byte_flags;
    case 0x85:                                                  /* 18A7A */
        res = val[0].w.x & val[1].w.x;
        flags.cf = 0;
        flags.of = 0;
        flags.upd_zf = flags.upd_sf = 1;
        goto word_flags;
    case 0x86:                                  /* XCHG */      /* 18AAE */
        *ptr[0] = val[1].b.l;
        *ptr[1] = val[0].b.l;
        goto next;
    case 0x87:                                                  /* 18AC6 */
        if (incode[0])
            val[1].w.x = SWAP(val[1].w.x);
        W(ptr[0]) = val[1].w.x;
        if (incode[1])
            val[0].w.x = SWAP(val[0].w.x);
        W(ptr[1]) = val[0].w.x;
        goto next;
    case 0x88: case 0x8A:                       /* MOV */       /* 18B22 */
    case 0xC6:                                                  /* 18BF0 */
        *ptr[0] = val[1].b.l;
        goto next;
    case 0x89: case 0x8B:                                       /* 18B30 */
    case 0xC7:                                                  /* 18BFE */
        if (incode[0])
            val[1].w.x = SWAP(val[1].w.x);
        W(ptr[0]) = val[1].w.x;
        goto next;
    case 0x8F:                                  /* POP r/m */   /* 18B60 */
        r_ea.w.x = POP();
        if (incode[0])
            r_ea.w.x = SWAP(r_ea.w.x);
        W(ptr[0]) = r_ea.w.x;
        goto next;
    case 0xC0: case 0xC1:                       /* every /n rejected */
        goto bad_op;

    case 0xD0:                                  /* shift r/m8,1 */ /* 18C2E */
        n = val[0].b.l;
        switch (modrm >> 3 & 7) {
        case 0:                                 /* ROL */
            i = n >> 7 & 1;
            flags.cf = i;
            val[0].b.l = n << 1 | i;
            flags.of = (val[0].b.l >> 7) ^ i;
            *ptr[0] = val[0].b.l;
            goto next;
        case 1:                                 /* ROR */
            i = n & 1;
            flags.cf = i;
            val[0].b.l = n >> 1 | i << 7;
            flags.of = (val[0].b.l >> 6 & 1) ^ (val[0].b.l >> 7 & 1);
            *ptr[0] = val[0].b.l;
            goto next;
        case 2:                                 /* RCL */
            r_ea.b.l = flags.cf;
            i = n >> 7 & 1;
            flags.cf = i;
            val[0].b.l = n << 1 | r_ea.b.l;
            flags.of = (val[0].b.l >> 7) ^ i;
            *ptr[0] = val[0].b.l;
            goto next;
        case 3:                                 /* RCR */
            r_ea.b.l = flags.cf;
            flags.cf = n;
            val[0].b.l = r_ea.b.l << 7 | n >> 1;
            flags.of = (val[0].b.l >> 6 & 1) ^ (val[0].b.l >> 7 & 1);
            *ptr[0] = val[0].b.l;
            goto next;
        case 4:                                 /* SHL */
            i = n >> 7 & 1;
            flags.cf = i;
            val[0].b.l = n << 1;
            res = val[0].b.l;
            flags.of = (val[0].b.l >> 7) ^ i;
            *ptr[0] = val[0].b.l;
            goto byte_flags;
        case 5:                                 /* SHR */
            flags.cf = n;
            flags.of = n >> 7;
            val[0].b.l = n >> 1;
            res = val[0].b.l;
            *ptr[0] = val[0].b.l;
            goto byte_flags;
        case 7:                                 /* SAR */
            flags.cf = n;
            flags.of = 0;
            r_ea.b.l = n & 0x80;
            val[0].b.l = n >> 1 | r_ea.b.l;
            res = val[0].b.l;
            *ptr[0] = val[0].b.l;
            goto byte_flags;
        }
        goto bad_op;
    case 0xD1:                                  /* shift r/m16,1 */ /* 18E36 */
        n = val[0].w.x;
        switch (modrm >> 3 & 7) {
        case 0:                                 /* ROL */
            i = n >> 15 & 1;
            flags.cf = i;
            val[0].w.x = n << 1 | i;
            flags.of = (val[0].w.x >> 15) ^ i;
            goto store_word;
        case 1:                                 /* ROR */
            i = n & 1;
            flags.cf = i;
            val[0].w.x = n >> 1 | i << 15;
            flags.of = (val[0].w.x >> 14 & 1) ^ (val[0].w.x >> 15 & 1);
            goto store_word;
        case 2:                                 /* RCL */
            r_ea.w.x = flags.cf;
            i = n >> 15 & 1;
            flags.cf = i;
            val[0].w.x = n << 1 | r_ea.w.x;
            flags.of = (val[0].w.x >> 15) ^ i;
            goto store_word;
        case 3:                                 /* RCR */
            r_ea.w.x = flags.cf;
            flags.cf = n;
            val[0].w.x = r_ea.w.x << 15 | n >> 1;
            flags.of = (val[0].w.x >> 14 & 1) ^ (val[0].w.x >> 15 & 1);
            goto store_word;
        case 4:                                 /* SHL */
            i = n >> 15 & 1;
            flags.cf = i;
            val[0].w.x = n << 1;
            res = val[0].w.x;
            flags.of = (val[0].w.x >> 15) ^ i;
            goto store_word_zs;
        case 5:                                 /* SHR */
            flags.cf = n;
            flags.of = n >> 15;
            val[0].w.x = n >> 1;
            res = val[0].w.x;
            goto store_word_zs;
        case 7:                                 /* SAR */
            flags.cf = n;
            flags.of = 0;
            r_ea.w.x = n & 0x8000;
            val[0].w.x = n >> 1 | r_ea.w.x;
            res = val[0].w.x;
            goto store_word_zs;
        }
        goto bad_op;
    case 0xD2:                                  /* shift r/m8,CL */ /* 19156 */
        switch (modrm >> 3 & 7) {
        case 0:                                 /* ROL */
            for (n = r_cx.b.l & 31; n; n--) {
                i = val[0].b.l >> 7 & 1;
                flags.cf = i;
                val[0].b.l = val[0].b.l << 1 | i;
            }
            *ptr[0] = val[0].b.l;
            goto next;
        case 1:                                 /* ROR */
            for (n = r_cx.b.l & 31; n; n--) {
                i = val[0].b.l & 1;
                flags.cf = i;
                val[0].b.l = val[0].b.l >> 1 | i << 7;
            }
            *ptr[0] = val[0].b.l;
            goto next;
        case 2:                                 /* RCL */
            for (n = r_cx.b.l & 31; n; n--) {
                r_ea.b.l = flags.cf;
                flags.cf = val[0].b.l >> 7;
                val[0].b.l = val[0].b.l << 1 | r_ea.b.l;
            }
            *ptr[0] = val[0].b.l;
            goto next;
        case 3:                                 /* RCR */
            for (n = r_cx.b.l & 31; n; n--) {
                r_ea.b.l = flags.cf;
                flags.cf = val[0].b.l;
                val[0].b.l = r_ea.b.l << 7 | val[0].b.l >> 1;
            }
            *ptr[0] = val[0].b.l;
            goto next;
        case 4:                                 /* SHL */
            n = (unsigned char)(val[0].b.l << ((r_cx.b.l - 1) & 31));
            flags.cf = n >> 7;
            val[0].b.l = n << 1;
            res = val[0].b.l;
            *ptr[0] = val[0].b.l;
            goto byte_flags;
        case 5:                                 /* SHR */
            n = (unsigned char)(val[0].b.l >> ((r_cx.b.l - 1) & 31));
            flags.cf = n;
            val[0].b.l = n >> 1;
            res = val[0].b.l;
            *ptr[0] = val[0].b.l;
            goto byte_flags;
        case 7:                                 /* SAR */
            for (n = r_cx.b.l & 31; n; n--) {
                flags.cf = val[0].b.l;
                r_ea.b.l = val[0].b.l & 0x80;
                val[0].b.l = val[0].b.l >> 1 | r_ea.b.l;
            }
            res = val[0].b.l;
            *ptr[0] = val[0].b.l;
            goto byte_flags;
        }
        goto bad_op;
    case 0xD3:                                  /* shift r/m16,CL */ /* 19364 */
        switch (modrm >> 3 & 7) {
        case 0:                                 /* ROL */
            for (n = r_cx.b.l & 31; n; n--) {
                i = val[0].w.x >> 15 & 1;
                flags.cf = i;
                val[0].w.x = val[0].w.x << 1 | i;
            }
            goto store_word;
        case 1:                                 /* ROR */
            for (n = r_cx.b.l & 31; n; n--) {
                i = val[0].w.x & 1;
                flags.cf = i;
                val[0].w.x = val[0].w.x >> 1 | i << 15;
            }
            goto store_word;
        case 2:                                 /* RCL */
            for (n = r_cx.b.l & 31; n; n--) {
                r_ea.w.x = flags.cf;
                flags.cf = val[0].w.x >> 15;
                val[0].w.x = val[0].w.x << 1 | r_ea.w.x;
            }
            goto store_word;
        case 3:                                 /* RCR */
            for (n = r_cx.b.l & 31; n; n--) {
                r_ea.w.x = flags.cf;
                flags.cf = val[0].w.x;
                val[0].w.x = r_ea.w.x << 15 | val[0].w.x >> 1;
            }
            goto store_word;
        case 4:                                 /* SHL */
            n = (unsigned short)((unsigned long)val[0].w.x << ((r_cx.b.l - 1) & 31));
            flags.cf = n >> 15;
            val[0].w.x = n << 1;
            res = val[0].w.x;
            goto store_word_zs;
        case 5:                                 /* SHR */
            n = (unsigned short)((unsigned long)val[0].w.x >> ((r_cx.b.l - 1) & 31));
            flags.cf = n;
            val[0].w.x = n >> 1;
            res = val[0].w.x;
            goto store_word_zs;
        case 7:                                 /* SAR: no flags but CF */
            for (n = r_cx.b.l & 31; n; n--) {
                flags.cf = val[0].w.x;
                r_ea.w.x = val[0].w.x & 0x8000;
                val[0].w.x = val[0].w.x >> 1 | r_ea.w.x;
            }
            res = val[0].w.x;
            if (incode[0])
                val[0].w.x = SWAP(val[0].w.x);
            W(ptr[0]) = val[0].w.x;
            goto word_flags;
        }
        goto bad_op;

    case 0xF6:                                                  /* 19690 */
        switch (modrm >> 3 & 7) {
        case 0:                                 /* TEST r/m8,imm8 */
            res = val[0].b.l & val[1].b.l;
            flags.cf = 0;
            flags.of = 0;
            goto byte_flags;
        case 2:                                 /* NOT */
            val[0].b.l = ~val[0].b.l;
            *ptr[0] = val[0].b.l;
            goto next;
        case 3:                                 /* NEG */
            flags.cf = val[0].b.l != 0;         /* then recomputed as 0 */
            val[0].b.l = -val[0].b.l;
            res = val[0].b.l;
            *ptr[0] = val[0].b.l;
            flags.upd_cf = flags.upd_of = 1;
            goto byte_flags;
        case 4:                                 /* MUL */
            r_ax.w.x = val[0].b.l * r_ax.b.l;
            flags.cf = flags.of = r_ax.b.h != 0;
            goto next;
        case 5:                                 /* IMUL */
            r_ax.w.x = (signed char)val[0].b.l * (signed char)r_ax.b.l;
            flags.cf = flags.of = (long)r_ax.w.x != (signed char)r_ax.b.l;
            goto next;
        case 6:                                 /* DIV */
            if (val[0].b.l == 0) {
                InternalError("Divide by zero encountered in script");
                goto next;
            }
            r_ea.w.x = r_ax.w.x;
            r_ax.b.l = r_ea.w.x / val[0].b.l;
            r_ax.b.h = r_ea.w.x % val[0].b.l;
            goto next;
        case 7:                                 /* IDIV */
            if (val[0].b.l == 0) {
                InternalError("Divide by zero encountered in script");
                goto next;
            }
            r_ea.w.x = r_ax.w.x;
            r_ax.b.l = (short)r_ea.w.x / (signed char)val[0].b.l;
            r_ax.b.h = (short)r_ea.w.x % (signed char)val[0].b.l;
            goto next;
        }
        goto bad_op;
    case 0xF7:                                                  /* 1984C */
        switch (modrm >> 3 & 7) {
        case 0:                                 /* TEST r/m16,imm16 */
            res = val[0].w.x & val[1].w.x;
            flags.cf = 0;
            flags.of = 0;
            flags.upd_zf = flags.upd_sf = 1;
            goto word_flags;
        case 2:                                 /* NOT */
            val[0].w.x = ~val[0].w.x;
            goto store_word;
        case 3:                                 /* NEG */
            flags.cf = val[0].w.x != 0;         /* then recomputed as 0 */
            val[0].w.x = -val[0].w.x;
            res = val[0].w.x;
            goto store_word_all;
        case 4:                                 /* MUL */
            r_ea.d = (unsigned long)val[0].w.x * r_ax.w.x;
            r_dx.w.x = r_ea.d >> 16;
            r_ax.w.x = r_ea.d;
            flags.cf = flags.of = r_dx.w.x != 0;
            goto next;
        case 5:                                 /* IMUL */
            r_ea.d = (long)(short)val[0].w.x * (short)r_ax.w.x;
            r_dx.w.x = r_ea.d >> 16;
            r_ax.w.x = r_ea.d;
            flags.cf = flags.of = (long)r_ea.d != (long)r_ax.w.x;
            goto next;
        case 6:                                 /* DIV: AX only */
            if (val[0].w.x == 0)
                goto next;
            r_ea.d = r_ax.w.x;
            r_ax.w.x = r_ea.d / val[0].w.x;
            r_dx.w.x = r_ea.d % val[0].w.x;
            goto next;
        case 7:                                 /* IDIV: AX only, unsigned */
            if (val[0].w.x == 0)
                goto next;
            r_ea.d = r_ax.w.x;
            r_ax.w.x = (long)r_ea.d / (short)val[0].w.x;
            r_dx.w.x = (long)r_ea.d % (short)val[0].w.x;
            goto next;
        }
        goto bad_op;
    case 0xFE:                                                  /* 19A5A */
        switch (modrm >> 3 & 7) {
        case 0:                                 /* INC */
            res = ++val[0].b.l;
            *ptr[0] = val[0].b.l;
            flags.upd_of = 1;
            goto byte_flags;
        case 1:                                 /* DEC */
            res = --val[0].b.l;
            *ptr[0] = val[0].b.l;
            flags.upd_of = 1;
            goto byte_flags;
        }
        goto bad_op;
    case 0xFF:                                                  /* 19AB4 */
        switch (modrm >> 3 & 7) {
        case 0:                                 /* INC */
            res = ++val[0].w.x;
            if (incode[0])
                val[0].w.x = SWAP(val[0].w.x);
            W(ptr[0]) = val[0].w.x;
            flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
            goto word_flags;
        case 1:                                 /* DEC */
            res = --val[0].w.x;
            if (incode[0])
                val[0].w.x = SWAP(val[0].w.x);
            W(ptr[0]) = val[0].w.x;
            flags.upd_zf = flags.upd_sf = flags.upd_of = 1;
            goto word_flags;
        case 3:                                 /* CALL FAR: ScriptService */
            n = (0x40 - r_sp.w.x) >> 1;                         /* 19B86 */
            if (n > 12)
                n = 12;
            for (i = 0; i < n; i++)
                args[i] = W(stack + r_sp.w.x + 2 * i);
            /* all twelve are passed, set or not */
            r_ea.d = ScriptService(args[0], args[1], args[2], args[3],
                                   args[4], args[5], args[6], args[7],
                                   args[8], args[9], args[10], args[11]);
            r_ax.w.x = r_ea.d;
            r_dx.w.x = r_ea.d >> 16;
            goto next;
        case 4:                                 /* JMP r/m16 */ /* 19C5A */
            r_ip.w.x = val[0].w.x;
            goto next;
        case 6:                                 /* PUSH r/m16 */ /* 19C68 */
            PUSH(val[0].w.x);
            goto next;
        }
        goto bad_op;
    default:
        goto bad_op;
    }

    /* Word write-backs, swapping into the code's byte order. */
store_word_all:                                 /* flags: CF ZF SF OF */
    flags.upd_cf = flags.upd_of = 1;
store_word_zs:                                  /* flags: ZF SF */
    flags.upd_zf = flags.upd_sf = 1;
    if (incode[0])
        val[0].w.x = SWAP(val[0].w.x);
    W(ptr[0]) = val[0].w.x;
    goto word_flags;
store_word:                                     /* no flags */
    if (incode[0])
        val[0].w.x = SWAP(val[0].w.x);
    W(ptr[0]) = val[0].w.x;
    goto next;

word_flags:                                                     /* 19C8C */
    if (flags.upd_cf)
        flags.cf = (res & 0x10000) != 0;
    if (flags.upd_zf)
        flags.zf = res == 0;
    if (flags.upd_sf)
        flags.sf = (res & 0x8000) != 0;
    if (flags.upd_of)
        flags.of = res < -0x8000 || res > 0x7FFF;
    goto next;

byte_flags:                                                     /* 19D0A */
    if (flags.upd_cf)
        flags.cf = (res & 0x100) != 0;
    flags.zf = res == 0;
    flags.sf = (res & 0x80) != 0;
    if (flags.upd_of)
        flags.of = (short)res < -0x100 || res > 0xFF;
    goto next;

bad_op:                                                         /* 19C84 */
    Trace();
illegal:                                                        /* 19D70 */
    InternalError("Current script contains an illegal instruction (%02X%02X)", op, op2);

next:                                                           /* 19D8E */
    rep = 0;
    seg = default_seg;
    mem = data;
    desc[0] = desc[1] = desc[2] = 0;
    incode[0] = incode[1] = incode[2] = 0;
    UPD_CLEAR();
    goto prefix;
}
