/* seg025: going to warp (ST25's space cutscenes are gone) */

#include <stdio.h>
#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "event.h"
#include "sprite.h"
#include "fixmath.h"
#include "obj3d.h"

void ClearShips(void);              /* seg020 */
void RestoreShip(Obj3D *o);
void PlayDemScene(char *name);         /* (c2B980): play a sound */

extern Obj3D player_ship;
extern int kbd_mouse;
extern Rect clip_rect;

void StopShip(Obj3D *o);

/* The Enterprise goes to warp at full speed. */
void PlayWarp(void)
{
    char name[16];
    long speed;

    ClearShips();
    RestoreShip(&player_ship);
    sprintf(name, "warp%d", rand() % 3 + 1);
    PlayDemScene(name);
    speed = player_ship.mo.target_speed;
    StopShip(&player_ship);
    player_ship.mo.target_speed = speed;
    player_ship.mo.speed = player_ship.mo.max_speed;
}

/* Stop o, and centre the pointer if it steers the Enterprise. */
void StopShip(Obj3D *o)
{
    o->mo.target_speed = o->mo.turn_target[0] = o->mo.turn_target[1] = o->mo.turn_target[2] = 0;
    o->mo.speed = o->mo.turn_rate[0] = o->mo.turn_rate[1] = o->mo.turn_rate[2] = 0;
    if (o == &player_ship && kbd_mouse) {
        mouse_x = (clip_rect.x1 + clip_rect.x0) / 2;
        SpriteSetPos(&mouse_sprite, mouse_x, mouse_y = (clip_rect.y0 + clip_rect.y1) / 2, 15);
        SetPointer(mouse_x, mouse_y);
    }
}
