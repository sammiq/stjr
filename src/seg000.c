/* seg000: actors in the away-team rooms - animations, walking, the walk
 * graph and .ban screen animations */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "gfx.h"
#include "sprite.h"
#include "resource.h"
#include "fixmath.h"
#include "actor.h"
#include "ems.h"

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

void Fatal(char *fmt, ...);     /* fatal error */
void SaveWrite(void *p, unsigned n);    /* seg019 */
void SaveRead(void *p, unsigned n);
int WalkBlocked(int x, int y);        /* seg008: is (x, y) blocked */
void CheckRegions(int x, int y, int tx, int ty);       /* seg008 */
void PostRoomMsg(unsigned char a, unsigned char b, unsigned char c, unsigned char d);  /* seg008 */
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

static WalkGraph walk;

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
void ReleaseAnim(Actor *a);
int StartTalk(int n, char *name, int x, int y, int scale, int force);
void WalkActorTo(int n, int x0, int y0, int x1, int y1, int notify);
void ActorPos(int n, int x, int y, int z);
void ClickRegion(int x, int y);          /* seg008 */
void SetCallback(int n, int (far *fn)(int n), int notify);
void StartEffect(int n, unsigned kind, int notify);
void CallbackStep(int n);
void WalkDone(Actor *a);
void GrowBitmap(Actor *a, int grow);
void TalkStep(int n);
void FillColor(Actor *a, unsigned char color);
int DigiStatus(void);
void BridgeSfx(int n);
extern unsigned char sfx_vol_next;
extern unsigned char sfx_pan_next;
void FadePixels(Actor *a, unsigned char level);
void Outline(Actor *a, unsigned char color);
int far Effect0(int n);
int far Effect1(int n);
int far Effect2(int n);
int far Effect3(int n);
int IsEMSHandle(MemHandle h);
MemHandle AllocMemAbort(unsigned size, int ems);
void FreeSpriteBitmap(MemHandle h, int scale);
MemHandle CacheLoadEMS(char *name, char *ext);
MemHandle LoadSpriteBitmap(char *name, int scale);
long GetFileSize(char *name, char *ext);

typedef struct StateBits {
    unsigned char used : 1;
    unsigned char callback : 1;
    unsigned char walk : 1;
    unsigned char b3 : 1;
    unsigned char stopped : 1;
    unsigned char hold : 1;
    unsigned char talk : 1;
    unsigned char b7 : 1;
} StateBits;

int word_3B8B2 = 1;
Actor *talk_actor;

void SaveActors(void)
{
    SaveWrite(actors, sizeof(actors));
}

void LoadActors(void)
{
    Actor *a;
    int i;

    SaveRead(actors, sizeof(actors));
    for (a = actors, i = 0; i != MAX_ACTORS; a++, i++) {
        if (a->state & ACT_USED) {
            if (!(a->state & (ACT_CALLBACK | ACT_WALK)))
                a->anim_h = CacheLoadEMS(a->anim, "anm");
            AddSprite(&a->sprite);
            SpriteSetBitmap(&a->sprite, LoadSpriteBitmap(a->name, a->scale));
            if (a->state & ACT_CALLBACK) {
                a->count = 0;
                a->fn(i);
            }
        }
    }
}

void InitActors(void)
{
    MemSet(actors, sizeof(actors), 0);
    MemSet(bans, sizeof(bans), 0);
}

void ActorPos(int n, int x, int y, int z)
{
    Actor *a;

    a = &actors[n];
    a->x = x;
    a->y = y;
    a->z = z;
}

/* Play name.anm on actor n (-1: a free one) at (x, y): its number. A '?'
 * first is the actor's letter, a '?' last the way it faces. */
