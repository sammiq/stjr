/* seg029: the bridge script for the first mission, "Demon World" */

#include <string.h>
#include "mem.h"
#include "sound.h"
#include "fixmath.h"
#include "obj3d.h"

typedef struct Msg {
    unsigned char type;
    unsigned char arg;
    int unk;
} Msg;

/* seg001 */
void BridgeSfx(int n);
void BridgeMsg(void);
Msg *PeekMsg(void);
char *GetText(int n);
void SetTextFile(char *name);
void CutScene(char *name, char *voc);
void SetSteering(int on);
void HailSay(char *name, char *title, char *text);
void Orbit(int arrive, int say);
void Debrief(int n, int msg, int score, int max);
void ClearMsgs(void);
/* seg008 */
void MsgBox(char *title, char *text, int x, int y, int color, int msg);
/* seg000 */
int StartAnim(int n, char *name, int x, int y, int scale);
void EndAnim(int n);
/* seg020 */
void BoostEnd(void);
void InitShips(char *name);
void ClearShots(void);
void SetPower(int shields, int weapons);
/* seg017 */
void DelR3(Obj3D *o);
/* seg030 */
void TugArrive(void);

void DemonArrive(void);
void DemonFight(void);
void DemonHail(void);
void DemonTravel(void);
void DemonReturn(void);

extern char *crew_names[8];
extern int word_45AA2;
extern int in_orbit;
extern int under_attack;
extern void (far *bridge_tick)(void);
extern int word_45AB2;
extern int word_45AB4;
extern int msg_head;
extern int word_50CA6;
extern Obj3D ships[4];
extern unsigned long bridge_ticks;
extern int mission_vars[6];
extern void (far *saved_tick)(void);
extern int word_52C1E;
extern Obj3D player_ship;
extern char mission[16];

/* Arriving: the fly-by, the Captain's log and Starfleet's orders. */
void DemonArrive(void)
{
    Msg m;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            LoadMusic("bridgew");
            BoostEnd();
            strcpy(mission, "demon");
            MemSet(mission_vars, 12, 0);
            SetTextFile(mission);
            saved_tick = DemonArrive;
            CutScene("demon", "DEM0\\FLYBY");
            break;
        case 0x97:
            MsgBox("Captain's Log", GetText(0), 0xA0, 0x82, 0xB0, 0);
            break;
        case 0xA5:
            MsgBox(crew_names[6], GetText(1), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[1], GetText(2), 0x126, 0x6A, 0x2C, 0);
            InitShips("enterpri");
            bridge_tick = DemonFight;
            SetSteering(1);
            PlayMusic(2, -3);
            BridgeSfx(0x28);
            break;
        }
        BridgeMsg();
    } else
        msg_head = (msg_head + 1) % 16;
}

/* The fight, until one side's hull is half gone. */
void DemonFight(void)
{
    Msg m;
    ShipPart *p;
    int i;

    if (ships[0].systems[SYS_HULL].cur < ships[0].systems[SYS_HULL].max >> 1) {
        PlayMusic(3, -1);
        MsgBox(crew_names[1], GetText(4), 0x126, 0x6A, 0x2C, 0);
        MsgBox(crew_names[6], GetText(5), 0x12A, 0x96, 0xA1, 0);
        goto over;
    }
    if (player_ship.systems[SYS_HULL].cur < player_ship.systems[SYS_HULL].max >> 1) {
        PlayMusic(4, -1);
        MsgBox(crew_names[1], GetText(6), 0x126, 0x6A, 0x2C, 0);
        MsgBox(crew_names[7], GetText(7), 0x40, 0x64, 0xA1, 0);
        MsgBox(crew_names[0], GetText(8), 0xA0, 0x82, 0xB0, 0);
        MsgBox(crew_names[6], GetText(9), 0x12A, 0x96, 0xA1, 0);
    over:
        ClearShots();
        BoostEnd();
        MsgBox(crew_names[4], "#BRID\\B_336#Lowering shields and disarming weapons.", 0x7A, 0x74, 0xB0, 2);
        for (p = &ships[0].systems[SYS_TORP_PORT], i = 0; i != 4; ++i, ++p)
            p->unk = 0;
        bridge_ticks = 0;
        bridge_tick = DemonHail;
        ships[0].flee = 1;
    } else {
        m = *PeekMsg();
        switch (m.type) {
        case 1:
            switch (m.arg) {
            case 0x40:
                msg_head = (msg_head + 1) % 16;
                MsgBox(crew_names[6], GetText(10), 0x12A, 0x96, 0xA1, 0);
                return;
            case 0x20:
                msg_head = (msg_head + 1) % 16;
                MsgBox(crew_names[1], GetText(11), 0x126, 0x6A, 0x2C, 0);
                return;
            }
            break;
        }
        BridgeMsg();
    }
}

