/* seg008: the away team - rooms, their scripts and objects, conversation
 * boxes and the player's actions */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <setjmp.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "event.h"
#include "gfx.h"
#include "sound.h"
#include "sprite.h"
#include "resource.h"
#define MenuWait MenuWait_
#include "menu.h"
#undef MenuWait
#include "actor.h"
#include "room.h"

RoomState room;

int MenuWait();
int ItemGive();
int ItemHave();
void ItemTake(int id);
void ItemsInit(void);
void ItemsSave(void);
void ItemsLoad(void);
int PickItem(int x, int y, int restore);
void Fatal();
int tolower(int c);
char *WrapLine(char *src, char *dst, int width);
MemHandle getanyfile(char *name, char *ext);
void FreeAnyFile(MemHandle h);
long GetFileSize(char *name, char *ext);
char *InputCode(void);
void GameOverMenu(void);
int ActionPanel(void);
void SaveWrite(void *p, unsigned n);
void SaveRead(void *p, unsigned n);
void SaveClose(void);
void SaveSpace(void);
void LoadSpace(void);
void SaveMusicState(void);
void LoadMusicState(void);
void PlayVoc(char *name);
void StopVoc(void);
void SaveActors(void);
void LoadActors(void);
void InitActors(void);
void FreeActors(void);
void UpdateActors(void);
void EndOrStand(int n);
void LoadBan(char *name);
void LoadWalkGraph(char *name);
void DrawBans(void);
void UpdateBans(void);
void BridgeSfx(int n);              /* seg001 */
void BridgeLeave(void);
void BridgeEnter(int reset);
void SetTextFile(char *name);
char *GetText(int n);
void FreeText(char *p);
void SendScript(int n);
int LeverPuzzle(void);              /* seg012 */
int Turbolift(int unused, int deck);
int ItemCase(int mask);
void FlashBitmap(char *name);         /* seg030 */
void StartCrew(void);

typedef struct Msg {
    unsigned char type;
    unsigned char arg;
    unsigned char b2;
    unsigned char b3;
} Msg;

/* A room script: a key (action, target, target2, extra; FF matches any)
 * and the machine code to run. */
typedef struct Script {
    long key;
    unsigned next;
    char code[1];
} Script;

typedef struct Point {
    int x;
    int y;
} Point;

typedef struct Item {
    int have;                   /* 00 */
    int code;                   /* 02 */
    char name[10];              /* 04 bitmap name */
    int text;                   /* 0E description */
} Item;

/* Deferred messages: posted when the crew member walking there arrives. */
typedef struct Timer {
    unsigned char active;
    unsigned char msg[4];
} Timer;

extern Bitmap far *screen;
extern Bitmap far *backbuf;
extern unsigned char far *mask_buf;
extern unsigned long blink_count;
extern int kbd_mouse;
extern int in_orbit;
extern int under_attack;
extern int encounter_kind;
extern int encounter_delay;
extern unsigned long bridge_ticks;
extern int word_45AB2;
extern int word_45AB4;
extern int view_dir;
extern int word_45ABA;
char mission[16];
extern int boost_active[6];
extern int last_mission;
extern int mission_ranks[7];
extern void (far *bridge_tick)(void);
extern void (far *tick_fns[32])(void);
extern int game_mode;
extern int prev_mode;
extern int key_accel;
extern int sfx_on;
extern int digi_ok;
Msg msg_queue[16];
extern int msg_head;
int msg_tail;
MemHandle map_handle;
Sprite item_sprite;
Sprite inv_sprite;
extern int word_51156;