int StartAnim(int n, char *name, int x, int y, int scale)
{
    char buf[10];
    Actor *a;
    int pri;
    Sprite *spr;
    AnimFrame far *f;

    if (n == -1) {
        for (n = MAX_ACTORS - 1, a = &actors[MAX_ACTORS - 1]; n >= 9; n--, a--)
            if (!(a->state & ACT_USED))
                break;
        if (n < 9)
            Fatal("All anims in use.");
    } else
        a = &actors[n];
    if (x == -1)
        x = a->sprite.x;
    if (y == -1)
        y = a->sprite.y;
    if (scale == -1)
        scale = a->flags & 0x20 ? DepthScale(y) : 0x100;
    spr = &a->sprite;
    if (a->state & ACT_USED)
        ReleaseAnim(a);
    else
        AddSprite(spr);
    a->state |= ACT_USED;
    strncpy(buf, name, 9);
    buf[8] = 0;
    if (a->letter && buf[0] == '?')
        buf[0] = a->letter;
    {
        int len;

        len = strlen(buf);
        if (buf[len - 1] == '?') {
            if (a->dir) {
                a->dir2 = a->dir;
                a->dir = 0;
            } else if (!a->dir2)
                a->dir2 = 's';
            buf[len - 1] = a->dir2;
        }
    }
    if (!word_3B8B2 && memcmp(name, "?stnd?", 7) == 0)
        strcat(buf, "j");
    MemCpy(a->anim, buf, 9);
    a->state &= ~(ACT_CALLBACK | ACT_WALK | ACT_TALK);
    a->anim_h = CacheLoadEMS(buf, "anm");
    a->nframes = GetFileSize(buf, "anm") / sizeof(AnimFrame);
    a->frame = 0;
    a->ax = x;
    a->ay = y;
    a->loops = 0;
    a->scale = scale;
    f = LockMem(a->anim_h);
    a->next_time = f->delay + blink_count;
    MemCpy(buf, f, 8);
    buf[8] = 0;
    UnlockMem(a->anim_h);
    SpriteSetBitmap(spr, LoadSpriteBitmap(buf, scale));
    strcpy(a->name, buf);
    a->scale = scale;
    f = LockMem(a->anim_h);
    pri = DepthPri(f->y + a->ay) + f->z;
    SpriteSetPos(spr, f->x + a->ax, f->y + a->ay, pri);
    ((StateBits *)a)->hold = f->next[3] == 0xFF;
    UnlockMem(a->anim_h);
    a->notify = 0;
    return n;
}

/* StartAnim for a talking actor (only if it talks, or force). */
int StartTalk(int n, char *name, int x, int y, int scale, int force)
{
    char buf[10];
    Actor *a;
    Actor *p;
    int pri;
    Sprite *spr;
    AnimFrame far *f;

    if (n == -3)
        return 0;
    talk_actor = 0;
    if (n == -2)
        return -2;
    if (!memcmp("NOANIM", name, 7))
        return n;
    if (n == -1) {
        for (n = MAX_ACTORS - 1, p = &actors[MAX_ACTORS - 1]; n >= 9; n--, p--) {
            if (!(p->state & ACT_USED))
                break;
            if (n < 9)
                Fatal("All anims in use.");
        }
    } else
        p = &actors[n];
    talk_actor = p;
    if (n == -1 || n < 0 || n >= MAX_ACTORS)
        return 0;
    a = p;
    if (!(a->flags & 0x80) && !force)
        return n;
    if ((a->state & (ACT_CALLBACK | ACT_WALK)) || a->notify)
        return n;
    if (x == -1)
        x = a->sprite.x;
    if (y == -1)
        y = a->sprite.y;
    if (scale == -1)
        scale = a->flags & 0x20 ? DepthScale(y) : 0x100;
    spr = &a->sprite;
    if (a->state & ACT_USED)
        ReleaseAnim(a);
    else
        AddSprite(spr);
    a->state |= ACT_USED;
    strncpy(buf, name, 9);
    buf[8] = 0;
    if (a->letter && buf[0] == '?')
        buf[0] = a->letter;
    {
        int len;

        len = strlen(buf);
        if (buf[len - 1] == '?') {
            if (a->dir) {
                a->dir2 = a->dir;
                a->dir = 0;
            } else if (!a->dir2)
                a->dir2 = 's';
            buf[len - 1] = a->dir2;
        }
    }
    ((StateBits *)a)->callback = ((StateBits *)a)->walk = 0;
    ((StateBits *)a)->talk = 1;
    ((StateBits *)a)->b7 = 0;
    MemCpy(a->anim, buf, 9);
    a->anim_h = CacheLoadEMS(buf, "anm");
    a->nframes = GetFileSize(buf, "anm") / sizeof(AnimFrame);
    a->frame = 0;
    a->ax = x;
    a->ay = y;
    a->loops = 0;
    a->scale = scale;
    f = LockMem(a->anim_h);
    a->next_time = f->delay + blink_count;
    MemCpy(buf, f, 8);
    buf[8] = 0;
    UnlockMem(a->anim_h);
    SpriteSetBitmap(spr, LoadSpriteBitmap(buf, scale));
    strcpy(a->name, buf);
    a->scale = scale;
    f = LockMem(a->anim_h);
    pri = DepthPri(f->y + a->ay) + f->z;
    SpriteSetPos(spr, f->x + a->ax, f->y + a->ay, pri);
    ((StateBits *)a)->hold = f->next[3] == 0xFF;
    UnlockMem(a->anim_h);
    a->notify = 0;
    return n;
}

