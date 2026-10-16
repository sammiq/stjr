/* seg013: memory manager - near heap, far pool with handles, EMS */

#include <stdio.h>
#include <malloc.h>
#include <dos.h>
#include "ems.h"
#include "mem.h"

/* Globals this file owns (declared in the headers). */
MemSlot mem__handle_tbl[MEM_MAX_HANDLES];
PoolHdr far *lpPoolStart;
unsigned pool_free_mem;
PoolHdr far *lpPoolCurrent;
PoolHdr far *lpPoolEnd;
MemSlot *mem_handle_free_list;

extern unsigned _aseghi;    /* C runtime: highest segment in use */

void Fatal(char *msg);  /* fatal error */
int CachePurge(int ems);    /* seg016: release cached memory, 0 if nothing left */

int pool_stack_size = 0;
int pool_lock_count = 0;

void *AllocMemPtr(int size)
{
    void *p;

    if ((p = malloc(size)) == 0)
        Fatal("Near memory allocation failure, game over.");
    return p;
}

void FreeMemPtr(void *p)
{
    free(p);
}

void InitPMem(void)
{
    union REGS in;
    union REGS out;

    in.h.ah = 0x48;
    in.x.bx = 0xFFFF;
    intdos(&in, &out);
    if (out.x.cflag && out.x.ax == 8) {
        in.x.bx = out.x.bx;
        intdos(&in, &out);
    }
    if (out.x.cflag || in.x.bx < 1)
        Fatal("Can't allocate P memory space");
    FP_SEG(lpPoolStart) = out.x.ax;
    FP_OFF(lpPoolStart) = 0;
    pool_free_mem = in.x.bx;
    lpPoolCurrent = lpPoolStart;
    FP_SEG(lpPoolEnd) = FP_SEG(lpPoolStart) + pool_free_mem;
    FP_OFF(lpPoolEnd) = 0;
    if (FP_SEG(lpPoolEnd) > _aseghi)
        _aseghi = FP_SEG(lpPoolEnd);
    lpPoolStart->size = pool_free_mem;
    lpPoolStart->handle = 0;
}

/* Slide all used blocks down to the start of the pool. */
void CompactPMem(void)
{
    PoolHdr far *src;
    PoolHdr far *dst;
    unsigned size;

    src = lpPoolStart;
    for (dst = lpPoolStart; src != lpPoolEnd; FP_SEG(src) += size) {
        size = src->size;
        if (src->handle != 0) {
            if (src != dst) {
                MemCpy(dst, src, size << 4);
                dst->handle->ptr = POOL_DATA(dst);
            }
            FP_SEG(dst) += size;
        }
    }
    if (src != dst) {
        dst->size = FP_SEG(src) - FP_SEG(dst);
        dst->handle = 0;
    } else
        Fatal("CompactPMem didn't leave any free memory");
    lpPoolCurrent = dst;
}

/* Allocate temporary memory from the top of the pool. */
void far *PushMem(unsigned size)
{
    unsigned paras;
    PoolHdr far *p;
    PoolHdr far *last;
    char buf[80];

    for (paras = ((size + 15) >> 4) + 1; pool_free_mem <= paras; ) {
        if (!CachePurge(0)) {
            sprintf(buf, "Can't push %d bytes of FAR memory", size);
            Fatal(buf);
        }
    }
    if (lpPoolCurrent == lpPoolEnd)
        lpPoolCurrent = lpPoolStart;
    last = 0;
    for (p = lpPoolCurrent; p != lpPoolEnd; FP_SEG(p) += p->size) {
        if (p->handle == 0) {
            if (last != 0)
                last->size += p->size;
            else
                last = p;
        } else
            last = 0;
    }
    if (last == 0 || last->size < paras) {
        CompactPMem();
        last = lpPoolCurrent;
    }
    FP_SEG(lpPoolEnd) -= paras;
    last->size -= paras;
    pool_free_mem -= paras;
    lpPoolEnd->size = paras;
    ++pool_stack_size;
    return POOL_DATA(lpPoolEnd);
}

void PopMem(void)
{
    if (pool_stack_size == 0)
        Fatal("PopMem without PushMem.");
    --pool_stack_size;
    pool_free_mem += lpPoolEnd->size;
    lpPoolEnd->handle = 0;
    FP_SEG(lpPoolEnd) += lpPoolEnd->size;
}

void InitMemHandles(void)
{
    int i;

    mem_handle_free_list = 0;
    for (i = 0; i < MEM_MAX_HANDLES; i++) {
        mem__handle_tbl[i].next = mem_handle_free_list;
        mem_handle_free_list = &mem__handle_tbl[i];
    }
}

void InitMem(void)
{
    InitMemHandles();
    InitPMem();
}

MemHandle AllocMemHandle(void far *p)
{
    MemHandle h;

    for (; mem_handle_free_list == 0; ) {
        if (!CachePurge(1))
            Fatal("Out of memory handles!");
    }
    h = mem_handle_free_list;
    mem_handle_free_list = mem_handle_free_list->next;
    h->ptr = p;
    return h;
}

