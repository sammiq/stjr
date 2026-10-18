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
void sub_2B60C(char *name);         /* (c2B980) */
void Fatal();
void LockScreen(void);
void UnlockScreen(void);

Bitmap far *backbuf;
Bitmap far *screen;
unsigned char far *mask_buf;
unsigned char far *screen_base;
int in_title;
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
void LoadRoom(char *mission, int n);
void EnterRoom(int a);
void FreeRoom(void);
void MsgBox(char *title, char *msg, int a, int b, int c, int d);    /* seg008: message box */

/* Ctrl-C: ignored (and re-armed). New in the sequel. */
void BreakHandler(int sig)
{
    signal(SIGINT, BreakHandler);
}

/* New in the sequel. */
void PlayTitle(void)
{
    in_title = 1;
    sub_2B60C("title");
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

/* Does nothing. */
void Nop(void)
{
}

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

/* Fatal error: print the message and quit. */
void Fatal(fmt, a, b, c, d)
char *fmt;
int a, b, c, d;
{
    if (gfx_mode) {             /* new: show it on the graphics screen first */
        SetFade(cur_palette, 100);
        printf("Internal error:\n");
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

/* Move the pointer sprite with the mouse. */
void TrackMouse(Event *e)
{
    if (e->type == EV_MOVE) {
        SpriteSetPos(&mouse_sprite, e->x, e->y, 15);
        mouse_sprite.x = e->x;
        mouse_sprite.y = e->y;
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