#define FIXROUND(v) ((int)(((v) + 0x8000L) >> 16))

/* Walk actor n from (x0, y0) to (x1, y1), by the walk graph if it can't
 * go straight there. */
void WalkActorTo(int n, int x0, int y0, int x1, int y1, int notify)
{
    Actor *a;

    a = &actors[n];
    if (WalkBlocked(x1, y1)) {
        a->state |= ACT_STOPPED;
        return;
    }
    if (x0 == -1)
        x0 = a->sprite.x;
    if (y0 == -1)
        y0 = a->sprite.y;
    if (a->state & ACT_USED)
        ReleaseAnim(a);
    else
        AddSprite(&a->sprite);
    a->state |= ACT_USED | ACT_WALK;
    a->state &= ~(ACT_CALLBACK | ACT_TALK);
    a->next_time = blink_count + 1;
    a->notify = notify;
    a->tx = x1;
    a->ty = y1;
    a->step = 0;
    a->node = a->dest = -1;
    if (x1 == x0 && y1 == y0)
        goto arrived;
    if (CanWalk(x0, y0, x1, y1))
        SetWalk(a, x0, y0, x1, y1);
    else {
        a->node = NearestNode(x0, y0);
        a->dest = NearestNode(x1, y1);
        if (a->node == -1 || a->dest == -1)
            goto arrived;
        SetWalk(a, x0, y0, walk.nodes[a->node].x, walk.nodes[a->node].y);
    }
    SetWalkFrame(a, FIXROUND(a->fx), FIXROUND(a->fy));
    if (n == 0)
        ClickRegion(x1, y1);
    return;
arrived:
    if (notify)
        PostRoomMsg(10, notify, 0, 0);
    a->state |= ACT_STOPPED;
    SetWalkFrame(a, x0, y0);
    EndOrStand(n);
}

/* Run fn on actor n each frame (from the next tick) until it returns
 * nonzero. */
void SetCallback(int n, int (far *fn)(int n), int notify)
{
    Actor *a;

    a = &actors[n];
    if (a->state & ACT_USED) {
        a->state &= ~ACT_WALK;
        a->state |= ACT_CALLBACK;
        a->next_time = blink_count;
        a->notify = notify;
        a->fn = fn;
        a->tick = -1;
        a->count = 0;
    }
}

/* Start one of the effects on actor n. */
void StartEffect(int n, unsigned kind, int notify)
{
    int (far *fns[4])(int n);

    fns[0] = Effect0;
    fns[1] = Effect1;
    fns[2] = Effect2;
    fns[3] = Effect3;
    if (kind <= 3)
        SetCallback(n, fns[kind], notify);
}

/* Step every actor whose time has come. */
void UpdateActors(void)
{
    Actor *a;
    int i;

    for (a = actors, i = 0; i != MAX_ACTORS; a++, i++) {
        if ((a->state & ACT_USED) && a->next_time <= blink_count) {
            if (a->state & ACT_CALLBACK)
                CallbackStep(i);
            else if (a->state & ACT_WALK)
                WalkStep(i);
            else if (a->state & ACT_TALK)
                TalkStep(i);
            else
                AnimStep(i);
        }
    }
}

void CallbackStep(int n)
{
    Actor *a;

    a = &actors[n];
    if (a->count) {
        FreeMem(a->sprite.handle);
        a->count = 0;
        SpriteSetBitmap(&a->sprite, LoadSpriteBitmap(a->name, a->scale));
    }
    a->tick++;
    if (a->fn(n))
        EndOrStand(n);
}

