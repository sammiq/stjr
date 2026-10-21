/* acmp: the ACMP audio decompressor (8-bit samples coded in blocks of
 * 256 as deltas: unary, fixed width or halved and interpolated). The
 * decoder works on cur; a stream's AcmpState is swapped in and out when
 * another stream is read. */

#include <string.h>
#include <memory.h>

typedef struct AcmpState {
    void far *ctx;                      /* 000 handed to read */
    unsigned (far *read)(void far *ctx, char *buf, unsigned n);    /* 004 */
    unsigned char inbuf[256];           /* 008 compressed bytes */
    unsigned char *inp;                 /* 108 */
    int inlen;                          /* 10A */
    unsigned bits;                      /* 10C bit reader */
    unsigned nbits;                     /* 10E */
    unsigned rbyte;                     /* 110 unary reader */
    unsigned rbits;                     /* 112 */
    unsigned rlast;                     /* 114 */
    unsigned char outbuf[256];          /* 116 decoded samples */
    unsigned char *outp;                /* 216 */
    unsigned outlen;                    /* 218 */
    unsigned char prev;                 /* 21A the last sample */
    char unk21B;                        /* 21B */
    unsigned long remain;               /* 21C samples left */
} AcmpState;

static AcmpState acmp_cur;
AcmpState far *acmp_owner = 0;          /* whose state acmp_cur holds */

#define cur acmp_cur
#define GETBYTE() (--cur.inlen >= 0 ? *cur.inp++ : AcmpFill())

unsigned AcmpBits(unsigned n);

void AcmpSetReader(void far *ctx, unsigned (far *read)(void far *, char *, unsigned))
{
    cur.ctx = ctx;
    cur.read = read;
    cur.inlen = 0;
}

/* Refill the input buffer: its first byte. */
unsigned char AcmpFill(void)
{
    cur.inlen = cur.read(cur.ctx, cur.inbuf, 256);
    cur.inp = cur.inbuf;
    cur.inlen--;
    return *cur.inp++;
}

void AcmpResetBits(void)
{
    cur.rlast = cur.rbits = cur.rbyte = cur.nbits = cur.bits = 0;
}

unsigned AcmpBits(unsigned n)
{
    unsigned v;

    while (cur.nbits < n) {
        cur.bits |= (unsigned)GETBYTE() << cur.nbits;
        cur.nbits += 8;
    }
    v = cur.bits & ((1 << n) - 1);
    cur.bits >>= n;
    cur.nbits -= n;
    return v;
}

/* A run length: bits alternating from the last run's, ending at a change
 * (10 or more: the next 6 bits). */
int AcmpUnary(void)
{
    int n;

    n = 1;
    cur.rlast = cur.rlast == 0;
    for (;;) {
        if (cur.rbits == 0) {
            cur.rbyte = GETBYTE();
            cur.rbits = 8;
        }
        cur.rbits--;
        if ((cur.rbyte ^ cur.rlast) & 1)
            break;
        n++;
        cur.rbyte >>= 1;
    }
    cur.rbyte >>= 1;
    if (n == 10)
        return AcmpBits(6);
    return n;
}

void AcmpConst(unsigned char *out, unsigned n)
{
    memset(out, AcmpBits(8), n);
}

void AcmpDecode1(unsigned char *out, unsigned n, int shift)
{
    int v;
    unsigned i;
    int k;
    int d;

    v = 0x80;
    for (i = 0; i < n; i++) {
        if ((k = AcmpUnary() - 1) != 0) {
            d = AcmpBits(k) | 1 << k;
            d = d & 1 ? -(d >> 1) : d >> 1;
            v += d << shift;
        }
        *out++ = v;
    }
}

void AcmpDecode2(unsigned char *out, unsigned n, int shift)
{
    int v;
    unsigned i;
    int d;

    v = 0x80;
    for (i = 0; i < n; i++) {
        if ((d = AcmpBits(4)) != 0)
            d -= 8;
        else
            d = AcmpBits(8 - shift);
        v += d << shift;
        *out++ = v;
    }
}

void AcmpDecode3(unsigned char *out, unsigned n, int shift)
{
    int v;
    unsigned i;
    int k;
    int d;

    v = 0x80;
    for (i = 0; i < n; i++) {
        k = AcmpUnary() - 1;
        d = AcmpBits(3) + (k << 3);
        d = d & 1 ? -(d >> 1) : d >> 1;
        v += d << shift;
        *out++ = v;
    }
}

void AcmpDecode4(unsigned char *out, unsigned n, int shift)
{
    int v;
    unsigned i;
    int k;
    int d;

    v = 0x80;
    for (i = 0; i < n; i++) {
        k = AcmpUnary() - 1;
        d = AcmpBits(4) + (k << 4);
        d = d & 1 ? -(d >> 1) : d >> 1;
        v += d << shift;
        *out++ = v;
    }
}

void AcmpDecode5(unsigned char *out, unsigned n, int shift)
{
    int v;
    unsigned i;
    int k;
    int d;

    v = 0x80;
    for (i = 0; i < n; i++) {
        if ((d = AcmpBits(2)) == 3)
            d = -1;
        else if (d == 2) {
            k = AcmpUnary();
            d = AcmpBits(k + 1) | 2 << k;
            d = d & 1 ? -(d >> 1) : d >> 1;
        }
        v += d << shift;
        *out++ = v;
    }
}

