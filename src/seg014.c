/* seg014: menus */

#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "sprite.h"
#include "gfx.h"
#include "event.h"
#include "sound.h"
#include "menu.h"

/* Globals this file owns (declared in the headers). */
int menu_sel;
int menu_count;

void UpdateActors(void);               /* seg000 */
void DrawBans(void);
void UpdateBans(void);
void BridgeSfx(int a);              /* seg001 */
void ActionCursor(int a, int b);       /* seg008 */
void SaveMenu(void);               /* seg019: save game */
void LoadGameMenu(void);           /* seg019: load game */
void QuitMenu(int x, int y);       /* seg019: quit */
void TextModeMenu(int a);

extern int kbd_mouse;
extern int key_accel;
extern long blink_count;
extern int voc_wait;

Sprite *menu_sprites = 0;
long menu_disabled = 0;

/* The button of s[0..n-1] at (x, y), or -1. */
int MenuHit(Sprite *s, int n, int x, int y)
{
    Rect r;
    int i;
    Bitmap far *bmp;

    for (i = 0; i != n; ++i, ++s) {
        if (s->type == SPRITE_SHADOW) {
            bmp = LockMem(s->handle);
            r.x0 = s->x - bmp->x;
            r.y0 = s->y - bmp->y;
            r.x1 = s->x + bmp->w - 1;
            r.y1 = s->y + bmp->h - 1;
            UnlockMem(s->handle);
            if (x < r.x0 || x > r.x1 || y < r.y0 || y > r.y1)
                continue;
            return i;
        }
    }
    return -1;
}

/* Draw a frame of colour c just inside the edge of bitmap h. */
void DrawButtonFrame(MemHandle h, int c)
{
    int n;
    int n2;
    int stride;
    int off;
    unsigned char far *p;
    Bitmap far *bmp;

    bmp = LockMem(h);
    n = bmp->w - 2;
    off = (bmp->h - 3) * bmp->w;
    p = bmp->data + bmp->w + 1;
    while (n--) {
        *p = c;
        p[off] = c;
        p++;
    }
    n2 = bmp->h - 2;
    off = bmp->w - 3;
    p = bmp->data + bmp->w + 1;
    stride = bmp->w;
    while (n2--) {
        *p = c;
        p[off] = c;
        p += stride;
    }
    UnlockMem(h);
}

/* Show the buttons whose bits are set in mask and hide the others. */
void MenuShow(long mask)
{
    int i;
    long bit;

    for (i = 0, bit = 1; i != menu_count && bit; ++i, bit <<= 1) {
        if ((mask & bit) && menu_sprites[i].type == 0) {
            AddSprite(&menu_sprites[i]);
            menu_sprites[i].type = SPRITE_SHADOW;
            menu_sprites[i].dirty = 1;
        } else if ((mask & bit) == 0 && menu_sprites[i].type == SPRITE_SHADOW) {
            if (menu_sel == i) {
                DrawButtonFrame(menu_sprites[menu_sel].handle, 0);
                menu_sel = -1;
            }
            SpriteErase(&menu_sprites[i]);
        }
    }
    UpdateSprites();
    for (i = 0, bit = 1; i != menu_count && bit; ++i, bit <<= 1) {
        if ((mask & bit) == 0 && menu_sprites[i].type == SPRITE_SHADOW) {
            DelSprite(&menu_sprites[i]);
            menu_sprites[i].type = 0;
        }
    }
}

void MenuDisable(long mask)
{
    menu_disabled |= mask;
    if (menu_sel != -1 && ((1L << menu_sel) & menu_disabled)) {
        DrawButtonFrame(menu_sprites[menu_sel].handle, 0);
        menu_sprites[menu_sel].dirty = 1;
        menu_sel = -1;
    }
}

void MenuEnable(long mask)
{
    menu_disabled &= ~mask;
}

void MenuHome(void)
{
    MenuMove(menu_sprites, menu_count, -1, MENU_FIRST);
}