/* A walk ended: tell the room. */
void WalkDone(Actor *a)
{
    a->state |= ACT_STOPPED;
    if (a->notify)
        PostRoomMsg(10, a->notify, 0, 0);
}

/* Give the actor's bitmap a blank border of grow pixels (for the effects to
 * draw into). */
void GrowBitmap(Actor *a, int grow)
{
    Bitmap far *src;
    unsigned size;
    MemHandle h;
    int ems;
    BitmapHdr saved;
    Bitmap far *dst;
    char far *s;
    char far *d;
    int i;

    src = LockMem(a->sprite.handle);
    size = (src->w + grow * 2) * (src->h + grow * 2);
    UnlockMem(a->sprite.handle);
    h = AllocMemAbort(size + 8, 1);
    src = LockMem(a->sprite.handle);
    if (IsEMSHandle(a->sprite.handle) && IsEMSHandle(h)) {
        saved = *(BitmapHdr far *)backbuf;
        *(BitmapHdr far *)backbuf = *(BitmapHdr far *)src;
        MemCpy(backbuf->data, src->data, src->w * src->h);
        UnlockMem(a->sprite.handle);
        src = backbuf;
        ems = 1;
    } else
        ems = 0;
    dst = LockMem(h);
    dst->w = src->w + grow * 2;
    dst->h = src->h + grow * 2;
    dst->x = src->x + grow;
    dst->y = src->y + grow;
    if (grow == 0)
        MemCpy(dst->data, src->data, size);
    else {
        s = src->data;
        d = dst->data;
        for (i = grow; i; i--) {
            MemSet(d, dst->w, 0);
            d += dst->w;
        }
        for (i = src->h; i; i--) {
            MemSet(d, grow, 0);
            MemCpy(d += grow, s, src->w);
            s += src->w;
            MemSet(d += src->w, grow, 0);
            d += grow;
        }
        for (i = grow; i; i--) {
            MemSet(d, dst->w, 0);
            d += dst->w;
        }
    }
    UnlockMem(h);
    if (ems)
        *(BitmapHdr far *)backbuf = saved;
    else
        UnlockMem(a->sprite.handle);
    FreeSpriteBitmap(a->sprite.handle, a->scale);
    SpriteSetBitmap(&a->sprite, h);
    a->count = 1;
}

/* Colour every set pixel of the actor's bitmap. */
void FillColor(Actor *a, unsigned char color)
{
    Bitmap far *b;
    char far *p;
    unsigned n;

    b = LockMem(a->sprite.handle);
    p = b->data;
    n = b->w * b->h;
    _asm {
        push ds
        mov cx, n
        mov ah, color
        lds si, p
    fill:
        lodsb
        or al, al
        je skip
        mov [si-1], ah
    skip:
        loop fill
        pop ds
    }
    UnlockMem(a->sprite.handle);
}

/* Clear the pixels whose low 3 bits are level or more. */
void FadePixels(Actor *a, unsigned char level)
{
    Bitmap far *b;
    char far *p;
    unsigned n;

    b = LockMem(a->sprite.handle);
    p = b->data;
    n = b->w * b->h;
    _asm {
        push ds
        mov cx, n
        mov dl, level
        lds si, p
    next:
        lodsb
        and al, 7
        cmp al, dl
        jb keep
        mov byte ptr [si-1], 0
    keep:
        loop next
        pop ds
    }
    UnlockMem(a->sprite.handle);
}

/* Draw a color outline around the set pixels (working from a copy in
 * backbuf). */
void Outline(Actor *a, unsigned char color)
{
    Bitmap far *b;
    int w;
    char far *src;
    char far *dst;
    unsigned n;

    b = LockMem(a->sprite.handle);
    w = b->w;
    src = b->data;
    dst = backbuf->data;
    n = (b->h - 2) * w - 1;
    MemCpy(dst, src, w * b->h);
    _asm {
        push ds
        mov cx, n
        mov dl, color
        mov si, w
        les di, src
        lds bx, dst
        add di, si
        add bx, si
    pair:
        mov ax, [bx]
        or ax, ax
        jne set
        sub bx, si
        mov ax, [bx]
        add bx, si
        or ax, [bx-1]
        or ax, [bx+1]
        or ax, [bx+si]
        je step2
        or al, al
        je right
        mov es:[di], dl
        or ah, ah
        je step2
    right:
        mov es:[di+1], dl
    step2:
        add bx, 2
        add di, 2
        dec cx
        je done
        loop pair
        jmp done
    set:
        or al, al
        je one
        or ah, ah
        jne step2
        inc bx
        inc di
        dec cx
    one:
        sub bx, si
        mov al, [bx]
        add bx, si
        or al, [bx-1]
        or al, [bx+1]
        or al, [bx+si]
        je step1
        mov es:[di], dl
    step1:
        jcxz done
        inc bx
        inc di
        loop pair
    done:
        pop ds
    }
    UnlockMem(a->sprite.handle);
}