int HasScript(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
int RunScripts(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
int RunWildScripts(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
char far *RdfPtr(unsigned off);
void PlayScaled(int n, char *name, int x, int y);
int DepthScale(int y);
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
long PopRoomMsg(void);
void TraceMsg(long msg);
void RoomMsg(void);
void CallScript(void far *code);
long ScriptService(int cmd, int a1, int a2, int a3, int a4, unsigned a5);
void CentreLine(char *dst, char *src);
void ChoiceTitle(char *dst, char far *name, int n);
long Converse(int text, int x, int y);
long TextBox(char *(far *fn)(int, void *, char *), void *arg, int x, int y,
               int color, int choice, int maxl, int flag);
void MsgBox(char *title, char *text, int x, int y, int color, int msg);
char *SkipVoice(char *p);
char *PlayVoiceTag(char *p);
int WrapCount(char *s);
void WrapText(char *dst, char *s);
Bitmap *MakeTextBox(int *px, int *py, int color, int lines, unsigned titled, Sprite *spr);
void BoxLines(Bitmap *box, int n, int max, char *src, unsigned titled);
void BoxTitle(Bitmap *box, char *title);
char *LayoutChoice(char *(far *fn)(int, void *, char *), void *arg, unsigned sel,
                Bitmap *box, int max, int *nlines);
void ActionCursor(int action, int on);
int FindObject(int x, int y);
int InPoly(int far *poly, int x, int y);
int far *NextPoly(int far *poly);
void CheckRegions(int x, int y);
void RoomTimers(void);
int WalkBlocked(int x, int y);
int PickUseTarget(void);
Event WaitAction(void);
void CrewAnim(char *buf, int crew, char *what);
void HiliteCursor(void);
int WalkToHit(void);
int CantAct(int obj, int action);
void StunTick(void);
void ShowInvIcon(int on);
void HideInvIcon(void);
int AwayInput(void);
void LoadRoom(char *mission, int n);
void EnterRoom(int entry);
void BeamUp(void);
void FreeRoom(void);
void SaveRoom(void);
void RestoreRoom(void);

/* The priority at y. */
int DepthPri(int y)
{
    return ((unsigned char)mask_buf[y * 160] >> 4) & 0x0F;
}

/* Queue a room message. */
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d)
{
    Msg *m;

    m = &msg_queue[msg_tail++];
    m->type = a;
    m->arg = b;
    m->b2 = c;
    m->b3 = d;
    msg_tail %= 16;
}

/* Centre src in a 24 character line. */
void CentreLine(char *dst, char *src)
{
    int len;

    MemSet(dst, 24, ' ');
    len = strlen(src);
    if (len > 24)
        len = 24;
    MemCpy(dst + (24 - len) / 2, src, len);
}

/* A choice's title: the speaker, numbered when there are choices. */
void ChoiceTitle(char *dst, char far *name, int n)
{
    char buf[44];
    int len;

    len = _fstrlen(name) + 1;
    MemCpy(buf, name, min(len, 25));
    buf[24] = 0;
    if (n) {
        sprintf(buf + strlen(buf), " choice %d", n);
        buf[24] = 0;
    }
    CentreLine(dst, buf);
}

typedef struct TextArg {
    char title[24];
    char *text;
} TextArg;

/* The single choice of a message box (for TextBox). */
char *MsgChoice(unsigned n, TextArg *arg, char *title)
{
    int len;
    char *buf;

    if (n)
        return 0;
    MemCpy(title, arg, 24);
    len = strlen(arg->text) + 1;
    buf = AllocMemPtr(len);
    MemCpy(buf, arg->text, len);
    return buf;
}

/* Skip a #voice# tag. */
char *SkipVoice(char *p)
{
    char *q;

    q = p;
    if (*q == '#') {
        for (++q; *q != '#'; ++q)
            if (*q == 0)
                return p;
        ++q;
    }
    return q;
}

/* The number of 24 character lines s wraps to. */
int WrapCount(char *s)
{
    char buf[26];
    int n;

    for (n = 0; (s = WrapLine(s, buf, 24)) != 0; n++)
        ;
    return n;
}

/* Wrap s into 24 character lines at dst. */
void WrapText(char *dst, char *s)
{
    char buf[26];
    int i;

    s = WrapLine(s, buf, 24);
    while (s) {
        for (i = strlen(buf); i != 24; ++i)
            buf[i] = ' ';
        MemCpy(dst, buf, 24);
        dst += 24;
        s = WrapLine(s, buf, 24);
    }
}

/* Put n lines of src in the box (blank the rest of max). */
void BoxLines(Bitmap *box, int n, int max, char *src, unsigned titled)
{
    int i;
    char *p;

    p = (char *)box + 35;
    n = min(n, max);
    if (titled)
        p += 52;
    for (i = 0; i != n; i++) {
        MemCpy(p, src, 24);
        src += 24;
        p += 26;
    }
    for (; i != max; i++) {
        MemSet(p, 24, ' ');
        p += 26;
    }
}

/* Put the title (a speaker) on the box's top line. */
void BoxTitle(Bitmap *box, char *title)
{
    char *p;

    if (*title) {
        p = (char *)box + 35;
        MemCpy(p, title, 24);
    }
}

/* The polygon after poly. */
int far *NextPoly(int far *poly)
{
    char far *p;

    p = (char far *)poly;
    p += poly[1] * 4 + 4;
    return (int far *)p;
}

/* x on screen. */
int ClampX(int x)
{
    if (x <= 0)
        x = 0;
    if (x >= 320)
        x = 319;
    return x;
}

/* y on screen. */
int ClampY(int y)
{
    if (y <= 0)
        y = 0;
    if (y >= 200)
        y = 199;
    return y;
}

/* Is (x, y) blocked in the walk map? */
int WalkBlocked(int x, int y)
{
    unsigned char bit;
    int off;
    int r;
    unsigned char far *map;

    map = LockMem(map_handle);
    bit = 0x80 >> (x & 7);
    off = y * 40;
    off += x >> 3;
    r = map[off] & bit;
    UnlockMem(map_handle);
    return r;
}

/* Wait for a click or an action key. */
Event WaitAction(void)
{
    Event *e;

    for (;; PopEvent()) {
        if ((e = PeekEvent()) != 0) {
            switch (e->type) {
            case EV_TICK:
                HiliteCursor();
                UpdateSprites();
                MusicTick();
                break;
            case EV_MOVE:
                SpriteSetPos(&mouse_sprite, e->x, e->y, 15);
                break;
            case EV_DOWN1:
                PopEvent();
                return *e;
            case EV_DOWN2:
                return *e;
            case EV_KEY:
                switch (((unsigned)e->key >> 8) & 0xFF) {
                case 0x17:
                    PopEvent();
                    return *e;
                case 0x1C:
                case 0x3B:
                    PopEvent();
                    e->type = EV_DOWN1;
                    return *e;
                case 1:
                case 0x11:
                case 0x14:
                case 0x16:
                case 0x22:
                case 0x26:
                case 0x39:
                case 0x3C:
                    return *e;
                default:
                    break;
                }
                break;
            }
        }
    }
}

/* Take down the inventory icons. */
void HideInvIcon(void)
{
    if (item_sprite.type == SPRITE_SHADOW)
        SpriteErase(&item_sprite);
    if (inv_sprite.type == SPRITE_SHADOW)
        SpriteErase(&inv_sprite);
    UpdateSprites();
    if (item_sprite.type == SPRITE_SHADOW) {
        DelSprite(&item_sprite);
        item_sprite.type = 0;
        CacheRelease(item_sprite.handle);
    }
    if (inv_sprite.type == SPRITE_SHADOW) {
        DelSprite(&inv_sprite);
        inv_sprite.type = 0;
        CacheRelease(inv_sprite.handle);
    }
}

