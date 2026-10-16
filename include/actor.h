/* actor.h - animated actors in the away-team rooms (seg000) */

#ifndef ACTOR_H
#define ACTOR_H

#include "mem.h"
#include "sprite.h"

#define MAX_ACTORS  32

/* Actor.type */
#define ANIM_STAND  0       /* standing animation */
#define ANIM_WALK   1
#define ANIM_PLAY   2       /* any other .anm */

typedef struct Actor {
    int state;              /* 00 1 in use */
    char name[16];          /* 02 the .anm */
    int type;               /* 12 ANIM_ */
    Sprite sprite;          /* 14 */
    char bitmap[10];        /* 48 shown now */
    int scale;              /* 52 */
    MemHandle anim;         /* 54 the .anm data (AnimFrame[]) */
    int nframes;            /* 56 */
    int frame;              /* 58 */
    long next_time;         /* 5A blink_count of the next frame */
    int x;                  /* 5E */
    int y;                  /* 60 */
    int loops;              /* 62 times the last frame was reached */
    int notify;             /* 64 report to the room when done */
    int notify_arg;         /* 66 */
    char walk_name[16];     /* 68 walk bitmaps, then the direction letter */
    int walk_node;          /* 78 walk graph node being walked to, or -1 */
    int dest_node;          /* 7A */
    long fx;                /* 7C 16.16 position while walking */
    long fy;                /* 80 */
    long dx;                /* 84 step */
    long dy;                /* 88 */
    int dest_x;             /* 8C */
    int dest_y;             /* 8E */
    int steps;              /* 90 left to the next node */
    unsigned char step;     /* 92 walk frame counter */
    unsigned char dir;      /* 93 'N', 'S', 'E', 'W' or 0 */
    char unk94[4];          /* 94 */
    char stand[16];         /* 98 standing animation prefix */
} Actor;

/* A frame of a .anm file. */
typedef struct AnimFrame {
    char bitmap[10];        /* 00 */
    int x;                  /* 0A */
    int y;                  /* 0C */
    int z;                  /* 0E added to the depth */
    int delay;              /* 10 ticks */
    char next[4];           /* 12 frames that may follow, picked at random */
} AnimFrame;

/* A playing .ban (run-length coded screen changes). */
typedef struct Ban {
    MemHandle h;            /* 00 */
    int pos;                /* 02 offset of the next frame */
} Ban;

extern Actor actors[MAX_ACTORS];
extern Ban bans[16];

int StartAnim(int n, char *name, int x, int y, int scale);
int StartWalk(int n, char *name, int x, int y, int dx, int dy);
void EndAnim(int n);
void init_stand_anim(int n);

#endif
