/* seg021: sprites */

#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "sprite.h"

void Fatal(char *fmt, ...);     /* fatal error */

Sprite *sprite_array[MAX_SPRITES];
Rect dirty_rects[64];
int dirty_count;
extern int video_mode;              /* 0 VGA, 1 EGA, 2 Tandy */
extern Bitmap far *backbuf;         /* sprites are composed here */
extern Bitmap far *screen;          /* the background without sprites */
extern unsigned char far *mask_buf; /* EGA priority mask, 2 pixels a byte */
unsigned char palette[256][3];
unsigned char pal_remap[256];
unsigned char shade_table[256];

int sprite_count0 = 0;
Sprite **sprite_list = sprite_array;
int *sprite_count = &sprite_count0;
Rect screen_rect = { 0, 0, 319, 199 };
unsigned char ega_expand[16] = {
    0x00, 0x02, 0x08, 0x0A, 0x20, 0x22, 0x28, 0x2A,
    0x80, 0x82, 0x88, 0x8A, 0xA0, 0xA2, 0xA8, 0xAA
};
int pal_matched = 0;
unsigned char ega_palette[16][3] = {
    { 0x00, 0x00, 0x00 }, { 0x00, 0x00, 0x2A }, { 0x00, 0x2A, 0x00 }, { 0x00, 0x2A, 0x2A },
    { 0x2A, 0x00, 0x00 }, { 0x2A, 0x00, 0x2A }, { 0x2A, 0x15, 0x00 }, { 0x2A, 0x2A, 0x2A },
    { 0x15, 0x15, 0x15 }, { 0x15, 0x15, 0x3F }, { 0x15, 0x3F, 0x15 }, { 0x15, 0x3F, 0x3F },
    { 0x3F, 0x15, 0x15 }, { 0x3F, 0x15, 0x3F }, { 0x3F, 0x3F, 0x15 }, { 0x3F, 0x3F, 0x3F }
};

/* Assigns the parameters, not what they point to, so does nothing. */
void GetSpriteList(Sprite **list, int *count)
{
    list = sprite_list;
    count = sprite_count;
}

void SetSpriteList(Sprite **list, int *count)
{
    sprite_list = list;
    sprite_count = count;
}

void ResetSpriteList(void)
{
    sprite_list = sprite_array;
    sprite_count = &sprite_count0;
}

void MarkAllDirty(void)
{
    int i;
    Sprite *s;

    if (*sprite_count == 0)
        return;
    for (i = 0; i != *sprite_count; i++) {
        s = sprite_list[i];
        s->dirty = 1;
    }
}

void ClearSprites(void)
{
    *sprite_count = 0;
}

void SpriteInit(Sprite *s)
{
    s->type = 0;
    s->name = 0;
    s->erase = 0;
    s->old.x0 = s->old.y0 = -1;
    s->old.x1 = s->old.y1 = -2;
}

void AddSprite(Sprite *s)
{
    if (*sprite_count != MAX_SPRITES) {
        SpriteInit(s);
        sprite_list[(*sprite_count)++] = s;
    } else
        Fatal("AddSprite: fatal: too many sprites.");
}

void DelSprite(Sprite *s)
{
    int i;

    for (i = 0; i != *sprite_count; i++) {
        if (sprite_list[i] == s) {
            sprite_list[i] = sprite_list[--*sprite_count];
            return;
        }
    }
    Fatal("DelSprite: fatal: sprite not in list.");
}

void SpriteErase(Sprite *s)
{
    s->erase = 1;
    s->dirty = 1;
}

/* Restore the background under every changed sprite, redraw the sprites
 * touching those areas and copy them to the screen. */
