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

#define NUM_STARS 45

void CyclePalette(void);               /* seg000 */
void WarpOut(void);               /* seg025 */
void CreatePlanet(Obj3D *o, char *name, int radius, int small, unsigned seed, int pal);
void RandomPlanet(Obj3D *o);

Obj3D dummy_planet;
extern Bitmap far *backbuf;
extern Bitmap far *screen;
extern long blink_count;

/* Positions of the stars on StarMap.bmp. */
Point star_pos[NUM_STARS] = {
    { 14, 16 }, { 28, 59 }, { 62, 32 }, { 102, 38 }, { 116, 33 }, { 167, 18 },
    { 245, 27 }, { 263, 8 }, { 294, 37 }, { 260, 63 }, { 253, 118 }, { 230, 122 },
    { 237, 93 }, { 220, 77 }, { 177, 62 }, { 167, 111 }, { 118, 79 }, { 90, 102 },
    { 73, 111 }, { 111, 124 }, { 21, 95 }, { 49, 28 }, { 81, 153 }, { 40, 133 },
    { 25, 121 }, { 112, 159 }, { 154, 169 }, { 160, 152 }, { 184, 135 }, { 213, 166 },
    { 271, 165 }, { 269, 136 }, { 297, 145 }, { 303, 103 }, { 279, 111 }, { 280, 85 },
    { 300, 14 }, { 217, 33 }, { 218, 55 }, { 166, 85 }, { 50, 44 }, { 151, 44 },
    { 156, 16 }, { 83, 72 }, { 150, 102 }
};

Point *NearestStar(int x, int y);

/* Make dummy_planet the planet of star n. */
void SetPlanet(int n)
{
    switch (n) {
    case 0:
        CreatePlanet(&dummy_planet, "cent", 500, 0, 453, 6);
        break;
    case 1:
        CreatePlanet(&dummy_planet, "cam", 500, 0, 293, 10);
        break;
    case 2:
        CreatePlanet(&dummy_planet, "ark7", 500, 0, 517, 11);
        break;
    case 3:
        CreatePlanet(&dummy_planet, "harl", 500, 0, 318, 12);
        break;
    case 4:
        CreatePlanet(&dummy_planet, "harrapa", 500, 0, 924, 18);
        break;
    case 5:
        CreatePlanet(&dummy_planet, "elasi", 500, 0, 341, 7);
        break;
    case 6:
        CreatePlanet(&dummy_planet, "digifal", 500, 0, 856, 8);
        break;
    case 7:
        CreatePlanet(&dummy_planet, "strah", 500, 0, 135, 0);
        break;
    case 8:
        CreatePlanet(&dummy_planet, "hrak", 500, 0, 392, 14);
        break;
    case 9:
        CreatePlanet(&dummy_planet, "trirho", 500, 0, 643, 13);
        break;
    case 10:
        CreatePlanet(&dummy_planet, "shiva", 500, 0, 832, 12);
        break;
    case 11:
        CreatePlanet(&dummy_planet, "alpha", 500, 0, 341, 11);
        break;
    case 12:
        CreatePlanet(&dummy_planet, "omega", 500, 0, 839, 10);
        break;
    case 13:
        CreatePlanet(&dummy_planet, "argos", 500, 0, 932, 7);
        break;
    case 14:
        CreatePlanet(&dummy_planet, "beta", 500, 0, 645, 14);
        break;
    case 15:
        CreatePlanet(&dummy_planet, "sirius", 500, 0, 234, 15);
        break;
    case 16:
        CreatePlanet(&dummy_planet, "sigma", 500, 0, 341, 16);
        break;
    case 17:
        CreatePlanet(&dummy_planet, "castor", 500, 0, 883, 17);
        break;
    case 18:
        CreatePlanet(&dummy_planet, "pollux", 500, 0, 752, 9);
        break;
    case 19:
        CreatePlanet(&dummy_planet, "christ", 500, 0, 234, 9);
        break;
    default:
        RandomPlanet(&dummy_planet);
        break;
    }
}

/* Let the player pick a star on the chart. Returns its number and sets up
 * its planet. */
int StarMap(void)
{
    char unused[76];
    Event *e;
    Point *star;
    Sprite cursor;
    MemHandle old_bmp;
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
    LoadFilePacked("StarMap", "bmp", screen);
    MemCpy(backbuf->data, screen->data, 64000);
    BlitToScreen(&screen_rect);
    UpdateSprites();
    FadeIn();
    for (;;) {
        if ((e = PeekEvent()) != 0) {
            switch (e->type) {
            case EV_TICK:
                CyclePalette();
                blink_count++;
                break;
            case EV_KEY:
                switch (((unsigned)e->key >> 8) & 0xFF) {
                case 0x1C:
                case 0x39:
                case 0x3B:
                case 0x3C:
                    goto pick;
                }
                break;
            case EV_DOWN1:
            case EV_DOWN2:
            pick:
                PopEvent();
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
    SpriteErase(&cursor);
    UpdateSprites();
    DelSprite(&cursor);
    ReleaseBitmap(cursor.handle);
    ReleaseBitmap(mouse_sprite.handle);
    SpriteSetBitmap(&mouse_sprite, old_bmp);
    WarpOut();
    LoadPalette("bridge");
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
