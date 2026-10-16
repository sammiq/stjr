/* seg001: the bridge - main loop, view panels, crew, radar, damage
 * display and the bridge menus */

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
#define SpriteAddRect SpriteAddRect_
#include "sprite.h"
#undef SpriteAddRect
#include "resource.h"
#include "fixmath.h"
#include "obj3d.h"
#include "actor.h"
#include "menu.h"
#include "room.h"

/* Globals this file owns (declared in the headers). */
Sprite mouse_sprite;

/* Called here with the rectangle passed whole. */
void SpriteAddRect(Sprite *s, MemHandle h, Rect r);

int getch(void);
void Fatal();
void PostRoomMsg(int msg, int who, int a, int b);     /* seg008: report */
void MsgBox(char *title, char *msg, int a, int b, int c, int d);    /* seg008: message box */
/* mission bridge handlers, seg029 - seg036 */
void DemonArrive(void);
void DemonFight(void);
void DemonHail(void);
void DemonTravel(void);
void DemonReturn(void);
void TugArrive(void);
void TugPirates(void);
void TugDisabled(void);
void TugOrbit(void);
void TugReturn(void);
void LoveArrive(void);
void LoveTravel(void);
void LoveRomulans(void);
void LoveOrbit(void);
void LoveAway(void);
void LoveReturn(void);
void MuddArrive(void);
void MuddHarlequin(void);
void MuddReturn(void);
void FeatherArrive(void);
void FeatherKenka(void);
void FeatherAttack(void);
void TrialArrive(void);
void TrialKenka(void);
void TrialSpock(void);
void TrialSulu(void);
void TrialKallarax(void);
void TrialFight(void);
void VengArrive(void);
void VengFinale(void);
void SinsArrive(void);
void SinsProxima(void);
void FreeActors(void);              /* seg000 */
void UpdateActors(void);

/* seg006 */
void CamReset(void);
void SetView(int x0, int y0, int x1, int y1, int fov);
void RenderR3(int statics);
/* seg020 */
int FireShot(Obj3D *o, Weapon *w, Vec32 *dir, ShipPart *p);
void Bearing(Obj3D *o, Vec32 *to, int *pitch, int *yaw);
int WeaponsReady(Obj3D *o);
void UpdatePower(Obj3D *o);
void MoveShip(Obj3D *o);
void Repair(Obj3D *o);
void UpdateShips(void);
void UpdateShots(void);
int BoostStart(void);
void SetPower(int shields, int weapons);
void SetRepair(int sys);
/* seg027 */
void Vec32Add(Vec32 *a, Vec32 *b);
/* others */
int StarMap(void);                  /* seg023 */
void CrewAnim(char *buf, int n, char *name);   /* seg008 */
void InitShips(char *name);         /* seg020 */
void ClearShots(void);
int tolower(int c);
int LoadShotShape(Obj3D *o);        /* seg006 */
void FreeShotShape(Obj3D *o);
void DelR3(Obj3D *o);
void StopShip(Obj3D *o);            /* seg025 */
void RandomPlanet(Obj3D *o);
void ChoiceTitle(int x, char far *name, int n);   /* seg008 */
void StarsReset(void);
void OrbitArrive(void);             /* seg025 */
void OrbitDepart(void);
void OrthoR3(void);                 /* seg006 */
void ClearView(void);
void Computer(void);                /* seg005 */

void BridgeSfx(int n);
void ClearScreen(void);
void KeyStation(int dx, int dy);
void SetSteering(int on);
void BridgeLoop(void);
void WaitButtonUp(void);
void FullView(void);
void FullViewEnd(void);
void BridgeScreen(void);
void BridgeScreenEnd(void);
void BridgeEnter(int reset);
void BridgeLeave(void);
void StartCrew(void);
void UpdateCrew(void);
void DrawRadar(void);
void FreeRadar(void);
void DrawShipStatus(Obj3D *o);
void DrawBmp(char *name);
void TintBmp(Bitmap far *bmp, int color);
void CyclePalette(void);
void CycleRange(int first, int count);
void InitBlip(void);
void MoveBlip(void);
void FaceEnemy(void);
void FireWeapons(int torps, int phasers);
void ClickCrew(int x, int y);
void BridgeKey(Event e);
void ClampPointer(void);
void ViewFull(void);
void ViewBridge(void);
void EncounterTick(void);
void DrawGauges(void);
void CrewMenu(char *name, int x, int y);
void BridgeMsg(void);
void SetViewDir(void);
void CrewOrder(int cmd);
int StarMapGo(void);
void Orbit(int arrive, int say);
void CamFollow(int n);
void CamPath(long *out, int which, int n);
void SendScript(int n);
void HailShow(char *name);
void HailRestart(void);
void HailEnd(void);
void HailSay(char *name, char *title, char *text);
void Transport(char *name);
void RepairAll(Obj3D *o);
void Debrief(int n, int msg, int score, int max);
void SayNumber(char *out, int n);
void CaptainsLog(void);
void StartEncounter(void);
void FreeText(char *p);
void SetTextFile(char *name);
char *GetText(int n);
void ShuttleFlyby(int kind);
void ShuttleEnd(void);
void CutScene(char *name, char *voc);
void CutSceneTick(void);
char *GetChoice(int n, int *list, int x);
void ResetMsgs(void);
void DrawWeaponGauge(ShipPart *p, Weapon *w, int x, int y, Bitmap far *bmp, int flip);
void DrawEngineGauge(ShipPart *p, int x, int y);
void DrawSpeedGauges(void);
void HLine(int x, int y, int len, int color);
void ClearMsgs(void);

typedef struct Point {
    int x;
    int y;
} Point;


extern Bitmap far *screen;
extern unsigned char far *mask_buf;
unsigned long blink_count;
Obj3D player_ship;
Obj3D ships[4];
Matrix cam_orient;
extern Vec32 cam_pos;
Sprite view_sprite;
BitmapHdr space_bmp;
extern MemHandle space_bmp_handle;
extern Rect clip_rect;
extern int view_cx;
extern int view_cy;
extern int key_accel;
extern int btn_key;
extern int arrow_key;
extern long proj_dist;
extern float star_near;
extern int fade_level;
unsigned long bridge_ticks;
extern int msg_tail;
int msg_head;
int word_537AE;
Sprite radar_sprite;
Sprite bspr1;
Sprite bspr2;
Sprite bspr3;
Sprite bspr4;
Sprite bspr5;
Sprite bspr6;
BitmapHdr bhdr1;
BitmapHdr bhdr2;
BitmapHdr bhdr3;
BitmapHdr bhdr4;
BitmapHdr bhdr5;
extern Actor actors[];

typedef struct Msg {
    unsigned char type;
    unsigned char arg;
    int unk;
} Msg;

extern Msg msg_queue[16];
Msg *PeekMsg(void);
Obj3D *last_target;
extern char mission[];
int cam_tab1[2][3];
int cam_tab2[2][3];
extern Obj3D dummy_planet;
Sprite hail_sprite;
char hail_name[16];
int hail_anim;
extern jmp_buf game_jmp;
int mission_ranks[7];
extern int voc_wait;
extern int boost_power;
extern int boost_time;
int encounter_delay;
int word_51156;
extern Bitmap far *backbuf;
Shot shot_obj;                      /* the fly-by shuttle, drawn as a shot */
extern int small_planets;
char *word_531D8;
Sprite cut_sprite;
void (far *saved_tick)(void);
char text_name[10];
extern long boost_count;
extern int boost_amount;

/* A line of a scripted conversation. */
typedef struct Line {
    int who;
    char *text;
    int x;
    int y;
    int c;
    int d;
} Line;

#define ROW(m, i)   (*(Vec *)(m).e[i])

