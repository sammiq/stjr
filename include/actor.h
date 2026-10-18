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

/* The sequel's actor (0x8A bytes; ST25's was 0xA8). Only the fields the
 * decompiled code uses so far are known; ST25's layout is in
 * ref/st25/include/actor.h. */
typedef struct Actor {
    int state;              /* 00 1 in use */
    char name[10];          /* 02 */
    Sprite sprite;          /* 0C */
    char unk40[4];          /* 40 */
    unsigned char notify;   /* 44 room message when the animation ends */
    unsigned char flags;    /* 45 bit 0: in the landing party (beams down) */
    int busy;               /* 46 */
    char letter;            /* 48 for "i?use": the crew member's icon */
    char dir2;              /* 49 the way it faces, if dir is 0 */
    char dir;               /* 4A n, s, e or w */
    char title[24];         /* 4B a speaker's name, for CrewSay */
    char color;             /* 63 their text box colour */
    int x;                  /* 64 (CrewSay: the box position, 0 for 20) */
    int y;                  /* 66 */
    int z;                  /* 68 (CrewSay: the box's timeout) */
    char unk6A[0x14];       /* 6A */
    int loops;              /* 7E times the last frame was reached */
    char unk80[0x0A];       /* 80 */
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
