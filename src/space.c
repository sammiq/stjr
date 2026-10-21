/* space: the bridge's scripted episodes (new in the sequel). Each episode
 * has a space .rdf of scripts that call SpaceCmd, as a room's call
 * ScriptService. */

#include <stdio.h>
#include <string.h>
#include <setjmp.h>
#include <dos.h>
#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "event.h"
#include "gfx.h"
#include "sound.h"
#include "sprite.h"
#include "resource.h"
#include "actor.h"
#include "fixmath.h"
#include "obj3d.h"
#include "menu.h"

typedef struct ActorBits {
    unsigned char b0 : 3;
    unsigned char b3 : 1;
    unsigned char b4 : 1;
} ActorBits;

typedef struct Item {
    char have;
    char name[9];
} Item;

/* The header of an .rdf. */
typedef struct RdfHdr {
    long (far *service)();      /* 00 callback for the scripts */
    int *state;                 /* 04 the room state */
    int version;                /* 06 */
} RdfHdr;

typedef struct RoomState {
    char b[0x12A];
} RoomState;

typedef struct Episode {
    char *file;
    char *title;
} Episode;

void Fatal(char *fmt, ...);     /* fatal error */
void SaveWrite(void *p, unsigned n);    /* seg019 */
void SaveRead(void *p, unsigned n);
void GameOverMenu(void);
void MenuClose(void);                   /* seg014 */
void ClearMsgs(void);                   /* seg001 */
void BridgeMsg(void);
void SetPower(int shields, int weapons);    /* seg020 */
void BridgeSfx(int n);                  /* seg001 */
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d);  /* seg008 */
void OpenMissionArchive(void);          /* seg003 */
void CloseVCC(char *name);              /* seg015 */
int OpenVCC(char *name);
long SpaceCmd(unsigned cmd, int a1, int a2, int a3, int a4, int a5, int a6);
void RestartCrew(void);
void HideCrew(void);
void Evaluate(char *report, int keep);
void PlayDemScene(char *name);
void ShowCrew(char *name, int a);
int InitShips(char *name);              /* seg020 */
void SetEnemies(char *name, int count);
void ClearShots(void);
void ClearShips(void);
void RestoreShip(Obj3D *o);
void sub_28CB0(void);
void StopShip(Obj3D *o);                /* seg025 */
void SetPlanet(int n);                  /* seg022 */
void StarsReset(void);                  /* seg023 */
void RenderR3(int statics);             /* seg006 */
void CutScene(char *name);              /* seg001 */
void ShuttleEnd(void);
void ViewBridge(void);
void sub_14492(void);
void SetSteering(int on);
void Computer(void);                    /* seg005 */
char *InputCode(void);                  /* seg002 */
void StartEffect(int a, int b, int c);    /* seg000 */
void EndOrStand(int a);
long Converse(int text);                /* seg008 */
void SetCrewIcon(int n, char c);
void SetSpeaker(int n, unsigned off);
int StartTalk(int a, char *s, int b, int c, int d, int e);
void PlayVoice(char *name);             /* seg015 */
void StopVoice(void);
char *ItemName(int off);                /* seg009 */
void SaveNamed(char *name);             /* seg019 */
void LoadNamed(char *name, int arg);
int GetLoadArg(void);
void sub_1B61E(char *name);             /* seg007 */
void LoadPalette(char *name);
void ClearView(void);                   /* seg006 */
void SetCursor(void);                   /* seg001 */
extern Sprite view_sprite;
typedef struct Msg {
    unsigned char type;
    unsigned char arg;
    int unk;
} Msg;
Msg *PeekMsg(void);                     /* seg001 */
int StarMapGo(void);
void CrewSay(int who, char *text);      /* seg008 */
extern int msg_head;
extern int goal_planet;
extern int cur_planet;
long MsgBox(char *title, char *text, int x, int y, int color, int msg);   /* seg008 */
void UpdateActors(void);                /* seg000 */
void PlayDem(char *name);               /* demo */
extern int poll_busy;
extern int game_mode;
extern int msg_wait;
extern int mission_max;
extern int mission_score;
extern int rating;
extern int boost_power;
extern int boost_time;

