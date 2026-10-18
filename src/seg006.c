/* seg006: the 3D space view (ships, planets, shots and explosions) */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "gfx.h"
#include "sprite.h"
#include "fixmath.h"
#include "obj3d.h"

#define FP_SEG(fp) (*((unsigned _far *)&(fp) + 1))
#define FP_OFF(fp) (*((unsigned _far *)&(fp)))

#define ABS(x)  ((x) > 0 ? (x) : -(x))
#define SGN(x)  ((x) > 0 ? 1 : ((x) < 0 ? -1 : 0))

#define MAX_R3  48

/* One row of a filled shape. */
typedef struct Span {
    int right;
    int left;
} Span;

typedef struct Point {
    int x;
    int y;
} Point;

void Fatal(char *fmt, ...);     /* fatal error */
void MsgBox(char *title, char *msg, int a, int b, int c, int d);    /* seg008: message box */
void GameOverMenu(void);               /* seg019: game over */
void SaveWrite(void *p, int n);     /* seg019: save game I/O */
void SaveRead(void *p, int n);
void BridgeSfx(int n);              /* seg001 */
void SetRepair(int n);

/* seg023 */
void StarsReset(void);
void DrawStars(void);

/* seg027 */
int Project(long a, long z);

/* seg018 */
int DrawPlanet(Obj3D *o);
void FreePlanet(Obj3D *o);

int view_cx;
int view_cy;
Rect clip_rect;
extern Bitmap far *screen;
extern Bitmap far *backbuf;
extern Vec32 cam_pos;
extern Matrix cam_orient;
Matrix cam_matrix;           /* cam_orient transposed */
extern Sprite view_sprite;           /* the view, as a sprite */
extern Obj3D player_ship;
extern Shot shot_obj;
extern Obj3D dummy_planet;
extern Obj3D ships[4];
extern unsigned long blink_count;
extern char enemy_name[10];        /* seg020 */
extern int enemy_count;
extern int target_idx;              /* seg001: the ship being locked onto */
extern int target_lock;             /* frames locked on, up to 50 */
extern int word_3DEA6;
void HLineClip(int x, int y, int len, int c);   /* new in the sequel */
void VLineClip(int x, int y, int len, int c);
void CrewSay(int who, char *text);          /* seg008 */
void LoadNamed(char *name, int a);
extern unsigned char ship_detail;   /* draw ships in full (off in the intro) */
extern int view_tab[24][13];        /* bitmap for each yaw and pitch, 0x8000 mirrored */

Obj3D *r3_list[MAX_R3] = { 0 };

void CamReset(void);
void SetView(int x0, int y0, int x1, int y1, int fov);
void DrawStatic(void);
void ClearR3List(void);
void AddR3(Obj3D *o);
void DelR3(Obj3D *o);
void LockScreen(void);           /* seg012 */
void UnlockScreen(void);
void ClearView(void);
void DrawStarfield(void);
int CompareR3(Obj3D **a, Obj3D **b);
void RenderR3(int statics);
Obj3D *ProjectR3(Obj3D *o);
int LoadShotShape(Obj3D *o);
void FreeShotShape(Obj3D *o);
int SelectView(Obj3D *o);
void ReleaseShipShape(Obj3D *o);
double DDiv(double a, double b);
void DrawR3Shape(Obj3D *o);
int InView(Obj3D *o);
void OrthoR3(void);
void DrawBeam(Obj3D *o);
void SpanCircle(Span *s, int cx, int cy, int r);
void SpanQuad(Span *s, int x0, int y0, int x1, int y1, int r0, int r1);
void DrawLine(int x0, int y0, int x1, int y1, int c);
Point *LinePoints(int x0, int y0, int x1, int y1);
void SpanLine(Span *s, int x0, int y0, int x1, int y1);
void FillSpans(Span *s, int c);
void OutlineSpans(Span *s, int c);
void SaveR3(Obj3D *o);
void SaveR3Shot(Obj3D *o);
void RestoreR3(Obj3D *o);
void RestoreR3Shot(Obj3D *o);
void SaveSpace(void);
void LoadSpace(void);

int view_h;

int view_x0;

int view_x1;

int view_y0;

int view_y1;

char far *view_ptr;          /* first row of the view on the screen */

long proj_dist;

float star_near;

Vec32 fr_left;               /* frustum edges */

Vec32 fr_right;

Vec32 fr_top;

Vec32 fr_bottom;

int span_fill;

Obj3D *r3_sorted[MAX_R3] = { 0 };

char *shape_names[5] = { "ENT", "KLG", "ORI", "ROM", "FKR" };


int view_w;                  /* half the view width */

void CamReset(void)
{
    MemSet(&cam_pos, sizeof(cam_pos), 0);
    MatIdentity(&cam_orient);
}

/* Set the view rectangle and the field of view. */
void SetView(int x0, int y0, int x1, int y1, int fov)
{
    view_cx = (x0 + x1) / 2;
    view_cy = (y0 + y1) / 2;
    view_w = (x1 - x0 + 1) / 2;
    view_h = (y1 - y0 + 1) / 2;
    clip_rect.x0 = view_x0 = view_cx - view_w;
    clip_rect.x1 = view_x1 = view_cx + view_w;
    clip_rect.y0 = view_y0 = view_cy - view_h;
    clip_rect.y1 = view_y1 = view_cy + view_h;
    proj_dist = FixDiv(view_w, FixTan(fov));
    star_near = 50;
    fr_left.x = -view_w;
    fr_left.y = 0;
    fr_left.z = proj_dist;
    fr_right.x = view_w;
    fr_right.y = 0;
    fr_right.z = proj_dist;
    fr_top.x = 0;
    fr_top.y = view_h;
    fr_top.z = proj_dist;
    fr_bottom.x = 0;
    fr_bottom.y = -view_h;
    fr_bottom.z = proj_dist;
    StarsReset();
}

