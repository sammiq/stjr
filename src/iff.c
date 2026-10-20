/* iff: reading DPaint .lbm pictures (IFF FORM PBM or ILBM) */

#include <string.h>
#include <malloc.h>
#include <io.h>
#include <stdlib.h>
#include "mem.h"
#include "resource.h"

/* The BMHD chunk. */
typedef struct Bmhd {
    unsigned w;                 /* 00 */
    unsigned h;                 /* 02 */
    int x;                      /* 04 */
    int y;                      /* 06 */
    unsigned char nplanes;      /* 08 */
    unsigned char masking;      /* 09 */
    unsigned char compression;  /* 0A 1: ByteRun1 */
    unsigned char pad;          /* 0B */
    unsigned transparent;       /* 0C */
    unsigned char xaspect;      /* 0E */
    unsigned char yaspect;      /* 0F */
    int page_w;                 /* 10 */
    int page_h;                 /* 12 */
} Bmhd;

typedef struct Words {
    unsigned lo;
    unsigned hi;
} Words;

int far ReadByte(int fd);       /* seg003 */

int IffFind(char *name, int fd);
int IffIlbmRows(Bmhd *h, char *row, int n, int fd);
int IffPbmRows(Bmhd *h, char *row, int n, int fd);
void IffUnpack(int (far *get)(int), int fd, char *dst, int n);
void SwapLong(long *p);
void SwapInt(int *p);
void SwapULong(unsigned long *p);
void SwapUInt(unsigned *p);

int IffBmhd(Bmhd *h, int fd)
{
    long len;

    if (IffFind("BMHD", fd) == 0) {
        _read(fd, &len, 4);
        SwapULong(&len);
        if (len != 20)
            return -1;
        ReadFile(fd, h, 20);
        SwapUInt(&h->w);
        SwapUInt(&h->h);
        SwapInt(&h->x);
        SwapInt(&h->y);
        SwapUInt(&h->transparent);
        SwapInt(&h->page_w);
        SwapInt(&h->page_h);
        return 0;
    }
    return -3;
}

int IffBody(int fd)
{
    long len;

    if (IffFind("BODY", fd) == 0) {
        _read(fd, &len, 4);
        return 0;
    }
    return -1;
}

/* Read n rows of the picture into row (type: 0 PBM, 1 ILBM). */
int IffRows(int type, Bmhd *h, char *row, int n, int fd)
{
    if (type == 0)
        return IffPbmRows(h, row, n, fd);
    if (type == 1)
        return IffIlbmRows(h, row, n, fd);
    return -1;
}

/* ILBM: each row is 8 bitplanes, turned into chunky pixels. */
int IffIlbmRows(Bmhd *h, char *row, int n, int fd)
{
    char far *dst;
    unsigned x;
    int k;
    int p;
    char *buf;
    char *plane;
    char *q;
    unsigned w;
    unsigned bpl;

    dst = row;
    w = h->w;
    bpl = w >> 3;
    if ((w & 3) || h->nplanes != 8)
        return -3;
    if ((buf = _nmalloc(w)) == 0)
        return -2;
    while (n--) {
        for (plane = buf, p = 0; p != h->nplanes; p++, plane += bpl) {
            if (h->compression == 1)
                IffUnpack(ReadByte, fd, plane, bpl);
            else {
                ReadFile(fd, q, x);
                q += x;
            }
        }
        for (x = 0, plane = buf; x != w; x += 8, plane++, dst += 8) {
            _asm {
                push si
                push di
                push ds
                lds si, dword ptr plane
                mov al, [si]
                add si, bpl
                mov ah, [si]
                add si, bpl
                mov bl, [si]
                add si, bpl
                mov bh, [si]
                add si, bpl
                mov cl, [si]
                add si, bpl
                mov ch, [si]
                add si, bpl
                mov dl, [si]
                add si, bpl
                mov dh, [si]
                mov word ptr k, 8
                lds si, dst
            l_pix:
                sub di, di
                shl dh, 1
                rcl di, 1
                shl dl, 1
                rcl di, 1
                shl ch, 1
                rcl di, 1
                shl cl, 1
                rcl di, 1
                shl bh, 1
                rcl di, 1
                shl bl, 1
                rcl di, 1
                shl ah, 1
                rcl di, 1
                shl al, 1
                rcl di, 1
                xchg di, ax
                mov [si], al
                xchg di, ax
                inc si
                dec word ptr k
                jz l_done
                jmp l_pix
            l_done:
                pop ds
                pop di
                pop si
            }
        }
    }
    _nfree(buf);
    return 0;
}

