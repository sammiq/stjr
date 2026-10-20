/* demo: cutscenes (new in the sequel) - .dem scripts that show .lbm
 * pictures, play DPaint .anm animations and Interplay .mve movies, with
 * music, sounds and palette fades */

#include <stdio.h>
#include <string.h>
#include <dos.h>
#include <io.h>
#include "mem.h"
#include "bitmap.h"
#include "cache.h"
#include "resource.h"
#include "event.h"
#include "gfx.h"
#include "sound.h"
#include "ems.h"

void Fatal(char *fmt, ...);             /* fatal error */
void GetPalette(unsigned char far *pal);        /* seg007 */
int PlayDigiSfx(char *name, int vol, int pan, int loop);   /* seg015 */
void BridgeSfx(int n);                  /* seg001 */

/* The MVE player (c2D688) */
void sub_30586(void far *(far *alloc)(unsigned), void (far *free)(void far *));
void sub_307B0(int (far *read)(int, void far *, unsigned));
void sub_330B6(int (far *poll)(void));
void sub_30908(int handle);
void sub_3091A(void far *buf, int a, int b, unsigned size);
void sub_3310C(int fd, int a, int b, int c);
void sub_334CA(void);

/* The IFF reader (c2B980) */
int IffType(int fd);
int IffBmhd(void *bmhd, int fd);
int IffCmap(int fd, unsigned char *pal, int n);
int IffBody(int fd);
int IffRows(int type, void *bmhd, char *row, int a, int fd);
void PlayDelta(char far *delta, char far *dst);

/* AIL timers (c2D688) */
int sub_2F377(void (far *fn)(void));
void sub_2F58A(int timer, long freq);
void sub_2F4A9(int timer);
void sub_2F442(int timer);

extern int digi_handle;
extern int menu_busy;
extern Bitmap far *backbuf;
extern char cd_path[];

/* A block of an MVE heap: the movie player's memory. */
typedef struct Block {
    struct Block far *next;     /* 00 */
    unsigned size;              /* 04 */
    int free;                   /* 06 */
} Block;

/* A .dem script command. */
typedef struct DemCmd {
    int frame;                  /* 00 the animation frame it waits for */
    int op;                     /* 02 */
    int a;                      /* 04 */
    int b;                      /* 06 */
    char name[8];               /* 08 padded with spaces */
} DemCmd;

typedef struct Name8 {
    char c[8];
} Name8;

/* A DPaint animation's header. */
typedef struct DpHeader {
    long id;                    /* 00 "LPF " */
    unsigned max_lps;           /* 04 */
    unsigned nlps;              /* 06 large pages */
    long nrecords;              /* 08 */
    unsigned max_recs;          /* 0C */
    unsigned table_off;         /* 0E */
    long content;               /* 10 */
    unsigned width;             /* 14 */
    unsigned height;            /* 16 */
    unsigned char variant;      /* 18 */
    unsigned char version;      /* 19 */
    unsigned char has_last_delta;   /* 1A */
    unsigned char last_delta_ok;    /* 1B */
    unsigned char pixel_type;   /* 1C */
    unsigned char compression;  /* 1D */
    unsigned char other_recs;   /* 1E */
    unsigned char bitmap_type;  /* 1F */
    char record_types[32];      /* 20 */
    long nframes;               /* 40 */
    unsigned fps;               /* 44 */
    char unk46[0x3A];           /* 46 */
} DpHeader;

/* A large page's descriptor. */
typedef struct LpDesc {
    unsigned base;              /* 00 first record */
    unsigned count;             /* 02 records */
    unsigned bytes;             /* 04 */
} LpDesc;

Block far *mve_heap0;
Block far *mve_heap1;
int fade_cur;                           /* percent */
int fade_target;
unsigned long fade_time;                /* tick of the last step */
int fade_speed;                         /* percent per tick, 0: at once */
unsigned dem_ticks;
unsigned anim_ticks;
int anim_timer;
int lp_cur;
int anim_fd;
LpDesc lp_hdr;
DpHeader dp_header;
DemCmd *dem_buf;
char far *anim_buf;
DemCmd *dem_pc;
LpDesc *lp_table;

int mve_frame = 0;
int in_title = 0;                       /* playing the title cutscene */

int far MvePoll(void);
void far *far MveAlloc(unsigned size);
void far MveFree(void far *p);
int far MveRead(int fd, void far *buf, unsigned n);
void FadeOutStart(void);
int DemTick(int frame);
int OpenRes(char *name, char *ext);
void CheckErr(int err, char *msg);
void PlayDpAnim(char *name);

