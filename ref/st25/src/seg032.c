/* seg032: the bridge script for the fourth mission, "Another Fine Mess"
 * (Harry Mudd) */

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
void CutScene(char *name, char *voc);
void SetSteering(int on);
void HailShow(char *name);
void HailRestart(void);
void HailEnd(void);
void HailSay(char *name, char *title, char *text);
void Orbit(int arrive, int say);
void Debrief(int n, int msg, int score, int max);
void ShuttleFlyby(int kind);
void ShuttleEnd(void);
void ClearMsgs(void);
/* seg008 */
void MsgBox(char *title, char *text, int x, int y, int color, int msg);
/* seg000 */
int StartAnim(int n, char *name, int x, int y, int scale);
void EndAnim(int n);
/* seg020 */
void BoostEnd(void);
void InitShips(char *name);
/* seg033 */
void FeatherArrive(void);

void MuddArrive(void);
void MuddHarlequin(void);
void MuddReturn(void);

extern char *crew_names[8];
extern int word_45AA2;
extern int under_attack;
extern void (far *bridge_tick)(void);
extern int word_45AB2;
extern int word_45AB4;
extern int msg_head;
extern int word_50CA6;
extern int word_51156;
extern Obj3D ships[4];
extern unsigned long bridge_ticks;
extern int mission_vars[6];
extern void (far *saved_tick)(void);
extern int word_52C1E;
extern char mission[16];

/* Arriving: the fly-by, Starfleet's orders, and on to Harlequin. */
void MuddArrive(void)
{
    Msg m;

    m = *PeekMsg();
    if (mission_vars[0] == 0 && m.type != 0 && m.type != 5) {
        msg_head = (msg_head + 1) % 16;
        return;
    }
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            LoadMusic("bridge");
            BoostEnd();
            strcpy(mission, "mudd");
            SetTextFile(mission);
            MemSet(mission_vars, 12, 0);
            saved_tick = MuddArrive;
            CutScene("another", "MUD0\\FLYBY");
            break;
        case 0x97:
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(0), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(1), 0xA0, 0x82, 0xB0, 1);
            break;
        }
        BridgeMsg();
        return;
    } else if (m.type == 5 && m.arg == 1) {
        msg_head = (msg_head + 1) % 16;
        HailSay("woman", "Admiral", GetText(2));
        mission_vars[0] = 1;
        word_45AB4 = 3;
        SetSteering(1);
    } else if (m.type == 1) {
        if (m.arg == 0x40) {
            if (mission_vars[3] == 0) {
                MsgBox(crew_names[6], GetText(3), 0x12A, 0x96, 0xA1, 0);
                msg_head = (msg_head + 1) % 16;
            } else
                BridgeMsg();
            return;
        } else if (m.arg == 0x20) {
            if (mission_vars[3] == 0) {
                MsgBox(crew_names[1], GetText(4), 0x126, 0x6A, 0x2C, 0);
                msg_head = (msg_head + 1) % 16;
            } else
                BridgeMsg();
            return;
        } else if (m.arg == 0x60) {
            mission_vars[3] = 1;
            BridgeMsg();
            if (word_45AB2 == 3) {
                MsgBox(crew_names[1], GetText(5), 0x126, 0x6A, 0x2C, 0);
                bridge_ticks = 0;
                bridge_tick = MuddHarlequin;
            }
            return;
        } else {
            BridgeMsg();
            return;
        }
    }
    BridgeMsg();
}

/* At Harlequin: the Elasi attack, then Mudd's ship is found. */
void MuddHarlequin(void)
{
    Msg m;
    int i;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 10:
            mission_vars[1] = 0;
            MsgBox(crew_names[1], GetText(6), 0x126, 0x6A, 0x2C, 0);
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(7), 0x12A, 0x96, 0xA1, 1);
            break;
        default:
            if (mission_vars[1] && under_attack == 0 && mission_vars[2] == 0) {
                if (GetMusicSeq() != 0)
                    PlayMusic(-1, -1);
                MsgBox(crew_names[1], GetText(8), 0x126, 0x6A, 0x2C, 0);
                MsgBox(crew_names[6], GetText(9), 0x12A, 0x96, 0xA1, 0);
                MsgBox(crew_names[0], GetText(10), 0xA0, 0x82, 0xB0, 0);
                MsgBox("Voice", GetText(11), 0xA0, 0x82, 0x2C, 0);
                MsgBox(crew_names[0], GetText(12), 0xA0, 0x82, 0xB0, 0);
                MsgBox(crew_names[6], GetText(13), 0x12A, 0x96, 0xA1, 2);
                mission_vars[2] = 1;
                word_45AB4 = 4;
            }
            if (under_attack)
                for (i = 0; i != 2; ++i)
                    if (ships[i].systems[SYS_HULL].cur * 2 <= ships[i].systems[SYS_HULL].max)
                        ships[i].flee = 1;
            break;
        }
        BridgeMsg();
        return;
    } else if (m.type == 5 && m.arg == 1) {
        msg_head = (msg_head + 1) % 16;
        HailSay("pira", "Elasi Pirate", GetText(14));
        InitShips("orion");
        InitShips("orion");
        mission_vars[1] = 1;
        under_attack = 1;
        PlayMusic(2, -3);
        return;
    } else if (m.type == 5 && m.arg == 2) {
        msg_head = (msg_head + 1) % 16;
        HailShow("mudd");
        MsgBox("Harry Mudd", GetText(15), 0xA0, 0xBE, 0x2C, -7);
        MsgBox(crew_names[0], GetText(16), 0xA0, 0x82, 0xB0, 0);
        HailRestart();
        MsgBox("Harry Mudd", GetText(17), 0xA0, 0xBE, 0x2C, -7);
        HailEnd();
        MsgBox(crew_names[1], GetText(18), 0x126, 0x6A, 0x2C, 0);
        return;
    } else if (m.type == 1) {
        if (m.arg == 0x40) {
            if (under_attack)
                MsgBox(crew_names[6], GetText(19), 0x12A, 0x96, 0xA1, 0);
            else if (mission_vars[2])
                MsgBox(crew_names[6], GetText(20), 0x12A, 0x96, 0xA1, 0);
            else {
                BridgeMsg();
                return;
            }
            msg_head = (msg_head + 1) % 16;
            return;
        } else if (m.arg == 0x20) {
            if (under_attack)
                MsgBox(crew_names[1], GetText(21), 0x126, 0x6A, 0x2C, 0);
            else if (mission_vars[2])
                MsgBox(crew_names[1], GetText(22), 0x126, 0x6A, 0x2C, 0);
            else {
                BridgeMsg();
                return;
            }
            msg_head = (msg_head + 1) % 16;
            return;
        } else if (m.arg == 0x60) {
            if (mission_vars[2]) {
                BridgeMsg();
                if (word_45AB2 == word_45AB4) {
                    ShuttleFlyby(5);
                    bridge_ticks = 0;
                    bridge_tick = MuddReturn;
                }
                return;
            } else {
                msg_head = (msg_head + 1) % 16;
                return;
            }
        } else {
            BridgeMsg();
            return;
        }
    } else
        BridgeMsg();
}