extern int combat_level;
extern char byte_47A91;
extern char crew_name[10];
extern char mission_name[16];
extern int back_sound;
extern int room_timers[];
extern char room_vars[0x100];
extern Item items[64];
extern MemHandle talk_handle;
extern char far *talk_data;
extern unsigned long bridge_ticks;
extern unsigned long blink_count;
extern char under_attack;
extern Obj3D player_ship;
extern Obj3D ships[4];
extern int in_orbit;
extern int full_view;
extern int word_3CA46;
extern int word_3CA48;
extern unsigned char sfx_vol_next;
extern unsigned char sfx_pan_next;
extern signed char fade_rgb[3];
extern jmp_buf game_jmp;

int in_random = 0;                      /* in a random encounter */
int space_menu = 0;
int crew_anim = -1;                     /* the crew member's animation */
unsigned episode = -1;
Episode episodes[8] = {
    { "fed", "Federation" },
    { "sentnl", "Sentinel" },
    { "noman", "No Man's Land" },
    { "light", "Light and Darkness" },
    { "voids", "Voids" },
    { "scotty", "Museum Piece" },
    { "madness", "Though This Be Madness" },
    { "meth", "Yet There Is Method In It" }
};
int grade_sum = 0;

static int space_ip;                           /* where the script called SpaceCmd */
static unsigned space_sp;                      /* the stack when a script was called */
static int space_w2;
static RoomState saved_room;                   /* the episode's, during a random encounter */
static int saved_ip;
static jmp_buf space_jmp;
static Sprite crew_sprite;                     /* a crew member shown over the bridge */
static int grades[8];                         /* each episode's rating (0 to 4) */
int grades[8];                         /* each episode's rating (0 to 4) */

void SpaceSave(void)
{
    SaveWrite(&space_ip, 2);
    SaveWrite(&space_w2, 2);
    SaveWrite(crew_name, 10);
    SaveWrite(&crew_anim, 2);
    SaveWrite(&episode, 2);
    SaveWrite(grades, 16);
    SaveWrite(&grade_sum, 2);
    SaveWrite(&in_random, 2);
    if (in_random) {
        SaveWrite(&saved_room, sizeof(saved_room));
        SaveWrite(&saved_ip, 2);
    }
    SaveWrite(&combat_level, 2);
}

void SpaceLoad(void)
{
    int dummy;

    SaveRead(&space_ip, 2);
    SaveRead(&space_w2, 2);
    SaveRead(crew_name, 10);
    SaveRead(&crew_anim, 2);
    SaveRead(&episode, 2);
    SaveRead(grades, 16);
    SaveRead(&grade_sum, 2);
    SaveRead(&in_random, 2);
    if (in_random) {
        SaveRead(&saved_room, sizeof(saved_room));
        SaveRead(&saved_ip, 2);
    }
    if (combat_level & 0x8000) {
        SaveRead(&dummy, 2);
        combat_level &= 0x7FFF;
    } else
        SaveRead(&combat_level, 2);
}

void SpaceMenuClose(void)
{
    if (space_menu)
        MenuClose();
    space_menu = 0;
}

void SetUnderAttack(int on)
{
    under_attack = on;
}

/* Run the bridge until crew member n's animation ends. */
void WaitCrew(int n)
{
    Event ev;
    Actor *a;

    ClearMsgs();
    a = &actors[n];
    ((ActorBits *)a)->b4 = 0;
    while (!((ActorBits *)a)->b4) {
        if (GetEvent(&ev) && ev.type == EV_TICK) {
            PostRoomMsg(0, (unsigned char)bridge_ticks, (unsigned char)(bridge_ticks >> 8),
                        (unsigned char)(bridge_ticks >> 16));
            blink_count++;
            bridge_ticks++;
            BridgeMsg();
        }
    }
}

#define CREW(n, l, col, s) \
    actors[n].letter = l; \
    actors[n].color = col; \
    actors[n].z = actors[n].y = actors[n].x = 0; \
    strcpy(actors[n].title, s); \
    ((ActorBits *)&actors[n])->b3 = actors[n].flags = c