/* Play the movie name, using heap0 and heap1 (64000 bytes each) for the
 * player's memory. */
void PlayMovie(char *name, Block far *heap0, Block far *heap1)
{
    int fd;
    MemHandle h;

    MemSet((void far *)0xA0000000, 64000, 0);
    mve_heap1 = heap1;
    (mve_heap0 = heap0)->next = 0;
    mve_heap1->next = mve_heap0->next;
    mve_heap0->size = 64000;
    mve_heap1->size = mve_heap0->size;
    mve_heap0->free = 1;
    mve_heap1->free = mve_heap0->free;
    if (_dos_open(name, 0x8000, &fd))
        Fatal("%s : not found.", name);
    sub_30586(MveAlloc, MveFree);
    sub_307B0(MveRead);
    sub_330B6(MvePoll);
    mve_frame = 0;
    menu_busy = 1;
    if (in_title) {
        sub_30908(digi_handle);
        sub_3091A(LockMem(h = AllocMemAbort(0x817E, 0)), 0, 0, 0x817E);
        sub_3310C(fd, -1, -1, 0);
        sub_334CA();
        UnlockMem(h);
        FreeMem(h);
    } else {
        sub_30908(-1);
        sub_3310C(fd, -1, -1, 0);
        sub_334CA();
    }
    menu_busy = 0;
    _dos_close(fd);
    GetPalette(cur_palette);
    FadeOutStart();
}

/* Called by the player each frame: 0 to stop. */
int far MvePoll(void)
{
    EMSBlock *e;
    int r;

    mve_frame++;
    e = EMSSave();
    r = DemTick(mve_frame);
    EMSRestore(e);
    return r != 0;
}

void far *far MveAlloc(unsigned size)
{
    int i;
    unsigned s;
    Block far *b;
    Block far *n;

    if (size > 48000)
        Fatal("mveAlloc: asked for too much mem.");
    size = ((size + 15) & 0xFFF0) + 16;
    for (i = 0; i != 2; i++)
        for (b = i == 0 ? mve_heap0 : mve_heap1; b; b = b->next)
            if (b->free && b->size >= size)
                goto found;
    Fatal("mveAlloc: no free mem.\n");
    return 0;
found:
    s = size - 8;
    n = (Block far *)((char far *)b + s);
    n->next = b->next;
    n->size = b->size - s;
    n->free = 1;
    b->next = n;
    b->size = s;
    b->free = 0;
    return (char far *)b + 8;
}

void far MveFree(void far *p)
{
    int i;
    Block far *b;
    Block far *prev;

    for (i = 0; i != 2; i++) {
        prev = 0;
        for (b = i == 0 ? mve_heap0 : mve_heap1; b; prev = b, b = b->next)
            if ((char far *)b + 8 == p)
                goto found;
    }
    Fatal("mveFree: bad mem ptr.");
    return;
found:
    b->free = 1;
    if (b->next->free) {
        b->size += b->next->size;
        b->next = b->next->next;
    }
    if (prev && prev->free) {
        prev->size += b->size;
        prev->next = b->next;
    }
}

int far MveRead(int fd, void far *buf, unsigned n)
{
    unsigned got;

    if (_dos_read(fd, buf, n, &got) == 0 && got == n)
        return 1;
    return 0;
}

/* Show cur_palette at level percent (-1: the current level again). */
void SetFadeLevel(int level)
{
    unsigned char pal[768];
    int i;
    unsigned k;

    if (level == -1)
        level = fade_cur;
    else if (fade_cur == level)
        return;
    fade_cur = level;
    level <<= 8;
    k = (unsigned)level / 100;
    for (i = 0; i < 768; i++)
        pal[i] = (cur_palette[i] * k) >> 8;
    SetPalette(pal);
}

void FadeInStart(void)
{
    fade_target = 100;
    fade_time = GetTicks();
}

void FadeOutStart(void)
{
    if (fade_speed) {
        fade_target = 0;
        fade_time = GetTicks();
    }
}

/* A step of the fade, once a tick. */
void FadeStep(void)
{
    int step;
    unsigned v;

    step = fade_speed ? fade_speed : 100;
    if (fade_target != fade_cur && GetTicks() != fade_time) {
        if (fade_target <= fade_cur)
            v = fade_cur - step;
        else {
            v = step + fade_cur;
            v = v < 100 ? v : 100;
        }
        SetFadeLevel(v);
        fade_time++;
    }
}

int Fading(void)
{
    if (fade_target != fade_cur)
        return 1;
    return 0;
}

