/* seg036: the bridge script for the last mission, "Vengeance" (the
 * Enterprise's sister ship Republic), the final rating and the credits */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "mem.h"
#include "cache.h"
#include "event.h"
#include "gfx.h"
#include "sound.h"
#include "sprite.h"
#include "fixmath.h"
#include "obj3d.h"

typedef struct Msg {
    unsigned char type;
    unsigned char arg;
    unsigned char b2;
    unsigned char b3;
} Msg;

/* seg001 */
void BridgeSfx(int n);
void BridgeMsg(void);
Msg *PeekMsg(void);
char *GetText(int n);
void SetTextFile(char *name);
void CutScene(char *name, char *voc);
void SetSteering(int on);
void ClearScreen(void);
void HailShow(char *name);
void HailEnd(void);
void ViewFull(void);
void ViewBridge(void);
void Debrief(int n, int msg, int score, int max);
void SayNumber(char *out, int n);
void ShuttleFlyby(int kind);
void ShuttleEnd(void);
void ClearMsgs(void);
char *GetChoice(int n, int *list, int x);
/* seg008 */
void MsgBox(char *title, char *text, int x, int y, int color, int msg);
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
long TextBox(char *(far *fn)(), int *arg, int x, int y, int color, int choice, int maxl,
             int flag);
/* seg000 */
int StartAnim(int n, char *name, int x, int y, int scale);
/* seg017 */
void AddR3(Obj3D *o);
void DelR3(Obj3D *o);
void RenderR3(int statics);
/* seg016 */
void PlaceObj(Obj3D *o, int a0, int r0, int a1, int r1, int frames);
/* seg015 */
void RandomPlanet(Obj3D *o);
/* seg020 */
void BoostEnd(void);
void InitShips(char *name);
/* seg023 */
void StarsReset(void);
/* seg025 */
void WarpOut(void);
/* seg018 */
void GameOverMenu(void);

void VengArrive(void);
void VengFinale(void);
void AdmiralVerdict(char *text);
void EndKirk(void);
void EndSpock(void);
void EndMcCoy(void);
void Credits(void);
int CreditsFly(Obj3D *o, int n);

extern char *crew_names[8];
extern int word_45AA2;
extern int kbd_mouse;
extern int in_orbit;
extern int under_attack;
extern void (far *bridge_tick)(void);
extern int word_45AB2;
extern int word_45AB4;
extern Matrix cam_orient;
extern int msg_head;
extern int word_50CA6;
extern unsigned long bridge_ticks;
extern int mission_vars[6];
extern Obj3D dummy_planet;
extern void (far *saved_tick)(void);
extern int word_52C1E;
extern int mission_ranks[7];
extern Obj3D player_ship;
extern Vec32 cam_pos;
extern long proj_dist;
extern char mission[16];

char bredell[] = "Bredell";
int bredell_choices1[] = { 0, 1, -1 };
int bredell_choices2[] = { 2, 3, -1 };
int bredell_choices3[] = { 4, 5, 6, -1 };
int bredell_choices4[] = { 7, 8, 9, -1 };

/* Arriving: the fly-by, the Republic's crew, then Bredell's Elasi ship. */
void VengArrive(void)
{
    Msg m;
    int r;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            LoadMusic("bridgew");
            word_45AB4 = word_45AB2;
            BoostEnd();
            strcpy(mission, "veng");
            SetTextFile(mission);
            MemSet(mission_vars, 12, 0);
            saved_tick = VengArrive;
            CutScene("vengence", "VEN0\\FLYBY");
            break;
        case 0x97:
            MsgBox(crew_names[0], GetText(10), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(11), 0x126, 0x6A, 0x2C, 0);
            ShuttleFlyby(7);
            MsgBox(crew_names[0], GetText(12), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[6], GetText(13), 0x12A, 0x96, 0xA1, 0);
            r = TextBox(GetChoice, bredell_choices1, 0xA0, 0x82, 0xB0, 1, 0, 0);
            in_orbit = 1;
            PostRoomMsg(1, 0x11, 0, 0);
            break;
        }
        BridgeMsg();
        return;
    } else {
        if (m.type == 1 && m.arg == 0x11) {
            BridgeMsg();
            return;
        }
        if (m.type == 6) {
            mission_vars[0] = word_50CA6;
            mission_vars[1] = word_52C1E;
            in_orbit = 0;
            ViewFull();
            kbd_mouse = 0;
            ShuttleEnd();
            WarpOut();
            RandomPlanet(&dummy_planet);
            ViewBridge();
            SetSteering(1);
            StartAnim(2, "xstndmc", 0, 0, 256);
            RenderR3(0);
            UpdateSprites();
            player_ship.mo.target_speed = player_ship.mo.max_speed;
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[0], GetText(14), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(15), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[0], GetText(16), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(17), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[1], GetText(18), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[6], GetText(19), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[1], GetText(20), 0x126, 0x6A, 0x2C, 0);
            r = TextBox(GetChoice, bredell_choices2, 0xA0, 0x82, 0xB0, 1, 0, 0);
            if (r == 0) {
            talk:
                HailShow("maddoc");
                MsgBox(bredell, GetText(21), 0xA0, 0xBE, 0x2C, -7);
                MsgBox(crew_names[0], GetText(22), 0xA0, 0x82, 0xB0, 0);
                MsgBox(bredell, GetText(23), 0xA0, 0xBE, 0x2C, -7);
                r = TextBox(GetChoice, bredell_choices3, 0xA0, 0x82, 0xB0, 1, 0, 0);
                if (r == 0) {
                    MsgBox(bredell, GetText(24), 0xA0, 0xBE, 0x2C, -7);
                    MsgBox(crew_names[0], GetText(25), 0xA0, 0x82, 0xB0, 0);
                    MsgBox(bredell, GetText(26), 0xA0, 0xBE, 0x2C, -7);
                    MsgBox(crew_names[0], GetText(27), 0xA0, 0x82, 0xB0, 0);
                    MsgBox(bredell, GetText(28), 0xA0, 0xBE, 0x2C, -7);
                    r = TextBox(GetChoice, bredell_choices4, 0xA0, 0x82, 0xB0, 1, 0, 0);
                    MsgBox(bredell, GetText(29), 0xA0, 0xBE, 0x2C, -7);
                } else if (r == 1)
                    MsgBox(bredell, GetText(30), 0xA0, 0xBE, 0x2C, -7);
                else
                    MsgBox(bredell, GetText(31), 0xA0, 0xBE, 0x2C, -7);
                InitShips("vardain");
                under_attack = 1;
                HailEnd();
                bridge_tick = VengFinale;
                bridge_ticks = 0;
                PlayMusic(2, -3);
                BridgeSfx(0x28);
            } else {
                MsgBox(crew_names[4], GetText(32), 0x7A, 0x74, 0xB0, 0);
                BridgeSfx(0x22);
                MsgBox(crew_names[6], GetText(33), 0x12A, 0x96, 0xA1, 0);
                goto talk;
            }
        } else
            msg_head = (msg_head + 1) % 16;
    }
}

