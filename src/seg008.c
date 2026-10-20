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
void ItemTake(int id);
void ItemsInit(void);
void ItemsSave(void);
void ItemsLoad(void);
int PickItem(int x, int y, int restore);
void Fatal();
int tolower(int c);
int isprint(int c);
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
void StopSfxLoop(void);              /* seg015 */
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
void FlashBitmap(char *name, int z);
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
    char have;                  /* 00 */
    char name[9];               /* 01 bitmap name */
} Item;

int ItemHave(int id);

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
char mission_name[16];
char room_name[16];                    /* room_mission and its number */
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
extern MemHandle talk_handle;           /* the room's conversations */
extern char far *talk_data;             /* locked */
extern MemHandle text_handle;           /* their strings */
char *TalkChoice(unsigned n, int *list, char *title);
void TimedBox(char *(far *fn)(int, void *, char *), void *arg, int x, int y,
              int color, int maxl, int ticks);

/* A speaker record in the talk data. */
typedef struct Speaker {
    int x;                      /* 00 box position (0: 20) */
    int y;                      /* 02 */
    unsigned char color;        /* 04 */
    unsigned char z;            /* 05 the box's timeout */
    char title[24];             /* 06 */
} Speaker;
/* A text panel (a script's caption). */
typedef struct Panel {
    int active;                 /* 00 */
    int arg[6];                 /* 02 */
    Sprite sprite;              /* 0E */
} Panel;

Panel panels[6];
extern int msg_action;                  /* the message being handled, for */
extern int msg_target;                  /* the scripts */
extern int msg_target2;
extern unsigned line_width;             /* of the draw buffer */
extern char far *draw_buf;
void RoomTick(void);
int FixAtan2(long a, long b);           /* seg010 */
void ShowPanel(int i);

/* ScriptService's helpers elsewhere */
void SetCrewIcon(int n, char c);
void SetSpeaker(int n, unsigned off);
void DrawLine3(int x0, int y0, int x1, int y1, int color);
int OpenPanel(int a, int b, int c, int d, int f, int e);
void ClosePanel(int i);
void WaitActor(int n);
void RoomWait(unsigned ticks);
char DirTo(int n, int x, int y);
void ObjectCentre(int id, int *px, int *py);
typedef struct ActorBits {
    unsigned char b0 : 3;
    unsigned char b3 : 1;
} ActorBits;
typedef struct FlagBits {
    unsigned char b0 : 1;
    unsigned char b1 : 1;
} FlagBits;
void StartEffect(int a, int b, int c);
int ItemGive(int a);
void ItemTake(int a);
void LoadWalkGraph(char *name);
int Turbolift(int a, int b);
void sub_1C266(int src, int a, int b);
void sub_1C20A(int src, int a);
void sub_1C2FA(void);
void BeamUp(void);
void EndOrStand(int a);
unsigned sub_20AD4(int a, int b);
char *ItemName(int a);
void PlayDemScene(char *name);
void LoadNamed(char *name, int a);
void Computer(void);
void PlayVoice(char *name);
void StopVoice(void);
void LockScreen(void);
void UnlockScreen(void);
extern jmp_buf room_jmp;
extern jmp_buf game_jmp;
extern int mission_max;
extern int mission_score;
extern unsigned char sfx_vol_next;
extern unsigned char sfx_pan_next;
extern char bg_name[10];
extern char pri_name[10];
extern char map_name[10];
extern Rect screen_rect;
extern unsigned char far *screen_base;
extern unsigned char cur_palette[];
extern int fade_level;
int VoiceMode(void);                    /* the speech/text setting */
int show_text;                          /* show the box's text */
int voice_only;                         /* only the voice is playing */
extern int word_3CE3A;
extern char cd_path[];
int PlayDigiSfx(char *name, int vol, int pan, int loop);   /* seg015 */
extern char byte_47A87;                 /* busy: the wait pointer */
extern char byte_47A86;                 /* the crew can't walk */
extern unsigned char room_action;       /* 1 walk, 2 use, 3 get, 4 look, 5 talk */
extern unsigned char room_target;       /* object acted on */
extern unsigned char room_target2;      /* used on this */
int hit_valid;                          /* the object hit has a walk-to point */
int cur_exit;
Timer timers[31];                       /* deferred actions */
void WalkActorTo(int n, int a, int b, int x, int y, unsigned msg);  /* seg000 */
extern int room_timers[8];
int AnyActorBusy(void);
int hit_x;
int hit_y;

int HasScript(unsigned char a, unsigned char b, unsigned char c);
int FindScript(unsigned char test, unsigned char wild, unsigned char a, unsigned char b,
               unsigned char c);
int ScanScripts(int kind, unsigned long key, int run);
extern char byte_47A8E;

/* A gate block: a table of scripts by kind (start, end offsets). */
typedef struct Gate {
    int source;                 /* 00 0 the room, 1 global, 2 the mission */
    unsigned table;             /* 02 */
    int unk04;                  /* 04 */
} Gate;