void UpdateSprites(void)
{
    int i;
    Sprite *s;
    Rect *r;

    if (*sprite_count == 0)
        return;
    SortSprites();
    ComputeSpriteRects();
    dirty_count = 0;
    for (i = 0; i != *sprite_count; i++) {
        s = sprite_list[i];
        if (s->visible && s->dirty) {
            if (s->has_union)
                dirty_rects[dirty_count++] = s->union_rect;
            else {
                dirty_rects[dirty_count++] = s->rect;
                dirty_rects[dirty_count++] = s->old;
            }
        } else if (s->dirty)
            dirty_rects[dirty_count++] = s->old;
    }
    switch (video_mode) {
    case 0:
    case 2:
        for (r = dirty_rects, i = 0; i != dirty_count; ++i, ++r)
            RestoreBackground(r);
        break;
    case 1:
        for (r = dirty_rects, i = 0; i != dirty_count; ++i, ++r) {
            r->x0 &= ~3;
            r->x1 |= 3;
            RestoreBackground(r);
        }
        break;
    }
    for (i = 0; i != *sprite_count; i++) {
        s = sprite_list[i];
        if (s->erase == 0 && s->visible) {
            Rect clip;
            Rect area;
            int j;
            int found;

            found = 0;
            for (r = dirty_rects, j = 0; j != dirty_count; ++j, ++r) {
                if (ClipRect(&clip, &s->rect, r)) {
                    if (found)
                        UnionRect(&area, &area, &clip);
                    else {
                        area = clip;
                        found = 1;
                    }
                }
            }
            if (found)
                DrawSprite(s, &area);
        }
        s->erase = 0;
        s->dirty = 0;
        s->old = s->rect;
    }
    for (r = dirty_rects, i = 0; i != dirty_count; ++i, ++r)
        BlitToScreen(r);
}

void SortSprites(void)
{
    qsort(sprite_list, *sprite_count, sizeof(Sprite *), CompareSprites);
}

int CompareSprites(Sprite **a, Sprite **b)
{
    register int d;

    if ((d = (*a)->z - (*b)->z) == 0)
        if ((d = (*a)->layer - (*b)->layer) == 0)
            if ((d = (*a)->y - (*b)->y) == 0)
                d = (*a)->x - (*b)->x;
    return d;
}

void ComputeSpriteRects(void)
{
    Rect r;
    Sprite *s;
    int i;
    Bitmap far *bmp;

    for (i = 0; i != *sprite_count; i++) {
        s = sprite_list[i];
        bmp = LockMem(s->handle);
        s->ox = r.x0 = s->x - bmp->x;
        s->oy = r.y0 = s->y - bmp->y;
        r.x1 = r.x0 + bmp->w - 1;
        r.y1 = r.y0 + bmp->h - 1;
        UnlockMem(s->handle);
        if (ClipRect(&s->rect, &screen_rect, &r)) {
            if (s->old.x0 <= s->old.x1) {
                if (ClipRect(&r, &s->rect, &s->old)) {
                    UnionRect(&s->union_rect, &s->rect, &s->old);
                    s->has_union = 1;
                } else
                    s->has_union = 0;
            } else {
                s->union_rect = s->rect;
                s->has_union = 1;
            }
            s->visible = 1;
        } else {
            s->visible = 0;
            s->has_union = 0;
        }
    }
}