char far *vga_ptr = (char far *)0xA0000000;
static char lbm_ext[] = "lbm";

/* Load the 320x200 picture name.lbm into dst, and its palette. */
void LoadLbm(char *name, char far *dst)
{
    char row[320];
    char bmhd[20];
    int type;
    int fd;
    int i;
    int y;

    CheckErr(type = IffType(fd = OpenRes(name, lbm_ext)), "Not a DPaint picture");
    if (type != 0 && type != 1)
        CheckErr(-1, "Not a PBM or ILBM file");
    CheckErr(IffBmhd(bmhd, fd), "Bad BMHD");
    CheckErr(IffCmap(fd, cur_palette, 256), "No color map");
    for (i = 0; i < 768; i++)
        cur_palette[i] >>= 2;
    SetFadeLevel(0);
    CheckErr(IffBody(fd), "No BODY");
    for (y = 200; y; y--, dst += 320) {
        CheckErr(IffRows(type, bmhd, row, 1, fd), "Bad Body");
        MemCpy(dst, row, 320);
        MusicTick();
    }
    _close(fd);
}

/* Open name.ext in the game's directory. */
int OpenRes(char *name, char *ext)
{
    char path[64];

    sprintf(path, "%s%s%s.%s", cd_path, uncomp_dir, name, ext);
    return OpenFile(path);
}

void CheckErr(int err, char *msg)
{
    if (err < 0)
        Fatal("Error %d: %s\n", err, msg);
}

void far DemTimer(void)
{
    dem_ticks++;
}

/* Show the picture name for ticks, fading it in and out. */
void ShowLbm(char *name, unsigned ticks)
{
    int t;

    LoadLbm(name, vga_ptr);
    FadeInStart();
    while (fade_cur != 100)
        DemTick(1);
    dem_ticks = 0;
    sub_2F58A(t = sub_2F377(DemTimer), 1L);
    sub_2F4A9(t);
    while (dem_ticks < ticks)
        DemTick(0);
    sub_2F442(t);
    FadeOutStart();
    while (fade_cur != 0)
        DemTick(1);
}

/* Load the script name.dem. */
void LoadDem(char *name)
{
    unsigned size;
    unsigned packed;
    DemCmd *p;
    MemHandle h;
    char far *src;

    GetFileSizes(name, "dem", &size, &packed);
    p = AllocMemPtr(size);
    h = getanyfile(name, "dem");
    src = LockMem(h);
    MemCpy(p, src, size);
    UnlockMem(h);
    FreeAnyFile(h);
    dem_pc = dem_buf = p;
}

/* Run the script's commands for frame (-1: those that start things). */
void RunDem(int frame)
{
    char name[14];
    char *p;
    char path[64];
    MemHandle h;
    char far *buf;
    unsigned ticks;

    for (;;) {
        if (frame != -1 && dem_pc->frame != frame)
            return;
        *(Name8 *)name = *(Name8 *)dem_pc->name;
        name[8] = 0;
        if ((p = strchr(name, ' ')) != 0)
            *p = 0;
        switch (dem_pc->op) {
        case 0:
            if (frame != -1)
                return;
            dem_pc++;
            PlayDpAnim(name);
            break;
        case 1:
            ticks = dem_pc->a;
            if (frame != -1)
                return;
            dem_pc++;
            ShowLbm(name, ticks);
            break;
        case 2:
            dem_pc++;
            break;
        case 3:
            PlayMusic(dem_pc->a, dem_pc->b);
            dem_pc++;
            break;
        case 4:
            BridgeSfx(dem_pc->a);
            dem_pc++;
            break;
        case 5:
            PlayDigiSfx(name, 0x7F, 0x40, 0);
            dem_pc++;
            break;
        case 6:
            switch (dem_pc->a) {
            case 0:
                dem_pc++;
                break;
            case 1:
                fade_speed = 10;
                dem_pc = dem_buf;
                break;
            case 2:
                return;
            }
            break;
        case 7:
            fade_speed = dem_pc->a;
            if (fade_speed < 0)
                fade_speed = 0;
            else if (fade_speed > 100)
                fade_speed = 100;
            dem_pc++;
            break;
        case 8:
            if (frame != -1)
                return;
            dem_pc++;
            sprintf(path, "%s%s%s.mve", cd_path, uncomp_dir, name);
            buf = LockMem(h = AllocMemAbort(64000, 1));
            fade_target = fade_cur = 100;
            PlayMovie(path, backbuf->data, buf);
            UnlockMem(h);
            FreeMem(h);
            break;
        }
    }
}