char *crew_names[8] = {
    "Captain Kirk", "Mr. Spock", "Dr. McCoy", "Security Officer",
    "Mr. Sulu", "Mr. Chekov", "Lieutenant Uhura", "Mr. Scott"
};
int word_45AA2 = 0;
int full_view = 0;                 /* the view fills the screen */
int kbd_mouse = 0;                  /* the pointer steers the ship */
int in_orbit = 0;                 /* in orbit */
int under_attack = 0;
int encounter_kind = 0;                 /* encounter: 1 Klingon, 2 Romulan, 3 Elasi */
void (far *bridge_tick)(void) = DemonArrive;    /* the bridge tick */
int word_45AB2 = -1;
int word_45AB4 = 18;
int magnify = 6;                 /* magnification */
int view_dir = 0;                 /* view direction, -1 forward */
int word_45ABA = 0;
void (far *tick_fns[32])(void) = {
    DemonArrive, DemonFight, DemonHail, DemonTravel, DemonReturn,
    TugArrive, TugPirates, TugDisabled, TugOrbit, TugReturn,
    LoveArrive, LoveTravel, LoveRomulans, LoveOrbit, LoveAway, LoveReturn,
    MuddArrive, MuddHarlequin, MuddReturn,
    FeatherArrive, FeatherKenka, FeatherAttack,
    TrialArrive, TrialKenka, TrialSpock, TrialSulu, TrialKallarax, TrialFight,
    VengArrive, VengFinale,
    SinsArrive, SinsProxima
};
char byte_45B3C = 1;
Rect top_rects[3] = {
    { 0x5A, 0x0F, 0x7E, 0x15 }, { 0xC2, 0x0F, 0xE6, 0x15 }, { 0x8C, 0x0D, 0xB2, 0x16 }
};
MemHandle word_45B56 = 0;
MemHandle word_45B58 = 0;
MemHandle word_45B5A = 0;
Rect side_rects[2] = { { 0, 0x42, 0x3D, 0x6B }, { 0x101, 0x44, 0x13F, 0x6C } };
MemHandle word_45B6C = 0;
MemHandle word_45B6E = 0;
int word_45B70 = 0;
int target_analysis = 0;                 /* target analysis */
int word_45B74 = 0;
Point stations[6] = {
    { 0x3E, 0x79 }, { 0x7D, 0x84 }, { 0xA0, 0xA6 }, { 0xC7, 0x83 }, { 0x11B, 0x7F }, { 0x123, 0xB0 }
};
Vec32 cam_ofs = { -150, 50, -500 };
char radar_colors[4] = { 0x2E, 0x78, 0x64, 0x56 };

void BridgeSfx(int n)
{
    switch (n) {
    case 34:
        PlaySfx("HAILING");
        break;
    case 36:
        PlaySfx("PHASSHOT");
        break;
    case 37:
        PlaySfx("PHOTSHOT");
        break;
    case 38:
        PlaySfx("HITSHIEL");
        break;
    case 39:
        PlaySfxSeq((unsigned)n);
        break;
    case 16:
        PlaySfxSeq((unsigned)n);
        break;
    case 40:
        PlaySfx("REDALERT");
        break;
    case 41:
        PlaySfx("WARP");
        break;
    case 4:
        PlaySfx("tricorde");
        break;
    case 5:
        PlaySfx("STDOOR1");
        break;
    case 6:
        PlaySfx("PHASSHOT");
        break;
    case 7:
        PlaySfxSeq((unsigned)n);
        break;
    case 8:
        PlaySfx("TRANSDEM");
        break;
    case 9:
        PlaySfx("TRANSMAT");
        break;
    case 10:
        PlaySfx("TRANSENE");
        break;
    case 11:
        break;
    case 12:
        break;
    default:
        break;
    }
}

void ClearScreen(void)
{
    MemSet(screen->data, 0xFA00, 0);
    MemSet(mask_buf, 0x7D00, 0);
    RestoreBackground(&screen_rect);
    BlitToScreen(&screen_rect);
}

/* Keyboard pointer: jump to the nearest station in direction (dx, dy). */
void KeyStation(int dx, int dy)
{
    int i;
    int best;
    int besti;
    int d;

    best = 0x7FFF;
    if (dx == 0 && dy == 0)
        mouse_x += 4;
    if (dy == 0 && dx != 0) {
        if (mouse_y < 0x95)
            dy = -1;
        else
            dy = 1;
    }
    for (i = 5; i >= 0; i--) {
        d = stations[i].x - mouse_x;
        if (dx < 0)
            d = -d;
        if (d <= 0) {
            if (dx == 0 && dy != 0 && (mouse_y < 0x95) != (dy == -1))
                d = -d;
            else
                d += 320;
        }
        if (dy != 0 && (stations[i].y < 0x95) != (dy == -1))
            continue;
        if (d < best) {
            best = d;
            besti = i;
        }
    }
    mouse_x = stations[besti].x;
    mouse_y = stations[besti].y;
    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
    SetPointer(mouse_x, mouse_y);
}

void SetSteering(int on)
{
    if (kbd_mouse || full_view)
        word_45B74 = full_view;
    kbd_mouse = on;
    ReleaseBitmap(mouse_sprite.handle);
    if (kbd_mouse)
        SpriteSetBitmap(&mouse_sprite, LoadBitmap(player_ship.weapons_req ? "cursor" : "entcur"));
    else
        SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
    if (on && word_45B74)
        ViewFull();
    else
        ViewBridge();
    mouse_x = 160;
    mouse_y = on ? (clip_rect.y0 + clip_rect.y1) / 2 : 0xA6;
    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
    SetPointer(mouse_x, mouse_y);
    key_accel = on;
}

/* The bridge main loop. */
void BridgeLoop(void)
{
    int unused[3];
    Event ev;
    int full;

    for (;;) {
        if (encounter_kind == 0) {
            while (msg_head != msg_tail)
                (*bridge_tick)();
        } else {
            while (msg_head != msg_tail)
                EncounterTick();
        }
        if (GetEvent(&ev) == 0)
            continue;
        if (player_ship.expl) {
            if (player_ship.expl_frame == 0) {
                full = full_view;
                if (full)
                    FadeOut();
                else
                    ViewFull();
                SetSteering(1);
                view_dir = -1;
                cam_orient = player_ship.orient;
                MatRotYPre(64, &cam_orient);
                MatTVecMul32(&cam_ofs, &cam_orient, &cam_pos);
                Vec32Add(&cam_pos, &player_ship.pos);
                player_ship.expl_frame = 1;
                if (full) {
                    RenderR3(0);
                    UpdateSprites();
                    FadeIn();
                }
            }
            if (ev.type)
                continue;
            SpriteErase(&mouse_sprite);
        }
        switch (ev.type) {
        case EV_TICK:
            PostRoomMsg(0, (int)bridge_ticks & 0xFF, (int)(bridge_ticks >> 8) & 0xFF, (int)(bridge_ticks >> 16) & 0xFF);
            blink_count++;
            bridge_ticks++;
            if (in_orbit == 0) {
                if (btn_key == 0x52)
                    player_ship.mo.turn_target[2] = player_ship.mo.turn_max;
                else if (btn_key == 0x53)
                    player_ship.mo.turn_target[2] = -player_ship.mo.turn_max;
                else
                    player_ship.mo.turn_target[2] = 0;
            }
            break;
        case EV_MOVE:
            ClampPointer();
            if (in_orbit == 0 && kbd_mouse && word_45AA2 == 0) {
                player_ship.mo.turn_target[1] = (long)(ev.x - view_cx) << 16;
                player_ship.mo.turn_target[0] = (long)(ev.y - view_cy) << 16;
            }
            break;
        case EV_DOWN2:
            if (word_45AA2 == 0 && kbd_mouse)
                PostRoomMsg(1, 2, 0, 0);
            break;
        case EV_DOWN1:
            if (word_45AA2 == 0) {
                if (kbd_mouse == 0)
                    ClickCrew(ev.x, ev.y);
                else
                    PostRoomMsg(1, 1, 0, 0);
            }
            break;
        case EV_KEY:
            if ((((unsigned)ev.key >> 8) & 0xFF) == 0x19) {
                getch();
                break;
            }
            if (word_45AA2)
                break;
            if (kbd_mouse == 0) {
                switch (((unsigned)ev.key >> 8) & 0xFF) {
                case 0x48:
                    KeyStation(0, -1);
                    break;
                case 0x50:
                    KeyStation(0, 1);
                    break;
                case 0x4B:
                    KeyStation(-1, 0);
                    break;
                case 0x4D:
                    KeyStation(1, 0);
                    break;
                case 0x47:
                    KeyStation(-1, -1);
                    break;
                case 0x4F:
                    KeyStation(-1, 1);
                    break;
                case 0x49:
                    KeyStation(1, -1);
                    break;
                case 0x51:
                    KeyStation(1, 1);
                    break;
                case 0x1C:
                case 0x3B:
                    ClickCrew(mouse_x, mouse_y);
                    break;
                default:
                    BridgeKey(ev);
                    break;
                }
            } else
                BridgeKey(ev);
            break;
        }
    }
}

/* Wait for the left button to be released. */
void WaitButtonUp(void)
{
    int going;
    Event *e;

    going = 1;
    while (going) {
        if ((e = PeekEvent()) != 0) {
            if (e->type == EV_UP1)
                going = 0;
            else if (e->type == EV_TICK)
                UpdateSprites();
            PopEvent();
        }
    }
}

