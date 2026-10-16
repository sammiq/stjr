/* seg022: the star chart */

#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "sprite.h"
#include "gfx.h"
#include "event.h"
#include "obj3d.h"

typedef struct Point {
    int x;
    int y;
} Point;

#define NUM_STARS 45

void CyclePalette(void);               /* seg000 */
void WarpOut(void);               /* seg025 */
void CreatePlanet(Obj3D *o, char *name, int radius, int small, unsigned seed, int pal);
void RandomPlanet(Obj3D *o);

extern Bitmap far *backbuf;
extern Bitmap far *screen;
extern long blink_count;

Point *NearestStar(int x, int y);

void OffsetRect(Rect *out, Rect *r, int dx, int dy)
{
    out->x0 = r->x0 + dx;
    out->y0 = r->y0 + dy;
    out->x1 = r->x1 + dx;
    out->y1 = r->y1 + dy;
}

#define ABS(v) ((v) > 0 ? (v) : -(v))

