/* seg007: video modes, palettes, fades, rectangles and text */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "sprite.h"
#include "gfx.h"

unsigned char cur_palette[768];
unsigned char remap_table[256];
int fade_level;

void Fatal(char *fmt, ...);     /* fatal error */
void BuildRemap(unsigned char far *table, int level);   /* (c1AE8C) */

int cur_remap_id = -1;

void CopyRect(Bitmap far *dst, int x, int y, Bitmap far *src, int sx, int sy, int w, int h)
{
    char far *d;
    char far *s;
    int unused;
    int dskip;
    int sskip;

    d = dst->data;
    d += y * dst->w + x;
    s = src->data;
    s += sy * src->w + sx;
    dskip = dst->w;
    sskip = src->w;
    while (h--) {
        MemCpy(d, s, w);
        d += dskip;
        s += sskip;
    }
}

/* CopyRect skipping 0 pixels. */
void CopyRectNZ(Bitmap far *dst, int x, int y, Bitmap far *src, int sx, int sy, int w, int h)
{
    char far *d;
    char far *s;
    int unused;
    int dskip;
    int sskip;

    d = dst->data;
    d += y * dst->w + x;
    s = src->data;
    s += sy * src->w + sx;
    dskip = dst->w;
    sskip = src->w;
    while (h--) {
        MemCpyNZ(d, s, w);
        d += dskip;
        s += sskip;
    }
}

/* Load cloak remap table n: from the cache, or built from the fade level
 * and cached as cloakN.$lu. New in the sequel (ST25 loaded cloakN.lut). */
void SetRemap(int remap)
{
    MemHandle h;
    char name[10];

    if (remap == cur_remap_id)
        return;
    sprintf(name, "cloak%d", remap);
    if ((h = CacheGet(name, "$lu", 0, 0, 1)) == 0) {
        h = AllocMemAbort(0x100, 0);
        BuildRemap(LockMem(h), (-1 - remap) * 64 / 9 + 64);
        UnlockMem(h);
        CacheStore(name, "$lu", h);
    }
    MemCpy(remap_table, LockMem(h), 0x100);
    UnlockMem(h);
    ReleaseCache(h);
    cur_remap_id = remap;
}

/* The sequel loads the remap table separately (SetRemap). */
void CopyRectRemap(Bitmap far *dst, int x, int y, Bitmap far *src, int sx, int sy, int w, int h)
{
    char far *d;
    char far *s;
    int unused;
    int dskip;
    int sskip;

    if (w == 0 || h == 0)
        return;
    d = dst->data;
    d += y * dst->w + x;
    s = src->data;
    s += sy * src->w + sx;
    dskip = dst->w - w;
    sskip = src->w - w;
    _asm {
        push si
        push di
        push ds
        lds si, s
        les di, s
        sub ax, ax
        mov bx, offset remap_table
    l_row:
        mov cx, w
        cmp [si], al
        jne l_solid
    l_zero:
        repe scasb
        je l_zero_end
        dec di
        inc cx
        mov dx, di
        sub dx, si
        xchg cx, dx
        mov si, di
        les di, d
        rep stosb
        mov cx, dx
        mov word ptr d, di
        mov es, word ptr s+2
        mov di, si
    l_solid:
        repne scasb
        jne l_solid_end
        dec di
        inc cx
        mov dx, di
        sub dx, si
        xchg cx, dx
        les di, d
    l_copy:
        lodsb
        _emit 36h
        xlat [bx]
        stosb
        loop l_copy
        sub ax, ax
        mov cx, dx
        mov word ptr d, di
        mov es, word ptr s+2
        mov di, si
        jmp l_zero
    l_zero_end:
        mov cx, di
        sub cx, si
        mov si, di
        les di, d
        rep stosb
        add si, sskip
        add di, dskip
        mov word ptr d, di
        mov es, word ptr s+2
        mov di, si
        dec h
        jne l_row
        jmp l_done
    l_solid_end:
        mov cx, di
        sub cx, si
        les di, d
    l_copy2:
        lodsb
        _emit 36h
        xlat [bx]
        stosb
        loop l_copy2
        sub ax, ax
        add si, sskip
        add di, dskip
        mov word ptr d, di
        mov es, word ptr s+2
        mov di, si
        dec h
        je l_done
        jmp l_row
    l_done:
        pop ds
        pop di
        pop si
    }
}

int PointInRect(Rect *r, int x, int y)
{
    if (r->x0 > x || r->x1 < x || r->y0 > y || r->y1 < y)
        return 0;
    return 1;
}

/* out = a & b; 0 if they don't overlap. */
int ClipRect(Rect *out, Rect *a, Rect *b)
{
    if (a->x0 > b->x1 || a->x1 < b->x0 || a->y0 > b->y1 || a->y1 < b->y0)
        return 0;
    else {
        out->x0 = max(a->x0, b->x0);
        out->y0 = max(a->y0, b->y0);
        out->x1 = min(a->x1, b->x1);
        out->y1 = min(a->y1, b->y1);
        return 1;
    }
}

/* out = bounding box of a and b. */
void UnionRect(Rect *out, Rect *a, Rect *b)
{
    out->x0 = min(a->x0, b->x0);
    out->y0 = min(a->y0, b->y0);
    out->x1 = max(a->x1, b->x1);
    out->y1 = max(a->y1, b->y1);
}

char *WrapLine(char *src, char *dst, int width)
{
    int i;
    int brk_i;
    char *brk_src;
    char *brk_dst;

    *dst = 0;
    if (*src == 0)
        return 0;
    brk_src = brk_dst = 0;
    for (i = 0; i != width && *src; i++) {
        if (*src == '\n') {
            *dst = 0;
            return src + 1;
        }
        if (*src == ' ') {
            brk_i = i;
            brk_src = src;
            brk_dst = dst;
        } else if (*src == '-') {       /* new: break after a hyphen */
            brk_src = src;
            brk_dst = dst + 1;
        } else if (*src == '\r') {
            src++;
            i--;
            continue;
        }
        *dst++ = *src++;
    }
    if (*src == 0) {
        *dst = 0;
        return src;
    }
    if (*src == ' ') {
        *dst = 0;
        return src + 1;
    }
    if (brk_dst == 0) {
        *dst = 0;
        return src;
    }
    src = brk_src;
    dst = brk_dst;
    *dst = 0;
    return src + 1;
}

void FadeIn(void)
{
    unsigned long t;

    while (fade_level <= 100) {
        t = GetTicks() + 1;
        while (GetTicks() < t)
            ;
        SetFade(cur_palette, fade_level);
        fade_level += 10;
    }
    fade_level = 100;
}

void FadeOut(void)
{
    unsigned long t;

    while (fade_level >= 0) {
        t = GetTicks() + 1;
        while (GetTicks() < t)
            ;
        SetFade(cur_palette, fade_level);
        fade_level -= 10;
    }
    fade_level = 0;
}

void FadeUp(void)
{
    if (fade_level < 100)
        SetFade(cur_palette, fade_level += 10);
}

void FadeDown(void)
{
    if (fade_level > 0)
        SetFade(cur_palette, fade_level -= 10);
}
