/* seg020: ships in space - weapons, damage, power, movement and the
 * enemy ships' manoeuvres */

#include <stdio.h>
#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "sound.h"
#include "sprite.h"
#include "resource.h"
#include "fixmath.h"
#include "obj3d.h"

#define ABS(x)  ((x) > 0 ? (x) : -(x))

#define MAX_SHOTS   32

/* Which system a hit on a side damages: for a random 0..99, lo..hi. */
typedef struct DmgEntry {
    int lo;
    int hi;
    int sys;
} DmgEntry;

void Fatal(char *fmt, ...);     /* fatal error */
void MsgBox(char *title, char *msg, int a, int b, int c, int d);    /* seg008: message box */
void PostRoomMsg(int msg, int who, int a, int b);                     /* seg008: report */
void BridgeSfx(int n);              /* seg001: sound effect */
void RepairAll(Obj3D *o);           /* seg001 */
long sub_3A35E(long x, long y, long z);  /* seg027: length */
void Vec32Add(Vec32 *a, Vec32 *b);  /* seg027 */

/* seg006 */
void AddR3(Obj3D *o);
void DelR3(Obj3D *o);
int LoadShotShape(Obj3D *o);
void FreeShotShape(Obj3D *o);
int SelectView(Obj3D *o);
void ReleaseShipShape(Obj3D *o);

extern Obj3D *r3_list[48];
extern Obj3D player_ship;
extern Obj3D ships[4];
Shot shots[MAX_SHOTS];
extern unsigned long blink_count;
extern int under_attack;
extern char *crew_names[8];
extern int kbd_mouse;
extern Obj3D *last_target;          /* last ship the player hit */
int boost_active;            /* extra power from the engines */
long boost_count;
int boost_amount;
int boost_power;
int boost_time;

int FireShot(Obj3D *o, Weapon *w, Vec32 *dir, ShipPart *p);
void UpdateShots(void);
void ClearShots(void);
void UpdateShips(void);
void ShipAI(Obj3D *o);
int ShotHit(Shot *s, Obj3D *t);
int PixelHit(Shot *s, Obj3D *t);
void SetVec32(Vec32 *v, long x, long y, long z);
void SetSpeed(Obj3D *o, long speed);
void InitShips(char *name);
void ShotExplode(Shot *s, Obj3D *t);
void UpdatePower(Obj3D *o);
void HitShip(Obj3D *t, Shot *s);
int FindSide(Vec32 *v);
int DamageShip(Obj3D *t, DmgEntry *tab, int n, int dmg);
int WeakestSide(ShipPart *p);
void SetRepair(int sys);
void Repair(Obj3D *o);
void MoveShip(Obj3D *o);
void Bearing(Obj3D *o, Vec32 *to, int *pitch, int *yaw);
void AiWander(Obj3D *o);
void AiTurn(Obj3D *o);
void AiLoop(Obj3D *o);
void AiStrafe(Obj3D *o);
void FireAll(Obj3D *o, Vec32 v, Vec32 *dir);
int WeaponsReady(Obj3D *o);
void BoostInit(void);
int BoostStart(void);
void BoostEnd(void);
void SetPower(int shields, int weapons);

void UpdateShots(void)
{
    int i;
    int j;
    Shot *s;
    Obj3D *t;
    Obj3D **p;

    for (i = 0, s = shots; i != MAX_SHOTS; ++i, ++s) {
        if (s->visible == R3_SHOT) {
            if (s->life-- <= 0)
                DelR3((Obj3D *)s);
            else {
        if (s->kind != 3) {
            for (j = 0, p = r3_list; j != 48; ++j, ++p) {
                if ((t = *p) == 0)
                    continue;
                if (t->visible == R3_SHIP && t != s->owner && ShotHit(s, t) == 1) {
                    if ((t != &player_ship) ^ (s->owner != &player_ship)) {
                        ShotExplode(s, t);
                        HitShip(t, s);
                        if (t != &player_ship)
                            last_target = t;
                    }
                    break;
                }
            }
        }
        MoveShip((Obj3D *)s);
            }
        }
    }
}

void ClearShots(void)
{
    int i;
    int j;
    Shot *s;
    Obj3D *t;
    Obj3D **p;

    for (i = 0, s = shots; i != MAX_SHOTS; ++i, ++s)
        if (s->visible == R3_SHOT)
            DelR3((Obj3D *)s);
}