/* The view filling the screen. */
void FullView(void)
{
    SetView(2, 2, 319, 199, 512 / magnify);
    if (space_bmp_handle == 0)
        space_bmp_handle = AllocMemHandle(&space_bmp);
    SpriteAddRect(&view_sprite, space_bmp_handle, clip_rect);
    full_view = 1;
}

void FullViewEnd(void)
{
    DelSprite(&view_sprite);
}

/* The bridge with the view on the main screen. */
void BridgeScreen(void)
{
    SetView(72, 30, 247, 102, 512 / magnify);
    if (space_bmp_handle == 0)
        space_bmp_handle = AllocMemHandle(&space_bmp);
    SpriteAddRect(&view_sprite, space_bmp_handle, clip_rect);
    LoadFilePacked("bridge", "bmp", screen);
    LoadFilePacked("bridge", "pri", mask_buf);
    RestoreBackground(&screen_rect);
    BlitToScreen(&screen_rect);
    StartCrew();
    InitBlip();
    if (word_45B56 == 0)
        word_45B56 = AllocMemHandle(&bhdr1);
    if (word_45B58 == 0)
        word_45B58 = AllocMemHandle(&bhdr2);
    if (word_45B5A == 0)
        word_45B5A = AllocMemHandle(&bhdr3);
    SpriteAddRect(&bspr1, word_45B56, top_rects[0]);
    SpriteAddRect(&bspr2, word_45B58, top_rects[2]);
    SpriteAddRect(&bspr3, word_45B5A, top_rects[1]);
    if (word_45B6C == 0)
        word_45B6C = AllocMemHandle(&bhdr4);
    if (word_45B6E == 0)
        word_45B6E = AllocMemHandle(&bhdr5);
    SpriteAddRect(&bspr4, word_45B6C, side_rects[0]);
    SpriteAddRect(&bspr5, word_45B6E, side_rects[1]);
    full_view = 0;
}

void BridgeScreenEnd(void)
{
    int unused;

    FreeActors();
    DelSprite(&bspr5);
    DelSprite(&bspr4);
    DelSprite(&bspr6);
    DelSprite(&view_sprite);
    DelSprite(&bspr1);
    DelSprite(&bspr2);
    DelSprite(&bspr3);
    FreeRadar();
    ClearScreen();
}

void BridgeEnter(int reset)
{
    LoadPalette("bridge");
    LoadMusic("bridge");
    if (reset && in_orbit == 0)
        CamReset();
    player_ship.pos = cam_pos;
    player_ship.orient = cam_orient;
    BridgeScreen();
    word_45B74 = 0;
    SetSteering(1);
}

void BridgeLeave(void)
{
    if (full_view)
        FullViewEnd();
    else
        BridgeScreenEnd();
    kbd_mouse = 0;
    key_accel = 1;
}

/* The bridge crew at their stations. */
void StartCrew(void)
{
    StartAnim(0, "bstndki", 0, 4, 256);
    StartAnim(1, "bstndsp", 0, 0, 256);
    StartAnim(6, "bstnduh", 0, 0, 256);
    StartAnim(5, "bstndch", 0, 0, 256);
    StartAnim(4, "bstndsu", 0, 0, 256);
    StartAnim(7, "bstndsc", 0, 0, 256);
    if (bridge_tick == VengFinale)
        StartAnim(2, "xstndmc", 0, 0, 256);
}

char *ship_names[4] = { "ent", "klg", "ori", "rom" };
struct {
    BitmapHdr h;
    char data[14];
} blip_bmp = { { 0, 0, 7, 2 } };
MemHandle word_45BBC = 0;
struct {
    char name[10];
    int x;
    int y;
} station_menus[8] = {
    { "command", 60, 100 }, { "comp", 200, 30 }, { "", 0, 0 }, { "", 0, 0 },
    { "helm", 60, 70 }, { "nav", 60, 70 }, { "comm", 30, 30 }, { "eng", 30, 30 }
};
int view_key = 0;

void UpdateCrew(void)
{
    if (full_view == 0)
        UpdateActors();
}

/* The radar: a dot for each distant ship. */
void DrawRadar(void)
{
    int i;
    char far *p;
    Bitmap far *bmp;
    int angle;
    int r;
    int x;
    int y;
    Obj3D *o;

    if (full_view)
        return;
    if (radar_sprite.handle == 0) {
        radar_sprite.x = 159;
        radar_sprite.y = 140;
        radar_sprite.z = 2;
        radar_sprite.handle = AllocMemAbort(0x129, 1);
        bmp = LockMem(radar_sprite.handle);
        bmp->x = 8;
        bmp->y = 8;
        bmp->w = 17;
        bmp->h = 17;
        UnlockMem(radar_sprite.handle);
        AddSprite(&radar_sprite);
    }
    bmp = LockMem(radar_sprite.handle);
    p = bmp->data;
    MemSet(p, 17 * 17, 0);
    p[8 * 17 + 8] = 0x8B;
    for (i = 0; i != 4; i++) {
        o = &ships[i];
        if (o->visible == 0)
            continue;
        if (o->visible != R3_SHIP)
            continue;
        if (o->scale < star_near)
            continue;
        if (o->shields_on && o->shield_glow >= 20)
            continue;
        {
            long vx;
            long vy;
            long vz;
            int t;

            vx = o->view.x;
            vy = o->view.y;
            vz = o->view.z;
            angle = FixAtan2(vy, vx);
            t = 256 - FixAtan2(vz, (unsigned)FixLength(vx, vy, 0));
            r = FixMul(16, FixSin(t >> 1));
            x = (FixMul(r, FixCos(angle)) + 1) / 2 + 8;
            y = (FixMul(r, -FixSin(angle)) + 1) / 2 + 8;
        }
        p[y * 17 + x] = radar_colors[(unsigned)i % 4];
    }
    UnlockMem(radar_sprite.handle);
    radar_sprite.dirty = 1;
}

void FreeRadar(void)
{
    if (radar_sprite.handle) {
        DelSprite(&radar_sprite);
        FreeMem(radar_sprite.handle);
        radar_sprite.handle = 0;
    }
}

/* The target ship's status panels: hull, damaged systems and shields. */
void DrawShipStatus(Obj3D *o)
{
    char name[16];
    MemHandle h;
    Bitmap far *bmp;
    int i;
    int j;
    ShipPart *p;

    if (full_view)
        return;
    DrawGauges();
    if ((blink_count & 3) == 0 || word_45B70 == 1) {
        bspr1.dirty = bspr2.dirty = bspr3.dirty = 1;
        bspr4.dirty = bspr5.dirty = 1;
        sprintf(name, "t%s", ship_names[o->kind]);
        DrawBmp(name);
        sprintf(name, "s%s", ship_names[o->kind]);
        DrawBmp(name);
        p = o->systems;
        for (j = 0; j != 10; ++j, ++p) {
            if (p->cur * 4 < p->max * 3) {
                sprintf(name, "t%s%02d", ship_names[o->kind], j);
                DrawBmp(name);
                sprintf(name, "s%s%02d", ship_names[o->kind], j);
                DrawBmp(name);
            }
        }
        for (p = o->shields, i = 0; i != 6; ++i, ++p) {
            sprintf(name, "%sshd%02d", ship_names[o->kind], i);
            h = CacheLoad(name, "bmp");
            bmp = LockMem(h);
            if (o->shields_pwr)
                TintBmp(bmp, (p->max - p->cur) * 8 / (p->max + 1) + 0xB0);
            else
                TintBmp(bmp, 0xB7);
            CopyRectNZ(screen, -bmp->x, -bmp->y, bmp, 0, 0, bmp->w, bmp->h);
            UnlockMem(h);
            CacheRelease(h);
        }
    }
}

/* Draw name.bmp onto the background. */
void DrawBmp(char *name)
{
    MemHandle h;
    Bitmap far *bmp;

    h = CacheLoad(name, "bmp");
    bmp = LockMem(h);
    CopyRectNZ(screen, -bmp->x, -bmp->y, bmp, 0, 0, bmp->w, bmp->h);
    UnlockMem(h);
    CacheRelease(h);
}

/* Set every non-zero pixel of bmp to color. */
void TintBmp(Bitmap far *bmp, int color)
{
    char far *p;
    int n;

    n = bmp->w * bmp->h;
    p = bmp->data;
    while (n--) {
        if (*p)
            *p = color;
        ++p;
    }
}

/* Cycle the bridge's palette ranges. */
void CyclePalette(void)
{
    if (video_mode != 0)
        return;
    if (fade_level != 100)
        return;
    if (blink_count & 1)
        return;
    CycleRange(0xD0, 8);
    CycleRange(0xE0, 8);
    CycleRange(0xE8, 8);
    CycleRange(0xF2, 11);
}

