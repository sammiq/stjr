/* seg017: the intro (logo, title flyby and credits) */

#include <stdio.h>
#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "gfx.h"
#include "event.h"
#include "sound.h"
#include "resource.h"
#include "fixmath.h"
#include "obj3d.h"
#define SpriteAddRect SpriteAddRect_
#include "sprite.h"
#undef SpriteAddRect

/* Called here with the rectangle passed whole. */
void SpriteAddRect(Sprite *s, MemHandle h, Rect r);

void ClearScreen(void);               /* seg001 */

/* seg006 */
void CamReset(void);
void SetView(int x0, int y0, int x1, int y1, int fov);
void AddR3(Obj3D *o);
void DelR3(Obj3D *o);
void RenderR3(int statics);

extern Rect clip_rect;
extern Bitmap far *screen;
extern long proj_dist;
extern Vec32 cam_pos;
extern Obj3D player_ship;
extern Sprite view_sprite;
extern BitmapHdr space_bmp;         /* the view's bitmap header */
extern MemHandle space_bmp_handle;
extern Rect screen_rect;
extern char voc_path[];
extern unsigned char byte_45B3C[];

void Intro(void);
void PlaceObj(Obj3D *o, int a0, int r0, int a1, int r1, int frames);
void IntroTitle(int n, Sprite *s);

#define CREDIT(name) \
    CacheRelease(obj.r3s); \
    DelR3(&obj); \
    obj.r3s = CacheLoad(name, "shp"); \
    obj.visible = R3_SHOT; \
    AddR3(&obj); \
    break;

/* Put o at angle a0 (degrees), distance r0 from the camera, heading for
 * angle a1, distance r1, which it reaches after the given frames. */
void PlaceObj(Obj3D *o, int a0, int r0, int a1, int r1, int frames)
{
    Vec32 d;
    int ang;

    a0 = ((long)a0 << 9) / 180;
    a1 = ((long)a1 << 9) / 180;
    o->pos.x = FixMul(r0, FixSin(a0)) + cam_pos.x;
    o->pos.z = FixMul(r0, FixCos(a0)) + cam_pos.z;
    o->pos.y = 0;
    d.x = FixMul(r1, FixSin(a1)) + cam_pos.x - o->pos.x;
    d.z = FixMul(r1, FixCos(a1)) + cam_pos.z - o->pos.z;
    ang = FixAtan2(d.x, d.z);
    MatIdentity(&o->orient);
    MatRotY(ang, &o->orient);
    if (frames) {
        o->vx = d.x / frames;
        o->vz = d.z / frames;
        o->vy = 0;
    } else {
        o->vx = 0;
        o->vz = 0;
        o->vy = 0;
    }
}

