/* seg031: the bridge script for the third mission, "Love's Labor
 * Jeopardized" (the Romulans and Ark 7) */

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
void HailSay(char *name, char *title, char *text);
void Orbit(int arrive, int say);
void Debrief(int n, int msg, int score, int max);
void ShuttleFlyby(int kind);
void ShuttleEnd(void);
void ClearMsgs(void);
/* seg008 */
void MsgBox(char *title, char *text, int x, int y, int color, int msg);
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d);
/* seg000 */
int StartAnim(int n, char *name, int x, int y, int scale);
void EndAnim(int n);
/* seg020 */
void BoostEnd(void);
void InitShips(char *name);
/* seg032 */
void MuddArrive(void);

void LoveArrive(void);
void LoveTravel(void);
void LoveRomulans(void);
void LoveOrbit(void);
void LoveAway(void);
void LoveReturn(void);

extern char *crew_names[8];
extern int word_45AA2;
extern int kbd_mouse;
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
extern char mission[16];

/* Arriving: the fly-by and Starfleet's orders. */
void LoveArrive(void)
{
    Msg m;
    int unused;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            LoadMusic("bridge");
            BoostEnd();
            strcpy(mission, "love");
            SetTextFile(mission);
            MemSet(mission_vars, 12, 0);
            saved_tick = LoveArrive;
            CutScene("tlove", "LOV0\\FLYBY");
            break;
        case 0x97:
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(0), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(1), 0xA0, 0x82, 0xB0, 1);
            break;
        }
        BridgeMsg();
    } else {
        if (m.type == 5 && m.arg == 1) {
            HailSay("woman", "Admiral", GetText(2));
            bridge_ticks = 0;
            bridge_tick = LoveTravel;
            word_45AB4 = 2;
            kbd_mouse = 1;
        }
        msg_head = (msg_head + 1) % 16;
    }
}

/* On the way to Ark 7. */
void LoveTravel(void)
{
    Msg m;
    int was_there;

    if (under_attack == 0 && GetMusicSeq() == 2)
        PlayMusic(-1, -1);
    m = *PeekMsg();
    switch (m.type) {
    case 1:
        switch (m.arg) {
        case 0x60:
            was_there = word_45AB2 == word_45AB4;
            BridgeMsg();
            if (word_45AB2 == word_45AB4 && was_there == 0) {
                MsgBox(crew_names[1], GetText(3), 0x126, 0x6A, 0x2C, 1);
                mission_vars[0] = 1;
            }
            return;
        case 0x20:
            msg_head = (msg_head + 1) % 16;
            if (mission_vars[0] == 0)
                MsgBox(crew_names[1], GetText(4), 0x126, 0x6A, 0x2C, 0);
            return;
        case 0x40:
            if (under_attack == 0) {
                msg_head = (msg_head + 1) % 16;
                if (mission_vars[0] == 0)
                    MsgBox(crew_names[6], GetText(5), 0x12A, 0x96, 0xA1, 0);
                return;
            }
            break;
        default:
            if (mission_vars[0])
                msg_head = (msg_head + 1) % 16;
            else
                BridgeMsg();
            return;
        }
        break;
    case 5:
        if (m.arg == 1) {
            bridge_ticks = 0;
            bridge_tick = LoveRomulans;
        }
        break;
    }
    BridgeMsg();
}

/* At Ark 7: the Romulan ship decloaks. */
void LoveRomulans(void)
{
    Msg m;

    m = *PeekMsg();
    switch (m.type) {
    case 0:
        switch (bridge_ticks) {
        case 1:
            InitShips("romulan");
            ships[0].systems[SYS_TORP_PORT].unk = 0;
            MsgBox(crew_names[1], "#BRID\\B_160#Romulan ship decloaking, Captain.", 0x126, 0x6A, 0x2C, 0);
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(6), 0x12A, 0x96, 0xA1, 1);
            break;
        default:
            if (under_attack == 0 && bridge_ticks > 1) {
                bridge_ticks = 0;
                bridge_tick = LoveOrbit;
            }
            break;
        }
        BridgeMsg();
        return;
    case 1:
        switch (m.arg) {
        case 0x40:
            msg_head = (msg_head + 1) % 16;
            if (mission_vars[0] == 0)
                MsgBox(crew_names[6], GetText(7), 0x12A, 0x96, 0xA1, 0);
            return;
        case 0x20:
            msg_head = (msg_head + 1) % 16;
            if (mission_vars[0] == 0)
                MsgBox(crew_names[1], GetText(8), 0x126, 0x6A, 0x2C, 0);
            return;
        }
        break;
    case 5:
        if (m.arg == 1) {
            msg_head = (msg_head + 1) % 16;
            mission_vars[0] = 0;
            HailSay("romula", "Romulan Captain", GetText(9));
            MsgBox(crew_names[1], GetText(10), 0x126, 0x6A, 0x2C, 0);
            ships[0].systems[SYS_TORP_PORT].unk = 1;
            PlayMusic(2, -3);
            BridgeSfx(0x28);
        }
        return;
    }
    if (mission_vars[0] == 0)
        BridgeMsg();
    else
        msg_head = (msg_head + 1) % 16;
}

