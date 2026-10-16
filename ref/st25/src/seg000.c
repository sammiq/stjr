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

void SaveActors(void)
{
    SaveWrite(actors, sizeof(actors));
}

void LoadActors(void)
{
    int i;
    Actor *a;
    Sprite *s;

    SaveRead(actors, sizeof(actors));
    for (a = actors, i = 0; i != MAX_ACTORS; ++i, ++a) {
        if (a->state) {
            if (a->type != ANIM_WALK)
                a->anim = CacheLoad(a->name, "anm");
            s = &a->sprite;
            AddSprite(s);
            SpriteSetBitmap(s, LoadSpriteBitmap(a->bitmap, a->scale));
        }
    }
}

void InitActors(void)
{
    MemSet(actors, sizeof(actors), 0);
    MemSet(bans, sizeof(bans), 0);
    strcpy(actors[0].stand, "kstnd");
    strcpy(actors[1].stand, "sstnd");
    strcpy(actors[2].stand, "mstnd");
    strcpy(actors[3].stand, "rstnd");
}

/* Play name.anm as actor n, or the first free one from 8 for -1.
 * Returns the actor. */
int StartAnim(int n, char *name, int x, int y, int scale)
{
    Actor *a;

    if (n == -1) {
        for (n = 8, a = &actors[8]; a != actors + MAX_ACTORS; ++n, ++a)
            if (a->state == 0)
                break;
        if (n == MAX_ACTORS)
            Fatal("All anims in use.");
    } else
        a = &actors[n];
    if (a->state) {
        release_anim(a);
        InitAnim(a, name, x, y, scale, 0);
    } else
        InitAnim(a, name, x, y, scale, 1);
    a->notify = 0;
    a->notify_arg = 0;
    return n;
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

/* Walk actor n from (x, y) to (dx, dy), straight or by the walk graph.
 * Returns 0 if it can't. */
int StartWalk(int n, char *name, int x, int y, int dx, int dy)
{
    Actor *a;
    int unused[2];

    a = &actors[n];
    a->notify = 0;
    if (WalkBlocked(dx, dy))
        return 0;
    if (a->state)
        release_anim(a);
    else
        AddSprite(&a->sprite);
    a->state = 1;
    a->type = ANIM_WALK;
    a->next_time = blink_count + 1;
    strcpy(a->walk_name, name);
    a->dest_x = dx;
    a->dest_y = dy;
    a->step = 0;
    a->notify = 0;
    a->walk_node = a->dest_node = -1;
    if (CanWalk(x, y, dx, dy)) {
        SetWalk(a, x, y, dx, dy);
        SetWalkFrame(a, (a->fx + 0x8000) >> 16, (a->fy + 0x8000) >> 16);
    } else {
        a->walk_node = NearestNode(x, y);
        a->dest_node = NearestNode(dx, dy);
        if (a->walk_node == -1 || a->dest_node == -1) {
            strcat(a->walk_name, "S");
            a->dir = 'S';
            SetWalkFrame(a, x, y);
            init_stand_anim(n);
            return 0;
        }
        SetWalk(a, x, y, walk.nodes[a->walk_node].x, walk.nodes[a->walk_node].y);
        SetWalkFrame(a, (a->fx + 0x8000) >> 16, (a->fy + 0x8000) >> 16);
    }
    return 1;
}

void UpdateActors(void)
{
    int i;
    Actor *a;

    for (a = actors, i = 0; i != MAX_ACTORS; ++i, ++a) {
        if (a->state) {
            switch (a->type) {
            case ANIM_STAND:
            case ANIM_PLAY:
                AnimStep(i);
                break;
            case ANIM_WALK:
                WalkStep(i);
                break;
            default:
                Fatal("invalid anim type.");
            }
        }
    }
}

/* Show the next frame of actor n's animation when it is due. */
void AnimStep(int n)
{
    Actor *a;
    AnimFrame far *data;
    AnimFrame far *f;
    int next;

    a = &actors[n];
    if (blink_count >= a->next_time) {
        data = LockMem(a->anim);
        f = data;
        next = f[a->frame].next[rand() & 3];
        if (a->frame != next && next == a->nframes - 1) {
            a->loops++;
            if (a->notify)
                PostRoomMsg(10, a->notify_arg, 0, 0);
        }
        a->frame = next;
        if (a->frame >= a->nframes) {
            UnlockMem(a->anim);
            if (a->stand[0] == 0)
                EndAnim(n);
            else
                init_stand_anim(n);
            return;
        }
        {
            char name[16];
            int z;
            Sprite *s;

            s = &a->sprite;
            f += a->frame;
            MemCpy(name, f, 16);
            UnlockMem(a->anim);
            FreeSpriteBitmap(s->handle, a->scale);
            SpriteSetBitmap(s, LoadSpriteBitmap(name, a->scale));
            strncpy(a->bitmap, name, 9);
            a->bitmap[9] = 0;
            data = LockMem(a->anim);
            f = data;
            f += a->frame;
            z = DepthPri(a->y + f->y) + f->z;
            SpriteSetPos(s, a->x + f->x, a->y + f->y, z);
            a->next_time = f->delay + blink_count;
            UnlockMem(a->anim);
        }
    }
}

/* Move a walking actor one or two steps (further away is slower), and
 * on to the next walk graph node at the end of each leg. */
void WalkStep(int n)
{
    Actor *a;
    Sprite *s;
    char unused1[16];
    long nx;
    long ny;
    char unused2[10];

    a = &actors[n];
    if (blink_count >= a->next_time) {
        s = &a->sprite;
        if (n == 0)
            CheckRegions(actors[0].x, actors[0].y);
        if (a->steps) {
            int i;
            int k;

            if (DepthScale((a->fy + 0x8000) >> 16) < 160)
                k = 1;
            else
                k = 2;
            for (i = 0; i != k && a->steps; ++i) {
                a->steps--;
                nx = a->fx + a->dx;
                ny = a->fy + a->dy;
                if ((a->steps & 3) == 0) {
                    FreeSpriteBitmap(s->handle, a->scale);
                    SetWalkFrame(a, (nx + 0x8000) >> 16, (ny + 0x8000) >> 16);
                    a->step++;
                }
                a->fx = nx;
                a->fy = ny;
                a->next_time = blink_count;
            }
        } else if (a->walk_node == -1) {
            if (a->notify) {
                a->notify = 0;
                PostRoomMsg(12, a->notify_arg & 0xFF, 0, 0);
            }
            FreeSpriteBitmap(s->handle, a->scale);
            SetWalkFrame(a, (a->fx + 0x8000) >> 16, (a->fy + 0x8000) >> 16);
            init_stand_anim(n);
        } else if (a->walk_node == a->dest_node) {
            a->walk_name[strlen(a->walk_name) - 1] = 0;
            a->walk_node = a->dest_node = -1;
            SetWalk(a, a->x, a->y, a->dest_x, a->dest_y);
        } else {
            a->walk_node = walk.next[a->walk_node][a->dest_node];
            a->walk_name[strlen(a->walk_name) - 1] = 0;
            SetWalk(a, a->x, a->y, walk.nodes[a->walk_node].x, walk.nodes[a->walk_node].y);
        }
    }
}

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
}

