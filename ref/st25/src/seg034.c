/* seg034: the bridge script for the fifth mission's second part, the trial
 * on Quetzecoatl's world */

#include <string.h>
#include "mem.h"
#include "sound.h"
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
void SetSteering(int on);
void HailShow(char *name);
void HailEnd(void);
void HailSay(char *name, char *title, char *text);
void Orbit(int arrive, int say);
void ViewFull(void);
void ViewBridge(void);
void Debrief(int n, int msg, int score, int max);
char *GetChoice(int n, int *list, int x);
/* seg008: not prototyped here, as one call passes an extra argument */
void MsgBox();
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
long TextBox(char *(far *fn)(), int *arg, int x, int y, int color, int choice, int maxl,
             int flag);
/* seg020 */
void InitShips(char *name);
/* seg025 */
void WarpOut(void);
/* seg035 */
void SinsArrive(void);

void TrialArrive(void);
void TrialKenka(void);
void TrialSpock(void);
void TrialSulu(void);
void TrialKallarax(void);
void TrialFight(void);
void TrialEnd(void);

extern char *crew_names[8];
extern int word_45AA2;
extern int kbd_mouse;
extern int under_attack;
extern void (far *bridge_tick)(void);
extern int word_45AB2;
extern int word_45AB4;
extern int msg_head;
extern int word_50CA6;
extern int word_51156;
extern unsigned long bridge_ticks;
extern int mission_vars[6];
extern int word_52C1E;
extern char mission[16];

int kallarax_choices[] = { 0x0E, 0x0F, 0x10, -1 };

/* In orbit for the trial; after it, the bridge scene for how it went. */
void TrialArrive(void)
{
    Msg m;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            word_45AB4 = word_45AB2 = 8;
            strcpy(mission, "trial");
            SetTextFile(mission);
            MemSet(mission_vars, 12, 0);
            mission_vars[1] = word_50CA6;
            mission_vars[2] = word_52C1E;
            Orbit(1, 0);
            break;
        case 0x32:
            MsgBox(crew_names[0], GetText(0), 0xA0, 0x82, 0xB0, 0);
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
            Orbit(0, 0);
            bridge_ticks = 0;
            switch (word_51156) {
            case 0:
                bridge_tick = TrialKenka;
                break;
            case 1:
                bridge_tick = TrialSpock;
                break;
            case 2:
                bridge_tick = TrialSpock;
                break;
            case 3:
                bridge_tick = TrialSulu;
                break;
            case 4:
                bridge_tick = TrialKallarax;
                break;
            }
            msg_head = (msg_head + 1) % 16;
        } else
            msg_head = (msg_head + 1) % 16;
    }
}

/* Kenka hails after the trial. */
void TrialKenka(void)
{
    Msg m;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 0x14:
            word_45AA2 = 1;
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(1), 0x12A, 0x96, 0xA1, 0);
            HailSay("klg2", "Vlict Kenka", GetText(2));
            MsgBox(crew_names[6], GetText(3), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(4), 0xA0, 0x82, 0xB0, 0);
            msg_head = (msg_head + 1) % 16;
            TrialEnd();
            return;
        }
        BridgeMsg();
        return;
    } else
        msg_head = (msg_head + 1) % 16;
}

void TrialSpock(void)
{
    Msg m;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 0x14:
            word_45AA2 = 1;
            MsgBox(crew_names[0], GetText(5), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(6), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[0], GetText(7), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(8), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[0], GetText(9), 0xA0, 0x82, 0xB0, 0);
            msg_head = (msg_head + 1) % 16;
            TrialEnd();
            return;
        }
        BridgeMsg();
        return;
    } else
        msg_head = (msg_head + 1) % 16;
}

void TrialSulu(void)
{
    Msg m;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 0x14:
            word_45AA2 = 1;
            MsgBox(crew_names[4], GetText(10), 0x7A, 0x74, 0xB0, 0);
            MsgBox(crew_names[0], GetText(11), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(12), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[0], GetText(13), 0xA0, 0x82, 0xB0, 0);
            msg_head = (msg_head + 1) % 16;
            TrialEnd();
            return;
        }
        BridgeMsg();
        return;
    } else
        msg_head = (msg_head + 1) % 16;
}

/* Kallarax hails: talk him down, or fight. */
void TrialKallarax(void)
{
    Msg m;
    int r;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 0x14:
            word_45AA2 = 1;
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(17), 0x12A, 0x96, 0xA1, 0);
            HailShow("klg1");
            MsgBox("KALLARAX", GetText(18), 0xA0, 0xBE, 0x2C, -7);
            r = TextBox(GetChoice, kallarax_choices, 0xA0, 0x82, 0xB0, 1, 0, 0);
            if (r == 0 || r == 1) {
                MsgBox("KALLARAX", GetText(19), 0xA0, 0xBE, 0x2C, -7);
                HailEnd();
                MsgBox(crew_names[6], GetText(20), 0x12A, 0x96, 0xA1, 0);
                MsgBox(crew_names[0], GetText(21),
                       " Set course for Digifal, Mr. Sulu. Warp Factor Six.", 0xA0, 0x82, 0xB0, 0);
                msg_head = (msg_head + 1) % 16;
                TrialEnd();
                return;
            } else {
                bridge_tick = TrialFight;
                bridge_ticks = 0;
            }
            break;
        }
        BridgeMsg();
        return;
    } else
        msg_head = (msg_head + 1) % 16;
}

/* The fight with Kallarax. */
void TrialFight(void)
{
    Msg m;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            MsgBox("KALLARAX", GetText(22), 0xA0, 0xBE, 0x2C, -7);
            HailEnd();
            PlayMusic(2, -3);
            BridgeSfx(0x28);
            MsgBox(crew_names[1], GetText(23), 0x126, 0x6A, 0x2C, 0);
            InitShips("K'LRTA");
            under_attack = 1;
            word_45AA2 = 0;
            break;
        default:
            if (bridge_ticks > 2 && under_attack == 0) {
                word_45AA2 = 1;
                if (GetMusicSeq() != 0)
                    PlayMusic(-1, -1);
                MsgBox(crew_names[0], GetText(24), 0xA0, 0x82, 0xB0, 0);
                MsgBox(crew_names[1], GetText(25), 0x126, 0x6A, 0x2C, 0);
                msg_head = (msg_head + 1) % 16;
                TrialEnd();
                return;
            }
        }
    }
    BridgeMsg();
}

/* Warp out: the debriefing with the score from both parts, then on to the
 * next mission. */
void TrialEnd(void)
{
    int unused;

    ViewFull();
    kbd_mouse = 0;
    WarpOut();
    ViewBridge();
    SetSteering(1);
    Debrief(4, 26, mission_vars[1] + word_50CA6, mission_vars[2] + word_52C1E);
    bridge_ticks = 0;
    bridge_tick = SinsArrive;
    word_45AA2 = 0;
}
