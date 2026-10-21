/* seg007: video modes, palettes, fades, rectangles and text */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "sprite.h"
#include "gfx.h"

unsigned char cur_palette[768];
static unsigned char remap_table[256];
int fade_level;

void Fatal(char *fmt, ...);     /* fatal error */
void LockScreen(void);                  /* seg012 */
void UnlockScreen(void);
void CycleBridge(void);                 /* seg001 */

extern unsigned char far *screen_base;  /* seg012 */

int gfx_mode = 0;                       /* in mode 13h */
signed char fade_rgb[3] = { 0, 0, 0 };

void InitVideo(void)
{
    int mode;

    gfx_mode = 1;
    mode = 0x13;
    _asm {
        push bp
        push si
        push di
        mov ax, mode
        int 10h
        pop di
        pop si
        pop bp
    }
}

void TextMode(void)
{
    if (gfx_mode) {
        gfx_mode = 0;
        _asm {
            push bp
            push si
            push di
            mov ax, 3
            int 10h
            pop di
            pop si
            pop bp
        }
    }
}

void SetPalette(unsigned char far *pal)
{
    _asm {
        mov ax, 1012h
        mov bx, 0
        mov cx, 100h
        les dx, pal
        int 10h
    }
}

void GetPalette(unsigned char far *pal)
{
    _asm {
        mov ax, 1017h
        mov bx, 0
        mov cx, 100h
        les dx, pal
        int 10h
    }
}

void SetPaletteRange(unsigned char far *pal, int first, int count)
{
    _asm {
        mov dx, 3C8h
        mov al, byte ptr first
        out dx, al
        push ds
        push si
        lds si, pal
        mov cx, count
        inc dx
    l_next:
        lodsb
        out dx, al
        lodsb
        out dx, al
        lodsb
        out dx, al
        loop l_next
        pop si
        pop ds
    }
}

#define SQ(v) ((v) * (v))

/* table: for colours 10-245 the nearest of colours 10-207 to it at level
 * 64ths of its brightness; the rest map to themselves. */
/* (99.95%: the target swaps the frame slots of c and best; declaration
 * order doesn't move them.) */
void BuildRemap(unsigned char far *table, int level)
{
    int i;
    int c;
    int j;
    int r;
    int g;
    int b;
    int best;
    int d;
    unsigned bestd;

    for (i = 0; i < 10; i++)
        *table++ = i;
    for (c = 30; c < 0x2E2; c += 3) {
        r = cur_palette[c] * level / 64;
        g = cur_palette[c + 1] * level / 64;
        b = cur_palette[c + 2] * level / 64;
        best = 0;
        bestd = 0xFFFF;
        for (j = 30; j <= 0x26D; j += 3) {
            d = SQ(cur_palette[j + 2] - b) + SQ(cur_palette[j + 1] - g) + SQ(cur_palette[j] - r);
            if (d < bestd) {
                best = j;
                bestd = d;
            }
        }
        *table++ = best / 3;
    }
    for (i = 0xF6; i < 0x100; i++)
        *table++ = i;
}

/* Take colours 48-127, 216-219 and 224-245 from name.pal. */
void sub_1B61E(char *name)
{
    MemHandle h;
    unsigned char far *pal;

    if (name == 0)
        return;
    MemCpy(&cur_palette[0x90], (pal = LockMem(h = CacheLoadEMS(name, "pal"))) + 0x90, 0xF0);
    MemCpy(&cur_palette[0x288], pal + 0x288, 12);
    MemCpy(&cur_palette[0x2A0], pal + 0x2A0, 0x42);
    UnlockMem(h);
    CacheRelease(h);
    BuildRemap(shade_table, 32);
    SetFade(cur_palette, fade_level);
}

/* Load name.pal (or keep the palette for 0), then take the colours the
 * screen's bitmap sets from it. */
void LoadPalette(char *name)
{
    MemHandle h;
    int i;

    if (name) {
        MemCpy(cur_palette, LockMem(h = CacheLoadEMS(name, "pal")), 0x300);
        UnlockMem(h);
        CacheRelease(h);
        for (i = 0; i < 30; i++)
            cur_palette[i] = cur_palette[0x2E2 + i] = 0;
        sub_1BCC2();
    }
    LockScreen();
    for (i = 30; i < 0x180; i++)
        cur_palette[i] = screen_base[i];
    if (stricmp(name, "bridge") == 0)
        CycleBridge();
    else
        for (i = 0x270; i < 0x288; i++)
            cur_palette[i] = screen_base[i];
    for (i = 0x288; i < 0x294; i++)
        cur_palette[i] = screen_base[i];
    for (i = 0x2A0; i < 0x2E2; i++)
        cur_palette[i] = screen_base[i];
    UnlockScreen();
    BuildRemap(shade_table, 32);
}

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

void sub_1BCC2(void)
{
    cur_palette[0x17] = cur_palette[0x16] = cur_palette[0x15] = 0x3F;
}

/* Show pal at level percent of the way from fade_rgb. */
void SetFade(unsigned char far *pal, int level)
{
    int i;
    int tab[127];

    for (i = 0; i != 127; i++)
        tab[i] = (i - 63) * level / 100;
    outp(0x3C8, 0);
    for (i = 0; i != 768; i += 3) {
        outp(0x3C9, fade_rgb[0] + tab[pal[i] - fade_rgb[0] + 63]);
        outp(0x3C9, fade_rgb[1] + tab[pal[i + 1] - fade_rgb[1] + 63]);
        outp(0x3C9, fade_rgb[2] + tab[pal[i + 2] - fade_rgb[2] + 63]);
    }
}