/* Update the screen where each .ban changed the back buffer. */
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

/* EGA: copy the changed runs of from (packed pixels) to the planes. */
char far *BanEGA(char far *dst, char far *src, char far *from)
{
    _asm {
        push ds
        push si
        push di
        push bp
        mov dx, 3CEh
        mov ax, 0FF08h
        out dx, ax
        mov dx, 3C4h
        mov al, 2
        out dx, al
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
    g_next:
        dec dx
        js g_end
        mov al, [bx]
        inc bx
        or al, al
        jns g_lit
        cmp al, 80h
        je g_jump
        mov cl, al
        neg cl
        inc cx
        mov al, [bx]
        inc bx
        or al, al
        jne g_copy
        add di, cx
        jmp g_next
    g_end:
        jmp g_done
    g_jump:
        add di, [bx]
        add bx, 2
        jmp g_next
    g_lit:
        mov cl, al
        inc cx
        add bx, cx
    g_copy:
        mov si, di
        and si, 0FFFCh
        add di, cx
        push ds
        mov ds, bp
        push di
        add di, 3
        and di, 0FFFCh
        sub di, si
        shr di, 2
        mov cx, di
        mov di, si
        add si, 8
        shr di, 2
        push bx
        lea bx, pal_remap
        push dx
        mov dx, 3C5h
    g_loop:
        push cx
        lodsw
        _emit 36h
        xlat [bx]
        xchg al, ah
        _emit 36h
        xlat [bx]
        mov cx, ax
        mov al, 1
        out dx, al
        lodsw
        _emit 36h
        xlat [bx]
        xchg al, ah
        _emit 36h
        xlat [bx]
        xchg cl, ah
        ror cx, 4
        rol cl, 4
        rol cx, 4
        ror ax, 4
        rol al, 4
        rol ax, 2
        mov dx, cx
        xor dx, ax
        and dx, 3333h
        xor cx, dx
        xor ax, dx
        rol ax, 2
        mov dx, 3C5h
        mov es:[di], al
        mov al, 2
        out dx, al
        mov es:[di], cl
        mov al, 4
        out dx, al
        mov es:[di], ah
        mov al, 8
        out dx, al
        mov es:[di], ch
        inc di
        pop cx
        loop g_loop
        pop dx
        pop bx
        pop di
        pop ds
        jmp g_next
    g_done:
        pop bp
        mov word ptr src, bx
        pop di
        pop si
        pop ds
    }
    return src;
}