/* Fill the view with one of the static bitmaps, tiled. */
void DrawStatic(void)
{
    int vw;
    int vh;
    int bw;
    int bh;
    int x;
    int y;
    int xx;
    int yy;
    int step;
    char far *p;
    unsigned char far *src;
    char far *rowp;
    char far *dst;
    Bitmap far *bmp;
    MemHandle h;
    char name[10];
    char c;

    sprintf(name, "static%d", rand() % 5);
    h = CacheLoad(name, "bmp");
    bmp = LockMem(h);
    vw = clip_rect.x1 - clip_rect.x0 + 1;
    vh = clip_rect.y1 - clip_rect.y0 + 1;
    bw = bmp->w;
    bh = bmp->h;
    src = bmp->data;
    LockScreen();
    dst = screen->data + clip_rect.y0 * 320 + clip_rect.x0;
    step = bh * 320;
    for (y = 0; y != bh; ++y, dst += 320)
        for (x = 0; x != bw; ++x, ++src)
            if (*src) {
                c = *src;
                rowp = p = dst + x;
                for (yy = y; yy < vh; yy += bh) {
                    for (xx = x; xx < vw; xx += bw, p += bw)
                        *p = c;
                    p = rowp += step;
                }
            }
    UnlockScreen();
    UnlockMem(h);
    CacheRelease(h);
}

void ClearR3List(void)
{
    Obj3D **p;

    for (p = r3_list; p != &r3_list[MAX_R3]; p++)
        if (*p)
            (*p)->visible = 0;
    MemSet(r3_list, sizeof(r3_list), 0);
}

void AddR3(Obj3D *o)
{
    Obj3D **p;

    for (p = r3_list; p != &r3_list[MAX_R3]; p++)
        if (*p == 0) {
            *p = o;
            return;
        }
    Fatal("AddR3: out of shapes.");
}

void DelR3(Obj3D *o)
{
    Obj3D **p;

    for (p = r3_list; p != &r3_list[MAX_R3]; p++)
        if (*p == o) {
            *p = 0;
            o->visible = 0;
            return;
        }
    Fatal("DelR3: shape not found.");
}

void ClearView(void)
{
    int w;
    int h;
    char far *p;

    w = clip_rect.x1 - clip_rect.x0 + 1;
    h = clip_rect.y1 - clip_rect.y0 + 1;
    LockScreen();
    p = screen->data + clip_rect.y0 * 320 + clip_rect.x0;
    while (h--) {
        MemSet(p, w, 0xDF);
        p += 320;
    }
    UnlockScreen();
}

void DrawStarfield(void)
{
    DrawStars();
}

/* qsort order: furthest first */
int CompareR3(Obj3D **a, Obj3D **b)
{
    long d;

    d = (*a)->scale - (*b)->scale;
    if (d < 0)
        return 1;
    if (d == 0)
        return 0;
    return -1;
}

/* Draw the view: stars, then everything in r3_list from back to front. */
void RenderR3(int statics)
{
    unsigned n;
    unsigned i;
    int unused;
    Obj3D *o;
    Obj3D *p;
    int dead;

    dead = 0;
    view_sprite.dirty = 1;
    MatTranspose(&cam_orient, &cam_matrix);
    ClearView();
    DrawStarfield();
    for (i = n = 0; i != MAX_R3; i++) {
        if ((o = r3_list[i]) == 0)
            continue;
        o->drawn = 0;
        switch (o->visible) {
        case R3_SHIP:
            if (o->expl) {
                o->expl_frame++;
                if (o->expl_frame > 45) {
                    if (o == &player_ship)
                        dead = 1;
                    else
                        DelR3(o);
                    o = 0;
                } else {
                    int reach;
                    int size;
                    Obj3D *q;

                    reach = o->reach;
                    size = o->size;
                    o->size = o->expl_frame >= 24 ? 12 : 6;
                    o->reach *= o->expl_frame >= 24 ? 2 : 1;
                    q = ProjectR3(o);
                    o->reach = reach;
                    o->size = size;
                    o = q;
                }
            } else
                o = ProjectR3(o);
            break;
        case R3_SHOT:
            o = ProjectR3(o);
            break;
        case R3_PLANET:
            o = ProjectR3(o);
            break;
        default:
            break;
        }
        if (o)
            r3_sorted[n++] = o;
    }
    if (n) {
        qsort(r3_sorted, n, sizeof(Obj3D *), CompareR3);
        for (i = 0; i != n; i++) {
            p = r3_sorted[i];
            p->drawn = 1;
            switch (p->visible) {
            case R3_SHOT:
                if (p->kind == 1)
                    DrawBeam(p);
                else
                    DrawR3Shape(p);
                break;
            case R3_SHIP:
                if (p->expl) {
                    int size;
                    int visible;
                    int kind;

                    if (p->expl_frame < 21)
                        DrawR3Shape(p);
                    visible = p->visible;
                    kind = p->kind;
                    size = p->size;
                    p->visible = R3_EXPL;
                    p->kind = -1;
                    p->size = p->expl_frame >= 24 ? 12 : 6;
                    DrawR3Shape(p);
                    p->visible = visible;
                    p->kind = kind;
                    p->size = size;
                } else {
                    DrawR3Shape(p);
                    /* new in the sequel: brackets round the target, red once locked */
                    if (target_lock && &ships[target_idx] == p) {
                        int c;

                        c = target_lock == 50 ? 0xA2 : 0xB0;
                        HLineClip(p->sx - 4, p->sy - 4, 8, c);
                        VLineClip(p->sx - 4, p->sy - 4, 8, c);
                        VLineClip(p->sx + 4, p->sy - 4, 8, c);
                        HLineClip(p->sx - 4, p->sy + 4, 9, c);
                    }
                }
                break;
            case R3_PLANET:
                DrawR3Shape(p);
                break;
            default:
                break;
            }
        }
    }
    if (dead) {
        if (word_3DEA6 == 0)
            LoadNamed("fed", 1);
        else {
            CrewSay(-1, "The Enterprise has been destroyed!");
            GameOverMenu();
        }
    }
    if (statics && !player_ship.expl)
        DrawStatic();
}

/* Transform an object into camera space and project its centre.
 * Returns 0 if it is out of view. */
Obj3D *ProjectR3(Obj3D *o)
{
    Vec32 v;
    Matrix m;

    o->view_m = o->orient;
    o->view = o->pos;
    Vec32Sub(&o->view, &cam_pos);
    o->scale = (unsigned)VecLen32(&o->view.x);
    MatTVecMul32(&o->view, &cam_matrix, &v);
    o->view = v;
    if (!InView(o))
        return 0;
    if (o->visible == R3_SHIP || o->visible == R3_PLANET || o->visible == R3_SHOT) {
        MatMul(&o->view_m, &cam_matrix, &m);
        o->view_m = m;
    }
    o->sx = Project(o->view.x, o->view.z) + view_cx;
    o->sy = view_cy - Project(o->view.y, o->view.z);
    return o;
}

