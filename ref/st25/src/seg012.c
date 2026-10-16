/* seg012: main, start-up checks and the bridge's full-screen puzzles
 * (the engineering levers, the turbolift and the item case) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <dos.h>
#define FindCD FindCD_
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "ems.h"
#include "event.h"
#include "gfx.h"
#include "sound.h"
#include "sprite.h"
#include "resource.h"
#include "fixmath.h"
#include "obj3d.h"
#include "room.h"
#undef FindCD

int getch(void);
void FindCD(char *argv0);

void Intro(void);                   /* seg017 */
void InitDummyPlanet(void);         /* seg006 */
void AddR3(Obj3D *o);
int SelectView(Obj3D *o);
void ReleaseShipShape(Obj3D *o);
void StopShip(Obj3D *o);            /* seg025 */
void BoostInit(void);               /* seg020 */
void SaveNew(void);                 /* seg019 */
void TextModeMenu(int ask);
void FreeActors(void);              /* seg000 */
void ClearScreen(void);               /* seg001 */
void BridgeLoop(void);
void BridgeEnter(int a);
void BridgeLeave(void);
void CyclePalette(void);
void Transport(char *name);
void ResetMsgs(void);
void StartAway(void);               /* seg008 */
void AwayLoop(void);
void EndAway(void);
void LoadRoom(char *mission, int n);
void EnterRoom(int a);
void FreeRoom(void);
void MsgBox(char *title, char *msg, int a, int b, int c, int d);    /* seg008: message box */

void main(int argc, char **argv);
void InitScreens(void);
void InitPlayerShip(void);
int LeverPuzzle(void);
void Turbolift(int unused, int deck);
int ItemCase(int mask);
void Fatal();
void TrackMouse(Event *e);
void ReadConfig(int argc, char **argv);
void ResetPointer(void);
int TurboHover(void);
int TurboPick(int deck);
void CheckMemory(void);
void FarPrintf();

typedef struct Point {
    int x;
    int y;
} Point;

Bitmap far *backbuf;
Bitmap far *screen;
unsigned char far *mask_buf;
extern unsigned long blink_count;
extern Obj3D player_ship;
extern Obj3D dummy_planet;
extern char sfx_name[];
int sb_port;
int sb_irq;
extern char room_name[];
extern jmp_buf game_jmp;            /* back to the main loop */
extern jmp_buf room_jmp;
int game_mode;               /* 1 bridge, 2 away team; 3, 4 beaming */
int prev_mode;

/* CheckMemory's message, kept out of DGROUP in a far data segment. */
char _far mem_msg1[] = "Star Trek: 25th Anniversary Enhanced CD-ROM requires 560K of free\n";
char _far mem_msg2[] = "low memory and 1024k of free EMS (expanded) memory to play. You currently\n";
char _far mem_msg3[] = "have %ldK free low memory and %ldK free EMS memory.\n";
char _far mem_msg4[] = "Try moving your TSRs and device drivers into high memory, or remove\n";
char _far mem_msg5[] = "them completely. Be sure you are not running a DOS shell from Windows.\n\n";
char _far mem_msg6[] = "If you have more memory in your computer, we recommend you free up\n";
char _far mem_msg7[] = "even more EMS memory to speed up the game -- 2048K free EMS is recommended.\n";
char _far size_msg1[] = "program size = %ld\n";    /* unused */
char _far size_msg2[] = "heap size    = %ld\n";

MemHandle space_bmp_handle = 0;
Point old_item_pos[5] = { { 0x89, 0x7A }, { 0x78, 0x85 }, { 0x99, 0x91 }, { 0xF7, 0x9C }, { 0x75, 0xA9 } };
Point item_pos[5] = { { 0x29, 0x80 }, { 0x58, 0x7D }, { 0x82, 0x7D }, { 0xAE, 0x79 }, { 0xE1, 0x7D } };

#define ABS(x)  ((x) > 0 ? (x) : -(x))

#define MOUSE_IN(x0, x1, y0, y1) \
    (mouse_x >= (x0) && mouse_x <= (x1) && mouse_y >= (y0) && mouse_y <= (y1))