/* PBM: chunky rows, padded to an even width. */
int IffPbmRows(Bmhd *h, char *row, int n, int fd)
{
    char *buf;
    int len;
    char *p;
    int cnt;

    if ((buf = _nmalloc(h->w + 2)) == 0)
        return -2;
    if (h->nplanes == 8) {
        len = h->w + 1 & ~1;
        while (n--) {
            if (h->compression == 1)
                IffUnpack(ReadByte, fd, buf, len);
            else {
                ReadFile(fd, p, cnt);
                p += cnt;
            }
            memcpy(row, buf, h->w);
            row += h->w;
        }
        _nfree(buf);
        return 0;
    }
    _nfree(buf);
    return -1;
}

/* Read up to n colours of the CMAP into pal. */
int IffCmap(int fd, unsigned char *pal, int n)
{
    unsigned long len;

    if (IffFind("CMAP", fd) == 0) {
        _read(fd, &len, 4);
        SwapULong(&len);
        if ((long)(n * 3) > len)
            n = len / 3;
        ReadFile(fd, pal, n * 3);
        return 0;
    }
    return -2;
}

/* 0 for a PBM, 1 for an ILBM; negative if it's neither. */
int IffType(int fd)
{
    char id[4];

    _lseek(fd, 0L, 0);
    _read(fd, id, 4);
    if (strncmp(id, "FORM", 4) == 0) {
        _read(fd, id, 4);
        if (_read(fd, id, 4) == 4) {
            if (strncmp(id, "PBM ", 4) == 0)
                return 0;
            return strncmp(id, "ILBM", 4) == 0 ? 1 : -1;
        }
        return -2;
    }
    return -3;
}

/* Seek to the data of the chunk name: 0 if found. */
int IffFind(char *name, int fd)
{
    unsigned long formlen;
    unsigned long size;
    char id[4];
    unsigned long pos;

    _lseek(fd, 0L, 0);
    _read(fd, id, 4);
    if (strncmp(id, "FORM", 4) == 0) {
        _read(fd, &formlen, 4);
        SwapULong(&formlen);
        pos = 12;
        do {
            _lseek(fd, pos, 0);
            _read(fd, id, 4);
            if (strncmp(id, name, 4) == 0)
                return 0;
            _read(fd, &size, 4);
            SwapULong(&size);
            size = size + 1 & ~1L;
            pos += size + 8;
        } while (pos < formlen + 12);
        return -1;
    }
    return -2;
}

/* ByteRun1: n bytes into dst, reading with get. */
void IffUnpack(int (far *get)(int), int fd, char *dst, int n)
{
    signed char c;
    char v;

    while (n) {
        c = get(fd);
        if (c >= 0) {
            if (++c) {
                n -= (unsigned char)c;
                do
                    *dst++ = get(fd);
                while (--c);
            }
        } else if (c != -128) {
            v = get(fd);
            if ((c = 1 - c) != 0) {
                n -= (unsigned char)c;
                do
                    *dst++ = v;
                while (--c);
            }
        }
    }
}

void SwapLong(long *p)
{
    Words t;

    t = *(Words *)p;
    *p = (long)_rotl(t.lo, 8) << 16 | _rotl(t.hi, 8);
}

void SwapInt(int *p)
{
    *p = _rotl(*p, 8);
}

void SwapULong(unsigned long *p)
{
    Words t;

    t = *(Words *)p;
    *p = (long)_rotl(t.lo, 8) << 16 | _rotl(t.hi, 8);
}

void SwapUInt(unsigned *p)
{
    *p = _rotl(*p, 8);
}
