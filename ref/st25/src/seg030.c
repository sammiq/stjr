/* seg030: the bridge script for the second mission, "Hijacked" (the Elasi
 * pirates and the USS Masada) */

#include <string.h>
#include <stdio.h>
#include "mem.h"
#include "cache.h"
#include "event.h"
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
void FreeText(char *p);
void SetTextFile(char *name);
void CutScene(char *name, char *voc);
void HailShow(char *name);
void HailRestart(void);
void HailEnd(void);
void HailSay(char *name, char *title, char *text);
void Orbit(int arrive, int say);
void Debrief(int n, int msg, int score, int max);
void ShuttleFlyby(int kind);
void ShuttleEnd(void);
void ClearMsgs(void);
char *GetChoice(int n, int *list, int x);
/* seg002 */
char *InputCode(void);
/* seg008 */
void MsgBox(char *title, char *text, int x, int y, int color, int msg);
long TextBox(char *(far *fn)(), int *arg, int x, int y, int color, int choice, int maxl,
             int flag);
/* seg000 */
int StartAnim(int n, char *name, int x, int y, int scale);
void EndAnim(int n);
/* seg020 */
void BoostEnd(void);
void InitShips(char *name);
/* seg017 */
void DelR3(Obj3D *o);
/* seg031 */
void LoveArrive(void);

void TugArrive(void);
void TugPirates(void);
void TugDisabled(void);
void TugOrbit(void);
void TugReturn(void);
void ElasiSay44(void);
void UhuraSay45(void);
void ElasiSay46(void);
void ElasiSay47(void);
void ElasiSay50(void);
void ElasiSay51(void);
void ScottSay52(void);
void SuluSay53(void);
void ElasiSay54(void);
void KirkSay58(void);
void SpockHostages(void);
void UhuraSay63(void);
void MissionCalledOff(void);
void ElasiTalk(void);

extern char *crew_names[8];
extern int word_45AA2;
extern int in_orbit;
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
Sprite flash_sprite;

char elasi_cereth[] = "Elasi Cereth";
char elasi_captain[] = "Elasi Captain";
char admiral[] = "Admiral";
int talk_choices1[] = { 0x12, 0x13, -1 };
int talk_choices2[] = { 0x30, 0x31, -1 };
int talk_choices3[] = { 0x37, 0x38, 0x39, -1 };
int talk_choices4[] = { 0x3D, 0x3E, -1 };
int talk_choices5[] = { 0x42, 0x43, 0x44, -1 };

/* Arriving: the fly-by and Starfleet's orders. */
void TugArrive(void)
{
    Msg m;
    int k;

    word_45AB4 = 14;
    m = *PeekMsg();
    if (word_45AB2 == word_45AB4) {
        bridge_ticks = 0;
        bridge_tick = TugPirates;
        return;
    }
    if (m.type == 0) {
        k = m.arg + (m.b2 << 8);
        switch (k) {
        case 1:
            LoadMusic("bridge");
            word_50CA6 = 0;
            word_52C1E = 0x20;
            word_51156 = 0;
            BoostEnd();
            strcpy(mission, "tug");
            MemSet(mission_vars, 12, 0);
            SetTextFile(mission);
            saved_tick = TugArrive;
            CutScene("hijacked", "TUG0\\FLYBY");
            break;
        case 0x96:
            PlayMusic(0, -1);
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(0), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(1), 0xA0, 0x82, 0xB0, 0);
            break;
        case 0xAA:
            HailSay("woman", admiral, GetText(2));
            break;
        case 0xAF:
            MsgBox(crew_names[5], GetText(3), 0xC4, 0x74, 0xB0, 0);
            break;
        }
    }
    switch (m.type) {
    case 1:
        switch (m.arg) {
        case 0x40:
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[6], GetText(4), 0x12A, 0x96, 0xA1, 0);
            break;
        case 0x20:
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[1], GetText(5), 0x126, 0x6A, 0x2C, 0);
            break;
        }
        break;
    }
    BridgeMsg();
    return;
}

