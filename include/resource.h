/* resource.h - resource archives (.DIR / .RUN / .001) and loose files */

#ifndef RESOURCE_H
#define RESOURCE_H

#include <dos.h>
#include "mem.h"

/* DATA.DIR entry, sorted by extension then name. */
typedef struct DirEntry {
    char name[8];           /* 00 */
    char ext[3];            /* 08 */
    unsigned offset;        /* 0B low word of the offset in DATA.001, or of
                               the DATA.RUN entry; bit 0: replaced by a patch */
    unsigned char hi;       /* 0D bits 0-6: offset bits 16-22, or for numbered
                               files (bit 7) the number of files */
} DirEntry;

/* A located file: in an archive's .001 each file starts with its unpacked
 * and packed sizes (read into size/packed); a loose file with its unpacked
 * size. */
typedef struct FileInfo {
    int fd;                 /* 00 the archive's .001, or the loose file */
    unsigned long offset;   /* 02 of the data; -1 (odd) if not found, 2 if loose */
    unsigned size;          /* 06 */
    unsigned packed;        /* 08 */
} FileInfo;

/* A .dir/.run/.001 set (new in the sequel: the game's and the mission's). */
typedef struct Archive {
    MemHandle dir;          /* 00 */
    MemHandle run;          /* 02 */
    unsigned count;         /* 04 .dir entries */
    int last;               /* 06 index of the last lookup */
    int fd;                 /* 08 the .001, -1 when closed */
} Archive;

extern Archive data_archive;
extern Archive mission_archive;
extern char *data_dir;
extern char *uncomp_dir;
extern struct find_t patch_find;

int UnpackChunk(unsigned char far *src, unsigned char far **pdst, unsigned len);
void Unpack(unsigned char far *src, unsigned char far *dst, unsigned len);
void UnpackAll(unsigned char far *src, unsigned char far *dst, unsigned len);
int OpenFile(char *name);
void ReadFile(int fd, void far *buf, unsigned len);
int ReadByte(int fd);
void OpenDataArchive(void);
void OpenMissionArchive(void);
void OpenArchive(Archive *a, char *name);
void CloseArchive(Archive *a);
FileInfo LocateFile(char *name, char *ext);
FileInfo OpenLooseFile(char *name, char *ext);
void CloseFile(FileInfo *fi);
FileInfo FindFile(Archive *a, char *name, char *ext, int mark);
void LoadFile(char *name, char *ext, char far *buf);
void LoadFilePacked(char *name, char *ext, unsigned char far *dst);
long GetFileSize(char *name, char *ext);
void GetFileSizes(char *name, char *ext, unsigned *psize, unsigned *ppacked);
void CopyName(char *dst, char *src);
void ScanPatches(Archive *a, char *pattern);
char *FindFirstPatch(char *pattern);
char *FindNextPatch(void);

#endif
