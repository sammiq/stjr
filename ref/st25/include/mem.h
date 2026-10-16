/* mem.h - memory manager: near heap, far pool, handles */

#ifndef MEM_H
#define MEM_H

/* Handle table slot: the far address of a block, or the free list link. */
typedef union MemSlot {
    void far *ptr;
    union MemSlot *next;
} MemSlot;

typedef MemSlot *MemHandle;

#define MEM_MAX_HANDLES 512

/* Every pool block starts on a paragraph boundary with this header; the
 * data follows in the next paragraph. */
typedef struct PoolHdr {
    unsigned size;          /* 00 block size in paragraphs, header included */
    MemHandle handle;       /* 02 owning handle, 0 if free */
} PoolHdr;

#define POOL_DATA(h)  ((void far *)((long)(h) + 0x10000L))
#define POOL_HDR(p)   ((PoolHdr far *)((long)(p) - 0x10000L))

extern MemSlot mem__handle_tbl[MEM_MAX_HANDLES];
extern MemSlot *mem_handle_free_list;   /* unused handle slots */
extern PoolHdr far *lpPoolStart;
extern PoolHdr far *lpPoolEnd;          /* PushMem blocks grow down from here */
extern PoolHdr far *lpPoolCurrent;      /* allocation rover */
extern unsigned pool_free_mem;          /* free paragraphs */
extern int pool_stack_size;             /* PushMem depth */
extern int pool_lock_count;

void *AllocMemPtr(int size);
void FreeMemPtr(void *p);
void InitPMem(void);
void CompactPMem(void);
void far *PushMem(unsigned size);
void PopMem(void);
void InitMemHandles(void);
void InitMem(void);
MemHandle AllocMemHandle(void far *p);
void FreeMemHandle(MemHandle h);
MemHandle AllocMem(unsigned size, int ems);
MemHandle AllocMemAbort(unsigned size, int ems);
int IsMemEMS(MemHandle h);
void far *LockMem(MemHandle h);
void UnlockMem(MemHandle h);
void FreeMem(MemHandle h);
void far *MemSet(void far *dst, unsigned n, int c);
void MemCpy(void far *dst, void far *src, unsigned n);
void MemCpyNZ(void far *dst, void far *src, unsigned n);

#endif