/* draw: load the bitmap of a shot or explosion */
int LoadShotShape(Obj3D *o)
{
    char name[16];

    switch (o->kind) {
    case 3:
        strcpy(name, "expl0X");
        name[5] = (3 & o->life) + '0';
        o->r3s = CacheLoadEMS(name, "shp");
        o->r3s_type = 0;
        if (o->life == 5)
            BridgeSfx(7);
        break;
    case 1:
        DrawBeam(o);
        break;
    case 0:
        strcpy(name, "shotX");
        name[4] = (1 & o->life) + '1';
        o->r3s = CacheLoadEMS(name, "shp");
        o->r3s_type = 0;
        break;
    case 2:
        strcpy(name, "plasm0");
        name[5] = (blink_count & 3) + '0';
        o->r3s = CacheLoadEMS(name, "shp");
        o->r3s_type = 0;
        if ((blink_count & 3) == 0)
            o->size++;
        break;
    case 4:                     /* new in the sequel: a named object */
        o->r3s = CacheLoadEMS(o->shape, "shp");
        o->r3s_type = 0;
        break;
    }
}

/* free: release a shot's bitmap */
void FreeShotShape(Obj3D *o)
{
    if (o->kind == 1) {
        if (o->r3s)
            FreeMem(o->r3s);
    } else
        CacheRelease(o->r3s);
    o->r3s = 0;
}

/* draw: pick the ship bitmap that shows the side facing the camera */
int SelectView(Obj3D *o)
{
    int pitch;
    unsigned step;
    int c1;
    int s1;
    int c2;
    int s2;
    char *sname;
    char name[10];
    Vec32 v;
    Vec32 w;
    Matrix m;
    int base[13];
    unsigned steps[13];
    int yaw;

    /* the .r3d views: base[] numbers the first of each pitch row, steps[]
     * is the yaw between views in it */
    base[0] = 1;
    base[1] = 2;
    base[2] = 6;
    base[3] = 13;
    base[4] = 22;
    base[5] = 33;
    base[6] = 46;
    base[7] = 59;
    base[8] = 72;
    base[9] = 83;
    base[10] = 92;
    base[11] = 99;
    base[12] = 103;
    steps[7] = steps[6] = steps[5] = 0x780;
    steps[8] = steps[4] = 0x900;
    steps[9] = steps[3] = 0xB40;
    steps[10] = steps[2] = 0xF00;
    steps[11] = steps[1] = 0x1E00;
    steps[12] = steps[0] = 0;
    if (o->kind == -1) {
        char expl[10];

        sprintf(expl, "BigExp%02d", o->expl_frame);
        o->r3s = CacheGet(expl, "shp", 1, 1, 1);
        o->r3s_type = 0;
        return;
    }
    if (o->scale < star_near)
        Fatal("object too close.");
    MemSet(&v, sizeof(v), 0);
    Vec32Sub(&v, &o->view);
    MatTranspose(&o->view_m, &m);
    MatTVecMul32(&v, &m, &w);
    v = w;
    pitch = FixACos(FixDiv(v.y, o->scale));
    if (pitch < 0x80 || pitch > 0x180) {
        yaw = FixLength((int)v.x, (int)v.z, 0);
        pitch = FixASin(FixDiv((unsigned)yaw, o->scale));
        if (v.y < 0)
            pitch = 0x200 - pitch;
    }
    pitch = (pitch * -45 - 0x3C0) / 0x780 + 12;
    yaw = FixAtan2(-v.x, -v.z);
    o->mirror = yaw < 0;
    if (o->mirror)
        yaw = -yaw;
    step = steps[pitch];
    yaw = step ? (yaw * 45 + (step >> 1)) / step : 0;
    sprintf(name, "%08d", base[pitch] + yaw);
    sname = shape_names[o->kind];
    strncpy(name, sname, strlen(sname));
    o->r3s = CacheGet(name, "r3d", 1, 1, 1);
    o->r3s_type = 0;
    yaw = step * yaw / 45;
    c1 = FixCos(yaw);
    s1 = FixSin(yaw);
    pitch = pitch * 0x780 / 45 - 0x100;
    c2 = FixCos(pitch);
    s2 = FixSin(pitch);
    o->rot.e[0][0] = c1;
    o->rot.e[0][1] = FixMul(s1, s2);
    o->rot.e[0][2] = FixMul(s1, c2);
    o->rot.e[1][0] = 0;
    o->rot.e[1][1] = c2;
    o->rot.e[1][2] = -s2;
    o->rot.e[2][0] = -s1;
    o->rot.e[2][1] = FixMul(c1, s2);
    o->rot.e[2][2] = FixMul(c1, c2);
    if (o->mirror) {
        o->rot.e[0][1] = -o->rot.e[0][1];
        o->rot.e[0][2] = -o->rot.e[0][2];
        o->rot.e[1][0] = -o->rot.e[1][0];
        o->rot.e[2][0] = -o->rot.e[2][0];
    }
}

/* free: release a ship's bitmap */
void ReleaseShipShape(Obj3D *o)
{
    if (o->kind == -1)
        ReleaseCache(o->r3s);
    else
        CacheReleaseEMS(o->r3s);
    o->r3s = 0;
}

double DDiv(double a, double b)
{
    return a / b;
}

unsigned char dither[8] = { 0x00, 0x80, 0x40, 0xC0, 0x20, 0xA0, 0x60, 0xE0 };

/* Draw an object's bitmap rotated and scaled: map the bitmap's corners to
 * the screen, scan-convert the outline, then step through the bitmap for
 * each row. */
