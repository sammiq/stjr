/* seg004: LIM EMS expanded memory allocator
 *
 * Rewritten for the sequel (see ems.h): blocks are handles, the whole of
 * EMS is one allocation, and the game needs at least 1Mb of it. */

#include <dos.h>
#include "ems.h"

extern unsigned _aseghi;    /* C runtime: highest segment in use */

void Fatal();               /* fatal error */

EMSBlock ems_blocks[EMS_MAX_BLOCKS];
EMSBlock *ems_head;
EMSBlock *ems_rover;
EMSBlock *ems_free_list;
unsigned long ems_free;

int ems_other_page = -1;
unsigned ems_page_seg = 0;
unsigned ems_num_pages = 0;
EMSBlock *ems_lock = 0;
int ems_lock_count = 0;

void EMSInit(void)
{
    int handle;
    unsigned top;
    int i;

    if (_dos_open("EMMXXXX0", 0, &handle) == 0) {
        _asm {
            mov ah, 41h
            int 67h
            mov ems_page_seg, bx
            mov ah, 42h
            int 67h
            mov ems_num_pages, bx
            or bx, bx
            je no_pages
            mov ah, 43h
            int 67h
            mov ems_other_page, dx
        no_pages:
        }
        if (ems_other_page != -1) {
            top = ems_page_seg + 0x1000;
            if (top > _aseghi)
                _aseghi = top;
            ems_free_list = 0;
            for (i = 0; i < EMS_MAX_BLOCKS; i++)
                EMSFreeBlock(&ems_blocks[i]);
            ems_free = (long)ems_num_pages << 14;
            ems_head = EMSNewBlock();
            ems_head->next = 0;
            ems_head->addr = 0;
            ems_head->size = ems_free;
            ems_rover = ems_head;
            ems_lock = 0;
            ems_lock_count = 0;
            if (ems_free < 1000000L)
                goto fail;
            return;
        }
    }
fail:
    Fatal("You must have a minimum of 1Mb of EMS memory to run this game.");
}

int ems_mapped = -1;

/* A block of size bytes (rounded up to 16, at most 64K) that doesn't cross
 * more 16K pages than EMSLockHandle maps; 0 if there is none. */
EMSBlock *EMSAllocHandle(unsigned long size)
{
    EMSBlock *b;
    EMSBlock *n;
    unsigned ofs;
    int fits;

    if (ems_other_page == -1)
        return 0;
    size = (size + 15) & ~15L;
    if (size > 0x10000L)
        return 0;
    if (size > ems_free)
        return 0;
    EMSCoalesce();
    b = ems_rover;
    do {
        if (!(b->size & EMS_USED)) {
            ofs = (unsigned)b->addr & 0x3FFF;
            while ((n = b->next) != 0 && !(n->size & EMS_USED)) {
                b->size += n->size;
                b->next = n->next;
                EMSFreeBlock(n);
            }
            fits = b->size >= size && 0x10000L - ofs >= size;
            ofs = 0x4000 - ofs;
            if (fits)
                ems_rover = b;
            else if ((unsigned long)ofs + size <= b->size) {
                /* start it at the next page instead */
                if ((n = EMSNewBlock()) == 0)
                    return 0;
                n->next = b->next;
                b->next = n;
                n->addr = b->addr + ofs;
                n->size = b->size - ofs;
                b->size = ofs;
                ems_rover = b;
                b = n;
                fits = 1;
            }
            if (fits)
                goto found;
        }
        if ((b = b->next) == 0)
            b = ems_head;
    } while (ems_rover != b);
    return 0;

found:
    if (b->size != size) {
        if ((n = EMSNewBlock()) == 0)
            return 0;
        n->next = b->next;
        b->next = n;
        n->addr = b->addr + size;
        n->size = b->size - size;
        b->size = size;
    }
    b->size |= EMS_USED;
    ems_free += EMS_USED - b->size;
    return b;
}

/* Map b's pages in (if they aren't) and return its address. */
void far *EMSLockHandle(EMSBlock *b)
{
    unsigned long addr;
    int page;
    int i;

    if (ems_lock != 0 && ems_lock != b)
        Fatal("EMS: multiple access.");
    ems_lock = b;
    ++ems_lock_count;
    addr = b->addr;
    page = (int)(addr >> 14) & 0xFF;
    if (page != ems_mapped) {
        ems_mapped = page;
        for (i = 0; i != 4; ++i, ++page)
            EMSMapPage(page, i);
    }
    return (void far *)((unsigned long)((((unsigned)addr & 0x3FF0) >> 4) + ems_page_seg) << 16);
}

void EMSUnlockHandle(EMSBlock *b)
{
    if (ems_lock == 0 || b != ems_lock)
        Fatal("EMS: EMSUnlock with wrong handle.");
    if (--ems_lock_count == 0)
        ems_lock = 0;
}

/* Forget the lock (around something else using the page frame). */
EMSBlock *EMSSave(void)
{
    EMSBlock *b;

    b = ems_lock;
    if (ems_lock_count > 1)
        Fatal("EMSSave: lock_count > 1");
    ems_lock = 0;
    ems_lock_count = 0;
    return b;
}

void EMSRestore(EMSBlock *b)
{
    if (ems_lock != 0)
        Fatal("EMSRestore while EMS locked.");
    if (b != 0)
        EMSLockHandle(b);
}

void EMSFreeHandle(EMSBlock *b)
{
    if (!(b->size & EMS_USED))
        Fatal("EMSFree: Attempt to free twice");
    b->size &= ~EMS_USED;
    ems_free += b->size;
    if (b->next == ems_rover)
        ems_rover = ems_head;
}

/* Merge neighbouring free blocks, when EMSBlocks are running out. */
void EMSCoalesce(void)
{
    EMSBlock *b;
    EMSBlock *n;

    if (ems_free_list != 0 && ems_free_list->next != 0)
        return;
    ems_rover = ems_head;
    for (b = ems_head; b != 0; b = b->next) {
        if (!(b->size & EMS_USED)) {
            while ((n = b->next) != 0 && !(n->size & EMS_USED)) {
                b->size += n->size;
                b->next = n->next;
                EMSFreeBlock(n);
            }
        }
    }
}

EMSBlock *EMSNewBlock(void)
{
    EMSBlock *b;

    if ((b = ems_free_list) == 0)
        return 0;
    ems_free_list = b->next;
    return b;
}

void EMSFreeBlock(EMSBlock *b)
{
    b->next = ems_free_list;
    ems_free_list = b;
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

int IsEMSHandle(EMSBlock *b)
{
    if (b >= ems_blocks && b < &ems_blocks[EMS_MAX_BLOCKS])
        return 1;
    return 0;
}