/* The Romulans leave: orbit Ark 7 and beam over. */
void LoveOrbit(void)
{
    Msg m;

    m = *PeekMsg();
    switch (m.type) {
    case 0:
        switch (bridge_ticks) {
        case 1:
            MsgBox(crew_names[1], GetText(11), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[4], GetText(12), 0x7A, 0x74, 0xB0, 1);
            mission_vars[0] = 1;
            break;
        }
        BridgeMsg();
        return;
    case 5:
        msg_head = (msg_head + 1) % 16;
        if (m.arg == 1) {
            ShuttleFlyby(4);
            bridge_ticks = 0;
            bridge_tick = LoveAway;
            mission_vars[0] = 0;
        }
        return;
    }
    if (mission_vars[0])
        msg_head = (msg_head + 1) % 16;
    else
        BridgeMsg();
}

/* The landing party is on Ark 7: Centurion Preax and the autobeacon. */
void LoveAway(void)
{
    Msg m;

    m = *PeekMsg();
    switch (m.type) {
    case 1:
        switch (m.arg) {
        case 0x20:
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[1], GetText(13), 0x126, 0x6A, 0x2C, 0);
            return;
        case 0x40:
            if (mission_vars[1] == 0) {
                BridgeSfx(0x22);
                MsgBox(crew_names[6], GetText(14), 0x12A, 0x96, 0xA1, 1);
                msg_head = (msg_head + 1) % 16;
                return;
            }
            break;
        }
        break;
    case 5:
        if (m.arg == 1) {
            HailSay("romula", "Centurion Preax", GetText(15));
            mission_vars[1] = 1;
            break;
        }
        if (m.arg == 2) {
            MsgBox("Autobeacon", GetText(16), 0xA0, 0x82, 0xA1, 0);
            break;
        }
        break;
    case 0:
        switch (bridge_ticks) {
        case 10:
            MsgBox(crew_names[6], GetText(17), 0x12A, 0x96, 0xA1, 0);
            PostRoomMsg(5, 2, 0, 0);
            break;
        }
        break;
    case 6:
        msg_head = (msg_head + 1) % 16;
        bridge_ticks = 0;
        bridge_tick = LoveReturn;
        return;
    }
    BridgeMsg();
}

/* Back from Ark 7: the debriefing, then on to the next mission. */
void LoveReturn(void)
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
            MsgBox(crew_names[6], GetText(18), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(19), 0xA0, 0x82, 0xB0, 1);
            break;
        case 0x208:
            MsgBox(crew_names[0], GetText(20), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[2], GetText(21), 0xA0, 0x64, 0x2C, 0);
            MsgBox(crew_names[0], GetText(22), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[2], GetText(23), 0xA0, 0x64, 0x2C, 0);
            MsgBox(crew_names[7], GetText(24), 0x40, 0x64, 0xA1, 0);
            MsgBox(crew_names[0], GetText(25), 0xA0, 0x82, 0xB0, 2);
            break;
        }
        BridgeMsg();
        return;
    case 5:
        switch (m.arg) {
        case 1:
            msg_head = (msg_head + 1) % 16;
            Debrief(2, 26, word_50CA6, word_52C1E);
            bridge_ticks = 500;
            return;
        case 2:
            msg_head = (msg_head + 1) % 16;
            ShuttleEnd();
            Orbit(0, 0);
            bridge_tick = MuddArrive;
            bridge_ticks = 0;
            StartAnim(1, "bstndsp", 0, 0, 256);
            EndAnim(2);
            word_45AA2 = 0;
            ClearMsgs();
            return;
        }
        break;
    }
    msg_head = (msg_head + 1) % 16;
}