/* Is shot s within t's reach on every axis? */
int ShotHit(Shot *s, Obj3D *t)
{
    long r;
    Vec32 d;

    r = t->reach;
    d = s->pos;
    Vec32Sub(&d, &t->pos);
    if (d.z < -r)
        return 0;
    if (d.z > r)
        return 0;
    if (d.y < -r)
        return 0;
    if (d.y > r)
        return 0;
    if (d.x < -r)
        return 0;
    if (d.x > r)
        return 0;
    return 1;
}

void SetVec32(Vec32 *v, long x, long y, long z)
{
    v->x = x;
    v->y = y;
    v->z = z;
}

/* Accelerate a ship towards speed (16.16) and set its velocity. */
void SetSpeed(Obj3D *o, long speed)
{
    int s;
    long d;

    if (o->visible == R3_SHIP) {
        d = speed - o->mo.speed;
        d = max(-o->mo.accel, d);
        d = min(o->mo.accel, d);
        o->mo.speed += d;
        speed = o->mo.speed;
    }
    s = speed >> 16;
    o->vx = FixMul(s, o->orient.e[2][0]);
    o->vy = FixMul(s, o->orient.e[2][1]);
    o->vz = FixMul(s, o->orient.e[2][2]);
}

char *side_names[6] = { "starboard", "aft", "port", "forward", "upper", "lower" };

/* Turn shot s into a small explosion moving with t. */
void ShotExplode(Shot *s, Obj3D *t)
{
    s->kind = 3;
    s->life = 8;
    s->reach = 60;
    s->size = 6;
    s->orient = t->orient;
    s->vx = t->vx;
    s->vy = t->vy;
    s->vz = t->vz;
}

/* The side of a ship facing v (ship coordinates), for side_names. */
int FindSide(Vec32 *v)
{
    if (ABS(v->x) >= ABS(v->y) && ABS(v->x) >= ABS(v->z)) {
        if (v->x < 0)
            return 2;
        else
            return 0;
    }
    if (ABS(v->y) >= ABS(v->x) && ABS(v->y) >= ABS(v->z)) {
        if (v->y < 0)
            return 5;
        else
            return 4;
    }
    if (ABS(v->z) >= ABS(v->x) && ABS(v->z) >= ABS(v->y)) {
        if (v->z < 0)
            return 1;
        else
            return 3;
    }
    Fatal("this is in FindSide and is impossible.");
}

/* The pitch and yaw that would turn o towards to. */
void Bearing(Obj3D *o, Vec32 *to, int *pitch, int *yaw)
{
    Matrix m;
    Matrix mt;
    Vec32 d;
    Vec32 f;
    Vec32 v;
    Vec32 unused;
    long len;

    d = *to;
    f = o->pos;
    m = o->orient;
    Vec32Sub(&d, &f);
    MatTranspose(&m, &mt);
    MatTVecMul32(&d, &mt, &v);
    d = v;
    len = (unsigned)VecLen32(&d.x);
    if (len < 1)
        len = 1;
    *pitch = -FixASin(FixDiv(d.y, len));
    *yaw = FixAtan2(d.x, d.z);
}

/* Pitch round at full speed. */
void AiTurn(Obj3D *o)
{
    switch (o->ai_state) {
    case 0:
        o->mo.target_speed = o->mo.max_speed;
        o->mo.turn_target[0] = o->mo.turn_max * (rand() & 1 ? -1 : 1);
        o->mo.turn_target[1] = 0;
        o->mo.turn_target[2] = 0;
        o->mo.turn_sum[0] = 0;
        o->ai_state++;
        break;
    case 1:
        if (o->mo.turn_sum[0] >= 0x2000000L) {
            if (o->ddist > 0)
                o->ai_busy = 0;
            o->ai_state++;
            return;
        }
        break;
    case 2:
        if (o->mo.turn_sum[0] >= 0x4000000L) {
            o->ai_busy = 0;
            return;
        }
        break;
    }
    MoveShip(o);
}

