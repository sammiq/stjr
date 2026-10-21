/* seg012: main, start-up checks and the bridge's full-screen puzzles
 * (the engineering levers, the turbolift and the item case) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <signal.h>
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
void PlayDem(char *name);         /* demo */
void Fatal();
void LockScreen(void);
void UnlockScreen(void);

Bitmap far *backbuf;
Bitmap far *screen;
unsigned char far *mask_buf;
unsigned char far *screen_base;
extern int in_title;                 /* (demo) */
extern int gfx_mode;               /* (seg007?) set while in a graphics mode */
int _getch(void);
void TextMode(void);
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
void LoadRoom(char *mission, int n, int first);
void EnterRoom(int a);
void FreeRoom(void);
void MsgBox(char *title, char *msg, int a, int b, int c, int d);    /* seg008: message box */

void InitScreens(void);
void InitPlayerShip(void);
void Turbolift(int unused, int deck);
void PlayTitle(void);
void InitScreen(void);
int DriverId(char *name);
void Fatal();
void TrackMouse(Event *e);
void ReadConfig(void);
void ResetPointer(void);
int TurboHover(void);

typedef struct Point {
    int x;
    int y;
} Point;

extern unsigned long blink_count;
extern Obj3D player_ship;
extern Obj3D dummy_planet;
extern char sfx_name[];
extern char room_name[];
extern jmp_buf game_jmp;            /* back to the main loop */
extern jmp_buf room_jmp;

#define ABS(x)  ((x) > 0 ? (x) : -(x))

#define MOUSE_IN(x0, x1, y0, y1) \
    (mouse_x >= (x0) && mouse_x <= (x1) && mouse_y >= (y0) && mouse_y <= (y1))

/* Restore the room after a full-screen puzzle. */
#define RESTORE_ROOM() \
    LoadFilePacked(room_name, "pri", mask_buf); \
    LoadFilePacked(room_name, "bmp", screen); \
    MemCpy(backbuf->data, screen->data, 0xFA00); \
    BlitToScreen(&screen_rect); \
    MarkAllDirty(); \
    UpdateSprites()

extern int word_426BE;
extern char voc_path[];
extern char cd_path[];
extern char save_prefix[];
extern int prev_mode;
extern int game_mode;
extern char mission_name[16];
extern int video_mode;
extern int input_dev;
extern unsigned music_card;
extern int digi_card;
extern int cfg_mio;
extern int cfg_io;
extern int cfg_irq;
extern int cfg_dma;
extern int back_sound;
void UnhookKbd(void);
void InitVideo(void);
void InitActors(void);                   /* seg000 */
void SoundClose(void);                  /* seg015 */
void NextEpisode(void);                 /* space */
void StartMenu(void);                   /* seg019 */
void sub_1C30E(void);                   /* seg008 */
void FadeOut(void);                     /* seg007 */
void FadeIn(void);
void LoadPalette(char *name);
int CfgOpen(char *name);                /* cfg */
char *CfgGet(char *key, char *out);
void CfgClose(void);

MemHandle space_bmp_handle = 0;          /* the space view's bitmap (seg001) */

/* Ctrl-C: ignored (and re-armed). New in the sequel. */
void BreakHandler(int sig)
{
    signal(SIGINT, BreakHandler);
}

