/* ems.h - LIM EMS expanded memory allocator
 *
 * The sequel's version: all of the free EMS is one EMM allocation, divided
 * into blocks. A block is its own handle (MemHandle-sized); IsEMSHandle
 * tells one from a far pool handle. Locking a block maps the four 16K pages
 * from the one it starts in, so a block never crosses more than that. */

#ifndef EMS_H
#define EMS_H

/* A block of expanded memory: a list ordered by address. */
typedef struct EMSBlock {
    struct EMSBlock *next;  /* 00 also the free list link */
    unsigned long addr;     /* 02 offset into the EMS allocation */
    unsigned long size;     /* 06 bytes, a multiple of 16; bit 0 set: in use */
} EMSBlock;                 /* 0A */

#define EMS_MAX_BLOCKS 256
#define EMS_USED       1L

extern int ems_other_page;          /* EMM handle, -1 if EMS is unavailable */
extern unsigned ems_page_seg;       /* page frame segment */
extern unsigned ems_num_pages;      /* free 16K pages at startup */
extern EMSBlock *ems_lock;          /* the block mapped in */
extern int ems_lock_count;
extern int ems_mapped;              /* first logical page mapped, -1 none */
extern EMSBlock ems_blocks[EMS_MAX_BLOCKS];
extern EMSBlock *ems_head;
extern EMSBlock *ems_rover;         /* where EMSAllocHandle looks first */
extern EMSBlock *ems_free_list;     /* unused EMSBlocks */
extern unsigned long ems_free;               /* free bytes */

void EMSInit(void);
EMSBlock *EMSAllocHandle(unsigned long size);
void far *EMSLockHandle(EMSBlock *b);
void EMSUnlockHandle(EMSBlock *b);
EMSBlock *EMSSave(void);
void EMSRestore(EMSBlock *b);
void EMSFreeHandle(EMSBlock *b);
void EMSCoalesce(void);
EMSBlock *EMSNewBlock(void);
void EMSFreeBlock(EMSBlock *b);
int EMSMapPage(int logical, int physical);
int EMSRelease(void);
int IsEMSHandle(EMSBlock *b);

#endif