void main(int argc, char **argv)
{
    int play_intro;

    atexit(PrintExitMsg);
    EMSInit();
    atexit(EMSRelease);
    CheckMemory();
    ReadConfig(argc, argv);
    InitMem();
    HookKbd();
    atexit(UnhookKbd);
    InitVideo();
    EventInit();
    atexit(TextMode);
    InitTrig();
    CacheInit();
    ClearSprites();
    InitScreens();
    OpenDataFiles();
    FindCD(argv[0]);
    SoundInit();
    atexit(SoundStop);
    InitPlayerShip();
    blink_count = 0;
    if (play_intro)
        Intro();
    DigiShutdown();
    InitDummyPlanet();
    AddR3(&dummy_planet);
    blink_count = 0;
    AddSprite(&mouse_sprite);
    SpriteSetPos(&mouse_sprite, 160, 100, 15);
    SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
    mouse_sprite.layer = 16;
    StopShip(&player_ship);
    BoostInit();
    prev_mode = -1;
    LoadMusic("bridge");
    game_mode = -1;
    SaveNew();
    LoadPalette("bridge");
    ClearScreen();
    FadeIn();
    TextModeMenu(0);
    FadeOut();
    game_mode = setjmp(game_jmp);
    FreeAllEMSFiles();
    if (sfx_name[0])
        PlaySfx(sfx_name);
    if (game_mode == 0)
        game_mode = 1;
    for (;;) {
        if (game_mode != prev_mode) {
            if (prev_mode != -1) {
                switch (prev_mode) {
                case 1:
                    BridgeLeave();
                    break;
                case 2:
                    EndAway();
                    break;
                case 3:
                case 4:
                    break;
                }
            }
            prev_mode = game_mode;
            switch (game_mode) {
            case 1:
                LoadMusic("bridge");
                BridgeEnter(1);
                break;
            case 2:
                StartAway();
                break;
            case 3:
                room.redshirt_dead = 0;
                LoadMusic("ground");
                Transport("teled");
                game_mode = 2;
                continue;
            case 4:
                Transport("teleb");
                game_mode = 1;
                ResetMsgs();
                DigiShutdown();
                PlaySfx("bridloop");
                continue;
            }
        }
        switch (game_mode) {
        case 1:
            BridgeLoop();
            break;
        case 2:
            AwayLoop();
            break;
        case 3:
        case 4:
            Fatal("can't be here.");
            break;
        }
    }
}

void InitScreens(void)
{
    backbuf = PushMem(0xFA08);
    backbuf->x = backbuf->y = 0;
    backbuf->w = 320;
    backbuf->h = 200;
    screen = PushMem(0xFA08);
    screen->x = screen->y = 0;
    screen->w = 320;
    screen->h = 200;
    mask_buf = PushMem(0x7E00);
}

void InitPlayerShip(void)
{
    ShipDesc desc;

    LoadFilePacked("enterpri", "dsc", (unsigned char far *)&desc);
    MemSet(&player_ship, sizeof(player_ship), 0);
    MatIdentity(&player_ship.orient);
    player_ship.visible = R3_SHIP;
    player_ship.draw = SelectView;
    player_ship.free = ReleaseShipShape;
    player_ship.kind = desc.kind;
    player_ship.reach = desc.reach;
    player_ship.size = desc.size;
    MemCpy(player_ship.shields, desc.shields, sizeof(player_ship.shields));
    MemCpy(player_ship.systems, desc.systems, sizeof(player_ship.systems));
    player_ship.mo = desc.mo;
    player_ship.range = desc.range;
    player_ship.has_shields = desc.has_shields;
    MemCpy(player_ship.weapons, desc.weapons, sizeof(player_ship.weapons));
    AddR3(&player_ship);
}

/* Restore the room after a full-screen puzzle. */
#define RESTORE_ROOM() \
    LoadFilePacked(room_name, "pri", mask_buf); \
    LoadFilePacked(room_name, "bmp", screen); \
    MemCpy(backbuf->data, screen->data, 0xFA00); \
    BlitToScreen(&screen_rect); \
    MarkAllDirty(); \
    UpdateSprites()

/* The three levers in engineering. Each lights up to six lamps; solved
 * when all three are near the middle. */
