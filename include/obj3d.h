/* obj3d.h - objects in the 3D space view: planets, ships and shots */

#ifndef OBJ3D_H
#define OBJ3D_H

#include "mem.h"
#include "fixmath.h"

#define R3_PLANET   1
#define R3_SHIP     2
#define R3_SHOT     3
#define R3_EXPL     4       /* only while an explosion is drawn */

#ifndef VEC32_DEFINED
#define VEC32_DEFINED
typedef struct Vec32 {
    long x;
    long y;
    long z;
} Vec32;
#endif

typedef struct Obj3D Obj3D;

/* A shield facing or a ship system. */
typedef struct ShipPart {
    int unk;                            /* 00 */
    int max;                            /* 02 */
    int cur;                            /* 04 */
} ShipPart;

/* A ship's weapon mount. */
typedef struct Weapon {
    long next;                          /* 00 blink_count when it may fire again */
    int life;                           /* 04 frames a shot lasts */
    int speed;                          /* 06 */
    int delay;                          /* 08 frames between shots */
    Vec32 ofs;                          /* 0A position on the ship */
    int kind;                           /* 16 shot kind */
} Weapon;

/* Ship movement. Angles and speeds are 16.16. */
typedef struct Motion {
    long turn_max;                      /* 00 */
    long turn_accel;                    /* 04 */
    long max_speed;                     /* 08 */
    long accel;                         /* 0C */
    long target_speed;                  /* 10 */
    long turn_target[3];                /* 14 pitch, yaw, roll */
    long speed_limit;                   /* 20 what the power allows */
    long speed;                         /* 24 */
    long turn_rate[3];                  /* 28 */
    long turn_sum[3];                   /* 34 turned so far */
    int timer;                          /* 40 */
} Motion;

/* A ship's .dsc file. */
typedef struct ShipDesc {
    int kind;                   /* 00 */
    int reach;                  /* 02 */
    int size;                   /* 04 */
    ShipPart shields[6];        /* 06 */
    ShipPart systems[10];       /* 2A */
    Motion mo;                  /* 66 */
    long range;                 /* A8 */
    int has_shields;            /* AC */
    Weapon weapons[4];          /* AE */
} ShipDesc;

/* The fields every object in the view has. */
#define R3_FIELDS \
    Vec32 pos;                          /* 00 world position */ \
    Matrix orient;                      /* 0C */ \
    int visible;                        /* 1E R3_PLANET, R3_SHIP, R3_SHOT, or 0 */ \
    int kind;                           /* 20 ship (shape_names) or shot type */ \
    int reach;                          /* 22 radius for culling */ \
    int size;                           /* 24 drawn radius */ \
    int vx;                             /* 26 velocity per frame */ \
    int vy;                             /* 28 */ \
    int vz;                             /* 2A */ \
    int (far *draw)(Obj3D *o);          /* 2C */ \
    void (far *free)(Obj3D *o);         /* 30 */ \
    int drawn;                          /* 34 set when drawn this frame */ \
    Vec32 view;                         /* 36 position relative to the camera */ \
    Matrix view_m;                      /* 42 */ \
    long scale;                         /* 54 distance from the camera */ \
    int sx;                             /* 58 projected centre */ \
    int sy;                             /* 5A */ \
    char shape[10];                     /* 5C name of the loaded .r3s */ \
    int view_idx;                       /* 66 bitmap in it */ \
    MemHandle r3s;                      /* 68 bitmap drawn for the object */ \
    int r3s_type;                       /* 6A offset of its header */ \
    Matrix rot;                         /* 6C orientation the bitmap shows */ \
    int mirror;                         /* 7E bitmap drawn mirrored */ \
    double inv[4];                      /* 80 screen to bitmap matrix */

/* A shot (only these 0xA8 bytes; see Obj3D). */
typedef struct Shot {
    R3_FIELDS
    Obj3D *owner;                       /* A0 */
    int life;                           /* A2 frames left; animates explosions */
    int damage;                         /* A4 */
    int color;                          /* A6 */
} Shot;

struct Obj3D {
    R3_FIELDS
    union {
        struct {                        /* planets */
            int radius;                 /* A0 */
            int small;                  /* A2 32x32 texture instead of 128x128 */
            char name[10];              /* A4 */
            int generated;              /* AE fractal texture */
            unsigned seed;              /* B0 */
            int palette;                /* B2 */
        };
        struct {                        /* shots, as Shot */
            Obj3D *owner;               /* A0 */
            int life;                   /* A2 */
            int damage;                 /* A4 */
            int color;                  /* A6 */
        };
        struct {                        /* ships */
            ShipPart shields[6];        /* A0 by side (FindSide) */
            ShipPart systems[10];       /* C4 SYS_ */
            Motion mo;                  /* 100 */
            int power;                  /* 142 left this frame */
            int shields_req;            /* 144 power wanted for shields */
            int shields_pwr;            /* 146 and got */
            int weapons_req;            /* 148 */
            int weapons_pwr;            /* 14A */
            long dist;                  /* 14C to the player */
            long ddist;                 /* 150 change in dist */
            int ai_busy;                /* 154 running ai */
            void (far *ai)(Obj3D *o);   /* 156 manoeuvre */
            int ai_state;               /* 15A */
            Weapon weapons[4];          /* 15C */
            long range;                 /* 1BC fighting distance */
            int has_shields;            /* 1C0 */
            int shields_up;             /* 1C2 raised */
            int shields_on;             /* 1C4 powered */
            int shield_glow;            /* 1C6 0 to 28 */
            int expl;                   /* 1C8 exploding */
            int expl_frame;             /* 1CA */
            int flee;                   /* 1CC */
        };
    };
};

/* systems[] */
#define SYS_HULL        0
#define SYS_BRIDGE      1
#define SYS_TORP_PORT   2
#define SYS_TORP_STBD   3
#define SYS_PHASER_PORT 4
#define SYS_PHASER_STBD 5
#define SYS_SENSORS     6
#define SYS_IMPULSE     7
#define SYS_WARP_PORT   8
#define SYS_WARP_STBD   9

/* seg027 (assembly) */
void Vec32Sub(Vec32 *a, Vec32 *b);
void MatTVecMul32(Vec32 *v, Matrix *m, Vec32 *out);

#endif