void DrawR3Shape(Obj3D *o)
{
    double t[2];
    double m[4];
    double uv[2];
    double im[4];
    double k;
    double invk;
    double pts[4][2];
    int top;
    int bot;
    int left[200];
    int right[200];
    int i;
    int y;
    Bitmap far *hdr;

    if (o->visible == R3_SHIP && o->has_shields && o->shields_on && o->shield_glow == 28)
        return;
    if (o->draw)
        o->draw(o);
    if (o->r3s == 0)
        goto release;
    hdr = (Bitmap far *)((char far *)LockMem(o->r3s) + o->r3s_type);
    k = (double)(o->size * proj_dist) / o->view.z;
    invk = 1.0 / k;
    switch (o->visible) {
    case R3_SHOT:
        m[0] = k;
        m[1] = 0.0;
        m[2] = 0.0;
        m[3] = k;
        im[0] = invk;
        im[1] = 0.0;
        im[2] = 0.0;
        im[3] = invk;
        break;
    case R3_PLANET:
    case R3_EXPL:
        {
            int ang;
            double c;
            double s;
            Matrix mt;
            Matrix m2;

            MatTranspose(&o->rot, &mt);
            MatMul(&mt, &o->view_m, &m2);
            ang = FixAtan2(m2.e[0][1], m2.e[0][0]);
            c = FixCos(ang) / 16384.0;
            s = FixSin(ang) / 16384.0;
            m[0] = c;
            m[1] = -s;
            m[2] = s;
            m[3] = c;
            im[0] = m[3];
            im[1] = -m[1];
            im[2] = -m[2];
            im[3] = m[0];
            if (k < 0.01)
                k = 0.01;
            if (k > 10)
                k = 10;
            m[0] *= k;
            m[1] *= k;
            m[2] *= k;
            m[3] *= k;
            im[0] /= k;
            im[1] /= k;
            im[2] /= k;
            im[3] /= k;
        }
        break;
    default:
        {
            int d0;
            int d1;
            int d2;
            int ia;
            int ib;
            int a[2][3];
            int px;
            int py;

            d0 = FixMul2(o->rot.e[0][0], o->rot.e[1][1], -o->rot.e[1][0], o->rot.e[0][1]);
            d1 = FixMul2(o->rot.e[1][0], o->rot.e[2][1], -o->rot.e[2][0], o->rot.e[1][1]);
            d2 = FixMul2(o->rot.e[0][0], o->rot.e[2][1], -o->rot.e[2][0], o->rot.e[0][1]);
            d0 = ABS(d0) / 4;
            d1 = ABS(d1) / 2;
            d2 = ABS(d2) / 1;
            ia = 0;
            ib = 2;
            if (d0 > d1) {
                if (d0 > d2)
                    ib = 1;
                else
                    ;
            } else if (d1 > d2)
                ia = 1;
            a[0][0] = FixMul2(o->rot.e[ib][1], o->view_m.e[ia][0], -o->rot.e[ia][1], o->view_m.e[ib][0]);
            a[0][1] = FixMul2(o->rot.e[ib][1], o->view_m.e[ia][1], -o->rot.e[ia][1], o->view_m.e[ib][1]);
            a[0][2] = FixMul2(o->rot.e[ib][1], o->view_m.e[ia][2], -o->rot.e[ia][1], o->view_m.e[ib][2]);
            a[1][0] = FixMul2(-o->rot.e[ib][0], o->view_m.e[ia][0], o->rot.e[ia][0], o->view_m.e[ib][0]);
            a[1][1] = FixMul2(-o->rot.e[ib][0], o->view_m.e[ia][1], o->rot.e[ia][0], o->view_m.e[ib][1]);
            a[1][2] = FixMul2(-o->rot.e[ib][0], o->view_m.e[ia][2], o->rot.e[ia][0], o->view_m.e[ib][2]);
            {
                int lim;

                lim = ABS(o->view.z) << 1;
                if (ABS(o->view.x) >= lim || ABS(o->view.y) >= lim)
                    {
                    UnlockMem(o->r3s);
                    goto release;
                }
            }
            px = FixDiv(o->view.x, o->view.z);
            py = FixDiv(o->view.y, o->view.z);
            m[0] = (a[0][0] - FixMul(a[0][2], px)) / 16384.0;
            m[1] = (a[0][1] - FixMul(a[0][2], py)) / 16384.0;
            m[2] = (a[1][0] - FixMul(a[1][2], px)) / 16384.0;
            m[3] = (a[1][1] - FixMul(a[1][2], py)) / 16384.0;
            k = DDiv(k, (int)FixMul2(o->rot.e[ia][0], o->rot.e[ib][1], -o->rot.e[ib][0], o->rot.e[ia][1]) / 16384.0);
            m[1] = -m[1];
            m[2] = -m[2];
            if (o->mirror) {
                m[0] = -m[0];
                m[1] = -m[1];
            }
            invk = DDiv(DDiv(1.0, k), m[0] * m[3] - m[1] * m[2]);
            im[0] = m[3];
            im[1] = -m[1];
            im[2] = -m[2];
            im[3] = m[0];
            m[0] *= k;
            m[1] *= k;
            m[2] *= k;
            m[3] *= k;
            im[0] *= invk;
            im[1] *= invk;
            im[2] *= invk;
            im[3] *= invk;
        }
    }
    t[0] = o->sx - m[0] * (hdr->x + 2) - m[2] * (hdr->y + 2);
    t[1] = o->sy - m[1] * (hdr->x + 2) - m[3] * (hdr->y + 2);
    uv[0] = hdr->x + 2 - im[0] * o->sx - im[2] * o->sy;
    uv[1] = hdr->y + 2 - im[1] * o->sx - im[3] * o->sy;
    {
        double w;

        w = hdr->w + 2;
        {
        double h;

        h = hdr->h + 2;
        pts[0][0] = 1 * m[0] + 1 * m[2] + t[0];
        pts[0][1] = 1 * m[1] + 1 * m[3] + t[1];
        pts[1][0] = 1 * m[0] + h * m[2] + t[0];
        pts[1][1] = 1 * m[1] + h * m[3] + t[1];
        pts[2][0] = w * m[0] + h * m[2] + t[0];
        pts[2][1] = w * m[1] + h * m[3] + t[1];
        pts[3][0] = w * m[0] + 1 * m[2] + t[0];
        pts[3][1] = w * m[1] + 1 * m[3] + t[1];
        }
    }
    for (i = clip_rect.y0; i <= clip_rect.y1; i++) {
        left[i] = clip_rect.x1 + 1;
        right[i] = clip_rect.x0 - 1;
    }
    top = clip_rect.y1;
    bot = clip_rect.y0;
    for (i = 0; i < 4; i++) {
        int a;
        int b;
        int y0;
        int y1;
        long x;
        long dx;
        double slope;

        a = i;
        b = (i + 1) & 3;
        if (pts[a][1] > pts[b][1]) {
            a = b;
            b = i;
        }
        y0 = ceil(pts[a][1]);
        y1 = floor(pts[b][1]);
        if (y0 > y1 || y0 > clip_rect.y1 || y1 < clip_rect.y0)
            continue;
        if (y0 < clip_rect.y0)
            y0 = clip_rect.y0;
        if (y1 > clip_rect.y1)
            y1 = clip_rect.y1;
        if (y0 < top)
            top = y0;
        if (y1 > bot)
            bot = y1;
        if (pts[a][1] == pts[b][1])
            slope = 0;
        else
            slope = (pts[b][0] - pts[a][0]) / (pts[b][1] - pts[a][1]);
        dx = 65536L * slope;
        x = 65536L * (pts[a][0] + (y0 - pts[a][1]) * slope);
        for (y = y0; y <= y1; y++) {
            int xr;
            int xl;

            xr = x >> 16;
            xl = (x + 0xFFFF) >> 16;
            if (xl < clip_rect.x0)
                xl = clip_rect.x0;
            if (xl < left[y])
                left[y] = xl;
            if (xr > clip_rect.x1)
                xr = clip_rect.x1;
            if (xr > right[y])
                right[y] = xr;
            x += dx;
        }
    }
    while (top <= bot && left[top] > right[top])
        top++;
    while (top <= bot && left[bot] > right[bot])
        bot--;
    if (top > bot)
        {
                    UnlockMem(o->r3s);
                    goto release;
                }
    {
        char far *row;
        char far *dst;
        Bitmap far *buf;
        char far *p;
        int du;
        int dv;
        int ddu;
        int ddv;
        int u0;
        int v0;
        int opaque;
        int hash;

        if (o->visible == R3_SHIP) {
            if (ship_detail)
                opaque = (o->size * proj_dist << 1) / 5 <= o->view.z;
            else
                opaque = 1;
        } else
            opaque = (o->size * proj_dist << 1) / 3 <= o->view.z;
        if (!opaque) {
            if (o->visible == R3_SHOT)
                hash = (blink_count >> 3) ^ blink_count;
            else {
                hash = o->rot.e[0][0] + o->rot.e[0][1] + o->rot.e[0][2]
                    + o->rot.e[1][0] + o->rot.e[1][1] + o->rot.e[1][2]
                    + o->rot.e[2][0] + o->rot.e[2][1] + o->rot.e[2][2];
                hash = ((hash >> 3) + (hash >> 6)) ^ hash;
            }
        }
        du = 256 * im[0];
        dv = 256 * im[1];
        ddu = 256 * im[2];
        ddv = 256 * im[3];
        u0 = ddu * top + (int)(256 * uv[0]);
        v0 = ddv * top + (int)(256 * uv[1]);
        {
            int w;
            int h;
            int i;
            char far *q;

            /* copy the bitmap into a 256 wide buffer with a clear border,
             * so the drawing loops can step through it with byte maths */
            buf = (Bitmap far *)backbuf->data;
            buf->w = 256;
            buf->h = 249;
            p = backbuf->data;
            ++FP_SEG(p);
            FP_OFF(p) = 0;
            w = hdr->w;
            h = hdr->h;
            q = p;
            if (h > 245)
                Fatal("Shape height too big in DrawR3Shape!");
            if (w > 252)
                Fatal("Shape width too big in DrawR3Shape!");
            for (i = 0; i < 2; i++)
                MemSet(q + (i << 8), w + 4, 0);
            for (i = 0; i < 2; i++)
                MemSet(q + ((h + 2 + i) << 8), w + 4, 0);
            q += 0x200;
            _asm {
                les bx, q
                mov cx, h
                mov al, byte ptr w
                add al, 2
            l_clear:
                mov word ptr es:[bx], 0
                mov bl, al
                mov word ptr es:[bx], 0
                xor bl, bl
                inc bh
                loop l_clear
            }
            if (o->visible == R3_SHIP && o->has_shields) {
                if (o->shields_on)
                    o->shield_glow = max(0, min(o->shield_glow + 1, 28));
                else
                    o->shield_glow = max(0, min(o->shield_glow - 1, 28));
                if (o->shield_glow >= 20) {
                    UnlockMem(o->r3s);
                    SetRemap(o->shield_glow - 20);
                    hdr = (Bitmap far *)((char far *)LockMem(o->r3s) + o->r3s_type);
                    CopyRectRemap(buf, 2, 2, hdr, 0, 0, w, h);
                } else
                    CopyRect(buf, 2, 2, hdr, 0, 0, w, h);
            } else
                CopyRect(buf, 2, 2, hdr, 0, 0, w, h);
        }
        UnlockMem(o->r3s);
        LockScreen();
        row = screen->data + top * 320;
        for (y = top; y <= bot; y++) {
            int x;
            int n;
            int u;
            int v;
            int d;
            int dd;

            x = left[y];
            n = right[y] + 1 - x;
            u = x * du + u0;
            v = x * dv + v0;
            u0 += ddu;
            v0 += ddv;
            dst = row + x;
            row += 320;
            if (n != 0) {
                if (opaque) {
                    u += 128;
                    v += 128;
                    _asm {
                        push si
                        push di
                        push bp
                        mov cx, u
                        mov bx, v
                        mov dx, du
                        mov si, dv
                        mov ds, word ptr p+2
                        les di, dst
                        mov bp, n
                        jmp o_next
                    o_put:
                        stosb
                        dec bp
                        je o_end
                    o_next:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        jne o_put
                    o_skip:
                        inc di
                        dec bp
                        je o_end
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        je o_skip
                        jmp o_put
                    o_end:
                        pop bp
                        pop di
                        pop si
                        mov ax, ss
                        mov ds, ax
                    }
                } else {
                    d = (x + y + hash) & 7;
                    dd = dither[d];
                    u += dd;
                    v += dd;
                    /* every other pixel skips a little, in a pattern that
                     * depends on d, to blur distant shapes */
                    _asm {
                        push si
                        push di
                        push bp
                        mov cx, u
                        mov bx, v
                        mov dx, du
                        mov si, dv
                        mov ds, word ptr p+2
                        les di, dst
                        add dx, 80h
                        add si, 80h
                        mov al, byte ptr d
                        mov bp, n
                        or al, al
                        je m0
                        dec al
                        je m1
                        dec al
                        je m2
                        dec al
                        je m3
                        jmp m_hi
                    m0:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        je s0
                    w0:
                        stosb
                        dec bp
                        je e1
                    m1:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        sub cx, 0C0h
                        lea bx, [bx+si-0C0h]
                        or al, al
                        je s1
                    w1:
                        stosb
                        dec bp
                        je e1
                    m2:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        je s2
                    w2:
                        stosb
                        dec bp
                        je e1
                    m3:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        sub cx, 120h
                        lea bx, [bx+si-120h]
                        or al, al
                        je s3
                    w3:
                        stosb
                        dec bp
                        jne m4
                    e1:
                        jmp m_end
                    r0:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        jne w0
                    s0:
                        inc di
                        dec bp
                        je e2
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        sub cx, 0C0h
                        lea bx, [bx+si-0C0h]
                        or al, al
                        jne w1
                    s1:
                        inc di
                        dec bp
                        je e2
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        jne w2
                    s2:
                        inc di
                        dec bp
                        je e2
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        sub cx, 120h
                        lea bx, [bx+si-120h]
                        or al, al
                        jne w3
                    s3:
                        inc di
                        dec bp
                        jne r4
                    e2:
                        jmp m_end
                    m_hi:
                        dec al
                        je m4
                        dec al
                        je m5
                        dec al
                        je m6
                        jmp m7
                    m4:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        je s4
                    w4:
                        stosb
                        dec bp
                        je e2
                    m5:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        sub cx, 0C0h
                        lea bx, [bx+si-0C0h]
                        or al, al
                        je s5
                    w5:
                        stosb
                        dec bp
                        je e2
                    m6:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        je s6
                    w6:
                        stosb
                        dec bp
                        je e2
                    m7:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        sub cx, 160h
                        lea bx, [bx+si-160h]
                        or al, al
                        je s7
                    w7:
                        stosb
                        dec bp
                        je e2
                        jmp m0
                    r4:
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        jne w4
                    s4:
                        inc di
                        dec bp
                        je m_end
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        sub cx, 0C0h
                        lea bx, [bx+si-0C0h]
                        or al, al
                        jne w5
                    s5:
                        inc di
                        dec bp
                        je m_end
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        add bx, si
                        or al, al
                        jne w6
                    s6:
                        inc di
                        dec bp
                        je m_end
                        xchg ch, bl
                        mov al, [bx]
                        xchg ch, bl
                        add cx, dx
                        sub cx, 160h
                        lea bx, [bx+si-160h]
                        or al, al
                        jne w7
                    s7:
                        inc di
                        dec bp
                        je m_end
                        jmp r0
                    m_end:
                        pop bp
                        pop di
                        pop si
                        mov ax, ss
                        mov ds, ax
                    }
                }
            }
        }
    }
    UnlockScreen();
release:
    if (o->free)
        o->free(o);
}