/* Start the episode in name.vcc and name's .rdf. */
void StartEpisode(char *name)
{
    char path[20];
    char c;
    int i;
    Item *it;
    Actor *a;

    c = 0;
    strcpy(mission_name, name);
    OpenMissionArchive();
    CloseVCC("all");
    sprintf(path, "%s.vcc", name);
    OpenVCC(path);
    OpenVCC("data.vcc");
    if (back_sound)
        OpenVCC("backsnd.vcc");
    space_ip = 0;
    MemSet(room_timers, sizeof(RoomState), 0);
    byte_47A91 = combat_level;
    for (it = items; it < &items[64]; it++)
        it->have = 0;
    items[5].have = items[4].have = items[3].have = items[2].have = items[1].have =
        items[0].have = 1;
    i = 0;
    for (a = actors; a < &actors[MAX_ACTORS]; a++) {
        a->letter = i;
        a->flags = i;
        ((ActorBits *)a)->b3 = 0;
    }
    CREW(0, 'k', 6, "Captain Kirk");
    actors[0].flags = 0xBD;
    CREW(1, 's', 8, "Mr. Spock");
    CREW(2, 'm', 8, "Dr. McCoy");
    CREW(3, 'r', 3, "Security Officer");
    CREW(4, 'l', 6, "Mr. Sulu");
    CREW(5, 'c', 6, "Mr. Chekov");
    CREW(6, 'u', 3, "Lt. Uhura");
    CREW(7, 'y', 3, "Mr. Scott");
    CREW(8, 'b', 8, "Ensign Jons");
    SetPower(0, 0);
}

void NextEpisode(void)
{
    if (++episode >= 8)
        GameOverMenu();
    else
        StartEpisode(episodes[episode].file);
}

/* Load the space .rdf: the episode's, or random.rdf. */
void LoadSpaceRdf(void)
{
    char name[10];
    RdfHdr far *h;

    if (in_random)
        talk_handle = CacheLoadEMS("random", "rdf");
    else {
        sprintf(name, "%.7ss", mission_name);
        talk_handle = CacheLoadEMS(name, "rdf");
    }
    h = LockMem(talk_handle);
    if (h->version != 0x311)
        Fatal("Incorrect space header version");
    h->service = SpaceCmd;
    h->state = room_timers;
    UnlockMem(talk_handle);
    LoadMusic(mission_name, 0x73);
    if (space_ip)
        PlayMusic(13, 13);
}

void FreeSpaceRdf(void)
{
    SpaceMenuClose();
    HideCrew();
    CacheRelease(talk_handle);
}

void EnterRandom(void)
{
    if (!in_random) {
        FreeSpaceRdf();
        saved_ip = space_ip;
        saved_room = *(RoomState *)room_timers;
        in_random = 1;
        space_ip = 0;
        MemSet(room_vars, sizeof(room_vars), 0);
        byte_47A91 = combat_level;
        LoadSpaceRdf();
    }
}

void LeaveRandom(void)
{
    if (in_random) {
        FreeSpaceRdf();
        space_ip = saved_ip;
        *(RoomState *)room_timers = saved_room;
        space_w2 = in_random = 0;
        LoadSpaceRdf();
    }
}

/* Run the script at off in the talk data. */
void SpaceScript(int off)
{
    char far *code;

    code = talk_data + off;
    if (setjmp(space_jmp)) {
        talk_data = LockMem(talk_handle);
        return;
    }
    _asm {
        mov ax, ds
        mov es, ax
        mov bx, offset room_timers
        mov si, bx
        mov space_sp, sp
        jmp dword ptr code
    }
}

/* Copy n characters at off in the talk data. */
#define GETTEXT(name, off, n) \
    (talk_data = LockMem(talk_handle), MemCpy(name, talk_data + (off), n), \
     name[(n) - 1] = 0, UnlockMem(talk_handle))
#define GETNAME(name, off) GETTEXT(name, off, 10)

