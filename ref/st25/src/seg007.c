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

/* Globals this file owns (declared in the headers). */
int video_mode;
unsigned char cur_palette[768];
unsigned char remap_table[256];
int fade_level;

void Fatal(char *fmt, ...);     /* fatal error */

unsigned char far *cur_glyph;

MemHandle font_handle = 0;
unsigned char far *font_data = 0;
int cur_remap_id = -1;
/* EGA palette register lists (16 colours and the border) for 4 fade steps */
unsigned char ega_fade[4][18] = {
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    { 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 0 },
    { 0, 1, 2, 3, 4, 5, 6, 0x10, 0, 1, 2, 3, 4, 5, 6, 7, 0 },
    { 0, 1, 2, 3, 4, 5, 6, 7, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0 }
};

/* Tandy: set the 16 palette registers (and the border) for a brightness. */
void SetTandyLevel(int level)
{
    char lo;
    char hi;

    if (level <= 24) {
        lo = 0, hi = 0;
    } else if (level <= 49) {
        lo = 0, hi = 7;
    } else if (level <= 74) {
        lo = 7, hi = 7;
    } else {
        lo = 7, hi = 15;
    }
    _asm {
        push si
        push di
        push bp
        mov cx, 10h
        xor bh, bh
        xor bl, bl
        mov di, 2
        call l_set
    l_next:
        mov di, 10h
        call l_set
        inc bl
        inc bh
        loop l_next
        jmp l_done
    l_set:
        mov dx, 3DAh
        cli
    l_wait:
        in al, dx
        and al, 8
        je l_wait
        mov al, bl
        cbw
        add ax, di
        out dx, al
        mov al, bh
        test al, 8
        je l_low
        and al, hi
        jmp l_out
    l_low:
        and al, lo
    l_out:
        mov dx, 3DEh
        out dx, al
        mov dx, 3DAh
        xor ax, ax
        out dx, al
        sti
        _emit 0C3h
    l_done:
        pop bp
        pop di
        pop si
    }
}

/* Tandy 1000 320x200 16 colour mode, programmed from CGA mode 4. */
void InitTandyMode(void)
{
    _asm {
        push si
        push di
        push bp
        mov ax, 4
        int 10h
        mov dx, 3D4h
        mov ax, 7100h
        call l_crtc
        mov ax, 5001h
        call l_crtc
        mov ax, 5A02h
        call l_crtc
        mov ax, 0E03h
        call l_crtc
        mov ax, 0FF04h
        call l_crtc
        mov ax, 605h
        call l_crtc
        mov ax, 0C806h
        call l_crtc
        mov ax, 0E207h
        call l_crtc
        mov ax, 9
        call l_crtc
        mov ax, 0Ch
        call l_crtc
        mov ax, 1810h
        call l_crtc
        mov ax, 4612h
        call l_crtc
        mov dx, 3D8h
        mov al, 1Bh
        out dx, al
        mov dx, 3D9h
        mov al, 0
        out dx, al
        mov dx, 3DDh
        mov al, 0
        out dx, al
        mov dx, 3DFh
        mov al, 24h
        out dx, al
        mov dx, 3DAh
        mov al, 1
        out dx, al
        mov dx, 3DEh
        mov al, 0Fh
        out dx, al
        mov dx, 3DAh
        mov al, 2
        out dx, al
        mov dx, 3DEh
        mov al, 0
        out dx, al
        mov dx, 3DAh
        mov al, 3
        out dx, al
        mov dx, 3DEh
        mov al, 10h
        out dx, al
        mov dx, 3DAh
        mov al, 5
        out dx, al
        mov dx, 3DEh
        mov al, 1
        out dx, al
        mov dx, 3DAh
        mov al, 8
        out dx, al
        mov dx, 3DEh
        mov al, 2
        out dx, al
        jmp l_done
    l_crtc:
        out dx, al
        mov al, ah
        inc dx
        out dx, al
        dec dx
        _emit 0C3h
    l_done:
        pop bp
        pop di
        pop si
    }
    SetTandyLevel(100);
    MemSet((void far *)0xA0000000L, 0xFA00, 0);
}