/* Is any of the object inside the view frustum? */
int InView(Obj3D *o)
{
    Vec32 v;
    long dx;
    long dy;

    v = o->view;
    if (v.z < star_near)
        return 0;
    if (v.x > 0)
        dx = v.z * fr_right.x - (v.x - o->reach) * fr_right.z;
    else
        dx = fr_left.z * (v.x + o->reach) - fr_left.x * v.z;
    if (v.y > 0)
        dy = fr_top.y * v.z - fr_top.z * (v.y - o->reach);
    else
        dy = (v.y + o->reach) * fr_bottom.z - v.z * fr_bottom.y;
    return dx > 0 && dy > 0;
}

/* Straighten the orientation matrices of ships and planets. */
void OrthoR3(void)
{
    int i;
    Obj3D *o;

    for (i = 0; i != MAX_R3; i++) {
        if ((o = r3_list[i]) == 0)
            continue;
        if (o->visible == R3_SHIP || o->visible == R3_PLANET)
            MatOrtho(&o->orient);
    }
}

#define SPAN_ROW(r, x0, x1) \
    row = (r); \
    if (row >= clip_rect.y0 && row <= clip_rect.y1) { \
        row -= clip_rect.y0; \
        s[row].left = min(s[row].left, x0); \
        s[row].right = max(s[row].right, x1); \
    }

