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
Matrix cam_orient;
extern Vec32 cam_pos;
Sprite view_sprite;
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
extern Actor actors[];

typedef struct Msg {
    unsigned char type;
    unsigned char arg;
    int unk;
} Msg;

extern Msg msg_queue[16];
Msg *PeekMsg(void);
extern char mission[];
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

int full_view = 0;                 /* the view fills the screen */
int magnify = 6;                 /* magnification */
int view_dir = 0;                 /* view direction, -1 forward */
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

void FullViewEnd(void)
{
    DelSprite(&view_sprite);
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

struct {
    BitmapHdr h;
    char data[14];
} blip_bmp = { { 0, 0, 7, 2 } };
struct {
    char name[10];
    int x;
    int y;
} station_menus[8] = {
    { "command", 60, 100 }, { "comp", 200, 30 }, { "", 0, 0 }, { "", 0, 0 },
    { "helm", 60, 70 }, { "nav", 60, 70 }, { "comm", 30, 30 }, { "eng", 30, 30 }
};

void UpdateCrew(void)
{
    if (full_view == 0)
        UpdateActors();
}

void FreeRadar(void)
{
    if (radar_sprite.handle) {
        DelSprite(&radar_sprite);
        FreeMem(radar_sprite.handle);
        radar_sprite.handle = 0;
    }
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

void ViewFull(void)
{
    if (full_view == 0) {
        magnify = 4;
        BridgeScreenEnd();
        FullView();
        full_view = 1;
    }
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

void ShuttleEnd(void)
{
    if (shot_obj.visible)
        DelR3((Obj3D *)&shot_obj);
}

void ClearMsgs(void)
{
    msg_head = msg_tail = 0;
}
