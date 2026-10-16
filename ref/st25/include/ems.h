/* ems.h - LIM EMS expanded memory allocator */

#ifndef EMS_H
#define EMS_H

/* A block of expanded memory. Blocks form a list ordered by address,
 * starting from a dummy head node. */
typedef struct EMSBlock {
    struct EMSBlock *next;  /* 00 */
    long addr;              /* 02 offset into the EMS allocation */
    long size;              /* 06 */
    int free;               /* 0A block is unallocated */
    int inuse;              /* 0C pool slot is taken */
} EMSBlock;                 /* 0E */

#define EMS_MAX_BLOCKS 256

/* EMS handles are far pointer sized: 0xFF in the top byte marks EMS,
 * the low 24 bits are the address within the allocation. */

extern int ems_other_page;          /* EMM handle, -1 if EMS is unavailable */
extern unsigned ems_page_seg;       /* page frame segment */
extern unsigned ems_num_pages;      /* free 16K pages at startup */
extern void far *ems_lock_ptr;      /* handle currently mapped in */
extern int ems_first_page;          /* handle of the first 1-page allocation */
extern EMSBlock ems_blocks[EMS_MAX_BLOCKS];
extern EMSBlock *ems_head;

void EMSInit(void);
void far *EMSAlloc(long size);
void far *EMSAccess(void far *handle);
void EMSDeaccess(void far *handle);
void far *EMSUnlock(void);
void EMSRestore(void far *handle);
void EMSFree(void far *handle);
EMSBlock *EMSNewBlock(void);
void EMSFreeBlock(EMSBlock *b);
void EMSCoalesce(void);
int EMSMapPage(int logical, int physical);
int EMSRelease(void);
void far *EMSMakeHandle(unsigned long addr);
void far *EMSHandleToPtr(void far *handle);
long EMSHandleOffset(void far *handle);
int IsEMSMemory(void far *handle);
int EMSSaveMap(void);
int EMSRestoreMap(void);

#endif