extern Gate gates[7];
extern int ngates;
extern int cur_source;
extern MemHandle global_handle;
extern MemHandle mission_handle;
extern char script_more;                /* a script asks for more matches */
int RunScripts(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
int RunWildScripts(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
char far *RdfPtr(unsigned off);
void PlayScaled(int n, char *name, int x, int y);
int DepthScale(int y);
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
long PopRoomMsg(void);
void TraceMsg(long msg);
void RoomMsg(void);
void CallScript(void far *code, unsigned long msg);
long ScriptService(unsigned cmd, int a1, int a2, int a3, int a4, int a5, int a6);
void CentreLine(char *dst, char *src);
void ChoiceTitle(char *dst, char far *name, int n);
long Converse(int text);
long TextBox(char *(far *fn)(int, void *, char *), void *arg, int x, int y,
               int color, int choice, int maxl, int flag);
long MsgBox(char *title, char *text, int x, int y, int color, int msg);
extern int full_view;
void StartTalk(int a, char *s, int b, int c, int d, int e);   /* seg000 */
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
void CheckRegions(int x, int y, int ox, int oy);
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
void CloseAllPanels(void);
int AwayInput(void);
void LoadRoom(char *mission, int n, int first);
void EnterRoom(int entry);
void BeamUp(void);
void FreeRoom(void);
void SaveRoom(void);
void RestoreRoom(void);

extern int room_num;
extern int word_47A82;
extern int word_47A84;
void ActorPos(int i, int x, int y, int z);  /* seg000 */
extern long room_ticks;
extern int word_3B936;
void SavePanels(void);
void LoadPanels(void);
void SaveSound(void);                   /* seg015 */
void LoadSound(void);
void OpenMissionArchive(void);          /* seg003 */
void SpaceSave(void);                   /* (c2B980) */
void SpaceLoad(void);
void SaveActors(void);                   /* seg000 */
void LoadActors(void);
void ShowCrew(char *name, int a);      /* (c2D688) */
void SetSteering(int on);               /* seg001 */
MemHandle getanyfileems(char *name, char *ext);

typedef struct Name10 {
    char s[10];
} Name10;
extern Name10 crew_name;               /* seg001 */

int word_3CA46 = 0;
int word_3CA48 = -1;
Item items[64] = {                      /* 0x40-0x7F */
    { 1, "iphasers" }, { 1, "iphaserk" }, { 1, "istricor" },
    { 1, "imtricor" }, { 1, "icomm" }, { 1, "imedkit" }
};
int menu_open = 0;
int word_3CCCC = 0;
int cur_region = -1;                    /* the region the pointer is in */

/* Save the room's state. */
void SaveRoom(void)
{
    SaveWrite(room_mission, 16);
    SaveWrite(&room_num, 2);
    SaveWrite(&room_ticks, 4);
    SaveWrite(bg_name, 10);
    SaveWrite(pri_name, 10);
    SaveWrite(map_name, 10);
    SaveWrite(&hit_valid, 2);
    SaveWrite(&hit_x, 2);
    SaveWrite(&hit_y, 2);
    SaveWrite(timers, sizeof(timers));
    SaveWrite(gates, sizeof(gates));
    SaveWrite(&ngates, 2);
    SavePanels();
    SaveWrite(&cur_region, 2);
}

/* Write the game state to the save file. */
void SaveGameState(void)
{
    SaveWrite(&game_mode, 2);
    SaveSpace();
    SaveWrite(&blink_count, 4);
    SaveWrite(&kbd_mouse, 2);
    SaveWrite(&in_orbit, 2);
    SaveWrite(&bridge_tick, 2);
    SaveWrite(&bridge_ticks, 4);
    SaveWrite(&word_3B936, 2);
    SaveWrite(&view_dir, 2);
    SaveWrite(mission_name, 16);
    SaveWrite(boost_active, 12);
    SpaceSave();
    if (game_mode == 2)
        SaveRoom();
    SaveWrite(&blink_count, 4);
    if (game_mode != -1)
        SaveActors();
    SaveWrite(room_timers, 0x12A);
    SaveWrite(msg_queue, sizeof(msg_queue));
    SaveWrite(&msg_head, 2);
    SaveWrite(&msg_tail, 2);
    SaveWrite(items, sizeof(items));
    SaveSound();
}

/* Load the room saved by SaveRoom. */
void RestoreRoom(void)
{
    FadeOut();
    SaveRead(room_mission, 16);
    SaveRead(&room_num, 2);
    LoadRoom(room_mission, room_num, 0);
    SaveRead(&room_ticks, 4);
    SaveRead(bg_name, 10);
    SaveRead(pri_name, 10);
    SaveRead(map_name, 10);
    LockScreen();
    LoadFilePacked(bg_name, "bgd", screen_base);
    MemCpy(backbuf->data, screen->data, 64000);
    UnlockScreen();
    BlitToScreen(&screen_rect);
    LoadFilePacked(pri_name, "pri", mask_buf);
    FreeAnyFile(map_handle);
    map_handle = getanyfileems(map_name, "map");
    LoadWalkGraph(map_name);
    room_action = 1;
    SaveRead(&hit_valid, 2);
    SaveRead(&hit_x, 2);
    SaveRead(&hit_y, 2);
    SaveRead(timers, sizeof(timers));
    SaveRead(gates, sizeof(gates));
    SaveRead(&ngates, 2);
    LoadPanels();
    SaveRead(&cur_region, 2);
}

/* Read the game state back from the save file. */
void LoadGameState(void)
{
    Name10 seq;

    if (prev_mode == 1)
        BridgeLeave();
    else if (prev_mode == 2)
        FreeRoom();
    SaveRead(&game_mode, 2);
    LoadSpace();
    SaveRead(&blink_count, 4);
    SaveRead(&kbd_mouse, 2);
    SaveRead(&in_orbit, 2);
    SaveRead(&bridge_tick, 2);
    SaveRead(&bridge_ticks, 4);
    SaveRead(&word_3B936, 2);
    SaveRead(&view_dir, 2);
    SaveRead(mission_name, 16);
    OpenMissionArchive();
    SaveRead(boost_active, 12);
    SpaceLoad();
    prev_mode = game_mode;
    FadeOut();
    if (game_mode == 2)
        RestoreRoom();
    else if (game_mode == -1) {
        BridgeEnter(1);
        prev_mode = 1;
    } else
        BridgeEnter(0);
    SaveRead(&blink_count, 4);
    if (game_mode != -1) {
        LoadActors();
        seq = crew_name;
        crew_name.s[0] = 0;
        if (seq.s[0]) {
            ShowCrew(seq.s, -1);
            SetSteering(0);
        }
    }
    SaveRead(room_timers, 0x12A);
    SaveRead(msg_queue, sizeof(msg_queue));
    SaveRead(&msg_head, 2);
    SaveRead(&msg_tail, 2);
    SaveRead(items, sizeof(items));
    LoadSound();
    SaveClose();
    longjmp(game_jmp, game_mode == 2 ? 2 : 1);
}

/* Drop src's gate blocks (all of them for table -1). */
void sub_1C20A(int src, int table)
{
    int n;
    int i;

    for (i = n = 0; i < ngates; i++) {
        if (gates[i].source == src && (table == -1 || gates[i].table == table))
            continue;
        gates[n++] = gates[i];
    }
    ngates = n;
}

/* Add a gate block, keeping them in order of unk04. */
void sub_1C266(int src, int table, int unk)
{
    int i;

    sub_1C20A(src, table);
    if (ngates == 7)
        Fatal("Too many gate blocks");
    for (i = ngates; i >= 1; i--) {
        if (unk > gates[i - 1].unk04)
            break;
        gates[i] = gates[i - 1];
    }
    gates[i].source = src;
    gates[i].table = table;
    gates[i].unk04 = unk;
    ngates++;
}

void sub_1C2FA(void)
{
    if (menu_open)
        MenuClose();
    menu_open = 0;
}

/* Start the away mission. */
void sub_1C30E(void)
{
    LockScreen();
    MemSet(screen, 64000, 0xDF);
    UnlockScreen();
    LoadMusic(mission_name, 0x67);
    LoadRoom(mission_name, word_3CA46, 1);
    EnterRoom(word_3CA48);
    word_3CA48 = -1;
    ActorPos(0, 20, 20, word_3CA46 = 0);
    ActorPos(1, 20, 20, 0);
    ActorPos(6, 20, 20, 0);
    ActorPos(5, 20, 20, 0);
    ActorPos(4, 20, 20, 0);
    ActorPos(7, 20, 20, 0);
    ActorPos(2, 20, 20, 0);
    ActorPos(3, 20, 20, 0);
    ActorPos(8, 20, 20, 0);
}

/* The away mission's main loop. */
void AwayLoop(void)
{
    setjmp(room_jmp);
    for (;;) {
        while (msg_tail != msg_head)
            RoomMsg();
        RoomTick();
        word_47A82 = mouse_x;
        word_47A84 = mouse_y;
    }
}

void EndAway(void)
{
    FreeRoom();
}

/* Beam the landing party up. */
void BeamUp(void)
{
    int i;
    int done;
    Actor *a;

    byte_47A87 = 1;
    sub_1C2FA();
    for (i = 0, a = actors; i != MAX_ACTORS; i++, a++) {
        if ((a->flags & 1) == 1) {
            ((ActorBits *)a)->b3 = 0;
            StartAnim(i, "?teled", -1, -1, -1);
        }
    }
    BridgeSfx(4);
    for (;;) {
        done = 1;
        for (i = 0, a = actors; i != MAX_ACTORS; i++, a++)
            if ((a->flags & 1) == 1 && a->loops == 0) {
                done = 0;
                break;
            }
        if (done)
            break;
        RoomTick();
    }
    byte_47A87 = 0;
    PlayMusic(0xFE, 0xFE);
    longjmp(game_jmp, 4);
}

/* The offset of b from a. */
int sub_1C4C8(char far *a, char far *b)
{
    return b - a;
}

/* The header of an .rdf: the mission's data.rdf, the episode's and the
 * room's. */
typedef struct RdfHdr {
    long (far *service)();      /* 00 callback for the scripts */
    int *state;                 /* 04 the room state */
    int version;                /* 06 */
    int y0;                     /* 08 gate table (data, episode); room: depth range */
    int y1;                     /* 0A item names (data, episode) */
    unsigned z0;                /* 0C their end */
    unsigned z1;                /* 0E episode: its first free actor */
    unsigned table;             /* 10 room: gate table */
    char unk12[12];             /* 12 */
    unsigned bans;              /* 1E names of the .ban animations */
    unsigned bans_end;          /* 20 */
    unsigned walk_in;           /* 22 how the crew enter the room */
    unsigned walk_in_end;       /* 24 */
} RdfHdr;

extern int word_47E18;
extern long word_47832;                 /* depth scale */

/* Load room n of the episode: its pictures, the mission's, episode's and
 * room's .rdf (first: also their item names and gate blocks). */
void LoadRoom(char *mission, int n, int first)
{
    RdfHdr far *g;
    RdfHdr far *h;
    int id;
    int i;
    char far *p;
    char far *end;
    char far *q;
    char far *qend;
    unsigned off;
    unsigned last;
    char name[12];
    Actor *a;
    int k;

    key_accel = 1;
    strcpy(room_mission, mission);
    room_num = n;
    room_ticks = 0;
    byte_47A87 = 0;
    cur_region = -1;
    FadeOut();
    sprintf(room_name, "%s%d", room_mission, n);
    strcpy(bg_name, room_name);
    LockScreen();
    LoadFilePacked(room_name, "bgd", screen_base);
    UnlockScreen();
    LoadFilePacked(room_name, "pri", mask_buf);
    strcpy(pri_name, room_name);
    LoadPalette("palette");
    LockScreen();
    MemCpy(backbuf->data, screen->data, 64000);
    UnlockScreen();
    BlitToScreen(&screen_rect);

    mission_handle = CacheLoadEMS("data", "rdf");
    g = LockMem(mission_handle);
    if (g->version != 0x211)
        Fatal("Incorrect game header version");
    g->service = ScriptService;
    g->state = room_timers;
    if (first) {
        gates[0].source = 2;
        gates[0].table = g->y0;
        gates[0].unk04 = 0x7FFF;
        ngates = 1;
        i = 6;
        for (p = (char far *)g + g->y1, end = (char far *)g + g->z0; p != end;
             p += _fstrlen(p) + 1) {
            _fstrncpy(items[i].name, p, 8);
            items[i].name[8] = 0;
            items[i].have = 1;
            i++;
        }
        id = i + 0x40;
    }
    UnlockMem(mission_handle);

    global_handle = CacheLoadEMS(room_mission, "rdf");
    g = LockMem(global_handle);
    switch (g->version) {
    case 0x211:
        word_47E18 = 0;
        break;
    case 0x212:
        UnlockMem(global_handle);
        word_47E18 = getanyfileems(room_name, "rtf");
        g = LockMem(global_handle);
        break;
    default:
        Fatal("Incorrect Episode header version:%d", g->version);
    }
    g->service = ScriptService;
    g->state = room_timers;
    if (first) {
        sub_1C266(1, g->y0, 1000);
        i = id - 0x40;
        for (q = (char far *)g + g->y1, qend = (char far *)g + g->z0; q != qend;
             q += _fstrlen(q) + 1) {
            _fstrncpy(items[i].name, q, 8);
            items[i].name[8] = 0;
            i++;
        }
    }
    for (i = g->z1; i < MAX_ACTORS; i++) {
        actors[i].letter = 0;
        actors[i].flags = 0;
        ((ActorBits *)&actors[i])->b3 = 0;
    }
    UnlockMem(global_handle);

    rdf_handle = getanyfileems(room_name, "rdf");
    h = LockMem(rdf_handle);
    switch (h->version) {
    case 0x111:
        text_handle = 0;
        break;
    case 0x112:
        UnlockMem(rdf_handle);
        text_handle = getanyfileems(room_name, "rtf");
        h = LockMem(rdf_handle);
        break;
    default:
        Fatal("Incorrect room header version");
    }
    h->service = ScriptService;
    h->state = room_timers;
    sub_1C20A(0, -1);
    sub_1C266(0, h->table, 0);
    UnlockMem(rdf_handle);
    room_action = 1;
    ActionCursor(1, 0);
    strcpy(map_name, room_name);
    map_handle = getanyfileems(map_name, "map");
    LoadWalkGraph(map_name);
    FreeActors();
    for (a = actors, k = MAX_ACTORS; k; k--, a++)
        if ((a->flags & 8) == 8)
            ((ActorBits *)a)->b3 = 1;
    h = LockMem(rdf_handle);
    word_47832 = (long)((double)(h->z1 - h->z0) / (double)(h->y0 - h->y1 + 1) * 256.0);
    if (h->bans != h->bans_end) {
        for (off = h->bans, last = h->bans_end; off != last; ) {
            p = (char far *)h + off;
            _fstrcpy(name, p);
            do
                off++;
            while (*p++);
            UnlockMem(rdf_handle);
            LoadBan(name);
            h = LockMem(rdf_handle);
        }
    }
    UnlockMem(rdf_handle);
    msg_head = msg_tail = 0;
    if (first)
        PostRoomMsg(11, 0, 0, 0);
    for (i = 0; i != 8; i++)
        if (room_timers[i] > 0)
            room_timers[i] = 0;
}

/* Bring the landing party in by entrance entry (-1: beam in, -2: just
 * post message 12). Each walk-in record is an actor, where it appears,
 * then (entrance, x, y, x2, y2) pairs ending in -1. */
/* (99.2%: the target tests next != end before moving next into off.) */
void EnterRoom(int entry)
{
    RdfHdr far *h;
    unsigned off;
    unsigned end;
    unsigned next;
    int n;
    int x;
    int y;
    int x2;
    int y2;
    int far *p;
    int e;

    PostRoomMsg(0, 0, 0, 0);
    if (entry == -2) {
        PostRoomMsg(12, 0, 0, 0);
        return;
    }
    h = LockMem(rdf_handle);
    for (off = h->walk_in, end = h->walk_in_end; off != end; off = next) {
        p = (int far *)((char far *)h + off);
        n = *p;
        x = *++p;
        y = *++p;
        p++;
        x2 = x;
        y2 = y;
        while ((e = *p++) != -1) {
            if (e == entry) {
                x = p[0];
                y = p[1];
                x2 = p[2];
                y2 = p[3];
            }
            p += 4;
        }
        next = sub_1C4C8((char far *)h, (char far *)p);
        if (n >= 0 && n < MAX_ACTORS && (actors[n].flags & 4) == 4) {
            UnlockMem(rdf_handle);
            if (entry == -1) {
                StartAnim(n, "?tele", x, y, -1);
                if (n == 0)
                    actors[n].notify = 0xFF;
            } else
                WalkActorTo(n, x, y, x2, y2, (n == 0 ? -1 : 0) & 0xFF);
            if (n == 0)
                byte_47A87 = 1;
            h = LockMem(rdf_handle);
        }
    }
    UnlockMem(rdf_handle);
    if (entry == -1)
        BridgeSfx(6);
}

/* 1 while a landing party member is busy. */
int AnyActorBusy(void)
{
    int i;
    Actor *a;

    for (a = actors, i = 0; i != MAX_ACTORS; i++, a++)
        if ((a->flags & 4) == 4 && (actors[i].flags & 6) == 6)
            return 1;
    return 0;
}

void sub_1CC76(void)
{
    if (inv_sprite.type == 2)
        SpriteErase(&inv_sprite);
    UpdateSprites();
    if (inv_sprite.type == 2) {
        DelSprite(&inv_sprite);
        inv_sprite.type = 0;
        CacheRelease(inv_sprite.handle);
    }
}

/* Handle the next event in the room. */
void RoomTick(void)
{
    Event ev;
    int obj;
    Actor *a;
    int k;

    sub_1C2FA();
    if (!GetEvent(&ev))
        return;
    switch (ev.type) {
    case EV_TICK:
        if (room_action == 2 && room_target < MAX_ACTORS
                && (actors[room_target].flags & 0x12) == 0x12) {
            HideInvIcon();
            room_action = 1;
            break;
        }
        UpdateActors();
        StunTick();
        HiliteCursor();
        DrawBans();
        UpdateSprites();
        UpdateBans();
        MusicTick();
        RoomTimers();
        blink_count++;
        if (word_3CCCC == 0 || room_ticks < 2) {
            room_ticks++;
            PostRoomMsg(0, (unsigned char)room_ticks, (unsigned char)(room_ticks >> 8), 0);
        }
        if (room_ticks >= 2)
            FadeUp();
        break;
    case EV_MOVE:
        SpriteSetPos(&mouse_sprite, ev.x, ev.y, 15);
        break;
    case EV_KEY:
        if (byte_47A87)
            break;
        switch ((unsigned char)((unsigned)ev.key >> 8)) {
        case 0x1C:
        case 0x3B:
            goto click;
        case 0x01:
        case 0x39:
        case 0x3C:
            goto menu;
        case 0x11:
            HideInvIcon();
            room_action = 1;
            break;
        case 0x14:
            HideInvIcon();
            room_action = 5;
            goto action;
        case 0x26:
            HideInvIcon();
            room_action = 4;
            goto action;
        case 0x22:
            HideInvIcon();
            room_action = 3;
            goto action;
        case 0x16:
            HideInvIcon();
            room_action = 2;
            goto action;
        case 0x17:
            if (room_action == 2) {
                sub_1CC76();
                obj = PickItem(50, 50, 1);
                goto use_item;
            } else {
                HideInvIcon();
                room_action = 4;
                obj = PickItem(50, 50, 1);
                goto look_item;
            }
        case 0x18:
            OptionsMenu(0xA0, 0x19);
            return;
        }
        return;
    case EV_DOWN1:
    click:
        if (byte_47A87)
            break;
        switch (room_action) {
        case 1:
            if (byte_47A86)
                break;
            for (a = actors, k = MAX_ACTORS; k; k--, a++)
                if ((a->flags & 0x10) == 0x10)
                    a->sprite.type = 1;
            obj = FindObject(mouse_x, mouse_y);
            for (a = actors, k = MAX_ACTORS; k; k--, a++)
                if ((a->flags & 0x10) == 0x10)
                    a->sprite.type = 0;
            if (WalkToHit())
                break;
            if (obj < 0x40 && obj > 0)
                PostRoomMsg(1, obj, 0, 0);
            else
                WalkActorTo(0, -1, -1, mouse_x, mouse_y, 0);
            break;
        case 2:
            if (room_target < MAX_ACTORS && (actors[room_target].flags & 0x12) == 0x12) {
                HideInvIcon();
                room_action = 1;
                break;
            }
            obj = FindObject(mouse_x, mouse_y);
            if (obj == -10) {
                sub_1CC76();
                obj = PickItem(50, 50, 0);
            use_item:
                if (obj == -1)
                    obj = -2;
            }
            HideInvIcon();
            room_target2 = obj;
            if (WalkToHit())
                break;
            if (obj != -2)
                PostRoomMsg(room_action, room_target, room_target2, 0);
            if ((actors[0].flags & 2) == 2)
                break;
            ShowInvIcon(1);
            break;
        case 3:
        case 4:
        case 5:
            obj = FindObject(mouse_x, mouse_y);
            if (CantAct(obj, room_action))
                break;
            HideInvIcon();
            if (obj == -10) {
                obj = PickItem(50, 50, 0);
            look_item:
                if (obj == -1)
                    obj = -2;
            }
            room_target = obj;
            if (WalkToHit())
                break;
            if (obj != -2)
                PostRoomMsg(room_action, room_target, 0, 0);
            if (room_action != 4)
                break;
            if ((actors[0].flags & 2) == 2)
                break;
            ShowInvIcon(0);
            break;
        }
        break;
    case EV_DOWN2:
    menu:
        if (byte_47A87)
            break;
        HideInvIcon();
        BridgeSfx(2);
        room_action = ActionPanel();
    action:
        if (room_action == 2) {
            obj = PickUseTarget();
            if (obj == -1) {
                room_action = 1;
                break;
            }
            room_target = obj;
        }
        if (room_action == 2 && room_target == 0x44 && (actors[0].flags & 2) != 2) {
            if (WalkToHit())
                break;
            PostRoomMsg(room_action, room_target, 0, 0);
            room_action = 1;
            break;
        }
        if (room_action == 4 || (room_action == 2 && (actors[0].flags & 2) != 2))
            ShowInvIcon(room_action == 2);
        break;
    }
}

void FreeRoom(void)
{
    sub_1C2FA();
    FadeOut();
    HideInvIcon();
    FreeActors();
    CloseAllPanels();
    if (word_47E18)
        FreeAnyFile(word_47E18);
    if (text_handle)
        FreeAnyFile(text_handle);
    FreeAnyFile(rdf_handle);
    rdf_handle = 0;
    CacheRelease(global_handle);
    CacheRelease(mission_handle);
    FreeAnyFile(map_handle);
}

/* The scale (in 256ths) of an actor at y. */
int DepthScale(int y)
{
    RdfHdr far *h;

    if (rdf_handle == 0)
        return 0x100;
    h = LockMem(rdf_handle);
    y = h->y0 > y ? y : h->y0;
    y = h->y1 < y ? y : h->y1;
    y = (int)(((long)(y - h->y1) * word_47832) >> 8) + h->z0;
    UnlockMem(rdf_handle);
    return y;
}

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

/* Search the gates' scripts of kind for key (bytes 1 and 2 of a script's
 * key may be FF: any, except for messages 0, 9, 10 and 11), running them
 * if run. 1 if one was found (and didn't ask for more). */
int ScanScripts(int kind, unsigned long key, int run)
{
    unsigned char action;
    int wild;
    int found;
    int g;
    Gate *gt;
    Script far *p;
    Script far *end;

    action = (unsigned char)key;
    wild = action == 0 || action == 10 || action == 11 || action == 9 ? 0 : 1;
    found = 0;
    if (ngates == 0)
        Fatal("No gate blocks");
    for (g = 0, gt = gates; g < ngates; g++, gt++) {
        switch (cur_source = gt->source) {
        case 0:
            talk_handle = rdf_handle;
            break;
        case 1:
            talk_handle = global_handle;
            break;
        case 2:
            talk_handle = mission_handle;
            break;
        }
        talk_data = LockMem(talk_handle);
        p = (Script far *)(talk_data + *(unsigned far *)(talk_data + gt->table + kind * 4));
        end = (Script far *)(talk_data + *(unsigned far *)(talk_data + gt->table + kind * 4 + 2));
        if (wild) {
            for (; p < end; p = (Script far *)(talk_data + p->next)) {
                unsigned long k;
                unsigned long mask;

                k = p->key;
                mask = (k & 0x00FF0000L) == 0x00FF0000L ? 0x00FF0000L : 0;
                if ((k & 0x0000FF00L) == 0x0000FF00L)
                    mask |= 0x0000FF00L;
                if ((mask | key) == k) {
                    if (!run)
                        goto yes;
                    script_more = 0;
                    CallScript(p->code, key);
                    if (!script_more)
                        goto yes;
                }
            }
        } else {
            for (; p < end; p = (Script far *)(talk_data + p->next))
                if (p->key == key) {
                    if (run) {
                        script_more = 0;
                        CallScript(p->code, key);
                        if (script_more)
                            continue;
                    }
                    if (action != 0 || kind != 1)
                        goto yes;
                    found = 1;
                    break;
                }
        }
        UnlockMem(talk_handle);
    }
    return found;
yes:
    UnlockMem(talk_handle);
    return 1;
}

/* Find (and unless test, run) the scripts for (a, b, c), of kind 0, then
 * kinds 1-3 (2 only unless wild; 3 only when neither). */
int FindScript(unsigned char test, unsigned char wild, unsigned char a, unsigned char b,
               unsigned char c)
{
    char saved;
    unsigned char any;
    unsigned long key;

    key = (unsigned long)a | (unsigned long)b << 8 | (unsigned long)c << 16;
    saved = byte_47A8E;
    any = test == 0 && wild == 0 ? 1 : 0;
    byte_47A8E = !any;
    if (ScanScripts(0, key, 1)) {
        byte_47A8E = saved;
        return any;
    }
    byte_47A8E = 0;
    if (ScanScripts(1, key, !test))
        goto found;
    byte_47A8E = !any;
    if (!wild && ScanScripts(2, key, 1))
        goto found;
    if (any && ScanScripts(3, key, 1))
        goto found;
    byte_47A8E = saved;
    return 0;
found:
    byte_47A8E = saved;
    return 1;
}

/* Does the room have a script for (a, b, c)? */
int HasScript(unsigned char a, unsigned char b, unsigned char c)
{
    return FindScript(1, 0, a, b, c);
}

/* Handle the next room message: scripts first, then the defaults. */
void RoomMsg(void)
{
    Msg *m;

    m = &msg_queue[msg_head++];
    msg_head %= 16;
    if (m->type == 10 && m->arg == 0xFF)
        byte_47A87 = 0;
    else if (m->type == 10 && m->arg >= 0xE0) {
        int i;

        i = m->arg - 0xE0;
        PostRoomMsg(timers[i].msg[0], timers[i].msg[1], timers[i].msg[2], timers[i].msg[3]);
        timers[i].active = 0;
        return;
    }
    if (FindScript(0, 0, m->type, m->arg, m->b2))
        return;
    switch (m->type) {
    case 1:
        WalkActorTo(0, -1, -1, mouse_x, mouse_y, 0);
        break;
    case 6: {
        Rdf far *r;
        int n;

        r = LockMem(rdf_handle);
        n = ((int far *)((char far *)r + 0x26))[m->arg];
        UnlockMem(rdf_handle);
        FreeRoom();
        BridgeSfx(0xFE);
        LoadRoom(room_mission, n, 0);
        EnterRoom(m->arg ^ 1);
        break;
    }
    }
}

/* Run a script's code (SI and BX at the room state) for message msg. */
void CallScript(void far *code, unsigned long msg)
{
    msg_action = (unsigned char)msg;
    msg_target = (unsigned char)(msg >> 8);
    msg_target2 = (unsigned char)(msg >> 16);
    _asm {
        push si
        push di
        mov ax, ds
        mov es, ax
        mov bx, offset room_timers
        mov si, bx
        call dword ptr code
        pop di
        pop si
    }
}

/* Run the room for ticks. */
void RoomWait(unsigned ticks)
{
    int busy;
    unsigned long start;

    busy = (unsigned char)byte_47A87;
    byte_47A87 = 1;
    word_3CCCC = 1;
    start = blink_count;
    while (blink_count - start < ticks)
        RoomTick();
    word_3CCCC = 0;
    byte_47A87 = busy;
}

/* Wait (running the room) until actor n finishes its animation. */
void WaitActor(int n)
{
    int busy;
    Actor *a;

    busy = (unsigned char)byte_47A87;
    byte_47A87 = 1;
    word_3CCCC = 1;
    a = &actors[n];
    *(char *)&a->state &= ~0x10;
    while (!(*(char *)&a->state & 0x10))
        RoomTick();
    word_3CCCC = 0;
    byte_47A87 = busy;
}

/* The direction letter from actor n towards (x, y). */
char DirTo(int n, int x, int y)
{
    int sx;

    sx = actors[n].sprite.x;
    return "enws"[(FixAtan2(actors[n].sprite.y - y, x - sx) + 0x480) / 256 & 3];
}

/* The centre of the bounding box of object id's polygons. */
void ObjectCentre(int id, int *px, int *py)
{
    Rdf far *r;
    int far *e;
    int far *end;
    unsigned far *v;
    unsigned minx;
    unsigned miny;
    unsigned maxx;
    unsigned maxy;
    int n;

    minx = miny = -1;
    maxx = maxy = 0;
    r = LockMem(rdf_handle);
    e = (int far *)((char far *)r + r->objects);
    end = (int far *)((char far *)r + r->objects_end);
    while (e != end) {
        if (*e & 0x8000)
            e += 3;
        if (*e == id) {
            for (v = (unsigned far *)(e + 2), n = e[1]; n; n--, v += 2) {
                if (v[0] < minx)
                    minx = v[0];
                if (v[0] > maxx)
                    maxx = v[0];
                if (v[1] < miny)
                    miny = v[1];
                if (v[1] > maxy)
                    maxy = v[1];
            }
        }
        e = NextPoly(e);
    }
    UnlockMem(rdf_handle);
    *px = (maxx + minx) / 2;
    *py = (maxy + miny) / 2;
}

/* Show bitmap name (at depth z) for 5 ticks. */
void FlashBitmap(char *name, int z)
{
    Sprite spr;
    unsigned long end;

    if (z < 0 || z > 15)
        z = 5;
    AddSprite(&spr);
    SpriteSetPos(&spr, 0, 0, z);
    SpriteSetBitmap(&spr, LoadBitmap(name));
    UpdateSprites();
    end = GetTicks() + 5;
    while (GetTicks() < end)
        SpriteErase(&spr);
    UpdateSprites();
    ReleaseBitmap(spr.handle);
    DelSprite(&spr);
}

/* Draw a line 3 pixels high in colour color into the draw buffer
 * (Bresenham; the loops' pixel offsets are patched for the width). */
void DrawLine3(int x0, int y0, int x1, int y1, int color)
{
    int stride;

    _asm {
        mov ax, line_width
        mov stride, ax
        mov si, x1
        sub si, x0
        jns xok
        neg si
    xok:
        mov bx, y1
        sub bx, y0
        jns yok
        neg bx
    yok:
        les di, draw_buf
        mov ax, x0
        cmp ax, x1
        jg from1
        add di, x0
        mov ax, y0
        mul line_width
        add di, ax
        mov ax, y0
        cmp ax, y1
        jmp short updown
    from1:
        add di, x1
        mov ax, y1
        mul line_width
        add di, ax
        mov ax, y1
        cmp ax, y0
    updown:
        jle down
        neg stride
    down:
        cmp si, bx
        jb steep
        mov ax, line_width
        mov word ptr cs:a1 + 3, ax
        mov word ptr cs:a2 + 3, ax
        mov word ptr cs:a3 + 3, ax
        neg ax
        mov word ptr cs:a0 + 3, ax
        mov word ptr cs:b0 + 3, ax
        mov word ptr cs:c0 + 3, ax
        mov cx, si
        mov dx, cx
        neg dx
        shl si, 1
        shl bx, 1
        mov ax, color
    a0: mov es:[di + 1234h], ah
    a1: mov es:[di + 4321h], ah
        stosb
        jcxz done
        push bp
        mov bp, stride
    xloop:
        add dx, bx
        jns xstep
    b0: mov es:[di + 1234h], ah
    a2: mov es:[di + 4321h], ah
        stosb
        loop xloop
        jmp short xdone
    xstep:
        add di, bp
        sub dx, si
    c0: mov es:[di + 1234h], ah
    a3: mov es:[di + 4321h], ah
        stosb
        loop xloop
    xdone:
        pop bp
        jmp short done
    steep:
        mov cx, bx
        mov dx, cx
        neg dx
        shl si, 1
        shl bx, 1
        mov ax, color
        mov es:[di - 1], ah
        mov es:[di], ax
        jcxz done
        push bp
        mov bp, stride
    yloop:
        add di, bp
        add dx, si
        jns ystep
        mov es:[di - 1], ah
        mov es:[di], ax
        loop yloop
        jmp short ydone
    ystep:
        inc di
        sub dx, bx
        mov es:[di - 1], ah
        mov es:[di], ax
        loop yloop
    ydone:
        pop bp
    done:
    }
}

/* Open a text panel; returns it, or -1 if all 6 are in use. */
int OpenPanel(int a, int b, int c, int d, int f, int e)
{
    int i;
    Panel *pn;

    for (i = 0; i < 6; i++)
        if (panels[i].active == 0)
            break;
    if (i == 6)
        return -1;
    panels[i].active = 1;
    pn = &panels[i];
    pn->arg[0] = a;
    pn->arg[1] = b;
    pn->arg[2] = c;
    pn->arg[3] = d;
    pn->arg[4] = e;
    pn->arg[5] = f;
    ShowPanel(i);
    UpdateSprites();
    return i;
}

int line_colors[2] = { 0xBBB8, 0xA3A0 };   /* edge and middle colours */

/* Draw line sprite i: (arg 0, 1) to (2, 3) at depth arg 4, colour arg 5. */
void ShowPanel(int i)
{
    Panel *pn;
    int x0;
    int y0;
    int x1;
    int y1;
    int z;
    int color;
    Sprite *spr;
    int left;
    int right;
    int top;
    int bottom;
    int w;
    int h;
    int lw;
    MemHandle hnd;
    Bitmap far *bmp;

    pn = &panels[i];
    if (!pn->active)
        return;
    x0 = pn->arg[0];
    y0 = pn->arg[1];
    x1 = pn->arg[2];
    y1 = pn->arg[3];
    z = pn->arg[4];
    color = pn->arg[5];
    spr = &pn->sprite;
    if ((unsigned)color > 1)
        color = 1;
    if (x1 > x0) {
        left = x0;
        right = x1;
    } else {
        left = x1;
        right = x0;
    }
    if (y1 > y0) {
        top = y0;
        bottom = y1;
    } else {
        top = y1;
        bottom = y0;
    }
    w = right - left + 3;
    h = bottom - top + 3;
    hnd = AllocMemAbort(w * h + 8, 1);
    bmp = LockMem(hnd);
    bmp->w = w;
    bmp->h = h;
    bmp->x = 1;
    bmp->y = 1;
    lw = bmp->w;
    draw_buf = bmp->data;
    MemSet(draw_buf, bmp->w * bmp->h, 0);
    line_width = lw;
    DrawLine3(x0 - left + 1, y0 - top + 1, x1 - left + 1, y1 - top + 1, line_colors[color]);
    UnlockMem(hnd);
    if (z < 0 || z > 15)
        z = 5;
    AddSprite(spr);
    SpriteSetPos(spr, left, top, z);
    SpriteSetBitmap(spr, hnd);
}

/* Close text panel i. */
void ClosePanel(int i)
{
    Sprite *spr;

    if (i >= 0 && i < 6 && panels[i].active) {
        spr = &panels[i].sprite;
        SpriteErase(spr);
        UpdateSprites();
        FreeMem(spr->handle);
        DelSprite(spr);
        panels[i].active = 0;
    }
}

void CloseAllPanels(void)
{
    int i;

    for (i = 0; i < 6; i++)
        ClosePanel(i);
}

void SavePanels(void)
{
    SaveWrite(panels, sizeof(panels));
}

void LoadPanels(void)
{
    int i;

    SaveRead(panels, sizeof(panels));
    for (i = 0; i < 6; i++)
        ShowPanel(i);
}

/* Copy the 10 character name at off in the talk data. */
#define GETNAME(name, off) \
    (talk_data = LockMem(talk_handle), MemCpy(name, talk_data + (off), 10), \
     name[9] = 0, UnlockMem(talk_handle))

/* (98%: the target updates actors through a pointer it never reloads,
 * doing bit changes through al.)
 * The room scripts' service call. The talk data is unlocked while it
 * runs (so it can move): a caller there gets its return segment fixed
 * up afterwards. */
long ScriptService(unsigned cmd, int a1, int a2, int a3, int a4, int a5, int a6)
{
    char *n;
    long result;

    result = 0;
    _asm {
        mov ax, [bp+4]
        cmp ax, word ptr talk_data+2
        jne inroom
        mov word ptr [bp+4], 0
    inroom:
    }
    UnlockMem(talk_handle);
    switch (cmd) {
    case 1: {
        char name[10];

        GETNAME(name, a2);
        if (name[0] == (char)0xFF) {
            Converse(a2 + 1);
            GETNAME(name, a2 + 7);
            if (name[0] == 0 && a5 != 0 && a5 != 0xFE)
                PostRoomMsg(10, a5, 0, 0);
            if (name[0] == 0)
                break;
        }
        a1 = StartAnim(a1, name, a3, a4, -1);
        if (a5 == 0xFE)
            WaitActor(a1);
        else
            actors[a1].notify = a5;
        break;
    }
    case 57: {
        char name[10];

        GETNAME(name, a2);
        if (full_view)
            break;
        StartTalk(a1, name, -1, -1, -1, 0);
        break;
    }
    case 45:
        if (a3 == 0xFE) {
            StartEffect(a1, a2, 0);
            WaitActor(a1);
        } else
            StartEffect(a1, a2, a3);
        break;
    case 2:
        SetCrewIcon(a1, a2);
        break;
    case 3:
        SetSpeaker(a1, a2);
        break;
    case 4:
        result = Converse(a1);
        break;
    case 5:
        result = ItemGive(a1);
        break;
    case 6:
        if (AnyActorBusy())
            break;
        FreeRoom();
        BridgeSfx(0xFE);
        LoadRoom(room_mission, a1, 0);
        EnterRoom(a2);
        longjmp(room_jmp, 1);
    case 7:
        ItemTake(a1);
        if (room_action == 2 && room_target == a1) {
            room_action = 1;
            ActionCursor(1, 0);
            HideInvIcon();
        }
        break;
    case 8:
        if (a1 >= 0 && a1 < 32 && a4 == 0xFE) {
            Actor *a;

            a = &actors[a1];
            *(char *)&a->state &= ~0x10;
            WalkActorTo(a1, -1, -1, a2, a3, 0);
            if (!(*(char *)&a->state & 0x10))
                WaitActor(a1);
        } else
            WalkActorTo(a1, -1, -1, a2, a3, a4);
        break;
    case 10: {
        char name[10];

        GETNAME(name, a1);
        if (name[0] == (char)0xFF) {
            Converse(a1 + 1);
            GETNAME(name, a1 + 7);
            if (name[0] == 0)
                break;
        }
        FlashBitmap(name, a2);
        break;
    }
    case 11:
        result = OpenPanel(a1, a2, a3, a4, a5, a6);
        break;
    case 12:
        ClosePanel(a1);
        break;
    case 9:
        FreeAnyFile(map_handle);
        talk_data = LockMem(talk_handle);
        MemCpy(map_name, talk_data + a1, 10);
        UnlockMem(talk_handle);
        map_handle = getanyfileems(map_name, "map");
        LoadWalkGraph(map_name);
        break;
    case 13:
        result = ItemHave(a1);
        break;
    case 14: {
        int x;
        int y;

        if (a1 >= 32 && a1 < 64)
            ObjectCentre(a1, &x, &y);
        else if (a1 >= 0 && a1 < 32) {
            Actor *a;

            a = &actors[a1];
            x = a->sprite.x;
            y = a->sprite.y;
        } else
            x = y = 0;
        result = (long)y << 16 | (unsigned)x;
        break;
    }
    case 15:
        result = rand() % (a2 - a1 + 1) + a1;
        break;
    case 16:
        sfx_vol_next = a2;
        sfx_pan_next = a3;
        BridgeSfx(a1);
        break;
    case 58: {
        char name[10];

        GETNAME(name, a1);
        PlayVoice(name);
        break;
    }
    case 59:
        StopVoice();
        break;
    case 17:
        PlayMusic(a1, a2);
        break;
    case 18:
        mission_max = a1;
        mission_score = a2;
        BeamUp();
        break;
    case 19:
        PlayMusic(0xFE, 0xFE);
        mission_max = a1;
        mission_score = a2;
        sub_1C2FA();
        byte_47A87 = 0;
        longjmp(game_jmp, 1);
        break;
    case 20:
        GameOverMenu();
    case 21: {
        char codes[30];
        char *p;
        char *in;
        int n;

        talk_data = LockMem(talk_handle);
        MemCpy(codes, talk_data + a1, 30);
        UnlockMem(talk_handle);
        p = codes;
        in = InputCode();
        n = 1;
        result = 0;
        while (*p) {
            if (_stricmp(p, in) == 0)
                result = n;
            p += strlen(p) + 1;
            n++;
        }
        break;
    }
    case 22:
        result = Turbolift(a1, a2);
        break;
    case 23: {
        char d;
        int x;
        int y;

        if (a1 < 0 || a1 >= 32)
            break;
        if (a2 == 0xFA)
            d = 'n';
        else if (a2 == 0xFB)
            d = 's';
        else if (a2 == 0xFC)
            d = 'e';
        else if (a2 == 0xFD)
            d = 'w';
        else {
            if (a2 >= 0 && a2 < 32) {
                x = actors[a2].sprite.x;
                y = actors[a2].sprite.y;
            } else {
                if (a2 < 32 || a2 >= 64)
                    break;
                ObjectCentre(a2, &x, &y);
            }
            d = DirTo(a1, x, y);
        }
        actors[a1].dir = d;
        break;
    }
    case 41: {
        Actor *a;
        char d;

        if (a1 < 0 || a1 >= 32)
            break;
        a = &actors[a1];
        if ((d = a->dir) == 0 && (d = a->dir2) == 0)
            d = 's';
        if (d == 'n')
            result = 0xFA;
        else if (d == 'e')
            result = 0xFC;
        else if (d == 'w')
            result = 0xFD;
        else
            result = 0xFB;
        break;
    }
    case 24: {
        MemHandle th;
        int ma;
        int mt;
        int mt2;
        int wild;

        th = talk_handle;
        ma = msg_action;
        mt = msg_target;
        mt2 = msg_target2;
        wild = byte_47A8E || a4 ? 1 : 0;
        script_more = !FindScript(wild, 1, a1, a2, a3);
        talk_handle = th;
        msg_action = ma;
        msg_target = mt;
        msg_target2 = mt2;
        result = !script_more;
        break;
    }
    case 25:
        sub_1C266(cur_source, a1, a2);
        break;
    case 26:
        sub_1C20A(cur_source, a1);
        break;
    case 27: {
        char name[10];

        talk_data = LockMem(talk_handle);
        MemCpy(name, talk_data + a1, 10);
        UnlockMem(talk_handle);
        sub_1C2FA();
        LoadMenu(name, a2, a3);
        ReleaseBitmap(mouse_sprite.handle);
        SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
        MenuHome();
        menu_open = 1;
        break;
    }
    case 28:
        sub_1C2FA();
        break;
    case 29:
        if (menu_open)
            MenuShow(*(long *)&a1);
        break;
    case 30:
        if (menu_open)
            MenuDisable(*(long *)&a1);
        break;
    case 31:
        if (menu_open)
            MenuEnable(*(long *)&a1);
        break;
    case 32:
        if (!menu_open) {
            result = 0;
            break;
        }
        result = MenuLoop(*(long *)&a1, 0);
        break;
    case 33:
        Computer();
        break;
    case 34: {
        Actor *a;

        a = &actors[a1];
        a->busy = a2;
        a->flags |= 2;
        break;
    }
    case 35: {
        Actor *a;

        a = &actors[a1];
        ((ActorBits *)a)->b3 = 0;
        a->flags = 0;
    }
    case 0:
        EndOrStand(a1);
        break;
    case 36: {
        Actor *a;

        a = &actors[a1];
        if ((a->flags & 2) && (a->flags & 4))
            a->busy = 1;
        break;
    }
    case 37:
        result = (actors[a1].flags & 2) != 2 ? 0 : 1;
        break;
    case 38:
        result = (actors[a1].flags & 4) != 4 ? 1 : 0;
        break;
    case 39: {
        Actor *a;

        a = &actors[a1];
        a->flags = 0xBD;
        ((ActorBits *)a)->b3 = 1;
        break;
    }
    case 40: {
        Actor *a;

        a = &actors[a1];
        a->flags = 0;
        ((ActorBits *)a)->b3 = 0;
        break;
    }
    case 42: {
        Actor *a;

        a = &actors[a1];
        a->flags = a->flags & ~(a3 ^ a2) ^ a2;
        ((ActorBits *)a)->b3 = (a->flags & 8) != 0;
        break;
    }
    case 43:
        talk_data = LockMem(talk_handle);
        SetPaletteRange(talk_data + a1, a2, a3);
        UnlockMem(talk_handle);
        break;
    case 44: {
        unsigned char rgb[3];

        rgb[0] = a2;
        rgb[1] = a3;
        rgb[2] = a4;
        SetPaletteRange(rgb, a1, 1);
        break;
    }
    case 46:
        RoomWait(a1);
        break;
    case 47:
        result = sub_20AD4(a1, a2);
        break;
    case 48:
        PlayDemScene(ItemName(a1));
        break;
    case 49:
        n = ItemName(a1);
        strcpy(bg_name, n);
        LockScreen();
        LoadFilePacked(n, "bgd", screen_base);
        UnlockScreen();
        break;
    case 50:
        n = ItemName(a1);
        strcpy(pri_name, n);
        LoadFilePacked(n, "pri", mask_buf);
        break;
    case 51:
        SetFade(cur_palette, 0);
        MemSet((char far *)0xA0000000L, 0xFA00, 0);
        RestoreBackground(&screen_rect);
        MarkAllDirty();
        UpdateSprites();
        BlitToScreen(&screen_rect);
        SetFade(cur_palette, fade_level);
        break;
    case 52: {
        char *n;
        MemHandle h;

        n = ItemName(a1);
        if (a2) {
            MemCpy(cur_palette, LockMem(h = CacheLoadEMS(n, "pal")), 0x300);
            UnlockMem(h);
            CacheRelease(h);
        } else
            LoadPalette(n);
        sub_1BCC2();
        SetFade(cur_palette, 100);
        break;
    }
    case 54: {
        unsigned long end;

        FadeOut();
        end = GetTicks() + a1;
        while (GetTicks() < end)
            MusicTick();
        break;
    }
    case 53:
        FadeIn();
        break;
    case 55:
        fade_rgb[0] = a1;
        fade_rgb[1] = a2;
        fade_rgb[2] = a3;
        break;
    case 56:
        LoadNamed(ItemName(a1), a2);
    default:
        Fatal("Unknown room command: %u", cmd);
        break;
    }
    talk_data = LockMem(talk_handle);
    _asm {
        mov ax, [bp+4]
        or ax, ax
        jne fixed
        mov ax, word ptr talk_data+2
        mov [bp+4], ax
    fixed:
    }
    return result;
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
        sprintf(buf + strlen(buf), " Choice %d", n);
        buf[24] = 0;
    }
    CentreLine(dst, buf);
}

/* Choice n of a conversation (for TextBox): its text (inline, or
 * 0xFnnn: string nnn of the text file), and its title in title. */
char *TalkChoice(unsigned n, int *list, char *title)
{
    unsigned far *entry;
    char far *str;
    char *buf;
    int len;

    talk_data = LockMem(talk_handle);
    entry = (unsigned far *)(talk_data + *list);
    if (entry[n + 1] == 0 || entry[n + 1] == 0xFFFF) {
        UnlockMem(talk_handle);
        return 0;
    }
    str = talk_data + entry[n + 1];
    if ((*(unsigned far *)str & 0xF000) == 0xF000) {
        int k;

        k = *(unsigned far *)str & 0x0FFF;
        UnlockMem(talk_handle);
        str = LockMem(text_handle);
        while (k)
            if (*str++ == 0)
                k--;
        len = _fstrlen(str) + 1;
        buf = AllocMemPtr(len);
        MemCpy(buf, str, len);
        UnlockMem(text_handle);
        talk_data = LockMem(talk_handle);
        entry = (unsigned far *)(talk_data + *list);
    } else {
        len = _fstrlen(str) + 1;
        buf = AllocMemPtr(len);
        MemCpy(buf, str, len);
    }
    if (entry[0] < 32)
        str = actors[entry[0]].title;
    else
        str = talk_data + entry[0] + 6;
    if (*str) {
        if (entry[2] != 0 && entry[2] != 0xFFFF)
            ChoiceTitle(title, str, n + 1);
        else
            ChoiceTitle(title, str, 0);
    } else
        *title = 0;
    UnlockMem(talk_handle);
    return buf;
}

/* Set crew member n's icon letter (for "i?use"). */
void SetCrewIcon(int n, char c)
{
    register Actor *a;

    if (n >= 0 && n < 32) {
        a = &actors[n];
        a->letter = c;
    }
}

/* Make actor n a speaker, from the record at off in the talk data. */
void SetSpeaker(int n, unsigned off)
{
    Speaker far *sp;
    Actor *a;

    if (n >= 0 && n < 32) {
        a = &actors[n];
        talk_data = LockMem(talk_handle);
        sp = (Speaker far *)(talk_data + off);
        a->x = sp->x;
        a->y = sp->y;
        a->color = sp->color;
        a->z = sp->z;
        _fstrncpy(a->title, sp->title, 24);
        a->title[23] = 0;
        UnlockMem(talk_handle);
    }
}

/* A conversation (entry text of the talk data): its speaker (an actor,
 * or a speaker record) sets the box. A timed box if the entry says so. */
long Converse(int text)
{
    unsigned far *entry;
    int ticks;
    int color;
    int x;
    int y;
    int z;
    int list;
    Actor *a;

    talk_data = LockMem(talk_handle);
    entry = (unsigned far *)(talk_data + text);
    if (entry[1] != 0 && entry[2] == 0xFFFF)
        ticks = entry[3];
    else
        ticks = 0;
    if (entry[0] < 32) {
        a = &actors[entry[0]];
        color = a->color;
        x = a->x;
        y = a->y;
        z = a->z;
    } else {
        Speaker far *sp;

        sp = (Speaker far *)(talk_data + entry[0]);
        x = sp->x;
        y = sp->y;
        color = sp->color;
        z = sp->z;
    }
    if (color == 0)
        color = 0;
    if (x == 0)
        x = 20;
    if (y == 0)
        y = 20;
    UnlockMem(talk_handle);
    list = text;
    if (ticks) {
        TimedBox(TalkChoice, &list, x, y, color, z, ticks);
        return 0;
    }
    return TextBox(TalkChoice, &list, x, y, color, 1, z, 0);
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

int msg_wait = 0;

/* A message box: title (a speaker) and text. */
long MsgBox(char *title, char *text, int x, int y, int color, int msg)
{
    TextArg arg;

    if (!full_view && !msg_wait)
        StartTalk(-2, "", -1, -1, 0x100, 0);
    if (title && *title)
        CentreLine(arg.title, title);
    else
        arg.title[0] = 0;
    arg.text = text;
    return TextBox(MsgChoice, &arg, x, y, color, 0, msg, 0);
}

/* The crew members' talking animations. */
char *crew_tlk[9] = {
    "tlk066", "tlk067", "NOANIM", "NOANIM", "tlk068", "tlk065", "tlk069", "tlk064", "NOANIM"
};

/* Crew member who (an actor; -1 for none) says text. (97%: the target
 * keeps color in di as well as its frame slot, and x, y in memory.) */
void CrewSay(int who, char *text)
{
    TextArg arg;
    Actor *a;
    int color;
    int x;
    int y;
    int z;

    if (who == -1) {
        color = 9;
        y = x = 20;
        z = 0;
        arg.title[0] = 0;
        if (!full_view)
            StartTalk(-2, "", -1, -1, 0x100, 0);
    } else {
        a = &actors[who];
        color = a->color;
        if ((x = a->x) == 0)
            x = 20;
        if ((y = a->y) == 0)
            y = 20;
        z = a->z;
        if (a->title[0])
            CentreLine(arg.title, a->title);
        else
            arg.title[0] = 0;
        if (who >= 0 && who < 9 && !full_view)
            StartTalk(who, crew_tlk[who], -1, -1, 0x100, 1);
    }
    arg.text = text;
    TextBox(MsgChoice, &arg, x, y, color, 0, z, 0);
}

int word_3CE3A = 0;                     /* a voice tag is playing */

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

/* Play a #voice# tag; returns the text after it. (The name was meant to
 * follow the CD path, but it's copied over it from the start, so the
 * voice is found in the current directory or a .vcc archive.) */
char *PlayVoiceTag(char *p)
{
    char *q;
    char name[256];
    int i;
    int len;

    word_3CE3A = 0;
    q = p;
    if (*q == '#') {
        sprintf(name, "%s%s", cd_path, uncomp_dir);
        len = strlen(name);
        i = 0;
        for (++q; *q != '#'; ++q, ++i) {
            if (*q == 0 || i > 250)
                return p;
            name[i] = *q;
        }
        ++q;
        name[i] = 0;
        word_3CE3A = PlayDigiSfx(name, 0x7F, 0x40, 1);
    }
    return q;
}

unsigned long last_talk = 0;            /* blink_count when the last box closed */

/* A conversation box: fn gives the choices. Returns the one picked, -1
 * if cancelled (flag). */
long TextBox(char *(far *fn)(int, void *, char *), void *arg, int x, int y,
               int color, int choice, int maxl, int flag)
{
    char *lines;
    char buf[24];
    int ntitled;
    int n;
    int maxlines;
    int sel;
    int nlines;
    char *text;
    int top;
    Sprite box;
    Bitmap *boxbuf;
    int done;
    int mx;
    int my;
    MemHandle bmp;
    int kbd;
    unsigned long timeout;
    unsigned long t;

    timeout = blink_count > last_talk + 1 ? 16 : 8;
    if (maxl <= 0 || maxl > 12)
        maxl = 12;
    for (maxlines = n = ntitled = 0; (text = (*fn)(n, arg, buf)) != 0; n++) {
        nlines = WrapCount(SkipVoice(text));
        if (nlines > maxlines)
            maxlines = nlines;
        if (buf[0])
            ntitled++;
        FreeMemPtr(text);
    }
    if (maxlines > maxl)
        maxlines = maxl;
    if (ntitled && ntitled != n)
        Fatal("not all choices have titles");
    boxbuf = MakeTextBox(&x, &y, color, maxlines, ntitled, &box);
    top = sel = 0;
    if (VoiceMode() != 0 && VoiceMode() != 1 && n == 1)
        show_text = 0;
    else
        show_text = 1;
    lines = LayoutChoice(fn, arg, sel, boxbuf, maxlines, &nlines);
    if (lines == 0) {
        FreeMemHandle(box.handle);
        DelSprite(&box);
        for (done = 0; !done; ) {
            int r;

            r = MenuWait(timeout, 1);
            if (timeout)
                MenuEnable(1L);
            switch (r) {
            case -4:
            case -2:
                if (timeout)
                    break;
                done = 1;
                if (flag)
                    sel = -1;
                break;
            case 9:
                if (n == 1)
                    done = 1;
                break;
            case 0:
                done = 1;
                break;
            }
            timeout = 0;
        }
        FreeMemPtr(boxbuf);
    } else {
        LoadMenu("mnudlg", x + 150, y - 17);
        mx = mouse_x;
        my = mouse_y;
        bmp = mouse_sprite.handle;
        mouse_x = x + 0xDE;
        mouse_y = y - 8;
        if (nlines > maxlines)
            mouse_y += 0x22;
        else if (n > 1)
            mouse_x -= 0x1D;
        SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
        SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
        SetPointer(mouse_x, mouse_y);
        kbd = kbd_mouse;
        kbd_mouse = 0;
        MenuShow((nlines > maxlines ? 6L : 0L) | (n > 1 ? 0x18u : 0u) | 1);
        MenuDisable(2L);
        if (timeout)
            MenuDisable(1L);
        if (choice == 0)
            MenuDisable(8L);
        for (done = 0; !done; ) {
            int r;

            if (VoiceMode() && voice_only)
                t = -1;
            else
                t = timeout;
            r = MenuLoop(t, 1);
            if (timeout)
                MenuEnable(1L);
            switch (r) {
            case -4:
            case -2:
                if (timeout)
                    break;
                done = 1;
                if (flag)
                    sel = -1;
                break;
            case 1:
                top -= maxlines;
                goto up;
            case 2:
                top += maxlines;
                goto down;
            case 3:
                --sel;
                if (choice == 0 && sel == 0)
                    MenuDisable(8L);
                else if (sel < 0)
                    sel = n - 1;
                MenuEnable(16L);
                goto redraw;
            case 4:
                MenuEnable(8L);
                ++sel;
                if (choice == 0 && sel == n - 1)
                    MenuDisable(16L);
                else
                    sel %= n;
            redraw:
                FreeMemPtr(lines);
                top = 0;
                lines = LayoutChoice(fn, arg, sel, boxbuf, maxlines, &nlines);
                if (nlines <= maxlines)
                    MenuShow(0x19L);
                else
                    MenuShow(0x1FL);
                MenuEnable(4L);
                MenuDisable(2L);
                box.dirty = 1;
                break;
            case 5:
                top--;
                goto up;
            case 6:
                top++;
                goto down;
            case 7:
                top = 0;
            up:
                MenuEnable(4L);
                top = max(0, top);
                if (top == 0)
                    MenuDisable(2L);
                goto draw;
            case 8:
                top = nlines - maxlines;
            down:
                MenuEnable(2L);
                if (top >= nlines)
                    top -= maxlines;
                top = min(nlines - 1, top);
                if (top + maxlines >= nlines)
                    MenuDisable(4L);
            draw:
                box.dirty = 1;
                BoxLines(boxbuf, nlines - top, maxlines, lines + top * 24, ntitled);
                break;
            case 9:
                if (n == 1)
                    done = 1;
                break;
            case 0:
                done = 1;
                break;
            }
            timeout = 0;
        }
        mouse_x = mx;
        mouse_y = my;
        SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
        ReleaseBitmap(mouse_sprite.handle);
        SpriteSetBitmap(&mouse_sprite, bmp);
        SetPointer(mouse_x, mouse_y);
        kbd_mouse = kbd;
        MenuClose();
        {
            MemHandle h;

            h = box.handle;
            SpriteErase(&box);
            UpdateSprites();
            DelSprite(&box);
            FreeMemHandle(h);
        }
        FreeMemPtr(boxbuf);
        FreeMemPtr(lines);
    }
    last_talk = blink_count;
    StopSfxLoop();
    return sel;
}

/* A box with fn's first choice, shown for ticks (faded in on its own if
 * ticks < 0; the room keeps running otherwise). */
void TimedBox(char *(far *fn)(int, void *, char *), void *arg, int x, int y,
              int color, int maxl, int ticks)
{
    Sprite box;
    char buf[24];
    Event ev;
    Bitmap *boxbuf;
    char *out;
    int nlines;
    int lines;

    {
        char *text;
        int titled;

        titled = 0;
        text = (*fn)(0, arg, buf);
        lines = WrapCount(SkipVoice(text));
        if (buf[0])
            titled = 1;
        FreeMemPtr(text);
        if (maxl <= 0 || maxl > 12)
            maxl = 12;
        if (lines > maxl)
            lines = maxl;
        boxbuf = MakeTextBox(&x, &y, color, lines, titled, &box);
    }
    out = LayoutChoice(fn, arg, 0, boxbuf, lines, &nlines);
    if (ticks < 0) {
        unsigned long start;

        FadeOut();
        ShowSprite(&box);
        FadeIn();
        start = blink_count;
        ticks = -ticks;
        while (blink_count - start < ticks)
            if (GetEvent(&ev))
                switch (ev.type) {
                case EV_TICK:
                    MusicTick();
                    blink_count++;
                    break;
                }
        FadeOut();
    } else {
        unsigned long start;

        start = blink_count;
        while (blink_count - start < ticks)
            if (GetEvent(&ev))
                switch (ev.type) {
                case EV_TICK:
                    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
                    UpdateActors();
                    DrawBans();
                    UpdateSprites();
                    UpdateBans();
                    MusicTick();
                    FadeUp();
                    blink_count++;
                    break;
                }
    }
    {
        MemHandle h;

        h = box.handle;
        SpriteErase(&box);
        UpdateSprites();
        DelSprite(&box);
        FreeMemHandle(h);
    }
    FreeMemPtr(boxbuf);
    FreeMemPtr(out);
    StopSfxLoop();
}

/* Edit buf (up to 23 characters) in a box at (x, y) under prompt.
 * Returns 1 when entered (Enter, F1 or click), 0 when cancelled (Esc, F2
 * or right click). (70%: the target keeps cursor in its frame slot, using
 * di only inside the key switch, and lays the switch out differently.) */
int InputBox(char *prompt, char *buf, int x, int y, int color)
{
    Sprite box;
    Event ev;
    int accel;
    Bitmap *boxbuf;
    int ok;
    int len;
    char *line;
    int cursor;
    unsigned key;
    int i;
    char c;

    accel = key_accel;
    key_accel = ok = 0;
    boxbuf = MakeTextBox(&x, &y, color, 1, 1, &box);
    line = (char *)boxbuf + 0x57;
    CentreLine((char *)boxbuf + 0x23, prompt);
    MemSet(line, 24, ' ');
    len = 0;
    if (buf && *buf) {
        len = strlen(buf);
        MemCpy(line, buf, len);
    }
    cursor = len;
    UpdateSprites();
    for (;;) {
        if (GetEvent(&ev))
            switch (ev.type) {
            case EV_TICK:
                SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
                UpdateActors();
                DrawBans();
                UpdateSprites();
                UpdateBans();
                MusicTick();
                FadeUp();
                blink_count++;
                box.dirty = 1;
                break;
            case EV_DOWN1:
                ok = 1;
                goto done;
            case EV_DOWN2:
                goto done;
            case EV_KEY:
                key = ev.key & 0xFF;
                if (key == 0)
                    key = ev.key;
                switch (key) {
                case 0x1B:
                case 0x3C00:
                    goto done;
                case 0x0D:
                case 0x3B00:
                    ok = 1;
                    goto done;
                case 0x08:
                case 0x0E00:
                    if (cursor > 0) {
                        cursor--;
                        if (cursor != 23)
                            MemCpy(line + cursor, line + cursor + 1, 23 - cursor);
                        line[23] = ' ';
                        box.dirty = 1;
                        len--;
                    }
                    break;
                case 0x4700:
                    cursor = 0;
                    box.dirty = 1;
                    break;
                case 0x4B00:
                    if (cursor > 0)
                        cursor--;
                    box.dirty = 1;
                    break;
                case 0x4D00:
                    if (cursor < 23)
                        cursor++;
                    box.dirty = 1;
                    break;
                case 0x4F00:
                    cursor = len;
                    box.dirty = 1;
                    break;
                case 0x5200:
                    for (i = 22; i >= cursor; i--)
                        line[i + 1] = line[i];
                    line[cursor] = ' ';
                    goto grow;
                case 0x5300:
                    if (len > cursor) {
                        if (cursor != 23)
                            MemCpy(line + cursor, line + cursor + 1, 23 - cursor);
                        line[23] = ' ';
                        box.dirty = 1;
                        len--;
                    }
                    break;
                default:
                    if (isprint(key)) {
                        for (i = 22; i >= cursor; i--)
                            line[i + 1] = line[i];
                        line[cursor] = key;
                        if (cursor < 23)
                            cursor++;
                    grow:
                        box.dirty = 1;
                        if (len < 23)
                            len++;
                    }
                    break;
                }
                break;
            }
        if (box.dirty) {
            if (blink_count & 2) {
                c = line[cursor];
                line[cursor] = '_';
                UpdateSprites();
                line[cursor] = c;
            } else
                UpdateSprites();
        }
    }
done:
    MemCpy(buf, line, 24);
    buf[len] = 0;
    {
        MemHandle h;

        h = box.handle;
        SpriteErase(&box);
        UpdateSprites();
        DelSprite(&box);
        FreeMemHandle(h);
    }
    FreeMemPtr(boxbuf);
    key_accel = accel;
    return ok;
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

/* Make the text box sprite: a frame of font characters, placed near
 * (*px, *py) and on screen. The sequel's font is 11 lines high. */
Bitmap *MakeTextBox(int *px, int *py, int color, int lines, unsigned titled, Sprite *spr)
{
    int unused;
    Bitmap *bmp;
    char *p;
    int i;
    int extra;
    int t;
    int x;
    int y;

    extra = titled ? 4 : 2;
    x = *px;
    y = *py;
    bmp = AllocMemPtr((lines + extra) * 26 + 8);
    MemSet(spr, sizeof(Sprite), 0);
    spr->z = 15;
    spr->layer = 8;
    spr->handle = AllocMemHandle(bmp);
    spr->colour = color;
    p = bmp->data;
    bmp->x = 0;
    bmp->y = 0;
    bmp->w = 0xD0;
    bmp->h = (lines + extra) * 11;
    MemSet(p, (lines + extra) * 26, ' ');
    if ((t = 319 - x - (bmp->w + 29) / 2) < 0)
        x += t;
    if ((t = x - (bmp->w + 29) / 2) < 1)
        x -= t - 1;
    if ((t = y - (bmp->h + 1) - 20) < 0)
        y -= t;
    x -= (bmp->w + 29) / 2;
    y -= bmp->h;
    *p = 0x10;
    MemSet(p + 1, 24, 0x11);
    p[25] = 0x12;
    p += 26;
    if (titled) {
        *p = 0x13;
        p[25] = 0x14;
        p += 26;
        *p = 0x13;
        MemSet(p + 1, 24, 0x19);
        p[25] = 0x14;
        p += 26;
    }
    for (i = lines; i != 0; --i) {
        *p = 0x13;
        p[25] = 0x14;
        p += 26;
    }
    *p = 0x15;
    MemSet(p + 1, 24, 0x16);
    p[25] = 0x17;
    p += 26;
    AddSprite(spr);
    spr->type = SPRITE_TEXT;
    SpriteSetPos(spr, x, y, 15);
    *px = x;
    *py = y;
    return bmp;
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

/* Lay out choice sel in the box, speaking its voice tag. Returns the
 * lines (0 when only spoken). */
char *LayoutChoice(char *(far *fn)(int, void *, char *), void *arg, unsigned sel,
                Bitmap *box, int max, int *nlines)
{
    char *text;
    char *q;
    char *out;
    char title[24];

    text = (*fn)(sel, arg, title);
    if (VoiceMode() != 2 && VoiceMode() != 1 && VoiceMode() != 0) {
        q = SkipVoice(text);
        show_text = 1;
        voice_only = 0;
    } else {
        q = PlayVoiceTag(text);
        if (q == text || word_3CE3A == 0) {
            show_text = 1;
            voice_only = 0;
        } else
            voice_only = 1;
    }
    if (show_text) {
        *nlines = WrapCount(q);
        out = AllocMemPtr(*nlines * 24);
        WrapText(out, q);
        BoxLines(box, *nlines, max, out, title[0]);
        BoxTitle(box, title);
        FreeMemPtr(text);
        return out;
    } else {
        FreeMemPtr(text);
        return 0;
    }
}

/* The pointer for action (highlighted when on something). */
void ActionCursor(int action, int on)
{
    char *name;

    if (byte_47A87)
        name = "wait";
    else
        switch (action) {
        case 2:
            name = on ? "useh" : "usen";
            break;
        case 3:
            name = on ? "geth" : "getn";
            break;
        case 4: {
            static char *look_cursors[8] = {
                "lookh0", "lookh0", "lookh0", "lookh0", "lookh0", "lookh1", "lookh2", "lookh3"
            };
            static int look_idx = 0;

            if (on) {
                if ((rand() & 7) == 0)
                    look_idx = rand() & 7;
                name = look_cursors[look_idx];
            } else
                name = "lookn";
            break;
        }
        case 5:
            if (on) {
                if (rand() & 3)
                    name = "talkh0";
                else
                    name = "talkh1";
            } else
                name = "talkn";
            break;
        case 15:
            name = "options";
            break;
        default:
            name = "walk";
            break;
        }
    ReleaseBitmap(mouse_sprite.handle);
    SpriteSetBitmap(&mouse_sprite, LoadBitmap(name));
}

/* What's at (x, y): a crew member or other actor, the inventory icon
 * (-10), the selected item, an object polygon, or 0xFE. */
int FindObject(int x, int y)
{
    Sprite *s;
    Rdf far *r;
    int far *e;
    int far *end;
    int far *q;
    int mask;
    int i;
    Actor *a;

    s = SpriteAt(x, y, 1);
    if (s != 0) {
        if (s == &inv_sprite)
            return -10;
        if (s == &item_sprite)
            return room_target;
        for (i = 0, a = actors; i != 32; ++i, ++a)
            if (s == &a->sprite)
                return i;
    }
    r = LockMem(rdf_handle);
    e = (int far *)((char far *)r + r->objects);
    end = (int far *)((char far *)r + r->objects_end);
    hit_valid = 0;
    mask = 1 << (room_action - 1);
    while (e != end) {
        q = e;
        if (*q & 0x8000) {
            if ((*q & mask) && InPoly(q + 3, x, y)) {
                i = q[3];
                if (q[1] != -1 && q[2] != -1) {
                    hit_valid = 1;
                    hit_x = q[1];
                    hit_y = q[2];
                }
                UnlockMem(rdf_handle);
                return i;
            }
            e = NextPoly(q + 3);
        } else if (InPoly(e, x, y) == 1) {
            i = *e;
            UnlockMem(rdf_handle);
            return i;
        } else
            e = NextPoly(e);
    }
    UnlockMem(rdf_handle);
    return 0xFE;
}

/* Is (x, y) inside the polygon poly (id, n, points)? (A crossing test.) */
int InPoly(int far *poly, int x, int y)
{
    int inside;
    int i;
    int n;
    Point far *p;
    Point far *prev;
    Point a;
    Point b;
    Point t;

    inside = 0;
    p = (Point far *)(poly + 2);
    n = poly[1];
    prev = (Point far *)poly + n;
    for (i = 0; i < n; i++) {
        a = *prev;
        b = *p;
        prev = p++;
        if (b.y < a.y) {
            t = a;
            a = b;
            b = t;
        }
        if (a.y > y || b.y <= y)
            continue;
        if (a.x <= x) {
            if (b.x <= x) {
                inside = !inside;
                continue;
            }
        } else if (b.x > x)
            continue;
        b.x -= a.x;
        b.y -= a.y;
        a.x = x - a.x;
        a.y = y - a.y;
        if (a.y * b.x <= a.x * b.y)
            inside = !inside;
    }
    return inside;
}

/* The polygon after poly. */
int far *NextPoly(int far *poly)
{
    char far *p;

    p = (char far *)poly;
    p += poly[1] * 4 + 4;
    return (int far *)p;
}

/* Report a click in a region. */
void ClickRegion(int x, int y)
{
    Rdf far *r;
    int far *e;
    int far *end;

    r = LockMem(rdf_handle);
    e = (int far *)((char far *)r + r->regions);
    end = (int far *)((char far *)r + r->regions_end);
    while (e != end) {
        if (InPoly(e, x, y) == 1) {
            PostRoomMsg(13, *e, 0, 0);
            break;
        }
        e = NextPoly(e);
    }
    UnlockMem(rdf_handle);
}

/* Report the region, else the exit, the pointer moves into from (ox, oy). */
void CheckRegions(int x, int y, int ox, int oy)
{
    Rdf far *r;
    int far *end;
    int far *e;

    r = LockMem(rdf_handle);
    e = (int far *)((char far *)r + r->regions);
    end = (int far *)((char far *)r + r->regions_end);
    while (e != end) {
        if (InPoly(e, x, y) == 1) {
            if (*e != cur_region) {
                if (cur_region != -1)
                    PostRoomMsg(14, cur_region, 0, 0);
                cur_region = *e;
                PostRoomMsg(7, *e, 0, 0);
                if (InPoly(e, ox, oy))
                    PostRoomMsg(8, *e, 0, 0);
            }
            goto done;
        }
        e = NextPoly(e);
    }
    if (cur_region != -1) {
        PostRoomMsg(14, cur_region, 0, 0);
        cur_region = -1;
    }
    if (AnyActorBusy() == 0) {
        e = (int far *)((char far *)r + r->exits);
        end = (int far *)((char far *)r + r->exits_end);
        while (e != end) {
            if (InPoly(e, x, y) == 1) {
                    if (*e != cur_exit && InPoly(e, ox, oy)) {
                    cur_exit = *e;
                    PostRoomMsg(6, *e, 0, 0);
                }
                goto done;
            }
            e = NextPoly(e);
        }
    }
    cur_exit = -1;
done:
    UnlockMem(rdf_handle);
}

/* Run the room timers (counting up or down); message 9 at zero. */
void RoomTimers(void)
{
    int i;

    for (i = 0; i != 8; i++)
        if ((room_timers[i] > 0 && --room_timers[i] == 0)
                || (room_timers[i] < 0 && ++room_timers[i] == 0))
            PostRoomMsg(9, i, 0, 0);
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

/* Pick what to use the selected item on. */
int PickUseTarget(void)
{
    Event ev;
    int obj;

    for (;;) {
        if ((actors[0].flags & 2) != 2)
            ShowInvIcon(0);
        ev = WaitAction();
        if (ev.type == EV_KEY && (((unsigned)ev.key >> 8) & 0xFF) == 0x17) {
            HideInvIcon();
            obj = PickItem(50, 50, 1);
            if (obj == -1)
                continue;
            return obj;
        } else if (ev.type != EV_DOWN1) {
            HideInvIcon();
            return -1;
        } else {
            obj = FindObject(mouse_x, mouse_y);
            HideInvIcon();
            if (obj == -1)
                continue;
            if (CantAct(obj, 2))
                continue;
        }
        if (obj == -10) {
            obj = PickItem(50, 50, 0);
            if (obj == -1)
                continue;
        } else if (obj < 0 || obj >= 32 || (actors[obj].flags & 0x10) != 0x10) {
            if (CantAct(0, 2))
                continue;
            if (!HasScript(2, 0, obj))
                continue;
            room_target = 0;
            room_target2 = obj;
            room_action = 2;
            obj = 0;
            if (!WalkToHit())
                PostRoomMsg(room_action, room_target, room_target2, 0);
        }
        return obj;
    }
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

int action_masks[5] = { 0, 7, 6, 7, 3 };

/* Highlight the pointer when it's over something the action applies to:
 * mask bit 0 crew, 1 other actors, 2 objects. */
void HiliteCursor(void)
{
    int mask;
    int obj;
    int on;

    mask = action_masks[room_action - 1];
    obj = FindObject(mouse_x, mouse_y);
    on = ((mask & 1) && obj >= 0 && obj < 32 && (actors[obj].flags & 0x10) == 0x10)
        || ((mask & 2) && obj >= 0 && obj < 32 && (actors[obj].flags & 0x10) != 0x10)
        || ((mask & 4) && obj >= 32 && obj <= 64);
    ActionCursor(room_action, on);
}

/* Walk the crew member to the spot clicked, with the action posted
 * when they get there. Returns 0 if the spot isn't a walk-to spot. */
int WalkToHit(void)
{
    int crew;
    unsigned timer;
    int found;
    int i;

    if (!hit_valid)
        return 0;
    hit_valid = 0;
    if (room_action != 2)
        crew = 0;
    else if (room_action == 2 && room_target < 32 && (actors[room_target].flags & 0x10) == 0x10)
        crew = room_target;
    else if (room_action == 2 && room_target >= 0x40 && room_target <= 0x80) {
        if (room_target == 0x42)
            crew = (actors[1].flags & 1) ? 1 : (actors[4].flags & 1) ? 4 : 0;
        else if (room_target == 0x43)
            crew = (actors[2].flags & 1) ? 2 : (actors[5].flags & 1) ? 5 : 0;
        else
            crew = 0;
    } else
        Fatal("Jay didn't think about pmcheck.");
    timer = 0;
    if (room_action != 1) {
        found = 0;
        if (room_action != 2)
            room_target2 = 0;
        if (HasScript(room_action, room_target, room_target2))
            for (i = 0; i != 31; i++)
                if (timers[i].active == 0) {
                    timer = i + 0xE0;
                    timers[i].active = timer;
                    timers[i].msg[0] = room_action;
                    timers[i].msg[1] = room_target;
                    timers[i].msg[2] = room_target2;
                    timers[i].msg[3] = 0;
                    found = 1;
                    break;
                }
        if (found == 0)
            return 0;
    }
    WalkActorTo(crew, -1, -1, hit_x, hit_y, timer);
    return 1;
}

/* Can't act on obj (a stunned crew member, or the officers 0x42/0x43
 * stand for when one is down)? */
int CantAct(int obj, int action)
{
    if (action == 4)
        return 0;
    if (obj >= 0 && obj < 32 && (actors[obj].flags & 0x12) == 0x12)
        return 1;
    if (obj == 0x43 && ((actors[2].flags & 2) == 2 || (actors[5].flags & 2) == 2))
        return 1;
    if (obj == 0x42 && ((actors[1].flags & 2) == 2 || (actors[4].flags & 2) == 2))
        return 1;
    return 0;
}

/* Show the inventory icon (if there's anything in it), and the
 * selected object for use. */
void ShowInvIcon(int on)
{
    char *name;
    int x;
    int have;
    char buf[8];
    int i;

    name = 0;
    for (i = 0x40; i != 0x80; i++)
        if (ItemHave(i))
            break;
    have = i != 0x80 ? 1 : 0;
    if (on) {
        if (room_target < 32 && (actors[room_target].flags & 0x10) == 0x10
                && actors[room_target].letter) {
            strcpy(buf, "i?use");
            buf[1] = actors[room_target].letter;
            name = buf;
        } else if (room_target >= 0x40 && room_target <= 0x80 && have)
            name = items[room_target - 0x40].name;
    }
    if (name) {
        AddSprite(&item_sprite);
        item_sprite.type = SPRITE_SHADOW;
        SpriteSetPos(&item_sprite, 10, 10, 15);
        item_sprite.handle = CacheLoadEMS(name, "bmp");
        item_sprite.layer = 8;
        x = 46;
    } else
        x = 10;
    if (have) {
        AddSprite(&inv_sprite);
        inv_sprite.type = SPRITE_SHADOW;
        SpriteSetPos(&inv_sprite, x, 10, 15);
        inv_sprite.handle = CacheLoadEMS("inv00", "bmp");
        inv_sprite.layer = 8;
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