/* At Beta Myamid: the Elasi pirates hail, then attack. */
void TugPirates(void)
{
    Msg m;
    int k;
    ShipPart *p;
    int i;

    m = *PeekMsg();
    if (m.type == 0) {
        k = m.arg + (m.b2 << 8);
        switch (k) {
        case 0x20:
            MsgBox(crew_names[1], GetText(6), 0x126, 0x6A, 0x2C, 0);
            break;
        case 0x40:
            BridgeSfx(0x22);
            MsgBox(crew_names[6], GetText(7), 0x12A, 0x96, 0xA1, 0);
            MsgBox(crew_names[0], GetText(8), 0xA0, 0x82, 0xB0, 0);
            HailShow("pira");
            MsgBox(elasi_captain, GetText(9), 0xA0, 0xBE, 0x2C, 0);
            MsgBox(crew_names[0], GetText(10), 0xA0, 0x82, 0xB0, 0);
            HailRestart();
            MsgBox(elasi_captain, GetText(11), 0xA0, 0xBE, 0x2C, 0);
            HailEnd();
            BridgeSfx(0x28);
            break;
        case 0x80:
            InitShips("orion");
            under_attack = 1;
            PlayMusic(2, -3);
        }
    }
    switch (m.type) {
    case 1:
        switch (m.arg) {
        case 0x50:
            msg_head = (msg_head + 1) % 16;
            break;
        case 0x40:
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[6], GetText(12), 0x12A, 0x96, 0xA1, 0);
            break;
        case 0x20:
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[1], GetText(13), 0x126, 0x6A, 0x2C, 0);
            break;
        }
        break;
    }
    if (under_attack && ships[0].systems[SYS_HULL].cur < ships[0].systems[SYS_HULL].max >> 1) {
        PlayMusic(3, -1);
        MsgBox(crew_names[5], GetText(14), 0xC4, 0x74, 0xB0, 0);
        MsgBox(crew_names[1], GetText(15), 0x126, 0x6A, 0x2C, 0);
        for (p = &ships[0].systems[SYS_TORP_PORT], i = 0; i != 4; ++i, ++p)
            p->unk = 0;
        bridge_ticks = 0;
        bridge_tick = TugDisabled;
        ships[0].flee = 1;
    }
    BridgeMsg();
}

/* The pirate ship disabled: orbit to beam over. */
void TugDisabled(void)
{
    Msg m;
    int unused;

    m = *PeekMsg();
    switch (m.type) {
    case 1:
        switch (m.arg) {
        case 0x50:
            msg_head = (msg_head + 1) % 16;
            if (ships[0].visible)
                DelR3(&ships[0]);
            ShuttleFlyby(6);
            in_orbit = 1;
            bridge_ticks = 0;
            bridge_tick = TugOrbit;
            return;
            break;
        case 0x40:
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[6], GetText(16), 0x12A, 0x96, 0xA1, 0);
            break;
        case 0x20:
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[1], GetText(17), 0x126, 0x6A, 0x2C, 0);
            break;
        }
        break;
    }
    BridgeMsg();
}

/* In orbit by the Masada: talking to the Elasi, the prefix code. */
void TugOrbit(void)
{
    Msg m;
    int k;

    m = *PeekMsg();
    if (m.type == 0) {
        k = m.arg + (m.b2 << 8);
        switch (k) {
        case 0x10:
            MsgBox(crew_names[1], GetText(20), 0xA0, 0xBE, 0x2C, 0);
            break;
        }
    }
    switch (m.type) {
    case 1:
        switch (m.arg) {
        case 0x40: {
            int choice;

            choice = 0;
            msg_head = (msg_head + 1) % 16;
            if (mission_vars[2] == 1)
                choice = TextBox(GetChoice, talk_choices1, 0xA0, 0x82, 0xB0, 1, 0, 0);
            else
                choice = 0;
            switch (choice) {
            case 0:
                MsgBox(crew_names[6], GetText(21), 0x12A, 0x96, 0xA1, 0);
                if (mission_vars[3] == 0) {
                    ElasiTalk();
                    mission_vars[3] = 1;
                } else {
                    HailShow("pira");
                    MsgBox(elasi_cereth, GetText(22), 0xA0, 0xBE, 0x2C, 0);
                    MsgBox(crew_names[0], GetText(23), 0xA0, 0x82, 0xB0, 0);
                    HailEnd();
                    mission_vars[0] += 1;
                    SpockHostages();
                }
                if (mission_vars[0] > 4) {
                    word_51156 = 2;
                    bridge_ticks = 0;
                    bridge_tick = TugReturn;
                    return;
                }
                break;
            case 1:
                if (strcmp("293391-197736-3829", InputCode()) == 0) {
                    MsgBox(crew_names[6], GetText(25), 0x12A, 0x96, 0xA1, 0);
                    mission_vars[1] = 1;
                } else
                    MsgBox(crew_names[6], GetText(26), 0x12A, 0x96, 0xA1, 0);
                break;
            }
            break;
        }
        case 0x20:
            msg_head = (msg_head + 1) % 16;
            MsgBox(crew_names[1], GetText(27), 0x126, 0x6A, 0x2C, 0);
            mission_vars[2] = 1;
            break;
        case 0x11:
            if (mission_vars[1] == 0) {
                MsgBox(crew_names[4], GetText(28), 0x7A, 0x74, 0xA1, 0);
                msg_head = (msg_head + 1) % 16;
                return;
            }
            break;
        }
        break;
    case 6:
        bridge_ticks = 0;
        bridge_tick = TugReturn;
        return;
        break;
    }
    BridgeMsg();
}

