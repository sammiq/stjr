/* seg024: bitmap scaling with generated code */

#include <stdlib.h>
#include "mem.h"
#include "bitmap.h"

void Fatal(char *fmt, ...);     
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