/* After the fight: Starfleet hails with the mission. */
void DemonHail(void)
{
    Msg m;
    int unused;

    m = *PeekMsg();
    switch (m.type) {
    case 5:
        switch (m.arg) {
        case 2:
            SetPower(0, 0);
            break;
        case 1:
            if (ships[0].visible == R3_SHIP)
                DelR3(&ships[0]);
            HailSay("woman", "Admiral", GetText(12));
            bridge_ticks = 0;
            bridge_tick = DemonTravel;
            word_45AB4 = 18;
            break;
        }
        break;
    case 1:
        switch (m.arg) {
        default:
            msg_head = (msg_head + 1) % 16;
            return;
        }
        break;
    case 0:
        switch (bridge_ticks) {
        case 0x14:
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(13), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(14), 0xA0, 0x82, 0xB0, 1);
            break;
        }
        break;
    }
    BridgeMsg();
}

/* Travelling to system word_45AB4: the answers to hails and orbit
 * requests until the planet is reached. */
void DemonTravel(void)
{
    Msg m;
    int was_there;

    m = *PeekMsg();
    switch (m.type) {
    case 6:
        msg_head = (msg_head + 1) % 16;
        bridge_ticks = 0;
        bridge_tick = DemonReturn;
        return;
    case 1:
        switch (m.arg) {
        case 0x60:
            was_there = word_45AB2 == word_45AB4;
            BridgeMsg();
            if (word_45AB2 == word_45AB4 && was_there == 0)
                MsgBox(crew_names[1], GetText(15), 0x126, 0x6A, 0x2C, 0);
            return;
        case 0x40:
            if (under_attack)
                ;
            else {
                if (word_45AB4 != word_45AB2) {
                    MsgBox(crew_names[6], GetText(16), 0x12A, 0x96, 0xA1, 0);
                    msg_head = (msg_head + 1) % 16;
                    return;
                } else if (mission_vars[0] == 0) {
                    BridgeSfx(0x22);
                    MsgBox(crew_names[6], GetText(17), 0x12A, 0x96, 0xA1, 0);
                    HailSay("prst", "Priest", GetText(18));
                    mission_vars[0] = 1;
                    msg_head = (msg_head + 1) % 16;
                    return;
                } else {
                    MsgBox(crew_names[6], GetText(19), 0x12A, 0x96, 0xA1, 0);
                    msg_head = (msg_head + 1) % 16;
                    return;
                }
            }
            break;
        case 0x20:
            if (under_attack)
                ;
            else {
                if (word_45AB2 != word_45AB4) {
                    MsgBox(crew_names[1], GetText(20), 0x126, 0x6A, 0x2C, 0);
                    msg_head = (msg_head + 1) % 16;
                    return;
                } else if (in_orbit == 0) {
                    MsgBox(crew_names[1], GetText(21), 0x126, 0x6A, 0x2C, 0);
                    msg_head = (msg_head + 1) % 16;
                    return;
                } else {
                    MsgBox(crew_names[1], GetText(22), 0x126, 0x6A, 0x2C, 0);
                    msg_head = (msg_head + 1) % 16;
                    return;
                }
            }
            break;
        }
        break;
    }
    BridgeMsg();
}

/* Back from the planet: the debriefing, then on to the next mission. */
void DemonReturn(void)
{
    Msg m;

    m = *PeekMsg();
    switch (m.type) {
    case 0:
        switch (bridge_ticks) {
        case 1:
            word_45AA2 = 1;
            StartAnim(1, "xstndsp", 0, 0, 256);
            StartAnim(2, "xstndmc", 0, 0, 256);
            break;
        case 10:
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(23), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(24), 0xA0, 0x82, 0xB0, 1);
            break;
        case 0x208:
            MsgBox(crew_names[2], GetText(25), 0xA0, 0x64, 0x2C, 0);
            MsgBox(crew_names[0], GetText(26), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(27), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[2], GetText(28), 0xA0, 0x64, 0x2C, 2);
            break;
        }
        break;
    case 5:
        switch (m.arg) {
        case 1:
            Debrief(0, 29, word_50CA6, word_52C1E);
            bridge_ticks = 500;
            break;
        case 2:
            Orbit(0, 0);
            bridge_tick = TugArrive;
            bridge_ticks = 0;
            StartAnim(1, "bstndsp", 0, 0, 256);
            EndAnim(2);
            word_45AA2 = 0;
            ClearMsgs();
            return;
        }
        break;
    }
    if (m.type == 0)
        BridgeMsg();
    else
        msg_head = (msg_head + 1) % 16;
}
