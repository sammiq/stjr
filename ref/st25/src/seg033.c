/* seg033: the bridge script for the fifth mission, "The Feathered Serpent"
 * (the Klingons and Quetzecoatl) */

#include <string.h>
#include "mem.h"
#include "sound.h"
#include "gfx.h"
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
void DrawRadar(void);
void DrawShipStatus(Obj3D *o);
void HailShow(char *name);
void HailEnd(void);
void HailSay(char *name, char *title, char *text);
void Orbit(int arrive, int say);
void ViewFull(void);
void ViewBridge(void);
void ClearMsgs(void);
char *GetChoice(int n, int *list, int x);
/* seg008 */
void MsgBox(char *title, char *text, int x, int y, int color, int msg);
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
long TextBox(char *(far *fn)(), int *arg, int x, int y, int color, int choice, int maxl,
             int flag);
/* seg017 */
void DelR3(Obj3D *o);
void RenderR3(int statics);
/* seg020 */
void BoostEnd(void);
void InitShips(char *name);
/* seg022 */
void SetPlanet(int n);
/* seg025 */
void WarpOut(void);
/* seg034 */
void TrialArrive(void);

void FeatherArrive(void);
void FeatherKenka(void);
void FeatherAttack(void);

extern char *crew_names[8];
extern int kbd_mouse;
extern int under_attack;
extern void (far *bridge_tick)(void);
extern int word_45AB2;
extern int word_45AB4;
extern int word_45B70;
extern int msg_head;
extern Obj3D ships[4];
extern unsigned long bridge_ticks;
extern int mission_vars[6];
extern void (far *saved_tick)(void);
extern Obj3D player_ship;
extern char mission[16];

int taraz_choices1[] = { 0, 1, 2, -1 };
int taraz_choices2[] = { 3, 4, -1 };
int kenka_choices1[] = { 0x0E, 0x0F, 0x10, -1 };
int kenka_choices2[] = { 0x11, 0x12, 0x13, -1 };

/* Arriving: the fly-by, then Taraz's Klingon ship on the way. */
void FeatherArrive(void)
{
    Msg m;
    int i;
    int cur;
    int max;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            LoadMusic("bridgeb");
            BoostEnd();
            strcpy(mission, "feather");
            MemSet(mission_vars, 12, 0);
            SetTextFile(mission);
            word_45AB4 = 6;
            saved_tick = FeatherArrive;
            CutScene("feather", "FEA0\\FLYBY");
            break;
        case 0x97:
            MsgBox(crew_names[0], GetText(5), 0xA0, 0x82, 0xB0, 0);
            break;
        }
        if (mission_vars[0] == 1) {
            for (i = cur = max = 0; i != 6; ++i) {
                cur += ships[0].shields[i].cur;
                max += ships[0].shields[i].max;
            }
            if (cur * 3 < max * 2) {
                ships[0].flee = 1;
                InitShips("klingon");
            }
        }
        if (mission_vars[1] && mission_vars[0] == 0) {
            if (mission_vars[2] == 0) {
                mission_vars[1] = 0;
                InitShips("klingon");
                ships[0].systems[SYS_PHASER_PORT].unk = 0;
                ships[0].systems[SYS_PHASER_STBD].unk = 0;
                ships[0].systems[SYS_TORP_PORT].unk = 0;
                word_45B70 = 1;
                DrawRadar();
                DrawShipStatus(&player_ship);
                RenderR3(0);
                FadeIn();
                UpdateSprites();
                MsgBox(crew_names[6], GetText(6), 0x12A, 0x96, 0xA1, 0);
                BridgeSfx(0x22);
                MsgBox(crew_names[0], GetText(7), 0xA0, 0x82, 0xB0, 0);
                HailShow("klg1");
                MsgBox("Taraz", GetText(8), 0xA0, 0xBE, 0x2C, -7);
                i = TextBox(GetChoice, taraz_choices1, 0xA0, 0x82, 0xB0, 1, 0, 0);
                if (i == 0 || i == 2) {
                fight:
                    MsgBox("Taraz", GetText(9), 0xA0, 0xBE, 0x2C, -7);
                    HailEnd();
                    PlayMusic(2, -3);
                    BridgeSfx(0x28);
                    MsgBox(crew_names[1], GetText(10), 0x126, 0x6A, 0x2C, 0);
                    mission_vars[0] = 1;
                    ships[0].systems[SYS_PHASER_PORT].unk = 1;
                    ships[0].systems[SYS_PHASER_STBD].unk = 1;
                    ships[0].systems[SYS_TORP_PORT].unk = 1;
                } else {
                    MsgBox("Taraz", GetText(11), 0xA0, 0xBE, 0x2C, -7);
                    i = TextBox(GetChoice, taraz_choices2, 0xA0, 0x82, 0xB0, 1, 0, 0);
                    if (i == 1)
                        goto fight;
                    else
                        HailEnd();
                }
            } else
                mission_vars[2] -= 1;
        }
        BridgeMsg();
        return;
    }
    if (m.type == 1) {
        switch (m.arg) {
        case 0x50:
            if (mission_vars[0] == 0 && word_45AB2 == word_45AB4) {
                bridge_ticks = 0;
                bridge_tick = FeatherKenka;
                msg_head = (msg_head + 1) % 16;
                return;
            }
            break;
        case 1:
        case 2:
            if (mission_vars[0] == 0 && under_attack && player_ship.weapons_pwr) {
                mission_vars[0] = 1;
                HailSay("klg1", "Taraz", GetText(12));
                ships[0].systems[SYS_PHASER_PORT].unk = 1;
                ships[0].systems[SYS_PHASER_STBD].unk = 1;
                ships[0].systems[SYS_TORP_PORT].unk = 1;
            }
            break;
        case 0x60:
            if (word_45AB2 == word_45AB4) {
                if (mission_vars[0] == 0)
                    under_attack = 0;
                BridgeMsg();
            } else {
                BridgeMsg();
                if (word_45AB2 == word_45AB4) {
                    mission_vars[1] = 1;
                    mission_vars[2] = 30;
                }
            }
            return;
        case 0x40:
            MsgBox(crew_names[6], GetText(13), 0x12A, 0x96, 0xA1, 0);
            msg_head = (msg_head + 1) % 16;
            return;
        }
    }
    BridgeMsg();
}