int LeverPuzzle(void)
{
    int l1;
    int l2;
    int l3;
    Sprite *spr;
    Sprite done;
    int i;
    int n;
    int running;
    Event ev;
    int unused[2];
    int y;
    int x;
    int base;
    int redraw;
    MemHandle h;
    Sprite *list[32];
    int count;
    int result;

    l1 = 0x11;
    l2 = -0x11;
    l3 = 0x11;
    count = 0;
    result = 0;
    FadeOut();
    FreeAllEMSFiles();
    SetSpriteList(list, &count);
    LoadFilePacked("machineb", "bmp", screen);
    MemCpy(backbuf->data, screen->data, 0xFA00);
    BlitToScreen(&screen_rect);
    MemSet(mask_buf, 0x7D00, 0);
    AddSprite(&mouse_sprite);
    mouse_sprite.dirty = 1;
    mouse_sprite.layer = 16;
    n = 21;
    spr = AllocMemPtr(n * sizeof(Sprite));
    for (i = 0; i < n; i++) {
        AddSprite(&spr[i]);
        spr[i].handle = 0;
    }
    SpriteSetBitmap(spr, LoadBitmap("levery"));
    SpriteSetBitmap(&spr[1], LoadBitmap("leverr"));
    SpriteSetBitmap(&spr[2], LoadBitmap("leverb"));
    h = LoadBitmap("lighty");
    for (i = 3; i <= 8; i++)
        spr[i].handle = h;
    h = LoadBitmap("lightr");
    for (i = 9; i <= 14; i++)
        spr[i].handle = h;
    h = LoadBitmap("lightb");
    for (i = 15; i <= 20; i++)
        spr[i].handle = h;
    AddSprite(&done);
    SpriteSetPos(&done, 260, 100, 2);
    SpriteSetBitmap(&done, LoadBitmap("donebutt"));
    redraw = 1;
    FadeIn();
    running = 1;
    while (running) {
        if (redraw) {
            SpriteSetPos(spr, 160, l1 + 117, 14);
            SpriteSetPos(&spr[1], 168, l2 + 117, 14);
            SpriteSetPos(&spr[2], 176, l3 + 117, 14);
            x = 131;
            y = 130;
            base = 3;
            n = ABS(l1) / 3;
            for (i = 0; i < 6; i++)
                SpriteSetPos(&spr[base + i], x, y, 14);
            y -= 6;
            for (i = 0; i < n; i++) {
                SpriteSetPos(&spr[base + i], x, y, 14);
                y -= 6;
            }
            x = 139;
            y = 130;
            base = 9;
            n = ABS(l2) / 3;
            for (i = 0; i < 6; i++)
                SpriteSetPos(&spr[base + i], x, y, 14);
            y -= 6;
            for (i = 0; i < n; i++) {
                SpriteSetPos(&spr[base + i], x, y, 14);
                y -= 6;
            }
            x = 147;
            y = 130;
            base = 15;
            n = ABS(l3) / 3;
            for (i = 0; i < 6; i++)
                SpriteSetPos(&spr[base + i], x, y, 14);
            y -= 6;
            for (i = 0; i < n; i++) {
                SpriteSetPos(&spr[base + i], x, y, 14);
                y -= 6;
            }
            redraw = 0;
        }
        if (GetEvent(&ev)) {
            TrackMouse(&ev);
            switch (ev.type) {
            case EV_KEY:
                switch (((unsigned)ev.key >> 8) & 0xFF) {
                case 0x1C:
                case 0x3B:
                    goto click;
                case 1:
                case 0x3C:
                    goto finish;
                }
                break;
            case EV_DOWN2:
                goto finish;
            case EV_DOWN1:
            click:
                if (SpriteAt(mouse_x, mouse_y) == &done) {
            finish:
                    result = ABS(l1) <= 2 && ABS(l2) <= 2 && ABS(l3) <= 2;
                    running = 0;
                    break;
                }
                if (mouse_y >= 100 && mouse_y <= 134) {
                    if (mouse_x >= 160 && mouse_x <= 166)
                        l1 = mouse_y - 117;
                    if (mouse_x >= 168 && mouse_x <= 174)
                        l2 = mouse_y - 117;
                    if (mouse_x >= 176 && mouse_x <= 182)
                        l3 = mouse_y - 117;
                    redraw = 1;
                }
                break;
            }
        }
        UpdateSprites();
    }
    FadeOut();
    for (i = 0; i != 3; i++)
        ReleaseBitmap(spr[i].handle);
    ReleaseBitmap(spr[3].handle);
    ReleaseBitmap(spr[9].handle);
    ReleaseBitmap(spr[15].handle);
    ReleaseBitmap(done.handle);
    ResetSpriteList();
    FreeMemPtr(spr);
    RESTORE_ROOM();
    return result;
}

