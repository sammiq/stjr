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
CacheEntry cache_entries[CACHE_ENTRIES];

List cache_list;

void DigiShutdown(void);                       void CacheInit(void)
{
    int i;
    CacheEntry *e;

    ListInit(&cache_list);
    for (e = cache_entries, i = 0; i != CACHE_ENTRIES; ++i, ++e) {
        MemSet(e, sizeof(CacheEntry), 0);
        ListAdd(&cache_list, &e->node);
    }
}

/* Find a file in the cache, loading it into the least recently used free
 * entry if needed (and if load is set). With unpack the unpacked data is
 * returned and the entry stays locked until ReleaseCache. */
MemHandle CacheGet(char *name, char *ext, int ems, int load, int unpack)
{
    int i;
    int hash;
    CacheEntry *e;

    hash = NameHash(name) + NameHash(ext);
    for (i = 0, e = (CacheEntry *)cache_list.tail.next; i != CACHE_ENTRIES;
            ++i, e = (CacheEntry *)e->node.next) {
        if (e->hash == hash && strncmp(e->name, name, 10) == 0 && strncmp(e->ext, ext, 4) == 0)
            goto found;
    }
    if (load == 0)
        return 0;
    for (i = 0, e = (CacheEntry *)cache_list.head.prev; i != CACHE_ENTRIES;
            ++i, e = (CacheEntry *)e->node.prev) {
        if (e->lock == 0) {
            if (e->packed)
                FreeMem(e->packed);
            if (e->data)
                FreeMem(e->data);
            GetFileSizes(name, ext, &e->size, &e->packed_size);
            e->lock++;
            e->packed = AllocMemAbort(e->packed_size, 0);
            e->lock--;
            LoadFile(name, ext, LockMem(e->packed));
            UnlockMem(e->packed);
            strncpy(e->name, name, 10);
            strncpy(e->ext, ext, 4);
            e->data = 0;
            e->hash = hash;
            goto found;
        }
    }
    Fatal("Cache overflow.");
found:
    ListRemove(&cache_list, &e->node);
    ListAdd(&cache_list, &e->node);
    if (unpack) {
        e->lock++;
        if (e->data == 0 && e->packed != 0) {
            e->data = AllocMemAbort(e->size, ems);
            UnpackAll(LockMem(e->packed), LockMem(e->data), e->packed_size);
            UnlockMem(e->packed);
            UnlockMem(e->data);
            if (e->size < (e->packed_size >> 2) + e->packed_size) {
                FreeMem(e->packed);
                e->packed = 0;
            }
        }
        return e->data;
    } else
        return 0;
}

/* Put an existing block into the cache under name.ext (locked). */
void CacheStore(char *name, char *ext, MemHandle h)
{
    int i;
    int hash;
    CacheEntry *e;

    hash = NameHash(name) + NameHash(ext);
    for (i = 0, e = (CacheEntry *)cache_list.head.prev; i != CACHE_ENTRIES;
            ++i, e = (CacheEntry *)e->node.prev) {
        if (e->lock == 0) {
            if (e->packed)
                FreeMem(e->packed);
            if (e->data)
                FreeMem(e->data);
            e->lock++;
            ListRemove(&cache_list, &e->node);
            ListAdd(&cache_list, &e->node);
            e->data = h;
            e->packed = 0;
            strncpy(e->name, name, 10);
            strncpy(e->ext, ext, 4);
            e->hash = hash;
            return;
        }
    }
    Fatal("Cache overflow.");
}

void ReleaseCache(MemHandle h)
{
    int i;
    CacheEntry *e;

    e = (CacheEntry *)cache_list.tail.next;
    for (i = 0; i != CACHE_ENTRIES; ++i, e = (CacheEntry *)e->node.next) {
        if (e->data == h) {
            if (--e->lock < 0)
                Fatal("ReleaseCache: too many releases. %s", e->name);
            return;
        }
    }
}

/* Free some cached memory; returns 0 if nothing could be freed. Unless
 * ems is set, memory in EMS is left alone. */
int CachePurge(int ems)
{
    CacheEntry *e;
    int i;
    MemHandle h;

    /* unlocked entries: drop the packed or unpacked copy */
    e = (CacheEntry *)cache_list.head.prev;
    for (i = 0; i != CACHE_ENTRIES; ++i, e = (CacheEntry *)e->node.prev) {
        if (e->lock == 0 && e->data != 0) {
            if (e->packed != 0) {
                if (!ems && IsMemEMS(e->data)) {
                    if (IsMemEMS(e->packed))
                        continue;
                    FreeMem(e->packed);
                    e->packed = 0;
                } else {
                    FreeMem(e->data);
                    e->data = 0;
                }
                return 1;
            } else if (e->ext[0] == '$') {
                if (!ems && IsMemEMS(e->data))
                    continue;
                FreeMem(e->data);
                ListRemove(&cache_list, &e->node);
                MemSet(e, sizeof(CacheEntry), 0);
                ListAdd(&cache_list, &e->node);
                return 1;
            }
        }
    }
    /* unlocked entries: drop the entry */
    e = (CacheEntry *)cache_list.head.prev;
    for (i = 0; i != CACHE_ENTRIES; ++i, e = (CacheEntry *)e->node.prev) {
        if (e->lock == 0 && (e->data != 0 || e->packed != 0)) {
            h = e->data ? e->data : e->packed;
            if (!ems && IsMemEMS(h))
                continue;
            FreeMem(h);
            ListRemove(&cache_list, &e->node);
            MemSet(e, sizeof(CacheEntry), 0);
            ListAdd(&cache_list, &e->node);
            return 1;
        }
    }
    /* locked entries: drop the packed copy */
    e = (CacheEntry *)cache_list.head.prev;
    for (i = 0; i != CACHE_ENTRIES; ++i, e = (CacheEntry *)e->node.prev) {
        if (e->lock != 0 && e->packed != 0 && e->data != 0) {
            if (!ems && IsMemEMS(e->packed))
                continue;
            FreeMem(e->packed);
            e->packed = 0;
            return 1;
        }
    }
    return 0;
}

/* New in the sequel: purge everything that can be. */
void CachePurgeAll(void)
{
    while (CachePurge(1))
        ;
}

MemHandle LoadBitmap(char *name)
{
    return CacheLoad(name, "bmp");
}

/* seg015 */

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