void CycleRange(int first, int count)
{
    unsigned char buf[34];
    int shift;
    int n;

    if (count > 11)
        Fatal("Increase the color cycle const.");
    shift = (blink_count >> 1) % count;
    n = (count - shift) * 3;
    MemCpy(buf, cur_palette + (first + shift) * 3, n);
    if (shift)
        MemCpy(buf + n, cur_palette + first * 3, count * 3 - n);
    SetPaletteRange(buf, first, count);
}

/* The blip running along the console. */
void InitBlip(void)
{
    MemSet(blip_bmp.data, sizeof(blip_bmp.data), 0xDA);
    MemSet(&bspr6, sizeof(Sprite), 0);
    AddSprite(&bspr6);
    SpriteSetPos(&bspr6, 0x49, 0x6B, 2);
    if (word_45BBC == 0)
        word_45BBC = AllocMemHandle(&blip_bmp);
    SpriteSetBitmap(&bspr6, word_45BBC);
}

void MoveBlip(void)
{
    int x;

    if (full_view)
        return;
    if (blink_count & 3)
        return;
    x = word_537AE++ * 8 + 0x49;
    word_537AE %= 22;
    SpriteSetPos(&bspr6, x, 0x6B, 2);
}

/* Turn the ship towards the first enemy. */
void FaceEnemy(void)
{
    int yaw;
    int pitch;

    if (ships[0].visible) {
        Bearing(&player_ship, &ships[0].pos, &pitch, &yaw);
        player_ship.mo.turn_target[1] = yaw >> 1;
    }
}

/* Fire torpedoes and/or phasers at the pointer. */
void FireWeapons(int torps, int phasers)
{
    Vec32 v;
    Vec32 dir;
    Matrix m;
    ShipPart *p;
    int fired;

    p = &player_ship.systems[SYS_TORP_PORT];
    if (!WeaponsReady(&player_ship) || player_ship.weapons_pwr == 0)
        return;
    v.x = arrow_key ? 0 : mouse_x - view_cx;
    v.y = arrow_key ? 0 : view_cy - mouse_y;
    v.z = proj_dist;
    MatTranspose(&player_ship.orient, &m);
    MatTVecMul32(&v, &player_ship.orient, &dir);
    if (torps) {
        fired = 0;
        fired |= FireShot(&player_ship, &player_ship.weapons[0], &dir, p);
        fired |= FireShot(&player_ship, &player_ship.weapons[1], &dir, p + 1);
        if (fired)
            BridgeSfx(37);
    }
    if (phasers) {
        fired = 0;
        fired |= FireShot(&player_ship, &player_ship.weapons[2], &dir, p + 2);
        fired |= FireShot(&player_ship, &player_ship.weapons[3], &dir, p + 3);
        if (fired)
            BridgeSfx(36);
    }
}

/* A crew member's menu. */
void CrewMenu(char *name, int x, int y)
{
    int r;
    int kbd;
    int x0;
    int y0;
    MemHandle bmp;
    Event ev;

    kbd = kbd_mouse;
    x0 = mouse_x;
    y0 = mouse_y;
    bmp = mouse_sprite.handle;
    kbd_mouse = 0;
    SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
    BridgeSfx(39);
    LoadMenu(name, x, y);
    MenuHome();
    r = MenuLoop(0, 0);
    MenuClose();
    if (r >= 0)
        PostRoomMsg(1, r & 0xFF, 0, 0);
    kbd_mouse = kbd;
    ReleaseBitmap(mouse_sprite.handle);
    SpriteSetBitmap(&mouse_sprite, bmp);
    if (r >= 0 || r == -2) {
        mouse_x = x0;
        mouse_y = y0;
        SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
        SetPointer(mouse_x, mouse_y);
    } else if (r == -1) {
        ev.type = EV_DOWN1;
        ev.x = mouse_x;
        ev.y = mouse_y;
        PostEvent(&ev);
    }
}

/* Click on the bridge: open the menu of the crew member there. */
void ClickCrew(int x, int y)
{
    Sprite *s;
    Actor *a;
    int i;

    if ((s = SpriteAt(x, y)) != 0) {
        for (i = 0, a = actors; i <= 7; ++i, ++a) {
            if (&a->sprite == s) {
                if (station_menus[i].name[0])
                    CrewMenu(station_menus[i].name, station_menus[i].x, station_menus[i].y);
                break;
            }
        }
    }
}

/* Bridge keys. */
void BridgeKey(Event e)
{
    int k;
    char buf[40];

    if (view_key) {
        view_key = 0;
        if ((k = e.key & 0xFF) >= '1' && k <= '6')
            view_dir = k - '1';
        return;
    }
    k = (unsigned)e.key >> 8;
    switch (k) {
    case 68:
    case 88:
        byte_45B3C ^= 1;
        break;
    case 15:
    case 61:
        SetSteering(kbd_mouse == 0);
        ClampPointer();
        break;
    case 31:
        PostRoomMsg(1, 0x51, 0, 0);
        break;
    case 17:
        PostRoomMsg(1, 0x61, 0, 0);
        break;
    case 41:
        if (in_orbit == 0)
            player_ship.mo.target_speed = -player_ship.mo.max_speed >> 3;
        break;
    case 2:
    case 3:
    case 4:
    case 5:
    case 6:
    case 7:
    case 8:
    case 9:
    case 10:
    case 11:
        if (in_orbit == 0)
            player_ship.mo.target_speed = (k - 2) * player_ship.mo.max_speed / 9;
        break;
    case 28:
    case 59:
        if (kbd_mouse)
            PostRoomMsg(1, 1, 0, 0);
        break;
    case 57:
    case 60:
        if (kbd_mouse)
            PostRoomMsg(1, 2, 0, 0);
        break;
    case 76:
        player_ship.mo.turn_target[0] = player_ship.mo.turn_target[1] = player_ship.mo.turn_target[2] = 0;
        if (kbd_mouse) {
            mouse_x = 160;
            mouse_y = (clip_rect.y0 + clip_rect.y1) / 2;
            SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
            SetPointer(mouse_x, mouse_y);
        }
        break;
    case 49:
        PostRoomMsg(1, 0x60, 0, 0);
        break;
    case 30:
        PostRoomMsg(1, 0x77, 0, 0);
        break;
    case 32:
        PostRoomMsg(1, 0x30, 0, 0);
        break;
    case 18:
        PostRoomMsg(1, 0x31, 0, 0);
        break;
    case 35:
        PostRoomMsg(1, 0x40, 0, 0);
        break;
    case 20:
        PostRoomMsg(1, 0x20, 0, 0);
        break;
    case 37:
        PostRoomMsg(1, 0, 0, 0);
        break;
    case 24:
        PostRoomMsg(1, 0x50, 0, 0);
        break;
    case 47:
        PostRoomMsg(1, 3, 0, 0);
        break;
    case 51:
        if (magnify == 4)
            break;
        magnify = max(magnify - 1, 4);
        goto mag;
    case 52:
        if (magnify == 8)
            break;
        magnify = min(magnify + 1, 8);
    mag:
        sprintf(buf, "Magnification %d", magnify - 3);
        MsgBox(crew_names[4], buf, 0x7A, 0x74, 0xB0, 0);
        if (full_view)
            SetView(2, 2, 319, 199, 512 / magnify);
        else
            SetView(72, 30, 247, 102, 512 / magnify);
        break;
    case 38:
        view_key = 1;
        break;
    case 46:
        PostRoomMsg(1, 0x21, 0, 0);
        break;
    }
}

/* Keep the pointer inside the view (keyboard steering) or below it. */
void ClampPointer(void)
{
    if (kbd_mouse) {
        mouse_x = max(clip_rect.x0, min(mouse_x, clip_rect.x1)),
            mouse_y = max(clip_rect.y0, min(mouse_y, clip_rect.y1));
        SetPointer(mouse_x, mouse_y);
    } else if (mouse_y < clip_rect.y1 + 4) {
        mouse_y = clip_rect.y1 + 4;
        SetPointer(mouse_x, mouse_y);
    }
    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
    mouse_sprite.layer = 16;
}