/* The fight; once it's won, the final debriefing, Starfleet's rating of
 * the whole game, and the credits. */
void VengFinale(void)
{
    Msg m;
    int i;
    int sum;
    int pct;
    char *text;
    char num[128];

    m = *PeekMsg();
    if (m.type == 0 && bridge_ticks == 300 && under_attack) {
        BridgeSfx(0x28);
        MsgBox(crew_names[1], GetText(34), 0x126, 0x6A, 0x2C, 0);
        InitShips("3PIRATE");
        InitShips("orion");
    }
    if (m.type == 1 && m.arg == 0x20) {
        MsgBox(crew_names[1], GetText(35), 0x126, 0x6A, 0x2C, 0);
        msg_head = (msg_head + 1) % 16;
        return;
    }
    if (m.type == 1 && m.arg == 0x40) {
        MsgBox(crew_names[6], GetText(36), 0x12A, 0x96, 0xA1, 0);
        msg_head = (msg_head + 1) % 16;
        return;
    }
    if (m.type == 0 && under_attack == 0) {
        msg_head = (msg_head + 1) % 16;
        ViewBridge();
        SetSteering(1);
        word_45AA2 = 1;
        MsgBox(crew_names[1], GetText(37), 0x126, 0x6A, 0x2C, 0);
        MsgBox(crew_names[0], GetText(38), 0xA0, 0x82, 0xB0, 0);
        MsgBox(crew_names[7], GetText(39), 0x40, 0x64, 0xA1, 0);
        MsgBox(crew_names[5], GetText(40), 0xC4, 0x74, 0xB0, 0);
        MsgBox(crew_names[0], GetText(41), 0xA0, 0x82, 0xB0, 0);
        MsgBox(crew_names[6], GetText(42), 0x12A, 0x96, 0xA1, 0);
        MsgBox(crew_names[0], GetText(43), 0xA0, 0x82, 0xB0, 0);
        Debrief(6, 44, mission_vars[0], mission_vars[1]);
        for (sum = 0, i = 0; i != 7; ++i)
            sum += mission_ranks[i];
        pct = sum * 100 / 28;
        pct = max(0, min(pct, 100));
        text = AllocMemPtr(0x200);
        num[0] = 0;
        SayNumber(num, pct);
        sprintf(text, GetText(45), num, pct);
        MsgBox("Admiral", text, 0xA0, 0xBE, 0x2C, -7);
        if (pct <= 50) {
            strcpy(text, GetText(46));
            AdmiralVerdict(text);
            EndMcCoy();
            MsgBox(crew_names[2], GetText(47), 0xA0, 0x64, 0x2C, 0);
            EndSpock();
            MsgBox(crew_names[1], GetText(48), 0x126, 0x6A, 0x2C, 0);
            EndKirk();
            MsgBox(crew_names[0], GetText(49), 0xA0, 0x82, 0xB0, 0);
            EndMcCoy();
            MsgBox(crew_names[2], GetText(50), 0xA0, 0x64, 0x2C, 0);
            EndSpock();
            MsgBox(crew_names[1], GetText(51), 0x126, 0x6A, 0x2C, 0);
            EndKirk();
            MsgBox(crew_names[0], GetText(52), 0xA0, 0x82, 0xB0, 0);
        } else if (pct <= 85) {
            strcpy(text, GetText(53));
            AdmiralVerdict(text);
            EndKirk();
            MsgBox(crew_names[0], GetText(54), 0xA0, 0x82, 0xB0, 0);
            EndSpock();
            MsgBox(crew_names[1], GetText(55), 0x126, 0x6A, 0x2C, 0);
            EndMcCoy();
            MsgBox(crew_names[2], GetText(56), 0xA0, 0x64, 0x2C, 0);
            EndSpock();
            MsgBox(crew_names[1], GetText(57), 0x126, 0x6A, 0x2C, 0);
            EndKirk();
            MsgBox(crew_names[0], GetText(58), 0xA0, 0x82, 0xB0, 0);
            EndMcCoy();
            MsgBox(crew_names[2], GetText(59), 0xA0, 0x64, 0x2C, 0);
            EndKirk();
            MsgBox(crew_names[0], GetText(60), 0xA0, 0x82, 0xB0, 0);
        } else {
            strcpy(text, GetText(61));
            AdmiralVerdict(text);
            EndMcCoy();
            MsgBox(crew_names[2], GetText(62), 0xA0, 0x64, 0x2C, 0);
            EndSpock();
            MsgBox(crew_names[1], GetText(63), 0x126, 0x6A, 0x2C, 0);
            EndMcCoy();
            MsgBox(crew_names[2], GetText(64), 0xA0, 0x64, 0x2C, 0);
            EndKirk();
            MsgBox(crew_names[0], GetText(65), 0xA0, 0x82, 0xB0, 0);
            EndSpock();
            MsgBox(crew_names[1], GetText(66), 0x126, 0x6A, 0x2C, 0);
            EndMcCoy();
            MsgBox(crew_names[2], GetText(67), 0xA0, 0x64, 0x2C, 0);
            EndKirk();
            MsgBox(crew_names[0], GetText(68), 0xA0, 0x82, 0xB0, 0);
        }
        FreeMemPtr(text);
        ViewFull();
        WarpOut();
        Credits();
        ClearScreen();
        word_45AA2 = 0;
        ClearMsgs();
        GameOverMenu();
    } else
        BridgeMsg();
}