void FreeMemHandle(MemHandle h)
{
    h->next = mem_handle_free_list;
    mem_handle_free_list = h;
}

MemHandle AllocMem(unsigned size, int ems)
{
    void far *e;
    unsigned paras;
    PoolHdr far *p;
    int failed;
    int found;
    PoolHdr far *last;
    PoolHdr far *n;

    paras = ((size + 15) >> 4) + 1;
    failed = 0;
    if (pool_lock_count != 0)
        Fatal("Memory locked in AllocMem!");
    for (;;) {
        if (ems != 0) {
            if ((e = EMSAlloc((long)size)) != 0)
                return AllocMemHandle(e);
        }
        if ((failed ? 0 : 0x400) + paras <= pool_free_mem) {
            found = 0;
            last = 0;
            for (p = lpPoolCurrent; p != lpPoolEnd; FP_SEG(p) += p->size) {
                if (p->handle == 0) {
                    if (last != 0) {
                        last->size += p->size;
                        p = last;
                    } else
                        last = p;
                    if (p->size >= paras) {
                        found = 1;
                        break;
                    }
                } else
                    last = 0;
            }
            if (!found) {
                if (lpPoolCurrent != lpPoolEnd)
                    FP_SEG(lpPoolCurrent) += lpPoolCurrent->size;
                last = 0;
                for (p = lpPoolStart; p != lpPoolCurrent; FP_SEG(p) += p->size) {
                    if (p->handle == 0) {
                        if (last != 0) {
                            last->size += p->size;
                            p = last;
                        } else
                            last = p;
                        if (p->size >= paras) {
                            found = 1;
                            break;
                        }
                    } else
                        last = 0;
                }
            }
            if (!found) {
                CompactPMem();
                p = lpPoolCurrent;
                if (p->size < paras)
                    Fatal("Internal error in AllocMem");
            }
            if (paras != p->size) {
                n = p;
                FP_SEG(n) += paras;
                n->size = p->size - paras;
                n->handle = 0;
                lpPoolCurrent = n;
                p->size = paras;
            } else
                lpPoolCurrent = p;
            pool_free_mem -= paras;
            p->handle = AllocMemHandle(POOL_DATA(p));
            return p->handle;
        }
        if (failed)
            return 0;
        failed = !CachePurge(ems != 0);
    }
}

MemHandle AllocMemAbort(unsigned size, int ems)
{
    MemHandle h;

    h = AllocMem(size, ems);
    if (h != 0)
        return h;
    Fatal("out of FAR memory");
}

int IsMemEMS(MemHandle h)
{
    return IsEMSMemory(h->ptr);
}

void far *LockMem(MemHandle h)
{
    ++pool_lock_count;
    return EMSAccess(h->ptr);
}

void UnlockMem(MemHandle h)
{
    --pool_lock_count;
    if (pool_lock_count < 0)
        Fatal("LockCount < 0!");
    EMSDeaccess(h->ptr);
}

void FreeMem(MemHandle h)
{
    PoolHdr far *p;

    if (pool_lock_count != 0)
        Fatal("Memory locked in FreeMem");
    if (IsEMSMemory(h->ptr))
        EMSFree(h->ptr);
    else {
        p = POOL_HDR(h->ptr);
        p->handle = 0;
        pool_free_mem += p->size;
    }
    FreeMemHandle(h);
}

void far *MemSet(void far *dst, unsigned n, int c)
{
    _asm {
        push si
        push di
        les di, dst
        mov cx, n
        mov al, byte ptr c
        mov ah, al
        test di, 1
        je evenaddr
        stosb
        dec cx
        je done
    evenaddr:
        mov bx, cx
        shr cx, 1
        je odd
        rep stosw
    odd:
        test bl, 1
        je done
        stosb
    done:
        mov ax, di
        mov dx, es
        pop di
        pop si
    }
}

void MemCpy(void far *dst, void far *src, unsigned n)
{
    _asm {
        push si
        push di
        push ds
        lds si, src
        les di, dst
        mov cx, n
        or cx, cx
        je done
        mov ax, si
        ror ax, 1
        jns words
        mov ax, di
        ror ax, 1
        jns words
        movsb
        dec cx
        je done
    words:
        mov ax, cx
        shr cx, 1
        je odd
        rep movsw
    odd:
        test al, 1
        je done
        movsb
    done:
        pop ds
        pop di
        pop si
    }
}

/* Copy, skipping zero (transparent) bytes. */
void MemCpyNZ(void far *dst, void far *src, unsigned n)
{
    _asm {
        push si
        push di
        push ds
        lds si, src
        les di, dst
        mov cx, n
        or cx, cx
        je done
    next:
        lodsb
        or al, al
        je skip
        stosb
        loop next
        jmp short done
    skip:
        inc di
        loop next
    done:
        pop ds
        pop di
        pop si
    }
}