/* The space scripts' service call (see ScriptService). */
long SpaceCmd(unsigned cmd, int a1, int a2, int a3, int a4, int a5, int a6)
{
    long result;
    unsigned rseg;

    result = 0;
    _asm {
        mov ax, [bp+2]
        mov dx, [bp+4]
        mov space_ip, ax
        mov rseg, dx
    }
    if (FP_SEG(talk_data) != rseg)
        Fatal("SpaceCmd called from wrong segment");
    UnlockMem(talk_handle);
    switch (cmd) {
    case 0:
        CutScene(mission_name);
        if (space_sp != (unsigned)&a1)
            Fatal("EpisodeTitleSequence command with data on stack");
        space_ip += 3;
        space_w2 = 1;
        SpaceMenuClose();
        longjmp(game_jmp, 1);
    case 1: {
        char buf[20];

        talk_data = LockMem(talk_handle);
        MemCpy(buf, talk_data + a1, 20);
        buf[19] = buf[18] = 0;
        UnlockMem(talk_handle);
        if (combat_level < 2)
            result = InitShips(buf + strlen(buf) + 1);
        else
            result = InitShips(buf);
        break;
    }
    case 2: {
        char name[10];

        GETNAME(name, a1);
        SetEnemies(name, a2);
        break;
    }
    case 3:
        if (a1 != -1)
            ships[a1].flee = 1;
        break;
    case 4:
        if (a1 == -1)
            result = 0;
        else if (a1 == -2)
            result = player_ship.systems[0].max >> 1 > player_ship.systems[0].cur;
        else {
            int t;

            if (ships[a1].visible && !ships[a1].flee
                    && ships[a1].systems[0].max >> 1 > ships[a1].systems[0].cur)
                t = 1;
            else
                t = 0;
            result = t;
        }
        break;
    case 5: {
        Obj3D *o;
        int i;
        int cur;
        int max;

        if (a1 == -1)
            break;
        if (a1 == -2)
            o = &player_ship;
        else {
            o = &ships[a1];
            if (!ships[a1].visible || ships[a1].flee)
                break;
        }
        max = cur = 0;
        for (i = 0; i < 6; i++) {
            cur += o->shields[i].cur;
            max += o->shields[i].max;
        }
        result = max * 2 > cur * 3;
        break;
    }
    case 6:
        ShuttleEnd();
        break;
    case 7:
        LoadMusic("title", 0);
        PlayDemScene("endgame");
        break;
    case 8: {
        char name[10];

        ViewBridge();
        GETNAME(name, a1);
        if (name[0] == (char)0xFF) {
            GETNAME(name, a1 + 7);
            if (name[0] == 0 && a2 != -1)
                PlayMusic(a2, -1);
            Converse(a1 + 1);
            if (name[0] == 0)
                break;
        }
        ShowCrew(name, a2);
        break;
    }
    case 57: {
        char name[10];

        GETNAME(name, a1);
        PlayVoice(name);
        break;
    }
    case 58:
        StopVoice();
        break;
    case 9:
        RestartCrew();
        break;
    case 10:
        HideCrew();
        break;
    case 11:
        ClearShots();
        SetPower(0, 0);
        sub_28CB0();
        break;
    case 12:
        goal_planet = a1;
        break;
    case 13:
        if (in_orbit)
            break;
        StopShip(&player_ship);
        in_orbit = 1;
        break;
    case 14:
        if (!in_orbit)
            break;
        StopShip(&player_ship);
        player_ship.mo.target_speed = player_ship.mo.max_speed >> 2;
        in_orbit = 0;
        break;
    case 15:
        sub_14492();
        SetPlanet(a1);
        StarsReset();
        RenderR3(0);
        UpdateSprites();
        break;
    case 16:
        player_ship.mo.target_speed = player_ship.mo.max_speed;
        break;
    case 17: {
        char name[sizeof(Obj3D)];

        GETNAME(name, a2);
        if (name[0] == (char)0xFF) {
            Converse(a2 + 1);
            GETNAME(name, a2 + 7);
            if (name[0] == 0)
                break;
        }
        a1 = StartAnim(a1, name, a3, a4, 0x100);
        if (a5)
            WaitCrew(a1);
        break;
    }
    case 56: {
        char name[sizeof(Obj3D)];

        GETNAME(name, a2);
        if (full_view)
            break;
        StartTalk(a1, name, -1, -1, -1, 0);
        break;
    }
    case 41:
        StartEffect(a1, a2, 0);
        if (a3)
            WaitCrew(a1);
        break;
    case 18:
        EndOrStand(a1);
        break;
    case 19: {
        char text[sizeof(Obj3D)];

        ViewBridge();
        talk_data = LockMem(talk_handle);
        _fstrncpy(text, talk_data + a1, 128);
        text[127] = 0;
        UnlockMem(talk_handle);
        Evaluate(text, a2);
        break;
    }
    case 20:
        SetCrewIcon(a1, (char)a2);
        break;
    case 21:
        SetSpeaker(a1, a2);
        break;
    case 22:
        result = Converse(a1);
        break;
    case 23:
        if (space_sp != (unsigned)&a2)
            Fatal("Space Pause command with data on stack");
        if ((space_w2 = a1) == 0)
            space_w2 = 1;
        SpaceMenuClose();
        longjmp(space_jmp, 1);
    case 24:
        if (space_sp != (unsigned)&a1)
            Fatal("Space BeginEventLoop command with data on stack");
        if (crew_name[0])
            SetSteering(0);
        space_w2 = 0;
        SpaceMenuClose();
        longjmp(space_jmp, 1);
    case 25:
        if (space_sp != (unsigned)&a4)
            Fatal("Space OffShipAdventure command with data on stack");
        SpaceMenuClose();
        FadeOut();
        word_3CA46 = a2;
        word_3CA48 = a3;
        space_w2 = 1;
        longjmp(game_jmp, a1 ? 2 : 3);
    case 26:
        SpaceMenuClose();
        if (in_random) {
            LeaveRandom();
            longjmp(space_jmp, 1);
        } else {
            ClearShips();
            longjmp(game_jmp, 5);
        }
    case 27:
        result = rand() % (a2 - a1 + 1) + a1;
        break;
    case 28:
        sfx_vol_next = a2;
        sfx_pan_next = a3;
        BridgeSfx(a1);
        break;
    case 29:
        PlayMusic(a1, a2);
        break;
    case 30: {
        char codes[30];
        char *p;
        char *s;
        int k;

        GETTEXT(codes, a1, 30);
        p = codes;
        s = InputCode();
        k = 1;
        result = 0;
        while (*p) {
            if (strcmp(p, s) == 0)
                result = k;
            p += strlen(p) + 1;
            k++;
        }
        break;
    }
    case 31: {
        char name[10];

        GETNAME(name, a1);
        SpaceMenuClose();
        LoadMenu(name, a2, a3);
        ReleaseBitmap(mouse_sprite.handle);
        SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
        MenuHome();
        space_menu = 1;
        break;
    }
    case 32:
        SpaceMenuClose();
        break;
    case 33:
        if (space_menu)
            MenuShow(*(long *)&a1);
        break;
    case 34:
        if (space_menu)
            MenuDisable(*(long *)&a1);
        break;
    case 35:
        if (space_menu)
            MenuEnable(*(long *)&a1);
        break;
    case 36:
        if (!space_menu) {
            result = 0;
            break;
        }
        result = MenuLoop(*(unsigned long *)&a1, 0);
        break;
    case 37:
        Computer();
        break;
    case 38: {
        Actor *a;

        a = &actors[a1];
        a->flags = 0xBD;
        ((ActorBits *)a)->b3 = 1;
        break;
    }
    case 39: {
        Actor *a;

        a = &actors[a1];
        a->flags = 0;
        ((ActorBits *)a)->b3 = 0;
        break;
    }
    case 40: {
        Actor *a;

        a = &actors[a1];
        a->flags = a->flags & ~(a3 ^ a2) ^ a2;
        ((ActorBits *)a)->b3 = (a->flags & 8) != 0;
        break;
    }
    case 42:
        GameOverMenu();
    case 43:
        player_ship.shields_req = 1;
        SetPower(1, player_ship.weapons_req);
        break;
    case 44:
        player_ship.weapons_req = 1;
        SetPower(player_ship.shields_req, 1);
        break;
    case 45:
        PlayDemScene(ItemName(a1));
        break;
    case 46: {
        char *n;

        n = ItemName(a1);
        sub_1B61E(n);
        sub_1BCC2();
        SetFade(cur_palette, fade_level);
        break;
    }
    case 48: {
        unsigned long t;

        FadeOut();
        t = GetTicks() + a1;
        while (GetTicks() < t)
            MusicTick();
        break;
    }
    case 47:
        FadeIn();
        break;
    case 49:
        fade_rgb[0] = a1;
        fade_rgb[1] = a2;
        fade_rgb[2] = a3;
        break;
    case 50:
        if (a1 == 0)
            RestoreShip(&player_ship);
        else
            Fatal("repairall: invalid id %d", a1);
        break;
    case 51: {
        char *n;

        if (space_sp != (unsigned)&a2)
            Fatal("SpaceSaveGame command with data on stack");
        n = ItemName(a1);
        space_w2 = 1;
        SpaceMenuClose();
        SaveNamed(n);
        longjmp(space_jmp, 1);
    }
    case 52: {
        char *n;

        n = ItemName(a1);
        LoadNamed(n, a2);
    }
    case 53:
        result = GetLoadArg();
        break;
    case 54:
        OpenVCC(ItemName(a1));
        break;
    case 55:
        CloseVCC(ItemName(a1));
        break;
    default:
        Fatal("Unknown space cmd");
        break;
    }
    talk_data = LockMem(talk_handle);
    _asm {
        mov ax, word ptr talk_data+2
        mov [bp+4], ax
    }
    return result;
}