void main(int argc, char **argv)
{
    signal(SIGINT, BreakHandler);
    word_426BE = 1;
    voc_path[0] = 0;
    ReadConfig();
    InitTrig();
    InitMem();
    atexit(EMSRelease);
    InitScreen();
    HookKbd();
    atexit(UnhookKbd);
    InitVideo();
    EventInit();
    atexit(TextMode);
    CacheInit();
    ClearSprites();
    InitScreens();
    InitActors();
    OpenDataArchive();
    InitPlayerShip();
    SoundInit();
    atexit(SoundClose);
    NextEpisode();
    blink_count = 0;
    PlayTitle();
    blink_count = 0;
    AddSprite(&mouse_sprite);
    SpriteSetPos(&mouse_sprite, 160, 100, 15);
    SpriteSetBitmap(&mouse_sprite, LoadBitmap("blank"));
    mouse_sprite.layer = 16;
    StopShip(&player_ship);
    BoostInit();
    prev_mode = -1;
    LoadMusic(mission_name, 's');
    game_mode = -1;
    SaveNew();
    if ((game_mode = setjmp(game_jmp)) == 0) {
        LoadPalette("bridge");
        StartMenu();
        TextModeMenu(0);
        FadeOut();
        game_mode = 1;
    }
    for (;;) {
        if (game_mode != prev_mode) {
            if (prev_mode != -1)
                switch (prev_mode) {
                case 1:
                    BridgeLeave();
                    break;
                case 2:
                    EndAway();
                    break;
                }
            switch (prev_mode = game_mode) {
            case 1:
                LoadMusic(mission_name, 's');
                BridgeEnter(1);
                break;
            case 2:
                sub_1C30E();
                break;
            case 3:
                LoadMusic(mission_name, 'g');
                Transport("?teled");
                game_mode = 2;
                continue;
            case 4:
                Transport("?teleb");
                game_mode = 1;
                continue;
            case 5:
                NextEpisode();
                game_mode = 1;
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

/* New in the sequel. */
void PlayTitle(void)
{
    in_title = 1;
    PlayDem("title");
    in_title = 0;
}

void InitScreens(void)
{
    backbuf = PushMem(0xFDE8);
    backbuf->x = backbuf->y = 0;
    backbuf->w = 320;
    backbuf->h = 200;
    mask_buf = PushMem(0x7E00);
}

/* The sequel keeps the screen bitmap (after a 0x300 byte palette) in EMS
 * when it can; LockScreen/UnlockScreen map it in around its use. */
MemHandle screen_handle = 0;
int screen_locks = 0;

void InitScreen(void)
{
    if ((screen_handle = EMSAllocHandle(0xFD08L)) == 0) {
        screen_base = PushMem(0xFD08);
        screen = (Bitmap far *)(screen_base + 0x300);
    }
    LockScreen();
    screen->x = 0;
    screen->y = 0;
    screen->w = 320;
    screen->h = 200;
    MemSet(screen_base, 0x300, 0);
    UnlockScreen();
}

void LockScreen(void)
{
    if (++screen_locks <= 1 && screen_handle) {
        screen_base = LockMem(screen_handle);
        screen = (Bitmap far *)(screen_base + 0x300);
    }
}

void UnlockScreen(void)
{
    if (--screen_locks < 0)
        Fatal("BkLockCount < 0");
    if (screen_locks <= 0 && screen_handle) {
        UnlockMem(screen_handle);
        screen_base = 0;
        screen = 0;
    }
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

/* The turbolift panel: pick a deck and go there. */
void Turbolift(int unused, int deck)
{
    static Point stops[5] = {
        { 0x89, 0x7A }, { 0x78, 0x85 }, { 0x99, 0x91 }, { 0xF7, 0x9C }, { 0x75, 0xA9 }
    };
    Sprite *list[MAX_SPRITES];
    char name[16];
    Event ev;
    int count;
    int done;
    int shown;
    int room;
    int entry;
    Sprite *spr;

    count = 0;
    FadeOut();
    FreeActors();
    SetSpriteList(list, &count);
    LockScreen();
    LoadFilePacked("veng9", "bmp", (unsigned char far *)screen);
    MemCpy(backbuf->data, screen->data, 0xFA00);
    UnlockScreen();
    BlitToScreen(&screen_rect);
    MemSet(mask_buf, 0x7D00, 15);
    AddSprite(&mouse_sprite);
    mouse_sprite.dirty = 1;
    mouse_sprite.layer = 16;
    MemSet(spr = AllocMemPtr(sizeof(Sprite)), sizeof(Sprite), 0);
    MarkAllDirty();
    UpdateSprites();
    ResetPointer();
    FadeIn();
    done = shown = 0;
    do {
        if (GetEvent(&ev)) {
            TrackMouse(&ev);
            switch (ev.type) {
            case EV_TICK:
                UpdateSprites();
                break;
            case EV_KEY:
                switch ((unsigned)ev.key >> 8) {
                case 0x1C:
                case 0x3B:
                    break;
                default:
                    continue;
                }
            case EV_DOWN1:
                if ((room = TurboHover()) != 0 && room != 6 && room != 7)
                    done = 1;
                else if (room == 6)
                    MsgBox("", "Turbo lift access blocked by radiation.", 50, 50, 9, 0);
                else if (room == 7)
                    MsgBox("", "The Turbo lift will not reach that area of the ship.", 50, 50, 9, 0);
                break;
            case EV_MOVE:
                if (mouse_y < 0x60)
                    ResetPointer();
                if ((room = TurboHover()) != 0) {
                    if (!shown) {
                        sprintf(name, "turbo%d", room);
                        AddSprite(spr);
                        SpriteSetPos(spr, 3, 0xA8, 15);
                        SpriteSetBitmap(spr, LoadBitmap(name));
                        shown = 1;
                    }
                } else if (shown) {
                    SpriteErase(spr);
                    UpdateSprites();
                    DelSprite(spr);
                    ReleaseBitmap(spr->handle);
                    shown = 0;
                }
                break;
            }
        }
    } while (!done);
    FadeOut();
    ReleaseBitmap(spr->handle);
    ResetSpriteList();
    FreeMemPtr(spr);
    MarkAllDirty();
    UpdateSprites();
    if (room == 1) {
        room = 0;
        entry = 1;
    } else if (room == 2)
        entry = room = 1;
    else if (room == 3) {
        room = 3;
        entry = 1;
    } else if (room == 4) {
        room = 5;
        entry = 1;
    } else if (room == 5) {
        room = 7;
        entry = 1;
    } else {
        room = 0;
        entry = 1;
    }
    FreeRoom();
    LoadMusic(mission_name, 'g');
    LoadRoom(room_mission, room, 0);
    EnterRoom(entry);
    longjmp(room_jmp, 1);
}

/* Fatal error: print the message and quit. */
void Fatal(fmt, a, b, c, d)
char *fmt;
int a, b, c, d;
{
    if (gfx_mode) {             /* new: show it on the graphics screen first */
        SetFade(cur_palette, 100);
        printf("\nInternal error:\n");
        printf(fmt, a, b, c, d);
        printf("\n");
        printf("Game aborted...\n");
        _getch();
        TextMode();
    }
    printf("Internal error:\n");
    printf(fmt, a, b, c, d);
    printf("\n");
    printf("Game aborted...\n");
    exit(1);
}

/* Does nothing. */
void Nop(void)
{
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

typedef struct Driver {
    char *name;
    int id;
} Driver;

/* The driver number for a sound card name in the config. */
int DriverId(char *name)
{
    Driver drivers[9];
    int i;

    drivers[0].name = "A001";
    drivers[0].id = 9;
    drivers[1].name = "A002";
    drivers[1].id = 4;
    drivers[2].name = "A004";
    drivers[2].id = 9;
    drivers[3].name = "A009";
    drivers[3].id = 6;
    drivers[4].name = "E000";
    drivers[4].id = 4;
    drivers[5].name = "E003";
    drivers[5].id = 7;
    drivers[6].name = "E009";
    drivers[6].id = 3;
    drivers[7].name = "E00F";
    drivers[7].id = 5;
    drivers[8].name = 0;
    drivers[8].id = 0;
    for (i = 0; drivers[i].name; i++)
        if (strcmp(drivers[i].name, name) == 0)
            return drivers[i].id;
    Fatal("Can't locate music or sound driver", 0, 0, 0, 0);
    return 0;
}

/* Read trek2.cfg: the sound cards and where the files are. */
void ReadConfig(void)
{
    char buf[32];

    video_mode = 0;
    input_dev = 1;
    if (CfgOpen("trek2.cfg")) {
        music_card = DriverId(CfgGet("music", buf));
        if (CfgGet("music_io", buf) && sscanf(buf, "%x", &cfg_mio) == 0)
            cfg_mio = 0;
        if (CfgGet("backsound", buf))
            back_sound = atoi(buf);
        digi_card = DriverId(CfgGet("sound", buf));
        if (CfgGet("sound_io", buf) && sscanf(buf, "%x", &cfg_io) == 0)
            cfg_io = 0;
        cfg_irq = CfgGet("sound_irq", buf) ? atoi(buf) : 0;
        cfg_dma = CfgGet("sound_dma", buf) ? atoi(buf) : 0;
        CfgGet("src", cd_path);
        if (voc_path[0])
            strcat(voc_path, ";");
        strcat(voc_path, cd_path);
        strcat(voc_path, ";");
        strcat(voc_path, cd_path);
        strcat(voc_path, "uncomp\\");
        CfgGet("dst", save_prefix);
        CfgClose();
    } else {
        strcpy(cd_path, "");
        strcpy(voc_path, "uncomp");
        cfg_dma = cfg_irq = cfg_io = digi_card = music_card = 0;
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