/* In orbit of Digifal: Admiral Kenka's demands. */
void FeatherKenka(void)
{
    Msg m;
    int r;

    under_attack = 0;
    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            Orbit(1, 1);
            break;
        }
        BridgeMsg();
        return;
    } else if (m.type == 1 && m.arg == 0x20) {
        MsgBox(crew_names[1], GetText(20), 0x126, 0x6A, 0x2C, 0);
        msg_head = (msg_head + 1) % 16;
        return;
    } else if (m.type == 6) {
        Orbit(0, 0);
        FadeIn();
        msg_head = (msg_head + 1) % 16;
        MsgBox(crew_names[6], GetText(21), 0x12A, 0x96, 0xA1, 0);
        BridgeSfx(0x22);
        MsgBox(crew_names[6], GetText(22), 0x12A, 0x96, 0xA1, 0);
        PostRoomMsg(5, 1, 0, 0);
        return;
    } else if (m.type == 5 && m.arg == 1) {
        HailShow("klg2");
        MsgBox("Admiral Kenka", GetText(23), 0xA0, 0xBE, 0x2C, -7);
        r = TextBox(GetChoice, kenka_choices1, 0xA0, 0x82, 0xB0, 1, 0, 0);
        if (r == 0 || r == 1) {
            MsgBox("Admiral Kenka", GetText(24), 0xA0, 0xBE, 0x2C, -7);
            MsgBox(crew_names[0], GetText(25), 0xA0, 0x82, 0xB0, 0);
            MsgBox("Admiral Kenka", GetText(26), 0xA0, 0xBE, 0x2C, -7);
            r = TextBox(GetChoice, kenka_choices2, 0xA0, 0x82, 0xB0, 1, 0, 0);
            if (r == 0 || r == 1) {
                MsgBox("Admiral Kenka", GetText(27), 0xA0, 0xBE, 0x2C, -7);
                BridgeSfx(0x22);
                MsgBox(crew_names[6], GetText(28), 0x12A, 0x96, 0xA1, 0);
                MsgBox(crew_names[0], GetText(29), 0xA0, 0x82, 0xB0, 0);
                MsgBox("Admiral Kenka", GetText(30), 0xA0, 0xBE, 0x2C, -7);
                HailEnd();
                HailShow("woman");
                MsgBox("Admiral", GetText(31), 0xA0, 0xBE, 0x2C, -7);
                HailEnd();
                MsgBox(crew_names[7], GetText(32), 0x40, 0x64, 0xA1, 0);
                MsgBox(crew_names[0], GetText(33), 0xA0, 0x82, 0xB0, 0);
                ViewFull();
                kbd_mouse = 0;
                WarpOut();
                if (ships[0].visible == R3_SHIP)
                    DelR3(&ships[0]);
                word_45AB4 = word_45AB2 = 8;
                SetPlanet(word_45AB4);
                SetSteering(1);
                ViewBridge();
                bridge_ticks = 0;
                bridge_tick = TrialArrive;
                ClearMsgs();
                return;
            } else {
            refuse:
                HailEnd();
                MsgBox(crew_names[4], GetText(34), 0x7A, 0x74, 0xB0, 0);
                PlayMusic(2, -3);
                BridgeSfx(0x28);
                InitShips("K'LRTA");
                bridge_ticks = 0;
                bridge_tick = FeatherAttack;
                return;
            }
        } else
            goto refuse;
    } else if (m.type == 1 && m.arg == 0x50) {
        MsgBox(crew_names[4], GetText(35), 0x7A, 0x74, 0x2C, 0);
        msg_head = (msg_head + 1) % 16;
        return;
    }
    BridgeMsg();
}

/* Kenka's ship attacks. */
void FeatherAttack(void)
{
    InitShips("klingon");
    BridgeMsg();
}
