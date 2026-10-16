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

char intro_titles = 0;              /* show the title text bitmaps */

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

void Intro(void)
{
    Sprite spr;
    Obj3D obj;
    long unused[2];
    long dz;
    int frame;
    char name[10];
    long t;
    long now;
    Event ev;
    int quit;
    int i;
    char path[62];

    quit = 0;
    if (midi_driver == 10) {
        LoadMusic("init");
        PlaySeq(0, 0);
    }
    CamReset();
    SetView(10, 20, 309, 169, 0x80);
    if (space_bmp_handle == 0)
        space_bmp_handle = AllocMemHandle(&space_bmp);
    SpriteAddRect(&view_sprite, space_bmp_handle, clip_rect);
    DelR3(&player_ship);
    MemSet(&obj, sizeof(obj), 0);
    MatIdentity(&obj.orient);
    obj.visible = R3_SHOT;
    obj.draw = 0;
    obj.free = 0;
    obj.r3s_type = 0;
    ClearScreen();
    FadeOut();
    LoadPalette("gold");
    LoadFilePacked("goldlogo", "bmp", screen);
    PlaySfx("logo");
    RestoreBackground(&screen_rect);
    BlitToScreen(&screen_rect);
    FadeIn();
    t = GetTicks();
    AddSprite(&spr);
    SpriteSetPos(&spr, 0, 0, 12);
    SpriteSetBitmap(&spr, LoadBitmap("blank"));
    spr.layer = 16;
    for (i = 12; i >= 0; --i) {
        sprintf(name, "credit%02d", i);
        CachePreload(name, "shp");
    }
    CachePreload("legal", "BMP");
    for (i = 6; i >= 0; --i) {
        sprintf(name, "tittxt%02d", i);
        CachePreload(name, "bmp");
    }
    CachePreload("planet", "shp");
    for (i = 6; i >= 0; --i) {
        sprintf(name, "ent%d3", i);
        CachePreload(name, "r3s");
    }
    LoadSfx("kirkintr");
    t += 540;
    while (GetTicks() < (unsigned long)t && MusicPlaying())
        ;
    if (midi_driver == 10) {
        PlaySeq(0, 1);
        while (MusicPlaying())
            ;
    }
    FadeOut();
    LoadPalette("bridge");
    ClearScreen();
    LoadMusic("title");
    t = GetTicks();
    for (frame = 0; frame != 384 || MusicPlaying() && !quit; frame = min(frame + 1, 390)) {
        StreamTick();
        while (GetEvent(&ev)) {
            if (ev.type == EV_KEY) {
                FadeOut();
                quit = 1;
            }
        }
        switch (frame) {
        case 0:
            dz = 10;
            PlayMusic(0, -1);
            byte_45B3C[0] = 0;
            break;
        case 30:
            sprintf(path, "%ssfx\\kirkintr.voc", voc_path);
            PlaySfx("kirkintr");
            IntroTitle(0, &spr);
            break;
        case 36:
            IntroTitle(1, &spr);
            break;
        case 42:
            IntroTitle(-1, &spr);
            AddR3(&player_ship);
            player_ship.visible = R3_SHIP;
            PlaceObj(&player_ship, 330, 5000, 0, 0, 18);
            break;
        case 60:
            PlaceObj(&player_ship, 0, 0, 30, 5000, 6);
            break;
        case 66:
            IntroTitle(2, &spr);
            obj.reach = 2000;
            obj.size = 10000L / proj_dist;
            obj.r3s = CacheLoad("planet", "shp");
            PlaceObj(&obj, 6, 10000, 6, 10000, 0);
            AddR3(&obj);
            PlaceObj(&player_ship, -15, 250, 15, 500, 18);
            dz = 0;
            break;
        case 90:
            IntroTitle(3, &spr);
            PlaceObj(&obj, 0, 5000, 0, 5000, 0);
            obj.pos.y = -2500;
            PlaceObj(&player_ship, -30, 450, 45, 540, 54);
            break;
        case 108:
            IntroTitle(4, &spr);
            break;
        case 126:
            IntroTitle(5, &spr);
            break;
        case 144:
            IntroTitle(6, &spr);
            PlaceObj(&obj, 30, 5600, 30, 5600, 0);
            obj.pos.y = -2500;
            PlaceObj(&player_ship, -10, 800, 155, 600, 18);
            break;
        case 150:
            IntroTitle(6, &spr);
            break;
        case 162:
            dz = 10;
            DelR3(&obj);
            CacheRelease(obj.r3s);
            /* fall through */
        case 168:
            IntroTitle(-1, &spr);
            PlaceObj(&player_ship, 340, 5000, 0, 0, 18);
            break;
        case 186:
            DelR3(&player_ship);
            obj.r3s = CacheLoad("credit00", "shp");
            obj.r3s_type = 0;
            obj.visible = R3_SHOT;
            obj.reach = 1;
            obj.size = 1;
            AddR3(&obj);
            PlaceObj(&obj, 0, 0, 0, proj_dist, 18);
            break;
        case 204:
            obj.pos.z = proj_dist + cam_pos.z;
            obj.vz = 0;
            break;
        case 216:
            ReleaseBitmap(spr.handle);
            SpriteSetBitmap(&spr, LoadBitmap("legal"));
            break;
        case 222:
            ReleaseBitmap(spr.handle);
            SpriteSetBitmap(&spr, LoadBitmap("blank"));
            CacheRelease(obj.r3s);
            DelR3(&obj);
            break;
        case 228:
            obj.r3s = CacheLoad("credit01", "shp");
            obj.visible = R3_SHOT;
            AddR3(&obj);
            break;
        case 240: CREDIT("credit02")
        case 252: CREDIT("credit03")
        case 264: CREDIT("credit04")
        case 276: CREDIT("credit05")
        case 288: CREDIT("credit06")
        case 300: CREDIT("credit07")
        case 312: CREDIT("credit08")
        case 324: CREDIT("credit09")
        case 330: CREDIT("credit10")
        case 336: CREDIT("credit11")
        case 342: CREDIT("credit12")
        case 348: CREDIT("credit13")
        case 354: CREDIT("credit14")
        case 360: CREDIT("credit15")
        case 366:
            CacheRelease(obj.r3s);
            DelR3(&obj);
            break;
        case 378:
            DelSprite(&spr);
            ReleaseBitmap(spr.handle);
            byte_45B3C[0] = 1;
            break;
        }
        if (quit == 0) {
            RenderR3(0);
            UpdateSprites();
            FadeUp();
            t += 3;
            while ((now = GetTicks()) < t)
                ;
        }
        cam_pos.z += dz;
        player_ship.pos.x += player_ship.vx;
        player_ship.pos.z += player_ship.vz + dz;
        obj.pos.x += obj.vx;
        obj.pos.z += obj.vz + dz;
    }
    FadeOut();
    AddR3(&player_ship);
    player_ship.visible = R3_SHIP;
    DelSprite(&view_sprite);
}

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

/* Show title text n, or nothing for -1. */
void IntroTitle(int n, Sprite *s)
{
    char name[16];

    if (intro_titles) {
        sprintf(name, "tittxt%02d", n);
        ReleaseBitmap(s->handle);
        if (n != -1)
            SpriteSetBitmap(s, LoadBitmap(name));
        else
            SpriteSetBitmap(s, LoadBitmap("blank"));
    }
}
