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

/* The sequel's actor (0x8A bytes; ST25's was 0xA8). From 6A on it holds
 * either a playing .anm, a callback run each frame, or a walk. */
typedef struct Actor {
    unsigned char state;    /* 00 ACT_ bits */
    char name[9];           /* 01 the bitmap shown */
    int scale;              /* 0A */
    Sprite sprite;          /* 0C */
    long next_time;         /* 40 blink_count of the next frame */
    unsigned char notify;   /* 44 room message when the animation ends */
    unsigned char flags;    /* 45 bit 0: in the landing party (beams down);
                               20: scaled by depth; 80: talks */
    int busy;               /* 46 */
    char letter;            /* 48 for "i?use": the crew member's icon */
    char dir2;              /* 49 the way it faces, if dir is 0 */
    char dir;               /* 4A n, s, e or w */
    char title[24];         /* 4B a speaker's name, for CrewSay */
    char color;             /* 63 their text box colour */
    int x;                  /* 64 (CrewSay: the box position, 0 for 20) */
    int y;                  /* 66 */
    int z;                  /* 68 (CrewSay: the box's timeout) */
    union {
        struct {                        /* playing a .anm */
            char anim[10];              /* 6A */
            MemHandle anim_h;           /* 74 */
            int ax;                     /* 76 */
            int ay;                     /* 78 */
            int nframes;                /* 7A */
            int frame;                  /* 7C */
            int loops;                  /* 7E times the last frame was reached */
        };
        struct {                        /* ACT_CALLBACK */
            int (far *fn)(int n);       /* 6A returns nonzero when done */
            int tick;                   /* 6E steps run */
            int count;                  /* 70 */
        };
        struct {                        /* ACT_WALK */
            int node;                   /* 6A walk graph node being walked to */
            int dest;                   /* 6C node nearest the destination */
            long fx;                    /* 6E 16.16 position */
            long fy;                    /* 72 */
            long dx;                    /* 76 step */
            long dy;                    /* 7A */
            int tx;                     /* 7E destination */
            int ty;                     /* 80 */
            int steps;                  /* 82 left to the next point */
            unsigned char step;         /* 84 walk frame */
            char unk85[5];              /* 85 */
        };
    };
} Actor;

/* Actor.state */
#define ACT_USED        0x01
#define ACT_CALLBACK    0x02
#define ACT_WALK        0x04
#define ACT_STAND       0x08    /* stands when an animation ends */
#define ACT_STOPPED     0x10    /* a walk ended (WaitActor) */
#define ACT_HOLD        0x20    /* the last frame repeats */
#define ACT_TALK        0x40

/* A frame of a .anm file. */
typedef struct AnimFrame {
    char bitmap[10];        /* 00 */
    int x;                  /* 0A */
    int y;                  /* 0C */
    int z;                  /* 0E added to the depth */
    int delay;              /* 10 ticks */
    unsigned char next[4];  /* 12 frames that may follow, picked at random
                               (ACT_HOLD: the next frame, sound volume, pan
                               and bridge sound, or FF) */
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
