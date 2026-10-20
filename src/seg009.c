/* seg009: the inventory */

#include <string.h>
#include "mem.h"
#include "cache.h"
#include "sprite.h"
#include "event.h"
#include "sound.h"

#define ITEM_FIRST  0x40        /* item ids start here */
#define ITEM_END    0x80
#define NUM_ITEMS   (ITEM_END - ITEM_FIRST)

typedef struct Item {
    char have;                  /* 00 */
    char name[9];               /* 01 bitmap name */
} Item;

/* As menu.h's MenuEntry. */
typedef struct InvEntry {
    char name[10];              /* 00 */
    int x;                      /* 0A */
    int y;                      /* 0C */
    int code;                   /* 0E */
} InvEntry;

void BridgeSfx(int a);              /* seg001 */
void UpdateActors(void);            /* seg000 */
void DrawBans(void);
void UpdateBans(void);
int FindObject(int x, int y);       /* seg008 */

/* seg014 */
int MenuHit(Sprite *s, int n, int x, int y);
void MenuMove(Sprite *s, int n, int cur, int dir);
void DrawButtonFrame(MemHandle h, int c);

extern Item items[NUM_ITEMS];
extern volatile int key_accel;     /* (volatile: the target stores key_accel = 0
                                     * and n = 0 as separate immediates) */
extern MemHandle talk_handle;       /* seg008: the room's conversations */
extern char far *talk_data;

InvEntry inv_ents[NUM_ITEMS];
char item_name[10];

/* Let the player point at the room's objects with the push button
 * pointer until a click or Enter. off is the offset in the talk data of
 * n pairs of an object and the offset of the name of the bitmap to show
 * while the pointer is on it. Returns the object pointed at last. */
/* (98.92%: the target loads bmp into si for the cleanup after done.) */
int sub_20AD4(int off, int n)
{
    Sprite label;
    char name[16];
    Event ev;
    MemHandle blank;
    MemHandle bmp;
    char far *data;
    int far *tab;
    int obj;
    int i;
    int last;

    bmp = 0;
    ReleaseBitmap(mouse_sprite.handle);
    SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
    n *= 2;
    blank = LoadBitmap("blank");
    SpriteInit(&label);
    AddSprite(&label);
    last = 0;
    SpriteSetPos(&label, 0, 0, 14);
    SpriteSetBitmap(&label, blank);
    for (;;) {
        if (!GetEvent(&ev))
            continue;
        switch (ev.type) {
        case EV_TICK:
            UpdateActors();
            DrawBans();
            UpdateSprites();
            UpdateBans();
            MusicTick();
            break;
        case EV_MOVE:
            SpriteSetPos(&mouse_sprite, ev.x, ev.y, 15);
            obj = FindObject(ev.x, ev.y);
            if (obj == last)
                break;
            if (bmp) {
                ReleaseBitmap(bmp);
                bmp = 0;
                SpriteSetBitmap(&label, blank);
            }
            data = LockMem(talk_handle);
            tab = (int far *)(data + off);
            for (i = 0; i != n; i += 2) {
                if (tab[i] == obj) {
                    if (tab[i + 1]) {
                        _fstrcpy(name, data + tab[i + 1]);
                        UnlockMem(talk_handle);
                        data = 0;
                        bmp = LoadBitmap(name);
                        SpriteSetBitmap(&label, bmp);
                    }
                    break;
                }
            }
            last = obj;
            if (data)
                UnlockMem(talk_handle);
            break;
        case EV_DOWN1:
            goto done;
        case EV_KEY:
            if (((unsigned)ev.key >> 8) == 0x1C)
                goto done;
            break;
        }
    }
done:
    SpriteErase(&label);
    UpdateSprites();
    DelSprite(&label);
    if (bmp)
        ReleaseBitmap(bmp);
    ReleaseBitmap(blank);
    return last;
}

/* The 9 character name at off in the talk data. */
char *ItemName(int off)
{
    talk_data = LockMem(talk_handle);
    MemCpy(item_name, talk_data + off, 10);
    item_name[9] = 0;
    UnlockMem(talk_handle);
    return item_name;
}

void ItemGive(int id)
{
    items[id - ITEM_FIRST].have = 1;
}

void ItemTake(int id)
{
    items[id - ITEM_FIRST].have = 0;
}