/* The handlers a paused script left after its call: talk data offsets. */
#define HANDLER(off) (*(int far *)(talk_data + space_ip + (off)))

/* The bridge's messages while an episode runs. */
void EncounterTick(void)
{
    Msg m;
    int h;

    m = *PeekMsg();
    if (space_ip == 0) {
        FadeOut();
        talk_data = LockMem(talk_handle);
        if (!in_random)
            cur_planet = *(int far *)(talk_data + 10);
        UnlockMem(talk_handle);
        SetPlanet(cur_planet);
        goal_planet = -1;
        sub_28CB0();
        StarsReset();
        RenderR3(0);
        UpdateSprites();
        if (m.type == 0)
            BridgeMsg();
        PlayMusic(13, 13);
        talk_data = LockMem(talk_handle);
        SpaceScript(12);
        UnlockMem(talk_handle);
        return;
    }
    if (space_w2) {
        switch (m.type) {
        case 0:
            BridgeMsg();
            if (--space_w2)
                return;
            goto resume;
        case 1:
            switch (m.arg) {
            case 3:
                if (!crew_name[0]) {
                    BridgeMsg();
                    return;
                }
                msg_head = (msg_head + 1) % 16;
                return;
            case 0x11:
            case 0x20:
            case 0x40:
            case 0x51:
            case 0x60:
                msg_head = (msg_head + 1) % 16;
            resume:
                talk_data = LockMem(talk_handle);
                SpaceScript(space_ip);
                UnlockMem(talk_handle);
                return;
            }
        }
    } else {
        switch (m.type) {
        case 0:
            BridgeMsg();
            talk_data = LockMem(talk_handle);
            h = HANDLER(4);
            goto run;
        case 1:
            switch (m.arg) {
            case 1:
            case 2:
                BridgeMsg();
                if (in_orbit)
                    return;
                if (!player_ship.weapons_pwr)
                    return;
                talk_data = LockMem(talk_handle);
                h = HANDLER(8);
                goto run;
            case 3:
                if (!crew_name[0]) {
                    BridgeMsg();
                    return;
                }
                msg_head = (msg_head + 1) % 16;
                return;
            case 0x11:
                msg_head = (msg_head + 1) % 16;
                if (player_ship.shields_pwr)
                    CrewSay(4, "#B_332#Captain, the shields are up.");
                else if (!in_orbit)
                    CrewSay(4, "#B_350#We're not in orbit Captain.");
                else {
                    talk_data = LockMem(talk_handle);
                    if ((h = HANDLER(12)) != 0)
                        SpaceScript(h);
                    UnlockMem(talk_handle);
                    if (!h)
                        CrewSay(4, "Right now, Captain?");
                }
                return;
            case 0x20:
                msg_head = (msg_head + 1) % 16;
                talk_data = LockMem(talk_handle);
                if ((h = HANDLER(2)) != 0)
                    SpaceScript(h);
                UnlockMem(talk_handle);
                if (!h)
                    CrewSay(1, "#B_155#Nothing to report, Captain.");
                return;
            case 0x40:
                msg_head = (msg_head + 1) % 16;
                talk_data = LockMem(talk_handle);
                if ((h = HANDLER(0)) != 0)
                    SpaceScript(h);
                UnlockMem(talk_handle);
                if (!h)
                    CrewSay(6, "#BRIDU016#Hailing frequencies open.");
                return;
            case 0x51:
                msg_head = (msg_head + 1) % 16;
                if (under_attack)
                    CrewSay(4, "#B_348#Unable to comply, Captain. We're under attack.");
                else if (cur_planet != goal_planet || in_orbit)
                    CrewSay(4, "#B_338#May I respectfully remind the Captain that we haven't accomplished our mission, Sir.");
                else {
                    talk_data = LockMem(talk_handle);
                    if ((h = HANDLER(10)) != 0)
                        SpaceScript(h);
                    UnlockMem(talk_handle);
                    CrewSay(4, "#B_333#Entering standard orbit.");
                }
                return;
            case 0x60:
                msg_head = (msg_head + 1) % 16;
                if (under_attack)
                    CrewSay(4, "#B_348#Unable to comply, Captain. We're under attack.");
                else if (goal_planet == cur_planet)
                    CrewSay(4, "#B_338#May I respectfully remind the Captain that we haven't accomplished our mission, Sir.");
                else if (in_orbit)
                    CrewSay(4, "#B_349#We must first leave orbit, Sir.");
                else {
                    if ((h = StarMapGo()) == -1)
                        return;
                    cur_planet = h;
                    StarsReset();
                    RenderR3(0);
                    UpdateSprites();
                    if (goal_planet != cur_planet) {
                        EnterRandom();
                        return;
                    }
                    talk_data = LockMem(talk_handle);
                    h = HANDLER(6);
                run:
                    if (h)
                        SpaceScript(h);
                    UnlockMem(talk_handle);
                }
                return;
            }
        }
    }
    BridgeMsg();
}

