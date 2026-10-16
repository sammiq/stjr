/* seg000: actors in the away-team rooms - animations, walking, the walk
 * graph and .ban screen animations */

#include <stdio.h>
#include <string.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "gfx.h"
#include "sprite.h"
#include "resource.h"
#include "fixmath.h"
#include "actor.h"

/* Globals this file owns (declared in the headers). */
Ban bans[16];

#define ABS(x)  ((x) > 0 ? (x) : -(x))
#define SGN(x)  ((x) > 0 ? 1 : ((x) < 0 ? -1 : 0))

typedef struct WalkNode {
    int x;
    int y;
} WalkNode;

/* NearestNode's list: node and distance. */
typedef struct NodeDist {
    int idx;
    int dist;
} NodeDist;

int rand(void);
void qsort();
void Fatal(char *fmt, ...);     /* fatal error */
void SaveWrite(void *p, unsigned n);    /* seg019 */
void SaveRead(void *p, unsigned n);
int WalkBlocked(int x, int y);        /* seg008: is (x, y) blocked */
void CheckRegions(int x, int y);       /* seg008 */
void PostRoomMsg(int msg, int who, int a, int b);     /* seg008: report */
int DepthPri(int y);               /* seg008: depth for y */
int DepthScale(int y);               /* seg008: scale for y */
void StandUp(Actor *a, int n);    /* seg008 */

extern Bitmap far *screen;
extern Bitmap far *backbuf;
extern unsigned long blink_count;
extern int video_mode;
extern int ems_other_page;
extern unsigned char pal_remap[];
/* The room's walk graph (.iw file). */
typedef struct WalkGraph {
    int count;
    WalkNode nodes[32];
    unsigned char next[32][32];     /* next node from a towards b */
} WalkGraph;

WalkGraph walk;

void SaveActors(void);
void LoadActors(void);
void InitActors(void);
int StartAnim(int n, char *name, int x, int y, int scale);
void LoadBan(char *name);
int StartWalk(int n, char *name, int x, int y, int dx, int dy);
void UpdateActors(void);
void AnimStep(int n);
void WalkStep(int n);
void DrawBans(void);
void LockScreen(void);           /* seg012 */
void UnlockScreen(void);
void UpdateBans(void);
void BanDraw(char far *dst, char far *src);
void BanCopyEGA(char far *dst, char far *src, char far *from);
char far *BanEGA(char far *dst, char far *src, char far *from);
char far *BanTandy(char far *dst, char far *src, char far *from);
char far *BanCopy(char far *dst, char far *src, char far *from);
void EndOrStand(int n);
void EndAnim(int n);
void FreeActors(void);
void InitAnim(Actor *a, char *name, int x, int y, int scale, int add);
void release_anim(Actor *a);
void FreeAnim(Actor *a);
void FreeWalk(Actor *a);
void init_stand_anim(int n);
void SetWalkFrame(Actor *a, int x, int y);
void SetWalk(Actor *a, int x0, int y0, int x1, int y1);
int CanWalk(int x0, int y0, int x1, int y1);
void LoadWalkGraph(char *name);
int NearestNode(int x, int y);
int CompareDist(NodeDist *a, NodeDist *b);

void LoadBan(char *name)
{
    int i;

    for (i = 0; i != 16; i++)
        if (bans[i].h == 0) {
            bans[i].h = CacheLoad(name, "ban");
            (bans + i)->pos = 0;
            break;
        }
}

/* Update the screen where each .ban changed the back buffer. */
/* Draw the next frame of each .ban into the screen and back buffer. */
void DrawBans(void)
{
    int n;
    Ban *b;
    char far *base;
    char far *p;

    b = bans;
    if ((blink_count & 3) != 0)
        return;
    LockScreen();               /* new: the screen bitmap lives in EMS */
    for (n = 16; n != 0; --n, ++b) {
        if (b->h) {
            base = LockMem(b->h);
            p = base + b->pos;
            if (*(int far *)p == -1)
                p = base;
            if (((int far *)p)[1] != 0) {
                BanDraw(screen->data, p);
                switch (video_mode) {
                case VIDEO_VGA:
                case VIDEO_TANDY:
                    BanDraw(backbuf->data, p);
                    break;
                case VIDEO_EGA:
                    BanCopyEGA(backbuf->data, p, screen->data);
                    break;
                }
            }
            b->pos = p - base;
            UnlockMem(b->h);
        }
    }
    UnlockScreen();
}