/* Handle the next queued bridge message. */
void BridgeMsg(void)
{
    Msg m;
    int i;
    char buf[80];

    if (msg_head == msg_tail)
        return;
    m = msg_queue[msg_head];
    msg_head = (msg_head + 1) % 16;
    switch (m.type) {
    case 1:
        CrewOrder(m.arg);
        break;
    case 2:
        if (m.arg == 0 && player_ship.expl == 0)
            MsgBox(crew_names[7], "#BRID\\BRID_S45#The shields are falling!", 0, 0xA0, 0xA1, 0);
        else
            break;
    case 3:
        if (m.arg == 0 && player_ship.expl == 0)
            MsgBox(crew_names[7], "#BRID\\BRID_S37#Our weapons are off-line!", 0, 0xA0, 0xA1, 0);
        break;
    case 4:
        if (m.arg == 0 && player_ship.expl == 0)
            MsgBox(crew_names[7], "#BRID\\BRID_S47#We can't maintain our speed!", 0, 0xA0, 0xA1, 0);
        break;
    case 5:
        break;
    case 7: {
        static struct {
            int sys;
            char *name;
        } repair_names[7] = {
            { 0xFF, "#BRID\\SCOTSHIE#Shields" }, { 0, "#BRID\\SCOTHULL#Hull" },
            { 1, "#BRID\\SCOTBRID#Bridge" }, { 6, "#BRID\\SCOTSENS#Sensors" },
            { 2, "#BRID\\SCOTTORP#Torpedoes" }, { 4, "#BRID\\SCOTPHAS#Phasers" },
            { 7, "#BRID\\SCOTENGI#Engines" }
        };

        for (i = 0; i != 7; i++)
            if (repair_names[i].sys == m.arg) {
                sprintf(buf, "%s repaired, Captain.", repair_names[i].name);
                MsgBox(crew_names[7], buf, 0x40, 0x64, 0xA1, 0);
                break;
            }
        break;
    }
    case 0:
        UpdatePower(&player_ship);
        MoveShip(&player_ship);
        Repair(&player_ship);
        UpdateShips();
        UpdateShots();
        if ((blink_count & 0x3F) == 0)
            OrthoR3();
        MatRotYPre(4, &dummy_planet.orient);
        SetViewDir();
        i = player_ship.systems[SYS_SENSORS].cur < rand() % player_ship.systems[SYS_SENSORS].max;
        RenderR3(i);
        mouse_sprite.dirty = 1;
        if (full_view == 0) {
            DrawRadar();
            if (target_analysis == 0)
                DrawShipStatus(&player_ship);
            else if (last_target == 0)
                DrawShipStatus(&player_ship);
            else if (last_target->visible == 0) {
                last_target = 0;
                DrawShipStatus(&player_ship);
            } else
                DrawShipStatus(last_target);
            MoveBlip();
            UpdateActors();
        }
        UpdateSprites();
        MusicTick();
        if (bridge_ticks > 2) {
            CyclePalette();
            FadeUp();
        }
        word_45B70 = 0;
        break;
    }
}

Msg *PeekMsg(void)
{
    if (msg_head != msg_tail)
        return &msg_queue[msg_head];
    else
        return 0;
}

/* Point the camera out of a side or the back of the ship. */
void SetViewDir(void)
{
    Vec a;
    Vec b;

    if (view_dir == -1)
        return;
    cam_pos = player_ship.pos;
    cam_orient = player_ship.orient;
    MemSet(&a, sizeof(a), 0);
    MemSet(&b, sizeof(b), 0);
    switch (view_dir) {
    case 0:
        break;
    case 1:
        VecSub(a.e, cam_orient.e[0]);
        VecSub(b.e, cam_orient.e[2]);
        ROW(cam_orient, 0) = a;
        ROW(cam_orient, 2) = b;
        break;
    case 2:
        VecSub(a.e, cam_orient.e[0]);
        b = ROW(cam_orient, 2);
        ROW(cam_orient, 0) = b;
        ROW(cam_orient, 2) = a;
        break;
    case 3:
        a = ROW(cam_orient, 0);
        VecSub(b.e, cam_orient.e[2]);
        ROW(cam_orient, 0) = b;
        ROW(cam_orient, 2) = a;
        break;
    case 4:
        a = ROW(cam_orient, 1);
        VecSub(b.e, cam_orient.e[2]);
        ROW(cam_orient, 1) = b;
        ROW(cam_orient, 2) = a;
        break;
    case 5:
        VecSub(a.e, cam_orient.e[1]);
        b = ROW(cam_orient, 2);
        ROW(cam_orient, 1) = b;
        ROW(cam_orient, 2) = a;
        break;
    }
}

/* A crew order. */
void CrewOrder(int cmd)
{
    Obj3D *o;

    switch (cmd) {
    case 0:
        CrewMenu("command", 60, 100);
        break;
    case 1:
        if (in_orbit == 0)
            FireWeapons(0, 1);
        break;
    case 2:
        if (in_orbit == 0)
            FireWeapons(1, 0);
        break;
    case 3:
        if (full_view)
            ViewBridge();
        else {
            ViewFull();
            SetSteering(1);
        }
        break;
    case 0x77:
        if (target_analysis ^= 1) {
            MsgBox(crew_names[4], "#BRID\\B_344#Target Analysis On.", 0x7A, 0x74, 0xB0, 0);
            last_target = 0;
            for (o = ships; o != &ships[4]; o++)
                if (o->visible) {
                    last_target = o;
                    break;
                }
        } else {
            MsgBox(crew_names[4], "#BRID\\B_343#Target Analysis Off.", 0x7A, 0x74, 0xB0, 0);
            last_target = 0;
        }
        break;
    case 0x10:
        CaptainsLog();
        break;
    case 0x11:
        if (player_ship.shields_pwr)
            MsgBox(crew_names[4], "#BRID\\B_332#Captain, the shields are up.", 0x7A, 0x74, 0xA1, 0);
        else if (in_orbit == 0)
            MsgBox(crew_names[4], "#BRID\\B_350#We're not in orbit, Captain.", 0x7A, 0x74, 0xA1, 0);
        else if (word_45AB2 == word_45AB4) {
            if (strcmpi(mission, "veng") && strcmpi(mission, "feather"))
                MsgBox(crew_names[0], "#BRID\\C_060#Spock, come with me. Mr Scott, you have the conn.", 0xA0, 0x82, 0xB0, 0);
            else if (strcmpi(mission, "feather") == 0)
                MsgBox(crew_names[0], "#BRID\\C_006#Assemble a landing party. Unless we find this so-called criminal, we're going to war.", 0xA0, 0x82, 0xB0, 0);
            FadeOut();
            longjmp(game_jmp, 3);
        } else
            MsgBox(crew_names[4], "#BRID\\B_346#This isn't our destination.", 0x7A, 0x74, 0xB0, 0);
        break;
    case 0x12:
        OptionsMenu(60, 65);
        break;
    case 0x20:
        MsgBox(crew_names[1], "#BRID\\B_155#Nothing to report, Captain.", 0x126, 0x6A, 0x2C, 0);
        break;
    case 0x21:
        Computer();
        break;
    case 0x30:
        CrewMenu("repair", 30, 30);
        break;
    case 0x31:
        if (BoostStart())
            MsgBox(crew_names[7], "#BRID\\BRID_S32#I don't know how long she can take it, Captain.", 0x40, 0x64, 0xA1, 0);
        else
            MsgBox(crew_names[7], "#BRID\\BRID_S41#She can't take it, Captain.", 0x40, 0x64, 0xA1, 0);
        break;
    case 0x40:
        MsgBox(crew_names[6], "#BRID\\BRIDU016#Hailing frequencies open.", 0x12A, 0x96, 0xA1, 0);
        break;
    case 0x50:
        if (under_attack)
            MsgBox(crew_names[4], "#BRID\\B_348#Unable to comply, Captain. We're under attack.", 0x7A, 0x74, 0xB0, 0);
        else if (word_45AB2 == word_45AB4 && in_orbit == 0)
            Orbit(in_orbit == 0, 1);
        else
            MsgBox(crew_names[4], "#BRID\\B_338#May I respectfully remind the Captain that we haven't accomplished our mission, Sir.", 0x7A, 0x74, 0x2C, 0);
        break;
    case 0x51:
        if (player_ship.shields_req ^= 1)
            MsgBox(crew_names[4], "#BRID\\B_340#Raising shields.", 0x7A, 0x74, 0xB0, 0);
        else
            MsgBox(crew_names[4], "#BRID\\B_337#Lowering shields, Captain.", 0x7A, 0x74, 0xB0, 0);
        break;
    case 0x60:
        if (under_attack)
            MsgBox(crew_names[4], "#BRID\\B_348#Unable to comply, Captain.  We're under attack.", 0x7A, 0x74, 0xB0, 0);
        else if (word_45AB2 == word_45AB4)
            MsgBox(crew_names[4], "#BRID\\B_338#May I respectfully remind the Captain that we haven't accomplished our mission, Sir.", 0x7A, 0x74, 0x2C, 0);
        else if (in_orbit)
            MsgBox(crew_names[4], "#BRID\\B_349#We must first leave orbit, Sir.", 0x7A, 0x74, 0xB0, 0);
        else {
            if ((word_45AB2 = StarMapGo()) != word_45AB4)
                StartEncounter();
            StarsReset();
            RenderR3(0);
            UpdateSprites();
        }
        break;
    case 0x61:
        if (player_ship.weapons_req ^= 1)
            MsgBox(crew_names[5], "#BRID\\B_351#Arming weapons.", 0xC4, 0x74, 0xB0, 0);
        else
            MsgBox(crew_names[5], "#BRID\\B_354#Disarming weapons.", 0xC4, 0x74, 0xB0, 0);
        SetPower(player_ship.shields_req, player_ship.weapons_req);
        break;
    case 0x70:
        SetRepair(0x7FFF);
        break;
    case 0x71:
        SetRepair(4);
        break;
    case 0x72:
        SetRepair(2);
        break;
    case 0x73:
        SetRepair(6);
        break;
    case 0x74:
        SetRepair(1);
        break;
    case 0x75:
        SetRepair(0);
        break;
    case 0x76:
        SetRepair(7);
        break;
    }
}