/* Pick a deck on the turbolift panel and go there. */
void Turbolift(int unused, int deck)
{
    Sprite *list[32];
    Sprite *s;
    int count;
    int unk46;
    int hit;
    int unk4a;
    int done;
    int shown;
    int num;
    int dir;
    int timeout;
    char *p;
    char name[16];
    char msg[76];
    char unkb2[40];
    int unkdc;
    Event ev;
    int unkec;

    count = 0;
    unkdc = 1;
    FadeOut();
    FreeAllEMSFiles();
    shown = 0;
    FreeActors();
    SetSpriteList(list, &count);
    p = room.vars;
    if (p[9] == 0) {
        LoadFilePacked("veng9b", "bmp", screen);
        MemCpy(backbuf->data, screen->data, 0xFA00);
        BlitToScreen(&screen_rect);
        MemSet(mask_buf, 0x7D00, 15);
        FadeIn();
        for (done = 0, timeout = 45; !done; ) {
            if (GetEvent(&ev)) {
                TrackMouse(&ev);
                switch (ev.type) {
                case EV_DOWN1:
                case EV_DOWN2:
                    goto stop;
                case EV_KEY:
                    switch (((unsigned)ev.key >> 8) & 0xFF) {
                    case 1:
                    case 0x1C:
                    case 0x39:
                    stop:
                        done = 1;
                    }
                    break;
                case EV_TICK:
                    --timeout;
                    if (timeout == 0)
                        done = 1;
                    break;
                }
            }
        }
        p[9] = 1;
        FadeOut();
    }
    LoadFilePacked("veng9", "bmp", screen);
    MemCpy(backbuf->data, screen->data, 0xFA00);
    BlitToScreen(&screen_rect);
    MemSet(mask_buf, 0x7D00, 15);
    AddSprite(&mouse_sprite);
    mouse_sprite.dirty = 1;
    mouse_sprite.layer = 16;
    s = AllocMemPtr(sizeof(Sprite));
    MemSet(s, sizeof(Sprite), 0);
    MarkAllDirty();
    UpdateSprites();
    ResetPointer();
    FadeIn();
    done = 0;
    while (!done) {
        if (GetEvent(&ev)) {
            TrackMouse(&ev);
            switch (ev.type) {
            case EV_KEY:
                switch (((unsigned)ev.key >> 8) & 0xFF) {
                case 0x1C:
                case 0x3B:
                    goto click;
                }
                break;
            case EV_TICK:
                blink_count++;
                CyclePalette();
                UpdateSprites();
                break;
            case EV_DOWN1:
            click:
                hit = TurboPick(deck);
                if (hit != 0 && hit != 6 && hit != 7)
                    done = 1;
                else if (hit == 6) {
                    sprintf(msg, "#GENE\\GENE_F14#Turbolift access is blocked by an extremely high radiation level.");
                    MsgBox(0, msg, 50, 50, 176, 0);
                } else if (hit == 7) {
                    sprintf(msg, "#GENE\\GENE_F15#This Turbolift cannot reach that area of the ship.");
                    MsgBox(0, msg, 50, 50, 176, 0);
                }
                break;
            case EV_MOVE:
                if (mouse_y < 96)
                    ResetPointer();
                hit = TurboHover();
                if (hit) {
                    if (!shown) {
                        sprintf(name, "turbo%d", hit);
                        AddSprite(s);
                        SpriteSetPos(s, 3, 168, 15);
                        SpriteSetBitmap(s, LoadBitmap(name));
                        shown = 1;
                    }
                } else if (shown) {
                    SpriteErase(s);
                    UpdateSprites();
                    DelSprite(s);
                    ReleaseBitmap(s->handle);
                    shown = 0;
                }
                break;
            }
        }
    }
    FadeOut();
    ReleaseBitmap(s->handle);
    ResetSpriteList();
    FreeMemPtr(s);
    RESTORE_ROOM();
    if (hit == 1) {
        num = 0;
        dir = 1;
    } else if (hit == 2) {
        num = 1;
        dir = 1;
    } else if (hit == 3 && deck == 0) {
        num = 3;
        dir = 1;
    } else if (hit == 3 && deck == 1) {
        num = 3;
        dir = 0;
    } else if (hit == 4) {
        num = 5;
        dir = 1;
    } else if (hit == 5) {
        num = 7;
        dir = 1;
    } else {
        num = 0;
        dir = 1;
    }
    FreeRoom();
    LoadMusic("ground");
    LoadRoom(room_mission, num);
    EnterRoom(dir % 6);
    longjmp(room_jmp, 1);
    return;
}

