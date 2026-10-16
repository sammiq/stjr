/* room.h - the away team's rooms (seg008): the room state, the room data
 * file (.rdf) and its scripts */

#ifndef ROOM_H
#define ROOM_H

/* The state of the current room, saved with the game and seen by the
 * room's scripts (SI points at it while they run). */
typedef struct RoomState {
    int timers[8];              /* 00 count down; message 8 at zero */
    int saved_x;                /* 10 pointer when the game was saved */
    int saved_y;                /* 12 */
    int stun[4];                /* 14 crew stunned for this many ticks */
    char no_walk;               /* 1C */
    char busy;                  /* 1D the player can't act */
    char redshirt_dead;         /* 1E */
    unsigned char action;       /* 1F 1 walk, 2 use, 3 get, 4 look, 5 talk */
    unsigned char target;       /* 20 object acted on */
    unsigned char target2;      /* 21 used on this */
    char unk22;                 /* 22 */
    char more;                  /* 23 a script asks for more matches */
    unsigned char flags;        /* 24 bits 0-3 crew stunned */
    unsigned char fall[4];      /* 25 where a stunned crew member falls */
    char vars[0x100];           /* 29 for the scripts */
} RoomState;

/* A room's .rdf file, locked at rdf. Offsets are from its start. */
typedef struct Rdf {
    long (far *service)();      /* 00 callback for the scripts */
    unsigned state;             /* 04 the RoomState */
    int y_max;                  /* 06 depth scaling */
    int y_min;                  /* 08 */
    unsigned scale_min;         /* 0A */
    unsigned scale_max;         /* 0C */
    unsigned scripts;           /* 0E */
    unsigned scripts_end;       /* 10 */
    unsigned objects;           /* 12 clickable polygons */
    unsigned objects_end;       /* 14 */
    unsigned exits;             /* 16 polygons */
    unsigned exits_end;         /* 18 */
    unsigned regions;           /* 1A */
    unsigned regions_end;       /* 1C */
    unsigned bans;              /* 1E names of the .ban animations */
    unsigned bans_end;          /* 20 */
    int exit_room[4];           /* 22 */
    int walk_in[4][8][2];       /* 2A per entrance: from, to for each crew */
    int beam_pos[4][2];         /* AA */
    int stand_pos[4][2];        /* BA */
} Rdf;

extern RoomState room;
extern Rdf far *rdf;
extern MemHandle rdf_handle;
extern char room_mission[16];

#endif