int crew_talk = 0;                      /* crew_name is a "tlk" animation */

/* Show crew member name over the bridge (with music). */
void ShowCrew(char *name, int music)
{
    if (*name) {
        if (strncmp(name, "tlk", 3) == 0) {
            crew_talk = 1;
            name += 3;
        } else
            crew_talk = 0;
    }
    if (*name == 0 || strcmp(name, crew_name) == 0) {
        RestartCrew();
        return;
    }
    if (crew_name[0])
        ReleaseBitmap(crew_sprite.handle);
    else if (_stricmp(name, "black") == 0)
        return;
    PlayMusic(music, -1);
    ClearView();
    view_sprite.dirty = 1;
    MemSet(&crew_sprite, sizeof(crew_sprite), 0);
    crew_sprite.layer = 0;
    crew_sprite.handle = LoadBitmap(name);
    if (!crew_name[0])
        AddSprite(&crew_sprite);
    SpriteSetPos(&crew_sprite, 0x47, 0x1E, 13);
    if (crew_talk)
        crew_anim = StartTalk(crew_anim, name, 0x47, 0x1E, 0x100, 1);
    else
        crew_anim = StartAnim(crew_anim, name, 0x47, 0x1E, 0x100);
    strncpy(crew_name, name, 8);
    crew_name[8] = 0;
    SetCursor();
    sub_1B61E(name);
}

