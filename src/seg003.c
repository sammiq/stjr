/* seg003: CD-ROM detection, resource files (DATA.DIR/RUN/001) and patches */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <io.h>
#include <dos.h>
#include "ems.h"
#include "mem.h"
#include "resource.h"

struct find_t patch_find;

void Fatal(char *fmt, ...);     /* fatal error */

void UnpackAll(unsigned char far *src, unsigned char far *dst, unsigned len)
{
    unsigned n;

    n = UnpackChunk(src, &dst, len);
    Unpack(src + n, dst, len - n);
}

/* Copy a name up to the first space. */
void CopyName(char *dst, char *src)
{
    while ((*dst = *src) != 0 && *src != ' ') {
        dst++;
        src++;
    }
    *dst = 0;
}

char *FindNextPatch(void)
{
    if (_dos_findnext(&patch_find) == 0)
        return patch_find.name;
    else
        return 0;
}