/* The sparkle of the transporter. */
int far Effect0(int n)
{
    Actor *a;

    a = &actors[n];
    switch (a->tick) {
    case 0:
        GrowBitmap(a, 2);
        Outline(a, 0xB8);
        a->next_time = blink_count + 2;
        break;
    case 1:
        GrowBitmap(a, 3);
        Outline(a, 0xB9);
        Outline(a, 0xB8);
        a->next_time = blink_count + 2;
        break;
    case 2:
    case 7:
        GrowBitmap(a, 4);
        Outline(a, 0xBA);
        Outline(a, 0xB9);
        Outline(a, 0xB8);
        a->next_time = blink_count + 2;
        break;
    case 3:
        GrowBitmap(a, 4);
        FillColor(a, 0xBD);
        Outline(a, 0xBA);
        Outline(a, 0xB9);
        Outline(a, 0xB8);
        a->next_time = blink_count + 1;
        break;
    case 4:
        GrowBitmap(a, 4);
        FillColor(a, 0xBC);
        Outline(a, 0xBA);
        Outline(a, 0xB9);
        Outline(a, 0xB8);
        a->next_time = blink_count + 2;
        break;
    case 5:
        GrowBitmap(a, 4);
        FillColor(a, 0xBB);
        Outline(a, 0xBA);
        Outline(a, 0xB9);
        Outline(a, 0xB8);
        a->next_time = blink_count + 3;
        break;
    case 6:
        GrowBitmap(a, 4);
        FillColor(a, 0xBA);
        Outline(a, 0xBA);
        Outline(a, 0xB9);
        Outline(a, 0xB8);
        a->next_time = blink_count + 4;
        break;
    case 8:
        GrowBitmap(a, 3);
        Outline(a, 0xBA);
        Outline(a, 0xB9);
        a->next_time = blink_count + 2;
        break;
    case 9:
        GrowBitmap(a, 2);
        Outline(a, 0xBA);
        a->next_time = blink_count + 2;
        WalkDone(a);
        break;
    case 10:
        return 1;
    }
    return 0;
}

/* Fading out. */
int far Effect1(int n)
{
    Actor *a;

    a = &actors[n];
    switch (a->tick) {
    case 0:
        GrowBitmap(a, 2);
        Outline(a, 0xA1);
        a->next_time = blink_count + 2;
        break;
    case 1:
        GrowBitmap(a, 3);
        Outline(a, 0xA2);
        Outline(a, 0xA1);
        a->next_time = blink_count + 2;
        break;
    case 2:
        GrowBitmap(a, 4);
        Outline(a, 0xA3);
        Outline(a, 0xA2);
        Outline(a, 0xA1);
        a->next_time = blink_count + 2;
        break;
    case 3:
        GrowBitmap(a, 4);
        FillColor(a, 0xA4);
        Outline(a, 0xA3);
        Outline(a, 0xA2);
        Outline(a, 0xA1);
        a->next_time = blink_count + 2;
        break;
    case 4:
    case 5:
    case 6:
    case 7:
    case 8:
    case 9:
    case 10:
        GrowBitmap(a, 4);
        FadePixels(a, 11 - a->tick);
        FillColor(a, 0xA4);
        Outline(a, 0xA3);
        Outline(a, 0xA2);
        Outline(a, 0xA1);
        a->next_time = blink_count + 2;
        break;
    case 11:
        GrowBitmap(a, 3);
        FadePixels(a, 1);
        FillColor(a, 0xA3);
        Outline(a, 0xA2);
        Outline(a, 0xA1);
        a->next_time = blink_count + 1;
        break;
    case 12:
        GrowBitmap(a, 2);
        FadePixels(a, 1);
        FillColor(a, 0xA2);
        Outline(a, 0xA1);
        a->next_time = blink_count + 1;
        break;
    case 13:
        GrowBitmap(a, 0);
        FadePixels(a, 1);
        FillColor(a, 0xA1);
        a->next_time = blink_count + 1;
        WalkDone(a);
        break;
    case 14:
        return 1;
    }
    return 0;
}