/* Fly straight, pull up, turn, pull up again. */
void AiLoop(Obj3D *o)
{
    switch (o->ai_state) {
    case 0:
        o->mo.target_speed = o->mo.max_speed;
        o->mo.turn_target[0] = 0;
        o->mo.turn_target[1] = 0;
        o->mo.turn_target[2] = 0;
        o->mo.timer = 32;
        o->ai_state++;
        break;
    case 1:
        if (o->mo.timer < 0) {
            o->mo.turn_target[0] = -o->mo.turn_max;
            o->mo.turn_sum[0] = 0;
            o->ai_state++;
        }
        break;
    case 2:
        if (o->mo.turn_sum[0] >= 0x1000000L) {
            o->mo.turn_target[0] = 0;
            o->mo.timer = 48;
            o->ai_state++;
        }
        break;
    case 3:
        if (o->mo.timer < 0) {
            o->mo.turn_target[1] = o->mo.turn_max * (rand() & 1 ? -1 : 1);
            o->mo.turn_sum[1] = 0;
            o->ai_state++;
        }
        break;
    case 4:
        if (o->mo.turn_sum[1] >= 0x2000000L) {
            o->mo.turn_target[1] = 0;
            o->mo.timer = 48;
            o->ai_state++;
        }
        break;
    case 5:
        if (o->mo.timer < 0) {
            o->mo.turn_target[0] = -o->mo.turn_max;
            o->mo.turn_sum[0] = 0;
            o->ai_state++;
        }
        break;
    case 6:
        if (o->mo.turn_sum[0] >= 0x1000000L) {
            o->mo.turn_target[0] = 0;
            o->mo.timer = 48;
            o->ai_state++;
        }
        break;
    case 7:
        if (o->mo.timer < 0) {
            o->mo.turn_target[0] = -o->mo.turn_max;
            o->mo.turn_sum[0] = 0;
            o->ai_state++;
        }
        break;
    case 8:
        o->ai_busy = 0;
        return;
    }
    MoveShip(o);
}

/* Random quarter turns on one axis at a time, until out of range. */
void AiStrafe(Obj3D *o)
{
    switch (o->ai_state) {
    case 0:
        if (o->ddist > 0 && o->dist > o->range)
            o->ai_busy = 0;
        else {
            o->mo.target_speed = o->mo.max_speed;
            o->mo.turn_target[0] = 0;
            o->mo.turn_target[1] = 0;
            o->mo.turn_target[2] = 0;
            o->mo.timer = rand() & 0x3F;
            o->ai_state++;
        }
        break;
    case 1:
        if (o->mo.timer < 0)
            o->ai_state = (rand() & 3) * 2;
        break;
    case 2:
        if (o->ddist > 0 && o->dist > o->range)
            o->ai_busy = 0;
        else {
            o->mo.target_speed = o->mo.max_speed;
            o->mo.turn_target[0] = o->mo.turn_max * (rand() & 1 ? -1 : 1);
            o->mo.turn_target[1] = 0;
            o->mo.turn_target[2] = 0;
            o->mo.turn_sum[0] = 0;
            o->ai_state++;
        }
        break;
    case 3:
        if (o->mo.turn_sum[0] >= 0x1000000L)
            o->ai_state = (rand() & 3) * 2;
        break;
    case 4:
        if (o->ddist > 0 && o->dist > o->range)
            o->ai_busy = 0;
        else {
            o->mo.target_speed = o->mo.max_speed;
            o->mo.turn_target[0] = 0;
            o->mo.turn_target[1] = o->mo.turn_max * (rand() & 1 ? -1 : 1);
            o->mo.turn_target[2] = 0;
            o->mo.turn_sum[1] = 0;
            o->ai_state++;
        }
        break;
    case 5:
        if (o->mo.turn_sum[1] >= 0x1000000L)
            o->ai_state = (rand() & 3) * 2;
        break;
    case 6:
        if (o->ddist > 0 && o->dist > o->range)
            o->ai_busy = 0;
        else {
            o->mo.target_speed = o->mo.max_speed;
            o->mo.turn_target[1] = 0;
            o->mo.turn_target[2] = 0;
            o->mo.turn_target[2] = o->mo.turn_max * (rand() & 1 ? -1 : 1);
            o->mo.turn_sum[2] = 0;
            o->ai_state++;
        }
        break;
    case 7:
        if (o->mo.turn_sum[2] >= 0x1000000L)
            o->ai_state = (rand() & 3) * 2;
        break;
    }
    MoveShip(o);
}

int WeaponsReady(Obj3D *o)
{
    int i;

    for (i = 0; i != 4; i++)
        if (blink_count > o->weapons[i].next)
            return 1;
    return 0;
}

void BoostInit(void)
{
    boost_power = 30;
    boost_time = 450;
}

int BoostStart(void)
{
    if (boost_active == 0) {
        boost_active = 1;
        boost_count = boost_time;
        boost_amount = boost_power;
        return 1;
    } else
        return 0;
}

