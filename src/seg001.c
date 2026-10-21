/* seg001: the bridge - main loop, view panels, crew, radar, damage
 * display and the bridge menus */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
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
void PostRoomMsg(int msg, char who, char a, char b);     /* seg008: report */
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
int InitShips(char *name);          /* seg020 */
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
void BridgeScreen(int reset);
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
void CycleRange(int first, int count, unsigned char *tab);
void CycleBridge(void);
void SetCursor(void);
extern unsigned char cycle_tab[45];
void InitBlip(void);
void MoveBlip(void);
void FaceEnemy(void);
void FireWeapons(int torps, int phasers);
int Intercept(float a, float b, float c);
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
static Sprite radar_sprite;
static int word_537AE;                         /* the blip's position */
static Matrix cam_rel;
void CrewOrder(int cmd);
void TrackTarget(void);
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
extern char far *screen_base;
void LoadPalette(char *name);
void RepairAll(Obj3D *o);
void Debrief(int n, int msg, int score, int max);
void SayNumber(char *out, int n);
void CaptainsLog(void);
void StartEncounter(void);
void FreeText(char *p);
void SetTextFile(char *name);
char *GetText(int n);
void ShuttleFlyby(char far *name);
void ShuttleEnd(void);
void CutScene(char *name);
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
Matrix cam_orient;
extern Vec32 cam_pos;
Sprite view_sprite;
extern MemHandle space_bmp_handle;
extern BitmapHdr space_bmp;
BitmapHdr bhdr1;
BitmapHdr bhdr2;
BitmapHdr bhdr3;
BitmapHdr bhdr4;
BitmapHdr bhdr5;         /* the view's bitmap header */
extern Rect clip_rect;
extern int view_cx;
extern int view_cy;
extern int key_accel;
extern int btn_key;
extern int arrow_key;
extern long proj_dist;
extern float star_near;
extern int fade_level;
int msg_head;
extern int msg_tail;
Sprite bspr1;
Sprite bspr2;
Sprite bspr3;
Sprite bspr4;
Sprite bspr5;
Sprite bspr6;
extern Actor actors[];

typedef struct Msg {
    unsigned char type;
    unsigned char arg;
    int unk;
} Msg;

extern Msg msg_queue[16];
Msg *PeekMsg(void);
void ActorPos(int i, int x, int y, int z);  /* seg000 */
void LoadSpaceRdf(void);            /* (c2B980) */
extern Obj3D *last_target;
void CycleTarget(int dir);
void CrewSay(int who, char *text);          /* seg008 */
extern char crew_name;
extern char under_attack;               /* (c2B980) */
void FreeSpaceRdf(void);
void LockScreen(void);           /* seg012 */
void UnlockScreen(void);            /* (c2B980) */
extern char mission_name[];
int cam_tab1[2][3];
int cam_tab2[2][3];
extern Obj3D dummy_planet;
extern jmp_buf game_jmp;
extern int voc_wait;
extern int boost_power;
extern int boost_time;
extern Bitmap far *backbuf;
Shot shot_obj;                      /* the fly-by shuttle, drawn as a shot */
extern int small_planets;
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

Obj3D ships[4];

unsigned long bridge_ticks;

Obj3D *last_target;


Sprite cut_sprite;

int bridge_tick;                /* a cutscene is running (ST25: the bridge tick function) */
extern int cut_skip;            /* skip the cutscene */

char *crew_names[8] = {
    "Captain Kirk", "Mr. Spock", "Dr. McCoy", "Security Officer",
    "Mr. Sulu", "Mr. Chekov", "Lieutenant Uhura", "Mr. Scott"
};
unsigned word_3B92E = 0;
int full_view = 0;              /* the view fills the screen */
int kbd_mouse = 0;              /* the pointer steers the ship */
int in_orbit = 0;               /* in orbit */
int word_3B936 = -1;
int magnify = 6;                /* magnification */
int view_dir = 0;               /* view direction, -1 forward */
int combat_level = 0;           /* space combat difficulty; 0x8000 once restarted */
char ship_detail = 1;           /* draw ships in full (off in the intro) */
char byte_3B93F = 0;
Rect top_rects[3] = {
    { 0x5A, 0x0F, 0x7E, 0x15 }, { 0xC2, 0x0F, 0xE6, 0x15 }, { 0x8C, 0x0D, 0xB2, 0x16 }
};
MemHandle word_3B958 = 0;
MemHandle word_3B95A = 0;
MemHandle word_3B95C = 0;
Rect side_rects[2] = { { 0, 0x42, 0x3D, 0x6B }, { 0x101, 0x44, 0x13F, 0x6C } };
MemHandle word_3B96E = 0;
MemHandle word_3B970 = 0;
int word_3B972 = 0;
int auto_target = 0;            /* show the target's status, not ours */
int word_3B976 = 0;
int target_on = 0;              /* weapons locked on targets */
int target_idx = -1;            /* the ship being targeted, or -1 */
int target_lock = 0;            /* frames locked on, up to 50 */

void ClearScreen(void)
{
    LockScreen();
    MemSet(screen->data, 0xFA00, 0xDF);
    UnlockScreen();
    MemSet(mask_buf, 0x7D00, 0);
    RestoreBackground(&screen_rect);
    BlitToScreen(&screen_rect);
    fade_level = 0;
}

