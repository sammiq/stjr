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

void (far *ai_moves[3])(Obj3D *o) = { AiTurn, AiLoop, AiStrafe };

DmgEntry dmg_t0[10] = {
    { 0, 19, 9 }, { 20, 24, 8 }, { 25, 34, 7 }, { 35, 39, 1 }, { 40, 49, 6 },
    { 50, 51, 4 }, { 52, 54, 5 }, { 55, 56, 2 }, { 57, 59, 3 }, { 60, 99, 0 }
};
DmgEntry dmg_t1[4] = {
    { 0, 24, 9 }, { 25, 49, 8 }, { 50, 64, 7 }, { 65, 99, 0 }
};
DmgEntry dmg_t2[10] = {
    { 0, 19, 8 }, { 20, 24, 9 }, { 25, 34, 7 }, { 35, 39, 1 }, { 40, 49, 6 },
    { 50, 51, 5 }, { 52, 54, 4 }, { 55, 56, 3 }, { 57, 59, 2 }, { 60, 99, 0 }
};
DmgEntry dmg_t3[9] = {
    { 0, 9, 8 }, { 10, 19, 9 }, { 20, 24, 1 }, { 25, 39, 6 }, { 40, 44, 5 },
    { 45, 49, 4 }, { 50, 54, 3 }, { 55, 59, 2 }, { 60, 99, 0 }
};
DmgEntry dmg_t4[7] = {
    { 0, 19, 8 }, { 20, 39, 9 }, { 40, 49, 7 }, { 50, 54, 1 }, { 55, 56, 3 },
    { 57, 59, 2 }, { 60, 99, 0 }
};
DmgEntry dmg_t5[9] = {
    { 0, 14, 8 }, { 15, 29, 9 }, { 30, 34, 7 }, { 35, 44, 6 }, { 45, 49, 5 },
    { 50, 54, 4 }, { 55, 57, 3 }, { 58, 59, 2 }, { 60, 99, 0 }
};
DmgEntry *dmg_tables[6] = { dmg_t0, dmg_t1, dmg_t2, dmg_t3, dmg_t4, dmg_t5 };
int dmg_counts[6] = { 10, 4, 10, 9, 7, 9 };
int dmg_unused[2] = { 0, 0 };

/* Fire weapon w of o, along dir or straight ahead, using system p.
 * Returns 1 if a shot went. */
int FireShot(Obj3D *o, Weapon *w, Vec32 *dir, ShipPart *p)
{
    int i;
    Shot *s;
    Vec32 v;
    Vec32 unused;
    long len;
    int damage;

    if (p->cur < p->max >> 1 || w->next > blink_count || p->unk == 0 || o->weapons_pwr == 0)
        return 0;
    damage = p->max;
    for (i = 0, s = shots; i != MAX_SHOTS; ++i, ++s) {
        if (s->visible == 0) {
            MemSet(s, sizeof(Shot), 0);
            s->pos = o->pos;
            MatTVecMul32(&w->ofs, &o->orient, &v);
            Vec32Add(&s->pos, &v);
            if (dir == 0)
                s->orient = o->orient;
            else {
                len = (unsigned)VecLen32(&dir->x);
                if (len == 0)
                    len = 1;
                s->orient.e[2][0] = FixDiv(dir->x, len);
                s->orient.e[2][1] = FixDiv(dir->y, len);
                s->orient.e[2][2] = FixDiv(dir->z, len);
            }
            s->visible = R3_SHOT;
            s->kind = w->kind;
            s->reach = 60;
            s->size = 3;
            SetSpeed((Obj3D *)s, ((long)w->speed << 16) + o->mo.speed);
            s->draw = LoadShotShape;
            s->free = FreeShotShape;
            s->owner = o;
            s->life = w->life;
            s->damage = damage;
            switch (o->kind) {
            case 2:
                s->color = 0xEA;
                break;
            case 1:
                s->color = 0xB8;
                break;
            case 0:
                s->color = 0xA0;
                break;
            }
            w->next = w->delay + blink_count;
            AddR3((Obj3D *)s);
            return 1;
        }
    }
    return 0;
}

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

void UpdateShips(void)
{
    Obj3D *o;

    under_attack = 0;
    for (o = ships; o != &ships[4]; o++)
        if (o->visible) {
            ShipAI(o);
            under_attack = 1;
        }
}