void UpdateBans(void)
{
    int n;
    Ban *b;
    Rect r;
    char far *base;
    char far *p;

    b = bans;
    if ((blink_count & 3) != 0)
        return;
    for (n = 16; n != 0; --n, ++b) {
        if (b->h) {
            base = LockMem(b->h);
            p = base + b->pos;
            if (*(int far *)p == -1)
                p = base, b->pos = 0;
            if (((int far *)p)[1] != 0) {
                r.x0 = ((int far *)p)[2];
                r.y0 = ((int far *)p)[3];
                r.x1 = ((int far *)p)[4];
                r.y1 = ((int far *)p)[5];
                switch (video_mode) {
                case VIDEO_VGA:
                    UnlockMem(b->h);
                    RedrawSpritesIn(&r);
                    base = LockMem(b->h);
                    p = base + b->pos;
                    p = BanCopy((char far *)0xA0000000L, p, backbuf->data);
                    break;
                case VIDEO_TANDY:
                    UnlockMem(b->h);
                    RedrawSpritesIn(&r);
                    base = LockMem(b->h);
                    p = base + b->pos;
                    p = BanTandy((char far *)0xA0000000L, p, backbuf->data);
                    break;
                case VIDEO_EGA:
                    r.x0 &= 0xFFFC;
                    r.x1 |= 3;
                    UnlockMem(b->h);
                    RedrawSpritesIn(&r);
                    base = LockMem(b->h);
                    p = base + b->pos;
                    p = BanEGA((char far *)0xA0000000L, p, backbuf->data);
                }
            } else
                p += 4;
            b->pos = p - base;
            UnlockMem(b->h);
        }
    }
}

/* Draw a .ban frame: a start offset and run count, an 8 byte rectangle,
 * then runs (n+1 literal bytes, 0 transparent; -n: n+1 copies; 80h: skip). */
void BanDraw(char far *dst, char far *src)
{
    _asm {
        push ds
        push si
        push di
        lds si, src
        les di, dst
        lodsw
        add di, ax
        lodsw
        mov dx, ax
        add si, 8
        sub cx, cx
    d_next:
        dec dx
        js d_done
        lodsb
        or al, al
        js d_neg
        mov cl, al
        inc cx
    d_lit:
        lodsb
        or al, al
        je d_skip
        stosb
        loop d_lit
        jmp d_next
    d_skip:
        inc di
        loop d_lit
        jmp d_next
    d_neg:
        cmp al, 80h
        je d_jump
        mov cl, al
        neg cl
        inc cx
        lodsb
        or al, al
        jne d_fill
        add di, cx
        jmp d_next
    d_fill:
        rep stosb
        jmp d_next
    d_jump:
        lodsw
        add di, ax
        jmp d_next
    d_done:
        pop di
        pop si
        pop ds
    }
}

/* EGA: copy the changed runs of from (whole words) into dst. */
void BanCopyEGA(char far *dst, char far *src, char far *from)
{
    _asm {
        push ds
        push si
        push di
        push bp
        lds si, src
        les di, dst
        mov bp, word ptr from+2
        lodsw
        add di, ax
        lodsw
        mov dx, ax
        add si, 8
        sub cx, cx
        mov bx, si
    e_next:
        dec dx
        js e_done
        mov al, [bx]
        inc bx
        or al, al
        js e_neg
        mov cl, al
        inc cx
        add bx, cx
    e_copy:
        mov si, di
        and si, 0FFFCh
        add di, cx
        push ds
        mov ds, bp
        push di
        add di, 3
        and di, 0FFFCh
        sub di, si
        shr di, 1
        mov cx, di
        mov di, si
        rep movsw
        pop di
        pop ds
        jmp e_next
    e_neg:
        cmp al, 80h
        je e_jump
        mov cl, al
        neg cl
        inc cx
        mov al, [bx]
        inc bx
        or al, al
        jne e_copy
        add di, cx
        jmp e_next
    e_jump:
        add di, [bx]
        add bx, 2
        jmp e_next
    e_done:
        pop bp
        pop di
        pop si
        pop ds
    }
}

/* EGA and Tandy are gone from the sequel. */
char far *BanEGA(char far *dst, char far *src, char far *from)
{
    return src;
}

char far *BanTandy(char far *dst, char far *src, char far *from)
{
    return src;
}

/* VGA: copy the changed runs of from into dst. */
char far *BanCopy(char far *dst, char far *src, char far *from)
{
    _asm {
        push ds
        push si
        push di
        push bp
        lds si, src
        les di, dst
        mov bp, word ptr from+2
        lodsw
        add di, ax
        lodsw
        mov dx, ax
        add si, 8
        sub cx, cx
        mov bx, si
    b_next:
        dec dx
        js b_done
        mov al, [bx]
        inc bx
        or al, al
        js b_neg
        mov cl, al
        inc cx
        add bx, cx
    b_copy:
        push ds
        mov ds, bp
        mov si, di
        add si, 8
        rep movsb
        pop ds
        jmp b_next
    b_neg:
        cmp al, 80h
        je b_jump
        mov cl, al
        neg cl
        inc cx
        mov al, [bx]
        inc bx
        or al, al
        jne b_copy
        add di, cx
        jmp b_next
    b_jump:
        add di, [bx]
        add bx, 2
        jmp b_next
    b_done:
        pop bp
        mov word ptr src, bx
        pop di
        pop si
        pop ds
    }
    return src;
}

/* Load the room's walk graph from name.iw: node count, nodes, then for
 * each node the next node towards every other. */
#define READ(dst, n)    (MemCpy(dst, p, n), p += (n))

int CompareDist(NodeDist *a, NodeDist *b)
{
    return a->dist - b->dist;
}
