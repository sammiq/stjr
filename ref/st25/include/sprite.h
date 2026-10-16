/* sprite.h - sprites drawn over the background into the back buffer */

#ifndef SPRITE_H
#define SPRITE_H

#include "mem.h"

#ifndef RECT_DEFINED
#define RECT_DEFINED
typedef struct Rect {
    int x0;
    int y0;
    int x1;
    int y1;
} Rect;
#endif

/* Sprite types. */
#define SPRITE_BITMAP   0       /* bitmap, masked by the EGA priority buffer */
#define SPRITE_RECT     1       /* invisible rectangle, never drawn */
#define SPRITE_SHADOW   2       /* 0 pixels shade the background */
#define SPRITE_TEXT     3       /* bitmap of characters drawn with font.fnt */

#define MAX_SPRITES 32

typedef struct Sprite {
    int x;                  /* 00 */
    int y;                  /* 02 */
    int z;                  /* 04 priority, sort key */
    int layer;              /* 06 second sort key */
    char *name;             /* 08 */
    MemHandle handle;       /* 0A bitmap */
    int type;               /* 0C */
    int colour;             /* 0E text colour */
    int dirty;              /* 10 */
    int has_union;          /* 12 union is valid */
    int visible;            /* 14 */
    int erase;              /* 16 */
    Rect old;               /* 18 rect when last drawn */
    Rect rect;              /* 20 clipped screen rect */
    Rect union_rect;        /* 28 old | rect */
    int ox;                 /* 30 bitmap origin on screen */
    int oy;                 /* 32 */
} Sprite;

extern Sprite **sprite_list;
extern int *sprite_count;
extern Rect screen_rect;
extern Sprite mouse_sprite;

int ClipRect(Rect *out, Rect *a, Rect *b);      /* seg007 */
void UnionRect(Rect *out, Rect *a, Rect *b);    /* seg007 */

void GetSpriteList(Sprite **list, int *count);
void SetSpriteList(Sprite **list, int *count);
void ResetSpriteList(void);
void MarkAllDirty(void);
void ClearSprites(void);
void SpriteInit(Sprite *s);
void AddSprite(Sprite *s);
void DelSprite(Sprite *s);
void SpriteErase(Sprite *s);
void UpdateSprites(void);
void SortSprites(void);
int CompareSprites(Sprite **a, Sprite **b);
void ComputeSpriteRects(void);
void DrawSprite(Sprite *s, Rect *clip);
void RestoreBackground(Rect *r);
void MatchPalette(unsigned char far *pal, int first, int count);
void LoadRemap(char *name);
void BlitEGA(Rect *r);
void DrawTestPattern(void);
void BlitTandy(Rect *r);
void BlitToScreen(Rect *r);
Sprite *SpriteAt(int x, int y);
void SpriteSetPos(Sprite *s, int x, int y, unsigned z);
void SpriteSetBitmap(Sprite *s, MemHandle h);
void SpriteAddRect(Sprite *s, MemHandle h, int x0, int y0, int x1, int y1);
void RedrawSpritesIn(Rect *r);

#endif