/* A pulsing glow (until stopped). */
int far Effect2(int n)
{
    Actor *a;

    a = &actors[n];
    switch (a->tick) {
    case 0:
    case 4:
        a->tick = 0;
        GrowBitmap(a, 2);
        Outline(a, 0x80);
        a->next_time = blink_count + 2;
        break;
    case 1:
    case 3:
        GrowBitmap(a, 3);
        Outline(a, 0x81);
        Outline(a, 0x80);
        a->next_time = blink_count + 2;
        break;
    case 2:
        GrowBitmap(a, 4);
        Outline(a, 0x82);
        Outline(a, 0x81);
        Outline(a, 0x80);
        a->next_time = blink_count + 2;
        break;
    }
    return 0;
}

int far Effect3(int n)
{
    Actor *a;

    a = &actors[n];
    switch (a->tick) {
    case 0:
    case 4:
        a->tick = 0;
        GrowBitmap(a, 2);
        Outline(a, 0x88);
        a->next_time = blink_count + 2;
        break;
    case 1:
    case 3:
        GrowBitmap(a, 3);
        Outline(a, 0x89);
        Outline(a, 0x88);
        a->next_time = blink_count + 2;
        break;
    case 2:
        GrowBitmap(a, 4);
        Outline(a, 0x8A);
        Outline(a, 0x89);
        Outline(a, 0x88);
        a->next_time = blink_count + 2;
        break;
    }
    return 0;
}

/* Show the next frame of actor n's .anm. */
void AnimStep(int n)
{
    char buf[10];
    Actor *a;
    AnimFrame far *frames;
    AnimFrame far *f;
    int next;
    EMSBlock *ems;
    int pri;
    Sprite *spr;

    a = &actors[n];
    f = LockMem(a->anim_h);
    if (a->state & ACT_HOLD) {
        next = f[a->frame].next[0];
        if (next < a->nframes && f[next].next[3] != 0xFF) {
            ems = EMSSave();
            sfx_vol_next = f[next].next[1];
            sfx_pan_next = f[next].next[2];
            if (!DigiStatus())
                BridgeSfx(f[next].next[3]);
            EMSRestore(ems);
        }
    } else
        next = f[a->frame].next[rand() & 3];
    if (a->loops == 0 && a->nframes - next == 1) {
        if (!++a->loops)
            a->loops--;
        a->state |= ACT_STOPPED;
        if (a->notify)
            PostRoomMsg(10, a->notify, 0, 0);
    }
    a->frame = next;
    if (next >= a->nframes) {
        UnlockMem(a->anim_h);
        EndOrStand(n);
        return;
    }
    f += a->frame;
    MemCpy(buf, f, 8);
    buf[8] = 0;
    UnlockMem(a->anim_h);
    spr = &a->sprite;
    FreeSpriteBitmap(spr->handle, a->scale);
    SpriteSetBitmap(spr, LoadSpriteBitmap(buf, a->scale));
    strcpy(a->name, buf);
    frames = LockMem(a->anim_h);
    f = frames + a->frame;
    pri = DepthPri(f->y + a->ay) + f->z;
    SpriteSetPos(spr, f->x + a->ax, f->y + a->ay, pri);
    a->next_time = f->delay + blink_count;
    UnlockMem(a->anim_h);
}

