/* seg023: starfield */

#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"

typedef struct Vec32 {
    long x;
    long y;
    long z;
} Vec32;

typedef struct Rect {
    int x0;
    int y0;
    int x1;
    int y1;
} Rect;

typedef struct Star {
    int active;             /* 00 */
    Vec32 pos;              /* 02 world position */
} Star;

#define NUM_STARS 16

extern float star_near;
extern int view_w;
extern int view_h;
extern long proj_dist;
extern int cam_matrix[3][3];
extern Vec32 cam_pos;
extern int view_cx;
extern int view_cy;
extern Rect clip_rect;
extern Bitmap far *screen;

/* seg027 */
void Vec32FromScreen(Vec32 *out, int x, int y, int z);
void MatVecMul32(int *m, Vec32 *v, Vec32 *out);
void Vec32Add(Vec32 *a, Vec32 *b);
void Vec32Sub(Vec32 *a, Vec32 *b);
void MatTVecMul32(Vec32 *v, int *m, Vec32 *out);
int Project(long a, long z);

int ClipRect(Rect *out, Rect *a, Rect *b);      /* seg007: clip a to b */

MemHandle star_bmp = 0;
Star stars[NUM_STARS];

void BlitClipped(Bitmap far *bmp, Rect *r, Rect *clip);

void StarsReset(void)
{
    long unused;

    if (star_bmp)
        CacheRelease(star_bmp);
    MemSet(stars, sizeof(stars), 0);
}

/* Respawn, move and draw the stars around the camera. stars.shp holds
 * the star frames back to back. */
void DrawStars(void)
{
    int i;
    int x;
    int y;
    int z;
    Vec32 v2;
    Vec32 v;
    long unused1;
    Star *s;
    int wr;
    int hr;
    int wr2;
    int hr2;
    Rect r;
    Rect rc;
    char unused2[16];
    Bitmap far *bmp;
    char far *cur;
    char far *base;

    wr = (view_w * 3) >> 1;
    wr2 = wr / 2;
    hr = (view_h * 3) >> 1;
    hr2 = hr / 2;
    z = proj_dist << 3;
    star_bmp = CacheLoad("stars", "shp");
    base = cur = LockMem(star_bmp);
    for (s = stars, i = 0; i != NUM_STARS; ++i, ++s) {
        if ((i & 0xF) == 0)
            cur = base;
        bmp = (Bitmap far *)cur;
        cur = cur + (((Bitmap far *)cur)->w * ((Bitmap far *)cur)->h + 8);
        if (s->active == 0) {
            x = rand() % wr - wr2;
            y = rand() % hr - hr2;
            Vec32FromScreen(&v, x, y, z);
            MatVecMul32((int *)cam_matrix, &v, &s->pos);
            Vec32Add(&s->pos, &cam_pos);
            s->active = 1;
        }
        v = s->pos;
        Vec32Sub(&v, &cam_pos);
        MatTVecMul32(&v, (int *)cam_matrix, &v2);
        if (v2.z > star_near && v2.z < 0x3FFF
                && (v2.x > 0 ? v2.x : -v2.x) < v2.z
                && (v2.y > 0 ? v2.y : -v2.y) < v2.z) {
            r.x0 = Project(v2.x, v2.z) + view_cx;
            r.y0 = view_cy - Project(v2.y, v2.z);
            r.x1 = r.x0 + bmp->w - 1;
            r.y1 = r.y0 + bmp->h - 1;
            if (ClipRect(&rc, &r, &clip_rect))
                BlitClipped(bmp, &r, &rc);
        } else
            s->active = 0;
    }
    UnlockMem(star_bmp);
    CacheRelease(star_bmp);
    star_bmp = 0;
}

/* Draw the part clip of bmp placed at r into the screen, skipping 0. */
void BlitClipped(Bitmap far *bmp, Rect *r, Rect *clip)
{
    int w;
    int h;
    int x0;
    int y0;
    char far *src;
    char far *dst;
    int srcskip;
    int dstskip;
    int unused;

    x0 = r->x0;
    y0 = r->y0;
    r = clip;
    w = r->x1 - r->x0 + 1;
    h = r->y1 - r->y0 + 1;
    src = bmp->data + r->x0 - x0;
    src += (r->y0 - y0) * bmp->w;
    srcskip = bmp->w - w;
    dst = screen->data + r->x0 + r->y0 * 320;
    dstskip = 320 - w;
    _asm {
        push si
        push di
        push ds
        lds si, src
        les di, dst
    l_row:
        dec h
        js l_done
        mov cx, w
    l_pix:
        lodsb
        or al, al
        je l_skip
        stosb
        loop l_pix
        jmp short l_next
    l_skip:
        inc di
        loop l_pix
    l_next:
        add si, srcskip
        add di, dstskip
        jmp l_row
    l_done:
        pop ds
        pop di
        pop si
    }
}
