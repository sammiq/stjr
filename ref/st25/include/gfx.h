/* gfx.h - video modes, palettes, fades, rectangles and the 8x8 font */

#ifndef GFX_H
#define GFX_H

#include "mem.h"
#include "bitmap.h"

#ifndef RECT_DEFINED
#define RECT_DEFINED
typedef struct Rect {
    int x0;
    int y0;
    int x1;
    int y1;
} Rect;
#endif

/* video_mode */
#define VIDEO_VGA       0       /* mode 13h */
#define VIDEO_EGA       1       /* mode 0Eh, two pixels per remapped byte */
#define VIDEO_TANDY     2       /* Tandy 1000 320x200x16 */

extern int video_mode;                  /* -1 until InitVideo */
extern unsigned char cur_palette[768];
extern unsigned char shade_table[256];
extern unsigned char remap_table[256];
extern int fade_level;                  /* 0 black .. 100 full */

void SetTandyLevel(int level);
void InitTandyMode(void);
void InitVideo(void);
void TextMode(void);
void SetPalette(unsigned char far *pal);
void SetPaletteRange(unsigned char far *pal, int first, int count);
void LoadPalette(char *name);
void CopyRect(Bitmap far *dst, int x, int y, Bitmap far *src, int sx, int sy, int w, int h);
void CopyRectNZ(Bitmap far *dst, int x, int y, Bitmap far *src, int sx, int sy, int w, int h);
void CopyRectRemap(Bitmap far *dst, int x, int y, Bitmap far *src, int sx, int sy, int w, int h,
                   int remap);
int PointInRect(Rect *r, int x, int y);
int ClipRect(Rect *out, Rect *a, Rect *b);
void UnionRect(Rect *out, Rect *a, Rect *b);
char *WrapLine(char *src, char *dst, int width);
void SetGlyph(int c);
void BlitRows(char far *src, int sskip, char far *dst, int dskip, int w, int h);
int DrawString(char *s, int x, int y, Bitmap far *bmp);
void DrawText(char *s, int len, int x, int y, Bitmap far *bmp);
void LoadFont(void);
void FreeFont(void);
void VideoNop(void);
void FadeIn(void);
void FadeOut(void);
void SetFade(unsigned char far *pal, int level);
void FadeUp(void);
void FadeDown(void);

#endif