/* A talking actor's frame: its mouth moves while its voice plays. */
void TalkStep(int n)
{
    char buf[10];
    Actor *a;
    AnimFrame far *frames;
    AnimFrame far *f;
    Sprite *spr;
    int st;
    int next;
    int pri;

    a = &actors[n];
    f = frames = LockMem(a->anim_h);
    spr = &a->sprite;
    st = DigiStatus();
    next = frames[a->frame].next[0];
    if (st && st != 2 && a == talk_actor)
        a->frame = next;
    else
        a->frame = 0;
    if ((!st || a != talk_actor) && (a->state & 8) && a->letter == a->anim[0]) {
        UnlockMem(a->anim_h);
        a->state &= ~ACT_TALK;
        a->state |= ACT_STOPPED;
        EndOrStand(n);
        return;
    }
    f += a->frame;
    MemCpy(buf, f, 8);
    buf[8] = 0;
    UnlockMem(a->anim_h);
    FreeSpriteBitmap(spr->handle, a->scale);
    SpriteSetBitmap(spr, LoadSpriteBitmap(buf, a->scale));
    strcpy(a->name, buf);
    frames = LockMem(a->anim_h);
    f = frames + a->frame;
    pri = DepthPri(f->y + a->ay) + f->z;
    SpriteSetPos(spr, f->x + a->ax, f->y + a->ay, pri);
    a->next_time = f->delay + blink_count;
    UnlockMem(a->anim_h);
}

/* Take actor n a step (two when it's near the camera) along its walk. */
void WalkStep(int n)
{
    Actor *a;
    Sprite *spr;
    int i;
    int speed;
    long nx;
    long ny;

    a = &actors[n];
    spr = &a->sprite;
    if (n == 0)
        CheckRegions(a->sprite.x, a->sprite.y, a->tx, a->ty);
    if (a->steps) {
        if (DepthScale(FIXROUND(a->fy)) < 0xA0)
            speed = 1;
        else
            speed = 2;
        for (i = 0; i != speed && a->steps; i++) {
            a->steps--;
            nx = a->fx + a->dx;
            ny = a->fy + a->dy;
            if (!(a->steps & 3)) {
                FreeSpriteBitmap(spr->handle, a->scale);
                SetWalkFrame(a, FIXROUND(nx), FIXROUND(ny));
                a->step++;
            }
            a->fx = nx;
            a->fy = ny;
            a->next_time = blink_count;
        }
        return;
    }
    if (a->node == -1) {
        if (a->notify)
            PostRoomMsg(10, a->notify, 0, 0);
        a->state |= ACT_STOPPED;
        FreeSpriteBitmap(spr->handle, a->scale);
        SetWalkFrame(a, FIXROUND(a->fx), FIXROUND(a->fy));
        EndOrStand(n);
        return;
    }
    if (a->node == a->dest) {
        a->node = a->dest = -1;
        SetWalk(a, a->sprite.x, a->sprite.y, a->tx, a->ty);
    } else {
        a->node = walk.next[a->node][a->dest];
        SetWalk(a, a->sprite.x, a->sprite.y, walk.nodes[a->node].x, walk.nodes[a->node].y);
    }
}

/* Show the walk frame for (x, y). */
void SetWalkFrame(Actor *a, int x, int y)
{
    char buf[10];
    int dir;
    Sprite *spr;

    a->scale = DepthScale(y);
    dir = a->dir2 ? a->dir2 : 's';
    sprintf(buf, "%cwalk%c%02d", a->letter, dir, a->step & 7);
    SpriteSetBitmap(spr = &a->sprite, LoadSpriteBitmap(buf, a->scale));
    strcpy(a->name, buf);
    SpriteSetPos(spr, x, y, DepthPri(y));
    a->next_time = blink_count;
}

/* Set up a straight walk, along the longer axis one pixel per step. */
void SetWalk(Actor *a, int x0, int y0, int x1, int y1)
{
    int dx;
    int dy;

    a->fx = (long)x0 << 16;
    a->fy = (long)y0 << 16;
    dx = x1 - x0;
    dy = y1 - y0;
    if (abs(dx) > abs(dy)) {
        if (dx > 0)
            a->dir2 = 'e';
        else
            a->dir2 = 'w';
        if ((a->steps = abs(dx)) == 0)
            return;
        a->dx = (long)SGN(dx) << 16;
        a->dy = ((long)dy << 16) / abs(dx);
    } else {
        if (dy > 0)
            a->dir2 = 's';
        else
            a->dir2 = 'n';
        if ((a->steps = abs(dy)) == 0)
            return;
        a->dx = ((long)dx << 16) / abs(dy);
        a->dy = (long)SGN(dy) << 16;
    }
}

