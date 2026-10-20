/* seg021: sprites */

#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "sprite.h"

void Fatal(char *fmt, ...);     /* fatal error */

Sprite *sprite_array[MAX_SPRITES];
extern int video_mode;              /* 0 VGA, 1 EGA, 2 Tandy */
extern Bitmap far *backbuf;         /* sprites are composed here */
extern Bitmap far *screen;          /* the background without sprites */
void LockScreen(void);               /* seg012 */
void UnlockScreen(void);
extern unsigned char far *mask_buf; /* EGA priority mask, 2 pixels a byte */
unsigned char palette[256][3];

int sprite_count0 = 0;
Sprite **sprite_list = sprite_array;
int *sprite_count = &sprite_count0;

Rect dirty_rects[64];

int dirty_count;

unsigned char shade_table[256];

Rect screen_rect = { 1, 0, 319, 199 };    /* the sequel starts at x = 1 */

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
                if (s->old.x0 <= s->old.x1)     /* new: not an empty one */
                    dirty_rects[dirty_count++] = s->old;
            }
        } else if (s->dirty && s->old.x0 <= s->old.x1)
            dirty_rects[dirty_count++] = s->old;
    }
    LockScreen();
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
    UnlockScreen();
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
        if (s->visible)
            s->old = s->rect;
        else {
            s->old.x0 = s->old.y0 = -1;     /* new: empty */
            s->old.x1 = s->old.y1 = -2;
        }
    }
    for (r = dirty_rects, i = 0; i != dirty_count; ++i, ++r)
        BlitToScreen(r);
}

/* Draw just s, on a cleared screen (new in the sequel). */
void ShowSprite(Sprite *s)
{
    Rect r;
    Bitmap far *bmp;
    int i;

    bmp = LockMem(s->handle);
    s->ox = r.x0 = s->x - bmp->x;
    s->oy = r.y0 = s->y - bmp->y;
    r.x1 = r.x0 + bmp->w - 1;
    r.y1 = r.y0 + bmp->h - 1;
    UnlockMem(s->handle);
    MemSet(backbuf->data, 0xFA00, 0xDF);
    DrawSprite(s, &r);
    BlitToScreen(&screen_rect);
    s->old = screen_rect;
    RestoreBackground(&screen_rect);
    for (i = 0; i != *sprite_count; i++)
        sprite_list[i]->dirty = sprite_list[i]->visible;
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
            s->rect.x0 = s->rect.y0 = -1;   /* new: an empty rectangle */
            s->rect.x1 = s->rect.y1 = -2;
        }
    }
}

/* Colours for the 3-bit pixels of a glyph, per text colour; entry 5 is
 * also used for characters 10h-1Ah. 0 shades what is there instead. */
unsigned char glyph_colors[10][8] = {
    { 0x00, 0x87, 0x82, 0x82, 0x83, 0x84, 0x85, 0x86 },
    { 0x00, 0x8F, 0x88, 0x89, 0x8A, 0x8B, 0x8C, 0x8D },
    { 0x00, 0x87, 0x98, 0x99, 0x9A, 0x9B, 0x9C, 0x9D },
    { 0x00, 0xA7, 0xA2, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6 },
    { 0x00, 0xAF, 0xA8, 0xA8, 0xA9, 0xAA, 0xAB, 0xAC },
    { 0x00, 0x87, 0xB3, 0xB3, 0xB4, 0xB4, 0xB5, 0xB6 },
    { 0x00, 0xB7, 0xB0, 0xB0, 0xB1, 0xB2, 0xB3, 0xB4 },
    { 0x00, 0xBF, 0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBC },
    { 0x00, 0xC7, 0xC0, 0xC1, 0xC2, 0xC3, 0xC4, 0xC5 },
    { 0x00, 0x87, 0xC9, 0xCA, 0xCB, 0xCC, 0xCD, 0xCE },
};

/* Draw character c of a font (33 bytes each: three bitplanes of 11 rows)
 * at dst in colour color. New in the sequel. */
void DrawGlyph(unsigned char far *font, unsigned char c, unsigned char far *dst, unsigned color)
{
    unsigned char far *src;
    unsigned char *colors;
    int unused1;
    int unused2;

    src = font + c * 33;
    if (c >= 0x10 && c <= 0x1A)
        colors = glyph_colors[5];
    else if (color > 9)
        colors = glyph_colors[0];
    else
        colors = glyph_colors[color];
    _asm {
        push ds
        lds si, src
        les di, dst
        mov cx, 0Bh
    l_row:
        mov ah, [si]
        mov dl, [si+0Bh]
        mov dh, [si+16h]
        push cx
        mov cx, 8
    l_pixel:
        xor bx, bx
        rol dh, 1
        rcl bl, 1
        rol dl, 1
        rcl bl, 1
        rol ah, 1
        rcl bl, 1
        or bl, bl
        je l_shade
        add bx, colors
        mov al, ss:[bx]
        jmp short l_put
    l_shade:
        mov bl, es:[di]
        mov al, ss:shade_table[bx]
    l_put:
        stosb
        loop l_pixel
        pop cx
        inc si
        add di, 138h
        loop l_row
        pop ds
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
        unsigned char far *font;
        Rect r;

        font_h = CacheLoadEMS("font", "fon");
        font = LockMem(font_h);
        r = *clip;
        bmp = LockMem(s->handle);
        r.x0 = (r.x0 - s->ox) / 8;
        r.y0 = (r.y0 - s->oy) / 11;
        r.x1 = (r.x1 - s->ox) / 8;
        r.y1 = (r.y1 - s->oy) / 11;
        w = r.x1 - r.x0 + 1;
        h = r.y1 - r.y0 + 1;
        prio = s->z;
        dst = backbuf->data + (((r.y0 * 11 + s->oy) * 40 + r.x0) << 3) + s->ox;
        dstskip = (440 - w) << 3;
        src = bmp->data + (bmp->w >> 3) * r.y0 + r.x0;
        srcskip = (bmp->w >> 3) - w;
        while (h--) {
            n = w;
            while (n--) {
                DrawGlyph(font, *src, dst, s->colour);
                src++;
                dst += 8;
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

    LockScreen();
    dst = backbuf->data + r->y0 * 320 + r->x0;
    src = screen->data + r->y0 * 320 + r->x0;
    w = r->x1 - r->x0 + 1;
    h = r->y1 - r->y0 + 1;
    while (h--) {
        MemCpy(dst, src, w);
        dst += 320;
        src += 320;
    }
    UnlockScreen();
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

void BlitToScreen(Rect *r)
{
    unsigned w;
    unsigned h;
    int unused;
    unsigned char far *dst;
    unsigned char far *src;

    /* VGA only in the sequel */
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
/* The sequel: with masked set, a hit behind the room's depth mask
 * (4 bits a pixel) doesn't count. */
Sprite *SpriteAt(int x, int y, int masked)
{
    Sprite *s;
    int i;
    int dx;
    int dy;
    Bitmap far *bmp;
    unsigned char m;

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
                if (masked) {
                    m = mask_buf[y * 160 + (x >> 1)];
                    if (x & 1)
                        m >>= 4;
                    if ((m & 0xF) > s->z)
                        return 0;
                }
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
    if ((int)z < 0)             /* new: depth clamped to 0-15 */
        z = 0;
    else if (z > 15)
        z = 15;
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