/* Detect the display (VGA, EGA or Tandy) on the first call and set the
 * graphics mode. */
void InitVideo(void)
{
    int mode;

    if (video_mode == -1) {
        _asm {
            mov video_mode, VIDEO_VGA
            mov ax, 1A00h
            int 10h
            cmp al, 1Ah
            je l_found
            mov video_mode, VIDEO_EGA
            mov ax, 1200h
            mov bl, 10h
            int 10h
            cmp bl, 10h
            jne l_found
            mov video_mode, VIDEO_TANDY
        l_found:
        }
    }
    switch (video_mode) {
    case VIDEO_VGA:
        mode = 0x13;
        break;
    case VIDEO_EGA:
        mode = 0x0E;
        break;
    case VIDEO_TANDY:
        InitTandyMode();
        return;
    default:
        Fatal("Unsupport display type");
    }
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

void SetPalette(unsigned char far *pal)
{
    switch (video_mode) {
    case VIDEO_VGA:
        _asm {
            mov ax, 1012h
            mov bx, 0
            mov cx, 100h
            les dx, pal
            int 10h
        }
        break;
    case VIDEO_EGA:
    case VIDEO_TANDY:
        MatchPalette(pal, 0, 256);
        break;
    }
}

void SetPaletteRange(unsigned char far *pal, int first, int count)
{
    switch (video_mode) {
    case VIDEO_VGA:
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
        break;
    case VIDEO_EGA:
    case VIDEO_TANDY:
        MatchPalette(pal, first, count);
        break;
    }
}

/* Load name.pal and its shading table name.lut. */
void LoadPalette(char *name)
{
    LoadFilePacked(name, "pal", cur_palette);
    LoadFilePacked(name, "lut", shade_table);
    switch (video_mode) {
    case VIDEO_EGA:
    case VIDEO_TANDY:
        if (strcmpi(name, "bridge") == 0 || strcmpi(name, "palette") == 0)
            LoadRemap(name);
        else
            MatchPalette(cur_palette, 0, 256);
        break;
    case VIDEO_VGA:
        break;
    }
}

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

/* CopyRect through the colour table cloak<remap>.lut; runs of 0 are copied
 * as 0. */
void CopyRectRemap(Bitmap far *dst, int x, int y, Bitmap far *src, int sx, int sy, int w, int h,
                   int remap)
{
    char far *d;
    char far *s;
    int unused;
    int dskip;
    int sskip;
    char name[10];

    if (w == 0 || h == 0)
        return;
    d = dst->data;
    d += y * dst->w + x;
    s = src->data;
    s += sy * src->w + sx;
    dskip = dst->w - w;
    sskip = src->w - w;
    if (remap != cur_remap_id) {
        sprintf(name, "cloak%d", remap);
        LoadFilePacked(name, "lut", remap_table);
        cur_remap_id = remap;
    }
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

/* Copy the first line of src into dst, breaking at a newline or the last
 * space within width characters. Returns where the next line starts, or 0
 * at the end of the text. */
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
        }
        if (*src == '\r') {
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

void SetGlyph(int c)
{
    cur_glyph = font_data + c * 64;
}

void BlitRows(char far *src, int sskip, char far *dst, int dskip, int w, int h)
{
    int unused;

    sskip += w;
    dskip += w;
    while (h--) {
        MemCpy(dst, src, w);
        dst += dskip;
        src += sskip;
    }
}

int DrawString(char *s, int x, int y, Bitmap far *bmp)
{
    int len;

    if (s == 0)
        return 0;
    len = strlen(s);
    DrawText(s, len, x, y, bmp);
}

/* Draw len characters of s with the 8x8 font at (x, y) in bmp. */
void DrawText(char *s, int len, int x, int y, Bitmap far *bmp)
{
    int x0;
    int x1;
    int y0;
    int y1;
    int bx0;
    int bx1;
    int by0;
    int by1;
    int cx0;
    int dx;
    int cx1;
    int unused1;
    int cy0;
    int cy1;
    int dy;
    int unused2;
    int w;
    int h;
    int i;
    int cw;
    int ch;
    int sskip;
    int dskip;
    int soff;
    int doff;
    char far *src;
    char far *dst;

    cw = 8;
    ch = 8;
    font_data = LockMem(font_handle);
    for (i = 0; i < len; i++) {
        x0 = x;
        x1 = cw - 1 + x0;
        y0 = y;
        y1 = ch - 1 + y0;
        bx0 = 0;
        bx1 = bx0 + (bmp->w - 1);
        by0 = 0;
        by1 = by0 + (bmp->h - 1);
        SetGlyph(s[i]);
        if (x0 <= bx1 && x1 >= bx0 && y0 <= by1 && y1 >= by0) {
            cx0 = bx0 - x0;
            if (cx0 < x0 - x0)
                cx0 = x0 - x0;
            cx1 = bx1 - x0;
            if (cx1 > x1 - x0)
                cx1 = x1 - x0;
            cy0 = by0 - y0;
            if (cy0 < y0 - y0)
                cy0 = y0 - y0;
            cy1 = by1 - y0;
            if (cy1 > y1 - y0)
                cy1 = y1 - y0;
            dx = x0 - bx0;
            if (dx < bx1 - bx1)
                dx = bx1 - bx1;
            dy = y0 - by0;
            if (dy < by0 - by0)
                dy = by0 - by0;
            w = cx1 - cx0 + 1;
            h = cy1 - cy0 + 1;
            soff = cy0 * cw + cx0;
            doff = dx + (long)dy * (bx1 - bx0 + 1);
            sskip = cw - w;
            dskip = bx1 - bx0 + 1 - w;
            src = cur_glyph + soff;
            dst = bmp->data + doff;
            BlitRows(src, sskip, dst, dskip, w, h);
        }
        x += cw;
    }
    UnlockMem(font_handle);
}

void LoadFont(void)
{
    font_handle = CacheLoad("font", "fnt");
}

void FreeFont(void)
{
    CacheRelease(font_handle);
}

void VideoNop(void)
{
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

/* Show pal at level percent brightness. */
void SetFade(unsigned char far *pal, int level)
{
    unsigned char far *p;
    int lv;
    int scale;
    unsigned char buf[768];

    switch (video_mode) {
    case VIDEO_EGA:
        if (level <= 24)
            p = ega_fade[0];
        else if (level <= 49)
            p = ega_fade[1];
        else if (level <= 74)
            p = ega_fade[2];
        else
            p = ega_fade[3];
        _asm {
            mov ax, 1002h
            les dx, p
            push bp
            push si
            push di
            int 10h
            pop di
            pop si
            pop bp
        }
        break;
    case VIDEO_TANDY:
        SetTandyLevel(level);
        break;
    case VIDEO_VGA:
        lv = level;
        _asm {
            mov ah, byte ptr lv
            xor al, al
            mov dx, 0
            mov cx, 64h
            div cx
            mov scale, ax
            les si, pal
            lea di, buf
            mov bx, 300h
        l_scale:
            xor ah, ah
            mov al, es:[si]
            mov cx, scale
            mul cx
            mov [di], ah
            inc si
            inc di
            dec bx
            jne l_scale
        l_wait1:
            mov dx, 3DAh
            in al, dx
            test al, 8
            jne l_wait1
        l_wait2:
            in al, dx
            test al, 8
            je l_wait2
            mov dx, 3C8h
            mov al, 0
            out dx, al
            mov dx, 3C9h
            lea si, buf
            mov cx, 180h
        l_out1:
            mov al, [si]
            out dx, al
            inc si
            dec cx
            jne l_out1
        l_wait3:
            mov dx, 3DAh
            in al, dx
            test al, 8
            jne l_wait3
        l_wait4:
            in al, dx
            test al, 8
            je l_wait4
            mov dx, 3C8h
            mov al, 80h
            out dx, al
            mov dx, 3C9h
            lea si, buf
            add si, 180h
            mov cx, 180h
        l_out2:
            mov al, [si]
            out dx, al
            inc si
            dec cx
            jne l_out2
        }
        break;
    }
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
