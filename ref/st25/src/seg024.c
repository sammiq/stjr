/* seg024: bitmap scaling with generated code */

#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"

/* Globals this file owns (declared in the headers). */
char scale_code[0x502];
char scale_row[0x140];

void Fatal(char *fmt, ...);     /* fatal error */

/* Scale a bitmap by scale/256, returning a new bitmap. */
MemHandle ScaleBitmap(MemHandle handle, int scale)
{
    int unused1[12];
    char far *srcrow;
    char far *dstrow;
    long unused2;
    int srcw;
    int srch;
    int w;
    int h;
    int err;
    int inc1;
    int inc2;
    int y;
    char drawn;
    Bitmap far *src;
    MemHandle nh;
    Bitmap far *dst;

    src = LockMem(handle);
    w = ((long)src->w * scale) >> 8;
    h = ((long)src->h * scale) >> 8;
    UnlockMem(handle);
    w = max(1, w);
    h = max(1, h);
    nh = AllocMemAbort(w * h + 8, 0);
    src = LockMem(handle);
    dst = LockMem(nh);
    dst->x = ((long)src->x * scale) >> 8;
    dst->y = ((long)src->y * scale) >> 8;
    dst->w = w;
    dst->h = h;
    srcw = src->w;
    srch = src->h;
    srcrow = src->data;
    dstrow = dst->data;
    BuildScaler(scale_code, w, srcw);
    --srch;
    --h;
    if (scale <= 0x100) {
        /* shrinking: skip source rows */
        err = 0;
        inc1 = h * 2;
        inc2 = (h - srch) * 2;
        for (y = 0; y <= srch; y++) {
            if (err < 0)
                err += inc1;
            else {
                err += inc2;
                RunScaler(scale_row, srcrow, scale_code);
                MemCpy(dstrow, scale_row, w);
                dstrow += w;
            }
            srcrow += src->w;
        }
    } else {
        /* enlarging: repeat source rows */
        err = srch * 2 - h;
        inc1 = srch * 2;
        inc2 = (srch - h) * 2;
        drawn = 0;
        srcw = src->w;
        for (y = 0; y <= h; y++) {
            if (!drawn) {
                RunScaler(scale_row, srcrow, scale_code);
                drawn = 1;
            }
            MemCpy(dstrow, scale_row, w);
            dstrow += w;
            if (err < 0)
                err += inc1;
            else {
                err += inc2;
                srcrow += srcw;
                drawn = 0;
            }
        }
    }
    UnlockMem(handle);
    UnlockMem(nh);
    return nh;
}

/* Generate code that scales a row of sw pixels to dw pixels: unrolled
 * movsb / mov al,[si]; stosb / inc si / add si,n, ending in retf. */
void BuildScaler(register char *p, int dw, int sw)
{
    int err;
    int inc1;
    int inc2;
    int count;
    int i;
    register int n;
    int pending;
    char *start;

    start = p;
    if (sw >= dw) {
        err = dw * 2 - sw;
        inc1 = dw * 2;
        inc2 = (dw - sw) * 2;
        pending = n = 0;
        i = 0;
        for (count = sw; count--; i++) {
            if (err < 0)
                err += inc1;
            else {
                err += inc2;
                if (n != 0) {
                    if (pending) {
                        p[-3] = 0xA4;           /* movsb */
                        p -= 2;
                        pending = 0;
                        --n;
                    }
                    if (n > 2) {
                        *p++ = 0x83;            /* add si, n */
                        *p++ = 0xC6;
                        *p++ = n;
                    } else {
                        while (n--)
                            *p++ = 0x46;        /* inc si */
                    }
                    n = 0;
                }
                *p++ = 0x8A;                    /* mov al, [si] */
                *p++ = 0x04;
                *p++ = 0xAA;                    /* stosb */
                pending = 1;
            }
            ++n;
        }
        *p++ = 0xCB;                            /* retf */
    } else {
        err = (sw - 1) * 2 - (dw - 1);
        inc1 = (sw - 1) * 2;
        inc2 = ((sw - 1) - (dw - 1)) * 2;
        n = 0;
        i = 0;
        for (count = dw; count--; i++) {
            if (n != 0) {
                if (n > 2) {
                    *p++ = 0x83;                /* add si, n */
                    *p++ = 0xC6;
                    *p++ = n;
                } else {
                    while (n--)
                        *p++ = 0x46;            /* inc si */
                }
                n = 0;
            }
            *p++ = 0x8A;                        /* mov al, [si] */
            *p++ = 0x04;
            *p++ = 0xAA;                        /* stosb */
            if (err < 0)
                err += inc1;
            else {
                err += inc2;
                ++n;
            }
        }
        *p++ = 0xCB;                            /* retf */
    }
    if (p > start + SCALE_CODE_MAX)
        Fatal("too many inst %d.\n", p - start);
}

/* Call the generated code with es:di = dst, ds:si = src. */
void RunScaler(void far *dst, void far *src, char *code)
{
    _asm {
        push si
        push di
        push ds
        push cs
        mov ax, offset back
        push ax
        push ds
        push code
        les di, dst
        lds si, src
        retf
    back:
        pop ds
        pop di
        pop si
    }
}
