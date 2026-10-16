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