/* Back from the Masada: the debriefing for how it went, then on to the
 * next mission. */
void TugReturn(void)
{
    Msg m;

    m = *PeekMsg();
    switch (m.type) {
    case 0:
        switch (bridge_ticks) {
        case 1:
            word_45AA2 = 1;
            if (word_51156 == 2)
                break;
            StartAnim(1, "xstndsp", 0, 0, 256);
            StartAnim(2, "xstndmc", 0, 0, 256);
            if (word_51156 == 1)
                ShuttleEnd();
            break;
        case 0x14:
            if (word_51156 == 0) {
                BridgeSfx(0x22);
                MsgBox(crew_names[6], GetText(29), 0x12A, 0x96, 0xA1, 0);
                MsgBox(crew_names[0], GetText(30), 0xA0, 0x82, 0xB0, 0);
                Debrief(1, 31, word_50CA6, word_52C1E);
                MsgBox(crew_names[2], GetText(32), 0xA0, 0x64, 0x2C, 0);
                MsgBox(crew_names[1], GetText(33), 0x126, 0x6A, 0x2C, 0);
                MsgBox(crew_names[2], GetText(34), 0xA0, 0x64, 0x2C, 0);
                MsgBox(crew_names[0], GetText(35), 0xA0, 0x82, 0xB0, 0);
                MsgBox(crew_names[1], GetText(36), 0x126, 0x6A, 0x2C, 0);
                MsgBox(crew_names[0], GetText(37), 0xA0, 0x82, 0xB0, 0);
            } else if (word_51156 == 1) {
                BridgeSfx(0x22);
                MsgBox(crew_names[6], GetText(39), 0x12A, 0x96, 0xA1, 0);
                MsgBox(crew_names[0], GetText(40), 0xA0, 0x82, 0xB0, 0);
                Debrief(1, 41, 0, 0);
            } else if (word_51156 == 2) {
                BridgeSfx(0x22);
                MsgBox(crew_names[6], GetText(42), 0x12A, 0x96, 0xA1, 0);
                Debrief(1, 43, 0, 0);
            }
            ShuttleEnd();
            Orbit(0, 0);
            StartAnim(1, "bstndsp", 0, 0, 256);
            EndAnim(2);
            bridge_ticks = 0;
            bridge_tick = LoveArrive;
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

/* Lines of the talk with the Elasi. */
void ElasiSay44(void)
{
    HailRestart();
    MsgBox(elasi_cereth, GetText(44), 0xA0, 0xBE, 0x2C, 0);
}

void UhuraSay45(void)
{
    MsgBox(crew_names[6], GetText(45), 0x12A, 0x96, 0xA1, 0);
}

void ElasiSay46(void)
{
    HailRestart();
    MsgBox(elasi_cereth, GetText(46), 0xA0, 0xBE, 0x2C, 0);
}

void ElasiSay47(void)
{
    HailRestart();
    MsgBox(elasi_cereth, GetText(47), 0xA0, 0xBE, 0x2C, 0);
}

void ElasiSay50(void)
{
    HailRestart();
    MsgBox(elasi_cereth, GetText(50), 0xA0, 0xBE, 0x2C, 0);
}

void ElasiSay51(void)
{
    HailRestart();
    MsgBox(elasi_cereth, GetText(51), 0xA0, 0xBE, 0x2C, 0);
}

void ScottSay52(void)
{
    MsgBox(crew_names[7], GetText(52), 0x40, 0x64, 0xA1, 0);
}

void SuluSay53(void)
{
    MsgBox(crew_names[4], GetText(53), 0x7A, 0x74, 0xB0, 0);
}

void ElasiSay54(void)
{
    HailRestart();
    MsgBox(elasi_cereth, GetText(54), 0xA0, 0xBE, 0x2C, 0);
}

void KirkSay58(void)
{
    MsgBox(crew_names[0], GetText(58), 0xA0, 0x82, 0xB0, 0);
}

/* Spock counts the hostages killed. */
void SpockHostages(void)
{
    char buf[80];

    sprintf(buf, GetText(60));
    FreeText(0);
    MsgBox(crew_names[1], buf, 0x126, 0x6A, 0x2C, 0);
}

void UhuraSay63(void)
{
    BridgeSfx(0x22);
    MsgBox(crew_names[6], GetText(63), 0x12A, 0x96, 0xA1, 0);
}

/* Starfleet calls the mission off. */
void MissionCalledOff(void)
{
    MsgBox(admiral, GetText(64), 0xA0, 0xBE, 0x2C, -7);
    Orbit(0, 0);
    bridge_ticks = 0;
    bridge_tick = LoveArrive;
    return;
}

/* The talk with Elasi Cereth. */
void ElasiTalk(void)
{
    int unused;
    int r;

    r = 0;
    HailShow("pira");
    MsgBox(elasi_cereth, GetText(65), 0xA0, 0xBE, 0x2C, 0);
    switch (TextBox(GetChoice, talk_choices5, 0xA0, 0x82, 0xB0, 1, 0, 0)) {
    case 0:
        goto a;
    case 1:
        goto b;
    case 2:
        goto c;
    }
a:
    ElasiSay44();
    UhuraSay45();
    goto d;
b:
    mission_vars[0] += 1;
    ElasiSay46();
    SpockHostages();
    goto d;
c:
    ElasiSay47();
    goto a;
d:
    switch (TextBox(GetChoice, talk_choices2, 0xA0, 0x82, 0xB0, 1, 0, 0)) {
    case 0:
        goto e;
    case 1:
        goto e;
    }
    ElasiSay50();
    goto f;
e:
    ElasiSay51();
    ScottSay52();
    SuluSay53();
    ElasiSay54();
    goto f;
f:
    switch (TextBox(GetChoice, talk_choices3, 0xA0, 0x82, 0xB0, 1, 0, 0)) {
    case 0:
        goto end;
    case 1:
        goto g;
    case 2:
        goto h;
    }
    KirkSay58();
    goto h;
g:
    HailRestart();
    MsgBox(elasi_cereth, GetText(69), 0xA0, 0xBE, 0x2C, 0);
    goto end;
h:
    HailRestart();
    MsgBox(elasi_cereth, GetText(70), 0xA0, 0xBE, 0x2C, 0);
    mission_vars[0] += 1;
    SpockHostages();
    HailRestart();
    MsgBox(elasi_cereth, GetText(71), 0xA0, 0xBE, 0x2C, 0);
    if (mission_vars[0] > 4)
        r = 2;
    goto end;
i:
    if (mission_vars[0] > 4)
        goto j;
    MsgBox(crew_names[6], GetText(72), 0x12A, 0x96, 0xA1, 0);
    HailRestart();
    MsgBox(elasi_cereth, GetText(73), 0xA0, 0xBE, 0x2C, 0);
    goto k;
k:
    switch (TextBox(GetChoice, talk_choices4, 0xA0, 0x82, 0xB0, 1, 0, 0)) {
    case 0:
        goto l;
    case 1:
        goto i;
    }
j:
    UhuraSay63();
    MissionCalledOff();
    goto end;
l:
    HailRestart();
    MsgBox(elasi_cereth, GetText(74), 0xA0, 0xBE, 0x2C, 0);
    mission_vars[0] += 2;
    SpockHostages();
    goto end;
end:
    HailEnd();
}

/* Show bitmap name over everything at layer z (5 if out of range) for a
 * few ticks. */
void FlashBitmap(char *name, int z)
{
    unsigned long t;

    if (z < 0 || z > 15)
        z = 5;
    AddSprite(&flash_sprite);
    SpriteSetPos(&flash_sprite, 0, 0, z);
    SpriteSetBitmap(&flash_sprite, LoadBitmap(name));
    UpdateSprites();
    t = GetTicks() + 5;
    while (GetTicks() < t)
        SpriteErase(&flash_sprite);
    UpdateSprites();
    ReleaseBitmap(flash_sprite.handle);
    DelSprite(&flash_sprite);
}