void DemNext(void)
{
    while (dem_pc->op != 6)
        dem_pc++;
}

/* Skip to the script's end, starting the music it would have. */
void DemSkip(void)
{
    while (dem_pc->op != 6 || dem_pc->a == 1) {
        if (dem_pc->op == 3)
            PlayMusic(dem_pc->a, dem_pc->b);
        dem_pc++;
    }
    BridgeSfx(0xFE);
}

/* Once a tick: 1 if the player skipped the rest. */
int DemTick(int frame)
{
    Event ev;
    char k;

    while (GetEvent(&ev)) {
        if (ev.type == EV_KEY) {
            if ((k = (unsigned)ev.key >> 8) == 1 || k == 0x39) {
                DemSkip();
                return 1;
            }
        } else if (ev.type == EV_UP2) {
            DemSkip();
            return 1;
        }
    }
    MusicTick();
    FadeStep();
    RunDem(frame);
    return 0;
}

/* Play the cutscene name.dem. */
void PlayDem(char *name)
{
    fade_cur = 0;
    fade_target = 100;
    fade_time = -1;
    fade_speed = 10;
    LoadDem(name);
    DemTick(-1);
    FreeMemPtr(dem_buf);
    GetPalette(cur_palette);
    FadeOut();
}

/* The large page holding record rec. */
unsigned FindLp(unsigned rec)
{
    unsigned i;

    for (i = 0; i < dp_header.nlps; i++)
        if (lp_table[i].base <= rec && lp_table[i].base + lp_table[i].count > rec)
            break;
    return i;
}

void ReadLp(int n, char far *buf)
{
    int pad;

    if (lp_cur == n)
        return;
    lp_cur = n;
    _lseek(anim_fd, ((long)n << 16) + 0xB00, 0);
    _read(anim_fd, &lp_hdr, 6);
    _read(anim_fd, &pad, 2);
    ReadFile(anim_fd, buf, lp_hdr.count * 2 + lp_hdr.bytes);
}

/* Play record rec of the large page in buf onto the screen. */
void DrawRec(unsigned rec, char far *buf)
{
    unsigned i;
    unsigned n;
    unsigned off;
    unsigned char far *p;

    off = 0;
    n = rec - lp_hdr.base;
    for (i = 0; i < n; i++)
        off += ((unsigned far *)buf)[i];
    p = (unsigned char far *)buf + lp_hdr.count * 2 + off;
    if (p[1])
        p += *(unsigned far *)(p + 2) + (*(unsigned far *)(p + 2) & 1) + 4;
    else
        p += 4;
    PlayDelta(p, vga_ptr);
}

void ShowRec(unsigned rec)
{
    ReadLp(FindLp(rec), anim_buf);
    DrawRec(rec, anim_buf);
}

void far AnimTimer(void)
{
    anim_ticks++;
}

/* Play the DPaint animation name.anm. */
void PlayDpAnim(char *name)
{
    unsigned i;
    unsigned n;

    lp_cur = -1;
    anim_buf = backbuf->data;
    lp_table = AllocMemPtr(0x600);
    anim_fd = OpenRes(name, "anm");
    if (_read(anim_fd, &dp_header, 0x80) != 0x80)
        Fatal("Play_Dp_Anim: bad file header.");
    _lseek(anim_fd, 0x80L, 1);
    {
        unsigned char rgb[4];

        for (i = 0; i < 768; i += 3) {
            _read(anim_fd, rgb, 4);
            cur_palette[i + 2] = rgb[0] >> 2;
            cur_palette[i + 1] = rgb[1] >> 2;
            cur_palette[i] = rgb[2] >> 2;
        }
    }
    SetFadeLevel(-1);
    _read(anim_fd, lp_table, 0x600);
    i = 0;
    n = (unsigned)dp_header.nrecords;
    if (dp_header.has_last_delta)
        n--;
    ReadLp(FindLp(0), anim_buf);
    anim_ticks = 0;
    anim_timer = sub_2F377(AnimTimer);
    sub_2F58A(anim_timer, (long)dp_header.fps);
    sub_2F4A9(anim_timer);
    FadeInStart();
    for (;;) {
        DrawRec(i, anim_buf);
        if (++i >= n)
            break;
        ReadLp(FindLp(i), anim_buf);
        if (DemTick(i))
            break;
        while (anim_ticks < i)
            if (DemTick(i))
                goto done;
    }
done:
    FadeOutStart();
    while (Fading())
        DemTick(i);
    sub_2F442(anim_timer);
    _close(anim_fd);
    FreeMemPtr(lp_table);
}