/* Draw the part clip of a sprite into the back buffer. */
void DrawSprite(Sprite *s, Rect *clip)
{
    unsigned char far *mask;
    int unused1;
    unsigned char far *src;
    unsigned char far *dst;
    unsigned w;
    unsigned h;
    int maskskip;
    int unused2;
    int srcskip;
    int dstskip;
    int unused3;
    int unused4;
    int prio;
    unsigned n;
    Bitmap far *bmp;

    w = clip->x1 - clip->x0 + 1;
    h = clip->y1 - clip->y0 + 1;
    if (w <= 0 || h <= 0)
        Fatal("DrawSprite: w/h <= 0");
    prio = s->z;
    dst = backbuf->data + clip->y0 * 320 + clip->x0;
    dstskip = 320 - w;
    if (s->type == SPRITE_TEXT) {
        MemHandle font_h;
        char far *font;
        Rect r;

        font_h = CacheLoad("font", "fnt");
        font = LockMem(font_h);
        r = *clip;
        bmp = LockMem(s->handle);
        r.x0 = (r.x0 - s->ox) >> 3;
        r.y0 = (r.y0 - s->oy) >> 3;
        r.x1 = (r.x1 - s->ox) >> 3;
        r.y1 = (r.y1 - s->oy) >> 3;
        w = r.x1 - r.x0 + 1;
        h = r.y1 - r.y0 + 1;
        prio = s->z;
        dst = backbuf->data + s->oy * 320 + s->ox + (r.y0 << 3) * 320 + (r.x0 << 3);
        dstskip = 2560 - (w << 3);
        src = bmp->data + r.x0 + r.y0 * (bmp->w >> 3);
        srcskip = (bmp->w >> 3) - w;
        while (h--) {
            n = w;
            while (n--) {
                char far *glyph;
                int gy;
                int gx;
                char colour;

                colour = (*src >= 0x10 && *src <= 0x1A) ? 0xB3 : s->colour;
                glyph = font + *src * 64;
                for (gy = 0; gy != 8; gy++) {
                    for (gx = 0; gx != 8; gx++) {
                        if (*glyph == 0)
                            *dst = shade_table[*dst];
                        else if (*glyph == 'x')
                            *dst = colour;
                        else
                            *dst = *glyph;
                        glyph++;
                        dst++;
                    }
                    dst += 312;
                }
                src++;
                dst -= 2552;
            }
            src += srcskip;
            dst += dstskip;
        }
        UnlockMem(s->handle);
        UnlockMem(font_h);
        CacheRelease(font_h);
    } else if (s->type == SPRITE_SHADOW) {
        bmp = LockMem(s->handle);
        src = bmp->data + (clip->x0 - s->ox) + (clip->y0 - s->oy) * bmp->w;
        srcskip = bmp->w - w;
        while (h--) {
            n = w;
            while (n--) {
                if (*src)
                    *dst = *src;
                else
                    *dst = shade_table[*dst];
                src++;
                dst++;
            }
            src += srcskip;
            dst += dstskip;
        }
        UnlockMem(s->handle);
    } else if (s->type == SPRITE_RECT)
        ;
    else {
        bmp = LockMem(s->handle);
        src = bmp->data + (clip->x0 - s->ox) + (clip->y0 - s->oy) * bmp->w;
        srcskip = bmp->w - w;
        mask = mask_buf + clip->y0 * 160 + (clip->x0 >> 1);
        maskskip = 160 - (((clip->x1 + 1) >> 1) - (clip->x0 >> 1));
        /* The mask is reached through ss so ds can address the bitmap;
         * locals are then reached with ds: overrides. A mask nibble at
         * or below the sprite's priority hides the pixel. */
        _asm {
            push bp
            push si
            push di
            mov cx, ss
            mov dx, sp
            mov bx, word ptr mask
            mov ax, word ptr mask+2
            mov ss, ax
            mov sp, 7E00h
            push ds:w
            push ds:h
            push ds:srcskip
            push ds:dstskip
            push ds:maskskip
            push cx
            push dx
            les di, ds:dst
            mov dl, byte ptr ds:prio
            mov dh, dl
            shl dh, 4
            or dh, 0Fh
            lds si, ds:src
            mov bp, sp
        l_row:
            mov cx, [bp+0Ch]
            test di, 1
            je l_even
            mov ah, ss:[bx]
            inc bx
            inc cx
            shr cx, 1
            pushf
            jmp l_odd
        l_even:
            shr cx, 1
            je l_last
            pushf
        l_pair:
            mov ah, ss:[bx]
            inc bx
            stc
            sbb ah, dh
            jae l_skip2
            lodsb
            or al, al
            je l_skip2b
            stosb
        l_odd:
            and ah, 0Fh
            cmp ah, dl
            ja l_skip1
            lodsb
            or al, al
            je l_skip1b
            stosb
            loop l_pair
        l_popf:
            popf
        l_last:
            jae l_next
            mov ah, ss:[bx]
            stc
            sbb ah, dh
            jae l_skip3
            lodsb
            or al, al
            je l_skip3b
            stosb
            jmp l_next
        l_skip2:
            inc si
        l_skip2b:
            inc di
            jmp l_odd
        l_skip1:
            inc si
        l_skip1b:
            inc di
            loop l_pair
            jmp l_popf
        l_skip3:
            inc si
        l_skip3b:
            inc di
        l_next:
            add si, [bp+8]
            add di, [bp+6]
            add bx, [bp+4]
            dec byte ptr [bp+0Ah]
            jne l_row
            pop dx
            pop cx
            mov ss, cx
            mov sp, dx
            mov ds, cx
            pop di
            pop si
            pop bp
        }
        UnlockMem(s->handle);
    }
}

/* Copy r of the background into the back buffer. */
void RestoreBackground(Rect *r)
{
    unsigned w;
    unsigned h;
    int unused;
    unsigned char far *dst;
    unsigned char far *src;

    dst = backbuf->data + r->y0 * 320 + r->x0;
    src = screen->data + r->y0 * 320 + r->x0;
    w = r->x1 - r->x0 + 1;
    h = r->y1 - r->y0 + 1;
    while (h--) {
        MemCpy(dst, src, w);
        dst += 320;
        src += 320;
    }
}

/* Build pal_remap, mapping colours first..first+count-1 of pal to the
 * nearest of the 256 EGA colour pairs (dithered as two pixels). */
