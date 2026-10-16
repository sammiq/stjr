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
extern unsigned char far *mask_buf; /* EGA priority mask, 2 pixels a byte */
unsigned char palette[256][3];

int sprite_count0 = 0;
Sprite **sprite_list = sprite_array;
int *sprite_count = &sprite_count0;

void SetSpriteList(Sprite **list, int *count)
{
    sprite_list = list;
    sprite_count = count;
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

int CompareSprites(Sprite **a, Sprite **b)
{
    register int d;

    if ((d = (*a)->z - (*b)->z) == 0)
        if ((d = (*a)->layer - (*b)->layer) == 0)
            if ((d = (*a)->y - (*b)->y) == 0)
                d = (*a)->x - (*b)->x;
    return d;
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