/* Tandy: copy the changed runs of from through pal_remap. */
char far *BanTandy(char far *dst, char far *src, char far *from)
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
    t_next:
        dec dx
        js t_done
        mov al, [bx]
        inc bx
        or al, al
        js t_neg
        mov cl, al
        inc cx
        add bx, cx
    t_copy:
        push ds
        mov ds, bp
        mov si, di
        add si, 8
        push bx
        lea bx, pal_remap
    t_loop:
        lodsb
        _emit 36h
        xlat [bx]
        stosb
        loop t_loop
        pop bx
        pop ds
        jmp t_next
    t_neg:
        cmp al, 80h
        je t_jump
        mov cl, al
        neg cl
        inc cx
        mov al, [bx]
        inc bx
        or al, al
        jne t_copy
        add di, cx
        jmp t_next
    t_jump:
        add di, [bx]
        add bx, 2
        jmp t_next
    t_done:
        pop bp
        mov word ptr src, bx
        pop di
        pop si
        pop ds
    }
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

void EndOrStand(int n)
{
    Actor *a;

    a = &actors[n];
    if (a->stand[0] == 0)
        EndAnim(n);
    else
        init_stand_anim(n);
}

void EndAnim(int n)
{
    Actor *a;

    a = &actors[n];
    if (a->state != 1)
        return;
    SpriteErase(&a->sprite);
    UpdateSprites();
    DelSprite(&a->sprite);
    release_anim(a);
}

void FreeActors(void)
{
    int i;

    for (i = 0; i != MAX_ACTORS; i++)
        if (actors[i].state == 1)
            EndAnim(i);
    for (i = 0; i != 16; i++)
        if (bans[i].h) {
            CacheRelease(bans[i].h);
            bans[i].h = 0;
        }
}

/* Start name.anm on actor a. Standing animations come from the "j" set
 * when there is no second EMS page. */
void InitAnim(Actor *a, char *name, int x, int y, int scale, int add)
{
    char fname[10];
    AnimFrame far *data;
    AnimFrame far *f;
    Sprite *s;
    int z;

    if (strnicmp(name + 1, "stnd", 4) == 0) {
        if (ems_other_page == -1)
            sprintf(fname, "%sj", name);
        else
            strcpy(fname, name);
    } else
        strcpy(fname, name);
    MemCpy(a->name, fname, 16);
    a->type = ANIM_PLAY;
    a->anim = CacheLoad(fname, "anm");
    a->nframes = GetFileSize(fname, "anm") / sizeof(AnimFrame);
    a->frame = 0;
    a->x = x;
    a->y = y;
    a->loops = 0;
    a->scale = scale;
    data = LockMem(a->anim);
    f = data;
    a->next_time = f->delay + blink_count;
    MemCpy(fname, f, 10);
    UnlockMem(a->anim);
    s = &a->sprite;
    if (add)
        AddSprite(s);
    SpriteSetBitmap(s, LoadSpriteBitmap(fname, scale));
    strncpy(a->bitmap, fname, 9);
    a->bitmap[9] = 0;
    a->scale = scale;
    data = LockMem(a->anim);
    f = data;
    z = DepthPri(a->y + f->y) + f->z;
    SpriteSetPos(s, a->x + f->x, a->y + f->y, z);
    UnlockMem(a->anim);
    a->state = 1;
}

