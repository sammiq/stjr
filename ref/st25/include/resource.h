/* resource.h - DATA.DIR / DATA.RUN / DATA.001 resource files and patches */

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

/* A located file. In DATA.001 each file starts with its unpacked and packed
 * sizes, which are read into size/packed. */
typedef struct FileInfo {
    char name[12];          /* 00 */
    unsigned long offset;   /* 0C -1 if not found */
    unsigned size;          /* 10 */
    unsigned packed;        /* 12 */
} FileInfo;

extern int voc_on_cd;       /* 1 when speech is read from the CD */
extern char *exit_msg;      /* printed by PrintExitMsg */
extern int data_not_open;
extern int dir_last;        /* DATA.DIR index of the last lookup */
extern char voc_path[];     /* directory holding the speech files */
extern MemHandle dir_handle;
extern unsigned dir_size;
extern unsigned dir_count;
extern MemHandle run_handle;
extern int data_fd;
extern struct find_t patch_find;
extern char far file_buf[];

void FindCD(void);
void PrintExitMsg(void);
void SetExitMsg(char *msg);
int UnpackChunk(unsigned char far *src, unsigned char far **pdst, unsigned len);
void Unpack(unsigned char far *src, unsigned char far *dst, unsigned len);
void UnpackAll(unsigned char far *src, unsigned char far *dst, unsigned len);
void ReadFile(int fd, void far *buf, unsigned len);
unsigned ReadChunk(int fd, char far *buf, unsigned len, unsigned *pread);
void OpenDataFiles(void);
FileInfo FindFile(char *name, char *ext, int mark);
int LoadPatch(char *name, char *ext, char far *buf);
int LoadPatchPacked(char *name, char *ext, unsigned char far *dst);
long GetPatchSize(char *name, char *ext);
int GetPatchSizes(char *name, char *ext, unsigned *psize, unsigned *ppacked);
void LoadFile(char *name, char *ext, char far *buf);
void LoadFilePacked(char *name, char *ext, unsigned char far *dst);
long GetFileSize(char *name, char *ext);
void GetFileSizes(char *name, char *ext, unsigned *psize, unsigned *ppacked);
void CopyName(char *dst, char *src);
void ScanPatches(void);
char *FindFirstPatch(void);
char *FindNextPatch(void);

#endif
