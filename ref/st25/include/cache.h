/* cache.h - resource cache, EMS sound files and the streaming buffer */

#ifndef CACHE_H
#define CACHE_H

#include "list.h"
#include "mem.h"

#define CACHE_ENTRIES 256

/* A cached file: the packed data as read from DATA.001 and/or the unpacked
 * data. Entries are kept in most recently used order. */
typedef struct CacheEntry {
    Node node;              /* 00 */
    char name[10];          /* 04 */
    char ext[4];            /* 0E names starting with '$' are generated */
    int lock;               /* 12 */
    int hash;               /* 14 */
    MemHandle packed;       /* 16 */
    int packed_size;        /* 18 */
    MemHandle data;         /* 1A */
    int size;               /* 1C */
} CacheEntry;

/* A sound file loaded whole into EMS. */
typedef struct EMSFile {
    MemHandle handle;       /* 00 */
    char name[10];          /* 02 */
} EMSFile;

/* A sound effect channel. Starts like a MemRef so MapMemRef can map the
 * read position; pos/len walk the VOC blocks of the loaded file. */
typedef struct SndChan {
    MemHandle handle;       /* 00 */
    int busy;               /* 02 */
    unsigned long pos;      /* 04 offset in the file */
    long len;               /* 08 bytes left in the current block */
    unsigned long loop_pos; /* 0C VOC repeat start */
    unsigned long loops;    /* 10 VOC repeat count */
} SndChan;

/* A location inside a handle's block. */
typedef struct MemRef {
    MemHandle handle;       /* 00 */
    int unk;                /* 02 */
    unsigned long offset;   /* 04 */
} MemRef;

/* An object with a .r3s bank attached (layout beyond these fields unknown). */
typedef struct R3SOwner {
    char unk[0x68];
    MemHandle r3s;          /* 68 */
    int r3s_type;           /* 6A */
    char r3s_hdr[18];       /* 6C */
} R3SOwner;

extern CacheEntry cache_entries[CACHE_ENTRIES];
extern List cache_list;
extern long stream_fill_pos;
extern long stream_play_pos;
extern int stream_active;
extern MemHandle stream_handle;
extern long map_tmp;
extern long stream_tmp;
extern SndChan snd_chan[4];
extern EMSFile far ems_files[8];

void CacheInit(void);
MemHandle CacheGet(char *name, char *ext, int ems, int load, int unpack);
void CacheStore(char *name, char *ext, MemHandle h);
void ReleaseCache(MemHandle h);
int CachePurge(int ems);
MemHandle LoadBitmap(char *name);
void ReleaseBitmap(MemHandle h);
MemHandle getanyfile(char *name, char *ext);
void FreeAnyFile(MemHandle h);
void CachePreload(char *name, char *ext);
MemHandle CacheLoad(char *name, char *ext);
void CacheRelease(MemHandle h);
void LoadR3S(R3SOwner *o, char *name, int n);
void ReleaseR3S(MemHandle h);
MemHandle LoadSpriteBitmap(char *name, int scale);
void FreeSpriteBitmap(MemHandle h, int scale);
int NameHash(char *s);
void StreamInit(void);
void StreamFill(void);
MemHandle LoadEMSFile(char *name, char *ext);
void far *EMSMapAddr(void far *handle);
void far *MapHandle(MemHandle h);
void far *MapMemRef(MemRef *r);
void far *MapStream(void);
void CacheNop(void);
void FreeAllEMSFiles(void);
void FreeEMSFiles(void);
void SfxNop(MemHandle h);
void LoadSfx(char *name);

#endif