/* The star map. Returns the chosen destination. */
int StarMapGo(void)
{
    int full;
    int r;

    full = full_view;
    FadeOut();
    ViewFull();
    kbd_mouse = 0;
    key_accel = 1;
    r = StarMap();
    SetSteering(1);
    if (full == 0)
        ViewBridge();
    FadeOut();
    return r;
}

void ViewFull(void)
{
    if (full_view == 0) {
        magnify = 4;
        BridgeScreenEnd();
        FullView();
        full_view = 1;
    }
}

void ViewBridge(void)
{
    if (full_view) {
        magnify = 6;
        FullViewEnd();
        BridgeScreen();
        full_view = 0;
    }
}

void Orbit(int arrive, int say)
{
    int full;
    int mag;
    char *msg;

    full = full_view;
    mag = magnify;
    magnify = 6;
    FadeOut();
    ViewFull();
    if (arrive) {
        OrbitArrive();
        msg = "#BRID\\B_333#Entering standard orbit.";
    } else {
        OrbitDepart();
        msg = "#BRID\\B_335#Leaving orbit.";
    }
    ViewBridge();
    RenderR3(0);
    UpdateSprites();
    if (say)
        MsgBox(crew_names[4], msg, 0x7A, 0x74, 0xB0, 0);
    in_orbit = arrive;
    magnify = mag;
}

void CamFollow(int n)
{
    Vec32 v;
    Matrix m;

    CamPath(&player_ship.pos.x, 1, n);
    if (view_dir != -1)
        return;
    CamPath(&cam_pos.x, 0, n);
    v = player_ship.pos;
    Vec32Sub(&v, &cam_pos);
    if (MatFromVecs(&v.x, player_ship.orient.e[1], 0, &m))
        cam_orient = m;
}

void CamPath(long *out, int which, int n)
{
    int i;

    for (i = 0; i != 3; i++)
        out[i] = cam_tab1[which][i] * n + cam_tab2[which][i];
}

void SendScript(int n)
{
    if (n)
        PostRoomMsg(5, n & 0xFF, 0, 0);
}

/* Show name on the main screen. */
void HailShow(char *name)
{
    ViewBridge();
    if (strcmpi(name, "romula") == 0 || strcmpi(name, "pira") == 0 || strcmpi(name, "klg1") == 0
        || strcmpi(name, "klg2") == 0 || strcmpi(name, "maddoc") == 0)
        PlayMusic(15, -2);
    else if (strcmpi(name, "mudd") == 0)
        PlayMusic(17, -2);
    ClearView();
    view_sprite.dirty = 1;
    MemSet(&hail_sprite, sizeof(Sprite), 0);
    hail_sprite.layer = 0;
    hail_sprite.handle = LoadBitmap(name);
    AddSprite(&hail_sprite);
    SpriteSetPos(&hail_sprite, 72, 30, 13);
    hail_anim = StartAnim(-1, name, 72, 30, 256);
    strcpy(hail_name, name);
}

void HailRestart(void)
{
    StartAnim(hail_anim, hail_name, 72, 30, 256);
}

void HailEnd(void)
{
    SpriteErase(&hail_sprite);
    EndAnim(hail_anim);
    DelSprite(&hail_sprite);
    ReleaseBitmap(hail_sprite.handle);
    RenderR3(0);
    UpdateSprites();
}

Point beam_pos[4] = { { 0x8E, 0x7C }, { 0xBE, 0x7C }, { 0x7E, 0x72 }, { 0xAA, 0x72 } };
int last_mission = -1;                /* last mission completed */

void HailSay(char *name, char *title, char *text)
{
    HailShow(name);
    MsgBox(title, text, 0xA0, 0xBE, 0x2C, -7);
    HailEnd();
}

/* The transporter: beam the landing party (name: teled or teleb). */
void Transport(char *name)
{
    char buf[10];
    int i;
    int n;
    Event ev;

    DigiShutdown();
    FadeOut();
    FreeActors();
    InitActors();
    LoadFilePacked("transprt", "bmp", screen);
    MemSet(mask_buf, 0x7D00, 0);
    LoadPalette("palette");
    MemCpy(backbuf->data, screen->data, 0xFA00);
    BlitToScreen(&screen_rect);
    n = room.redshirt_dead ? 3 : 4;
    for (i = 0; i != n; i++) {
        CrewAnim(buf, i, name);
        StartAnim(i, buf, beam_pos[i].x, beam_pos[i].y, 256);
        actors[i].stand[0] = 0;
    }
    if (strcmpi(mission, "feather") == 0 && tolower(name[4]) == 'b')
        StartAnim(9, "qteleb", 0x61, 0x79, 256);
    else if (strcmpi(mission, "trial") == 0) {
        if (tolower(name[4]) == 'd')
            StartAnim(9, "qteled", 0x61, 0x79, 256);
        else if (word_51156 >= 3)
            StartAnim(9, "qteleb", 0x61, 0x79, 256);
    }
    StartAnim(8, "transc", 0, 0, 256);
    SpriteErase(&mouse_sprite);
    SpriteErase(&bspr6);
    UpdateSprites();
    FadeIn();
    BridgeSfx(10);
    BridgeSfx(strcmpi(name, "teled") == 0 ? 8 : 9);
    while (actors[0].loops == 0) {
        if (GetEvent(&ev)) {
            switch (ev.type) {
            case EV_TICK:
                blink_count++;
                UpdateActors();
                SpriteErase(&mouse_sprite);
                SpriteErase(&bspr6);
                UpdateSprites();
                break;
            }
        }
    }
    SpriteErase(&bspr6);
    UpdateSprites();
    FadeOut();
    FreeActors();
    InitActors();
}

/* Repair a ship completely. */
void RepairAll(Obj3D *o)
{
    ShipPart *p;
    int i;

    for (i = 0, p = o->shields; i != 6; ++i, ++p)
        p->cur = p->max;
    for (i = 0, p = o->systems; i != 10; ++i, ++p)
        p->cur = p->max;
}

/* Starfleet's verdict on mission n. */
void Debrief(int n, int msg, int score, int max)
{
    int pct;
    int rank;
    char *verdict;
    char *text;
    int len;
    unsigned music;
    int i;
    char voice1[128];
    char voice2[128];

    if (max > 0) {
        score = max(0, min(score, max));
        pct = score * 100 / max;
    } else
        pct = 0;
    if (pct <= 50) {
        rank = 0;
        music = 13;
        verdict = "#BRID\\B_199#I'll be frank, Kirk. Starfleet expects more of you than that. Try to do better on your next assignment.";
    } else if (pct >= 51 && pct <= 70) {
        rank = 1;
        music = 13;
        verdict = "#BRID\\B_197#A satisfactory performance, Captain, but there's still room for improvement.";
    } else if (pct >= 71 && pct <= 85) {
        rank = 2;
        music = 11;
        verdict = "#BRID\\B_214#Well done, Captain. Keep up the good work.";
    } else if (pct >= 86 && pct <= 99) {
        rank = 3;
        music = 12;
        verdict = "#BRID\\B_414#The top brass at Starfleet are impressed. Outstanding work, Jim.";
    } else {
        rank = 4;
        music = 14;
        verdict = "#BRID\\B_195#A perfect mission, Jim! You are a model for all Starfleet!";
    }
    PlayMusic(music, -2);
    voice1[0] = 0;
    SayNumber(voice1, pct);
    voice2[0] = 0;
    SayNumber(voice2, rank);
    len = strlen(GetText(msg));
    FreeText(0);
    text = AllocMemPtr(len + strlen(verdict) + 80);
    sprintf(text, GetText(msg), voice1, voice2, pct, rank);
    FreeText(0);
    HailShow("woman");
    MsgBox("Admiral", text, 0xA0, 0xBE, 0x2C, -7);
    MsgBox("Admiral", verdict, 0xA0, 0xBE, 0x2C, -7);
    if (n != 6)
        HailEnd();
    FreeMemPtr(text);
    last_mission = n;
    mission_ranks[n] = rank;
    boost_power += rank >> 1;
    boost_time += rank * 15;
    for (i = 0; i != 4; i++)
        player_ship.systems[i + 2].max += rank >> 2;
    for (i = 0; i != 6; i++)
        player_ship.shields[i].max += rank >> 1;
}