/* draw: a beam, two circles joined along the shot's direction */
void DrawBeam(Obj3D *o)
{
    Vec32 a;
    Vec32 b;
    long d[3];
    int sx0;
    int sy0;
    int sx1;
    int sy1;
    int unused1;
    int r0;
    int r1;
    int n;
    int unused2;
    Span *spans;
    int unused3;
    int unused4;

    o->r3s = 0;
    a = b = o->view;
    d[0] = o->view_m.e[2][0] * 200L / 0x4000;
    d[1] = o->view_m.e[2][1] * 200L / 0x4000;
    d[2] = o->view_m.e[2][2] * 200L / 0x4000;
    for (n = 0; n != 3; n++)
        (&a.x)[n] -= d[n], (&b.x)[n] += d[n];
    if (b.z < star_near || a.z < star_near)
        return;
    r0 = Project(o->reach >> 3, a.z);
    r1 = Project(o->reach >> 3, b.z);
    r0 = max(1, min(r0, 99));
    r1 = max(1, min(r1, 99));
    spans = AllocMemPtr((n = clip_rect.y1 - clip_rect.y0 + 1) * sizeof(Span));
    while (n-- > 0) {
        spans[n].right = -32767;
        spans[n].left = 32767;
    }
    sx0 = Project(a.x, a.z) + view_cx;
    sy0 = view_cy - Project(a.y, a.z);
    sx1 = Project(b.x, b.z) + view_cx;
    sy1 = view_cy - Project(b.y, b.z);
    LockScreen();
    SpanCircle(spans, sx1, sy1, r1);
    SpanCircle(spans, sx0, sy0, r0);
    SpanQuad(spans, sx0, sy0, sx1, sy1, r0, r1);
    FillSpans(spans, o->color + 2);
    DrawLine(sx0, sy0, sx1, sy1, o->color);
    OutlineSpans(spans, o->color + 4);
    UnlockScreen();
    FreeMemPtr(spans);
}

/* Add a filled circle to the spans. */
void SpanCircle(Span *s, int cx, int cy, int r)
{
    int x;
    int y;
    int d;
    int row;

    for (x = 0, y = r, d = 3 - r * 2; x < y; ++x) {
        SPAN_ROW(cy + y, cx - x, cx + x)
        SPAN_ROW(cy - y, cx - x, cx + x)
        SPAN_ROW(cy + x, cx - y, cx + y)
        SPAN_ROW(cy - x, cx - y, cx + y)
        if (d < 0)
            d = d + 4 * x + 6;
        else {
            d = d + 4 * (x - y) + 10;
            --y;
        }
    }
    if (x == y) {
        SPAN_ROW(cy + y, cx - x, cx + x)
        SPAN_ROW(cy - y, cx - x, cx + x)
        SPAN_ROW(cy + x, cx - y, cx + y)
        SPAN_ROW(cy - x, cx - y, cx + y)
    }
}