/* An enemy ship's turn: fight the player, run a manoeuvre, or flee. */
void ShipAI(Obj3D *o)
{
    Matrix mt;
    Vec32 v;
    Vec32 d;
    long dist;
    long spd;
    int pitch;
    int yaw;
    int n;

    if (o->expl) {
        MoveShip(o);
        return;
    }
    UpdatePower(o);
    Repair(o);
    if (o->has_shields)
        o->shields_up = 1;
    n = o->systems[SYS_SENSORS].max * 3 >> 2;
    if (rand() % n > o->systems[SYS_SENSORS].cur) {
        MoveShip(o);
        return;
    }
    d = player_ship.pos;
    Vec32Sub(&d, &o->pos);
    MatTranspose(&o->orient, &mt);
    MatTVecMul32(&d, &mt, &v);
    dist = sub_3A35E(d.x, d.y, d.z);
    o->ddist = dist - o->dist;
    o->dist = dist;
    if (o->has_shields) {
        long ax;
        long ay;

        ax = ABS(v.x);
        ay = ABS(v.y);
        if (max(ax, ay) << 2 < v.z)
            o->shields_up = 0;
        if (o->shield_glow == 0)
            FireAll(o, v, &d);
    } else
        FireAll(o, v, &d);
    if (o->flee == 1) {
        if (o->dist > 12000) {
            DelR3(o);
            o->visible = 0;
            return;
        }
        pitch = FixASin(FixDiv(v.y, dist));
        yaw = -FixAtan2(v.x, v.z);
        o->mo.target_speed = o->mo.max_speed;
        o->mo.turn_target[0] = (long)pitch << 16;
        o->mo.turn_target[1] = (long)yaw << 16;
        o->mo.turn_target[2] = 0;
        MoveShip(o);
        return;
    }
    if (o->mo.speed_limit < o->mo.target_speed >> 2) {
        spd = 0;
        o->ai_busy = 0;
    } else {
        if (o->ai_busy) {
            o->ai(o);
            return;
        }
        if (dist <= o->range) {
            o->ai_busy = 1;
            o->ai = ai_moves[rand() % 3];
            o->ai_state = 0;
            return;
        }
        if (dist > o->range << 2)
            spd = o->mo.max_speed >> 0;
        else if (dist > o->range * 3)
            spd = o->mo.max_speed >> 0;
        else if (dist > o->range << 1)
            spd = o->mo.max_speed >> 1;
        else
            spd = o->mo.max_speed >> 2;
    }
    pitch = -FixASin(FixDiv(v.y, dist));
    yaw = FixAtan2(v.x, v.z);
    o->mo.target_speed = spd;
    o->mo.turn_target[0] = (long)pitch << 16;
    o->mo.turn_target[1] = (long)yaw << 16;
    o->mo.turn_target[2] = 0;
    MoveShip(o);
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

/* Does shot s cover a set pixel of t's hit mask (the .sml bitmap)? */
int PixelHit(Shot *s, Obj3D *t)
{
    MemHandle h;
    Bitmap far *bmp;
    int dx;
    int dy;
    int u;
    int v;
    int bpr;
    int w8;
    unsigned char far *p;
    int r;
    char name[16];

    sprintf(name, "%s%02x", t->shape, t->view_idx & 0xFF);
    h = CacheLoad(name, "sml");
    bmp = LockMem(h);
    w8 = (bmp->w + 7) & 0xFFF8;
    bpr = w8 >> 3;
    dx = s->sx - t->sx;
    dy = s->sy - t->sy;
    u = dx * t->inv[0] + dy * t->inv[2];
    v = dx * t->inv[1] + dy * t->inv[3];
    if (u + bmp->x > bmp->w || u + bmp->x < 0)
        return 0;
    if (v + bmp->y > bmp->h || v + bmp->y < 0)
        return 0;
    if (t->view_idx & 0x8000) {
        dx = u + bmp->x;
        dx = w8 - dx - 1 - (w8 - bmp->w);
    } else
        dx = u + bmp->x;
    p = bmp->data;
    p += (v + bmp->y) * bpr + (dx >> 3);
    r = (*p & (0x80 >> (dx & 7))) ? 1 : 0;
    UnlockMem(h);
    CacheRelease(h);
    return r;
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

/* Bring in an enemy ship, described by name.dsc, near the player. */
void InitShips(char *name)
{
    Obj3D *o;
    ShipDesc desc;
    int unused;

    for (o = ships; o != &ships[4]; o++)
        if (o->visible == 0) {
            MemSet(o, sizeof(Obj3D), 0);
            o->pos = player_ship.pos;
            o->pos.x += (64 - (rand() & 0x7F)) * 16;
            o->pos.y += (64 - (rand() & 0x7F)) * 16;
            o->pos.z += (64 - (rand() & 0x7F)) * 16;
            LoadFilePacked(name, "dsc", (unsigned char far *)&desc);
            MatIdentity(&o->orient);
            o->visible = R3_SHIP;
            o->draw = SelectView;
            o->free = ReleaseShipShape;
            o->kind = desc.kind;
            o->reach = desc.reach;
            o->size = desc.size;
            MemCpy(o->shields, desc.shields, sizeof(o->shields));
            MemCpy(o->systems, desc.systems, sizeof(o->systems));
            o->mo = desc.mo;
            o->range = desc.range;
            o->has_shields = desc.has_shields;
            MemCpy(o->weapons, desc.weapons, sizeof(o->weapons));
            o->weapons_req = o->shields_req = 1;
            o->shield_glow = 1;
            o->flee = 0;
            AddR3(o);
            break;
        }
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

/* Share out the engines' power: shields, weapons, then speed. */
void UpdatePower(Obj3D *o)
{
    int unused;
    int p;
    int q;

    o->power = o->systems[SYS_WARP_PORT].cur + o->systems[SYS_WARP_STBD].cur
        + o->systems[SYS_IMPULSE].cur;
    if (o == &player_ship && boost_count) {
        o->power += boost_amount;
        boost_count--;
    }
    if (o->shields_req) {
        if (o->power >= 10) {
            o->power -= 10;
            o->shields_pwr = 1;
        } else if (o->shields_pwr) {
            PostRoomMsg(2, o != &player_ship, 0, 0);
            o->shields_pwr = 0;
        }
    } else
        o->shields_pwr = 0;
    if (o->shields_up) {
        if (o->power >= 20) {
            if (o->shields_on == 0)
                o->shield_glow = 0;
            o->power -= 20;
            o->shields_on = 1;
        } else
            o->shields_on = 0;
    } else
        o->shields_on = 0;
    if (o->weapons_req) {
        if (o->power >= 10) {
            o->power -= 10;
            o->weapons_pwr = 1;
        } else if (o->weapons_pwr) {
            PostRoomMsg(3, o != &player_ship, 0, 0);
            o->weapons_pwr = 0;
        }
    } else
        o->weapons_pwr = 0;
    p = min(o->power, 70);
    q = o->mo.target_speed * 70 / o->mo.max_speed;
    if (q > p) {
        o->mo.speed_limit = o->mo.max_speed * p / 70;
        o->power -= p;
    } else {
        o->mo.speed_limit = o->mo.target_speed;
        o->power -= q;
    }
}

/* Shot s hit ship t: the shield on that side takes what it can, the rest
 * damages systems. */
void HitShip(Obj3D *t, Shot *s)
{
    Vec32 d;
    Vec32 v;
    Matrix m;
    int side;
    int a;
    int b;
    ShipPart *sp;
    char unused[80];

    d = s->pos;
    Vec32Sub(&d, &t->pos);
    MatTranspose(&t->orient, &m);
    MatTVecMul32(&d, &m, &v);
    side = FindSide(&v);
    if (t->shields_pwr == 0)
        ;
    else {
        sp = &t->shields[side];
        a = sp->cur;
        b = min(s->damage, a);
        sp->cur -= b;
        s->damage -= s->damage * a / sp->max;
    }
    b = DamageShip(t, dmg_tables[side], dmg_counts[side], s->damage);
    if (b == 1 && t->expl == 0) {
        if (t == &player_ship)
            PlayMusic(4, -1);
        else if (GetMusicSeq() != 3)
            PlayMusic(3, -2);
        t->expl = 1;
        t->expl_frame = -1;
        t->shields_up = 0;
        t->shields_on = 0;
    }
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

char *system_names[10] = {
    "Hull",
    "Bridge",
    "port torpedoes",
    "starboard torpedoes",
    "port phasers",
    "starboard phasers",
    "sensors",
    "impulse engines",
    "port warp engine",
    "starboard warp engine"
};

/* Damage a system picked from tab; returns 1 if the hull gives out. */
int DamageShip(Obj3D *t, DmgEntry *tab, int n, int dmg)
{
    char unused[80];
    ShipPart *sp;
    int r;
    int i;

    r = rand() % 100;
    for (i = 0; i != n; ++i, ++tab) {
        if (r >= tab->lo && r <= tab->hi) {
            sp = &t->systems[tab->sys];
            r = min(sp->cur, dmg);
            sp->cur -= r;
            dmg -= r;
            if (dmg) {
                if ((t->systems[SYS_HULL].cur -= dmg) <= 0)
                    return 1;
            }
            return 0;
        }
    }
}

/* The weakest of the starboard, port, upper and lower shields. */
int WeakestSide(ShipPart *p)
{
    int i;
    int best;
    int least;

    least = 0x7FFF;
    for (i = 0; i != 6; ++i, ++p) {
        if (i == 1 || i == 3)
            continue;
        if (p->cur < least) {
            best = i;
            least = p->cur;
        }
    }
    return best;
}

int repair_sys = -1;                /* what the player's crew repairs first */

void SetRepair(int sys)
{
    repair_sys = sys;
    if (sys != -1)
        MsgBox(crew_names[7], "#BRID\\BRID_S22#Aye Sir.", 0x40, 0x64, 0xA1, 0);
}

/* Every 32 frames: recharge the shields and repair the systems a little. */
void Repair(Obj3D *o)
{
    int left;
    int i;
    int n;
    ShipPart *p;

    if ((blink_count & 0x1F) != 7)
        return;
    for (p = o->shields, n = 0; n != 6; ++p, ++n)
        p->cur = min(p->cur + 1, p->max);
    for (p = o->systems, n = 0; n != 10; ++n, ++p)
        p->cur = min(p->cur + 1, p->max);
    if (o == &player_ship) {
        switch (repair_sys) {
        case 0:
        case 1:
        case 6:
            p = &o->systems[repair_sys];
            if (p->cur == p->max) {
                PostRoomMsg(7, repair_sys, 0, 0);
                repair_sys = -1;
            } else
                p->cur = min(p->cur + 1, p->max);
            break;
        case 2:
            p = &o->systems[SYS_TORP_PORT], n = 2;
            goto several;
        case 4:
            p = &o->systems[SYS_PHASER_PORT], n = 2;
            goto several;
        case 7:
            p = &o->systems[SYS_IMPULSE], n = 3;
            goto several;
        case 0x7FFF:
            p = o->shields;
            n = 6;
        several:
            left = n;
            for (i = 0; i != n; ++p, ++i)
                if (p->cur == p->max)
                    --left;
                else
                    p->cur = min(p->cur + 1, p->max);
            if (left == 0) {
                PostRoomMsg(7, repair_sys, 0, 0);
                repair_sys = -1;
            }
            break;
        }
    }
}

/* Turn a ship towards its target rates, then move it. Shots just move. */
void MoveShip(Obj3D *o)
{
    long d;
    long k;

    if (o->visible == R3_SHOT) {
        o->pos.x += o->vx;
        o->pos.y += o->vy;
        o->pos.z += o->vz;
        return;
    }
    k = ((long)o->systems[SYS_BRIDGE].cur << 16) / o->systems[SYS_BRIDGE].max;
    if ((d = o->mo.turn_target[0] - o->mo.turn_rate[0]) != 0) {
        d = min(o->mo.turn_accel, d);
        d = max(-o->mo.turn_accel, d);
        d = (d >> 16) * k;
        o->mo.turn_rate[0] += d;
        o->mo.turn_rate[0] = max(o->mo.turn_rate[0], -o->mo.turn_max);
        o->mo.turn_rate[0] = min(o->mo.turn_rate[0], o->mo.turn_max);
    }
    if ((d = o->mo.turn_target[1] - o->mo.turn_rate[1]) != 0) {
        d = min(o->mo.turn_accel, d);
        d = max(-o->mo.turn_accel, d);
        d = (d >> 16) * k;
        o->mo.turn_rate[1] += d;
        o->mo.turn_rate[1] = max(o->mo.turn_rate[1], -o->mo.turn_max);
        o->mo.turn_rate[1] = min(o->mo.turn_rate[1], o->mo.turn_max);
    }
    if ((d = o->mo.turn_target[2] - o->mo.turn_rate[2]) != 0) {
        d = min(o->mo.turn_accel, d);
        d = max(-o->mo.turn_accel, d);
        d = (d >> 16) * k;
        o->mo.turn_rate[2] += d;
        o->mo.turn_rate[2] = max(o->mo.turn_rate[2], -o->mo.turn_max);
        o->mo.turn_rate[2] = min(o->mo.turn_rate[2], o->mo.turn_max);
    }
    if ((d = o->mo.turn_rate[0] >> 16) != 0) {
        MatRotXSC(d < 0 ? -sin_small[-d] : sin_small[d],
                  d < 0 ? cos_small[-d] : cos_small[d], &o->orient);
        o->mo.turn_sum[0] += ang_small[ABS(d)];
    }
    if ((d = o->mo.turn_rate[1] >> 16) != 0) {
        MatRotYSC(d < 0 ? -sin_small[-d] : sin_small[d],
                  d < 0 ? cos_small[-d] : cos_small[d], &o->orient);
        o->mo.turn_sum[1] += ang_small[ABS(d)];
    }
    if ((d = o->mo.turn_rate[2] >> 16) != 0) {
        MatRotZSC(d < 0 ? -sin_small[-d] : sin_small[d],
                  d < 0 ? cos_small[-d] : cos_small[d], &o->orient);
        o->mo.turn_sum[2] += ang_small[ABS(d)];
    }
    o->mo.timer--;
    SetSpeed(o, o->mo.speed_limit);
    o->pos.x += o->vx;
    o->pos.y += o->vy;
    o->pos.z += o->vz;
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

/* Turn at random until 30 degrees off, then pick a manoeuvre. */
void AiWander(Obj3D *o)
{
    int r;

    switch (o->ai_state) {
    case 0:
        while ((r = rand() & 7) == 0)
            ;
        if (r & 1)
            o->mo.turn_target[0] = o->mo.turn_max * (rand() & 1 ? -1 : 1);
        else
            o->mo.turn_target[0] = 0;
        if (r & 2)
            o->mo.turn_target[1] = o->mo.turn_max * (rand() & 1 ? -1 : 1);
        else
            o->mo.turn_target[1] = 0;
        if (r & 4)
            o->mo.turn_target[2] = o->mo.turn_max * (rand() & 1 ? -1 : 1);
        else
            o->mo.turn_target[2] = 0;
        o->mo.target_speed = o->mo.max_speed >> 2;
        o->mo.turn_sum[0] = 0;
        o->mo.turn_sum[1] = 0;
        o->mo.turn_sum[2] = 0;
        o->ai_state++;
        break;
    case 1:
        if (o->mo.turn_sum[0] >= 0x550000L || o->mo.turn_sum[1] >= 0x550000L
            || o->mo.turn_sum[2] >= 0x550000L) {
            o->ai = ai_moves[rand() % 3];
            o->ai_state = 0;
        }
        break;
    }
    MoveShip(o);
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

/* Fire everything at the player if they are ahead (v in ship coordinates). */
void FireAll(Obj3D *o, Vec32 v, Vec32 *dir)
{
    int i;
    int fired;
    ShipPart *p;

    v.x = ABS(v.x);
    v.y = ABS(v.y);
    if (max(v.x, v.y) << 2 < v.z) {
        fired = 0;
        p = &o->systems[SYS_TORP_PORT];
        for (i = 0; i != 4; ++i, ++p)
            fired |= FireShot(o, &o->weapons[i], dir, p);
        if (fired)
            BridgeSfx(0x25);
    }
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

void BoostEnd(void)
{
    boost_active = 0;
    SetPower(0, 0);
    RepairAll(&player_ship);
    SetRepair(-1);
}

/* The player's power switches; the pointer shows whether weapons are on. */
void SetPower(int shields, int weapons)
{
    player_ship.weapons_req = weapons;
    player_ship.shields_req = shields;
    if (kbd_mouse) {
        ReleaseBitmap(mouse_sprite.handle);
        SpriteSetBitmap(&mouse_sprite, LoadBitmap(weapons ? "cursor" : "entcur"));
    }
}
