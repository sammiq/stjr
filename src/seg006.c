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
extern unsigned char byte_45B3C[];
extern int view_tab[24][13];        /* bitmap for each yaw and pitch, 0x8000 mirrored */

Obj3D *r3_list[MAX_R3] = { 0 };

void CamReset(void);
void SetView(int x0, int y0, int x1, int y1, int fov);
void DrawStatic(void);
void ClearR3List(void);
void AddR3(Obj3D *o);
void DelR3(Obj3D *o);
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

void CamReset(void)
{
    MemSet(&cam_pos, sizeof(cam_pos), 0);
    MatIdentity(&cam_orient);
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

void SaveR3(Obj3D *o)
{
    SaveWrite(o, sizeof(Obj3D));
}

void SaveR3Shot(Obj3D *o)
{
    SaveWrite(o, 0xA8);
}