void AcmpDecode6(unsigned char *out, unsigned n, int shift)
{
    unsigned i;

    for (i = 0; i < n; i++)
        *out++ = AcmpBits(8 - shift) << shift;
}

/* Decode a block of n samples into out; prev is the sample before it. */
void AcmpBlock(unsigned char prev, unsigned char *out, unsigned n)
{
    unsigned char hdr;
    int shift;
    unsigned len;
    int i;
    int j;
    int a;
    int b;
    int t;
    int s;

    AcmpResetBits();
    hdr = AcmpBits(8);
    shift = (hdr & 0x60) >> 5;
    len = hdr & 0x80 ? (n + 1) >> 1 : n;
    switch (hdr & 0x1F) {
    case 0:
        AcmpConst(out, len);
        break;
    case 1:
        AcmpDecode1(out, len, shift);
        break;
    case 2:
        AcmpDecode2(out, len, shift);
        break;
    case 3:
        AcmpDecode3(out, len, shift);
        break;
    case 4:
        AcmpDecode4(out, len, shift);
        break;
    case 5:
        AcmpDecode5(out, len, shift);
        break;
    case 6:
        AcmpDecode6(out, len, shift);
        break;
    }
    if (hdr & 0x80) {
        /* half rate: fill in the samples between */
        for (i = n - 1; i >= 0; i--) {
            j = i >> 1;
            if (i & 1)
                out[i] = out[j];
            else {
                a = j ? out[j - 1] : prev;
                if (j > 1 && j < len - 1) {
                    b = j != 1 ? out[j - 2] : prev;
                    s = out[j] + a;
                    t = s - out[j + 1] - b;
                    t = (t + t * 2 + (s + 1 << 5)) >> 6;
                    if (t < 0)
                        t = 0;
                    else if (t > 255)
                        t = 255;
                    out[i] = t;
                } else {
                    a = a + 1 & ~1;
                    out[i] = (a + out[j]) >> 1;
                }
            }
        }
    }
}

/* Load s into cur. */
void AcmpRestore(AcmpState far *s)
{
    cur.ctx = s->ctx;
    cur.read = s->read;
    cur.inp = s->inp;
    if ((cur.inlen = s->inlen) != 0)
        _fmemcpy((unsigned char far *)cur.inp, s->inbuf, cur.inlen);
    cur.bits = s->bits;
    cur.nbits = s->nbits;
    cur.rbyte = s->rbyte;
    cur.rbits = s->rbits;
    cur.rlast = s->rlast;
    cur.outp = s->outp;
    if ((cur.outlen = s->outlen) != 0)
        _fmemcpy((unsigned char far *)cur.outp, s->outbuf, cur.outlen);
    cur.prev = s->prev;
    cur.remain = s->remain;
}

/* Store cur into s. */
void AcmpSave(AcmpState far *s)
{
    s->ctx = cur.ctx;
    s->read = cur.read;
    s->inp = cur.inp;
    s->inlen = cur.inlen;
    if (cur.inlen)
        _fmemcpy(s->inbuf, (unsigned char far *)cur.inp, cur.inlen);
    s->bits = cur.bits;
    s->nbits = cur.nbits;
    s->rbyte = cur.rbyte;
    s->rbits = cur.rbits;
    s->rlast = cur.rlast;
    s->outp = cur.outp;
    s->outlen = cur.outlen;
    if (cur.outlen)
        _fmemcpy(s->outbuf, (unsigned char far *)cur.outp, cur.outlen);
    s->prev = cur.prev;
    s->remain = cur.remain;
}

/* Make s the stream cur decodes. */
void AcmpSelect(AcmpState far *s)
{
    if (s && s != acmp_owner) {
        if (acmp_owner)
            AcmpSave(acmp_owner);
        AcmpRestore(s);
        acmp_owner = s;
    }
}

void AcmpRelease(AcmpState far *s)
{
    if (s == acmp_owner)
        acmp_owner = 0;
}

unsigned AcmpStateSize(void)
{
    return sizeof(AcmpState);
}

/* Start decoding into s: the stream begins with its length in samples. */
void AcmpOpen(AcmpState far *s, void far *ctx, unsigned (far *read)(void far *, char *, unsigned))
{
    int a;
    int b;
    int c;

    AcmpSelect(s);
    AcmpSetReader(ctx, read);
    cur.outlen = 0;
    cur.prev = 0x80;
    cur.remain = a = GETBYTE();
    cur.remain |= (long)(a = GETBYTE()) << 8;
    cur.remain |= (long)(b = GETBYTE()) << 16;
    cur.remain |= (long)(c = GETBYTE()) << 24;
}

/* Decode up to n samples of s into buf: how many. */
unsigned AcmpRead(AcmpState far *s, unsigned char far *buf, unsigned n)
{
    unsigned left;
    unsigned k;

    AcmpSelect(s);
    for (left = n; left && cur.remain; left -= k) {
        if (cur.outlen == 0) {
            cur.outlen = cur.remain > 256 ? 256 : (unsigned)cur.remain;
            AcmpBlock(cur.prev, cur.outbuf, cur.outlen);
            cur.prev = cur.outbuf[cur.outlen - 1];
            cur.outp = cur.outbuf;
        }
        if ((k = cur.outlen) > left)
            k = left;
        _fmemcpy(buf, (unsigned char far *)cur.outp, k);
        buf += k;
        cur.outp += k;
        cur.outlen -= k;
        cur.remain -= k;
    }
    return n - left;
}

void AcmpClose(AcmpState far *s)
{
    AcmpRelease(s);
}
