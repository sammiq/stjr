/* seg016: resource cache, EMS sound files and the streaming buffer */

#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include <dos.h>
#include "list.h"
#include "mem.h"
#include "ems.h"
#include "bitmap.h"
#include "resource.h"
#include "cache.h"

int tolower(int c);
void Fatal(char *fmt, ...);             /* fatal error */
unsigned ReadVoc(void far *buf, long len); /* seg015: read stream data */
void DigiShutdown(void);                       /* seg015 */

void ReleaseBitmap(MemHandle h)
{
    CacheRelease(h);
}

/* Load and unpack a file into its own block (not cached). */
MemHandle getanyfile(char *name, char *ext)
{
    long size;
    MemHandle h;

    if ((size = GetFileSize(name, ext)) > 65000L)
        Fatal("getanyfile: excessively large object requested %s.", name);
    h = AllocMemAbort(size, 0);
    LoadFilePacked(name, ext, LockMem(h));
    UnlockMem(h);
    return h;
}

/* getanyfile into EMS. New in the sequel. */
MemHandle getanyfileems(char *name, char *ext)
{
    long size;
    MemHandle h;

    if ((size = GetFileSize(name, ext)) > 65000L)
        Fatal("getanyfile: excessively large object requested %s.", name);
    h = AllocMemAbort(size, 1);
    LoadFilePacked(name, ext, LockMem(h));
    UnlockMem(h);
    return h;
}

void FreeAnyFile(MemHandle h)
{
    FreeMem(h);
}

void CachePreload(char *name, char *ext)
{
    CacheGet(name, ext, 0, 1, 0);
}

MemHandle CacheLoad(char *name, char *ext)
{
    return CacheGet(name, ext, 0, 1, 1);
}

/* CacheLoad into EMS. New in the sequel. */
MemHandle CacheLoadEMS(char *name, char *ext)
{
    return CacheGet(name, ext, 1, 1, 1);
}

void CacheRelease(MemHandle h)
{
    ReleaseCache(h);
}

void LoadR3S(R3SOwner *o, char *name, int n)
{
    MemHandle h;
    void far *p;
    char buf[16];
    int unused;

    unused = 0;
    sprintf(buf, "%s%02x", name, (n >> 1) & 0x77);
    h = CacheGet(buf, "r3s", 1, 1, 1);
    o->r3s = h;
    o->r3s_type = 0x24;
    p = LockMem(h);
    MemCpy(o->r3s_hdr, p, 18);
    UnlockMem(h);
}

/* New in the sequel: CacheRelease's twin, for CacheLoadEMS. */
void CacheReleaseEMS(MemHandle h)
{
    ReleaseCache(h);
}

/* ST25's version also built bitmaps from a base and an XOR delta. */
MemHandle LoadSpriteBitmap(char *name, int scale)
{
    MemHandle h;
    MemHandle scaled;

    h = CacheGet(name, "bmp", 1, 1, 1);
    if (scale == 0x100)
        return h;
    else {
        scaled = ScaleBitmap(h, scale);
        ReleaseCache(h);
        return scaled;
    }
}

void FreeSpriteBitmap(MemHandle h, int scale)
{
    if (scale == 0x100)
        ReleaseCache(h);
    else
        FreeMem(h);
}

int NameHash(char *s)
{
    int sum;

    for (sum = 0; *s != 0; s++)
        sum += tolower(*s);
    return sum;
}