Point stations[6] = {
    { 0x3E, 0x79 }, { 0x7D, 0x84 }, { 0xA0, 0xA6 }, { 0xC7, 0x83 }, { 0x11B, 0x7F }, { 0x123, 0xB0 }
};

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
        word_3B976 = full_view;
    kbd_mouse = on;
    ReleaseBitmap(mouse_sprite.handle);
    SetCursor();
    if (on && word_3B976)
        ViewFull();
    else
        ViewBridge();
    mouse_x = (clip_rect.x0 + clip_rect.x1) / 2;
    SpriteSetPos(&mouse_sprite, mouse_x, mouse_y = on ? (clip_rect.y0 + clip_rect.y1) / 2 : 0xA6, 15);
    SetPointer(mouse_x, mouse_y);
    key_accel = on;
}

Vec32 cam_ofs = { -150, 50, -500 };

/* The bridge main loop. */
void BridgeLoop(void)
{
    int unused[3];
    Event ev;
    unsigned full;

    for (;;) {
        while (msg_head != msg_tail)
            if (bridge_tick)
                CutSceneTick();
            else
                EncounterTick();
        if (GetEvent(&ev) == 0)
            continue;
        if (player_ship.expl) {
            if (player_ship.expl_frame == 0) {
                target_idx = -1;
                target_on = target_lock = 0;
                if ((full = full_view) != 0)
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
            PostRoomMsg(0, bridge_ticks, bridge_ticks >> 8, bridge_ticks >> 16);
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
            if (in_orbit == 0 && kbd_mouse && word_3B92E == 0) {
                player_ship.mo.turn_target[1] = (long)(ev.x - view_cx) << 16;
                player_ship.mo.turn_target[0] = (long)(ev.y - view_cy) << 16;
            }
            break;
        case EV_DOWN2:
            if (word_3B92E == 0 && kbd_mouse)
                PostRoomMsg(1, 2, 0, 0);
            break;
        case EV_DOWN1:
            if (word_3B92E == 0) {
                if (kbd_mouse == 0)
                    ClickCrew(ev.x, ev.y);
                else
                    PostRoomMsg(1, 1, 0, 0);
            }
            break;
        case EV_KEY:
            if ((((unsigned)ev.key >> 8) & 0xFF) == 0x19) {
                _getch();
                break;
            }
            if (word_3B92E)
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

void FullView(void)
{
    SetView(2, 2, 319, 199, 512 / magnify);
    if (space_bmp_handle == 0)
        space_bmp_handle = AllocMemHandle(&space_bmp);
    SpriteAddRect(&view_sprite, space_bmp_handle, clip_rect);
    full_view = 1;
    SetFade(cur_palette, fade_level = 100);
}

void FullViewEnd(void)
{
    DelSprite(&view_sprite);
}

void BridgeScreen(int reset)
{
    SetView(72, 30, 247, 102, 512 / magnify);
    if (space_bmp_handle == 0)
        space_bmp_handle = AllocMemHandle(&space_bmp);
    SpriteAddRect(&view_sprite, space_bmp_handle, clip_rect);
    LockScreen();
    LoadFilePacked("bridge", "bgd", screen_base);
    UnlockScreen();
    LoadFilePacked("bridge", "pri", mask_buf);
    MemSet((char far *)0xA0000000L, 0xFA00, 0);
    LoadPalette("palette");
    SetFade(cur_palette, fade_level);
    RestoreBackground(&screen_rect);
    if (reset)
        StartCrew();
    InitBlip();
    if (word_3B958 == 0)
        word_3B958 = AllocMemHandle(&bhdr1);
    if (word_3B95A == 0)
        word_3B95A = AllocMemHandle(&bhdr2);
    if (word_3B95C == 0)
        word_3B95C = AllocMemHandle(&bhdr3);
    SpriteAddRect(&bspr1, word_3B958, top_rects[0]);
    SpriteAddRect(&bspr2, word_3B95A, top_rects[2]);
    SpriteAddRect(&bspr3, word_3B95C, top_rects[1]);
    if (word_3B96E == 0)
        word_3B96E = AllocMemHandle(&bhdr4);
    if (word_3B970 == 0)
        word_3B970 = AllocMemHandle(&bhdr5);
    SpriteAddRect(&bspr4, word_3B96E, side_rects[0]);
    SpriteAddRect(&bspr5, word_3B970, side_rects[1]);
    full_view = 0;
    BlitToScreen(&screen_rect);
    UpdateSprites();
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
    if (reset && in_orbit == 0) {
        CamReset();
        auto_target = 0;
        last_target = 0;
    }
    player_ship.pos = cam_pos;
    player_ship.orient = cam_orient;
    BridgeScreen(reset);
    word_3B976 = 0;
    SetSteering(1);
    LoadSpaceRdf();
}

void BridgeLeave(void)
{
    if (full_view)
        FullViewEnd();
    else
        BridgeScreenEnd();
    kbd_mouse = 0;
    key_accel = 1;
    FreeSpaceRdf();
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
    ActorPos(0, 160, 130, 0);
    ActorPos(1, 294, 106, 0);
    ActorPos(6, 298, 150, 0);
    ActorPos(5, 196, 116, 0);
    ActorPos(4, 122, 116, 0);
    ActorPos(7, 64, 100, 0);
    ActorPos(2, 160, 100, 0);
}

extern char *shape_names[5];        /* seg006 */



void UpdateCrew(void)
{
    if (full_view == 0)
        UpdateActors();
}

unsigned char radar_colors[4] = { 0xB8, 0xC8, 0xA2, 0xB3 };

/* The radar: a dot for each distant ship. */
void DrawRadar(void)
{
    int idx;
    int c;
    int x;
    int y;
    char far *p;
    Bitmap far *bmp;
    int angle;
    int r;
    int i;
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
    p[8 * 17 + 8] = 0x81;
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
        idx = y * 17 + x;
        c = radar_colors[i & 3];
        p[idx] = c;
        if (last_target == o) {         /* new in the sequel: a cross on the target */
            if (x > 0)
                p[idx - 1] = c;
            if (y > 0)
                p[idx - 17] = c;
            if (x < 16)
                p[idx + 1] = c;
            if (y < 16)
                p[idx + 17] = c;
        }
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
    LockScreen();
    DrawGauges();
    if ((blink_count & 3) == 0 || word_3B972 == 1) {
        bspr1.dirty = bspr2.dirty = bspr3.dirty = 1;
        bspr4.dirty = bspr5.dirty = 1;
        sprintf(name, "t%s", shape_names[o->kind]);
        DrawBmp(name);
        sprintf(name, "s%s", shape_names[o->kind]);
        DrawBmp(name);
        p = o->systems;
        for (j = 0; j != 10; ++j, ++p) {
            if (p->cur * 4 < p->max * 3) {
                sprintf(name, "t%s%02d", shape_names[o->kind], j);
                DrawBmp(name);
                sprintf(name, "s%s%02d", shape_names[o->kind], j);
                DrawBmp(name);
            }
        }
        for (p = o->shields, i = 0; i != 6; ++i, ++p) {
            sprintf(name, "%sshd%02d", shape_names[o->kind], i);
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
    UnlockScreen();
}

/* Draw name.bmp onto the background. */
void DrawBmp(char *name)
{
    MemHandle h;
    Bitmap far *bmp;

    h = CacheLoad(name, "bmp");
    bmp = LockMem(h);
    LockScreen();
    CopyRectNZ(screen, -bmp->x, -bmp->y, bmp, 0, 0, bmp->w, bmp->h);
    UnlockScreen();
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

/* The bridge's red alert colours. */
unsigned char cycle_tab[45] = {
    50, 0, 0, 57, 0, 0, 63, 0, 0, 63, 0, 0, 54, 0, 0, 45, 0, 0, 36, 0, 0, 43, 0, 0,
    50, 0, 0, 57, 0, 0, 63, 0, 0, 63, 0, 0, 54, 0, 0, 45, 0, 0, 36, 0, 0
};

/* Cycle count colours from first, from tab (the sequel's palette cycling
 * takes the colours from a table). */
void CycleRange(int first, int count, unsigned char *tab)
{
    int shift;
    int dst;
    int src;
    int i;

    shift = (blink_count >> 1) % count;
    src = shift * 3;
    dst = first * 3;
    for (i = count * 3; i; i--)
        cur_palette[dst++] = tab[src++];
    if (video_mode == 0 && fade_level == 100 && (blink_count & 1) == 0)
        SetPaletteRange(tab + shift * 3, first, count);
}

void CycleBridge(void)
{
    CycleRange(0xD0, 8, cycle_tab);
}

struct {
    BitmapHdr h;
    char data[14];
} blip_bmp = { { 0, 0, 7, 2 } };
MemHandle word_3BAC4 = 0;

/* The blip running along the console. */
void InitBlip(void)
{
    MemSet(blip_bmp.data, sizeof(blip_bmp.data), 0xB0);
    MemSet(&bspr6, sizeof(Sprite), 0);
    AddSprite(&bspr6);
    SpriteSetPos(&bspr6, 0x49, 0x6B, 2);
    if (word_3BAC4 == 0)
        word_3BAC4 = AllocMemHandle(&blip_bmp);
    SpriteSetBitmap(&bspr6, word_3BAC4);
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

void FireWeapons(int torps, int phasers)
{
    int fired;

    if (!WeaponsReady(&player_ship) || player_ship.weapons_pwr == 0)
        return;
    if (target_on && target_lock == 50) {
        /* locked on: lead the target */
        ShipPart *p;
        Obj3D *o;
        Vec32 d;
        Vec32 v;
        Vec32 aim;
        float a;
        float b;
        float c;
        float s;
        int t;
        int i;

        o = &ships[target_idx];
        p = &player_ship.systems[SYS_TORP_PORT];
        MemCpy(&d, &o->pos, sizeof(d));
        Vec32Sub(&d, &player_ship.pos);
        v.x = o->vx - player_ship.vx;
        v.y = o->vy - player_ship.vy;
        v.z = o->vz - player_ship.vz;
        a = (float)(v.y * v.y) + (float)(v.z * v.z) + (float)v.x * v.x;
        b = (v.y * d.y + v.z * d.z + v.x * d.x) * 2.0;
        c = (float)(d.y * d.y) + (float)(d.z * d.z) + (float)d.x * d.x;
        if (torps) {
            s = player_ship.weapons[0].speed;
            if ((t = Intercept(a - s * s, b, c)) > 0) {
                for (i = 0; i != 3; i++)
                    (&aim.x)[i] = (&v.x)[i] * t;
                Vec32Add(&aim, &d);
                fired = FireShot(&player_ship, &player_ship.weapons[0], &aim, p);
                fired |= FireShot(&player_ship, &player_ship.weapons[1], &aim, p + 1);
                if (fired)
                    BridgeSfx(5);
            }
        }
        if (phasers) {
            s = player_ship.weapons[2].speed;
            if ((t = Intercept(a - s * s, b, c)) > 0) {
                for (i = 0; i != 3; i++)
                    (&aim.x)[i] = (&v.x)[i] * t;
                Vec32Add(&aim, &d);
                fired = FireShot(&player_ship, &player_ship.weapons[2], &aim, p + 2);
                fired |= FireShot(&player_ship, &player_ship.weapons[3], &aim, p + 3);
                if (fired)
                    BridgeSfx(4);
            }
        }
    } else {
        ShipPart *p;
        Vec32 v;
        Vec32 dir;
        Matrix m;

        p = &player_ship.systems[SYS_TORP_PORT];
        v.x = arrow_key ? 0 : mouse_x - view_cx;
        v.y = arrow_key ? 0 : view_cy - mouse_y;
        v.z = proj_dist;
        MatTranspose(&player_ship.orient, &m);
        MatTVecMul32(&v, &player_ship.orient, &dir);
        if (torps) {
            fired = FireShot(&player_ship, &player_ship.weapons[0], &dir, p);
            fired |= FireShot(&player_ship, &player_ship.weapons[1], &dir, p + 1);
            if (fired)
                BridgeSfx(5);
        }
        if (phasers) {
            fired = FireShot(&player_ship, &player_ship.weapons[2], &dir, p + 2);
            fired |= FireShot(&player_ship, &player_ship.weapons[3], &dir, p + 3);
            if (fired)
                BridgeSfx(4);
        }
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

    kbd = kbd_mouse;
    x0 = mouse_x;
    y0 = mouse_y;
    bmp = mouse_sprite.handle;
    kbd_mouse = 0;
    SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
    BridgeSfx(2);
    LoadMenu(name, x, y);
    MenuHome();
    r = MenuLoop(0, 0);
    MenuClose();
    if (r >= 0)
        PostRoomMsg(1, r, 0, 0);
    kbd_mouse = kbd;
    ReleaseBitmap(mouse_sprite.handle);
    SpriteSetBitmap(&mouse_sprite, bmp);
    if (r >= 0 || r == -2) {
        mouse_x = x0;
        mouse_y = y0;
        SpriteSetPos(&mouse_sprite, mouse_x, mouse_y, 15);
        SetPointer(mouse_x, mouse_y);
    } else if (r == -1) {
        Event ev;

        ev.type = EV_DOWN1;
        ev.x = mouse_x;
        ev.y = mouse_y;
        PostEvent(&ev);
    }
}

/* The menu of the crew member at each station. */
struct {
    char name[10];
    int x;
    int y;
} station_menus[8] = {
    { "mnukirk", 60, 100 }, { "mnuspock", 200, 30 }, { "", 0, 0 }, { "", 0, 0 },
    { "mnusulu", 76, 43 }, { "mnucheko", 60, 70 }, { "mnuuhura", 182, 75 }, { "mnuscott", 30, 30 }
};

/* Click on the bridge: open the menu of the crew member there. */
void ClickCrew(int x, int y)
{
    Sprite *s;
    Actor *a;
    int i;

    if ((s = SpriteAt(x, y, 0)) != 0) {
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

    k = (unsigned)e.key >> 8;
    switch (k) {
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
    case 15:
        if (crew_name == 0) {
            SetSteering(kbd_mouse == 0);
            ClampPointer();
        }
        break;
    case 17:
        PostRoomMsg(1, 0x61, 0, 0);
        break;
    case 18:
        PostRoomMsg(1, 0x31, 0, 0);
        break;
    case 19:
        PostRoomMsg(1, 0x10, 0, 0);
        break;
    case 20:
        PostRoomMsg(1, 0x20, 0, 0);
        break;
    case 23:
        PostRoomMsg(1, 0x12, 0, 0);
        break;
    case 24:
        PostRoomMsg(1, 0x51, 0, 0);
        break;
    case 26:
        CycleTarget(-1);
        break;
    case 27:
        CycleTarget(1);
        break;
    case 28:
    case 59:
        if (kbd_mouse)
            PostRoomMsg(1, 1, 0, 0);
        break;
    case 30:
        PostRoomMsg(1, 0x22, 0, 0);
        break;
    case 31:
        PostRoomMsg(1, 0x52, 0, 0);
        break;
    case 32:
        PostRoomMsg(1, 0x30, 0, 0);
        break;
    case 35:
        PostRoomMsg(1, 0x40, 0, 0);
        break;
    case 37:
        PostRoomMsg(1, 0, 0, 0);
        break;
    case 38:
        PostRoomMsg(1, 0x62, 0, 0);
        break;
    case 41:
        if (in_orbit == 0)
            player_ship.mo.target_speed = -player_ship.mo.max_speed >> 3;
        break;
    case 46:
        PostRoomMsg(1, 0x21, 0, 0);
        break;
    case 47:
        PostRoomMsg(1, 3, 0, 0);
        break;
    case 48:
        PostRoomMsg(1, 0x11, 0, 0);
        break;
    case 49:
        PostRoomMsg(1, 0x60, 0, 0);
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
        CrewSay(4, buf);
        if (full_view)
            SetView(2, 2, 319, 199, 512 / magnify);
        else
            SetView(72, 30, 247, 102, 512 / magnify);
        break;
    case 57:
    case 60:
        if (kbd_mouse)
            PostRoomMsg(1, 2, 0, 0);
        break;
    case 61:                    /* F3-F8: the view direction */
    case 62:
    case 63:
    case 64:
    case 65:
    case 66:
        view_dir = k - 61;
        break;
    case 76:
        player_ship.mo.turn_target[0] = player_ship.mo.turn_target[1] = player_ship.mo.turn_target[2] = 0;
        if (kbd_mouse) {
            mouse_x = (clip_rect.x0 + clip_rect.x1) / 2;
            SpriteSetPos(&mouse_sprite, mouse_x,
                         mouse_y = (clip_rect.y0 + clip_rect.y1) / 2, 15);
            SetPointer(mouse_x, mouse_y);
        }
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
            CrewSay(7, "#brid_s45#The shields are falling!");
        else
            break;
    case 3:
        if (m.arg == 0 && player_ship.expl == 0)
            CrewSay(7, "#brid_s37#Our weapons are off-line!");
        break;
    case 4:
        if (m.arg == 0 && player_ship.expl == 0)
            CrewSay(7, "#brid_s47#We can't maintain our speed!");
        break;
    case 5: {
        static struct {
            int sys;
            char *name;
        } repair_names[7] = {
            { 0xFF, "#scotshie#Shields" }, { 0, "#scothull#Hull" },
            { 1, "#scotbrid#Bridge" }, { 6, "#scotsens#Sensors" },
            { 2, "#scottorp#Torpedoes" }, { 4, "#scotphas#Phasers" },
            { 7, "#scotengi#Engines" }
        };

        for (i = 0; i != 7; i++)
            if (repair_names[i].sys == m.arg) {
                sprintf(buf, "%s repaired, Captain.", repair_names[i].name);
                CrewSay(7, buf);
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
        TrackTarget();
        if ((blink_count & 0x3F) == 0)
            OrthoR3();
        SetViewDir();
        i = rand() % player_ship.systems[SYS_SENSORS].max > player_ship.systems[SYS_SENSORS].cur;
        RenderR3(i);
        mouse_sprite.dirty = 1;
        if (full_view == 0) {
            DrawRadar();
            if (auto_target == 0)
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
            CycleBridge();
            FadeUp();
        }
        word_3B972 = 0;
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

/* The camera for view_dir. New in the sequel: view 6 trails the ship
 * (the camera is 40 frames behind), and is aimed with the pointer first. */
typedef struct TrailPos {
    Vec32 pos;
    Matrix orient;
} TrailPos;

MemHandle trail_handle = 0;
int trail_pos = -1;             /* in the trail, -1 not started */

void SetViewDir(void)
{
    Vec a;
    Vec b;
    int n;

    if (view_dir == -1)
        return;
    cam_pos = player_ship.pos;
    cam_orient = player_ship.orient;
    MemSet(&a, sizeof(a), 0);
    MemSet(&b, sizeof(b), 0);
    if (view_dir == 6 && trail_pos == -1) {
        Event ev;
        int done;
        int pitch;
        int yaw;
        int roll;

        if ((trail_handle = AllocMem(0x4B0, 1)) == 0)
            view_dir = 0;
        ViewFull();
        SetSteering(1);
        done = 0;
        do {
            if (GetEvent(&ev)) {
                switch (ev.type) {
                case EV_TICK:
                    if (in_orbit == 0) {
                        if (btn_key == 0x52)
                            roll = player_ship.mo.turn_max >> 16;
                        else if (btn_key == 0x53)
                            roll = -player_ship.mo.turn_max >> 16;
                    }
                    MatRotXPre(pitch, &cam_orient);
                    MatRotYPre(yaw, &cam_orient);
                    MatRotZPre(roll, &cam_orient);
                    roll = 0;
                    cam_pos = player_ship.pos;
                    for (n = 0; n != 3; n++)
                        (&cam_pos.x)[n] -= cam_orient.e[2][n] >> 4;
                    RenderR3(0);
                    UpdateSprites();
                    break;
                case EV_MOVE:
                    ClampPointer();
                    yaw = (ev.x - view_cx) >> 3;
                    pitch = (ev.y - view_cy) >> 2;
                    break;
                case EV_KEY:
                    switch ((unsigned)ev.key >> 8) {
                    case 0x1C:
                    case 0x39:
                        done = 1;
                    }
                    break;
                case EV_DOWN1:
                case EV_DOWN2:
                    done = 1;
                    break;
                }
            }
        } while (!done);
    } else if (view_dir != 6 && trail_pos != -1) {
        FreeMem(trail_handle);
        trail_pos = -1;
    }
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
    case 6: {
        TrailPos far *t;

        t = LockMem(trail_handle);
        if (trail_pos == -1) {
            Matrix mt;
            TrailPos far *q;

            MatTranspose(&player_ship.orient, &mt);
            MatMul(&cam_orient, &mt, &cam_rel);
            for (q = t + 1, n = 39; n; n--, q++) {
                q->pos = cam_pos;
                q->orient = cam_orient;
            }
            trail_pos = 0;
        } else {
            MatMul(&cam_rel, &player_ship.orient, &cam_orient);
            for (n = 0; n != 3; n++)
                (&cam_pos.x)[n] -= cam_orient.e[2][n] >> 4;
        }
        t[trail_pos].pos = cam_pos;
        t[trail_pos].orient = cam_orient;
        trail_pos = (trail_pos + 1) % 40;
        cam_pos = t[trail_pos].pos;
        cam_orient = t[trail_pos].orient;
        UnlockMem(trail_handle);
        break;
    }
    }
}

void CrewOrder(int cmd)
{
    Obj3D *o;

    switch (cmd) {
    case 0x62:                  /* lock the weapons on a target */
        if (target_on ^= 1) {
            if (under_attack) {
                player_ship.weapons_req = 1;
                SetPower(player_ship.shields_req, 1);
                CrewSay(5, "#chk_001#Our weapons, are locked, Keptin.");
            } else {
                target_on = 0;
                CrewSay(5, "#chk_002#I do not think that would have any effect, Keptin.");
            }
        } else
            CrewSay(5, "#chk_003#Yes, Keptin.");
        target_lock = 0;
        target_idx = -1;
        break;
    case 0x50:
        if (in_orbit)
            CrewSay(4, "#B_349#We must first leave orbit, Sir.");
        else
            CrewMenu("mnuspeed", 60, 100);
        break;
    case 0x53:
        CrewMenu("mnuview", 60, 100);
        break;
    case 0x54:
        CrewMenu("mnulook", 60, 100);
        break;
    case 0x55:
        CrewMenu("mnumagn", 60, 100);
        break;
    case 0:
        CrewMenu("mnukirk", 60, 100);
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
        if (crew_name)
            break;
        if (full_view)
            ViewBridge();
        else {
            ViewFull();
            SetSteering(1);
        }
        break;
    case 0x10:
        CaptainsLog();
        break;
    case 0x12:
        OptionsMenu(160, 25);
        break;
    case 0x21:
        Computer();
        break;
    case 0x22:
        if (auto_target ^= 1) {
            CrewSay(4, "#b_344#Target Analysis On.");
            last_target = 0;
            if (target_idx != -1)
                last_target = &ships[target_idx];
            else
                for (o = ships; o != &ships[4]; o++)
                    if (o->visible && o->shields_on == 0) {
                        last_target = o;
                        break;
                    }
        } else {
            CrewSay(4, "#b_343#Target Analysis Off.");
            last_target = 0;
        }
        break;
    case 0x30:
        CrewMenu("mnudmgc", 30, 30);
        break;
    case 0x31:
        if (in_orbit)
            CrewSay(4, "#b_349#We must first leave orbit, Sir.");
        else if (BoostStart())
            CrewSay(7, "#BRID_S41#She can't take it, Captain.");
        else
            CrewSay(7, "#BRID_S32#I don't know how long she can take it, Captain.");
        break;
    case 0x52:
        if (player_ship.shields_req ^= 1)
            CrewSay(4, "#b_340#Raising shields.");
        else
            CrewSay(4, "#b_337#Lowering shields.");
        break;
    case 0x56:
        if (full_view == 0 && crew_name == 0) {
            ViewFull();
            SetSteering(1);
        }
        break;
    case 0x61:
        if (player_ship.weapons_req ^= 1)
            CrewSay(5, "#b_351#Arming weapons.");
        else
            CrewSay(5, "#b_354#Disarming weapons.");
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
    case 0x80:                  /* the view menu */
        view_dir = 2;
        break;
    case 0x81:
        view_dir = 3;
        break;
    case 0x82:
        view_dir = 0;
        break;
    case 0x83:
        view_dir = 1;
        break;
    case 0x84:
        view_dir = 4;
        break;
    case 0x85:
        view_dir = 5;
        break;
    case 0x90:                  /* the magnification menu */
    case 0x91:
    case 0x92:
    case 0x93:
    case 0x94:
        magnify = cmd - 0x8C;
        if (full_view)
            SetView(2, 2, 319, 199, 512 / magnify);
        else
            SetView(72, 30, 247, 102, 512 / magnify);
        break;
    case 0xA0:                  /* the speed menu */
        if (in_orbit == 0)
            player_ship.mo.target_speed = -player_ship.mo.max_speed >> 3;
        break;
    case 0xA1:
    case 0xA2:
    case 0xA3:
    case 0xA4:
    case 0xA5:
    case 0xA6:
    case 0xA7:
    case 0xA8:
    case 0xA9:
    case 0xAA:
        if (in_orbit == 0)
            player_ship.mo.target_speed = (cmd - 0xA1) * player_ship.mo.max_speed / 9;
        break;
    }
}

int StarMapGo(void)
{
    int r;

    FadeOut();
    ViewFull();
    kbd_mouse = 0;
    key_accel = 1;
    r = StarMap();
    ViewBridge();
    SetSteering(1);
    return r;
}

/* New in the sequel: another full-screen view (unidentified). */
void sub_14492(void)
{
    FadeOut();
    ViewFull();
    sub_2A546();
    ViewBridge();
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
        BridgeScreen(1);
        full_view = 0;
    }
    if (view_dir == 6)
        view_dir = 0;
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

/* Where the landing party appears on the transporter pads. */
Point beam_pos[5] = { { 0x8E, 0x7C }, { 0xBE, 0x7C }, { 0x7E, 0x72 }, { 0xAA, 0x72 }, { 0x61, 0x79 } };

/* Beam the landing party (the actors flagged for it) to name's room. */
void Transport(char *name)
{
    int i;
    Actor *a;
    int n;
    int sfx;
    int wait;
    Event ev;

    FadeOut();
    FreeActors();
    LockScreen();
    LoadFilePacked("transprt", "bgd", screen_base);
    MemCpy(backbuf->data, screen->data, 0xFA00);
    UnlockScreen();
    MemSet(mask_buf, 0x7D00, 0);
    LoadPalette("palette");
    BlitToScreen(&screen_rect);
    for (i = 0, a = actors, n = 0; i != 32; i++, a++)
        if ((a->flags & 1) == 1) {
            StartAnim(i, name, beam_pos[n].x, beam_pos[n].y, 256);
            if (++n >= 5)
                break;
        }
    StartAnim(9, "transc", 0, 0, 256);
    SpriteErase(&mouse_sprite);
    SpriteErase(&bspr6);
    UpdateSprites();
    FadeIn();
    BridgeSfx(5);
    for (i = -1; i != 8; )
        if (GetEvent(&ev) && ev.type == EV_TICK) {
            i++;
            MusicTick();
        }
    sfx = stricmp(name, "?teled") == 0 ? 4 : 6;
    wait = sfx == 4 ? 25 : 0;
    i = -1;
    while (actors[0].loops == 0)
        if (GetEvent(&ev)) {
            switch (ev.type) {
            case EV_TICK:
                blink_count++;
                UpdateActors();
                SpriteErase(&mouse_sprite);
                SpriteErase(&bspr6);
                UpdateSprites();
                MusicTick();
                if (++i == wait)
                    BridgeSfx(sfx);
                break;
            }
        }
    SpriteErase(&bspr6);
    UpdateSprites();
    FadeOut();
    FreeActors();
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



/* Approach the planet: the shuttle flies past. */
void ShuttleFlyby(char far *name)
{
    int i;
    long t;
    long dz;

    ClearShots();
    in_orbit = 1;
    FadeOut();
    ViewFull();
    MemSet(&shot_obj, 2, 0);
    MatIdentity(&shot_obj.orient);
    shot_obj.visible = R3_SHOT;
    shot_obj.kind = 4;
    _fstrncpy(shot_obj.shape, name, 10);
    shot_obj.shape[9] = 0;
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
    RenderR3(0);
    UpdateSprites();
}

void ShuttleEnd(void)
{
    if (shot_obj.visible)
        DelR3((Obj3D *)&shot_obj);
}

/* Show the planet cut-scene picture name.bmp (and say voc). */
void CutScene(char *name)
{
    Bitmap far *bmp;

    PlayMusic(12, -1);
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
    cut_sprite.handle = CacheLoadEMS(name, "bmp");
    bmp = LockMem(cut_sprite.handle);
    bmp->x = bmp->w / 2;
    bmp->y = bmp->h / 2;
    UnlockMem(cut_sprite.handle);
    bridge_tick = 1;
    word_3B92E = 1;
}

/* Run a cutscene to its end: the camera script on each tick, skipping
 * ahead (as fast as it can) once a key or button is pressed. New in the
 * sequel, which runs it as a loop of its own. */
void CutSceneTick(void)
{
    Event ev;

    ClearMsgs();
    bridge_ticks = 0;
    for (;;) {
        while (GetEvent(&ev) == 0)
            ;
        if (ev.type == EV_TICK) {
            blink_count++;
            bridge_ticks++;
            PostRoomMsg(0, 0, 0, 0);
            do {
                CamFollow(bridge_ticks);
                switch (bridge_ticks) {
                case 1:
                    StarsReset();
                    break;
                case 0x41:
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
                    SetFade(cur_palette, fade_level = 0);
                    ViewBridge();
                    cam_tab2[1][0] = cam_tab1[1][0] * bridge_ticks;
                    cam_tab1[1][0] = player_ship.mo.max_speed >> 18;
                    player_ship.mo.target_speed = player_ship.mo.max_speed >> 2;
                    word_3B92E = bridge_tick = view_dir = 0;
                    SetSteering(1);
                    cut_skip = 0;
                    bridge_ticks = 0;
                    return;
                }
                if (cut_skip)
                    bridge_ticks++;
            } while (cut_skip);
            BridgeMsg();
        } else if (ev.type == EV_KEY || ev.type == EV_UP1 || ev.type == EV_UP2)
            cut_skip = 1;
    }
}

int cut_skip = 0;
Point weapon_pos[4] = { { 0xC4, 0x10 }, { 0xC2, 0x14 }, { 0x5A, 0x10 }, { 0x5C, 0x14 } };
Point engine_pos[2] = { { 0x8C, 0x0D }, { 0x8C, 0x10 } };
int word_3BEC0[4] = { 0 };

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
        color = 0xDE;
        sx = 0;
    } else if (player_ship.weapons_pwr == 0 || p->cur < p->max >> 1) {
        color = 0xDE;
        sx = 24;
    } else {
        color = flip ? 0xB2 : 0xB1;
        if (w->next > blink_count) {
            len = 24 - (w->next - blink_count) * 24 / w->delay;
            sx = 8;
        } else
            sx = 16;
    }
    HLine(x, y, len, color);
    HLine(x + len, y, 24 - len, 0xDE);
    if (x > 160)
        sy += 3;
    LockScreen();
    CopyRect(screen, x + 27, y - 1, bmp, sx, sy, 8, 3);
    UnlockScreen();
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
    color = boost_count ? 0xA2 : 0xDE;
    max = min(p->max, max);
    len = (long)max * 34 / p->max;
    HLine(x, y, len, 0xB1);
    HLine(x, y + 1, len, 0xB1);
    HLine(x + len, y, 34 - len, 0xDE);
    HLine(x + len, y + 1, 34 - len, 0xDE);
    HLine(x + 35, y, 4, color);
    HLine(x + 35, y + 1, 4, color);
}

/* The target and actual speed bars. */
void DrawSpeedGauges(void)
{
    int n;

    n = player_ship.mo.target_speed * 25 / player_ship.mo.max_speed;
    n = max(n, 0);
    HLine(0x8F, 20, n, 0xA2);
    HLine(n + 0x8F, 20, 25 - n, 0xDF);
    n = player_ship.mo.speed * 24 / player_ship.mo.max_speed;
    n = max(n, 0);
    HLine(0x90, 22, n, 0xBA);
    HLine(n + 0x90, 22, 24 - n, 0xDF);
}

/* A horizontal line on the background. */
void HLine(int x, int y, int len, int color)
{
    LockScreen();
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
    UnlockScreen();
}

void ClearMsgs(void)
{
    msg_head = msg_tail = 0;
}

/* When a shot of the given speed meets a target: the smallest positive
 * root of a t^2 + b t + c, or -1. New in the sequel. */
int Intercept(float a, float b, float c)
{
    float t;
    float t2;
    float d;
    float den;
    float t1;

    d = b * b - 4.0 * a * c;
    if (d < 0)
        return -1;
    d = sqrt(d);
    t = t1 = (-b - d) / (den = 2 * a);
    t2 = (d - b) / den;
    if (t1 > 0)
        return t;
    if (t2 > 0)
        return t2;
    return -1;
}

#define LABS(v) ((v) < 0 ? -(v) : (v))

/* Keep the lock on the target while it stays ahead (up to 50 frames
 * locked), else pick the first ship ahead. New in the sequel. */
void TrackTarget(void)
{
    Matrix m;
    Vec32 v;
    Vec32 r;
    int i;

    if (target_on == 0)
        return;
    if (target_idx != -1 && ships[target_idx].visible && ships[target_idx].shields_on == 0) {
        MatTranspose(&player_ship.orient, &m);
        MemCpy(&v, &ships[target_idx].pos, sizeof(v));
        Vec32Sub(&v, &player_ship.pos);
        MatTVecMul32(&v, &m, &r);
        if (r.z > 0 && LABS(r.x) <= r.z && LABS(r.y) <= r.z) {
            target_lock = min(target_lock + 1, 50);
            return;
        }
        target_lock = 0;
        target_idx = -1;
        return;
    }
    target_lock = 0;
    MatTranspose(&player_ship.orient, &m);
    for (i = 0; i != 4; i++) {
        if (ships[i].visible && ships[i].shields_on == 0) {
            MemCpy(&v, &ships[i].pos, sizeof(v));
            Vec32Sub(&v, &player_ship.pos);
            MatTVecMul32(&v, &m, &r);
            if (r.z > 0 && LABS(r.x) <= r.z && LABS(r.y) <= r.z)
                goto found;
        }
    }
    return;
found:
    target_lock = 0;
    target_idx = i;
    if (auto_target)
        last_target = &ships[i];
}

/* PgUp/PgDn: the next ship ahead in direction dir. New in the sequel. */
void CycleTarget(int dir)
{
    int saved;
    Matrix m;
    Vec32 v;
    Vec32 r;
    int n;
    int i;

    saved = target_lock;
    target_lock = 0;
    MatTranspose(&player_ship.orient, &m);
    if (target_idx == -1)
        i = 0;
    else
        i = (dir + target_idx) % 4;
    for (n = 0; n != 4; n++) {
        if (ships[i].visible && ships[i].shields_on == 0) {
            MemCpy(&v, &ships[i].pos, sizeof(v));
            Vec32Sub(&v, &player_ship.pos);
            MatTVecMul32(&v, &m, &r);
            if (r.z > 0 && LABS(r.x) <= r.z && LABS(r.y) <= r.z)
                goto found;
        }
        i = (dir + i) % 4;
    }
    return;
found:
    if (target_idx == i) {
        target_lock = saved;
        return;
    }
    target_idx = i;
    if (auto_target)
        last_target = &ships[i];
}

/* The pointer: crosshairs when steering (with weapons) or blank. */
void SetCursor(void)
{
    if (kbd_mouse) {
        if (crew_name)
            SpriteSetBitmap(&mouse_sprite, LoadBitmap("blank"));
        else
            SpriteSetBitmap(&mouse_sprite, LoadBitmap(player_ship.weapons_req ? "cursor" : "entcur"));
    } else
        SpriteSetBitmap(&mouse_sprite, LoadBitmap("pushbtn"));
}