/* Start the crew member's animation again. */
void RestartCrew(void)
{
    if (crew_name[0]) {
        if (crew_talk)
            StartTalk(crew_anim, crew_name, 0x47, 0x1E, 0x100, 1);
        else
            StartAnim(crew_anim, crew_name, 0x47, 0x1E, 0x100);
    }
}

/* Back to the bridge. */
void HideCrew(void)
{
    if (crew_name[0]) {
        SpriteErase(&crew_sprite);
        EndOrStand(crew_anim);
        DelSprite(&crew_sprite);
        ReleaseBitmap(crew_sprite.handle);
        LoadPalette("bridge");
        SetFade(cur_palette, fade_level);
        RenderR3(0);
        UpdateSprites();
        crew_name[0] = 0;
        crew_anim = -1;
        SetCursor();
    }
}

char *eval_crew[2] = { "tlkadmira", "tlkwoman" };
char *eval_name[2] = { "Admiral Richards", "Admiral Cain" };

/* The admiral's evaluation at the end of an episode: the crew get better
 * with each good grade. */
void Evaluate(char *report, int keep)
{
    int total;
    int got;
    int pct;
    int grade;
    int music;
    char *msg;
    int *p;

    total = mission_max;
    got = mission_score;
    pct = 1;
    if (got > 0) {
        int n;

        n = got;
        if (n > total)
            n = total;
        if (n < 0)
            n = 0;
        pct = n * 100 / got;
    } else
        pct = 0;
    if (pct <= 50) {
        grade = 0;
        music = 9;
        msg = "#EVAL005#I'll be frank Kirk, Starfleet expects more out of you than that.  If I were you, I'd do some serious soul-searching about my command ability. I would expect as much from a cadet.  But from Starfleet's finest... I'm going to have to forward my concerns to Command. Cain out.";
    } else if (pct >= 51 && pct <= 70) {
        grade = 1;
        music = 9;
        msg = "#EVAL004#While you acheived the desired results for your assignment, Jim, I can only give you a satifactory rating.  I would expect as much from a cadet.  I'm concerned about your performance and am going to have to forward my concerns to Command. Cain out.";
    } else if (pct >= 71 && pct <= 85) {
        grade = 2;
        music = 12;
        msg = "#EVAL003#Well done, Kirk. Keep up the good work. I must say, however, your performance is not what we've come to expect from James T. Kirk. I guess we all have our off days, Captain. Cain out.";
    } else if (pct >= 86 && pct <= 99) {
        grade = 3;
        music = 14;
        msg = "#EVAL002#The top brass at Starfleet are impressed with the results of your recent performance.  Outstanding work, Jim.  Keep up the good work. Cain out.";
    } else {
        grade = 4;
        music = 10;
        msg = "#EVAL001#I am very pleased with your performance. It was a perfect mission, Jim! Your reputation as Starfleet's best starship captain is secure. Cain out.";
    }
    if (report && *report) {
        ShowCrew("black", -1);
        UpdateActors();
        UpdateSprites();
        ShowCrew(eval_crew[1], music);
        msg_wait = 1;
        MsgBox(eval_name[1], "#EVAL000#I've reviewed your report from your recent assignmentCaptain and have a few comments.", 160, 199, 8, 5);
        MsgBox(eval_name[1], msg, 160, 199, 8, 5);
        msg_wait = 0;
        if (!keep)
            HideCrew();
    }
    if (episode != -1) {
        grades[episode] = grade;
        grade_sum += grade;
        rating = grade_sum * 100 / (((int)episode + 1) * 4);
    }
    boost_power += grade >> 1;
    boost_time += grade * 15;
    for (p = &player_ship.systems[2].max; p != &player_ship.systems[6].max; p += 4)
        *p += grade >> 2;
    for (p = &player_ship.shields[0].max; p != &player_ship.shields[6].max; p += 4)
        *p += grade >> 1;
}

