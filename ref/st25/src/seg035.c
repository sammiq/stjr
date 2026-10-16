/* seg035: the bridge script for the sixth mission, "Sins of Omission"
 * (Proxima Maxima) */

#include <string.h>
#include "mem.h"
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
void HailSay(char *name, char *title, char *text);
void Orbit(int arrive, int say);
void Debrief(int n, int msg, int score, int max);
void ClearMsgs(void);
/* seg008 */
void MsgBox(char *title, char *text, int x, int y, int color, int msg);
/* seg000 */
int StartAnim(int n, char *name, int x, int y, int scale);
void EndAnim(int n);
/* seg017 */
void RenderR3(int statics);
/* seg020 */
void BoostEnd(void);
/* seg036 */
void VengArrive(void);

void SinsArrive(void);
void SinsProxima(void);

extern char *crew_names[8];
extern int word_45AA2;
extern int in_orbit;
extern void (far *bridge_tick)(void);
extern int word_45AB2;
extern int word_45AB4;
extern int msg_head;
extern int word_50CA6;
extern unsigned long bridge_ticks;
extern int mission_vars[6];
extern void (far *saved_tick)(void);
extern int word_52C1E;
extern char mission[16];

/* Arriving: the fly-by, Starfleet's orders, and on to Proxima. */
void SinsArrive(void)
{
    Msg m;
    int unused;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            LoadMusic("bridge");
            BoostEnd();
            strcpy(mission, "sins");
            SetTextFile(mission);
            MemSet(mission_vars, 12, 0);
            saved_tick = SinsArrive;
            CutScene("devilmon", "SIN0\\FLYBY");
            break;
        case 0x97:
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(0), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(1), 0xA0, 0x82, 0xB0, 0);
            HailSay("woman", "Admiral", GetText(2));
            MsgBox(crew_names[1], GetText(3), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[0], GetText(4), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(5), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[5], GetText(6), 0xC4, 0x74, 0xB0, 0);
            MsgBox(crew_names[1], GetText(7), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[0], GetText(8), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(9), 0x126, 0x6A, 0x2C, 0);
            word_45AB4 = 11;
            break;
        }
        BridgeMsg();
        return;
    } else if (m.type == 1 && m.arg == 0x40)
        MsgBox(crew_names[6], GetText(10), 0x12A, 0x96, 0xA1, 0);
    else if (m.type == 1 && m.arg == 0x20)
        MsgBox(crew_names[1], GetText(11), 0x126, 0x6A, 0x2C, 0);
    else if (m.type == 1 && m.arg == 0x60) {
        BridgeMsg();
        if (word_45AB2 == word_45AB4) {
            bridge_ticks = 0;
            bridge_tick = SinsProxima;
        }
        return;
    } else {
        BridgeMsg();
        return;
    }
    msg_head = (msg_head + 1) % 16;
    return;
}

/* At Proxima: the landing party, then the debriefing and on to the last
 * mission. */
void SinsProxima(void)
{
    Msg m;
    int unused;

    m = *PeekMsg();
    if (m.type == 0) {
        switch (bridge_ticks) {
        case 1:
            break;
        case 0x97:
            break;
        }
        BridgeMsg();
        return;
    } else if (m.type == 1 && m.arg == 0x40) {
        if (mission_vars[0])
            MsgBox(crew_names[6], GetText(12), 0x12A, 0x96, 0xA1, 0);
        else
            MsgBox(crew_names[6], GetText(13), 0x12A, 0x96, 0xA1, 0);
    } else if (m.type == 1 && m.arg == 0x20) {
        if (in_orbit == 0)
            MsgBox(crew_names[1], GetText(14), 0x126, 0x6A, 0x2C, 0);
        else if (mission_vars[0] == 0) {
            mission_vars[0] = 1;
            MsgBox(crew_names[1], GetText(15), 0x126, 0x6A, 0x2C, 0);
            MsgBox(crew_names[4], GetText(16), 0x7A, 0x74, 0xB0, 0);
            MsgBox(crew_names[0], GetText(17), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[6], GetText(18), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(19), 0xA0, 0x82, 0xB0, 0);
            MsgBox(crew_names[1], GetText(20), 0x126, 0x6A, 0x2C, 0);
        } else
            MsgBox(crew_names[1], GetText(21), 0x126, 0x6A, 0x2C, 0);
    } else if (m.type == 6) {
        word_45AA2 = 1;
        RenderR3(0);
        StartAnim(1, "xstndsp", 0, 0, 256);
        StartAnim(2, "xstndmc", 0, 0, 256);
        UpdateSprites();
        BridgeSfx(0x22);
        MsgBox(crew_names[6], GetText(22), 0x12A, 0x96, 0xA1, 0);
        MsgBox(crew_names[0], GetText(23), 0xA0, 0x82, 0xB0, 1);
        Debrief(5, 24, word_50CA6, word_52C1E);
        MsgBox(crew_names[2], GetText(25), 0xA0, 0x64, 0x2C, 0);
        MsgBox(crew_names[1], GetText(26), 0x126, 0x6A, 0x2C, 0);
        MsgBox(crew_names[2], GetText(27), 0xA0, 0x64, 0x2C, 0);
        MsgBox(crew_names[0], GetText(28), 0xA0, 0x82, 0xB0, 0);
        MsgBox(crew_names[0], GetText(29), 0xA0, 0x64, 0x2C, 0);
        MsgBox(crew_names[2], GetText(30), 0xA0, 0x64, 0x2C, 0);
        MsgBox(crew_names[0], GetText(31), 0xA0, 0x82, 0xB0, 0);
        Orbit(0, 0);
        StartAnim(1, "bstndsp", 0, 0, 256);
        EndAnim(2);
        bridge_tick = VengArrive;
        bridge_ticks = 0;
        word_45AA2 = 0;
        ClearMsgs();
        return;
    } else {
        BridgeMsg();
        return;
    }
    msg_head = (msg_head + 1) % 16;
    return;
}
