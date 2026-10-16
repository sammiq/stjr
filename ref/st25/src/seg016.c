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

CacheEntry cache_entries[CACHE_ENTRIES];
List cache_list;
long stream_fill_pos;
long stream_play_pos;
int stream_active;
MemHandle stream_handle;
long map_tmp;
long stream_tmp;
EMSFile far ems_files[8];

void CacheInit(void)
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

MemHandle LoadBitmap(char *name)
{
    return CacheLoad(name, "bmp");
}

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

void ReleaseR3S(MemHandle h)
{
    ReleaseCache(h);
}

/* Load a bitmap, scaled by scale/256. Crew "stnd"/"tele" bitmaps other
 * than the 'm' ones are built from the 'm' bitmap plus a .xor delta, with
 * the uniform colours shifted for 'k' and 'r', and cached as .$bm. */
MemHandle LoadSpriteBitmap(char *name, int scale)
{
    MemHandle h;
    MemHandle scaled;
    int unused;
    Bitmap far *src;
    Bitmap far *xr;
    Bitmap far *dst;
    MemHandle hbase;
    MemHandle hxor;
    int shift;
    unsigned npix;
    char c;
    char far *s;
    char far *d;
    int rows;
    unsigned w;
    int skip;
    int unused2;

    if ((strncmp(name + 1, "stnd", 4) == 0 || strncmp(name + 1, "tele", 4) == 0)
            && (name[0] == 'm' || name[0] == 's' || name[0] == 'k' || name[0] == 'r')) {
        if (name[0] == 'm')
            h = CacheGet(name, "bmp", 0, 1, 1);
        else if ((h = CacheGet(name, "$bm", 0, 0, 1)) != 0)
            ;
        else {
            c = name[0];
            name[0] = 'm';
            hbase = CacheGet(name, "bmp", 0, 1, 1);
            name[0] = c;
            hxor = CacheGet(name, "xor", 0, 1, 1);
            src = LockMem(hbase);
            npix = src->w * src->h;
            UnlockMem(hbase);
            h = AllocMemAbort(npix + 8, 1);
            dst = LockMem(h);
            src = LockMem(hbase);
            xr = LockMem(hxor);
            *(BitmapHdr far *)dst = *(BitmapHdr far *)src;
            if (c == 'k')
                shift = 8;
            else if (c == 'r')
                shift = -8;
            else
                shift = 0;
            if (shift == 0)
                MemCpy(dst->data, src->data, npix);
            else {
                s = src->data;
                d = dst->data;
                _asm {
                    push si
                    push di
                    lds si, s
                    les di, d
                    mov cx, npix
                    mov bl, 0A8h
                    mov dl, byte ptr shift
                    add dl, 0A8h
                    mov dh, 7
                l_plain:
                    lodsb
                    sub al, bl
                    cmp al, dh
                    jbe l_shift
                l_store:
                    add al, bl
                    stosb
                    loop l_plain
                    jmp l_done
                l_next:
                    lodsb
                    sub al, bl
                    cmp al, dh
                    ja l_store
                l_shift:
                    add al, dl
                    stosb
                    loop l_next
                    jmp l_done
                l_done:
                    mov ax, ss
                    mov ds, ax
                    pop di
                    pop si
                }
            }
            s = xr->data;
            d = &dst->data[(src->y - xr->y) * dst->w + (src->x - xr->x)];
            w = xr->w;
            rows = xr->h;
            skip = dst->w - w;
            _asm {
                push si
                push di
                lds si, s
                les di, d
            l_row:
                mov cx, w
                test si, 1
                je l_even
                lodsb
                xor es:[di], al
                inc di
                dec cx
            l_even:
                shr cx, 1
                pushf
            l_words:
                lodsw
                xor es:[di], ax
                add di, 2
                loop l_words
                popf
                jae l_rowend
                lodsb
                xor es:[di], al
                inc di
            l_rowend:
                add di, skip
                dec rows
                jne l_row
                mov ax, ss
                mov ds, ax
                pop di
                pop si
            }
            UnlockMem(hxor);
            ReleaseCache(hxor);
            UnlockMem(hbase);
            ReleaseCache(hbase);
            UnlockMem(h);
            CacheStore(name, "$bm", h);
        }
    } else
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

/* A 64K EMS ring buffer for streamed sound. */
void StreamInit(void)
{
    void far *p;
    int unused;

    if ((p = EMSAlloc(0x10000L)) != 0)
        stream_handle = AllocMemHandle(p);
}

/* Refill the ring buffer up to the play position, 8K at a time. */
void StreamFill(void)
{
    long left;
    int unused1;
    long addr;
    long unused2;
    long pos;
    long chunk;
    unsigned n;
    void far *p;

    if (!stream_active)
        return;
    left = stream_play_pos - stream_fill_pos;
    if (left <= 0)
        left += 0x10000L;
    left -= 1;
    left &= 0xFFFFE000L;
    pos = stream_fill_pos;
    while (left != 0) {
        addr = (long)stream_handle->ptr;
        addr = addr + pos;
        p = LockMem((MemHandle)&addr);
        chunk = left > 0x2000 ? 0x2000L : left;
        n = ReadVoc(p, chunk);
        if (n == 0) {
            stream_active = 0;
            UnlockMem((MemHandle)&addr);
            break;
        } else if (n < chunk) {
            stream_active = 0;
            _fmemset((char far *)p + n, 0x80, 0x2000 - n);
        }
        left -= chunk;
        pos += chunk;
        if (pos >= 0x10000L)
            pos = 0;
        UnlockMem((MemHandle)&addr);
    }
    stream_fill_pos = pos;
}

/* Load voc_path/sfx/name.ext whole into EMS, remembering up to 8 files. */
MemHandle LoadEMSFile(char *name, char *ext)
{
    long size;
    MemHandle h;
    long addr;
    void far *e;
    char path[40];
    int fd;
    long pos;
    long chunk;
    void far *p;
    void far *saved;
    unsigned got;
    int i;

    for (i = 0; i < 8; i++)
        if (ems_files[i].handle != 0 && _fstrnicmp(ems_files[i].name, name, 10) == 0)
            return ems_files[i].handle;
    sprintf(path, "%ssfx/%s.%s", voc_path, name, ext);
    if ((fd = open(path, O_RDONLY | O_BINARY)) == -1)
        return 0;
    size = filelength(fd);
    close(fd);
    if ((e = EMSAlloc(size)) != 0)
        h = AllocMemHandle(e);
    if (_dos_open(path, O_RDONLY | O_BINARY, &fd) != 0)
        return;
    pos = 0;
    saved = EMSUnlock();
    while (size != 0) {
        addr = (long)h->ptr;
        addr = addr + pos;
        p = LockMem((MemHandle)&addr);
        chunk = size > 0x4000 ? 0x4000L : size;
        ReadChunk(fd, p, chunk, &got);
        size -= chunk;
        pos += chunk;
        UnlockMem((MemHandle)&addr);
    }
    EMSRestore(saved);
    _dos_close(fd);
    for (i = 0; i < 8; i++)
        if (ems_files[i].handle == 0)
            break;
    if (i == 8)
        FreeEMSFiles();
    for (i = 0; i < 8; i++)
        if (ems_files[i].handle == 0) {
            ems_files[i].handle = h;
            _fstrncpy(ems_files[i].name, name, 10);
            break;
        }
    return h;
}

/* Like EMSAccess, without the lock bookkeeping. */
void far *EMSMapAddr(void far *handle)
{
    int page;
    int i;
    long addr = (long)handle;

    if (ems_other_page == -1)
        return handle;
    if (!IsEMSMemory(handle))
        return handle;
    page = (addr >> 14) & 0xFF;
    for (i = 0; i != 4; ++i, ++page)
        EMSMapPage(page, i);
    return EMSHandleToPtr(handle);
}

void far *MapHandle(MemHandle h)
{
    return EMSMapAddr(h->ptr);
}

void far *MapMemRef(MemRef *r)
{
    int unused;
    void far *p;

    map_tmp = (long)r->handle->ptr;
    map_tmp = map_tmp + r->offset;
    p = MapHandle((MemHandle)&map_tmp);
    return p;
}

void far *MapStream(void)
{
    int unused;
    void far *p;

    stream_tmp = (long)stream_handle->ptr;
    stream_tmp = stream_tmp + stream_play_pos;
    p = MapHandle((MemHandle)&stream_tmp);
    return p;
}

void CacheNop(void)
{
}

void FreeAllEMSFiles(void)
{
    int i;

    DigiShutdown();
    for (i = 0; i < 8; i++)
        if (ems_files[i].handle != 0) {
            FreeAnyFile(ems_files[i].handle);
            ems_files[i].handle = 0;
            ems_files[i].name[0] = 0;
        }
}

/* Free the EMS sound files that no channel is playing. */
void FreeEMSFiles(void)
{
    int i;

    for (i = 0; i < 8; i++) {
        if (ems_files[i].handle != 0
                && !(snd_chan[0].handle == ems_files[i].handle && snd_chan[0].busy)
                && !(snd_chan[1].handle == ems_files[i].handle && snd_chan[1].busy)
                && !(snd_chan[2].handle == ems_files[i].handle && snd_chan[2].busy)
                && !(snd_chan[3].handle == ems_files[i].handle && snd_chan[3].busy)) {
            FreeAnyFile(ems_files[i].handle);
            ems_files[i].handle = 0;
            ems_files[i].name[0] = 0;
        }
    }
}

void SfxNop(MemHandle h)
{
}

void LoadSfx(char *name)
{
    MemHandle h;

    h = LoadEMSFile(name, "voc");
    SfxNop(h);
}