/* By Mudd's ship, then back: the debriefing and on to the next mission. */
void MuddReturn(void)
{
    Msg m;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 100:
            MsgBox(crew_names[1], GetText(23), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[0], GetText(24), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(25), 0x126, 0x6A, 0x2C, 0);
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(26), 0x12A, 0x96, 0xA1, 0);
            HailShow("mudd");
            MsgBox("Harry Mudd", GetText(27), 0xA0, 0xBE, 0x2C, -7);
            MsgBox(crew_names[0], GetText(28), 0xA0, 0x82, 0xB0, 0);
            HailRestart();
            MsgBox("Harry Mudd", GetText(29), 0xA0, 0xBE, 0x2C, -7);
            MsgBox(crew_names[1], GetText(30), 0x126, 0x6A, 0x2C, 0);
            HailRestart();
            MsgBox("Harry Mudd", GetText(31), 0xA0, 0xBE, 0x2C, -7);
            MsgBox(crew_names[0], GetText(32), 0xA0, 0x82, 0xB0, 0);
            HailRestart();
            MsgBox("Harry Mudd", GetText(33), 0xA0, 0xBE, 0x2C, -7);
            MsgBox(crew_names[0], GetText(34), 0xA0, 0x82, 0xB0, 0);
            HailEnd();
            break;
        }
        if (mission_vars[5]) {
            if (mission_vars[5] == 1) {
                Debrief(3, 35, word_50CA6, word_52C1E);
                if (word_51156) {
                    MsgBox(crew_names[7], GetText(36), 0x40, 0x64, 0xA1, 0);
                    MsgBox(crew_names[0], GetText(37), 0xA0, 0x82, 0xB0, 0);
                } else
                    MsgBox(crew_names[0], GetText(38), 0xA0, 0x82, 0xB0, 0);
                MsgBox(crew_names[6], GetText(41), 0x12A, 0x96, 0xA1, 0);
                MsgBox(crew_names[0], GetText(42), 0xA0, 0x82, 0xB0, 0);
                MsgBox(crew_names[6], GetText(43), 0x12A, 0x96, 0xA1, 0);
                MsgBox(crew_names[0], GetText(44), 0xA0, 0x82, 0xB0, 4);
            }
            mission_vars[5] -= 1;
        }
        BridgeMsg();
        return;
    } else if (m.type == 1) {
        if (mission_vars[4]) {
            msg_head = (msg_head + 1) % 16;
            return;
        }
        if (m.arg == 0x40 || m.arg == 0x60) {
            MsgBox(crew_names[6], GetText(45), 0x12A, 0x96, 0xA1, 0);
            msg_head = (msg_head + 1) % 16;
            return;
        } else if (m.arg == 0x20) {
            MsgBox(crew_names[1], GetText(46), 0x126, 0x6A, 0x2C, 0);
            msg_head = (msg_head + 1) % 16;
            return;
        } else if (m.arg == 0x50) {
            msg_head = (msg_head + 1) % 16;
            return;
        }
    } else if (m.type == 6) {
        mission_vars[4] = 1;
        mission_vars[5] = 10;
        StartAnim(1, "xstndsp", 0, 0, 256);
        StartAnim(2, "xstndmc", 0, 0, 256);
        word_45AA2 = 1;
        if (bridge_ticks <= 100)
            bridge_ticks = 101;
    } else if (m.type == 5 && m.arg == 4) {
        ShuttleEnd();
        Orbit(0, 0);
        bridge_tick = FeatherArrive;
        bridge_ticks = 0;
        msg_head = (msg_head + 1) % 16;
        StartAnim(1, "bstndsp", 0, 0, 256);
        EndAnim(2);
        word_45AA2 = 0;
        ClearMsgs();
        return;
    }
    BridgeMsg();
}