/* Add the quadrilateral joining two circles to the spans. */
void SpanQuad(Span *s, int x0, int y0, int x1, int y1, int r0, int r1)
{
    int a;
    int unused1;
    int unused2;
    int p[8];
    int unused3;
    int unused4;

    a = FixAtan2(y1 - y0, x1 - x0);
    ++r0;
    ++r1;
    p[0] = x0 + (long)r0 * FixCos(a + 0x100) / 0x4000;
    p[1] = y0 + (long)r0 * FixSin(a + 0x100) / 0x4000;
    p[2] = x1 + (long)r1 * FixCos(a + 0x100) / 0x4000;
    p[3] = y1 + (long)r1 * FixSin(a + 0x100) / 0x4000;
    p[4] = x1 + (long)r1 * FixCos(a - 0x100) / 0x4000;
    p[5] = y1 + (long)r1 * FixSin(a - 0x100) / 0x4000;
    p[6] = x0 + (long)r0 * FixCos(a - 0x100) / 0x4000;
    p[7] = y0 + (long)r0 * FixSin(a - 0x100) / 0x4000;
    SpanLine(s, p[4], p[5], p[6], p[7]);
    SpanLine(s, p[0], p[1], p[2], p[3]);
}

#define SPAN_POINT(x, y) \
    if ((y) >= clip_rect.y0 && (y) <= clip_rect.y1) { \
        row = (y) - clip_rect.y0; \
        s[row].right = max(s[row].right, x); \
        s[row].left = min(s[row].left, x); \
    }

void DrawLine(int x0, int y0, int x1, int y1, int c)
{
    int n;
    int unused;
    Point *p;
    Point *list;
    char far *base;

    if ((list = p = LinePoints(x0, y0, x1, y1)) == 0)
        return;
    LockScreen();
    base = screen->data;
    for (n = p->x, ++p; n--; ++p) {
        if (p->y < clip_rect.y0 || p->y > clip_rect.y1)
            continue;
        if (p->x > clip_rect.x1 || p->x < clip_rect.x0)
            continue;
        base[p->y * 320 + p->x] = c;
    }
    FreeMemPtr(list);
    UnlockScreen();
}

/* The points of a line clipped to clip_rect: a count, then the points.
 * Returns 0 if the line is outside. */
Point *LinePoints(int x0, int y0, int x1, int y1)
{
    int e;
    int inc1;
    int inc2;
    int sx;
    int sy;
    int adx;
    int ady;
    Point *p;
    Point *list;

    sx = x0 < clip_rect.x0 ? 1 : 0;
    sx |= x0 > clip_rect.x1 ? 2 : 0;
    sx |= y0 < clip_rect.y0 ? 4 : 0;
    sx |= y0 > clip_rect.y1 ? 8 : 0;
    sy = x1 < clip_rect.x0 ? 1 : 0;
    sy |= x1 > clip_rect.x1 ? 2 : 0;
    sy |= y1 < clip_rect.y0 ? 4 : 0;
    sy |= y1 > clip_rect.y1 ? 8 : 0;
    if (sx & sy)
        return 0;
    if (sx | sy) {
        int nx;
        int ny;

        e = sx ^ sy;
        adx = x1 - x0;
        ady = y1 - y0;
        if (e & 1) {
            _asm {
                mov ax, clip_rect.x0
                sub ax, x0
                imul ady
                idiv adx
                add ax, y0
                mov ny, ax
            }
            nx = clip_rect.x0;
            if (sx & 1) {
                x0 = nx;
                y0 = ny;
            } else {
                x1 = nx;
                y1 = ny;
            }
        }
        if (e & 2) {
            _asm {
                mov ax, clip_rect.x1
                sub ax, x0
                imul ady
                idiv adx
                add ax, y0
                mov ny, ax
            }
            nx = clip_rect.x1;
            if (sx & 2) {
                x0 = nx;
                y0 = ny;
            } else {
                x1 = nx;
                y1 = ny;
            }
        }
        if (e & 4) {
            _asm {
                mov ax, clip_rect.y0
                sub ax, y0
                imul adx
                idiv ady
                add ax, x0
                mov nx, ax
            }
            ny = clip_rect.y0;
            if (sx & 4) {
                x0 = nx;
                y0 = ny;
            } else {
                x1 = nx;
                y1 = ny;
            }
        }
        if (e & 8) {
            _asm {
                mov ax, clip_rect.y1
                sub ax, y0
                imul adx
                idiv ady
                add ax, x0
                mov nx, ax
            }
            ny = clip_rect.y1;
            if (sx & 8) {
                x0 = nx;
                y0 = ny;
            } else {
                x1 = nx;
                y1 = ny;
            }
        }
        if (!PointInRect(&clip_rect, nx, ny))
            return 0;
    }
    adx = ABS(x1 - x0);
    ady = ABS(y1 - y0);
    sx = SGN(x1 - x0);
    sy = SGN(y1 - y0);
    if (adx >= ady) {
        e = ady * 2 - adx;
        inc1 = ady * 2;
        inc2 = (ady - adx) * 2;
        list = p = AllocMemPtr((adx + 2) * sizeof(Point));
        p->x = adx;
        p->y = 0;
        ++p;
        p->x = x0;
        p->y = y0;
        ++p;
        while (x0 != x1) {
            x0 += sx;
            if (e < 0)
                e += inc1;
            else
                e += inc2, y0 += sy;
            p->x = x0;
            p->y = y0;
            ++p;
        }
    } else {
        e = adx * 2 - ady;
        inc1 = adx * 2;
        inc2 = (adx - ady) * 2;
        list = p = AllocMemPtr((ady + 2) * sizeof(Point));
        p->x = ady;
        p->y = 0;
        ++p;
        p->x = x0;
        p->y = y0;
        ++p;
        while (y0 != y1) {
            y0 += sy;
            if (e < 0)
                e += inc1;
            else
                e += inc2, x0 += sx;
            p->x = x0;
            p->y = y0;
            ++p;
        }
    }
    return list;
}

/* Add the points of a line to the spans. */
void SpanLine(Span *s, int x0, int y0, int x1, int y1)
{
    int e;
    int inc1;
    int inc2;
    int sx;
    int sy;
    int dx;
    int dy;
    int row;

    dx = ABS(x1 - x0);
    dy = ABS(y1 - y0);
    sx = SGN(x1 - x0);
    sy = SGN(y1 - y0);
    if (dx >= dy) {
        e = dy * 2 - dx;
        inc1 = dy * 2;
        inc2 = (dy - dx) * 2;
        SPAN_POINT(x0, y0)
        while (x0 != x1) {
            x0 += sx;
            if (e < 0)
                e += inc1;
            else
                e += inc2, y0 += sy;
            SPAN_POINT(x0, y0)
        }
    } else {
        e = dx * 2 - dy;
        inc1 = dx * 2;
        inc2 = (dx - dy) * 2;
        SPAN_POINT(x0, y0)
        while (y0 != y1) {
            y0 += sy;
            if (e < 0)
                e += inc1;
            else
                e += inc2, x0 += sx;
            SPAN_POINT(x0, y0)
        }
    }
}