/* The case of items: bit 0x10 >> n of mask is item n. Clicking an item
 * drops it out of the case. Returns the items left. */
int ItemCase(int mask)
{
    Sprite *list[32];
    int count;
    Sprite *items;
    Sprite close;
    int i;
    int bit;
    int done;
    Event ev;
    Sprite *hit;
    long t;
    char name[10];

    count = 0;
    FadeOut();
    SetSpriteList(list, &count);
    LoadFilePacked("stlcase", "bmp", screen);
    MemCpy(backbuf->data, screen->data, 0xFA00);
    BlitToScreen(&screen_rect);
    MemSet(mask_buf, 0x7D00, 0);
    AddSprite(&mouse_sprite);
    mouse_sprite.dirty = 1;
    mouse_sprite.layer = 16;
    items = AllocMemPtr(5 * sizeof(Sprite));
    MemSet(items, 5 * sizeof(Sprite), 0);
    for (i = 0, bit = 0x10; i < 5; i++, bit >>= 1) {
        if ((mask & bit) == 0)
            continue;
        sprintf(name, "stlitem%d", i);
        AddSprite(&items[i]);
        SpriteSetPos(&items[i], item_pos[i].x, item_pos[i].y, 2);
        SpriteSetBitmap(&items[i], LoadBitmap(name));
    }
    AddSprite(&close);
    SpriteSetPos(&close, 225, 25, 2);
    SpriteSetBitmap(&close, LoadBitmap("donebutt"));
    MarkAllDirty();
    UpdateSprites();
    FadeIn();
    done = 0;
    while (!done) {
        if (GetEvent(&ev)) {
            TrackMouse(&ev);
            switch (ev.type) {
            case EV_KEY:
                switch (((unsigned)ev.key >> 8) & 0xFF) {
                case 0x1C:
                case 0x3B:
                    goto click;
                case 1:
                case 0x3C:
                    goto quit;
                }
                break;
            case EV_TICK:
                UpdateSprites();
                break;
            case EV_DOWN2:
            quit:
                done = 1;
                break;
            case EV_DOWN1:
            click:
                hit = SpriteAt(mouse_x, mouse_y);
                if (hit == &close) {
                    done = 1;
                    break;
                }
                if (hit) {
                    t = 0;
                    while (hit->y < 200) {
                        SpriteSetPos(hit, hit->x, hit->y, 8);
                        UpdateSprites();
                        while (GetTicks() == (unsigned long)t)
                            ;
                        ++hit->y;
                    }
                    SpriteErase(hit);
                    UpdateSprites();
                    DelSprite(hit);
                    ReleaseBitmap(hit->handle);
                    mask ^= 0x10 >> (hit - items);
                }
                break;
            }
        }
    }
    FadeOut();
    for (i = 0, bit = 0x10; i < 5; i++, bit >>= 1) {
        if ((mask & bit) == 0)
            continue;
        ReleaseBitmap(items[i].handle);
    }
    ReleaseBitmap(close.handle);
    ResetSpriteList();
    FreeMemPtr(items);
    RESTORE_ROOM();
    return mask;
}

/* Fatal error: print the message and quit. */
void Fatal(fmt, a, b, c, d)
char *fmt;
int a, b, c, d;
{
    SetFade(cur_palette, 100);
    printf("Internal error:\n");
    printf(fmt, a, b, c, d);
    printf("\n");
    printf("Game aborted...\n");
    getch();
    exit(1);
}

/* Move the pointer sprite with the mouse. */
void TrackMouse(Event *e)
{
    if (e->type == EV_MOVE) {
        SpriteSetPos(&mouse_sprite, e->x, e->y, 15);
        mouse_sprite.x = e->x;
        mouse_sprite.y = e->y;
    }
}