void MatchPalette(unsigned char far *pal, int first, int count)
{
    int i;
    int j;

    if (pal_matched == 0) {
        pal_matched = 1;
        for (i = 0; i < 256; i++)
            for (j = 0; j < 3; j++)
                palette[i][j] = (ega_palette[i >> 4][j] >> 1) + (ega_palette[i & 15][j] >> 1);
    }
    for (i = first; i < first + count; i++) {
        int r;
        int g;
        int b;
        int best;
        int best_i;

        r = pal[i * 3];
        g = pal[i * 3 + 1];
        b = pal[i * 3 + 2];
        best = 0x7FFF;
        best_i = 0;
        for (j = 0; j < 256; j++) {
            int dr;
            int dg;
            int db;
            int d;

            dr = palette[j][0] - r;
            dg = palette[j][1] - g;
            db = palette[j][2] - b;
            d = dr * dr + dg * dg + db * db;
            if (d < best) {
                best_i = j;
                best = d;
            }
        }
        if (video_mode == 1)
            pal_remap[i] = ega_expand[best_i >> 4] | (ega_expand[best_i & 15] >> 1);
        else
            pal_remap[i] = best_i;
    }
}

void LoadRemap(char *name)
{
    int i;
    int c;

    switch (video_mode) {
    case 0:
        break;
    case 1:
        LoadFilePacked(name, "ega", pal_remap);
        for (i = 0; i < 256; i++) {
            c = pal_remap[i];
            pal_remap[i] = ega_expand[c >> 4] | (ega_expand[c & 15] >> 1);
        }
        break;
    case 2:
        LoadFilePacked(name, "ega", pal_remap);
        break;
    }
}

/* Copy r of the back buffer to EGA memory. Each pixel pair is remapped to
 * a byte of two 4 bit pixels, and every 8 pixels are converted to planar
 * form; runs of black are filled with write mode 2. */
void BlitEGA(Rect *r)
{
    unsigned x0;
    unsigned x1;
    unsigned n;
    int h;
    int srcskip;
    int dstskip;
    unsigned char far *src;
    unsigned char far *dst;

    x0 = r->x0 & ~3;
    x1 = r->x1 | 3;
    dst = (unsigned char far *)0xA0000000L + ((r->y0 * 320 + x0) >> 2);
    src = backbuf->data + r->y0 * 320 + x0;
    n = (x1 + 1 - x0) >> 2;
    h = r->y1 - r->y0 + 1;
    srcskip = 320 - (n << 2);
    dstskip = 80 - n;
    _asm {
        push si
        push di
        mov dx, 3CEh
        mov ax, 0FF08h
        out dx, ax
        mov dx, 3C4h
        mov al, 2
        out dx, al
        mov dx, 3C5h
        mov cx, h
        lea bx, pal_remap
        les di, dst
        lds si, src
        jmp l_row
    l_next:
        add si, srcskip
        add di, dstskip
    l_row:
        push cx
        mov cx, n
        jmp l_pix
    l_zero:
        or ax, [si]
        je l_run
        xor cx, cx
        jmp l_out
    l_pix:
        push cx
        lodsw
        or ax, ax
        je l_zero
        _emit 36h
        xlat [bx]
        xchg al, ah
        _emit 36h
        xlat [bx]
        mov cx, ax
    l_out:
        mov al, 1
        out dx, al
        lodsw
        _emit 36h
        xlat [bx]
        xchg al, ah
        _emit 36h
        xlat [bx]
        xchg cl, ah
        ror cx, 4
        rol cl, 4
        rol cx, 4
        ror ax, 4
        rol al, 4
        rol ax, 2
        mov dx, cx
        xor dx, ax
        and dx, 3333h
        xor cx, dx
        xor ax, dx
        rol ax, 2
        mov dx, 3C5h
        mov es:[di], al
        mov al, 2
        out dx, al
        mov es:[di], cl
        mov al, 4
        out dx, al
        mov es:[di], ah
        mov al, 8
        out dx, al
        mov es:[di], ch
        inc di
        pop cx
        loop l_pix
    l_rowend:
        pop cx
        loop l_next
        jmp l_done
    l_run:
        pop cx
        mov al, 0Fh
        out dx, al
        mov dx, 1
        dec cx
        je l_runend
    l_scan:
        add si, 2
        inc dx
        lodsw
        or ax, [si]
        loope l_scan
        je l_runend
        sub si, 4
        dec dx
        inc cx
    l_runend:
        add si, 2
        push cx
        mov cx, dx
        mov dx, 3CEh
        mov ax, 205h
        out dx, ax
        xor al, al
        rep stosb
        mov ax, 5
        out dx, ax
        mov dx, 3C5h
        pop cx
        jcxz l_rowend
        jmp l_pix
    l_done:
        mov ax, ss
        mov ds, ax
        pop di
        pop si
    }
}