/* Append the voice clips saying n (0 to 100) to out. */
void SayNumber(char *out, int n)
{
    char buf[64];
    int a;
    int b;

    a = 0;
    b = 0;
    if (n >= 0 && n <= 19)
        a = n + 0xE4;
    if (n >= 20 && n <= 29) {
        a = 0xF8;
        b = n - 20;
    }
    if (n >= 30 && n <= 49) {
        a = 0xF9;
        b = n - 30;
    }
    if (n >= 40 && n <= 49) {
        a = 0xFA;
        b = n - 40;
    }
    if (n >= 50 && n <= 59) {
        a = 0xFB;
        b = n - 50;
    }
    if (n >= 60 && n <= 69) {
        a = 0xFC;
        b = n - 60;
    }
    if (n >= 70 && n <= 79) {
        a = 0xFD;
        b = n - 70;
    }
    if (n >= 80 && n <= 89) {
        a = 0xFE;
        b = n - 80;
    }
    if (n >= 90 && n <= 99) {
        a = 0xFF;
        b = n - 90;
    }
    if (n == 100)
        a = 0x100;
    sprintf(buf, ",brid\\b_%03d", a);
    strcat(out, buf);
    if (b) {
        sprintf(buf, ",brid\\b_%03d", b + 0xE4);
        strcat(out, buf);
    }
}

char *mission_names[7] = {
    "Demon World", "Hijacked", "Love's Labor Jeopardized", "Another Fine Mess",
    "Feathered Serpent", "That Old Devil Moon", "Vengeance"
};
char *text_buf = 0;               /* text from GetText */
Point weapon_pos[4] = { { 0xC4, 0x10 }, { 0xC2, 0x14 }, { 0x5A, 0x10 }, { 0x5C, 0x14 } };
Point engine_pos[2] = { { 0x8C, 0x0D }, { 0x8C, 0x10 } };
int word_45C86[4] = { 0 };

/* The captain's log: points for the recent missions. */
void CaptainsLog(void)
{
    int wait;
    char log[300];
    char buf[20];
    int total;
    int i;

    wait = voc_wait;
    voc_wait = 0;
    if (last_mission == -1)
        MsgBox("Captain's Log", "#BRID\\C_007#No recent missions have been completed.", 0xA0, 0x82, 0xB0, 0);
    else {
        total = 0;
        for (i = last_mission; i != -1; i--)
            total += mission_ranks[i];
        strcpy(log, "#BRID\\C_007#We have earned ");
        if (total != 1)
            sprintf(buf, "%d points ", total);
        else
            strcpy(buf, "1 point ");
        strcat(log, buf);
        strcat(log, "for the following recently completed missions:\n\n");
        for (i = last_mission; i != -1; i--) {
            strcat(log, mission_names[i]);
            if (mission_ranks[i] != 1)
                sprintf(buf, ":  %d points.\n\n", mission_ranks[i]);
            else
                strcpy(buf, ":  1 point.\n\n");
            strcat(log, buf);
        }
        MsgBox("Captain's Log", log, 0xA0, 0x82, 0xB0, 0);
    }
    voc_wait = wait;
}

/* Start a random encounter on the way. */
void StartEncounter(void)
{
    unsigned n;
    int count;

    n = blink_count & 0x7FFF;
    srand(n);
    encounter_kind = rand() % 3 + 1;
    encounter_delay = 10;
    count = n = (rand() & 3) + 1;
    while (n--) {
        switch (encounter_kind) {
        case 1:
            InitShips("klingon");
            break;
        case 2:
            if (rand() & 1)
                InitShips("romulan");
            else
                InitShips("ckling");
            break;
        case 3:
            switch (rand() % 3) {
            case 0:
                InitShips("orion");
                break;
            case 1:
                InitShips("pirate1");
                break;
            case 2:
                InitShips("mpirate");
                break;
            }
            break;
        }
    }
    switch (encounter_kind) {
    case 1:
        SetTextFile("klingon");
        break;
    case 2:
        SetTextFile("romulan");
        break;
    case 3:
        SetTextFile("elasi");
        break;
    }
    under_attack = 1;
    if (count >= 3)
        LoadMusic("bridgeb");
    else
        LoadMusic("bridge");
}

/* Bridge tick during an encounter: the crew's lines, then the hail. */
void EncounterTick(void)
{
    if (encounter_delay > 0) {
        --encounter_delay;
        BridgeMsg();
        return;
    } else if (encounter_delay == 0) {
        char *name;
        char *title;
        char *who;

        --encounter_delay;
        MsgBox(crew_names[5], GetText(0), 0xC4, 0x74, 0xB0, 0);
        MsgBox(crew_names[1], GetText(1), 0x126, 0x6A, 0x2C, 0);
        if (encounter_kind == 1)
            who = crew_names[1];
        else if (encounter_kind == 3)
            who = crew_names[0];
        else
            who = crew_names[4];
        MsgBox(who, GetText(2), 0x7A, 0x74, 0xB0, 0);
        MsgBox(crew_names[7], GetText(3), 0x40, 0x64, 0xA1, 0);
        BridgeSfx(34);
        MsgBox(crew_names[6], GetText(4), 0x12A, 0x96, 0xA1, 0);
        MsgBox(crew_names[0], GetText(5), 0xA0, 0x82, 0xB0, 0);
        title = "Captain";
        switch (encounter_kind) {
        case 1:
            name = "klg1";
            break;
        case 2:
            name = "romula";
            break;
        case 3:
            name = "pira";
            break;
        }
        HailSay(name, title, GetText(6));
        PlayMusic(2, -3);
        BridgeSfx(40);
    } else {
        Msg m;

        m = *PeekMsg();
        if (m.type == 1 && m.arg == 0x20) {
            MsgBox(crew_names[1], GetText(7), 0x126, 0x6A, 0x2C, 0);
            msg_head = (msg_head + 1) % 16;
            return;
        } else if (m.type == 1 && m.arg == 0x40) {
            MsgBox(crew_names[6], GetText(8), 0x12A, 0x96, 0xA1, 0);
            msg_head = (msg_head + 1) % 16;
            return;
        } else {
            if (under_attack == 0) {
                encounter_kind = 0;
                SetTextFile(mission);
                LoadMusic("bridge");
            }
            BridgeMsg();
        }
    }
}

/* Approach the planet: the shuttle flies past. */
void ShuttleFlyby(int kind)
{
    int saved;
    int i;
    long t;
    long unused;
    long dz;

    saved = small_planets;
    ClearShots();
    in_orbit = 1;
    FadeOut();
    ViewFull();
    MemSet(&shot_obj, 2, 0);
    shot_obj.pos.x = dummy_planet.pos.x - 1000;
    shot_obj.pos.y = dummy_planet.pos.y + 1000;
    shot_obj.pos.z = dummy_planet.pos.z - 5000;
    MatIdentity(&shot_obj.orient);
    shot_obj.visible = R3_SHOT;
    shot_obj.kind = kind;
    shot_obj.reach = 250;
    shot_obj.size = 2;
    shot_obj.draw = LoadShotShape;
    shot_obj.free = FreeShotShape;
    AddR3((Obj3D *)&shot_obj);
    MatIdentity(&cam_orient);
    MatIdentity(&player_ship.orient);
    player_ship.pos = shot_obj.pos;
    view_dir = 0;
    StopShip(&player_ship);
    player_ship.pos.z = shot_obj.pos.z - (proj_dist << 1) - 9801;
    dz = 197;
    for (i = 0; i != 100; i++) {
        cam_pos = player_ship.pos;
        t = GetTicks();
        FadeUp();
        RenderR3(0);
        SpriteErase(&mouse_sprite);
        UpdateSprites();
        MatRotYPre(4, &dummy_planet.orient);
        blink_count++;
        while ((unsigned long)t == GetTicks())
            ;
        player_ship.pos.z += dz;
        dz -= 2;
    }
    FadeOut();
    ViewBridge();
    player_ship.pos.z = shot_obj.pos.z - (proj_dist << 1);
    cam_pos = player_ship.pos;
    small_planets = saved;
    RenderR3(0);
    UpdateSprites();
}

