/* seg004: LIM EMS expanded memory allocator */

#include <dos.h>
#include "ems.h"

extern unsigned _aseghi;    /* C runtime: highest segment in use */

/* No prototypes in this file in the original: the pointer is passed near. */
int MemSet();
void Fatal();           /* fatal error */

int ems_other_page = -1;

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