/* The Admiral's verdict. */
void AdmiralVerdict(char *text)
{
    MsgBox("Admiral", text, 0xA0, 0xBE, 0x2C, -7);
    HailEnd();
}

/* Empty: called before Kirk's, Spock's and McCoy's lines in the ending
 * (perhaps for portraits that were never added). */
void EndKirk(void)
{
}

void EndSpock(void)
{
}

void EndMcCoy(void)
{
}

/* The credits: the credits ship flies past, then Gene Roddenberry's
 * tribute while the music plays. A key skips them. */
void Credits(void)
{
    Obj3D o;
    int r;

    DigiShutdown();
    LoadMusic("title");
    MemSet(&o, sizeof o, 0);
    o.r3s = CacheLoad("credit00", "shp");
    o.r3s_type = 0;
    o.visible = R3_SHOT;
    o.reach = 1;
    o.size = 1;
    AddR3(&o);
    MemSet(&cam_pos, 12, 0);
    MatIdentity(&cam_orient);
    MatRotY(0x200, &cam_orient);
    PlaceObj(&o, 0, 0, 0, -proj_dist, 10);
    StarsReset();
    if (CreditsFly(&o, 10))
        goto done;
    o.pos.z = cam_pos.z - proj_dist;
    o.vz = 0;
    r = CreditsFly(&o, 50);
    CacheRelease(o.r3s);
    DelR3(&o);
    if (r)
        goto done;
    if (CreditsFly(&o, 15))
        goto done;
    o.r3s = CacheLoad("credgene", "shp");
    o.r3s_type = 0;
    o.visible = R3_SHOT;
    o.reach = 1;
    o.size = 1;
    AddR3(&o);
    o.pos.z = cam_pos.z - proj_dist;
    PlayVoc("sfx\\geneeulo");
play:
    if ((r = CreditsFly(&o, 0xDC)) == 0 && MusicPlaying())
        goto play;
    CacheRelease(o.r3s);
    DelR3(&o);
    if (r)
        goto done;
    CreditsFly(&o, 15);
done:
    FadeOut();
    LoadMusic("bridge");
}

/* Fly o towards the camera for n frames. Returns 1 if a key was pressed. */
int CreditsFly(Obj3D *o, int n)
{
    long t;
    long now;
    int i;
    Event ev;

    t = GetTicks();
    for (i = 0; i != n; i++) {
        StreamTick();
        RenderR3(0);
        SpriteErase(&mouse_sprite);
        UpdateSprites();
        o->pos.z += o->vz - 10;
        cam_pos.z -= 10;
        t += 3;
        while ((now = GetTicks()) < t)
            ;
        FadeUp();
        while (GetEvent(&ev))
            if (ev.type == 6) {
                FadeOut();
                return 1;
            }
    }
    return 0;
}
