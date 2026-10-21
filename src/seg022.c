/* seg022: the star chart */

#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "sprite.h"
#include "gfx.h"
#include "event.h"
#include "obj3d.h"

typedef struct Point {
    int x;
    int y;
} Point;

#define NUM_STARS 20

void CycleBridge(void);                 /* seg001 */
void LockScreen(void);                  /* seg012 */
void UnlockScreen(void);
void PlayWarp(void);                   /* (c2A526) */
void PlayMusic(int seq, int next);      /* seg015 */

extern Bitmap far *backbuf;
extern Bitmap far *screen;
extern long blink_count;
extern unsigned char far *screen_base;
extern Rect screen_rect;

Point star_pos[NUM_STARS] = {
    { 42, 26}, { 45, 47}, { 21, 101}, { 65, 58}, {101, 16},
    {136, 18}, {181, 19}, {254, 14}, {283, 24}, {247, 31},
    {111, 84}, {154, 54}, {197, 57}, {239, 93}, {264, 63},
    { 94, 131}, {140, 105}, {149, 129}, {203, 103}, {268, 116},
};

Point *NearestStar(int x, int y);

/* Make the planet of star n (does nothing in this game). */
void SetPlanet(int n)
{
}

/* Let the player pick a star on the chart. Returns its number, or -1 if
 * the player cancels. */
int StarMap(void)
{
    Event *e;
    Point *star;
    Sprite cursor;
    MemHandle old_bmp;
    int ok;
    int sel;

    old_bmp = mouse_sprite.handle;
    SpriteSetBitmap(&mouse_sprite, LoadBitmap("cross"));
    star = NearestStar(mouse_sprite.x, mouse_sprite.y);
    MemSet(&cursor, sizeof(Sprite), 0);
    cursor.x = star->x;
    cursor.y = star->y;
    cursor.z = 14;
    cursor.handle = LoadBitmap("circle");
    AddSprite(&cursor);
    LockScreen();
    LoadFilePacked("StarMap", "bgd", screen_base);
    MemCpy(backbuf->data, screen->data, 64000);
    UnlockScreen();
    LoadPalette("palette");
    BlitToScreen(&screen_rect);
    UpdateSprites();
    FadeIn();
    for (;;) {
        if ((e = PeekEvent()) != 0) {
            switch (e->type) {
            case EV_TICK:
                CycleBridge();
                blink_count++;
                break;
            case EV_KEY:
                switch (((unsigned)e->key >> 8) & 0xFF) {
                case 0x1C:
                case 0x39:
                case 0x3B:
                case 0x3C:
                    ok = 1;
                    goto done;
                case 0x01:
                    ok = 0;
                    goto done;
                }
                break;
            case EV_DOWN1:
                ok = 1;
                goto done;
            case EV_DOWN2:
                ok = 0;
                goto done;
            case EV_MOVE:
                SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
                star = NearestStar(mouse_x, mouse_y);
                SpriteSetPos(&cursor, star->x, star->y, 14);
                UpdateSprites();
                break;
            }
            PopEvent();
        }
    }
done:
    PopEvent();
    SpriteErase(&cursor);
    UpdateSprites();
    DelSprite(&cursor);
    ReleaseBitmap(cursor.handle);
    ReleaseBitmap(mouse_sprite.handle);
    SpriteSetBitmap(&mouse_sprite, old_bmp);
    FadeOut();
    LockScreen();
    MemSet(screen->data, 64000, 0);
    UnlockScreen();
    if (ok) {
        PlayMusic(0xFE, 0xFE);
        PlayWarp();
    }
    MemSet((void far *)0xA0000000, 64000, 0);
    if (!ok)
        return -1;
    sel = star - star_pos;
    SetPlanet(sel);
    return sel;
}

void OffsetRect(Rect *out, Rect *r, int dx, int dy)
{
    out->x0 = r->x0 + dx;
    out->y0 = r->y0 + dy;
    out->x1 = r->x1 + dx;
    out->y1 = r->y1 + dy;
}

#define ABS(v) ((v) > 0 ? (v) : -(v))


Point *NearestStar(int x, int y)
{
    int n;
    int d;
    int best;
    Point *p;
    Point *found;

    best = 0x7FFF;
    for (p = star_pos, n = NUM_STARS; n != 0; --n, ++p) {
        d = ABS(p->x - x) + ABS(p->y - y);
        if (d < best) {
            found = p;
            best = d;
        }
    }
    return found;
}
