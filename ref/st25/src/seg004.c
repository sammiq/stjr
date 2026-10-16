/* seg004: LIM EMS expanded memory allocator */

#include <dos.h>
#include "ems.h"

/* Globals this file owns (declared in the headers). */
EMSBlock ems_blocks[EMS_MAX_BLOCKS];
EMSBlock *ems_head;
int ems_first_page;

extern unsigned _aseghi;    /* C runtime: highest segment in use */

/* No prototypes in this file in the original: the pointer is passed near. */
int MemSet();
void Fatal();           /* fatal error */

int ems_other_page = -1;
unsigned ems_page_seg = 0;
unsigned ems_num_pages = 0;
void far *ems_lock_ptr = 0;

void EMSInit(void)
{
    int handle;
    EMSBlock *blk;
    unsigned top;

    if (_dos_open("EMMXXXX0", 0, &handle) != 0)
        return;
    _asm {
        mov ah, 41h
        int 67h
        mov ems_page_seg, bx
        mov ah, 42h
        int 67h
        mov ems_num_pages, bx
        or bx, bx
        je no_pages
        push bx
        mov bx, 1
        mov ah, 43h
        int 67h
        mov ems_first_page, dx
        pop bx
        dec bx
        mov ah, 43h
        int 67h
        mov ems_other_page, dx
    no_pages:
    }
    if (ems_other_page != -1) {
        top = ems_page_seg + 0x1000L;
        if (top > _aseghi)
            _aseghi = top;
        MemSet(ems_blocks, sizeof(ems_blocks), 0);
        ems_head = EMSNewBlock();
        blk = EMSNewBlock();
        ems_head->next = blk;
        ems_head->addr = 0;
        ems_head->size = 0x10;
        ems_head->free = 0;
        blk->next = 0;
        blk->addr = 0x10;
        blk->size = ((long)ems_num_pages << 14) - 0x10;
        blk->free = 1;
        ems_lock_ptr = 0;
    }
}

void far *EMSAlloc(long size)
{
    EMSBlock *b;
    EMSBlock *n;

    if (ems_other_page == -1)
        return 0;
    for (b = ems_head->next; b != 0; b = b->next) {
        if (b->free) {
            if (b->size >= size) {
                if (b->size != size) {
                    if ((n = EMSNewBlock()) == 0)
                        return 0;
                    n->next = b->next;
                    b->next = n;
                    n->addr = b->addr + size;
                    n->size = b->size - size;
                    n->free = 1;
                    b->size = size;
                }
                b->free = 0;
                return EMSMakeHandle(b->addr);
            }
        }
    }
    return 0;
}

void far *EMSAccess(void far *handle)
{
    int page;
    int i;
    long addr = (long)handle;

    if (ems_other_page == -1)
        return handle;
    if (!IsEMSMemory(handle))
        return handle;
    if (ems_lock_ptr != 0)
        Fatal("EMS: multiple access.");
    ems_lock_ptr = handle;
    page = (addr >> 14) & 0xFF;
    for (i = 0; i != 4; ++i, ++page)
        EMSMapPage(page, i);
    return EMSHandleToPtr(handle);
}

void EMSDeaccess(void far *handle)
{
    if (ems_other_page == -1)
        return;
    if (IsEMSMemory(handle)) {
        if (ems_lock_ptr == 0)
            Fatal("EMS: multiple deaccess.");
        ems_lock_ptr = 0;
    }
}

void far *EMSUnlock(void)
{
    void far *p;

    p = ems_lock_ptr;
    ems_lock_ptr = 0;
    return p;
}

void EMSRestore(void far *handle)
{
    if (ems_lock_ptr != 0)
        Fatal("EMSRestore while EMS locked.");
    if (handle != 0)
        EMSAccess(handle);
}

void EMSFree(void far *handle)
{
    EMSBlock *b;
    long addr;

    if (ems_other_page == -1)
        return;
    addr = EMSHandleOffset(handle);
    for (b = ems_head->next; b != 0; b = b->next) {
        if (b->addr == addr) {
            b->free = 1;
            EMSCoalesce();
            return;
        }
    }
    Fatal("EMSFree: invalid address.");
}

EMSBlock *EMSNewBlock(void)
{
    EMSBlock *b;

    for (b = ems_blocks; b != ems_blocks + EMS_MAX_BLOCKS; b++) {
        if (b->inuse == 0) {
            MemSet(b, sizeof(EMSBlock), 0);
            b->inuse = 1;
            return b;
        }
    }
    return 0;
}

void EMSFreeBlock(EMSBlock *b)
{
    MemSet(b, sizeof(EMSBlock), 0);
    b->inuse = 0;
}

/* Merge adjacent free blocks. */
void EMSCoalesce(void)
{
    EMSBlock *b;
    EMSBlock *n;

    b = ems_head->next;
    while (b->next != 0) {
        if (b->free && b->next->free) {
            n = b->next;
            b->size += n->size;
            b->next = n->next;
            EMSFreeBlock(n);
        } else {
            b = b->next;
        }
    }
}

int EMSMapPage(int logical, int physical)
{
    _asm {
        mov ah, 44h
        mov al, byte ptr physical
        mov bx, logical
        mov dx, ems_other_page
        int 67h
    }
}

int EMSRelease(void)
{
    if (ems_other_page == -1)
        return;
    _asm {
        mov ah, 45h
        mov dx, ems_other_page
        int 67h
    }
}

void far *EMSMakeHandle(unsigned long addr)
{
    long h;

    h = addr;
    h |= 0xFF000000L;
    return (void far *)h;
}

void far *EMSHandleToPtr(void far *handle)
{
    long p;

    p = (long)handle;
    p = (p & 0x3FFF) | ((long)ems_page_seg << 16);
    return (void far *)p;
}

long EMSHandleOffset(void far *handle)
{
    long a;

    a = (long)handle;
    a &= 0x00FFFFFFL;
    return a;
}

int IsEMSMemory(void far *handle)
{
    long a;

    a = (long)handle;
    return ((a >> 16) & 0xFF00) == 0xFF00;
}

int EMSSaveMap(void)
{
    _asm {
        mov ah, 47h
        mov dx, ems_other_page
        int 67h
        mov al, ah
        mov ah, 0
    }
}

int EMSRestoreMap(void)
{
    _asm {
        mov ah, 48h
        mov dx, ems_other_page
        int 67h
        mov al, ah
        mov ah, 0
    }
}