/* Fill the spans (one per row of clip_rect) with colour c. */
void FillSpans(Span *s, int c)
{
    char far *base;

    LockScreen();
    base = screen->data + clip_rect.y0 * 320;
    span_fill = (c & 0xFF) | (c << 8);
    _asm {
        mov si, s
        les bx, base
        mov dx, clip_rect.y1
        sub dx, clip_rect.y0
        inc dx
        push bp
    f_row:
        lodsw
        mov cx, ax
        lodsw
        cmp cx, ax
        jl f_next
        cmp ax, clip_rect.x1
        jg f_next
        cmp cx, clip_rect.x0
        jl f_next
        cmp ax, clip_rect.x0
        jge f_l
        mov ax, clip_rect.x0
    f_l:
        cmp cx, clip_rect.x1
        jle f_r
        mov cx, clip_rect.x1
    f_r:
        mov di, bx
        add di, ax
        sub cx, ax
        inc cx
        mov bp, cx
        mov ax, span_fill
        cmp cx, 3
        jl f_bytes
        test di, 1
        je f_even
        stosb
        dec cx
        dec bp
    f_even:
        shr cx, 1
        rep stosw
        test bp, 1
        je f_next
        stosb
        jmp short f_next
    f_bytes:
        rep stosb
    f_next:
        add bx, 320
        dec dx
        jne f_row
        pop bp
    }
    UnlockScreen();
}

/* Plot the ends of the spans in colour c. */
void OutlineSpans(Span *s, int c)
{
    char far *base;

    LockScreen();
    base = screen->data + clip_rect.y0 * 320;
    _asm {
        mov si, s
        les bx, base
        mov dx, clip_rect.y1
        sub dx, clip_rect.y0
        inc dx
        push bp
        mov ax, c
        mov ah, al
        mov bp, ax
    o_row:
        lodsw
        mov cx, ax
        lodsw
        cmp cx, ax
        jl o_next
        cmp ax, clip_rect.x1
        jg o_next
        cmp cx, clip_rect.x0
        jl o_next
        cmp ax, clip_rect.x0
        jge o_l
        mov ax, clip_rect.x0
    o_l:
        cmp cx, clip_rect.x1
        jle o_r
        mov cx, clip_rect.x1
    o_r:
        mov di, ax
        mov ax, bp
        mov es:[bx+di], al
        mov di, cx
        mov es:[bx+di], al
    o_next:
        add bx, 320
        dec dx
        jne o_row
        pop bp
    }
    UnlockScreen();
}

void SaveR3(Obj3D *o)
{
    SaveWrite(o, sizeof(Obj3D));
}

void SaveR3Shot(Obj3D *o)
{
    SaveWrite(o, 0xA8);
}

void RestoreR3(Obj3D *o)
{
    SaveRead(o, sizeof(Obj3D));
    if (o->visible) {
        AddR3(o);
        switch (o->visible) {
        case R3_SHIP:
            o->draw = SelectView;
            o->free = ReleaseShipShape;
            break;
        case R3_SHOT:
            Fatal("illegal shot saved in restore r3.");
            break;
        }
    }
}

void RestoreR3Shot(Obj3D *o)
{
    SaveRead(o, 0xA8);
    if (o->visible) {
        AddR3(o);
        switch (o->visible) {
        case R3_PLANET:
        case R3_SHIP:
            Fatal("illegal non-shot saved in restore r3 shot.");
            break;
        case R3_SHOT:
            o->draw = LoadShotShape;
            o->free = FreeShotShape;
            break;
        }
    }
}

void SaveSpace(void)
{
    Obj3D *o;

    SaveR3(&player_ship);
    SaveR3Shot((Obj3D *)&shot_obj);
    SaveWrite(&cam_pos, sizeof(cam_pos));
    SaveWrite(&cam_orient, sizeof(cam_orient));
    SaveWrite(enemy_name, sizeof(enemy_name));
    SaveWrite(&enemy_count, sizeof(enemy_count));
    for (o = ships; o != &ships[4]; o++)
        SaveR3(o);
}

void LoadSpace(void)
{
    Obj3D *o;
    int i;

    for (i = 0; i != MAX_R3; i++) {
        if ((o = r3_list[i]) == 0)
            continue;
        if (o->visible)
            DelR3(o);
    }
    RestoreR3(&player_ship);
    RestoreR3Shot((Obj3D *)&shot_obj);
    SaveRead(&cam_pos, sizeof(cam_pos));
    SaveRead(&cam_orient, sizeof(cam_orient));
    SaveRead(enemy_name, sizeof(enemy_name));
    SaveRead(&enemy_count, sizeof(enemy_count));
    for (o = ships; o != &ships[4]; o++) {
        RestoreR3(o);
        o->ai_busy = 0;
    }
    SetRepair(-1);
}

/* New in the sequel (target brackets): clipped lines of colour c. */
void VLineClip(int x, int y0, int len, int c)
{
    int y1;
    char far *p;

    LockScreen();
    y1 = y0 + len - 1;
    if (x >= clip_rect.x0 && x <= clip_rect.x1 && y0 <= clip_rect.y1 && y1 >= clip_rect.y0) {
        y0 = max(clip_rect.y0, y0);
        p = screen->data + y0 * 320 + x;
        y1 = min(clip_rect.y1, y1);
        len = y1 - y0 + 1;
        while (len--) {
            *p = c;
            p += 320;
        }
    }
    UnlockScreen();
}

void HLineClip(int x0, int y, int len, int c)
{
    int x1;
    char far *p;

    LockScreen();
    x1 = x0 + len - 1;
    if (y >= clip_rect.y0 && y <= clip_rect.y1 && x0 <= clip_rect.x1 && x1 >= clip_rect.x0) {
        x0 = max(clip_rect.x0, x0);
        p = screen->data + (x0 + y * 320);
        x1 = min(clip_rect.x1, x1);
        len = x1 - x0 + 1;
        while (len--)
            *p++ = c;
    }
    UnlockScreen();
}