/* What the captain starts with. */
int start_items[6] = { 0x40, 0x41, 0x42, 0x43, 0x44, 0x45 };

void ItemsInit(void)
{
    int i;

    for (i = ITEM_FIRST; i != ITEM_END; i++)
        ItemTake(i);
    for (i = 6; i != 0; i--)
        ItemGive(start_items[i - 1]);
}

int ItemHave(int id)
{
    return (unsigned char)items[id - ITEM_FIRST].have;
}

/* Show the items carried in rows of five at (x, y) and let the player
 * pick one. Returns its id, or -1. restore: put the pointer back. */
int PickItem(int x, int y, int restore)
{
    Sprite *sprites;
    char name[10];
    int i;
    int n;
    int sel;
    int running;
    int count;
    Event *e;
    InvEntry *ents;
    unsigned old_x;
    unsigned old_y;
    int old_accel;

    sel = -1;
    old_x = mouse_x;
    old_y = mouse_y;
    old_accel = key_accel;
    key_accel = 0;
    for (n = 0, i = ITEM_FIRST; i < ITEM_END; i++) {
        if (items[i - ITEM_FIRST].have) {
            strcpy(inv_ents[n].name, items[i - ITEM_FIRST].name);
            inv_ents[n].x = n % 5 * 32 + x;
            inv_ents[n].y = n / 5 * 32 + y;
            inv_ents[n].code = i;
            n++;
        }
    }
    count = n;
    ents = inv_ents;
    sprites = AllocMemPtr(count * sizeof(Sprite));
    for (i = 0; i != count; i++) {
        AddSprite(&sprites[i]);
        sprites[i].type = SPRITE_SHADOW;
        SpriteSetPos(&sprites[i], ents[i].x, ents[i].y, 15);
        MemCpy(name, ents[i].name, 10);
        sprites[i].handle = CacheLoadEMS(name, "bmp");
        sprites[i].layer = 8;
    }
    MenuMove(sprites, count, -1, 4);
    running = 1;
    while (running) {
        MusicTick();
        if ((e = PeekEvent()) != 0) {
            switch (e->type) {
            case EV_KEY:
                switch (((unsigned)e->key >> 8) & 0xFF) {
                case 0x1C:
                case 0x3B:
                    goto pick;
                case 0x01:
                case 0x3C:
                    goto cancel;
                case 0x4D:
                    MenuMove(sprites, count, sel, 0);
                    break;
                case 0x4B:
                    MenuMove(sprites, count, sel, 1);
                    break;
                case 0x48:
                case 0x49:
                    MenuMove(sprites, count, sel, 2);
                    break;
                case 0x50:
                case 0x51:
                    MenuMove(sprites, count, sel, 3);
                    break;
                case 0x47:
                    MenuMove(sprites, count, sel, 4);
                    break;
                case 0x4F:
                    MenuMove(sprites, count, sel, 5);
                    break;
                }
                break;
            case EV_DOWN1:
            pick:
                running = 0;
                break;
            case EV_DOWN2:
            cancel:
                running = 0;
                if (sel != -1)
                    DrawButtonFrame(sprites[sel].handle, 0);
                sel = -1;
                break;
            case EV_TICK:
                i = MenuHit(sprites, count, mouse_x, mouse_y);
                if (i != sel) {
                    if (sel != -1) {
                        DrawButtonFrame(sprites[sel].handle, 0);
                        sprites[sel].dirty = 1;
                    }
                    if (i != -1) {
                        DrawButtonFrame(sprites[i].handle, 0xB8);
                        sprites[i].dirty = 1;
                    }
                    sel = i;
                }
                SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
                UpdateSprites();
                break;
            }
            PopEvent();
        }
    }
    BridgeSfx(1);
    if (sel >= 0)
        DrawButtonFrame(sprites[sel].handle, 0);
    for (i = 0; i != count; i++)
        SpriteErase(&sprites[i]);
    UpdateSprites();
    for (i = 0; i != count; i++) {
        CacheRelease(sprites[i].handle);
        DelSprite(&sprites[i]);
    }
    FreeMemPtr(sprites);
    if (sel >= 0)
        sel = inv_ents[sel].code;
    if (restore) {
        mouse_x = old_x;
        mouse_y = old_y;
        SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
        SetPointer(mouse_x, mouse_y);
    }
    key_accel = old_accel;
    return sel;
}