/* Hardware settings: from the command line (as passed by the installer's
 * play program), else intrplay.cfg, else defaults. */
void ReadConfig(int argc, char **argv)
{
    int cfg[16];
    FILE *f;
    int i;

    if (argc == 9 || argc == 10) {
        for (i = 0; i < 7; i++)
            cfg[i] = atoi(argv[i + argc - 8]);
        video_mode = cfg[0];
        input_dev = cfg[1];
        midi_driver = cfg[2];
        digi_driver = cfg[3];
        sb_port = cfg[4];
        sb_irq = cfg[5];
    } else if ((f = fopen("intrplay.cfg", "rb")) != 0) {
        fread(cfg, 1, sizeof(cfg), f);
        fclose(f);
        video_mode = cfg[0];
        input_dev = cfg[1];
        midi_driver = cfg[2];
        digi_driver = cfg[3];
        sb_port = cfg[4];
        sb_irq = cfg[5];
    } else {
        video_mode = -1;
        input_dev = 0;
        midi_driver = 1;
        digi_driver = 0;
        sb_port = 0;
        sb_irq = 0;
    }
}

void ResetPointer(void)
{
    mouse_y = 96;
    SetPointer(mouse_x, mouse_y);
    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
    mouse_sprite.layer = 16;
}

/* The turbolift panel button under the pointer, 1 to 6, or 0. */
int TurboHover(void)
{
    if (MOUSE_IN(0x7F, 0x91, 0x78, 0x7B))
        return 1;
    else if (MOUSE_IN(0x6E, 0x7E, 0x83, 0x87))
        return 2;
    else if (MOUSE_IN(0x95, 0xAD, 0x8F, 0x93))
        return 3;
    else if (MOUSE_IN(0xEF, 0xFD, 0x98, 0xA0))
        return 4;
    else if (MOUSE_IN(0x6B, 0x80, 0xA3, 0xA7))
        return 5;
    else if (MOUSE_IN(0x6E, 0x88, 0xAB, 0xAF))
        return 6;
    else
        return 0;
}

/* As TurboHover, but 7 for a deck the lift can't reach from deck. */
int TurboPick(int deck)
{
    if (MOUSE_IN(0x7F, 0x91, 0x78, 0x7B)) {
        if (deck == 0)
            return 1;
        else
            return 7;
    } else if (MOUSE_IN(0x6E, 0x7E, 0x83, 0x87)) {
        if (deck == 0)
            return 2;
        else
            return 7;
    } else if (MOUSE_IN(0x95, 0xAD, 0x8F, 0x93))
        return 3;
    else if (MOUSE_IN(0xEF, 0xFD, 0x98, 0xA0)) {
        if (deck == 1)
            return 4;
        else
            return 7;
    } else if (MOUSE_IN(0x6B, 0x80, 0xA3, 0xA7)) {
        if (deck == 1)
            return 5;
        else
            return 7;
    } else if (MOUSE_IN(0x6E, 0x88, 0xAB, 0xAF))
        return 6;
    else
        return 0;
}

/* Quit with a message unless there is 560K of low memory and 1M of EMS. */
void CheckMemory(void)
{
    unsigned far *psp;
    unsigned seg;
    long size;
    long avail;
    char unused[100];

    psp = (unsigned far *)((unsigned long)_psp << 16);
    size = (unsigned long)(psp[1] - _psp) << 4;
    _dos_allocmem(0xFFFF, &seg);
    avail = (unsigned long)seg << 4;
    if (size + avail < 0x8C000L || ems_num_pages << 4 < 1024) {
        FarPrintf(mem_msg1);
        FarPrintf(mem_msg2);
        FarPrintf(mem_msg3, (size + avail) / 1024, (unsigned long)ems_num_pages << 4);
        FarPrintf(mem_msg4);
        FarPrintf(mem_msg5);
        FarPrintf(mem_msg6);
        FarPrintf(mem_msg7);
        exit(0);
    }
}

/* printf with a far format string. */
void FarPrintf(fmt, a, b, c, d, e, f, g, h)
char far *fmt;
int a, b, c, d, e, f, g, h;
{
    char buf[100];

    _fstrncpy(buf, fmt, 100);
    buf[99] = 0;
    printf(buf, a, b, c, d, e, f, g, h);
}