/* Is the straight line from (x0, y0) to (x1, y1) clear? */
int CanWalk(int x0, int y0, int x1, int y1)
{
    int dx;
    int dy;
    long sx;
    long sy;
    long x;
    long y;
    int n;

    dx = x1 - x0;
    dy = y1 - y0;
    if (abs(dx) > abs(dy)) {
        if ((n = abs(dx)) == 0)
            return 1;
        sy = ((long)dy << 16) / abs(dx);
        sx = (long)SGN(dx) << 16;
    } else {
        if ((n = abs(dy)) == 0)
            return 1;
        sx = ((long)dx << 16) / abs(dy);
        sy = (long)SGN(dy) << 16;
    }
    if (WalkBlocked(FIXROUND(x = (long)x0 << 16), FIXROUND(y = (long)y0 << 16)))
        return 0;
    while (n--)
        if (WalkBlocked(FIXROUND(x += sx), FIXROUND(y += sy)))
            return 0;
    return 1;
}

/* The nearest walk graph node that (x, y) can walk straight to, or -1. */
int NearestNode(int x, int y)
{
    int i;
    NodeDist *list;
    NodeDist *p;
    WalkNode *n;

    p = list = AllocMemPtr(walk.count * sizeof(NodeDist));
    n = walk.nodes;
    for (i = 0; i != walk.count; ++i, ++n, ++p) {
        p->idx = i;
        p->dist = FixLength(x - n->x, y - n->y, 0);
    }
    qsort(list, walk.count, sizeof(NodeDist), CompareDist);
    for (p = list, i = 0; i != walk.count; ++i, ++p)
        if (CanWalk(x, y, walk.nodes[p->idx].x, walk.nodes[p->idx].y)) {
            i = p->idx;
            FreeMemPtr(list);
            return i;
        }
    FreeMemPtr(list);
    return -1;
}

int CompareDist(NodeDist *a, NodeDist *b)
{
    return a->dist - b->dist;
}

/* Load the room's walk graph from name.iw: node count, nodes, then for
 * each node the next node towards every other. Walks under way start
 * again. */
#define READ(dst, n)    (MemCpy(dst, p, n), p += (n))

void LoadWalkGraph(char *name)
{
    int i;
    char buf[0x482];
    char *p;
    Actor *a;

    MemSet(&walk, sizeof(walk), 0xFF);
    LoadFilePacked(name, "iw", (unsigned char far *)buf);
    p = buf;
    READ(&walk.count, 2);
    READ(walk.nodes, sizeof(walk.nodes));
    for (i = 0; i != walk.count; i++)
        READ(walk.next[i], walk.count);
    for (i = 0, a = actors; i != MAX_ACTORS; i++, a++)
        if ((a->state & ACT_USED) && (a->state & ACT_WALK))
            WalkActorTo(i, -1, -1, a->tx, a->ty, a->notify);
}

/* Stunned actors get up when their time is up. */
void StunTick(void)
{
    Actor *a;
    int i;

    for (i = 0, a = actors; i != MAX_ACTORS; i++, a++)
        if (a->busy && --a->busy == 0) {
            a->flags &= ~2;
            StartAnim(i, "?getu?", -1, -1, -1);
        }
}

/* An animation ended: crew members stand, the rest go. */
void EndOrStand(int n)
{
    Actor *a;
    Sprite *spr;

    a = &actors[n];
    if (a->state & ACT_STAND) {
        StartAnim(n, "?stnd?", -1, -1, -1);
        return;
    }
    if (a->state & ACT_USED) {
        spr = &a->sprite;
        SpriteErase(spr);
        UpdateSprites();
        DelSprite(spr);
        ReleaseAnim(a);
    }
}

void FreeActors(void)
{
    int i;
    int j;

    for (i = 0; i != MAX_ACTORS; i++)
        if (actors[i].state & ACT_USED) {
            actors[i].state &= ~ACT_STAND;
            EndOrStand(i);
            if (actors[i].flags & 8)
                actors[i].state |= ACT_STAND;
        }
    for (j = 0; j != 16; j++)
        if (bans[j].h) {
            CacheRelease(bans[j].h);
            bans[j].h = 0;
        }
}

void ReleaseAnim(Actor *a)
{
    if ((a->state & ACT_CALLBACK) && a->count)
        FreeMem(a->sprite.handle);
    else
        FreeSpriteBitmap(a->sprite.handle, a->scale);
    if (!(a->state & (ACT_CALLBACK | ACT_WALK)))
        CacheRelease(a->anim_h);
    a->state &= ~ACT_USED;
}

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