void release_anim(Actor *a)
{
    switch (a->type) {
    case ANIM_STAND:
    case ANIM_PLAY:
        FreeAnim(a);
        break;
    case ANIM_WALK:
        FreeWalk(a);
        break;
    default:
        Fatal("release_anim:invalid anim type.");
    }
    a->state = 0;
}

void FreeAnim(Actor *a)
{
    FreeSpriteBitmap(a->sprite.handle, a->scale);
    CacheRelease(a->anim);
    a->anim = 0;
}

void FreeWalk(Actor *a)
{
    FreeSpriteBitmap(a->sprite.handle, a->scale);
}

/* Make actor n stand, facing the way it last walked. */
void init_stand_anim(int n)
{
    Actor *a;
    char name[16];

    a = &actors[n];
    if (a->state == 0)
        Fatal("init_stand_anim: dead anim");
    StandUp(a, n);
    if (a->dir)
        sprintf(name, "%s%c", a->stand, a->dir);
    else
        sprintf(name, "%ss", a->stand);
    StartAnim(n, name, a->x, a->y, DepthScale(a->y));
    a->type = ANIM_STAND;
}

/* Show the walking actor's next frame at (x, y). */
void SetWalkFrame(Actor *a, int x, int y)
{
    char name[16];

    a->scale = DepthScale(y);
    sprintf(name, "%s%02d", a->walk_name, a->step & 7);
    SpriteSetBitmap(&a->sprite, LoadSpriteBitmap(name, a->scale));
    strncpy(a->bitmap, name, 9);
    a->bitmap[9] = 0;
    SpriteSetPos(&a->sprite, x, y, DepthPri(y));
    a->next_time = blink_count;
    a->x = x;
    a->y = y;
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
    if (ABS(dx) > ABS(dy)) {
        if (dx > 0)
            strcat(a->walk_name, "E"), a->dir = 'E';
        else
            strcat(a->walk_name, "W"), a->dir = 'W';
        if ((a->steps = ABS(dx)) == 0)
            return;
        a->dx = (long)SGN(dx) << 16;
        a->dy = ((long)dy << 16) / ABS(dx);
    } else {
        if (dy > 0)
            strcat(a->walk_name, "S"), a->dir = 'S';
        else
            strcat(a->walk_name, "N"), a->dir = 'N';
        if ((a->steps = ABS(dy)) == 0)
            return;
        a->dx = ((long)dx << 16) / ABS(dy);
        a->dy = (long)SGN(dy) << 16;
    }
}

/* Is the straight line from (x0, y0) to (x1, y1) clear? */
int CanWalk(int x0, int y0, int x1, int y1)
{
    long dx;
    long dy;
    long x;
    long y;
    int n;

    dx = x1 - x0;
    dy = y1 - y0;
    if (ABS(dx) > ABS(dy)) {
        if ((n = ABS(dx)) == 0)
            return 1;
        dy = (dy << 16) / ABS(dx);
        dx = (long)SGN(dx) << 16;
    } else {
        if ((n = ABS(dy)) == 0)
            return 1;
        dx = (dx << 16) / ABS(dy);
        dy = (long)SGN(dy) << 16;
    }
    x = (long)x0 << 16;
    y = (long)y0 << 16;
    if (WalkBlocked((x + 0x8000) >> 16, (y + 0x8000) >> 16))
        return 0;
    while (n--) {
        x += dx;
        y += dy;
        if (WalkBlocked((x + 0x8000) >> 16, (y + 0x8000) >> 16))
            return 0;
    }
    return 1;
}

/* Load the room's walk graph from name.iw: node count, nodes, then for
 * each node the next node towards every other. */
#define READ(dst, n)    (MemCpy(dst, p, n), p += (n))

void LoadWalkGraph(char *name)
{
    int i;
    char buf[0x482];
    char *p;

    MemSet(&walk, sizeof(walk), 0xFF);
    LoadFilePacked(name, "iw", (unsigned char far *)buf);
    p = buf;
    READ(&walk.count, 2);
    READ(walk.nodes, sizeof(walk.nodes));
    for (i = 0; i != (int)walk.count; i++) {
        READ(walk.next[i], walk.count);
    }
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
    Fatal("impossible walk");
}

int CompareDist(NodeDist *a, NodeDist *b)
{
    return a->dist - b->dist;
}