/* Play a .dem cutscene, then put the screen back as it was. */
void PlayDemScene(char *name)
{
    unsigned char *pal;
    int busy;

    pal = AllocMemPtr(0x300);
    busy = poll_busy;
    MemCpy(pal, cur_palette, 0x300);
    poll_busy = 1;
    PlayDem(name);
    poll_busy = busy;
    fade_level = 0;
    MemSet((void far *)0xA0000000, 64000, 0);
    MemSet(cur_palette, 0x300, 0);
    SetPalette(cur_palette);
    if (game_mode == 1)
        RenderR3(0);
    RestoreBackground(&screen_rect);
    MarkAllDirty();
    UpdateSprites();
    BlitToScreen(&screen_rect);
    MemCpy(cur_palette, pal, 0x300);
    SetFade(cur_palette, fade_level);
    FreeMemPtr(pal);
}

/* The grades so far. */
void CaptainsLog(void)
{
    char text[350];
    char num[20];
    int i;
    int total;

    if ((int)episode <= 0) {
        MsgBox("Captain's Log", "#C_007#No recent missions have been completed.", 160, 130, 6, 0);
        return;
    }
    total = 0;
    for (i = episode - 1; i > -1; i--)
        total += grades[i];
    strcpy(text, "We have earned ");
    if (total != 1)
        sprintf(num, "%d points ", total);
    else
        strcpy(num, "1 point ");
    strcat(text, num);
    strcat(text, "for the following recently completed missions:\n\n");
    for (i = episode - 1; i > -1; i--) {
        if (episodes[i].title && *episodes[i].title) {
            strcat(text, episodes[i].title);
            if (grades[i] != 1)
                sprintf(num, ":  %d points.\n\n", grades[i]);
            else
                strcpy(num, ":  1 point.\n\n");
            strcat(text, num);
        }
    }
    MsgBox("Captain's Log", text, 160, 130, 6, 0);
}