/* Unused: colour bars for checking the palette. */
void DrawTestPattern(void)
{
    Rect r;
    int x;
    int y;

    for (x = 0; x < 320; x++)
        for (y = 0; y < 160; y++)
            backbuf->data[(y + 10) * 320 + x] = x / 20 + y / 10 * 16;
    r.x0 = 0;
    r.y0 = 10;
    r.x1 = 319;
    r.y1 = 169;
    BlitToScreen(&r);
}

/* Copy r of the back buffer to Tandy video memory through pal_remap. */
void BlitTandy(Rect *r)
{
    int w;
    int h;
    int skip;
    unsigned char far *dst;
    unsigned char far *src;

    dst = (unsigned char far *)0xA0000000L + r->y0 * 320 + r->x0;
    src = backbuf->data + r->y0 * 320 + r->x0;
    w = r->x1 - r->x0 + 1;
    h = r->y1 - r->y0 + 1;
    skip = 320 - w;
    _asm {
        push si
        push di
        mov dx, skip
        mov cx, h
        lea bx, pal_remap
        les di, dst
        lds si, src
    l_row:
        push cx
        mov cx, w
    l_pix:
        lodsb
        _emit 36h
        xlat [bx]
        stosb
        loop l_pix
        add si, dx
        add di, dx
        pop cx
        loop l_row
        mov ax, ss
        mov ds, ax
        pop di
        pop si
    }
}

void BlitToScreen(Rect *r)
{
    unsigned w;
    unsigned h;
    int unused;
    unsigned char far *dst;
    unsigned char far *src;

    switch (video_mode) {
    case 1:
        BlitEGA(r);
        return;
    case 2:
        BlitTandy(r);
        return;
    default:
        break;
    }
    dst = (unsigned char far *)0xA0000000L + r->y0 * 320 + r->x0;
    src = backbuf->data + r->y0 * 320 + r->x0;
    w = r->x1 - r->x0 + 1;
    h = r->y1 - r->y0 + 1;
    while (h--) {
        MemCpy(dst, src, w);
        dst += 320;
        src += 320;
    }
}

/* The topmost sprite with a non-zero pixel at (x, y), ignoring the mouse
 * pointer. */
Sprite *SpriteAt(int x, int y)
{
    Sprite *s;
    int i;
    int dx;
    int dy;
    Bitmap far *bmp;

    for (i = *sprite_count - 1; i >= 0; i--) {
        s = sprite_list[i];
        if (s != &mouse_sprite && s->type != SPRITE_RECT
                && x >= s->rect.x0 && x <= s->rect.x1
                && y >= s->rect.y0 && y <= s->rect.y1) {
            bmp = LockMem(s->handle);
            dx = x - s->ox;
            dy = y - s->oy;
            if (s->type == SPRITE_SHADOW || s->type == SPRITE_TEXT
                    || ((unsigned char far *)bmp->data)[dy * bmp->w + dx]) {
                UnlockMem(s->handle);
                return s;
            }
            UnlockMem(s->handle);
        }
    }
    return 0;
}

void SpriteSetPos(Sprite *s, int x, int y, unsigned z)
{
    s->x = x;
    s->y = y;
    s->z = z;
    s->dirty = 1;
}

void SpriteSetBitmap(Sprite *s, MemHandle h)
{
    s->handle = h;
    s->dirty = 1;
}

/* Add s as an invisible rectangle, using h as an empty bitmap header. */
void SpriteAddRect(Sprite *s, MemHandle h, int x0, int y0, int x1, int y1)
{
    Bitmap far *bmp;

    SpriteSetPos(s, x0, y0, 0);
    SpriteSetBitmap(s, h);
    bmp = LockMem(h);
    bmp->x = 0;
    bmp->y = 0;
    bmp->w = x1 - x0 + 1;
    bmp->h = y1 - y0 + 1;
    UnlockMem(h);
    AddSprite(s);
    s->type = SPRITE_RECT;
}

void RedrawSpritesIn(Rect *r)
{
    int i;
    Sprite *s;
    Rect clip;

    if (*sprite_count == 0)
        return;
    for (i = 0; i != *sprite_count; i++) {
        s = sprite_list[i];
        if (s->visible && ClipRect(&clip, &s->rect, r))
            DrawSprite(s, &clip);
    }
}