void ShuttleEnd(void)
{
    if (shot_obj.visible)
        DelR3((Obj3D *)&shot_obj);
}

/* Play n lines of conversation. */
void SayLines(Line *p, int n)
{
    while (n--) {
        MsgBox(crew_names[p->who], p->text, p->x, p->y, p->c, p->d);
        ++p;
    }
}

/* Show the planet cut-scene picture name.bmp (and say voc). */
void CutScene(char *name, char *voc)
{
    Bitmap far *bmp;

    if (voc)
        word_531D8 = voc;
    RandomPlanet(&dummy_planet);
    PlayMusic(11, -1);
    DigiShutdown();
    PlaySfx("bridloop");
    ViewFull();
    cam_tab1[0][0] = 100;
    cam_tab2[0][0] = 0x7B6;
    cam_tab1[0][1] = 0;
    cam_tab2[0][1] = 0;
    cam_tab1[0][2] = 0;
    cam_tab2[0][2] = 0x2D0;
    cam_tab1[1][0] = 0x7D;
    cam_tab2[1][0] = 0;
    cam_tab1[1][1] = 0;
    cam_tab2[1][1] = 0;
    cam_tab1[1][2] = 0;
    cam_tab2[1][2] = 0;
    MatIdentity(&cam_orient);
    MatIdentity(&player_ship.orient);
    MatRotYPre(256, &player_ship.orient);
    view_dir = -1;
    StopShip(&player_ship);
    kbd_mouse = 0;
    ReleaseBitmap(mouse_sprite.handle);
    SpriteSetBitmap(&mouse_sprite, LoadBitmap("blank"));
    MemSet(&cut_sprite, sizeof(Sprite), 0);
    cut_sprite.x = 160;
    cut_sprite.y = 60;
    cut_sprite.z = 14;
    cut_sprite.handle = CacheLoad(name, "bmp");
    bmp = LockMem(cut_sprite.handle);
    bmp->x = bmp->w / 2;
    bmp->y = bmp->h / 2;
    UnlockMem(cut_sprite.handle);
    bridge_tick = CutSceneTick;
    word_45AA2 = 1;
}

/* The bridge tick during the planet cut-scene. */
void CutSceneTick(void)
{
    Msg m;

    m = *PeekMsg();
    if (m.type == 0) {
        CamFollow(bridge_ticks);
        switch (bridge_ticks) {
        case 2:
            StarsReset();
            break;
        case 0x41:
            if (word_531D8)
                PlayVoc(word_531D8);
            AddSprite(&cut_sprite);
            break;
        case 0x5F:
            SpriteErase(&cut_sprite);
            break;
        case 0x60:
            DelSprite(&cut_sprite);
            break;
        case 0x61:
            CacheRelease(cut_sprite.handle);
            break;
        case 0x69:
            ViewBridge();
            view_dir = 0;
            cam_tab2[1][0] = cam_tab1[1][0] * bridge_ticks;
            cam_tab1[1][0] = player_ship.mo.max_speed >> 18;
            player_ship.mo.target_speed = player_ship.mo.max_speed >> 2;
            break;
        case 0x96:
            bridge_tick = saved_tick;
            word_45AA2 = 0;
            SetSteering(1);
            break;
        }
        BridgeMsg();
    } else
        msg_head = (msg_head + 1) % 16;
}

/* Free the text from GetText. */
void FreeText(char *p)
{
    if (text_buf && (p == 0 || p == text_buf)) {
        FreeMemPtr(text_buf);
        text_buf = 0;
    }
}

/* Use name.txt for GetText. */
void SetTextFile(char *name)
{
    FreeText(0);
    strcpy(text_name, name);
}

/* String n of the current .txt file. */
char *GetText(int n)
{
    char far *p;
    MemHandle h;

    FreeText(0);
    h = CacheLoad(text_name, "txt");
    p = LockMem(h);
    while (n) {
        while (*p++)
            ;
        --n;
    }
    n = _fstrlen(p);
    text_buf = AllocMemPtr(n + 1);
    MemCpy(text_buf, p, n + 1);
    UnlockMem(h);
    CacheRelease(h);
    return text_buf;
}

/* Choice n of list: a copy of its text. */
char *GetChoice(int n, int *list, int x)
{
    int len;
    char *buf;

    if (list[n] == -1)
        return 0;
    if (list[1] == -1)
        ChoiceTitle(x, crew_names[0], 0);
    else
        ChoiceTitle(x, crew_names[0], n + 1);
    len = strlen(GetText(list[n])) + 1;
    FreeText(0);
    buf = AllocMemPtr(len);
    MemCpy(buf, GetText(list[n]), len);
    FreeText(0);
    return buf;
}

void ResetMsgs(void)
{
    msg_head = msg_tail = 0;
    PostRoomMsg(6, 0, 0, 0);
}

/* The weapon, engine and speed gauges. */
void DrawGauges(void)
{
    MemHandle h;
    Bitmap far *bmp;
    int i;

    h = CacheLoad("phasind", "bmp");
    bmp = LockMem(h);
    for (i = 0; i != 4; i++)
        DrawWeaponGauge(&player_ship.systems[i + 2], &player_ship.weapons[i], weapon_pos[i].x, weapon_pos[i].y, bmp, i & 1);
    UnlockMem(h);
    CacheRelease(h);
    for (i = 0; i != 2; i++)
        DrawEngineGauge(&player_ship.systems[i + 8], engine_pos[i].x, engine_pos[i].y);
    DrawSpeedGauges();
}

/* A weapon's charge bar and status light. */
void DrawWeaponGauge(ShipPart *p, Weapon *w, int x, int y, Bitmap far *bmp, int flip)
{
    int sx;
    int sy;
    int len;
    int color;

    sy = 0;
    len = 24;
    if (player_ship.weapons_req == 0) {
        color = 0x81;
        sx = 0;
    } else if (player_ship.weapons_pwr == 0 || p->cur < p->max >> 1) {
        color = 0x81;
        sx = 24;
    } else {
        color = flip + 0xB1;
        if (w->next > blink_count) {
            len = 24 - (w->next - blink_count) * 24 / w->delay;
            sx = 8;
        } else
            sx = 16;
    }
    HLine(x, y, len, color);
    HLine(x + len, y, 24 - len, 0x81);
    if (x > 160)
        sy += 3;
    CopyRect(screen, x + 27, y - 1, bmp, sx, sy, 8, 3);
}

/* An engine's power bar. */
void DrawEngineGauge(ShipPart *p, int x, int y)
{
    int max;
    int color;
    int len;

    max = p->cur;
    if (boost_count)
        max += boost_amount / 2;
    color = boost_count ? 0x69 : 0x81;
    max = min(p->max, max);
    len = (long)max * 34 / p->max;
    HLine(x, y, len, 0xB1);
    HLine(x, y + 1, len, 0xB1);
    HLine(x + len, y, 34 - len, 0x81);
    HLine(x + len, y + 1, 34 - len, 0x81);
    HLine(x + 35, y, 4, color);
    HLine(x + 35, y + 1, 4, color);
}

/* The target and actual speed bars. */
void DrawSpeedGauges(void)
{
    int n;

    n = player_ship.mo.target_speed * 25 / player_ship.mo.max_speed;
    n = max(n, 0);
    HLine(0x8F, 20, n, 0x69);
    HLine(n + 0x8F, 20, 25 - n, 0);
    n = player_ship.mo.speed * 24 / player_ship.mo.max_speed;
    n = max(n, 0);
    HLine(0x90, 22, n, 0xBA);
    HLine(n + 0x90, 22, 24 - n, 0);
}

/* A horizontal line on the background. */
void HLine(int x, int y, int len, int color)
{
    _asm {
        mov cx, len
        or cx, cx
        je done
        push di
        les di, screen
        mov ax, 320
        mul y
        add di, ax
        add di, x
        add di, 8
        mov al, byte ptr color
        rep stosb
        pop di
    done:
    }
}

void ClearMsgs(void)
{
    msg_head = msg_tail = 0;
}
