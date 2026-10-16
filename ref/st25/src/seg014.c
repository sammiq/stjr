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
unsigned mouse_x;
unsigned mouse_y;

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
int stream_done;
extern int voc_wait;
MemHandle menu_handle;
int menu_saved_accel;

Sprite *menu_sprites = 0;
int *menu_ids = 0;
long menu_disabled = 0;
MenuSave *menu_stack = 0;

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

/* Move the pointer to the middle of the button next to button cur in
 * direction dir, wrapping round. */
void MenuMove(Sprite *s, int n, int cur, int dir)
{
    int i;
    unsigned bx;
    unsigned by;
    unsigned wx;
    unsigned wy;
    Bitmap far *bmp;
    unsigned x0;
    unsigned x1;
    unsigned y0;
    unsigned y1;
    unsigned mx;
    unsigned my;

    bx = 0x7FFF;
    by = 0x7FFF;
    wx = 0x7FFF;
    wy = 0x7FFF;
    if (0 <= cur && cur < n) {
        bmp = LockMem(s[cur].handle);
        x0 = s[cur].x - bmp->x;
        x1 = x0 + bmp->w - 1;
        y0 = s[cur].y - bmp->y;
        y1 = y0 + bmp->h - 1;
        if (mouse_x < x0 || x1 < mouse_x || mouse_y < y0 || y1 < mouse_y) {
            mouse_x = (x0 + x1 + 1) / 2;
            mouse_y = (y0 + y1 + 1) / 2;
        }
        UnlockMem(s[cur].handle);
    }
    for (i = 0; i != n; ++i, ++s) {
        if (s->type == SPRITE_SHADOW) {
            bmp = LockMem(s->handle);
            x0 = s->x - bmp->x;
            x1 = x0 + bmp->w - 1;
            y0 = s->y - bmp->y;
            y1 = y0 + bmp->h - 1;
            mx = (x0 + x1 + 1) / 2;
            my = (y0 + y1 + 1) / 2;
            UnlockMem(s->handle);
            switch (dir) {
            case MENU_NEXT:
                if ((my == mouse_y && mx > mouse_x) || my > mouse_y) {
                    if (my < by || (my == by && mx < bx)) {
                        bx = mx;
                        by = my;
                    }
                }
            case MENU_FIRST:
                if (my < wy || (my == wy && mx < wx)) {
                    wx = mx;
                    wy = my;
                }
                break;
            case MENU_PREV:
                if ((my == mouse_y && mx < mouse_x) || my < mouse_y) {
                    if (by == 0x7FFF || my > by || (my == by && mx > bx)) {
                        bx = mx;
                        by = my;
                    }
                }
            case MENU_LAST:
                if (wy == 0x7FFF || my > wy || (my == wy && mx > wx)) {
                    wx = mx;
                    wy = my;
                }
                break;
            case MENU_DOWN:
                if (my > mouse_y || (my == by && mx == mouse_x)) {
                    if (bx == 0x7FFF || my <= by) {
                        bx = mx;
                        by = my;
                    }
                }
                if (wx == 0x7FFF || my < wy || (mx == wx && my == wy)) {
                    wx = mx;
                    wy = my;
                }
                break;
            case MENU_UP:
                if (my < mouse_y || (my == by && mx == mouse_x)) {
                    if (bx == 0x7FFF || my >= by) {
                        bx = mx;
                        by = my;
                    }
                }
                if (wx == 0x7FFF || my > wy || (mx == wx && my == wy)) {
                    wx = mx;
                    wy = my;
                }
                break;
            }
        }
    }
    if (bx == 0x7FFF) {
        bx = wx;
        by = wy;
    }
    if (bx != 0x7FFF) {
        mouse_x = bx;
        mouse_y = by;
    }
    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
    SetPointer(mouse_x, mouse_y);
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

/* The options menu: save, load, music and sound on/off, quit. */
void OptionsMenu(int x, int y)
{
    int sel;
    int flags;
    int old_kbd;
    unsigned old_x;
    unsigned old_y;
    MemHandle old_bmp;

    old_kbd = kbd_mouse;
    old_x = mouse_x;
    old_y = mouse_y;
    old_bmp = mouse_sprite.handle;
    kbd_mouse = 0;
    SpriteSetBitmap(&mouse_sprite, LoadBitmap("options"));
    LoadMenu("options", x, y);
    flags = 0;
    if (midi_ok == 1)
        flags |= 1L << (music_on ? 3 : 4);
    else
        flags |= 0x18;
    if (digi_ok == 1)
        flags |= 1L << (sfx_on ? 5 : 6);
    else
        flags |= 0x60;
    MenuDisable(flags);
    MenuHome();
    sel = MenuLoop(0, 0);
    MenuClose();
    kbd_mouse = old_kbd;
    ReleaseBitmap(mouse_sprite.handle);
    SpriteSetBitmap(&mouse_sprite, old_bmp);
    if (sel != MENU_NONE && sel != MENU_CANCEL) {
        mouse_x = old_x;
        mouse_y = old_y;
        SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
        SetPointer(mouse_x, mouse_y);
    }
    switch (sel) {
    case 0:
        SaveMenu();
        break;
    case 1:
        LoadGameMenu();
        break;
    case 2:
        SetMusicOn(1);
        break;
    case 3:
        SetMusicOn(0);
        break;
    case 4:
        SetSfxOn(1);
        break;
    case 5:
        SetSfxOn(0);
        break;
    case 6:
        QuitMenu(20, 20);
        break;
    case 7:
        TextModeMenu(1);
        break;
    }
}

/* The action panel: walk, look, talk, use, get and options. The pointer
 * changes to the action under it. Returns the action chosen (1 walk). */
int ActionPanel(void)
{
    char unused1[16];
    int mode;
    int unused2;
    int sel;
    int running;
    Event e;
    Sprite panel;
    int x;
    int y;
    int dx;
    int dy;
    unsigned old_x;
    unsigned old_y;
    int w;
    int h;
    int clicked;
    int old_accel;
    char *cursor;

    sel = 1;
    x = 50;
    y = 50;
    clicked = 0;
    old_accel = key_accel;
    key_accel = 0;
    mode = 2;
    panel.handle = LoadBitmap("action");
    {
        Bitmap far *bmp;

        bmp = LockMem(panel.handle);
        w = bmp->w;
        h = bmp->h;
        UnlockMem(panel.handle);
    }
    old_x = mouse_x;
    old_y = mouse_y;
    mouse_x = w / 2 + x;
    mouse_y = h / 2 + y;
    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
    SetPointer(mouse_x, mouse_y);
    AddSprite(&panel);
    SpriteSetPos(&panel, x, y, 15);
    ActionCursor(sel, 0);
    UpdateSprites();
    panel.layer = 8;
    running = 1;
    while (running) {
        MusicTick();
        if (GetEvent(&e)) {
            switch (e.type) {
            case EV_KEY:
                {
                    int key;
                    int sel2;

                    key = ((unsigned)e.key >> 8) & 0xFF;
                    switch (key) {
                    case 0x1C:
                    case 0x3B:
                        goto click;
                    case 0x01:
                    case 0x39:
                    case 0x3C:
                        goto cancel;
                    default:
                        sel2 = sel;
                        if (key == 0x49)
                            sel2 = 13;
                        else if (key == 0x51)
                            sel2 = 3;
                        else {
                            switch (sel) {
                            case 2:
                                if (key == 0x4D || key == 0x50)
                                    sel2 = 1;
                                else if (key == 0x48)
                                    sel2 = 5;
                                break;
                            case 3:
                                if (key == 0x48)
                                    sel2 = 13;
                                else if (key == 0x4B)
                                    sel2 = 1;
                                break;
                            case 1:
                                if (key == 0x4B)
                                    sel2 = 2;
                                else if (key == 0x4D || key == 0x50)
                                    sel2 = 3;
                                else if (key == 0x48)
                                    sel2 = 5;
                                break;
                            case 5:
                                if (key == 0x4B)
                                    sel2 = 2;
                                else if (key == 0x4D)
                                    sel2 = 13;
                                else if (key == 0x48)
                                    sel2 = 4;
                                else if (key == 0x50)
                                    sel2 = 1;
                                break;
                            case 4:
                                if (key == 0x4B)
                                    sel2 = 2;
                                else if (key == 0x4D)
                                    sel2 = 13;
                                else if (key == 0x50)
                                    sel2 = 5;
                                break;
                            case 13:
                                if (key == 0x4B)
                                    sel2 = 4;
                                else if (key == 0x50)
                                    sel2 = 3;
                                break;
                            }
                        }
                        if (sel2 != sel) {
                            switch (sel2) {
                            case 13:
                                mouse_x = 45, mouse_y = 9;
                                break;
                            case 4:
                                mouse_x = 28, mouse_y = 5;
                                break;
                            case 5:
                                mouse_x = 28, mouse_y = 14;
                                break;
                            case 2:
                                mouse_x = 7, mouse_y = 21;
                                break;
                            case 3:
                                mouse_x = 46, mouse_y = 38;
                                break;
                            case 1:
                                mouse_x = w / 2;
                                mouse_y = h / 2;
                                break;
                            }
                            mouse_x += x;
                            mouse_y += y;
                            SetPointer(mouse_x, mouse_y);
                            goto move;
                        }
                        break;
                    }
                }
                break;
            case EV_DOWN1:
            click:
                running = 0;
                clicked = 1;
                break;
            case EV_DOWN2:
            cancel:
                running = 0;
                sel = 1;
                break;
            case EV_MOVE:
            move:
                dx = mouse_x - x;
                dy = mouse_y - y;
                if (dx >= 39 && dx <= 50 && dy >= 2 && dy <= 17) {
                    sel = 13;
                    cursor = "options";
                    SpriteSetPos(&mouse_sprite, x + 44, y + 2, 15);
                } else if (dx >= 18 && dx <= 38 && dy >= 2 && dy <= 9) {
                    sel = 4;
                    cursor = "look";
                    SpriteSetPos(&mouse_sprite, x + 28, y + 6, 15);
                } else if (dx >= 18 && dx <= 38 && dy >= 11 && dy <= 17) {
                    sel = 5;
                    cursor = "talk";
                    SpriteSetPos(&mouse_sprite, x + 27, y + 14, 15);
                } else if (dx >= 2 && dx <= 13 && dy >= 16 && dy <= 26) {
                    sel = 2;
                    cursor = "use";
                    SpriteSetPos(&mouse_sprite, x + 7, y + 19, 15);
                } else if (dx >= 40 && dx <= 53 && dy >= 34 && dy <= 43) {
                    sel = 3;
                    cursor = "get";
                    SpriteSetPos(&mouse_sprite, x + 44, y + 38, 15);
                } else {
                    sel = 1;
                    cursor = "walk";
                    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
                }
                ReleaseBitmap(mouse_sprite.handle);
                SpriteSetBitmap(&mouse_sprite, LoadBitmap(cursor));
                break;
            case EV_TICK:
                FadeUp();
                UpdateSprites();
                break;
            }
        }
    }
    BridgeSfx(16);
    SpriteErase(&panel);
    UpdateSprites();
    DelSprite(&panel);
    ReleaseBitmap(panel.handle);
    if (sel == 13) {
        OptionsMenu(50, 50);
        sel = 1;
    }
    if (mouse_x >= x && mouse_x < x + w && mouse_y >= y && mouse_y < y + h) {
        mouse_x = old_x;
        mouse_y = old_y;
        SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
        SetPointer(mouse_x, mouse_y);
    } else if (sel == 1 && clicked)
        PostEvent(&e);
    ActionCursor(sel, 0);
    key_accel = old_accel;
    return sel;
}

/* Open menu name.mnu at (x, y), over any menu already open. */
void LoadMenu(char *name, int x, int y)
{
    char bname[10];
    int i;
    int any;

    if (menu_sprites) {
        MenuSave *save;

        save = AllocMemPtr(16);
        save->sprites = menu_sprites;
        save->ids = menu_ids;
        save->disabled = menu_disabled;
        save->handle = menu_handle;
        save->count = menu_count;
        save->sel = menu_sel;
        save->next = menu_stack;
        menu_stack = save;
    } else
        menu_saved_accel = key_accel;
    menu_count = GetFileSize(name, "mnu") / 16;
    menu_handle = CacheLoad(name, "mnu");
    menu_sprites = AllocMemPtr(menu_count * sizeof(Sprite));
    menu_ids = AllocMemPtr(menu_count * 2);
    any = 0;
    for (i = 0; i != menu_count; i++) {
        MenuEntry far *ents;
        MemHandle h;

        AddSprite(&menu_sprites[i]);
        menu_sprites[i].type = SPRITE_SHADOW;
        ents = LockMem(menu_handle);
        SpriteSetPos(&menu_sprites[i], ents[i].x + x, ents[i].y + y, 15);
        MemCpy(bname, ents[i].name, 10);
        menu_ids[i] = ents[i].id;
        any |= ents[i].id;
        UnlockMem(menu_handle);
        h = CacheLoad(bname, "bmp");
        menu_sprites[i].handle = h;
        menu_sprites[i].layer = 8;
    }
    if (any == 0)
        for (i = 0; i != menu_count; i++)
            menu_ids[i] = i;
    menu_sel = -1;
    menu_disabled = 0;
    key_accel = 0;
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

/* Run the open menu until a button is chosen. Returns its id, or one of
 * the MENU_ results. keys: the keypad picks buttons 1-8 directly instead
 * of moving between them. */
int MenuLoop(unsigned long timeout, int keys)
{
    int hit;
    Event e;
    unsigned long end;
    int result;
    int unused;

    end = ticks + timeout;
    for (;;) {
        if (GetEvent(&e)) {
            switch (e.type) {
            case EV_KEY:
                if (keys) {
                    switch (((unsigned)e.key >> 8) & 0xFF) {
                    case 0x1C:
                    case 0x3B:
                        result = 0;
                        goto done;
                    case 0x01:
                    case 0x3C:
                        goto cancel;
                    case 0x39:
                        if ((menu_disabled & 0x10) == 0 && menu_sprites[4].type == SPRITE_SHADOW) {
                            result = 4;
                            goto done;
                        }
                        break;
                    case 0x4D:
                        if ((menu_disabled & 0x10) == 0 && menu_sprites[4].type == SPRITE_SHADOW) {
                            result = 4;
                            goto done;
                        }
                        break;
                    case 0x4B:
                        if ((menu_disabled & 8) == 0 && menu_sprites[3].type == SPRITE_SHADOW) {
                            result = 3;
                            goto done;
                        }
                        break;
                    case 0x47:
                        if ((menu_disabled & 2) == 0 && menu_sprites[1].type == SPRITE_SHADOW) {
                            result = 7;
                            goto done;
                        }
                        break;
                    case 0x49:
                        if ((menu_disabled & 2) == 0 && menu_sprites[1].type == SPRITE_SHADOW) {
                            result = 1;
                            goto done;
                        }
                        break;
                    case 0x48:
                        if ((menu_disabled & 2) == 0 && menu_sprites[1].type == SPRITE_SHADOW) {
                            result = 5;
                            goto done;
                        }
                        break;
                    case 0x4F:
                        if ((menu_disabled & 4) == 0 && menu_sprites[2].type == SPRITE_SHADOW) {
                            result = 8;
                            goto done;
                        }
                        break;
                    case 0x51:
                        if ((menu_disabled & 4) == 0 && menu_sprites[2].type == SPRITE_SHADOW) {
                            result = 2;
                            goto done;
                        }
                        break;
                    case 0x50:
                        if ((menu_disabled & 4) == 0 && menu_sprites[2].type == SPRITE_SHADOW) {
                            result = 6;
                            goto done;
                        }
                        break;
                    }
                } else {
                    switch (((unsigned)e.key >> 8) & 0xFF) {
                    case 0x1C:
                    case 0x3B:
                        goto select;
                    case 0x01:
                    case 0x3C:
                        goto cancel;
                    case 0x4D:
                        MenuMove(menu_sprites, menu_count, menu_sel, MENU_NEXT);
                        break;
                    case 0x4B:
                        MenuMove(menu_sprites, menu_count, menu_sel, MENU_PREV);
                        break;
                    case 0x48:
                    case 0x49:
                        MenuMove(menu_sprites, menu_count, menu_sel, MENU_UP);
                        break;
                    case 0x50:
                    case 0x51:
                        MenuMove(menu_sprites, menu_count, menu_sel, MENU_DOWN);
                        break;
                    case 0x47:
                        MenuMove(menu_sprites, menu_count, menu_sel, MENU_FIRST);
                        break;
                    case 0x4F:
                        MenuMove(menu_sprites, menu_count, menu_sel, MENU_LAST);
                        break;
                    }
                }
                break;
            case EV_DOWN1:
            select:
                if (menu_sel != -1) {
                    result = menu_ids[menu_sel];
                    goto done;
                }
                if (MenuHit(menu_sprites, menu_count, mouse_x, mouse_y) == -1) {
                    result = MENU_NONE;
                    goto done;
                }
                break;
            case EV_DOWN2:
            cancel:
                result = menu_sel == -1 ? MENU_CANCEL : MENU_ESCAPE;
                goto done;
            case EV_TICK:
                hit = MenuHit(menu_sprites, menu_count, mouse_x, mouse_y);
                if (hit != -1 && ((1L << hit) & menu_disabled))
                    hit = -1;
                if (hit != menu_sel) {
                    if (menu_sel != -1)
                        DrawButtonFrame(menu_sprites[menu_sel].handle, 0),
                            menu_sprites[menu_sel].dirty = 1;
                    if (hit != -1)
                        DrawButtonFrame(menu_sprites[hit].handle, 218),
                            menu_sprites[hit].dirty = 1;
                    menu_sel = hit;
                }
                SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
                UpdateActors();
                DrawBans();
                UpdateSprites();
                UpdateBans();
                MusicTick();
                if (stream_done) {
                    stream_done = 0;
                    if (voc_wait) {
                        result = 9;
                        return result;
                    }
                }
                FadeUp();
                blink_count++;
                if (timeout && ticks >= end)
                    return MENU_TIMEOUT;
                break;
            }
        }
    }
done:
    BridgeSfx(16);
    return result;
}

/* MenuLoop without the pointer highlighting buttons. */
int MenuWait(unsigned long timeout)
{
    int unused1;
    Event e;
    unsigned long end;
    int result;
    int unused2;

    end = ticks + timeout;
    for (;;) {
        if (GetEvent(&e)) {
            switch (e.type) {
            case EV_KEY:
                switch (((unsigned)e.key >> 8) & 0xFF) {
                case 0x1C:
                case 0x3B:
                    result = 0;
                    goto done;
                case 0x01:
                case 0x3C:
                    goto cancel;
                case 0x39:
                case 0x47:
                case 0x48:
                case 0x49:
                case 0x4B:
                case 0x4D:
                case 0x4F:
                case 0x50:
                case 0x51:
                    break;
                }
                break;
            case EV_DOWN1:
                if (menu_sel != -1) {
                    result = menu_ids[menu_sel];
                    goto done;
                }
                if (MenuHit(menu_sprites, menu_count, mouse_x, mouse_y) == -1) {
                    result = MENU_NONE;
                    goto done;
                }
                break;
            case EV_DOWN2:
            cancel:
                result = menu_sel == -1 ? MENU_CANCEL : MENU_ESCAPE;
                goto done;
            case EV_TICK:
                SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
                UpdateActors();
                DrawBans();
                UpdateSprites();
                UpdateBans();
                MusicTick();
                if (stream_done) {
                    stream_done = 0;
                    if (voc_wait) {
                        result = 9;
                        return result;
                    }
                }
                FadeUp();
                blink_count++;
                if (timeout && ticks >= end)
                    return MENU_TIMEOUT;
                break;
            }
        }
    }
done:
    BridgeSfx(16);
    return result;
}

/* Close the menu and reopen the one under it. */
void MenuClose(void)
{
    int i;
    MenuSave *save;

    if (menu_sel != -1)
        DrawButtonFrame(menu_sprites[menu_sel].handle, 0);
    for (i = 0; i != menu_count; i++)
        if (menu_sprites[i].type == SPRITE_SHADOW)
            SpriteErase(&menu_sprites[i]);
    UpdateSprites();
    for (i = 0; i != menu_count; i++) {
        CacheRelease(menu_sprites[i].handle);
        if (menu_sprites[i].type == SPRITE_SHADOW)
            DelSprite(&menu_sprites[i]);
    }
    FreeMemPtr(menu_ids);
    FreeMemPtr(menu_sprites);
    CacheRelease(menu_handle);
    menu_sprites = 0;
    if (menu_stack) {
        save = menu_stack;
        menu_sprites = menu_stack->sprites;
        menu_ids = menu_stack->ids;
        menu_disabled = menu_stack->disabled;
        menu_handle = menu_stack->handle;
        menu_count = menu_stack->count;
        menu_sel = menu_stack->sel;
        menu_stack = menu_stack->next;
        FreeMemPtr(save);
    } else
        key_accel = menu_saved_accel;
}
